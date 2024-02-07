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

msgi -bar
dependencias
msgi -bar
mkdir -p /etc/VPS-MX
wget https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx.tar &> /dev/null
tar xpf vpsmx.tar --directory /etc/VPS-MX
rm -rf vpsmx.tar
msgi -bar
msgi -ama "DIGITE: menu"
msgi -bar
cat << eof > /bin/menu
/etc/VPS-MX/menu
eof
msgi -bar
rm $(pwd)/$0

