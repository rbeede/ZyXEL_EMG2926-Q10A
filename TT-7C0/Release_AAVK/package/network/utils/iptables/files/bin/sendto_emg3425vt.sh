#!/bin/sh

. /etc/functions.sh
include /lib/config

config_load parental_monitor
config_get sent rule$1 sent 
Network_Name=""

check_interface(){

	for var in ath0 ath10 ath1 ath2 ath3 ath11 ath12 ath13
	do
		[ -n "$(wlanconfig $var list | grep $1)" ] && {
			Network_Name=$(iwconfig $var | grep ESSID | awk -F '"' '{print $2}')
			break
		} || {
			Network_Name="Ethernet"
		}
	done
	
}

##$1 child name
##$2 Device name
##$3 Network Name
mail_content_english(){
	echo "From: Home Router" > /var/mail
	echo "To: Dear Parent" >> /var/mail
	echo "Subject: Connexion notification : $1 " >> /var/mail
	echo "Dear Parent," >> /var/mail
	echo "" >> /var/mail
	echo "	Device $2 is now connected to the network $3 " >> /var/mail
	echo "" >> /var/mail
}
mail_content_french(){
	echo "From: Home Router" > /var/mail
	echo "To: Dear Parent" >> /var/mail
	echo "Subject: Avis de connection : $1 " >> /var/mail
	echo "Dear Parent," >> /var/mail
	echo "" >> /var/mail
	echo "	L'appareil $2 est maintenant connecte au reseau $3 " >> /var/mail
	echo "" >> /var/mail

}

if [ "$sent" -eq 0 ]; then
	config_get mac rule$1 mac
	config_get email rule$1 email 
	config_get child_name rule$1 name
	language=$(uci get system.main.language)
	echo $mac

	rules=`echo $mac | awk '{FS=";"} {print NF}'`
	i=1
	count=0
	least=0
	while [ "$i" -le "$rules" ]
	do
		device_mac=`echo $mac | awk '{FS=";"} {print $'$i'}'`
		echo $device_mac
		ip=`grep "$device_mac" /tmp/dhcp.leases | awk -F ' ' '{ print $3}'`
		echo $ip
		if [ -n "$ip" ]; then
			count=`arping -I br-lan $ip -c 3 | wc -l`
			if [ "$count" -gt 3 ]; then
				least=$(( $least + 1 ))
				device_name=`grep "$device_mac" /tmp/dhcp.leases | awk -F ' ' '{ print $4}'`
				[ "$language" == "en" ] && {
					check_interface $device_mac
					mail_content_english $child_name $device_name $Network_Name
				} || {
					check_interface $device_mac
					mail_content_french $child_name $device_name $Network_Name
				}
			fi
		fi
		i=$(( $i + 1 ))
	done
	idx=1
	if [ "$least" -gt 0 ]; then
		echo "sent"
		while [ "$idx" -le 5 ]
		do
			[ -n "$(echo $email | awk -F ';' '{print $'$idx'}')" ] && { 
				email_list=$(echo $email | awk -F ';' '{print $'$idx'}')
				cat /var/mail | ssmtp -C /var/ssmtp.conf -v $email_list
			} || {
				break
			}
			idx=$(( $idx + 1 ))
		done
		
		uci set parental_monitor.rule$1.sent=1
		uci commit parental_monitor
	fi
fi
