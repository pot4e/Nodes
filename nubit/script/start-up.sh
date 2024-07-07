#!/bin/bash

# =====================
# Configuration Variables
# =====================
NETWORK="nubit-alphatestnet-1"
NODE_TYPE="light"
VALIDATOR_IP="validator.nubit-alphatestnet-1.com"
AUTH_TYPE="admin"

export PATH=$HOME/go/bin:$PATH
export BINARY="$HOME/nubit-node/bin/nubit"
export BINARYNKEY="$HOME/nubit-node/bin/nkey"
export CONFIG_FILE="$HOME/.nubit-${NODE_TYPE}-${NETWORK}/config.toml"  # Path to configuration file

# Default wallet name if not provided by the user
walletName="my_nubit_key"

# =====================
# Utility Functions
# =====================

# Function to prompt for input, handling interactive and non-interactive modes
prompt_for_input() {
    local prompt_message="$1"
    local input_variable_name="$2"
    local is_secure="${3:-0}"  # Optional third parameter to handle secure input (default is non-secure)

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

# Function to download and extract node data
download_and_extract_data() {
    local url="https://nubit.sh/nubit-data/lightnode_data.tgz"
    echo "Downloading light node data from URL: $url"
    if command -v curl >/dev/null 2>&1; then
        curl -sLO $url
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- $url
    else
        echo "Neither curl nor wget are available. Please install one of these and try again."
        exit 1
    fi

    mkdir -p "$dataPath"
    echo "Extracting data. PLEASE DO NOT CLOSE!"
    tar -xvf lightnode_data.tgz -C "$dataPath"
    rm lightnode_data.tgz
}

# =====================
# Pre-checks and Validations
# =====================

# Check if the Nubit light node is already running
if ps -ef | grep -v grep | grep -w "nubit $NODE_TYPE" > /dev/null; then
    echo "--------------------------------------------------------------------------------"
    echo "|  A Nubit light node process is already running.                             |"
    echo "|  Please shut down the existing process before starting a new one.          |"
    echo "--------------------------------------------------------------------------------"
    exit 1
fi

# Define paths
dataPath="$HOME/.nubit-${NODE_TYPE}-${NETWORK}"
binPath="$HOME/nubit-node/bin"

# Check for the required binaries
if [ ! -f "$binPath/nubit" ] || [ ! -f "$binPath/nkey" ]; then
    echo "Required binaries not found. Please run \"curl -sL1 https://nubit.sh | bash\" first!"
    exit 1
fi

# Ensure data directory exists and is populated
download_and_extract_data

# =====================
# Node Setup and Initialization
# =====================

# Prompt the user for input on whether they have an existing mnemonic
prompt_for_input "Do you have an existing mnemonic to use? (yes/no): " hasMnemonic

if [ "$hasMnemonic" == "yes" ]; then
    echo "Using default wallet name: $walletName"
    # Prompt for the mnemonic securely
    prompt_for_input "Enter your mnemonic: " mnemonic 1
    echo "Importing the provided mnemonic..."

    # Use the provided mnemonic to add the key using nkey command
    echo "$mnemonic" | $BINARYNKEY add "$walletName" --recover --keyring-backend test --node.type $NODE_TYPE --p2p.network $NETWORK

    # Save the mnemonic for future reference (optional)
    echo "$mnemonic" > "$HOME/nubit-node/your_imported_wallet_mnemonic.txt"

    echo "Initializing node..."
    $BINARY $NODE_TYPE init --p2p.network $NETWORK > output.txt
    cat output.txt

else
    echo "User does not have a mnemonic. Proceeding with default setup."

    echo "Initializing node..."
    $BINARY $NODE_TYPE init --p2p.network $NETWORK > output.txt
    mnemonic=$(grep -A 1 "MNEMONIC (save this somewhere safe!!!):" output.txt | tail -n 1)
    echo "$mnemonic" > "$HOME/nubit-node/mnemonic.txt"
    cat output.txt
    rm output.txt
fi

# =====================
# Post-Setup Operations
# =====================

# Retrieve and display the public key
sleep 1
$BINARYNKEY list --p2p.network $NETWORK --node.type $NODE_TYPE > output.txt
publicKey=$(sed -n 's/.*"key":"\([^"]*\)".*/\1/p' output.txt)
echo "** PUBKEY **"
echo "$publicKey"
echo "$publicKey" > "$HOME/nubit-node/public_key.txt"
rm output.txt

# Perform authentication and start the node
export AUTH_TYPE
echo "** AUTH KEY **"
$BINARY $NODE_TYPE auth $AUTH_TYPE --node.store $dataPath
echo ""
sleep 5

chmod a+x $BINARY
chmod a+x $BINARYNKEY
$BINARY $NODE_TYPE start --p2p.network $NETWORK --core.ip $VALIDATOR_IP --metrics.endpoint otel.nubit-alphatestnet-1.com:4318 --rpc.skip-auth