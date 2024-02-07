#!/bin/bash
declare -A sfile=( [usr]="/etc/VPS-MX/info.user" [instal]="/etc/casitainstal" )
declare -A sruta
			       sruta=(
   [0]="/etc/VPS-MX" [fonts]="//usr/share/figlet" [usr]="/etc/VPS-MX/controlador"
			             )


fuentes=("ansi.flf" "future.tlf")

		(
dpkg --configure -a

for update in `echo 'update upgrade autoremove clean'`; do
	apt-get $update -y &> /dev/null
done

for init in `printf "lolcat toilet figlet pv jq\n"`; do
	apt-get install $init -y &> /dev/null
done

dpkg --configure -a

		) && clear || exit 1


install_inicial(){

	function fun_tit(){
		echo -e "╻  ┏━┓┏━╸┏━┓┏━┓╻╺┳╸┏━┓┏┳┓╻ ╻\n┃  ┣━┫┃  ┣━┫┗━┓┃ ┃ ┣━┫┃┃┃┏╋┛\n┗━╸╹ ╹┗━╸╹ ╹┗━┛╹ ╹ ╹ ╹╹ ╹╹ ╹" | lolcat
	}

	function msg(){
		    BRAN='\033[1;37m' && VERMELHO='\e[31m' && VERDE='\e[32m' && AMARELO='\e[33m' && MORADO='\e[35m'
		    AZUL='\e[34m' && MAGENTA='\e[35m' && MAG='\033[1;36m' && NEGRITO='\e[1m' && SEMCOR='\e[0m'
	      case $1 in
		      -e) echo -e "${NEGRITO}\e[97m$2\e[0m";;
		     -ne) echo -ne "\e[1;30m[\e[1;35m•\e[1;30m] ${MAGENTA}${2} ${VERDE}";read $3;;
		     -be) msg -bar && msg -e "$2";;
		     -nb) msg -bar && msg -ne "$2" $3;;
		    -ama) cor="${AMARELO}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}" ;;
		    -azu) cor="${MAG}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}" ;;
		    -bra) cor="${VERMELHO}" && echo -ne "${cor}${2}${SEMCOR}" ;;
		    -bar) cor="${MORADO}————————————————————————————————————————————————————" && echo -e "${SEMCOR}${cor}${SEMCOR}" ;;
		   -verd) cor="${VERDE}${NEGRITO}" && echo -e "${cor}${2}${SEMCOR}" ;;
		   -verm) cor="${AMARELO}${NEGRITO}[!] ${VERMELHO}" && echo -e "${cor}${2}${SEMCOR}" ;;
	      esac
	}

	function print_center(){
		  if [[ -z $2 ]]; then text="$1" ; else   col="$1"&&text="$2" ; fi
		  while read line; do
		    unset space
		    x=$(( ( 54 - ${#line}) / 2))
		    for (( i = 0; i < $x; i++ )); do space+=' ' ; done
			    space+="$line"
	       if [[ -z $2 ]]; then  msg -ama "$space" ; else msg "$col" "$space"  ; fi
		  done <<< $(echo -e "$text")
	}

	dependencias(){
	        for i in $soft; do
	                leng="${#i}"
	                puntos=$(( 21 - $leng))
	                pts="."
	                for (( a = 0; a < $puntos; a++ )); do
	                        pts+="."
	                done
	                msg -nazu "       instalando $i$(msg -ama "$pts")"
	                if apt install $i -y &>/dev/null ; then
	                        msg -verd "INSTALL"
	                else
	                        msg -verm2 "FAIL"
	                        sleep 2
        	                tput cuu1 && tput dl1
	                        print_center -ama "aplicando fix a $i"
	                        dpkg --configure -a &>/dev/null
	                        sleep 2
	                        tput cuu1 && tput dl1
		                msg -nazu "       instalando $i$(msg -ama "$pts")"
	                        if apt install $i -y &>/dev/null ; then
	                                msg -verd "INSTALL"
        	                else
        	                        msg -verm2 "FAIL"
	                        fi
	                fi
	        done
		        sed -i "s;Listen 80;Listen 81;g" /etc/apache2/ports.conf
		        service apache2 restart > /dev/null 2>&1 &
	}


fun_tit
	[[ ! -e ${sfile[instal]} ]] && {
		msg -bar
		print_center -ama "INICIANDO INSTALACIÓN DE PAQUETES"
		dependencias
		msg -bar
	} || {
		msg -bar
		print_center -ama "ACTUALIZANDO PAQUETES"
		msg -bar
			(
		apt-get update -y
		apt-get upgrade -y
		apt list --upgradable
		apt autoremove
			) && >/dev/null
	}

	read -p $'\e[1;30m	====>> presione enter para continuar <<====' ent

	[[ -e /etc/VPS-MX ]] && rm -rf /etc/VPS-MX
	mkdir -p /etc/VPS-MX/{controlador,tmp,data/}

	for font in ${fuentes[@]}; do
		wget -O /usr/share/figlet/$font 

}

install_inicial
