
function _CSSR(){
BARRA1="\e[0;31m--------------------------------------------------------------------\e[0m"

sh_ver="1.0.26"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
ssr_folder="/usr/local/shadowsocksr"
config_file="${ssr_folder}/config.json"
config_user_file="${ssr_folder}/user-config.json"
config_user_api_file="${ssr_folder}/userapiconfig.py"
config_user_mudb_file="${ssr_folder}/mudb.json"
ssr_log_file="${ssr_folder}/ssserver.log"
Libsodiumr_file="/usr/local/lib/libsodium.so"
Libsodiumr_ver_backup="1.0.16"
Server_Speeder_file="/serverspeeder/bin/serverSpeeder.sh"
LotServer_file="/appex/bin/serverSpeeder.sh"
BBR_file="${file}/bbr.sh"
jq_file="${ssr_folder}/jq"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[ INFORMACION ]${Font_color_suffix}"
Error="${Red_font_prefix}[# ERROR #]${Font_color_suffix}"
Tip="${Green_font_prefix}[ NOTA ]${Font_color_suffix}"
Separator_1="——————————————————————————————"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} La cuenta actual no es ROOT (no tiene permiso ROOT), no puede continuar la operacion, por favor ${Green_background_prefix} sudo su ${Font_color_suffix} Venga a ROOT (le pedire que ingrese la contraseña de la cuenta actual despues de la ejecucion)" && exit 1
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
	bit=`uname -m`
}
check_pid(){
	PID=`ps -ef |grep -v grep | grep server.py |awk '{print $2}'`
}
check_crontab(){
	[[ ! -e "/usr/bin/crontab" ]] && echo -e "${Error}Falta de dependencia Crontab, Por favor, intente instalar manualmente CentOS: yum install crond -y , Debian/Ubuntu: apt-get install cron -y !" && exit 1
}
SSR_installation_status(){
	[[ ! -e ${ssr_folder} ]] && echo -e "${Error}\nShadowsocksR No se encontro la carpeta, por favor verifique\n$(msg -bar)" && exit 1
}
Server_Speeder_installation_status(){
	[[ ! -e ${Server_Speeder_file} ]] && echo -e "${Error}No instalado (Server Speeder), Por favor compruebe!" && exit 1
}
LotServer_installation_status(){
	[[ ! -e ${LotServer_file} ]] && echo -e "${Error}No instalado LotServer, Por favor revise!" && exit 1
}
BBR_installation_status(){
	if [[ ! -e ${BBR_file} ]]; then
		echo -e "${Error} No encontre el script de BBR, comience a descargar ..."
		cd "${file}"
		if ! wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/bbr.sh; then
			echo -e "${Error} BBR script descargar!" && exit 1
		else
			echo -e "${Info} BBR script descarga completa!"
			chmod +x bbr.sh
		fi
	fi
}
#Establecer reglas de firewall
Add_iptables(){
	if [[ ! -z "${ssr_port}" ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssr_port} -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssr_port} -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ssr_port} -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport ${ssr_port} -j ACCEPT
	fi
}
Del_iptables(){
	if [[ ! -z "${port}" ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	fi
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
	else
		iptables-save > $prefix/iptables.up.rules
		ip6tables-save > $prefix/ip6tables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		service ip6tables save
		chkconfig --level 2345 iptables on
		chkconfig --level 2345 ip6tables on
	else
		iptables-save > $prefix/iptables.up.rules
		ip6tables-save > $prefix/ip6tables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < $prefix/iptables.up.rules\n/sbin/ip6tables-restore < $prefix/ip6tables.up.rules' > $prefix/network/if-pre-up.d/iptables
		chmod +x $prefix/network/if-pre-up.d/iptables
	fi
}
#Leer la informaci�n de configuraci�n
Get_IP(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
}
Get_User_info(){
	Get_user_port=$1
	user_info_get=$(python mujson_mgr.py -l -p "${Get_user_port}")
	match_info=$(echo "${user_info_get}"|grep -w "### user ")
	if [[ -z "${match_info}" ]]; then
		echo -e "${Error}La adquisicion de informacion del usuario fallo ${Green_font_prefix}[Puerto: ${ssr_port}]${Font_color_suffix} " && exit 1
	fi
	user_name=$(echo "${user_info_get}"|grep -w "user :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	port=$(echo "${user_info_get}"|grep -w "port :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	password=$(echo "${user_info_get}"|grep -w "passwd :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	method=$(echo "${user_info_get}"|grep -w "method :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	protocol=$(echo "${user_info_get}"|grep -w "protocol :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	protocol_param=$(echo "${user_info_get}"|grep -w "protocol_param :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	[[ -z ${protocol_param} ]] && protocol_param="0(Ilimitado)"
msg -bar
	obfs=$(echo "${user_info_get}"|grep -w "obfs :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	#transfer_enable=$(echo "${user_info_get}"|grep -w "transfer_enable :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}'|awk -F "ytes" '{print $1}'|sed 's/KB/ KB/;s/MB/ MB/;s/GB/ GB/;s/TB/ TB/;s/PB/ PB/')
	#u=$(echo "${user_info_get}"|grep -w "u :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
	#d=$(echo "${user_info_get}"|grep -w "d :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
	forbidden_port=$(echo "${user_info_get}"|grep -w "Puerto prohibido :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
	[[ -z ${forbidden_port} ]] && forbidden_port="Permitir todo"
msg -bar
	speed_limit_per_con=$(echo "${user_info_get}"|grep -w "speed_limit_per_con :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	speed_limit_per_user=$(echo "${user_info_get}"|grep -w "speed_limit_per_user :"|sed 's/[[:space:]]//g'|awk -F ":" '{print $NF}')
msg -bar
	Get_User_transfer "${port}"
}
Get_User_transfer(){
	transfer_port=$1
	#echo "transfer_port=${transfer_port}"
	all_port=$(${jq_file} '.[]|.port' ${config_user_mudb_file})
	#echo "all_port=${all_port}"
	port_num=$(echo "${all_port}"|grep -nw "${transfer_port}"|awk -F ":" '{print $1}')
	#echo "port_num=${port_num}"
	port_num_1=$(expr ${port_num} - 1)
	#echo "port_num_1=${port_num_1}"
	transfer_enable_1=$(${jq_file} ".[${port_num_1}].transfer_enable" ${config_user_mudb_file})
	#echo "transfer_enable_1=${transfer_enable_1}"
	u_1=$(${jq_file} ".[${port_num_1}].u" ${config_user_mudb_file})
	#echo "u_1=${u_1}"
	d_1=$(${jq_file} ".[${port_num_1}].d" ${config_user_mudb_file})
	#echo "d_1=${d_1}"
	transfer_enable_Used_2_1=$(expr ${u_1} + ${d_1})
	#echo "transfer_enable_Used_2_1=${transfer_enable_Used_2_1}"
	transfer_enable_Used_1=$(expr ${transfer_enable_1} - ${transfer_enable_Used_2_1})
	#echo "transfer_enable_Used_1=${transfer_enable_Used_1}"
	
	
	if [[ ${transfer_enable_1} -lt 1024 ]]; then
		transfer_enable="${transfer_enable_1} B"
	elif [[ ${transfer_enable_1} -lt 1048576 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1024'}')
		transfer_enable="${transfer_enable} KB"
	elif [[ ${transfer_enable_1} -lt 1073741824 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1048576'}')
		transfer_enable="${transfer_enable} MB"
	elif [[ ${transfer_enable_1} -lt 1099511627776 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1073741824'}')
		transfer_enable="${transfer_enable} GB"
	elif [[ ${transfer_enable_1} -lt 1125899906842624 ]]; then
		transfer_enable=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_1}'/'1099511627776'}')
		transfer_enable="${transfer_enable} TB"
	fi
	#echo "transfer_enable=${transfer_enable}"
	if [[ ${u_1} -lt 1024 ]]; then
		u="${u_1} B"
	elif [[ ${u_1} -lt 1048576 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1024'}')
		u="${u} KB"
	elif [[ ${u_1} -lt 1073741824 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1048576'}')
		u="${u} MB"
	elif [[ ${u_1} -lt 1099511627776 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1073741824'}')
		u="${u} GB"
	elif [[ ${u_1} -lt 1125899906842624 ]]; then
		u=$(awk 'BEGIN{printf "%.2f\n",'${u_1}'/'1099511627776'}')
		u="${u} TB"
	fi
	#echo "u=${u}"
	if [[ ${d_1} -lt 1024 ]]; then
		d="${d_1} B"
	elif [[ ${d_1} -lt 1048576 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1024'}')
		d="${d} KB"
	elif [[ ${d_1} -lt 1073741824 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1048576'}')
		d="${d} MB"
	elif [[ ${d_1} -lt 1099511627776 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1073741824'}')
		d="${d} GB"
	elif [[ ${d_1} -lt 1125899906842624 ]]; then
		d=$(awk 'BEGIN{printf "%.2f\n",'${d_1}'/'1099511627776'}')
		d="${d} TB"
	fi
	#echo "d=${d}"
	if [[ ${transfer_enable_Used_1} -lt 1024 ]]; then
		transfer_enable_Used="${transfer_enable_Used_1} B"
	elif [[ ${transfer_enable_Used_1} -lt 1048576 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1024'}')
		transfer_enable_Used="${transfer_enable_Used} KB"
	elif [[ ${transfer_enable_Used_1} -lt 1073741824 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1048576'}')
		transfer_enable_Used="${transfer_enable_Used} MB"
	elif [[ ${transfer_enable_Used_1} -lt 1099511627776 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1073741824'}')
		transfer_enable_Used="${transfer_enable_Used} GB"
	elif [[ ${transfer_enable_Used_1} -lt 1125899906842624 ]]; then
		transfer_enable_Used=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_1}'/'1099511627776'}')
		transfer_enable_Used="${transfer_enable_Used} TB"
	fi
	#echo "transfer_enable_Used=${transfer_enable_Used}"
	if [[ ${transfer_enable_Used_2_1} -lt 1024 ]]; then
		transfer_enable_Used_2="${transfer_enable_Used_2_1} B"
	elif [[ ${transfer_enable_Used_2_1} -lt 1048576 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1024'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} KB"
	elif [[ ${transfer_enable_Used_2_1} -lt 1073741824 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1048576'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} MB"
	elif [[ ${transfer_enable_Used_2_1} -lt 1099511627776 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1073741824'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} GB"
	elif [[ ${transfer_enable_Used_2_1} -lt 1125899906842624 ]]; then
		transfer_enable_Used_2=$(awk 'BEGIN{printf "%.2f\n",'${transfer_enable_Used_2_1}'/'1099511627776'}')
		transfer_enable_Used_2="${transfer_enable_Used_2} TB"
	fi
	#echo "transfer_enable_Used_2=${transfer_enable_Used_2}"
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
ss_link_qr(){
	SSbase64=$(urlsafe_base64 "${method}:${password}@${ip}:${port}")
	SSurl="ss://${SSbase64}"
	SSQRcode="http://www.codigos-qr.com/qr/php/qr_img.php?d=${SSurl}"
	ss_link=" SS    Link :\n ${Green_font_prefix}${SSurl}${Font_color_suffix} \n Codigo QR SS:\n ${Green_font_prefix}${SSQRcode}${Font_color_suffix}"
}
ssr_link_qr(){
	SSRprotocol=$(echo ${protocol} | sed 's/_compatible//g')
	SSRobfs=$(echo ${obfs} | sed 's/_compatible//g')
	SSRPWDbase64=$(urlsafe_base64 "${password}")
	SSRbase64=$(urlsafe_base64 "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}")
	SSRurl="ssr://${SSRbase64}"
	SSRQRcode="http://www.codigos-qr.com/qr/php/qr_img.php?d=${SSRurl}"
	ssr_link=" SSR   Link :\n ${Red_font_prefix}${SSRurl}${Font_color_suffix} \n Codigo QR SSR:\n ${Red_font_prefix}${SSRQRcode}${Font_color_suffix}"
}
ss_ssr_determine(){
	protocol_suffix=`echo ${protocol} | awk -F "_" '{print $NF}'`
	obfs_suffix=`echo ${obfs} | awk -F "_" '{print $NF}'`
	if [[ ${protocol} = "origin" ]]; then
		if [[ ${obfs} = "plain" ]]; then
			ss_link_qr
			ssr_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				ss_link=""
			else
				ss_link_qr
			fi
		fi
	else
		if [[ ${protocol_suffix} != "compatible" ]]; then
			ss_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				if [[ ${obfs_suffix} = "plain" ]]; then
					ss_link_qr
				else
					ss_link=""
				fi
			else
				ss_link_qr
			fi
		fi
	fi
	ssr_link_qr
}
# Display configuration information
View_User(){
clear
	SSR_installation_status
	List_port_user
	while true
	do
		echo -e "Ingrese el puerto de usuario para ver la informacion\nde la cuenta completa"
msg -bar
		stty erase '^H' && read -p "(Predeterminado: cancelar):" View_user_port
		[[ -z "${View_user_port}" ]] && echo -e "Cancelado ...\n$(msg -bar)" && exit 1
		View_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${View_user_port}"',')
		if [[ ! -z ${View_user} ]]; then
			Get_User_info "${View_user_port}"
			View_User_info
			break
		else
			echo -e "${Error} Por favor ingrese el puerto correcto !"
		fi
	done
#read -p "Enter para continuar" enter
}
View_User_info(){
	ip=$(cat ${config_user_api_file}|grep "SERVER_PUB_ADDR = "|awk -F "[']" '{print $2}')
	[[ -z "${ip}" ]] && Get_IP
	ss_ssr_determine
	clear 
	echo -e " Usuario [{user_name}] Informacion de Cuenta:"
msg -bar
    echo -e " PANEL VPS-MX"
	
	echo -e " IP : ${Green_font_prefix}${ip}${Font_color_suffix}"

	echo -e " Puerto : ${Green_font_prefix}${port}${Font_color_suffix}"

	echo -e " Contraseña : ${Green_font_prefix}${password}${Font_color_suffix}"

	echo -e " Encriptacion : ${Green_font_prefix}${method}${Font_color_suffix}"

	echo -e " Protocol : ${Red_font_prefix}${protocol}${Font_color_suffix}"

	echo -e " Obfs : ${Red_font_prefix}${obfs}${Font_color_suffix}"

	echo -e " Limite de dispositivos: ${Green_font_prefix}${protocol_param}${Font_color_suffix}"

	echo -e " Velocidad de subproceso Unico: ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"

	echo -e " Velocidad Maxima del Usuario: ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}"

	echo -e " Puertos Prohibido: ${Green_font_prefix}${forbidden_port} ${Font_color_suffix}"

	echo -e " Consumo de sus Datos:\n Carga: ${Green_font_prefix}${u}${Font_color_suffix} + Descarga: ${Green_font_prefix}${d}${Font_color_suffix} = ${Green_font_prefix}${transfer_enable_Used_2}${Font_color_suffix}"
	
         echo -e " Trafico Restante: ${Green_font_prefix}${transfer_enable_Used} ${Font_color_suffix}"
msg -bar
	echo -e " Trafico Total del Usuario: ${Green_font_prefix}${transfer_enable} ${Font_color_suffix}"
msg -bar
	echo -e "${ss_link}"
msg -bar
	echo -e "${ssr_link}"
msg -bar
	echo -e " ${Green_font_prefix} Nota: ${Font_color_suffix}
 En el navegador, abra el enlace del codigo QR, puede\n ver la imagen del codigo QR."
msg -bar
}
#Configuracion de la informacion de configuracion
Set_config_user(){
msg -bar
	echo -ne "\e[92m 1) Ingrese un nombre al usuario que desea Configurar\n (No repetir, o se marcara incorrectamente!)\n"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: VPS-MX):" ssr_user
	[[ -z "${ssr_user}" ]] && ssr_user="VPS-MX"
	echo && echo -e "	Nombre de usuario : ${Green_font_prefix}${ssr_user}${Font_color_suffix}" && echo
}
Set_config_port(){
msg -bar
	while true
	do
	echo -e "\e[92m 2) Por favor ingrese un Puerto para el Usuario "
msg -bar
	stty erase '^H' && read -p "(Predeterminado: 2525):" ssr_port
	[[ -z "$ssr_port" ]] && ssr_port="2525"
	expr ${ssr_port} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_port} -ge 1 ]] && [[ ${ssr_port} -le 65535 ]]; then
			echo && echo -e "	Port : ${Green_font_prefix}${ssr_port}${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Por favor ingrese el numero correcto (1-65535)"
		fi
	else
		echo -e "${Error} Por favor ingrese el numero correcto (1-65535)"
	fi
	done
}
Set_config_password(){
msg -bar
	echo -e "\e[92m 3) Por favor ingrese una contrasena para el Usuario"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: VPS-MX):" ssr_password
	[[ -z "${ssr_password}" ]] && ssr_password="VPS-MX"
	echo && echo -e "	contrasena : ${Green_font_prefix}${ssr_password}${Font_color_suffix}" && echo
}
Set_config_method(){
msg -bar
	echo -e "\e[92m 4) Seleccione tipo de Encriptacion para el Usuario\e[0m
$(msg -bar)
 ${Green_font_prefix} 1.${Font_color_suffix} Ninguno
 ${Green_font_prefix} 2.${Font_color_suffix} rc4
 ${Green_font_prefix} 3.${Font_color_suffix} rc4-md5
 ${Green_font_prefix} 4.${Font_color_suffix} rc4-md5-6
 ${Green_font_prefix} 5.${Font_color_suffix} aes-128-ctr
 ${Green_font_prefix} 6.${Font_color_suffix} aes-192-ctr
 ${Green_font_prefix} 7.${Font_color_suffix} aes-256-ctr
 ${Green_font_prefix} 8.${Font_color_suffix} aes-128-cfb
 ${Green_font_prefix} 9.${Font_color_suffix} aes-192-cfb
 ${Green_font_prefix}10.${Font_color_suffix} aes-256-cfb
 ${Green_font_prefix}11.${Font_color_suffix} aes-128-cfb8
 ${Green_font_prefix}12.${Font_color_suffix} aes-192-cfb8
 ${Green_font_prefix}13.${Font_color_suffix} aes-256-cfb8
 ${Green_font_prefix}14.${Font_color_suffix} salsa20
 ${Green_font_prefix}15.${Font_color_suffix} chacha20
 ${Green_font_prefix}16.${Font_color_suffix} chacha20-ietf
 
 ${Red_font_prefix}17.${Font_color_suffix} xsalsa20
 ${Red_font_prefix}18.${Font_color_suffix} xchacha20
$(msg -bar)
 ${Tip} Para salsa20/chacha20-*:\n Porfavor instale libsodium:\n Opcion 4 en menu principal SSRR"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: 16. chacha20-ietf):" ssr_method
msg -bar
	[[ -z "${ssr_method}" ]] && ssr_method="16"
	if [[ ${ssr_method} == "1" ]]; then
		ssr_method="Ninguno"
	elif [[ ${ssr_method} == "2" ]]; then
		ssr_method="rc4"
	elif [[ ${ssr_method} == "3" ]]; then
		ssr_method="rc4-md5"
	elif [[ ${ssr_method} == "4" ]]; then
		ssr_method="rc4-md5-6"
	elif [[ ${ssr_method} == "5" ]]; then
		ssr_method="aes-128-ctr"
	elif [[ ${ssr_method} == "6" ]]; then
		ssr_method="aes-192-ctr"
	elif [[ ${ssr_method} == "7" ]]; then
		ssr_method="aes-256-ctr"
	elif [[ ${ssr_method} == "8" ]]; then
		ssr_method="aes-128-cfb"
	elif [[ ${ssr_method} == "9" ]]; then
		ssr_method="aes-192-cfb"
	elif [[ ${ssr_method} == "10" ]]; then
		ssr_method="aes-256-cfb"
	elif [[ ${ssr_method} == "11" ]]; then
		ssr_method="aes-128-cfb8"
	elif [[ ${ssr_method} == "12" ]]; then
		ssr_method="aes-192-cfb8"
	elif [[ ${ssr_method} == "13" ]]; then
		ssr_method="aes-256-cfb8"
	elif [[ ${ssr_method} == "14" ]]; then
		ssr_method="salsa20"
	elif [[ ${ssr_method} == "15" ]]; then
		ssr_method="chacha20"
	elif [[ ${ssr_method} == "16" ]]; then
		ssr_method="chacha20-ietf"
	elif [[ ${ssr_method} == "17" ]]; then
		ssr_method="xsalsa20"
	elif [[ ${ssr_method} == "18" ]]; then
		ssr_method="xchacha20"
	else
		ssr_method="aes-256-cfb"
	fi
	echo && echo -e "	Encriptacion: ${Green_font_prefix}${ssr_method}${Font_color_suffix}" && echo
}
Set_config_protocol(){
msg -bar
	echo -e "\e[92m 5) Por favor, seleccione un Protocolo
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} origin
 ${Green_font_prefix}2.${Font_color_suffix} auth_sha1_v4
 ${Green_font_prefix}3.${Font_color_suffix} auth_aes128_md5
 ${Green_font_prefix}4.${Font_color_suffix} auth_aes128_sha1
 ${Green_font_prefix}5.${Font_color_suffix} auth_chain_a
 ${Green_font_prefix}6.${Font_color_suffix} auth_chain_b

 ${Red_font_prefix}7.${Font_color_suffix} auth_chain_c
 ${Red_font_prefix}8.${Font_color_suffix} auth_chain_d
 ${Red_font_prefix}9.${Font_color_suffix} auth_chain_e
 ${Red_font_prefix}10.${Font_color_suffix} auth_chain_f
$(msg -bar)
 ${Tip}\n Si selecciona el protocolo de serie auth_chain_ *:\n Se recomienda establecer el metodo de cifrado en ninguno"
msg -bar
	stty erase '^H' && read -p "(Predterminado: 1. origin):" ssr_protocol
msg -bar
	[[ -z "${ssr_protocol}" ]] && ssr_protocol="1"
	if [[ ${ssr_protocol} == "1" ]]; then
		ssr_protocol="origin"
	elif [[ ${ssr_protocol} == "2" ]]; then
		ssr_protocol="auth_sha1_v4"
	elif [[ ${ssr_protocol} == "3" ]]; then
		ssr_protocol="auth_aes128_md5"
	elif [[ ${ssr_protocol} == "4" ]]; then
		ssr_protocol="auth_aes128_sha1"
	elif [[ ${ssr_protocol} == "5" ]]; then
		ssr_protocol="auth_chain_a"
	elif [[ ${ssr_protocol} == "6" ]]; then
		ssr_protocol="auth_chain_b"
	elif [[ ${ssr_protocol} == "7" ]]; then
		ssr_protocol="auth_chain_c"
	elif [[ ${ssr_protocol} == "8" ]]; then
		ssr_protocol="auth_chain_d"
	elif [[ ${ssr_protocol} == "9" ]]; then
		ssr_protocol="auth_chain_e"
	elif [[ ${ssr_protocol} == "10" ]]; then
		ssr_protocol="auth_chain_f"
	else
		ssr_protocol="origin"
	fi
	echo && echo -e "	Protocolo : ${Green_font_prefix}${ssr_protocol}${Font_color_suffix}" && echo
	if [[ ${ssr_protocol} != "origin" ]]; then
		if [[ ${ssr_protocol} == "auth_sha1_v4" ]]; then
			stty erase '^H' && read -p "Set protocol plug-in to compatible mode(_compatible)?[Y/n]" ssr_protocol_yn
			[[ -z "${ssr_protocol_yn}" ]] && ssr_protocol_yn="y"
			[[ $ssr_protocol_yn == [Yy] ]] && ssr_protocol=${ssr_protocol}"_compatible"
			echo
		fi
	fi
}
Set_config_obfs(){
msg -bar
	echo -e "\e[92m 6) Por favor, seleccione el metodo OBFS
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} plain
 ${Green_font_prefix}2.${Font_color_suffix} http_simple
 ${Green_font_prefix}3.${Font_color_suffix} http_post
 ${Green_font_prefix}4.${Font_color_suffix} random_head
 ${Green_font_prefix}5.${Font_color_suffix} tls1.2_ticket_auth
$(msg -bar)
  Si elige tls1.2_ticket_auth, entonces el cliente puede\n  elegir tls1.2_ticket_fastauth!"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: 5. tls1.2_ticket_auth):" ssr_obfs
	[[ -z "${ssr_obfs}" ]] && ssr_obfs="5"
	if [[ ${ssr_obfs} == "1" ]]; then
		ssr_obfs="plain"
	elif [[ ${ssr_obfs} == "2" ]]; then
		ssr_obfs="http_simple"
	elif [[ ${ssr_obfs} == "3" ]]; then
		ssr_obfs="http_post"
	elif [[ ${ssr_obfs} == "4" ]]; then
		ssr_obfs="random_head"
	elif [[ ${ssr_obfs} == "5" ]]; then
		ssr_obfs="tls1.2_ticket_auth"
	else
		ssr_obfs="tls1.2_ticket_auth"
	fi
	echo && echo -e "	obfs : ${Green_font_prefix}${ssr_obfs}${Font_color_suffix}" && echo
	msg -bar
	if [[ ${ssr_obfs} != "plain" ]]; then
			stty erase '^H' && read -p "Configurar modo Compatible (Para usar SS)? [y/n]: " ssr_obfs_yn
			[[ -z "${ssr_obfs_yn}" ]] && ssr_obfs_yn="y"
			[[ $ssr_obfs_yn == [Yy] ]] && ssr_obfs=${ssr_obfs}"_compatible"
	fi
}
Set_config_protocol_param(){
msg -bar
	while true
	do
	echo -e "\e[92m 7) Limitar Cantidad de Dispositivos Simultaneos\n  ${Green_font_prefix} auth_*La serie no es compatible con la version original. ${Font_color_suffix}"
msg -bar
	echo -e "${Tip} Limite de numero de dispositivos:\n Es el numero de clientes que usaran la cuenta\n el minimo recomendado 2."
msg -bar
	stty erase '^H' && read -p "(Predeterminado: Ilimitado):" ssr_protocol_param
	[[ -z "$ssr_protocol_param" ]] && ssr_protocol_param="" && echo && break
	expr ${ssr_protocol_param} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_protocol_param} -ge 1 ]] && [[ ${ssr_protocol_param} -le 9999 ]]; then
			echo && echo -e "	Limite del dispositivo: ${Green_font_prefix}${ssr_protocol_param}${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Por favor ingrese el numero correcto (1-9999)"
		fi
	else
		echo -e "${Error} Por favor ingrese el numero correcto (1-9999)"
	fi
	done
}
Set_config_speed_limit_per_con(){
msg -bar
	while true
	do
	echo -e "\e[92m 8) Introduzca un Limite de Velocidad x Hilo (en KB/S)"
msg -bar
	stty erase '^H' && read -p "(Predterminado: Ilimitado):" ssr_speed_limit_per_con
msg -bar
	[[ -z "$ssr_speed_limit_per_con" ]] && ssr_speed_limit_per_con=0 && echo && break
	expr ${ssr_speed_limit_per_con} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_speed_limit_per_con} -ge 1 ]] && [[ ${ssr_speed_limit_per_con} -le 131072 ]]; then
			echo && echo -e "	Velocidad de Subproceso Unico: ${Green_font_prefix}${ssr_speed_limit_per_con} KB/S${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Por favor ingrese el numero correcto (1-131072)"
		fi
	else
		echo -e "${Error} Por favor ingrese el numero correcto (1-131072)"
	fi
	done
}
Set_config_speed_limit_per_user(){
msg -bar
	while true
	do
	echo -e "\e[92m 9) Introduzca un Limite de Velocidad Maxima (en KB/S)"
msg -bar
	echo -e "${Tip} Limite de Velocidad Maxima del Puerto :\n Es la velocidad maxima que ira el Usuario."
msg -bar
	stty erase '^H' && read -p "(Predeterminado: Ilimitado):" ssr_speed_limit_per_user
	[[ -z "$ssr_speed_limit_per_user" ]] && ssr_speed_limit_per_user=0 && echo && break
	expr ${ssr_speed_limit_per_user} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_speed_limit_per_user} -ge 1 ]] && [[ ${ssr_speed_limit_per_user} -le 131072 ]]; then
			echo && echo -e "	Velocidad Maxima del Usuario : ${Green_font_prefix}${ssr_speed_limit_per_user} KB/S${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Por favor ingrese el numero correcto (1-131072)"
		fi
	else
		echo -e "${Error} Por favor ingrese el numero correcto (1-131072)"
	fi
	done
}
Set_config_transfer(){
msg -bar
	while true
	do
	echo -e "\e[92m 10) Ingrese Cantidad Total de Datos para el Usuario\n   (en GB, 1-838868 GB)"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: Ilimitado):" ssr_transfer
	[[ -z "$ssr_transfer" ]] && ssr_transfer="838868" && echo && break
	expr ${ssr_transfer} + 0 &>/dev/null
	if [[ $? == 0 ]]; then
		if [[ ${ssr_transfer} -ge 1 ]] && [[ ${ssr_transfer} -le 838868 ]]; then
			echo && echo -e "	Trafico Total Para El Usuario: ${Green_font_prefix}${ssr_transfer} GB${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} Por favor ingrese el numero correcto (1-838868)"
		fi
	else
		echo -e "${Error} Por favor ingrese el numero correcto (1-838868)"
	fi
	done
}
Set_config_forbid(){
msg -bar
	echo "PROIBIR PUERTOS"
msg -bar
	echo -e "${Tip} Puertos prohibidos:\n Por ejemplo, si no permite el acceso al puerto 25, los\n usuarios no podran acceder al puerto de correo 25 a\n traves del proxy de SSR. Si 80,443 esta desactivado,\n los usuarios no podran acceda a los sitios\n http/https normalmente."
msg -bar
	stty erase '^H' && read -p "(Predeterminado: permitir todo):" ssr_forbid
	[[ -z "${ssr_forbid}" ]] && ssr_forbid=""
	echo && echo -e "	Puerto prohibido: ${Green_font_prefix}${ssr_forbid}${Font_color_suffix}" && echo
}
Set_config_enable(){
	user_total=$(expr ${user_total} - 1)
	for((integer = 0; integer <= ${user_total}; integer++))
	do
		echo -e "integer=${integer}"
		port_jq=$(${jq_file} ".[${integer}].port" "${config_user_mudb_file}")
		echo -e "port_jq=${port_jq}"
		if [[ "${ssr_port}" == "${port_jq}" ]]; then
			enable=$(${jq_file} ".[${integer}].enable" "${config_user_mudb_file}")
			echo -e "enable=${enable}"
			[[ "${enable}" == "null" ]] && echo -e "${Error} Obtenga el puerto actual [${ssr_port}] Estado deshabilitado fallido!" && exit 1
			ssr_port_num=$(cat "${config_user_mudb_file}"|grep -n '"puerto": '${ssr_port}','|awk -F ":" '{print $1}')
			echo -e "ssr_port_num=${ssr_port_num}"
			[[ "${ssr_port_num}" == "null" ]] && echo -e "${Error}Obtener actual Puerto [${ssr_port}] Numero de filas fallidas!" && exit 1
			ssr_enable_num=$(expr ${ssr_port_num} - 5)
			echo -e "ssr_enable_num=${ssr_enable_num}"
			break
		fi
	done
	if [[ "${enable}" == "1" ]]; then
		echo -e "Puerto [${ssr_port}] El estado de la cuenta es: ${Green_font_prefix}Enabled ${Font_color_suffix} , Cambiar a ${Red_font_prefix}Disabled${Font_color_suffix} ?[Y/n]"
		stty erase '^H' && read -p "(Predeterminado: Y):" ssr_enable_yn
		[[ -z "${ssr_enable_yn}" ]] && ssr_enable_yn="y"
		if [[ "${ssr_enable_yn}" == [Yy] ]]; then
			ssr_enable="0"
		else
			echo -e "Cancelado...\n$(msg -bar)" && exit 0
		fi
	elif [[ "${enable}" == "0" ]]; then
		echo -e "Port [${ssr_port}] El estado de la cuenta:${Green_font_prefix}Habilitado ${Font_color_suffix} , Cambie a ${Red_font_prefix}Deshabilitado${Font_color_suffix} ?[Y/n]"
		stty erase '^H' && read -p "(Predeterminado: Y):" ssr_enable_yn
		[[ -z "${ssr_enable_yn}" ]] && ssr_enable_yn = "y"
		if [[ "${ssr_enable_yn}" == [Yy] ]]; then
			ssr_enable="1"
		else
			echo "Cancelar ..." && exit 0
		fi
	else
		echo -e "${Error} El actual estado de discapacidad de Puerto es anormal.[${enable}] !" && exit 1
	fi
}
Set_user_api_server_pub_addr(){
	addr=$1
	if [[ "${addr}" == "Modify" ]]; then
		server_pub_addr=$(cat ${config_user_api_file}|grep "SERVER_PUB_ADDR = "|awk -F "[']" '{print $2}')
		if [[ -z ${server_pub_addr} ]]; then
			echo -e "${Error} La IP del servidor o el nombre de dominio obtenidos fallaron!" && exit 1
		else
			echo -e "${Info} La IP del servidor o el nombre de dominio actualmente configurados es ${Green_font_prefix}${server_pub_addr}${Font_color_suffix}"
		fi
	fi
	echo "Introduzca la IP del servidor o el nombre de dominio que se mostrara en la configuracion del usuario (cuando el servidor tiene varias IP, puede especificar la IP o el nombre de dominio que se muestra en la configuracion del usuario)"
msg -bar
	stty erase '^H' && read -p "(Predeterminado:Deteccion automatica de la red externa IP):" ssr_server_pub_addr
	if [[ -z "${ssr_server_pub_addr}" ]]; then
		Get_IP
		if [[ ${ip} == "VPS_IP" ]]; then
			while true
			do
			stty erase '^H' && read -p "${Error} La deteccion automatica de la IP de la red externa fallo, ingrese manualmente la IP del servidor o el nombre de dominio" ssr_server_pub_addr
			if [[ -z "$ssr_server_pub_addr" ]]; then
				echo -e "${Error}No puede estar vacio!"
			else
				break
			fi
			done
		else
			ssr_server_pub_addr="${ip}"
		fi
	fi
	echo && msg -bar && echo -e "	IP o nombre de dominio: ${Green_font_prefix}${ssr_server_pub_addr}${Font_color_suffix}" && msg -bar && echo
}
Set_config_all(){
	lal=$1
	if [[ "${lal}" == "Modify" ]]; then
		Set_config_password
		Set_config_method
		Set_config_protocol
		Set_config_obfs
		Set_config_protocol_param
		Set_config_speed_limit_per_con
		Set_config_speed_limit_per_user
		Set_config_transfer
		Set_config_forbid
	else
		Set_config_user
		Set_config_port
		Set_config_password
		Set_config_method
		Set_config_protocol
		Set_config_obfs
		Set_config_protocol_param
		Set_config_speed_limit_per_con
		Set_config_speed_limit_per_user
		Set_config_transfer
		Set_config_forbid
	fi
}
#Modificar la informaci�n de configuraci�n
Modify_config_password(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -k "${ssr_password}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Fallo la modificacion de la contrasena del usuario ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} La contrasena del usuario se modifico correctamente ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Puede tardar unos 10 segundos aplicar la ultima configuracion)"
	fi
}
Modify_config_method(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -m "${ssr_method}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} La modificacion del metodo de cifrado del usuario fallo ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Modo de cifrado de usuario ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Note: Nota: la configuracion mas reciente puede demorar unos 10 segundos)"
	fi
}
Modify_config_protocol(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -O "${ssr_protocol}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Fallo la modificacion del protocolo de usuario ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Acuerdo de usuario modificacion exito ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Nota: la configuracion m�s reciente puede demorar unos 10 segundos)"
	fi
}
Modify_config_obfs(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -o "${ssr_obfs}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} La modificacion de la confusion del usuario fallo ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Confusion del usuario exito de modificacion ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Nota: La aplicacion de la ultima configuracion puede demorar unos 10 segundos)"
	fi
}
Modify_config_protocol_param(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -G "${ssr_protocol_param}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Fallo la modificacion del parametro del protocolo del usuario (numero de dispositivos limite) ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Parametros de negociaci�n del usuario (numero de dispositivos limite) modificados correctamente ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Nota: puede tomar aproximadamente 10 segundos aplicar la ultima configuracion)"
	fi
}
Modify_config_speed_limit_per_con(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -s "${ssr_speed_limit_per_con}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Fallo la modificacion de la velocidad de un solo hilo ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Modificacion de la velocidad de un solo hilo exitosa ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Nota: puede tomar aproximadamente 10 segundos aplicar la ultima configuracion)"
	fi
}
Modify_config_speed_limit_per_user(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -S "${ssr_speed_limit_per_user}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} Usuario Puerto la modificaci�n del limite de velocidad total fallo ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Usuario Puerto limite de velocidad total modificado con exito ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Nota: la configuracion mas reciente puede demorar unos 10 segundos)"
	fi
}
Modify_config_connect_verbose_info(){
	sed -i 's/"connect_verbose_info": '"$(echo ${connect_verbose_info})"',/"connect_verbose_info": '"$(echo ${ssr_connect_verbose_info})"',/g' ${config_user_file}
}
Modify_config_transfer(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -t "${ssr_transfer}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} La modificacion de trafico total del usuario fallo ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Trafico total del usuario ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Nota: la configuracion mas reciente puede demorar unos 10 segundos)"
	fi
}
Modify_config_forbid(){
	match_edit=$(python mujson_mgr.py -e -p "${ssr_port}" -f "${ssr_forbid}"|grep -w "edit user ")
	if [[ -z "${match_edit}" ]]; then
		echo -e "${Error} La modificacion del puerto prohibido por el usuario ha fallado ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} " && exit 1
	else
		echo -e "${Info} Los puertos prohibidos por el usuario se modificaron correctamente ${Green_font_prefix}[Port: ${ssr_port}]${Font_color_suffix} (Nota: puede tomar aproximadamente 10 segundos aplicar la ultima configuracion)"
	fi
}
Modify_config_enable(){
	sed -i "${ssr_enable_num}"'s/"enable": '"$(echo ${enable})"',/"enable": '"$(echo ${ssr_enable})"',/' ${config_user_mudb_file}
}
Modify_user_api_server_pub_addr(){
	sed -i "s/SERVER_PUB_ADDR = '${server_pub_addr}'/SERVER_PUB_ADDR = '${ssr_server_pub_addr}'/" ${config_user_api_file}
}
Modify_config_all(){
	Modify_config_password
	Modify_config_method
	Modify_config_protocol
	Modify_config_obfs
	Modify_config_protocol_param
	Modify_config_speed_limit_per_con
	Modify_config_speed_limit_per_user
	Modify_config_transfer
	Modify_config_forbid
}
Check_python(){
	python_ver=`python -h`
	if [[ -z ${python_ver} ]]; then
		echo -e "${Info} No instalo Python, comience a instalar ..."
		if [[ ${release} == "centos" ]]; then
			yum install -y python
		else
			apt-get install -y python
		fi
	fi
}
Centos_yum(){
	yum update
	cat $prefix/redhat-release |grep 7\..*|grep -i centos>/dev/null
	if [[ $? = 0 ]]; then
		yum install -y vim unzip crond net-tools git
	else
		yum install -y vim unzip crond git
	fi
}
Debian_apt(){
	apt-get update
	apt-get install -y vim unzip cron git net-tools
}
#Descargar ShadowsocksR
Download_SSR(){
	cd "/usr/local"
	# wget -N --no-check-certificate "https://github.com/ToyoDAdoubi/shadowsocksr/archive/manyuser.zip"
	#git config --global http.sslVerify false
	git clone -b akkariiin/master https://github.com/shadowsocksrr/shadowsocksr.git
	[[ ! -e ${ssr_folder} ]] && echo -e "${Error} Fallo la descarga del servidor ShadowsocksR!" && exit 1
	# [[ ! -e "manyuser.zip" ]] && echo -e "${Error} Fallo la descarga del paquete de compresion lateral ShadowsocksR !" && rm -rf manyuser.zip && exit 1
	# unzip "manyuser.zip"
	# [[ ! -e "/usr/local/shadowsocksr-manyuser/" ]] && echo -e "${Error} Fallo la descompresi�n del servidor ShadowsocksR !" && rm -rf manyuser.zip && exit 1
	# mv "/usr/local/shadowsocksr-manyuser/" "/usr/local/shadowsocksr/"
	# [[ ! -e "/usr/local/shadowsocksr/" ]] && echo -e "${Error} Fallo el cambio de nombre del servidor ShadowsocksR!" && rm -rf manyuser.zip && rm -rf "/usr/local/shadowsocksr-manyuser/" && exit 1
	# rm -rf manyuser.zip
	cd "shadowsocksr"
	cp "${ssr_folder}/config.json" "${config_user_file}"
	cp "${ssr_folder}/mysql.json" "${ssr_folder}/usermysql.json"
	cp "${ssr_folder}/apiconfig.py" "${config_user_api_file}"
	[[ ! -e ${config_user_api_file} ]] && echo -e "${Error} Fallo la replicacion apiconfig.py del servidor ShadowsocksR!" && exit 1
	sed -i "s/API_INTERFACE = 'sspanelv2'/API_INTERFACE = 'mudbjson'/" ${config_user_api_file}
	server_pub_addr="127.0.0.1"
	Modify_user_api_server_pub_addr
	#sed -i "s/SERVER_PUB_ADDR = '127.0.0.1'/SERVER_PUB_ADDR = '${ip}'/" ${config_user_api_file}
	sed -i 's/ \/\/ only works under multi-user mode//g' "${config_user_file}"
	echo -e "${Info} Descarga del servidor ShadowsocksR completa!"
}
Service_SSR(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ssrmu_centos -O $prefix/init.d/ssrmu; then
			echo -e "${Error} Fallo la descarga de la secuencia de comandos de administracion de servicios de ShadowsocksR!" && exit 1
		fi
		chmod +x $prefix/init.d/ssrmu
		chkconfig --add ssrmu
		chkconfig ssrmu on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ssrmu_debian -O $prefix/init.d/ssrmu; then
			echo -e "${Error} Fallo la descarga de la secuencia de comandos de administracion de servicio de ShadowsocksR!" && exit 1
		fi
		chmod +x $prefix/init.d/ssrmu
		update-rc.d -f ssrmu defaults
	fi
	echo -e "${Info} ShadowsocksR Service Management Script Descargar Descargar!"
}
#Instalar el analizador JQ
JQ_install(){
	if [[ ! -e ${jq_file} ]]; then
		cd "${ssr_folder}"
		if [[ ${bit} = "x86_64" ]]; then
			# mv "jq-linux64" "jq"
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -O ${jq_file}
		else
			# mv "jq-linux32" "jq"
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux32" -O ${jq_file}
		fi
		[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ parser, por favor!" && exit 1
		chmod +x ${jq_file}
		echo -e "${Info} La instalacion del analizador JQ se ha completado, continuar ..." 
	else
		echo -e "${Info} JQ parser esta instalado, continuar ..."
	fi
}
#Instalacion
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		Centos_yum
	else
		Debian_apt
	fi
	[[ ! -e "/usr/bin/unzip" ]] && echo -e "${Error} Dependiente de la instalacion de descomprimir (paquete comprimido) fallo, en su mayoria problema, por favor verifique!" && exit 1
	Check_python
	#echo "nameserver 8.8.8.8" > $prefix/resolv.conf
	#echo "nameserver 8.8.4.4" >> $prefix/resolv.conf
	cp -f /usr/share/zoneinfo/Asia/Shanghai $prefix/localtime
	if [[ ${release} == "centos" ]]; then
		$prefix/init.d/crond restart
	else
		$prefix/init.d/cron restart
	fi
}
Install_SSR(){
clear
	check_root
	msg -bar
	[[ -e ${ssr_folder} ]] && echo -e "${Error}\nLa carpeta ShadowsocksR ha sido creada, por favor verifique\n(si la instalacion falla, desinstalela primero) !\n$(msg -bar)" && exit 1 
	echo -e "${Info}\nComience la configuracion de la cuenta de ShadowsocksR..."
msg -bar
	Set_user_api_server_pub_addr
	Set_config_all
	echo -e "${Info} Comience a instalar / configurar las dependencias de ShadowsocksR ..."
	Installation_dependency
	echo -e "${Info} Iniciar descarga / Instalar ShadowsocksR File ..."
	Download_SSR
	echo -e "${Info} Iniciar descarga / Instalar ShadowsocksR Service Script(init)..."
	Service_SSR
	echo -e "${Info} Iniciar descarga / instalar JSNO Parser JQ ..."
	JQ_install
	echo -e "${Info} Comience a agregar usuario inicial ..."
	Add_port_user "install"
	echo -e "${Info} Empezar a configurar el firewall de iptables ..."
	Set_iptables
	echo -e "${Info} Comience a agregar reglas de firewall de iptables ..."
	Add_iptables
	echo -e "${Info} Comience a guardar las reglas del servidor de seguridad de iptables ..."
	Save_iptables
	echo -e "${Info} Todos los pasos para iniciar el servicio ShadowsocksR ..."
	Start_SSR
	Get_User_info "${ssr_port}"
	View_User_info

}
Update_SSR(){
	SSR_installation_status
	# echo -e "Debido a que el beb� roto actualiza el servidor ShadowsocksR, entonces."
	cd ${ssr_folder}
	git pull
	Restart_SSR

}
Uninstall_SSR(){
	[[ ! -e ${ssr_folder} ]] && echo -e "${Error} ShadowsocksR no esta instalado, por favor, compruebe!\n$(msg -bar)" && exit 1
	echo "Desinstalar ShadowsocksR [y/n]"
msg -bar 
	stty erase '^H' && read -p "(Predeterminado: n):" unyn
msg -bar
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z "${PID}" ]] && kill -9 ${PID}
		user_info=$(python mujson_mgr.py -l)
		user_total=$(echo "${user_info}"|wc -l)
		if [[ ! -z ${user_info} ]]; then
			for((integer = 1; integer <= ${user_total}; integer++))
			do
				port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
				Del_iptables
			done
		fi
		if [[ ${release} = "centos" ]]; then
			chkconfig --del ssrmu
		else
			update-rc.d -f ssrmu remove
		fi
		rm -rf ${ssr_folder} && rm -rf $prefix/init.d/ssrmu
		echo && echo " Desinstalacion de ShadowsocksR completada!" && echo
	else
		echo && echo "Desinstalar cancelado ..." && echo
	fi

}
Check_Libsodium_ver(){
	echo -e "${Info} Descargando la ultima version de libsodium"
	#Libsodiumr_ver=$(wget -qO- "https://github.com/jedisct1/libsodium/tags"|grep "/jedisct1/libsodium/releases/tag/"|head -1|sed -r 's/.*tag\/(.+)\">.*/\1/')
	Libsodiumr_ver=1.0.17
	[[ -z ${Libsodiumr_ver} ]] && Libsodiumr_ver=${Libsodiumr_ver_backup}
	echo -e "${Info} La ultima version de libsodium es ${Green_font_prefix}${Libsodiumr_ver}${Font_color_suffix} !"
}
Install_Libsodium(){
	if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "${Error} libsodium ya instalado, quieres actualizar?[y/N]"
		stty erase '^H' && read -p "(Default: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Nn] ]]; then
			echo -e "Cancelado...\n$(msg -bar)" && exit 1
		fi
	else
		echo -e "${Info} libsodium no instalado, instalacion iniciada ..."
	fi
	Check_Libsodium_ver
	if [[ ${release} == "centos" ]]; then
		yum -y actualizacion
		echo -e "${Info} La instalacion depende de ..."
		yum -y groupinstall "Herramientas de desarrollo"
		echo -e "${Info} Descargar ..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} Descomprimir ..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} Compilar e instalar ..."
		./configure --disable-maintainer-mode && make -j2 && make install
		echo /usr/local/lib > $prefix/ld.so.conf.d/usr_local_lib.conf
	else
		apt-get update
		echo -e "${Info} La instalacion depende de ..."
		apt-get install -y build-essential
		echo -e "${Info} Descargar ..."
		wget  --no-check-certificate -N "https://github.com/jedisct1/libsodium/releases/download/${Libsodiumr_ver}/libsodium-${Libsodiumr_ver}.tar.gz"
		echo -e "${Info} Descomprimir ..."
		tar -xzf libsodium-${Libsodiumr_ver}.tar.gz && cd libsodium-${Libsodiumr_ver}
		echo -e "${Info} Compilar e instalar ..."
		./configure --disable-maintainer-mode && make -j2 && make install
	fi
	ldconfig
	cd .. && rm -rf libsodium-${Libsodiumr_ver}.tar.gz && rm -rf libsodium-${Libsodiumr_ver}
	[[ ! -e ${Libsodiumr_file} ]] && echo -e "${Error} libsodium Instalacion fallida!" && exit 1
	echo && echo -e "${Info} libsodium exito de instalacion!" && echo
msg -bar
}
#Mostrar informaci�n de conexi�n
debian_View_user_connection_info(){
	format_1=$1
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} No encontro, por favor compruebe!" && exit 1
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |wc -l`
	user_list_all=""
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp6' |grep ":${user_port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u`
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				get_IP_address
			else
				user_IP=`echo -e "\n${user_IP_1}"`
			fi
		fi
		user_list_all=${user_list_all}"Puerto: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, El numero total de IPs vinculadas: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, Current linked IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		user_IP=""
	done
	echo -e "Numero total de usuarios: ${Green_background_prefix} "${user_total}" ${Font_color_suffix} Numero total de IPs vinculadas: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix}\n"
	echo -e "${user_list_all}"
msg -bar 
}
centos_View_user_connection_info(){
	format_1=$1
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} No encontrado, por favor revise!" && exit 1
	IP_total=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' | grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |wc -l`
	user_list_all=""
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'python' |grep 'tcp' |grep ":${user_port} "|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u`
		if [[ -z ${user_IP_1} ]]; then
			user_IP_total="0"
		else
			user_IP_total=`echo -e "${user_IP_1}"|wc -l`
			if [[ ${format_1} == "IP_address" ]]; then
				get_IP_address
			else
				user_IP=`echo -e "\n${user_IP_1}"`
			fi
		fi
		user_list_all=${user_list_all}"Puerto: ${Green_font_prefix}"${user_port}"${Font_color_suffix}, El numero total de IPs vinculadas: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}, Current linked IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		user_IP=""
	done
	echo -e "El numero total de usuarios: ${Green_background_prefix} "${user_total}" ${Font_color_suffix} El numero total de IPs vinculadas: ${Green_background_prefix} "${IP_total}" ${Font_color_suffix} "
	echo -e "${user_list_all}"
}
View_user_connection_info(){
clear
	SSR_installation_status
	msg -bar
	 echo -e "Seleccione el formato para mostrar :
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} Mostrar IP 

 ${Green_font_prefix}2.${Font_color_suffix} Mostrar IP + Resolver el nombre DNS"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: 1):" ssr_connection_info
msg -bar
	[[ -z "${ssr_connection_info}" ]] && ssr_connection_info="1"
	if [[ ${ssr_connection_info} == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ ${ssr_connection_info} == "2" ]]; then
		echo -e "${Tip} Detectar IP (ipip.net)puede llevar mas tiempo si hay muchas IPs"
msg -bar
		View_user_connection_info_1 "IP_address"
	else
		echo -e "${Error} Ingrese el numero correcto(1-2)" && exit 1
	fi
}
View_user_connection_info_1(){
	format=$1
	if [[ ${release} = "centos" ]]; then
		cat $prefix/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 0 ]]; then
			debian_View_user_connection_info "$format"
		else
			centos_View_user_connection_info "$format"
		fi
	else
		debian_View_user_connection_info "$format"
	fi
}
get_IP_address(){
	#echo "user_IP_1=${user_IP_1}"
	if [[ ! -z ${user_IP_1} ]]; then
	#echo "user_IP_total=${user_IP_total}"
		for((integer_1 = ${user_IP_total}; integer_1 >= 1; integer_1--))
		do
			IP=`echo "${user_IP_1}" |sed -n "$integer_1"p`
			#echo "IP=${IP}"
			IP_address=`wget -qO- -t1 -T2 http://freeapi.ipip.net/${IP}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g'`
			#echo "IP_address=${IP_address}"
			user_IP="${user_IP}\n${IP}(${IP_address})"
			#echo "user_IP=${user_IP}"
			sleep 1s
		done
	fi
}
#Modificar la configuraci�n del usuario
Modify_port(){
msg -bar
	List_port_user
	while true
	do
		echo -e "Por favor ingrese el usuario (Puerto) que tiene que ser modificado" 
msg -bar
		stty erase '^H' && read -p "(Predeterminado: cancelar):" ssr_port
		[[ -z "${ssr_port}" ]] && echo -e "Cancelado ...\n$(msg -bar)" && exit 1
		Modify_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${ssr_port}"',')
		if [[ ! -z ${Modify_user} ]]; then
			break
		else
			echo -e "${Error} Puerto Introduzca el Puerto correcto!"
		fi
	done
}
Modify_Config(){
clear
	SSR_installation_status
	echo && echo -e "    ###¿Que desea realizar?###
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix}  Agregar y Configurar Usuario
 ${Green_font_prefix}2.${Font_color_suffix}  Eliminar la Configuracion del Usuario
————————— Modificar la Configuracion del Usuario ————
 ${Green_font_prefix}3.${Font_color_suffix}  Modificar contrasena de Usuario
 ${Green_font_prefix}4.${Font_color_suffix}  Modificar el metodo de Cifrado
 ${Green_font_prefix}5.${Font_color_suffix}  Modificar el Protocolo
 ${Green_font_prefix}6.${Font_color_suffix}  Modificar Ofuscacion
 ${Green_font_prefix}7.${Font_color_suffix}  Modificar el Limite de Dispositivos
 ${Green_font_prefix}8.${Font_color_suffix}  Modificar el Limite de Velocidad de un solo Hilo
 ${Green_font_prefix}9.${Font_color_suffix}  Modificar limite de Velocidad Total del Usuario
 ${Green_font_prefix}10.${Font_color_suffix} Modificar el Trafico Total del Usuario
 ${Green_font_prefix}11.${Font_color_suffix} Modificar los Puertos Prohibidos Del usuario
 ${Green_font_prefix}12.${Font_color_suffix} Modificar la Configuracion Completa
————————— Otras Configuraciones —————————
 ${Green_font_prefix}13.${Font_color_suffix} Modificar la IP o el nombre de dominio que\n se muestra en el perfil del usuario
$(msg -bar)
 ${Tip} El nombre de usuario y el puerto del usuario\n no se pueden modificar. Si necesita modificarlos, use\n el script para modificar manualmente la funcion !"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: cancelar):" ssr_modify
	[[ -z "${ssr_modify}" ]] && echo -e "Cancelado ...\n$(msg -bar)" && exit 1
	if [[ ${ssr_modify} == "1" ]]; then
		Add_port_user
	elif [[ ${ssr_modify} == "2" ]]; then
		Del_port_user
	elif [[ ${ssr_modify} == "3" ]]; then
		Modify_port
		Set_config_password
		Modify_config_password
	elif [[ ${ssr_modify} == "4" ]]; then
		Modify_port
		Set_config_method
		Modify_config_method
	elif [[ ${ssr_modify} == "5" ]]; then
		Modify_port
		Set_config_protocol
		Modify_config_protocol
	elif [[ ${ssr_modify} == "6" ]]; then
		Modify_port
		Set_config_obfs
		Modify_config_obfs
	elif [[ ${ssr_modify} == "7" ]]; then
		Modify_port
		Set_config_protocol_param
		Modify_config_protocol_param
	elif [[ ${ssr_modify} == "8" ]]; then
		Modify_port
		Set_config_speed_limit_per_con
		Modify_config_speed_limit_per_con
	elif [[ ${ssr_modify} == "9" ]]; then
		Modify_port
		Set_config_speed_limit_per_user
		Modify_config_speed_limit_per_user
	elif [[ ${ssr_modify} == "10" ]]; then
		Modify_port
		Set_config_transfer
		Modify_config_transfer
	elif [[ ${ssr_modify} == "11" ]]; then
		Modify_port
		Set_config_forbid
		Modify_config_forbid
	elif [[ ${ssr_modify} == "12" ]]; then
		Modify_port
		Set_config_all "Modify"
		Modify_config_all
	elif [[ ${ssr_modify} == "13" ]]; then
		Set_user_api_server_pub_addr "Modify"
		Modify_user_api_server_pub_addr
	else
		echo -e "${Error} Ingrese el numero correcto(1-13)" && exit 1
	fi

}
List_port_user(){
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} No encontre al usuario, por favor verifica otra vez!" && exit 1
	user_list_all=""
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		user_username=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $2}'|sed 's/\[//g;s/\]//g')
		Get_User_transfer "${user_port}"
		
		user_list_all=${user_list_all}"Nombre de usuario: ${Green_font_prefix} "${user_username}"${Font_color_suffix}\nPort: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\nUso del trafico (Usado + Restante = Total):\n ${Green_font_prefix}${transfer_enable_Used_2}${Font_color_suffix} + ${Green_font_prefix}${transfer_enable_Used}${Font_color_suffix} = ${Green_font_prefix}${transfer_enable}${Font_color_suffix}\n--------------------------------------------\n "
	done
	echo && echo -e "===== El numero total de usuarios ===== ${Green_background_prefix} "${user_total}" ${Font_color_suffix}\n--------------------------------------------"
	echo -e ${user_list_all}
}
Add_port_user(){
clear
	lalal=$1
	if [[ "$lalal" == "install" ]]; then
		match_add=$(python mujson_mgr.py -a -u "${ssr_user}" -p "${ssr_port}" -k "${ssr_password}" -m "${ssr_method}" -O "${ssr_protocol}" -G "${ssr_protocol_param}" -o "${ssr_obfs}" -s "${ssr_speed_limit_per_con}" -S "${ssr_speed_limit_per_user}" -t "${ssr_transfer}" -f "${ssr_forbid}"|grep -w "add user info")
	else
		while true
		do
			Set_config_all
			match_port=$(python mujson_mgr.py -l|grep -w "port ${ssr_port}$")
			[[ ! -z "${match_port}" ]] && echo -e "${Error} El puerto [${ssr_port}] Ya existe, no lo agregue de nuevo !" && exit 1
			match_username=$(python mujson_mgr.py -l|grep -w "Usuario \[${ssr_user}]")
			[[ ! -z "${match_username}" ]] && echo -e "${Error} Nombre de usuario [${ssr_user}] Ya existe, no lo agregues de nuevo !" && exit 1
			match_add=$(python mujson_mgr.py -a -u "${ssr_user}" -p "${ssr_port}" -k "${ssr_password}" -m "${ssr_method}" -O "${ssr_protocol}" -G "${ssr_protocol_param}" -o "${ssr_obfs}" -s "${ssr_speed_limit_per_con}" -S "${ssr_speed_limit_per_user}" -t "${ssr_transfer}" -f "${ssr_forbid}"|grep -w "add user info")
			if [[ -z "${match_add}" ]]; then
				echo -e "${Error} Usuario no se pudo agregar ${Green_font_prefix}[Nombre de usuario: ${ssr_user} , port: ${ssr_port}]${Font_color_suffix} "
				break
			else
				Add_iptables
				Save_iptables
				msg -bar
				echo -e "${Info} Usuario agregado exitosamente\n ${Green_font_prefix}[Nombre de usuario: ${ssr_user} , Puerto: ${ssr_port}]${Font_color_suffix} "
				echo
				stty erase '^H' && read -p "Continuar para agregar otro Usuario?[y/n]:" addyn
				[[ -z ${addyn} ]] && addyn="y"
				if [[ ${addyn} == [Nn] ]]; then
					Get_User_info "${ssr_port}"
					View_User_info
					break
				else
					echo -e "${Info} Continuar agregando configuracion de usuario ..."
				fi
			fi
		done
	fi
}
Del_port_user(){

	List_port_user
	while true
	do
		msg -bar
		echo -e "Por favor ingrese el puerto de usuario para ser eliminado"
		stty erase '^H' && read -p "(Predeterminado: Cancelar):" del_user_port
		msg -bar
		[[ -z "${del_user_port}" ]] && echo -e "Cancelado...\n$(msg -bar)" && exit 1
		del_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${del_user_port}"',')
		if [[ ! -z ${del_user} ]]; then
			port=${del_user_port}
			match_del=$(python mujson_mgr.py -d -p "${del_user_port}"|grep -w "delete user ")
			if [[ -z "${match_del}" ]]; then
				echo -e "${Error} La eliminación del usuario falló ${Green_font_prefix}[Puerto: ${del_user_port}]${Font_color_suffix} "
			else
				Del_iptables
				Save_iptables
				echo -e "${Info} Usuario eliminado exitosamente ${Green_font_prefix}[Puerto: ${del_user_port}]${Font_color_suffix} "
			fi
			break
		else
			echo -e "${Error} Por favor ingrese el puerto correcto !"
		fi
	done
	msg -bar
}
Manually_Modify_Config(){
clear
msg -bar
	SSR_installation_status
	nano ${config_user_mudb_file}
	echo "Si reiniciar ShadowsocksR ahora?[Y/n]" && echo
msg -bar
	stty erase '^H' && read -p "(Predeterminado: y):" yn
	[[ -z ${yn} ]] && yn="y"
	if [[ ${yn} == [Yy] ]]; then
		Restart_SSR
	fi

}
Clear_transfer(){
clear
msg -bar
	SSR_installation_status
	 echo -e "Que quieres realizar?
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix}  Borrar el trafico de un solo usuario
 ${Green_font_prefix}2.${Font_color_suffix}  Borrar todo el trafico de usuarios (irreparable)
 ${Green_font_prefix}3.${Font_color_suffix}  Todo el trafico de usuarios se borra en el inicio
 ${Green_font_prefix}4.${Font_color_suffix}  Deja de cronometrar todo el trafico de usuarios
 ${Green_font_prefix}5.${Font_color_suffix}  Modificar la sincronizacion de todo el trafico de usuarios"
msg -bar
	stty erase '^H' && read -p "(Predeterminado:Cancelar):" ssr_modify
	[[ -z "${ssr_modify}" ]] && echo "Cancelado ..." && exit 1
	if [[ ${ssr_modify} == "1" ]]; then
		Clear_transfer_one
	elif [[ ${ssr_modify} == "2" ]]; then
msg -bar
		echo "Esta seguro de que desea borrar todo el trafico de usuario[y/n]" && echo
msg -bar
		stty erase '^H' && read -p "(Predeterminado: n):" yn
		[[ -z ${yn} ]] && yn="n"
		if [[ ${yn} == [Yy] ]]; then
			Clear_transfer_all
		else
			echo "Cancelar ..."
		fi
	elif [[ ${ssr_modify} == "3" ]]; then
		check_crontab
		Set_crontab
		Clear_transfer_all_cron_start
	elif [[ ${ssr_modify} == "4" ]]; then
		check_crontab
		Clear_transfer_all_cron_stop
	elif [[ ${ssr_modify} == "5" ]]; then
		check_crontab
		Clear_transfer_all_cron_modify
	else
		echo -e "${Error} Por favor numero de (1-5)" && exit 1
	fi

}
Clear_transfer_one(){
	List_port_user
	while true
	do
	    msg -bar
		echo -e "Por favor ingrese el puerto de usuario para borrar el tráfico usado"
		stty erase '^H' && read -p "(Predeterminado: Cancelar):" Clear_transfer_user_port
		[[ -z "${Clear_transfer_user_port}" ]] && echo -e "Cancelado...\n$(msg -bar)" && exit 1
		Clear_transfer_user=$(cat "${config_user_mudb_file}"|grep '"port": '"${Clear_transfer_user_port}"',')
		if [[ ! -z ${Clear_transfer_user} ]]; then
			match_clear=$(python mujson_mgr.py -c -p "${Clear_transfer_user_port}"|grep -w "clear user ")
			if [[ -z "${match_clear}" ]]; then
				echo -e "${Error} El usuario no ha podido utilizar la compensación de tráfico ${Green_font_prefix}[Puerto: ${Clear_transfer_user_port}]${Font_color_suffix} "
			else
				echo -e "${Info} El usuario ha eliminado con éxito el tráfico utilizando cero. ${Green_font_prefix}[Puerto: ${Clear_transfer_user_port}]${Font_color_suffix} "
			fi
			break
		else
			echo -e "${Error} Por favor ingrese el puerto correcto !"
		fi
	done
}
Clear_transfer_all(){
clear
	cd "${ssr_folder}"
	user_info=$(python mujson_mgr.py -l)
	user_total=$(echo "${user_info}"|wc -l)
	[[ -z ${user_info} ]] && echo -e "${Error} No encontro, por favor compruebe!" && exit 1
	for((integer = 1; integer <= ${user_total}; integer++))
	do
		user_port=$(echo "${user_info}"|sed -n "${integer}p"|awk '{print $4}')
		match_clear=$(python mujson_mgr.py -c -p "${user_port}"|grep -w "clear user ")
		if [[ -z "${match_clear}" ]]; then
			echo -e "${Error} El usuario ha utilizado el trafico borrado fallido ${Green_font_prefix}[Port: ${user_port}]${Font_color_suffix} "
		else
			echo -e "${Info} El usuario ha utilizado el trafico para borrar con exito ${Green_font_prefix}[Port: ${user_port}]${Font_color_suffix} "
		fi
	done
	echo -e "${Info} Se borra todo el trafico de usuarios!"
}
Clear_transfer_all_cron_start(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh/d" "$file/crontab.bak"
	echo -e "\n${Crontab_time} /bin/bash $file/ssrmu.sh clearall" >> "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Temporizacion de todo el trafico de usuarios borrado. !" && exit 1
	else
		echo -e "${Info} Programacion de todos los tiempos de inicio claro exitosos!"
	fi
}
Clear_transfer_all_cron_stop(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh/d" "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Temporizado Todo el trafico de usuarios se ha borrado Parado fallido!" && exit 1
	else
		echo -e "${Info} Timing All Clear Stop Stop Successful!!"
	fi
}
Clear_transfer_all_cron_modify(){
	Set_crontab
	Clear_transfer_all_cron_stop
	Clear_transfer_all_cron_start
}
Set_crontab(){
clear

		echo -e "Por favor ingrese el intervalo de tiempo de flujo
 === Formato ===
 * * * * * Mes * * * * *
 ${Green_font_prefix} 0 2 1 * * ${Font_color_suffix} Representante 1er, 2:00, claro, trafico usado.
$(msg -bar)
 ${Green_font_prefix} 0 2 15 * * ${Font_color_suffix} Representativo El 1  2} representa el 15  2:00 minutos Punto de flujo usado despejado 0 minutos Borrar flujo usado�
$(msg -bar)
 ${Green_font_prefix} 0 2 */7 * * ${Font_color_suffix} Representante 7 dias 2: 0 minutos despeja el trafico usado.
$(msg -bar)
 ${Green_font_prefix} 0 2 * * 0 ${Font_color_suffix} Representa todos los domingos (7) para despejar el trafico utilizado.
$(msg -bar)
 ${Green_font_prefix} 0 2 * * 3 ${Font_color_suffix} Representante (3) Flujo de trafico usado despejado"
msg -bar
	stty erase '^H' && read -p "(Default: 0 2 1 * * 1 de cada mes 2:00):" Crontab_time
	[[ -z "${Crontab_time}" ]] && Crontab_time="0 2 1 * *"
}
Start_SSR(){
clear
	SSR_installation_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} ShadowsocksR se esta ejecutando!" && exit 1
	$prefix/init.d/ssrmu start

}
Stop_SSR(){
clear
	SSR_installation_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} ShadowsocksR no esta funcionando!" && exit 1
	$prefix/init.d/ssrmu stop

}
Restart_SSR(){
clear
	SSR_installation_status
	check_pid
	[[ ! -z ${PID} ]] && $prefix/init.d/ssrmu stop
	$prefix/init.d/ssrmu start

}
View_Log(){
	SSR_installation_status
	[[ ! -e ${ssr_log_file} ]] && echo -e "${Error} El registro de ShadowsocksR no existe!" && exit 1
	echo && echo -e "${Tip} Presione ${Red_font_prefix}Ctrl+C ${Font_color_suffix} Registro de registro de terminacion" && echo
	tail -f ${ssr_log_file}

}
#Afilado
Configure_Server_Speeder(){
clear
msg -bar
	echo && echo -e "Que vas a hacer
${BARRA1}
 ${Green_font_prefix}1.${Font_color_suffix} Velocidad aguda
$(msg -bar)
 ${Green_font_prefix}2.${Font_color_suffix} Velocidad aguda
————————
 ${Green_font_prefix}3.${Font_color_suffix} Velocidad aguda
$(msg -bar)
 ${Green_font_prefix}4.${Font_color_suffix} Velocidad aguda
$(msg -bar)
 ${Green_font_prefix}5.${Font_color_suffix} Reinicie la velocidad aguda
$(msg -bar)
 ${Green_font_prefix}6.${Font_color_suffix} Estado agudo
 $(msg -bar)
 Nota: Sharp y LotServer no se pueden instalar / iniciar al mismo tiempo"
msg -bar
	stty erase '^H' && read -p "(Predeterminado: Cancelar):" server_speeder_num
	[[ -z "${server_speeder_num}" ]] && echo "Cancelado ..." && exit 1
	if [[ ${server_speeder_num} == "1" ]]; then
		Install_ServerSpeeder
	elif [[ ${server_speeder_num} == "2" ]]; then
		Server_Speeder_installation_status
		Uninstall_ServerSpeeder
	elif [[ ${server_speeder_num} == "3" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} start
		${Server_Speeder_file} status
	elif [[ ${server_speeder_num} == "4" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} stop
	elif [[ ${server_speeder_num} == "5" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} restart
		${Server_Speeder_file} status
	elif [[ ${server_speeder_num} == "6" ]]; then
		Server_Speeder_installation_status
		${Server_Speeder_file} status
	else
		echo -e "${Error} Por favor numero(1-6)" && exit 1
	fi
}
Install_ServerSpeeder(){
	[[ -e ${Server_Speeder_file} ]] && echo -e "${Error} Server Speeder esta instalado!" && exit 1
	#Prestamo de la version feliz de 91yun.rog
	wget --no-check-certificate -qO /tmp/serverspeeder.sh https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder.sh
	[[ ! -e "/tmp/serverspeeder.sh" ]] && echo -e "${Error} Prestamo de la version feliz de 91yun.rog!" && exit 1
	bash /tmp/serverspeeder.sh
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "serverspeeder" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		rm -rf /tmp/serverspeeder.sh
		rm -rf /tmp/91yunserverspeeder
		rm -rf /tmp/91yunserverspeeder.tar.gz
		echo -e "${Info} La instalacion del servidor Speeder esta completa!" && exit 1
	else
		echo -e "${Error} Fallo la instalacion de Server Speeder!" && exit 1
	fi
}
Uninstall_ServerSpeeder(){
clear
msg -bar
	echo "yes para desinstalar Speed ??Speed ??(Server Speeder)[y/N]" && echo
msg -bar
	stty erase '^H' && read -p "(Predeterminado: n):" unyn
	[[ -z ${unyn} ]] && echo && echo "Cancelado ..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		chattr -i /serverspeeder$prefix/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		echo && echo "Server Speeder Desinstalacion completa!" && echo
	fi
}
# LotServer
Configure_LotServer(){
clear
msg -bar
	echo && echo -e "Que vas a hacer?
$(msg -bar)
 ${Green_font_prefix}1.${Font_color_suffix} Instalar LotServer
$(msg -bar)
 ${Green_font_prefix}2.${Font_color_suffix} Desinstalar LotServer
————————
 ${Green_font_prefix}3.${Font_color_suffix} Iniciar LotServer
$(msg -bar)
 ${Green_font_prefix}4.${Font_color_suffix} Detener LotServer
$(msg -bar)
 ${Green_font_prefix}5.${Font_color_suffix} Reiniciar LotServer
$(msg -bar)
 ${Green_font_prefix}6.${Font_color_suffix} Ver el estado de LotServer
${BARRA1}
 
 Nota: Sharp y LotServer no se pueden instalar / iniciar al mismo tiempo"
msg -bar

	stty erase '^H' && read -p "(Predeterminado: Cancelar):" lotserver_num
	[[ -z "${lotserver_num}" ]] && echo "Cancelado ..." && exit 1
	if [[ ${lotserver_num} == "1" ]]; then
		Install_LotServer
	elif [[ ${lotserver_num} == "2" ]]; then
		LotServer_installation_status
		Uninstall_LotServer
	elif [[ ${lotserver_num} == "3" ]]; then
		LotServer_installation_status
		${LotServer_file} start
		${LotServer_file} status
	elif [[ ${lotserver_num} == "4" ]]; then
		LotServer_installation_status
		${LotServer_file} stop
	elif [[ ${lotserver_num} == "5" ]]; then
		LotServer_installation_status
		${LotServer_file} restart
		${LotServer_file} status
	elif [[ ${lotserver_num} == "6" ]]; then
		LotServer_installation_status
		${LotServer_file} status
	else
		echo -e "${Error} Por favor numero(1-6)" && exit 1
	fi
}
Install_LotServer(){
	[[ -e ${LotServer_file} ]] && echo -e "${Error} LotServer esta instalado!" && exit 1
	#Github: https://github.com/0oVicero0/serverSpeeder_Install
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	[[ ! -e "/tmp/appex.sh" ]] && echo -e "${Error} Fallo la descarga del script de instalacion de LotServer!" && exit 1
	bash /tmp/appex.sh 'install'
	sleep 2s
	PID=`ps -ef |grep -v grep |grep "appex" |awk '{print $2}'`
	if [[ ! -z ${PID} ]]; then
		echo -e "${Info} La instalacion de LotServer esta completa!" && exit 1
	else
		echo -e "${Error} Fallo la instalacion de LotServer!" && exit 1
	fi
}
Uninstall_LotServer(){
clear
msg -bar
	echo "Desinstalar Para desinstalar LotServer[y/N]" && echo
msg -bar
	stty erase '^H' && read -p "(Predeterminado: n):" unyn
msg -bar
	[[ -z ${unyn} ]] && echo && echo "Cancelado ..." && exit 1
	if [[ ${unyn} == [Yy] ]]; then
		wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh" && bash /tmp/appex.sh 'uninstall'
		echo && echo "La desinstalacion de LotServer esta completa!" && echo
	fi
}
# BBR
Configure_BBR(){
clear
msg -bar
 echo -e "  Que vas a hacer?
$(msg -bar)	
 ${Green_font_prefix}1.${Font_color_suffix} Instalar BBR
————————
${Green_font_prefix}2.${Font_color_suffix} Iniciar BBR
${Green_font_prefix}3.${Font_color_suffix} Dejar de BBR
${Green_font_prefix}4.${Font_color_suffix} Ver el estado de BBR"
msg -bar
echo -e "${Green_font_prefix} [Por favor, preste atencion antes de la instalacion] ${Font_color_suffix}
$(msg -bar)
1. Abra BBR, reemplace, hay un error de reemplazo (despues de reiniciar)
2. Este script solo es compatible con los nucleos de reemplazo de Debian / Ubuntu. OpenVZ y Docker no admiten el reemplazo de los nucleos.
3. Debian reemplaza el proceso del kernel [Desea finalizar el kernel de desinstalacion], seleccione ${Green_font_prefix} NO ${Font_color_suffix}"
	stty erase '^H' && read -p "(Predeterminado: Cancelar):" bbr_num
msg -bar
	[[ -z "${bbr_num}" ]] && echo -e "Cancelado...\n$(msg -bar)" && exit 1
	if [[ ${bbr_num} == "1" ]]; then
		Install_BBR
	elif [[ ${bbr_num} == "2" ]]; then
		Start_BBR
	elif [[ ${bbr_num} == "3" ]]; then
		Stop_BBR
	elif [[ ${bbr_num} == "4" ]]; then
		Status_BBR
	else
		echo -e "${Error} Por favor numero(1-4)" && exit 1
	fi
}
Install_BBR(){
	[[ ${release} = "centos" ]] && echo -e "${Error} Este script de instalacion del sistema CentOS. BBR !" && exit 1
	BBR_installation_status
	bash "${BBR_file}"
}
Start_BBR(){
	BBR_installation_status
	bash "${BBR_file}" start
}
Stop_BBR(){
	BBR_installation_status
	bash "${BBR_file}" stop
}
Status_BBR(){
	BBR_installation_status
	bash "${BBR_file}" status
}
BackUP_ssrr(){
clear
msg -bar
msg -ama "$(fun_trans "HERRAMIENTA DE BACKUP SS-SSRR -BETA")"
msg -bar
msg -azu "CREANDO BACKUP" "RESTAURAR BACKUP"
msg -bar
rm -rf /root/mudb.json > /dev/null 2>&1
cp /usr/local/shadowsocksr/mudb.json /root/mudb.json > /dev/null 2>&1
msg -azu "$(fun_trans "Procedimiento Hecho con Exito, Guardado en:")"
echo -e "\033[1;31mBACKUP > [\033[1;32m/root/mudb.json\033[1;31m]"
msg -bar
}
RestaurarBackUp_ssrr(){
clear
msg -bar
msg -ama "$(fun_trans "HERRAMIENTA DE RESTAURACION SS-SSRR -BETA")"
msg -bar
msg -azu "Recuerde tener minimo una cuenta ya creada"
msg -azu "Copie el archivo mudb.json en la carpeta /root"
read -p "     ►► Presione enter para continuar ◄◄"
msg -bar
msg -azu "$(fun_trans "Procedimiento Hecho con Exito")"
read -p "  ►► Presione enter para Reiniciar Panel SSRR ◄◄"
msg -bar
mv /root/mudb.json /usr/local/shadowsocksr/mudb.json
Restart_SSR
msg -bar
}

# Otros
Other_functions(){
clear
msg -bar
	echo && echo -e "  Que vas a realizar?
$(msg -bar)
  ${Green_font_prefix}1.${Font_color_suffix} Configurar BBR
  ${Green_font_prefix}2.${Font_color_suffix} Velocidad de configuracion (ServerSpeeder)
  ${Green_font_prefix}3.${Font_color_suffix} Configurar LotServer (Rising Parent)
  ${Tip} Sharp / LotServer / BBR no es compatible con OpenVZ!
  ${Tip} Speed y LotServer no pueden coexistir!
————————————
  ${Green_font_prefix}4.${Font_color_suffix} Llave de bloqueo BT/PT/SPAM (iptables)
  ${Green_font_prefix}5.${Font_color_suffix} Llave de desbloqueo BT/PT/SPAM (iptables)
————————————
  ${Green_font_prefix}6.${Font_color_suffix} Cambiar modo de salida de registro ShadowsocksR
  —— Modo bajo o verboso..
  ${Green_font_prefix}7.${Font_color_suffix} Supervisar el estado de ejecucion del servidor ShadowsocksR
  —— NOTA: Esta funcion es adecuada para que el servidor SSR finalice los procesos regulares. Una vez que esta funcion esta habilitada, sera detectada cada minuto. Cuando el proceso no existe, el servidor SSR se inicia automaticamente.
———————————— 
 ${Green_font_prefix}8.${Font_color_suffix} Backup SSRR
 ${Green_font_prefix}9.${Font_color_suffix} Restaurar Backup" && echo
msg -bar
	stty erase '^H' && read -p "(Predeterminado: cancelar):" other_num
	[[ -z "${other_num}" ]] && echo -e "Cancelado...\n$(msg -bar)" && exit 1
	if [[ ${other_num} == "1" ]]; then
		Configure_BBR
	elif [[ ${other_num} == "2" ]]; then
		Configure_Server_Speeder
	elif [[ ${other_num} == "3" ]]; then
		Configure_LotServer
	elif [[ ${other_num} == "4" ]]; then
		BanBTPTSPAM
	elif [[ ${other_num} == "5" ]]; then
		UnBanBTPTSPAM
	elif [[ ${other_num} == "6" ]]; then
		Set_config_connect_verbose_info
	elif [[ ${other_num} == "7" ]]; then
		Set_crontab_monitor_ssr
	elif [[ ${other_num} == "8" ]]; then
		BackUP_ssrr
	elif [[ ${other_num} == "9" ]]; then
		RestaurarBackUp_ssrr
	else
		echo -e "${Error} Por favor numero [1-9]" && exit 1
	fi

}
#Prohibido�BT PT SPAM
BanBTPTSPAM(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh && chmod +x ban_iptables.sh && bash ban_iptables.sh banall
	rm -rf ban_iptables.sh
}
#Desbloquear BT PT SPAM
UnBanBTPTSPAM(){
	wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ban_iptables.sh && chmod +x ban_iptables.sh && bash ban_iptables.sh unbanall
	rm -rf ban_iptables.sh
}
Set_config_connect_verbose_info(){
clear
msg -bar
	SSR_installation_status
	[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ parser No, por favor, compruebe!" && exit 1
	connect_verbose_info=`${jq_file} '.connect_verbose_info' ${config_user_file}`
	if [[ ${connect_verbose_info} = "0" ]]; then
		echo && echo -e "Modo de registro actual: ${Green_font_prefix}Registro de errores en modo simple${Font_color_suffix}"
msg -bar
		echo -e "yes para cambiar a ${Green_font_prefix}Modo detallado (registro de conexi�n + registro de errores)${Font_color_suffix}？[y/N]"
msg -bar
		stty erase '^H' && read -p "(Predeterminado: n):" connect_verbose_info_ny
		[[ -z "${connect_verbose_info_ny}" ]] && connect_verbose_info_ny="n"
		if [[ ${connect_verbose_info_ny} == [Yy] ]]; then
			ssr_connect_verbose_info="1"
			Modify_config_connect_verbose_info
			Restart_SSR
		else
			echo && echo "	Cancelado ..." && echo
		fi
	else
		echo && echo -e "Modo de registro actual: ${Green_font_prefix}Modo detallado (conexion de conexion + registro de errores)${Font_color_suffix}"
msg -bar
		echo -e "yes para cambiar a ${Green_font_prefix}Modo simple ${Font_color_suffix}?[y/N]"
		stty erase '^H' && read -p "(Predeterminado: n):" connect_verbose_info_ny
		[[ -z "${connect_verbose_info_ny}" ]] && connect_verbose_info_ny="n"
		if [[ ${connect_verbose_info_ny} == [Yy] ]]; then
			ssr_connect_verbose_info="0"
			Modify_config_connect_verbose_info
			Restart_SSR
		else
			echo && echo "	Cancelado ..." && echo
		fi
	fi
}
Set_crontab_monitor_ssr(){
clear
msg -bar
	SSR_installation_status
	crontab_monitor_ssr_status=$(crontab -l|grep "ssrmu.sh monitor")
	if [[ -z "${crontab_monitor_ssr_status}" ]]; then
		echo && echo -e "Modo de monitoreo actual: ${Green_font_prefix}No monitoreado${Font_color_suffix}"
msg -bar
		echo -e "Ok para abrir ${Green_font_prefix}Servidor ShadowsocksR ejecutando monitoreo de estado${Font_color_suffix} Funcion? (Cuando el proceso R lado SSR R)[Y/n]"
msg -bar
		stty erase '^H' && read -p "(Predeterminado: y):" crontab_monitor_ssr_status_ny
		[[ -z "${crontab_monitor_ssr_status_ny}" ]] && crontab_monitor_ssr_status_ny="y"
		if [[ ${crontab_monitor_ssr_status_ny} == [Yy] ]]; then
			crontab_monitor_ssr_cron_start
		else
			echo && echo "	Cancelado ..." && echo
		fi
	else
		echo && echo -e "Modo de monitoreo actual: ${Green_font_prefix}Abierto${Font_color_suffix}"
msg -bar
		echo -e "Ok para apagar ${Green_font_prefix}Servidor ShadowsocksR ejecutando monitoreo de estado${Font_color_suffix} Funcion? (procesar servidor SSR)[y/N]"
msg -bar
		stty erase '^H' && read -p "(Predeterminado: n):" crontab_monitor_ssr_status_ny
		[[ -z "${crontab_monitor_ssr_status_ny}" ]] && crontab_monitor_ssr_status_ny="n"
		if [[ ${crontab_monitor_ssr_status_ny} == [Yy] ]]; then
			crontab_monitor_ssr_cron_stop
		else
			echo && echo "	Cancelado ..." && echo
		fi
	fi
}
crontab_monitor_ssr(){
	SSR_installation_status
	check_pid
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Detectado que el servidor ShadowsocksR no esta iniciado, inicie..." | tee -a ${ssr_log_file}
		$prefix/init.d/ssrmu start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Fallo el inicio del servidor ShadowsocksR..." | tee -a ${ssr_log_file} && exit 1
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Inicio de inicio del servidor ShadowsocksR..." | tee -a ${ssr_log_file} && exit 1
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] El proceso del servidor ShadowsocksR se ejecuta normalmente..." exit 0
	fi
}
crontab_monitor_ssr_cron_start(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh monitor/d" "$file/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file/ssrmu.sh monitor" >> "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Fallo el arranque del servidor ShadowsocksR!" && exit 1
	else
		echo -e "${Info} El servidor ShadowsocksR esta ejecutando la monitorizacion del estado con exito!"
	fi
}
crontab_monitor_ssr_cron_stop(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrmu.sh monitor/d" "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrmu.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Fallo la detencion del servidor ShadowsocksR!" && exit 1
	else
		echo -e "${Info} La supervision del estado de ejecucion del servidor de ShadowsocksR se detiene correctamente!"
	fi
}
Update_Shell(){
clear
msg -bar
	echo -e "La version actual es [ ${sh_ver} ], Comienza a detectar la ultima version ..."
	sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/hybtoy/ssrrmu/master/ssrrmu.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/hybtoy/ssrrmu/master/ssrrmu.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} Ultima version de deteccion !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "Descubrir nueva version[ ${sh_new_ver} ], Esta actualizado?[Y/n]"
msg -bar
		stty erase '^H' && read -p "(Predeterminado: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			cd "${file}"
			if [[ $sh_new_type == "github" ]]; then
				wget -N --no-check-certificate https://raw.githubusercontent.com/hybtoy/ssrrmu/master/ssrrmu.sh && chmod +x ssrrmu.sh
			fi
			echo -e "El script ha sido actualizado a la ultima version.[ ${sh_new_ver} ] !"
		else
			echo && echo "	Cancelado ..." && echo
		fi
	else
		echo -e "Actualmente es la ultima version.[ ${sh_new_ver} ] !"
	fi
	exit 0

}
# Mostrar el estado del menu
menu_status(){
msg -bar
	if [[ -e ${ssr_folder} ]]; then
		check_pid
		if [[ ! -z "${PID}" ]]; then
			echo -e "         VPS-MX \n Estado actual: ${Green_font_prefix}Instalado${Font_color_suffix} y ${Green_font_prefix}Iniciado${Font_color_suffix}"
		else
			echo -e " Estado actual: ${Green_font_prefix}Instalado${Font_color_suffix} pero ${Red_font_prefix}no comenzo${Font_color_suffix}"
		fi
		cd "${ssr_folder}"
	else
		echo -e " Estado actual: ${Red_font_prefix}No Instalado${Font_color_suffix}"
	fi
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} el script no es compatible con el sistema actual ${release} !" && exit 1
action=$1
if [[ "${action}" == "clearall" ]]; then
	Clear_transfer_all
elif [[ "${action}" == "monitor" ]]; then
	crontab_monitor_ssr
else

echo -e "$() " 
echo -e "        Controlador de ShadowSock-R  ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
$(msg -bar)
  ${Green_font_prefix}1.${Font_color_suffix} Instalar ShadowsocksR 
  ${Green_font_prefix}2.${Font_color_suffix} Actualizar ShadowsocksR
  ${Green_font_prefix}3.${Font_color_suffix} Desinstalar ShadowsocksR
  ${Green_font_prefix}4.${Font_color_suffix} Instalar libsodium (chacha20)
—————————————
  ${Green_font_prefix}5.${Font_color_suffix} Verifique la informacion de la cuenta
  ${Green_font_prefix}6.${Font_color_suffix} Mostrar la informacion de conexion 
  ${Green_font_prefix}7.${Font_color_suffix} Agregar/Modificar/Eliminar la configuracion del usuario  
  ${Green_font_prefix}8.${Font_color_suffix} Modificar manualmente la configuracion del usuario
  ${Green_font_prefix}9.${Font_color_suffix} Borrar el trafico usado  
——————————————
 ${Green_font_prefix}10.${Font_color_suffix} Iniciar ShadowsocksR
 ${Green_font_prefix}11.${Font_color_suffix} Detener ShadowsocksR
 ${Green_font_prefix}12.${Font_color_suffix} Reiniciar ShadowsocksR
 ${Green_font_prefix}13.${Font_color_suffix} Verificar Registro de ShadowsocksR
—————————————
 ${Green_font_prefix}14.${Font_color_suffix} Otras Funciones
 ${Green_font_prefix}15.${Font_color_suffix} Actualizar Script 
$(msg -bar)
 ${Green_font_prefix}16.${Font_color_suffix}${Red_font_prefix} SALIR"
	
	menu_status
	msg -bar
    stty erase '^H' && read -p "Porfavor seleccione una opcion [1-16]:" num
	msg -bar
case "$num" in
	1)
	Install_SSR
	;;
	2)
	Update_SSR
	;;
	3)
	Uninstall_SSR
	;;
	4)
	Install_Libsodium
	;;
	5)
	View_User
	;;
	6)
	View_user_connection_info
	;;
	7)
	Modify_Config
	;;
	8)
	Manually_Modify_Config
	;;
	9)
	Clear_transfer
	;;
	10)
	Start_SSR
	;;
	11)
	Stop_SSR
	;;
	12)
	Restart_SSR
	;;
	13)
	View_Log
	;;
	14)
	Other_functions
	;;
	15)
	Update_Shell
	;;
     16)
     exit 1
      ;;
	*)
	echo -e "${Error} Porfavor use numeros del [1-16]"
	msg -bar
	;;
esac
fi

}

function _budp(){
installarm(){
clear
if [[ ! -e /bin/badvpn-udpgw ]]; then
msg -ama "	INICIANDO DESCARGA BADVPN ARM TEST"
[[ -e /bin/badvpn-udpgw ]] && rm -f /bin/badvpn-udpgw 
[[ -e /bin/badvpn ]] && rm -f /bin/badvpn
[[ -e /usr/local/bin/badvpn-udpgw ]] && rm -f /usr/local/bin/badvpn-udpgw
rm -rf $HOME/badvpn*
apt-get install -y gcc &>/dev/null # 2>/dev/null
apt-get install -y make &>/dev/null #2>/dev/null
apt-get install -y g++ &>/dev/null #2>/dev/null
apt-get install -y openssl &>/dev/null #2>/dev/null
apt-get install -y build-essential &>/dev/null #2>/dev/null
if apt-get install -y cmake &>/dev/null; then
 msg -verd "	CMAKE INSTALADO"
 else
 msg -verm2 "	FALLÓ"
 return
 fi
cd $HOME
if wget https://github.com/lacasitamx/SCRIPTMOD-LACASITA/raw/master/test/badvpn-master.zip &>/dev/null; then
msg -ama "	DESCARGA CORRECTA"
else
msg -verm2 "	DESCARGA FALLIDA"
return
fi

if unzip badvpn-master.zip &>/dev/null; then
msg -verd "	Descomprimiendo archivo"
else
msg -verm2 "	La descomprecion ha fallado"
return
fi

cd badvpn-master
mkdir build
cd build
if cmake .. -DCMAKE_INSTALL_PREFIX="/" -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 &>/dev/null && make install &>/dev/null; then
msg -verd "	Cmake con exito"
else
msg -verm2 "	Cmake Fallido"
return
fi
cd $HOME
rm -rf badvpn-master.zip
#arm
sleep 1s
clear
msg -ama " ACTIVANDO BADVPN 7300"
echo -e "[Unit]
Description=BadVPN UDPGW Service
After=network.target\n
[Service]
Type=simple

User=root
WorkingDirectory=/root
ExecStart=$(which badvpn-udpgw)  --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3s\n
[Install]
WantedBy=multi-user.target" > $prefix/systemd/system/badvpn.service

    systemctl enable badvpn &>/dev/null
    systemctl start badvpn &>/dev/null
    systemctl daemon-reload &>/dev/null
   # $(which badvpn) "start"
 #   badvpn start
    activado
else
msg -verm2 "	DETENIENDO BADVPN"
    msg -bar
    systemctl stop badvpn &>/dev/null
    systemctl disable badvpn &>/dev/null
    rm $prefix/systemd/system/badvpn.service
  #  rm /usr/bin/badvpn-udpgw &>/dev/null
    [[ -e /bin/badvpn-udpgw ]] && rm -f /bin/badvpn-udpgw 
	[[ -e /bin/badvpn ]] && rm -f /bin/badvpn
	[[ -e /usr/local/bin/badvpn-udpgw ]] && rm -f /usr/local/bin/badvpn-udpgw
	rm -rf $HOME/badvpn*
	systemctl daemon-reload &>/dev/null
    msg -verm " BADVPN DESACTIVADO"
    fi
}
unistall(){
msg -bar 
	
    msg -ama "          DESACTIVADOR DE BADVPN (UDP)"
    msg -bar
    
    systemctl stop badvpn &>/dev/null
    systemctl disable badvpn &>/dev/null
    rm -rf $prefix/systemd/system/badvpn.service 
    screen -r -S "badvpn" -X quit
        screen -wipe 1>/dev/null 2>/dev/null
        [[ $(grep -wc "badvpn" $prefix/autostart) != '0' ]] && {
		    sed -i '/badvpn/d' $prefix/autostart
		}
    rm -rf $HOME/badvpn*
    kill -9 $(ps x | grep badvpn | grep -v grep | awk '{print $1'}) > /dev/null 2>&1
    killall badvpn-udpgw > /dev/null 2>&1
    rm -rf /bin/badvpn-udpgw
    [[ ! "$(ps x | grep badvpn | grep -v grep | awk '{print $1}')" ]] && msg -ne "                DESACTIVADO CON EXITO \n"
    unset pid_badvpn
	msg -bar
	}
	
activado (){
msg -bar
    #puerto local  
    [[ "$(ps x | grep badvpn | grep -v grep | awk '{print $1}')" ]] && msg -verd "                  ACTIVADO CON EXITO" || msg -ama "                 Falló"
	msg -bar
	}
	
BadVPN () {
pid_badvpn=$(ps x | grep badvpn | grep -v grep | awk '{print $1}')

clear

    msg -ama "  \e[1;43m\e[91mACTIVADOR DE BADVPN (7100-7200-7300-Multi Port)\e[0m"
    msg -bar
echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "ACTIVAR BADVPN 7300") \e[92m(System)"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "ACTIVAR BADVPN 7300") \e[92m(Screen Directo)"
echo -e "$(msg -verd "[3]")$(msg -verm2 "➛ ")$(msg -azu "AGREGAR +PORT BADVPN ")"
echo -e "$(msg -verd "[4]")$(msg -verm2 "➛ ")$(msg -azu "APLICAR FIX CMAKE")"
echo -e "$(msg -verd "[5]")$(msg -verm2 "➛ ")$(msg -azu "DETENER SERVICIO BADVPN")"
echo -e "$(msg -verd "[0]")$(msg -verm2 "➛ ")$(msg -azu "VOLVER")"
msg -bar
read -p "Digite una opción (default 2): " -e -i 2 portasx
#tput cuu1 && tput dl1
if [[ ${portasx} = 1 ]]; then
if [[ -z $pid_badvpn ]]; then
msg -ama "	DESCARGANDO PAQUETES....."
apt install wget -y &>/dev/null
apt-get install -y gcc &>/dev/null # 2>/dev/null
apt-get install -y make &>/dev/null #2>/dev/null
apt-get install -y g++ &>/dev/null #2>/dev/null
apt-get install -y openssl &>/dev/null #2>/dev/null
apt-get install -y build-essential &>/dev/null #2>/dev/null
if apt-get install cmake -y &>/dev/null; then
msg -verd "	CMAKE INSTALADO"
 else
 msg -verm2 "	FALLÓ"
 return
 fi

cd $HOME
if wget https://github.com/lacasitamx/SCRIPTMOD-LACASITA/raw/master/test/badvpn-master.zip &>/dev/null; then
msg -verd "	DESCARGA CORRECTA"
else
msg -verm2 "	DESCARGA FALLIDA"
return
fi

if unzip badvpn-master.zip &>/dev/null; then
msg -verd "	Descomprimiendo archivo"
else
msg -verm2 "	La descomprecion ha fallado"
return
fi

cd badvpn-master
mkdir build
cd build
if cmake .. -DCMAKE_INSTALL_PREFIX="/" -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 &>/dev/null && make install &>/dev/null; then
msg -verd "	Cmake con exito"
else
msg -verm2 "	Cmake Fallido"
return
fi
cd $HOME
rm -rf badvpn-master.zip
#rm -rf badvpn*
#arm
sleep 1s
clear
echo -e "[Unit]
Description=BadVPN UDPGW Service
After=network.target\n
[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=$(which badvpn-udpgw)  --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3s\n
[Install]
WantedBy=multi-user.target" > $prefix/systemd/system/badvpn.service

    systemctl enable badvpn &>/dev/null
    systemctl start badvpn &>/dev/null
    systemctl daemon-reload &>/dev/null
activado
else
systemctl stop badvpn &>/dev/null
    systemctl disable badvpn &>/dev/null
    rm -rf $prefix/systemd/system/badvpn.service 
    msg -ne "                7300 DESACTIVADO CON EXITO \n"
fi
elif [[ ${portasx} = 2 ]]; then
if [[ -z $pid_badvpn ]]; then
if [[ ! -e /bin/badvpn-udpgw ]]; then
    wget -O /bin/badvpn-udpgw https://raw.githubusercontent.com/lacasitamx/VPSMX/master/ArchivosUtilitarios/badvpn-udpgw &>/dev/null
    chmod 777 /bin/badvpn-udpgw
   fi
screen -dmS badvpn $(which badvpn-udpgw) --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10
        [[ $(grep -wc "badvpn" $prefix/autostart) = '0' ]] && {
		    echo -e "ps x | grep 'badvpn' | grep -v 'grep' || screen -dmS badvpn $(which badvpn-udpgw) --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000" >> $prefix/autostart
		} || {
		    sed -i '/udpvpn/d' $prefix/autostart
		    echo -e "ps x | grep 'badvpn' | grep -v 'grep' || screen -dmS badvpn $(which badvpn-udpgw) --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000" >> $prefix/autostart
		}
		activado
		else
		unistall
		fi
   elif [[ ${portasx} = 3 ]]; then
if [[ ! -e /bin/badvpn-udpgw ]]; then
    wget -O /bin/badvpn-udpgw https://raw.githubusercontent.com/lacasitamx/VPSMX/master/ArchivosUtilitarios/badvpn-udpgw &>/dev/null
    chmod 777 /bin/badvpn-udpgw
   fi
   read -p " Digite El Puerto Para Badvpn: " ud
screen -dmS badvpn $(which badvpn-udpgw) --listen-addr 127.0.0.1:$ud --max-clients 10000 --max-connections-for-client 10
echo -e "ps x | grep 'badvpn' | grep -v 'grep' || screen -dmS badvpn $(which badvpn-udpgw) --listen-addr 127.0.0.1:$ud --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000" >> $prefix/autostart
activado

	elif [[ ${portasx} = 4 ]]; then
	wget https://cmake.org/files/v3.8/cmake-3.8.2.tar.gz
	tar xf cmake-3.8.2.tar.gz &>/dev/null
	cd cmake-3.8.2
	./configure &>/dev/null
	sudo make install &>/dev/null
	cd $HOME
if wget https://github.com/lacasitamx/SCRIPTMOD-LACASITA/raw/master/test/badvpn-master.zip &>/dev/null; then
msg -verd "	DESCARGA CORRECTA"
else
msg -verm2 "	DESCARGA FALLIDA"
return
fi

if unzip badvpn-master.zip &>/dev/null; then
msg -verd "	Descomprimiendo archivo"
else
msg -verm2 "	La descomprecion ha fallado"
return
fi

cd badvpn-master
mkdir build
cd build
if cmake .. -DCMAKE_INSTALL_PREFIX="/" -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 &>/dev/null && make install &>/dev/null; then
msg -verd "	Cmake con exito"
else
msg -verm2 "	Cmake Fallido"
return
fi
cd $HOME
rm -rf badvpn-master.zip
#rm -rf badvpn*
#arm
sleep 1s
clear
echo -e "[Unit]
Description=BadVPN UDPGW Service
After=network.target\n
[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=$(which badvpn-udpgw)  --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3s\n
[Install]
WantedBy=multi-user.target" > $prefix/systemd/system/badvpn.service

    systemctl enable badvpn &>/dev/null
    systemctl start badvpn &>/dev/null
    systemctl daemon-reload &>/dev/null
activado
unset pid_badvpn
elif [[ ${portasx} = 5 ]]; then
	unistall
   elif [[ ${portasx} = 0 ]]; then
   msg -verm "	SALIENDO"
   exit
   fi
  


}
BadVPN

}

function _chekuser(){
chk_ip=$ip

start(){
	if [[ $(systemctl is-active chekuser) = "active" ]]; then
		msg -azu "DESABILITANDO CHEKUSER"
		systemctl stop chekuser &>/dev/null
    	systemctl disable chekuser &>/dev/null
    	rm -rf $prefix/systemd/system/chekuser.service
		msg -verd 'chekuser, se desactivo con exito!'
		enter
		return
	fi

	  while true; do
	echo -ne "\033[1;37m"
    read -p " INGRESE UN PUERTO: " chekuser
	echo ""
    [[ $(mportas|grep -w "$chekuser") ]] || break
    echo -e "\033[1;33m Este puerto está en uso"
    unset chekuser
    done
    echo " $(msg -ama "Puerto") $(msg -verd "$chekuser")"
    msg -bar

    print_center 'SELECCIONA UN FORMATO DE FECHA'
    msg -bar
    menu_func 'YYYY/MM/DD' 'DD/MM/YYYY'
    msg -bar
    date=$(selection_fun 2)
    case $date in
    	1)fecha="YYYY/MM/DD";;
    	2)fecha="DD/MM/YYYY";;
    esac
    [[ $date = 0 ]] && return
    del 5
    echo " $(msg -ama "Formato") $(msg -verd "$fecha")"
  #  enter
    del 2

    print_center -ama 'Instalandon python3-pip'
    if apt install -y python3-pip &>/dev/null; then
    	del 1
    	print_center -verd 'Instalandon python3-pip ok'
    else
    	del 1
    	print_center -verm2 'falla al instalar python3-pip\nintente instalar manualmente\n\ncomando manual >> apt install -y python3-pip\n\nresuelva esta falla para luego intentar'
   # 	enter
    	return
    fi

    print_center -ama 'Instalandon flask'
    if pip3 install flask &>/dev/null; then
    	del 1
    	print_center -verd 'Instalandon flask ok'
    else
    	del 1
    	print_center -verm2 '\nfalla al instalar flask\nintente instalar manualmente\n\ncomando manual >> pip3 install flask\n\nresuelva esta falla para luego intentar'
   # 	enter
    	return
    fi

    print_center -ama 'Iniciando servicio'

    if [[ $(systemctl is-active chekuser) = "active" ]]; then
    	systemctl stop chekuser &>/dev/null
    	systemctl disable chekuser &>/dev/null
    fi

    rm -rf $prefix/systemd/system/chekuser.service

    echo -e "[Unit]
Description=chekuser Service by @Rufu99
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/bin/python3 ${sdir[0]}/protocolos/chekuser.py $chekuser $date
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target" > $prefix/systemd/system/chekuser.service

# ExecStart=/usr/bin/python3 ${ADM_inst}/chekuser.py $chekuser $date
# ps x|grep -v grep|grep chekuser.py|awk '{print $7}'

	systemctl enable chekuser &>/dev/null
	systemctl start chekuser &>/dev/null

	if [[ $(systemctl is-active chekuser) = "active" ]]; then
		title -verd 'Instalacion completa'
		print_center -ama "URL: http://$chk_ip:$chekuser/checkUser"
	else
		systemctl stop chekuser &>/dev/null
    	systemctl disable chekuser &>/dev/null
    	rm -rf $prefix/systemd/system/chekuser.service
		print_center -verm2 'falla al iniciar servicio chekuser'
	fi
	#enter
}

mod_port(){
	while true; do
	echo -ne "\033[1;37m"
    read -p " INGRESE UN PUERTO: " chekuser
	echo ""
    [[ $(mportas|grep -w "$chekuser") ]] || break
    echo -e "\033[1;33m Este puerto está en uso"
    unset chekuser
    done
    echo " $(msg -ama "Puerto") $(msg -verd "$chekuser")"
    enter
    port_chek=$(ps x|grep -v grep|grep chekuser.py|awk '{print $7}')
    systemctl stop chekuser &>/dev/null
    systemctl disable chekuser &>/dev/null
    sed -i "s/$port_chek/$chekuser/g" $prefix/systemd/system/chekuser.service
    systemctl enable chekuser &>/dev/null
    systemctl start chekuser &>/dev/null

    if [[ $(systemctl is-active chekuser) = "active" ]]; then
		title -verd 'puerto modificado'
		print_center -ama "URL: http://$chk_ip:$chekuser/checkUser"
	else
		systemctl stop chekuser &>/dev/null
    	systemctl disable chekuser &>/dev/null
    	rm -rf $prefix/systemd/system/chekuser.service
		print_center -verm2 'algo salio mal\nfalla al iniciar servicio chekuser'
	fi
	#enter
}

mod_fdate(){
	title 'SELECCIONA UN FORMATO DE FECHA'
	menu_func 'YYYY/MM/DD' 'DD/MM/YYYY'
    msg -bar
    date=$(selection_fun 2)
    case $date in
    	1)fecha="YYYY/MM/DD";;
    	2)fecha="DD/MM/YYYY";;
    esac
    [[ $date = 0 ]] && return
    del 3
    echo " $(msg -ama "Formato") $(msg -verd "$fecha")"
    enter
    formato=$(ps x|grep -v grep|grep chekuser.py|awk '{print $8}')
    systemctl stop chekuser &>/dev/null
    systemctl disable chekuser &>/dev/null
    sed -i "s/$formato/$date/g" $prefix/systemd/system/chekuser.service
    systemctl enable chekuser &>/dev/null
    systemctl start chekuser &>/dev/null

    if [[ $(systemctl is-active chekuser) = "active" ]]; then
		title -verd 'formato de fecha modificado'
		print_center -ama "FORMATO: $fecha"
	else
		systemctl stop chekuser &>/dev/null
    	systemctl disable chekuser &>/dev/null
    	rm -rf $prefix/systemd/system/chekuser.service
		print_center -verm2 'algo salio mal\nfalla al iniciar servicio chekuser'
	fi
	#enter

}

menu_chekuser(){
	title 'VERIFICACION DE USUARIOS ONLINE'
	num=1
	if [[ $(systemctl is-active chekuser) = "active" ]]; then
		formato=$(ps x|grep -v grep|grep chekuser.py|awk '{print $8}')
		case $formato in
    		1)fecha_data="YYYY/MM/DD";;
    		2)fecha_data="DD/MM/YYYY";;
    	esac
    
    	fecha_data=$(printf '%15s' "$fecha_data")
		port_chek=$(ps x|grep -v grep|grep chekuser.py|awk '{print $7}')
		msg -ama "\e[93mURL: http://$chk_ip:$port_chek/checkUser"
		port_chek=$(printf '%8s' "$port_chek")
	
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verm2 'DESACTIVAR') $(msg -azu 'CHEKUSER')"
		echo " $(msg -verd '[2]') $(msg -verm2 '>') $(msg -azu 'MODIFICAR PUERTO') $(msg -verd "$port_chek")"
		echo " $(msg -verd '[3]') $(msg -verm2 '>') $(msg -azu 'MODIFICAR FORMATO') $(msg -verd "$fecha_data")"
		msg -bar
		num=3
	else
	
        print_center -verm2 'ADVERTENCIA!!!\nesto puede generar consumo de ram/cpu\nen metodos de coneccion inestables\nse recomienda no usar chekuser en esos casos'
        msg -bar
		echo " $(msg -verd '[1]') $(msg -verm2 '>') $(msg -verd 'ACTIVAR') $(msg -azu 'CHEKUSER')"
		msg -bar
	fi
	back
	opcion=$(selection_fun $num)
	case $opcion in
		1)start;;
		2)mod_port;;
		3)mod_fdate;;
		0)return 1;;
	esac
}

while [[  $? -eq 0 ]]; do
  menu_chekuser
done


}

function _dropbear(){

fun_dropbear () {
 [[ -e $prefix/default/dropbear ]] && {
 msg -bar
 echo -e "\033[1;32m $(fun_trans ${id} "REMOVIENDO DROPBEAR")"
 msg -bar
 service dropbear stop & >/dev/null 2>&1
 fun_bar "apt-get remove dropbear -y"
 msg -bar
 echo -e "\033[1;32m $(fun_trans "Dropbear Removido")"
 msg -bar
 [[ -e $prefix/default/dropbear ]] && rm $prefix/default/dropbear
 return 0
 }

echo -e "\033[1;32m $(fun_trans "   INSTALADOR DROPBEAR")"
msg -bar
echo -e "\033[1;31m $(fun_trans "Seleccione Puertos Validados en orden secuencial:\n")\033[1;32m 22 80 81 82 85 90\033[1;37m"
msg -bar
echo -ne "\033[1;31m $(fun_trans "Digite  Puertos"): \033[1;37m" && read DPORT
tput cuu1 && tput dl1
TTOTAL=($DPORT)
    for((i=0; i<${#TTOTAL[@]}; i++)); do
        [[ $(mportas|grep "${TTOTAL[$i]}") = "" ]] && {
        echo -e "\033[1;33m $(fun_trans  "Puerto Elegido:")\033[1;32m ${TTOTAL[$i]} OK"
        PORT="$PORT ${TTOTAL[$i]}"
        } || {
        echo -e "\033[1;33m $(fun_trans  "Puerto Elegido:")\033[1;31m ${TTOTAL[$i]} FAIL"
        }
   done
  [[  -z $PORT ]] && {
  echo -e "\033[1;31m $(fun_trans  "Ningun Puerto Valida Fue Elegido")\033[0m"
  return 1
  }
sysvar=$(cat -n $prefix/issue |grep 1 |cut -d' ' -f6,7,8 |sed 's/1//' |sed 's/      //' | grep -o Ubuntu)
[[ ! $(cat $prefix/shells|grep "/bin/false") ]] && echo -e "/bin/false" >> $prefix/shells
[[ "$sysvar" != "" ]] && {
echo -e "Port 22
Protocol 2
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes" > $prefix/ssh/sshd_config
msg -bar
echo -e "${cor[2]} $(fun_trans ${id} "Instalando dropbear")"
msg -bar
fun_bar "apt-get install dropbear -y"
apt-get install dropbear -y > /dev/null 2>&1
msg -bar
touch $prefix/dropbear/banner
msg -bar
echo -e "${cor[2]} $(fun_trans ${id} "Configurando dropbear")"
cat <<EOF > $prefix/default/dropbear
NO_START=0
DROPBEAR_EXTRA_ARGS="VAR"
DROPBEAR_BANNER="$prefix/dropbear/banner"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
for dpts in $(echo $PORT); do
sed -i "s/VAR/-p $dpts VAR/g" $prefix/default/dropbear
done
sed -i "s/VAR//g" $prefix/default/dropbear
} || {
echo -e "Port 22
Protocol 2
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes" > $prefix/ssh/sshd_config
echo -e "${cor[2]} $(fun_trans  "Instalando dropbear")"
msg -bar
fun_bar "apt-get install dropbear -y"
touch $prefix/dropbear/banner
msg -bar
echo -e "${cor[2]} $(fun_trans  "Configurando dropbear")"
msg -bar
cat <<EOF > $prefix/default/dropbear
NO_START=0
DROPBEAR_EXTRA_ARGS="VAR"
DROPBEAR_BANNER="$prefix/dropbear/banner"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
for dpts in $(echo $PORT); do
sed -i "s/VAR/-p $dpts VAR/g" $prefix/default/dropbear
done
sed -i "s/VAR//g" $prefix/default/dropbear
}
fun_eth &>/dev/null
service ssh restart > /dev/null 2>&1
service dropbear restart > /dev/null 2>&1
echo -e "${cor[3]} $(fun_trans "Su dropbear ha sido configurado con EXITO")"
msg -bar
#UFW
for ufww in $(mportas|awk '{print $2}'); do
ufw allow $ufww > /dev/null 2>&1
done
}
fun_dropbear

}

function _openvpn(){

if readlink /proc/$$/exe | grep -q "dash"; then
    echo "Este script se utiliza con bash"
    exit
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "Sorry, solo funciona como root"
    exit
fi

if [[ ! -e /dev/net/tun ]]; then
    echo "El TUN device no esta disponible
Necesitas habilitar TUN antes de usar este script"
    exit
fi

if [[ -e $prefix/debian_version ]]; then
    OS=debian
    GROUPNAME=nogroup
    RCLOCAL='$prefix/rc.local'
elif [[ -e $prefix/centos-release || -e $prefix/redhat-release ]]; then
    OS=centos
    GROUPNAME=nobody
    RCLOCAL='$prefix/rc.d/rc.local'
else
    echo "Tu sistema operativo no esta disponible para este script"
    exit
fi

agrega_dns() {
    msg -ama " Escriba el HOST DNS que desea Agregar"
    read -p " [NewDNS]: " SDNS
    cat $prefix/hosts | grep -v "$SDNS" >$prefix/hosts.bak && mv -f $prefix/hosts.bak $prefix/hosts
    if [[ -e $prefix/opendns ]]; then
        cat $prefix/opendns >/tmp/opnbak
        mv -f /tmp/opnbak $prefix/opendns
        echo "$SDNS" >>$prefix/opendns
    else
        echo "$SDNS" >$prefix/opendns
    fi
    [[ -z $NEWDNS ]] && NEWDNS="$SDNS" || NEWDNS="$NEWDNS $SDNS"
    unset SDNS
}
mportas() {
    unset portas
    portas_var=$(lsof -V -i -P -n | grep -v "ESTABLISHED" | grep -v "COMMAND")
    while read port; do
        var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ "$(echo -e $portas | grep "$var1 $var2")" ]] || portas+="$var1 $var2 \n"
    done <<<"$portas_var"
    i=1
    echo -e "$portas"
}
dns_fun() {
    case $1 in
    3) dns[$2]='push "dhcp-option DNS 1.0.0.1"' ;;
    4) dns[$2]='push "dhcp-option DNS 1.1.1.1"' ;;
    5) dns[$2]='push "dhcp-option DNS 9.9.9.9"' ;;
    6) dns[$2]='push "dhcp-option DNS 1.1.1.1"' ;;
    7) dns[$2]='push "dhcp-option DNS 80.67.169.40"' ;;
    8) dns[$2]='push "dhcp-option DNS 80.67.169.12"' ;;
    9) dns[$2]='push "dhcp-option DNS 84.200.69.80"' ;;
    10) dns[$2]='push "dhcp-option DNS 84.200.70.40"' ;;
    11) dns[$2]='push "dhcp-option DNS 208.67.222.222"' ;;
    12) dns[$2]='push "dhcp-option DNS 208.67.220.220"' ;;
    13) dns[$2]='push "dhcp-option DNS 8.8.8.8"' ;;
    14) dns[$2]='push "dhcp-option DNS 8.8.4.4"' ;;
    15) dns[$2]='push "dhcp-option DNS 77.88.8.8"' ;;
    16) dns[$2]='push "dhcp-option DNS 77.88.8.1"' ;;
    17) dns[$2]='push "dhcp-option DNS 176.103.130.130"' ;;
    18) dns[$2]='push "dhcp-option DNS 176.103.130.131"' ;;
    esac
}
meu_ip() {
    if [[ -e ${sdir[0]}/MEUIPvps ]]; then
        echo "$(cat ${sdir[0]}/MEUIPvps)"
    else
        MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127 \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | grep -o -E '[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | head -1)
        MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
        [[ "$MEU_IP" != "$MEU_IP2" ]] && echo "$MEU_IP2" || echo "$MEU_IP"
        echo "$MEU_IP" >${sdir[0]}/MEUIPvps
    fi
}
IP="$(meu_ip)"

instala_ovpn2() {
    msg -bar3
    clear
    msg -bar
    
    echo -e " \033[1;32m     INSTALADOR DE OPENVPN | VPS-MX By @Kalix1"
    msg -bar
    # OpenVPN setup and first user creation
    echo -e " \033[1;97mSe necesitan ciertos parametros para configurar OpenVPN."
    echo "Configuracion por default solo presiona ENTER."
    echo "Primero, cual es la IPv4 que quieres para OpenVPN"
    echo "Detectando..."
    msg -bar
    # Autodetect IP address and pre-fill for the user
    IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127 \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | grep -oE '[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | head -1)
    read -p "IP address: " -e -i $IP IP
    # If $IP is a private IP address, the server must be behind NAT
    if echo "$IP" | grep -qE '^(10 \.|172 \.1[6789] \.|172 \.2[0-9] \.|172 \.3[01] \.|192 \.168)'; then
        echo
        echo "Este servidor esta detras de una red NAT?"
        read -p "IP  Publica  / hostname: " -e PUBLICIP
    fi
    msg -bar
    msg -ama "Que protocolo necesitas para las conexiones OpenVPN?"
    msg -bar
    echo "   1) UDP (recomendada)"
    echo "   2) TCP"
    msg -bar
    read -p "Protocolo [1-2]: " -e -i 1 PROTOCOL
    case $PROTOCOL in
    1)
        PROTOCOL=udp
        ;;
    2)
        PROTOCOL=tcp
        ;;
    esac
    msg -bar
    msg -ama "Que puerto necesitas en OpenVPN (Default 1194)?"
    msg -bar
    read -p "Puerto: " -e -i 1194 PORT
    msg -bar
    msg -ama "Cual DNS usaras en tu VPN?"
    msg -bar
    echo "   1) Actuales en el VPS"
    echo "   2) 1.1.1.1"
    echo "   3) Google"
    echo "   4) OpenDNS"
    echo "   5) Verisign"
    msg -bar
    read -p "DNS [1-5]: " -e -i 1 DNS
    #CIPHER
    msg -bar
    msg -ama " Elija que codificacion desea para el canal de datos:"
    msg -bar
    echo "   1) AES-128-CBC"
    echo "   2) AES-192-CBC"
    echo "   3) AES-256-CBC"
    echo "   4) CAMELLIA-128-CBC"
    echo "   5) CAMELLIA-192-CBC"
    echo "   6) CAMELLIA-256-CBC"
    echo "   7) SEED-CBC"
    echo "   8) NONE"
    msg -bar
    while [[ $CIPHER != @([1-8]) ]]; do
        read -p " Cipher [1-7]: " -e -i 1 CIPHER
    done
    case $CIPHER in
    1) CIPHER="cipher AES-128-CBC" ;;
    2) CIPHER="cipher AES-192-CBC" ;;
    3) CIPHER="cipher AES-256-CBC" ;;
    4) CIPHER="cipher CAMELLIA-128-CBC" ;;
    5) CIPHER="cipher CAMELLIA-192-CBC" ;;
    6) CIPHER="cipher CAMELLIA-256-CBC" ;;
    7) CIPHER="cipher SEED-CBC" ;;
    8) CIPHER="cipher none" ;;
    esac
    msg -bar
    msg -ama " Estamos listos para configurar su servidor OpenVPN"
    msg -bar
    read -n1 -r -p "Presiona cualquier tecla para continuar..."
    if [[ "$OS" = 'debian' ]]; then
        apt-get update
        apt-get install openvpn iptables openssl ca-certificates -y
    else
        #
        yum install epel-release -y
        yum install openvpn iptables openssl ca-certificates -y
    fi
    # Get easy-rsa
    EASYRSAURL='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz'
    wget -O ~/easyrsa.tgz "$EASYRSAURL" 2>/dev/null || curl -Lo ~/easyrsa.tgz "$EASYRSAURL"
    tar xzf ~/easyrsa.tgz -C ~/
    mv ~/EasyRSA-3.0.8/ $prefix/openvpn/
    mv $prefix/openvpn/EasyRSA-3.0.8/ $prefix/openvpn/easy-rsa/
    chown -R root:root $prefix/openvpn/easy-rsa/
    rm -f ~/easyrsa.tgz
    cd $prefix/openvpn/easy-rsa/
    #
    ./easyrsa init-pki
    ./easyrsa --batch build-ca nopass
    ./easyrsa gen-dh
    ./easyrsa build-server-full server nopass
    EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
    #
    cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key pki/crl.pem $prefix/openvpn
    #
    chown nobody:$GROUPNAME $prefix/openvpn/crl.pem
    #
    openvpn --genkey --secret $prefix/openvpn/ta.key
    #
    echo "port $PORT
proto $PROTOCOL
dev tun
sndbuf 0
rcvbuf 0
ca ca.crt
cert server.crt
key server.key
dh dh.pem
auth SHA512
tls-auth ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" >$prefix/openvpn/server.conf
    echo 'push "redirect-gateway def1 bypass-dhcp"' >>$prefix/openvpn/server.conf
    # DNS
    case $DNS in
    1)
        #
        #
        if grep -q "127.0.0.53" "$prefix/resolv.conf"; then
            RESOLVCONF='/run/systemd/resolve/resolv.conf'
        else
            RESOLVCONF='$prefix/resolv.conf'
        fi
        #
        grep -v '#' $RESOLVCONF | grep 'nameserver' | grep -E -o '[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | while read line; do
            echo "push  \"dhcp-option DNS $line \"" >>$prefix/openvpn/server.conf
        done
        ;;
    2)
        echo 'push "dhcp-option DNS 1.1.1.1"' >>$prefix/openvpn/server.conf
        echo 'push "dhcp-option DNS 1.0.0.1"' >>$prefix/openvpn/server.conf
        ;;
    3)
        echo 'push "dhcp-option DNS 8.8.8.8"' >>$prefix/openvpn/server.conf
        echo 'push "dhcp-option DNS 8.8.4.4"' >>$prefix/openvpn/server.conf
        ;;
    4)
        echo 'push "dhcp-option DNS 208.67.222.222"' >>$prefix/openvpn/server.conf
        echo 'push "dhcp-option DNS 208.67.220.220"' >>$prefix/openvpn/server.conf
        ;;
    5)
        echo 'push "dhcp-option DNS 64.6.64.6"' >>$prefix/openvpn/server.conf
        echo 'push "dhcp-option DNS 64.6.65.6"' >>$prefix/openvpn/server.conf
        ;;
    esac

    echo "keepalive 10 120
${CIPHER}
user nobody
group $GROUPNAME
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify crl.pem" >>$prefix/openvpn/server.conf
    updatedb
    PLUGIN=$(locate openvpn-plugin-auth-pam.so | head -1)
    [[ ! -z $(echo ${PLUGIN}) ]] && {
        echo "client-to-client
client-cert-not-required
username-as-common-name
plugin $PLUGIN login" >>$prefix/openvpn/server.conf
    }
    #
    echo 'net.ipv4.ip_forward=1' >$prefix/sysctl.d/30-openvpn-forward.conf
    #
    echo 1 >/proc/sys/net/ipv4/ip_forward
    if pgrep firewalld; then
        #
        #
        #
        #
        firewall-cmd --zone=public --add-port=$PORT/$PROTOCOL
        firewall-cmd --zone=trusted --add-source=10.8.0.0/24
        firewall-cmd --permanent --zone=public --add-port=$PORT/$PROTOCOL
        firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
        #
        firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
        firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
    else
        #
        if [[ "$OS" = 'debian' && ! -e $RCLOCAL ]]; then
            echo '#!/bin/sh -e
exit 0' >$RCLOCAL
        fi
        chmod +x $RCLOCAL
        #
        iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
        sed -i "1 a \iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP" $RCLOCAL
        if iptables -L -n | grep -qE '^(REJECT|DROP)'; then
            #
            #
            #
            iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
            iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
            iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
            sed -i "1 a \iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT" $RCLOCAL
            sed -i "1 a \iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT" $RCLOCAL
            sed -i "1 a \iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" $RCLOCAL
        fi
    fi
    #
    if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" && [[ "$PORT" != '1194' ]]; then
        #
        if ! hash semanage 2>/dev/null; then
            yum install policycoreutils-python -y
        fi
        semanage port -a -t openvpn_port_t -p $PROTOCOL $PORT
    fi
    #
    if [[ "$OS" = 'debian' ]]; then
        #
        if pgrep systemd-journal; then
            systemctl restart openvpn@server.service
        else
            $prefix/init.d/openvpn restart
        fi
    else
        if pgrep systemd-journal; then
            systemctl restart openvpn@server.service
            systemctl enable openvpn@server.service
        else
            service openvpn restart
            chkconfig openvpn on
        fi
    fi
    #
    if [[ "$PUBLICIP" != "" ]]; then
        IP=$PUBLICIP
    fi
    #
    echo "# OVPN_ACCESS_SERVER_PROFILE=VPS-MX
client
dev tun
proto $PROTOCOL
sndbuf 0
rcvbuf 0
remote $IP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
${CIPHER}
setenv opt block-outside-dns
key-direction 1
verb 3
auth-user-pass" >$prefix/openvpn/client-common.txt
    msg -bar
    msg -ama " Ahora crear una SSH para generar el (.ovpn)!"
    msg -bar
    echo -e " \033[1;32m Configuracion Finalizada!"
    msg -bar

}

instala_ovpn() {
    parametros_iniciais() {
        #Verifica o Sistema
        [[ "$EUID" -ne 0 ]] && echo " Lo siento, usted necesita ejecutar esto como ROOT" && exit 1
        [[ ! -e /dev/net/tun ]] && echo " TUN no esta Disponible" && exit 1
        if [[ -e $prefix/debian_version ]]; then
            OS="debian"
            VERSION_ID=$(cat $prefix/os-release | grep "VERSION_ID")
            IPTABLES='$prefix/iptables/iptables.rules'
            [[ ! -d $prefix/iptables ]] && mkdir $prefix/iptables
            [[ ! -e $IPTABLES ]] && touch $IPTABLES
            SYSCTL='$prefix/sysctl.conf'
            [[ "$VERSION_ID" != 'VERSION_ID="7"' ]] && [[ "$VERSION_ID" != 'VERSION_ID="8"' ]] && [[ "$VERSION_ID" != 'VERSION_ID="9"' ]] && [[ "$VERSION_ID" != 'VERSION_ID="14.04"' ]] && [[ "$VERSION_ID" != 'VERSION_ID="16.04"' ]] && [[ "$VERSION_ID" != 'VERSION_ID="18.04"' ]] && [[ "$VERSION_ID" != 'VERSION_ID="17.10"' ]] && {
                echo " Su vercion de Debian / Ubuntu no Soportada."
                while [[ $CONTINUE != @(y|Y|s|S|n|N) ]]; do
                    read -p "Continuar ? [y/n]: " -e CONTINUE
                done
                [[ "$CONTINUE" = @(n|N) ]] && exit 1
            }
        else
            msg -ama " Parece que no estas ejecutando este instalador en un sistema Debian o Ubuntu"
            msg -bar
            return 1
        fi
        #Pega Interface
        NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )( \S+)' | head -1)

    }
    add_repo() {
        #INSTALACAO E UPDATE DO REPOSITORIO
        # Debian 7
        if [[ "$VERSION_ID" = 'VERSION_ID="7"' ]]; then
            echo "deb http://build.openvpn.net/debian/openvpn/stable wheezy main" >$prefix/apt/sources.list.d/openvpn.list
            wget -q -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - >/dev/null 2>&1
        # Debian 8
        elif [[ "$VERSION_ID" = 'VERSION_ID="8"' ]]; then
            echo "deb http://build.openvpn.net/debian/openvpn/stable jessie main" >$prefix/apt/sources.list.d/openvpn.list
            wget -q -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - >/dev/null 2>&1
        # Ubuntu 14.04
        elif [[ "$VERSION_ID" = 'VERSION_ID="14.04"' ]]; then
            echo "deb http://build.openvpn.net/debian/openvpn/stable trusty main" >$prefix/apt/sources.list.d/openvpn.list
            wget -q -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - >/dev/null 2>&1
        # Ubuntu 16.04
        elif [[ "$VERSION_ID" = 'VERSION_ID="16.04"' ]]; then
            echo "deb http://build.openvpn.net/debian/openvpn/stable xenial main" >$prefix/apt/sources.list.d/openvpn.list
            wget -q -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - >/dev/null 2>&1
        # Ubuntu 18.04
        elif [[ "$VERSION_ID" = 'VERSION_ID="18.04"' ]]; then
            apt-get remove openvpn -y >/dev/null 2>&1
            rm -rf $prefix/apt/sources.list.d/openvpn.list >/dev/null 2>&1
            echo "deb http://build.openvpn.net/debian/openvpn/stable bionic main" >$prefix/apt/sources.list.d/openvpn.list
            wget -q -O - https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add - >/dev/null 2>&1
        fi
    }
    coleta_variaveis() {
        echo -e " \033[1;32m     INSTALADOR DE OPENVPN | VPS-MX By @Kalix1"
        msg -bar
        msg -ne " Confirme su IP"
        read -p ": " -e -i $IP ip
        msg -bar
        msg -ama " Que puerto desea usar?"
        msg -bar
        while true; do
            read -p " Port: " -e -i 1194 PORT
            [[ $(mportas | grep -w "$PORT") ]] || break
            echo -e " \033[1;33m Este puerto esta en uso \033[0m"
            unset PORT
        done
        msg -bar
        echo -e " \033[1;31m Que protocolo desea para las conexiones OPENVPN?"
        echo -e " \033[1;31m A menos que UDP este bloqueado, no utilice TCP (es mas lento)"
        #PROTOCOLO
        while [[ $PROTOCOL != @(UDP|TCP) ]]; do
            read -p " Protocol [UDP/TCP]: " -e -i TCP PROTOCOL
        done
        [[ $PROTOCOL = "UDP" ]] && PROTOCOL=udp
        [[ $PROTOCOL = "TCP" ]] && PROTOCOL=tcp
        #DNS
        msg -bar
        msg -ama " Que DNS desea utilizar?"
        msg -bar
        echo "   1) Usar DNS de sistema "
        echo "   2) Cloudflare"
        echo "   3) Quad"
        echo "   4) FDN"
        echo "   5) DNS.WATCH"
        echo "   6) OpenDNS"
        echo "   7) Google DNS"
        echo "   8) Yandex Basic"
        echo "   9) AdGuard DNS"
        msg -bar
        while [[ $DNS != @([1-9]) ]]; do
            read -p " DNS [1-9]: " -e -i 1 DNS
        done
        #CIPHER
        msg -bar
        msg -ama " Elija que codificacion desea para el canal de datos:"
        msg -bar
        echo "   1) AES-128-CBC"
        echo "   2) AES-192-CBC"
        echo "   3) AES-256-CBC"
        echo "   4) CAMELLIA-128-CBC"
        echo "   5) CAMELLIA-192-CBC"
        echo "   6) CAMELLIA-256-CBC"
        echo "   7) SEED-CBC"
        msg -bar
        while [[ $CIPHER != @([1-7]) ]]; do
            read -p " Cipher [1-7]: " -e -i 1 CIPHER
        done
        case $CIPHER in
        1) CIPHER="cipher AES-128-CBC" ;;
        2) CIPHER="cipher AES-192-CBC" ;;
        3) CIPHER="cipher AES-256-CBC" ;;
        4) CIPHER="cipher CAMELLIA-128-CBC" ;;
        5) CIPHER="cipher CAMELLIA-192-CBC" ;;
        6) CIPHER="cipher CAMELLIA-256-CBC" ;;
        7) CIPHER="cipher SEED-CBC" ;;
        esac
        msg -bar
        msg -ama " Estamos listos para configurar su servidor OpenVPN"
        msg -bar
        read -n1 -r -p " Enter para Continuar ..."
        tput cuu1 && tput dl1
    }
    parametros_iniciais # BREVE VERIFICACAO
    coleta_variaveis    # COLETA VARIAVEIS PARA INSTALAÇÃO
    add_repo            # ATUALIZA REPOSITÓRIO OPENVPN E INSTALA OPENVPN
    # Cria Diretorio
    [[ ! -d $prefix/openvpn ]] && mkdir $prefix/openvpn
    # Install openvpn
    echo -ne "  \033[1;31m[ ! ] apt-get update"
    apt-get update -q >/dev/null 2>&1 && echo -e " \033[1;32m [OK]" || echo -e " \033[1;31m [FAIL]"
    echo -ne "  \033[1;31m[ ! ] apt-get install openvpn curl openssl"
    apt-get install -qy openvpn curl >/dev/null 2>&1 && apt-get install openssl ca-certificates -y >/dev/null 2>&1 && echo -e " \033[1;32m [OK]" || echo -e " \033[1;31m [FAIL]"
    SERVER_IP="$(meu_ip)" # IP Address
    [[ -z "${SERVER_IP}" ]] && SERVER_IP=$(ip a | awk -F"[ /]+" '/global/ && !/127.0/ {print $3; exit}')
    echo -ne "  \033[1;31m[ ! ] Generating Server Config" # Gerando server.con
    (
        case $DNS in
        1)
            i=0
            grep -v '#' $prefix/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3} \.[0-9]{1,3}' | while read line; do
                dns[$i]="push  \"dhcp-option DNS $line \""
            done
            [[ ! "${dns[@]}" ]] && dns[0]='push "dhcp-option DNS 8.8.8.8"' && dns[1]='push "dhcp-option DNS 8.8.4.4"'
            ;;
        2) dns_fun 3 && dns_fun 4 ;;
        3) dns_fun 5 && dns_fun 6 ;;
        4) dns_fun 7 && dns_fun 8 ;;
        5) dns_fun 9 && dns_fun 10 ;;
        6) dns_fun 11 && dns_fun 12 ;;
        7) dns_fun 13 && dns_fun 14 ;;
        8) dns_fun 15 && dns_fun 16 ;;
        9) dns_fun 17 && dns_fun 18 ;;
        esac
        echo 01 >$prefix/openvpn/ca.srl
        while [[ ! -e $prefix/openvpn/dh.pem || -z $(cat $prefix/openvpn/dh.pem) ]]; do
            openssl dhparam -out $prefix/openvpn/dh.pem 2048 &>/dev/null
        done
        while [[ ! -e $prefix/openvpn/ca-key.pem || -z $(cat $prefix/openvpn/ca-key.pem) ]]; do
            openssl genrsa -out $prefix/openvpn/ca-key.pem 2048 &>/dev/null
        done
        chmod 600 $prefix/openvpn/ca-key.pem &>/dev/null
        while [[ ! -e $prefix/openvpn/ca-csr.pem || -z $(cat $prefix/openvpn/ca-csr.pem) ]]; do
            openssl req -new -key $prefix/openvpn/ca-key.pem -out $prefix/openvpn/ca-csr.pem -subj /CN=OpenVPN-CA/ &>/dev/null
        done
        while [[ ! -e $prefix/openvpn/ca.pem || -z $(cat $prefix/openvpn/ca.pem) ]]; do
            openssl x509 -req -in $prefix/openvpn/ca-csr.pem -out $prefix/openvpn/ca.pem -signkey $prefix/openvpn/ca-key.pem -days 365 &>/dev/null
        done
        cat >$prefix/openvpn/server.conf <<EOF
server 10.8.0.0 255.255.255.0
verb 3
duplicate-cn
key client-key.pem
ca ca.pem
cert client-cert.pem
dh dh.pem
keepalive 10 120
persist-key
persist-tun
comp-lzo
float
push "redirect-gateway def1 bypass-dhcp"
${dns[0]}
${dns[1]}

user nobody
group nogroup

${CIPHER}
proto ${PROTOCOL}
port $PORT
dev tun
status openvpn-status.log
EOF
        updatedb
        PLUGIN=$(locate openvpn-plugin-auth-pam.so | head -1)
        [[ ! -z $(echo ${PLUGIN}) ]] && {
            echo "client-to-client
client-cert-not-required
username-as-common-name
plugin $PLUGIN login" >>$prefix/openvpn/server.conf
        }
    ) && echo -e " \033[1;32m [OK]" || echo -e " \033[1;31m [FAIL]"
    echo -ne "  \033[1;31m[ ! ] Generating CA Config" # Generate CA Config
    (
        while [[ ! -e $prefix/openvpn/client-key.pem || -z $(cat $prefix/openvpn/client-key.pem) ]]; do
            openssl genrsa -out $prefix/openvpn/client-key.pem 2048 &>/dev/null
        done
        chmod 600 $prefix/openvpn/client-key.pem
        while [[ ! -e $prefix/openvpn/client-csr.pem || -z $(cat $prefix/openvpn/client-csr.pem) ]]; do
            openssl req -new -key $prefix/openvpn/client-key.pem -out $prefix/openvpn/client-csr.pem -subj /CN=OpenVPN-Client/ &>/dev/null
        done
        while [[ ! -e $prefix/openvpn/client-cert.pem || -z $(cat $prefix/openvpn/client-cert.pem) ]]; do
            openssl x509 -req -in $prefix/openvpn/client-csr.pem -out $prefix/openvpn/client-cert.pem -CA $prefix/openvpn/ca.pem -CAkey $prefix/openvpn/ca-key.pem -days 365 &>/dev/null
        done
    ) && echo -e " \033[1;32m [OK]" || echo -e " \033[1;31m [FAIL]"
    teste_porta() {
        msg -bar
        echo -ne "  \033[1;31m$(fun_trans ${id} "Verificando"):"
        sleep 1s
        [[ ! $(mportas | grep "$1") ]] && {
            echo -e " \033[1;33m [FAIL] \033[0m"
        } || {
            echo -e " \033[1;32m [Pass] \033[0m"
            return 1
        }
    }
    msg -bar
    echo -e " \033[1;33m Ahora Necesitamos un Proxy SQUID o PYTHON-OPENVPN"
    echo -e " \033[1;33m Si no existe un proxy en la puerta, un proxy Python sera abierto!"
    msg -bar
    while [[ $? != "1" ]]; do
        read -p " Confirme el Puerto(Proxy) " -e -i 80 PPROXY
        teste_porta $PPROXY
    done
    cat >$prefix/openvpn/client-common.txt <<EOF
# OVPN_ACCESS_SERVER_PROFILE=VPS-MX
client
nobind
dev tun
redirect-gateway def1 bypass-dhcp
remote-random
remote ${SERVER_IP} ${PORT} ${PROTOCOL}
http-proxy ${SERVER_IP} ${PPROXY}
$CIPHER
comp-lzo yes
keepalive 10 20
float
auth-user-pass
EOF
    # Iptables
    if [[ ! -f /proc/user_beancounters ]]; then
        INTIP=$(ip a | awk -F"[ /]+" '/global/ && !/127.0/ {print $3; exit}')
        N_INT=$(ip a | awk -v sip="$INTIP" '$0 ~ sip { print $7}')
        iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $N_INT -j MASQUERADE
        iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $SERVER_IP
    else
        iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to-source $SERVER_IP

    fi
    iptables-save >$prefix/iptables.conf
    cat >$prefix/network/if-up.d/iptables <<EOF
#!/bin/sh
iptables-restore < $prefix/iptables.conf
EOF
    chmod +x $prefix/network/if-up.d/iptables
    # Enable net.ipv4.ip_forward
    sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' $prefix/sysctl.conf
    echo 1 >/proc/sys/net/ipv4/ip_forward
    # Regras de Firewall
    if pgrep firewalld; then
        if [[ "$PROTOCOL" = 'udp' ]]; then
            firewall-cmd --zone=public --add-port=$PORT/udp
            firewall-cmd --permanent --zone=public --add-port=$PORT/udp
        elif [[ "$PROTOCOL" = 'tcp' ]]; then
            firewall-cmd --zone=public --add-port=$PORT/tcp
            firewall-cmd --permanent --zone=public --add-port=$PORT/tcp
        fi
        firewall-cmd --zone=trusted --add-source=10.8.0.0/24
        firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
    fi
    if iptables -L -n | grep -qE 'REJECT|DROP'; then
        if [[ "$PROTOCOL" = 'udp' ]]; then
            iptables -I INPUT -p udp --dport $PORT -j ACCEPT
        elif [[ "$PROTOCOL" = 'tcp' ]]; then
            iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
        fi
        iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
        iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables-save >$IPTABLES
    fi
    if hash sestatus 2>/dev/null; then
        if sestatus | grep "Current mode" | grep -qs "enforcing"; then
            if [[ "$PORT" != '1194' ]]; then
                if ! hash semanage 2>/dev/null; then
                    yum install policycoreutils-python -y
                fi
                if [[ "$PROTOCOL" = 'udp' ]]; then
                    semanage port -a -t openvpn_port_t -p udp $PORT
                elif [[ "$PROTOCOL" = 'tcp' ]]; then
                    semanage port -a -t openvpn_port_t -p tcp $PORT
                fi
            fi
        fi
    fi
    #Liberando DNS
    msg -bar
    msg -ama " Ultimo Paso, Configuraciones DNS"
    msg -bar
    while [[ $DDNS != @(n|N) ]]; do
        echo -ne " \033[1;33m"
        read -p " Agergar HOST DNS [S/N]: " -e -i n DDNS
        [[ $DDNS = @(s|S|y|Y) ]] && agrega_dns
    done
    [[ ! -z $NEWDNS ]] && {
        sed -i "/127.0.0.1[[:blank:]] \+localhost/a 127.0.0.1 $NEWDNS" $prefix/hosts
        for DENESI in $(echo $NEWDNS); do
            sed -i "/remote ${SERVER_IP} ${PORT} ${PROTOCOL}/a remote ${DENESI} ${PORT} ${PROTOCOL}" $prefix/openvpn/client-common.txt
        done
    }
    msg -bar
    # REINICIANDO OPENVPN
    if [[ "$OS" = 'debian' ]]; then
        if pgrep systemd-journal; then
            sed -i 's|LimitNPROC|#LimitNPROC|' /lib/systemd/system/openvpn \@.service
            sed -i 's|$prefix/openvpn/server|$prefix/openvpn|' /lib/systemd/system/openvpn \@.service
            sed -i 's|%i.conf|server.conf|' /lib/systemd/system/openvpn \@.service
            #systemctl daemon-reload
            (
                systemctl restart openvpn
                systemctl enable openvpn
            ) >/dev/null 2>&1
        else
            $prefix/init.d/openvpn restart >/dev/null 2>&1
        fi
    else
        if pgrep systemd-journal; then
            (
                systemctl restart openvpn@server.service
                systemctl enable openvpn@server.service
            ) >/dev/null 2>&1
        else
            (
                service openvpn restart
                chkconfig openvpn on
            ) >/dev/null 2>&1
        fi
    fi
    service squid restart &>/dev/null
    service squid3 restart &>/dev/null
    apt-get install ufw -y >/dev/null 2>&1
    for ufww in $(mportas | awk '{print $2}'); do
        ufw allow $ufww >/dev/null 2>&1
    done
    #Restart OPENVPN
    (
        killall openvpn 2>/dev/null
        systemctl stop openvpn@server.service >/dev/null 2>&1
        service openvpn stop >/dev/null 2>&1
        sleep 0.1s
        cd $prefix/openvpn >/dev/null 2>&1
        screen -dmS ovpnscr openvpn --config "server.conf" >/dev/null 2>&1
    ) >/dev/null 2>&1
    echo -e " \033[1;32m Openvpn configurado con EXITO!"
    msg -bar
    msg -ama " Ahora crear una SSH para generar el (.ovpn)!"
    msg -bar
    return 0
}
edit_ovpn_host() {
    msg -bar3
    msg -ama " CONFIGURACION HOST DNS OPENVPN"
    msg -bar
    while [[ $DDNS != @(n|N) ]]; do
        echo -ne " \033[1;33m"
        read -p " Agregar host [S/N]: " -e -i n DDNS
        [[ $DDNS = @(s|S|y|Y) ]] && agrega_dns
    done
    [[ ! -z $NEWDNS ]] && sed -i "/127.0.0.1[[:blank:]] \+localhost/a 127.0.0.1 $NEWDNS" $prefix/hosts
    msg -bar
    msg -ama " Es Necesario el Reboot del Servidor Para"
    msg -ama " Para que las configuraciones sean efectudas"
    msg -bar
}
fun_openvpn() {
    [[ -e $prefix/openvpn/server.conf ]] && {
        unset OPENBAR
        [[ $(mportas | grep -w "openvpn") ]] && OPENBAR=" \033[1;32m ONLINE" || OPENBAR=" \033[1;31m OFFLINE"
        msg -ama " OPENVPN YA ESTA INSTALADO"
        msg -bar
        echo -e " \033[1;32m [1] > \033[1;36m DESINSTALAR  OPENVPN"
        echo -e " \033[1;32m [2] > \033[1;36m EDITAR CONFIGURACION CLIENTE  \033[1;31m(MEDIANTE NANO)"
        echo -e " \033[1;32m [3] > \033[1;36m EDITAR CONFIGURACION SERVIDOR  \033[1;31m(MEDIANTE NANO)"
        echo -e " \033[1;32m [4] > \033[1;36m CAMBIAR HOST DE OPENVPN"
        echo -e " \033[1;32m [5] > \033[1;36m INICIAR O PARAR OPENVPN - $OPENBAR"
        msg -bar
        while [[ $xption != @([0|1|2|3|4|5]) ]]; do
            echo -ne " \033[1;33m $(fun_trans "Opcion"): " && read xption
            tput cuu1 && tput dl1
        done
        case $xption in
        1)
            clear
            msg -bar
            echo -ne " \033[1;97m"
            read -p "QUIERES DESINTALAR OPENVPN? [Y/N]: " -e REMOVE
            msg -bar
            if [[ "$REMOVE" = 'y' || "$REMOVE" = 'Y' ]]; then
                PORT=$(grep '^port ' $prefix/openvpn/server.conf | cut -d " " -f 2)
                PROTOCOL=$(grep '^proto ' $prefix/openvpn/server.conf | cut -d " " -f 2)
                if pgrep firewalld; then
                    IP=$(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING | grep ' \-s 10.8.0.0/24 '"'"'!'"'"' -d 10.8.0.0/24 -j SNAT --to ' | cut -d " " -f 10)
                    #
                    firewall-cmd --zone=public --remove-port=$PORT/$PROTOCOL
                    firewall-cmd --zone=trusted --remove-source=10.8.0.0/24
                    firewall-cmd --permanent --zone=public --remove-port=$PORT/$PROTOCOL
                    firewall-cmd --permanent --zone=trusted --remove-source=10.8.0.0/24
                    firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
                    firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
                else
                    IP=$(grep 'iptables -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to ' $RCLOCAL | cut -d " " -f 14)
                    iptables -t nat -D POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to $IP
                    sed -i '/iptables -t nat -A POSTROUTING -s 10.8.0.0 \/24 ! -d 10.8.0.0 \/24 -j SNAT --to /d' $RCLOCAL
                    if iptables -L -n | grep -qE '^ACCEPT'; then
                        iptables -D INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
                        iptables -D FORWARD -s 10.8.0.0/24 -j ACCEPT
                        iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
                        sed -i "/iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT/d" $RCLOCAL
                        sed -i "/iptables -I FORWARD -s 10.8.0.0 \/24 -j ACCEPT/d" $RCLOCAL
                        sed -i "/iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT/d" $RCLOCAL
                    fi
                fi
                if sestatus 2>/dev/null | grep "Current mode" | grep -q "enforcing" && [[ "$PORT" != '1194' ]]; then
                    semanage port -d -t openvpn_port_t -p $PROTOCOL $PORT
                fi
                if [[ "$OS" = 'debian' ]]; then
                    apt-get remove --purge -y openvpn
                else
                    yum remove openvpn -y
                fi
                rm -rf $prefix/openvpn
                rm -f $prefix/sysctl.d/30-openvpn-forward.conf
                msg -bar
                echo "OpenVPN removido!"
                msg -bar
            else
                msg -bar
                echo "Desinstalacion abortada!"
                msg -bar
            fi
            return 0
            ;;
        2)
            nano $prefix/openvpn/client-common.txt
            return 0
            ;;
        3)
            nano $prefix/openvpn/server.conf
            return 0
            ;;
        4) edit_ovpn_host ;;
        5)
            [[ $(mportas | grep -w openvpn) ]] && {
                $prefix/init.d/openvpn stop >/dev/null 2>&1
                killall openvpn &>/dev/null
                systemctl stop openvpn@server.service &>/dev/null
                service openvpn stop &>/dev/null
                #ps x |grep openvpn |grep -v grep|awk '{print $1}' | while read pid; do kill -9 $pid; done
            } || {
                cd $prefix/openvpn
                screen -dmS ovpnscr openvpn --config "server.conf" >/dev/null 2>&1
                cd $HOME
            }
            msg -ama " Procedimiento Hecho con Exito"
            msg -bar
            return 0
            ;;
        0)
            return 0
            ;;
        esac
        exit
    }
    [[ -e $prefix/squid/squid.conf ]] && instala_ovpn2 && return 0
    [[ -e $prefix/squid3/squid.conf ]] && instala_ovpn2 && return 0

    instala_ovpn2 || return 1
}

fun_openvpn

}

function _shadowsocks(){

config="$prefix/shadowsocks-libev/config.json"

del_shadowsocks () {
[[ -e $prefix/shadowsocks-libev/config.json ]] && {
[[ $(ps ax|grep ss-server|grep -v grep|awk '{print $1}') != "" ]] && kill -9 $(ps ax|grep ss-server|grep -v grep|awk '{print $1}') > /dev/null 2>&1 && ss-server -c $prefix/shadowsocks-libev/config.json -d stop > /dev/null 2>&1
echo -e "\033[1;33m	SHADOWSOCKS LIBEV DETENIDO"
msg -bar
rm $prefix/shadowsocks-libev/config.json
rm -rf Instalador-libev.sh Instalador-libev.log shadowsocks_libev_qr.png
rm -rf Instalador-libev.sh Instalador-libev.log
return 0
}
}

[[ $(ps ax | grep ss-server | grep -v grep | awk '{print $1}') ]] && ss="\e[92m[ ON ]" || ss="\e[91m[ OFF ]"

echo -e "       \e[91m\e[43mINSTALADOR SHADOWSOCKS-LIBEV+(obfs)\e[0m "
msg -bar
echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "INSTALAR SHADOWSOCKS LIBEV") $ss"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "DESINSTALAR SHADOWSOCKS LIBEV")"
echo -e "$(msg -verd "[3]")$(msg -verm2 "➛ ")$(msg -azu "VER CONFI LIBEV")"
echo -e "$(msg -verd "[4]")$(msg -verm2 "➛ ")$(msg -azu "MODIFICAR CONFIGURACION (nano)")"
echo -e "$(msg -verd "[0]")$(msg -verm2 "➛ ")$(msg -azu "VOLVER")"
msg -bar
echo -n " Selecione Una Opcion: "
read opcao
case $opcao in
1)
clear
msg -bar
wget --no-check-certificate -O Instalador-libev.sh https://raw.githubusercontent.com/lacasitamx/ZETA/master/sha/Instalador-libev.sh > /dev/null 2>&1
chmod +x Instalador-libev.sh
./Instalador-libev.sh 2>&1 | tee Instalador-libev.log
value=$(ps ax |grep ss-server|grep -v grep)
[[ $value != "" ]] && value="\033[1;32mINICIADO CON EXITO" || value="\033[1;31mERROR"
msg -bar
echo -e "${value}"
msg -bar
;;
2)
clear
msg -bar
echo -e "\033[1;93m  Desinstalar  ..."
del_shadowsocks
msg -bar
wget --no-check-certificate -O Instalador-libev.sh https://raw.githubusercontent.com/lacasitamx/ZETA/master/sha/Instalador-libev.sh > /dev/null 2>&1
chmod +x Instalador-libev.sh
./Instalador-libev.sh uninstall
rm -rf Instalador-libev.sh Instalador-libev.log shadowsocks_libev_qr.png

msg -bar
sleep 3
exit
;;
3)
clear
msg -bar
msg -ama " VER CONFIGURACION"
msg -bar
if [[ ! -e ${config} ]]; then
msg -verm " NO HAY INFORMACION"
else
cat $prefix/shadowsocks-libev/confis
msg -bar
fi
;;
4)
clear
msg -bar
msg -ama " MODIFICAR CONFIGURACION"
msg -bar

if [[ ! -e ${config} ]]; then
msg -verm " NO HAY INFORMACION"
else
msg -verd " para guardar la confi precione ( crtl + x )"
read -p " enter para continuar"
nano ${config}
msg -bar
$prefix/init.d/shadowsocks-libev restart
msg -bar
fi
;;
esac

}

function _slowdns(){

#!/bin/bash
ADM_inst="${sdir[0]}/Slow/install"
ADM_slow="${sdir[0]}/Slow/Key"
info(){
	clear
	nodata(){
		msg -bar
		msg -ama "!SIN INFORMACION SLOWDNS!"
		exit 0
	}

	if [[ -e  ${ADM_slow}/domain_ns ]]; then
		ns=$(cat ${ADM_slow}/domain_ns)
		if [[ -z "$ns" ]]; then
			nodata
			exit 0
		fi
	else
		nodata
		exit 0
	fi

	if [[ -e ${ADM_slow}/server.pub ]]; then
		key=$(cat ${ADM_slow}/server.pub)
		if [[ -z "$key" ]]; then
			nodata
			exit 0
		fi
	else
		nodata
		exit 0
	fi

	msg -bar
	msg -ama "DATOS DE SU CONEXION SLOWDNS"
	msg -bar
	msg -ama "Su NS (Nameserver): $(cat ${ADM_slow}/domain_ns)"
	msg -bar
	msg -ama "Su Llave: $(cat ${ADM_slow}/server.pub)"
	
	exit 0
}

drop_port(){
    local portasVAR=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
    local NOREPEAT
    local reQ
    local Port
    unset DPB
    while read port; do
        reQ=$(echo ${port}|awk '{print $1}')
        Port=$(echo {$port} | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ $(echo -e $NOREPEAT|grep -w "$Port") ]] && continue
        NOREPEAT+="$Port\n"

        case ${reQ} in
        	sshd|dropbear|trojan|stunnel4|stunnel|python|python3|v2ray|xray)DPB+=" $reQ:$Port";;
            *)continue;;
        esac
    done <<< "${portasVAR}"
 }

ini_slow(){
clear
msg -bar
	msg -ama "	INSTALADOR SLOWDNS"
	msg -bar
	echo ""
	drop_port
	n=1
    for i in $DPB; do
        proto=$(echo $i|awk -F ":" '{print $1}')
        proto2=$(printf '%-12s' "$proto")
        port=$(echo $i|awk -F ":" '{print $2}')
        echo -e " $(msg -verd "[$n]") $(msg -verm2 ">") $(msg -ama "$proto2")$(msg -azu "$port")"
        drop[$n]=$port
        dPROT[$n]=$proto2
        num_opc="$n"
        let n++ 
    done
    msg -bar
    opc=$(selection_fun $num_opc)
    echo "${drop[$opc]}" > ${ADM_slow}/puerto
    echo "${dPROT[$opc]}" >${ADM_slow}/puertoloc
    PORT=$(cat ${ADM_slow}/puerto)
    clear
    msg -bar
    msg -ama "	INSTALADOR SLOWDNS"
    msg -bar
    echo ""
    echo -e " $(msg -ama "Puerto de conexion atraves de SlowDNS:") $(msg -verd "$PORT")"
    msg -bar

    unset NS
    while [[ -z $NS ]]; do
    	msg -ama " Tu dominio NS: "
    	read NS
    	tput cuu1 && tput dl1
    done
    echo "$NS" > ${ADM_slow}/domain_ns
    echo -e " $(msg -ama "Tu dominio NS:") $(msg -verd "$NS")"
    msg -bar

    if [[ ! -e ${ADM_inst}/dns-server ]]; then
    	msg -ama " Descargando binario...."
    	if wget -O ${ADM_inst}/dns-server raw.github.com/lacasitamx/SCRIPTMOD-LACASITA/master/SLOWDNS/dns-server &>/dev/null ; then
    		chmod +x ${ADM_inst}/dns-server
    		msg -verd " DESCARGA CON EXITO"
    	else
    		msg -verm " DESCARGA FALLIDA"
    		msg -bar
    		msg -ama "No se pudo descargar el binario"
    		msg -verm "Instalacion cancelada"
    		
    		exit 0
    	fi
    	msg -bar
    fi

    [[ -e "${ADM_slow}/server.pub" ]] && pub=$(cat ${ADM_slow}/server.pub)

    if [[ ! -z "$pub" ]]; then
    	msg -ama " Usar La clave existente [S/N] ?: "
    	read ex_key

    	case $ex_key in
    		s|S|y|Y) tput cuu1 && tput dl1
    			 echo -e " $(msg -ama "Tu clave:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")";;
    		n|N) tput cuu1 && tput dl1
    			 rm -rf ${ADM_slow}/server.key
    			 rm -rf ${ADM_slow}/server.pub
    			 ${ADM_inst}/dns-server -gen-key -privkey-file ${ADM_slow}/server.key -pubkey-file ${ADM_slow}/server.pub &>/dev/null
    			 echo -e " $(msg -ama "Tu clave:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")";;
    		*);;
    	esac
    else
    	rm -rf ${ADM_slow}/server.key
    	rm -rf ${ADM_slow}/server.pub
    	${ADM_inst}/dns-server -gen-key -privkey-file ${ADM_slow}/server.key -pubkey-file ${ADM_slow}/server.pub &>/dev/null
    	echo -e " $(msg -ama "Tu clave:") $(msg -verd "$(cat ${ADM_slow}/server.pub)")"
    fi
    msg -bar
    msg -ama "    INSTALANDO SERVICIO 𝙎𝙇𝙊𝙒𝘿𝙉𝙎   ..." |pv -q 30
    apt install ncurses-utils -y &>/dev/null
    
	apt install iptables -y &>/dev/null
	#iptables -F >/dev/null 2>&1
   iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    echo "nameserver 1.1.1.1 " >$prefix/resolv.conf
    echo "nameserver 1.0.0.1 " >>$prefix/resolv.conf
    
    screen -dmS slowdns ${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT
    [[ $(grep -wc "slowdns" $prefix/autostart) = '0' ]] && {
						echo -e "netstat -au | grep -w 7300 > /dev/null || {  screen -r -S 'slowdns' -X quit;  screen -dmS slowdns ${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT ; }" >>$prefix/autostart
					} || {
						sed -i '/slowdns/d' $prefix/autostart
						echo -e "netstat -au | grep -w 7300 > /dev/null || {  screen -r -S 'slowdns' -X quit;  screen -dmS slowdns ${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT ; }" >>$prefix/autostart
					}
    	msg -verd " INSTALACION CON EXITO"
    
    exit 0
}

reset_slow(){
	clear
	msg -bar
	msg -verd "    Reiniciando 𝙎𝙇𝙊𝙒𝘿𝙉𝙎...."
	screen -ls | grep slowdns | cut -d. -f1 | awk '{print $1}' | xargs kill
	NS=$(cat ${ADM_slow}/domain_ns)
	PORT=$(cat ${ADM_slow}/puerto)
	screen -dmS slowdns ${ADM_inst}/dns-server -udp :5300 -privkey-file /root/server.key $NS 127.0.0.1:$PORT
	[[ $(grep -wc "slowdns" $prefix/autostart) = '0' ]] && {
						echo -e "netstat -au | grep -w 7300 > /dev/null || {  screen -r -S 'slowdns' -X quit;  screen -dmS slowdns ${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT ; }" >>$prefix/autostart
					} || {
						sed -i '/slowdns/d' $prefix/autostart
						echo -e "netstat -au | grep -w 7300 > /dev/null || {  screen -r -S 'slowdns' -X quit;  screen -dmS slowdns ${ADM_inst}/dns-server -udp :5300 -privkey-file ${ADM_slow}/server.key $NS 127.0.0.1:$PORT ; }" >>$prefix/autostart
					}
		msg -verd " SERVICIO SLOW REINICIADO"
	
	exit 0
}
stop_slow(){
	clear
	msg -bar
	msg -ama "    Deteniendo SlowDNS...."
	if screen -ls | grep slowdns | cut -d. -f1 | awk '{print $1}' | xargs kill ; then
	for pidslow in $(screen -ls | grep ".slowdns" | awk {'print $1'}); do
						screen -r -S "$pidslow" -X quit
			done
			[[ $(grep -wc "dns-server" $prefix/autostart) != '0' ]] && {
						sed -i '/dns-server/d' $prefix/autostart
			}
  screen -wipe >/dev/null
		msg -verd " SERVICIO SLOW DETENIDO!!"
		rm ${ADM_inst}/dns-server &>/dev/null
		rm -rf ${ADM_slow}/* &>/dev/null
	else
		msg -verm " SERVICIO SLOW NO DETENIDO!"
	fi
	exit 0
}
portdns(){
  proto="dns-serve"
  portas=$(lsof -V -i -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND")
  for list in $proto; do
    case $list in
      dns-serve)
      portas2=$(echo $portas|grep -w "$list")
      [[ $(echo "${portas2}"|grep "$list") ]] && inst[$list]="\033[1;33m[\e[1;92mActivo\e[33m] " || inst[$list]="\033[1;33m[\e[1;91mDesactivado\e[1;33m]";;
    esac
  done
  }
while :
do
	portdns
	if [[ -e ${ADM_slow}/puertoloc ]]; then LOC=$((cat ${ADM_slow}/puertoloc)|cut -d' ' -f1); else LOC="XX"; fi
	if [[ -e ${ADM_slow}/puerto ]]; then PT=$((cat ${ADM_slow}/puerto)|cut -d' ' -f1); else PT="XX"; fi

	msg -ama "	\e[91m\e[43mMENÚ DE INSTALACION 𝙎𝙇𝙊𝙒𝘿𝙉𝙎   \e[0m"
	echo ""
	#if [[ -e ${ADM_inst}/dns-server ]]; then
	echo -e "     \e[91mSlowDNS\e[93m + \e[92m${LOC} \e[97m»» \e[91m${PT} \e[1;97mSERVICIO: ${inst[dns-serv]}\e[0m"
	#else
	#echo -e "	\e[1;97mSERVICIO: ${inst[dns-serv]}"
	#fi
	
	msg -bar
	
	echo -e "  $(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "INSTALAR 𝙎𝙇𝙊𝙒𝘿𝙉𝙎  ")"
	echo -e "  $(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "REINICIAR 𝙎𝙇𝙊𝙒𝘿𝙉𝙎  ")"
	echo -e "  $(msg -verd "[3]")$(msg -verm2 "➛ ")$(msg -azu "DETENER 𝙎𝙇𝙊𝙒𝘿𝙉𝙎  ")"
	echo -e "  $(msg -verd "[4]")$(msg -verm2 "➛ ")$(msg -azu "DATOS DE LA CUENTA")"
	echo -e "  $(msg -verd "[0]")$(msg -verm2 "➛ ")$(msg -azu "VOLVER")"
	msg -bar
	echo -ne "  \033[1;37mSelecione Una Opcion : "
read opc
case $opc in
		1)ini_slow;;
		2)reset_slow;;
		3)stop_slow;;
		4)info;;
		0)exit;;
	esac
done

}

function _sockspy(){
[[ $(dpkg --get-selections | grep -w "python" | head -1) ]] || apt-get install python -y &>/dev/null
[[ $(dpkg --get-selections | grep -w "python-pip" | head -1) ]] || apt-get install python pip -y &>/dev/null
[[ $(dpkg --get-selections | grep -w "net-tools" | head -1) ]] || apt-get install net-tools -y &>/dev/null
IP=$ip

tcpbypass_fun() {
    [[ -e $HOME/socks ]] && rm -rf $HOME/socks >/dev/null 2>&1
    [[ -d $HOME/socks ]] && rm -rf $HOME/socks >/dev/null 2>&1
    cd $HOME && mkdir socks >/dev/null 2>&1
    cd socks
    patch="https://www.dropbox.com/s/mn75pqufdc7zn97/backsocz"
    arq="backsocz"
    wget $patch -o /dev/null
    unzip $arq >/dev/null 2>&1
    mv -f ./ssh $prefix/ssh/sshd_config && service ssh restart 1>/dev/null 2>/dev/null
    mv -f sckt$(python3 --version | awk '{print $2}' | cut -d'.' -f1,2) /usr/sbin/sckt
    mv -f scktcheck /bin/scktcheck
    chmod +x /bin/scktcheck
    chmod +x /usr/sbin/sckt
    rm -rf $HOME/socks
    cd $HOME
    msg="$2"
    [[ $msg = "" ]] && msg="@vpsmod"
    portxz="$1"
    [[ $portxz = "" ]] && portxz="8080"
    screen -dmS sokz scktcheck "$portxz" "$msg" >/dev/null 2>&1
}
gettunel_fun() {
    echo "master=NetVPS" >${sdir[inst]}/pwd.pwd
    while read service; do
        [[ -z $service ]] && break
        echo "127.0.0.1:$(echo $service | cut -d' ' -f2)=$(echo $service | cut -d' ' -f1)" >>${sdir[inst]}/pwd.pwd
    done <<<"$(mportas)"
    screen -dmS getpy python ${sdir[inst]}/PGet.py -b "0.0.0.0:$1" -p "${sdir[inst]}/pwd.pwd"
    [[ "$(ps x | grep "PGet.py" | grep -v "grep" | awk -F "pts" '{print $1}')" ]] && {
        echo -e "Gettunel Iniciado con Sucesso"
        msg -bar
        echo -ne "Su contraseña Gettunel es:"
        echo -e "\033[1;32m NetVPS"
        msg -bar
    } || echo -e "Gettunel no fue iniciado"
    msg -bar
}

sistema20() {
    if [[ ! -e ${sdir[0]}/fix ]]; then
        echo ""
        ins() {
            export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/
            apt-get install python -y
            apt-get install python pip -y
        }
        ins &>/dev/null && echo -e "INSTALANDO FIX" | pv -qL 40
        sleep 1.s
        [[ ! -e ${sdir[0]}/fix ]] && touch ${sdir[0]}/fix
    else
        echo ""
    fi
}
sistema22() {
    if [[ ! -e ${sdir[0]}/fixer ]]; then
        echo ""
        ins() {
            export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/
            apt-get install python2 -y
            apt-get install python -y
            apt install python pip -y
            rm -rf /usr/bin/python
            ln -s /usr/bin/python2.7 /usr/bin/python
        }
        ins &>/dev/null && echo -e "INSTALANDO FIX" | pv -qL 40
        sleep 1.s
        [[ ! -e ${sdir[0]}/fixer ]] && touch ${sdir[0]}/fixer
    else
        echo ""
    fi
}

PythonDic_fun() {

    clear
    echo ""
    echo ""
    
    msg -bar
    echo -e "\033[1;31m  SOCKS DIRECTO-PY | CUSTOM\033[0m"
    while true; do
        msg -bar
        echo -ne "\033[1;37m"
        read -p " ESCRIBE SU PUERTO: " porta_socket
        echo -e ""
        [[ $(mportas | grep -w "$porta_socket") ]] || break
        echo -e " ESTE PUERTO YA ESTÁ EN USO"
        unset porta_socket
    done
    msg -bar
    echo -e "\033[1;97m Digite Un Puerto Local 22|443|80\033[1;37m"
    msg -bar
    while true; do
        echo -ne "\033[1;36m"
        read -p " Digite Un Puerto SSH/DROPBEAR activo: " PORTLOC
        echo -e ""
        if [[ ! -z $PORTLOC ]]; then
            if [[ $(echo $PORTLOC | grep [0-9]) ]]; then
                [[ $(mportas | grep $PORTLOC | head -1) ]] && break || echo -e "ESTE PUERTO NO EXISTE"
            fi
        fi
    done
    #
    puertoantla="$(mportas | grep $PORTLOC | awk '{print $2}' | head -1)"
    msg -bar
    echo -ne " Escribe El HTTP Response? 101|200|300: \033[1;37m" && read cabezado
    tput cuu1 && tput dl1
    if [[ -z $cabezado ]]; then
        cabezado="200"
        echo -e "	\e[31mResponse Default:\033[1;32m ${cabezado}"
    else
        echo -e "	\e[31mResponse Elegido:\033[1;32m ${cabezado}"
    fi
    msg -bar
    echo -e "$(fun_trans "Introdusca su Mini-Banner")"
    msg -bar
    echo -ne " Introduzca el texto de estado plano o en HTML:\n \033[1;37m" && read texto_soket
    tput cuu1 && tput dl1
    if [[ -z $texto_soket ]]; then
        texto_soket="$ress"
        echo -e "	\e[31mMensage Default: \033[1;32m${texto_soket} "
    else
        echo -e "	\e[31mMensage: \033[1;32m ${texto_soket}"
    fi
    msg -bar

    (
        less <<CPM >${sdir[0]}/protocolos/PDirect.py
import socket, threading, thread, select, signal, sys, time, getopt

# Listen
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = int("$porta_socket")
PASS = ''

# CONST
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:$puertoantla'
RESPONSE = 'HTTP/1.1 $cabezado <strong>$texto_soket</strong>\r\n\r\nHTTP/1.1 $cabezado Conexion Exitosa\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()
    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()
    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()
    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()
class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True
    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            if hostPort == '':
                hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, 'X-Split')
            if split != '':
                self.client.recv(BUFLEN)
            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
				
                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + e.strerror
            self.server.printLog(self.log)
	    pass
        finally:
            self.close()
            self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + ': ')
        if aux == -1:
            return ''
        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')
        if aux == -1:
            return ''
        return head[:aux];
    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method=='CONNECT':
            	
                port = 443
            else:
                port = 80
                port = 8080
                port = 8799
                port = 3128
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path
        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = ''
        self.server.printLog(self.log)
        self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
		    try:
                        data = in_.recv(BUFLEN)
                        if data:
			    if in_ is self.target:
				self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]
                            count = 0
			else:
			    break
		    except:
                        error = True
                        break
            if count == TIMEOUT:
                error = True
            if error:
                break
def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print "\n:-------PythonProxy-------:\n"
    print "Listening addr: " + LISTENING_ADDR
    print "Listening port: " + str(LISTENING_PORT) + "\n"
    print ":-------------------------:\n"
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    while True:
        try:
            time.sleep(2)
        except KeyboardInterrupt:
            print 'Stopping...'
            server.close()
            break
if __name__ == '__main__':
    main()
CPM
    ) >$HOME/proxy.log &

    chmod +x ${sdir[0]}/protocolos/PDirect.py
    screen -dmS ws$porta_socket python ${sdir[inst]}/PDirect.py $porta_socket $texto_soket >/root/proxy.log &
    #screen -dmS pydic-"$porta_socket" python ${sdir[inst]}/PDirect.py "$porta_socket" "$texto_soket" && echo ""$porta_socket" "$texto_soket"" >> ${sdir[0]}/PortPD.log

    echo "$porta_socket $texto_soket" >${sdir[0]}/PortPD.log
    [[ $(grep -wc "PDirect.py" $prefix/autostart) = '0' ]] && {
        echo -e "netstat -tlpn | grep -w $porta_socket > /dev/null || {  screen -r -S 'ws$porta_socket' -X quit;  screen -dmS ws$porta_socket python ${sdir[inst]}/PDirect.py $porta_socket $texto_soket; }" >>$prefix/autostart
    } || {
        sed -i '/PDirect.py/d' $prefix/autostart
        echo -e "netstat -tlpn | grep -w $porta_socket > /dev/null || {  screen -r -S 'ws$porta_socket' -X quit;  screen -dmS ws$porta_socket python ${sdir[inst]}/PDirect.py $porta_socket $texto_soket; }" >>$prefix/autostart
    }

}

pythontest() {
    clear
    echo ""
    echo ""
    
    msg -bar
    echo -e "\033[1;31m  SOCKS DIRECTO-PY | CUSTOM\033[0m"
    while true; do
        msg -bar
        echo -ne "\033[1;37m"
        read -p " ESCRIBE SU PUERTO: " porta_socket
        echo -e ""
        [[ $(mportas | grep -w "$porta_socket") ]] || break
        echo -e " ESTE PUERTO YA ESTÁ EN USO"
        unset porta_socket
    done
    msg -bar
    echo -e "\033[1;97m Digite Un Puerto Local 22|443|80\033[1;37m"
    msg -bar
    while true; do
        echo -ne "\033[1;36m"
        read -p " Digite Un Puerto SSH/DROPBEAR activo: " PORTLOC
        echo -e ""
        if [[ ! -z $PORTLOC ]]; then
            if [[ $(echo $PORTLOC | grep [0-9]) ]]; then
                [[ $(mportas | grep $PORTLOC | head -1) ]] && break || echo -e "ESTE PUERTO NO EXISTE"
            fi
        fi
    done
    #
    puertoantla="$(mportas | grep $PORTLOC | awk '{print $2}' | head -1)"
    msg -bar
    echo -ne " Escribe El HTTP Response? 101|200|300: \033[1;37m" && read cabezado
    tput cuu1 && tput dl1
    if [[ -z $cabezado ]]; then
        cabezado="200"
        echo -e "	\e[31mResponse Default:\033[1;32m ${cabezado}"
    else
        echo -e "	\e[31mResponse Elegido:\033[1;32m ${cabezado}"
    fi
    msg -bar
    echo -e "$(fun_trans "Introdusca su Mini-Banner")"
    msg -bar
    echo -ne " Introduzca el texto de estado plano o en HTML:\n \033[1;37m" && read texto_soket
    tput cuu1 && tput dl1
    if [[ -z $texto_soket ]]; then
        texto_soket="$ress"
        echo -e "	\e[31mMensage Default: \033[1;32m${texto_soket} "
    else
        echo -e "	\e[31mMensage: \033[1;32m ${texto_soket}"
    fi
    msg -bar

    (
        less <<CPM >${sdir[0]}/protocolos/python.py
import socket, threading, thread, select, signal, sys, time, getopt

# Listen
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = int("$porta_socket")
PASS = ''

# CONST
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:$puertoantla'
RESPONSE = 'HTTP/1.1 $cabezado <strong>$texto_soket</strong>\r\n\r\nHTTP/1.1 $cabezado Conexion Exitosa\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()
    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()
    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()
    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()
class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True
    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            if hostPort == '':
                hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, 'X-Split')
            if split != '':
                self.client.recv(BUFLEN)
            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
				
                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + e.strerror
            self.server.printLog(self.log)
	    pass
        finally:
            self.close()
            self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + ': ')
        if aux == -1:
            return ''
        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')
        if aux == -1:
            return ''
        return head[:aux];
    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method=='CONNECT':
            	
                port = 443
            else:
                port = 80
                port = 8080
                port = 8799
                port = 3128
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path
        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = ''
        self.server.printLog(self.log)
        self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
		    try:
                        data = in_.recv(BUFLEN)
                        if data:
			    if in_ is self.target:
				self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]
                            count = 0
			else:
			    break
		    except:
                        error = True
                        break
            if count == TIMEOUT:
                error = True
            if error:
                break
def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print "\n:-------PythonProxy-------:\n"
    print "Listening addr: " + LISTENING_ADDR
    print "Listening port: " + str(LISTENING_PORT) + "\n"
    print ":-------------------------:\n"
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    while True:
        try:
            time.sleep(2)
        except KeyboardInterrupt:
            print 'Stopping...'
            server.close()
            break
if __name__ == '__main__':
    main()
CPM
    ) >$HOME/proxy.log &

    chmod +x ${sdir[0]}/protocolos/python.py
    echo -e "[Unit]\nDescription=python.py Service \nAfter=network.target\nStartLimitIntervalSec=0\n\n[Service]\nType=simple\nUser=root\nWorkingDirectory=/root\nExecStart=/usr/bin/python ${sdir[inst]}/python.py $porta_socket $texto_soket\nRestart=always\nRestartSec=3s\n[Install]\nWantedBy=multi-user.target" >$prefix/systemd/system/python.PD.service
    echo "$porta_socket $texto_soket" >${sdir[0]}/PortPD.log
    systemctl enable python.PD &>/dev/null
    systemctl start python.PD &>/dev/null

}

pid_kill() {
    [[ -z $1 ]] && refurn 1
    pids="$@"
    for pid in $(echo $pids); do
        kill -9 $pid &>/dev/null
    done
}
selecionador() {
    clear
    echo ""
    echo ""
    echo ""
    while true; do
        msg -bar
        echo -ne "\033[1;37m"
        read -p " ESCRIBE SU PUERTO: " porta_socket
        echo -e ""
        [[ $(mportas | grep -w "$porta_socket") ]] || break
        echo -e " ESTE PUERTO YA ESTÁ EN USO"
        unset porta_socket
    done
    echo -e "Introdusca su Mini-Banner"
    msg -bar
    echo -ne "Introduzca el texto de estado plano o en HTML:\n \033[1;37m" && read texto_soket
    msg -bar
}
remove_fun() {
    echo -e "Parando Socks Python"
    msg -bar
    pidproxy=$(ps x | grep "PPub.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy ]] && pid_kill $pidproxy
    pidproxy2=$(ps x | grep "PPriv.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy2 ]] && pid_kill $pidproxy2
    pidproxy3=$(ps x | grep "PDirect.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy3 ]] && pid_kill $pidproxy3
    pidproxy4=$(ps x | grep "POpen.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy4 ]] && pid_kill $pidproxy4
    pidproxy5=$(ps x | grep "PGet.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy5 ]] && pid_kill $pidproxy5
    pidproxy6=$(ps x | grep "scktcheck" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy6 ]] && pid_kill $pidproxy6
    pidproxy7=$(ps x | grep "python.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy7 ]] && pid_kill $pidproxy7
    pidproxy8=$(ps x | grep "lacasitamx.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy8 ]] && pid_kill $pidproxy8
    echo -e "\033[1;91mSocks DETENIDOS"
    msg -bar
    rm ${sdir[0]}/PortPD.log &>/dev/null
    echo "" >${sdir[0]}/PortPD.log

    for pidproxy in $(screen -ls | grep ".ws" | awk {'print $1'}); do
        screen -r -S "$pidproxy" -X quit
    done
    [[ $(grep -wc "PDirect.py" $prefix/autostart) != '0' ]] && {
        sed -i '/PDirect.py/d' $prefix/autostart
    }
    sleep 1
    screen -wipe >/dev/null &> /dev/null
    systemctl stop python.PD &>/dev/null
    systemctl disable python.PD &>/dev/null
    rm $prefix/systemd/system/python.PD.service &>/dev/null
    iniciarsocks
}

iniciarsocks() {
    pidproxy=$(ps x | grep -w "PPub.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy ]] && P1="\033[1;32m[ON]" || P1="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy2=$(ps x | grep -w "PPriv.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy2 ]] && P2="\033[1;32m[ON]" || P2="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy3=$(ps x | grep -w "PDirect.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy3 ]] && P3="\033[1;32m[ON]" || P3="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy4=$(ps x | grep -w "POpen.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy4 ]] && P4="\033[1;32m[ON]" || P4="\e[37m[\033[1;31mOFF\e[37m]"

    pidproxy5=$(ps x | grep "PGet.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy5 ]] && P5="\033[1;32m[ON]" || P5="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy6=$(ps x | grep "scktcheck" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy6 ]] && P6="\033[1;32m[ON]" || P6="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy7=$(ps x | grep "python.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy7 ]] && P7="\033[1;32m[ON]" || P7="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy8=$(ps x | grep "python.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy8 ]] && P8="\033[1;32m[ON]" || P8="\e[37m[\033[1;31mOFF\e[37m]"
    fun_tit --sockspy
    echo -e "   	\e[91m\e[43mINSTALADOR DE PROXY'S\e[0m "
    msg -bar
    echo -e " \e[1;93m[\e[92m1\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python SIMPLE      $P1"
    echo -e " \e[1;93m[\e[92m2\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python SEGURO      $P2"
    echo -e " \e[1;93m[\e[92m3\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy WEBSOCKET Custom   $P3 \e[1;32m(Screen TEST)"
    echo -e " \e[1;93m[\e[92m4\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy WEBSOCKET Custom   $P7 \e[1;32m(Socks HTTP)"
    echo -e " \e[1;93m[\e[92m5\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python OPENVPN     $P4"
    echo -e " \e[1;93m[\e[92m6\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python GETTUNEL    $P5"
    echo -e " \e[1;93m[\e[92m7\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python TCP BYPASS  $P6"
    echo -e " \e[1;93m[\e[92m8\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mAplicar Fix en \e[1;32m(Ubu22 o Debian11 )"
    echo -e " \e[1;93m[\e[92m9\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mDETENER SERVICIO PYTHON"
    msg -bar
    echo -e " \e[1;93m[\e[92m0\e[93m] \e[97m$(msg -verm2 "➛ ") \e[97m\033[1;41m VOLVER \033[1;37m"
    msg -bar
    IP=(meu_ip)
    while [[ -z $portproxy || $portproxy != @(0|[1-9]) ]]; do
        echo -ne " Digite Una Opcion: \033[1;37m" && read portproxy
        tput cuu1 && tput dl1
    done
    case $portproxy in
    1)
        selecionador
        screen -dmS screen python ${sdir[inst]}/PPub.py "$porta_socket" "$texto_soket"
        ;;
    2)
        selecionador
        screen -dmS screen python3 ${sdir[inst]}/PPriv.py "$porta_socket" "$texto_soket" "$IP"
        ;;
    3)
        PIDI="$(ps aux | grep -v grep | grep "ws")"
        if [[ -z $PIDI ]]; then
            sistema20
            PythonDic_fun
        else
            for pidproxy in $(screen -ls | grep ".ws" | awk {'print $1'}); do
                screen -r -S "$pidproxy" -X quit
            done
            [[ $(grep -wc "PDirect.py" $prefix/autostart) != '0' ]] && {
                sed -i '/PDirect.py/d' $prefix/autostart
            }
            sleep 1
            screen -wipe >/dev/null
            msg -bar
            echo -e "\033[1;91mSocks Directo DETENIDO"
            msg -bar
            exit 0
        fi
        ;;
    4)
        if [[ ! -e $prefix/systemd/system/python.PD.service ]]; then
            sistema20
            pythontest
        else
            systemctl stop python.PD &>/dev/null
            systemctl disable python.PD &>/dev/null
            rm $prefix/systemd/system/python.PD.service &>/dev/null

            msg -bar
            echo -e "\033[1;91mSocks Directo DETENIDO"
            msg -bar
            exit 0
        fi
        ;;
    5)
        selecionador
        screen -dmS screen python ${sdir[inst]}/POpen.py "$porta_socket" "$texto_soket"
        ;;
    6)
        selecionador
        gettunel_fun "$porta_socket"
        ;;
    7)
        selecionador
        tcpbypass_fun "$porta_socket" "$texto_soket"
        ;;
    8)
        sistema22
        msg -bar
        msg -ama " AHORA REGRESA EN LA OPCION 3 DE SOCKS HTTP"
        msg -bar

        ;;
    9) remove_fun ;;
    0) return ;;
    esac
    echo -e "\033[1;92mProcedimiento COMPLETO"
    msg -bar
}
iniciarsocks

}

function _squid(){
fun_squid  () {
  if [[ -e $prefix/squid/squid.conf ]]; then
  var_squid="$prefix/squid/squid.conf"
 		 systemctl stop squid &>/dev/null
            systemctl disable squid &>/dev/null
  elif [[ -e $prefix/squid3/squid.conf ]]; then
  var_squid="$prefix/squid3/squid.conf"
  systemctl stop squid3 &>/dev/null
   systemctl disable squid3 &>/dev/null
  fi
  [[ -e $var_squid ]] && {
  echo -e "\033[1;32m $(fun_trans "REMOVIENDO SQUID")"
  msg -bar
  service squid stop > /dev/null 2>&1
  apt-get remove squid -y &>/dev/null
  apt-get remove squid3 -y &>/dev/null && echo -e " \033[1;33m[\033[1;31m#################################\033[1;33m] - \033[1;32m100%\033[0m"
  msg -bar
  echo -e "\033[1;32m $(fun_trans "Procedimento Concluido")"
  msg -bar
  [[ -e $var_squid ]] && rm $var_squid
  return 0
  }

msg -ama "         INSTALADOR SQUID "
msg -bar
fun_ip
echo -ne " Confirme su ip\033[1;91m"; read -p ": " -e -i $IP ip
msg -bar
echo -e " \033[1;97mAhora elige los puertos que desea en el Squid"
echo -e " \033[1;97mSeleccione puertos en orden secuencial,\n \033[1;92mEjemplo: 80 8080 8799 3128"
msg -bar
echo -ne " Digite losPuertos:\033[1;32m "; read portasx
msg -bar
totalporta=($portasx)
unset PORT
   for((i=0; i<${#totalporta[@]}; i++)); do
        [[ $(mportas|grep "${totalporta[$i]}") = "" ]] && {
        echo -e "\033[1;33m Puerto Escojido:\033[1;32m ${totalporta[$i]} OK"
        PORT+="${totalporta[$i]}\n"
        } || {
        echo -e "\033[1;33m Puerto Escojido:\033[1;31m ${totalporta[$i]} FAIL"
        }
   done
  [[ -z $PORT ]] && {
  echo -e "\033[1;31m No se ha elegido ninguna puerto valido\033[0m"
  return 1
  }

echo -e " INSTALANDO SQUID"
msg -bar
apt-get install squid3 -y &>/dev/null && echo -e " \033[1;33m[\033[1;31m########################################\033[1;33m] - \033[1;32m100%\033[0m" | pv -qL10
apt-get install squid -y
msg -bar
echo -e " $(fun_trans  "INICIANDO CONFIGURACION")"
echo -e ".bookclaro.com.br/\n.claro.com.ar/\n.claro.com.br/\n.claro.com.co/\n.claro.com.ec/\n.claro.com.gt/\n.cloudfront.net/\n.claro.com.ni/\n.claro.com.pe/\n.claro.com.sv/\n.claro.cr/\n.clarocurtas.com.br/\n.claroideas.com/\n.claroideias.com.br/\n.claromusica.com/\n.clarosomdechamada.com.br/\n.clarovideo.com/\n.facebook.net/\n.facebook.com/\n.netclaro.com.br/\n.oi.com.br/\n.oimusica.com.br/\n.speedtest.net/\n.tim.com.br/\n.timanamaria.com.br/\n.vivo.com.br/\n.rdio.com/\n.compute-1.amazonaws.com/\n.portalrecarga.vivo.com.br/\n.vivo.ddivulga.com/" > $prefix/payloads
msg -bar
echo -e "\033[1;32m $(fun_trans  "Ahora Escoja Una Conf Para Su Proxy")"
msg -bar
echo -e "|1| $(fun_trans  "Basico")"
echo -e "|2| $(fun_trans  "Avanzado recomendado")\033[1;37m"
msg -bar
read -p "[1/2]: " -e -i 1 proxy_opt
tput cuu1 && tput dl1
if [[ $proxy_opt = 1 ]]; then
echo -e " $(fun_trans  "          INSTALANDO SQUID BASICO")"
elif [[ $proxy_opt = 2 ]]; then
echo -e " $(fun_trans  "          INSTALANDO SQUID AVANZADO")"
else
echo -e " $(fun_trans  "          INSTALANDO SQUID BASICO")"
proxy_opt=1
fi
unset var_squid
if [[ -d $prefix/squid ]]; then
var_squid="$prefix/squid/squid.conf"
systemctl enable squid &>/dev/null
systemctl start squid &>/dev/null

elif [[ -d $prefix/squid3 ]]; then
var_squid="$prefix/squid3/squid.conf"
systemctl enable squid3 &>/dev/null
systemctl start squid3 &>/dev/null
fi
if [[ "$proxy_opt" = @(02|2) ]]; then
echo -e "#ConfiguracaoSquiD
acl url1 dstdomain -i $IP
acl url2 dstdomain -i 127.0.0.1
acl url3 url_regex -i '$prefix/payloads'
acl url4 url_regex -i '$prefix/opendns'
acl url5 dstdomain -i localhost
acl accept dstdomain -i GET
acl accept dstdomain -i POST
acl accept dstdomain -i OPTIONS
acl accept dstdomain -i CONNECT
acl accept dstdomain -i PUT
acl HEAD dstdomain -i HEAD
acl accept dstdomain -i TRACE
acl accept dstdomain -i OPTIONS
acl accept dstdomain -i PATCH
acl accept dstdomain -i PROPATCH
acl accept dstdomain -i DELETE
acl accept dstdomain -i REQUEST
acl accept dstdomain -i METHOD
acl accept dstdomain -i NETDATA
acl accept dstdomain -i MOVE
acl all src 0.0.0.0/0
http_access allow url1
http_access allow url2
http_access allow url3
http_access allow url4
http_access allow url5
http_access allow accept
http_access allow HEAD
http_access deny all

# Request Headers Forcing

request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
#request_header_access All deny all

# Response Headers Spoofing

#reply_header_access Via deny all
#reply_header_access X-Cache deny all
#reply_header_access X-Cache-Lookup deny all

#portas" > $var_squid
for pts in $(echo -e $PORT); do
echo -e "http_port $pts" >> $var_squid
done
echo -e "
#nome
visible_hostname VPS-MX

via off
forwarded_for off
pipeline_prefetch off" >> $var_squid
 else
echo -e "#Configuracion SquiD
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 8080
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst $ip-$ip/255.255.255.255
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320

#Puertos" > $var_squid
for pts in $(echo -e $PORT); do
echo -e "http_port $pts" >> $var_squid
done
echo -e "
#HostName
visible_hostname VPS-MX

via off
forwarded_for off
pipeline_prefetch off" >> $var_squid
fi
touch $prefix/opendns
fun_eth
msg -bar
echo -ne " \033[1;31m [ ! ] \033[1;33m$(fun_trans  "    REINICIANDO SERVICIOS")"
squid3 -k reconfigure > /dev/null 2>&1
squid -k reconfigure > /dev/null 2>&1
service ssh restart > /dev/null 2>&1
systemctl restart squid &>/dev/null
 systemctl restart squid3 &>/dev/null
service squid3 restart > /dev/null 2>&1
service squid restart > /dev/null 2>&1
systemctl restart unattended-upgrades.service &>/dev/null
echo -e " \033[1;32m[OK]"
msg -bar
echo -e "${cor[3]}$(fun_trans  "            SQUID CONFIGURADO")"
msg -bar
#UFW
for ufww in $(mportas|awk '{print $2}'); do
ufw allow $ufww > /dev/null 2>&1
done
}

SPR &
online_squid () {
payload="$prefix/payloads"
msg -bar
echo -e "\033[1;33m            SQUID CONFIGURADO"
msg -bar
echo -e "${cor[2]} [1] >${cor[3]} Colocar Host en Squid"
echo -e "${cor[2]} [2] >${cor[3]} Remover Host de Squid"
echo -e "${cor[2]} [3] >${cor[3]} Desinstalar Squid"
echo -e "${cor[2]} [0] >${cor[3]} Volver"
msg -bar
while [[ $varpay != @(0|[1-3]) ]]; do
read -p "[0/3]: " varpay
tput cuu1 && tput dl1
done
if [[ "$varpay" = "0" ]]; then
return 1
elif [[ "$varpay" = "1" ]]; then
echo -e "${cor[4]} $(fun_trans  "Hosts Actuales Dentro del Squid")"
msg -bar
cat $payload | awk -F "/" '{print $1,$2,$3,$4}'
msg -bar
while [[ $hos != \.* ]]; do
echo -ne "${cor[4]}$(fun_trans  "Escriba el nuevo host"): " && read hos
tput cuu1 && tput dl1
[[ $hos = \.* ]] && continue
echo -e "${cor[4]}$(fun_trans  "Comience con") .${cor[0]}"
sleep 2s
tput cuu1 && tput dl1
done
host="$hos/"
[[ -z $host ]] && return 1
[[ `grep -c "^$host" $payload` -eq 1 ]] &&:echo -e "${cor[4]}$(fun_trans  "Host ya Exciste")${cor[0]}" && return 1
echo "$host" >> $payload && grep -v "^$" $payload > /tmp/a && mv /tmp/a $payload
echo -e "${cor[4]}$(fun_trans  "Host Agregado con Exito")"
msg -bar
cat $payload | awk -F "/" '{print $1,$2,$3,$4}'
msg -bar
if [[ ! -f "$prefix/init.d/squid" ]]; then
service squid3 reload
systemctl restart squid3
service squid3 restart
else
$prefix/init.d/squid reload
syetemctl restart squid
service squid restart
fi	
return 0
elif [[ "$varpay" = "2" ]]; then
echo -e "${cor[4]} $(fun_trans  "Hosts Actuales Dentro del Squid")"
msg -bar
cat $payload | awk -F "/" '{print $1,$2,$3,$4}'
msg -bar
while [[ $hos != \.* ]]; do
echo -ne "${cor[4]}Digite un Host: " && read hos
tput cuu1 && tput dl1
[[ $hos = \.* ]] && continue
echo -e "${cor[4]}Comience con ."
sleep 2s
tput cuu1 && tput dl1
done
host="$hos/"
[[ -z $host ]] && return 1
[[ `grep -c "^$host" $payload` -ne 1 ]] &&!echo -e "${cor[5]}Host No Encontrado" && return 1
grep -v "^$host" $payload > /tmp/a && mv /tmp/a $payload
echo -e "${cor[4]}Host Removido Con Exito"
msg -bar
cat $payload | awk -F "/" '{print $1,$2,$3,$4}'
msg -bar
if [[ ! -f "$prefix/init.d/squid" ]]; then
service squid3 reload
systemctl restart squid3
service squid3 restart
service squid reload
systemctl restart squid
service squid restart
else
$prefix/init.d/squid reload
systemctl restart squid
service squid restart
$prefix/init.d/squid3 reload
systemctl restart squid3
service squid3 restart
fi	
return 0
elif [[ "$varpay" = "3" ]]; then
fun_squid
fi
}
if [[ -e $prefix/squid/squid.conf ]]; then
online_squid
elif [[ -e $prefix/squid3/squid.conf ]]; then
online_squid
else
fun_squid
fi

}

function _ssl(){
tmp="${sdir[0]}/crt" #&& [[ ! -d ${tmp} ]] && mkdir ${tmp}
tmp_crt="${sdir[0]}/crt/certificados" #&& [[ ! -d ${tmp_crt} ]] && mkdir ${tmp_crt}
#===========cloudflare====
export correo='lacasitamx93@gmail.com'
export _dns='2973fe5da34aa6c4a8ead51cd124973f' #id de zona
export apikey='1829594c1de4cb59a0f795d780cb61332b64a' #api key
export _domain='lacasitamx.host'
export url='https://api.cloudflare.com/client/v4/zones'
# 
#========================

fun_ip &>/dev/null
crear_subdominio(){
clear
clear
apt install jq -y &>/dev/null

	echo -e "       \e[91m\e[43mGENERADOR DE SUB-DOMINIOS\e[0m"
	msg -verd " Verificando direccion ip..."
	sleep 2

	ls_dom=$(curl -s -X GET "$url/$_dns/dns_records?per_page=100" \
     -H "X-Auth-Email: $correo" \
     -H "X-Auth-Key: $apikey" \
     -H "Content-Type: application/json" | jq '.')

    num_line=$(echo $ls_dom | jq '.result | length')
    ls_domi=$(echo $ls_dom | jq -r '.result[].name')
    ls_ip=$(echo $ls_dom | jq -r '.result[].content')
    my_ip=$(wget -qO- ipv4.icanhazip.com)

	if [[ $(echo "$ls_ip"|grep -w "$my_ip") = "$my_ip" ]];then
		for (( i = 0; i < $num_line; i++ )); do
			if [[ $(echo "$ls_dom" | jq -r ".result[$i].content"|grep -w "$my_ip") = "$my_ip" ]]; then
				domain=$(echo "$ls_dom" | jq -r ".result[$i].name")
				echo "$domain" > ${sdir[0]}/tmp/dominio.txt
				break
			fi
		done
		tput cuu1 && tput dl1
		msg -verm2 " ya existe un sub-dominio asociado a esta IP"
		msg -bar
		echo -e " $(msg -ama "sub-dominio:") $(msg -verd "$domain")"
		msg -bar
		exit
    fi

    if [[ -z $name ]]; then
    	tput cuu1 && tput dl1
		echo -e " $(msg -azu "El dominio principal es:") $(msg -verd "$_domain")\n $(msg -azu "El sub-dominio sera:") $(msg -verd "mivps.$_domain")"
		msg -bar
    	while [[ -z "$name" ]]; do
    		msg -ne " Nombre (ejemplo: mivps)  "
    		read name
    		tput cuu1 && tput dl1

    		name=$(echo "$name" | tr -d '[[:space:]]')

    		if [[ -z $name ]]; then
    			msg -verm2 " ingresar un nombre...!"
    			unset name
    			sleep 2
    			tput cuu1 && tput dl1
    			continue
    		elif [[ ! $name =~ $tx_num ]]; then
    			msg -verm2 " ingresa solo letras y numeros...!"
    			unset name
    			sleep 2
    			tput cuu1 && tput dl1
    			continue
    		elif [[ "${#name}" -lt "3" ]]; then
    			msg -verm2 " nombre demaciado corto!"
    			sleep 2
    			tput cuu1 && tput dl1
    			unset name
    			continue
    		else
    			domain="$name.$_domain"
    			msg -ama " Verificando disponibiliad..."
    			sleep 2
    			tput cuu1 && tput dl1
    			if [[ $(echo "$ls_domi" | grep "$domain") = "" ]]; then
    				echo -e " $(msg -verd "[ok]") $(msg -azu "sub-dominio disponible")"
    				sleep 2
    			else
    				echo -e " $(msg -verm2 "[fail]") $(msg -azu "sub-dominio NO disponible")"
    				unset name
    				sleep 2
    				tput cuu1 && tput dl1
    				continue
    			fi
    		fi
    	done
    fi
    tput cuu1 && tput dl1
    echo -e " $(msg -azu " El sub-dominio sera:") $(msg -verd "$domain")"
    msg -bar
    msg -ne " Continuar...[S/N]: "
    read opcion
    [[ $opcion = @(n|N) ]] && return 1
    tput cuu1 && tput dl1
    msg -azu " Creando sub-dominio"
    sleep 1

    var=$(cat <<EOF
{
  "type": "A",
  "name": "$name",
  "content": "$my_ip",
  "ttl": 1,
  "priority": 10,
  "proxied": false
}
EOF
)
    chek_domain=$(curl -s -X POST "$url/$_dns/dns_records" \
    -H "X-Auth-Email: $correo" \
    -H "X-Auth-Key: $apikey" \
    -H "Content-Type: application/json" \
    -d $(echo $var|jq -c '.')|jq '.')

    tput cuu1 && tput dl1
    if [[ "$(echo $chek_domain|jq -r '.success')" = "true" ]]; then
    	echo -e "$(echo $chek_domain|jq -r '.result.name')" > ${sdir[0]}/tmp/dominio.txt
	echo "@drowkid01" >> ${sfile[domains]}
    	msg -verd " Sub-dominio creado con exito!"
    		userid="${sdir[0]}/ID"
			activ=$idusr
 		 TOKEN="6737010670:AAHLCAXetDPYy8Sqv1m_1c0wbJdDDYeEBcs"
			URL="https://api.telegram.org/bot$TOKEN/sendMessage"
			MSG="🔰SUB-DOMINIO CREADO 🔰
╔═════ ▓▓ ࿇ ▓▓ ═════╗
 × ＣａｓｉｔａＭＯＤ ×
 ══════◄••❀••►══════
 IP: $(cat ${sdir[0]}/MEUIPvps)
 ══════◄••❀••►══════
 SUB-DOMINIO: $(cat ${sdir[0]}/tmp/dominio.txt)
 ══════◄••❀••►══════
 SUBDOMINIOS CREADOS POR CASITAMOD [`cat ${sfile[domains]}|wc -l`]
 ══════◄••❀••►══════
 estructura: @kalix1
 mod: @drowkid01, @darnix0
╚═════ ▓▓ ࿇ ▓▓ ═════╝
"
curl -s --max-time 10 -d "chat_id=$activ&disable_web_page_preview=1&text=$MSG" $URL &>/dev/null
curl -s --max-time 10 -d "chat_id=1001710426842&disable_web_page_preview=1&text=$MSG" $URL &>/dev/null

TOKEN="6737010670:AAHLCAXetDPYy8Sqv1m_1c0wbJdDDYeEBcs"
			URL="https://api.telegram.org/bot$TOKEN/sendMessage"
			MSG="🔰SUB-DOMINIO CREADO 🔰
╔═════ ▓▓ ࿇ ▓▓ ═════╗
 × ＣａｓｉｔａＭＯＤ ×
 ══════◄••❀••►══════
 User ID: $iduser
 ══════◄••❀••►══════
 IP: $(wget -qO- ifconfig.me)
 ══════◄••❀••►══════
 SUB-DOMINIO: $(cat ${sdir[0]}/tmp/dominio.txt)
 ══════◄••❀••►══════
 estructura: @kalix1
 mod: @drowkid01, @darnix0
╚═════ ▓▓ ࿇ ▓▓ ═════╝
"
curl -s --max-time 10 -d "chat_id=$idusr&disable_web_page_preview=1&text=$MSG" $URL &>/dev/null

  #  read -p " enter para continuar"
    else
    	echo "" > ${sdir[0]}/tmp/dominio.txt
    	msg -ama " Falla al crear Sub-dominio!"
    fi
 
}
ssl_stunel () {
[[ $(mportas|grep stunnel4|head -1) ]] && {
echo -e "\033[1;33m $(fun_trans  "Deteniendo Stunnel")"
msg -bar
service stunnel4 stop > /dev/null 2>&1
service stunnel stop &>/dev/null
apt-get purge stunnel4 -y &>/dev/null && echo -e "\e[31m DETENIENDO SERVICIO SSL" | pv -qL10
apt-get purge stunnel -y &>/dev/null

if [[ ! -z $(crontab -l|grep -w "onssl.sh") ]]; then
#si existe
crontab -l > /root/cron; sed -i '/onssl.sh/ d' /root/cron; crontab /root/cron; rm /tmp/st/onssl.sh
rm -rf /tmp/st
fi #saltando

msg -bar
echo -e "\033[1;33m $(fun_trans  "Detenido Con Exito!")"
msg -bar
return 0
}
clear
msg -bar
echo -e "\033[1;33m $(fun_trans  "Seleccione una puerta de redirección interna.")"
echo -e "\033[1;33m $(fun_trans  "Un puerto SSH/DROPBEAR/SQUID/OPENVPN/PYTHON")"
msg -bar
         while true; do
         echo -ne "\033[1;37m"
         read -p " Puerto Local: " redir
		 echo ""
         if [[ ! -z $redir ]]; then
             if [[ $(echo $redir|grep [0-9]) ]]; then
                [[ $(mportas|grep $redir|head -1) ]] && break || echo -e "\033[1;31m $(fun_trans  "Puerto Invalido")"
             fi
         fi
         done
msg -bar
DPORT="$(mportas|grep $redir|awk '{print $2}'|head -1)"
echo -e "\033[1;33m $(fun_trans  "Ahora Que Puerto sera SSL")"
msg -bar
    while true; do
	echo -ne "\033[1;37m"
    read -p " Puerto SSL: " SSLPORT
	echo ""
    [[ $(mportas|grep -w "$SSLPORT") ]] || break
    echo -e "\033[1;33m $(fun_trans  "Esta puerta está en uso")"
    unset SSLPORT
    done
msg -bar
echo -e "\033[1;33m $(fun_trans  "Instalando SSL")"
msg -bar
inst(){
apt-get install stunnel -y
apt-get install stunnel4 -y
}
inst &>/dev/null && echo -e "\e[1;92m INICIANDO SSL" | pv -qL10
#echo -e "client = no\n[SSL]\ncert = $prefix/stunnel/stunnel.pem\naccept = ${SSLPORT}\nconnect = 127.0.0.1:${DPORT}" > $prefix/stunnel/stunnel.conf
echo -e "cert = $prefix/stunnel/stunnel.pem\nclient = no\ndelay = yes\nciphers = ALL\nsslVersion = ALL\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n\n[stunnel]\nconnect = 127.0.0.1:${DPORT}\naccept = ${SSLPORT}" > $prefix/stunnel/stunnel.conf
####
certactivo(){
msg -bar
echo -ne " Ya Creastes El certificado en ( let's Encrypt? o en Zero SSL? )\n Si Aun No Lo Instala Por Favor Precione N [S/N]: "; read seg
		[[ $seg = @(n|N) ]] && msg -bar && crearcert
db="$(ls ${tmp_crt})"
  #  opcion="n"
    if [[ ! "$(echo "$db"|grep ".crt")" = "" ]]; then
        cert=$(echo "$db"|grep ".crt")
        key=$(echo "$db"|grep ".key")
        msg -bar
        msg -azu "CERTIFICADO SSL ENCONTRADO"
        msg -bar
        echo -e "$(msg -azu "CERT:") $(msg -ama "$cert")"
        echo -e "$(msg -azu "KEY:")  $(msg -ama "$key")"
        msg -bar
            cp ${tmp_crt}/$cert ${tmp}/stunnel.crt
            cp ${tmp_crt}/$key ${tmp}/stunnel.key
            cat ${tmp}/stunnel.key ${tmp}/stunnel.crt > $prefix/stunnel/stunnel.pem
            
	sed -i 's/ENABLED=0/ENABLED=1/g' $prefix/default/stunnel4
	echo "ENABLED=1" >> $prefix/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
	
	msg -bar
	echo -e "\033[1;33m $(fun_trans  "CERTIFICADO INSTALADO CON EXITO")"
	msg -bar

	rm -rf ${tmp_crt}/stunnel.crt > /dev/null 2>&1
    rm -rf ${tmp_crt}/stunnel.key > /dev/null 2>&1
        fi
    return 0
}
crearcert(){
        openssl genrsa -out ${tmp}/stunnel.key 2048 > /dev/null 2>&1
        (echo "mx" ; echo "mx" ; echo "Speed" ; echo -e "$ress" ; echo -e "$ress" ; echo -e "$ress" ; echo -e "$ress" )|openssl req -new -key ${tmp}/stunnel.key -x509 -days 1000 -out ${tmp}/stunnel.crt > /dev/null 2>&1
        #(echo "mx" ; echo "mx" ; echo "Speed" ; echo "ServerPRO" ; echo "Online" ; echo -e "$ress" ; echo "ServidorVPS" )|openssl req -new -key ${tmp}/stunnel.key -x509 -days 1000 -out ${tmp}/stunnel.crt > /dev/null 2>&1
    cat ${tmp}/stunnel.key ${tmp}/stunnel.crt > $prefix/stunnel/stunnel.pem
######-------
sed -i 's/ENABLED=0/ENABLED=1/g' $prefix/default/stunnel4
	echo "ENABLED=1" >> $prefix/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null

msg -bar
echo -e "\033[1;33m $(fun_trans  "SSL INSTALADO CON EXITO")"
msg -bar

rm -rf /root/stunnel.crt > /dev/null 2>&1
rm -rf /root/stunnel.key > /dev/null 2>&1
return 0
}
clear

echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "CERIFICADO SSL STUNNEL4 ")"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "Certificado Existen de Zero ssl | Let's Encrypt")"
msg -bar
echo -ne "\033[1;37mSelecione Una Opcion: "
read opcao
case $opcao in
1)crearcert ;;
2)certactivo ;;
esac
}
SPR &
ssl_stunel_2 () {
echo -e "\033[1;32m $(fun_trans  "             AGREGAR MAS PUERTOS SSL")"
msg -bar
echo -e "\033[1;33m $(fun_trans  "Seleccione una puerta de redirección interna.")"
echo -e "\033[1;33m $(fun_trans  "Un puerto SSH/DROPBEAR/SQUID/OPENVPN/SSL")"
msg -bar
         while true; do
         echo -ne "\033[1;37m"
         read -p " Puerto-Local: " portx
		 echo ""
         if [[ ! -z $portx ]]; then
             if [[ $(echo $portx|grep [0-9]) ]]; then
                [[ $(mportas|grep $portx|head -1) ]] && break || echo -e "\033[1;31m $(fun_trans  "Puerto Invalido")"
             fi
         fi
         done
msg -bar
DPORT="$(mportas|grep $portx|awk '{print $2}'|head -1)"
echo -e "\033[1;33m $(fun_trans  "Ahora Que Puerto sera SSL")"
msg -bar
    while true; do
	echo -ne "\033[1;37m"
    read -p " Listen-SSL: " SSLPORT
	echo ""
    [[ $(mportas|grep -w "$SSLPORT") ]] || break
    echo -e "\033[1;33m $(fun_trans  "Esta puerta está en uso")"
    unset SSLPORT
    done
msg -bar
echo -e "\033[1;33m $(fun_trans  "Instalando SSL")"
msg -bar
apt-get install stunnel4 -y &>/dev/null && echo -e "\e[1;92m INICIANDO SSL" | pv -qL10
echo -e "client = no\n[stunnel+]\ncert = $prefix/stunnel/stunnel.pem\naccept = ${SSLPORT}\nconnect = 127.0.0.1:${DPORT}" >> $prefix/stunnel/stunnel.conf
######
sed -i 's/ENABLED=0/ENABLED=1/g' $prefix/default/stunnel4
	echo "ENABLED=1" >> $prefix/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
msg -bar
echo -e "${cor[4]}            INSTALADO CON EXITO"
msg -bar

rm -rf /root/stunnel.crt > /dev/null 2>&1
rm -rf /root/stunnel.key > /dev/null 2>&1
return 0
}
sslpython(){
msg -bar
echo -e "\033[1;37mSe Requiere tener el puerto 80 y el 443 libres"
echo -ne " Desea Continuar? [S/N]: "; read seg
[[ $seg = @(n|N) ]] && msg -bar && return
clear
install_python(){ 
 apt-get install python -y &>/dev/null && echo -e "\033[1;97m Activando Python Directo ►80\n" | pv -qL 10
 
 sleep 2
 	echo -e "[Unit]\nDescription=python.py Service \nAfter=network.target\nStartLimitIntervalSec=0\n\n[Service]\nType=simple\nUser=root\nWorkingDirectory=/root\nExecStart=/usr/bin/python ${sdir[inst]}/python.py 80 $ress\nRestart=always\nRestartSec=3s\n[Install]\nWantedBy=multi-user.target" > $prefix/systemd/system/python.PD.service
    systemctl enable python.PD &>/dev/null
    systemctl start python.PD &>/dev/null
    echo -e "80 $ress" >${sdir[0]}/PortPD.log
	echo -e "80 $ress" > ${sdir[0]}/PySSL.log
 msg -bar
 } 
 
 install_ssl(){  
 apt-get install stunnel4 -y &>/dev/null && echo -e "\033[1;97m Activando Servicios SSL ►443\n" | pv -qL 12
 
 apt-get install stunnel4 -y > /dev/null 2>&1 
 #echo -e "client = no\ncert = $prefix/stunnel/stunnel.pem\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n[http]\naccept = 443\nconnect = $IP:80" >$prefix/stunnel/stunnel.conf
 echo -e "cert = $prefix/stunnel/stunnel.pem\nclient = no\ndelay = yes\nciphers = ALL\nsslVersion = ALL\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n\n[http]\nconnect = 127.0.0.1:80\naccept = 443" > $prefix/stunnel/stunnel.conf
openssl genrsa -out stunnel.key 2048 > /dev/null 2>&1 
 (echo mx; echo mx; echo Full; echo speed; echo internet; echo ServerPRO; echo ServerVPS)|openssl req -new -key stunnel.key -x509 -days 1095 -out stunnel.crt > /dev/null 2>&1
 cat stunnel.crt stunnel.key > stunnel.pem   
 mv stunnel.pem $prefix/stunnel/ 
 ######------- 
 sed -i 's/ENABLED=0/ENABLED=1/g' $prefix/default/stunnel4
	echo "ENABLED=1" >> $prefix/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
 rm -rf /root/stunnel.crt > /dev/null 2>&1 
 rm -rf /root/stunnel.key > /dev/null 2>&1 
 } 
install_python 
install_ssl 
msg -bar
echo -e "${cor[4]}               INSTALACION COMPLETA"
msg -bar
}

unistall(){
clear
msg -bar
msg -ama "DETENIENDO SERVICIOS SSL Y PYTHON"
msg -bar
			service stunnel4 stop > /dev/null 2>&1
			apt-get purge stunnel4 -y &>/dev/null
			apt-get purge stunnel -y &>/dev/null
			kill -9 $(ps aux |grep -v grep |grep -w "python.py"|grep dmS|awk '{print $2}') &>/dev/null
			systemctl stop python.PD &>/dev/null
            systemctl disable python.PD &>/dev/null
            rm $prefix/systemd/system/python.PD.service &>/dev/null
            rm ${sdir[0]}/PortPD.log &>/dev/null
           
			rm ${sdir[0]}/PySSL.log &>/dev/null
			#rm -rf $prefix/stunnel/certificado.zip private.key certificate.crt ca_bundle.crt &>/dev/null
clear
msg -bar
msg -verd "LOS SERVICIOS SE HAN DETENIDO"
msg -bar
}

#
certif(){
if [ -f $prefix/stunnel/stunnel.conf ]; then
msg -bar

echo -e "\e[1;37m ACONTINUACION ES TENER LISTO EL LINK DEL CERTIFICADO.zip\n VERIFICADO EN ZEROSSL, DESCARGALO Y SUBELO\n EN TU GITHUB O DROPBOX"
echo -ne " Desea Continuar? [S/N]: "; read seg
[[ $seg = @(n|N) ]] && msg -bar && return
clear
####Cerrificado ssl/tls#####
msg -bar
echo -e "\e[1;33m👇 LINK DEL CERTIFICADO.zip 👇           \n     \e[0m"
echo -ne "\e[1;36m LINK\e[37m: \e[34m"
#extraer certificado.zip
read linkd
wget $linkd -O $prefix/stunnel/certificado.zip
cd $prefix/stunnel/
unzip certificado.zip 
cat private.key certificate.crt ca_bundle.crt > stunnel.pem
#
sed -i 's/ENABLED=0/ENABLED=1/g' $prefix/default/stunnel4
	echo "ENABLED=1" >> $prefix/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
msg -bar
echo -e "${cor[4]} CERTIFICADO INSTALADO CON EXITO \e[0m" 
msg -bar
else
msg -bar
echo -e "${cor[3]} SERVICIO SSL NO ESTÁ INSTALADO \e[0m"
msg -bar
fi
}

certificadom(){
if [ -f $prefix/stunnel/stunnel.conf ]; then
insapa2(){
for pid in $(pgrep python);do
kill $pid
done
for pid in $(pgrep apache2);do
kill $pid
done
service dropbear stop
apt install apache2 -y
echo "Listen 80

<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule> " > $prefix/apache2/ports.conf
service apache2 restart
}
clear
msg -bar
insapa2 &>/dev/null && echo -e " \e[1;33mAGREGANDO RECURSOS " | pv -qL 10
msg -bar
echo -e "\e[1;37m Verificar dominio \e[0m\n\n"
echo -e "\e[1;37m TIENES QUE MODIFICAR EL ARCHIVO DESCARGADO\n EJEMPLO: 530DDCDC3 comodoca.com 7bac5e210\e[0m"
msg -bar
read -p " LLAVE > Nombre Del Archivo: " keyy
msg -bar
read -p " DATOS > De La LLAVE: " dat2w
[[ ! -d /var/www/html/.well-known ]] && mkdir /var/www/html/.well-known
[[ ! -d /var/www/html/.well-known/pki-validation ]] && mkdir /var/www/html/.well-known/pki-validation
datfr1=$(echo "$dat2w"|awk '{print $1}')
datfr2=$(echo "$dat2w"|awk '{print $2}')
datfr3=$(echo "$dat2w"|awk '{print $3}')
echo -ne "${datfr1}\n${datfr2}\n${datfr3}" >/var/www/html/.well-known/pki-validation/$keyy.txt
msg -bar
echo -e "\e[1;37m VERIFIQUE EN LA PÁGINA ZEROSSL \e[0m"
msg -bar
read -p " ENTER PARA CONTINUAR"
clear
msg -bar
echo -e "\e[1;33m👇 LINK DEL CERTIFICADO 👇       \n     \e[0m"
echo -e "\e[1;36m LINK\e[37m: \e[34m"
read link
incertis(){
wget $link -O $prefix/stunnel/certificado.zip
cd $prefix/stunnel/
unzip certificado.zip 
cat private.key certificate.crt ca_bundle.crt > stunnel.pem
#
sed -i 's/ENABLED=0/ENABLED=1/g' $prefix/default/stunnel4
	echo "ENABLED=1" >> $prefix/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
}
incertis &>/dev/null && echo -e " \e[1;33mEXTRAYENDO CERTIFICADO " | pv -qL 10
msg -bar
echo -e "${cor[4]} CERTIFICADO INSTALADO \e[0m" 
msg -bar

for pid in $(pgrep apache2);do
kill $pid
done
apt install apache2 -y &>/dev/null
echo "Listen 81

<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule> " > $prefix/apache2/ports.conf
service apache2 restart &>/dev/null
service dropbear start &>/dev/null
service dropbear restart &>/dev/null
for port in $(cat ${sdir[0]}/PortPD.log| grep -v "nobody" |cut -d' ' -f1)
do
PIDVRF3="$(ps aux|grep pid-"$port" |grep -v grep|awk '{print $2}')"
Portd="$(cat ${sdir[0]}/PortPD.log|grep -v "nobody" |cut -d' ' -f1)"
if [[ -z ${Portd} ]]; then
    systemctl start python.PD &>/dev/null
#screen -dmS pydic-"$port" python ${sdir[0]}/protocolos/python.py "$port"
else
    systemctl start python.PD &>/dev/null
fi
done
else
msg -bar
echo -e "${cor[3]} SSL/TLS NO INSTALADO \e[0m"
msg -bar
fi
}
#
stop_port(){
	msg -bar
	msg -ama " Comprovando puertos..."
	ports=('80' '443')

	for i in ${ports[@]}; do
		if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]]; then
			msg -bar
			echo -ne "$(msg -ama " Liberando puerto: $i")"
			lsof -i:$i | awk '{print $2}' | grep -v "PID" | xargs kill -9
			sleep 1s
			if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]];then
				tput cuu1 && tput dl1
				msg -verm2 "ERROR AL LIBERAR PURTO $i"
				msg -bar
				msg -ama " Puerto $i en uso."
				msg -ama " auto-liberacion fallida"
				msg -ama " detenga el puerto $i manualmente"
				msg -ama " e intentar nuevamente..."
				msg -bar
				
				return 1			
			fi
		fi
	done
 }
 
acme_install(){

    if [[ ! -e $HOME/.acme.sh/acme.sh ]];then
    	msg -bar3
    	msg -ama " INSTALANDO SCRIPT ACME"
    	curl -s "https://get.acme.sh" | sh &>/dev/null
    fi
    if [[ ! -z "${mail}" ]]; then
    msg -bar
    	msg -ama " LOGEANDO EN Zerossl"
    	sleep 1
    	$HOME/.acme.sh/acme.sh --register-account  -m ${mail} --server zerossl
    	$HOME/.acme.sh/acme.sh --set-default-ca --server zerossl
    	
    else
    msg -bar
    msg -ama " APLICANDO SERVIDOR letsencrypt"
    msg -bar
    	sleep 1
    	$HOME/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    	
    fi
    msg -bar
    msg -ama " GENERANDO CERTIFICADO SSL"
    msg -bar
    sleep 1
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
    	"$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath ${tmp_crt}/${domain}.crt --keypath ${tmp_crt}/${domain}.key --ecc --force &>/dev/null
    
    	rm -rf $HOME/.acme.sh/${domain}_ecc
    	msg -bar
    	msg -verd " Certificado SSL se genero con éxito"
    	msg -bar
    	
    else
    	rm -rf "$HOME/.acme.sh/${domain}_ecc"
    	msg -bar
    	msg -verm2 "Error al generar el certificado SSL"
    	msg -bar
    	msg -ama " verifique los posibles error"
    	msg -ama " o intente de nuevo"
    	
    	
    fi
 }
 
 gerar_cert(){
	clear
	case $1 in
		1)
	msg -bar
	msg -ama "Generador De Certificado Let's Encrypt"
	msg -bar;;
		2)
	msg -bar
	msg -ama "Generador De Certificado Zerossl"
	msg -bar;;
	esac
	msg -ama "Requiere ingresar un dominio."
	msg -ama "el mismo solo deve resolver DNS, y apuntar"
	msg -ama "a la direccion ip de este servidor."
	msg -bar
	msg -ama "Temporalmente requiere tener"
	msg -ama "los puertos 80 y 443 libres."
	if [[ $1 = 2 ]]; then
		msg -bar
		msg -ama "Requiere tener una cuenta Zerossl."
	fi
	msg -bar
 	msg -ne " Continuar [S/N]: "
	read opcion
	[[ $opcion != @(s|S|y|Y) ]] && return 1

	if [[ $1 = 2 ]]; then
     while [[ -z $mail ]]; do
     	clear
		msg -bar
		msg -ama "ingresa tu correo usado en Zerossl"
		msg -bar3
		msg -ne " >>> "
		read mail
	 done
	fi

	if [[ -e ${tmp_crt}/dominio.txt ]]; then
		domain=$(cat ${tmp_crt}/dominio.txt)
		[[ $domain = "multi-domain" ]] && unset domain
		if [[ ! -z $domain ]]; then
			clear
			msg -bar
			msg -azu "Dominio asociado a esta ip"
			msg -bar
			echo -e "$(msg -verm2 " >>> ") $(msg -ama "$domain")"
			msg -ne "Continuar, usando este dominio? [S/N]: "
			read opcion
			tput cuu1 && tput dl1
			[[ $opcion != @(S|s|Y|y) ]] && unset domain
		fi
	fi

	while [[ -z $domain ]]; do
		clear
		msg -bar
		msg -ama "ingresa tu dominio"
		msg -bar
		msg -ne " >>> "
		read domain
	done
	msg -bar
	msg -ama " Comprovando direccion IP ..."
	local_ip=$(wget -qO- ipv4.icanhazip.com)
    domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    sleep 1
    [[ -z "${domain_ip}" ]] && domain_ip="ip no encontrada"
    if [[ $(echo "${local_ip}" | tr '.' '+' | bc) -ne $(echo "${domain_ip}" | tr '.' '+' | bc) ]]; then
    	clear
    	msg -bar
    	msg -verm2 "ERROR DE DIRECCION IP"
    	msg -bar
    	msg -ama " La direccion ip de su dominio\n no coincide con la de su servidor."
    	msg -bar
    	echo -e " $(msg -azu "IP dominio:  ")$(msg -verm2 "${domain_ip}")"
    	echo -e " $(msg -azu "IP servidor: ")$(msg -verm2 "${local_ip}")"
    	msg -bar
    	msg -ama " Verifique su dominio, e intente de nuevo."
    	msg -bar
    	
    	
    fi

    
    stop_port
    acme_install
    echo "$domain" > ${tmp_crt}/dominio.txt
    
}
if [[ ! -z $(crontab -l|grep -w "onssl.sh") ]]; then
ons="\e[1;92m[ON]"
else
ons="\e[1;91m[OFF]"
fi
[[ $(ps x | grep stunnel4 | grep -v grep | awk '{print $1}') ]] && stunel4="\e[1;32m[ ON ]" || stunel4="\e[1;31m[ OFF ]"

echo -e "       \e[91m\e[43mINSTALADOR MULTI SSL\e[0m "
msg -bar
echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "INICIAR |DETENER SSL") $stunel4"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "AGREGAR + PUERTOS SSL")"
msg -bar
echo -e "$(msg -verd "[3]")$(msg -verm2 "➛ ")$(msg -azu "SSL+Websocket Auto-Config 80➮443    ")"
echo -e "$(msg -verd "[4]")$(msg -verm2 "➛ ")$(msg -azu "\e[1;31mDETENER SERVICIO SSL+Websocket  ")"
msg -bar
echo -e "$(msg -verd "[5]")$(msg -verm2 "➛ ")$(msg -azu "CREAR SUBDOMINIO") \e[1;92m( Nuevo )"
msg -bar
echo -e "$(msg -verd "[6]")$(msg -verm2 "➛ ")$(msg -azu "CERTIFICADO SSL/TLS")"
echo -e "$(msg -verd "[7]")$(msg -verm2 "➛ ")$(msg -azu "ENCENDER SSL")"
echo -e "$(msg -verd "[8]")$(msg -verm2 "➛ ")$(msg -azu "AUTO-MANTENIMIENTO SSL") $ons"
[[ -e $prefix/stunnel/private.key ]] && echo -e "$(msg -verd "[9]")$(msg -verm2 "➛ ")$(msg -azu "Usar Certificado Zerossl")"
msg -bar
echo -ne "\033[1;37mSelecione Una Opcion: "
read opcao
case $opcao in
1)
msg -bar
ssl_stunel

;;
2)
msg -bar
ssl_stunel_2
sleep 3
exit
;;
3)
sslpython
exit
;;
4) unistall ;;
5)
crear_subdominio
exit
;;
6)
clear
msg -bar
echo -e "	\e[91m\e[43mCERTIFICADO SSL/TLS\e[0m"
msg -bar
echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "CERTIFICADO ZIP DIRECTO")"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "CERTIFICADO MANUAL ZEROSSL")"
echo -e "$(msg -verd "[3]")$(msg -verm2 "➛ ")$(msg -azu "GENERAR CERTIFICADO SSL (Let's Encrypt)")"
echo -e "$(msg -verd "[4]")$(msg -verm2 "➛ ")$(msg -azu "GENERAR CERTIFICADO SSL (Zerossl Directo)")"
msg -bar
echo -ne "\033[1;37mSelecione Una Opcion : "
read opc
case $opc in
1)
certif
exit
;;
2)
certificadom
exit
;;
3)
gerar_cert 1
exit 
;;
4)
gerar_cert 2
exit
;;
esac
;;
7)
clear
msg -bar
msg -ama "	START STUNNEL\n	ESTA OPCION ES SOLO SI LLEGA A DETENER EL PUERTO"
msg -ama
echo -ne " Desea Continuar? [S/N]: "; read seg
[[ $seg = @(n|N) ]] && msg -bar && return
clear
	#systemctl start stunnel4 &>/dev/null
	#systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
msg -bar
msg -verd "	SERVICIOS STUNNEL REINICIADOS"
msg -bar
;;
8)
clear

if [[ ! -z $(crontab -l|grep -w "onssl.sh") ]]; then
    msg -azu " Auto-Inicio SSL programada cada $(msg -verd "[ $(crontab -l|grep -w "onssl.sh"|awk '{print $2}'|sed $'s/[^[:alnum:]\t]//g')HS ]")"
    msg -bar
    while :
    do
    echo -ne "$(msg -azu " Detener Auto-Inicio SSL [S/N]: ")" && read yesno
    tput cuu1 && tput dl1
    case $yesno in
      s|S) crontab -l > /root/cron && sed -i '/onssl.sh/ d' /root/cron && crontab /root/cron && rm /tmp/st/onssl.sh
           msg -azu " Auto-Inicio SSL Detenida!" && msg -bar && sleep 2
           return 1;;
      n|N)return 1;;
      *)return 1 ;;
    esac
    done
  fi 
  clear
  msg -bar
msg -ama "	  \e[1;97m\e[2;100mAUTO-INICIAR SSL \e[0m"
msg -bar 
echo -ne "$(msg -azu "Desea programar El Auto-Inicio SSL [s/n]:") "
  read initio
  if [[ $initio = @(s|S|y|Y) ]]; then
    tput cuu1 && tput dl1
    echo -ne "$(msg -azu " PONGA UN NÚMERO, EJEMPLO [1-12HORAS]:") "
    read initio
    if [[ $initio =~ ^[0-9]+$ ]]; then
      crontab -l > /root/cron
      [[ ! -d /tmp/st ]] && mkdir /tmp/st
	[[ ! -e /tmp/st/onssl.sh ]] && wget -O /tmp/st/onssl.sh https://www.dropbox.com/s/sjbulk4bz6wu2p0/onssl.sh &>/dev/null
	chmod 777 /tmp/st/onssl.sh
      echo "0 */$initio * * * bash /tmp/st/onssl.sh" >> /root/cron
      crontab /root/cron
      
      service cron restart
      rm /root/cron
      tput cuu1 && tput dl1
      msg -azu " Auto-Limpieza programada cada: $(msg -verd "${initio} HORAS")" && msg -bar && sleep 2
    else
      tput cuu1 && tput dl1
      msg -verm2 " ingresar solo numeros entre 1 y 12"
      sleep 2
      msg -bar
    fi
  fi
  return 1
;;
9)
clear
msg -bar
msg -ama "	CERTIFICADOS ALMACENADOS de Zerossl\n	QUIERES USAR EL CERTIFICADO DE ZEROSSL?\n  private.key certificate.crt ca_bundle.crt"
msg -ama
echo -ne " Desea Continuar? [S/N]: "; read seg
[[ $seg = @(n|N) ]] && msg -bar && return
clear
cd $prefix/stunnel/
cat private.key certificate.crt ca_bundle.crt > stunnel.pem
#systemctl start stunnel4 &>/dev/null
	#systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
msg -bar
msg -verd "	CERTIFICADO ZEROSSL AGREGADO\n	SERVICIO SSL INICIADO"
msg -bar
;;
esac

}
function _v2ray(){
clear
err_fun() {
    case $1 in
    1)
        msg -verm "$(fun_trans "Usuario Nulo")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    2)
        msg -verm "$(fun_trans "Nombre muy corto (MIN: 2 CARACTERES)")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    3)
        msg -verm "$(fun_trans "Nombre muy grande (MAX: 5 CARACTERES)")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    4)
        msg -verm "$(fun_trans "Contraseña Nula")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    5)
        msg -verm "$(fun_trans "Contraseña muy corta")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    6)
        msg -verm "$(fun_trans "Contraseña muy grande")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    7)
        msg -verm "$(fun_trans "Duracion Nula")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    8)
        msg -verm "$(fun_trans "Duracion invalida utilize numeros")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    9)
        msg -verm "$(fun_trans "Duracion maxima y de un año")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    11)
        msg -verm "$(fun_trans "Limite Nulo")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    12)
        msg -verm "$(fun_trans "Limite invalido utilize numeros")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    13)
        msg -verm "$(fun_trans "Limite maximo de 999")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    14)
        msg -verm "$(fun_trans "Usuario Ya Existe")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    15)
        msg -verm "$(fun_trans "(Solo numeros) GB = Min: 1gb Max: 1000gb")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    16)
        msg -verm "$(fun_trans "(Solo numeros)")"
        sleep 2s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    17)
        msg -verm "$(fun_trans "(Sin Informacion - Para Cancelar Digite CRTL + C)")"
        sleep 4s
        tput cuu1
        tput dl1
        tput cuu1
        tput dl1
        ;;
    esac
}
intallv2ray() {
    apt install python3-pip -y
    source <(curl -sL https://www.dropbox.com/s/gh8vll0a8nejwr8/install-v2ray.sh)
    msg -ama "$(fun_trans "Intalado con Exito")!"
    USRdatabase="${sdir[0]}/RegV2ray"
    [[ ! -e ${USRdatabase} ]] && touch ${USRdatabase}
    sort ${USRdatabase} | uniq >${USRdatabase}tmp
    mv -f ${USRdatabase}tmp ${USRdatabase}
    msg -bar
    service v2ray restart
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh

}
protocolv2ray() {
    msg -ama "$(fun_trans "Escojer opcion 3 y poner el dominio de nuestra IP")!"
    msg -bar
    v2ray stream
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}
dirapache="/usr/local/lib/ubuntn/apache/ver" && [[ ! -d ${dirapache} ]] && exit
tls() {
    msg -ama "$(fun_trans "Activar o Desactivar TLS")!"
    msg -bar
    v2ray tls
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}
portv() {
    msg -ama "$(fun_trans "Cambiar Puerto v2ray")!"
    msg -bar
    v2ray port
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}
stats() {
    msg -ama "$(fun_trans "Estadisticas de Consumo")!"
    msg -bar
    v2ray stats
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}
unistallv2() {
    source <(curl -sL https://www.dropbox.com/s/gh8vll0a8nejwr8/install-v2ray.sh) --remove >/dev/null 2>&1
    rm -rf ${sdir[0]}/RegV2ray >/dev/null 2>&1
    echo -e "\033[1;92m                  V2RAY REMOVIDO OK "
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}
infocuenta() {
    v2ray info
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}

addusr() {
    msg -ama "             AGREGAR USUARIO | UUID V2RAY"
    msg -bar
    ##DAIS
    valid=$(date '+%C%y-%m-%d' -d " +31 days")
    ##CORREO
    MAILITO=$(cat /dev/urandom | tr -dc '[:alnum:]' | head -c 10)
    ##ADDUSERV2RAY
    UUID=$(cat /proc/sys/kernel/random/uuid)
    sed -i '13i\           \{' $prefix/v2ray/config.json
    sed -i '14i\           \"alterId": 0,' $prefix/v2ray/config.json
    sed -i '15i\           \"id": "'$UUID'",' $prefix/v2ray/config.json
    sed -i '16i\           \"email": "'$MAILITO'@gmail.com"' $prefix/v2ray/config.json
    sed -i '17i\           \},' $prefix/v2ray/config.json
    echo ""
    while true; do
        echo -ne "\e[91m >> Digita un Nombre: \033[1;92m"
        read -p ": " nick
        nick="$(echo $nick | sed -e 's/[^a-z0-9 -]//ig')"
        if [[ -z $nick ]]; then
            err_fun 17 && continue
        elif [[ "${#nick}" -lt "2" ]]; then
            err_fun 2 && continue
        elif [[ "${#nick}" -gt "5" ]]; then
            err_fun 3 && continue
        fi
        break
    done
    echo -e "\e[91m >> Agregado UUID: \e[92m$UUID "
    while true; do
        echo -ne "\e[91m >> Duracion de UUID (Dias):\033[1;92m " && read diasuser
        if [[ -z "$diasuser" ]]; then
            err_fun 17 && continue
        elif [[ "$diasuser" != +([0-9]) ]]; then
            err_fun 8 && continue
        elif [[ "$diasuser" -gt "360" ]]; then
            err_fun 9 && continue
        fi
        break
    done
    #Lim
    #[[ $(cat $prefix/passwd |grep $1: |grep -vi [a-z]$1 |grep -v [0-9]$1 > /dev/null) ]] && return 1
    valid=$(date '+%C%y-%m-%d' -d " +$diasuser days") && datexp=$(date "+%F" -d " + $diasuser days")

    echo -e "\e[91m >> Expira el : \e[92m$datexp "
    ##Registro
    echo "  $UUID | $nick | $valid " >>${sdir[0]}/RegV2ray
    Fecha=$(date +%d-%m-%y-%R)
    cp ${sdir[0]}/RegV2ray ${sdir[0]}/v2ray/RegV2ray-"$Fecha"
    v2ray restart >/dev/null 2>&1
    echo ""
    v2ray info >${sdir[0]}/v2ray/confuuid.log
    lineP=$(sed -n '/'${UUID}'/=' ${sdir[0]}/v2ray/confuuid.log)
    numl1=4
    let suma=$lineP+$numl1
    sed -n ${suma}p ${sdir[0]}/v2ray/confuuid.log
    echo ""
    msg -bar
    echo -e "\e[92m           UUID AGREGEGADO CON EXITO "
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}

delusr() {
    clear
    clear
    invaliduuid() {
        msg -bar
        echo -e "\e[91m                    UUID INVALIDO \n$(msg -bar)"
        msg -ne "Enter Para Continuar" && read enter
        ${sdir[inst]}/v2ray.sh
    }
    msg -bar
    
    msg -ama "             ELIMINAR USUARIO | UUID V2RAY"
    msg -bar
    echo -e "\e[97m               USUARIOS REGISTRADOS"
    echo -e "\e[33m$(cat ${sdir[0]}/RegV2ray | cut -d '|' -f2,1)"
    msg -bar
    echo -ne "\e[91m >> Digita el UUID a eliminar:\n \033[1;92m " && read uuidel
    [[ $(sed -n '/'${uuidel}'/=' $prefix/v2ray/config.json | head -1) ]] || invaliduuid
    lineP=$(sed -n '/'${uuidel}'/=' $prefix/v2ray/config.json)
    linePre=$(sed -n '/'${uuidel}'/=' ${sdir[0]}/RegV2ray)
    sed -i "${linePre}d" ${sdir[0]}/RegV2ray
    numl1=2
    let resta=$lineP-$numl1
    sed -i "${resta}d" $prefix/v2ray/config.json
    sed -i "${resta}d" $prefix/v2ray/config.json
    sed -i "${resta}d" $prefix/v2ray/config.json
    sed -i "${resta}d" $prefix/v2ray/config.json
    sed -i "${resta}d" $prefix/v2ray/config.json
    v2ray restart >/dev/null 2>&1
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}

mosusr_kk() {
    clear
    clear
    msg -bar
    
    msg -ama "         USUARIOS REGISTRADOS | UUID V2RAY"
    msg -bar
    # usersss=$(cat ${sdir[0]}/RegV2ray|cut -d '|' -f1)
    # cat ${sdir[0]}/RegV2ray|cut -d'|' -f3
    VPSsec=$(date +%s)
    local HOST="${sdir[0]}/RegV2ray"
    local HOST2="${sdir[0]}/RegV2ray"
    local RETURN="$(cat $HOST | cut -d'|' -f2)"
    local IDEUUID="$(cat $HOST | cut -d'|' -f1)"
    if [[ -z $RETURN ]]; then
        echo -e "----- NINGUN USER REGISTRADO -----"
        msg -ne "Enter Para Continuar" && read enter
        ${sdir[inst]}/v2ray.sh

    else
        i=1
        echo -e "\e[97m                 UUID                | USER | EXPIRACION \e[93m"
        msg -bar
        while read hostreturn; do
            DateExp="$(cat ${sdir[0]}/RegV2ray | grep -w "$hostreturn" | cut -d'|' -f3)"
            if [[ ! -z $DateExp ]]; then
                DataSec=$(date +%s --date="$DateExp")
                [[ "$VPSsec" -gt "$DataSec" ]] && EXPTIME="\e[91m[EXPIRADO]\e[97m" || EXPTIME="\e[92m[$(($(($DataSec - $VPSsec)) / 86400))]\e[97m Dias"
            else
                EXPTIME="\e[91m[ S/R ]"
            fi
            usris="$(cat ${sdir[0]}/RegV2ray | grep -w "$hostreturn" | cut -d'|' -f2)"
            local contador_secuencial+="\e[93m$hostreturn \e[97m|\e[93m$usris\e[97m|\e[93m $EXPTIME \n"
            if [[ $i -gt 30 ]]; then
                echo -e "$contador_secuencial"
                unset contador_secuencial
                unset i
            fi
            let i++
        done <<<"$IDEUUID"

        [[ ! -z $contador_secuencial ]] && {
            linesss=$(cat ${sdir[0]}/RegV2ray | wc -l)
            echo -e "$contador_secuencial \n Numero de Registrados: $linesss"
        }
    fi
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh
}
lim_port() {
    clear
    clear
    msg -bar
    
    msg -ama "          LIMITAR MB X PORT | UUID V2RAY"
    msg -bar
    ###VER
    estarts() {
        VPSsec=$(date +%s)
        local HOST="${sdir[0]}/v2ray/lisportt.log"
        local HOST2="${sdir[0]}/v2ray/lisportt.log"
        local RETURN="$(cat $HOST | cut -d'|' -f2)"
        local IDEUUID="$(cat $HOST | cut -d'|' -f1)"
        if [[ -z $RETURN ]]; then
            echo -e "----- NINGUN PUERTO REGISTRADO -----"
            msg -ne "Enter Para Continuar" && read enter
            ${sdir[inst]}/v2ray.sh
        else
            i=1
            while read hostreturn; do
                iptables -n -v -L >${sdir[0]}/v2ray/data1.log
                statsss=$(cat ${sdir[0]}/v2ray/data1.log | grep -w "tcp spt:$hostreturn quota:" | cut -d' ' -f3,4,5)
                gblim=$(cat ${sdir[0]}/v2ray/lisportt.log | grep -w "$hostreturn" | cut -d'|' -f2)
                local contador_secuencial+="         \e[97mPUERTO: \e[93m$hostreturn \e[97m|\e[93m$statsss \e[97m|\e[93m $gblim GB  \n"
                if [[ $i -gt 30 ]]; then
                    echo -e "$contador_secuencial"
                    unset contador_secuencial
                    unset i
                fi
                let i++
            done <<<"$IDEUUID"

            [[ ! -z $contador_secuencial ]] && {
                linesss=$(cat ${sdir[0]}/v2ray/lisportt.log | wc -l)
                echo -e "$contador_secuencial \n Puertos Limitados: $linesss"
            }
        fi
        msg -bar
        msg -ne "Enter Para Continuar" && read enter
        ${sdir[inst]}/v2ray.sh
    }
    ###LIM
    liport() {
        while true; do
            echo -ne "\e[91m >> Digite Port a Limitar:\033[1;92m " && read portbg
            if [[ -z "$portbg" ]]; then
                err_fun 17 && continue
            elif [[ "$portbg" != +([0-9]) ]]; then
                err_fun 16 && continue
            elif [[ "$portbg" -gt "1000" ]]; then
                err_fun 16 && continue
            fi
            break
        done
        while true; do
            echo -ne "\e[91m >> Digite Cantidad de GB:\033[1;92m " && read capgb
            if [[ -z "$capgb" ]]; then
                err_fun 17 && continue
            elif [[ "$capgb" != +([0-9]) ]]; then
                err_fun 15 && continue
            elif [[ "$capgb" -gt "1000" ]]; then
                err_fun 15 && continue
            fi
            break
        done
        uml1=1073741824
        gbuser="$capgb"
        let multiplicacion=$uml1*$gbuser
        sudo iptables -I OUTPUT -p tcp --sport $portbg -j DROP
        sudo iptables -I OUTPUT -p tcp --sport $portbg -m quota --quota $multiplicacion -j ACCEPT
        iptables-save >$prefix/iptables/rules.v4
        echo ""
        echo -e " Port Seleccionado: $portbg | Cantidad de GB: $gbuser"
        echo ""
        echo " $portbg | $gbuser | $multiplicacion " >>${sdir[0]}/v2ray/lisportt.log
        msg -bar
        msg -ne "Enter Para Continuar" && read enter
        ${sdir[inst]}/v2ray.sh
    }
    #monitor

    ###RES
    resdata() {
        VPSsec=$(date +%s)
        local HOST="${sdir[0]}/v2ray/lisportt.log"
        local HOST2="${sdir[0]}/v2ray/lisportt.log"
        local RETURN="$(cat $HOST | cut -d'|' -f2)"
        local IDEUUID="$(cat $HOST | cut -d'|' -f1)"
        if [[ -z $RETURN ]]; then
            echo -e "----- NINGUN PUERTO REGISTRADO -----"
            return 0
        else
            i=1
            while read hostreturn; do
                iptables -n -v -L >${sdir[0]}/v2ray/data1.log
                statsss=$(cat ${sdir[0]}/v2ray/data1.log | grep -w "tcp spt:$hostreturn quota:" | cut -d' ' -f3,4,5)
                gblim=$(cat ${sdir[0]}/v2ray/lisportt.log | grep -w "$hostreturn" | cut -d'|' -f2)
                local contador_secuencial+="         \e[97mPUERTO: \e[93m$hostreturn \e[97m|\e[93m$statsss \e[97m|\e[93m $gblim GB  \n"

                if [[ $i -gt 30 ]]; then
                    echo -e "$contador_secuencial"
                    unset contador_secuencial
                    unset i
                fi
                let i++
            done <<<"$IDEUUID"

            [[ ! -z $contador_secuencial ]] && {
                linesss=$(cat ${sdir[0]}/v2ray/lisportt.log | wc -l)
                echo -e "$contador_secuencial \n Puertos Limitados: $linesss"
            }
        fi
        msg -bar

        while true; do
            echo -ne "\e[91m >> Digite Puerto a Limpiar:\033[1;92m " && read portbg
            if [[ -z "$portbg" ]]; then
                err_fun 17 && continue
            elif [[ "$portbg" != +([0-9]) ]]; then
                err_fun 16 && continue
            elif [[ "$portbg" -gt "1000" ]]; then
                err_fun 16 && continue
            fi
            break
        done
        invaliduuid() {
            msg -bar
            echo -e "\e[91m                PUERTO INVALIDO \n$(msg -bar)"
            msg -ne "Enter Para Continuar" && read enter
            ${sdir[inst]}/v2ray.sh
        }
        [[ $(sed -n '/'${portbg}'/=' ${sdir[0]}/v2ray/lisportt.log | head -1) ]] || invaliduuid
        gblim=$(cat ${sdir[0]}/v2ray/lisportt.log | grep -w "$portbg" | cut -d'|' -f3)
        sudo iptables -D OUTPUT -p tcp --sport $portbg -j DROP
        sudo iptables -D OUTPUT -p tcp --sport $portbg -m quota --quota $gblim -j ACCEPT
        iptables-save >$prefix/iptables/rules.v4
        lineP=$(sed -n '/'${portbg}'/=' ${sdir[0]}/v2ray/lisportt.log)
        sed -i "${linePre}d" ${sdir[0]}/v2ray/lisportt.log
        msg -bar
        msg -ne "Enter Para Continuar" && read enter
        ${sdir[inst]}/v2ray.sh
    }
    ## MENU
    echo -ne "\033[1;32m [1] > " && msg -azu "$(fun_trans "LIMITAR DATA x PORT") "
    echo -ne "\033[1;32m [2] > " && msg -azu "$(fun_trans "RESETEAR DATA DE PORT") "
    echo -ne "\033[1;32m [3] > " && msg -azu "$(fun_trans "VER DATOS CONSUMIDOS") "
    echo -ne "$(msg -bar)\n\033[1;32m [0] > " && msg -bra "\e[97m\033[1;41m VOLVER \033[1;37m"
    msg -bar
    selection=$(selection_fun 3)
    case ${selection} in
    1) liport ;;
    2) resdata ;;
    3) estarts ;;
    0)
        ${sdir[inst]}/v2ray.sh
        ;;
    esac
}

limpiador_activador() {
    unset PIDGEN
    PIDGEN=$(ps aux | grep -v grep | grep "limv2ray")
    if [[ ! $PIDGEN ]]; then
        wget -O /usr/bin/limv2ray https://www.dropbox.com/s/goty5g155vcp02r/limv2ray &>/dev/null
        chmod 777 /usr/bin/limv2ray
        screen -dmS limv2ray watch -n 21600 limv2ray
    else
        #killall screen
        screen -S limv2ray -p 0 -X quit
    fi
    unset PID_GEN
    PID_GEN=$(ps x | grep -v grep | grep "limv2ray")
    [[ ! $PID_GEN ]] && PID_GEN="\e[91m [ DESACTIVADO ] " || PID_GEN="\e[92m [ ACTIVADO ] "
    statgen="$(echo $PID_GEN)"
    clear
    clear
    msg -bar
    
    msg -ama "          ELIMINAR EXPIRADOS | UUID V2RAY"
    msg -bar
    echo ""
    echo -e "                    $statgen "
    echo ""
    msg -bar
    msg -ne "Enter Para Continuar" && read enter
    ${sdir[inst]}/v2ray.sh

}

pidr_inst() {
    proto="v2ray"
    portas=$(lsof -V -i -P -n | grep -v "ESTABLISHED" | grep -v "COMMAND")
    for list in $proto; do
        case $list in
        v2ray)
            portas2=$(echo $portas | grep -w "LISTEN" | grep -w "$list")
            [[ $(echo "${portas2}" | grep "$list") ]] && inst[$list]="\033[1;32m[ACTIVO] " || inst[$list]="\033[1;31m[DESACTIVADO]"
            ;;
        esac
    done
}
PID_GEN=$(ps x | grep -v grep | grep "limv2ray")
[[ ! $PID_GEN ]] && PID_GEN="\e[91m [ OFF ] " || PID_GEN="\e[92m [ ON ] "
statgen="$(echo $PID_GEN)"
SPR &
on="\e[1;32m[ACTIVO]" && off="\e[1;31m[DESACTIVADO]"

declare -A inst
pidr_inst

msg -bar
#msg -bar

msg -bar
echo -e "        \e[91m\e[43mINSTALADOR DE V2RAY\e[0m"
msg -bar
## INSTALADOR
echo -e "$(msg -verd "  [1]")$(msg -verm2 " ➛ ")$(msg -azu " INSTALAR V2RAY ") ${inst[v2ray]}"
echo -e "$(msg -verd "  [2]")$(msg -verm2 " ➛ ")$(msg -azu " CAMBIAR PROTOCOLO ") "
echo -e "$(msg -verd "  [3]")$(msg -verm2 " ➛ ")$(msg -azu " ACTIVAR TLS ") "
echo -e "$(msg -verd "  [4]")$(msg -verm2 " ➛ ")$(msg -azu " CAMBIAR PUERTO V2RAY ")"
msg -bar
## CONTROLER
echo -e "$(msg -verd "  [5]")$(msg -verm2 " ➛ ")$(msg -azu " AGREGAR USUARIO UUID ")"
echo -e "$(msg -verd "  [6]")$(msg -verm2 " ➛ ")$(msg -azu " ELIMINAR USUARIO UUID ")"
echo -e "$(msg -verd "  [7]")$(msg -verm2 " ➛ ")$(msg -azu " MOSTRAR USUARIOS REGISTRADOS ")"
#echo -e "$(msg -verd "  [8]")$(msg -verm2 " ➛")$(msg -ama "  \e[33mMOSTRAR USUARIOS CONECTADOS ")"
echo -e "$(msg -verd "  [8]")$(msg -verm2 " ➛ ")$(msg -azu " INFORMACION DE CUENTAS ")"
echo -e "$(msg -verd "  [9]")$(msg -verm2 " ➛ ")$(msg -azu " ESTADISTICAS DE CONSUMO ")"
echo -e "$(msg -verd "  [10]")$(msg -verm2 "➛ ")$(msg -azu " LIMITADOR POR CONSUMO ")\e[91m ( BETA x PORT )"
echo -e "$(msg -verd "  [11]")$(msg -verm2 "➛ ")$(msg -azu " LIMPIADOR DE EXPIRADOS ------- $statgen ")"
msg -bar
## DESISNTALAR
echo -e "$(msg -verd "  [12]")$(msg -verm2 "➛ ")$(msg -azu "\033[1;31mDESINSTALAR V2RAY ")"
echo -e "$(msg -verd "  [0]") $(msg -verm2 "➛ ")$(msg -azu " \e[97m\033[1;41m VOLVER \033[1;37m ")"
msg -bar
#echo -e "         \e[97mEstado actual: $(pid_inst v2ray)"
#msg -bar
selection=$(selection_fun 18)
case ${selection} in
1) intallv2ray ;;
2) protocolv2ray ;;
3) tls ;;
4) portv ;;
5) addusr ;;
6) delusr ;;
7) mosusr_kk ;;
#8)monitor;;
8) infocuenta ;;
9) stats ;;
10) lim_port ;;
11) limpiador_activador ;;
12) unistallv2 ;;
0) exit ;;
esac

}
function _wireguard(){

#!/bin/bash
dir="${sdir[0]}"
mportas() {
    unset portas
    portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN")
    while read port; do
        var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ "$(echo -e $portas | grep "$var1 $var2")" ]] || portas+="$var1 $var2\n"
    done <<<"$portas_var"
    i=1
    echo -e "$portas"
}

fun_ip() {
    MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
    MIP2=$(wget -qO- ifconfig.me)
    [[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
}

[[ ! -d ${sdir[0]}/wireguard ]] && mkdir ${sdir[0]}/wireguard
# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
    echo 'Este instalador debe ejecutarse con "bash", no con "sh".'
    exit
fi

# Discard stdin. Needed when running from an one-liner which includes a newline
read -N 999999 -t 0.001

# Detect OpenVZ 6
if [[ $(uname -r | cut -d "." -f 1) -eq 2 ]]; then
    echo "El sistema está ejecutando un kernel antiguo, que es incompatible con este instalador"
    exit
fi

# Detect OS
# $os_version variables aren't always in use, but are kept here for convenience
if grep -qs "ubuntu" $prefix/os-release; then
    os="ubuntu"
    os_version=$(grep 'VERSION_ID' $prefix/os-release | cut -d '"' -f 2 | tr -d '.')
elif [[ -e $prefix/debian_version ]]; then
    os="debian"
    os_version=$(grep -oE '[0-9]+' $prefix/debian_version | head -1)
elif [[ -e $prefix/centos-release ]]; then
    os="centos"
    os_version=$(grep -oE '[0-9]+' $prefix/centos-release | head -1)
elif [[ -e $prefix/fedora-release ]]; then
    os="fedora"
    os_version=$(grep -oE '[0-9]+' $prefix/fedora-release | head -1)
else
    echo "Este instalador parece estar ejecutándose en una distribución no compatible. Las distribuciones compatibles son Ubuntu, Debian, CentOS y Fedora"
    exit
fi

if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
    echo "Se requiere Ubuntu 18.04 o superior para usar este instalador. Esta versión de Ubuntu es demasiado antigua y no es compatible"
    exit
fi

if [[ "$os" == "debian" && "$os_version" -lt 9 ]]; then
    echo "Se requiere Debian 9+ o superior para usar este instalador. Esta versión de Debian es demasiado antigua y no tiene soporte"
    exit
fi

if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
    echo "CentOS 7 or higher is required to use this installer. This version of CentOS is too old and unsupported."
    exit
fi

# Detect environments where $PATH does not include the sbin directories
if ! grep -q sbin <<<"$PATH"; then
    echo '$PATH no incluye sen. Intenta usar "su -" en lugar de "su".'
    exit
fi

systemd-detect-virt -cq
is_container="$?"

if [[ "$os" == "fedora" && "$os_version" -eq 31 && $(uname -r | cut -d "." -f 2) -lt 6 && ! "$is_container" -eq 0 ]]; then
    echo 'Fedora 31 is supported, but the kernel is outdated. Upgrade the kernel using "dnf upgrade kernel" and restart.'
    exit
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "Este instalador debe ejecutarse con privilegios de superusuario"
    exit
fi

if [[ "$is_container" -eq 0 ]]; then
    if [ "$(uname -m)" != "x86_64" ]; then
        echo "En sistemas en contenedores, este instalador solo admite la arquitectura x86_64. El sistema se ejecuta en $(uname -m) y no es compatible"
        exit
    fi
    # TUN device is required to use BoringTun if running inside a container
    if [[ ! -e /dev/net/tun ]] || ! (exec 7<>/dev/net/tun) 2>/dev/null; then
        echo "El sistema no tiene disponible el dispositivo TUN. TUN debe estar habilitado antes de ejecutar este instalador"
        exit
    fi
fi

function setup_environment() {
    ### define colors ###
    lightred=$'\033[1;31m'    # light red
    red=$'\033[0;31m'         # red
    lightgreen=$'\033[1;32m'  # light green
    green=$'\033[0;32m'       # green
    lightblue=$'\033[1;34m'   # light blue
    blue=$'\033[0;34m'        # blue
    lightpurple=$'\033[1;35m' # light purple
    purple=$'\033[0;35m'      # purple
    lightcyan=$'\033[1;36m'   # light cyan
    cyan=$'\033[0;36m'        # cyan
    lightgray=$'\033[0;37m'   # light gray
    white=$'\033[1;37m'       # white
    brown=$'\033[0;33m'       # brown
    yellow=$'\033[1;33m'      # yellow
    darkgray=$'\033[1;30m'    # dark gray
    black=$'\033[0;30m'       # black
    nocolor=$'\e[0m'          # no color

    echo -e -n "${lightred}"
    echo -e -n "${red}"
    echo -e -n "${lightgreen}"
    echo -e -n "${green}"
    echo -e -n "${lightblue}"
    echo -e -n "${blue}"
    echo -e -n "${lightpurple}"
    echo -e -n "${purple}"
    echo -e -n "${lightcyan}"
    echo -e -n "${cyan}"
    echo -e -n "${lightgray}"
    echo -e -n "${white}"
    echo -e -n "${brown}"
    echo -e -n "${yellow}"
    echo -e -n "${darkgray}"
    echo -e -n "${black}"
    echo -e -n "${nocolor}"
    clear

    # Set Vars
    LOGFILE='/var/log/wireguardSH.log'
}

new_client_dns() {
    echo -e -n "${lightgreen}"
    echo "Seleccione un servidor DNS para el cliente"
    echo "   1) DNS DEFAULT del sistema actual"
    echo "   2) Google"
    echo "   3) 1.1.1.1"
    echo "   4) OpenDNS"
    echo "   5) Quad9"
    echo "   6) AdGuard"
    echo -e -n "${nocolor}"
    read -p "DNS server [1]: " dns
    until [[ -z "$dns" || "$dns" =~ ^[1-6]$ ]]; do
        echo -e -n "${red}"
        echo "$dns: invalid selection."
        echo -e -n "${green}"
        read -p "DNS server [1]: " dns
    done
    # DNS
    case "$dns" in
    1 | "")
        # Locate the proper resolv.conf
        # Needed for systems running systemd-resolved
        if grep -q '^nameserver 127.0.0.53' "$prefix/resolv.conf"; then
            resolv_conf="/run/systemd/resolve/resolv.conf"
        else
            resolv_conf="$prefix/resolv.conf"
        fi
        # Extract nameservers and provide them in the required format
        dns=$(grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | xargs | sed -e 's/ /, /g')
        ;;
    2)
        dns="8.8.8.8, 8.8.4.4"
        ;;
    3)
        dns="1.1.1.1, 1.0.0.1"
        ;;
    4)
        dns="208.67.222.222, 208.67.220.220"
        ;;
    5)
        dns="9.9.9.9, 149.112.112.112"
        ;;
    6)
        dns="94.140.14.14, 94.140.15.15"
        ;;
    esac
}

new_client_setup() {
    # Given a list of the assigned internal IPv4 addresses, obtain the lowest still
    # available octet. Important to start looking at 2, because 1 is our gateway.
    octet=2
    while grep AllowedIPs $prefix/wireguard/wg0.conf | cut -d "." -f 4 | cut -d "/" -f 1 | grep -q "$octet"; do
        ((octet++))
    done
    # Don't break the WireGuard configuration in case the address space is full
    if [[ "$octet" -eq 255 ]]; then
        echo "253 clients are already configured. The WireGuard internal subnet is full!"
        exit
    fi
    key=$(wg genkey)
    psk=$(wg genpsk)
    # Configure client in the server
    cat <<EOF >>$prefix/wireguard/wg0.conf
# BEGIN_PEER $client
[Peer]
PublicKey = $(wg pubkey <<<$key)
PresharedKey = $psk
AllowedIPs = 10.7.0.$octet/32$(grep -q 'fddd:2c4:2c4:2c4::1' $prefix/wireguard/wg0.conf && echo ", fddd:2c4:2c4:2c4::$octet/128")
# END_PEER $client
EOF
    # Create client configuration
    cat <<EOF >${sdir[0]}/wireguard/"$client".conf
[Interface]
Address = 10.7.0.$octet/24$(grep -q 'fddd:2c4:2c4:2c4::1' $prefix/wireguard/wg0.conf && echo ", fddd:2c4:2c4:2c4::$octet/64")
DNS = $dns
PrivateKey = $key

[Peer]
PublicKey = $(grep PrivateKey $prefix/wireguard/wg0.conf | cut -d " " -f 3 | wg pubkey)
PresharedKey = $psk
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $(grep '^# ENDPOINT' $prefix/wireguard/wg0.conf | cut -d " " -f 3):$(grep ListenPort $prefix/wireguard/wg0.conf | cut -d " " -f 3)
PersistentKeepalive = 25
EOF
}

setup_environment

install() {
    echo -e -n "${green}"
    # If system has a single IPv4, it is selected automatically. Else, ask the user
    if [[ $(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}') -eq 1 ]]; then
        ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
    else
        number_of_ip=$(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}')
        echo
        echo -e -n "${lightgreen}"
        echo "¿Qué dirección IPv4 se debe usar?"
        ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | nl -s ') '
        read -p "IPv4 address [1]: " ip_number
        until [[ -z "$ip_number" || "$ip_number" =~ ^[0-9]+$ && "$ip_number" -le "$number_of_ip" ]]; do
            echo -e -n "${red}"
            echo "$ip_number: invalid selection."
            read -p "IPv4 address [1]: " ip_number
            echo -e -n "${green}"
        done
        [[ -z "$ip_number" ]] && ip_number="1"
        ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n "$ip_number"p)
    fi
    # If $ip is a private IP address, the server must be behind NAT
    if echo "$ip" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
        echo
        echo -e -n "${lightgreen}"
        echo "Este servidor está detrás de NAT. ¿Cuál es la dirección IPv4 pública o el nombre de host?"
        # Get public IP and sanitize with grep
        get_public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<<"$(wget -T 10 -t 1 -4qO- "http://ip1.dynupdate.no-ip.com/" || curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
        read -p "Public IPv4 address / hostname [$get_public_ip]: " public_ip
        # If the checkip service is unavailable and user didn't provide input, ask again
        until [[ -n "$get_public_ip" || -n "$public_ip" ]]; do
            echo -e -n "${red}"
            echo "Invalid input."
            read -p "Public IPv4 address / hostname: " public_ip
            echo -e -n "${green}"
        done
        [[ -z "$public_ip" ]] && public_ip="$get_public_ip"
    fi
    # If system has a single IPv6, it is selected automatically
    if [[ $(ip -6 addr | grep -c 'inet6 [23]') -eq 1 ]]; then
        ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}')
    fi
    # If system has multiple IPv6, ask the user to select one
    if [[ $(ip -6 addr | grep -c 'inet6 [23]') -gt 1 ]]; then
        number_of_ip6=$(ip -6 addr | grep -c 'inet6 [23]')
        echo
        echo -e -n "${lightgreen}"
        echo "Which IPv6 address should be used?"
        ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | nl -s ') '
        read -p "IPv6 address [1]: " ip6_number
        until [[ -z "$ip6_number" || "$ip6_number" =~ ^[0-9]+$ && "$ip6_number" -le "$number_of_ip6" ]]; do
            echo -e -n "${red}"
            echo "$ip6_number: invalid selection."
            read -p "IPv6 address [1]: " ip6_number
            echo -e -n "${green}"
        done
        [[ -z "$ip6_number" ]] && ip6_number="1"
        ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | sed -n "$ip6_number"p)
    fi
    echo
    echo -e -n "${lightgreen}"
    echo " INGRESE UN PUERTO PARA WireGuard"
    #echo -e -n "${nocolor}"
    #read -p "Puerto [51820]: " port
    #until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
    #   echo -e -n "${red}"
    #echo "$port: invalid port."
    #read -p "Puerto [51820]: " port
    #echo -e -n "${green}"
    #done
    while true; do
        echo -ne "\033[1;37m"
        read -p " Puerto [51820]: " port
        echo ""
        [[ $(mportas | grep -w "$port") ]] || break
        echo -e "\033[1;33m Esta puerta está en uso"
        unset port
    done
    [[ -z "$port" ]] && port="51820"
    echo
    echo -e -n "${lightgreen}"
    echo "Introduzca un nombre para el primer cliente: "
    echo -e -n "${nocolor}"
    read -p "Nombre [cliente]: " unsanitized_client
    # Allow a limited set of characters to avoid conflicts
    client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<<"$unsanitized_client")
    [[ -z "$client" ]] && client="client"
    echo
    new_client_dns
    # Set up automatic updates for BoringTun if the user is fine with that
    if [[ "$is_container" -eq 0 ]]; then
        echo
        echo -e -n "${lightgreen}"
        echo "Se instalará BoringTun para configurar WireGuard en el sistema"
        read -p "¿Deberían habilitarse las actualizaciones automáticas para ello? [Y/n]: " boringtun_updates
        until [[ "$boringtun_updates" =~ ^[yYnN]*$ ]]; do
            echo "$remove: invalid selection."
            read -p "Should automatic updates be enabled for it? [Y/n]: " boringtun_updates
        done
        if [[ "$boringtun_updates" =~ ^[yY]*$ ]]; then
            if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
                cron="cronie"
            elif [[ "$os" == "debian" || "$os" == "ubuntu" ]]; then
                cron="cron"
            fi
        fi
        echo -e -n "${nocolor}"
    fi
    echo
    echo -e -n "${lightgreen}"
    echo "La instalación de WireGuard está lista para comenzar"
    echo -e -n "${nocolor}"
    # Install a firewall in the rare case where one is not already available
    if ! systemctl is-active --quiet firewalld.service && ! hash iptables 2>/dev/null; then
        if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
            firewall="firewalld"
            # We don't want to silently enable firewalld, so we give a subtle warning
            # If the user continues, firewalld will be installed and enabled during setup
            echo "También se instalará firewalld, que es necesario para administrar las tablas de enrutamiento"
        elif [[ "$os" == "debian" || "$os" == "ubuntu" ]]; then
            # iptables is way less invasive than firewalld so no warning is given
            firewall="iptables"
        fi
    fi
    echo -e -n "${lightgreen}"
    read -n1 -r -p "Presione enter para continuar..."
    echo -e -n "${nocolor}"
    # Install WireGuard
    # If not running inside a container, set up the WireGuard kernel module
    if [[ ! "$is_container" -eq 0 ]]; then
        if [[ "$os" == "ubuntu" ]]; then
            # Ubuntu
            apt-get update
            apt-get install -y wireguard qrencode $firewall
        elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
            # Debian 10
            if ! grep -qs '^deb .* buster-backports main' $prefix/apt/sources.list $prefix/apt/sources.list.d/*.list; then
                echo "deb http://deb.debian.org/debian buster-backports main" >>$prefix/apt/sources.list
            fi
            apt-get update
            # Try to install kernel headers for the running kernel and avoid a reboot. This
            # can fail, so it's important to run separately from the other apt-get command.
            apt-get install -y linux-headers-"$(uname -r)"
            # There are cleaner ways to find out the $architecture, but we require an
            # specific format for the package name and this approach provides what we need.
            architecture=$(dpkg --get-selections 'linux-image-*-*' | cut -f 1 | grep -oE '[^-]*$' -m 1)
            # linux-headers-$architecture points to the latest headers. We install it
            # because if the system has an outdated kernel, there is no guarantee that old
            # headers were still downloadable and to provide suitable headers for future
            # kernel updates.
            apt-get install -y linux-headers-"$architecture"
            apt-get install -y wireguard qrencode $firewall
        elif [[ "$os" == "debian" && "$os_version" -eq 9 ]]; then
            # Debian 10
            if ! grep -qs '^deb .* stretch-backports main' $prefix/apt/sources.list $prefix/apt/sources.list.d/*.list; then
                echo "deb http://deb.debian.org/debian stretch-backports main" >>$prefix/apt/sources.list
            fi
            apt-get update
            # Try to install kernel headers for the running kernel and avoid a reboot. This
            # can fail, so it's important to run separately from the other apt-get command.
            apt-get install -y linux-headers-"$(uname -r)"
            # There are cleaner ways to find out the $architecture, but we require an
            # specific format for the package name and this approach provides what we need.
            architecture=$(dpkg --get-selections 'linux-image-*-*' | cut -f 1 | grep -oE '[^-]*$' -m 1)
            # linux-headers-$architecture points to the latest headers. We install it
            # because if the system has an outdated kernel, there is no guarantee that old
            # headers were still downloadable and to provide suitable headers for future
            # kernel updates.
            apt-get install -y linux-headers-"$architecture"
            apt-get install -y wireguard qrencode $firewall
        elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
            # CentOS 8
            dnf install -y epel-release elrepo-release
            dnf install -y kmod-wireguard wireguard-tools qrencode $firewall
            mkdir -p $prefix/wireguard/
        elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
            # CentOS 7
            yum install -y epel-release https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
            yum install -y yum-plugin-elrepo
            yum install -y kmod-wireguard wireguard-tools qrencode $firewall
            mkdir -p $prefix/wireguard/
        elif [[ "$os" == "fedora" ]]; then
            # Fedora
            dnf install -y wireguard-tools qrencode $firewall
            mkdir -p $prefix/wireguard/
        fi
    # Else, we are inside a container and BoringTun needs to be used
    else
        # Install required packages
        if [[ "$os" == "ubuntu" ]]; then
            # Ubuntu
            apt-get update
            apt-get install -y qrencode ca-certificates $cron $firewall
            apt-get install -y wireguard-tools --no-install-recommends
        elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
            # Debian 10
            if ! grep -qs '^deb .* buster-backports main' $prefix/apt/sources.list $prefix/apt/sources.list.d/*.list; then
                echo "deb http://deb.debian.org/debian buster-backports main" >>$prefix/apt/sources.list
            fi

            apt-get update
            apt-get install -y qrencode ca-certificates $cron $firewall
            apt-get install -y wireguard-tools --no-install-recommends
        elif [[ "$os" == "debian" && "$os_version" -eq 9 ]]; then
            # Debian 10
            if ! grep -qs '^deb .* stretch-backports main' $prefix/apt/sources.list $prefix/apt/sources.list.d/*.list; then
                echo "deb http://deb.debian.org/debian stretch-backports main" >>$prefix/apt/sources.list
            fi
            apt-get update
            apt-get install -y qrencode ca-certificates $cron $firewall
            apt-get install -y wireguard-tools --no-install-recommends
        elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
            # CentOS 8
            dnf install -y epel-release
            dnf install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
            mkdir -p $prefix/wireguard/
        elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
            # CentOS 7
            yum install -y epel-release
            yum install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
            mkdir -p $prefix/wireguard/
        elif [[ "$os" == "fedora" ]]; then
            # Fedora
            dnf install -y wireguard-tools qrencode ca-certificates tar $cron $firewall
            mkdir -p $prefix/wireguard/
            [[ ! -d ${sdir[0]}/wireguard ]] && mkdir ${sdir[0]}/wireguard
        fi
        # Grab the BoringTun binary using wget or curl and extract into the right place.
        # Don't use this service elsewhere without permission! Contact me before you do!
        { wget -qO- https://wg.nyr.be/1/latest/download 2>/dev/null || curl -sL https://wg.nyr.be/1/latest/download; } | tar xz -C /usr/local/sbin/ --wildcards 'boringtun-*/boringtun' --strip-components 1
        # Configure wg-quick to use BoringTun
        mkdir $prefix/systemd/system/wg-quick@wg0.service.d/ 2>/dev/null
        echo "[Service]
Environment=WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun
Environment=WG_SUDO=1" >$prefix/systemd/system/wg-quick@wg0.service.d/boringtun.conf
        if [[ -n "$cron" ]] && [[ "$os" == "centos" || "$os" == "fedora" ]]; then
            systemctl enable --now crond.service
        fi
    fi
    # If firewalld was just installed, enable it
    if [[ "$firewall" == "firewalld" ]]; then
        systemctl enable --now firewalld.service
    fi
    # Generate wg0.conf
    cat <<EOF >$prefix/wireguard/wg0.conf
# Do not alter the commented lines
# They are used by wireguard-install
# ENDPOINT $([[ -n "$public_ip" ]] && echo "$public_ip" || echo "$ip")

[Interface]
Address = 10.7.0.1/24$([[ -n "$ip6" ]] && echo ", fddd:2c4:2c4:2c4::1/64")
PrivateKey = $(wg genkey)
ListenPort = $port

EOF
    chmod 600 $prefix/wireguard/wg0.conf
    # Enable net.ipv4.ip_forward for the system
    echo 'net.ipv4.ip_forward=1' >$prefix/sysctl.d/30-wireguard-forward.conf
    # Enable without waiting for a reboot or service restart
    echo 1 >/proc/sys/net/ipv4/ip_forward
    if [[ -n "$ip6" ]]; then
        # Enable net.ipv6.conf.all.forwarding for the system
        echo "net.ipv6.conf.all.forwarding=1" >>$prefix/sysctl.d/30-wireguard-forward.conf
        # Enable without waiting for a reboot or service restart
        echo 1 >/proc/sys/net/ipv6/conf/all/forwarding
    fi
    if systemctl is-active --quiet firewalld.service; then
        # Using both permanent and not permanent rules to avoid a firewalld
        # reload.
        firewall-cmd --add-port="$port"/udp
        firewall-cmd --zone=trusted --add-source=10.7.0.0/24
        firewall-cmd --permanent --add-port="$port"/udp
        firewall-cmd --permanent --zone=trusted --add-source=10.7.0.0/24
        # Set NAT for the VPN subnet
        firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
        firewall-cmd --permanent --direct --add-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
        if [[ -n "$ip6" ]]; then
            firewall-cmd --zone=trusted --add-source=fddd:2c4:2c4:2c4::/64
            firewall-cmd --permanent --zone=trusted --add-source=fddd:2c4:2c4:2c4::/64
            firewall-cmd --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
            firewall-cmd --permanent --direct --add-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
        fi
    else
        # Create a service to set up persistent iptables rules
        iptables_path=$(command -v iptables)
        ip6tables_path=$(command -v ip6tables)
        # nf_tables is not available as standard in OVZ kernels. So use iptables-legacy
        # if we are in OVZ, with a nf_tables backend and iptables-legacy is available.
        if [[ $(systemd-detect-virt) == "openvz" ]] && readlink -f "$(command -v iptables)" | grep -q "nft" && hash iptables-legacy 2>/dev/null; then
            iptables_path=$(command -v iptables-legacy)
            ip6tables_path=$(command -v ip6tables-legacy)
        fi
        echo "[Unit]
Before=network.target
[Service]
Type=oneshot
ExecStart=$iptables_path -t nat -A POSTROUTING -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to $ip
ExecStart=$iptables_path -I INPUT -p udp --dport $port -j ACCEPT
ExecStart=$iptables_path -I FORWARD -s 10.7.0.0/24 -j ACCEPT
ExecStart=$iptables_path -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$iptables_path -t nat -D POSTROUTING -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to $ip
ExecStop=$iptables_path -D INPUT -p udp --dport $port -j ACCEPT
ExecStop=$iptables_path -D FORWARD -s 10.7.0.0/24 -j ACCEPT
ExecStop=$iptables_path -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" >$prefix/systemd/system/wg-iptables.service
        if [[ -n "$ip6" ]]; then
            echo "ExecStart=$ip6tables_path -t nat -A POSTROUTING -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to $ip6
ExecStart=$ip6tables_path -I FORWARD -s fddd:2c4:2c4:2c4::/64 -j ACCEPT
ExecStart=$ip6tables_path -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=$ip6tables_path -t nat -D POSTROUTING -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to $ip6
ExecStop=$ip6tables_path -D FORWARD -s fddd:2c4:2c4:2c4::/64 -j ACCEPT
ExecStop=$ip6tables_path -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" >>$prefix/systemd/system/wg-iptables.service
        fi
        echo "RemainAfterExit=yes
[Install]
WantedBy=multi-user.target" >>$prefix/systemd/system/wg-iptables.service
        systemctl enable --now wg-iptables.service
    fi
    # Generates the custom client.conf
    new_client_setup
    # Enable and start the wg-quick service
    systemctl enable --now wg-quick@wg0.service
    # Set up automatic updates for BoringTun if the user wanted to
    if [[ "$boringtun_updates" =~ ^[yY]*$ ]]; then
        # Deploy upgrade script
        cat <<'EOF' >/usr/local/sbin/boringtun-upgrade
#!/bin/bash
latest=$(wget -qO- https://wg.nyr.be/1/latest 2>/dev/null || curl -sL https://wg.nyr.be/1/latest 2>/dev/null)
# If server did not provide an appropriate response, exit
if ! head -1 <<< "$latest" | grep -qiE "^boringtun.+[0-9]+\.[0-9]+.*$"; then
	echo "Servidor de actualización no disponible"
	exit
fi
current=$(boringtun -V)
if [[ "$current" != "$latest" ]]; then
	download="https://wg.nyr.be/1/latest/download"
	xdir=$(mktemp -d)
	# If download and extraction are successful, upgrade the boringtun binary
	if { wget -qO- "$download" 2>/dev/null || curl -sL "$download" ; } | tar xz -C "$xdir" --wildcards "boringtun-*/boringtun" --strip-components 1; then
		systemctl stop wg-quick@wg0.service
		rm -f /usr/local/sbin/boringtun
		mv "$xdir"/boringtun /usr/local/sbin/boringtun
		systemctl start wg-quick@wg0.service
		echo -e -n "${lightgreen}"
		echo "Succesfully updated to $(boringtun -V)"
	else
		echo -e -n "${red}"
		echo "boringtun update failed"
	fi
	rm -rf "$xdir"
	echo -e -n "${nocolor}"
else
	echo "$current is up to date"
fi
EOF
        chmod +x /usr/local/sbin/boringtun-upgrade
        # Add cron job to run the updater daily at a random time between 3:00 and 5:59
        {
            crontab -l 2>/dev/null
            echo "$(($RANDOM % 60)) $(($RANDOM % 3 + 3)) * * * /usr/local/sbin/boringtun-upgrade &>/dev/null"
        } | crontab -
    fi
    code() {
        echo
        qrencode -t UTF8 <${sdir[0]}/wireguard/"$client.conf"
        echo -e '\xE2\x86\x91 Ese es un código QR que contiene la configuración del cliente.'
        echo
    }
    msg -ama " DESEA VER EL QR [s/n]"
    read -p " [ S | N ]: " -e -i n code
    [[ "$code" = "s" || "$code" = "S" ]] && $code
    # If the kernel module didn't load, system probably had an outdated kernel
    # We'll try to help, but will not will not force a kernel upgrade upon the user
    if [[ ! "$is_container" -eq 0 ]] && ! modprobe -nq wireguard; then
        echo -e -n "${red}"
        echo "¡Advertencia!"
        echo "La instalación finalizó, pero el módulo kernel de WireGuard no pudo cargarse"
        if [[ "$os" == "ubuntu" && "$os_version" -eq 1804 ]]; then
            echo 'Upgrade the kernel and headers with "apt-get install linux-generic" and restart.'
        #elif [[ "$os" == "debian" && "$os_version" -eq 9 ]]; then
        #echo "Actualice el kernel con \"apt-get install linux-image-$architecture\" y reinicie"
        elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
            echo "Actualice el kernel con \"apt-get install linux-image-$architecture\" y reinicie"
        elif [[ "$os" == "centos" && "$os_version" -le 8 ]]; then
            echo "Reboot the system to load the most recent kernel."
        fi
        echo -e -n "${nocolor}"
    else
        echo -e -n "${green}"
        echo "INSTALADO CON EXITO!"
        echo -e -n "${nocolor}"
    fi
    echo
    echo -e -n "${lightgreen}"
    echo "La configuración del cliente está disponible en la opcion 4" #: ${sdir[0]}/wireguard/$client.conf"
    echo "Se pueden agregar nuevos clientes ejecutando este script nuevamente"
    echo -e -n "${nocolor}"
    #else
}
menufun() {
    clear
    #msg -bar
    
    msg -bar
    echo -e "	\e[1;100mMENÚ WIREGUARD\e[0m"
    msg -bar
    #echo "Select an option:"
    echo -e "\e[1;91m   1) \e[92mAGREGAR NUEVO USUARIO"
    echo -e "\e[1;91m   2) \e[97m\e[41mELIMINAR USUARIO\e[0m"
    echo -e "\e[1;91m   3) \e[93mDESCARGAR CONFI "
    echo -e "\e[1;91m   4) \e[92mINFORMACION DE LA CUENTA"
    echo -e "\e[1;91m   5) \e[97m\e[1;41mDESINSTALAR WIREGUARD\e[0m"
    echo -e "\e[1;93m   6) \e[91mSALIR"
    msg -bar
    read -p "$(echo -e "\e[1;97m SELECIONE UNA OPCION:") " option
    until [[ "$option" =~ ^[1-6]$ ]]; do
        echo "$option: OPCION INVALIDA."
        read -p "Selecione Una Opcion: " option
    done
    echo -e -n "${nocolor}"
    case "$option" in
    1)
        clear
        echo
        echo -e -n "${cyan}"
        echo " Ingrese El nombre Del Usuario: "
        echo -e -n "${nocolor}"
        read -p "Nombre: " unsanitized_client
        # Allow a limited set of characters to avoid conflicts
        client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<<"$unsanitized_client")
        while [[ -z "$client" ]] || grep -q "^# BEGIN_PEER $client$" $prefix/wireguard/wg0.conf; do
            echo "$client: invalid name."
            read -p "Nombre: " unsanitized_client
            client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<<"$unsanitized_client")
        done
        echo
        new_client_dns
        new_client_setup
        # Append new client configuration to the WireGuard interface
        wg addconf wg0 <(sed -n "/^# BEGIN_PEER $client/,/^# END_PEER $client/p" $prefix/wireguard/wg0.conf)
        code() {
            echo
            qrencode -t UTF8 <${sdir[0]}/wireguard/"$client.conf"
            echo -e '\xE2\x86\x91 Ese es un código QR que contiene la configuración de su cliente.'
            echo
        }
        msg -ama " DESEA VER EL QR [s/n]"
        read -p " [ S | N ]: " -e -i n code
        [[ "$code" = "s" || "$code" = "S" ]] && $code
        echo -e -n "${green}"
        echo "$client agregado, la configuracion esta en la opcion 4 " #: ${sdir[0]}/wireguard/$client.conf"
        echo -e -n "${nocolor}"
        exit
        ;;
    2)
        # This option could be documented a bit better and maybe even be simplified
        # ...but what can I say, I want some sleep too
        number_of_clients=$(grep -c '^# BEGIN_PEER' $prefix/wireguard/wg0.conf)
        if [[ "$number_of_clients" = 0 ]]; then
            echo
            echo -e -n "${red}"
            echo "¡No hay clientes existentes!"
            echo -e -n "${nocolor}"
            exit
        fi
        echo
        echo -e -n "${green}"
        echo "Seleciona la opcion del cliente: "
        grep '^# BEGIN_PEER' $prefix/wireguard/wg0.conf | cut -d ' ' -f 3 | nl -s ') '
        read -p "Cliente: " client_number
        until [[ "$client_number" =~ ^[0-9]+$ && "$client_number" -le "$number_of_clients" ]]; do
            echo "$client_number: invalid selection."
            read -p "Cliente: " client_number
        done
        client=$(grep '^# BEGIN_PEER' $prefix/wireguard/wg0.conf | cut -d ' ' -f 3 | sed -n "$client_number"p)
        echo
        echo -e -n "${red}"
        read -p "Confirmar $client para remover? [y/N]: " remove
        until [[ "$remove" =~ ^[yYnN]*$ ]]; do
            echo "$remove: invalid selection."
            echo -e -n "${red}"
            read -p "Confirmar $client para remover? [y/N]: " remove
        done
        echo -e -n "${nocolor}"
        if [[ "$remove" =~ ^[yY]$ ]]; then
            # The following is the right way to avoid disrupting other active connections:
            # Remove from the live interface
            wg set wg0 peer "$(sed -n "/^# BEGIN_PEER $client$/,\$p" $prefix/wireguard/wg0.conf | grep -m 1 PublicKey | cut -d " " -f 3)" remove
            # Remove from the configuration file
            sed -i "/^# BEGIN_PEER $client/,/^# END_PEER $client/d" $prefix/wireguard/wg0.conf
            echo
            echo -e -n "${green}"
            echo "$client eliminado!"
            rm ~/$client.conf &>/dev/null
            rm ${sdir[0]}/wireguard/$client.conf &>/dev/null
            echo -e -n "${nocolor}"
        else
            echo
            echo -e -n "${red}"
            echo "$client no eliminado!"
            echo -e -n "${nocolor}"
        fi
        echo -e -n "${nocolor}"
        exit
        ;;
    3)
        clear
        #msg -bar
        #
        clear
        #msg -bar
        
        n=1
        for i in $(ls ${sdir[0]}/wireguard); do
            loc=$(echo $i) #|awk -F "" '{print $1}')
            zona=$(printf '%-12s' "$loc")
            echo -e " \e[37m [$n] \e[31m> \e[32m$zona"
            r[$n]=$zona
            selec="$n"
            let n++
        done
        msg -bar
        opci=$(selection_fun $selec)
        echo ""
        cp -r ${sdir[0]}/wireguard/${r[$opci]} /var/www/html/${r[$opci]}
        chmod 777 /var/www/html/${r[$opci]}

        fun_ip
        msg -bar
        msg -ama " LINK DEL CLIENTE: http://$IP:81/${r[$opci]}"
        msg -bar

        ;;
    4)
        clear
        msg -bar
        
        n=1
        for i in $(ls ${sdir[0]}/wireguard); do
            loc=$(echo $i) #|awk -F "" '{print $1}')
            zona=$(printf '%-12s' "$loc")
            echo -e " \e[37m [$n] \e[31m> \e[32m$zona"
            r[$n]=$zona
            selec="$n"
            let n++
        done
        msg -bar
        opci=$(selection_fun $selec)
        echo ""
        echo -e "	\e[1;100mCONFIGURACION DEL CLIENTE\e[0m\n\e[97m$(cat ${sdir[0]}/wireguard/${r[$opci]})"
        msg -bar

        ;;
    5)
        echo
        echo -e -n "${red}"
        read -p "Confirmar WireGuard para remover? [y/N]: " remove
        echo -e -n "${nocolor}"
        until [[ "$remove" =~ ^[yYnN]*$ ]]; do
            echo -e -n "${red}"
            echo "$remove: invalid selection."
            read -p "Confirmar WireGuard para remover? [y/N]: " remove
            echo -e -n "${nocolor}"
        done
        if [[ "$remove" =~ ^[yY]$ ]]; then
            port=$(grep '^ListenPort' $prefix/wireguard/wg0.conf | cut -d " " -f 3)
            if systemctl is-active --quiet firewalld.service; then
                ip=$(firewall-cmd --direct --get-rules ipv4 nat POSTROUTING | grep '\-s 10.7.0.0/24 '"'"'!'"'"' -d 10.7.0.0/24' | grep -oE '[^ ]+$')
                # Using both permanent and not permanent rules to avoid a firewalld reload.
                firewall-cmd --remove-port="$port"/udp
                firewall-cmd --zone=trusted --remove-source=10.7.0.0/24
                firewall-cmd --permanent --remove-port="$port"/udp
                firewall-cmd --permanent --zone=trusted --remove-source=10.7.0.0/24
                firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
                firewall-cmd --permanent --direct --remove-rule ipv4 nat POSTROUTING 0 -s 10.7.0.0/24 ! -d 10.7.0.0/24 -j SNAT --to "$ip"
                if grep -qs 'fddd:2c4:2c4:2c4::1/64' $prefix/wireguard/wg0.conf; then
                    ip6=$(firewall-cmd --direct --get-rules ipv6 nat POSTROUTING | grep '\-s fddd:2c4:2c4:2c4::/64 '"'"'!'"'"' -d fddd:2c4:2c4:2c4::/64' | grep -oE '[^ ]+$')
                    firewall-cmd --zone=trusted --remove-source=fddd:2c4:2c4:2c4::/64
                    firewall-cmd --permanent --zone=trusted --remove-source=fddd:2c4:2c4:2c4::/64
                    firewall-cmd --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
                    firewall-cmd --permanent --direct --remove-rule ipv6 nat POSTROUTING 0 -s fddd:2c4:2c4:2c4::/64 ! -d fddd:2c4:2c4:2c4::/64 -j SNAT --to "$ip6"
                fi
            else
                systemctl disable --now wg-iptables.service
                rm -f $prefix/systemd/system/wg-iptables.service
            fi
            systemctl disable --now wg-quick@wg0.service
            rm -f $prefix/systemd/system/wg-quick@wg0.service.d/boringtun.conf
            rm -f $prefix/sysctl.d/30-wireguard-forward.conf
            # Different packages were installed if the system was containerized or not
            if [[ ! "$is_container" -eq 0 ]]; then
                if [[ "$os" == "ubuntu" ]]; then
                    # Ubuntu
                    rm -rf $prefix/wireguard/
                    apt-get remove --purge -y wireguard wireguard-tools
                elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
                    # Debian 10
                    rm -rf $prefix/wireguard/
                    apt-get remove --purge -y wireguard wireguard-dkms wireguard-tools
                    #elif [[ "$os" == "debian" && "$os_version" -eq 9 ]]; then
                    # Debian 10
                    #rm -rf $prefix/wireguard/
                    #apt-get remove --purge -y wireguard wireguard-dkms wireguard-tools
                elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
                    # CentOS 8
                    rm -rf $prefix/wireguard/
                    dnf remove -y kmod-wireguard wireguard-tools
                elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
                    # CentOS 7
                    rm -rf $prefix/wireguard/
                    yum remove -y kmod-wireguard wireguard-tools
                elif [[ "$os" == "fedora" ]]; then
                    # Fedora
                    rm -rf $prefix/wireguard/
                    dnf remove -y wireguard-tools
                fi
            else
                { crontab -l 2>/dev/null | grep -v '/usr/local/sbin/boringtun-upgrade'; } | crontab -
                if [[ "$os" == "ubuntu" ]]; then
                    # Ubuntu
                    rm -rf $prefix/wireguard/
                    apt-get remove --purge -y wireguard-tools
                elif [[ "$os" == "debian" && "$os_version" -eq 10 ]]; then
                    # Debian 10
                    rm -rf $prefix/wireguard/
                    apt-get remove --purge -y wireguard-tools
                    #elif [[ "$os" == "debian" && "$os_version" -eq 9 ]]; then
                    # Debian 10
                    #rm -rf $prefix/wireguard/
                    #apt-get remove --purge -y wireguard-tools
                elif [[ "$os" == "centos" && "$os_version" -eq 8 ]]; then
                    # CentOS 8
                    rm -rf $prefix/wireguard/
                    dnf remove -y wireguard-tools
                elif [[ "$os" == "centos" && "$os_version" -eq 7 ]]; then
                    # CentOS 7
                    rm -rf $prefix/wireguard/
                    yum remove -y wireguard-tools
                elif [[ "$os" == "fedora" ]]; then
                    # Fedora
                    rm -rf $prefix/wireguard/
                    dnf remove -y wireguard-tools
                fi
                rm -f /usr/local/sbin/boringtun /usr/local/sbin/boringtun-upgrade
            fi
            echo
            echo -e -n "${green}"
            echo "WireGuard desinstalado!"
            rm ${sdir[0]}/wireguard/*.conf &>/dev/null
            echo -e -n "${nocolor}"
        else
            echo
            echo -e -n "${red}"
            echo "desinstalacion WireGuard abortado!"
            echo -e -n "${nocolor}"
        fi
        exit
        ;;
    6)
        exit
        ;;
    esac

}
#echo -e -n "${nocolor}"
if [[ ! -e $prefix/wireguard/wg0.conf ]]; then
    clear
    #msg -bar
    
    msg -bar
    echo -e "	\e[1;100mMENÚ WIREGUARD\e[0m"
    msg -bar
    #echo "Select an option:"
    echo -e "\e[1;91m   1) \e[92mINSTALAR WIREGUARD"
    echo -e "\e[1;93m   0) \e[91mSALIR"
    msg -bar
    read -p "$(echo -e "\e[1;97m SELECIONE UNA OPCION:") " option
    case $option in
    1) install ;;
    0) exit ;;
    esac
else
    menufun
fi
#

}

 case $1 in
 --CSSR)_CSSR &&menu3;; # protocolo: CSSR
 --badvpn)_budp&&menu3;; # protocolo: budp
 --chekuser)_chekuser&&menu3;; # protocolo: chekuser
 --dropbear)_dropbear&&menu3;; # protocolo: dropbear
 --openvpn)_openvpn&&menu3;; # protocolo: openvpn
 --protocolos)_protocolos&&menu3;; # protocolo: protocolos
 --shadowsocks)_shadowsocks&&menu3;; # protocolo: shadowsocks
 --slowdns)_slowdns&&menu3;; # protocolo: slowdns
 #--sockspy)_sockspy&&menu3;; # protocolo: sockspy
 --sockspy)
#!/bin/bash
ll="/usr/local/include/snaps" && [[ ! -d ${ll} ]] && exit

#
clear
clear
SCPdir="/etc/VPS-MX"
SCPfrm="${SCPdir}/herramientas" && [[ ! -d ${SCPfrm} ]] && exit
SCPinst="${SCPdir}/protocolos" && [[ ! -d ${SCPinst} ]] && exit

declare -A cor=([0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m")
[[ $(dpkg --get-selections | grep -w "python" | head -1) ]] || apt-get install python -y &>/dev/null
[[ $(dpkg --get-selections | grep -w "python-pip" | head -1) ]] || apt-get install python pip -y &>/dev/null
[[ $(dpkg --get-selections | grep -w "net-tools" | head -1) ]] || apt-get install net-tools -y &>/dev/null
mportas() {
    unset portas
    portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN")
    while read port; do
        var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
        [[ "$(echo -e $portas | grep "$var1 $var2")" ]] || portas+="$var1 $var2\n"
    done <<<"$portas_var"
    i=1
    echo -e "$portas"
}
meu_ip() {
    MEU_IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
    MEU_IP2=$(wget -qO- ipv4.icanhazip.com)
    [[ "$MEU_IP" != "$MEU_IP2" ]] && echo "$MEU_IP2" || echo "$MEU_IP"
}
IP=$(wget -qO- ipv4.icanhazip.com)
tcpbypass_fun() {
    [[ -e $HOME/socks ]] && rm -rf $HOME/socks >/dev/null 2>&1
    [[ -d $HOME/socks ]] && rm -rf $HOME/socks >/dev/null 2>&1
    cd $HOME && mkdir socks >/dev/null 2>&1
    cd socks
    patch="https://www.dropbox.com/s/mn75pqufdc7zn97/backsocz"
    arq="backsocz"
    wget $patch -o /dev/null
    unzip $arq >/dev/null 2>&1
    mv -f ./ssh /etc/ssh/sshd_config && service ssh restart 1>/dev/null 2>/dev/null
    mv -f sckt$(python3 --version | awk '{print $2}' | cut -d'.' -f1,2) /usr/sbin/sckt
    mv -f scktcheck /bin/scktcheck
    chmod +x /bin/scktcheck
    chmod +x /usr/sbin/sckt
    rm -rf $HOME/socks
    cd $HOME
    msg="$2"
    [[ $msg = "" ]] && msg="@vpsmod"
    portxz="$1"
    [[ $portxz = "" ]] && portxz="8080"
    screen -dmS sokz scktcheck "$portxz" "$msg" >/dev/null 2>&1
}
l="/usr/local/lib/sped" && [[ ! -d ${l} ]] && exit
gettunel_fun() {
    echo "master=NetVPS" >${SCPinst}/pwd.pwd
    while read service; do
        [[ -z $service ]] && break
        echo "127.0.0.1:$(echo $service | cut -d' ' -f2)=$(echo $service | cut -d' ' -f1)" >>${SCPinst}/pwd.pwd
    done <<<"$(mportas)"
    screen -dmS getpy python ${SCPinst}/PGet.py -b "0.0.0.0:$1" -p "${SCPinst}/pwd.pwd"
    [[ "$(ps x | grep "PGet.py" | grep -v "grep" | awk -F "pts" '{print $1}')" ]] && {
        echo -e "Gettunel Iniciado con Sucesso"
        msg -bar
        echo -ne "Su contraseña Gettunel es:"
        echo -e "\033[1;32m NetVPS"
        msg -bar
    } || echo -e "Gettunel no fue iniciado"
    msg -bar
}

sistema20() {
    if [[ ! -e /etc/VPS-MX/fix ]]; then
        echo ""
        ins() {
            export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/
            apt-get install python -y
            apt-get install python pip -y
        }
        ins &>/dev/null && echo -e "INSTALANDO FIX" | pv -qL 40
        sleep 1.s
        [[ ! -e /etc/VPS-MX/fix ]] && touch /etc/VPS-MX/fix
    else
        echo ""
    fi
}
sistema22() {
    if [[ ! -e /etc/VPS-MX/fixer ]]; then
        echo ""
        ins() {
            export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games/
            apt-get install python2 -y
            apt-get install python -y
            apt install python pip -y
            rm -rf /usr/bin/python
            ln -s /usr/bin/python2.7 /usr/bin/python
        }
        ins &>/dev/null && echo -e "INSTALANDO FIX" | pv -qL 40
        sleep 1.s
        [[ ! -e /etc/VPS-MX/fixer ]] && touch /etc/VPS-MX/fixer
    else
        echo ""
    fi
}

PythonDic_fun() {

    clear
    echo ""
    echo ""
    msg -tit
    msg -bar
    echo -e "\033[1;31m  SOCKS DIRECTO-PY | CUSTOM\033[0m"
    while true; do
        msg -bar
        echo -ne "\033[1;37m"
        read -p " ESCRIBE SU PUERTO: " porta_socket
        echo -e ""
        [[ $(mportas | grep -w "$porta_socket") ]] || break
        echo -e " ESTE PUERTO YA ESTÁ EN USO"
        unset porta_socket
    done
    msg -bar
    echo -e "\033[1;97m Digite Un Puerto Local 22|443|80\033[1;37m"
    msg -bar
    while true; do
        echo -ne "\033[1;36m"
        read -p " Digite Un Puerto SSH/DROPBEAR activo: " PORTLOC
        echo -e ""
        if [[ ! -z $PORTLOC ]]; then
            if [[ $(echo $PORTLOC | grep [0-9]) ]]; then
                [[ $(mportas | grep $PORTLOC | head -1) ]] && break || echo -e "ESTE PUERTO NO EXISTE"
            fi
        fi
    done
    #
    puertoantla="$(mportas | grep $PORTLOC | awk '{print $2}' | head -1)"
    msg -bar
    echo -ne " Escribe El HTTP Response? 101|200|300: \033[1;37m" && read cabezado
    tput cuu1 && tput dl1
    if [[ -z $cabezado ]]; then
        cabezado="200"
        echo -e "	\e[31mResponse Default:\033[1;32m ${cabezado}"
    else
        echo -e "	\e[31mResponse Elegido:\033[1;32m ${cabezado}"
    fi
    msg -bar
    echo -e "$(fun_trans "Introdusca su Mini-Banner")"
    msg -bar
    echo -ne " Introduzca el texto de estado plano o en HTML:\n \033[1;37m" && read texto_soket
    tput cuu1 && tput dl1
    if [[ -z $texto_soket ]]; then
        texto_soket="@lacasitamx"
        echo -e "	\e[31mMensage Default: \033[1;32m${texto_soket} "
    else
        echo -e "	\e[31mMensage: \033[1;32m ${texto_soket}"
    fi
    msg -bar

    (
        less <<CPM >/etc/VPS-MX/protocolos/PDirect.py
import socket, threading, thread, select, signal, sys, time, getopt

# Listen
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = int("$porta_socket")
PASS = ''

# CONST
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:$puertoantla'
RESPONSE = 'HTTP/1.1 $cabezado <strong>$texto_soket</strong>\r\n\r\nHTTP/1.1 $cabezado Conexion Exitosa\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()
    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()
    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()
    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()
class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True
    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            if hostPort == '':
                hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, 'X-Split')
            if split != '':
                self.client.recv(BUFLEN)
            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
				
                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + e.strerror
            self.server.printLog(self.log)
	    pass
        finally:
            self.close()
            self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + ': ')
        if aux == -1:
            return ''
        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')
        if aux == -1:
            return ''
        return head[:aux];
    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method=='CONNECT':
            	
                port = 443
            else:
                port = 80
                port = 8080
                port = 8799
                port = 3128
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path
        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = ''
        self.server.printLog(self.log)
        self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
		    try:
                        data = in_.recv(BUFLEN)
                        if data:
			    if in_ is self.target:
				self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]
                            count = 0
			else:
			    break
		    except:
                        error = True
                        break
            if count == TIMEOUT:
                error = True
            if error:
                break
def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print "\n:-------PythonProxy-------:\n"
    print "Listening addr: " + LISTENING_ADDR
    print "Listening port: " + str(LISTENING_PORT) + "\n"
    print ":-------------------------:\n"
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    while True:
        try:
            time.sleep(2)
        except KeyboardInterrupt:
            print 'Stopping...'
            server.close()
            break
if __name__ == '__main__':
    main()
CPM
    ) >$HOME/proxy.log &

    chmod +x /etc/VPS-MX/protocolos/PDirect.py
    screen -dmS ws$porta_socket python ${SCPinst}/PDirect.py $porta_socket $texto_soket >/root/proxy.log &
    #screen -dmS pydic-"$porta_socket" python ${SCPinst}/PDirect.py "$porta_socket" "$texto_soket" && echo ""$porta_socket" "$texto_soket"" >> /etc/VPS-MX/PortPD.log

    echo "$porta_socket $texto_soket" >/etc/VPS-MX/PortPD.log
    [[ $(grep -wc "PDirect.py" /etc/autostart) = '0' ]] && {
        echo -e "netstat -tlpn | grep -w $porta_socket > /dev/null || {  screen -r -S 'ws$porta_socket' -X quit;  screen -dmS ws$porta_socket python ${SCPinst}/PDirect.py $porta_socket $texto_soket; }" >>/etc/autostart
    } || {
        sed -i '/PDirect.py/d' /etc/autostart
        echo -e "netstat -tlpn | grep -w $porta_socket > /dev/null || {  screen -r -S 'ws$porta_socket' -X quit;  screen -dmS ws$porta_socket python ${SCPinst}/PDirect.py $porta_socket $texto_soket; }" >>/etc/autostart
    }

}

pythontest() {
    clear
    echo ""
    echo ""
    msg -tit
    msg -bar
    echo -e "\033[1;31m  SOCKS DIRECTO-PY | CUSTOM\033[0m"
    while true; do
        msg -bar
        echo -ne "\033[1;37m"
        read -p " ESCRIBE SU PUERTO: " porta_socket
        echo -e ""
        [[ $(mportas | grep -w "$porta_socket") ]] || break
        echo -e " ESTE PUERTO YA ESTÁ EN USO"
        unset porta_socket
    done
    msg -bar
    echo -e "\033[1;97m Digite Un Puerto Local 22|443|80\033[1;37m"
    msg -bar
    while true; do
        echo -ne "\033[1;36m"
        read -p " Digite Un Puerto SSH/DROPBEAR activo: " PORTLOC
        echo -e ""
        if [[ ! -z $PORTLOC ]]; then
            if [[ $(echo $PORTLOC | grep [0-9]) ]]; then
                [[ $(mportas | grep $PORTLOC | head -1) ]] && break || echo -e "ESTE PUERTO NO EXISTE"
            fi
        fi
    done
    #
    puertoantla="$(mportas | grep $PORTLOC | awk '{print $2}' | head -1)"
    msg -bar
    echo -ne " Escribe El HTTP Response? 101|200|300: \033[1;37m" && read cabezado
    tput cuu1 && tput dl1
    if [[ -z $cabezado ]]; then
        cabezado="200"
        echo -e "	\e[31mResponse Default:\033[1;32m ${cabezado}"
    else
        echo -e "	\e[31mResponse Elegido:\033[1;32m ${cabezado}"
    fi
    msg -bar
    echo -e "$(fun_trans "Introdusca su Mini-Banner")"
    msg -bar
    echo -ne " Introduzca el texto de estado plano o en HTML:\n \033[1;37m" && read texto_soket
    tput cuu1 && tput dl1
    if [[ -z $texto_soket ]]; then
        texto_soket="$ress"
        echo -e "	\e[31mMensage Default: \033[1;32m${texto_soket} "
    else
        echo -e "	\e[31mMensage: \033[1;32m ${texto_soket}"
    fi
    msg -bar

    (
        less <<CPM >/etc/VPS-MX/protocolos/python.py
import socket, threading, thread, select, signal, sys, time, getopt

# Listen
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = int("$porta_socket")
PASS = ''

# CONST
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:$puertoantla'
RESPONSE = 'HTTP/1.1 $cabezado <strong>$texto_soket</strong>\r\n\r\nHTTP/1.1 $cabezado Conexion Exitosa\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()
    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()
    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()
    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()
            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()
class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True
        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True
    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')
            if hostPort == '':
                hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, 'X-Split')
            if split != '':
                self.client.recv(BUFLEN)
            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
				
                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + e.strerror
            self.server.printLog(self.log)
	    pass
        finally:
            self.close()
            self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + ': ')
        if aux == -1:
            return ''
        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')
        if aux == -1:
            return ''
        return head[:aux];
    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method=='CONNECT':
            	
                port = 443
            else:
                port = 80
                port = 8080
                port = 8799
                port = 3128
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path
        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = ''
        self.server.printLog(self.log)
        self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
		    try:
                        data = in_.recv(BUFLEN)
                        if data:
			    if in_ is self.target:
				self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]
                            count = 0
			else:
			    break
		    except:
                        error = True
                        break
            if count == TIMEOUT:
                error = True
            if error:
                break
def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print "\n:-------PythonProxy-------:\n"
    print "Listening addr: " + LISTENING_ADDR
    print "Listening port: " + str(LISTENING_PORT) + "\n"
    print ":-------------------------:\n"
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    while True:
        try:
            time.sleep(2)
        except KeyboardInterrupt:
            print 'Stopping...'
            server.close()
            break
if __name__ == '__main__':
    main()
CPM
    ) >$HOME/proxy.log &

    chmod +x /etc/VPS-MX/protocolos/python.py
    echo -e "[Unit]\nDescription=python.py Service\nAfter=network.target\nStartLimitIntervalSec=0\n\n[Service]\nType=simple\nUser=root\nWorkingDirectory=/root\nExecStart=/usr/bin/python ${SCPinst}/python.py $porta_socket $texto_soket\nRestart=always\nRestartSec=3s\n[Install]\nWantedBy=multi-user.target" >/etc/systemd/system/python.PD.service
    echo "$porta_socket $texto_soket" >/etc/VPS-MX/PortPD.log
    systemctl enable python.PD &>/dev/null
    systemctl start python.PD &>/dev/null

}

pid_kill() {
    [[ -z $1 ]] && refurn 1
    pids="$@"
    for pid in $(echo $pids); do
        kill -9 $pid &>/dev/null
    done
}
selecionador() {
    clear
    echo ""
    echo ""
    echo ""
    while true; do
        msg -bar
        echo -ne "\033[1;37m"
        read -p " ESCRIBE SU PUERTO: " porta_socket
        echo -e ""
        [[ $(mportas | grep -w "$porta_socket") ]] || break
        echo -e " ESTE PUERTO YA ESTÁ EN USO"
        unset porta_socket
    done
    echo -e "Introdusca su Mini-Banner"
    msg -bar
    echo -ne "Introduzca el texto de estado plano o en HTML:\n \033[1;37m" && read texto_soket
    msg -bar
}
remove_fun() {
    echo -e "Parando Socks Python"
    msg -bar
    pidproxy=$(ps x | grep "PPub.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy ]] && pid_kill $pidproxy
    pidproxy2=$(ps x | grep "PPriv.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy2 ]] && pid_kill $pidproxy2
    pidproxy3=$(ps x | grep "PDirect.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy3 ]] && pid_kill $pidproxy3
    pidproxy4=$(ps x | grep "POpen.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy4 ]] && pid_kill $pidproxy4
    pidproxy5=$(ps x | grep "PGet.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy5 ]] && pid_kill $pidproxy5
    pidproxy6=$(ps x | grep "scktcheck" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy6 ]] && pid_kill $pidproxy6
    pidproxy7=$(ps x | grep "python.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy7 ]] && pid_kill $pidproxy7
    pidproxy8=$(ps x | grep "lacasitamx.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy8 ]] && pid_kill $pidproxy8
    echo -e "\033[1;91mSocks DETENIDOS"
    msg -bar
    rm /etc/VPS-MX/PortPD.log &>/dev/null
    echo "" >/etc/VPS-MX/PortPD.log

    for pidproxy in $(screen -ls | grep ".ws" | awk {'print $1'}); do
        screen -r -S "$pidproxy" -X quit
    done
    [[ $(grep -wc "PDirect.py" /etc/autostart) != '0' ]] && {
        sed -i '/PDirect.py/d' /etc/autostart
    }
    sleep 1
    screen -wipe >/dev/null
    systemctl stop python.PD &>/dev/null
    systemctl disable python.PD &>/dev/null
    rm /etc/systemd/system/python.PD.service &>/dev/null
    exit 0
}
iniciarsocks() {
    pidproxy=$(ps x | grep -w "PPub.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy ]] && P1="\033[1;32m[ON]" || P1="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy2=$(ps x | grep -w "PPriv.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy2 ]] && P2="\033[1;32m[ON]" || P2="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy3=$(ps x | grep -w "PDirect.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy3 ]] && P3="\033[1;32m[ON]" || P3="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy4=$(ps x | grep -w "POpen.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy4 ]] && P4="\033[1;32m[ON]" || P4="\e[37m[\033[1;31mOFF\e[37m]"

    pidproxy5=$(ps x | grep "PGet.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy5 ]] && P5="\033[1;32m[ON]" || P5="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy6=$(ps x | grep "scktcheck" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy6 ]] && P6="\033[1;32m[ON]" || P6="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy7=$(ps x | grep "python.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy7 ]] && P7="\033[1;32m[ON]" || P7="\e[37m[\033[1;31mOFF\e[37m]"
    pidproxy8=$(ps x | grep "python.py" | grep -v "grep" | awk -F "pts" '{print $1}') && [[ ! -z $pidproxy8 ]] && P8="\033[1;32m[ON]" || P8="\e[37m[\033[1;31mOFF\e[37m]"

    #msg -bar

    echo -e "   	\e[91m\e[43mINSTALADOR DE PROXY'S\e[0m "
    msg -bar
    echo -e " \e[1;93m[\e[92m1\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python SIMPLE      $P1"
    echo -e " \e[1;93m[\e[92m2\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python SEGURO      $P2"
    echo -e " \e[1;93m[\e[92m3\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy WEBSOCKET Custom   $P3 \e[1;32m(Screen TEST)"
    echo -e " \e[1;93m[\e[92m4\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy WEBSOCKET Custom   $P7 \e[1;32m(Socks HTTP)"
    echo -e " \e[1;93m[\e[92m5\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python OPENVPN     $P4"
    echo -e " \e[1;93m[\e[92m6\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python GETTUNEL    $P5"
    echo -e " \e[1;93m[\e[92m7\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mProxy Python TCP BYPASS  $P6"
    echo -e " \e[1;93m[\e[92m8\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mAplicar Fix en \e[1;32m(Ubu22 o Debian11 )"
    echo -e " \e[1;93m[\e[92m9\e[93m] \e[97m$(msg -verm2 "➛ ")\033[1;97mDETENER SERVICIO PYTHON"
    msg -bar
    echo -e " \e[1;93m[\e[92m0\e[93m] \e[97m$(msg -verm2 "➛ ") \e[97m\033[1;41m VOLVER \033[1;37m"
    msg -bar
    IP=(meu_ip)
    while [[ -z $portproxy || $portproxy != @(0|[1-9]) ]]; do
        echo -ne " Digite Una Opcion: \033[1;37m" && read portproxy
        tput cuu1 && tput dl1
    done
    case $portproxy in
    1)
        selecionador
        screen -dmS screen python ${SCPinst}/PPub.py "$porta_socket" "$texto_soket"
        ;;
    2)
        selecionador
        screen -dmS screen python3 ${SCPinst}/PPriv.py "$porta_socket" "$texto_soket" "$IP"
        ;;
    3)
        PIDI="$(ps aux | grep -v grep | grep "ws")"
        if [[ -z $PIDI ]]; then
            sistema20
            PythonDic_fun
        else
            for pidproxy in $(screen -ls | grep ".ws" | awk {'print $1'}); do
                screen -r -S "$pidproxy" -X quit
            done
            [[ $(grep -wc "PDirect.py" /etc/autostart) != '0' ]] && {
                sed -i '/PDirect.py/d' /etc/autostart
            }
            sleep 1
            screen -wipe >/dev/null
            msg -bar
            echo -e "\033[1;91mSocks Directo DETENIDO"
            msg -bar
            exit 0
        fi
        ;;
    4)
        if [[ ! -e /etc/systemd/system/python.PD.service ]]; then
            sistema20
            pythontest
        else
            systemctl stop python.PD &>/dev/null
            systemctl disable python.PD &>/dev/null
            rm /etc/systemd/system/python.PD.service &>/dev/null

            msg -bar
            echo -e "\033[1;91mSocks Directo DETENIDO"
            msg -bar
            exit 0
        fi
        ;;
    5)
        selecionador
        screen -dmS screen python ${SCPinst}/POpen.py "$porta_socket" "$texto_soket"
        ;;
    6)
        selecionador
        gettunel_fun "$porta_socket"
        ;;
    7)
        selecionador
        tcpbypass_fun "$porta_socket" "$texto_soket"
        ;;
    8)
        sistema22
        msg -bar
        msg -ama " AHORA REGRESA EN LA OPCION 3 DE SOCKS HTTP"
        msg -bar

        ;;
    9) remove_fun ;;
    0) return ;;
    esac
    echo -e "\033[1;92mProcedimiento COMPLETO"
    msg -bar
}
iniciarsocks
;;
 --squid)_squid&&menu3;; # protocolo: squid
 #--ssl)_ssl&&menu3;; # protocolo: ssl
 --ssl)
clear
clear

SCPdir="/etc/VPS-MX"
tmp="/etc/VPS-MX/crt" #&& [[ ! -d ${tmp} ]] && mkdir ${tmp}
tmp_crt="/etc/VPS-MX/crt/certificados" && [[ ! -d ${tmp_crt} ]] && mkdir -p ${tmp_crt} &> /dev/null
SCPfrm="${SCPdir}/herramientas" #&& [[ ! -d ${SCPfrm} ]] && exit
SCPinst="${SCPdir}/protocolos"  #&& [[ ! -d ${SCPinst} ]] && exit
declare -A cor=( [0]="\033[1;37m" [1]="\033[1;34m" [2]="\033[1;31m" [3]="\033[1;33m" [4]="\033[1;32m" [5]="\e[1;36m" )

mportas () {
unset portas
portas_var=$(lsof -V -i tcp -P -n | grep -v "ESTABLISHED" |grep -v "COMMAND" | grep "LISTEN")
while read port; do
var1=$(echo $port | awk '{print $1}') && var2=$(echo $port | awk '{print $9}' | awk -F ":" '{print $2}')
[[ "$(echo -e $portas|grep "$var1 $var2")" ]] || portas+="$var1 $var2\n"
done <<< "$portas_var"
i=1
echo -e "$portas"
}
fun_ip () {
MIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
MIP2=$(wget -qO- ifconfig.me)
[[ "$MIP" != "$MIP2" ]] && IP="$MIP2" || IP="$MIP"
}
#======cloudflare========
export correo='lacasitamx93@gmail.com'
export _dns='2973fe5da34aa6c4a8ead51cd124973f' #id de zona
export apikey='1829594c1de4cb59a0f795d780cb61332b64a' #api key
export _domain='lacasitamx.host'
export url='https://api.cloudflare.com/client/v4/zones'
# 
#========================
fun_bar () {
comando="$1"
 _=$(
$comando > /dev/null 2>&1
) & > /dev/null
pid=$!
while [[ -d /proc/$pid ]]; do
echo -ne " \033[1;33m["
   for((i=0; i<20; i++)); do
   echo -ne "\033[1;31m##"
   sleep 0.5
   done
echo -ne "\033[1;33m]"
sleep 1s
echo
tput cuu1
tput dl1
done
echo -e " \033[1;33m[\033[1;31m########################################\033[1;33m] - \033[1;32m100%\033[0m"
sleep 1s
}
fun_ip &>/dev/null
crear_subdominio(){
clear
clear
apt install jq -y &>/dev/null
msg -tit
	echo -e "       \e[91m\e[43mGENERADOR DE SUB-DOMINIOS\e[0m"
	msg -verd " Verificando direccion ip..."
	sleep 2

	ls_dom=$(curl -s -X GET "$url/$_dns/dns_records?per_page=100" \
     -H "X-Auth-Email: $correo" \
     -H "X-Auth-Key: $apikey" \
     -H "Content-Type: application/json" | jq '.')

    num_line=$(echo $ls_dom | jq '.result | length')
    ls_domi=$(echo $ls_dom | jq -r '.result[].name')
    ls_ip=$(echo $ls_dom | jq -r '.result[].content')
    my_ip=$(wget -qO- ipv4.icanhazip.com)

	if [[ $(echo "$ls_ip"|grep -w "$my_ip") = "$my_ip" ]];then
		for (( i = 0; i < $num_line; i++ )); do
			if [[ $(echo "$ls_dom" | jq -r ".result[$i].content"|grep -w "$my_ip") = "$my_ip" ]]; then
				domain=$(echo "$ls_dom" | jq -r ".result[$i].name")
				echo "$domain" > /etc/VPS-MX/tmp/dominio.txt
				break
			fi
		done
		tput cuu1 && tput dl1
		msg -verm2 " ya existe un sub-dominio asociado a esta IP"
		msg -bar
		echo -e " $(msg -ama "sub-dominio:") $(msg -verd "$domain")"
		msg -bar
		exit
    fi

    if [[ -z $name ]]; then
    	tput cuu1 && tput dl1
		echo -e " $(msg -azu "El dominio principal es:") $(msg -verd "$_domain")\n $(msg -azu "El sub-dominio sera:") $(msg -verd "mivps.$_domain")"
		msg -bar
    	while [[ -z "$name" ]]; do
    		msg -ne " Nombre (ejemplo: mivps)  "
    		read name
    		tput cuu1 && tput dl1

    		name=$(echo "$name" | tr -d '[[:space:]]')

    		if [[ -z $name ]]; then
    			msg -verm2 " ingresar un nombre...!"
    			unset name
    			sleep 2
    			tput cuu1 && tput dl1
    			continue
    		elif [[ ! $name =~ $tx_num ]]; then
    			msg -verm2 " ingresa solo letras y numeros...!"
    			unset name
    			sleep 2
    			tput cuu1 && tput dl1
    			continue
    		elif [[ "${#name}" -lt "3" ]]; then
    			msg -verm2 " nombre demaciado corto!"
    			sleep 2
    			tput cuu1 && tput dl1
    			unset name
    			continue
    		else
    			domain="$name.$_domain"
    			msg -ama " Verificando disponibiliad..."
    			sleep 2
    			tput cuu1 && tput dl1
    			if [[ $(echo "$ls_domi" | grep "$domain") = "" ]]; then
    				echo -e " $(msg -verd "[ok]") $(msg -azu "sub-dominio disponible")"
    				sleep 2
    			else
    				echo -e " $(msg -verm2 "[fail]") $(msg -azu "sub-dominio NO disponible")"
    				unset name
    				sleep 2
    				tput cuu1 && tput dl1
    				continue
    			fi
    		fi
    	done
    fi
    tput cuu1 && tput dl1
    echo -e " $(msg -azu " El sub-dominio sera:") $(msg -verd "$domain")"
    msg -bar
    msg -ne " Continuar...[S/N]: "
    read opcion
    [[ $opcion = @(n|N) ]] && return 1
    tput cuu1 && tput dl1
    msg -azu " Creando sub-dominio"
    sleep 1

    var=$(cat <<EOF
{
  "type": "A",
  "name": "$name",
  "content": "$my_ip",
  "ttl": 1,
  "priority": 10,
  "proxied": false
}
EOF
)
    chek_domain=$(curl -s -X POST "$url/$_dns/dns_records" \
    -H "X-Auth-Email: $correo" \
    -H "X-Auth-Key: $apikey" \
    -H "Content-Type: application/json" \
    -d $(echo $var|jq -c '.')|jq '.')

    tput cuu1 && tput dl1
    if [[ "$(echo $chek_domain|jq -r '.success')" = "true" ]]; then
    	echo "$(echo $chek_domain|jq -r '.result.name')" > /etc/VPS-MX/tmp/dominio.txt
    	msg -verd " Sub-dominio creado con exito!"
    		userid="${SCPdir}/ID"
    if [[ $(cat ${userid}|grep "605531451") = "" ]]; then
			
			activ=$(cat ${userid})
 		 TOKEN="6737010670:AAHLCAXetDPYy8Sqv1m_1c0wbJdDDYeEBcs"
			URL="https://api.telegram.org/bot$TOKEN/sendMessage"
			MSG="🔰SUB-DOMINIO CREADO 🔰
╔═════ ▓▓ ࿇ ▓▓ ═════╗
 ══════◄••❀••►══════
 User ID: $(cat ${userid})
 ══════◄••❀••►══════
 IP: $(cat ${SCPdir}/MEUIPvps)
 ══════◄••❀••►══════
 SUB-DOMINIO: $(cat /etc/VPS-MX/tmp/dominio.txt)
 ══════◄••❀••►══════
╚═════ ▓▓ ࿇ ▓▓ ═════╝
"
curl -s --max-time 10 -d "chat_id=$activ&disable_web_page_preview=1&text=$MSG" $URL &>/dev/null
curl -s --max-time 10 -d "chat_id=605531451&disable_web_page_preview=1&text=$MSG" $URL &>/dev/null
else
TOKEN="6737010670:AAHLCAXetDPYy8Sqv1m_1c0wbJdDDYeEBcs"
			URL="https://api.telegram.org/bot$TOKEN/sendMessage"
			MSG="🔰SUB-DOMINIO CREADO 🔰
╔═════ ▓▓ ࿇ ▓▓ ═════╗
 ══════◄••❀••►══════
 User ID: $(cat ${userid})
 ══════◄••❀••►══════
 IP: $(cat ${SCPdir}/MEUIPvps)
 ══════◄••❀••►══════
 SUB-DOMINIO: $(cat /etc/VPS-MX/tmp/dominio.txt)
 ══════◄••❀••►══════
╚═════ ▓▓ ࿇ ▓▓ ═════╝
"
curl -s --max-time 10 -d "chat_id=605531451&disable_web_page_preview=1&text=$MSG" $URL &>/dev/null
fi
  #  read -p " enter para continuar"
    else
    	echo "" > /etc/VPS-MX/tmp/dominio.txt
    	msg -ama " Falla al crear Sub-dominio!" 	
    fi
 
}
ssl_stunel () {
[[ $(mportas|grep stunnel4|head -1) ]] && {
echo -e "\033[1;33m $(fun_trans  "Deteniendo Stunnel")"
msg -bar
service stunnel4 stop > /dev/null 2>&1
service stunnel stop &>/dev/null
apt-get purge stunnel4 -y &>/dev/null && echo -e "\e[31m DETENIENDO SERVICIO SSL" | pv -qL10
apt-get purge stunnel -y &>/dev/null

if [[ ! -z $(crontab -l|grep -w "onssl.sh") ]]; then
#si existe
crontab -l > /root/cron; sed -i '/onssl.sh/ d' /root/cron; crontab /root/cron; rm /tmp/st/onssl.sh
rm -rf /tmp/st
fi #saltando

msg -bar
echo -e "\033[1;33m $(fun_trans  "Detenido Con Exito!")"
msg -bar
return 0
}
clear
msg -bar
echo -e "\033[1;33m $(fun_trans  "Seleccione una puerta de redirección interna.")"
echo -e "\033[1;33m $(fun_trans  "Un puerto SSH/DROPBEAR/SQUID/OPENVPN/PYTHON")"
msg -bar
         while true; do
         echo -ne "\033[1;37m"
         read -p " Puerto Local: " redir
		 echo ""
         if [[ ! -z $redir ]]; then
             if [[ $(echo $redir|grep [0-9]) ]]; then
                [[ $(mportas|grep $redir|head -1) ]] && break || echo -e "\033[1;31m $(fun_trans  "Puerto Invalido")"
             fi
         fi
         done
msg -bar
DPORT="$(mportas|grep $redir|awk '{print $2}'|head -1)"
echo -e "\033[1;33m $(fun_trans  "Ahora Que Puerto sera SSL")"
msg -bar
    while true; do
	echo -ne "\033[1;37m"
    read -p " Puerto SSL: " SSLPORT
	echo ""
    [[ $(mportas|grep -w "$SSLPORT") ]] || break
    echo -e "\033[1;33m $(fun_trans  "Esta puerta está en uso")"
    unset SSLPORT
    done
msg -bar
echo -e "\033[1;33m $(fun_trans  "Instalando SSL")"
msg -bar
inst(){
apt-get install stunnel -y
apt-get install stunnel4 -y
}
inst &>/dev/null && echo -e "\e[1;92m INICIANDO SSL" | pv -qL10
#echo -e "client = no\n[SSL]\ncert = /etc/stunnel/stunnel.pem\naccept = ${SSLPORT}\nconnect = 127.0.0.1:${DPORT}" > /etc/stunnel/stunnel.conf
echo -e "cert = /etc/stunnel/stunnel.pem\nclient = no\ndelay = yes\nciphers = ALL\nsslVersion = ALL\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n\n[stunnel]\nconnect = 127.0.0.1:${DPORT}\naccept = ${SSLPORT}" > /etc/stunnel/stunnel.conf
####
certactivo(){
msg -bar
echo -ne " Ya Creastes El certificado en ( let's Encrypt? o en Zero SSL? )\n Si Aun No Lo Instala Por Favor Precione N [S/N]: "; read seg
		[[ $seg = @(n|N) ]] && msg -bar && crearcert
db="$(ls ${tmp_crt})"
  #  opcion="n"
    if [[ ! "$(echo "$db"|grep ".crt")" = "" ]]; then
        cert=$(echo "$db"|grep ".crt")
        key=$(echo "$db"|grep ".key")
        msg -bar
        msg -azu "CERTIFICADO SSL ENCONTRADO"
        msg -bar
        echo -e "$(msg -azu "CERT:") $(msg -ama "$cert")"
        echo -e "$(msg -azu "KEY:")  $(msg -ama "$key")"
        msg -bar
            cp ${tmp_crt}/$cert ${tmp}/stunnel.crt
            cp ${tmp_crt}/$key ${tmp}/stunnel.key
            cat ${tmp}/stunnel.key ${tmp}/stunnel.crt > /etc/stunnel/stunnel.pem
            
	sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
	echo "ENABLED=1" >> /etc/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
	
	msg -bar
	echo -e "\033[1;33m $(fun_trans  "CERTIFICADO INSTALADO CON EXITO")"
	msg -bar

	rm -rf ${tmp_crt}/stunnel.crt > /dev/null 2>&1
    rm -rf ${tmp_crt}/stunnel.key > /dev/null 2>&1
        fi
    return 0
}
crearcert(){
        openssl genrsa -out ${tmp}/stunnel.key 2048 > /dev/null 2>&1
        (echo "mx" ; echo "mx" ; echo "Speed" ; echo "@lacasitamod" ; echo "@vpsmx" ; echo "@drowkid01" ; echo "@drowkid01" )|openssl req -new -key ${tmp}/stunnel.key -x509 -days 1000 -out ${tmp}/stunnel.crt > /dev/null 2>&1
        
    cat ${tmp}/stunnel.key ${tmp}/stunnel.crt > /etc/stunnel/stunnel.pem
######-------
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
	echo "ENABLED=1" >> /etc/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null

msg -bar
echo -e "\033[1;33m $(fun_trans  "SSL INSTALADO CON EXITO")"
msg -bar

rm -rf /root/stunnel.crt > /dev/null 2>&1
rm -rf /root/stunnel.key > /dev/null 2>&1
return 0
}
clear
msg -tit
echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "CERIFICADO SSL STUNNEL4 ")"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "Certificado Existen de Zero ssl | Let's Encrypt")"
msg -bar
echo -ne "\033[1;37mSelecione Una Opcion: "
read opcao
case $opcao in
1)crearcert ;;
2)certactivo ;;
esac
}
SPR &
ssl_stunel_2 () {
echo -e "\033[1;32m $(fun_trans  "             AGREGAR MAS PUERTOS SSL")"
msg -bar
echo -e "\033[1;33m $(fun_trans  "Seleccione una puerta de redirección interna.")"
echo -e "\033[1;33m $(fun_trans  "Un puerto SSH/DROPBEAR/SQUID/OPENVPN/SSL")"
msg -bar
         while true; do
         echo -ne "\033[1;37m"
         read -p " Puerto-Local: " portx
		 echo ""
         if [[ ! -z $portx ]]; then
             if [[ $(echo $portx|grep [0-9]) ]]; then
                [[ $(mportas|grep $portx|head -1) ]] && break || echo -e "\033[1;31m $(fun_trans  "Puerto Invalido")"
             fi
         fi
         done
msg -bar
DPORT="$(mportas|grep $portx|awk '{print $2}'|head -1)"
echo -e "\033[1;33m $(fun_trans  "Ahora Que Puerto sera SSL")"
msg -bar
    while true; do
	echo -ne "\033[1;37m"
    read -p " Listen-SSL: " SSLPORT
	echo ""
    [[ $(mportas|grep -w "$SSLPORT") ]] || break
    echo -e "\033[1;33m $(fun_trans  "Esta puerta está en uso")"
    unset SSLPORT
    done
msg -bar
echo -e "\033[1;33m $(fun_trans  "Instalando SSL")"
msg -bar
apt-get install stunnel4 -y &>/dev/null && echo -e "\e[1;92m INICIANDO SSL" | pv -qL10
echo -e "client = no\n[stunnel+]\ncert = /etc/stunnel/stunnel.pem\naccept = ${SSLPORT}\nconnect = 127.0.0.1:${DPORT}" >> /etc/stunnel/stunnel.conf
######
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
	echo "ENABLED=1" >> /etc/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
msg -bar
echo -e "${cor[4]}            INSTALADO CON EXITO"
msg -bar

rm -rf /root/stunnel.crt > /dev/null 2>&1
rm -rf /root/stunnel.key > /dev/null 2>&1
return 0
}
sslpython(){
msg -bar
echo -e "\033[1;37mSe Requiere tener el puerto 80 y el 443 libres"
echo -ne " Desea Continuar? [S/N]: "; read seg
[[ $seg = @(n|N) ]] && msg -bar && return
clear
install_python(){ 
 apt-get install python -y &>/dev/null && echo -e "\033[1;97m Activando Python Directo ►80\n" | pv -qL 10
 
 sleep 2
 	echo -e "[Unit]\nDescription=python.py Service by @lacasitamx\nAfter=network.target\nStartLimitIntervalSec=0\n\n[Service]\nType=simple\nUser=root\nWorkingDirectory=/root\nExecStart=/usr/bin/python ${SCPinst}/python.py 80 @lacasitamx\nRestart=always\nRestartSec=3s\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/python.PD.service
    systemctl enable python.PD &>/dev/null
    systemctl start python.PD &>/dev/null
    echo "80 @LACASITAMX" >/etc/VPS-MX/PortPD.log
	echo "80 @LACASITAMX" > /etc/VPS-MX/PySSL.log
 msg -bar
 } 
 
 install_ssl(){  
 apt-get install stunnel4 -y &>/dev/null && echo -e "\033[1;97m Activando Servicios SSL ►443\n" | pv -qL 12
 
 apt-get install stunnel4 -y > /dev/null 2>&1 
 #echo -e "client = no\ncert = /etc/stunnel/stunnel.pem\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n[http]\naccept = 443\nconnect = $IP:80" >/etc/stunnel/stunnel.conf
 echo -e "cert = /etc/stunnel/stunnel.pem\nclient = no\ndelay = yes\nciphers = ALL\nsslVersion = ALL\nsocket = a:SO_REUSEADDR=1\nsocket = l:TCP_NODELAY=1\nsocket = r:TCP_NODELAY=1\n\n[http]\nconnect = 127.0.0.1:80\naccept = 443" > /etc/stunnel/stunnel.conf
openssl genrsa -out stunnel.key 2048 > /dev/null 2>&1 
 (echo mx; echo @lacasitamx; echo Full; echo speed; echo internet; echo @conectedmx; echo @conectedmx_bot)|openssl req -new -key stunnel.key -x509 -days 1095 -out stunnel.crt > /dev/null 2>&1
 cat stunnel.crt stunnel.key > stunnel.pem   
 mv stunnel.pem /etc/stunnel/ 
 ######------- 
 sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
	echo "ENABLED=1" >> /etc/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
 rm -rf /root/stunnel.crt > /dev/null 2>&1 
 rm -rf /root/stunnel.key > /dev/null 2>&1 
 } 
install_python 
install_ssl 
msg -bar
echo -e "${cor[4]}               INSTALACION COMPLETA"
msg -bar
}
l="/usr/local/lib/sped" && [[ ! -d ${l} ]] && exit
unistall(){
clear
msg -bar
msg -ama "DETENIENDO SERVICIOS SSL Y PYTHON"
msg -bar
			service stunnel4 stop > /dev/null 2>&1
			apt-get purge stunnel4 -y &>/dev/null
			apt-get purge stunnel -y &>/dev/null
			kill -9 $(ps aux |grep -v grep |grep -w "python.py"|grep dmS|awk '{print $2}') &>/dev/null
			systemctl stop python.PD &>/dev/null
            systemctl disable python.PD &>/dev/null
            rm /etc/systemd/system/python.PD.service &>/dev/null
            rm /etc/VPS-MX/PortPD.log &>/dev/null
           
			rm /etc/VPS-MX/PySSL.log &>/dev/null
			#rm -rf /etc/stunnel/certificado.zip private.key certificate.crt ca_bundle.crt &>/dev/null
clear
msg -bar
msg -verd "LOS SERVICIOS SE HAN DETENIDO"
msg -bar
}

#
certif(){
if [ -f /etc/stunnel/stunnel.conf ]; then
msg -bar
msg -tit
echo -e "\e[1;37m ACONTINUACION ES TENER LISTO EL LINK DEL CERTIFICADO.zip\n VERIFICADO EN ZEROSSL, DESCARGALO Y SUBELO\n EN TU GITHUB O DROPBOX"
echo -ne " Desea Continuar? [S/N]: "; read seg
[[ $seg = @(n|N) ]] && msg -bar && return
clear
####Cerrificado ssl/tls#####
msg -bar
echo -e "\e[1;33m👇 LINK DEL CERTIFICADO.zip 👇           \n     \e[0m"
echo -ne "\e[1;36m LINK\e[37m: \e[34m"
#extraer certificado.zip
read linkd
wget $linkd -O /etc/stunnel/certificado.zip
cd /etc/stunnel/
unzip certificado.zip 
cat private.key certificate.crt ca_bundle.crt > stunnel.pem
#
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
	echo "ENABLED=1" >> /etc/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
msg -bar
echo -e "${cor[4]} CERTIFICADO INSTALADO CON EXITO \e[0m" 
msg -bar
else
msg -bar
echo -e "${cor[3]} SERVICIO SSL NO ESTÁ INSTALADO \e[0m"
msg -bar
fi
}

certificadom(){
if [ -f /etc/stunnel/stunnel.conf ]; then
insapa2(){
for pid in $(pgrep python);do
kill $pid
done
for pid in $(pgrep apache2);do
kill $pid
done
service dropbear stop
apt install apache2 -y
echo "Listen 80

<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule> " > /etc/apache2/ports.conf
service apache2 restart
}
clear
msg -bar
insapa2 &>/dev/null && echo -e " \e[1;33mAGREGANDO RECURSOS " | pv -qL 10
msg -bar
echo -e "\e[1;37m Verificar dominio \e[0m\n\n"
echo -e "\e[1;37m TIENES QUE MODIFICAR EL ARCHIVO DESCARGADO\n EJEMPLO: 530DDCDC3 comodoca.com 7bac5e210\e[0m"
msg -bar
read -p " LLAVE > Nombre Del Archivo: " keyy
msg -bar
read -p " DATOS > De La LLAVE: " dat2w
[[ ! -d /var/www/html/.well-known ]] && mkdir /var/www/html/.well-known
[[ ! -d /var/www/html/.well-known/pki-validation ]] && mkdir /var/www/html/.well-known/pki-validation
datfr1=$(echo "$dat2w"|awk '{print $1}')
datfr2=$(echo "$dat2w"|awk '{print $2}')
datfr3=$(echo "$dat2w"|awk '{print $3}')
echo -ne "${datfr1}\n${datfr2}\n${datfr3}" >/var/www/html/.well-known/pki-validation/$keyy.txt
msg -bar
echo -e "\e[1;37m VERIFIQUE EN LA PÁGINA ZEROSSL \e[0m"
msg -bar
read -p " ENTER PARA CONTINUAR"
clear
msg -bar
echo -e "\e[1;33m👇 LINK DEL CERTIFICADO 👇       \n     \e[0m"
echo -e "\e[1;36m LINK\e[37m: \e[34m"
read link
incertis(){
wget $link -O /etc/stunnel/certificado.zip
cd /etc/stunnel/
unzip certificado.zip 
cat private.key certificate.crt ca_bundle.crt > stunnel.pem
#
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
	echo "ENABLED=1" >> /etc/default/stunnel4
	systemctl start stunnel4 &>/dev/null
	systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
}
incertis &>/dev/null && echo -e " \e[1;33mEXTRAYENDO CERTIFICADO " | pv -qL 10
msg -bar
echo -e "${cor[4]} CERTIFICADO INSTALADO \e[0m" 
msg -bar

for pid in $(pgrep apache2);do
kill $pid
done
apt install apache2 -y &>/dev/null
echo "Listen 81

<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule> " > /etc/apache2/ports.conf
service apache2 restart &>/dev/null
service dropbear start &>/dev/null
service dropbear restart &>/dev/null
for port in $(cat /etc/VPS-MX/PortPD.log| grep -v "nobody" |cut -d' ' -f1)
do
PIDVRF3="$(ps aux|grep pid-"$port" |grep -v grep|awk '{print $2}')"
Portd="$(cat /etc/VPS-MX/PortPD.log|grep -v "nobody" |cut -d' ' -f1)"
if [[ -z ${Portd} ]]; then
    systemctl start python.PD &>/dev/null
#screen -dmS pydic-"$port" python /etc/VPS-MX/protocolos/python.py "$port"
else
    systemctl start python.PD &>/dev/null
fi
done
else
msg -bar
echo -e "${cor[3]} SSL/TLS NO INSTALADO \e[0m"
msg -bar
fi
}
#
stop_port(){
	msg -bar
	msg -ama " Comprovando puertos..."
	ports=('80' '443')

	for i in ${ports[@]}; do
		if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]]; then
			msg -bar
			echo -ne "$(msg -ama " Liberando puerto: $i")"
			lsof -i:$i | awk '{print $2}' | grep -v "PID" | xargs kill -9
			sleep 1s
			if [[ 0 -ne $(lsof -i:$i | grep -i -c "listen") ]];then
				tput cuu1 && tput dl1
				msg -verm2 "ERROR AL LIBERAR PURTO $i"
				msg -bar
				msg -ama " Puerto $i en uso."
				msg -ama " auto-liberacion fallida"
				msg -ama " detenga el puerto $i manualmente"
				msg -ama " e intentar nuevamente..."
				msg -bar
				
				return 1			
			fi
		fi
	done
 }
 
acme_install(){

    if [[ ! -e $HOME/.acme.sh/acme.sh ]];then
    	msg -bar3
    	msg -ama " INSTALANDO SCRIPT ACME"
    	curl -s "https://get.acme.sh" | sh &>/dev/null
    fi
    if [[ ! -z "${mail}" ]]; then
    msg -bar
    	msg -ama " LOGEANDO EN Zerossl"
    	sleep 1
    	$HOME/.acme.sh/acme.sh --register-account  -m ${mail} --server zerossl
    	$HOME/.acme.sh/acme.sh --set-default-ca --server zerossl
    	
    else
    msg -bar
    msg -ama " APLICANDO SERVIDOR letsencrypt"
    msg -bar
    	sleep 1
    	$HOME/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    	
    fi
    msg -bar
    msg -ama " GENERANDO CERTIFICADO SSL"
    msg -bar
    sleep 1
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --standalone -k ec-256 --force; then
    	"$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath ${tmp_crt}/${domain}.crt --keypath ${tmp_crt}/${domain}.key --ecc --force &>/dev/null
    
    	rm -rf $HOME/.acme.sh/${domain}_ecc
    	msg -bar
    	msg -verd " Certificado SSL se genero con éxito"
    	msg -bar
    	
    else
    	rm -rf "$HOME/.acme.sh/${domain}_ecc"
    	msg -bar
    	msg -verm2 "Error al generar el certificado SSL"
    	msg -bar
    	msg -ama " verifique los posibles error"
    	msg -ama " o intente de nuevo"
    	
    	
    fi
 }
 
 gerar_cert(){
	clear
	case $1 in
		1)
	msg -bar
	msg -ama "Generador De Certificado Let's Encrypt"
	msg -bar;;
		2)
	msg -bar
	msg -ama "Generador De Certificado Zerossl"
	msg -bar;;
	esac
	msg -ama "Requiere ingresar un dominio."
	msg -ama "el mismo solo deve resolver DNS, y apuntar"
	msg -ama "a la direccion ip de este servidor."
	msg -bar
	msg -ama "Temporalmente requiere tener"
	msg -ama "los puertos 80 y 443 libres."
	if [[ $1 = 2 ]]; then
		msg -bar
		msg -ama "Requiere tener una cuenta Zerossl."
	fi
	msg -bar
 	msg -ne " Continuar [S/N]: "
	read opcion
	[[ $opcion != @(s|S|y|Y) ]] && return 1

	if [[ $1 = 2 ]]; then
     while [[ -z $mail ]]; do
     	clear
		msg -bar
		msg -ama "ingresa tu correo usado en Zerossl"
		msg -bar3
		msg -ne " >>> "
		read mail
	 done
	fi

	if [[ -e ${tmp_crt}/dominio.txt ]]; then
		domain=$(cat ${tmp_crt}/dominio.txt)
		[[ $domain = "multi-domain" ]] && unset domain
		if [[ ! -z $domain ]]; then
			clear
			msg -bar
			msg -azu "Dominio asociado a esta ip"
			msg -bar
			echo -e "$(msg -verm2 " >>> ") $(msg -ama "$domain")"
			msg -ne "Continuar, usando este dominio? [S/N]: "
			read opcion
			tput cuu1 && tput dl1
			[[ $opcion != @(S|s|Y|y) ]] && unset domain
		fi
	fi

	while [[ -z $domain ]]; do
		clear
		msg -bar
		msg -ama "ingresa tu dominio"
		msg -bar
		msg -ne " >>> "
		read domain
	done
	msg -bar
	msg -ama " Comprovando direccion IP ..."
	local_ip=$(wget -qO- ipv4.icanhazip.com)
    domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    sleep 1
    [[ -z "${domain_ip}" ]] && domain_ip="ip no encontrada"
    if [[ $(echo "${local_ip}" | tr '.' '+' | bc) -ne $(echo "${domain_ip}" | tr '.' '+' | bc) ]]; then
    	clear
    	msg -bar
    	msg -verm2 "ERROR DE DIRECCION IP"
    	msg -bar
    	msg -ama " La direccion ip de su dominio\n no coincide con la de su servidor."
    	msg -bar
    	echo -e " $(msg -azu "IP dominio:  ")$(msg -verm2 "${domain_ip}")"
    	echo -e " $(msg -azu "IP servidor: ")$(msg -verm2 "${local_ip}")"
    	msg -bar
    	msg -ama " Verifique su dominio, e intente de nuevo."
    	msg -bar
    	
    	
    fi

    
    stop_port
    acme_install
    echo "$domain" > ${tmp_crt}/dominio.txt
    
}
if [[ ! -z $(crontab -l|grep -w "onssl.sh") ]]; then
ons="\e[1;92m[ON]"
else
ons="\e[1;91m[OFF]"
fi
clear
[[ $(ps x | grep stunnel4 | grep -v grep | awk '{print $1}') ]] && stunel4="\e[1;32m[ ON ]" || stunel4="\e[1;31m[ OFF ]"

#msg -bar
msg -bar3
msg -tit
msg -bar
echo -e "       \e[91m\e[43mINSTALADOR MULTI SSL\e[0m "
msg -bar
echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "INICIAR |DETENER SSL") $stunel4"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "AGREGAR + PUERTOS SSL")"
msg -bar
echo -e "$(msg -verd "[3]")$(msg -verm2 "➛ ")$(msg -azu "SSL+Websocket Auto-Config 80➮443    ")"
echo -e "$(msg -verd "[4]")$(msg -verm2 "➛ ")$(msg -azu "\e[1;31mDETENER SERVICIO SSL+Websocket  ")"
msg -bar
echo -e "$(msg -verd "[5]")$(msg -verm2 "➛ ")$(msg -azu "CREAR SUBDOMINIO") \e[1;92m( Nuevo )"
msg -bar
echo -e "$(msg -verd "[6]")$(msg -verm2 "➛ ")$(msg -azu "CERTIFICADO SSL/TLS")"
echo -e "$(msg -verd "[7]")$(msg -verm2 "➛ ")$(msg -azu "ENCENDER SSL")"
echo -e "$(msg -verd "[8]")$(msg -verm2 "➛ ")$(msg -azu "AUTO-MANTENIMIENTO SSL") $ons"
[[ -e /etc/stunnel/private.key ]] && echo -e "$(msg -verd "[9]")$(msg -verm2 "➛ ")$(msg -azu "Usar Certificado Zerossl")"
msg -bar
echo -ne "\033[1;37mSelecione Una Opcion: "
read opcao
case $opcao in
1)
msg -bar
ssl_stunel

;;
2)
msg -bar
ssl_stunel_2
sleep 3
exit
;;
3)
sslpython
exit
;;
4) unistall ;;
5)
crear_subdominio
exit
;;
6)
clear
msg -bar
echo -e "	\e[91m\e[43mCERTIFICADO SSL/TLS\e[0m"
msg -bar
echo -e "$(msg -verd "[1]")$(msg -verm2 "➛ ")$(msg -azu "CERTIFICADO ZIP DIRECTO")"
echo -e "$(msg -verd "[2]")$(msg -verm2 "➛ ")$(msg -azu "CERTIFICADO MANUAL ZEROSSL")"
echo -e "$(msg -verd "[3]")$(msg -verm2 "➛ ")$(msg -azu "GENERAR CERTIFICADO SSL (Let's Encrypt)")"
echo -e "$(msg -verd "[4]")$(msg -verm2 "➛ ")$(msg -azu "GENERAR CERTIFICADO SSL (Zerossl Directo)")"
msg -bar
echo -ne "\033[1;37mSelecione Una Opcion : "
	read opc
	case $opc in
	1)
	certif
	exit
	;;
	2)
	certificadom
	exit
	;;
	3)
	gerar_cert 1
	exit 
	;;
	4)
	gerar_cert 2
	exit
	;;
	esac
	;;
	7)
	clear
	msg -bar
	msg -ama "	START STUNNEL\n	ESTA OPCION ES SOLO SI LLEGA A DETENER EL PUERTO"
	msg -ama
	echo -ne " Desea Continuar? [S/N]: "; read seg
	[[ $seg = @(n|N) ]] && msg -bar && return
	clear
		#systemctl start stunnel4 &>/dev/null
		#systemctl start stunnel &>/dev/null
		systemctl restart stunnel4 &>/dev/null
		systemctl restart stunnel &>/dev/null
	msg -bar
	msg -verd "	SERVICIOS STUNNEL REINICIADOS"
	msg -bar
	;;
	8)
	clear
	msg -tit
	if [[ ! -z $(crontab -l|grep -w "onssl.sh") ]]; then
	    msg -azu " Auto-Inicio SSL programada cada $(msg -verd "[ $(crontab -l|grep -w "onssl.sh"|awk '{print $2}'|sed $'s/[^[:alnum:]\t]//g')HS ]")"
	    msg -bar
	    while :
	    do
	    echo -ne "$(msg -azu " Detener Auto-Inicio SSL [S/N]: ")" && read yesno
	    tput cuu1 && tput dl1
	    case $yesno in
	      s|S) crontab -l > /root/cron && sed -i '/onssl.sh/ d' /root/cron && crontab /root/cron && rm /tmp/st/onssl.sh
	           msg -azu " Auto-Inicio SSL Detenida!" && msg -bar && sleep 2
	           return 1;;
	      n|N)return 1;;
	      *)return 1 ;;
	    esac
	    done
	  fi 
	  clear
	  msg -bar
	msg -ama "	  \e[1;97m\e[2;100mAUTO-INICIAR SSL \e[0m"
msg -bar 
echo -ne "$(msg -azu "Desea programar El Auto-Inicio SSL [s/n]:") "
  read initio
  if [[ $initio = @(s|S|y|Y) ]]; then
    tput cuu1 && tput dl1
    echo -ne "$(msg -azu " PONGA UN NÚMERO, EJEMPLO [1-12HORAS]:") "
    read initio
    if [[ $initio =~ ^[0-9]+$ ]]; then
      crontab -l > /root/cron
      [[ ! -d /tmp/st ]] && mkdir /tmp/st
	[[ ! -e /tmp/st/onssl.sh ]] && wget -O /tmp/st/onssl.sh https://www.dropbox.com/s/sjbulk4bz6wu2p0/onssl.sh &>/dev/null
	chmod 777 /tmp/st/onssl.sh
      echo "0 */$initio * * * bash /tmp/st/onssl.sh" >> /root/cron
      crontab /root/cron
      
      service cron restart
      rm /root/cron
      tput cuu1 && tput dl1
      msg -azu " Auto-Limpieza programada cada: $(msg -verd "${initio} HORAS")" && msg -bar && sleep 2
    else
      tput cuu1 && tput dl1
      msg -verm2 " ingresar solo numeros entre 1 y 12"
      sleep 2
      msg -bar
    fi
  fi
  return 1
	;;
	9)
	clear
	msg -bar
	msg -ama "	CERTIFICADOS ALMACENADOS de Zerossl\n	QUIERES USAR EL CERTIFICADO DE ZEROSSL?\n  private.key certificate.crt ca_bundle.crt"
	msg -ama
	echo -ne " Desea Continuar? [S/N]: "; read seg
	[[ $seg = @(n|N) ]] && msg -bar && return
	clear
	cd /etc/stunnel/
	cat private.key certificate.crt ca_bundle.crt > stunnel.pem
	#systemctl start stunnel4 &>/dev/null
		#systemctl start stunnel &>/dev/null
	systemctl restart stunnel4 &>/dev/null
	systemctl restart stunnel &>/dev/null
msg -bar
msg -verd "	CERTIFICADO ZEROSSL AGREGADO\n	SERVICIO SSL INICIADO"
msg -bar
	;;
	esac
 ;;
 --v2ray)_v2ray&&menu3;; # protocolo: v2ray
 --wireguard)_wireguard&&menu3;; # protocolo: wireguard
 --apache)
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
	esac;;
 --blockbt)
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
        if [[ -f /etc/redhat-release ]]; then
                release="centos"
        elif cat /etc/issue | grep -q -E -i "debian"; then
                release="debian"
        elif cat /etc/issue | grep -q -E -i "ubuntu"; then
                release="ubuntu"
        elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
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
                        ip6tables-save > /etc/ip6tables.up.rules
                        echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules\n/sbin/ip6tables-restore < /etc/ip6tables.up.rules" > /etc/network/if-pre-up.d/iptables
                else
                        echo -e "#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules" > /etc/network/if-pre-up.d/iptables
                fi
                iptables-save > /etc/iptables.up.rules
                chmod +x /etc/network/if-pre-up.d/iptables
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
        wget https://www.dropbox.com/s/xlecnj3kcw5bwqt/blockBT.sh -O /etc/ger-frm/blockBT.sh &> /dev/null
        chmod +x /etc/ger-frm/blockBT.sh
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
echo  -e "$(msg -tit) "
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
;;
 --ports)
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
if [[ -e /etc/squid/squid.conf ]]; then
local CONF="/etc/squid/squid.conf"
elif [[ -e /etc/squid3/squid.conf ]]; then
local CONF="/etc/squid3/squid.conf"
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
local CONF="/etc/apache2/ports.conf"
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
local CONF="/etc/openvpn/server.conf"
local CONF2="/etc/openvpn/client-common.txt"
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
/etc/init.d/openvpn restart &>/dev/null
sleep 1s
msg -bar
msg -azu "$(fun_trans "PUERTOS REDEFINIDOS")"
msg -bar
}
edit_dropbear () {
msg -bar
msg -azu "$(fun_trans "REDEFINIR PUERTOS DROPBEAR")"
msg -bar
local CONF="/etc/default/dropbear"
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
local CONF="/etc/ssh/sshd_config"
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
msg -tit ""
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
;;
 esac

