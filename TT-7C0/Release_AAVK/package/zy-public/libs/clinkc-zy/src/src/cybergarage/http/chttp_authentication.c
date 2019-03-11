/******************************************************************
*
*	CyberLink for C
*
*	Copyright (C) Satoshi Konno 2005
*
*       Copyright (C) 2006 Nokia Corporation. All rights reserved.
*
*       This is licensed under BSD-style license,
*       see file COPYING.
*
*	File: chttp_authentication.c
*
*	Revision:
*
*	05/31/12
*		- first release
*
******************************************************************/


#include <cybergarage/http/chttp_authentication.h>
#include <cybergarage/http/chttp_cookie.h>
#include <cybergarage/http/cb64.h>
#include <cybergarage/http/cmd5.h>
#include <sys/time.h>
#include <string.h>

int nc = 0;
CgHttpAuth *digestHead = NULL;
CgHttpAuth *digestTail = NULL;

/****************************************************************************
* 									Function for linklist utility
*****************************************************************************/
static BOOL cg_http_digest_del_entry(CgHttpAuth *delEntry)
{
	CgHttpAuth *now = digestHead;
	
	/*delete head entry*/
	if(delEntry == digestHead){
		/*also tail*/
		if(delEntry == digestTail){
			digestHead = NULL;
			digestTail = NULL;
		}
		else
			digestHead = delEntry->next;
		
		free(delEntry);
		return TRUE;
	}
	
	while(now != NULL){
		if(now->next == delEntry){
			/*delete tail entry*/
			if(delEntry == digestTail){
				now->next = NULL;
				digestTail = now;
				free(delEntry);
				return TRUE;
			}else{	//delete middle entry	
				now->next = delEntry->next;
				free(delEntry);
				return TRUE;
			}
		}
		now = now->next;
	}
	
	return TRUE;
}

static BOOL cg_http_digest_replace_entry(CgHttpAuth *oldEntry, CgHttpAuth *newEntry)
{
	CgHttpAuth *now = digestHead;
	
	/*delete head entry*/
	if(oldEntry == digestHead){
		/*also tail*/
		if(oldEntry == digestTail)
			digestTail = newEntry;
		else
			newEntry->next = digestHead->next;
		
		digestHead = newEntry;
		free(oldEntry);
		return TRUE;
	}
	
	while(now != NULL){
		if(now->next == oldEntry){
			/*delete tail entry*/
			if(oldEntry == digestTail){
				now->next = newEntry;
				digestTail = newEntry;
				free(oldEntry);
				return TRUE;
			}else{	//delete middle entry
				newEntry->next = oldEntry->next;
				now->next = newEntry;
				free(oldEntry);
				return TRUE;
			}
		}
		now = now->next;
	}
	
	return TRUE;
}

/****************************************************************************
* 									Function for client request
*****************************************************************************/
	
