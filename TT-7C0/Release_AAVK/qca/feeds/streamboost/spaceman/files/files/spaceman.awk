#!/usr/bin/awk -f
BEGIN {
	ctr="[Cc]ontent-[Tt]ype: "
	slash="/"
}
{
	if (match($0,ctr)) {
		after = substr($0,RSTART+RLENGTH);
		if (match(after,slash)) {
			type = substr(after,1,RSTART-1)
			gsub(":",",",$2)
			gsub(":",",",$4)
			printf("spaceman;6,%s,%s;generic_%s\n",$4,$2,type)
		}
	}
}
