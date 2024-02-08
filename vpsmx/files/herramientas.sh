#!/bin/bash

declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )


function _CrearDemo(){
rm -rf ${sdir[0]}/demo-ssh 2>/dev/null
mkdir ${sdir[0]}/demo-ssh 2>/dev/null

tmpusr () {
time="$1"
timer=$(( $time * 60 ))
timer2="'$timer's"
echo "#!/bin/bash
sleep $timer2
kill"' $(ps -u '"$2 |awk '{print"' $1'"}') 1> /dev/null 2> /dev/null
userdel --force $2
rm -rf /tmp/$2
exit" > /tmp/$2
}

tmpusr2 () {
time="$1"
timer=$(( $time * 60 ))
timer2="'$timer's"
echo "#!/bin/bash
sleep $timer2
kill=$(dropb | grep "$2" | awk '{print $2}')
kill $kill
userdel --force $2
rm -rf /tmp/$2
exit" > /tmp/$2
}
echo  -e "$()$(msg -bar) " 
msg -ama "        CREAR USUARIO POR TIEMPO (Minutos)"
msg -bar
echo -e "\033[1;97m Los Usuarios que cres en esta opcion se eliminaran\n automaticamete pasando el tiempo designado.\033[0m"
msg -bar

echo -e "\033[1;91m [1]-\033[1;97mNombre del usuario:\033[0;37m"; read -p " " name
if [[ -z $name ]]; then
echo "No a digitado el Nuevo Usuario"
exit
fi
if cat $prefix/passwd |grep $name: |grep -vi [a-z]$name |grep -v [0-9]$name > /dev/null; then
echo -e "\033[1;31mUsuario $name ya existe\033[0m"
exit
fi
echo -e "\033[1;91m [2]-\033[1;97mContraseña para usuario $name:\033[0;37m"; read -p " " pass
echo -e "\033[1;91m [3]-\033[1;97mTiempo de Duración En Minutos:\033[0;37m"; read -p " " tmp
if [ "$tmp" = "" ]; then
tmp="30"
echo -e "\033[1;32mFue Definido 30 minutos Por Defecto!\033[0m"
msg -bar
sleep 2s
fi
#useradd -M -s /bin/false $name
#(echo $pass; echo $pass)|passwd $name 2>/dev/null
useradd -M -s /bin/false -p $(openssl passwd -1 $pass) -c sshm,$pass $name
touch /tmp/$name
tmpusr $tmp $name
chmod 777 /tmp/$name
touch /tmp/cmd
chmod 777 /tmp/cmd
echo "nohup /tmp/$name & >/dev/null" > /tmp/cmd
/tmp/cmd 2>/dev/null 1>/dev/null
rm -rf /tmp/cmd
touch ${sdir[0]}/demo-ssh/$name
echo "senha: $pass" >> ${sdir[0]}/demo-ssh/$name
echo "data: ($tmp)Minutos" >> ${sdir[0]}/demo-ssh/$name
msg -bar2
echo -e "\033[1;93m ¡¡ USUARIO TEMPORAL x MINUTOS !!\033[0m"
msg -bar2
echo -e "\033[1;36m  >> IP del Servidor: \033[0m$(meu_ip) " 
echo -e "\033[1;36m  >> Usuario: \033[0m$name"
echo -e "\033[1;36m  >> Contraseña: \033[0m$pass"
echo -e "\033[1;36m  >> Minutos de Duración: \033[0m$tmp"
msg -bar2
msg -ne " Enter Para Continuar" && read enter
${sdir[usr]}/usercodes
}

function _apacheon(){
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" )
echo -e "\033[1;96m           Gestor de Archivos FTP VPS•MX"
msg -bar
echo -e "${cor[4]} [1] >${cor[3]} $(fun_trans "Colocar Archivo Online")"
echo -e "${cor[4]} [2] >${cor[3]} $(fun_trans "Remover Archivo Online")"
echo -e "${cor[4]} [3] >${cor[3]} $(fun_trans "Ver Links de Archivos Online")"
msg -bar
while [[ ${arquivoonlineadm} != @([1-3]) ]]; do
read -p "[1-3]: " arquivoonlineadm
tput cuu1 && tput dl1
done
case ${arquivoonlineadm} in
3)
[[ -z $(ls /var/www/html) ]] && echo -e "$barra"  || {
    for my_arqs in `ls /var/www/html`; do
    [[ "$my_arqs" = "index.html" ]] && continue
    [[ "$my_arqs" = "index.php" ]] && continue
    [[ -d "$my_arqs" ]] && continue
    echo -e "\033[1;31m[$my_arqs] \033[1;36mhttp://$IP:81/$my_arqs\033[0m"
    done
    msg -bar
    }
;;
2)
i=1
[[ -z $(ls /var/www/html) ]] && echo -e "$barra"  || {
    for my_arqs in `ls /var/www/html`; do
    [[ "$my_arqs" = "index.html" ]] && continue
    [[ "$my_arqs" = "index.php" ]] && continue
    [[ -d "$my_arqs" ]] && continue
    select_arc[$i]="$my_arqs"
    echo -e "${cor[2]}[$i] > ${cor[3]}$my_arqs - \033[1;36mhttp://$IP:81/$my_arqs\033[0m"
    let i++
    done
    msg -bar
    echo -e "${cor[5]}$(fun_trans "Seleccione el archivo que desea borrar")"
    msg -bar
    while [[ -z ${select_arc[$slct]} ]]; do
    read -p " [1-$i]: " slct
    tput cuu1 && tput dl1
    done
    arquivo_move="${select_arc[$slct]}"
    [[ -d /var/www/html ]] && [[ -e /var/www/html/$arquivo_move ]] && rm -rf /var/www/html/$arquivo_move > /dev/null 2>&1
    [[ -e /var/www/$arquivo_move ]] && rm -rf /var/www/$arquivo_move > /dev/null 2>&1
    echo -e "${cor[5]}$(fun_trans "Exito!")"
    msg -bar
    }
;;    
1)
i="1"
[[ -z $(ls $HOME) ]] && echo -e "$barra"  || {
    for my_arqs in `ls $HOME`; do
    [[ -d "$my_arqs" ]] && continue
    select_arc[$i]="$my_arqs"
    echo -e "${cor[2]} [$i] > ${cor[3]}$my_arqs"
    let i++
    done
    i=$(($i - 1))
	msg -bar
    echo -e "${cor[5]}$(fun_trans "Seleccione el archivo")"
    msg -bar
    while [[ -z ${select_arc[$slct]} ]]; do
    read -p " [1-$i]: " slct
    tput cuu1 && tput dl1
    done
    arquivo_move="${select_arc[$slct]}"
    [ ! -d /var ] && mkdir /var
    [ ! -d /var/www ] && mkdir /var/www
    [ ! -d /var/www/html ] && mkdir /var/www/html
    [ ! -e /var/www/html/index.html ] && touch /var/www/html/index.html
    [ ! -e /var/www/index.html ] && touch /var/www/index.html
    chmod -R 755 /var/www
    cp $HOME/$arquivo_move /var/www/$arquivo_move
    cp $HOME/$arquivo_move /var/www/html/$arquivo_move
    echo -e "\033[1;36m http://$IP:81/$arquivo_move\033[0m"
    msg -bar
    echo -e "${cor[5]}$(fun_trans "Exito!")"
     msg -bar
    }
;;
esac
}

function _blockBT(){

sh_ver="1.0.11"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Informacion]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"

smtp_port="25,26,465,587"
pop3_port="109,110,995"
imap_port="143,218,220,993"
other_port="24,50,57,105,106,158,209,1109,24554,60177,60179"
bt_key_word="torrent
.torrent
peer_id=
announce
info_hash
get_peers
find_node
BitTorrent
announce_peer
BitTorrent protocol
announce.php?passkey=
magnet:
xunlei
sandai
Thunder
XLLiveUD"

