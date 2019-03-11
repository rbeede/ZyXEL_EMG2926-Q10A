#!/bin/sh

. /etc/functions.sh
include /lib/config

config_load parental_monitor
config_get sent rule$1 sent 

if [ "$sent" -eq 0 ]; then
	config_get mac_list rule$1 mac_list
	config_get email rule$1 email 
	echo $mac_list

	rules=`echo $mac_list | awk '{FS=";"} {print NF}'`
	i=1
	count=0
	least=0
	while [ "$i" -le "$rules" ]
	do
		device=`echo $mac_list | awk '{FS=";"} {print $'$i'}'`
		echo $device
		ip=`grep "$device" /tmp/dhcp.leases | awk -F ' ' '{ print $3}'`
		echo $ip
		if [ -n "$ip" ]; then
			count=`arping -I br-lan $ip -c 3 | wc -l`
			if [ "$count" -gt 3 ]; then
				least=$(( $least + 1 ))
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
