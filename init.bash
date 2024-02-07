#!/bin/bash
source <(curl -sSL https://raw.githubusercontent.com/NetVPS/LATAM_Oficial/main/Ejecutables/colores)
dpkg --configure -a
apt-get install lolcat pv -y &> /dev/null


dependencias() {
  dpkg --configure -a >/dev/null 2>&1
  apt -f install -y >/dev/null 2>&1
  soft="sudo bsdmainutils zip unzip ufw curl python python3 python3-pip openssl cron iptables lsof pv boxes at mlocate gawk bc jq curl npm nodejs socat netcat netcat-traditional net-tools cowsay figlet lolcat apache2"
  for i in $soft; do
    paquete="$i"
    echo -e "\033[1;97m INSTALANDO PAQUETE \e[93m >>> \e[36m $i"
    barra_intall "apt-get install $i -y"
  done
}
clear
echo -e "╻  ┏━┓┏━╸┏━┓┏━┓╻╺┳╸┏━┓┏┳┓╻ ╻
┃  ┣━┫┃  ┣━┫┗━┓┃ ┃ ┣━┫┃┃┃┏╋┛
┗━╸╹ ╹┗━╸╹ ╹┗━┛╹ ╹ ╹ ╹╹ ╹╹ ╹" | lolcat
msg() {
    BRAN='\033[1;37m' && VERMELHO='\e[31m' && VERDE='\e[32m' && AMARELO='\e[33m' && MORADO='\e[35m'
    AZUL='\e[34m' && MAGENTA='\e[35m' && MAG='\033[1;36m' && NEGRITO='\e[1m' && SEMCOR='\e[0m'
    case $1 in
    -ne) cor="${VERMELHO}${NEGRITO}" && echo -ne "${cor}${2}${SEMCOR}" ;;
    -ama) cor="${AMARELO}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}" ;;
    -verm) cor="${AMARELO}${NEGRITO}[!] ${VERMELHO}" && echo -e "${cor}${2}${SEMCOR}" ;;
    -azu) cor="${MAG}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}" ;;
    -verd) cor="${VERDE}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}" ;;
    -bra) cor="${VERMELHO}" && echo -ne "${cor}${2}${SEMCOR}" ;;
    "-bar2" | "-bar") cor="${MORADO}————————————————————————————————————————————————————" && echo -e "${SEMCOR}${cor}${SEMCOR}" ;;
    esac
}

apt-get install toilet -y &> /dev/null
apt-get install jq &> /dev/null
apt-get install figlet &> /dev/null

wget https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/ansi.flf &> /dev/null
wget https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/future.tlf &> /dev/null

msg -bar
dependencias
msg -bar
mkdir -p /etc/VPS-MX
wget https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx.tar &> /dev/null
tar xpf vpsmx.tar --directory /etc/VPS-MX
rm -rf vpsmx.tar
msg -bar
msg -ama "DIGITE: menu"
msg -bar

wget -O /etc/VPS-MX/menu https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/menu &> /dev/null
chmod +rwx /etc/VPS-MX/menu
[[ -s /etc/VPS-MX/menu ]] && {
        rm /bin/menu &> /dev/null
        echo "cd /etc/VPS-MX && bash menu" > /bin/menu
        chmod +rwx /bin/menu
}

