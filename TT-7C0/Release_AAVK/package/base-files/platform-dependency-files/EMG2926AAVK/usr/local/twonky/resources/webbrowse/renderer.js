// JavaScript Document
// the current selected renderer url for music, photo and video
var currentRenderer = new Array (3);
currentRenderer[persistentIDMusic] = "";
currentRenderer[persistentIDPhoto] = "";
currentRenderer[persistentIDVideo] = "";
var currentRendererTitle = new Array (3);
currentRendererTitle[persistentIDMusic] = "";
currentRendererTitle[persistentIDPhoto] = "";
currentRendererTitle[persistentIDVideo] = "";
var addItemToRendererList = false;

var playItem = "item";					// current playing item or container; set in playBookmark and playContainer

var localdevice = "localdevice";
var gurl = "";
var myPlaylist;
var currentPhotoIndex = -1;					// local device photo viewer

var normalSpeed = "1";						// default speed = normal speed
var currentPlayspeeds = new Array ();		// the supported play speeds of the current playing content
currentPlayspeeds[0] = normalSpeed;			// set default speed
var currentSpeedIndex = 0;					// index of the current playing speed in the array currentPlayspeeds

var beamButtonPath = "/resources/webbrowse/";
var beamButtonImageLoading = "r_loading.gif";
var closeButtonImage = "r_close.png";

var startDragAndDrop = false;		// set to true in mousedown event to save the first mousemove position (mouseStart)
var stopMouseMove = false;			// stop mouse move event
var volumeCurrentPosition = 0;		// current volume slider position
var mouseStartX = 0;				// first mousemove event after mousedown event
var windowOffsetLeft = 0;			// save left position of the window before moving window
var windowOffsetTop = 0;			// save top position of the window before moving window
var windowHeight = 480;
var windowWidth = 640;

var updateCurrentItemTimer = "";	// timer, update the current item in the toolbox
var updateTimerInterval = 4000;
var updateButtonsTimer = "";		// timer, update the buttons of the toolbox
var updateTimer2Interval = 1000;	// timer fires every 1 second
var updateTimer2 = 12;				// get the renderer status if the updateTimer2Interval was called 12 times 
var intervalCounter = 0;			// count the intervall from the start of the interval
var delayTimeNormal = 10;			// play normal - set timeout in seconds, delay time = 0 -> no timeout
var delayTimeRepeat = 8;			// play repeat or shuffle queue - set timeout in seconds
var modeNormal = "0";				// play mode: normal
var modeRepeat = "512";				// play mode: repeat
var modeShuffle = "2";				// play mode: shuffle (play randomly)
var modeRepeatAndShuffle = "514";	// play mode: repeat and shuffle

var fadeOutTimer = "";
var fadeOutTimerInterval = 200;
var fadeOutTimerCounter = 0;

var currentImageID = "";

// show the progress bar and the duration if the information is available
var rendererCanShowTheProgress = false;		// show or hide the progress bar, depending on the selected renderer
var currentPlayState = "";					// current play state (playing, paused,...)
var currentSeekPercent = 0;					// current position in the progress bar in percent
var currentSeekPosition = "00:00:00";		// current position in the progress bar
var currentSeekDuration = "00:00:00";		// duration of the current playing song/video in the progress bar
var updateProgressTimer = "";				// timer, update the progress
var updateProgressTimerInterval = 2000;

var smartPlayReadyTimer = "";				// timer, checks if SmartPlay is ready

//An object containing all the data for the Status page.
var statusData = {};

// show/hide error messages
var showErrorMessages = false;


// ----> prepare the renderer list
function resetRendererArea() {
    try {
        id = document.getElementById("browseRenderer");
        id.innerHTML = "";					// clear renderer list
    } catch (e) {
    }
}

// load the renderer list on the left navigation area (My Devices)
function loadRendererList() {
    try {
        if (document.getElementById("leftColumn2")) return;   // renderer list is already loaded
        var response = httpGet("/resources/webbrowse/renderer-nav.htm");
        if (!response) return;
        var id = document.getElementById("rendererContainer");
        id.innerHTML = response;
        replaceStrings("leftColumn2");
		// set the delay time (important for photo playback)
		response = setDelayTime(delayTimeNormal, false);
    } catch (e) {
    }
}
// show the renderer list
function populateRendererList(mediatype) {
    showLoadingGraphic();
    try {
		buildRendererList(-1);		// build list with no current index
		// mark first renderer of the list (local device) or the selected renderer
		if (currentRenderer[currentPersistentID].length == 0) {
			var renderer = localdevice; 
			var title = getString("localdevice");
		} else {
			var renderer = currentRenderer[currentPersistentID];
			var title = currentRendererTitle[currentPersistentID];
		}
		selectRenderer(renderer, title);
		// show rendererToolBox
		showRendererToolBox();
    } catch (e) { }
    hideLoadingGraphic();
}
// build the renderer list. If the currentIndex is not -1, set the renderer with the index as the current selected renderer
function buildRendererList(currentIndex) {
    var html1 = "";
	// add local player
	html1 = '<li id="Rlocal" rendererurl="' + localdevice + '" onclick="selectRenderer(\'' + localdevice + '\', \'' + getString("localdevice") + '\')"><a>' + getString("localdevice") + '</a></li>';
	var html = addRendererToList(html1, currentIndex);
	// last entry is the settings link
	if (addItemToRendererList)
		html += '<li id="settingslink" rendererurl="settingslink">' +
				'<font class="rendererSetting">' + getString("queue") + '</font>' +
				'<a style="display:inline" onclick="rendererSettings()"><font color="#E95922">' + getString("on") + '</font></a></li>';
	else
		html += '<li id="settingslink" rendererurl="settingslink">' +
				'<font class="rendererSetting">' + getString("queue") + '</font>' +
				'<a style="display:inline" onclick="rendererSettings()"><font color="#E95922">' + getString("off") + '</font></a></li>';
	var id = document.getElementById("browseRenderer");
	id.innerHTML = html;
}
function addRendererToList(html1, currentIndex) {
	var html = html1;
	// add available renderers
    var response = httpGet("/nmc/rss/renderer?fmt=json");
    if (!response) return html;
    try {
        var list = parseJson(response);				// transform json item to object
    } catch (e) { return html; }
    if (itemHasProperty(list, "error")) { return html; }

    if (list.length == 0) { return; }
	if (!itemHasProperty(list, "item")) return html;
	var itemCount = list.item.length;
	var index = 0;
    for (var i = 0; i < itemCount; i++) {
        var rItem = getItem(list, i);
		//if (rItem.isOnline == "true") {
			if (itemHasProperty(rItem, "enclosure.url") && itemHasProperty(rItem, "title")) {		// check the structure of the item
				var id = "R"+index;
				var hasDialSupport = false;
				var canHaveTwonky = false;
				var hasTwonky = false;
				if (itemHasProperty(rItem, "renderer.hasDialSupport")) hasDialSupport = getNMCPropertyBool(rItem, "hasDialSupport");
				if (itemHasProperty(rItem, "renderer.canHaveTwonky")) hasDialSupport = getNMCPropertyBool(rItem, "canHaveTwonky");
				if (itemHasProperty(rItem, "renderer.hasTwonky")) hasTwonky = getNMCPropertyBool(rItem, "hasTwonky");
				html += '<li id="' + id + '" rendererurl="' + rItem.enclosure.url + 
				        '" onclick="selectRenderer(\'' + rItem.enclosure.url + '\', \'' + escape(rItem.title) + '\', ' + hasDialSupport + ', ' + hasDialSupport + ', ' + hasTwonky + ')"><a>' + rItem.title + '</a></li>';
				if (currentIndex == i) {
					// update the current renderer
					currentRenderer[currentPersistentID] = rItem.enclosure.url;
					currentRendererTitle[currentPersistentID] = rItem.title;
				}
				index = index+1;
			}
		//}
    }
	return html;
}
function selectRenderer(url, title, hasDialSupport, canHaveTwonky, hasTwonky) {
    try {
        var elem = document.getElementById("browseRenderer");
        var l = elem.children.length;
        var j = 1000;
        for (var i = 0; i < l; i++) {
            removeClass(elem.children[i].id, "current");
			if (getAttributeValue(elem.children[i], "rendererurl") == url) j = i;
        }
        if (j < 1000) {
			addClass(elem.children[j].id, "current");
			currentRenderer[currentPersistentID] = url;
			currentRendererTitle[currentPersistentID] = unescape(title);
			replaceContainerBeamIcon(url == localdevice);
			if (url == localdevice) {
				closeRendererToolBox();
				showLocalDeviceBox(false, true);		// first parameter: show the box, if the queue is not empty, second parameter: renderer selected
			} else {
				closeLocalDeviceBox();
				activateRenderer(hasDialSupport, canHaveTwonky, hasTwonky);
			}
		}
    } catch (e) {
    }
}
function selectRendererIndex(index) {
    try {
        var elem = document.getElementById("browseRenderer");
        var l = elem.children.length;
        for (var i = 0; i < l; i++) {
            removeClass(elem.children[i].id, "current");
        }
		if (index < l) {
			addClass(elem.children[index].id, "current");
			replaceContainerBeamIcon(false);
		}
    } catch (e) {
    }
}
// local device has an own beam button
function replaceContainerBeamIcon(isLocalDevice) {
	if (foreignUnknownServer) return;		// unknown server can not beam container
	var items = document.getElementsByName("containerBeamButton");
	if (items.length == 0) return;	// no container
	var removeThisClass = "myLibraryBeamContainerNmcLocalDevice";
	var addthisClass = "myLibraryBeamContainerNmc";
	if (isLocalDevice) {
		removeThisClass = "myLibraryBeamContainerNmc";
		addthisClass = "myLibraryBeamContainerNmcLocalDevice";
	}
	if (hasClass(items[0], addthisClass)) return;	// there is already the right beam button
	// replace the beam button
	for (var i=0; i<items.length;i++) {
		removeClass(items[i].id, removeThisClass);
		addClass(items[i].id, addthisClass);
	}
}
// init renderer activation
function initRendererActivation() {
    statusData["privacypolicy"] = "http://my.twonky.com/user/privacy";
    readLanguageFile();		// default language = english	
}
// renderer activation was canceled - return to the last webbrowser location
function cancelActivation() {
	var c = getCookie("twlwl", "/webbrowse");
	navigateToUrl(c);
}
// renderer activation was successful - return to the last webbrowser location
function doneActivation() {
	var c = getCookie("twlwl", "/webbrowse");
	navigateToUrl(c);
}
// activate the renderer (/nmc/rpc/ioctl_dmr?DMRActivate) or 
// start SmartPlay (/nmc/rpc/ioctl_dmr?DMRLaunchTwonky)
function activateRenderer(hasDialSupport, canHaveTwonky, hasTwonky) {
	document.cookie = "twlwl=" + window.location;		// set a cookie with the last window location
	if (hasDialSupport) {
		if (canHaveTwonky) {
			// update the property hasTwonky (the user has installed twonky)
			var hasTwonkyAfterReload = httpGet("/nmc/rpc/ioctl_dmr?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&DMRReloadHasTwonky");
			if (hasTwonkyAfterReload =="true") {
				startSmartPlay();
				// show a message box and ask the user to continue with the activation of the renderer
				/* this should not be necessary
				var htmlBtn = '<a class="actionbtnmd floatL" onclick="javascript:startSmartPlay();" > \
							   <span class="actionbtn_l"></span><span class="actionbtn_c">' + getString("ok") + '</span><span class="actionbtn_r"></span></a>';
				htmlBtn += '<a class="actionbtnmd floatL" onclick="javascript:noActivation();" > \
							   <span class="actionbtn_l"></span><span class="actionbtn_c">' + getString("cancel") + '</span><span class="actionbtn_r"></span></a>';
				showMessage(getString("activatedialdevice"), htmlBtn);
				setMessageBody(getString("startsmartplaynow"));
				displayBox();
				return;
				*/
			} else {
				// direct user to install twonky on the device
				showDialog(getString("directuser"));
				// can not beam content to a non-activated renderer -> select local device
				selectRenderer(localdevice, getString("localdevice"));
			}
		}
	}
	if (!hasDialSupport && !canHaveTwonky && !hasTwonky) {
		// activate the renderer
		var r = httpGet("/nmc/rpc/ioctl_dmr?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&DMRActivate");
        // response 1: url=<activation url>
		if (r.substring(0,4) == "url=") {	
			window.open(r.substring(4),"_self");
			return;
		}
		// response 2: result=ok (renderer is activated)
		if (r == "result=ok") { 				
			canRendererShowTheProgress();		// evaluate if the renderer has the capability to show a progress bar
			showRendererToolBox();
			return;
		}
        // response 3: error=<error message> (renderer was not activated)
		if (r.substring(0,6) == "error=") {		
			showDialog(r.substring(6));
			// can not beam content to a non-activated renderer -> select local device
			selectRenderer(localdevice, getString("localdevice"));
			return;
		}
		canRendererShowTheProgress();		// evaluate if the renderer has the capability to show a progress bar
		showRendererToolBox();
	}
}
function noActivation() {
	hideBox();
	selectRenderer(localdevice, getString("localdevice"));
}
function stopActivation() {
	clearInterval(smartPlayReadyTimer);
	hideBox();
	selectRenderer(localdevice, getString("localdevice"));
}
function startSmartPlay() {
	// info box not necessary      hideBox();
	// 1. get the current renderer list
	var oldList = getRendererList();
	if (oldList.length == 0) { 
		selectRenderer(localdevice, getString("localdevice"));
		return; 
	}
	if (!itemHasProperty(oldList, "item")) {
		selectRenderer(localdevice, getString("localdevice"));
		return;
	}
	// get the index of the renderer in the old renderer list
	var itemCount = oldList.item.length;
	var index = -1;
	var title = "";
	for (var i = 0; i < itemCount; i++) {
		var rItem = getItem(oldList, i);
		if (itemHasProperty(rItem, "enclosure.url")) {
			if (rItem.enclosure.url == currentRenderer[currentPersistentID]) {
				index = i; 	// found the renderer in the list
				title = rItem.title;
			}
		}
	}
	if (index == -1) {
		selectRenderer(localdevice, getString("localdevice"));
		return;
	}
	// 2. start SmartPlay (e.g. Fire TV)
	showMessage(getString("activatedialdevice"), "");
	setMessageBody(getString("startsmartplay"));
	displayBox();
	var r = httpGet("/nmc/rpc/ioctl_dmr?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&DMRLaunchTwonky%20waitdmr=10");
	// smart play has no activation url
	// renderer is activated (result=ok); go forward and show the renderer toolbox
	hideBox();
	try {
		var json = parseJson(r);
	} catch (e) {
		return;
	}
	if (itemHasProperty(json, "success")) {
		if (json.success) {
			// the activation was successful and SmartPlay is ready.
			buildRendererList(index);		// refresh the rendererlist and set the current selected renderer variables (currentRenderer[currentPersistentID], currentRendererTitle[currentPersistentID])
			selectRendererIndex(index+1);	// select the renderer with the index plus 1 (the first list item is the local player)		
			canRendererShowTheProgress();	// evaluate if the renderer has the capability to show a progress bar
			showRendererToolBox();
			return;
		} else {
			// activation error - show error message and select the local device
			if (itemHasProperty(json, "message")) {
				showDialog(getString("erroractivatedevice") + " (" + json.message + ").");
				// can not beam content to a non-activated renderer -> select local device
				selectRenderer(localdevice, getString("localdevice"));
				return;
			}
		}
	}
}
function getRendererList() {
	var response = httpGet("/nmc/rss/renderer?fmt=json");
	if (!response) {
		selectRenderer(localdevice, getString("localdevice"));
		return "";
	}
	try {
		var list = parseJson(response);				// transform json item to object
	} catch (e) { 
		selectRenderer(localdevice, getString("localdevice"));
		return "";
	}
	if (itemHasProperty(list, "error")) { 
		selectRenderer(localdevice, getString("localdevice"));
		return "";
	}
	return list;
}


