#!/bin/bash

NETWORK="nubit-alphatestnet-1"
NODE_TYPE="light"
VALIDATOR_IP="validator.nubit-alphatestnet-1.com"
AUTH_TYPE="admin"

export PATH=$HOME/go/bin:$PATH
BINARY="$HOME/nubit-node/bin/nubit"
BINARYNKEY="$HOME/nubit-node/bin/nkey"

# Check if the Nubit light node is already running
if ps -ef | grep -v grep | grep -w "nubit $NODE_TYPE" > /dev/null; then
    echo "--------------------------------------------------------------------------------"
    echo "|  A Nubit light node process is already running.                             |"
    echo "|  Please shut down the existing process before starting a new one.          |"
    echo "--------------------------------------------------------------------------------"
    exit 1
fi

dataPath=$HOME/.nubit-${NODE_TYPE}-${NETWORK}
binPath=$HOME/nubit-node/bin
if [ ! -f $binPath/nubit ] || [ ! -f $binPath/nkey ]; then
    echo "Please run \"curl -sL1 https://nubit.sh | bash\" first!"
    exit 1
fi
cd $HOME/nubit-node
if [ ! -d $dataPath ]; then
    URL=https://nubit.sh/nubit-data/lightnode_data.tgz
    echo "Download light node data from URL: $URL"
    if command -v curl >/dev/null 2>&1; then
        curl -sLO $URL
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- $URL
    else
        echo "Neither curl nor wget are available. Please install one of these and try again."
        exit 1
    fi
    mkdir $dataPath
    echo "Extracting data. PLEASE DO NOT CLOSE!"
    tar -xvf lightnode_data.tgz -C $dataPath
    rm lightnode_data.tgz
    $BINARY $NODE_TYPE init --p2p.network $NETWORK > output.txt
    mnemonic=$(grep -A 1 "MNEMONIC (save this somewhere safe!!!):" output.txt | tail -n 1)
    echo $mnemonic > mnemonic.txt
    cat output.txt
    rm output.txt
fi

sleep 1
$HOME/nubit-node/bin/nkey list --p2p.network $NETWORK --node.type $NODE_TYPE > output.txt
publicKey=$(sed -n 's/.*"key":"\([^"]*\)".*/\1/p' output.txt)
echo "** PUBKEY **"
echo $publicKey
echo ""
echo "$publicKey" > "$HOME/nubit-node/public_key.txt"
rm output.txt

export AUTH_TYPE
echo "** AUTH KEY **"
$BINARY $NODE_TYPE auth $AUTH_TYPE --node.store $dataPath
echo ""
sleep 5

chmod a+x $BINARY
chmod a+x $BINARYNKEY
$BINARY $NODE_TYPE start --p2p.network $NETWORK --core.ip $VALIDATOR_IP --metrics.endpoint otel.nubit-alphatestnet-1.com:4318 --rpc.skip-auth
