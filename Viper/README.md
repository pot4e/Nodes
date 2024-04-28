# Viper Private Testnet Validator Node

![alt text](https://github.com/pot4e/Nodes/blob/main/Viper/viper-private.jpg?raw=true)

# Cấu hình

4 CPUs (or vCPUs)

8 GB RAM

100 GB Disk

# Chuẩn bị

Bạn cần chuẩn bị một số thứ sau

- VPS (Ở đây chúng tôi sử dụng VPS của Contabo)

- Domain để cấu hình ssl (Bạn có thể mua tại hostinger với giá khá rẻ, hoặc một số domain free)

# Cài đặt một số dependencies

Github:
```bash
sudo apt install git-all -y
git --version
```

Dependencies:
```bash
sudo apt update
sudo apt dist-upgrade -y
sudo apt-get install git build-essential curl file nginx certbot python3-certbot-nginx jq -y
```

Mở port firewal

```bash
sudo ufw enble
```

Bấm đồng ý hoặc enter gì đó để mở firewal

```bash
sudo ufw default deny
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8081
sudo ufw allow 26656
```

# Cài đặt ssh cho private github

Tạo ssh key
```bash
ssh-keygen
```
Bấm enter 3 lần để tạo

```bash
cat ~/.ssh/id_rsa.pub
```
Copy hết thông tin được hiển thị ra

Truy cập: `https://github.com/settings/ssh/new`

Title: Điền bất kì

Key: Điền thông tin được copy ở trên xong bấm Add SSH Key

```bash
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa
ssh-add -l
ssh -T git@github.com
```

Thấy dòng `Hi {your github}! You've successfully authenticated, but GitHub does not provide shell access.` là ok

# Cài đặt Viper

## Sửa hostname

```bash
nano /etc/hostname
Sau đó sửa thành domain của bạn (Ví dụ của mình sẽ là viper-rpc.daningyn.xyz)
Ctrl-X sau đó bấm Y và bấm enter tiếp theo để lưu file
```

Reboot VPS
```bash
reboot
```

## Clone Viper Source

```bash
git clone git@github.com:vipernet-xyz/viper-binaries.git
```
```bash
cd viper-binaries
sudo cp viper_linux_amd64 /usr/local/bin/viper
```

## Config Viper

### Tạo Wallet

```bash
viper wallet create-account
```

Copy Wallet của bạn để lưu vào một biến cho dễ xử lý, bằng cách sau

```bash
echo "export WALLET_ADDRESS={address}" >> ~/.bash_profile
echo "export HOSTNAME={domain}" >> ~/.bash_profile
```
```bash
source ~/.bash_profile
```

Với `{address}` nên được thay bằng wallet address bạn đã tạo ở trên

Với `{domain}` ở trên bạn sửa ở file `/etc/hostname`

Tạo Validator
```bash
viper servicers create-validator $WALLET_ADDRESS
```

Cập nhật config và thêm persistent peer
```bash
echo $(viper util print-configs) | jq '.tendermint_config.P2P.PersistentPeers = "859674aa64c0ee20ebce8a50e69390698750a65f@mynode1.testnet.vipernet.xyz:26656,eec6c84a7ededa6ee2fa25e3da3ff821d965f94d@mynode2.testnet.vipernet.xyz:26656,81f4c53ccbb36e190f4fc5220727e25c3186bfeb@mynode3.testnet.vipernet.xyz:26656,d53f620caab13785d9db01515b01d6f21ab26d54@mynode4.testnet.vipernet.xyz:26656,e2b1dc002270c8883abad96520a2fe5982cb3013@mynode5.testnet.vipernet.xyz:26656"' | jq . > ~/.viper/config/configuration.json
```

### Tạo chain

```bash
viper util gen-chains
```

Nhập ID Viper network: `0001`

Nhập URL: `http://127.0.0.1:8082/`

Nhập websocket: `http://127.0.0.1:8082/`

Câu hỏi add non-native nhập: `n` và bấm enter

### Tạo Geozone

```bash
viper util gen-geozone
```

Bạn có thể xem thử tại [`geo ID`](https://github.com/vipernet-xyz/viper-binaries/blob/main/chains&geoZones/README.md), và xác định VPS mình nằm ở đâu để lấy ID của chỗ đó

### Tạo genesis

```bash
cd ~/.viper/config
wget https://raw.githubusercontent.com/vipernet-xyz/genesis/main/testnet/genesis.json genesis.json
ulimit -Sn 16384
```

### Tạo Service

Copy content này vào
```bash
cat <<EOF > /etc/systemd/system/viper.service
[Unit]
Description=viper service
After=network.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
User=root
Group=sudo
ExecStart=/usr/local/bin/viper network start
ExecStop=/usr/local/bin/viper network stop

[Install]
WantedBy=default.target
EOF
```

### Setup Data

```bash
cd ~/.viper
rm -rf data
rm -r viper_evidence.db
rm -r viper_result.db
sudo git clone https://github.com/vishruthsk/data.git data
sudo chown -R root ~/.viper/data
cd config
rm addrbook.json
```

### Chạy Viper service

```bash
sudo systemctl daemon-reload
sudo systemctl enable viper.service
sudo systemctl start viper.service
```

### Tạo https

```bash
sudo certbot --nginx --domain $HOSTNAME --register-unsafely-without-email --no-redirect --agree-tos
```

Copy toàn bộ lệnh dưới để config https cho viper
```bash
cat <<EOF > /etc/nginx/sites-available/viper
server {
    add_header Access-Control-Allow-Origin "*";
    listen 80 ;
    listen [::]:80 ;
    listen 8081 ssl;
    listen [::]:8081 ssl;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    server_name $HOSTNAME;

    location / {
        try_files \$uri \$uri/ =404;
    }

    listen [::]:443 ssl ipv6only=on;
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/$HOSTNAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$HOSTNAME/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    access_log /var/log/nginx/reverse-access.log;
    error_log /var/log/nginx/reverse-error.log;

    location ~* ^/v1/client/(dispatch|relay|sim|trigger) {
        proxy_pass http://127.0.0.1:8082;
        add_header Access-Control-Allow-Methods "POST, OPTIONS";
        allow all;
    }

    location = /v1 {
        add_header Access-Control-Allow-Methods "GET";
        proxy_pass http://127.0.0.1:8082;
        allow all;
    }

    location = /v1/query/height {
        add_header Access-Control-Allow-Methods "GET";
        proxy_pass http://127.0.0.1:8082;
        allow all;
    }
}
EOF
```

Chạy tiếp lệnh để setup https

```bash
sudo systemctl stop nginx
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/viper /etc/nginx/sites-enabled/viper
sudo systemctl restart nginx
```

Mở browser lên check xem domain của mình đã có https chưa: `https://domain`

Sau khi OK rồi thì restart lại service của Viper

```bash
sudo systemctl restart viper.service
```

## Faucet

Lên channel node-chat của Viper tag admin và xin faucet vào địa chỉ ví Viper của mình
```
echo $WALLET_ADDRESS
```
Sau khi block sync xong thì ví sẽ có token

## Stake sau khi Sync Xong

```bash
viper servicers stake self $WALLET_ADDRESS 13000000000 0001 {geo_ID} https://$HOSTNAME:443 testnet
```

Với `{geo_ID}` là geo_ID bạn đã lấy ở trên khi setup

# Các lệnh hữu ích

## Check Node Status 
```bash
curl http://127.0.0.1:26657/status
```

## Check Validator của bạn
```bash
viper servicers query servicer $WALLET_ADDRESS
```

### Lệnh kiểm tra về Ví
#### Check Balance 
```bash
viper wallet query account-balance $WALLET_ADDRESS
```

#### Backup Wallet
```bash
viper wallet export-encrypted $WALLET_ADDRESS

# or

viper wallet export-raw $WALLET_ADDRESS
```

#### Recovery Wallet

```bash
viper wallet import-encrypted

# or

viper wallet import-raw
```

#### Fetch Wallet Info
```bash
viper wallet fetch-account $WALLET_ADDRESS

```

#### List all ví
```bash
viper wallet list-accounts
```

#### Đổi password của ví
```bash
viper wallet change-pass $WALLET_ADDRESS --pwd-new input-new-passwd --pwd-old input-old-passwd
```
`input-new-passwd`: Nhập password mới

`input-old-passwd`: Nhập lại password cũ

### Check logs của node
```bash
sudo journalctl -u viper -f -o cat
```

### Restart the node
```bash
sudo systemctl restart viper
```

### Stop the node
```bash
sudo systemctl stop viper
```
