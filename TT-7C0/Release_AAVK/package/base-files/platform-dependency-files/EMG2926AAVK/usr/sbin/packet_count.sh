#!/bin/sh

avg=2
mkdir -p /tmp/wireless_packet
mkdir -p /tmp/wired_packet
tx_data1=$(apstats -v -i ath0 | grep 'Tx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)
rx_data1=$(apstats -v -i ath0 | grep 'Rx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)

tx_5gdata1=$(apstats -v -i ath10 | grep 'Tx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)
rx_5gdata1=$(apstats -v -i ath10 | grep 'Rx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)

wan_tx_data1=$(ifconfig eth0 | grep 'TX bytes' | cut -d ':' -f 3 | cut -d ' ' -f 1)
wan_rx_data1=$(ifconfig eth0 | grep 'RX bytes' | cut -d ':' -f 2 | cut -d ' ' -f 1)

lan_tx_data1=$(ifconfig eth1 | grep 'TX bytes' | cut -d ':' -f 3 | cut -d ' ' -f 1)
lan_rx_data1=$(ifconfig eth1 | grep 'RX bytes' | cut -d ':' -f 2 | cut -d ' ' -f 1)

sleep 2

tx_data2=$(apstats -v -i ath0 | grep 'Tx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)
rx_data2=$(apstats -v -i ath0 | grep 'Rx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)

tx_5gdata2=$(apstats -v -i ath10 | grep 'Tx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)
rx_5gdata2=$(apstats -v -i ath10 | grep 'Rx Data Bytes' | cut -d '=' -f 2 | cut -d ' ' -f 2)

wan_tx_data2=$(ifconfig eth0 | grep 'TX bytes' | cut -d ':' -f 3 | cut -d ' ' -f 1)
wan_rx_data2=$(ifconfig eth0 | grep 'RX bytes' | cut -d ':' -f 2 | cut -d ' ' -f 1)

lan_tx_data2=$(ifconfig eth1 | grep 'TX bytes' | cut -d ':' -f 3 | cut -d ' ' -f 1)
lan_rx_data2=$(ifconfig eth1 | grep 'RX bytes' | cut -d ':' -f 2 | cut -d ' ' -f 1)


TXByte=`expr $tx_data2 - $tx_data1`
RXByte=`expr $rx_data2 - $rx_data1`
TXByte_5g=`expr $tx_5gdata2 - $tx_5gdata1`
RXByte_5g=`expr $rx_5gdata2 - $rx_5gdata1`

wan_TXByte=`expr $wan_tx_data2 - $wan_tx_data1`
wan_RXByte=`expr $wan_rx_data2 - $wan_rx_data1`
lan_TXByte=`expr $lan_tx_data2 - $lan_tx_data1`
lan_RXByte=`expr $lan_rx_data2 - $lan_rx_data1`


avgtx=`expr $TXByte / $avg`
avgrx=`expr $RXByte / $avg`
avgtx_5g=`expr $TXByte_5g / $avg`
avgrx_5g=`expr $RXByte_5g / $avg`

wan_avgtx=`expr $wan_TXByte / $avg`
wan_avgrx=`expr $wan_RXByte / $avg`
lan_avgtx=`expr $lan_TXByte / $avg`
lan_avgrx=`expr $lan_RXByte / $avg`


echo "$avgtx" > /tmp/wireless_packet/Packet_Statistics_tx
echo "$avgrx" > /tmp/wireless_packet/Packet_Statistics_rx
echo "$avgtx_5g" > /tmp/wireless_packet/Packet_Statistics_5gtx 
echo "$avgrx_5g" > /tmp/wireless_packet/Packet_Statistics_5grx

echo "$wan_avgtx" > /tmp/wired_packet/Packet_Statistics_wantx
echo "$wan_avgrx" > /tmp/wired_packet/Packet_Statistics_wanrx
echo "$lan_avgtx" > /tmp/wired_packet/Packet_Statistics_lantx
echo "$lan_avgrx" > /tmp/wired_packet/Packet_Statistics_lanrx



