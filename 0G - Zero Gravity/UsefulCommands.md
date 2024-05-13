# Các command hữu ích của 0G
Các câu lệnh dưới đây có sử dụng một số biến đã được khai báo ở phần cài đặt Validator node. Nếu bạn không thực hiện theo guide này, có thể [khai báo lại ở đây](https://github.com/batuoc263/T4E-Nodes/blob/main/0G%20-%20Zero%20Gravity/Validator%20Node.md#h%C6%B0%E1%BB%9Bng-d%E1%BA%ABn-c%C3%A0i-%C4%91%E1%BA%B7t).

## Check node status
```
0gchaind status | jq
```
## Query validator
```
0gchaind q staking validator $(0gchaind keys show $WALLET_NAME --bech val -a) 
```
## Query missed blocks counter & jail details của validator
```
0gchaind q slashing signing-info $(0gchaind tendermint show-validator)
```
## Unjail validator
```
0gchaind tx slashing unjail --from $WALLET_NAME --gas=500000 --gas-prices=99999ua0gi -y
```
## Delegate tokens vào validator
```
0gchaind tx staking delegate $(0gchaind keys show $WALLET_NAME --bech val -a)  <AMOUNT>ua0gi --from $WALLET_NAME --gas=500000 --gas-prices=99999ua0gi -y
```
## Get p2p peer address
```
0gchaind status | jq -r '"\(.NodeInfo.id)@\(.NodeInfo.listen_addr)"'
```
## Edit validator
```
0gchaind tx staking edit-validator --website="<WEBSITE>" --details="<DESCRIPTION>" --new-moniker="<NEW_MONIKER>" --identity="<KEY BASE PREFIX>" --from=$WALLET_NAME --gas=500000 --gas-prices=99999ua0gi -y
```
## Gửi tokens giữa các wallet
```
0gchaind tx bank send $WALLET_NAME <TO_WALLET> <AMOUNT>ua0gi --gas=500000 --gas-prices=99999ua0gi -y
```
## Query wallet balance
```
0gchaind q bank balances $(0gchaind keys show $WALLET_NAME -a)
```
## Kiểm tra server load
```
sudo apt update
sudo apt install htop -y
htop
```
## Query active validators
```
0gchaind q staking validators -o json --limit=1000 \
| jq '.validators[] | select(.status=="BOND_STATUS_BONDED")' \
| jq -r '.tokens + " - " + .description.moniker' \
| sort -gr | nl
```
## Query inactive validators
```
0gchaind q staking validators -o json --limit=1000 \
| jq '.validators[] | select(.status=="BOND_STATUS_UNBONDED")' \
| jq -r '.tokens + " - " + .description.moniker' \
| sort -gr | nl
```
## Check logs của node
```
sudo journalctl -u 0gd -f -o cat
```
## Restart node
```
sudo systemctl restart 0gd
```
## Stop node
```
sudo systemctl stop 0gd
```
## Upgrade node
```
0G_VERSION=<version>

cd $HOME
rm -rf $HOME/0g-chain
git clone -b $0G_VERSION https://github.com/0glabs/0g-chain.git
./0g-chain/networks/testnet/install.sh
source .profile
0gchaind version
# Restart the node
sudo systemctl restart 0gd && sudo journalctl -u 0gd -f -o cat
```
## Delete node 
```
# !!! IF YOU HAVE CREATED A VALIDATOR, MAKE SURE TO BACKUP `priv_validator_key.json` file located in $HOME/.0gchain/config/ 
sudo systemctl stop 0gd
sudo systemctl disable 0gd
sudo rm /etc/systemd/system/0gd.service
rm -rf $HOME/.0gchain $HOME/0g-chain
```
## Ví dụ về cách sử dụng gRPC
```
wget https://github.com/fullstorydev/grpcurl/releases/download/v1.7.0/grpcurl_1.7.0_linux_x86_64.tar.gz
tar -xvf grpcurl_1.7.0_linux_x86_64.tar.gz
chmod +x grpcurl
./grpcurl  -plaintext  localhost:$GRPC_PORT list
### MAKE SURE gRPC is enabled in app.toml
# grep -A 3 "\[grpc\]" /home/og-testnet-validator/.0gchain/config/app.toml
```
## Ví dụ về REST API query
```
curl localhost:$API_PORT/cosmos/staking/v1beta1/validators
### MAKE SURE API is enabled in app.toml
# grep -A 3 "\[api\]" /home/og-testnet-validator/.0gchain/config/app.toml
```
