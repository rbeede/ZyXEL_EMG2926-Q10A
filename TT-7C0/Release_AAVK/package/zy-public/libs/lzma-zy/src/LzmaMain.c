#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <getopt.h>
#include "Lzma.h"


int main(int argc, char* argv[]){
	int opt = 0, flag = 0;
	char fileName[64];
	char fileNameDst[64];
	FILE  *fp, *fp1;

//	clogSetUp("lzma", clogType, clogLevel);
	openlog("lzma", LOG_NOWAIT, LOG_USER);
	
	while((opt = getopt(argc, argv, "c:d:n:")) != -1){
		switch(opt){
			case 'c':
				syslog(LOG_DEBUG, "ccc\n");
				strcpy(fileName, optarg);
				flag = 1;
				break;
			case 'd':
				syslog(LOG_DEBUG, "ddd\n");
				strcpy(fileName, optarg);
				break;
			case 'n':
				syslog(LOG_DEBUG, "nnn\n");
				strcpy(fileNameDst, optarg);
				break;				
			default:
				printf("PROTOTYPE:\n");
				printf("%-8s %s\n", " ", "compress file:   lzma -c [uncompress file] -n [target name]");
				printf("%-8s %s\n", " ", "decompress file: lzma -d [compress file] -n [target name]");
				return 0;
		}
	}

	if (argc == 1){
		printf("lzma -h for help\n");
		return 0;
	}
	syslog(LOG_DEBUG, "flag :%d\n", flag);
	if (flag == 1){
		syslog(LOG_DEBUG, "compress data from %s to %s\n", fileName, fileNameDst);

		fp = fopen( fileName, "r");
		if( fp == NULL){
			syslog(LOG_ERR, "fopen src file fail\n");		
			return -1;
		}
		
		fp1 = fopen( fileNameDst, "w");
		if( fp == NULL){
			syslog(LOG_ERR, "fopen dst file fail\n");		
			return -1;
		}
		
		FileEncode(fp, fp1);

		fclose(fp);
		fclose(fp1);
	
	}
	else{
		syslog(LOG_DEBUG, "decompress data from %s to %s\n", fileName, fileNameDst);
		fp = fopen( fileName, "r");
		if( fp == NULL){
			syslog(LOG_ERR, "fopen src file fail\n");		
			return -1;
		}
		
		fp1 = fopen( fileNameDst, "w");
		if( fp == NULL){
			syslog(LOG_ERR, "fopen dst file fail\n");		
			return -1;
		}
		
		FileDecode(fp, fp1);

		fclose(fp);
		fclose(fp1);		
	}
	
	return 0;
}