CgHttpResponse *cg_http_request_post_with_auth(CgHttpRequest *httpReq, char *ipaddr, int port, char *user, char *passwd)
{
	CgHttpResponse *httpRes;
	char *authHeader;
	int basicHeaderLen;
	CgHttpHeader *header = NULL;
	char *basicHeader, *base64Encode;
	char *staleFlag, *entityBody, digestHeader[1024]={0}, algorithmHeader[64]={0}, opaqueHeader[128]={0};
	char *method = NULL, *uripath = NULL;
	CgHttpAuth *auth;
	char md5Input[1024]={0}, ha1[CG_MD5_STRING_BUF_SIZE]={0}, ha2[CG_MD5_STRING_BUF_SIZE]={0}, digest[CG_MD5_STRING_BUF_SIZE]={0}, hEntity[CG_MD5_STRING_BUF_SIZE]={0};
	char *tmp = NULL;
	char *nonce = NULL;

	/*post http request*/
	httpRes = cg_http_request_post(httpReq, ipaddr, port);

	/*check if the query web page needs authentication*/
	if ((cg_http_response_getstatuscode(httpRes)) != CG_HTTP_STATUS_UNAUTHORIZED)
		return httpRes;

	/*get authentication header*/
	auth = &httpRes->authData;
	cg_http_auth_header_parse((CgHttpPacket*)httpRes);
	authHeader = cg_http_response_getauth(httpRes);
	if (strcmp(authHeader, "Basic") == 0)   /*basic authentication*/   
	{
		base64Encode = cg_http_base64encode(user, passwd);
		basicHeaderLen = strlen(base64Encode)+strlen("Basic ")+1;
		basicHeader = (char *)malloc((basicHeaderLen)*sizeof(char));
		memset( basicHeader, 0, (basicHeaderLen)*sizeof(char) );
		if(basicHeader == NULL)
			printf("error: out of memory,%s,%d\n",__FUNCTION__,__LINE__);
		
		snprintf(basicHeader, basicHeaderLen, "Basic %s",base64Encode);
		if(basicHeader == NULL)
			printf("error: base64 encode fail\n");
	
		/*add header to request*/
		header = cg_http_header_new();
		cg_http_header_setname(header, CG_HTTP_AUTHENTICATION);
		cg_http_header_setvalue(header, basicHeader);
		cg_http_packet_addheader((CgHttpPacket*)httpReq, header);
		httpRes = cg_http_request_post(httpReq, ipaddr, port);
		if(httpRes == NULL)
			printf("error: http response fail\n");	
		
		/*clean up*/
		free(base64Encode);
		free(basicHeader);

		/*authentication success*/
		if((cg_http_response_getstatuscode(httpRes)) == CG_HTTP_STATUS_OK)
			auth->result = AUTH_OK;
		
		/*authentication fail if the 401 response is presented*/
		if((cg_http_response_getstatuscode(httpRes)) == CG_HTTP_STATUS_UNAUTHORIZED)
			auth->result = AUTH_WRONG_INPUT;
		
		return httpRes;
	}
	else if (strcmp(authHeader, "Digest") == 0)   /*digest authentication*/
	{
		/*prepare value of digest headers*/
		auth->realm			= cg_http_response_getrealm(httpRes);
		if(!auth->realm){
			printf("error: can not get realm");
			return httpRes;
		}
	
		nonce 				= cg_http_response_getnonce(httpRes);
		if( nonce != NULL)
			strcpy(auth->nonce, nonce);		
		else{
			printf("error: can not get nonce");
			return httpRes;
		}

		tmp =  cg_http_response_getqop(httpRes);	
		if(!tmp)
			auth->qop		= NULL;
		else
			auth->qop		= tmp;

		tmp 				= cg_http_response_getalgorithm(httpRes);
		if(!tmp)
			auth->algorithm	= NULL;
		else
			auth->algorithm	= tmp;
	
		tmp 				= cg_http_response_getopaque(httpRes);
		if(!tmp)
			auth->opaque	= NULL;
		else
			auth->opaque	= tmp;
		
		method				= cg_http_request_getmethod(httpReq);
		uripath				= cg_http_request_geturi(httpReq);
		auth->cnonce		= generateCnonce();
		nc++;
		auth->nc			= nc;
		
/*
	if the algorithm is "MD5" or unspecified
		ha1 = MD5( username:realm:passwd )

	if the qop is "auth" or unspecified
		ha2 = MD5( Method:digest-uri )
*/
		snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", user, auth->realm, passwd);		
		cg_str2md5(md5Input,ha1);
		snprintf(md5Input, sizeof(md5Input), "%s:%s", method, uripath);		
		cg_str2md5(md5Input,ha2);

/*
	here we dicuss the different formula of digest response based on qop value.
	
	if the qop is unspecified:
	1. the hash function in here must be "MD5" or unspecified, 
	otherwise we don't support other hash function.
	
	2. digest response= MD5(ha1:nonce:ha2)

	
	if the qop is "auth" or "auth-int":
	1.the hash function in here must be "MD5" or unspecified or "MD5-sess", 
	otherwise we don't support other hash function.

	2.in particular, if the qop is "auth-int"
		ha2 = MD5( Method:digest-uri:MD5(entity-body) )

	3.in particular, if the algorithm is "MD5-sess"
		ha1 = MD5( MD5( username:realm:passwd):nonce:cnonce )

	4. digest response= MD5(ha1:nonce:nc:cnonce:qop:ha2)
		
*/
		if (!(auth->qop)) {
			if((auth->algorithm)&&(strcmp(auth->algorithm, "MD5") != 0)){
				auth->result = AUTH_UNSUPPORT_ALGORITHM;
				return httpRes;
			}
			snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", ha1, auth->nonce, ha2);	
			cg_str2md5(md5Input,digest);
			snprintf(digestHeader, sizeof(digestHeader),	"Digest username=\"%s\", "
													"realm=\"%s\", "
													"nonce=\"%s\", "
													"uri=\"%s\", "
													"response=\"%s\"",
	               										user,
	               										auth->realm,
	               										auth->nonce,
	               										uripath,
	               										digest);
		
			if((auth->algorithm)){
				snprintf(algorithmHeader, sizeof(algorithmHeader), ", algorithm=%s", auth->algorithm);
				strcat(digestHeader, algorithmHeader);
			}
			if(auth->opaque){
				snprintf(opaqueHeader, sizeof(opaqueHeader), ", opaque=%s", auth->opaque);
				strcat(digestHeader, opaqueHeader);
			}
		}
		else{
			if((auth->algorithm)&&(strcmp(auth->algorithm, "MD5") != 0)&&(strcmp(auth->algorithm,"MD5-sess") != 0)){
				auth->result = AUTH_UNSUPPORT_ALGORITHM;
				return httpRes;
			}
			
			if(strcmp(auth->qop, "auth-int") == 0){
				entityBody = cg_http_request_getcontent(httpReq);	
				cg_str2md5(entityBody, hEntity);
				snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", method, uripath, hEntity);	
				cg_str2md5(md5Input,ha2);
			}
			
			if((auth->algorithm) && (strcmp(auth->algorithm, "MD5-sess") == 0)){
				snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", ha1, auth->nonce, auth->cnonce);
				cg_str2md5(md5Input,ha1);
			}
		
			snprintf(md5Input, sizeof(md5Input), "%s:%s:%08x:%s:%s:%s", 
											ha1,
											auth->nonce,
											auth->nc,
											auth->cnonce,
											auth->qop,
											ha2);
			cg_str2md5(md5Input,digest);
			snprintf(digestHeader, sizeof(digestHeader),	"Digest username=\"%s\", "
													"realm=\"%s\", "
													"nonce=\"%s\", "
													"uri=\"%s\", "
													"response=\"%s\", "
													"qop=\"%s\", "
													"nc=%08x, "
													"cnonce=\"%s\"",
	               										user,
	               										auth->realm,
	               										auth->nonce,
	               										uripath,
	               										digest,
	               										auth->qop,
	               										auth->nc,
	               										auth->cnonce);

			if(auth->algorithm){
				snprintf(algorithmHeader, sizeof(algorithmHeader), ", algorithm=%s", auth->algorithm);
				strcat(digestHeader, algorithmHeader);
			}
			if(auth->opaque){
				snprintf(opaqueHeader, sizeof(opaqueHeader), ", opaque=\"%s\"", auth->opaque);
				strcat(digestHeader, opaqueHeader);
			}  
		}

		/*add header to digest request*/
		header = cg_http_header_new();
		cg_http_header_setname(header, CG_HTTP_AUTHENTICATION);
		cg_http_header_setvalue(header, digestHeader);
		cg_http_packet_addheader((CgHttpPacket*)httpReq, header);
		httpRes = cg_http_request_post(httpReq, ipaddr, port);
		if(httpRes == NULL)
			printf("error: http response fail\n");

		/*authentication success*/
		if((cg_http_response_getstatuscode(httpRes)) == CG_HTTP_STATUS_OK){
			auth->result = AUTH_OK;
			return httpRes;
		}
		
		/*authentication fail if the 401 response is presented:
			it presents that the username and password is correct, 
			but the nonce value is old when the http response carries stale header, and the value is "TRUE".

			otherwise, the username or password is wrong.
		*/
		if((cg_http_response_getstatuscode(httpRes)) == CG_HTTP_STATUS_UNAUTHORIZED){
			cg_http_auth_header_parse((CgHttpPacket*)httpRes);		
			staleFlag = cg_http_response_getstale(httpRes);
			if(staleFlag && strcasecmp(staleFlag, "TRUE") == 0){
				auth->result = AUTH_STALE;
				return httpRes;
			}
			else{
				auth->result = AUTH_WRONG_INPUT;
				return httpRes;
			}
		}
		else
			return httpRes;
	}	
	/*the authentication way neither Basic nor Digest*/
	else{
		auth->result = AUTH_UNSUPPORT_AUTH;
		return httpRes;
	}	
}

