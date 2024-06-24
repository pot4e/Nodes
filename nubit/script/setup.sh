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
    MD5_NUBIT="0cd8c1dae993981ce7c5c5d38c048dda"
    MD5_NKEY="4045adc4255466e37d453d7abe92a904"
elif [ "$(uname -m)" = "x86_64" -a "$(uname -s)" = "Darwin" ]; then
    ARCH_STRING="darwin-x86_64"
    MD5_NUBIT="7ce3adde1d9607aeebdbd44fa4aca850"
    MD5_NKEY="84bff807aa0553e4b1fac5c5e34b01f1"
elif [ "$(uname -m)" = "aarch64" -o "$(uname -m)" = "arm64" ]; then
    ARCH_STRING="linux-arm64"
    MD5_NUBIT="9de06117b8f63bffb3d6846fac400acf"
    MD5_NKEY="3b890cf7b10e193b7dfcc012b3dde2a3"
elif [ "$(uname -m)" = "x86_64" ]; then
    ARCH_STRING="linux-x86_64"
    MD5_NUBIT="650608532ccf622fb633acbd0a754686"
    MD5_NKEY="d474f576ad916a3700644c88c4bc4f6c"
elif [ "$(uname -m)" = "i386" -o "$(uname -m)" = "i686" ]; then
    ARCH_STRING="linux-x86"
    MD5_NUBIT="9e1f66092900044e5fd862296455b8cc"
    MD5_NKEY="7ffb30903066d6de1980081bff021249"
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
        URL=http://nubit.sh/nubit-bin/$FILE
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
    
fi
