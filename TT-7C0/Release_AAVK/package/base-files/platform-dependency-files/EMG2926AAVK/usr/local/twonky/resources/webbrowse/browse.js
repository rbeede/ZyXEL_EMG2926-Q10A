// server language file
var serverLanguageFile = new Array();
// convert-readme.txt file with license informations
var convertReadmeFile = "";
// Reload side after overlay dialog has been closed
var setReloadSide = false;
// detect safari browser
var browser = "other";
// detect Mac OS
var os = "other";

// timer which clear the background spinner after 5 seconds
var loadingGraficActiv;

//An object containing all the data for the Status page.
var statusData = {};

// Get this number of items/container from the nmc
var nmcItemCount = 30;
// show max items on the screen at once
var itemsLimit = 6000;
// monitor the items beyond nmcItemCount.
// replace the templates with media content if an item becomes visible or if a timer fires
var monitorItems = new Array();
// timer to replace templates with media content
var timerLoadMore = "";
var timerLoadMoreInterval = 3500;

var persistentIDMusic = "music";
var persistentIDPhoto = "picture";
var persistentIDVideo = "video";
var currentPersistentID = "";

var navTreeSpecialItem = false;
var foreignUnknownServer = false;
var foreignUnknownServerClass = persistentIDVideo;

var timer;
var timerInterval = 1000;
var lastHash = "";

// default thumbnails of items
var videoDefaultImg = "/resources/webbrowse/gen_video_100.png";
var musicDefaultImg = "/resources/webbrowse/gen_music_40.png";
var photoDefaultImg = "/resources/webbrowse/gen_photo_100.png";
// default thumbnails of containers
var noCoverAudio = "/resources/webbrowse/nocover_audio.jpg";
var noCoverPhoto = "/resources/webbrowse/nocover_photo.jpg";
var noCoverVideo = "/resources/webbrowse/nocover_video.jpg";

// multi user support vars of the current selected server
var multiusersupportenabled = "false";		// is disabled
var serverIndex = 0;			// index of the current server in the server list
var serverURL = "";
var serverTitle = "";
var serverBookmark = "";
var username = "";
var password = "";
// array contains the login credentials and MUS vars of all servers
var serverAccess = new Array();
// array to store the well known bookmarks of the servers
var wellKnownBookmarks = new Array();

// the error status is set if the content area can not be build
// errors see function showNavigationError()
var navigateServerStatus = 0;			// 0 = no error occurred
var navigateServerStatusString = "";	// error message from nmc

var resolutionBranch = 160*160;
var resolutionVideo = 100*100;
var resolutionMusic = 45*45;
var resolutionPhoto = 100*100;


// ---- Initialize the Browse application
function initPage() {
	loadFooterHtml();			// read the footer
    browserIdentification();	// identify browser
    osIdentification();			// identify OS
    statusData["privacypolicy"] = "http://my.twonky.com/user/privacy";
    getConvertReadmeFile();		// license file
	getMultiUserSupportFlag();	// get the flag multiusersupportenabled
    readLanguageFile();			// get the translations from the server
    onLanguageFetched();
	getServerCookies();			// get the server cookies and add them to the global var serverAccess
    initBase();					// build navigation and content area
    initTimer();				// refresh page (IE has no event handling for browser back button)
}
function loadFooterHtml(){
    var data = makeGetRequest("/resources/webbrowse/indexFooter.htm", {});
	var id = document.getElementById("twFooter");
	id.innerHTML = data;
}

// initialize page
function initBase() {
    var id;
    var hash = window.location.hash;
    if (hash) hash = hash.substring(1, hash.length); // remove hash mark
    switch (hash) {
        case "":
        case "video":
            // load/refresh Video
            initBaseRoot(persistentIDVideo);
            break;
        case "music":
            // load/refresh Music
            initBaseRoot(persistentIDMusic);
            break;
        case "photo":
            // load/refresh Photo
            initBaseRoot(persistentIDPhoto);
            break;
        default:
            // refresh child page with containers and/or items
            initBaseAfterRefresh(hash);
    }
}
function initBaseRoot(persistentID) {
    // initialize the page
	currentPersistentID = persistentID;
    lastHash = currentPersistentID;
    loadSkeleton();								// add navigation area and breadcrumb
	loadServersList();							// add servers list
	loadRendererList();							// add renderer list
    resetContentArea();
	markRootGroup(currentPersistentID);
	// get the data	for "My Servers" and "My Devices" on the left side of the page
	populateRendererList(currentPersistentID);		// get and show renderer list (My Devices)
	populateServersList();							// get and show servers list (My Servers)
}
// ------------------ login
// if multi user support is enabled login with username and password is required
function loginRequired() {
	if (multiusersupportenabled == "false") {
		// hide the log out link in the header of the page
		addClass("login", "hide");
		return false;	// multi user support is disabled - login not necessary
	}
	// was authentification already successful ?
	if (authentificationOK()) return false;	
	// show the login
	if (!loadLoginHtml()) return true;				// could not load the login html code
	return true;
}
// load the html page to login
function loadLoginHtml() {
	var id;
    try {
		resetObjectsBeforeLogin();			// clear the area
		// show the login page
        var response = httpGet("/resources/webbrowse/server-login.htm");
        if (!response) return false;
        id = document.getElementById("browseContents");	
        id.innerHTML = response;						// show the login content
        replaceStrings("serverlogin");
        id = document.getElementById("logintext");
        id.innerHTML += serverTitle;
		document.getElementById("username").focus();	// set focus to the username entry field	
		return true;
    } catch (e) {
		return false;
    }
}
function usernameInputKeyUp(event) {
	var id;
    if (event.which == 13) {		// key enter was pressed
		id = document.getElementById("username");
		if (id.value == "guest") {	// is default user guest
			loginOK();				// login guest
			return;
		} else {					// set focus to password
			id = document.getElementById("password").focus();
			return;
		}
    }
	// user is entering a username - enable the password entry field 
	id = document.getElementById("password");
	id.disabled = false;
}
function passwordInputKeyUp(event) {
    if (event.which == 13) {		// key enter was pressed
		loginOK();					// login user
	}
}
// username and password have been entered by the user
function loginOK() {
	var id = document.getElementById("username");
	username = id.value;
	id = document.getElementById("password");
	password = id.value;
	if (credentialsOk()) {
		// login ok! 
		// save the login credentials and show the content
		var a = new Array();
		a["url"] = serverURL;
		a["bookmark"] = serverBookmark;
		a["title"] = serverTitle;
		a["user"] = username;
		a["pwd"] = password;
		serverAccess.push(a);
		setServerCookie(a, serverAccess.length-1);	// set server access cookie
		// show the user name and the link to log out
		var s = getString("logout");
		id = document.getElementById("loginUser");
		id.innerHTML = s.toLowerCase() + " " + username;
		removeClass("login", "hide");
		// show the content
		buildScreen("");			
	}
}
// check the credentials
function credentialsOk() {
	var response = httpGet("/nmc/rpc/check_multiuser_access?server=" + serverBookmark + "&user=" + username + "&password=" + password);
	try {
		var rc = parseJson(response); 		// transform json item to object
	} catch (e) {
		var id = document.getElementById("loginFailed");
		id.innerHTML = getString("loginfailed") + " http request";			
		return false;						
	}
	if (itemHasProperty(rc, "success")) {
		if (rc.success == true) return true;	// login ok
		else {									// login failed
			var id = document.getElementById("loginFailed");
			id.innerHTML = getString("loginfailed") + " " + rc.message;			
			return false;						
		}
	}
	var id = document.getElementById("loginFailed");
	id.innerHTML = getString("loginfailed") + " general";			
	return false;						
}
// was the user authentification already successful (test with the current server bookmark)
function authentificationOK() {
	// lookup the current server
	for (var i = 0; i < serverAccess.length; i++) {
		if (serverAccess[i].bookmark == serverBookmark) {
			// show the user name and the link to log out
			var s = getString("logout");
			var id = document.getElementById("loginUser");
			id.innerHTML = s.toLowerCase() + " " + serverAccess[i].user;
			removeClass("login", "hide");
			username = serverAccess[i].user;
			password = serverAccess[i].pwd;
			return true;
		}
	}
	return false;
}
// remove the authentification
// bookmark: server bookmark to remove
function removeAuthentification(bookmark) {
	// lookup the bookmark
	for (var i = 0; i < serverAccess.length; i++) {
		if (serverAccess[i].bookmark == bookmark) {
			// remove the authentification
			serverAccess.splice(i,1);
			addClass("login", "hide");	// hide the log out button
			setServerCookies();			// set all server access cookies
			return;
		}
	}
}
// clear HTML objects
function resetObjectsBeforeLogin() {
	id = document.getElementById("serverSettingsContentWrapper");
	id.style.display = "block";						// show content area
	id = document.getElementById("browseContents");
	id.innerHTML = "";								// clear content area
	id = document.getElementById("breadcrumb");		// clear the breadcrumb on top of the content area
	id.innerHTML = "";
}
// logout user from server
function logout() {
	removeAuthentification(serverBookmark);	// remove the login credentials
	resetObjectsBeforeLogin();				// clear HTML objects
	document.execCommand('ClearAuthenticationCache', 'false');	// do it for IE
	// select the current server
	selectServer(escape(serverURL), escape(serverTitle), serverBookmark, multiusersupportenabled);
}


// ----- cookie functions
var serverAccessCookie = "twserver";
// get the server access cookies
// example: twserverX=username|pwd|bookmark|url|title (X = number)
function getServerCookies() {
	clearArrayServerAccess();	// clear the global array serverAccess
	if (!(document.cookie)) return;
	var cookies = document.cookie;
	var oneCookie = cookies.split(";");
	for (var j=0;j<oneCookie.length;j++) {
		var cookie = oneCookie[j].split("=");		// cookie[0]=id, cookie[1]=value
		if (cookie[0].indexOf(serverAccessCookie) >= 0) {
			if (cookie[1] == "") continue;
			// save the login credentials in the global var serverAccess
			var s = cookie[1].split("|");
			if (s.length == 5) {
				var a = new Array();
				a["user"] = s[0];
				a["pwd"] = s[1];
				a["bookmark"] = s[2];
				a["url"] = s[3];
				a["title"] = s[4];
				serverAccess.push(a);
			}
		}
	}
}
// set a server access cookie (example: twserver0=user|pwd|bookmark|url|title)
// serverAccessArray: user|pwd|bookmark|url|title
function setServerCookie(serverAccessArray, index) {
	try {
		var cookieValue = serverAccessArray["user"] + "|" + serverAccessArray["pwd"] + "|" + serverAccessArray["bookmark"] + "|" + serverAccessArray["url"] + "|" + serverAccessArray["title"];
		document.cookie = serverAccessCookie + index + "=" + cookieValue;
	} catch (e) {
	}
}
// set all server access cookies
function setServerCookies() {
	if (!(document.cookie)) return;
	resetServerCookies();		// clear the cookies
	// save the server logins in cookies
	for (var i = 0; i < serverAccess.length; i++) {
		setServerCookie(serverAccess[i], i);
	}
}
// clear the server access cookies (value is empty)
function resetServerCookies() {
	if (!(document.cookie)) return;
	var cookies = document.cookie;
	var oneCookie = cookies.split(";");
	for (var j=0;j<oneCookie.length;j++) {
		var cookie = oneCookie[j].split("=");		// cookie[0]=id, cookie[1]=value
		if (cookie[0].indexOf(serverAccessCookie) >= 0) 
			document.cookie = cookie[0] + "=";
	}
}
// clear the global array serverAccess
function clearArrayServerAccess() {
	if (serverAccess.length == 0) return;
	while (serverAccess.length > 0) {
		serverAccess.pop();
	}
}


