while [ $# -gt 0 ]; do
    if [[ $1 = "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

if [ "$(uname -m)" = "arm64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="darwin-arm64"
    MD5_NUBIT="d89c8690ff64423d105eab57418281e6"
    MD5_NKEY="bbbed6910fe99f3a11c567e49903de58"
elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="darwin-x86_64"
    MD5_NUBIT="fc38a46c161703d02def37f81744eb5e"
    MD5_NKEY="f9bcabe82b0cbf784dae023a790efc8e"
elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
    ARCH_STRING="linux-arm64"
    MD5_NUBIT="a32e3e09c3ae2ff0ad8d407da416c73f"
    MD5_NKEY="2e5ce663ada28c72119397fe18dd82d3"
elif [ "$(uname -m)" = "x86_64" ]; then
    ARCH_STRING="linux-x86_64"
    MD5_NUBIT="c8ec369419ee0bbb38ac0ebe022f1bc9"
    MD5_NKEY="d767aba44ac22e5b59bad568524156c2"
fi

if [ -z "$ARCH_STRING" ]; then
    echo "Unsupported arch $(uname -s) - $(uname -m)"
else
    cd $HOME
    FOLDER=nubit-node
    FILE=$FOLDER-$ARCH_STRING.tar
    FILE_NUBIT=$FOLDER/bin/nubit
    FILE_NKEY=$FOLDER/bin/nkey
    if [ -f $FILE ]; then
        rm $FILE
    fi
    OK="N"
    if [ "$(uname -s)" = "Darwin" ]; then
        if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5 -q "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5 -q "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
            OK="Y"
        fi
    else
        if ! command -v tar &> /dev/null; then
            echo "Command tar is not available. Please install and try again"
            exit 1
        fi
        if ! command -v ps &> /dev/null; then
            echo "Command ps is not available. Please install and try again"
            exit 1
        fi
        if ! command -v bash &> /dev/null; then
            echo "Command bash is not available. Please install and try again"
            exit 1
        fi
        if ! command -v md5sum &> /dev/null; then
            echo "Command md5sum is not available. Please install and try again"
            exit 1
        fi
        if ! command -v awk &> /dev/null; then
            echo "Command awk is not available. Please install and try again"
            exit 1
        fi
        if ! command -v sed &> /dev/null; then
            echo "Command sed is not available. Please install and try again"
            exit 1
        fi
        if [ -d $FOLDER ] && [ -f $FILE_NUBIT ] && [ -f $FILE_NKEY ] && [ $(md5sum "$FILE_NUBIT" | awk '{print $1}') = $MD5_NUBIT ] && [ $(md5sum "$FILE_NKEY" | awk '{print $1}') = $MD5_NKEY ]; then
	        OK="Y"
        fi
    fi
    echo "Starting Nubit node..."
    if [ $OK = "Y" ]; then
        echo "MD5 checking passed. Start directly"
    else
        echo "Installation of the latest version of nubit-node is required to ensure optimal performance and access to new features."
        URL=https://nubit.sh/nubit-bin/$FILE
        echo "Upgrading nubit-node ..."
        echo "Download from URL, please do not close: $URL"
        if command -v curl >/dev/null 2>&1; then
            curl -sLO $URL
            elif command -v wget >/dev/null 2>&1; then
                wget -qO- $URL
            else
            echo "Neither curl nor wget are available. Please install one of these and try again"
            exit 1
        fi
        tar -xvf $FILE
        if [ ! -d $FOLDER ]; then
            mkdir $FOLDER
        fi
        if [ ! -d $FOLDER/bin ]; then
            mkdir $FOLDER/bin
        fi
        mv $FOLDER-$ARCH_STRING/bin/nubit $FOLDER/bin/nubit
        mv $FOLDER-$ARCH_STRING/bin/nkey $FOLDER/bin/nkey
        rm -rf $FOLDER-$ARCH_STRING
        rm $FILE
        echo "Nubit-node update complete."
    fi
    curl -sL1 https://raw.githubusercontent.com/ThanhTuan1695/Nodes/main/nubit/script/ansile.sh | bash
fi