check_sys(){
	if [[ -f $prefix/redhat-release ]]; then
		release="centos"
	elif cat $prefix/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat $prefix/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat $prefix/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_BT(){
	Cat_KEY_WORDS
	BT_KEY_WORDS=$(echo -e "$Ban_KEY_WORDS_list"|grep "torrent")
}
check_SPAM(){
	Cat_PORT
	SPAM_PORT=$(echo -e "$Ban_PORT_list"|grep "${smtp_port}")
}
Cat_PORT(){
	Ban_PORT_list=$(iptables -t filter -L OUTPUT -nvx --line-numbers|grep "REJECT"|awk '{print $13}')
}
Cat_KEY_WORDS(){
	Ban_KEY_WORDS_list=""
	Ban_KEY_WORDS_v6_list=""
	if [[ ! -z ${v6iptables} ]]; then
		Ban_KEY_WORDS_v6_text=$(${v6iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
		Ban_KEY_WORDS_v6_list=$(echo -e "${Ban_KEY_WORDS_v6_text}"|sed -r 's/.*\"(.+)\".*/\1/')
	fi
	Ban_KEY_WORDS_text=$(${v4iptables} -t mangle -L OUTPUT -nvx --line-numbers|grep "DROP")
	Ban_KEY_WORDS_list=$(echo -e "${Ban_KEY_WORDS_text}"|sed -r 's/.*\"(.+)\".*/\1/')
}
View_PORT(){
	Cat_PORT
	echo -e "========${Red_background_prefix} Puerto Bloqueado Actualmente ${Font_color_suffix}========="
	echo -e "$Ban_PORT_list" && echo && echo -e "==============================================="
}
View_KEY_WORDS(){
	Cat_KEY_WORDS
	echo -e "============${Red_background_prefix} Actualmente Prohibido ${Font_color_suffix}============"
	echo -e "$Ban_KEY_WORDS_list" && echo -e "==============================================="
}
View_ALL(){
	echo
	View_PORT
	View_KEY_WORDS
	echo
	msg -bar2
}
Save_iptables_v4_v6(){
	if [[ ${release} == "centos" ]]; then
		if [[ ! -z "$v6iptables" ]]; then
			service ip6tables save
			chkconfig --level 2345 ip6tables on
		fi
		service iptables save
		chkconfig --level 2345 iptables on
	else
		if [[ ! -z "$v6iptables" ]]; then
			ip6tables-save > $prefix/ip6tables.up.rules
			echo -e "#!/bin/bash\n/sbin/iptables-restore < $prefix/iptables.up.rules\n/sbin/ip6tables-restore < $prefix/ip6tables.up.rules" > $prefix/network/if-pre-up.d/iptables
		else
			echo -e "#!/bin/bash\n/sbin/iptables-restore < $prefix/iptables.up.rules" > $prefix/network/if-pre-up.d/iptables
		fi
		iptables-save > $prefix/iptables.up.rules
		chmod +x $prefix/network/if-pre-up.d/iptables
	fi
}
Set_key_word() { $1 -t mangle -$3 OUTPUT -m string --string "$2" --algo bm --to 65535 -j DROP; }
Set_tcp_port() {
	[[ "$1" = "$v4iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with icmp-port-unreachable
	[[ "$1" = "$v6iptables" ]] && $1 -t filter -$3 OUTPUT -p tcp -m multiport --dports "$2" -m state --state NEW,ESTABLISHED -j REJECT --reject-with tcp-reset
}
Set_udp_port() { $1 -t filter -$3 OUTPUT -p udp -m multiport --dports "$2" -j DROP; }
Set_SPAM_Code_v4(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
		do
		Set_tcp_port $v4iptables "$i" $s
		Set_udp_port $v4iptables "$i" $s
	done
}
Set_SPAM_Code_v4_v6(){
	for i in ${smtp_port} ${pop3_port} ${imap_port} ${other_port}
	do
		for j in $v4iptables $v6iptables
		do
			Set_tcp_port $j "$i" $s
			Set_udp_port $j "$i" $s
		done
	done
}
Set_PORT(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
		Set_tcp_port $v6iptables $PORT $s
		Set_udp_port $v6iptables $PORT $s
	elif [[ -n "$v4iptables" ]]; then
		Set_tcp_port $v4iptables $PORT $s
		Set_udp_port $v4iptables $PORT $s
	fi
	Save_iptables_v4_v6
}
Set_KEY_WORDS(){
	key_word_num=$(echo -e "${key_word}"|wc -l)
	for((integer = 1; integer <= ${key_word_num}; integer++))
		do
			i=$(echo -e "${key_word}"|sed -n "${integer}p")
			Set_key_word $v4iptables "$i" $s
			[[ ! -z "$v6iptables" ]] && Set_key_word $v6iptables "$i" $s
	done
	Save_iptables_v4_v6
}
Set_BT(){
	key_word=${bt_key_word}
	Set_KEY_WORDS
	Save_iptables_v4_v6
}
Set_SPAM(){
	if [[ -n "$v4iptables" ]] && [[ -n "$v6iptables" ]]; then
		Set_SPAM_Code_v4_v6
	elif [[ -n "$v4iptables" ]]; then
		Set_SPAM_Code_v4
	fi
	Save_iptables_v4_v6
}
Set_ALL(){
	Set_BT
	Set_SPAM
}
Ban_BT(){
	check_BT
	[[ ! -z ${BT_KEY_WORDS} ]] && echo -e "${Error} Torrent bloqueados y Palabras Claves, no es\nnecesario volver a prohibirlas !" && msg -bar2 && exit 0
	s="A"
	Set_BT
	View_ALL
	echo -e "${Info} Torrent bloqueados y Palabras Claves !"
	msg -bar2
}
Ban_SPAM(){
	check_SPAM
	[[ ! -z ${SPAM_PORT} ]] && echo -e "${Error} Se detectó un puerto SPAM bloqueado, no es\nnecesario volver a bloquear !" && msg -bar2 && exit 0
	s="A"
	Set_SPAM
	View_ALL
	echo -e "${Info} Puertos SPAM Bloqueados !"
	msg -bar2
}
Ban_ALL(){
	check_BT
	check_SPAM
	s="A"
	if [[ -z ${BT_KEY_WORDS} ]]; then
		if [[ -z ${SPAM_PORT} ]]; then
			Set_ALL
			View_ALL
			echo -e "${Info} Torrent bloqueados, Palabras Claves y Puertos SPAM !"
			msg -bar2
		else
			Set_BT
			View_ALL
			echo -e "${Info} Torrent bloqueados y Palabras Claves !"
		fi
	else
		if [[ -z ${SPAM_PORT} ]]; then
			Set_SPAM
			View_ALL
			echo -e "${Info} Puerto SPAM (spam) prohibido !"
		else
			echo -e "${Error} Torrent Bloqueados, Palabras Claves y Puertos SPAM,\nno es necesario volver a prohibir !" && msg -bar2 && exit 0
		fi
	fi
}
UnBan_BT(){
	check_BT
	[[ -z ${BT_KEY_WORDS} ]] && echo -e "${Error} Torrent y Palabras Claves no bloqueadas, verifique !"&& msg -bar2 && exit 0
	s="D"
	Set_BT
	View_ALL
	echo -e "${Info} Torrent Desbloqueados y Palabras Claves !"
	msg -bar2
}
UnBan_SPAM(){
	check_SPAM
	[[ -z ${SPAM_PORT} ]] && echo -e "${Error} Puerto SPAM no detectados, verifique !" && msg -bar2 && exit 0
	s="D"
	Set_SPAM
	View_ALL
	echo -e "${Info} Puertos de SPAM Desbloqueados !"
	msg -bar2
}
UnBan_ALL(){
	check_BT
	check_SPAM
	s="D"
	if [[ ! -z ${BT_KEY_WORDS} ]]; then
		if [[ ! -z ${SPAM_PORT} ]]; then
			Set_ALL
			View_ALL
			echo -e "${Info} Torrent, Palabras Claves y Puertos SPAM Desbloqueados !"
			msg -bar2
		else
			Set_BT
			View_ALL
			echo -e "${Info} Torrent, Palabras Claves Desbloqueados !"
			msg -bar2
		fi
	else
		if [[ ! -z ${SPAM_PORT} ]]; then
			Set_SPAM
			View_ALL
			echo -e "${Info} Puertos SPAM Desbloqueados !"
			msg -bar2
		else
			echo -e "${Error} No se  detectan Torrent, Palabras Claves y Puertos SPAM Bloqueados, verifique !" && msg -bar2 && exit 0
		fi
	fi
}
ENTER_Ban_KEY_WORDS_type(){
	Type=$1
	Type_1=$2
	if [[ $Type_1 != "ban_1" ]]; then
		echo -e "Por favor seleccione un tipo de entrada：
		
 1. Entrada manual (solo se admiten palabras clave únicas)
 
 2. Lectura local de archivos (admite lectura por lotes de palabras clave, una palabra clave por línea)
 
 3. Lectura de dirección de red (admite lectura por lotes de palabras clave, una palabra clave por línea)" && echo
		read -e -p "(Por defecto: 1. Entrada manual):" key_word_type
	fi
	[[ -z "${key_word_type}" ]] && key_word_type="1"
	if [[ ${key_word_type} == "1" ]]; then
		if [[ $Type == "ban" ]]; then
			ENTER_Ban_KEY_WORDS
		else
			ENTER_UnBan_KEY_WORDS
		fi
	elif [[ ${key_word_type} == "2" ]]; then
		ENTER_Ban_KEY_WORDS_file
	elif [[ ${key_word_type} == "3" ]]; then
		ENTER_Ban_KEY_WORDS_url
	else
		if [[ $Type == "ban" ]]; then
			ENTER_Ban_KEY_WORDS
		else
			ENTER_UnBan_KEY_WORDS
		fi
	fi
}
ENTER_Ban_PORT(){
	echo -e "Ingrese el puerto que Bloqueará:\n(segmento de Puerto único / Puerto múltiple / Puerto continuo)\n"
	if [[ ${Ban_PORT_Type_1} != "1" ]]; then
	echo -e "
	${Green_font_prefix}======== Ejemplo Descripción ========${Font_color_suffix}
	
 -Puerto único: 25 (puerto único)
 
 -Multipuerto: 25, 26, 465, 587 (varios puertos están separados por comas)

 -Segmento de puerto continuo: 25: 587 (todos los puertos entre 25-587)" && echo
	fi
	read -e -p "(Intro se cancela por defecto):" PORT
	[[ -z "${PORT}" ]] && echo "Cancelado..." && View_ALL && exit 0
}
ENTER_Ban_KEY_WORDS(){
    msg -bar2
	echo -e "Ingrese las palabras clave que se prohibirán\n(nombre de dominio, etc., solo admite una sola palabra clave)"
	if [[ ${Type_1} != "ban_1" ]]; then
	echo ""
	echo -e "${Green_font_prefix}======== Ejemplo Descripción ========${Font_color_suffix}
	
 -Palabras clave: youtube, que prohíbe el acceso a cualquier nombre de dominio que contenga la palabra clave youtube.
 
 -Palabras clave: youtube.com, que prohíbe el acceso a cualquier nombre de dominio (máscara de nombre de pan-dominio) que contenga la palabra clave youtube.com.

 -Palabras clave: www.youtube.com, que prohíbe el acceso a cualquier nombre de dominio (máscara de subdominio) que contenga la palabra clave www.youtube.com.

 -Autoevaluación de más efectos (como la palabra clave .zip se puede usar para deshabilitar la descarga de cualquier archivo de sufijo .zip)." && echo
	fi
	read -e -p "(Intro se cancela por defecto):" key_word
	[[ -z "${key_word}" ]] && echo "Cancelado ..." && View_ALL && exit 0
}
ENTER_Ban_KEY_WORDS_file(){
	echo -e "Ingrese el archivo local de palabras clave que se prohibirá / desbloqueará (utilice la ruta absoluta)" && echo
	read -e -p "(El valor predeterminado es leer key_word.txt en el mismo directorio que el script):" key_word
	[[ -z "${key_word}" ]] && key_word="key_word.txt"
	if [[ -e "${key_word}" ]]; then
		key_word=$(cat "${key_word}")
		[[ -z ${key_word} ]] && echo -e "${Error} El contenido del archivo está vacío. !" && View_ALL && exit 0
	else
		echo -e "${Error} Archivo no encontrado ${key_word} !" && View_ALL && exit 0
	fi
}
ENTER_Ban_KEY_WORDS_url(){
	echo -e "Ingrese la dirección del archivo de red de palabras clave que se prohibirá / desbloqueará (por ejemplo, http: //xxx.xx/key_word.txt)" && echo
	read -e -p "(Intro se cancela por defecto):" key_word
	[[ -z "${key_word}" ]] && echo "Cancelado ..." && View_ALL && exit 0
	key_word=$(wget --no-check-certificate -t3 -T5 -qO- "${key_word}")
	[[ -z ${key_word} ]] && echo -e "${Error} El contenido del archivo de red está vacío o se agotó el tiempo de acceso !" && View_ALL && exit 0
}
ENTER_UnBan_KEY_WORDS(){
	View_KEY_WORDS
	echo -e "Ingrese la palabra clave que desea desbloquear (ingrese la palabra clave completa y precisa de acuerdo con la lista anterior)" && echo
	read -e -p "(Intro se cancela por defecto):" key_word
	[[ -z "${key_word}" ]] && echo "Cancelado ..." && View_ALL && exit 0
}
ENTER_UnBan_PORT(){
	echo -e "Ingrese el puerto que desea desempaquetar:\n(ingrese el puerto completo y preciso de acuerdo con la lista anterior, incluyendo comas, dos puntos)" && echo
	read -e -p "(Intro se cancela por defecto):" PORT
	[[ -z "${PORT}" ]] && echo "Cancelado ..." && View_ALL && exit 0
}
Ban_PORT(){
	s="A"
	ENTER_Ban_PORT
	Set_PORT
	echo -e "${Info} Puerto bloqueado [ ${PORT} ] !\n"
	Ban_PORT_Type_1="1"
	while true
	do
		ENTER_Ban_PORT
		Set_PORT
		echo -e "${Info} Puerto bloqueado [ ${PORT} ] !\n"
	done
	View_ALL
}
Ban_KEY_WORDS(){
	s="A"
	ENTER_Ban_KEY_WORDS_type "ban"
	Set_KEY_WORDS
	echo -e "${Info} Palabras clave bloqueadas [ ${key_word} ] !\n"
	while true
	do
		ENTER_Ban_KEY_WORDS_type "ban" "ban_1"
		Set_KEY_WORDS
		echo -e "${Info} Palabras clave bloqueadas [ ${key_word} ] !\n"
	done
	View_ALL
}
UnBan_PORT(){
	s="D"
	View_PORT
	[[ -z ${Ban_PORT_list} ]] && echo -e "${Error} Se detecta cualquier puerto no bloqueado !" && exit 0
	ENTER_UnBan_PORT
	Set_PORT
	echo -e "${Info} Puerto decapsulado [ ${PORT} ] !\n"
	while true
	do
		View_PORT
		[[ -z ${Ban_PORT_list} ]] && echo -e "${Error} No se detecta puertos bloqueados !" && msg -bar2 && exit 0
		ENTER_UnBan_PORT
		Set_PORT
		echo -e "${Info} Puerto decapsulado [ ${PORT} ] !\n"
	done
	View_ALL
}
UnBan_KEY_WORDS(){
	s="D"
	Cat_KEY_WORDS
	[[ -z ${Ban_KEY_WORDS_list} ]] && echo -e "${Error} No se ha detectado ningún bloqueo !" && exit 0
	ENTER_Ban_KEY_WORDS_type "unban"
	Set_KEY_WORDS
	echo -e "${Info} Palabras clave desbloqueadas [ ${key_word} ] !\n"
	while true
	do
		Cat_KEY_WORDS
		[[ -z ${Ban_KEY_WORDS_list} ]] && echo -e "${Error} No se ha detectado ningún bloqueo !" && msg -bar2 && exit 0
		ENTER_Ban_KEY_WORDS_type "unban" "ban_1"
		Set_KEY_WORDS
		echo -e "${Info} Palabras clave desbloqueadas [ ${key_word} ] !\n"
	done
	View_ALL
}
UnBan_KEY_WORDS_ALL(){
	Cat_KEY_WORDS
	[[ -z ${Ban_KEY_WORDS_text} ]] && echo -e "${Error} No se detectó ninguna clave, verifique !" && msg -bar2 && exit 0
	if [[ ! -z "${v6iptables}" ]]; then
		Ban_KEY_WORDS_v6_num=$(echo -e "${Ban_KEY_WORDS_v6_list}"|wc -l)
		for((integer = 1; integer <= ${Ban_KEY_WORDS_v6_num}; integer++))
			do
				${v6iptables} -t mangle -D OUTPUT 1
		done
	fi
	Ban_KEY_WORDS_num=$(echo -e "${Ban_KEY_WORDS_list}"|wc -l)
	for((integer = 1; integer <= ${Ban_KEY_WORDS_num}; integer++))
		do
			${v4iptables} -t mangle -D OUTPUT 1
	done
	Save_iptables_v4_v6
	View_ALL
	echo -e "${Info} Todas las palabras clave han sido desbloqueadas !"
}
check_iptables(){
	v4iptables=`iptables -V`
	v6iptables=`ip6tables -V`
	if [[ ! -z ${v4iptables} ]]; then
		v4iptables="iptables"
		if [[ ! -z ${v6iptables} ]]; then
			v6iptables="ip6tables"
		fi
	else
		echo -e "${Error} El firewall de iptables no está instalado !
Por favor, instale el firewall de iptables：
CentOS Sistema： yum install iptables -y
Debian / Ubuntu Sistema： apt-get install iptables -y"
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://www.dropbox.com/s/xlecnj3kcw5bwqt/blockBT.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} No se puede vincular a Github !" && exit 0
	wget https://www.dropbox.com/s/xlecnj3kcw5bwqt/blockBT.sh -O $prefix/ger-frm/blockBT.sh &> /dev/null
	chmod +x $prefix/ger-frm/blockBT.sh
	echo -e "El script ha sido actualizado a la última versión.[ ${sh_new_ver} ]"
	msg -bar2 
	exit 0
}
check_sys
check_iptables
action=$1
if [[ ! -z $action ]]; then
	[[ $action = "banbt" ]] && Ban_BT && exit 0
	[[ $action = "banspam" ]] && Ban_SPAM && exit 0
	[[ $action = "banall" ]] && Ban_ALL && exit 0
	[[ $action = "unbanbt" ]] && UnBan_BT && exit 0
	[[ $action = "unbanspam" ]] && UnBan_SPAM && exit 0
	[[ $action = "unbanall" ]] && UnBan_ALL && exit 0
fi
clear
clear
msg -bar
echo  -e "$() " 
echo -e "  Panel de Firewall VPS•MX ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}"
msg -bar2
echo -e "  ${Green_font_prefix}0.${Font_color_suffix} Ver la lista actual de prohibidos
————————————
  ${Green_font_prefix}1.${Font_color_suffix} Bloquear Torrent, Palabras Clave
  ${Green_font_prefix}2.${Font_color_suffix} Bloquear Puertos SPAM 
  ${Green_font_prefix}3.${Font_color_suffix} Bloquear Torrent, Palabras Clave + Puertos SPAM
  ${Green_font_prefix}4.${Font_color_suffix} Bloquear Puerto personalizado
  ${Green_font_prefix}5.${Font_color_suffix} Bloquear Palabras Clave Personalizadas
————————————
  ${Green_font_prefix}6.${Font_color_suffix} Desbloquear Torrent, Palabras Clave
  ${Green_font_prefix}7.${Font_color_suffix} Desbloquear Puertos SPAM
  ${Green_font_prefix}8.${Font_color_suffix} Desbloquear Torrent, Palabras Clave , Puertos SPAM
  ${Green_font_prefix}9.${Font_color_suffix} Desbloquear Puerto Personalizado
 ${Green_font_prefix}10.${Font_color_suffix} Desbloquear Palabra Clave Personalizadas
 ${Green_font_prefix}11.${Font_color_suffix} Desbloquear Todas las palabras Clave Personalizadas
————————————
 ${Green_font_prefix}12.${Font_color_suffix} Actualizar script" && msg -bar2
read -e -p " Por favor ingrese un número [0-12]:" num && msg -bar2
case "$num" in
	0)
	View_ALL
	;;
	1)
	Ban_BT
	;;
	2)
	Ban_SPAM
	;;
	3)
	Ban_ALL
	;;
	4)
	Ban_PORT
	;;
	5)
	Ban_KEY_WORDS
	;;
	6)
	UnBan_BT
	;;
	7)
	UnBan_SPAM
	;;
	8)
	UnBan_ALL
	;;
	9)
	UnBan_PORT
	;;
	10)
	UnBan_KEY_WORDS
	;;
	11)
	UnBan_KEY_WORDS_ALL
	;;
	12)
	Update_Shell
	;;
	*)
	echo "Por favor ingrese el número correcto [0-12]"
	;;
