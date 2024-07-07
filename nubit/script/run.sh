#!/bin/bash

# Step 1: Download the scripts

# Download clean.sh
curl -O https://raw.githubusercontent.com/ThanhTuan1695/Nodes/main/nubit/script/clean.sh
if [ $? -ne 0 ]; then
  echo "Failed to download clean.sh"
  exit 1
fi

# Download setup.sh
curl -O https://raw.githubusercontent.com/ThanhTuan1695/Nodes/main/nubit/script/setup.sh
if [ $? -ne 0 ]; then
  echo "Failed to download setup.sh"
  exit 1
fi

# Download start-up.sh
curl -O https://raw.githubusercontent.com/ThanhTuan1695/Nodes/main/nubit/script/start-up.sh
if [ $? -ne 0 ]; then
  echo "Failed to download start-up.sh"
  exit 1
fi

# Step 2: Set execute permissions

chmod +x clean.sh
chmod +x setup.sh
chmod +x start-up.sh

# Step 3: Run the scripts in sequence

./clean.sh
if [ $? -ne 0 ]; then
  echo "clean.sh failed"
  exit 1
fi

./setup.sh
if [ $? -ne 0 ]; then
  echo "setup.sh failed"
  exit 1
fi

./start-up.sh
if [ $? -ne 0 ]; then
  echo "start-up.sh failed"
  exit 1
fi

echo "All scripts executed successfully."