// --------------- refresh screen
function initBaseAfterRefresh(hash) {
	getServerCookies();				// get the server cookies and add them to the global var serverAccess
    // get item with parent list
    var response = httpGet(hash + "&fmt=json");
    if (!response) {
        initBaseRoot(persistentIDVideo);
        return;
    }
    try {
        var list = parseJson(response); 		// transform json item to object
    } catch (e) {
        return;
    }
    if (itemHasProperty(list, "error")) {
        initBaseRoot(persistentIDVideo);
        return;
    }
    var parentListLength = getNMCPropertyInt(list, "parentList.length");
    if (parentListLength >= 1) {
        serverURL = getNMCPropertyText(list, "parentList.url", parentListLength - 1); 		// root
		currentPersistentID = getObjIDFromTitle(list);
        lastHash = currentPersistentID;
        markRootGroup(currentPersistentID);
		loadSkeleton();						// add navigation area and breadcrumb
		loadServersList();					// add servers list
		loadRendererList();					// add renderer list
		resetContentArea();
		// get the data	for "My Servers" and "My Devices" on the left side of the page
		populateRendererList(currentPersistentID);		// get and show renderer list (My Devices)
		populateServersList();							// get and show servers list (My Servers)
    }
    // build breadcrumb and mark current title in left navigation
	var navigationIsGiven = false;
	var parentListIndex = 0;
	var parentListMinIndex = 0;
	if (parentListLength >= 2) {
		navigationIsGiven = true;
		parentListIndex = parentListLength - 3;	// (-1)root, (-2)video/music/photo, (-3)Album/All photos/....
		parentListMinIndex = 2;					// parent: root, parent: video/music/photo
	}
	if (foreignUnknownServer && (parentListLength >= 1)) {
		navigationIsGiven = true;
		parentListIndex = parentListLength - 2;	// (-1)root, (-2)video/music/photo
		parentListMinIndex = 1;					// parent: root
	}
	if (navigationIsGiven) {	// mark item in left navigation
        if (parentListLength == parentListMinIndex) markLeftNavigation(getNMCPropertyText(list, "id"));
        else markLeftNavigation(getNMCPropertyText(list, "parentList.id", parentListIndex));
        buildBreadcrumb(list);
    }
}

// ---- navigation
// navigate to settings page
function navigateToUrl(param) {
    window.location.href = param;
}
// navigate web browse
function navigateTo(params) {
	// navigate to new location
    var id;
    if (params) window.location.hash = params;		// change hash
    lastHash = window.location.hash;
    resetContentArea();
    switch (params) {
        case "settings":
            navigateToUrl("/webconfig");
            break;
        case "":
        case "video":
            buildRootAndLeftNavigation(persistentIDVideo);
            break;
        case "music":
            buildRootAndLeftNavigation(persistentIDMusic);
            break;
        case "photo":
            buildRootAndLeftNavigation(persistentIDPhoto);
            break;
        case "licenseinfo":
            showLicenseInfo();
            break;
        default:
			if (loginRequired()) return;
            // show content - Parameter: id, startPage, count
            loadMediaBrowseContent(params);
            break;
    }
}
function resetContentArea() {
    try {
		id = document.getElementById("serversContainer");
		id.style.display = "block";			// show servers list
		id = document.getElementById("rendererContainer");
		id.style.display = "block";			// show renderer list
        id = document.getElementById("serverSettingsContentWrapper");
        id.style.display = "block";			// show content area
        id = document.getElementById("browseContents");
        id.innerHTML = "";					// clear content area
        id = document.getElementById("licenseInfoPage");
        id.style.display = "none";			// hide license info page
        id = document.getElementById("breadcrumb");
        id.innerHTML = "";					// clear breadcrumb (above content area)
        id = document.getElementById("browsePages");
        id.innerHTML = "";					// clear page area (below content area)
    } catch (e) {
    }
}

function buildRootAndLeftNavigation(pID) {
    markRootGroup(pID);
    currentPersistentID = pID;
	// get the data	for "My Servers" and "My Devices" on the left side of the page
	populateRendererList(currentPersistentID);		// get and show renderer list (My Devices)
	populateServersList();							// get and show servers list (My Servers)

}
function buildScreen(hash) {
	if (hash == "") {
		// get the structure of one media base container (video, music or photo) and display it below the server name
		var url0 = populateLeftNavigation();			// get and show navigation entries (below the server name)
		// get the data for the content area on the right site (show the container and items)
		if (url0 == "") {
			showNavigationError();
		} else {
			loadMediaBrowseContent(url0);			// get the content and display it
			if (currentRenderer[currentPersistentID] == localdevice) showLocalDeviceBox(false, true);
		}
	} else {
		loadMediaBrowseContent(hash);					// get and show browse content
	}
}
function showNavigationError() {
	var html = "";
	var s = "";
	switch (navigateServerStatus) {
		case 1:		// internal error
			s = getString("navigateserverstatus1")+ "(" + navigateServerStatusString + ")";
			break;
		case 2:		// no media
			s = getString("navigateserverstatus2");
			break;
		default:	// unknown error
			s = getString("navigateserverstatus0");
	}
	navigateServerStatus = 0;
	html = '<div class="subHeader"><span class="">' + s + '</span></div>';	
	try {
		var id = document.getElementById("browseContents");
		id.innerHTML = html;
	} catch (e) {
	}	
}
// mark the current root item and navigation item
function markRootGroup(pID) {
    removeClass(persistentIDVideo + "text", "navactive");
    removeClass(persistentIDMusic + "text", "navactive");
    removeClass(persistentIDPhoto + "text", "navactive");
    addClass(pID + "text", "navactive");
}
// mark the current selected navigation tree entry
function markLeftNavigation(id) {
	var id1 = "id" + serverIndex + "_" + id;
	var leftNavBrowse = "leftNavBrowse" + serverIndex;
    try {
        var elem = document.getElementById(leftNavBrowse);
        var l = elem.children.length;
        var j = 1000;
        for (var i = 0; i < l; i++) {
            removeClass(elem.children[i].id, "current");
            if (elem.children[i].id == id1) j = i;
        }
        if (j < 1000) addClass(elem.children[j].id, "current");
    } catch (e) {
    }
}


// ----------- 1. - get server list 
// ----> prepare the servers list
function resetServersArea() {
    try {
        id = document.getElementById("browseServers");
        id.innerHTML = "";					// clear servers list
    } catch (e) {
    }
}
// load the servers list on the left navigation area (My Servers)
function loadServersList() {
    try {
        if (document.getElementById("leftColumn1")) return;   // servers list is already loaded
        var response = httpGet("/resources/webbrowse/servers-nav.htm");
        if (!response) return;
        var id = document.getElementById("serversContainer");
        id.innerHTML = response;
        replaceStrings("leftColumn1");
    } catch (e) {
    }
}
// build the servers list
function populateServersList() {
    showLoadingGraphic();
    var html = "";
    var response = httpGet("/nmc/rss/server" + "?start=0&fmt=json");
    if (!response) hideLoadingGraphic();
    try {
        var list = parseJson(response); 				// transform json item to object
    } catch (e) { hideLoadingGraphic(); }
    if (itemHasProperty(list, "error")) { hideLoadingGraphic(); return; }

    if (list.length == 0) { hideLoadingGraphic(); return; }
    var itemCount = getReturnedItems(list);				// item count
    for (var i = 0; i < itemCount; i++) {
		var id = "S" + i;
		var url = getNMCPropertyText(list, "item.url", i);
		var title = getNMCPropertyText(list, "item.title", i);
		var bookmark = getNMCPropertyText(list, "item.bookmark", i);
		var musEnabled = getNMCPropertyText(list, "item.multiUserSupport", i);
		var leftNavContainer = "leftNavContainer" + i;
		var leftServerContainer = "leftServerContainer";
		// add server to the list
		html += '<li name="leftServerContainer" id="' + id + '" serverurl="' + escape(url) + '"onclick="selectServer(\'' + escape(url) + '\', \'' + escape(title) + '\', \'' + bookmark + '\', \'' + musEnabled + '\')"><a>' + title + '</a></li>';
		html += '<div id="' + leftNavContainer + '" class="leftNavContainer" >';
		html += '</div>';
		// store the well known bookmarks
		storeWellKnownBookmarks(url, list.item[i]);
		// a) after a reload the serverURL is the parent server. Set the title, bookmark and the multi user flag.
		if ((serverURL == url) && (serverBookmark == "")) {		
			serverTitle = title;					// title of the local Twonky server
			serverBookmark = bookmark;				// bookmark of the local Twonky server
			multiusersupportenabled = musEnabled;	// multi user support enabled
		}
		// b) the current server is the local server and no serverURL is set.
        if (isLocalServer(list, i)) {				// is it the local Twonky server?
			if (serverURL.length == 0) {
				serverURL = url;				// url of the local Twonky server
				serverTitle = title;			// title of the local Twonky server
				serverBookmark = bookmark;		// bookmark of the local Twonky server
				multiusersupportenabled = musEnabled;	// multi user support enabled
			}
		}
    }
    try {
		// highlight the local Twonky server in the server list
        var id = document.getElementById("browseServers");
        id.innerHTML = html;					// show the server list
		selectServer(escape(serverURL), escape(serverTitle), serverBookmark, multiusersupportenabled);	
    } catch (e) { }
    hideLoadingGraphic();
}
// store the well known bookmarks of the servers
// structure: wellKnownBookmarks[i].url
//			  wellKnownBookmarks[i].item[j].realContainerId
//			  wellKnownBookmarks[i].item[j].value
function storeWellKnownBookmarks(url, serverItem) {
	if (!itemHasProperty(serverItem, "wellKnownBookmarks")) return;		// server has no well known bookmarks
	var a = new Array();
	a["url"] = url;
	var b = new Array();
	for (var i=0; i<serverItem.wellKnownBookmarks.length; i++) {
		b.push(serverItem.wellKnownBookmarks[i]);
	}
	a["item"] = b;
	wellKnownBookmarks.push(a);
}
// return the well known bookmark as string (music, album, ...)
// return empty string, if there is no bookmark for this bookmark ID 
function getWellKnownBookmark(url, bookmarkId) {
	for (var i=0; i<wellKnownBookmarks.length; i++) {
		if (wellKnownBookmarks[i].url == url) {										// found server
			for (var j=0;j<wellKnownBookmarks[i].item.length;j++) {	
				if (wellKnownBookmarks[i].item[j].realContainerId == bookmarkId) {	// found bookmark
					var bookmark = wellKnownBookmarks[i].item[j].value;
					return bookmark.substring(2, bookmark.length);
				}
			}
		}
	}
	return "";
}
// return true, if it is a server with well known bookmarks
// return false, if not
function isServerWithWellKnownBookmark(url) {
	for (var i=0; i<wellKnownBookmarks.length; i++) {
		if (wellKnownBookmarks[i].url == url) {										// found server
			return true;
		}
	}
	return false;
}
// highlight the server in the server list (this is the current selected server)
// update the global vars serverIndex, serverUrl, serverTitle, serverBookmark, multiusersupportenabled
// check if a *** user login *** is required
function selectServer(urlEscaped, titleEscaped, bookmark, musEnabled) {
	var leftNavContainer = "leftNavContainer";
	var leftServerContainer = "leftServerContainer";
	var title = unescape(titleEscaped);
	var url = unescape(urlEscaped);
    try {
		// child 1:	server 					<li id="S0" class="current" onclick="selectServer(...
		// child 2:	server navigation tree 	<div id="leftNavContainer0" class="leftNavContainer" style="display: block;"> <ul id="leftNavBrowse0"> <li ...
        var elem = document.getElementById("browseServers");
		// hide the navigation trees
        var l = elem.children.length;
        for (var i = 1; i < l; i = i + 2) {
			elem.children[i].style.display = "none";
        }
		// de-select the server in the server list
        var j = 1000;
        for (i = 0; i < elem.children.length; i = i + 2) {
            removeClass(elem.children[i].id, "current");
			var svrurl = getAttributeValue(elem.children[i], "serverurl");	// serverurl is escaped
			if (unescape(svrurl) == url) j = i;
        }
		// select the current server and show his navigation tree
        if (j < 1000) {
			// mark the selected server in the server list "My Servers"
			addClass(elem.children[j].id, "current");
			// set the global server vars
			serverIndex = j/2;
			serverURL = url;
			serverTitle = title;
			serverBookmark = bookmark;
			multiusersupportenabled = musEnabled;
			// show the login page or show "My Library" and the content
			if (!loginRequired()) buildScreen("");
		}
    } catch (e) {
    }
}

