#!/bin/sh
## Check to make sure router can communicate with the cloud
##
## Copyright (C) 2013 Qualcomm Inc - All Rights Reserved
## Qualcomm Proprietary
##

EXPECTED_MFR=zyxel
EXPECTED_MODEL=nbg6716
EXPECTED_CERT_SUBJECT="CN=zyxel_nbg6716_lithium, OU=Streamboost, O=Qualcomm, C=US, L=Austin, ST=Texas"

CONF=/var/run/appflow/streamboost.sys.conf
CA_CERT=/etc/ssl/certs/CA.cert.pem
CLIENT_CERT=/etc/ssl/certs/client_cert.pem
CLIENT_KEY=/etc/ssl/private/client_key.pem
OPENSSL=/usr/bin/openssl
STREAMBOOST=/usr/sbin/streamboost
LOGFILE=/var/log/check_comms.log

err() {
	echo "ERROR: $2" >&2
	log "ERROR($1): $2"
	echo "see $LOGFILE for details"
	exit $1
}

log() {
	echo "$1" >> $LOGFILE
}


log "Starting $0 at $(date)"

# check dependencies
[ -x $OPENSSL ] || err 1 "$OPENSSL not found"
[ -x $STREAMBOOST ] || err 1 "$STREAMBOOST not found"

log "Checking config $CONF"
[ -e $CONF ] || err 2 "Can't find $CONF"
. /var/run/appflow/streamboost.sys.conf

[ -n "$BOARD_MFR" ] || err 3 "Can't find BOARD_MFR in $CONF"

[ -n "$BOARD_MODEL" ] || err 4 "Can't find BOARD_MODEL in $CONF"

[ "$BOARD_MFR" == "$EXPECTED_MFR" ] || \
	err 5 "BOARD_MFR in $CONF is '$BOARD_MFR'(should be '$EXPECTED_MFR')"

[ "$BOARD_MODEL" == "$EXPECTED_MODEL" ] || \
	err 6 "BOARD_MODEL in $CONF is '$BOARD_MODEL'(should be '$EXPECTED_MODEL')"


log "Checking SSL certificate/private key"
[ -e $CLIENT_CERT ] || err 7 "Can't find $CLIENT_CERT"
[ -e $CLIENT_KEY ] || err 8 "Can't find $CLIENT_KEY"

log "Checking certificate subject"
log "Client cert: $(cat $CLIENT_CERT)"
CLIENT_CERT_TXT=$($OPENSSL x509 -noout -text -in $CLIENT_CERT) || \
	err 9 "openssl x509 failed"
log "Client cert txt: $CLIENT_CERT_TXT"
echo "$CLIENT_CERT_TXT" | grep Subject: | \
	grep "$EXPECTED_CERT_SUBJECT" > /dev/null || \
	err 9 "Client certificate $CLIENT_CERT is wrong"

log "Client key: $(cat $CLIENT_KEY)"
CLIENT_KEY_TXT=$($OPENSSL rsa -noout -text -in $CLIENT_KEY) || \
	err 9 "openssl rsa failed"
log "Client key text: $CLIENT_KEY_TXT"

log "Making sure private key matches certificate"
CERT_MODULUS_MD5=$($OPENSSL x509 -noout -modulus -in $CLIENT_CERT | $OPENSSL md5)
KEY_MODULUS_MD5=$($OPENSSL rsa -noout -modulus -in $CLIENT_KEY | $OPENSSL md5)
[ "$CERT_MODULUS_MD5" == "$KEY_MODULUS_MD5" ] || \
	err 10 "Cert($CLIENT_CERT) and key($CLIENT_KEY) don't match"

log "Verifying certificate"
VERIFY_TXT=$($OPENSSL verify $CLIENT_CERT $CA_CERT 2>&1)
log "$VERIFY_TXT"
echo "$VERIFY_TXT" | grep "^OK" > /dev/null || \
	err 11 "Certificate is not valid"

log "Checking that updates run correctly"
UPDATE_TXT=$($STREAMBOOST update 2>&1)
UPDATE_CODE=$?
log "$UPDATE_TXT"
[ $UPDATE_CODE == 0 ] || err 12 "streamboost update failed"

echo "looks good"
exit 0
