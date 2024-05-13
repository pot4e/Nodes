# Hướng dẫn cài đặt validator node
# Yêu cầu phần cứng
```
- Memory: 64 GB RAM
- CPU: 8 cores
- Disk: 1 TB NVME SSD
- Bandwidth: 100mbps Gbps for Download / Upload
- Linux amd64 arm64 (Hướng dẫn này sử dụng Ubuntu 22.04 LTS)
```
# Hướng dẫn cài đặt
1. Cài đặt các package cần thiết
```
sudo apt update && \
sudo apt install curl git jq build-essential gcc unzip wget lz4 -y
```
2. Cài đặt Go
```
cd $HOME && \
ver="1.22.0" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version
```
3. Build 0gchaind binary
```
git clone -b v0.1.0 https://github.com/0glabs/0g-chain.git
cd 0g-chain
make install
0gchaind version
```
4. Set up các biến
```
# Customize if you need
echo 'export MONIKER="My_Node"' >> ~/.bash_profile
echo 'export CHAIN_ID="zgtendermint_16600-1"' >> ~/.bash_profile
echo 'export WALLET_NAME="wallet"' >> ~/.bash_profile
echo 'export RPC_PORT="26657"' >> ~/.bash_profile
source $HOME/.bash_profile
```
5. Khởi tạo node
```
cd $HOME
0gchaind init $MONIKER --chain-id $CHAIN_ID
0gchaind config chain-id $CHAIN_ID
0gchaind config node tcp://localhost:$RPC_PORT
0gchaind config keyring-backend os # You can set it to "test" so you will not be asked for a password
```
6. Download genesis.json
```
wget https://github.com/0glabs/0g-chain/releases/download/v0.1.0/genesis.json -O $HOME/.0gchain/config/genesis.json
```
7. Add seeds và peers vào file config.toml
```
SEEDS="c4d619f6088cb0b24b4ab43a0510bf9251ab5d7f@54.241.167.190:26656,44d11d4ba92a01b520923f51632d2450984d5886@54.176.175.48:26656,f2693dd86766b5bf8fd6ab87e2e970d564d20aff@54.193.250.204:26656,f878d40c538c8c23653a5b70f615f8dccec6fb9f@54.215.187.94:26656" && \
sed -i.bak -e "s/^seeds *=.*/seeds = \"${SEEDS}\"/" $HOME/.0gchain/config/config.toml
```
8. Change ports (Tùy chọn)
```
# Customize if you need
EXTERNAL_IP=$(wget -qO- eth0.me) \
PROXY_APP_PORT=26658 \
P2P_PORT=26656 \
PPROF_PORT=6060 \
API_PORT=1317 \
GRPC_PORT=9090 \
GRPC_WEB_PORT=9091
```
```
sed -i \
    -e "s/\(proxy_app = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$PROXY_APP_PORT\"/" \
    -e "s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$RPC_PORT\"/" \
    -e "s/\(pprof_laddr = \"\)\([^:]*\):\([0-9]*\).*/\1localhost:$PPROF_PORT\"/" \
    -e "/\[p2p\]/,/^\[/{s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$P2P_PORT\"/}" \
    -e "/\[p2p\]/,/^\[/{s/\(external_address = \"\)\([^:]*\):\([0-9]*\).*/\1${EXTERNAL_IP}:$P2P_PORT\"/; t; s/\(external_address = \"\).*/\1${EXTERNAL_IP}:$P2P_PORT\"/}" \
    $HOME/.0gchain/config/config.toml
```
```
sed -i \
    -e "/\[api\]/,/^\[/{s/\(address = \"tcp:\/\/\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$API_PORT\4/}" \
    -e "/\[grpc\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$GRPC_PORT\4/}" \
    -e "/\[grpc-web\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$GRPC_WEB_PORT\4/}" \
    $HOME/.0gchain/config/app.toml
```
9. Cấu hình pruning để tiết kiệm dung lượng lưu trữ (Tùy chọn)
```
sed -i \
    -e "s/^pruning *=.*/pruning = \"custom\"/" \
    -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" \
    -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" \
    "$HOME/.0gchain/config/app.toml"
```
10. Cài đặt min gas price
```
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ua0gi\"/" $HOME/.0gchain/config/app.toml
```
11. Enable indexer (Tùy chọn)
```
sed -i "s/^indexer *=.*/indexer = \"kv\"/" $HOME/.0gchain/config/config.toml
```
12. Tạo service file
```
sudo tee /etc/systemd/system/0gd.service > /dev/null <<EOF
[Unit]
Description=0G Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which 0gchaind) start --home $HOME/.0gchain
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```
13. Start node
```
sudo systemctl daemon-reload && \
sudo systemctl enable 0gd && \
sudo systemctl restart 0gd && \
sudo journalctl -u 0gd -f -o cat
```
P/s: Có thể download snapshot hoặc sử dụng state-sync để đồng bộ nhanh hơn. 