// returns the local Twonky server url or the url of the first server in the rss server list
function getServerURL() {
    var r = httpGet("/nmc/rss/server" + "?start=0&fmt=json");
    if (!r) {
		navigateServerStatus = 0;				// can not get the server list -> unknown error
		return "";
	}
    try {
        var list = parseJson(r); 				// transform json item to object
    } catch (e) {
		navigateServerStatus = 0;				// server list is not readable -> unknown error
        return "";
    }
    if (itemHasProperty(list, "success")) {
		if (!list.success) {
			navigateServerStatus = 1;			// server list returned an error -> internal error (<error message>)
			if (itemHasProperty(list, "message"))
				navigateServerStatusString = list.message;	// error message like device does not exist, failed to connect to device ....
			return "";
		}
	}
    var itemCount = getReturnedItems(list);		// item count
	if (itemCount == 0) {
		navigateServerStatus = 2;				// server has no items		-> no media	
		return "";
	}
    for (var i = 0; i < itemCount; i++) {       // find the local Twonky server
        if (isLocalServer(list, i)) {
			return getNMCPropertyText(list, "item.url", i);	// return the url of the local Twonky server
		}
    }
	return getNMCPropertyText(list, "item.url", 0);			// return the url of the first server in the rss server list
}
// is it the local Twonky server?
function isLocalServer(elem, index) {
    var isLocalDevice = (getNMCPropertyText(elem, "item.server.isLocalDevice", index) == "true");
    var knownServer = getNMCPropertyText(elem, "item.server.knownServer", index);
	if (knownServer.length <= 6) return false;
    // server found if running on local device and server is Twonky
    if (isLocalDevice && (knownServer.substr(0,6) == "Twonky")) return true;
    return false;
}
function getPort(url) {
    try {
        var i = url.indexOf(":", 6);
        if (i < 0) return "";
        return url.substr(i + 1, 4);
    } catch (e) {
        return "";
    }
}

// ----------- 2. - get root container with video, photo and music
function getBaseContainer() {
	foreignUnknownServer = false;
    navTreeSpecialItem = false;
    if (serverURL == "") {
        serverURL = getServerURL();
    }
    if (serverURL == "") return "";		// error is set in getServerURL()
    var r = httpGet(serverURL + "?start=0&fmt=json");
    if (!r) {
		navigateServerStatus = 0;		// can not get the base container -> unknown error	
		return "";
	}
    try {
        var list = parseJson(r); 		// transform json item to object
    } catch (e) {
		navigateServerStatus = 0;		// base container is not correct -> unknown error
        return "";
    }
    if (itemHasProperty(list, "success")) {
		if (!list.success) {
			navigateServerStatus = 1;	// base container returned an error -> internal error
			if (itemHasProperty(list, "message"))
				navigateServerStatusString = list.message;	// error message like device does not exist, failed to connect to device ....
			return "";
		}
	}
    var itemCount = getReturnedItems(list);	// item count
    var child = getItem(list, 0);
    if (child == "") {
		navigateServerStatus = 2;		// no base container -> no media
		return "";
	}
	// twonky server - only the Twonky server has this property
	if (itemHasProperty(child, "meta.pv:persistentID")) {
		showVideoMusicPhotoHeader(true);
		for (var i = 0; i < itemCount; i++) {        // find the media content video, photo or music
			if (getNMCPropertyText(list, "meta.pv:persistentID", i) == currentPersistentID)
				return getNMCPropertyText(list, "item.url", i);
		}
		// check if it is a special item (no video, music or photo container)
		if (itemCount == 1) {
			var upnpclass = getNMCPropertyText(list, "item.meta.upnp:class", 0);
			if (upnpclass.indexOf("container") < 0) {
				// it is a special item
				navTreeSpecialItem = true;
				return getNMCPropertyText(list, "meta.id", 0);		
			}
		}
		navigateServerStatus = 2;			// base container not found -> no media
		return "";
	}
	// foreign server with well known bookmarks
	if (isServerWithWellKnownBookmark(serverURL)) {
		showVideoMusicPhotoHeader(true);
		for (var i = 0; i < itemCount; i++) {        // find the media content video, photo or music
			var itemId = getNMCPropertyText(list.item[i], "meta.id");
			if (isCurrentPersistentID(itemId))
				return getNMCPropertyText(list, "item.url", i);		// found the well known bookmark
		}
		navigateServerStatus = 2;			// base container not found -> no media
		return "";
	}
	// foreign unknown server
	showVideoMusicPhotoHeader(false);
	foreignUnknownServer = true;
	return serverURL;
}
function isCurrentPersistentID(itemId) {
	var knownId = getWellKnownBookmark(serverURL, itemId);
	if (knownId == "") return false;
	if (knownId == currentPersistentID) return true;
	return false;
}
// show or hide the header "video music photo"
function showVideoMusicPhotoHeader(showHeader) {
	var idV = document.getElementById("video");
	var idM = document.getElementById("music");
	var idP = document.getElementById("picture");
	if (showHeader) {
		idV.style.display = "block";
		idM.style.display = "block";
		idP.style.display = "block";
	} else {
		idV.style.display = "none";
		idM.style.display = "none";
		idP.style.display = "none";
	}
}
// ----------- 3. - build the skeleton with the main html-container:
//   - title and navigation on top of the content area = breadcrumb
//   - content area = browseContents
//   - pages below the content area = browsePagination
function loadSkeleton() {
    try {
        var id = document.getElementById("serverSettingsContentWrapper");
        id.innerHTML = "<div id='breadcrumb' class='breadcrumb'></div>\
						<div id='browseContents'></div></div>\
						<div class='clear'></div>\
						<div id='browsePagination'><div id='browsePages' class='browsePages largeFont'></div></div>";
        id.className += " contentDisplay";
    } catch (e) {
    }
}

			
// ----------- 4. - populate the left navigation tree
// build the navigation tree of the selected server and show this tree
// return url of the first item or an empty string
function populateLeftNavigation() {
	var leftNavContainer = "leftNavContainer" + serverIndex;
	var leftNavBrowse = "leftNavBrowse" + serverIndex;
    var baseContainer = getBaseContainer();
	var rc = "";
    showLoadingGraphic();
    var html = "";
    if (baseContainer == "") {				// error is set in getBaseContainer()
        clearContentArea();
        hideLoadingGraphic();
        return rc;
    }
    var response = httpGet(baseContainer + "?start=0&fmt=json");
    if (!response) {
        clearContentArea();
		navigateServerStatus = 0;			// can not get the base container -> unknown error
        hideLoadingGraphic();
        return rc;
    }
    // show the left navigation tree
    try {
        var list = parseJson(response);		// transform json item to object
    } catch (e) {
		navigateServerStatus = 0;			// base container is corrupt -> unknown error
        hideLoadingGraphic();
        return rc;
    }
    if (itemHasProperty(list, "success")) {
		if (!list.success) {
			navigateServerStatus = 1;		// base container returned an error -> internal error
			if (itemHasProperty(list, "message"))
				navigateServerStatusString = list.message;	// error message like device does not exist, failed to connect to device ....
			return rc;
		}
	}
    var itemCount = getReturnedItems(list);
    if (itemCount == 0) {
        clearContentArea();
		navigateServerStatus = 2;			// base container has no items -> no media
        hideLoadingGraphic();
        return rc;
    }
	// build the html code of the navigation tree
	html += '<ul id="' + leftNavBrowse + '" >';
    for (var i = 0; i < itemCount; i++) {
        html += getLeftNavItem(list, i);	// get the html code for one navigation tree item
    }
	html += '</ul>';
	var id = document.getElementById(leftNavContainer);
	id.innerHTML = html;		// save the navigation tree
	id.style.display = "block";	// show the navigation tree container
	// return the url of the first navigation tree item
	rc = getNavigateTo(list, 0);
    hideLoadingGraphic();
    return rc;
}
// return the html code for one navigation tree item
function getLeftNavItem(list, index) {
    try {
        var itemId = getNMCPropertyText(list, "item.meta.id", index);
        var url = getNMCPropertyText(list, "item.url", index);
        var title = getTitle(list, index);
        if (navTreeSpecialItem) return title;
        else return '<li id="id' + serverIndex + '_' + itemId + '" onclick="navigateTo(\'' + url + '?start=0&count=' + nmcItemCount + '&' + itemId + '\')" ><a>' + title + '</a></li>';
    } catch (e) {
        return "";
    }
}
function getNavigateTo(list, index) {
    try {
        var itemId = getNMCPropertyText(list, "item.meta.id", index);
        var url = getNMCPropertyText(list, "item.url", index);
        if (navTreeSpecialItem) return "";
        return url + '?start=0&count=' + nmcItemCount + '&' + itemId;
    } catch (e) {
        return "";
    }
}
function clearContentArea() {
    try {
        var id = document.getElementById("browseContents");
        id.innerHTML = "";
        id = document.getElementById("browsePages");
        id.innerHTML = "";
        id = document.getElementById("breadcrumb");
        id.innerHTML = "";
    } catch (e) {
    }
}

// server returns the title
function getTitle(list, index) {
    try {
        var item = getItem(list, index);
        if (item == "") return "";
        var title = getNMCPropertyText(item, "title");
        return title;
    } catch (e) {
        return "";
    }
}
// return V, M or P
function getObjType() {
    return (currentPersistentID.substring(0, 1)).toUpperCase();
}
function getObjIDFromTitle(elem) {
    try {
        var title = getNMCPropertyText(elem, "parentList.title", getNMCPropertyInt(elem, "parentList.length") - 2);
        switch (title) {
            case getString("video"):
                return persistentIDVideo;
            case getString("music"):
                return persistentIDMusic;
            case getString("pictures"):
                return persistentIDPhoto;
            default:
                return persistentIDVideo;
        }
        return persistentIDVideo;
    } catch (e) {
        return persistentIDVideo;
    }
}
// return the upnp:albumArtURI
// alternative the meta data with the lowest resolution
function getThumbnail(elem, elemTyp) {
    try {
        var albumArtURI = true;
        var resValue = true;
        if (!itemHasProperty(elem, "meta")) return "";
        if (!itemHasProperty(elem, "meta.upnp:albumArtURI")) albumArtURI = false;
        if (!itemHasProperty(elem, "meta.res")) resValue = false;
        if (resValue) if (!(elem.meta.res.length > 0)) resValue = false;
        if (!albumArtURI && !resValue) return "";

        if (albumArtURI) return elem.meta["upnp:albumArtURI"];
        if (resValue) {
			var thumbnailRes = 1000;
			if (elemTyp == persistentIDMusic) thumbnailRes = resolutionMusic;
			if (elemTyp == persistentIDVideo) thumbnailRes = resolutionVideo;
			if (elemTyp == persistentIDPhoto) thumbnailRes = resolutionPhoto;
			if (elemTyp == "branch") thumbnailRes = resolutionBranch;
			var bestRes = -1;
			var bestResIndex = 0;
            if (elem.meta.res.length == 1) return elem.meta.res[0].value;
			for (var i=0;i<elem.meta.res.length;i++) {
				var res = getNMCPropertyText(elem, "meta.res.resolution", i);
				var resolution = res.split("x");
				var r = parseInt(resolution[0])*parseInt(resolution[1]);
				var r1 = Math.abs(bestRes - thumbnailRes);
				var r2 = Math.abs(r - thumbnailRes);
				if (bestRes == -1) {
					bestRes = r2;
					bestResIndex = i;
				} else {
					if (r2 < r1) {
						bestRes = r2;
						bestResIndex = i;
					}
				}
			}
			return elem.meta.res[bestResIndex].value;
        }
        return "";
    } catch (e) {
        return "";
    }
}
// return true, if the item is a container
// return false, if it is an item
function isContainer(elem) {
    var metaClass = true;
    var upnpClass = true;
    if (!itemHasProperty(elem, "meta")) metaClass = false;
    if (!itemHasProperty(elem, "upnp:class")) upnpClass = false;
    //if (metaClass) if (!itemHasProperty(elem, "meta.upnp:class")) return false;
    if (!metaClass && !upnpClass) return false;
    try {
        if (metaClass)
            if (elem.meta["upnp:class"].substring(0, 16) == "object.container") return true;
        if (upnpClass)
            if (elem["upnp:class"] == "object.container") return true;
        return false;
    } catch (e) {
        return false;
    }
}
// return true, if the item is an audiobook container
// return false, if not 
function isAudiobookContainer(elem) {
    var metaClass = true;
    var upnpClass = true;
    if (!itemHasProperty(elem, "meta")) metaClass = false;
    if (!itemHasProperty(elem, "upnp:class")) upnpClass = false;
    if (!metaClass && !upnpClass) return false;
    try {
        if (metaClass)
            if (elem.meta["upnp:class"] == "object.container.audiobookContainer") return true;
        if (upnpClass)
            if (elem["upnp:class"] == "object.container.audiobookContainer") return true;
        return false;
    } catch (e) {
        return false;
    }
}

