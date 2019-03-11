#!/bin/sh


Usage(){
        echo "Usage:"
        echo "      configure_vlan int_group  [Vlan interface Name]"
        echo "      configure_vlan delete [Vlan interface Name]"
        echo "      configure_vlan del_int_group [entryNo] [WAN Name] [vlan ip addr]"
		echo "		configure_vlan add_vlan"
        echo "" 
}



add_vlan_setting()  #ok
{
	check_ifx=$(ifconfig vlan$1 | grep HWaddr )

	if [ "$check_ifx" == "" ] ;then	
		vconfig set_name_type VLAN_PLUS_VID_NO_PAD
		vconfig add eth1 $1
		ifconfig vlan$1 up
		/sbin/ifup vlan$1
		/sbin/ifup vlanth$1
	fi
}


## the function is for setting each physical port 
switch_port_setting(){

	/bin/vlan_default setup_switch
	/bin/vlan_default setup_lan_inf
	/bin/vlan_default setup_wan_inf

}


cmd=$1
case "$cmd" in
        int_group)
              #echo "ip route add default dev $3 table $2" >> /tmp/aaa
              #echo "ip rule add from $4/24 table $2 pref 32800" >> /tmp/aaa
              echo "$2 IP_GROUP$2" >> /etc/iproute2/rt_tables

		#=====  Add route table ======================================
		local doamin1=""
		local mask1=""

		rm /tmp/wan_routex
		route -n | grep  $3 | grep 255.255  > /tmp/wan_routex
		exec < /tmp/wan_routex
		while read line
		do
			local test=$(echo $line | awk '{print $8}')
			local test2=$(echo $line | awk '{print $4}' )	
			if [ "$test" == "$3" ] && [ "$test2" != "UG" ] ;then
				doamin1=$(echo $line | awk '{print $1}' | tr -d '\n')
				mask1=$(echo $line | awk '{print $3}' | tr -d '\n')
				break
			fi		
		done

		ip route add $doamin1/$mask1  dev $3 table $2
		#========================================================
			  		  
              ip route add 192.168.$2.0/24 dev br-vlanth$2 table $2
              ip route add default via $5 dev $3 table $2
              ip rule del from 192.168.$2.0/24 table $2 pref 100
              ip rule del to 192.168.$2.0/24 table $2 pref 100
              ip rule add from 192.168.$2.0/24 table $2 pref 100
              ip rule add to 192.168.$2.0/24 table $2 pref 100
              ip route flush cache
              
              echo "0" > /sys/devices/virtual/net/br-vlanth$2/bridge/multicast_snooping
              
              exit $?
		;;
        del_int_group)
                # echo delete "$2 IP_GROUP$2" >> /etc/iproute2/rt_tables
                ip route delete table $2
                ip rule delete from $4/24 lookup IP_GROUP"$2"
                exit $?
        ;;
        delete)  #ok
                vconfig rem $2
                exit $?
        ;;
    

		add_vlan)  #ok
				add_vlan_setting $2
				exit $?
		;;
        *)
                Usage
        ;; 
esac

exit $?