14. Tạo ví
```
0gchaind keys add $WALLET_NAME

# DO NOT FORGET TO SAVE THE SEED PHRASE
# You can add --recover flag to restore existing key instead of creating
```
15. Lấy HEX address để faucet token
```
echo "0x$(0gchaind debug addr $(0gchaind keys show $WALLET_NAME -a) | grep hex | awk '{print $3}')"
```
16. Faucet tokens
-> FAUCET <-

17. Check wallet balance
Đảm bảo răng node của bạn đã sync xong (catching_up trả về false)

```
0gchaind status | jq .SyncInfo.catching_up
```
Nếu node đã sync, sử dụng câu lệnh sau để kiểm tra balance

```
0gchaind q bank balances $(0gchaind keys show $WALLET_NAME -a) 
```
18. Tạo validator
```
0gchaind tx staking create-validator \
  --amount=1000000ua0gi \
  --pubkey=$(0gchaind tendermint show-validator) \
  --moniker=$MONIKER \
  --chain-id=$CHAIN_ID \
  --commission-rate=0.05 \
  --commission-max-rate=0.10 \
  --commission-max-change-rate=0.01 \
  --min-self-delegation=1 \
  --from=$WALLET_NAME \
  --identity="" \
  --website="" \
  --details="0G to the moon!" \
  --gas=500000 --gas-prices=99999ua0gi \
  -y
```
Lưu ý: Nhớ lưu lại priv_validator_key.json ở $HOME/.0gchain/config/

# State sync
1. Stop node
```
sudo systemctl stop 0gd
```
2. Backup priv_validator_state.json
```
cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
```
3. Reset DB
```
0gchaind tendermint unsafe-reset-all --home $HOME/.0gchain --keep-addr-book
```
4. Cài đặt các biến cần thiết (Copy toàn bộ và paste lên terminal trong 1 lệnh)
```
PEERS="1248487ea585730cdf5d3c32e0c2a43ad0cda973@peer-zero-gravity-testnet.trusted-point.com:26326" && \
RPC="https://rpc-zero-gravity-testnet.trusted-point.com:443" && \
LATEST_HEIGHT=$(curl -s --max-time 3 --retry 2 --retry-connrefused $RPC/block | jq -r .result.block.header.height) && \
TRUST_HEIGHT=$((LATEST_HEIGHT - 1500)) && \
TRUST_HASH=$(curl -s --max-time 3 --retry 2 --retry-connrefused "$RPC/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash) && \

if [ -n "$PEERS" ] && [ -n "$RPC" ] && [ -n "$LATEST_HEIGHT" ] && [ -n "$TRUST_HEIGHT" ] && [ -n "$TRUST_HASH" ]; then
    sed -i \
        -e "/\[statesync\]/,/^\[/{s/\(enable = \).*$/\1true/}" \
        -e "/^rpc_servers =/ s|=.*|= \"$RPC,$RPC\"|;" \
        -e "/^trust_height =/ s/=.*/= $TRUST_HEIGHT/;" \
        -e "/^trust_hash =/ s/=.*/= \"$TRUST_HASH\"/" \
        -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" \
        $HOME/.0gchain/config/config.toml
    echo -e "\nLATEST_HEIGHT: $LATEST_HEIGHT\nTRUST_HEIGHT: $TRUST_HEIGHT\nTRUST_HASH: $TRUST_HASH\nPEERS: $PEERS\n\nALL IS FINE"
else
    echo -e "\nError: One or more variables are empty. Please try again or change RPC\nExiting...\n"
fi
```
4. Move file priv_validator_state.json trở lại
```
mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json
```
5. Start node
```
sudo systemctl restart 0gd && sudo journalctl -u 0gd -f -o cat
```
Bạn sẽ thấy những dòng log như sau. Có thể mất tới 5 phút để phát hiện snapshot. Nếu không hoạt động, hãy thử tải snapshot.