char *generateCnonce()
{
	struct timeval now;
	char cnonceBuf[10];
	char *cnonce;
	int cnonceLen;
	
	/*get time*/
	gettimeofday(&now, NULL);
	snprintf(cnonceBuf, sizeof(cnonceBuf), "%09ld", (long)now.tv_sec);

	/* Note: The value returned may be larger than the actual size
     	* required, but will never be smaller.
     	*/
	cnonceLen = b64_encode(cnonceBuf, sizeof(cnonceBuf), NULL, 0) ;

	/* Using the length determined by the call to b64_encode(), create
     	* a buffer of sufficient size.
     	*/
	cnonce = (char*)malloc(cnonceLen+1);
	if (cnonce == NULL)
		printf("error: out of memory,%s,%d\n",__FUNCTION__,__LINE__);

	memset( cnonce, 0, cnonceLen+1 );
	/* Perform base64 encoding*/
	b64_encode(cnonceBuf, sizeof(cnonceBuf), cnonce, cnonceLen); 
	return cnonce;
}

void cg_http_auth_header_parse(CgHttpPacket *httpPkt)
{
	char headerArray[512]={0};
       char *headerPtr = NULL, *headerLine = NULL, *passphrase = NULL;
	int statusCode = 0;
       char *p[32];
	CgHttpHeader *subheader;
       char *name, *value, *authMethod, *key, *val;
       int i = 0, j = 0;
	BOOL isReq = FALSE;

	/*ckeck whether the input is http request or response*/
	if(cg_http_request_isgetrequest((CgHttpRequest *)httpPkt) || cg_http_request_ispostrequest((CgHttpRequest *)httpPkt))
		isReq = TRUE;

	/*get authentication header line*/
	if(isReq == FALSE){// response from http server
		headerLine = cg_http_response_getauth(httpPkt);
		if (headerLine == NULL){
			printf("error: can not get authentication header line\n");
			return;
		}
	}
	else{// request from http client	
		headerLine = cg_http_request_getauth(httpPkt);	
		if (headerLine == NULL){
			printf("error: can not get authentication header line\n");
			return;
		}
	}
	
       /*beacause strtok will modifies the string(char *header)we give it,
       so convert the input pointer to array and set to header pointer*/
       strcpy(headerArray, headerLine);
       headerPtr = headerArray;

       /*detach the authentication header as authentication method.
	*it is noteworthy that "Basic" auth request header format is different below: 
	*	Authorization: Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ (encode response string)
	*/
	authMethod = strtok(headerPtr, " ");
	if(authMethod != NULL){
		if(!isReq)
              	cg_http_packet_setheadervalue(httpPkt, CG_HTTP_WWW_AUTHENTICATION,  authMethod);
		else if(!strcmp(authMethod, "Basic")){
			cg_http_packet_setheadervalue(httpPkt, CG_HTTP_AUTHENTICATION,  authMethod);
			passphrase = strtok(NULL, " ");
			cg_http_packet_setheadervalue(httpPkt, CG_HTTP_RESPONSE,  passphrase);
			return;
		}
		else
			cg_http_packet_setheadervalue(httpPkt, CG_HTTP_AUTHENTICATION,  authMethod);
	}

	/*detach the authentication header to extract subheaders*/
	/*prepare header pair to array p[]*/
		
	key= strtok(NULL, " ,=");
	while( key!=NULL )
	{
		p[i]=key;
			
		if( !strcmp(key,"nonce") )
			val= strtok(NULL, " ,");
		else
			val= strtok(NULL, " ,=");
		
		if(val[0]=='\"' && val[strlen(val)-1]=='\"')
		{
			val[0]= val[strlen(val)-1]= 0;
			++val;
		}
		
		p[i+1]=val;
			
		key= strtok(NULL, " ,=");
		i+=2;
	}
	
	/*set header pair from retrieve p[]
	for example, p[0]=name_#1 p[1]=value_#1, p[2]=name_#2 p[3]=value_#2 and so on */
	for(j=0;j<i;j+=2){	
		if ((name=p[j]) != NULL) {	
			if ((value=p[j+1]) == NULL)
				value = "";

			subheader = cg_http_header_new();
			cg_http_header_setname(subheader, name);
			cg_http_header_setvalue(subheader, value);
			cg_http_packet_addheader(httpPkt, subheader);
		}
	}
}