esac
}

function _dnsnetflix(){
dnsnetflix () {
echo "nameserver $dnsp" > $prefix/resolv.conf
#echo "nameserver 8.8.8.8" >> $prefix/resolv.conf
$prefix/init.d/ssrmu stop &>/dev/null
$prefix/init.d/ssrmu start &>/dev/null
$prefix/init.d/shadowsocks-r stop &>/dev/null
$prefix/init.d/shadowsocks-r start &>/dev/null
msg -bar2
echo -e "${cor[4]}  DNS AGREGADOS CON EXITO"
} 
clear
msg -bar2

echo -e "\033[1;93m     AGREGARDOR DE DNS PERSONALES By @USA1_BOT "
msg -bar2
echo -e "\033[1;39m Esta funcion ara que puedas ver Netflix con tu VPS"
msg -bar2
echo -e "\033[1;91m ¡ Solo seran utiles si registraste tu IP en el BOT !"
echo -e "\033[1;39m En APPS como HTTP Inyector,KPN Rev,APKCUSTOM, etc."
echo -e "\033[1;39m Se deveran agregar en la aplicasion a usar estos DNS."
echo -e "\033[1;39m En APPS como SS,SSR,V2RAY no es necesario agregarlos."
msg -bar2
echo -e "\033[1;93m Recuerde escojer entre 1 DNS ya sea el de USA,BR,MX,CL \n segun le aya entregado el BOT."
echo ""
echo -e "\033[1;97m Ingrese su DNS a usar: \033[0;91m"; read -p "   "  dnsp
echo ""
msg -bar2
read -p " Estas seguro de continuar?  [ s | n ]: " dnsnetflix   
[[ "$dnsnetflix" = "s" || "$dnsnetflix" = "S" ]] && dnsnetflix
msg -bar2
}

function _fai2ban(){
pid_fail=$(dpkg -l | grep fail2ban | grep ii)
apache=$(dpkg -l | grep apache2 | grep ii)
squid=$(dpkg -l | grep squid | grep ii)
dropbear=$(dpkg -l | grep dropbear | grep ii)
openssh=$(dpkg -l | grep openssh | grep ii)
stunnel4=$(dpkg -l | grep stunnel4 | grep ii)
[[ "$openssh" != "" ]] && s1="ssh"
[[ "$squid" != "" ]] && s2="squid"
[[ "$dropbear" != "" ]] && s3="dropbear"
[[ "$apache" != "" ]] && s4="apache"
[[ "$stunnel4" != "" ]] && s5="stunnel4"
clear
clear
msg -bar

echo -e "\e[93m         --   Fail2ban Protection v0.11.2 -- "
echo -e "\e[97m          Anti ataques DDOS y spoofing SPAM"
msg -bar
if [[ ! -z "$pid_fail" ]]; then
 echo -e "${cor[2]} [1] >${cor[5]} $(fun_trans "Desinstalar Fail2ban")"
 echo -e "${cor[2]} [2] >\e[92m $(fun_trans "Mirar el registro")"
 msg -bar
  while [[ -z ${logxyz} || ${logxyz} != @(1|2) ]]; do
   echo -ne "\033[1;37m$(fun_trans "Seleccione una Opcion"): " && read logxyz
   tput cuu1 && tput dl1
  done
 case ${logxyz} in
  1)apt-get remove fail2ban -y &> /dev/null;;
  2)cat /var/log/fail2ban.log 
    msg -bar;;
 esac
exit 0
fi
echo -e "${cor[5]}        Desea Instalar  Fail2ban?"
msg -bar
  while [[ -z ${fail2ban} || ${fail2ban} != @(s|S|n|N|y|Y) ]]; do
   echo -ne "\033[1;37m$(fun_trans "Seleccione una Opcion") [S/N]: " && read fail2ban
   tput cuu1 && tput dl1
  done
