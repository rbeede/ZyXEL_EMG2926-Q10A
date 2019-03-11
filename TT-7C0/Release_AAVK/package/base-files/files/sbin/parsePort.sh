#!/bin/sh
local ftp_port=$(uci get proftpd.global.port)
local www_port=$(uci get firewall.remote_www.port)
local telnet_port=$(uci get firewall.remote_telnet.port)
local https_port=$(uci get firewall.remote_https.port)
local system_default_port="1 7 9 11 13 15 17 19 25 37 42 43 53 77 79 87 95 101 102 103 104 109 110 111 113 115 117 119 123 135 139 143 179 389 465 512 513 514 515 526 530 531 532 540 556 563 587 601 636 993 995 2049 4045 6000 445 263 9000 9100 9191"

echo -n "$ftp_port $www_port $telnet_port $https_port $system_default_port" > /tmp/system_port

local port=$(netstat -lptun | awk '{print $4}')
for i in $port
do
	local port_catch=$(echo $i |sed 's/:/ /g')
	local last_port=$(echo $port_catch | awk '{print $NF}')
	if echo $last_port | grep -q '^[0-9]\+$'; then
		local used_port=$(cat /tmp/system_port)
		local port_flag=0
		for j in $used_port
		do
			if [ $j -eq $last_port ]; then
				port_flag=1
			fi
		done
		if [ $port_flag -eq 0 ]; then
			echo -n " $last_port" >> /tmp/system_port
		fi
	fi
done

local NAT_RuleCount=$(uci get nat.general.rules_count)
for i in $(seq 1 1 $NAT_RuleCount)
do
	local Ex_port=$(uci get nat.rule$i.port)
	for j in $(echo $Ex_port | sed 's/,/ /g')
	do
		if [ $(echo $j |grep "-") ];then
			if [ $(echo $j | awk -F '-' '{print $1}') -le $(echo $j | awk -F '-' '{print $2}') ];then
				for k in $(seq $(echo $j | awk -F '-' '{print $1}') 1 $(echo $j | awk -F '-' '{print $2}'))
				do	
					echo -n " $k" >> /tmp/system_port
				done
			else 	
				for k in $(seq $(echo $j | awk -F '-' '{print $2}') 1 $(echo $j | awk -F '-' '{print $1}'))
				do
					echo -n " $k" >> /tmp/system_port
				done
			fi
		else
			echo -n " $j" >> /tmp/system_port
		fi
		
	done
done