/****************************************************************************
* 									Function for servers
*****************************************************************************/
void initDigestInfo(CgHttpAuth **digest)
{
	*digest = (CgHttpAuth *)malloc(sizeof(CgHttpAuth));
	memset(*digest, '\0', sizeof(CgHttpAuth));
	(*digest)->realm 		= NULL;
	(*digest)->algorithm 	= NULL;
	(*digest)->qop 		= NULL;
	(*digest)->cnonce 	= NULL;
	(*digest)->opaque 	= NULL;
	(*digest)->username 	= NULL;	
	(*digest)->response 	= NULL;
	(*digest)->nc 			= 0;
	(*digest)->next 		= NULL;
}

void generateNonce(char nonce[])
{
	struct timeval now;
	char nonceBuf[100];
			
	/*get time*/
	gettimeofday(&now, NULL);
	srand(now.tv_usec*17);
	snprintf(nonceBuf, sizeof(nonceBuf), "%8x:%8x:%8x", 
		(unsigned)now.tv_usec*rand(), (unsigned)now.tv_usec*rand(), (unsigned)now.tv_usec*1551*rand());

	cg_str2md5(nonceBuf, nonce);
}

void sendDigestChallenge(CgHttpRequest *httpReq, char *realm)
{
	CgHttpResponse *httpRes;
	char authHeader[1024];
	CgHttpAuth *newEntry = NULL;
	CgHttpAuth *now = digestHead;
	char nonce[CG_MD5_STRING_BUF_SIZE]={0};

	initDigestInfo(&newEntry);
	generateNonce(nonce);
	strcpy(newEntry->nonce, nonce);
	
	if(realm == NULL)
		newEntry->realm= CG_HTTP_DEFAULT_REALM;
	else
		newEntry->realm= realm;
	
	newEntry->opaque = CG_HTTP_DEFAULT_OPAQUE;
	newEntry->qop = CG_HTTP_DEFAULT_QOP;
	newEntry->algorithm = CG_HTTP_DEFAULT_ALGORITHM;
	
	strcpy(newEntry->clientHost, cg_http_request_getremoteaddress(httpReq));
	while(now != NULL){
		if(!strcmp(now->clientHost, newEntry->clientHost))
			break;
		
		now = now->next;
	}
	
	/*add digest entry*/
	if(digestHead == NULL){
		digestHead = newEntry;
		digestTail = newEntry;
	}
	else if(now != NULL){//replace the entry which same remote host
		cg_http_digest_replace_entry(now, newEntry);
	}
	else{	
		digestTail->next = newEntry;
		digestTail = newEntry;
	}

	/*response digest challenge*/
	httpRes = cg_http_response_new();
	cg_http_response_setstatuscode(httpRes, CG_HTTP_STATUS_UNAUTHORIZED);
	cg_http_response_setcontentlength(httpRes, 0);
	sprintf(authHeader, "Digest realm=\"%s\", nonce=\"%s\", qop=\"%s\", algorithm=\"%s\", opaque=\"%s\" ", 
		newEntry->realm, newEntry->nonce, newEntry->qop, newEntry->algorithm, newEntry->opaque);
	cg_http_response_setheadervalue(httpRes, CG_HTTP_WWW_AUTHENTICATION, authHeader);
	cg_http_request_postresponse( httpReq, httpRes );
	cg_http_response_delete( httpRes );
}