// the following function returns one property from the nmc json feeds as text
function getNMCPropertyText(elem, property, index) {
    try {
        switch (property) {
            case "parentList.id":
                return elem.parentList[index].id
            case "parentList.url":
                return elem.parentList[index].url;
            case "parentList.title":
                return elem.parentList[index].title;
            case "parentList.childCount":
                return elem.parentList[index].childCount;
            case "id":
                return elem.id;
            case "title":
                return elem.title;
            case "url":
                return elem.enclosure.url;
            case "bookmark":
                return elem.bookmark;
            case "pv:playbackBookmark":
				if (itemHasProperty(elem, "pv:playbackBookmark"))
					return elem['pv:playbackBookmark'];
				else
					return "";
            case "pv:playbackTimeOffset":
				if (itemHasProperty(elem, "pv:playbackTimeOffset"))
					return elem['pv:playbackTimeOffset'];
				else
					return "";
            case "pv:playbackByteOffset":
				if (itemHasProperty(elem, "pv:playbackByteOffset"))
					return elem['pv:playbackByteOffset'];
				else
					return "";
            case "pbookmark":
                return elem.meta.PersistentBookmark;
            case "item.url":
                return elem.item[index].enclosure.url;
            case "item.bookmark":
                return elem.item[index].bookmark;
            case "item.id":
                return elem.item[index].id;
            case "item.title":
                return elem.item[index].title;
            case "item.multiUserSupport":
				if (itemHasProperty(elem.item[index], "server.multiUserSupport"))
					return elem.item[index].server.multiUserSupport;
				else return "false";
            case "meta.id":
				if (itemHasProperty(elem, "meta.id"))
					return elem.meta.id;
				else return "";
            case "meta.title":
                return elem.meta['dc:title'];
            case "meta.album":
                return elem.meta['upnp:album'];
            case "meta.artist":
                return elem.meta['upnp:artist'];
            case "meta.genre":
                return elem.meta['upnp:genre'];
            case "res.size":
                return elem.meta.res[0].size;
            case "meta.format":
                return elem.meta['pv:extension'];
            case "meta.date":
                return elem.meta['dc:date'];
            case "item.meta.id":
				if (itemHasProperty(elem.item[index], "meta.id"))
					return elem.item[index].meta.id;
				else return "";
            case "item.meta.upnp:class":
				if (itemHasProperty(elem.item[index], "meta.upnp:class"))
					return elem.item[index].meta['upnp:class'];
				else return "";
            case "item.server.isLocalDevice":
				if (itemHasProperty(elem.item[index], "server.isLocalDevice"))
					return elem.item[index].server.isLocalDevice;
				else return "";
            case "item.server.knownServer":
				if (itemHasProperty(elem.item[index], "server.knownServer"))
					return elem.item[index].server.knownServer;
				else return "";
            case "item.server.baseURL":
				if (itemHasProperty(elem.item[index], "server.baseURL"))
					return elem.item[index].server.baseURL;
				else return "";
            case "meta.pv:persistentID":
				if (itemHasProperty(elem.item[index], "meta.pv:persistentID"))
					return elem.item[index].meta['pv:persistentID'];
				else return "";
            case "meta.res.value":
				if (itemHasProperty(elem, "meta.res"))
					return elem.meta.res[index].value;
				else return "";
            case "meta.res.resolution":
				if (itemHasProperty(elem, "meta.res"))
					return elem.meta.res[index].resolution;
				else return "";
            case "meta.upnp:class":
				if (itemHasProperty(elem, "meta.upnp:class"))
					return elem.meta['upnp:class'];
				else return "";
            case "meta.pv:containerContent":
				if (itemHasProperty(elem, "meta.pv:containerContent"))
					return elem.meta['pv:containerContent'];
				else return "";
            default:
                return "";
        }
    } catch (e) {
        return "";
    }
}
// the following function returns one property from the nmc json feeds as integer
function getNMCPropertyInt(elem, property, index) {
    try {
        switch (property) {
            case "parentList.length":
                return elem.parentList.length;
            case "childCount":
                return elem.childCount;
            case "meta.childCount":
				if (itemHasProperty(elem, "meta.childCount"))
					return parseInt(elem.meta.childCount);
            case "meta.childCountContainer":
				if (itemHasProperty(elem, "meta.pv:childCountContainer"))
					return parseInt(elem.meta['pv:childCountContainer']);
            case "meta.res.length":
				if (itemHasProperty(elem, "meta.res"))
					return elem.meta.res.length;
            default:
                return 0;
        }
    } catch (e) {
        return 0;
    }
}
// the following function returns one property from the nmc json feeds as boolean
function getNMCPropertyBool(elem, property, index) {
    try {
        switch (property) {
            case "hasDialSupport":
				if (itemHasProperty(elem, "renderer.hasDialSupport"))
					return elem.renderer.hasDialSupport;
            case "canHaveTwonky":
				if (itemHasProperty(elem, "renderer.canHaveTwonky"))
					return elem.renderer.canHaveTwonky;
            case "hasTwonky":
				if (itemHasProperty(elem, "renderer.hasTwonky"))
					return elem.renderer.hasTwonky;
            default:
                return false;
        }
    } catch (e) {
        return false;
    }
}
// get one item of a list
function getItem(elem, index) {
    try {
        if (!itemHasProperty(elem, "item")) return "";
        return elem.item[index];
    } catch (e) {
        return "";
    }
}
// get property returneditems
function getReturnedItems(elem) {
    try {
        if (!itemHasProperty(elem, "returneditems")) return 0;
		if (elem.returneditems.length > 0) {
            var c = elem.returneditems.split(" ");
            if (c.length > 1) return parseInt(c[0]);
        }
        return 0;
    } catch (e) {
        return 0;
    }
}
// get property meta.duration and return the formated value
function getMetaDuration(elem) {
    if (!itemHasProperty(elem, "meta.pv:duration" )) return "";
    try {
        var duration = elem.meta["pv:duration"].split(".")[0];
        if (duration.length == 0) duration = elem.meta["pv:duration"];
        if (!(duration.indexOf(":") > 0)) {
            if (duration.length == 0) duration = "00:00";
            if (duration.length == 1) duration = "00:0" + duration;
            if (duration.length == 2) duration = "00:" + duration;
        }
        if (duration.length > 5) {
            if (duration.split(":")[0] == "00") {
                duration = duration.substring(3, duration.length);
            } else {
                if (duration.split(":")[0] == "0") {
                    duration = duration.substring(2, duration.length);
                }
            }
        }
        return duration;
    } catch (e) {
        return "";
    }
}


// ---------- 5. - build the content area with breadcrumb and pagination
// fragment: <url>?start=<no>&count=<no>
function loadMediaBrowseContent(fragment) {
    var paramPieces = fragment.split("?");
    var url = paramPieces[0];
    var paramPieces2 = paramPieces[1].split("&");
    var start = paramPieces2[0].split("=")[1];
    var count = paramPieces2[1].split("=")[1];
    if (paramPieces2.length > 2) markLeftNavigation(paramPieces2[2]);	// mark item in left navigation

	// url: The url to have its contents displayed.
	// startItem: The index of the first item to display.
	// numItems: The number of child items.
    showLoadingGraphic();
	clearMonitorItemArray();
	var json = readData(url, start, count);
	buildHeaderAndTemplates(json, url, start, count);		// build the header and the templates
	loadMediaContentData(json, 0);							// show the first items/container on the screen
	buildContentFooter(json, url, start, count);			// add the subheader at the bottom of the content area
    hideLoadingGraphic();
}
// if there are many items show not all items
// group the items and add links to go to the items of the groups
function buildSubheader(json, url, start, count) {
	var childCount = parseInt(getNMCPropertyInt(json, "childCount"));					// returns a string
	if (childCount <= itemsLimit) return "";
	var subPages = Math.floor(childCount / itemsLimit);
	if ((childCount % itemsLimit) > 0) subPages = subPages + 1;
	var html = "";
	for (var i=0;i < subPages;i++) {
		var itemStart = (i*itemsLimit)+1;	// display this as first item
		var itemStartA = i*itemsLimit;		// start item of the navigation link
		var itemEnd = (i+1)*itemsLimit;
		if (i == (subPages-1)) itemEnd = childCount;
		if ((i*itemsLimit) == start)
			html += '<div class="subSubheader">' + 
					'<div class="floatL" style="width:50px;color:#333333;text-align:right">' + itemStart + '</div>' + 
					'<div class="floatL">-</div>' + 
					'<div class="floatL" style="width:50px;color:#333333">' + itemEnd + '</div></div>';
		else   // add a link to navigate to this page
			html += '<div class="subSubheader breadcrumb"><a onclick="navigateTo(\'' + url + '?start=' + itemStartA + '&count=' + count + '\')">' + 
					'<div class="floatL" style="width:50px;text-align:right">' + itemStart + '</div>' +
					'<div class="floatL">-</div>' +
					'<div class="floatL" style="width:50px">' + itemEnd + '</div></a></div>';
	}
	return html;
}
// if there are items beyond the limit, add the subheader also at the bottom of the content area
function buildContentFooter(json, url, start, count) {
	var html = '<div class="serverContentSpacer"></div>' + 
			   '<div>' + buildSubheader(json, url, start, count) + '<div class="clear"></div>';
    try {
        var id = document.getElementById("browseContents");
        id.innerHTML += html;
    } catch (e) {
    }
}
function buildHeaderAndTemplates(json, url, start, count) {
	var childCount = parseInt(getNMCPropertyInt(json, "childCount"));					// returns a string
	currentContainerIndex = 0;
	currentItemIndex = 0;
    var html = "";	
	// 1. -- build the container and item structure
	var title = replaceSpecialChars(getNMCPropertyText(json, "title"));	
	html = '<div class="subHeader"><span class="subheaderTitle">' + title + '</span></div>';
	html += '<div>' + buildSubheader(json, url, start, count) + '<div class="clear"></div>';
	html += '<div><div id="browseContainerAndItems"></div><div class="clear"></div></div>';
	try {
		var id = document.getElementById("browseContents");
		id.innerHTML = html;
	} catch (e) {
	}
	buildBreadcrumb(json);		// build the title which shows the current subfolders
	html = "";
	// 2. -- fill the container and item structure with empty container and items
	// build the item templates
	if (childCount > itemsLimit) childCount = itemsLimit;
	for (i=0; i<childCount;i++) {
		if (foreignUnknownServer) {
			// foreign unknown server don't have to be organized by media type
			html += leafHtmlNeutralTemplate(i);
		} else {
			// Twonky server and server with well known bookmarks are organized by media type
			switch (currentPersistentID) {
				case persistentIDVideo:
					html += leafHtmlVideoTemplate(i);
					break;
				case persistentIDPhoto:
					html += leafHtmlPhotoTemplate(i);
					break;
				case persistentIDMusic:
					html += leafHtmlMusicTemplate(i);
					break;
			}
		}
	}
	// 3. -- add the templates to the page
    try {
        var id = document.getElementById("browseContainerAndItems");
        id.innerHTML += html;
    } catch (e) {
    }
	// 4. -- add the first html-element of every bloc to the array. 
	//		 If an array-element becomes visible, remove the array entry and show the content data of this bloc.
	var itemBloc = nmcItemCount;		// currently 30 items
	for (var i=0;i<childCount;i=i+itemBloc) {
		if (i == 0) continue;
		var a = new Array();
		a["id"] = "item" + i;
		a["url"] = url;
		a["start"] = i;
		a["count"] = itemBloc;
		monitorItems.push(a);
	}
	VisibilityMonitor();			// add the event to onscroll and onresize; if event fires replace templates with media content
	startTimerGetMoreContent();		// start timer to replace templates with media content
}
function clearMonitorItemArray() {
	if (monitorItems.length == 0) return;
	while (monitorItems.length > 0) {
		monitorItems.pop();
	}
}
// make a http-get-request rss\server\<server url>?start=<startItem>&count=<numItems>&fmt=json
function readData(url, startItem, numItems) {
    var response = httpGet(url + "?start=" + startItem + "&count=" + numItems + "&fmt=json");
    if (!response) return "";
    try {
        var json = parseJson(response);
    } catch (e) {
        hideLoadingGraphic();
        return "";
    }
    if (itemHasProperty(json, "error")) {	// error occurred
        hideLoadingGraphic();
        return "";
    }
    if (itemHasProperty(json, "success")) {	// error occurred
		if (!json.success) {
			hideLoadingGraphic();
			return "";
		}
    }
	return json;
}
// fill the templates with data
function loadMediaContentData(json, startIndex) {
    var nodes = 0;		// count nodes
	var html = "";
    var returnedItems = getReturnedItems(json);		// returns an integer
	var personalRating = isPersonalRating(json, returnedItems);
    // fill the container and item templates
    for (var i = 0; i < returnedItems; i++) {
        var elem = getItem(json, i);
        if (elem == "") continue;
        if (isContainer(elem)) {
			// nodeType is branch
			if (isAudiobookContainer(elem)) {
				// it is an audiobook container. Do not allow to browse into the audiobook container.
				html = branchHtmlAudiobook(elem, startIndex + i);
				loadContainer(html, startIndex + i);		// load it as item			
			} else {
				// nodeType is branch - show thumbnail or default thumbnail
				html = branchHtml(elem, startIndex + i, personalRating);
				nodes++;
				loadContainer(html, startIndex + i);
			}
        } else {
            // nodeType is leaf
			addABreakAfterContainer(elem, startIndex + i);
            html = leafHtml(elem, startIndex + i);
			loadItem(html, startIndex + i);
        }
    }
}
// fill the container template with media content
function loadContainer(html, index) {
	var containerID = "item" + index;
    try {
		var id = document.getElementById(containerID);
		// remove the class of the leaf
		switch (currentPersistentID) {
			case persistentIDVideo:
				removeClass(containerID, "myLibraryListRow");
				break;
			case persistentIDPhoto:
				removeClass(containerID, "allPhotosItemContainer");
				break;
			case persistentIDMusic:
				removeClass(containerID, "myLibraryListRow");
				break;
		}
		// add the container classes
		addClass(containerID, "byFolderContainer");
		addClass(containerID, "shadow");
		// add the html code to the container
		id.innerHTML = html;
    } catch (e) {
    }
}
// fill the item template with media content
function loadItem(html, index) {
	var itemID = "item" + index;
    try {
		var id = document.getElementById(itemID);
		id.innerHTML = html;
    } catch (e) {
    }
}
// add a line break between container and items
function addABreakAfterContainer(html, index) {
	if (index == 0) return; 	// first elem is an item
	var prevIndex = index - 1;
	var itemID = "item" + prevIndex;
	var id = document.getElementById(itemID);
	if (hasClass(id, "byFolderContainer")) {
		// add a break
		id.outerHTML += '<div class="clear"></div>'; 
	}	
}
// check if the container has only "personal ratings"-container ( all titles has only stars *, **, ***, ...)
function isPersonalRating(elem, retItems) {
	if (retItems == 0) return false;
	for (var i=0;i<retItems;i++) {
		var item = getItem(elem, i);
		var title = replaceSpecialChars(getNMCPropertyText(item, "title"));	
		for (var j = 0;j< title.length;j++) {
			if (title.substr(j,1) == "*") continue;
			return false;
		}
	}
	return true;
}