//Add the active class to a button when the mouse is pressed.
function onButtonMouseDown(id){
    addClass(id, "active");
}
//Remove the active class from a button when the mouse is released.
function onButtonMouseUp(id){
    removeClass(id, "active");
}
// get a cookie; if the cookie does not exist return the default value
function getCookie(cookyKey, defaultValue) {
	if (!(document.cookie)) return defaultValue;
	var c = document.cookie;
	var a = c.split(";");
	for (var j=0;j<a.length;j++) {
		var cookieID = a[j].substring(0,a[j].indexOf("="));
		var cookieValue = a[j].substring(a[j].indexOf("=")+1, a[j].length);
		if (cookieID.indexOf(cookyKey) >= 0) {
			return cookieValue;
		}
	}
	return defaultValue;
}


function getAttributeValue(child, attributeName) {
	if (child.attributes == null) return "";
	for (var j = 0; j < child.attributes.length; j++) {
		if (child.attributes[j].name == attributeName)
			return child.attributes[j].value;
	}
	return "";
}
function getBookmark(url) {
	try {
		return url.substring(url.indexOf("/RB")+3);
	} catch(e) {
		return url;
	}
}

// -----> device settings
// if beaming items to a renderer play the items (Queue: off) or add the item to the renderer queue (Queue: on)
function rendererSettings() {
	var html;
	addItemToRendererList = !addItemToRendererList;
	if (addItemToRendererList)
		html = '<font class="rendererSetting">' + getString("queue") + '</font>' +
				'<a style="display:inline" onclick="rendererSettings()"><font color="#E95922">' + getString("on") + '</font></a>';
	else
		html = '<font class="rendererSetting">' + getString("queue") + '</font>' +
				'<a style="display:inline" onclick="rendererSettings()"><font color="#E95922">' + getString("off") + '</font></a>';
	var id = document.getElementById("settingslink");
	id.innerHTML = html;
	stopTimerCurrentItem();
	stopTimerButtons();
}



