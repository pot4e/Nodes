# pull new binaries
cd ~/viper-binaries
sudo git pull
# update new binary
sudo systemctl stop viper
sudo cp ~/viper-binaries/viper_linux_amd64 /usr/local/bin/viper

# remove data
cd ~/.viper
rm -rf data
rm -rf viper_evidence.db
rm -rf viper_result.db

sudo git clone https://github.com/vishruthsk/data.git data
cd config

echo $(viper util print-configs) | jq '.tendermint_config.P2P.PersistentPeers = "859674aa64c0ee20ebce8a50e69390698750a65f@mynode1.testnet.vipernet.xyz:26656,eec6c84a7ededa6ee2fa25e3da3ff821d965f94d@mynode2.testnet.vipernet.xyz:26656,81f4c53ccbb36e190f4fc5220727e25c3186bfeb@mynode3.testnet.vipernet.xyz:26656,d53f620caab13785d9db01515b01d6f21ab26d54@mynode4.testnet.vipernet.xyz:26656,e2b1dc002270c8883abad96520a2fe5982cb3013@mynode5.testnet.vipernet.xyz:26656"' | jq . > ~/.viper/config/configuration.json
cat ~/.viper/config/configuration.json
rm addrbook.json
sudo systemctl start viper
sudo systemctl status viper