// Visibility Monitor
// if a marked element is visible read more data and replace the templates with media content
// add event to window.onscroll and window.onresize
function VisibilityMonitor() {
	function check() {
		if (monitorItems.length == 0) return;
		var pageRect = getPageRect();
		for (var i=0;i<monitorItems.length;i++) {
			var id = document.getElementById(monitorItems[i]["id"]);
			if (!id) continue;
			if (rectsIntersect(pageRect, getElementRect(id))) {
				stopTimerGetMoreContent();
				// element is in view
				document.body.style.cursor = 'wait';
				var elem = monitorItems[i];
				monitorItems.splice(i,1);			// remove the entry
				var json = readData(elem["url"], elem["start"], elem["count"]);
				loadMediaContentData(json, elem["start"]);			// show the items/container on the screen
				document.body.style.cursor = 'auto';
				startTimerGetMoreContent();
				return;
			}
		}
	};
	document.onscroll=document.onresize=check;
	check();
}
function getPageRect() {
	var isquirks= document.compatMode!=='BackCompat';
	var page= isquirks? document.documentElement : document.body;
	var x= window.pageXOffset;
	var y= window.pageYOffset;
	var w= 'innerWidth' in window? window.innerWidth : page.clientWidth;
	var h= 'innerHeight' in window? window.innerHeight : page.clientHeight;
	return [x, y, x+w, y+h];
}
function getElementRect(element) {
	var x= 0, y= 0;
	var w= element.offsetWidth, h= element.offsetHeight;
	while (element.offsetParent!==null) {
		x+= element.offsetLeft;
		y+= element.offsetTop;
		element= element.offsetParent;
	}
	return [x, y, x+w, y+h];
}
function rectsIntersect(a, b) {
	return a[0]<b[2] && a[2]>b[0] && a[1]<b[3] && a[3]>b[1];
}
// timer to read more data and replace the templates with media content 
function stopTimerGetMoreContent() {
	clearTimeout(timerLoadMore);		// stop timer
}
function startTimerGetMoreContent() {
	timerLoadMore = setTimeout("getMoreContent()", timerLoadMoreInterval);
}
// function is called via a timer
function getMoreContent() {
	stopTimerGetMoreContent();
	if (monitorItems.length == 0) return;
	document.body.style.cursor = 'wait';
	var elem = monitorItems[0];
	monitorItems.splice(0,1);					// remove the entry
	var json = readData(elem["url"], elem["start"], elem["count"]);
	loadMediaContentData(json, elem["start"]);	// show the items/container on the screen
	document.body.style.cursor = 'auto';
	startTimerGetMoreContent();
}


function replaceSpecialChars(stringIn) {
	return stringIn;	// since 8.1: stringIn is HTML encoded
    var str1 = stringIn.replace(/&amp;/g, "&");
	str1 = str1.replace(/&/g, "&amp;");
	return str1;
}
// elem: is one item of the example Video - Album (at the end of this document)
// personalRating: if true show a bigger font 
function branchHtml(elem, index, personalRating) {
    var html = "";
    var url = getNMCPropertyText(elem, "url");
	var title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
	var id = "BB" + index;
	var idDiv = id + "div";
    var objType = getObjType();
	var childCount = getNMCPropertyInt(elem, "meta.childCount");
	var childCountContainer = getNMCPropertyInt(elem, "meta.childCountContainer");

    var thumbnail = getThumbnail(elem, "branch");
    var thumbnailDisplay = '<img id="fTh' + id + '" class="folderThumbnail" src="/resources/webbrowse/spacer.gif" onload="this.onload=null;loadDefaultThumbnail(this, \'' + objType + '\', ' + true + ')" />';
    if (thumbnail) thumbnailDisplay = '<img id="fTh' + id + '" class="folderThumbnail" src="' + thumbnail + '" onerror="this.onerror=null;loadDefaultThumbnail(this, \'' + objType + '\', ' + true + ')" />';
	var divImg = '<div id="img' + id + '" class="folderImageWrapper">' + thumbnailDisplay + '</div>';

	var htmltitle = ' title="' + getString("beamtodevice") + '" ';
	var onClickPlayContainer = ' onclick="playContainer(\'' + url + '?start=0&count=' + nmcItemCount + '\', \'' + idDiv + '\')" ';
	var onClickNavigateTo = ' onclick="navigateTo(\'' + url + '?start=0&count=' + nmcItemCount + '\')" ';
	
	var beamButton = '<a id="' + idDiv + '" name="containerBeamButton" class="myLibraryNoContainerNmc"' + onClickNavigateTo + '></a>';
	if (childCountContainer < childCount) {	// show beam icon only it there are items in the container
		if (currentRenderer[currentPersistentID] == localdevice) 		// local device: show the play icon
			beamButton = '<a id="' + idDiv + '" name="containerBeamButton" class="myLibraryBeamContainerNmcLocalDevice"' + htmltitle + onClickPlayContainer + '></a>';
		else															// renderer: show the beam icon
			beamButton = '<a id="' + idDiv + '" name="containerBeamButton" class="myLibraryBeamContainerNmc"' + htmltitle + onClickPlayContainer + '></a>';
	}
	
	if (personalRating)		// personal rating title: use a bigger font
		var divTitle = '<div id="title"><a class="personalRating">' + title + '</a></div>';
	else					// other title: use standard font
		var divTitle = '<div id="title"><a>' + title + '</a></div>';

    html += '<div ' + onClickNavigateTo + '>' + divImg + '</div>';										// image 160x160
	html += '<div class="titleContainer truncate" ' + onClickNavigateTo + ' >' + divTitle + '</div>';	// container title
	html += beamButton;																					// beam button
    return html;
}
// Audiobook container
function branchHtmlAudiobook(elem, index) {
    var html = "";
    var url = getNMCPropertyText(elem, "url");
	var title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
	var id = "BB" + index;
	var idDiv = id + "div";
    var objType = getObjType();
	var childCount = getNMCPropertyInt(elem, "meta.childCount");
	var childCountContainer = getNMCPropertyInt(elem, "meta.childCountContainer");

    var bookmark = getNMCPropertyText(elem, "bookmark");
	var poster = getThumbnail(elem, "branch");
	var elemUrl = getNMCPropertyText(elem, "url");
    var upnpclass = "object.item.audioItem.audioBook";
	var artist = "";
	
    var thumbnail = getThumbnail(elem, "branch");
    var thumbnailDisplay = '<img id="fTh' + id + '" class="folderThumbnail" src="/resources/webbrowse/spacer.gif" onload="this.onload=null;loadDefaultThumbnail(this, \'' + objType + '\', ' + true + ')" />';
    if (thumbnail) thumbnailDisplay = '<img id="fTh' + id + '" class="folderThumbnail" src="' + thumbnail + '" onerror="this.onerror=null;loadDefaultThumbnail(this, \'' + objType + '\', ' + true + ')" />';
	var divImg = '<div id="img' + id + '" class="folderImageWrapper" style="cursor:default">' + thumbnailDisplay + '</div>';
	
	// the onclick event calls the function playBookmark with the bookmark (if played on a renderer) AND the url (if played on the local device)
	var htmlsrc = ' src="' + beamButtonPath + beamButtonImageLoading + '" ';
	var htmltitle = ' title="' + getString("beamtodevice") + '" ';
	var htmlonclick = ' onclick="playBookmark(\'' + bookmark + '\', \'' + id + '\', \'' + url + '\', \'' + elemUrl + '\', \'' + escape(title) + '\', \'' + escape(artist) + '\', \'' + poster + '\', \'' + upnpclass + '\', true)" ';
	var beamButton = '<a id="' + idDiv + '" name="containerBeamButton" class="myLibraryNoContainerNmc"' + htmlonclick + '></a>';
	if (childCountContainer < childCount) {	// show beam icon only it there are items in the container
		if (currentRenderer[currentPersistentID] == localdevice) 		// local device: show the play icon
			beamButton = '<a id="' + idDiv + '" name="containerBeamButton" class="myLibraryBeamContainerNmcLocalDevice"' + htmltitle + htmlonclick + '></a>';
		else															// renderer: show the beam icon
			beamButton = '<a id="' + idDiv + '" name="containerBeamButton" class="myLibraryBeamContainerNmc"' + htmltitle + htmlonclick + '></a>';
	}
	var divTitle = '<div id="title">' + title + '</div>';

    html += '<div ' + '>' + divImg + '</div>';										// image 160x160
	html += '<div class="titleContainerAudiobook truncate" ' + ' >' + divTitle + '</div>';		// container title
	html += beamButton;																				// beam button
    return html;
}
// elem: is one item of the example Video - Album (at the end of this document)
function leafHtml(elem, index) {
    var id = getNMCPropertyText(elem, "meta.id");
    var html = "";
    var htmlButton = "";
    var objType = getObjType();
	if (foreignUnknownServer) {
		// foreign unknown server don't have to be organized by media type
		html += leafHtmlNeutral(elem, index);
	} else {
		// Twonky server and server with well known bookmarks are organized by media type
		var thumbnail = getThumbnail(elem, currentPersistentID);			// get thumbnail
		if (currentPersistentID != persistentIDPhoto) {
			// music and video container
			var thumbnailDisplay = '<img id="fTh' + id + '" src="' + thumbnail + '" \
			onerror="this.onerror=null;loadDefaultThumbnail(this, \'' + objType + '\', ' + false + ')" />';
		}
		switch (objType) {        // show content
			case "V":
				html = leafHtmlVideo(elem, thumbnailDisplay, index);
				break;
			case "P":
				html = leafHtmlPhoto(elem, thumbnail, index);
				break;
			case "M":
				html = leafHtmlMusic(elem, thumbnailDisplay, index);
				break;
		}
	}
    return html;
}

