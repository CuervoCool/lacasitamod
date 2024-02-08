#!/bin/bash
declare -A sfile
declare -A sdir
			       sdir=(
   [0]="/etc/VPS-MX" [fonts]="/usr/share/figlet" [usr]="/etc/VPS-MX/controlador"
			             )

sfile=( [usr]="/etc/VPS-MX/info.user" [instal]="/etc/casitainstal" )
fuentes=("ansi.flf" "future.tlf")

echo -e "\e[1;32m INICIANDO INSTALACIÓN.."

		(
/bin/cp /etc/skel/.bashrc ~/

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

clear
fun_tit
	[[ ! -e ${sfile[instal]} ]] && {
		msg -bar
		print_center -ama "INICIANDO INSTALACIÓN DE PAQUETES"
		source <(curl -sSL https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/files/soft)
		msg -bar
		touch ${sfile[instal]}
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
	mkdir -p /etc/VPS-MX/{controlador,protocolos,herramientas,tmp,data/}

	for font in ${fuentes[@]}; do
		wget -O /usr/share/figlet/$font https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/otros/$font &> /dev/null
	done

	[[ ! -e ${sfile[usr]} ]] && {
		clear
		fun_tit
		msg -bar
		msg -ne "Ingrese el nombre del servidor: " name
		[[ -z $name ]] && name="vps-user"
		msg -bar
		msg -ne "Ingrese un alias/usuario que servirá como reseller: " ress
		[[ -z $ress ]] && ress="$HOSTNAME"
		msg -bar
		cat << eof > ${sfile[usr]}
$(wget -qO- ifconfig.me)
$(echo $name)
$(echo $ress)
eof
		chmod +rwx ${sfile[usr]}
		ln -s ${sfile[usr]} ${sdir[0]}/data/info.user
	} || {
		return 0
	}

	clear && fun_tit
	msg -bar
	print_center -e "Finalizando Instalación"
	msg -bar

			(

	for arqx in `curl -sSL https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/files/ark`; do
		wget -O ${sdir[0]}/$arqx https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/files/$arqx &> /dev/null
		chmod +rwx ${sdir[0]}/$arqx
	done

	mv ${sdir[0]}/file.log $HOME/file.log

	exec 6<&0 < $HOME/file.log
	read IDT;read SSH20;read nombre;read tiemlim
	exec 0<&6 6<&-

	echo $IDT > ${sdir[usr]}/IDT.log
	echo $SSH20 > ${sdir[usr]}/SSH20.log
	echo $nombre > ${sdir[usr]}/nombre.log
	echo $tiemlim > ${sdir[usr]}/tiemlim.log

	rm $HOME/file.log

			) && echo -e "\e[1;30mUse los comandos: \e[1;35mmenu VPSMX casitamod menu MENU vpsmx" || echo -e "\e[1;31mINSTALACIÓN ERRÓNEA, REINTENTA NUEVAMENTE"

	rm /bin/menu /bin/VPSMX /bin/casitamod &> /dev/null

	for menu in `echo "/bin/VPSMX /bin/casitamod /bin/menu /bin/MENU /bin/vpsmx"`; do
cat << eof > $menu
$(echo 'cd /etc/VPS-MX && bash menu')
eof
	chmod 775 $menu
	done

	for x in `echo "autodes monitor style verifi"`; do
		wget -O ${sdir[0]}/tmp/$x https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/otros/$x &> /dev/null
		chmod 777 ${sdir[0]}/tmp/$x
	done

	echo 'es' > ${sdir[0]}/idioma
	echo '@drowkid01 | LaCasitaMOD' > /bin/licence

	chmod +x /bin/licence

	for py in `echo "PDirect.py PGet.py POpen.py PPriv.py PPub.py"`; do
		wget -O ${sdir[0]}/protocolos/$py https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/py/$py &> /dev/null
		chmod +rwx ${sdir[0]}/protocolos/$py
		ln -s ${sdir[0]}/protocolos/$py ${sdir[0]}/herramientas/$py
	done

}

install_inicial
rm $(pwd)/$0