authRet_t cg_http_request_check_digest_auth(CgHttpRequest *httpReq, char *user, char *passwd)
{
	char *headerLine = NULL, *authMethod = NULL;
	char *method = NULL, *uripath = NULL;
	CgHttpAuth *auth = NULL;
	char *tmp = NULL;
	char md5Input[1024]={0}, ha1[CG_MD5_STRING_BUF_SIZE]={0}, ha2[CG_MD5_STRING_BUF_SIZE]={0}, digest[CG_MD5_STRING_BUF_SIZE]={0}, hEntity[CG_MD5_STRING_BUF_SIZE]={0};
	char *entityBody;
	CgHttpAuth *now = digestHead;
	BOOL stale = FALSE, found = FALSE;
	
	initDigestInfo(&auth);
	strcpy(auth->clientHost, cg_http_request_getremoteaddress(httpReq));

	/*get authentication header line*/
	headerLine = cg_http_request_getauth(httpReq);
	if (headerLine == NULL){
		/*client request without authentication header, two reasons:
		*	1. first request
		*	2. client got Amnesia
		*/
		return HTTP_AUTH_NOT_EXIST;
	}

	cg_http_auth_header_parse((CgHttpPacket*)httpReq);
	authMethod = cg_http_request_getauth(httpReq);		
	if (strcmp(authMethod, "Digest") == 0){  /*digest authentication*/
		/*prepare value of digest headers*/
		auth->realm			= cg_http_request_getrealm(httpReq);
		if(!auth->realm){
			printf("error: can not get realm");
			return HTTP_AUTH_ERROR;
		}
			
		tmp 				= cg_http_request_getnonce(httpReq);
		strcpy(auth->nonce, tmp);
		if(!auth->nonce){
			printf("error: can not get nonce");
			return HTTP_AUTH_ERROR;
		}
			
		auth->response		= cg_http_request_getresponse(httpReq);
		if(!auth->response){
			printf("error: can not get response");
			return HTTP_AUTH_ERROR;
		}

		auth->username		= cg_http_request_getusername(httpReq);
		if(!auth->username){
			printf("error: can not get username");
			return HTTP_AUTH_INVALID_USERNAME;
		}

		if(strcmp(user, auth->username))
			return HTTP_AUTH_INVALID_USERNAME;
			
		while(now != NULL){		
			if(!strcmp(now->clientHost, auth->clientHost)){
				found = TRUE;
				
				if(strcmp(now->realm, auth->realm))
					return HTTP_AUTH_NOT_EXIST;
				if(strcmp(now->nonce, auth->nonce))
					stale = TRUE;
				
				break;
			}
				 
			now = now->next;
		}

		if(!found)			
			return HTTP_AUTH_NOT_EXIST;
			
		if(now->qop){
			tmp 				= cg_http_request_getqop(httpReq);
			if(!tmp){
				auth->qop		= NULL;
				/*qop can be unspecified*/
			}
			else{
				auth->qop		= tmp;				
				if(strcmp(auth->qop, now->qop))
					return HTTP_AUTH_NOT_EXIST;
			}
		}
			
		if(now->algorithm){
			tmp 				= cg_http_request_getalgorithm(httpReq);
			if(!tmp){
				auth->algorithm	= NULL;
				/*algorithm can be unspecified*/
			}
			else{
				auth->algorithm	= tmp;			
				if(strcmp(auth->algorithm, now->algorithm))
					return HTTP_AUTH_NOT_EXIST;
			}
		}
						
		if(now->opaque){
			tmp 				= cg_http_request_getopaque(httpReq);
			if(!tmp){
				auth->opaque	= NULL;
				printf("error: can not get opaque\n");
				return HTTP_AUTH_ERROR;
			}
			else{
				auth->opaque	= tmp;							
				if(strcmp(auth->opaque, now->opaque))
					return HTTP_AUTH_NOT_EXIST;
			}
		}
			
		tmp 				= cg_http_request_getcnonce(httpReq);
		if(!tmp)
			auth->cnonce	= NULL;
		else
			auth->cnonce	= tmp;
			
		tmp 				= cg_http_request_getnc(httpReq);
		if(!tmp)
			auth->nc		= 0;
		else
			sscanf(tmp, "%08x", &auth->nc);

		method				= cg_http_request_getmethod(httpReq);
		uripath				= cg_http_request_geturi(httpReq);

/*
	if the algorithm is "MD5" or unspecified
		ha1 = MD5( username:realm:passwd )

	if the qop is "auth" or unspecified
		ha2 = MD5( Method:digest-uri )
*/
		memset(md5Input, "\0", sizeof(md5Input));
		snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", user, auth->realm, passwd);
		cg_str2md5(md5Input,ha1);
		memset(md5Input, "\0", sizeof(md5Input));
		snprintf(md5Input, sizeof(md5Input), "%s:%s", method, uripath);
		cg_str2md5(md5Input,ha2);

/*
	here we dicuss the different formula of digest response based on qop value.
	
	if the qop is unspecified:
	1. the hash function in here must be "MD5" or unspecified, 
	otherwise we don't support other hash function.
	
	2. digest response= MD5(ha1:nonce:ha2)

	
	if the qop is "auth" or "auth-int":
	1.the hash function in here must be "MD5" or unspecified or "MD5-sess", 
	otherwise we don't support other hash function.

	2.in particular, if the qop is "auth-int"
		ha2 = MD5( Method:digest-uri:MD5(entity-body) )

	3.in particular, if the algorithm is "MD5-sess"
		ha1 = MD5( MD5( username:realm:passwd):nonce:cnonce )

	4. digest response= MD5(ha1:nonce:nc:cnonce:qop:ha2)
		
*/
		if (!(auth->qop)) {
			if((auth->algorithm)&&(strcmp(auth->algorithm, "MD5") != 0)){
				auth->result = AUTH_UNSUPPORT_ALGORITHM;
				return HTTP_AUTH_NOT_EXIST;
			}
			snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", ha1, auth->nonce, ha2);	
			cg_str2md5(md5Input,digest);
		}
		else{
			if((auth->algorithm)&&(strcmp(auth->algorithm, "MD5") != 0)&&(strcmp(auth->algorithm,"MD5-sess") != 0)){
				auth->result = AUTH_UNSUPPORT_ALGORITHM;
				return HTTP_AUTH_NOT_EXIST;
			}
				
			if(strstr(auth->qop, "auth-int") != NULL){
				entityBody = cg_http_request_getcontent(httpReq);		
				cg_str2md5(entityBody, hEntity);		
				snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", method, uripath, hEntity);
				cg_str2md5(md5Input, ha2);		
			}
				
			if((auth->algorithm) && (strcmp(auth->algorithm, "MD5-sess") == 0)){
				snprintf(md5Input, sizeof(md5Input), "%s:%s:%s", ha1, auth->nonce, auth->cnonce);	
				cg_str2md5(md5Input, ha1);			
			}

			memset(md5Input, '\0', sizeof(md5Input));
			snprintf(md5Input, sizeof(md5Input), "%s:%s:%08x:%s:%s:%s",
											ha1,
											auth->nonce,
											auth->nc,
											auth->cnonce,
											auth->qop,
											ha2);			
			cg_str2md5(md5Input,digest);
		}

		if(!strcmp(digest, auth->response))
			return HTTP_AUTH_SUCCESS;
		else
			return HTTP_AUTH_INVALID_PASSWORD;
	}
	else{
		printf("invalid authenticcation method\n");
		return HTTP_AUTH_NOT_EXIST;
	}

	return HTTP_AUTH_NOT_EXIST;
}