if [[ "$fail2ban" = @(s|S|y|Y) ]]; then
apt-get install fail2ban -y &> /dev/null
wget -O $HOME/fail2ban https://github.com/fail2ban/fail2ban/archive/0.11.2.tar.gz &> /dev/null
tar -xf $HOME/fail2ban &> /dev/null
cd $HOME/fail2ban-0.11.2 &> /dev/null
python ./setup.py install &> /dev/null
echo '[INCLUDES]
before = paths-debian.conf
[DEFAULT]
ignoreip = 127.0.0.1/8
# ignorecommand = /path/to/command <ip>
ignorecommand =
bantime  = 1036800
findtime  = 3600
maxretry = 5
backend = auto
usedns = warn
logencoding = auto
enabled = false
filter = %(__name__)s
destemail = root@localhost
sender = root@localhost
mta = sendmail
protocol = tcp
chain = INPUT
port = 0:65535
fail2ban_agent = Fail2Ban/%(fail2ban_version)s
banaction = iptables-multiport
banaction_allports = iptables-allports
action_ = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mw = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
            %(mta)s-whois[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mwl = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
action_xarf = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             xarf-login-attack[service=%(__name__)s, sender="%(sender)s", logpath=%(logpath)s, port="%(port)s"]
action_cf_mwl = cloudflare[cfuser="%(cfemail)s", cftoken="%(cfapikey)s"]
                %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
action_blocklist_de  = blocklist_de[email="%(sender)s", service=%(filter)s, apikey="%(blocklist_de_apikey)s", agent="%(fail2ban_agent)s"]
action_badips = badips.py[category="%(__name__)s", banaction="%(banaction)s", agent="%(fail2ban_agent)s"]
action_badips_report = badips[category="%(__name__)s", agent="%(fail2ban_agent)s"]
action = %(action_)s' > $prefix/fail2ban/jail.local
echo -ne "${cor[5]} $(fun_trans "Fail2ban sera activo en los Siguientes\n Puertos y Servicos"):"
echo ""
msg -bar
echo -ne "\n"
[ "$s1" != "" ] && echo -ne " $s1"
[ "$s2" != "" ] && echo -ne " $s2"
[ "$s3" != "" ] && echo -ne " $s3"
[ "$s4" != "" ] && echo -ne " $s4"
[ "$s5" != "" ] && echo -ne " $s5"
echo -ne "\n"
echo -ne "\n"
msg -bar
sleep 1
if [[ "$s1" != "" ]]; then
echo '[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
[sshd-ddos]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s' >> $prefix/fail2ban/jail.local
else
echo '[sshd]
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
[sshd-ddos]
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s' >> $prefix/fail2ban/jail.local
fi
if [[ "$s2" != "" ]]; then
echo '[squid]
enabled = true
port     =  80,443,3128,8080
logpath = /var/log/squid/access.log' >> $prefix/fail2ban/jail.local
else
echo '[squid]
port     =  80,443,3128,8080
logpath = /var/log/squid/access.log' >> $prefix/fail2ban/jail.local
fi
if [[ "$s3" != "" ]]; then
echo '[dropbear]
enabled = true
port     = ssh
logpath  = %(dropbear_log)s
backend  = %(dropbear_backend)s' >> $prefix/fail2ban/jail.local
else
echo '[dropbear]
port     = ssh
logpath  = %(dropbear_log)s
backend  = %(dropbear_backend)s' >> $prefix/fail2ban/jail.local
fi
if [[ "$s4" != "" ]]; then
echo '[apache-auth]
enabled = true
port     = http,https
logpath  = %(apache_error_log)s' >> $prefix/fail2ban/jail.local
else
echo '[apache-auth]
port     = http,https
logpath  = %(apache_error_log)s' >> $prefix/fail2ban/jail.local
fi
echo '[selinux-ssh]
port     = ssh
logpath  = %(auditd_log)s
[apache-badbots]
port     = http,https
logpath  = %(apache_access_log)s
bantime  = 172800
maxretry = 1
[apache-noscript]
port     = http,https
logpath  = %(apache_error_log)s
[apache-overflows]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2
[apache-nohome]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2
[apache-botsearch]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2
[apache-fakegooglebot]
port     = http,https
logpath  = %(apache_access_log)s
maxretry = 1
ignorecommand = %(ignorecommands_dir)s/apache-fakegooglebot <ip>
[apache-modsecurity]
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2
[apache-shellshock]
port    = http,https
logpath = %(apache_error_log)s
maxretry = 1
[openhab-auth]
filter = openhab
action = iptables-allports[name=NoAuthFailures]
logpath = /opt/openhab/logs/request.log
[nginx-http-auth]
port    = http,https
logpath = %(nginx_error_log)s
[nginx-limit-req]
port    = http,https
logpath = %(nginx_error_log)s
[nginx-botsearch]
port     = http,https
logpath  = %(nginx_error_log)s
maxretry = 2
[php-url-fopen]
port    = http,https
logpath = %(nginx_access_log)s
          %(apache_access_log)s
[suhosin]
port    = http,https
logpath = %(suhosin_log)s
[lighttpd-auth]
port    = http,https
logpath = %(lighttpd_error_log)s
[roundcube-auth]
port     = http,https
logpath  = %(roundcube_errors_log)s
[openwebmail]
port     = http,https
logpath  = /var/log/openwebmail.log
[horde]
port     = http,https
logpath  = /var/log/horde/horde.log
[groupoffice]
port     = http,https
logpath  = /home/groupoffice/log/info.log
[sogo-auth]
port     = http,https
logpath  = /var/log/sogo/sogo.log
[tine20]
logpath  = /var/log/tine20/tine20.log
port     = http,https
[drupal-auth]
port     = http,https
logpath  = %(syslog_daemon)s
backend  = %(syslog_backend)s
[guacamole]
port     = http,https
logpath  = /var/log/tomcat*/catalina.out
[monit]
#Ban clients brute-forcing the monit gui login
port = 2812
logpath  = /var/log/monit
[webmin-auth]
port    = 10000
logpath = %(syslog_authpriv)s
backend = %(syslog_backend)s
[froxlor-auth]
port    = http,https
logpath  = %(syslog_authpriv)s
backend  = %(syslog_backend)s
[3proxy]
port    = 3128
logpath = /var/log/3proxy.log
[proftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(proftpd_log)s
backend  = %(proftpd_backend)s
[pure-ftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(pureftpd_log)s
backend  = %(pureftpd_backend)s
[gssftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(syslog_daemon)s
backend  = %(syslog_backend)s
[wuftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(wuftpd_log)s
backend  = %(wuftpd_backend)s
[vsftpd]
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(vsftpd_log)s
[assp]
port     = smtp,465,submission
logpath  = /root/path/to/assp/logs/maillog.txt
[courier-smtp]
port     = smtp,465,submission
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s
[postfix]
port     = smtp,465,submission
logpath  = %(postfix_log)s
backend  = %(postfix_backend)s
[postfix-rbl]
port     = smtp,465,submission
logpath  = %(postfix_log)s
backend  = %(postfix_backend)s
maxretry = 1
[sendmail-auth]
port    = submission,465,smtp
logpath = %(syslog_mail)s
backend = %(syslog_backend)s
[sendmail-reject]
port     = smtp,465,submission
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s
[qmail-rbl]
filter  = qmail
port    = smtp,465,submission
logpath = /service/qmail/log/main/current
[dovecot]
port    = pop3,pop3s,imap,imaps,submission,465,sieve
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s
[sieve]
port   = smtp,465,submission
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s
[solid-pop3d]
port    = pop3,pop3s
logpath = %(solidpop3d_log)s
[exim]
port   = smtp,465,submission
logpath = %(exim_main_log)s
[exim-spam]
port   = smtp,465,submission
logpath = %(exim_main_log)s
[kerio]
port    = imap,smtp,imaps,465
logpath = /opt/kerio/mailserver/store/logs/security.log
[courier-auth]
port     = smtp,465,submission,imap3,imaps,pop3,pop3s
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s
[postfix-sasl]
port     = smtp,465,submission,imap3,imaps,pop3,pop3s
logpath  = %(postfix_log)s
backend  = %(postfix_backend)s
[perdition]
port   = imap3,imaps,pop3,pop3s
logpath = %(syslog_mail)s
backend = %(syslog_backend)s
[squirrelmail]
port = smtp,465,submission,imap2,imap3,imaps,pop3,pop3s,http,https,socks
logpath = /var/lib/squirrelmail/prefs/squirrelmail_access_log
[cyrus-imap]
port   = imap3,imaps
logpath = %(syslog_mail)s
backend = %(syslog_backend)s
[uwimap-auth]
port   = imap3,imaps
logpath = %(syslog_mail)s
backend = %(syslog_backend)s
[named-refused]
port     = domain,953
logpath  = /var/log/named/security.log
[nsd]
port     = 53
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]
logpath = /var/log/nsd.log
[asterisk]
port     = 5060,5061
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]
           %(mta)s-whois[name=%(__name__)s, dest="%(destemail)s"]
logpath  = /var/log/asterisk/messages
maxretry = 10
[freeswitch]
port     = 5060,5061
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]
           %(mta)s-whois[name=%(__name__)s, dest="%(destemail)s"]
logpath  = /var/log/freeswitch.log
maxretry = 10
[mysqld-auth]
port     = 3306
logpath  = %(mysql_log)s
backend  = %(mysql_backend)s
[recidive]
logpath  = /var/log/fail2ban.log
banaction = %(banaction_allports)s
bantime  = 604800  ; 1 week
findtime = 86400   ; 1 day
[pam-generic]
banaction = %(banaction_allports)s
logpath  = %(syslog_authpriv)s
backend  = %(syslog_backend)s
[xinetd-fail]
banaction = iptables-multiport-log
logpath   = %(syslog_daemon)s
backend   = %(syslog_backend)s
maxretry  = 2
[stunnel]
logpath = /var/log/stunnel4/stunnel.log
[ejabberd-auth]
port    = 5222
logpath = /var/log/ejabberd/ejabberd.log
[counter-strike]
logpath = /opt/cstrike/logs/L[0-9]*.log
# Firewall: http://www.cstrike-planet.com/faq/6
tcpport = 27030,27031,27032,27033,27034,27035,27036,27037,27038,27039
udpport = 1200,27000,27001,27002,27003,27004,27005,27006,27007,27008,27009,27010,27011,27012,27013,27014,27015
action  = %(banaction)s[name=%(__name__)s-tcp, port="%(tcpport)s", protocol="tcp", chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(udpport)s", protocol="udp", chain="%(chain)s", actname=%(banaction)s-udp]
[nagios]
logpath  = %(syslog_daemon)s     ; nrpe.cfg may define a different log_facility
backend  = %(syslog_backend)s
maxretry = 1
[directadmin]
logpath = /var/log/directadmin/login.log
port = 2222
[portsentry]
logpath  = /var/lib/portsentry/portsentry.history
maxretry = 1
[pass2allow-ftp]
# this pass2allow example allows FTP traffic after successful HTTP authentication
port         = ftp,ftp-data,ftps,ftps-data
# knocking_url variable must be overridden to some secret value in filter.d/apache-pass.local
filter       = apache-pass
# access log of the website with HTTP auth
logpath      = %(apache_access_log)s
blocktype    = RETURN
returntype   = DROP
bantime      = 3600
maxretry     = 1
findtime     = 1
[murmur]
port     = 64738
action   = %(banaction)s[name=%(__name__)s-tcp, port="%(port)s", protocol=tcp, chain="%(chain)s", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port="%(port)s", protocol=udp, chain="%(chain)s", actname=%(banaction)s-udp]
logpath  = /var/log/mumble-server/mumble-server.log
[screensharingd]
logpath  = /var/log/system.log
logencoding = utf-8
[haproxy-http-auth]
logpath  = /var/log/haproxy.log' >> $prefix/fail2ban/jail.local


[[ -e $HOME/fail2ban ]] && rm $HOME/fail2ban
[[ -d $HOME/fail2ban-0.11.2 ]] && rm -rf $HOME/fail2ban-0.11.2

cd 
service fail2ban restart
fi
}

function _paysnd(){
construct_fun () {
payload="$1"
sed -i 's/.crlf]/\\r\\n&/g' ${payload}
sed -i "s/.crlf]//g" ${payload}
sed -i 's/.cr]/\\r&/g' ${payload}
sed -i "s/.cr]//g" ${payload}
sed -i 's/.lf]/\\n&/g' ${payload}
sed -i "s/.lf]//g" ${payload}
sed -i "s/.auth]//g" ${payload}
sed -i 's/.delay_split]/\\r\\n&/g' ${payload}
sed -i "s/.delay_split]//g" ${payload}
sed -i 's/.instant_split]/\\r\\n&/g' ${payload}
sed -i "s/.instant_split]//g" ${payload}
sed -i 's/.split]/\\r\\n&/g' ${payload}
sed -i "s/.split]//g" ${payload}
sed -i "s;.host_port];${hostprox}:22;g" ${payload}
sed -i "s;.host];${proxy};g" ${payload}
sed -i "s;.port];:22;g" ${payload}
sed -i 's;.protocol];HTTP/1.0;g' ${payload}
sed -i 's;.ua];Dalvik/2.1.0;g' ${payload}
sed -i 's;.method];CONNECT;g' ${payload}
sed -i "s;.raw];CONNECT ${hostprox}:22 HTTP/1.0;g" ${payload}
sed -i "s;.netData];CONNECT ${hostprox}:22 HTTP/1.0;g" ${payload}
sed -i "s;.realData];CONNECT ${hostprox}:22 HTTP/1.0;g" ${payload}
}
esquelet="./payloads.txt"
gerar_arqpay () {
echo 'GET http://mhost/ HTTP/1.1[crlf][raw][crlf] [crlf][crlf]
CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]
CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf] [crlf]
CONNECT [host_port]@mhost HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]
CONNECT [host_port]@mhost HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT [host_port]@mhost [protocol][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT [host_port]@mhost [protocol][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf][crlf]
CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]User-Agent: [ua][crlf] [crlf]
CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Referer: mhost[crlf][crlf]
CONNECT mhost@[host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Referer: mhost[crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
GET mhost@[host_port] [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]
GET mhost@[host_port] [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf] [crlf]
GET [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]
GET [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf] [crlf]
CONNECT [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
CONNECT [host_port]@mhost [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][raw][crlf] [crlf]
CONNECT [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][crlf]
CONNECT [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]User-Agent: [ua][crlf][crlf][split][raw][crlf][crlf]CONNECT mhost:443 HTTP/1.1[crlf][raw][crlf][crlf]GET http://mhost/ HTTP/1.0[crlf]Host: mhost[crlf]Proxy-Authorization: basic: mhost[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive [crlf]Host: [host][crlf][crlf][split][raw][crlf][crlf]GET http://mhost/ HTTP/1.0[crlf]Host: mhost/[crlf][crlf]CONNECT [host_port] HTTP/1.0[crlf][crlf][realData][crlf][crlf]
[method] mhost:443 HTTP/1.1[crlf][raw][crlf][crlf]GET http://mhost/ HTTP/1.1\nHost: mhost\nConnection: close\nConnection: close\nUser-Agent:[ua][crlf]Proxy-Connection: Keep-Alive[crlf]Host: [host][crlf][crlf][delay_split][raw][crlf][crlf][raw][crlf][realData][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]User-Agent: KDDI[crlf]Host: [host][crlf][crlf][raw][raw][crlf][raw][crlf][raw][crlf][crlf]DELETE http://mhost/ HTTP/1.1[crlf]Host: m.opera.com[crlf]Proxy-Authorization: basic: *[crlf]User-Agent: KDDI[crlf]Connection: close[crlf]Proxy-Connection: Direct[crlf]Host: [host][crlf][crlf][raw][raw][crlf][crlf][raw][method] http://mhost[port] HTTP/1.1[crlf]Host: [host][crlf][crlf]CONNECT [host] [protocol][crlf][crlf][CONNECT [host] [protocol][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][netData][crlf][instant_split]MOVE http://mhost[delay_split][crlf][crlf][netData][crlf][instant_split]MOVE http://mhost[delay_split][crlf][crlf][netData][crlf][instant_split]MOVE http://mhost[delay_split][crlf][crlf]X-Online-Host: mhost[crlf]Packet Length: Authorization[crlf]Packet Content: Authorization[crlf]Transfer-Encoding: chunked[crlf]Referer: mhost[crlf][crlf]
[crlf][crlf]CONNECT [host_port]@mhost/ [protocol][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: [ua][crlf]CONNECT [host]@mhost/ [protocol][crlf][crlf]
[method] [host_port] [protocol] [delay_split]GET http://mhost/ HTTP/1.1[netData][crlf]GET mip:80[crlf]X-GreenArrow-MtaID: smtp1-1[crlf]CONNECT http://mhost/ HTTP/1.1[crlf]CONNECT http://mhost/ HTTP/1.0[crlf][split]CONNECT http://mhost/ HTTP/1.1[crlf]CONNECT http://mhost/ HTTP/1.1[crlf][crlf][method] [host_port] [protocol]?[split]GET http://mhost:8080/[crlf][crlf]GET [host_port] [protocol]?[split]OPTIONS http://mhost/[crlf]Connection: Keep-Alive[crlf]User-Agent: Mozilla/5.0 (Android; Mobile; rv:35.0) Gecko/35.0 Firefox/35.0[crlf]CONNECT [host_port] [protocol] [crlf]GET [host_port] [protocol]?[split]GET http://mhost/[crlf][crlf][method] mip:80[split]GET mhost/[crlf][crlf]: Cache-Control:no-store,no-cache,must-revalidate,post-check=0,pre-check=0[crlf]Connection:close[crlf]CONNECT [host_port] [protocol]?[split]GET http://mhost:/[crlf][crlf]POST [host_port] [protocol]?[split]GET[crlf]mhost:/[crlf]Content-Length: 999999999\r\n\r\n
GET [host_port] [protocol][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Referer: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET mhost/ HTTP/1.1[crlf][crlf]
CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: navegue.vivo.ddivulga.com/pacote[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]CONNECT [host_port] [protocol]GET http://mhost/ [protocol][crlf][split]CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost/[crlf]GET mhost/ HTTP/1.1[crlf]HEAD mhost/ HTTP/1.1[crlf]TRACE mhost/ HTTP/1.1[crlf]OPTIONS mhost/ HTTP/1.1[crlf]PATCH mhost/ HTTP/1.1[crlf]PROPATCH mhost/ HTTP/1.1[crlf]DELETE mhost/ HTTP/1.1[crlf]PUT mhost/ HTTP/1.1[crlf]Host: mhost/[crlf]Host: mhost/[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]X-Forwarded-For: mhost[protocol][crlf][crlf]
[raw][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost/[crlf]X-Forward-Host: mhost/[crlf]Connection: Keep-Alive[crlf]Connection: Close[crlf]User-Agent: [ua][crlf][crlf]
[raw][split]GET mhost/ HTTP/1.1[crlf] [crlf]
CONNECT [host_port]@mhost/ [protocol][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]GET mhost/[crlf]Connection: close Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][raw][crlf][crlf]
[raw]split]GET mhost/ HTTP/1.1[crlf][crlf]
GET [host_port] [protocol][instant_split]GET http://mhost/ HTTP/1.1[crlf]
GET [host_port] [protocol][crlf][delay_split]CONNECT http://mhost/ HTTP/1.1[crlf]
CONNECT [host_port] [protocol] [instant_split]GET http://mhost/ HTTP/1.1[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]User-Agent: [ua][crlf][crlf]
GET http://mhost/ HTTP/2.0[auth][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]CONNECT [host_port] [protocol] [auth][crlf][crlf][delay_split][raw][crlf]JAZZ http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf][delay_split]CONNECT [host_port] [protocol] [method][crlf] [crlf][crlf]
CONNECT [host_port] [protocol][crlf]GET http://mhost/ HTTP/1.1\rHost: mhost\r[crlf]X-Online-Host: mhost\r[crlf]X-Forward-Host: mhost\rUser-Agent: Mozilla/5.0 (X11; U; Linux x86_64; en-gb) AppleWebKit/534.35 (KHTML, like Gecko) Chrome/11.0.696.65 Safari/534.35 Puffin/2.9174AP[crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost/ [crlf]User-Agent: Yes[crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive[crlf][crlf][raw][crlf][crlf]
GET [host_port] [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][raw][crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]UseDNS: Yes[crlf]Cache-Control: no-cache[crlf][raw][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf] Access-Control-Allow-Credentials: true, true[crlf] Access-Control-Allow-Headers: X-Requested-With,Content-Type, X-Requested-With,Content-Type[crlf]  Access-Control-Allow-Methods: GET,PUT,OPTIONS,POST,DELETE, GET,PUT,OPTIONS,POST,DELETE[crlf]  Age: 8, 8[crlf] Cache-Control: max-age=86400[crlf] public[crlf] Connection: keep-alive[crlf] Content-Type: text/html; charset=UTF-8[crlf]Content-Length: 9999999999999[crlf]UseDNS: Yes[crlf]Vary: Accept-Encoding[crlf][raw][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf] Access-Control-Allow-Credentials: true, true[crlf] Access-Control-Allow-Headers: X-Requested-With,Content-Type, X-Requested-With,Content-Type[crlf]  Access-Control-Allow-Methods: GET,PUT,OPTIONS,POST,DELETE, GET,PUT,OPTIONS,POST,DELETE[crlf]  Age: 8, 8[crlf] Cache-Control: max-age=86400[crlf] public[crlf] Connection: keep-alive[crlf] Content-Type: text/html; charset=UTF-8[crlf]Content-Length: 9999999999999[crlf]Vary: Accept-Encoding[crlf][raw][crlf] [crlf][crlf]
[netData][split][raw][crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost/[crlf]User-Agent: Yes[crlf]Connection: close[crlf]Proxy-Connection: update[crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]host: http://mhost/[crlf]Connection: close update[crlf]User-Agent: [ua][crlf][crlf][raw][crlf][crlf] [crlf]
[raw][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][raw][crlf][crlf]User-Agent: [ua][crlf]Connection: Close[crlf]Proxy-connection: Close[crlf]Proxy-Authorization: Basic[crlf]Cache-Control: no-cache[crlf]Connection: Keep-Alive[crlf][raw][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Content-Type: text/html; charset=iso-8859-1[crlf]Connection: close[crlf][crlf]User-Agent: [ua][crlf][crlf]Referer: mhost[crlf]Cookie: mhost[crlf]Proxy-Connection: Keep-Alive [crlf][crlf][raw][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Upgrade-Insecure-Requests: 1[crlf]User-Agent: Mozilla/5.0 (Linux; Android 5.1; LG-X220 Build/LMY47I) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.83 Mobile Safari/537.36[crlf]Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8[crlf]Referer: http://mhost[crlf]Accept-Encoding: gzip, deflate, sdch[crlf]Accept-Language: pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4[crlf]Cookie: _ga=GA1.2.2045323091.1494102805; _gid=GA1.2.1482137697.1494102805; tfp=80bcf53934df3482b37b54c954bd53ab; tpctmp=1494102806975; pnahc=0; _parsely_visitor={%22id%22:%22719d5f49-e168-4c56-b7c7-afdce6daef18%22%2C%22session_count%22:1%2C%22last_session_ts%22:1494102810109}; sc_is_visitor_unique=rx10046506.1494105143.4F070B22E5E94FC564C94CB6DE2D8F78.1.1.1.1.1.1.1.1.1[crlf][crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive[crlf][netData][crlf] [crlf][crlf]
GET [host_port] [protocol][crlf][split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][raw][crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control: no-cache[crlf][raw][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: [ua][crlf]Connection: close [crlf]Referer:http://mhost[crlf]Content-Type: text/html; charset=iso-8859-1[crlf]Content-Length:0[crlf]Accept: text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5[crlf][raw][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: null[crlf]Connection: close[crlf]Proxy-Connection: x-online-host[crlf][crlf] CONNECT [host_port] [protocol] [netData][crlf]Content-Length: 130 [crlf][crlf]
[raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf][crlf]User-Agent: Yes[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Connection: Basic[crlf]Referer: mhost[crlf]Cookie: mhost/ [crlf]Proxy-Connection: Keep-Alive[crlf][crlf][netData][crlf] [crlf][crlf]
[raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Accept-Language: en-us,en;q=0.5[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Keep-Alive: 115[crlf]Connection: keep-alive[crlf]Referer: mhost[crlf]Cookie: mhost/ Proxy-Connection: Keep-Alive[crlf][crlf][netData][crlf] [crlf][crlf]
[raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control: no-cache[crlf][raw][crlf] [crlf]
[raw][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf]Connection: close[crlf][crlf][raw][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]CONNECT [host_port][method]HTTP/1.1[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost[crlf][crlf]DELETE http://mhost/ HTTP/1.1[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][method] [host_port]@mip [crlf][crlf]http://mhost/ HTTP/1.1[crlf]mip[crlf][crlf] [crlf][crlf]http://mhost/ HTTP/1.1[crlf]Host@mip[crlf][crlf] [crlf][crlf] http://mhost/ HTTP/1.1[crlf]Host mhost/[crlf][crlf][netData][crlf] [crlf][crlf] http://mhost/ HTTP/1.1[crlf] [crlf][crlf][netData][crlf] [crlf][crlf] http://mhost/ HTTP/1.1[cr][crlf] [crlf][crlf][netData][cr][crlf] [crlf][crlf]CONNECT mip:22@http://mhost/ HTTP/1.1[crlf] [crlf][crlf][netData][crlf] [crlf][crlf]
CONNECT [host_port]@mhost/ HTTP/1.1[crlf][crlf]CONNECT http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: close[crlf]User-Agent: [ua][crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control : no-cache[crlf][crlf]
CONNECT [host_port]@mhost/ HTTP/1.0[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: close[crlf]User-Agent: [ua][crlf]Proxy-connection: Keep-Alive[crlf]Proxy-Authorization: Basic[crlf]Cache-Control : no-cache[crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13[crlf]Accept-Language: en-us,en;q=0.5[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Keep-Alive: 115[crlf]Connection: keep-alive[crlf]Referer: mhost[crlf]Cookie: mhost/ Proxy-Connection: Keep-Alive [crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]User-Agent: Yes[crlf]Accept-Encoding: gzip,deflate[crlf]Accept-Charset: ISO-8859-1,utf-8;q=0.7,;q=0.7[crlf]Connection: Basic[crlf]Referer: mhost[crlf]Cookie: mhost/ [crlf]Proxy-Connection: Keep-Alive[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][delay_split]CONNECT [host_port]@mhost/ [protocol][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]DATA: 2048B[crlf]Host: mhost[crlf]User-Agent: Yes[crlf]Connection: close[crlf]Accept-Encoding: gzip[crlf]Non-Buffer: true[crlf]Proxy: false[crlf][crlf][netData][crlf] [crlf][crlf]
GET [host_port] [protocol][crlf][delay_split]CONNECT http://mhost/ HTTP/1.1[crlf]Host: http://mhost/[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: http://mhost[crlf]X-Forwarded-For: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Cache-Control=max-age=0[crlf][crlf][raw][crlf] [crlf][crlf]
CONNECT [host_port]@mhost/ [protocol][crlf]X-Online-Host: mhost[crlf][crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Referer: mhost[crlf]GET /HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]User-Agent: [ua][crlf][raw][crlf][crlf][raw][crlf]Referer: mhost[crlf][crlf]
GET http://mhost/ HTTP/1.1[cr][crlf]Host: mhost/\nUser-Agent: Yes\nConnection: close\nProxy-Connection: Keep-Alive\n\r\n\r\n[netData]\r\n \r\n\r\n
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: close Keep-Alive[crlf]User-Agent: [ua][crlf][crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][split]CONNECT mhost@[host_port] [protocol][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][realData][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf][crlf]CONNECT mhost/ [protocol][crlf][crlf]
[raw][crlf]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]CONNECT mhost/ [protocol][crlf]
[raw] HTTP/1.0\r\n\r\nGET http://mhost/ HTTP/1.1\r\nHost: mhost\r\nConnection: Keep-Alive\r\nCONNECT mhost\r\n\r\n
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][raw][crlf][crlf]
GET [host_port]@mhost/ HTTP/1.1[crlf]X-Real-IP:mip[crlf]X-Forwarded-For:http://mhost/ http://mhost/[crlf]X-Forwarded-Port:mhost[crlf]X-Forwarded-Proto:http[crlf]Connection:Keep-Alive[crlf][crlf][instant_split][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host:mhost[crlf][crlf][split][realData][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf][realData][crlf]CONNECT mhost/ HTTP/1.1[crlf][crlf]
CONNECT [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forward-Host: mhost[crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
[raw][crlf]GET http://mhost/ [protocol][crlf][split]mhost:/ HTTP/1.1[crlf]Host: mhost:[crlf]X-Forward-Host: mhost:[crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Connection: close[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host:http://mhost[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1\r\nHost: mhost\r\n\r\n[netData]\r\n\r\n\r\n
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][realData][crlf][crlf]
GET http://mhost/ HTTP/1.1\r\nX-Online-Host:mhost\r\n\r\nCONNECT mip:443[crlf]HTTP/1.0\r\n \r\n\\r\n\r\n\\r\n\r\n\\r\n\r\n\\r\n\r\n\\\r\n
GET http://mhost/ HTTP/1.1\r\nGET: mhost\n\r\nCONNECT mip:443[crlf]HTTP/1.0\r\n \r\n\\r\n\r\n\\r\n\r\n\\r\n\r\n\\r\n\r\n\\\r\n
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf]Connection: close[crlf][raw][crlf] [crlf][crlf]
GET http://mhost/[crlf]X-Forward-Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf]X-Forward-Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf]CONNECT mhost/ [protocol][crlf] [crlf][crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]mhost[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]Forward-Host: mhost[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]Connection: http://mhost[crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]CONNECT mhost@[host_port] [protocol][crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf]Connection: Keep-Alive[crlf]mhost@[host_port][crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf][netdata][crlf] [crlf]GET mhost/ [protocol][crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf][crlf]User-Agent: [ua][crlf][raw][crlf][crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf][split]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]X-Forwarded-For: mhost[crlf][crlf]User-Agent: [ua][crlf]Connection: close[crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf][raw][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf][raw][crlf] [crlf][crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]CONNECT http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
GET http://mhost/ [method] [host_port] HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]Connection: close[crlf][netData][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]CONNECT mhost@[host_port] [protocol][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]CONNECT http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]Connection: close[crlf][netdata][crlf] [crlf][split]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][netData][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][netData][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]mhost\r\nHost:mhost\r\n\r\n[netData]\r\n \r\n\r\n
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf][realData][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf]HEAD http://mhost/ [protocol][crlf]Host: mhost/ [crlf]CONNECT mhost/  [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]host: mhost[crlf][crlf][realData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost/ [crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][raw][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf]Connection: Keep-Alive[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][realData][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf][crlf]Host: mhost[crlf][crlf]CONNECT mhost/ [protocol][crlf] [crlf]
GET http://mhost/ HTTP/1.1[crlf]mhost[crlf]Host: mhost[crlf][crlf]CONNECT mhost/ [crlf][raw][crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]mhost[crlf]Host: mhost[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf]CONNECT [host_port][crlf]CONNECT mhost/ [crlf][crlf][cr]
[realData][crlf][split]GET http://mhost/  HTTP/1.1[crlf][crlf]Host: mhost[crlf]X-Online-Host: mhost[crlf]Connection: Keep-Alive[crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]mhost[crlf]Host: mhost[crlf][crlf]CONNECT [host_port][crlf]GET mhost/ [crlf]
CONNECT [host_port]@mhost/ HTTP/1.1[crlf][crlf]GET http://mhost/ [protocol][crlf]Host: mhost[crlf]X-Forward-Host: mhost[crlf][raw][crlf][crlf]
[raw][crlf][cr][crlf]X-Online-Host: mhost[crlf]Connection: [crlf]User-Agent: [ua][crlf]Content-Lenght: 99999999999[crlf][crlf]
[raw][crlf]X-Online-Host: mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][raw][crlf]X-Online-Host: mhost[crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Authorization: Basic: Connection: X-Forward-Keep-AliveX-Online-Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]host:frontend.claro.com.br[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][raw][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf][netData][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: Multibanco.com.br[crlf][crlf][raw][crlf] [crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Host: mhost/ [crlf][crlf][raw][crlf]CONNECT [crlf]
GET http://mhost/ HTTP/1.1[crlf] Proxy-Authorization: Basic:Connection: X-Forward-Keep-AliveX-Online-Host:[crlf][crlf][netData][crlf] [crlf][crlf]
CONNECT [host_port]@mhost/ [protocol][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]
CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost[crlf][crlf]
[raw][crlf]X-Online-Host: mhost[crlf][crlf][raw][crlf]X-Online-Host: mhost/ [crlf][crlf]
[raw][crlf]X-Online-Host: http://mhost[crlf][crlf]CONNECT[host_port] [protocol][crlf]X-Online-Host: mhost/ [crlf][crlf]
CONNECT [host_port]@mhost/ HTTP/1.1[crlf]CONNECT mip:443 [crlf][crlf]
CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost[crlf][crlf][split]GET mhost/ HTTP/1.1[cr][crlf][raw][crlf] [crlf][crlf]
CONNECT [host_port]@mhost/ [protocol][crlf][delay_split]GET http://mhost/ HTTP/1.1[crlf]Host:mhost[crlf][crlf]
CONNECT [host_port]@mhost/ [protocol][crlf][instant_split]GET http://mhost/ HTTP/1.1[crlf]Host: mhost[crlf][crlf]
GET http://mhost/ HTTP/1.1[crlf]Content-Type: text[crlf]Cache-Control: no-cache[crlf]Connection: close[crlf]Content-Lenght: 20624[crlf]GET mip:443@mhost/ HTTP/1.1[crlf][crlf]
CONNECT [host_port]@mhost/ [protocol][crlf]Host: mhost[crlf]X-Forwarded-For: mhost/ User-Agent: Yes[crlf]Connection: close[crlf]Proxy-Connection: Keep-Alive Connection: Transfer-Encoding[crlf] [protocol][crlf]User-Agent: [ua][crlf][raw][auth][crlf][crlf][netData][crlf] [crlf][crlf]
[raw][crlf]Host: mhost[crlf]GET http://mhost/ HTTP/1.1[crlf]X-Online-Host: mhost[crlf][crlf]' > $esquelet
}
err_fun () {
echo -e "${cor[5]} Operacion Invalida"
exit
}
msg -bar

echo -e "${cor[3]}               PAYLOAD BRUTE FORCE "
msg -bar
gerar_pay () {
# Coletando Host
while [[ ! ${value1} ]]; do
    read -p " Host Test: " value1
done
curl -I ${value1} > /dev/null 2>&1 || err_fun
[[ $(echo ${value1}|rev|cut -c 1) = "/" ]] && valor1="${value1:0:$((${#value1}-1))}" || valor1="${value1}"
valor2="127.0.0.1"
msg -bar
echo -e "${cor[5]} Request Method ${cor[3]}"
cat <<EOF
 [1] - GET        [2] - CONNECT  [3] - PUT     [4] - OPTIONS
 [5] - DELETE     [6] - HEAD     [7] - PATCH   [8] - POST
EOF
msg -bar
# Coletando Requisi��o
while [[ ! ${req} ]]; do
    read -p " => " valor3
    case $valor3 in
    1)req="GET";;
    2)req="CONNECT";;
    3)req="PUT";;
    4)req="OPTIONS";;
    5)req="DELETE";;
    6)req="HEAD";;
    7)req="PATCH";;
    8)req="POST";;
    esac
done
in="netData"
gerar_arqpay
sed -i "s;realData;abc;g" $esquelet
sed -i "s;netData;abc;g" $esquelet
sed -i "s;netdata;abc;g" $esquelet
sed -i "s;raw;abc;g" $esquelet
sed -i "s;abc;$in;g" $esquelet
sed -i "s;GET;$req;g" $esquelet
sed -i "s;mhost;$valor1;g" $esquelet
sed -i "s;mip;$valor2;g" $esquelet
msg -bar
read -p " Digite el Proxy/Dropbear: " hostprox
read -p " Digite el Puerto: " portx
msg -bar
echo -e "${cor[1]} STARTING..."
msg -bar
}
while true; do
echo -e " [1]-Testear Un Payload"
echo -e " [2]-Testear Payloads Registrados"
msg -bar
read -p " [1-2]: " opx
case $opx in
1)
read -p " Digite un Payload: " payloadx
echo "$payloadx" > $esquelet
sed -i "s;realData;abc;g" $esquelet
sed -i "s;netData;abc;g" $esquelet
sed -i "s;netdata;abc;g" $esquelet
sed -i "s;raw;abc;g" $esquelet
sed -i "s;abc;$in;g" $esquelet
sed -i "s;GET;$req;g" $esquelet
sed -i "s;mhost;$valor1;g" $esquelet
sed -i "s;mip;$valor2;g" $esquelet
construct_fun $esquelet
read -p " Digite el Proxy/o Dropbear: " hostprox
read -p " Digite el Puerto: " portx
msg -bar
break
;;
2)
msg -bar
gerar_pay
construct_fun $esquelet
break
;;
esac
done
read -p " Digite el Tiempo De Espera! (Segundos): " VARS
msg -bar
line=$(($(cat $esquelet|wc -l)+1))
for((a=1; a<$line; a++)); do
(
echo -ne "${cor[1]}Payload: ${cor[3]}" >&2
cat $esquelet|head -${a}|tail -1 >&2
echo -ne "${cor[1]}Respuesta: ${cor[2]}" >&2
pay="$(cat $esquelet|head -${a}|tail -1)"
exec 5<>/dev/tcp/${hostprox}/${portx}
echo "$pay" >&5
echo -e "$(cat <&5|head -1)\n" >&2
) & > /dev/null
PID=$!
sleep ${VARS}s
kill -SIGINT $PID &>/dev/null && echo -e "Sin Respuesta\n"
done
echo -ne "\033[0m"
}

function _ports(){
port () {
local portas
local portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
i=0
while read port; do
var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
[[ "$(echo -e ${portas}|grep -w "$var1 $var2")" ]] || {
    portas+="$var1 $var2 $portas"
    echo "$var1 $var2"
    let i++
    }
done <<< "$portas_var"
}
verify_port () {
local SERVICE="$1"
local PORTENTRY="$2"
[[ ! $(echo -e $(port|grep -v ${SERVICE})|grep -w "$PORTENTRY") ]] && return 0 || return 1
}
edit_squid () {

msg -ama "$(fun_trans "REDEFINIR PUERTOS SQUID")"
msg -bar
if [[ -e $prefix/squid/squid.conf ]]; then
local CONF="$prefix/squid/squid.conf"
elif [[ -e $prefix/squid3/squid.conf ]]; then
local CONF="$prefix/squid3/squid.conf"
fi
NEWCONF="$(cat ${CONF}|grep -v "http_port")"
msg -ne "$(fun_trans "Nuevos Puertos"): "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port squid "${PTS}" && echo -e "\033[1;33mPort $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPort $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
echo -e "${varline}" >> ${CONF}
 if [[ "${varline}" = "#portas" ]]; then
  for NPT in $(echo ${newports}); do
  echo -e "http_port ${NPT}" >> ${CONF}
  done
 fi
done <<< "${NEWCONF}"
msg -azu "$(fun_trans "AGUARDE")"
service squid restart &>/dev/null
service squid3 restart &>/dev/null
sleep 1s
msg -bar
msg -azu "$(fun_trans "PUERTOS REDEFINIDOS")"
msg -bar
}
edit_apache () {
msg -azu "$(fun_trans "REDEFINIR PUERTOS APACHE")"
msg -bar
local CONF="$prefix/apache2/ports.conf"
local NEWCONF="$(cat ${CONF})"
msg -ne "$(fun_trans "Nuevos Puertos"): "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port apache "${PTS}" && echo -e "\033[1;33mPort $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPort $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
if [[ $(echo ${varline}|grep -w "Listen") ]]; then
 if [[ -z ${END} ]]; then
 echo -e "Listen ${newports}" >> ${CONF}
 END="True"
 else
 echo -e "${varline}" >> ${CONF}
 fi
else
echo -e "${varline}" >> ${CONF}
fi
done <<< "${NEWCONF}"
msg -azu "$(fun_trans "AGUARDE")"
service apache2 restart &>/dev/null
sleep 1s
msg -bar
msg -azu "$(fun_trans "PUERTOS REDEFINIDOS")"
msg -bar
}
edit_openvpn () {
msg -azu "$(fun_trans "REDEFINIR PUERTOS OPENVPN")"
msg -bar
local CONF="$prefix/openvpn/server.conf"
local CONF2="$prefix/openvpn/client-common.txt"
local NEWCONF="$(cat ${CONF}|grep -v [Pp]ort)"
local NEWCONF2="$(cat ${CONF2})"
msg -ne "$(fun_trans "Nuevos puertos"): "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port openvpn "${PTS}" && echo -e "\033[1;33mPort $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPort $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
echo -e "${varline}" >> ${CONF}
if [[ ${varline} = "proto tcp" ]]; then
echo -e "port ${newports}" >> ${CONF}
fi
done <<< "${NEWCONF}"
rm ${CONF2}
while read varline; do
if [[ $(echo ${varline}|grep -v "remote-random"|grep "remote") ]]; then
echo -e "$(echo ${varline}|cut -d' ' -f1,2) ${newports} $(echo ${varline}|cut -d' ' -f4)" >> ${CONF2}
else
echo -e "${varline}" >> ${CONF2}
fi
done <<< "${NEWCONF2}"
msg -azu "$(fun_trans "AGUARDE")"
service openvpn restart &>/dev/null
$prefix/init.d/openvpn restart &>/dev/null
sleep 1s
msg -bar
msg -azu "$(fun_trans "PUERTOS REDEFINIDOS")"
msg -bar
}
edit_dropbear () {
msg -bar
msg -azu "$(fun_trans "REDEFINIR PUERTOS DROPBEAR")"
msg -bar
local CONF="$prefix/default/dropbear"
local NEWCONF="$(cat ${CONF}|grep -v "DROPBEAR_EXTRA_ARGS")"
msg -ne "$(fun_trans "Nuevos Puertos"): "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port dropbear "${PTS}" && echo -e "\033[1;33mPort $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPort $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
while read varline; do
echo -e "${varline}" >> ${CONF}
 if [[ ${varline} = "NO_START=0" ]]; then
 echo -e 'DROPBEAR_EXTRA_ARGS="VAR"' >> ${CONF}
 for NPT in $(echo ${newports}); do
 sed -i "s/VAR/-p ${NPT} VAR/g" ${CONF}
 done
 sed -i "s/VAR//g" ${CONF}
 fi
done <<< "${NEWCONF}"
msg -azu "$(fun_trans "AGUARDE")"
service dropbear restart &>/dev/null
sleep 1s
msg -bar
msg -azu "$(fun_trans "PUERTOS REDEFINIDOS")"
msg -bar
}
edit_openssh () {
msg -azu "$(fun_trans "REDEFINIR PUERTOS OPENSSH")"
msg -bar
local CONF="$prefix/ssh/sshd_config"
local NEWCONF="$(cat ${CONF}|grep -v [Pp]ort)"
msg -ne "$(fun_trans "Nuevos Puertos"): "
read -p "" newports
for PTS in `echo ${newports}`; do
verify_port sshd "${PTS}" && echo -e "\033[1;33mPort $PTS \033[1;32mOK" || {
echo -e "\033[1;33mPort $PTS \033[1;31mFAIL"
return 1
}
done
rm ${CONF}
for NPT in $(echo ${newports}); do
echo -e "Port ${NPT}" >> ${CONF}
done
while read varline; do
echo -e "${varline}" >> ${CONF}
done <<< "${NEWCONF}"
msg -azu "$(fun_trans "AGUARDE")"
service ssh restart &>/dev/null
service sshd restart &>/dev/null
sleep 1s
msg -bar
msg -azu "$(fun_trans "PUERTOS REDEFINIDOS")"
msg -bar
}

main_fun () {
msg -bar2
 ""
msg -ama "                EDITAR PUERTOS ACTIVOS "
msg -bar
lacasita
msg -bar2
unset newports
i=0
while read line; do
let i++
          case $line in
          squid|squid3)squid=$i;; 
          apache|apache2)apache=$i;; 
          openvpn)openvpn=$i;; 
          dropbear)dropbear=$i;; 
          sshd)ssh=$i;; 
          esac
done <<< "$(port|cut -d' ' -f1|sort -u)"
for((a=1; a<=$i; a++)); do
[[ $squid = $a ]] && echo -ne "\033[1;32m [$squid] > " && msg -azu "$(fun_trans "REDEFINIR PUERTOS SQUID")"
[[ $apache = $a ]] && echo -ne "\033[1;32m [$apache] > " && msg -azu "$(fun_trans "REDEFINIR PUERTOS APACHE")"
[[ $openvpn = $a ]] && echo -ne "\033[1;32m [$openvpn] > " && msg -azu "$(fun_trans "REDEFINIR PUERTOS OPENVPN")"
[[ $dropbear = $a ]] && echo -ne "\033[1;32m [$dropbear] > " && msg -azu "$(fun_trans "REDEFINIR PUERTOS DROPBEAR")"
[[ $ssh = $a ]] && echo -ne "\033[1;32m [$ssh] > " && msg -azu "$(fun_trans "REDEFINIR PUERTOS SSH")"
done
echo -ne "$(msg -bar)\n\033[1;32m [0] > " && msg -azu "\e[97m\033[1;41m VOLVER \033[1;37m"
msg -bar
while true; do
echo -ne "\033[1;37m$(fun_trans "Seleccione"): " && read selection
tput cuu1 && tput dl1
[[ ! -z $squid ]] && [[ $squid = $selection ]] && edit_squid && break
[[ ! -z $apache ]] && [[ $apache = $selection ]] && edit_apache && break
[[ ! -z $openvpn ]] && [[ $openvpn = $selection ]] && edit_openvpn && break
[[ ! -z $dropbear ]] && [[ $dropbear = $selection ]] && edit_dropbear && break
[[ ! -z $ssh ]] && [[ $ssh = $selection ]] && edit_openssh && break
[[ "0" = $selection ]] && break
done
#exit 0
}
main_fun
}