// -----> renderer toolbox
function showRendererToolBox() {
	var items = getRendererItems(currentRenderer[currentPersistentID]);
	if (items == "") {
		closeRendererToolBox();
		resetRenderer();
		return;				// no media - do not show the tool box
	}
	if (itemHasProperty(items, "error")) {
		closeRendererToolBox();
		return;				// error message
	}
	var retItems = getReturnedItems(items);	// returned items
	if (retItems == 0) {
		closeRendererToolBox();
		resetRenderer();
		return;				// no play items - do not show the tool box
	}
	// add the main structure to the box
	var id = document.getElementById("rendererToolBox");
	id.style.display = "block";
	id.innerHTML =  '<div id="toolBoxHeader"></div>' + 
					'<div id="toolBoxPlaying"></div>' + 
					'<div id="toolBoxControls"></div>' + 
					'<div id="toolBoxClearQueue"></div>' + 
					'<div id="toolBoxItemList" class="toolBoxItemList"></div>' + 
					'<div id="toolBoxErrorMessage"></div>' + 
					'<div id="toolBoxPlayOrAdd"></div>';
	// add the content to the three box parts
	buildToolBoxHeader();					// toolBoxHeader
	buildToolBoxErrorMessage();				// toolBoxErrorMessage (must be done before the control and the item list is build)
	toolBoxPlaying();						// toolBoxPlaying	
	buildToolBoxControls();					// toolBoxControls
	buildToolBoxClearQueue(retItems);		// toolBoxClearQueue
	buildToolBoxItemList(items, retItems);	// toolBoxItemList
	getPlayMode();
	getCurrentPlayspeeds();	
	var state = getPlayState("state");		// state: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	setButtonImages(state);		
	updateCurrentItemInToolbox();
	startTimerCurrentItem();
	startTimerButtons();
}
function closeRendererToolBox() {
	stopTimerCurrentItem();
	stopTimerButtons();
	var id = document.getElementById("rendererToolBox");
	id.style.display = "none";
	id.innerHTML = "";
}
function buildToolBoxHeader() {
	var closeButton = '<a class="renderer-closebutton" title="' + getString("closelocaldevicebox") + '" onclick="closeRendererToolBox()"></a></div>';
	var html;
	html = '<table class="rendererToolBoxHeader" ><tr><td style="width:90%" class="titleInToolBox">';
	html += currentRendererTitle[currentPersistentID];
	html += '</td><td style="width:10%; text-align:right">'
	html += closeButton;
	html += '</td></tr><table>';
	var id = document.getElementById("toolBoxHeader");
	id.innerHTML = html;
	// add drag and drop to the toolbox window
	addDragAndDropToWindow("rendererToolBox","toolBoxHeader", "localDeviceBox");
	addTouchEventToWindow("rendererToolBox","toolBoxHeader", "localDeviceBox");
}
function toolBoxPlaying() {
	// show: current title 
	var button = "";
	var html = '<table class="rendererControls"><tr>';
	html += '<td id="toolBoxTitle" style="margin-top: 10px">&nbsp;</td>';
	html += '</tr></table>';	
	var id = document.getElementById("toolBoxPlaying");
	id.innerHTML = html;
}
function buildToolBoxControls() {
	// show buttons: mute/unmute, volume bar, max volume, prev, play/pause, next, stop, repeat, shuffle
	var button = "";
	var html =  '<div id="renderer-progress" class="renderer-progress">' +
				'<div id="renderer-seek-bar" class="renderer-seek-bar">' +
				'<div id="renderer-play-bar" class="renderer-play-bar"></div>' +
				'</div></div>' +
				'<div id="renderer-current-time" class="renderer-current-time"></div>' +
				'<div id="renderer-duration" class="renderer-duration"></div>';
	html += '<table class="rendererControls"><tr>';
	// mute/unmute (show only one button)
	button = '<div id="ButtonMute"><a class="renderer-mute" onclick="muteButton()"></a></div>';
	button += '<div id="ButtonUnmute" class="controlHidden"><a class="renderer-unmute" onclick="muteButton()"></a></div>';	
	html += '<td>' + button + '</td>';
	// volume bar
	button = '<div id="volumeBar" class="renderer-volume-bar"><div id="volumeValue" class="renderer-volume-bar-value"></div></div>';
	html += '<td>' + button + '</td>';
	// max volume
	button = '<div id="ButtonMaxVol"><a class="renderer-volume-max" onclick="maxVolumeButton()"></a></div>';
	html += '<td>' + button + '</td>';
	html += '<td style="width:20px">&nbsp;</td>';
	// previous
	button = '<div id="ButtonPrevious"><a class="renderer-previous" onclick="previousButton()" ondblclick="firstButton()"></a></div>';
	html += '<td>' + button + '</td>';
	// play or pause (show only one button )
	button = '<div id="ButtonPlay"><a class="renderer-play" onclick="playButton(true)"></a></div>';
	button += '<div id="ButtonPause" class="controlHidden"><a class="renderer-pause" onclick="pauseButton()"></a></div>';
	html += '<td>' + button + '</td>';
	// next
	button = '<div id="ButtonNext"><a class="renderer-next" onclick="nextButton()" ondblclick="lastButton()"></a></div>';
	html += '<td>' + button + '</td>';
	html += '<td style="width:10px">&nbsp;</td>';
	// stop
	button = '<div id="ButtonStop"><a class="renderer-stop" onclick="stopButton()"></a></div>';
	html += '<td>' + button + '</td>';
	html += '<td style="width:30px">&nbsp;</td>';
	// repeat/repeat off (show only one button )
	button = '<div id="ButtonRepeat"><a class="renderer-repeat" onclick="playButtonRepeat(true)"></a></div>';
	button += '<div id="ButtonRepeatOff" class="controlHidden"><a class="renderer-repeat-off" onclick="playButtonRepeatOff(true)"></a></div>';
	html += '<td>' + button + '</td>';
	// shuffle/shuffle off (show only one button )
	button = '<div id="ButtonShuffle"><a class="renderer-shuffle" onclick="playButtonShuffle(true)"></a></div>';
	button += '<div id="ButtonShuffleOff" class="controlHidden"><a class="renderer-shuffle-off" onclick="playButtonShuffleOff(true)"></a></div>';
	html += '<td>' + button + '</td>';
	html += '<td><p id="Text1"></p></td>';
	// play speed (see buildRendererPlaySpeed())
	html += '<tr id="rendererPlaySpeed">' + '<td colspan=5 align=right>';
	html += '</td>';
	html += '<td align="center">';
	html += '</td><td colspan=6 align="left">';
	html += '</td></tr>';
	html += '</tr></table>';	
	var id = document.getElementById("toolBoxControls");
	id.innerHTML = html;
	var mute = getMute();						// returns 0:mute on, 1:mute off
	setMuteButtonImage(mute);	
	addMouseClickToSeek();
	addMouseClickToVolume();
	volumeCurrentPosition = getVolume();		// get current renderer volume in %
	document.getElementById('volumeValue').style.width = parseInt(volumeCurrentPosition/2)+'px';
}

function buildRendererPlaySpeed() {
	if (!document.getElementById("rendererPlaySpeed")) return;
	var html = "";
	var speedL = "";			// speeds left  (<1)
	var speedNormal = "";		// speed normal	(=1)
	var speedR = "";			// speeds right (>1)
	var s = "";
	try {
		if (currentPlayspeeds.length <= 1) {
			html = "";		// no play speeds available
		} else {
			for (var i=0; i<currentPlayspeeds.length;i++) {
				if (currentPlayspeeds[i] < normalSpeed) {
					s = '<div id="ButtonSpeed' + i + '" class="floatR"><a class="renderer-speed" onclick="rendererSpeedButton(' + i + ')"></a></div>';
					s += '<div id="ButtonSpeedOff' + i + '" class="floatR controlHidden"><a class="renderer-speed-off"></a></div>';
					speedL = s + speedL;
				}
				if (currentPlayspeeds[i] == normalSpeed) {
					s = '<div id="ButtonSpeed' + i + '"><a class="renderer-speed-normal" onclick="rendererSpeedButton(' + i + ')"></a></div>';
					s += '<div id="ButtonSpeedOff' + i + '" class="controlHidden"><a class="renderer-speed-normal-off"></a></div>';
					speedNormal = s;
				}
				if (currentPlayspeeds[i] > normalSpeed) {
					s = '<div id="ButtonSpeed' + i + '" class="floatL"><a class="renderer-speed" onclick="rendererSpeedButton(' + i + ')"></a></div>';
					s += '<div id="ButtonSpeedOff' + i + '" class="floatL controlHidden"><a class="renderer-speed-off"></a></div>';
					speedR = speedR + s;
				}
			}
			// show the speeds		
			html += '<td colspan=5 >';
			s = '<div id="ButtonSpeedLeft" class="floatR"><a class="renderer-speed-slower" onclick="speedSlowerButton()"></a></div>';
			html += speedL + s;
			html += '</td>';
			html += '<td align="center">';
			html += speedNormal;
			html += '</td><td colspan=6 >';
			s = '<div id="ButtonSpeedRight" class="floatL"><a class="renderer-speed-faster" onclick="speedFasterButton()"></a></div>';
			html += speedR + s;
			html += '<div class="clear"></div>';
			html += '</td>';
		}
		var id = document.getElementById("rendererPlaySpeed");
		id.innerHTML = html;
	} catch (e) {
	}
}

function buildToolBoxClearQueue(retItems) {
	if (retItems == 0) return;
	// clear queue
	var html = "";
	var button = "";
	if (retItems > 1) button = '<div id="ButtonClear" ><a class="renderer-clearlist" onclick="clearControl()">' + getString("clearqueue") + '</a></div><div class="clear"></div>';
	html += button;
	var id = document.getElementById("toolBoxClearQueue");
	id.innerHTML = html;
}
// items: item list
// retItems: returned items (number of items)
function buildToolBoxItemList(items, retItems) {
	var listWithScrollbar = false;
	if (retItems == 0) {
		var id = document.getElementById("toolBoxItemList");
		id.innerHTML = "";
		return;
	}
	if (retItems > 5) listWithScrollbar = true;
	// renderer list with the columns title, artist, album and delete button
	var html = "";
	if (listWithScrollbar) html += '<div class="rendererListDiv">';
	html += '<table  id="toolBoxRendererList" class="rendererList"><tr>';
	html += itemListHeader();			// the code depends on the content type video, music and photo
	html += '</tr>';
	html += '<tbody>';
	var button = "";
	var audiobook = false;
	for (var j=0; j<retItems; j++) {
		var item = getItem(items, j);
		html += itemListItem(item, j);		// the code depends on the content type video, music and photo
		var upnpClass = getNMCPropertyText(item, "meta.upnp:class");	// get the class of the item
		if (upnpClass.indexOf("audioBook") > 0) audiobook = true;		// is it the class audioBook?
	}
	html += '</tbody>';
	html += '</table>';
	if (listWithScrollbar) html += '</div>';

	// place renderer list 
	//var html1 = '<table class="rendererListBox"><tr><td>' + html + '</td></tr></table>';
	var html1 = html;
	var id = document.getElementById("toolBoxItemList");
	id.innerHTML = html1;
	
	// if there is at least one audiobook item hide the repeat and shuffle buttons
	if (audiobook) {
		addClass("ButtonRepeat", "controlHidden");				
		addClass("ButtonShuffle", "controlHidden");				
	}
}
function itemListHeader() {
	var html = '<th>' + 'Title:' + '</th><th>Artist/Format:</th><th>Album/Year:</th><th>&nbsp;</th>';
	return html;
}
function itemListItem(item, index) {
	var html = "";
	var title = '<a class="rendererListItem" onclick="playThis(\'' + index + '\')" origIndex="' + index + '"><span id="TB_td_' + index + '">' + replaceSpecialChars(getNMCPropertyText(item, "meta.title")) + '</span></a>';
	var col2 = "&nbsp;";
	var col3 = "&nbsp;";
	var mediaType = getMediaType(item);
	switch (mediaType) {
		case "music":	
			var col2 = getNMCPropertyText(item, "meta.artist");		// artist
			var col3 = getNMCPropertyText(item, "meta.album");		// album
			break;
		case "video":
			var col2 = getNMCPropertyText(item, "meta.format");		// format
			var date = getNMCPropertyText(item, "meta.date");
			var col3 = date.substring(0, 4);						// year
			break;
		case "photo":	
			var col2 = getNMCPropertyText(item, "meta.format");		// format
			var col3 = getNMCPropertyText(item, "meta.album");		// folder
			break;
		default:
			break;
	}
	var id = "ButtonDelete" + index;
	var button = '<div  id="' + id + '" ><a class="renderer-clearitem" onclick="deleteItem(\'' + index + '\')">x</a></div>';
	html = '<tr><td>' + title + '</td><td>' + col2 + '</td><td>' + col3 + '</td><td>' + button + '</td></tr>';
	return html;
}
function getMediaType(item) {
	var mediaType = getNMCPropertyText(item, "meta.upnp.class");
	if (mediaType.indexOf(".music") > 0) return "music";
	if (mediaType.indexOf(".photo") > 0) return "photo";
	if (mediaType.indexOf(".movie") > 0) return "video";
	return "";
}

