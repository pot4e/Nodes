#!/bin/bash

# Configuration Variables
NETWORK="nubit-alphatestnet-1"
NODE_TYPE="light"
VALIDATOR_IP="validator.nubit-alphatestnet-1.com"
AUTH_TYPE="admin"

export PATH=$HOME/go/bin:$PATH
export BINARY="$HOME/nubit-node/bin/nubit"
export BINARYNKEY="$HOME/nubit-node/bin/nkey"
export CONFIG_FILE="$HOME/.nubit-${NODE_TYPE}-${NETWORK}/config.toml"  # Đường dẫn tới file cấu hình

# Set default walletName if not provided by user
walletName="my_nubit_key"

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

dataPath=$HOME/.nubit-${NODE_TYPE}-${NETWORK}
binPath=$HOME/nubit-node/bin

# Check for the required binaries
if [ ! -f $binPath/nubit ] || [ ! -f $binPath/nkey ]; then
    echo "Please run \"curl -sL1 https://nubit.sh | bash\" first!"
    exit 1
fi

cd $HOME/nubit-node
prompt_for_input() {
    local prompt_message="$1"
    local input_variable_name="$2"
    local is_secure="${3:-0}"  # Optional third parameter to handle secure input

    if [ -t 0 ]; then
        # stdin is connected to a terminal
        if [ "$is_secure" -eq 1 ]; then
            # Secure input (e.g., mnemonic, passwords)
            read -s -r -p "$prompt_message" "$input_variable_name"
            echo ""  # New line after secure input
        else
            read -r -p "$prompt_message" "$input_variable_name"
        fi
    else
        # stdin is not connected to a terminal, use /dev/tty
        if [ "$is_secure" -eq 1 ]; then
            read -s -r -p "$prompt_message" "$input_variable_name" < /dev/tty
            echo ""  # New line after secure input
        else
            read -r -p "$prompt_message" "$input_variable_name" < /dev/tty
        fi
    fi
}

# Prompt the user for input on whether they have an existing mnemonic
prompt_for_input "Do you have an existing mnemonic to use? (yes/no): " hasMnemonic


if [ "$hasMnemonic" == "yes" ]; then
    echo "Using default wallet name: $walletName"
    prompt_for_input "Enter your mnemonic: " mnemonic 1
    echo ""  # New line for clean output after mnemonic prompt
    echo "Your mnemonic: $mnemonic"  
    # Use the provided mnemonic to add the key using nkey command
    echo "Importing the provided mnemonic..."
    echo $mnemonic | $BINARYNKEY add $walletName --recover --keyring-backend test --node.type $NODE_TYPE --p2p.network $NETWORK
    
    # Save the mnemonic for future reference (optional)
    echo $mnemonic > $HOME/nubit-node/your_imported_wallet_mnemonic.txt
    
    # Proceed with the default setup
    if [ ! -d $dataPath ]; then
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
    fi
            
    echo "Initializing node..."
    $BINARY $NODE_TYPE init --p2p.network $NETWORK > output.txt
    cat output.txt
else
    # Proceed with the default setup
    if [ ! -d $dataPath ]; then
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
        
        echo "Initializing node..."
        $BINARY $NODE_TYPE init --p2p.network $NETWORK > output.txt
        mnemonic=$(grep -A 1 "MNEMONIC (save this somewhere safe!!!):" output.txt | tail -n 1)
        echo $mnemonic > $dataPath/mnemonic.txt
        cat output.txt
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
echo $publicKey > $dataPath/public_key.txt
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