/******Basic authentication******/
void sendBasicChallenge(CgHttpRequest *httpReq, char *realm)
{
	CgHttpResponse *httpRes;
	char authHeader[64]={0};

	/*response basic challenge*/
	httpRes = cg_http_response_new();
	cg_http_response_setstatuscode(httpRes, CG_HTTP_STATUS_UNAUTHORIZED);
	cg_http_response_setcontentlength(httpRes, 0);
	sprintf(authHeader, "Basic realm=\"%s\"", realm);
	cg_http_response_setheadervalue(httpRes, CG_HTTP_WWW_AUTHENTICATION, authHeader);
	cg_http_request_postresponse( httpReq, httpRes );
	cg_http_response_delete( httpRes );
}

authRet_t cg_http_request_check_basic_auth(CgHttpRequest *httpReq, char *user, char *passwd, BOOL cookieAuthentication)
{
	char *headerLine, *authMethod, *passphrase = NULL;
	char *base64Encode = NULL;
	char *base64EncodeStr = NULL;
	char *decodePhrase = NULL;
	char *decodeUser = NULL;
	char *decodePasswd = NULL;
	char *cookie = NULL;
	int cookieLen = 0;
	char *ptr = NULL;
	CgHttpAuth *auth;

	auth = &httpReq->authData;
	if (!cookieAuthentication){
		/*get authentication header line*/
		headerLine = cg_http_request_getauth(httpReq);
		if (headerLine == NULL)
			return HTTP_AUTH_ERROR;
		
		cg_http_auth_header_parse((CgHttpPacket*)httpReq);
		authMethod = cg_http_request_getauth(httpReq);

		if (strcmp(authMethod, "Basic") == 0){  /*basic authentication*/
			passphrase = cg_http_request_getresponse(httpReq);
			base64Encode = cg_http_base64encode(user, passwd);		
			if(strcmp(base64Encode, passphrase) == 0){		
				free(base64Encode);
				return HTTP_AUTH_SUCCESS;
			}
			else	
				free(base64Encode);
		}
		else{
			printf("invalid authenticcation method\n");
			return HTTP_AUTH_NOT_EXIST;
		}
	}
	else{ /*use cookie information to do web authentication*/
		if(cg_http_request_getcookie(httpReq) == NULL)
			return HTTP_AUTH_NOT_EXIST;
	
		cookieLen = cg_strlen(cg_http_request_getcookie(httpReq));
		if(cookieLen != 0){
			cookie = (char *)malloc((cookieLen+1)*sizeof(char));
			if(cookie == NULL){
				printf("error: out of memory,%s,%d\n",__FUNCTION__,__LINE__);
				return HTTP_AUTH_ERROR;
			}

			/*the authentication cookie should be "Authentication=XXX", XXX means passphrase */
			strcpy(cookie, cg_http_request_getcookie(httpReq));
			if((ptr = strstr(cookie, "Authentication")) == NULL){
				return HTTP_AUTH_ERROR;
			}
			passphrase = ptr + strlen("Authentication=");
			
			if(passphrase){					
				base64EncodeStr = cg_http_url_decode(passphrase);			
				decodePhrase = cg_http_base64decode(base64EncodeStr);
				if(!strcmp(decodePhrase, ":"))
					return HTTP_AUTH_NOT_EXIST;
				decodeUser = strtok(decodePhrase, ":");				
				decodePasswd= strtok(NULL, " ");
			
				if(strcmp(decodeUser, user) != 0){
					free(base64EncodeStr);
					free(decodePhrase);
					free(cookie);				
					return HTTP_AUTH_INVALID_USERNAME;
				}
				else if(!strcmp(decodePasswd, passwd) && (!strcmp(decodeUser,user))){
					free(base64EncodeStr);
					free(decodePhrase);
					free(cookie);
					return HTTP_AUTH_SUCCESS;
				}
				else
					return HTTP_AUTH_INVALID_PASSWORD;
			}
			
			free(cookie);
		}
	}

	return HTTP_AUTH_INVALID_PASSWORD;
}

