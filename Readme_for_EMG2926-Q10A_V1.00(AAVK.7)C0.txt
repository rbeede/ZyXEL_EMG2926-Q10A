Readme for EMG2926-Q10A V1.00(AAVK.7)C0


0. Introduction

  This file will show you how to build the EMG2926-Q10A linux system, please note, the download image will overwrite the original image existed in the flash memory of EV board.


1. Package file

   A. EMG2926-Q10A(V1.00(AAVK.7)C0).tar.bz2        (EMG2926-Q10A GPL source code)

   B. Readme_for_EMG2926-Q10A_V1.00(AAVK.7)C0 (This file)


2. Build up compiler environment.

   A. Install Ubuntu 12.04 Desktop 32bit

   B. install following tools in your environment

	$ sudo apt-get install -y gcc
	$ sudo apt-get install -y g++
	$ sudo apt-get install -y binutils
	$ sudo apt-get install -y patch
	$ sudo apt-get install -y bzip2
	$ sudo apt-get install -y flex
	$ sudo apt-get install -y bison
	$ sudo apt-get install -y make
	$ sudo apt-get install -y autoconf
	$ sudo apt-get install -y gettext
	$ sudo apt-get install -y texinfo
	$ sudo apt-get install -y unzip
	$ sudo apt-get install -y sharutils
	$ sudo apt-get install -y subversion
	$ sudo apt-get install -y libncurses5-dev
	$ sudo apt-get install -y ncurses-term
	$ sudo apt-get install -y zlib1g-dev
	$ sudo apt-get install -y gawk
	$ sudo apt-get install -y lzop
	$ sudo apt-get install -y ctags
	$ sudo apt-get install -y git-core
	$ sudo apt-get update


3. Build the firmware for Web-GUI upgrade using
   NOTE: You can't do following things as "root"

   A. Decompress the source code 

	$ tar -jxvf EMG2926-Q10A(V1.00(AAVK.7)C0).tar.bz2

   B. After decompress the source code please enter the Release_AAVK folder

	$ cd TT-7C0/Release_AAVK/

   C. In the Release_AAVK folder please tpye the folling to build the code
      NOTE1: Please make sure your pc could connect the internet. Or the bulid process will stop on some download opensource atcion

	$ make V=99

      NOTE2: If system show some options , please press "Enter" to apply the default setting

	Press "Enter" 3 times

   D. The firmware image will locate at Release_AAVK/bin/ar71xx/zyxel/ras.bin.jffs2
      You can use it update EMG2926-Q10A by using the firmware update procedure.