function _squidpass(){

squidpass () {
tmp_arq="/tmp/arq-tmp"
if [ -d "$prefix/squid" ]; then
pwd="$prefix/squid/passwd"
config_="$prefix/squid/squid.conf"
service_="squid"
squid_="0"
elif [ -d "$prefix/squid3" ]; then
pwd="$prefix/squid3/passwd"
config_="$prefix/squid3/squid.conf"
service_="squid3"
squid_="1"
fi
msg -bar
echo -e " \033[1;36m Proxy Squid no Instalado no puede proseguir"
msg -bar
return 0
if [ -e $pwd ]; then 
echo -e "${cor[3]} Desea Desactivar Autentificasion del Proxy Squid"
read -p " [S/N]: " -e -i n sshsn
[[ "$sshsn" = @(s|S|y|Y) ]] && {
msg -bar
echo -e " \033[1;36mDesintalando Dependencias:"
rm -rf /usr/bin/squid_log1
fun_bar 'apt-get remove apache2-utils'
msg -bar
cat $config_ | grep -v '#Password' > $tmp_arq
mv -f $tmp_arq $config_ 
cat $config_ | grep -v '^auth_param.*passwd*$' > $tmp_arq
mv -f $tmp_arq $config_ 
cat $config_ | grep -v '^auth_param.*proxy*$' > $tmp_arq
mv -f $tmp_arq $config_ 
cat $config_ | grep -v '^acl.*REQUIRED*$' > $tmp_arq
mv -f $tmp_arq $config_ 
cat $config_ | grep -v '^http_access.*authenticated*$' > $tmp_arq
mv -f $tmp_arq $config_ 
cat $config_ | grep -v '^http_access.*all*$' > $tmp_arq
mv -f $tmp_arq $config_ 
echo -e "
http_access allow all" >> "$config_"
rm -f $pwd
service $service_ restart  > /dev/null 2>&1 &
echo -e " \033[1;31m Desautentificasion de Proxy Squid Desactivado"
msg -bar
} 
else
echo -e "${cor[3]} "Habilitar Autenfificasion de Proxy Squid?""
read -p " [S/N]: " -e -i n sshsn
[[ "$sshsn" = @(s|S|y|Y) ]] && {
msg -bar
echo -e " \033[1;36mInstalando Dependencias:"
echo "Archivo SQUID PASS" > /usr/bin/squid_log1
fun_bar 'apt-get install apache2-utils'
msg -bar
read -e -p " Tu nombre de usuario deseado: " usrn
[[ $usrn = "" ]] && 
msg -bar && 
echo -e " \033[1;31mEl usuario no puede ser nulo" && 
msg -bar && 
return 0
htpasswd -c $pwd $usrn
succes_=$(grep -c "$usrn" $pwd)
if [ "$succes_" = "0" ]; then
rm -f $pwd
msg -bar
echo -e " \033[1;31m Error al generar la contrase�a, no se inici� la autenticaci�n de Squid"
msg -bar
return 0
elif [[ "$succes_" = "1" ]]; then
cat $config_ | grep -v '^http_access.*all*$' > $tmp_arq
mv -f $tmp_arq $config_ 
if [ "$squid_" = "0" ]; then
echo -e "#Password
auth_param basic program /usr/lib/squid/basic_ncsa_auth $prefix/squid/passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all" >> "$config_"
service squid restart  > /dev/null 2>&1 &
update-rc.d squid defaults > /dev/null 2>&1 &
elif [ "$squid_" = "1" ]; then
echo -e "#Password
auth_param basic program /usr/lib/squid3/basic_ncsa_auth $prefix/squid3/passwd
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all" >> "$config_"
service squid3 restart > /dev/null 2>&1 &
update-rc.d squid3 defaults > /dev/null 2>&1 &
fi
msg -bar
service squid restart > /dev/null 2>&1
echo -e " \033[1;32m PROTECCION DE PROXY INICIADA"
msg -bar
fi
}
fi 
}

msg -ama "            AUTENTIFICAR PROXY SQUID "
msg -bar
unset squid_log1
[[ -e /usr/bin/squid_log1 ]] && squid_log1="\033[1;32m$(source trans -b pt:${id} "ACTIVO")"
echo -e "${cor[2]} [1] > ${cor[3]}AUTENTIFICAR O DESAUTENTIFICAR PROXY $squid_log1"
echo -e "${cor[2]} [0] > ${cor[4]}VOLVER"
msg -bar
echo -ne "\033[1;37mEscoja una Opcion: "
read optons
case $optons in
0)
msg -bar
exit
;;
1)
msg -bar
squidpass
;;
esac
#REINICIANDO VPS-MX (SQUID)
[[ "$1" = "1" ]] && squidpass
####_Eliminar_Tmps_####
[[ -e $_tmp ]] && rm $_tmp
[[ -e $_tmp2 ]] && rm $_tmp2
[[ -e $_tmp3 ]] && rm $_tmp3
[[ -e $_tmp4 ]] && rm $_tmp4
}