/****************************************************************************
* 							Base64 encode and url encode algorithm
*****************************************************************************/

 /* Simple conversion using b64_encode */
char *cg_http_base64encode(char *user, char *passwd)
{
	int srcLen, destLen;
	char *dest, *destBuf, *srcBuf;
	/* malloc srcBuf to fill in user and password*/
	srcLen = strlen(user)+strlen(passwd)+2;
	if(srcLen == 0)
		return NULL;
	
	if ((srcBuf = (char *)malloc((srcLen)*sizeof(char))) == NULL){
		printf("error: out of memory,%s,%d\n",__FUNCTION__,__LINE__);
		return NULL;
	}
	
	memset( srcBuf, 0, (srcLen)*sizeof(char) );
	snprintf(srcBuf, srcLen, "%s:%s", user, passwd);
	if (srcBuf == NULL)
		return NULL;
	
	/* Invoke b64_encode() to determine the maximum size of the encoded
	* string, specifying the argument 0 for the destSize parameter.
	*
	* Note: The value returned may be larger than the actual size
	* required, but will never be smaller.
	*/
	destLen = b64_encode(srcBuf, srcLen-1, NULL, 0);

	/* Using the length determined by the call to b64_encode(), create
	* a buffer of sufficient size.
	*/
	dest = (char*)malloc(destLen);
	if (dest == NULL){
		printf("error: out of memory,%s,%d\n",__FUNCTION__,__LINE__);
		return NULL;
		}
	memset( dest, 0, destLen);

	/*
    	size_t  i;

  	printf("Converting %u bytes:\n", (unsigned)NUM_ELEMENTS(bytes));
    	for(i = 0; i != NUM_ELEMENTS(bytes); ++i)
    	{
        	printf(" %d", bytes[i]);
    	}
    	puts("");
	*/
	
    	/* Perform base64 encoding. */
	destLen = b64_encode(srcBuf, srcLen-1, dest, destLen);
	
	/*malloc destBuf for return*/
	destBuf= (char *)malloc((destLen+1)*sizeof(char));
	if(destBuf == NULL)
		printf("error: out of memory,%s,%d\n",__FUNCTION__,__LINE__);
	memset( destBuf, 0, (destLen+1)*sizeof(char) );
	
	snprintf(destBuf, destLen+1, "%.*s",(int)destLen+1, dest);
	if(destBuf == NULL){
		printf("error: base 64 encode fail\n");
		return NULL;
	}
	/*clean up*/
 	free(srcBuf);
	free(dest);
	return destBuf;
}

 /* Simple conversion using b64_decode */
