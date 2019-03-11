function MM_showHideLayers() {for (i=0; i<(args.length-2); i+=3) if ((obj=MM_findObj(args[i]))!=null) { v=args[i+2];if (obj.style) { obj=obj.style; v=(v=='show')?'visible':(v=='hide')?'hidden':v; }obj.visibility=v; }}
function ConfirmDefault(){	if (confirm("Are you sure you want to reset the device back to the factory defaults?This will erase all of your custom configuration.")){ document.Config.submit();}}function MM_findObj(n, d) {var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layer[i].document);if(!x && d.getElementById) x=d.getElementById(n); return x;}
function MM_showHideLayers() {var i,p,v,obj,args=MM_showHideLayers.arguments;for (i=0; i<(args.length-2); i+=3) if ((obj=MM_findObj(args[i]))!=null) { v=args[i+2];if (obj.style) { objobj.style; v=(v=='show')?'visible':(v=='hide')?'hidden':v; }obj.visibility=v; }}
function MM_goToURL() {var i, args=MM_goToURL.arguments; document.MM_returnValue = false;for (i=0; i<(args.length-1); i+=2) eval(args[i]+".location='"+args[i+1]+"'");}
function showFullPath(str){fr =2;parent.frames[fr].document.open();parent.frames[fr].document.writeln(' <html>');parent.frames[fr].document.writeln(' <head>');parent.frames[fr].document.writeln(' <meta http-equiv=\"Content-Type\" content=\"text\/html; charset=iso-8859-1\">');	parent.frames[fr].document.writeln(' <title>.::Welcome to ZyXEL EMG2926-Q10A::.<\/title>');parent.frames[fr].document.writeln(' <link href=\"\/luci-static\/zyxel\/css\/expert.css\" rel=\"stylesheet\" type=\"text/css\">');parent.frames[fr].document.writeln(' <\/head>');parent.frames[fr].document.writeln(' <body>');	parent.frames[fr].document.writeln(' <div class=\"path\">');parent.frames[fr].document.writeln(' <span class=\"i_path\">'+str+'<\/span>');parent.frames[fr].document.writeln(' <\/div>');parent.frames[fr].document.writeln(' <\/body>');parent.frames[fr].document.writeln(' <\/html>');	parent.frames[fr].document.close();}
function MM_showHideLayers() {var i,p,v,obj,args=MM_showHideLayers.arguments;for (i=0; i<(args.length-2); i+=3) if ((obj=MM_findObj(args[i]))!=null) { v=args[i+2]; if (obj.style) { obj=obj.style; v=(v=='show')?'visible':(v=='hide')?'hidden':v; }obj.visibility=v; }}
function MM_openBrWindow(theURL,winName,features) {  window.open(theURL,winName,features);}
function MM_preloadImages() { var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array(); var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}}
function MM_swapImgRestore() { var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;}
function MM_swapImage() {var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}}
function checkLogout(){var flag;flag=confirm("Are you sure you want to log out?");if (flag)top.location.href="/";}
function checkExit(){var flag;flag=confirm("Are you sure you want to Exit");if (flag)top.location.href="/";}
function showtab(){var string = document.getElementById("advanced").style.display;if (string == ""){document.getElementById("advanced").style.display = "none";document.getElementById("showWord").innerHTML = "more...";}else if (string =="none"){document.getElementById("advanced").style.display = "";document.getElementById("showWord").innerHTML = "hide more";}}
function MM_popupMsg(msg) { alert(msg);}
function showWebMessage(code, msg1, msg2)
{
 fr =4;
 if(typeof(parent.frames[fr])!='undefined')
 {
	parent.frames[fr].document.open();
 	parent.frames[fr].document.writeln(' <html>');
 	parent.frames[fr].document.writeln(' <head>');
 	parent.frames[fr].document.writeln(' <meta http-equiv=\"Content-Type\" content=\"text\/html; charset=utf-8\">');
 	parent.frames[fr].document.writeln(' <title>.::Welcome to the Web-Based Configurator::.<\/title>');
 	parent.frames[fr].document.writeln(' <link href=\"\/luci-static\/zyxel\/css\/expert.css\" rel=\"stylesheet\" type=\"text/css\">');
 	parent.frames[fr].document.writeln(' <\/head>');parent.frames[fr].document.writeln(' <body>');	
 	parent.frames[fr].document.writeln(' <div id=\"messagebar\">');
 	parent.frames[fr].document.writeln(' <div class=\"barcontent\">');
 	parent.frames[fr].document.writeln(' <ul>');parent.frames[fr].document.writeln(' <li class=\"i_message\"><\/li>');
 	parent.frames[fr].document.writeln(' <li class=\"message_title\"><a style=\"color:#30466d; \">'+msg1+':<\/a><\/li>');
 	if (code == 0)
 	{
    		parent.frames[fr].document.writeln(' <li class=\"message_word\"><a style=\"color:#3d8900;\">'+msg2+'<\/a><\/li>');
 	}
 	else
 	{
    		parent.frames[fr].document.writeln(' <li class=\"message_word\"><a style=\"color:#ff3b06;\">'+msg2+'<\/a><\/li>');
 	}
 	parent.frames[fr].document.writeln(' <li class=\"message_word\"><\/li>');
 	parent.frames[fr].document.writeln(' <\/ul>');
 	parent.frames[fr].document.writeln(' <\/div>');
 	parent.frames[fr].document.writeln(' <\/div>');
 	parent.frames[fr].document.writeln(' <\/body>');
 	parent.frames[fr].document.writeln(' <\/html>');parent.frames[fr].document.close();
 }
}
function checkIpFormat(ipaddr){var i; var ipPattern = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/; var ipArray = ipaddr.match(ipPattern); if(ipaddr == "0.0.0.0"){ alert("special ip address [" + ipaddr + "] !"); return false;}if(ipArray == null){alert("invalid ip address [" + ipaddr + "] !");return false;}for(i=1;i<5;i++){if(ipArray[i] >= 255){alert("invalid ip address [" + ipaddr + "] !");return false;}}return true;}