// item templates for video, music and photo
function leafHtmlVideoTemplate(index) {
    var html = "";
    html += '<div id="item' + index + '" class="myLibraryListRow">';
	html += '<div class="myLibraryMediaContainerNmcVideo templateBorder"></div>';
	html += '<div class="myLibraryListMediaDataVideo"><div class="mediaDataVideo"></div><div class="mediaDataVideo"></div></div>';
	html += '</div>';
    return html;
}
function leafHtmlPhotoTemplate(index) {
    var html = "";
    html += '<div id="item' + index + '" class="allPhotosItemContainer">';
	html += '<div class="allPhotosItem templateBorder"></div>';
	html += '</div>';
    return html;
}
function leafHtmlMusicTemplate(index) {
    var html = "";
    html += '<div id="item' + index + '" class="myLibraryListRow">';
	html += '<div class="myLibraryMediaContainerNmcMusic templateBorder"></div>';
	html += '<div class="myLibraryListMediaDataMusic"><div class="mediaDataMusic"></div><div class="mediaDataMusic"></div><div class="mediaDataMusic"></div></div>';
	html += '</div>';
    return html;
}
function leafHtmlNeutralTemplate(index) {
    var html = "";
    html += '<div id="item' + index + '" class="myLibraryListRow">';
	html += '<div class="myLibraryMediaContainerNmcMusic templateBorder"></div>';
	html += '<div class="myLibraryListMediaDataMusic"><div class="mediaDataMusic"></div><div class="mediaDataMusic"></div><div class="mediaDataMusic"></div></div>';
	html += '</div>';
    return html;
}

function leafHtmlVideo(elem, thumbnail, index) {
    var html = "";
    var url = getNMCPropertyText(elem, "meta.res.value", 0);
    var bookmark = getNMCPropertyText(elem, "bookmark");
	var title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
    var artist = getNMCPropertyText(elem, "meta.artist");
	var poster = getThumbnail(elem, currentPersistentID);
	var elemUrl = getNMCPropertyText(elem, "url");
    var upnpclass = getNMCPropertyText(elem, "meta.upnp:class");
    var duration = getMetaDuration(elem);
    var durationDisplay = (duration) ? ('<div class="timeDisplay">' + duration + '</div>') : ("")
    var contentsize = getNMCPropertyText(elem, "res.size");
    var format = getNMCPropertyText(elem, "meta.format");
    var date = getNMCPropertyText(elem, "meta.date");
    var year = date.substring(0, 4);
    var fileSize = '<div class="mediaDataVideo">' + getString("filesize") + ' ' + Math.round((parseInt(contentsize) / 1048576) * 100) / 100 + ' MB</div>';
    var videoYear = '<div class="mediaDataVideo">' + getString("year") + ' ' + year + '</div>';
	var id = "BB" + index;
	var idDiv = id + "div";
	var htmlsrc = ' src="' + beamButtonPath + beamButtonImageLoading + '" ';
	var htmltitle = ' title="' + getString("beamtodevice") + '" ';
	// the onclick event calls the function playBookmark with the bookmark (if played on a renderer) AND the url (if played on the local device)
	var htmlonclick = ' onclick="playBookmark(\'' + bookmark + '\', \'' + id + '\', \'' + url + '\', \'' + elemUrl + '\', \'' + escape(title) + '\', \'' + escape(artist) + '\', \'' + poster + '\', \'' + upnpclass + '\', false)" ';
	var beamButton = '<img id="' + id + '" ' + htmlsrc + ' style="visibility:hidden"/>';
	var listIconContainer = '<div class="myLibraryMediaContainerNmcVideo">\
		<div class="myLibraryMediaIconVideo"><a ' + htmltitle + htmlonclick + '>' + thumbnail + durationDisplay + '</a> </div>\
		<div id="' + idDiv + '" class="myLibraryMediaBeamNmcVideo">' + beamButton + '</div>\
		</div>';
    html += '<div class="myLibraryListRow">' + listIconContainer + '<div class="myLibraryListMediaDataVideo">' +
		'<div class="mediaDataVideo"><a class="largeFont" ' + htmltitle + htmlonclick + '>' + title + '</a></div>' +
        fileSize +
        '<div class="mediaDataVideo">' + getString("format") + ' ' + format + '</div>' +
        videoYear +
        '</div></div>';
    return html;
}
function leafHtmlPhoto(elem, thumbnailData, index) {
    var html = '';
    var id = getNMCPropertyText(elem, "meta.id");
    var url = getNMCPropertyText(elem, "meta.res.value", 0);
    var bookmark = getNMCPropertyText(elem, "bookmark");
	var title = getNMCPropertyText(elem, "title");
    var artist = "";
	var poster = "";
    var upnpclass = getNMCPropertyText(elem, "meta.upnp:class");
	var elemUrl = getNMCPropertyText(elem, "url");
	var id = "BB" + index;
	var idDiv = id + "div";
	var htmlsrc = ' src="' + beamButtonPath + beamButtonImageLoading + '" ';
	var htmltitle = ' title="' + getString("beamtodevice") + '" ';
	// the onclick event calls the function playBookmark with the bookmark (if played on a renderer) AND the url (if played on the local device)
	var htmlonclick = ' onclick="playBookmark(\'' + bookmark + '\', \'' + id + '\', \'' + url + '\', \'' + elemUrl + '\', \'' + escape(title) + '\', \'' + escape(artist) + '\', \'' + poster + '\', \'' + upnpclass + '\', false)" ';
	var beamButton = '<div id="' + idDiv + '" class="myLibraryBeamNmc" >';
	beamButton += '<img id="' + id + '" ' + htmlsrc + ' style="visibility:hidden" />';
	beamButton += '</div>';
    html += '<div class="allPhotosItemContainer">' +
			'<div class="allPhotosItem">' + 
			'<a ' + htmltitle + htmlonclick + '>' +
			'<img id="fTh' + id + '" class="photoThumbnail" src="' + thumbnailData + '" onerror="this.onerror=null;loadDefaultThumbnail(this, \'P\', ' + false + ')" />' + 
			'</a></div>' +
			'<div class="allPhotosBeam" >' + beamButton + '</div>' +
			'</div>';
    return html;
}
function leafHtmlMusic(elem, thumbnail, index) {
    var html = "";
    var url = getNMCPropertyText(elem, "meta.res.value", 0);
    var bookmark = getNMCPropertyText(elem, "bookmark");
    var artist = getNMCPropertyText(elem, "meta.artist");
    var album = getNMCPropertyText(elem, "meta.album");
    var genre = getNMCPropertyText(elem, "meta.genre");
	var title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
	var poster = getThumbnail(elem, currentPersistentID);
	var elemUrl = getNMCPropertyText(elem, "url");
    var upnpclass = getNMCPropertyText(elem, "meta.upnp:class");
    var duration = getMetaDuration(elem);
    var durationDisplay = (duration) ? ('<div class="timeDisplay">' + duration + '</div>') : ("")
	var id = "BB" + index;
	var idDiv = id + "div";
	// the onclick event calls the function playBookmark with the bookmark (if played on a renderer) AND the url (if played on the local device)
	var htmlsrc = ' src="' + beamButtonPath + beamButtonImageLoading + '" ';
	var htmltitle = ' title="' + getString("beamtodevice") + '" ';
	var htmlonclick = ' onclick="playBookmark(\'' + bookmark + '\', \'' + id + '\', \'' + url + '\', \'' + elemUrl + '\', \'' + escape(title) + '\', \'' + escape(artist) + '\', \'' + poster + '\', \'' + upnpclass + '\', false)" ';
	var beamButton = '<img id="' + id + '" ' + htmlsrc + ' style="visibility:hidden" />';
	var listIconContainer = '<div class="myLibraryMediaContainerNmcMusic">\
		<div class="myLibraryMediaIconMusic"><a ' + htmltitle + htmlonclick + '>' + thumbnail + '</a></div>\
		<div id="' + idDiv + '" class="myLibraryMediaBeamNmcMusic">' + beamButton + '</div>\
		</div>';		
    html += '<div class="myLibraryListRow">' + listIconContainer + '<div class="myLibraryListMediaDataMusic">\
	<div class="mediaDataMusic"><a ' + htmltitle + htmlonclick + '>' + title + '</a> \
	<span class="largeFont">(' + duration + ')</span>\
	</div>\
	<div class="mediaDataMusic">' + getString("artist2") + ' ' + artist + '</div>\
	<div class="mediaDataMusic">' + getString("album2") + ' ' + album + '</div>\
	</div></div>';
    return html;
}
function leafHtmlNeutral(elem, index) {
    var html = "";
	var id = "BB" + index;
	var idDiv = id + "div";
    var url = getNMCPropertyText(elem, "meta.res.value", 0);
    var bookmark = getNMCPropertyText(elem, "bookmark");
	var title = "";
	var artist = "";
	var poster = "";
	var album = "";
	var genre = "";
	var elemUrl = "";
	var duration = "";
	var durationDisplay = "";
	var format = "";
	var fileSize = "";
	var videoYear = "";
	var htmlsrc = ' src="' + beamButtonPath + beamButtonImageLoading + '" ';
	var htmltitle = ' title="' + getString("beamtodevice") + '" ';
	var htmlonclick = "";
	var beamButton = "";
	var thumbnail = "";
	var upnpclass = getNMCPropertyText(elem, "meta.upnp:class");

	var itemType = "";
	if (upnpclass.indexOf("imageItem") >= 0) itemType = persistentIDPhoto;
	if (upnpclass.indexOf("audioItem") >= 0) itemType = persistentIDMusic;
	if (upnpclass.indexOf("videoItem") >= 0) itemType = persistentIDVideo;

	switch (itemType) {        // show content
		case persistentIDPhoto:
			title = getNMCPropertyText(elem, "title");
			artist = "";
			poster = "";
			elemUrl = getNMCPropertyText(elem, "url");
			// the onclick event calls the function playBookmark with the bookmark (if played on a renderer) AND the url (if played on the local device)
			htmlonclick = ' onclick="playBookmark(\'' + bookmark + '\', \'' + id + '\', \'' + url + '\', \'' + elemUrl + '\', \'' + escape(title) + '\', \'' + escape(artist) + '\', \'' + poster + '\', \'' + upnpclass + '\', false)" ';
			//beamButton = '<div id="' + idDiv + '" class="myLibraryBeamNmc" >';
			beamButton += '<img id="' + id + '" ' + htmlsrc + ' style="visibility:hidden" />';
			//beamButton += '</div>';
			thumbnail = getThumbnail(elem, persistentIDPhoto);			// get thumbnail
			thumbnail = '<img id="fTh' + id + '" src="' + thumbnail + '" \
			onerror="this.onerror=null;loadDefaultThumbnail(this, \'M\', ' + false + ')" />';
			break;
		case persistentIDMusic:
		case "":
			title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
			artist = getNMCPropertyText(elem, "meta.artist");
			album = getNMCPropertyText(elem, "meta.album");
			genre = getNMCPropertyText(elem, "meta.genre");
			poster = getThumbnail(elem, currentPersistentID);
			elemUrl = getNMCPropertyText(elem, "url");
			duration = getMetaDuration(elem);
			durationDisplay = (duration) ? ('(' + duration + ')') : ("")			
			// the onclick event calls the function playBookmark with the bookmark (if played on a renderer) AND the url (if played on the local device)
			htmlonclick = ' onclick="playBookmark(\'' + bookmark + '\', \'' + id + '\', \'' + url + '\', \'' + elemUrl + '\', \'' + escape(title) + '\', \'' + escape(artist) + '\', \'' + poster + '\', \'' + upnpclass + '\', false)" ';
			beamButton = '<img id="' + id + '" ' + htmlsrc + ' style="visibility:hidden" />';
			thumbnail = getThumbnail(elem, persistentIDMusic);			// get thumbnail
			thumbnail = '<img id="fTh' + id + '" src="' + thumbnail + '" \
			onerror="this.onerror=null;loadDefaultThumbnail(this, \'M\', ' + false + ')" />';
			break;
		case persistentIDVideo:
			title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
			artist = getNMCPropertyText(elem, "meta.artist");
			poster = getThumbnail(elem, currentPersistentID);
			elemUrl = getNMCPropertyText(elem, "url");
			duration = getMetaDuration(elem);
			durationDisplay = (duration) ? ('(' + duration + ')') : ("")
			var contentsize = getNMCPropertyText(elem, "res.size");
			format = getNMCPropertyText(elem, "meta.format");
			var date = getNMCPropertyText(elem, "meta.date");
			var year = date.substring(0, 4);
			fileSize = '<div class="mediaDataVideo">' + getString("filesize") + ' ' + Math.round((parseInt(contentsize) / 1048576) * 100) / 100 + ' MB</div>';
			videoYear = '<div class="mediaDataVideo">' + getString("year") + ' ' + year + '</div>';
			// the onclick event calls the function playBookmark with the bookmark (if played on a renderer) AND the url (if played on the local device)
			htmlonclick = ' onclick="playBookmark(\'' + bookmark + '\', \'' + id + '\', \'' + url + '\', \'' + elemUrl + '\', \'' + escape(title) + '\', \'' + escape(artist) + '\', \'' + poster + '\', \'' + upnpclass + '\', false)" ';
			beamButton = '<img id="' + id + '" ' + htmlsrc + ' style="visibility:hidden"/>';
			thumbnail = getThumbnail(elem, persistentIDVideo);			// get thumbnail
			thumbnail = '<img id="fTh' + id + '" src="' + thumbnail + '" \
			onerror="this.onerror=null;loadDefaultThumbnail(this, \'M\', ' + false + ')" />';
			break;
	}

	var listIconContainer = '<div class="myLibraryMediaContainerNmcMusic">\
		<div class="myLibraryMediaIconMusic"><a ' + htmltitle + htmlonclick + '>' + thumbnail + '</a></div>\
		<div id="' + idDiv + '" class="myLibraryMediaBeamNmcMusic">' + beamButton + '</div>\
		</div>';		
    html += '<div class="myLibraryListRow">' + listIconContainer + '<div class="myLibraryListMediaDataMusic">\
	<div class="mediaDataMusic"><a ' + htmltitle + htmlonclick + '>' + title + '</a> \
	<span class="largeFont">' + durationDisplay + '</span>\
	</div>';
	if ((artist != "") || (album != "")) {
		html += '<div class="mediaDataMusic">' + getString("artist2") + ' ' + artist + '</div>';
		html += '<div class="mediaDataMusic">' + getString("album2") + ' ' + album + '</div>';
	}
	if ((format != "") || (videoYear != "")) {
        html += '<div class="mediaDataVideo">' + getString("format") + ' ' + format + '</div>' + videoYear;
	}
	html += '</div></div>';
	return html;
}

