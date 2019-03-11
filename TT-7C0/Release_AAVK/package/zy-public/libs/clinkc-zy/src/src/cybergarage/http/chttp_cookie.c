/******************************************************************
*
*	File: chttp_cookie.c
*
*	Revision:
*
*	07/19/12
*		- first release ZyXEL
*
******************************************************************/


#include <cybergarage/http/chttp_cookie.h>
#include <string.h>

/*************************
* Function 	: cg_http_cookie_attribute_parse()
* Description	: parse the cookie attribute
* Output 	: 
*************************/
static void cg_http_cookie_attribute_parse( char *attr, CgHttpCookieData *cookiedata ){
	char *ptr = NULL;
	char name[SIZE_COOKIE_NAME+1] = {0};
	char value[SIZE_COOKIE_VALUE+1] = {0};

	ptr = strchr( attr, '=' );
	if( ptr != NULL ){
		strncpy( name, attr, (ptr-attr)>SIZE_COOKIE_NAME?SIZE_COOKIE_NAME:(ptr-attr) );
		strncpy( value, ptr+1, SIZE_COOKIE_VALUE);
	}
	else{
		strncpy( name, attr, SIZE_COOKIE_NAME );
	}
	
	if(strcasecmp(name, CG_HTTP_COOKIE_COMMENT)==0 && strlen(value)>0 ){
		strncpy(cookiedata->comment, value, SIZE_COOKIE_COMMENT);
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_URL)==0 && strlen(value)>0 ){
		strncpy(cookiedata->commentURL, value, SIZE_COOKIE_URL);
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_DISCARD)==0){
		cookiedata->discard = TRUE;
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_DOMAIN)==0 && strlen(value)>0 ){
		strncpy(cookiedata->domain, value, SIZE_COOKIE_DOMAIN);
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_MAXAGE)==0 && strlen(value)>0 ){
		/*A value of zero means the cookie SHOULD be discarded immediately*/
		strncpy(cookiedata->maxAge, value, SIZE_COOKIE_MAXAGE);
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_PATH)==0 && strlen(value)>0 ){
		strncpy(cookiedata->path, value, SIZE_COOKIE_PATH);
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_PORT)==0 && strlen(value)>0 ){
		strncpy(cookiedata->port, value, SIZE_COOKIE_PORT);
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_SECURE)==0){
		cookiedata->secure = TRUE;
	}
	else if(strcasecmp(name, CG_HTTP_COOKIE_VERSION)==0 && strlen(value)>0 ){
		strncpy(cookiedata->version, value, SIZE_COOKIE_VERSION);
	}
	else{
		/*The NAME=VALUE attribute-value pair MUST come first in each cookie.*/
		if(strlen(value)>0 && strlen(cookiedata->name)==0){
			strncpy(cookiedata->name, name, SIZE_COOKIE_NAME);
			strncpy(cookiedata->value, value, SIZE_COOKIE_VALUE);
		}
	}
	
}

/*************************
* Function 	: cg_http_cookie_header_parse()
* Description	: parse the cookie
* Output 	: 
*************************/
void cg_http_cookie_header_parse( char *cookie, CgHttpCookieData *cookiedata ){
	char buf[SIZE_COOKIE+1]={0};
	char delim[]="; ";
	char *token = NULL;

	strncpy(buf, cookie, SIZE_COOKIE);
	token = strtok( buf, delim );
	while( token != NULL ){
		cg_http_cookie_attribute_parse(token, cookiedata);
		token = strtok( NULL, delim );
	}
}