function _tcp(){

sh_ver="2.0"
amarillo="\e[33m" && bla="\e[1;37m" && final="\e[0m"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Informacion]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Atencion]${Font_color_suffix}"

remove_all(){
sed -i '/net.core.default_qdisc/d' $prefix/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' $prefix/sysctl.conf
echo -e "\e[1;31m ACELERADOR BBR DESINSTALADA\e[0m"
}

startbbr(){
	remove_all
	echo "net.core.default_qdisc=fq" >> $prefix/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> $prefix/sysctl.conf
	sysctl -p
	echo -e "${Info}¡BBR comenzó con éxito!"
	msg -bar
}

#Habilitar BBRplus
startbbrplus(){
	remove_all
	echo "net.core.default_qdisc=fq" >> $prefix/sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbrplus" >> $prefix/sysctl.conf
	sysctl -p
	echo -e "${Info}BBRplus comenzó con éxito!！"
	msg -bar
}

# Menú de inicio
start_menu(){
clear
msg -bar

echo -e " TCP Aceleración (BBR/Plus) ${Red_font_prefix}By @lacasitamx${Font_color_suffix}
$(msg -bar)
 ${Green_font_prefix}[ 1 ]${Font_color_suffix} Acelerar VPS Con BBR ${amarillo}(recomendado)${final}
 ${Green_font_prefix}[ 2 ]${Font_color_suffix} Acelerar VPS Con BBRplus
 ${Green_font_prefix}[ 3 ]${Font_color_suffix} Detener Acelerador VPS
 ${Green_font_prefix}[ 0 ]${Font_color_suffix} Salir del script" && msg -bar

	run_status=`grep "net.ipv4.tcp_congestion_control" $prefix/sysctl.conf | awk -F "=" '{print $2}'`
	if [[ ${run_status} ]]; then
	echo -e " Estado actual: ${Green_font_prefix}Instalado\n${Font_color_suffix} ${_font_prefix}BBR Comenzó exitosamente${Font_color_suffix} Kernel Acelerado, ${amarillo}${run_status}${Font_color_suffix}"
	else
	echo -e " Estado actual: ${Green_font_prefix}No instalado\n${Font_color_suffix} Kernel Acelerado: ${Red_font_prefix}Por favor,instale el Acelerador primero.${Font_color_suffix}"
	fi
msg -bar
read -p "$(echo -e "\e[31m► ${bla}Selecione Una Opcion [0-3]:${amarillo}") " num
case "$num" in
	0) ;;
	1) startbbr ;;
	2) startbbrplus ;;
	3) remove_all ;;
	*)
	clear
	echo -e "${Error}:Por favor ingrese el número correcto [0-3]"
	sleep 1s
	start_menu
	;;
