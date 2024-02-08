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

	dependencias(){
		source <(curl -sSL https://raw.githubusercontent.com/rudi9999/Herramientas/main/module/module)
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

clear
fun_tit
	[[ ! -e ${sfile[instal]} ]] && {
		msg -bar
		print_center -ama "INICIANDO INSTALACIÓN DE PAQUETES"
		dependencias
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
	mkdir -p /etc/VPS-MX/{controlador,tmp,data/}

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

	wget -O $HOME/files.tar https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/vpsmx.tar &> /dev/null
	mkdir $HOME/instal
	tar xpf $HOME/files.tar --directory $HOME/instal

	for arqx in `echo "menu protocolos.sh herramientas.sh"`; do
		chmod +rwx $HOME/instal/$arqx
		mv $HOME/instal/$arqx ${sdir[0]}/$arqx
	done

	rm -rf $HOME/instal $HOME/files.tar

	for extras in `curl -sSL https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/files/extras` ; do
		wget -O ${sdir[usr]}/$extras https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/files/$extras &> /dev/null
		chmod +rwx ${sdir[usr]}/$extras
	done
			) && echo -e "\e[1;30mUse los comandos: \e[1;35mmenu VPSMX casitamod menu MENU vpsmx" || echo -e "\e[1;31mINSTALACIÓN ERRÓNEA, REINTENTA NUEVAMENTE"

	rm /bin/menu /bin/VPSMX /bin/casitamod &> /dev/null

	for menu in `echo "/bin/VPSMX /bin/casitamod /bin/menu /bin/MENU /bin/vpsmx"`; do
cat << eof >> $menu
$(echo 'cd /etc/VPS-MX && bash menu')
eof
	chmod 775 $menu
	done

	wget -O /etc/VPS-MX/controlador/usercodes https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/files/usercodes &> /dev/null
	chmod +x /etc/VPS-MX/controlador/*

	wget -O /etc/VPS-MX/menu https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/vpsmx/files/menu &> /dev/null
	chmod +rwx /etc/VPS-MX/menu

	for x in `echo "autodes monitor style verifi"`; do
		wget -O ${sdir[0]}/tmp/$x https://raw.githubusercontent.com/CuervoCool/lacasitamod/main/otros/$x &> /dev/null
		chmod 777 ${sdir[0]}/tmp/$x
	done

	echo 'es' > ${sdir[0]}/idioma
	echo '@drowkid01 | LaCasitaMOD' > /bin/licence

	chmod +x /bin/licence
}

install_inicial