// ---------- 6. - build breadcrumb from parentList
function buildBreadcrumb(list) {
    var breadcrumb = "";
    var separator = "";
	var currentTitle = replaceSpecialChars(getNMCPropertyText(list, "title"));
    if (itemHasProperty(list, "parentList")) {
        // parents up to leftNavigation
        var parentListLength = getNMCPropertyInt(list, "parentList.length");
		// build without: length-1 = root, length-2 = video/music/photo, length-3 = leftNavigation
		var parentlength = parentListLength - 3;		// length-1 = root, length-2 = video/music/photo, length-3 = leftNavigation
		// foreign server build without: length-1 = root, length-2 = video/music/photo
		if (foreignUnknownServer) parentlength = parentListLength - 2;
        for (var i = 0; i <= parentlength; i++) {    
            var id = getNMCPropertyText(list, "parentList.id", i);
			var title = replaceSpecialChars(getNMCPropertyText(list, "parentList.title", i));
            var url = getNMCPropertyText(list, "parentList.url", i);
            var count = getNMCPropertyText(list, "parentList.childCount", i);
			if (count > nmcItemCount) count = nmcItemCount;
            breadcrumb = '<span class="breadcrumbWrapper" pathid="' + id + '">\
				<a onclick="navigateTo(\'' + url + '?start=0&count=' + count + '\')">\
				<span class="breadcrumbItem" pathid="' + id + '" numitems="' + count + '">' + title + '</span></a>' + separator + '</span>'
                + breadcrumb;
            separator = " / ";
        }
		breadcrumb += separator + replaceSpecialChars(list.title);
    }
    try {
        var id = document.getElementById("breadcrumb");
        id.innerHTML = breadcrumb;
    } catch (e) {
    }
}


// ------------ helper functions
function browserIdentification() {
    browser = "other";
    // special treating for Safari
    if (navigator.userAgent.indexOf("Safari") != -1) browser = "Safari";
    if (navigator.userAgent.indexOf("KHTML") != -1) browser = "Safari";
}
function osIdentification() {
    os = navigator.platform;
    if (navigator.platform.indexOf("Mac") != -1) os = "Mac";
}
function getConvertReadmeFile() {
    var data = makeGetRequest("/resources/webbrowse/convert-readme.txt", {});
    convertReadmeFile = data;
    convertReadmeFile = convertReadmeFile.replace(/(\r\n)|(\r)|(\n)/g, "<BR>");
}

function getMultiUserSupportFlag() {
    var response = makeGetRequest("/rpc/get_option?multiusersupportenabled", {});
    if (response) {
		if (response == "0") multiusersupportenabled = "false";
		if (response == "1") multiusersupportenabled = "true";
    }
}
function readLanguageFile() {
    var response = makeGetRequest("/rpc/get_language_file", {});
	if (!(response == "")) {
		var s = response.split("|");
		for (var i=1;i+1<s.length;i=i+2) {
			if (serverLanguageFile[s[i]]) {
				continue;
			}
			var t = s[i+1];
			var t1 = t.replace(/\r\n/,"");
			serverLanguageFile[s[i]] = t1;
		}
	}
}
function onLanguageFetched() {
    replaceStrings("headWrapper");
    replaceStrings("twFooter");
}

// A function to wrap retrieved JSON data in parentheses for eval-ing to prevent errors
function parseJson(jsonData) {
    return eval("(" + jsonData + ")");
}

// show the license information page
function showLicenseInfo() {
	var leftNavContainer = "leftNavContainer" + serverIndex;
    try {
        var id;
        id = document.getElementById(leftNavContainer);
        id.style.display = "none";
		id = document.getElementById("serversContainer");
		id.style.display = "none";
		id = document.getElementById("rendererContainer");
		id.style.display = "none";
        id = document.getElementById("serverSettingsContentWrapper");
        id.style.display = "none";
        id = document.getElementById("licenseInfoPage");
        id.style.display = "block";
        id.innerHTML = getString("mpeglicense") + "<br /><br />" + getString("copyright") + "<br /><br /><br /><br />" +
            convertReadmeFile + "<br /><br />" +
            "<BR><BR>License information is provided here: <br /><br /> " +
            "<a class='inlineLink' href='http://jquery.org/license/' >http://jquery.org/license/</a> (click on 'MIT License' link)<br /><br />" +
            "<a class='inlineLink' href='http://benalman.com/about/license/' >http://benalman.com/about/license/</a> <br /><br />" + 
            "<a class='inlineLink' href='http://jplayer.org/' >http://jplayer.org/</a> (click on 'MIT License' link) <br />";
    } catch (e) {
    }
}
//Get the value of a string given a key from the localized string translations.
//key: The key to retrieve a string for.
function getString(key) {
    if (serverLanguageFile[key]) {
        return serverLanguageFile[key];
    } else {
		return key;
	}
}

//Replace the contents of all elements in html that have a "string" attribute with the matching 
//value from the translation file.
function replaceStrings(id) {
    try {
        var elem = document.getElementById(id);
        replace(elem);
    } catch (e) {
    }
}
function replace(elem) {
    try {
        if (elem.childNodes == null) return;
        for (var i = 0; i < elem.childNodes.length; i++) {
            var child = elem.childNodes[i];
            if (child.attributes == null) continue;
            for (var j = 0; j < child.attributes.length; j++) {
                if (!(child.attributes[j].name == "string")) continue;
                if (child.childNodes.length > 0)
                    if (typeof child.childNodes[0].textContent == "undefined")
                        child.childNodes[0].nodeValue = getString(child.attributes[j].value);
                    else
                        child.childNodes[0].textContent = getString(child.attributes[j].value);
                else {
                    var str = getString(child.attributes[j].value);
                    var newNode = document.createTextNode(unescapeHtml(str));
                    child.appendChild(newNode);
                }
                child.removeAttribute("string");
                break;
            }
            replace(child);
        }
    } catch (e) {
    }
}

function unescapeHtml(str) {
    var e = document.createElement('div');
    e.innerHTML = str;
    return e.childNodes.length === 0 ? str : e.childNodes[0].nodeValue;
}

//Split a collection of data that is in name/value pair form (e.g. /rpc/get_all) and store it in a data object.
//The key becomes the first part of the split, and the value becomes the second (v=0 would be stored as {"v": 0}).
//responseData: The data to split.
//dataCollection: The data object in which to store the data. The data can be changed by the user.
//separatorChar: The character that separates the name/value pairs.
function parseSeparatedData(responseData, dataCollection, separatorChar) {
    var responsePieces = responseData.split("\n");
    for (var i = 0; i < responsePieces.length; i++) {
        var elem = responsePieces[i];
        var pieceArray = elem.split(separatorChar);
        if (pieceArray.length == 2) {
            var cleanedData = pieceArray[1].replace(/\r/g, "");
            dataCollection[pieceArray[0]] = cleanedData;
        }
    }
}
//A generic wrapper for making AJAX GET requests.
//url: The url to make the request to.
//params: A collection of objects to be passed as querystring arguments. Use the format {"key": value}. For example,
//[{"uuid": 1234}, {"example": true}] will be passed as ?uuid=1234&example=true in the querystring.
function makeGetRequest(url, params) {
    var urlParams = "";
    var separatorChar = "?";
    for (var key in params) {
        if (!params.hasOwnProperty(key)) {
            continue;
        }
        urlParams += separatorChar + key + "=" + params[key];
        separatorChar = "&";
    }
    return httpGet(url + urlParams);
}
function httpGet(urlin) {
    var req;
    req = false;
    var i = urlin.indexOf("]");		// IPv6
	if (i < 1) 
		i = urlin.indexOf(":", 5);	// IPv4
	else
		i = i+1;					// i points to the ":" http://[fe80::a4e2:4369:3ae0:a010]:9000
    var url = '';
    var k = urlin.indexOf("?", 1);

    if (i < 1) {
        url = urlin;
    }
    else {
		if ((k > 0) && (k < i)) url = urlin;
		else url = urlin.substr(i + 5, urlin.length);
    }
    // branch for native XMLHttpRequest object
    if (window.XMLHttpRequest) {
        try {
            req = new XMLHttpRequest();
        } catch (e) {
            req = false;
        }
        // branch for IE/Windows ActiveX version
    }
    else if (window.ActiveXObject) {
        try {
            req = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
                req = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (e) {
                req = false;
            }
        }
    }
    if (req) {
		if (multiusersupportenabled == "true") {				// send the request with authentification (username and password)
			req.open("GET", url, false, username, password);	// send username, pwd for firefox and chrome
			req.setRequestHeader("Authorization", "Basic " + Base64.encode(username + ":" + password));
		} else 
			req.open("GET", url, false);
        try {
            req.send("");
        } catch (e) {
            req = false;
        }
        return req.responseText;
    }
    return "";
}

function showLoadingGraphic() {
    addClass("serverSettingsContentWrapper", "loading");
    if (loadingGraficActiv) window.clearInterval(loadingGraficActiv);
    loadingGraficActiv = window.setInterval("hideLoadingGraphic()", 8000);
}
function hideLoadingGraphic() {
    window.clearInterval(loadingGraficActiv);
    loadingGraficActiv = null;
    removeClass("serverSettingsContentWrapper", "loading");
}

