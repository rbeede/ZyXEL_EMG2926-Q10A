#!/bin/bash

echo '
This program will prepare the development environment.

----------------------------------------------------------
Select a  product which the image will be built for:

 1. ap135.defconfig
 2. emg2921q10a.defconfig
 3. emg2926aavk.defconfig
 4. emg2926.defconfig
 5. emg2926obm.defconfig
 6. nbg6616.defconfig
 7. nbg6716.defconfig
 8. emg3425vt.deconfig
 9. emg3425aayj.deconfig
 10. nbg6815.defconfig

 21.bsp/nbg6616.defconfig
 22.bsp/nbg6716.defconfig

 q. Exit
----------------------------------------------------------'
echo -n "(1-99,q)? "
read oem

date +%T
case "$oem"
  in

    1)	echo '--- 1. ap135.defconfig'
	cp ./configs/ap135.defconfig ./.config
	make V=s
	;;
    2)	echo '--- 2. emg2921q10a.defconfig'
	cp ./configs/emg2921q10a.defconfig ./.config
	make V=s
	;;
    3)	echo '--- 3. emg2926aavk.defconfig'
	cp ./configs/emg2926aavk.defconfig ./.config
	make V=s
	;;
    4)	echo '--- 4. emg2926.defconfig'
	cp ./configs/emg2926.defconfig ./.config
	make V=s
	;;
    5)	echo '--- 5. emg2926obm.defconfig'
	cp ./configs/emg2926obm.defconfig ./.config
	make V=s
	;;
    6)	echo '--- 6. nbg6616.defconfig'
	cp ./configs/ap135.defconfig ./.config
	make V=s
	;;
    7)	echo '--- 7. nbg6716.defconfig'
	cp ./configs/nbg6716.defconfig ./.config
	make V=s
	;;
    8)	echo '--- 8. emg3425vt.deconfig'
	cp ./configs/emg3425vt.deconfig ./.config
	make V=s
	;;
    9)	echo '--- 9. emg3425aayj.deconfig'
	cp ./configs/emg3425aayj.deconfig ./.config
	make V=s
	;;
    10) echo '--- 10. nbg6815.deconfig'
        cp ./configs/nbg6815.defconfig ./.config
        make V=s
        ;;
    21)	echo '--- 21.bsp/nbg6616.defconfig'
	cp ./configs/bsp/nbg6616.defconfig ./.config
	make V=s
	;;
    22)	echo '--- 22.bsp/nbg6716.defconfig'
	cp ./configs/bsp/nbg6716.defconfig ./.config
	make V=s
	;;
   [q,Q])
	echo '--- q. Exit'
	exit 0
	;;

    *)
	echo "--- Unknown case [$oem]"
	exit 0
	;;

esac

echo "End of [case $oem]"

