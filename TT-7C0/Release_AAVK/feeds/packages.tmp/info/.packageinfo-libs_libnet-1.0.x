Source-Makefile: feeds/packages/libs/libnet-1.0.x/Makefile
Package: libnet0
Version: 1.0.2a-8
Depends: +libc +USE_EGLIBC:librt +USE_EGLIBC:libpthread +libpcap
Menu-Depends: 
Provides: 
Build-Depends: libtool libintl libiconv
Section: libs
Category: Libraries
Title: Low-level packet creation library (v1.0.x)
Maintainer: 
Source: libnet-1.0.2a.tar.gz
Type: ipkg
Description: Low-level packet creation library (v1.0.x)
http://www.packetfactory.net/libnet/

@@


