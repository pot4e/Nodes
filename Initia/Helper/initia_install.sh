#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/batuoc263/T4E-Nodes/main/Common/common.sh)

printHeader

read -r -p "Enter node name: " MONIKER

echo -e "T4E recommends getting the snapshot link at bwarelabs."
echo -e "URL: ${CYAN}https://bwarelabs.com/snapshots/initia${NC}"
read -r -p "Paste snapshot url: " SNAPSHOT_URL

CHAIN_ID="initiation-1"
BINARY_NAME="initiad"
BINARY_VERSION_TAG="v0.2.14"

echo -e "Node moniker: ${CYAN}$MONIKER${NC}"
echo -e "Chain id:     ${CYAN}$CHAIN_ID${NC}"
echo -e "Binary version tag:  ${CYAN}$BINARY_VERSION_TAG${NC}"

sleep 1

printCyan "1. Updating packages and dependencies" && sleep 1
#UPDATE APT
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop lz4 screen unzip bc fail2ban htop -y

printCyan "2. Installing GO" && sleep 1
#INSTALL GO
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.2.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile

printCyan "3. Downloading and building binaries" && sleep 1

# Clone project repository
cd $HOME
rm -rf initia
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.14

# Build binaries
make build

# Prepare binaries for Cosmovisor
mkdir -p $HOME/.initia/cosmovisor/genesis/bin
mv build/initiad $HOME/.initia/cosmovisor/genesis/bin/
rm -rf build

# Create application symlinks
sudo ln -s $HOME/.initia/cosmovisor/genesis $HOME/.initia/cosmovisor/current -f
sudo ln -s $HOME/.initia/cosmovisor/current/bin/initiad /usr/local/bin/initiad -f

printCyan "4. Install Cosmovisor and Create a service" && sleep 1

# Download and install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.5.0

# Create service
sudo tee /etc/systemd/system/initia.service > /dev/null << EOF
[Unit]
Description=initia node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.initia"
Environment="DAEMON_NAME=initiad"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.initia/cosmovisor/current/bin"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable initia.service

printCyan "5. Initialize the node" && sleep 1

initiad config chain-id $CHAIN_ID
initiad config set client keyring-backend test
initiad config set client node tcp://localhost:26657
initiad init "$MONIKER" --chain-id $CHAIN_ID

curl -Ls https://raw.githubusercontent.com/initia-labs/networks/main/initiation-1/genesis.json > $HOME/.initia/config/genesis.json
curl -Ls https://snapshots.nodes.guru/initia/addrbook.json > $HOME/.initia/config/addrbook.json

PEERS="40d3f977d97d3c02bd5835070cc139f289e774da@168.119.10.134:26313,841c6a4b2a3d5d59bb116cc549565c8a16b7fae1@23.88.49.233:26656,e6a35b95ec73e511ef352085cb300e257536e075@37.252.186.213:26656,2a574706e4a1eba0e5e46733c232849778faf93b@84.247.137.184:53456,ff9dbc6bb53227ef94dc75ab1ddcaeb2404e1b0b@178.170.47.171:26656,edcc2c7098c42ee348e50ac2242ff897f51405e9@65.109.34.205:36656,07632ab562028c3394ee8e78823069bfc8de7b4c@37.27.52.25:19656,028999a1696b45863ff84df12ebf2aebc5d40c2d@37.27.48.77:26656,140c332230ac19f118e5882deaf00906a1dba467@185.219.142.119:53456,1f6633bc18eb06b6c0cab97d72c585a6d7a207bc@65.109.59.22:25756,065f64fab28cb0d06a7841887d5b469ec58a0116@84.247.137.200:53456,767fdcfdb0998209834b929c59a2b57d474cc496@207.148.114.112:26656,093e1b89a498b6a8760ad2188fbda30a05e4f300@35.240.207.217:26656,12526b1e95e7ef07a3eb874465662885a586e095@95.216.78.111:26656"
SEEDS="2eaa272622d1ba6796100ab39f58c75d458b9dbc@34.142.181.82:26656,c28827cb96c14c905b127b92065a3fb4cd77d7f6@testnet-seeds.whispernode.com:25756"

sed -i.bak -e "s/^seeds *=.*/seeds = \"${SEEDS}\"/" $HOME/.initia/config/config.toml
sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.initia/config/config.toml

sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.initia/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.15uinit,0.01uusdc"|g' $HOME/.initia/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.initia/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.initia/config/config.toml
sed -i 's|^prometheus *=.*|prometheus = true|' $HOME/.initia/config/config.toml


initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book

curl -o - -L $SNAPSHOT_URL | lz4 -c -d - | tar -x -C $HOME/.initia

sudo systemctl start initia

echo '=============== SETUP FINISHED ==================='
echo -e "Check logs:"
printCyan "sudo journalctl -u $BINARY_NAME -f --no-hostname -o cat"
echo -e "Check synchronization:"
printCyan "$BINARY_NAME status 2>&1 | jq .SyncInfo.catching_up"
