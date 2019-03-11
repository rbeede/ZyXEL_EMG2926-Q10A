/******************************************************************************/
/*
*  Copyright (C) 2013 ZyXEL Communications, Corp.
*  All Rights Reserved.
*
* ZyXEL Confidential; Need to Know only.
* Protected as an unpublished work.
*
* The computer program listings, specifications and documentation
* herein are the property of ZyXEL Communications, Corp. and
* shall not be reproduced, copied, disclosed, or used in whole or
* in part for any reason without the prior express written permission of
* ZyXEL Communications, Corp.
*/
/******************************************************************************/


#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>

#include <cybergarage/util/clog.h>
#include <cybergarage/ssl/cssl.h>
#include <dirent.h>

#ifdef ZYXEL_PATCH /*support ssl, ZyXEL 2013*/
#include <openssl/ssl.h>
#define CA_FILETYPE ".pem"

#if defined(CG_USE_OPENSSL)
BOOL cg_ssl_set_verify(CgSocket *sock, Cgctx *ctxdata );

int cg_ssl_filter_cafile(
	const struct dirent *fileName	/* File Name Struct */
){
	struct stat fileStat;

	if (0 == stat(fileName->d_name, &fileStat)) {
		if (S_ISREG(fileStat.st_mode)) {
			return 1;
		}
		return 0;
	}
	
	return 0;

}

BOOL cg_ssl_set_cert(CgSocket *sock, Cgctx *ctxdata ){

	if (cg_socket_isssl(sock) != TRUE) return TRUE;

	if(sock->ctx == NULL)
		sock->ctx = SSL_CTX_new( cg_socket_isserver(sock)?SSLv23_server_method():SSLv23_client_method());
	if( ctxdata == NULL) return TRUE;
	
	if (ctxdata->cert_file != NULL){
		printf("SSL_CTX_use_certificate_file '%s'\n",ctxdata->cert_file);
		if (SSL_CTX_use_certificate_file(sock->ctx,ctxdata->cert_file, SSL_FILETYPE_PEM) <= 0){
			printf("unable to get certificate from '%s'\n",ctxdata->cert_file);
			return 0;
		}
		if (ctxdata->key_file == NULL) ctxdata->key_file=ctxdata->cert_file;
		if (SSL_CTX_use_PrivateKey_file(sock->ctx,ctxdata->key_file,SSL_FILETYPE_PEM) <= 0){
			printf("unable to get private key from '%s'\n",ctxdata->key_file);
			return 0;
		}
		
		
		/* Now we know that a key and cert have been set against
		 * the SSL context */
		if (!SSL_CTX_check_private_key(sock->ctx)){
			printf("Private key does not match the certificate public key\n");
			return 0;
		}
	}
	return 1;
}

BOOL cg_ssl_set_ca(CgSocket *sock, Cgctx *ctxdata ){
	char caname[256]={0};
	if (cg_socket_isssl(sock) != TRUE) return TRUE;

	if(sock->ctx == NULL)
		sock->ctx = SSL_CTX_new( cg_socket_isserver(sock)?SSLv23_server_method():SSLv23_client_method());	
	if( ctxdata == NULL) return TRUE;

	if (ctxdata->CAfile != NULL){
		if (! SSL_CTX_load_verify_locations(sock->ctx, ctxdata->CAfile, ctxdata->CApath)){
			printf( "Load Trust Certificate Authority File : [%s/%s] Fail\n", ctxdata->CApath, ctxdata->CAfile);
		}
		cg_ssl_set_verify(sock, ctxdata);
	}
	else if(ctxdata->CApath != NULL){//dir
		int num = 0;
		struct dirent **fileList;
		
		chdir(ctxdata->CApath);
		num = scandir(ctxdata->CApath, &fileList, (void *)cg_ssl_filter_cafile, alphasort);

		if (-1 == num) {
			printf( "scandir() failed\n");
		} 
		else {
			if (0 == num){
				printf( "No Any Trust CA File List (PEM Format)\n");
			} else {
				/* Load Trust CA File List */
				while (num--) {
					snprintf(caname, sizeof(caname), "%s%s", ctxdata->CApath, fileList[num]->d_name);
					if (! SSL_CTX_load_verify_locations(sock->ctx, caname, NULL)){
						printf( "Load Trust Certificate Authority File : [%s] Fail\n", caname);
					}

					free(fileList[num]);
				}
				num = 1;				
				cg_ssl_set_verify(sock, ctxdata);
			}

			if (NULL != fileList) {
				free(fileList);
			}
		}
	}

	return TRUE;
}

