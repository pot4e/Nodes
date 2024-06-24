#!/bin/bash

# Configuration Variables
NETWORK="nubit-alphatestnet-1"
NODE_TYPE="light"
VALIDATOR_IP="validator.nubit-alphatestnet-1.com"
AUTH_TYPE="admin"
DEFAULT_WALLET_NAME="my_nubit_key"

export PATH=$HOME/go/bin:$PATH
export BINARY="$HOME/nubit-node/bin/nubit"
export BINARYNKEY="$HOME/nubit-node/bin/nkey"
export CONFIG_FILE="$HOME/.nubit-${NODE_TYPE}-${NETWORK}/config.toml"  # Đường dẫn tới file cấu hình

# Define paths
dataPath=$HOME/.nubit-${NODE_TYPE}-${NETWORK}
binPath=$HOME/nubit-node/bin

# Check if the Nubit light node is already running
if ps -ef | grep -v grep | grep -w "nubit $NODE_TYPE" > /dev/null; then
    echo "--------------------------------------------------------------------------------"
    echo "|  There is already a Nubit light node process running in your environment.   |"
    echo "|  The startup process has been stopped. To shut down the running process,    |"
    echo "|  please:                                                                    |"
    echo "|      Close the window/tab where it's running, or                            |"
    echo "|      Go to the exact window/tab and press Ctrl + C (Linux) or Command + C   |"
    echo "|      (MacOS)                                                                |"
    echo "--------------------------------------------------------------------------------"
    exit 1
fi

# Check for the required binaries
if [ ! -f $binPath/nubit ] || [ ! -f $binPath/nkey ]; then
    echo "Please run \"curl -sL1 https://nubit.sh | bash\" first!"
    exit 1
fi

# Ensure the nubit-node directory exists and navigate to it
cd $HOME/nubit-node || exit

# Function to download and extract node data
download_and_extract_data() {
    URL=https://nubit.sh/nubit-data/lightnode_data.tgz
    echo "Downloading light node data from URL: $URL"
    if command -v curl >/dev/null 2>&1; then
        curl -sLO $URL
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- $URL
    else
        echo "Neither curl nor wget are available. Please install one of these and try again."
        exit 1
    fi

    mkdir -p $dataPath
    echo "Extracting data. PLEASE DO NOT CLOSE!"
    tar -xvf lightnode_data.tgz -C $dataPath
    rm lightnode_data.tgz
}

# Function to initialize the node
initialize_node() {
    echo "Initializing node..."
    $BINARY $NODE_TYPE init --p2p.network $NETWORK > output.txt
    cat output.txt
}

# Main process
read -p "Do you have an existing mnemonic to use? (yes/no): " hasMnemonic

if [ "$hasMnemonic" == "yes" ]; then
    echo "Using default wallet name: $DEFAULT_WALLET_NAME"
    echo "Enter your mnemonic: "
    read -r mnemonic
    echo ""  # New line for clean output

    # Import the provided mnemonic
    echo "Importing the provided mnemonic..."
    echo $mnemonic | $BINARYNKEY add $DEFAULT_WALLET_NAME --recover --keyring-backend test --node.type $NODE_TYPE --p2p.network $NETWORK
    
    # Save the mnemonic for future reference
    mkdir -p $dataPath
    echo $mnemonic > $dataPath/your_imported_wallet_mnemonic.txt

    # Download and initialize if necessary
    if [ ! -d $dataPath ]; then
        download_and_extract_data
    fi

    initialize_node
else
    # Proceed with downloading and initializing the node
    if [ ! -d $dataPath ]; then
        download_and_extract_data
        initialize_node

        # Extract and save the generated mnemonic
        mnemonic=$(grep -A 1 "MNEMONIC (save this somewhere safe!!!):" output.txt | tail -n 1)
        echo "Generated mnemonic: $mnemonic"
        echo $mnemonic > $dataPath/mnemonic.txt
        rm output.txt
    fi
fi

# Retrieve and display the public key
sleep 1
$BINARYNKEY list --p2p.network $NETWORK --node.type $NODE_TYPE > output.txt
publicKey=$(sed -n 's/.*"key":"\([^"]*\)".*/\1/p' output.txt)
echo "** PUBKEY **"
echo $publicKey
echo ""
rm output.txt

# Perform authentication and start the node
export AUTH_TYPE
echo "** AUTH KEY **"
$BINARY $NODE_TYPE auth $AUTH_TYPE --node.store $dataPath
echo ""
sleep 5

chmod a+x $BINARY
chmod a+x $BINARYNKEY
$BINARY $NODE_TYPE start --p2p.network $NETWORK --core.ip $VALIDATOR_IP --metrics.endpoint otel.nubit-alphatestnet-1.com:4318