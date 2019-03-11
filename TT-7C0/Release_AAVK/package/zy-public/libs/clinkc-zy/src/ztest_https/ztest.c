/******************************************************************************/
/*
*  Copyright (C) 2012 ZyXEL Communications, Corp.
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
#include <cybergarage/http/chttp.h>
#include <cybergarage/util/clog.h>
#include <cybergarage/ssl/cssl.h>

#define CLINK_TESTCASE_HTTP_PORT 4435 
#define CLINK_TESTCASE_HTTP_PAGE "<HTML><BODY>Z_Server Say World</BODY></HTML>"
#define CLINK_TESTCASE_HTTP_URL "/index.html"
#define CLINK_TESTCASE_HTTP_LOOP 1
#define CLINK_TESTCASE_HTTPCLIENT_PAGE "<HTML><BODY>Z_Client Say Hellow</BODY></HTML>"

#define SERVER_ADDR "127.0.0.1"
#define CLIENT 1
#define SERVER 1
#define	isSecure 1

static int verify_callback(int ok, X509_STORE_CTX *ctx)
{
	printf("%s\n", __func__);
	if (ok == 0)
		{
		switch (ctx->error)
			{
			case X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY :
			case X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE :
			case X509_V_ERR_CERT_UNTRUSTED :
			ok=1;
			}
		}

	return(ok);
}

void ClinkTestcaseHttpRequestRecieved(CgHttpRequest *httpReq)
{
        CgHttpResponse *httpRes;
        httpRes = cg_http_response_new();
        cg_http_response_setstatuscode(httpRes, CG_HTTP_STATUS_OK);
        cg_http_response_setcontent(httpRes, CLINK_TESTCASE_HTTP_PAGE);
        cg_http_response_setcontenttype(httpRes, "text/html");
        cg_http_response_setcontentlength(httpRes, strlen(CLINK_TESTCASE_HTTP_PAGE));
        cg_http_request_postresponse(httpReq, httpRes);
        cg_http_response_delete(httpRes);
}
int main(void)
{
	CgHttpResponse *httpRes = NULL;
	CgHttpRequest *httpReq;
	Cgctx *s_ctxdata = NULL;
	Cgctx *c_ctxdata = NULL;
	char certfile[]="/etc/cert/cserver.org.crt";
	char keyfile[]="/etc/cert/cserver.org.key";

	char cafile[]="/etc/cert/rootca.crt";
	
	s_ctxdata = (Cgctx*) malloc(sizeof(Cgctx));
	memset(s_ctxdata, '\0', sizeof(Cgctx));;
	s_ctxdata->cert_file= certfile;
	s_ctxdata->key_file = keyfile;
	s_ctxdata->verify_mode =SSL_VERIFY_PEER /*|SSL_VERIFY_FAIL_IF_NO_PEER_CERT*/;

	
	c_ctxdata = (Cgctx*) malloc(sizeof(Cgctx));
	memset(c_ctxdata, '\0', sizeof(Cgctx));
	c_ctxdata->CAfile = cafile;
	c_ctxdata->verify_mode = SSL_VERIFY_PEER;
	c_ctxdata->verify_callback = verify_callback;
#if SERVER
        /**** HTTP Server ****/
        CgHttpServer *httpServer = cg_http_server_new();
        cg_http_server_open(httpServer, CLINK_TESTCASE_HTTP_PORT, SERVER_ADDR, isSecure, (void*)s_ctxdata);
        cg_http_server_setlistener(httpServer, ClinkTestcaseHttpRequestRecieved);
        cg_http_server_start(httpServer);
#endif

#if CLIENT
        /**** HTTP Client ****/
        {
            httpReq = cg_http_request_new();
           	cg_http_request_setmethod(httpReq, CG_HTTP_GET);
            cg_http_request_seturi(httpReq, CLINK_TESTCASE_HTTP_URL);
			cg_http_response_setcontenttype(httpReq, "text/html");
            cg_http_request_setcontentlength(httpReq, sizeof(CLINK_TESTCASE_HTTPCLIENT_PAGE));
            cg_http_request_setcontent(httpReq, CLINK_TESTCASE_HTTPCLIENT_PAGE);
			if(isSecure){
				httpReq->ctxdata = (void*)c_ctxdata;
				httpRes =cg_https_request_post(httpReq, SERVER_ADDR, CLINK_TESTCASE_HTTP_PORT);
			}
			else{
				httpRes =cg_http_request_post(httpReq, SERVER_ADDR, CLINK_TESTCASE_HTTP_PORT);
			}
            printf( "cg_http_response_getstatuscode=%d\n", cg_http_response_getstatuscode(httpRes));
            cg_streq(cg_http_response_getcontent(httpRes), CLINK_TESTCASE_HTTP_PAGE);
			printf("Response content :\n%s\n", cg_http_response_getcontent(httpRes));
            cg_http_request_delete(httpReq);
        }
		free(c_ctxdata);
#else
		while(1){
			printf("live\n");
			sleep(5);
		}
#endif
        /**** HTTP Server ****/
#if SERVER
        cg_http_server_stop(httpServer);
		cg_http_server_delete(httpServer);
		free(s_ctxdata);
#endif		
		return 0;
}