esac
}

check_sys(){
	if [[ -f $prefix/redhat-release ]]; then
		release="centos"
	elif cat $prefix/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat $prefix/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat $prefix/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

#Verifique la versión de Linux
check_version(){
	if [[ -s $prefix/redhat-release ]]; then
		version=`grep -oE  "[0-9.]+" $prefix/redhat-release | cut -d . -f 1`
	else
		version=`grep -oE  "[0-9.]+" $prefix/issue | cut -d . -f 1`
	fi
	bit=`uname -m`
	if [[ ${bit} = "x86_64" ]]; then
		bit="x64"
	else
		bit="x32"
	fi
}
check_sys
check_version
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} Este script no es compatible con el sistema actual. ${release} !" && exit 1
start_menu
}

selection_funnn(){
 case $1 in
 --creardemo)_CrearDemo;; # herramienta: CrearDemo
 --apacheon)_apacheon;; # herramienta: apacheon
 --blockBT)_blockBT;; # herramienta: blockBT
 --dnsnetflix)_dnsnetflix;; # herramienta: dnsnetflix
 --fai2ban)_fai2ban;; # herramienta: fai2ban
 --herramientas)_herramientas;; # herramienta: herramientas
 --paysnd)_paysnd;; # herramienta: paysnd
 --ports)_ports;; # herramienta: ports
 --squidpass)_squidpass;; # herramienta: squidpass
 --tcp)_tcp;; # herramienta: tcp
 --x)_x;; # herramienta: x
 esac
}

[[ -z $1 ]] && exit 1

 case $@ in
  "$@") selection_funnn "$@";;
 esac