char *cg_http_base64decode(char *base64Str)
{
	int destLen = 0;
	char *dest = NULL;

	/* Invoke b64_decode() to determine the maximum size of the decoded
	* string, specifying the argument 0 for the destSize parameter.
	*
	* Note: The value returned may be larger than the actual size
	* required, but will never be smaller.
	*/
	destLen = b64_decode(base64Str, cg_strlen(base64Str), NULL, 0);

	/* Using the length determined by the call to b64_decode(), create
	* a buffer of sufficient size.
	*/
	dest = (char*)malloc(destLen + 1);
	if (dest == NULL){
		printf("error: out of memory,%s,%d\n",__FUNCTION__,__LINE__);
		return NULL;
	}
	memset( dest, 0, destLen+1);
	
    	/* Perform base64 decoding. */
	destLen = b64_decode(base64Str, cg_strlen(base64Str), dest, destLen);
	return dest;
}

/* Converts a hex character to its integer value */
char from_hex(char ch) {
  return isdigit(ch) ? ch - '0' : tolower(ch) - 'a' + 10;
}

/* Converts an integer value to its hex character*/
char to_hex(char code) {
  static char hex[] = "0123456789ABCDEF";
  return hex[code & 15];
}

char *cg_http_url_encode(char *str)
{
	char *pstr = str, *buf = malloc(strlen(str) * 3 + 1), *pbuf = buf;
	while (*pstr) {
		if (isalnum(*pstr) || *pstr == '-' || *pstr == '_' || *pstr == '.' || *pstr == '~') 
			*pbuf++ = *pstr;
		else if (*pstr == ' ') 
			*pbuf++ = '+';
		else 
			*pbuf++ = '%', *pbuf++ = to_hex(*pstr >> 4), *pbuf++ = to_hex(*pstr & 15);
			pstr++;
	}
	*pbuf = '\0';
	return buf;
}

/* Returns a url-decoded version of str */
/* IMPORTANT: be sure to free() the returned string after use */
char *cg_http_url_decode(char *str)
{
  char *pstr = str, *buf = malloc(strlen(str) + 1), *pbuf = buf;
  while (*pstr) {
    if (*pstr == '%') {
      if (pstr[1] && pstr[2]) {
        *pbuf++ = from_hex(pstr[1]) << 4 | from_hex(pstr[2]);
        pstr += 2;
      }
    } else if (*pstr == '+') { 
      *pbuf++ = ' ';
    } else {
      *pbuf++ = *pstr;
    }
    pstr++;
  }
  *pbuf = '\0';
  return buf;
}