// the error message box is the last element on the renderer control. 
// the default is not to show the errors
function buildToolBoxErrorMessage() {
	var html = "";
	html += '<div id="rendererErrorMessage" class="rendererErrorMessage">' + getString("logging") + ' ';
	if (showErrorMessages) 
		html += '<a onclick="showHideErrorMessage()"><font color="#0d88c1">' + getString("on") + '</font></a>';
	else
		html += '<a onclick="showHideErrorMessage()"><font color="#0d88c1">' + getString("off") + '</font></a>';
	html += '</div>';
	html += '<div id="errorMessageFrame" class="errorMessage">';
	html += '<div class="errorMessageBox">';
	html += '<div class="errorMessageList">';
	html += '<div id="errorMessage"></div>';
	html += '</div>';		// errorMessageList
	html += '</div>';		// errorMessageBox
	html += '</div>';
	var id = document.getElementById("toolBoxErrorMessage");
	id.innerHTML = html;
	if (!showErrorMessages) 
		addClass("errorMessageFrame", "controlHidden");
}
// add an error on top of the error list
var blueTimer;
function addErrorMessage(msg) {
	try {
		var html = "";
		var id = document.getElementById("errorMessage");
		html += '<div class="fontColorBlue">' + msg + '</div>';
		id.innerHTML = html + id.innerHTML;
		blueTimer = setTimeout(updateErrorMessage, 1000);
	} catch (e) {
	}	
}
// delete the error list
function clearErrorMessage(msg) {
	var id = document.getElementById("errorMessage");
	id.innerHTML = "";
}
// show or hide the error list
function showHideErrorMessage() {
	var id = document.getElementById("errorMessageFrame");
	var id1 = document.getElementById("rendererErrorMessage");
	showErrorMessages = !showErrorMessages;
	if (showErrorMessages) {
		removeClass("errorMessageFrame", "controlHidden");
		html = getString("logging") + ' <a onclick="showHideErrorMessage()"><font color="#0d88c1">' + getString("on") + '</font></a>';	
		id1.innerHTML = html;
	} else {
		addClass("errorMessageFrame", "controlHidden");
		html = getString("logging") + ' <a onclick="showHideErrorMessage()"><font color="#0d88c1">' + getString("off") + '</font></a>';		
		id1.innerHTML = html;
	}
}
// the textcolor of every error is blue. 
// After some time the text color is changing to the default color.
function updateErrorMessage() {
	var id = document.getElementById("errorMessage");
	var html = id.innerHTML;
	// remove the text color blue
	html = html.replace(/class="fontColorBlue"/g, "");
	id.innerHTML = html;
}


function startTimerCurrentItem() {
	if (!(updateCurrentItemTimer == "")) stopTimerCurrentItem();
	updateCurrentItemTimer = setInterval("updateCurrentItemInToolbox()", updateTimerInterval);
}
function stopTimerCurrentItem() {
	clearInterval(updateCurrentItemTimer);
	updateCurrentItemTimer = "";
}
// show the title of the current playing item above the controls and
// add the class highlightElement to the current playing item to mark the item in the playlist
function updateCurrentItemInToolbox() {
	try {
		// update the title and mark the current playing item in the queue
		var id = document.getElementById("toolBoxTitle");
		if (id == null) return;
		var title = "&nbsp;";
		var playing = getPlayIndex();
		if (!(playing == "")) {
			removeClassHightlightElement();
			var index = playing.split("|");			// current item|remaining items
			var currentIndex = parseInt(index[0]);
			var table = document.getElementById("toolBoxRendererList");
			if (table.rows.length == 1) return;		// only header and no items
			var row = table.rows[currentIndex+1];	// row 0 = header, row 1 = first item
			var cell = row.cells[0];
			var id_value = cell.children[0].children[0].id;		// <td ... ><a ... ><span id ...>
			var id_td = document.getElementById(id_value);
			if (id_td == null) title = "";
			else {
				title = id_td.innerHTML;
				addClass(id_value, "highlightElement");
			}
		}
		// show the current title under the header
		var html = '<p class="currentItemInToolBox">' + title + '</p>';
		id.innerHTML = html;
	} catch (e) {
		stopTimerCurrentItem();
	}
}
// remove the class highlightElement from all items in the playlist
function removeClassHightlightElement() {
	try {
		var table = document.getElementById("toolBoxRendererList");
		for (var i = 1, row; row = table.rows[i]; i++) {
			var cell = row.cells[0];
			removeClass(cell.children[0].children[0].id, "highlightElement");	// <td ... ><a ... ><span id ...>
		}
	} catch (e) {
	}	
}


// update the renderer control controled by timer
function startTimerButtons() {
	if (!(updateButtonsTimer == "")) stopTimerButtons();
	currentSeekPosition = "00:00:00";	// reset the current position
	intervalCounter = 0;				// reset the timer count
	updateButtonsTimer = setInterval("updateRendererControl()", updateTimer2Interval);
}
function stopTimerButtons() {
	clearInterval(updateButtonsTimer);
	updateButtonsTimer = "";
}
function updateRendererControl() {
	intervalCounter++;
	var updateRendererStatus = false;
	if ((intervalCounter < updateTimer2) && (currentSeekPosition == "00:00:00")) updateRendererStatus = true;
	//if ((intervalCounter < updateTimer2)) updateRendererStatus = true;
	if ((intervalCounter % updateTimer2) == 0) updateRendererStatus = true;
	if (updateRendererStatus) {
		updateButtonsInToolbox();
		// set the progress bar based on the information from the nmc (updateButtonsInToolbox()) 
		currentSeekPercent = getCurrentSeekPercent();
		setProgressBar();
	} else  {
		updateProgress();		// increment the currentSeekPosition and update the screen
	}
}
function updateButtonsInToolbox() {
	var state = "";
	var position = "00:00:00";
	var duration = "00:00:00";
	try {
		var playState = getPlayState("all");
		var status = playState.split("|");
		if (status.length == 3) {
			state = status[0];
			position = status[1];
			duration = status[2];
		}
		currentPlayState = state;
		currentSeekPosition = position;
		currentSeekDuration = duration;
		setButtonImages(state);		// state: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	} catch (e) {
		currentPlayState = state;
		currentSeekPosition = position;
		currentSeekDuration = duration;
		stopTimerButtons();
		return;
	}
	// update the play speeds
	getCurrentPlayspeeds();
}

function updateProgress() {
	if ((currentSeekPosition == "00:00:00") && (currentSeekDuration == "00:00:00")) return;		// reached end of list
	if (currentPlayState != 1) return;															// currently not playing
	// add 1 second to currentSeekPosition
	var pos = currentSeekPosition.split(":");
	var p = parseInt(pos[2]) + (parseInt(pos[1])*60) + (parseInt(pos[0])*3600);	// seconds + minutes + hours
	p = p + 1;
	var h = Math.floor(p / 3600);
	p = p - (h*3600);
	var m = Math.floor(p / 60);
	p = p - (m*60);
	currentSeekPosition = intToString(h,2) + ":" + intToString(m,2) + ":" + intToString(p,2);
	currentSeekPercent = getCurrentSeekPercent();
	setProgressBar();
}
function intToString(intValue, size) {
    var s = intValue+"";
    while (s.length < size) s = "0" + s;	
	return s;
}
function getCurrentSeekPercent() {
	try {
		var pos = currentSeekPosition.split(":");
		var p = parseInt(pos[2]) + (parseInt(pos[1])*60) + (parseInt(pos[0])*3600);	// seconds + minutes + hours
		var dur = currentSeekDuration.split(":");
		var d = parseInt(dur[2]) + (parseInt(dur[1])*60) + (parseInt(dur[0])*3600);	// seconds + minutes + hours
		if (p >= d) {
			currentSeekPosition = currentSeekDuration;	// reached end of the song
			return 100;									// return 100%
		}
		var r = Math.round((p * 100) / d);
		return r;						// return r%
	} catch (e) {
		return 0;						// return 0%
	}
}
function setProgressBar() {
	if (rendererCanShowTheProgress) {
		document.getElementById('renderer-play-bar').style.width = currentSeekPercent+'%';
		document.getElementById('renderer-current-time').innerHTML = currentSeekPosition;
		document.getElementById('renderer-duration').innerHTML = currentSeekDuration;
	}
}
// seek forward or backwards
// works with mouse and touch
function addMouseClickToSeek() {
	document.getElementById('renderer-progress').onmousedown = function(e) {
		stopTimerButtons();
		var self = this;
		e = e || event;
		fixPageXY(e); 
		mouseX = e.pageX;
		var offset = this.getBoundingClientRect();
		var point = parseInt(mouseX - offset.left);
		var objWidth = document.getElementById('toolBoxControls').clientWidth;
		var percent = Math.round((point * 100) / objWidth);
		setSeekPercent(percent);
		startTimerButtons();
	}
}