// add class to html-tag
function addClass(idName, className) {
    try {
        var elem = document.getElementById(idName);
		if (elem == null) return;
        var elemClass = elem.className || elem.getAttribute('class') || '';
        var separator = elemClass && elemClass.length > 0 ? ' ' : '';

        if (!elemClass || elemClass == '' || !elemClass.match(className)) {
            if (elem.className) {
                elem.className += separator + className;
            }
            else {
                elem.setAttribute('class', elemClass + separator + className);
            }
        }
    } catch (e) {
    }
}
// remove class from html-tag
function removeClass(idName, className) {
    try {
        var elem = document.getElementById(idName);
		if (elem == null) return;
        var elemClass = elem.className || elem.getAttribute('class') || '';
        var classList = elemClass.split(' ');
        var newClass = '';

        for (var i = 0; i < classList.length; i++) {
            if (!(classList[i] == className)) {
                newClass += classList[i] + ' ';
            }
        }

        newClass = trimString(newClass);

        if (elem.className) {
            elem.className = newClass;
        }
        else {
            elem.setAttribute('class', newClass);
        }
    } catch (e) {
    }
}
// has html-tag the class ?
function hasClass(elem, className) {
    try {
		if (elem == null) return;
        var elemClass = elem.className || elem.getAttribute('class') || '';
        var classList = elemClass.split(' ');

        for (var i = 0; i < classList.length; i++) {
            if (classList[i] == className) return true;
        }
		return false;
    } catch (e) {
		return false;
    }
}

// need to add this because trim() is not supported on IE8
function trimString(val) {
    return val.replace(/^\s+|\s+$/g, '');
}

// check if item has the property (l = item, p = property key)
function itemHasProperty(l, p) {
    var prop = p.split(".");
    var n = "";
    for (var key in l) {
        if (key == prop[0]) {
            if (prop.length == 1) return true;
            var pnew = prop[1];
            for (var i = 2; i < prop.length; i++) {
                pnew = pnew + "." + prop[i];
            }
            return itemHasProperty(l[key], pnew);
        }
    }
    return false;
}


function getDefaultContainerThumbnail(mediaType) {
    switch (mediaType) {
        case "V":
            return noCoverVideo;
            break;
        case "M":
            return noCoverAudio;
            break;
        case "P":
            return noCoverPhoto;
            break;
    }
}
//Load the default thumbnail for an image if the one specified in the media browse API can't be successfully loaded.
//image: The image to change the src of.
//mediaType: The media type of the node (video, music, photo). Used to determine which image to display.
function loadDefaultThumbnail(image, mediaType, isFolder) {
    //If the image is a child of an element with the byFolderContainer class, use the larger image.
    //Otherwise, use the smaller image for that content type.
    try {
		switch (mediaType) {
			case "V":
				image.src = (isFolder) ? (noCoverVideo) : (videoDefaultImg);				
				break;
			case "M":
				image.src = (isFolder) ? (noCoverAudio) : (musicDefaultImg);
				break;
			case "P":
				image.src = (isFolder) ? (noCoverPhoto) : (photoDefaultImg);
				break;
			default:
				image.src = "";
		}
		return true;
    } catch (e) {
		return true;
    }
}
// refresh page if browser back button was pressed
// (IE has no event handling for this button)
function initTimer() {
    lastHash = currentPersistentID;
    timer = setInterval(checkTimer, timerInterval);
}
function checkTimer() {
	if ((window.location.hash == "") && (lastHash == persistentIDVideo)) return;
    if (!(lastHash == window.location.hash)) navigateTo(window.location.hash.substring(1, window.location.hash.length));
}


// 1 - server list in json format
/*
 "id":"Servers"
 "title":"Servers"
 "upnp:class":"object.container"
 "url":"http://127.0.0.1:9000/nmc/rss/server?fmt=json"
 "description":"4 objects available in container"
 "returneditems":"4 objects returned from container"

 "item": [ {  // server 0
 "title":"margret Library at Margret-PC"
 "enclosure": {
 "value":""
 "type":"application/rss xml"
 "url":"http://127.0.0.1:9000/nmc/rss/server/RBuuid:55076f6e-6b79-4d65-64a5-1c6f65956ad9,0"
 }
 "bookmark":"uuid:55076f6e-6b79-4d65-64a5-1c6f65956ad9,0"

 "server": {
 "name":"margret Library at Margret-PC"
 "friendlyName":"margret Library at Margret-PC"
 "manufacturer":"PacketVideo"
 "modelName":"TwonkyServer"
 "modelNumber":"7.1"
 "modelDescription":"TwonkyServer"
 "dlnaVersion":"DMS-1.50"
 "upnpVersion":"1.0"
 "playlistSupport":"true"
 "isLocalDevice":"false"
 "isInternalDevice":"false"
 "UDN":"uuid:55076f6e-6b79-4d65-64a5-1c6f65956ad9"
 "baseURL":"http://192.168.1.144:9000"
 "isProxyServer":"false"
 "isSupportRecording":"false"
 "dtcpPushSupport":"false"
 "dtcpCopySupport":"false"
 "dtcpMoveSupport":"false"
 "uploadSupportAV":"true"
 "uploadSupportImage":"true"
 "uploadSupportAudio":"true"
 "deviceIsOnline":"true"
 "knownServer":"Twonky 7.1"
 }
 "upnp:class":"object.container"
 "wellKnownBookmarks": [
 { "realContainerId": "0$1", "value": ".,music" }
 { "realContainerId": "0$1$8", "value": ".,music/all" }
 { "realContainerId": "0$1$9", "value": ".,music/playlists" }
 { "realContainerId": "0$1$10", "value": ".,music/genre" }
 { "realContainerId": "0$1$11", "value": ".,music/artists" }
 { "realContainerId": "0$1$12", "value": ".,music/albums" }
 { "realContainerId": "0$1$13", "value": ".,music/folders" }
 { "realContainerId": "0$1$14", "value": ".,music/rating" }
 { "realContainerId": "0$2", "value": ".,picture" }
 ...
 { "realContainerId": "0$3", "value": ".,video" }
 ...
 { "realContainerId": "0$37", "value": ".,playlists" }
 { "realContainerId": "0$1$39", "value": ".,music/mytwonky" }
 ...
 ]
 }
 { // server 1 }
 { // server 2 }
 { // server 3 }
 */
// 2 - base container (video, music, photo)
/*
 "id":"0"
 "title":"margret Library at mgrane6410"
 "upnp:class":"object.container"
 "url":"http://127.0.0.1:9000/nmc/rss/server/RBuuid%3A55076f6e-6b79-4d65-64bc-0026b9ef209b,0%3Fstart%3D0%26count%3D25%26fmt%3Djson"
 "description":"3 objects available in container"
 "returneditems":"3 objects returned from container"
 "item": [ {  // container 0
 "title":"Music"
 "enclosure": {
 "value":""
 "type":"application/rss xml"
 "url":"http://127.0.0.1:9000/nmc/rss/server/RBuuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,0/IBuuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQx,_K3B2OmNsYXNzaWZpZWQ=,0,0,_Um9vdA==,0,"
 }
 "bookmark":"uuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQx,_K3B2OmNsYXNzaWZpZWQ=,0,0,_Um9vdA==,0,"
 "meta": {
 "pv:persistentID": "music"
 "childCount": "12"
 "restricted": "1"
 "parentID": "0"
 "id": "0$1"
 "dc:title":"Music"
 "pv:modificationTime":"15997621"
 "pv:lastUpdated":"15997621"
 "pv:containerContent":"object.item.audioItem.musicTrack"
 "upnp:class":"object.container"
 }
 "upnp:class":"object.container"
 }
 { // container 1 }
 { // container 2 }
 */
// 3 - left navigation tree (Album, by Folder, ...)
/*
 "id":"0$1"
 "title":"Music"
 "upnp:class":"object.container"
 "url":"http://127.0.0.1:9000/nmc/rss/server/RBuuid%3A55076f6e-6b79-4d65-64bc-0026b9ef209b,0/IBuuid%3A55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQx,_K3B2OmNsYXNzaWZpZWQ%3D,0,0,_Um9vdA%3D%3D,0,%3Fstart%3D0%26count%3D25%26fmt%3Djson"
 "description":"12 objects available in container"
 "returneditems":"12 objects returned from container"
 "childCount":"12"
 "item": [ {  // item 0
 "title":"Album"
 "enclosure": {
 "value":""
 "type":"application/rss xml"
 "url":"http://127.0.0.1:9000/nmc/rss/server/RBuuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,0/IBuuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQxJDEy,_K3B2OmNsYXNzaWZpZWQ=,0,0,_Um9vdA==,0,,0,0,_TXVzaWM=,_MCQx,"
 }
 "bookmark":"uuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQxJDEy,_K3B2OmNsYXNzaWZpZWQ=,0,0,_Um9vdA==,0,,0,0,_TXVzaWM=,_MCQx,"
 "meta": {
 "pv:persistentID": "music/albums"
 "childCount": "16"
 "restricted": "1"
 "parentID": "0$1"
 "id": "0$1$12"
 "dc:title":"Album"
 "pv:modificationTime":"15997668"
 "pv:lastUpdated":"15997668"
 "pv:containerContent":"object.item.audioItem.musicTrack"
 "upnp:class":"object.container"
 }
 }
 {  // item 1  }
 {  // item ...  }
 */
// 4 - Example: Video - Album
/*
 {
 "id":"0$3$35"
 "title":"Album"
 "upnp:class":"object.container"
 "url":"http://127.0.0.1:9000/nmc/rss/server/RBuuid%3A55076f6e-6b79-4d65-64bc-0026b9ef209b,0/IBuuid%3A55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQzJDM1,_K3B2OmNsYXNzaWZpZWQ%3D,2,0,_Um9vdA%3D%3D,0,,0,0,_VmlkZW9z,_MCQz,%3Fstart%3D0%26count%3D1%26fmt%3Djson"
 "description":"1 objects available in container"
 "returneditems":"1 objects returned from container"
 "childCount":"1"
 "item": [ {		// item 0
 "title":"Sample Videos"
 "enclosure": {
 "value":""
 "type":"application/rss xml"
 "url":"http://127.0.0.1:9000/nmc/rss/server/RBuuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,0/IBuuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQzJDM1JDM4MQ==,_K3B2OmNsYXNzaWZpZWQ=,2,0,_Um9vdA==,0,,0,0,_VmlkZW9z,_MCQz,,0,0,_QWxidW0=,_MCQzJDM1,"
 }
 "bookmark":"uuid:55076f6e-6b79-4d65-64bc-0026b9ef209b,_MCQzJDM1JDM4MQ==,_K3B2OmNsYXNzaWZpZWQ=,2,0,_Um9vdA==,0,,0,0,_VmlkZW9z,_MCQz,,0,0,_QWxidW0=,_MCQzJDM1,"
 "meta": {
 "searchable": "1"
 "childCount": "1"
 "restricted": "1"
 "parentID": "0$3$35"
 "id": "0$3$35$381"
 "dc:title":"Sample Videos"
 "upnp:genre":"Unknown"
 "upnp:album":"Sample Videos"
 "pv:modificationTime":"69748"
 "pv:lastUpdated":"69748"
 "pv:containerContent":"object.item.videoItem.movie"
 "upnp:class":"object.container"
 }
 } { // item 1 } ... ]
 }
 */
// 5 - parentList
/*
 <parentList>
 <parent>
 <id>0$1$12</id>
 <title>Album</title>
 <upnp:class>object.container</upnp:class>
 <childCount>366</childCount>
 <url>http://192.168.1.144:9000/nmc/rss/server/RBuuid%3A55076f6e-6b79-4d65-64a5-1c6f65956ad9,0/IBuuid%3A55076f6e-6b79-4d65-64a5-1c6f65956ad9,-,_K3B2OmNsYXNzaWZpZWQ%3D,0,0,_Um9vdA%3D%3D,0,,0,0,_TXVzaWM%3D,_MCQx,</url>
 </parent>
 <parent>
 <id>0$1</id>
 <title>Music</title>
 <upnp:class>object.container</upnp:class>
 <childCount>12</childCount>
 <url>http://192.168.1.144:9000/nmc/rss/server/RBuuid%3A55076f6e-6b79-4d65-64a5-1c6f65956ad9,0/IBuuid%3A55076f6e-6b79-4d65-64a5-1c6f65956ad9,-,_K3B2OmNsYXNzaWZpZWQ%3D,0,0,_Um9vdA%3D%3D,0,</url>
 </parent>
 <parent>
 <id>0</id>
 <title>Root</title>
 <upnp:class>object.container</upnp:class>
 <childCount>3</childCount>
 <url>http://192.168.1.144:9000/nmc/rss/server/RBuuid%3A55076f6e-6b79-4d65-64a5-1c6f65956ad9,0</url>
 </parent>
 </parentList>
 */
