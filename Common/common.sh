NC="\e[0m"           # no color
CYAN="\e[1m\e[1;96m" # cyan color
RED="\e[1m\e[1;91m" # red color

function printLine {
  echo "---------------------------------------------------------------------------------------"
}

function printCyan {
  echo -e "${CYAN}${1}${NC}"
}

function printRed {
  echo -e "${RED}${1}${NC}"
}

function printHeader {
    printLine
    printCyan "████████╗██╗  ██╗███████╗    ████████╗███████╗ █████╗ ███╗   ███╗"
    printCyan "╚══██╔══╝██║  ██║██╔════╝    ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║"
    printCyan "   ██║   ███████║█████╗         ██║   █████╗  ███████║██╔████╔██║"
    printCyan "   ██║   ╚════██║██╔══╝         ██║   ██╔══╝  ██╔══██║██║╚██╔╝██║"
    printCyan "   ██║        ██║███████╗       ██║   ███████╗██║  ██║██║ ╚═╝ ██║"
    printCyan "   ╚═╝        ╚═╝╚══════╝       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝"
    echo "Docs: https://docs.t4e.xyz"
    echo "Chanel: https://t.me/t4eresearch"
    echo "Github: https://github.com/pot4e"
    printLine && sleep 1
}