BOOL cg_ssl_set_verify(CgSocket *sock, Cgctx *ctxdata ){

	if (cg_socket_isssl(sock) != TRUE) return TRUE;

	if(sock->ctx == NULL)
		sock->ctx = SSL_CTX_new( cg_socket_isserver(sock)?SSLv23_server_method():SSLv23_client_method());
	if(ctxdata->verify_callback || ctxdata->verify_mode){
		SSL_CTX_set_verify(sock->ctx, ctxdata->verify_mode, ctxdata->verify_callback);
	}
	return TRUE;
}

BOOL cg_ssl_set_ctx(CgSocket *sock, void *ctxdata){

	if (cg_socket_isssl(sock) != TRUE) return TRUE;
	if(sock->ctx == NULL)
		sock->ctx = SSL_CTX_new( cg_socket_isserver(sock)?SSLv23_server_method():SSLv23_client_method());

	if( ctxdata == NULL) return TRUE;
	
	cg_ssl_set_cert( sock,  (Cgctx *)ctxdata );
	cg_ssl_set_ca( sock,  (Cgctx *)ctxdata );

	return TRUE;
}

void cg_ssl_show_cert(CgSocket *sock){
	X509*	 cert;
	char*	 str;

	/* Get the cipher - opt */ 
	printf ("SSL connection using %s\n", SSL_get_cipher (sock->ssl));
  
  	/* Get client's certificate (note: beware of dynamic allocation) - opt */
  	cert = SSL_get_peer_certificate (sock->ssl);
  	if (cert != NULL) {
    	printf ("Peer certificate:\n");
    
    	str = X509_NAME_oneline (X509_get_subject_name (cert), 0, 0);
    	printf ("\t subject: %s\n", str);
    	free (str);
    
   		str = X509_NAME_oneline (X509_get_issuer_name  (cert), 0, 0);
    	printf ("\t issuer: %s\n", str);
    	free (str);
    
    	/* We could do all sorts of certificate verification stuff here before
       	deallocating the certificate. */
    
    	X509_free (cert);
  	}
	else{
		printf("No peer certificate\n");
	}
}

BOOL cg_ssl_accept(CgSocket *serverSock, CgSocket *clientSock){
	int ret_sslconnect = 0;
	
	printf("%s()\n", __func__);
	if (cg_socket_isssl(clientSock) != TRUE) return TRUE;

	if(clientSock->ctx == NULL)
		clientSock->ctx = SSL_CTX_new( SSLv23_server_method());

	clientSock->ssl = SSL_new(clientSock->ctx);
	SSL_set_accept_state(clientSock->ssl);
	if (SSL_set_fd(clientSock->ssl, cg_socket_getid(clientSock)) == 0) {
		return FALSE;
	}

	if ( (ret_sslconnect=SSL_accept(clientSock->ssl)) < 1) {
		printf("SSL_get_error =%d\n", SSL_get_error(clientSock->ssl, ret_sslconnect));
		printf("SSL_accept <1\n");
		return FALSE;
	}


	printf( "%s(): SSL Certificate Authority Verify Result = [%s]\n",__func__, X509_verify_cert_error_string(SSL_get_verify_result(clientSock->ssl)));

	cg_ssl_show_cert(clientSock);
	return TRUE;
}

BOOL cg_ssl_extra_verify(CgSocket *sock ){
	Cgctx *ctxdata = NULL;
	int retverify;
	X509	*cert = NULL;
	X509_NAME *name = NULL;
	char commonName[512]={0};
	char *ptr = NULL;

	ctxdata = (Cgctx *)sock->ctxdata;
  	cert = SSL_get_peer_certificate(sock->ssl);
  	if (cert != NULL && ctxdata != NULL) { 
		/*verify the Comman Name, must be same as the hostname*/
		if(ctxdata->verify_cn != NULL){
	    	name = X509_get_subject_name (cert);

			if(name){
				X509_NAME_get_text_by_NID(name, NID_commonName, commonName, sizeof(commonName));			
				if(strcmp(commonName, ctxdata->verify_cn) != 0 )//common name may be  "*.test.com.tw", Motive
				{
					/* [Motive] common name may be  "*.test.com.tw" , charisse */
					if(strncmp(commonName, "*.", 2)==0 ){
						ptr = strstr(ctxdata->verify_cn, commonName+2 );
						if(ptr){
							if((ptr-ctxdata->verify_cn)+strlen(commonName)-2 == strlen(ctxdata->verify_cn) )
								return TRUE;
						}
						
					}
				    /* Handle a suspect certificate here */
					printf("commonName=%s, ctxdata->verify_cn=%s\n", commonName, ctxdata->verify_cn);
					printf("Common Name doesn't math host name");
					return FALSE;
				}
			}
		}
		    
  	}
	return TRUE;
	
}
#endif
#endif