// ----> one media item was selected by the user (call in browse.js)
// play the content on the selected device
function playBookmark(bookmark, imageID, url, elemUrl, title, artist, poster, upnpclass, isAudiobook) {
	playItem = 'item';
	// bookmark = media item
	var r;
	if (currentRenderer[currentPersistentID] == localdevice) {	
		// play on local device
		if (isAudiobook) {	// play the container audiobook			
			// beam audiobook container to local device
			// beaming audiobook container always clears the queue (is done in function playContainerOnLocalDevice())
			r = playContainerOnLocalDevice(url, true);
		} else		// play the item music, video, photo
			r = playOnLocalDevice(bookmark, url, elemUrl, title, artist, poster, upnpclass);
	} else {	
		// beam to renderer
		if (isAudiobook) {	// play the container audiobook
			// clear renderer queue
			r = clear();		
			// beam a container, not an item, so initialize the variables
			playItem = 'container';
			currentImageId = imageID;	// show the selected icon at the container
			addClass(currentImageId, "selected");
			// initiate the beam process
			var urlAudiobook = url + "?start=0";
			startBeamingContainer(urlAudiobook, imageID);
		} else {
			r = play(bookmark);
			showRendererToolBox();
			setButtonImages("1");								// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		}
	}
}


function play(bookmark) {
	if (!canPlay(bookmark, true)) return false;				// can renderer play the bookmark?	
	if (addItemToRendererList) {	// item list, queue: on
		// add bookmark to renderer
		if (!addContent(bookmark, true)) return false;			
		// start playing
		startPlayingAfterBeaming(getQueueLength()-1);		// queue length minus the just added item 
	} else {	// single item, queue: off
		if (!clear()) return false;							// clear renderer
		if (!addContent(bookmark, true)) return false;		// add bookmark to renderer	
		if (!playControl(true)) return false;				// play
	}
	return true;
}
// queueIndex: the index of the first added item to the queue
function startPlayingAfterBeaming(queueIndex) {
		var state = getState();			// returns playState|position|duration
		var states = state.split("|");
		switch (states[0]) {			// playState: 0=stopped, 1=playing, 2=preparing to play or seeking, 3=paused, 6=no media
			case "3": playControl(false);				// paused -> resume playing
					break;
			case "1": if (states[1] != "00:00:00") {	// let it play
						break;
					}
			default:		
					if (queueIndex < getQueueLength()) {
						if (queueIndex == 0)
							playControl(false);
						else
							setPlayIndex(queueIndex, false);
					}
		}
}
function getQueueLength() {
	var items = getRendererItems(currentRenderer[currentPersistentID]);
	if (items == "") return 0;
	if (itemHasProperty(items, "error")) return 0;
	var retItems = getReturnedItems(items);		// returned items
	return retItems;
}

// currentRenderer = renderer bookmark
function getState() {
	// returns playState|position|duration
	// playState: 0=stopped, 1=playing, 2=preparing to play or seeking, 3=paused, 6=no media
	var r = "";
	r = httpGet("/nmc/rpc/get_state?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&fmt=json");
	if (!callSucceeded(r, true, "Renderer state")) return "";
	return r;
}
// what: state, position, duration, all (playState|position|duration)
function getPlayState(what) {
	// playState: 0=stopped, 1=playing, 2=preparing to play or seeking, 3=paused, 6=no media
	// position: format 00:00:00
	// duration: format 00:00:00
	var r = getState();
	if (r == "") return "";
	var status = r.split("|");
	switch (what) {
		case "state": return status[0];
		case "position": return status[1];
		case "duration": return status[2];
		default: return r;
	}
}
function addContent(bookmark, showError) {
	var r = httpGet("/nmc/rpc/add_bookmark?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&item="+bookmark);
	if (!callSucceeded(r, showError, "Beam")) return false;
	return true;
}
function canPlay(bookmark, showError) {
	var r = httpGet("/nmc/rpc/can_play?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&item="+bookmark);
	if (!callSucceeded(r, showError, "Can Play")) return false;
	if (r == "0") return true;
	else showDialog("Device can not play this content.");
	return false;
}
function setDelayTime(delay, showError) {
	var r = httpGet("/nmc/rpc/get_slideshow_delay");
	if (callSucceeded(r, false, ""))  {
		if (r == delay) return;
	}
	var r = httpGet("/nmc/rpc/set_slideshow_delay?delay="+delay);
	if (!callSucceeded(r, showError, "Set Slideshow Delay")) return false;
	return true;
}
function resetRenderer() {
	var r = clear();
}

// -------------- buttons
// play
function playButton(showError) {
	stopTimerButtons();
	if (playControl(showError)) 
		setButtonImages("1");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	else 
		setButtonImages("");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	startTimerButtons();
}
// repeat on
var playRepeat = false;
function playButtonRepeat(showError) {
	stopTimerButtons();
	// enable repeat
	playRepeat = true;
	if (setPlayMode()) {
		setButtonImages("11");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		removeClass("ButtonRepeatOff", "controlHidden");
		addClass("ButtonRepeat", "controlHidden");				
	} else {
		setButtonImages("");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		playRepeat = false;
	}
	startTimerButtons();
}
// repeat off
function playButtonRepeatOff(showError) {
	stopTimerButtons();
	// disable repeat
	playRepeat = false;
	if (setPlayMode()) {
		setButtonImages("11");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		addClass("ButtonRepeatOff", "controlHidden");
		removeClass("ButtonRepeat", "controlHidden");				
	} else  {
		setButtonImages("");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		playRepeat = true;
	}
	startTimerButtons();
}
// shuffle on
var playShuffle = false;
function playButtonShuffle(showError) {
	stopTimerButtons();
	// enable shuffle
	playShuffle = true;
	if (setPlayMode()) {
		setButtonImages("12");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		removeClass("ButtonShuffleOff", "controlHidden");
		addClass("ButtonShuffle", "controlHidden");				
	} else {
		setButtonImages("");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		playShuffle = false;
	}
	startTimerButtons();
}
// shuffle off
function playButtonShuffleOff(showError) {
	stopTimerButtons();
	// disable shuffle
	playShuffle = false;
	if (setPlayMode()) {
		setButtonImages("12");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		addClass("ButtonShuffleOff", "controlHidden");
		removeClass("ButtonShuffle", "controlHidden");				
	} else {
		setButtonImages("");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		playShuffle = true;
	}
	startTimerButtons();
}
// set play speed
function rendererSpeedButton(speedIndex) {
	stopTimerButtons();
	currentSpeedIndex = speedIndex;
	var rc = setPlaySpeedControl();
	setRendererSpeed(speedIndex);
	startTimerButtons();
}
// highlight the current play speed button
function setRendererSpeed(speedIndex) {
	clearCurrentSpeedButton();
	// play video with the selected speed
	removeClass("ButtonSpeedOff"+speedIndex, "controlHidden");
	addClass("ButtonSpeed"+speedIndex, "controlHidden");				
}
// clear current playspeed button
function clearCurrentSpeedButton() {
	for (var i = 0;i<currentPlayspeeds.length;i++) {
		removeClass("ButtonSpeed"+i, "controlHidden");				
		addClass("ButtonSpeedOff"+i, "controlHidden");
	}
}
// play slower
function speedSlowerButton() {
	stopTimerButtons();
	var rc = rewindControl();
	setRendererSpeed(currentSpeedIndex);
	startTimerButtons();
}
// play faster
function speedFasterButton() {
	stopTimerButtons();
	var rc = fastForwardControl();
	setRendererSpeed(currentSpeedIndex);
	startTimerButtons();
}
// stop
function stopButton() {
	stopTimerButtons();
	if (stopControl(true)) { 
		setButtonImages("0");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
		resetAudiobookPosition();			// stop audiobook resets the audiobook position	
	} else  
		setButtonImages("");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	startTimerButtons();
}
// pause
function pauseButton() {
	stopTimerButtons();
	if (pauseControl()) 
		setButtonImages("3");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	else 
		setButtonImages("");				// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	startTimerButtons();
}
// goto first content in playlist
function firstButton() {
	stopTimerCurrentItem();
	stopTimerButtons();
	if (firstControl()) 
		setButtonImages("1");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	else
		setButtonImages("");
	updateCurrentItemInToolbox();
	startTimerCurrentItem();
	startTimerButtons();
	getCurrentPlayspeeds();	
}
// goto the previous content in playlist
function previousButton() {
	stopTimerCurrentItem();
	stopTimerButtons();
	if (previousControl()) 
		setButtonImages("1");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	else
		setButtonImages("");
	updateCurrentItemInToolbox();
	startTimerCurrentItem();
	startTimerButtons();
	getCurrentPlayspeeds();	
}
// goto the next content in playlist
function nextButton() {
	stopTimerCurrentItem();
	stopTimerButtons();
	if (nextControl()) 
		setButtonImages("1");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	else
		setButtonImages("");
	updateCurrentItemInToolbox();
	startTimerCurrentItem();
	startTimerButtons();
	getCurrentPlayspeeds();	
}
// goto the last content in playlist
function lastButton() {
	stopTimerCurrentItem();
	stopTimerButtons();
	if (lastControl())
		setButtonImages("1");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	else
		setButtonImages("");
	updateCurrentItemInToolbox();
	startTimerCurrentItem();
	startTimerButtons();
	getCurrentPlayspeeds();	
}
// start playing another content
function playThis(index) {
	stopTimerCurrentItem();
	stopTimerButtons();
	if (playThisControl(index))
		setButtonImages("1");					// r: ""=show play, pause, stop 0=stopped 1=playing 2=preparing to play 3=paused
	else
		setButtonImages("");
	updateCurrentItemInToolbox();
	startTimerCurrentItem();
	startTimerButtons();
	getCurrentPlayspeeds();	
}
// mute
function muteButton() {
	var mute = muteControl();				// return value 0=mute on, 1=mute off
	setMuteButtonImage(mute);
}
// max volume
function maxVolumeButton() {
	document.getElementById('volumeValue').style.width = '50px';	// max slider
	volumeCurrentPosition = 100;			// set new current volume position in %
	setVolume(volumeCurrentPosition);		// set new volume
}



// -----------------  controls
function playControl(showError) {
	var mode = getCurrentPlayMode();
	var r = getPlayState("state");
	// playState: 0=stopped, 1=playing, 2=preparing to play or seeking, 3=paused, 6=no media
	if (r == "3") {						// paused -> start playing
		r = httpGet("/nmc/rpc/pause?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&resume=1");
		if (!callSucceeded(r, showError, "Start playing")) return false;
	} else {
		stopTimerCurrentItem();
		// set the delay time
		if ((mode == modeNormal) || (mode == modeShuffle)) setDelayTime(delayTimeNormal, false);
		else setDelayTime(delayTimeRepeat, false);
		// start playing
		r = httpGet("/nmc/rpc/play?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&mode="+mode);
		if (!callSucceeded(r, showError, "Start playing")) return false;
		updateCurrentItemInToolbox();
		getCurrentPlayspeeds();	
		startTimerCurrentItem();
	}
	return true;
}
function getPlayMode() {
	var r = httpGet("/nmc/rpc/get_playmode?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	playShuffle = false;
	playRepeat = false;
	if (callSucceeded(r, false, "")) {
		switch(r) {
			case modeRepeat:
				playRepeat = true;
				break;
			case modeShuffle:
				playShuffle = true;
				break;
			case modeRepeatAndShuffle:
				playRepeat = true;
				playShuffle = true;
				break;
			default:
				playShuffle = false;
				playRepeat = false;
		}
	}
}
function setPlayMode() {
	var mode = getCurrentPlayMode();
	var r = httpGet("/nmc/rpc/set_playmode?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&mode="+mode);
	if (!callSucceeded(r, false, "")) return false;
	return true;
}
function getCurrentPlayMode() {
	var mode = modeNormal;									// normal play
	if (playRepeat) mode = modeRepeat; 						// repeat
	if (playShuffle) mode = modeShuffle; 					// shuffle
	if (playRepeat && playShuffle) mode = modeRepeatAndShuffle;    	// repeat and shuffle
	return mode;
}
function canRendererShowTheProgress() {
	var r = httpGet("/nmc/rpc/get_seek_capabilities?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	rendererCanShowTheProgress = false;
	if (callSucceeded(r, false, "")) {
		if (r > 0) {		// 0=no, 1=time, 2=byte, 3=time&byte
			rendererCanShowTheProgress = true;
			return true;
		}
	}
	return false;
}
function setSeekPercent(percent) {
	var r = httpGet("/nmc/rpc/seek_percent?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&seek="+percent);
	if (!callSucceeded(r, true, "Seek")) return false;
	return true;
}
function stopControl(showError) {
	var r = httpGet("/nmc/rpc/stop?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	if (!callSucceeded(r, showError, "Stop")) return false;
	return true;
}
function pauseControl() {
	var r = httpGet("/nmc/rpc/pause?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&resume=0");
	if (!callSucceeded(r, true, "Pause")) return false;
	return true;
}
function setPlaySpeedControl() {
	var r = httpGet("/nmc/rpc/set_playspeed?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&playspeed="+currentPlayspeeds[currentSpeedIndex]);
	if (!callSucceeded(r, true, "Playspeed")) return false;
	return true;
}
function rewindControl() {
	if (currentSpeedIndex == 0) return true;		// playing with slowest speed
	currentSpeedIndex = currentSpeedIndex - 1;
	if (currentSpeedIndex < 0) {
		currentSpeedIndex = 0;
		return true;			// playing with slowest speed
	}
	return setPlaySpeedControl();
}
function fastForwardControl() {
	if (currentSpeedIndex >= currentPlayspeeds.length-1) return true;		// playing with max speed
	currentSpeedIndex = currentSpeedIndex + 1;
	if (currentSpeedIndex > currentPlayspeeds.length-1) {
		currentSpeedIndex = currentPlayspeeds.length-1;
		return true;		  // playing with max speed
	}
	return setPlaySpeedControl();
}
function getCurrentPlayspeeds() {
	clearPlayspeeds();
	var r = httpGet("/nmc/rpc/get_current_playspeeds?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&fmt=json");
    try {
        var speeds = parseJson(r); 		// transform json item to object
    } catch (e) {
        return;
    }
    if (itemHasProperty(speeds, "error")) {
		currentPlayspeeds[0] = normalSpeed;
		currentSpeedIndex = 0;
        return;
    }
	currentPlayspeeds = speeds["PlaySpeeds"];
	currentSpeedIndex = -1;
	var speed = normalSpeed;
	truncateSpeeds();		// there can be up to 7 speeds below and over the normal speed
	r = httpGet("/nmc/rpc/get_playspeed?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	if (callSucceeded(r, false, "")) speed = r;
	for (var i = 0; i < currentPlayspeeds.length; i++) {
		if (currentPlayspeeds[i] == speed) currentSpeedIndex = i;
	}
	if (currentSpeedIndex == -1) {
		// index not found. Set index to the slowest or fastest speed.
		if (currentSpeedIndex < currentPlayspeeds[0]) currentSpeedIndex = 0;
		if (currentSpeedIndex > currentPlayspeeds[currentPlayspeeds.length-1]) currentSpeedIndex = currentPlayspeeds.length-1;
	}
	buildRendererPlaySpeed();
	setRendererSpeed(currentSpeedIndex);
}
// there can be up to 7 speeds below and over the normal speed. Remove the speeds beyond.
function truncateSpeeds() {
var speedR = 0;
var speedL = 0;
var speedN = 0;
	for (var i=0; i<currentPlayspeeds.length;i++) {
		if (currentPlayspeeds[i] < normalSpeed) speedL++;
		if (currentPlayspeeds[i] == normalSpeed) speedN = i;
		if (currentPlayspeeds[i] > normalSpeed) speedR++;
	}
	if (speedR > 7) {
		// truncate speeds on the right site
		var t = speedR - 7;
		for (var i=0; i<t;i++) {
			var l = currentPlayspeeds.length;
			currentPlayspeeds.splice(l-1,1);
		}
	}
	if (speedL > 7) {
		// truncate speeds on the left site
		var t = speedL - 7;
		for (var i=0; i<t;i++) {
			currentPlayspeeds.splice(0,1);
		}
	}
}
function clearPlayspeeds() {
	while (currentPlayspeeds.length > 0) {
		currentPlayspeeds.pop();
	}
}
function getPlayIndex() {
	var playing = httpGet("/nmc/rpc/get_playindex?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	if (!callSucceeded(playing, true, "Get Playindex")) return "";
	return playing;		// returns current item|remaining items in queue
}
function clear() {
	if (currentRenderer[currentPersistentID] == localdevice) return true;
	var r = getPlayState("state");
	if (r == "") return;
	// playState: 0=stopped, 1=playing, 2=preparing to play or seeking, 3=paused, 6=no media
	switch (r) {
		case "0": 					// stopped
			break;
		case "1":
		case "2":
		case "3":
			var rc = stopControl(false);	// stop renderer
			break;
		case "6": 					// no Data
			break;
		default:
			break;
	}
	// clear renderer queue
	r = httpGet("/nmc/rpc/clear?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	if (!callSucceeded(r, true, "Clear")) return false;
	stopTimerCurrentItem();
	stopTimerButtons();
	return true;
}
function clearControl() {
	if (clear()) {
		buildToolBoxItemList("",0);
		return true;
	} else return false;
}
function setPlayIndex(index, showError) {
	var r = httpGet("/nmc/rpc/set_playindex?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&index="+index);
	if (!callSucceeded(r, showError, "Set Playindex")) return false;
	return true;
}
function firstControl() {
	return setPlayIndex(0, true);
}
function previousControl() {
	var playing = getPlayIndex();
	if (playing == "") return false;
	var a = playing.split("|");
	if (a.length != 2) return false;
	var itemIndex = parseInt(a[0]);       // current item
	var remaining = parseInt(a[1]);		  // remaining items to play
	if (itemIndex > 0) {
		itemIndex = itemIndex-1;
	}
	return skipPrev(itemIndex);
}
function nextControl() {
	var playing = getPlayIndex();
	if (playing == "") return false;
	var a = playing.split("|");
	if (a.length != 2) return false;
	var itemIndex = parseInt(a[0]);     // current item
	var remaining = parseInt(a[1]);		// remaining items to play
	if (remaining > 0) {
		itemIndex = itemIndex+1;
	}
	return skipNext(itemIndex);
}
function lastControl() {
	var playing = getPlayIndex();
	if (playing == "") return false;
	var a = playing.split("|");
	if (a.length != 2) return false;
	var itemIndex = parseInt(a[0]);     // current item
	var remaining = parseInt(a[1]);		// remaining items to play
	itemIndex = itemIndex + remaining;
	return setPlayIndex(itemIndex, true);
}
function playThisControl(index) {
	// index: the index at the time the item was added to the playlist
	// get the current index of the element in the playlist (maybe items have been deleted)
	var pIndex = getPlayThisIndex(index);
	if (pIndex == -1) return false;
	return setPlayIndex(pIndex, true);
}
function getPlayThisIndex(index) {
	try {
		var tbl = document.getElementById("toolBoxRendererList");
		var findThisItem = "playThis('" + index + "')";
		for (var i = 1; i < tbl.rows.length; i++) {		// i=0: title, i=1: first item
			var row = tbl.rows[i];
			var html = row.innerHTML;
			if (html.indexOf(findThisItem, 0) > 0) { 		// found item
				return i-1;									// first table item is the title
			}
		}
		return -1;
	} catch (e) {
		return -1;
	}	
}
function muteControl() {
	var mute = getMute();
	var muteNew = 0;
	if (mute == 0) muteNew = 1;
	var r = httpGet("/nmc/rpc/set_mute?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&mute="+muteNew);
	if (!callSucceeded(r, true, "Set Mute")) return mute;
	return muteNew;
}
function getMute() {
	// mute on = 0, mute off = 1
	var r = httpGet("/nmc/rpc/get_mute?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	if (!callSucceeded(r, true, "Get Mute")) return 1;
	return parseInt(r);
}

function setVolume(vol) {
	var r = httpGet("/nmc/rpc/set_volume_percent?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&volume="+vol);
	if (!callSucceeded(r, true, "Set Volume")) return;
}
function getVolume() {
	var r = httpGet("/nmc/rpc/get_volume_percent?renderer="+getBookmark(currentRenderer[currentPersistentID]));
	if (!callSucceeded(r, true, "Get Volume")) return 0;
	return parseInt(r);
}
function skipNext(index) {
	// the index parameter is only used if the queue is not active, otherwise the parameter is ignored
	r = httpGet("/nmc/rpc/skip_next?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&index="+index);
	if (!callSucceeded(r, true, "Skip next")) return 0;
	return parseInt(r);
}
function skipPrev(index) {
	// the index parameter is only used if the queue is not active, otherwise the parameter is ignored
	r = httpGet("/nmc/rpc/skip_previous?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&index="+index);
	if (!callSucceeded(r, true, "Skip previous")) return 0;
	return parseInt(r);
}

// --------------- delete button in playlist
function deleteItem(index) {
	// index (range 0 .. x) at the time where the table was build
	// get the corresponding index of the current item list
	stopTimerCurrentItem();
	stopTimerButtons();
	try {
		var tbl = document.getElementById("toolBoxRendererList");
		var findThisItem = "deleteItem('" + index + "')";
		var delIndex = -1;
		for (var i = 1; i < tbl.rows.length; i++) {		// i=0: title, i=1: first item
			var row = tbl.rows[i];
			var html = row.innerHTML;
			if (html.indexOf(findThisItem, 0) > 0) {	// found item
				delIndex = i-1;							// first item: delIndex=0
			}
		}
	} catch (e) {}
	if (delIndex < 0) return;	// index not found
	var setNewPlayIndex = false;
	if (isCurrentPlayingItem(delIndex)) {
		// the current playing item should be deleted
		stopControl(false); 			// stop playing
		setNewPlayIndex = true;
	}
	// the current playing item should be deleted
	// delete item in renderer queue
	var r = httpGet("/nmc/rpc/delete_item?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&index="+delIndex);
	if (!callSucceeded(r, true, "Delete")) return;
	try {		// delete item in toolbox
		var id = document.getElementById("toolBoxRendererList");
		id.deleteRow(delIndex+1);
	} catch (e) {}
	if (setNewPlayIndex) {			// set new playindex
		if (id.rows.length == 1) {
			updateCurrentItemInToolbox();
			return;		// only title row left
		}
		if (delIndex == 0) {
			updateCurrentItemInToolbox();
			return;				// last item was deleted
		}
		var r = httpGet("/nmc/rpc/set_playindex?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&index="+delIndex);
	}
	updateCurrentItemInToolbox();
	startTimerCurrentItem();
	startTimerButtons();
	getCurrentPlayspeeds();	
}
function isCurrentPlayingItem(index) {
	var playing = getPlayIndex();
	if (playing == "") return false;
	var a = playing.split("|");
	if (a.length != 2) return false;
	var itemIndex = parseInt(a[0]);     // current item
	if (itemIndex == index) return true;
	return false;
}

// get renderer items
function getRendererItems(renderer) {
	if (renderer == localdevice) return "";
	var r=httpGet(renderer+"?fmt=json");
	if (!callSucceeded(r, true, "No items")) return "";
	else {
		try {
			var list = parseJson(r);	// transform json item to object
		} catch (e) { return ""; }
	}
	return list;
}




// ----> a container was selected by the user (call in browse.js)
// add the media items of the container to the renderer queue and show a message box
function playContainer(url, imageID) {
	playItem = 'container';
	// show the selected icon at the container
	currentImageId = imageID;	// global var
	addClass(currentImageId, "selected");
	// bookmark = container
	// add container items to the renderer queue
	if (currentRenderer[currentPersistentID] == localdevice) {
		// play on local device
		r = playContainerOnLocalDevice(url, false);
		removeClass(currentImageId, "selected");
		return;
	}
	// play on a renderer
	startBeamingContainer(url, imageID);
}
function startBeamingContainer(url, imageID) {
	// beam the container items to the renderer
	var htmlBtn = '<a class="actionbtnmd floatL" onclick="javascript:stopPlayContainer();" > \
				   <span class="actionbtn_l"></span><span class="actionbtn_c">' + getString("stop") + '</span><span class="actionbtn_r"></span></a>';
	displayBox();		// show progress and a break button
	showMessage(getString("beamtodevice2"), htmlBtn);
	setMessageBody("Beaming items.");
	setTimeout(function(){startPlayContainer(url, imageID)}, 100);
}

// ----> url = <url>?start=0&count=<childcount>
function startPlayContainer(url, imageID) {
    var paramPieces = url.split("?");
    var url = paramPieces[0];
    var paramPieces2 = paramPieces[1].split("&");
    var start = paramPieces2[0].split("=")[1];
    var response = httpGet(url + "?start=" + start + "&fmt=json");
    if (!response) {
		showDialog("Can not get the media items.");
		return;
	}
    try {
        var json = parseJson(response);
    } catch (e) { 
		showDialog("Can not get the media items.");
		return; 
	}
    if (itemHasProperty(json, "error")) {
		showDialog("Can not get the media items.");
		return;
	}	
	var canNotPlay = 0;
	var canNotAdd = 0;
	var withError = 0;
	var container = 0;
	var index = 0;
	var queueLength = 0;
	var count = getNMCPropertyInt(json, "childCount", 0);					// get the child count from the container
	var countContainer = 0;
	for (var i = 0; i < count; i++) {
		var elem = getItem(json, i);
		if (elem == "") continue;
		if (isContainer(elem)) countContainer++;
	}
	if (count == countContainer) {
		showDialog(getString("containerisempty"));
		return;
	}
	// renderer
	if (addItemToRendererList) {	
		queueLength = getQueueLength();		// Queue: on
	} else {
		var r = clear();					// clear renderer queue, Queue: off
	}
	getContainerItem(json, index, count, canNotPlay, canNotAdd, withError, container, queueLength);
}
function getContainerItem(json, index, count, canNotPlay, canNotAdd, withError, container, queueLength) {
	var elem = getItem(json, index);
	var skip = false;
	if (elem == "") {
		withError++;
		skip = true;
	}
	if (!skip) {
		if (isContainer(elem)) {
			container++;
			skip = true;
		}
	}
	if (!skip) {
		var bookmark = getNMCPropertyText(elem, "bookmark");
		if (!skip && !canPlay(bookmark, false)) {			// can renderer play the bookmark?
			canNotPlay++;
			skip = true;
		}
	}
	if (!skip) {
		if (addContent(bookmark, false)) {	// add bookmark to renderer	
			var z = index+1;
			var str1 = "Beaming item: {0} / {1}";
			str1 = str1.replace(/\{0\}/, String(z));
			str1 = str1.replace(/\{1\}/, String(count));
			setMessageBody(str1);	// show the current state on the message box
		} else {
			canNotAdd++;
			skip = true;
		}
	}
	if (index+1 < count) {	
		index++;			// beam next container item
		setTimeout(function(){getContainerItem(json, index, count, canNotPlay, canNotAdd, withError, container, queueLength)}, 10);	
	} else {				// done - all items have been beamed to the renderer
		try {			
			// change the message text to: Beaming items: n / m (z container) and
			// show error message: Could not add {0} items to renderer queue.
			var i = index+1-container;					// first line
			var html1 = "Beaming item: {0} / {1}";
			html1 = html1.replace(/\{0\}/, String(i));
			html1 = html1.replace(/\{1\}/, String(count));
			var html = html1;		
			html1 = " ({0} container)";					// show the number of containers
			html1 = html1.replace(/\{0\}/, String(container));		
			if (container > 0) html += html1;
			var j = canNotPlay+canNotAdd+withError;		// show error line
			html1 = "<br><br>Could not beam {0} items to renderer queue.";
			html1 = html1.replace(/\{0\}/, String(j));
			if (j > 0) html += html1;
			setMessageBody(html);
			// change the button text from stop to ok on the message box
			var id = document.getElementById("dialogButtonContainer");
//			html = '<a class="actionbtnmd floatL" onclick="javascript:okPlayContainer();" > \
//				   <span class="actionbtn_l"></span><span class="actionbtn_c">' + 'OK' + '</span><span class="actionbtn_r"></span></a>';
			html = "";
			setMessageButtons(html);
			// get the parameter
			var upnpclass = isAudiobookContainer(json);
			var playbackBookmark = "";
			var playbackTimeOffset = "";
			var playbackByteOffset = "";
			if (upnpclass) {
				// play audiobook
				playbackBookmark = getNMCPropertyText(json, "pv:playbackBookmark");
				playbackTimeOffset = getNMCPropertyText(json, "pv:playbackTimeOffset");
				playbackByteOffset = getNMCPropertyText(json, "pv:playbackByteOffset");
				showRendererToolBox();
				startPlayingAfterBeamingAudiobook(playbackBookmark, playbackTimeOffset, playbackByteOffset);
			} else {
				// start playing the first added item to the queue
				startPlayingAfterBeaming(queueLength);		// queueLength is the old queue length before adding the items to the queue
				fadeOutMessageBox();			
			}
		} catch(e) {}
		removeClass(currentImageId, "selected");
	}
}
// start playing audiobooks from the beginning or resume playing
// if a position was saved ask the user if he likes to resume playing or start from the beginning
function startPlayingAfterBeamingAudiobook(playbackBookmark, playbackTimeOffset, playbackByteOffset) {
	if ((playbackTimeOffset != "") || (playbackByteOffset != "")) {
		// ask user if he wants to resume playing or start from the beginning
		var htmlBtn = '<a class="actionbtnmd floatL" onclick="javascript:playFromPosition(\''+playbackBookmark+'\',\''+playbackTimeOffset+'\',\''+playbackByteOffset+'\');" > \
					   <span class="actionbtn_l"></span><span class="actionbtn_c">' + getString("resumeaudiobook") + '</span><span class="actionbtn_r"></span></a>';
		htmlBtn += '<a class="actionbtnmd floatL" onclick="javascript:playFromPosition(\'\',\'0\',\'\');" > \
					   <span class="actionbtn_l"></span><span class="actionbtn_c">' + getString("restartaudiobook") + '</span><span class="actionbtn_r"></span></a>';
		displayBox();		// show progress and a break button
		showMessage(getString("beamtodevice2"), htmlBtn);
		setMessageBody(getString("audiobookresumeplaying"));
	} else playFromPosition(playbackBookmark,"","");
}
function playFromPosition(playbackBookmark, playbackTimeOffset, playbackByteOffset) {
	hideBox();
	var r = httpGet("/nmc/rpc/play_from_position?renderer="+getBookmark(currentRenderer[currentPersistentID])+"&bookmark="+playbackBookmark+"&startposms="+playbackTimeOffset+"&startposbyte="+playbackByteOffset);
	if (!callSucceeded(r, true, "Resume playing")) return false;
	return true;
}
function resetAudiobookPosition() {
	// stop button was pressed. if an audiobook is playing clear the audiobook position.
	var id = document.getElementById("ButtonRepeat");
	var b = hasClass(id, "controlHidden");				
	if (b) {
		// if the renderer queue contains an audiobook the controls ButtonRepeat and ButtonShuffle are hidden
		var r = httpGet("/nmc/rpc/reset_audiobook_position?renderer="+getBookmark(currentRenderer[currentPersistentID]));
		if (!callSucceeded(r, true, "Reset play position")) return false;
		return true;
	}
}
// stop was pressed while beaming container items to the renderer
function stopPlayContainer() {
	clearMessage();
	hideBox();
	removeClass(currentImageId, "selected");
	showRendererToolBox();
}
// beaming ready - fade out the message box
function fadeOutMessageBox() {
	if (!(fadeOutTimer == "")) stopFadeOutTimer();
	fadeOutTimerCounter = 0;
	fadeOutTimer = setInterval("updateFadeOutTimer()", fadeOutTimerInterval);	
}
function updateFadeOutTimer() {
	fadeOutTimerCounter = fadeOutTimerCounter + 1;
	var thediv=document.getElementById("dialogContent");
	var o = 10 - fadeOutTimerCounter;
	if (o < 0) o = 0;
	thediv.style.opacity = "0." + o;
	thediv.style.filter = "alpha(opacity = " + o + "0)";	
	if (fadeOutTimerCounter >= 10) stopFadeOutTimer();
}
function stopFadeOutTimer() {
	clearInterval(fadeOutTimer);
	fadeOutTimer = "";
	var thediv=document.getElementById("dialogContent");
	thediv.style.opacity = "1.0";
	thediv.style.filter = "alpha(opacity = 100)";		
	clearMessage();
	hideBox();
	showRendererToolBox();
}



function callSucceeded(response, showError, message) {
    try {
		if (!response) return false;
		if (response.length > 0) {
			if (response.substring(0,6) == "<HTML>") return false;
			if (!(response.substring(0,1) == "{")) return true;
			var r = parseJson(response);				// transform json item to object
		} else return true;
    } catch (e) {
		return true;
	}
	if (! itemHasProperty(r, "success")) return true;
	
	if (!r.success) {
		if (showError) {
			addErrorMessage(message + " - " + r.code + ": " + r.message);
			//showDialog(message + "\n\r" + r.code + ": " + r.message);
		}
		return false;
	}
	return true;
}
function showDialog(msg){
	alert(msg);
}

function showShuffleRepeat() {
	if (playShuffle) {
		removeClass("ButtonShuffleOff", "controlHidden");
		addClass("ButtonShuffle", "controlHidden");				
	} else {
		addClass("ButtonShuffleOff", "controlHidden");
		removeClass("ButtonShuffle", "controlHidden");				
	}
	if (playRepeat) {
		removeClass("ButtonRepeatOff", "controlHidden");
		addClass("ButtonRepeat", "controlHidden");				
	} else {
		addClass("ButtonRepeatOff", "controlHidden");
		removeClass("ButtonRepeat", "controlHidden");				
	}
}
function showPlay(show) {
	if (show) {	// show play, hide pause
		removeClass("ButtonPlay", "controlHidden");
		addClass("ButtonPause", "controlHidden");
	} else {	// show pause, hide play
		removeClass("ButtonPause", "controlHidden");
		addClass("ButtonPlay", "controlHidden");
	}	
}
function setButtonImages(r) {
	showShuffleRepeat();
	currentPlayState = r;
	try {
		if (r == "") {
			showPlay(true);			// show play, pause not active
			return;
		}
		if (r == "0") {				// stopped
			showPlay(true);			// show play, pause not active
			return;
		}
		if (r == "1") {				// playing
			showPlay(false);		// play not active, show pause
			return;
		}
		if (r == "2") {				// preparing to play
			showPlay(false);		// play not active, show pause
			return;
		}
		if (r == "3") {				// paused
			showPlay(true);			// show play, pause not active
			return;
		}
		if (r == "9") {				// rewind or fast forward
			currentPlayState = "1";
			showPlay(true);			// show play, pause not active
			return;
		}
		if (r == "11") {			// repeat
			currentPlayState = "1";
			showPlay(false);		// play not active, show pause
			return;
		}
		if (r == "12") {			// shuffle
			currentPlayState = "1";
			showPlay(false);		// play not active, show pause
			return;
		}
		showPlay(true);			// show play, pause not active
	} catch(e) {
		showPlay(true);			// show play, pause not active
	}
}
function setMuteButtonImage(mute) {
	// 0:mute on, 1:mute off
	if (mute == 1) {
		removeClass("ButtonUnmute", "controlHidden");
		addClass("ButtonMute", "controlHidden");			
	} else {
		removeClass("ButtonMute", "controlHidden");
		addClass("ButtonUnmute", "controlHidden");			
	}
}

function showLoadingGraphicButton(imageID) {
	setImageSrc(imageID, beamButtonImageLoading);
}
function setImageSrc(imageID, buttonSrc) {
	try {
		var id = document.getElementById(imageID);
		if (id == null) return;
		id.src = beamButtonPath + buttonSrc;
    } catch (e) {
    }
}


// manage drag and drop for renderer box
function addDragAndDropToWindow(box, boxHeader, box2) {
	document.getElementById(boxHeader).onmousedown = function() {
	  //this.style.position = 'absolute';
	  var self = this;
	  startDragAndDrop = true;
	  stopMouseMove = false;
	  var id = document.getElementById(box);
	  windowOffsetLeft = parseInt(id.offsetLeft);
	  windowOffsetTop = parseInt(id.offsetTop);
	  //windowOffsetHeight = parseInt(id.offsetHeight);
	  windowWidth = window.innerWidth ||
				    html.clientWidth  ||
				    body.clientWidth  ||
				    screen.availWidth;

	  windowHeight = window.innerHeight ||
				     html.clientHeight  ||
				     body.clientHeight  ||
				     screen.availHeight;	  
	  document.onmousemove = function(e) {
		e = e || event;
		fixPageXY(e); 
		if (startDragAndDrop) {
			mouseStartX = e.pageX;
			mouseStartY = e.pageY;
			startDragAndDrop = false;
		}
		// new x position
		var deltaX = e.pageX-mouseStartX;		// current mouse position - first mouse position
		var left = windowOffsetLeft + deltaX;
		//id.style.left = left+'px';
		id.style.left = ((left*100)/windowWidth)+'%';
		// new y position
		var deltaY = e.pageY-mouseStartY;		// current mouse position - first mouse position
		var top = windowOffsetTop + deltaY;
		//id.style.top = top+'px';
		id.style.top = ((top*100)/windowHeight)+'%';
		// set height
		//id.style.height = windowOffsetHeight+'px';
		// rendererToolBox and localDeviceBox should be always on the same location
		var id2 = document.getElementById(box2);
		id2.style.left = left+'px';
		id2.style.top = top+'px';
		if (stopMouseMove) stopDragAndDrop();
	  }
	  this.onmouseup = function() {
		stopDragAndDrop();
	  }
	}
	document.getElementById(box).ondragstart = function() { 
		return false; 
	}
}
function addTouchEventToWindow(box, boxHeader, box2) {
	document.getElementById(boxHeader).ontouchstart = function() {
	  var self = this;
	  startDragAndDrop = true;
	  stopMouseMove = false;
	  var id = document.getElementById(box);
	  windowOffsetLeft = parseInt(id.offsetLeft);
	  windowOffsetTop = parseInt(id.offsetTop);
	  document.ontouchmove = function(e) {
		e = e || event;
		fixPageXY(e); 
		if (startDragAndDrop) {
			mouseStartX = e.pageX;
			mouseStartY = e.pageY;
			startDragAndDrop = false;
		}
		// new x position
		var deltaX = e.pageX-mouseStartX;		// current mouse position - first mouse position
		var left = windowOffsetLeft + deltaX;
		id.style.left = left+'px';
		// new y position
		var deltaY = e.pageY-mouseStartY;		// current mouse position - first mouse position
		var top = windowOffsetTop + deltaY;
		id.style.top = top+'px';
		if (stopMouseMove) stopDragAndDrop();
		// rendererToolBox and localDeviceBox should be always on the same location
		var id2 = document.getElementById(box2);
		id2.style.left = left+'px';
		id2.style.top = top+'px';
	  }
	  this.ontouchend = function() {
		stopDragAndDrop();
	  }
	}
}
function stopDragAndDrop() {
	document.onmousemove = null;
	document.ontouchmove = null;
}


// set a new volume
// works with mouse and touch
function addMouseClickToVolume() {
	document.getElementById('volumeBar').onmousedown = function(e) {
		var self = this;
		e = e || event;
		fixPageXY(e); 
		mouseX = e.pageX;
		var offset = this.getBoundingClientRect();
		var width = parseInt(mouseX - offset.left);
		document.getElementById('volumeValue').style.width = width+'px';
		volumeCurrentPosition = width * 2;		// set new current volume position in %
		setVolume(volumeCurrentPosition);		// set new volume
	}
}
function fixPageXY(e) {
  if (e.pageX == null && e.clientX != null ) { 
    var html = document.documentElement
    var body = document.body
    e.pageX = e.clientX + (html.scrollLeft || body && body.scrollLeft || 0)
    e.pageX -= html.clientLeft || 0
    e.pageY = e.clientY + (html.scrollTop || body && body.scrollTop || 0)
    e.pageY -= html.clientTop || 0
  }
}


// display message box
function displayBox() {
	var thediv=document.getElementById("dialogBox");
	if(thediv.style.display == "none"){
		thediv.style.display = "";
	}
	thediv=document.getElementById("dialogWrapper");
	if(thediv.style.display == "none"){
		thediv.style.display = "";
	}
}
function hideBox() {
	try {		
		var thediv=document.getElementById("dialogBox");
		if(thediv.style.display == ""){
			thediv.style.display = "none";
		}
	} catch(e) {}
	try {		
		var thediv=document.getElementById("dialogWrapper");
		if(thediv.style.display == ""){
			thediv.style.display = "none";
		}
	} catch(e) {}
}
// boxHeader: text string
// defaultButton: html code of the default button on the button of the message box
// example: "Beam content to renderer", "<a class="actionbtnmd floatL" onclick="function();"><span class="actionbtn_l"></span><span class="actionbtn_c">Stop</span><span class="actionbtn_r"></span></a>';"
function showMessage(boxHeader, defaultButton) {
	try {		
		var thediv=document.getElementById("dialogContent");		// no transparency
		thediv.style.opacity = "1.0";
		thediv.style.filter = "alpha(opacity = 100)";		
	} catch(e) {}
	try {
		var thediv=document.getElementById('dialogContentTitle');	// set title
		thediv.innerHTML = boxHeader;
	} catch(e) {}
	try {
		var html = "";
		thediv=document.getElementById('dialogBody');				// set body
		thediv.innerHTML = html;
	} catch(e) {}
	try {
		thediv=document.getElementById('dialogButtonContainer');	// set buttons
		thediv.innerHTML = defaultButton;
	} catch(e) {}
}
function clearMessage() {
	var thediv=document.getElementById('dialogContentTitle');	// set title
	thediv.innerHTML = "";
	thediv=document.getElementById('dialogBody');				// set body
	thediv.innerHTML = "";
	thediv=document.getElementById('dialogButtonContainer');	// set buttons
	thediv.innerHTML = "";
}
function setMessageBody(str) {
	try {		
		var thediv = document.getElementById("dialogBody");
		thediv.innerHTML = str;
	} catch(e) {}
}
function setMessageButtons(str) {
	try {		
		var thediv = document.getElementById("dialogButtonContainer");
		thediv.innerHTML = str;
	} catch(e) {}
}
