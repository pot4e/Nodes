# pull new binaries
cd ~/viper-binaries
sudo git pull

# update new binary
sudo systemctl stop viper
sudo cp ~/viper-binaries/viper_linux_amd64 /usr/local/bin/viper

# remove data
cd ~/.viper
rm -rf data

# download data
sudo git clone https://github.com/vishruthsk/data.git data
sudo chown -R viper ~/.viper/data

# start service
sudo systemctl start viper
sudo systemctl status viper
