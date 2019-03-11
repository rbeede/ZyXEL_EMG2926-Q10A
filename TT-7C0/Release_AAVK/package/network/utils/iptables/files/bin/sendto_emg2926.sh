#!/bin/sh

date=`date +%T`
echo $date

. /etc/functions.sh
include /lib/config
lock /tmp/.parental_monitor_mail.lock

config_load parental_monitor
config_get sent rule$1 sent
Network_Name=""
account=$(uci get sendmail.mail_server_setup.username)
config_get start_hour rule$1 start_hour
config_get start_min rule$1 start_min
echo $start_hour
echo $start_min
config_get stop_hour rule$1 stop_hour
config_get stop_min rule$1 stop_min
echo $stop_hour
echo $stop_min
local pre_limit_time=$(expr "$start_hour" \* 60 \+ "$start_min")
local limit_time=$(expr "$stop_hour" \* 60 \+ "$stop_min")
local now_hour=$(date +%H)
local now_min=$(date +%M)
local now_time=$(expr "$now_hour" \* 60 \+ "$now_min")


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
	echo "From:  Videotron router <$account>" > /var/mail
	echo "To: " >> /var/mail
	echo "Subject: Connection notification : $1 " >> /var/mail
	echo "MIME-Version: 1.0" >> /var/mail
	echo "Content-Type: text/html; charset="utf-8"" >> /var/mail
	echo "<html>" >> /var/mail
	echo "<body>" >> /var/mail
	echo "Hi," >> /var/mail
	echo " <p> " >> /var/mail
	echo " $date Device $2 is now connected to the network $3 " >> /var/mail
	echo " <br> " >> /var/mail
	echo "</body>" >> /var/mail
	echo "</html>" >> /var/mail
}
mail_content_french(){
	echo "From:=?UTF-8?B?Um91dGV1ciBWaWTDqW90cm9u?=<$account>" > /var/mail
	echo "To: " >> /var/mail
	echo "Subject: Avis de connexion : $1 " >> /var/mail
	echo "MIME-Version: 1.0" >> /var/mail
	echo "Content-Type: text/html; charset="utf-8"" >> /var/mail
	echo "<html>" >> /var/mail
	echo "<body>" >> /var/mail
	echo "Bonjour," >> /var/mail
	echo " <p> " >> /var/mail
	echo " $date L'appareil $2 est maintenant connecté au réseau $3 " >> /var/mail
	echo " <br> " >> /var/mail
	echo "</body>" >> /var/mail
	echo "</html>" >> /var/mail
}

[ $now_time -gt $pre_limit_time -a $now_time -lt $limit_time ] && {
	[ "$sent" -eq 0 ] && {
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
			if [ -n "$device_mac" ]; then
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
					cat /var/mail | grep To | sed -ir "s/To:.*$/To:$email_list/g" /var/mail
					cat /var/mail | ssmtp -C /var/ssmtp.conf -v $email_list
					uci set parental_monitor.rule$1.sent=1
				} || {
					break
				}
				idx=$(( $idx + 1 ))
			done
			
			uci commit parental_monitor
		fi
	}
}
lock -u /tmp/.parental_monitor_mail.lock