```
2:39PM INF sync any module=statesync msg="Discovering snapshots for 15s" server=node
2:39PM INF Discovered new snapshot format=3 hash="?^��I��\r�=�O�E�?�CQD�6�\x18�F:��\x006�" height=602000 module=statesync server=node
2:39PM INF Discovered new snapshot format=3 hash="%���\x16\x03�T0�v�f�C��5�<TlLb�5��l!�M" height=600000 module=statesync server=node
2:42PM INF VerifyHeader hash=CFC07DAB03CEB02F53273F5BDB6A7C16E6E02535B8A88614800ABA9C705D4AF7 height=602001 module=light server=node
```
Sau một thời gian, bạn sẽ thấy các nhật ký sau. Phải mất 5 phút để node bắt kịp các block còn lại

```
2:43PM INF indexed block events height=602265 module=txindex server=node
2:43PM INF executed block height=602266 module=state num_invalid_txs=0 num_valid_txs=0 server=node
2:43PM INF commit synced commit=436F6D6D697449447B5B31313720323535203139203132392031353920313035203136352033352031353320313220353620313533203139352031372036342034372033352034372032333220373120313939203720313734203620313635203338203336203633203235203136332039203134395D3A39333039417D module=server
2:43PM INF committed state app_hash=75FF13819F69A523990C3899C311402F232FE847C707AE06A526243F19A30995 height=602266 module=state num_txs=0 server=node
2:43PM INF indexed block events height=602266 module=txindex server=node
2:43PM INF executed block height=602267 module=state num_invalid_txs=0 num_valid_txs=0 server=node
2:43PM INF commit synced commit=436F6D6D697449447B5B323437203134322032342031313620323038203631203138362032333920323238203138312032333920313039203336203420383720323238203236203738203637203133302032323220313431203438203337203235203133302037302032343020313631203233372031312036365D3A39333039427D module=server
```
6. Kiểm tra trạng thái đồng bộ
```
0gchaind status | jq .SyncInfo
```
7. Disable state sync
```
sed -i -e "/\[statesync\]/,/^\[/{s/\(enable = \).*$/\1false/}" $HOME/.0gchain/config/config.toml
```
# Download addrbook.json mới nhất
1. Stop node và sử dụng `wget` để download file
```
sudo systemctl stop 0gd && \
wget -O $HOME/.0gchain/config/addrbook.json https://rpc-zero-gravity-testnet.trusted-point.com/addrbook.json
```
2. Restart node
```
sudo systemctl restart 0gd && sudo journalctl -u 0gd -f -o cat
```
3. Kiểm tra trạng thái đồng bộ
```
0gchaind status | jq .SyncInfo
```
# Thêm persistent peers mới nhất
1. Extract persistent_peers từ endpoint của Trusted-Point
```
PEERS=$(curl -s --max-time 3 --retry 2 --retry-connrefused "https://rpc-zero-gravity-testnet.trusted-point.com/peers.txt")
if [ -z "$PEERS" ]; then
    echo "No peers were retrieved from the URL."
else
    echo -e "\nPEERS: "$PEERS""
    sed -i "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$HOME/.0gchain/config/config.toml"
    echo -e "\nConfiguration file updated successfully.\n"
fi
```
2. Restart node
```
sudo systemctl restart 0gd && sudo journalctl -u 0gd -f -o cat
```
3. Kiểm tra trạng thái đồng bộ
```
0gchaind status | jq .SyncInfo
```
# Download Snapshot
Ở đây, chúng tôi sử dụng các bản snapshot của Trusted Point

1. Download snapshot
```
wget https://rpc-zero-gravity-testnet.trusted-point.com/latest_snapshot.tar.lz4
```
2. Stop node
```
sudo systemctl stop 0gd
```
3. Backup priv_validator_state.json
```
cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
```
4. Reset DB
```
0gchaind tendermint unsafe-reset-all --home $HOME/.0gchain --keep-addr-book
```
5. Giải nén file snapshot
```
lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.0gchain
```
6. Move priv_validator_state.json trở lại
```
mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json
```
7. Restart node
```
sudo systemctl restart 0gd && sudo journalctl -u 0gd -f -o cat
```
8. Kiểm tra trạng thái đồng bộ
```
0gchaind status | jq .SyncInfo
```
Snapshot được update 3 giờ 1 lần

# Monitoring
Phía trusted point có đưa ra một dashboard công khai để theo dõi tình trạng chung của node. Các bạn có thể theo dõi tại: http://dashboard-0g.trusted-point.com/
