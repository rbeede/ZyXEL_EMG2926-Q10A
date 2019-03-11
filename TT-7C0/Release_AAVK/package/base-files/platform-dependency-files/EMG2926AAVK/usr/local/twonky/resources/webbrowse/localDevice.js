/*  -----jPlayer
The cover art is disorted/scaled proportional in jPlayer. 
The following changes have been made to prevent the image to be scaled:
 - jquery.jplayer.min.js
   replace << this.internal.poster.jq.css({width:this.status.width >> with << this.internal.poster.jq.css({width:"auto" >> (2 times)
 - jplayer.blue.monday.css
   add << text-align: center; >> to the class << div.jp-jplayer audio, div.jp-jplayer{} >>	
   change the background color from << background-color: #000000; >> to << background-color: #EEEEEE; >> (class << div.jp-jplayer{} >>)
*/
// var myPlaylist; is defined in renderer.js
var screenWidth = 640;
var screenHeight = 480;
var screenResolutionW = new Array(160, 640, 1024, 1920);
var screenResolutionH = new Array(160, 480, 768, 1080);
var resolutionIndex = 0;

var slideshowSpeeds = new Array(0, 2000, 6000, 10000);
var slideshowTimer;
var slideshowSpeed_startIndex = 2;		// normal speed (6000 milli seconds)
var slideshowSpeed = slideshowSpeeds[slideshowSpeed_startIndex];


// do not show the repeat/shuffle buttons 
// when there was an audiobook item beamed to the local device
function hideRepeatShuffleButtons() {
	addClass("jp-toggles", "controlHidden");				
}
function showRepeatShuffleButtons() {
	removeClass("jp-toggles", "controlHidden");				
}

// ----->  jPlayer functions, HTML5
// play content on local device (jPlayer: music and video, HTML5: photo)
function playOnLocalDevice(bookmark, url, elemUrl, title, artist, poster, upnpclass) {
	if (upnpclass.indexOf("audioItem") > 0) foreignUnknownServerClass = persistentIDMusic;
	if (upnpclass.indexOf("videoItem") > 0) foreignUnknownServerClass = persistentIDVideo;
	if (upnpclass.indexOf("imageItem") > 0) foreignUnknownServerClass = persistentIDPhoto;
	// music: open the jPlayer
	// if navigating music OR an audio item on the unknown server
	if ((!foreignUnknownServer && (currentPersistentID == persistentIDMusic)) || (foreignUnknownServer && (foreignUnknownServerClass == persistentIDMusic))) {
		if (!document.getElementById("jPlayerPlayList")) {
			if (!initJPlayerBoxForLocalPlay()) return;		// init jPlayer
		}	
		showLocalDeviceBox(true, false);
		if (addItemToRendererList) {  // item list
			addJPlayerItem(unescape(url), unescape(title), unescape(artist), unescape(poster));
		} else {					  // single item 
			setJPlayerItem(unescape(url), unescape(title), unescape(artist), unescape(poster));
		}
		// do not show the button repeat and shuffle if it is an audiobook
		if (upnpclass.indexOf("audioBook") > 0) hideRepeatShuffleButtons();
		return;
	}
	// video: open a new browser tab and play the video
	// if navigating video OR an video item on the unknown server
	if ((!foreignUnknownServer && (currentPersistentID == persistentIDVideo)) || (foreignUnknownServer && (foreignUnknownServerClass == persistentIDVideo))) {
		window.open(url, "_blank");
		return;
	}
	// photo: open the local photo viewer
	// if navigating photo OR an image item on the unknown server
	if ((!foreignUnknownServer && (currentPersistentID == persistentIDPhoto)) || (foreignUnknownServer && (foreignUnknownServerClass == persistentIDPhoto))) {
		if (!document.getElementById("photoBox")) {
			if (!initPhotoBox()) return;		// init photo box
		}
		showLocalDeviceBox(true, false);
		var urlBest = getPhoto(elemUrl);
		if (addItemToRendererList) {  // item list
			addPhotoItem(urlBest, unescape(title), true);
		} else {					  // single item 
			setPhotoItem(urlBest, unescape(title));
		}
		return;
	}
	// default: open the url in a new browser tab
	window.open(url, "_blank");
}
function getPhoto(url) {
    var response = httpGet(url + "?start=0&count=1&fmt=json");
    if (!response) return url;
    try {
        var json = parseJson(response);
    } catch (e) { 
		return url; 
	}
    if (itemHasProperty(json, "error")) return url;
	var elem = getItem(json, 0);
	if (elem == "") return url;
	return getPhotoUrl(elem);
}
// add the items of the container to the local player
function playContainerOnLocalDevice(url, isAudiobook) {
	if (isAudiobook) {
		var response = httpGet(url + "?start=0&fmt=json");
	} else {
		var paramPieces = url.split("?");
		var url = paramPieces[0];
		var paramPieces2 = paramPieces[1].split("&");
		var start = paramPieces2[0].split("=")[1];
		var response = httpGet(url + "?start=" + start + "&fmt=json");
	}
    if (!response) {
		showDialog("Can not get the media items.");
		return;
	}
    try {
        var json = parseJson(response);
    } catch (e) { 
		showDialog(getString("playcontainererror"));
		return; 
	}
    if (itemHasProperty(json, "error")) {
		showDialog(getString("playcontainererror"));
		return;
	}	
	
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
	// video and/or Music -> jPlayer
	if ((currentPersistentID == persistentIDMusic) || (currentPersistentID == persistentIDVideo)) {
		if (!document.getElementById("jPlayerPlayList")) {
			if (!initJPlayerBoxForLocalPlay()) return;		// init jPlayer
		}
		showLocalDeviceBox(true, false);
		for (var index = 0; index < count; index++) {
			var elem = getItem(json, index);
			if (elem == "") continue;
			if (isContainer(elem)) continue;
			var url = getNMCPropertyText(elem, "meta.res.value", 0);
			var title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
			var artist = getNMCPropertyText(elem, "meta.artist");
			var poster = getThumbnail(elem);
			// if queuing is off (addItemToRendererList=Queue on) clear the queue
			// if it is an audiobook container clear the queue
			if ((!addItemToRendererList && (index == 0)) || (isAudiobook && (index == 0)))  
				setJPlayerItem(url, title, artist, poster);	// clear list on local device and add first item
			else
				addJPlayerItem(url, title, artist, poster);	// add items to local device
			// do not show the button repeat and shuffle if it is an audiobook
			var upnpclass = getNMCPropertyText(elem, "meta.upnp:class");	// get the class of the item			
			if (upnpclass.indexOf("audioBook") > 0) hideRepeatShuffleButtons();
		}
	}
	// photo -> HTML
	if (currentPersistentID == persistentIDPhoto) {
		if (!document.getElementById("photoBox")) {
			if (!initPhotoBox()) return;		// init photo box
		}
		showLocalDeviceBox(true, false);
		for (var index = 0; index < count; index++) {
			var elem = getItem(json, index);
			if (elem == "") continue;
			if (isContainer(elem)) continue;
			var url = getPhotoUrl(elem);
			var title = replaceSpecialChars(getNMCPropertyText(elem, "meta.title"));
			if (!addItemToRendererList && (index == 0)) 
				setPhotoItem(url, title);	// clear list on local device and add first item
			else
				if (index == 0) addPhotoItem(url, title, true);	// add items to local device
				else addPhotoItem(url, title, false);
		}
	}
}
function getPhotoUrl(elem) {
	try {
		var url = "";
		var i = getNMCPropertyInt(elem, "meta.res.length", 0);
		if (i == 1) return getNMCPropertyText(elem, "meta.res.value", 0);	// no scaled photos 
		// find the scaled photo that fits best into the window
		i = i - 1;
		var bestRes = -1;
		var bestResIndex = 0;
		var currentRes = screenResolutionW[resolutionIndex] * screenResolutionH[resolutionIndex];
		while (i >= 0) {
			var res = getNMCPropertyText(elem, "meta.res.resolution", i);
			var resolution = res.split("x");
			var r = parseInt(resolution[0])*parseInt(resolution[1]);
			var r1 = bestRes - currentRes;
			var r2 = r - currentRes;
			if (r2 >= 0) {
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
			i = i - 1;
		}
		return getNMCPropertyText(elem, "meta.res.value", bestResIndex);
	} catch(e) {
		return getNMCPropertyText(elem, "meta.res.value", 0);
	}
}


// init jPlayer
function initJPlayerBoxForLocalPlay() {
    try {
		if (document.getElementById("jPlayerPlayList"))  {
			showLocalDeviceBox(false, false);
			return true;   // jPlayer is already loaded
		}
		var response = httpGet("/resources/webbrowse/jPlayerPlayList.htm");
		if (!response) return false;
		var id = document.getElementById("localDeviceBox");
		id.style.display = "block";
		id.innerHTML = '<div id="localDeviceBoxHeader"></div>' + response;
		replaceStrings("jPlayerPlayList");
		buildLocalDeviceHeader();
		// init local playlist
		var cssSelector = { jPlayer: "#jquery_jplayer_1", cssSelectorAncestor: "#jp_container_1" };
		var playlist = [ ]; // Empty playlist
		// the default option solution is "html,flash"
		var options = { swfPath: "/resources/webbrowse/jPlayer", supplied: "webmv, m4v, ogv, mp3, oga", playlistOptions: { autoPlay: true, enableRemoveControls: true }, size: {height: "160px", width: "400px"} };
		myPlaylist = new jPlayerPlaylist(cssSelector, playlist, options);	
		$("#jquery_jplayer_1").bind($.jPlayer.event.error, function(event) {
            var errorMsg = event.jPlayer.error.message;		// error message
            var mediaName = event.jPlayer.status.src;		// content to play
			if (mediaName.length > 0) {
				var html = '<a class="actionbtnmd floatL" onclick="javascript:showMediaContent(\'' + mediaName + '\');" >';
				html += '<span class="actionbtn_l"></span><span class="actionbtn_c">' + getString("ok") + '</span><span class="actionbtn_r"></span></a>';
				html += '<a class="actionbtnmd floatL" onclick="javascript:clearMessage();hideBox();" >';
				html += '<span class="actionbtn_l"></span><span class="actionbtn_c">' + getString("cancel") + '</span><span class="actionbtn_r"></span></a>';
				displayBox();		// show message box
				showMessage(getString("cannotbeam"), html);
				setMessageBody(getString("tryotherplayer"));
			}
		});		
	    return true;
    } catch (e) {
		return false;
    }
}
function showMediaContent(mediaName) {
	clearMessage();
	hideBox();
    window.open(mediaName, "_self", 'menubar=yes,scrollbars=yes,status=yes,toolbar=yes,resizable=yes');	
}
function buildLocalDeviceHeader() {
	var closeButton = '<a class="jp-closebutton" title="' + getString("closelocaldevicebox") + '" onclick="closeJPlayerBox()"></a></div>';
	var html;
	html = '<table class="rendererToolBoxHeader" ><tr><td style="width:90%" class="titleInToolBox">';
	html += currentRendererTitle[currentPersistentID];
	html += '</td><td style="width:10%; text-align:right">'
	html += closeButton;
	html += '</td></tr><table>';
	var id = document.getElementById("localDeviceBoxHeader");
	id.innerHTML = html;
	// add drag and drop to the toolbox window
	addDragAndDropToWindow("localDeviceBox", "localDeviceBoxHeader", "rendererToolBox");
	addTouchEventToWindow("localDeviceBox", "localDeviceBoxHeader", "rendererToolBox");
}

// add and set items to local player
function addJPlayerItem(url, title, artist, poster) {
	var item = new Object();	
	if ((currentPersistentID == persistentIDMusic) || (foreignUnknownServer && (foreignUnknownServerClass == persistentIDMusic))) {
		//var item = { title: "", artist: "", free: true, mp3: "", poster: ""};
		item["title"] = title;
		item["artist"] = artist;
		item["mp3"] = url;
		item["poster"] = poster;
	} else {
		if ((currentPersistentID == persistentIDVideo) || (foreignUnknownServer && (foreignUnknownServerClass == persistentIDVideo))) {
			//var item = { title: "", artist: "", mp4: "", poster: ""};
			item["title"] = title;
			item["artist"] = artist;
			item["m4v"] = url;
			item["poster"] = poster;
		} else return;
	}
	// playlist is empty. Show the buttons and add then the item to the playlist.
	if (myPlaylist.playlist.length == 0) showRepeatShuffleButtons();
	myPlaylist.add( item );
}
function setJPlayerItem(url, title, artist, poster) {
	var itemlist = new Array();
	if ((currentPersistentID == persistentIDMusic) || (foreignUnknownServer && (foreignUnknownServerClass == persistentIDMusic))) {
		itemlist[0] = new Object();	
		itemlist[0]["title"] = title;
		itemlist[0]["artist"] = artist;
		itemlist[0]["mp3"] = url;
		itemlist[0]["poster"] = poster;
	} else {
		if ((currentPersistentID == persistentIDVideo) || (foreignUnknownServer && (foreignUnknownServerClass == persistentIDVideo))) {
			itemlist[0] = new Object();	
			itemlist[0]["title"] = title;
			itemlist[0]["artist"] = artist;
			itemlist[0]["m4v"] = url;
			itemlist[0]["poster"] = poster;
		} else return;
	}
	myPlaylist.setPlaylist( itemlist );
	// the playlist is reset. Show the buttons and add then the item to the playlist.
	showRepeatShuffleButtons();
}
function clearList() {
	myPlaylist.remove();
	showRepeatShuffleButtons();
}
function closeJPlayerBox() {
	var id = document.getElementById("localDeviceBox");
	id.style.display = "none";
}

function closeLocalDeviceBox() {
	try {
		var id = document.getElementById("localDeviceBox");
		id.style.display = "none";
    } catch (e) {
    }	
	try {
		id = document.getElementById("photoBoxContainer");
		id.style.display = "none";
    } catch (e) {
    }	
}
function showLocalDeviceBox(showAlways, rendererSelected) {
	var video = false;
	var music = false;
	var photo = false;
	// show local device box if it was initialized
	if (foreignUnknownServer) {
		video = (foreignUnknownServerClass == persistentIDVideo);
		music = (foreignUnknownServerClass == persistentIDMusic);
		photo = (foreignUnknownServerClass == persistentIDPhoto);
	} else {
		video = (currentPersistentID == persistentIDVideo);
		music = (currentPersistentID == persistentIDMusic);
		photo = (currentPersistentID == persistentIDPhoto);
	}
	closeLocalDeviceBox();
	// video and/or Music
	if (music || video || (foreignUnknownServer && rendererSelected)) {	
		if (document.getElementById("jPlayerPlayList"))  {	// play list is loaded ?
			if (!showAlways) {
				if ($("li", ".jp-playlist").length == 0) return;	// are there items in the playlist ?
			}
			var id = document.getElementById("localDeviceBox");
			id.style.display = "block";
			addDragAndDropToWindow("localDeviceBox", "localDeviceBoxHeader", "rendererToolBox");
			addTouchEventToWindow("localDeviceBox", "localDeviceBoxHeader", "rendererToolBox");
		}
	}
	// photo
	if (photo || (foreignUnknownServer && rendererSelected)) {
		if (!showAlways) {
			if (currentPhotoIndex < 0) return;
		}
		if (document.getElementById("photoBox"))  {
			var id = document.getElementById("photoBoxContainer");
			id.style.display = "block";
			addDragAndDropToWindow("photoBoxContainer", "photoBoxHeader", "rendererToolBox");
			addTouchEventToWindow("photoBoxContainer", "photoBoxHeader", "rendererToolBox");
		}
	}
}



// init photo viewer
function initPhotoBox() {
    try {
		setResolutionIndex();
		if (document.getElementById("photoBox"))  {
			showLocalDeviceBox(true, false);
			return true;   // photo box is already loaded
		}
		var response = httpGet("/resources/webbrowse/photoBox.htm");
		if (!response) return false;
		var id = document.getElementById("photoBoxContainer");
		id.style.display = "block";
		var i = resolutionIndex;
		id.style.maxWidth = screenResolutionW[i]+"px";
		id.style.maxHeight = (screenResolutionH[i]+65)+"px";
		id.innerHTML = response;
		replaceStrings("photoBoxContainer");
		buildPhotoHeader();
		buildPhotoFooter();
		setSpeed(slideshowSpeed_startIndex);
	    return true;
    } catch (e) {
		return false;
    }	
}
function setResolutionIndex() {
    try {
		screenWidth = screen.width;
		screenHeight = screen.height;	
		if (screenWidth < screenHeight) {
			var s = screenWidth;
			screenWidth = screenHeight;
			screenHeight = s;
		}
		for (var i=3; i>=0; i--) {
			if ((screenResolutionW[i] < screenWidth) && (screenResolutionH[i] < (screenHeight-170))) {
				resolutionIndex = i;
				return;
			}
		}
		resolutionIndex = 0;		
    } catch (e) {
		resolutionIndex = 0;
    }	
}
function buildPhotoHeader() {
	var closeButton = '<a class="renderer-closebutton" title="' + getString("closelocaldevicebox") + '" onclick="closePhotoBox()"></a></div>';
	var html;
	html = '<table class="photoTabHeader" ><tr><td style="width:90%" class="titleInToolBox">';
	html += currentRendererTitle[currentPersistentID];
	html += '</td><td style="width:10%; text-align:right">'
	html += closeButton;
	html += '</td></tr><table>';
	var id = document.getElementById("photoBoxHeader");
	id.innerHTML = html;
	// add drag and drop to the toolbox window
	addDragAndDropToWindow("photoBoxContainer", "photoBoxHeader", "rendererToolBox");
	addTouchEventToWindow("photoBoxContainer", "photoBoxHeader", "rendererToolBox");
}
function buildPhotoFooter() {
	var html = "";
	var button = "";
	var title = "";
	html += '<table width=100%><col width=40%><col width=20%><col width=40%><tr><td style="vertical-align: middle">';
	// col 1 - left
	// 		clear queue
	html += '<div class="photoList">';
	button = '<a class="photo-clearlist" onclick="clearPhotoList()">' + getString("clearqueue") + '</a>';	
	html += button;
	// 		title and clear item button
	html += '<div class="currentPhotoContainer">';		// current photo item
	title = '<div class="currentPhotoTitle truncate"><p id="photoTitle"></p></div>';
	button = '<a class="photo-clearitem" onclick="deletePhotoButton()" title="' + getString("deletefromqueue") + '" >x</a>';
	html += title + button;
	html += '</div>';	
	html += '</div>';
	html += '<div class="clear"></div>';
	html += '</div>';
	html += '</td><td>';
	// col 2 - center
	//		prev button
	html += '<table class="photoTabFooterCenter"><col width=24><col width=34><col width=24><tr>';
	button = '<div id="PhotoButtonPrevious"><a class="renderer-previous" style="margin-bottom:5px" onclick="previousPhotoButton()" title="' + getString("btnPrevious") + '" ></a></div>';
	html += '<td align="center">' + button + '</td>';
	// 		show only one button play or pause
	button = '<div id="PhotoButtonPlay"><a class="renderer-play" onclick="playPhotoButton()"></a></div>';
	button += '<div id="PhotoButtonPause" class="controlHidden"><a class="renderer-pause" onclick="pausePhotoButton()"></a></div>';
	html += '<td>' + button + '</td>';
	//		next button
	button = '<div id="PhotoButtonNext"><a class="renderer-next" style="margin-bottom:5px" onclick="nextPhotoButton()" title="' + getString("btnNext") + '" ></a></div>';
	html += '<td>' + button + '</td>';
	html += '</tr>';
	html += '</table>';	
	html += '</td><td style="vertical-align: middle">';
	// col 3 - left 
	// 		photo queue: is not visible
	html += '<div class="photoControls">';
	var box = '<select id="photoList" name="photoList" style="display: none"></select>';
	html += '<div>' + box + '</div>';		// photo list
	// 		button repeat
	html += '<table class="photoTabFooterLeft"><col width=24><col width=24><tr>';
	button = '<div id="PhotoButtonRepeat" class="controlHidden"><a class="photo-repeat" onclick="playPhotoRepeat()"></a></div>';
	button += '<div id="PhotoButtonRepeatOff"><a class="photo-repeat-off"></a></div>';
	html += '<td style="vertical-align: middle">' + button + '</td>';
	// 		button shuffle
	button = '<div id="PhotoButtonShuffle"><a class="photo-shuffle" onclick="playPhotoShuffle()"></a></div>';
	button += '<div id="PhotoButtonShuffleOff" class="controlHidden"><a class="photo-shuffle-off"></a></div>';
	html += '<td style="vertical-align: middle">' + button + '</td>';
	html += '</tr>';
	html += '</table>';	
	// slideshow speeds
	html += '<div class="photoSpeed">';
	button = '<a id="PhotoSpeed1" class="photoPlayer-speed" onclick="setSpeedButton(1)">2s</a>';
	html += button;
	button = '<a id="PhotoSpeed2" class="photoPlayer-speed" onclick="setSpeedButton(2)">6s</a>';
	html += button;
	button = '<a id="PhotoSpeed3" class="photoPlayer-speed" onclick="setSpeedButton(3)">10s</a>';
	html += button;
	html += '</div>';
	html += '</td></tr></table>';
	
	var id = document.getElementById("photoBoxFooter");
	id.innerHTML = html;
}
function closePhotoBox() {
	stopSlideshow();
	var id = document.getElementById("photoBoxContainer");
	id.style.display = "none";
}
function addPhotoItem(url, title, showThisPhoto) {
	var newOption = new Option(title, url);
	var id1 = getPhotoListID();
	if (id1 == "") return;
	stopShuffle();
	id1.options[id1.options.length] = newOption;
	if (currentPhotoIndex < 0) {
		currentPhotoIndex = 0;
		playPhoto();
		return;
	}
	if (showThisPhoto) {
		currentPhotoIndex = id1.options.length-1;
		playPhoto();
	}
}
function setPhotoItem(url, title) {
	deletePhotoList();
	stopShuffle();
	var newOption = new Option(title, url);
	var id1 = getPhotoListID();
	if (id1 == "") return;
	id1.options[id1.options.length] = newOption;
	currentPhotoIndex = 0;
	playPhoto();
}

function deletePhotoList() {
	var id1 = getPhotoListID();
	if (id1 == "") return;
	while (id1.options.length > 0) {
		id1.options[0] = null;
	}
	currentPhotoIndex = -1;
	stopShuffle();
}
function previousPhotoButton() {
	var id1 = getPhotoListID();
	if (id1 == "") return;
	if ((currentPhotoIndex-1) < 0) currentPhotoIndex = id1.options.length;	  // show the last item in the queue
	currentPhotoIndex--;
	playPhoto();
}
function nextPhotoButton() {
	var id1 = getPhotoListID();
	if (id1 == "") return;
	if ((currentPhotoIndex+1) >= id1.options.length) currentPhotoIndex = -1;  // show the first item in the queue
	currentPhotoIndex++;
	playPhoto();
}
function deletePhotoButton() {
	var id1 = getPhotoListID();
	if (id1 == "") return;
	var photoIndex = getPhotoIndex();		// get the repeat or shuffle index
	deletePhotoInShuffleList(photoIndex);
	id1.options[photoIndex] = null;			// delete photo from list
	if (currentPhotoIndex >= id1.options.length) currentPhotoIndex=0;
	if (id1.options.length == 0) {
		currentPhotoIndex = -1;				// last item was deleted from the list
	}
	// show the new current photo
	playPhoto();
}
function clearPhotoList() {
	deletePhotoList();
	playPhoto();
}
function pausePhotoButton() {
	stopSlideshow();	
}
function playPhotoButton() {
	nextPhotoButton();
}
function playPhotoShuffle() {
	startShuffle();
	nextPhotoButton();	
}
function playPhotoRepeat() {
	stopShuffle();
	nextPhotoButton();	
}

function playPhoto() {
	stopSlideshow();
	showPhoto();
	startSlideshow();
}
function showPhoto() {
	var id1 = getPhotoListID();
	if (id1 == "") return;
	if (id1.options.length == 0) {
		var html = "";
	} else {
		var idBox = document.getElementById("photoTabImage");
		var photoIndex = getPhotoIndex();		// get the repeat or shuffle index
		var html = '<img style="max-height:'+idBox.clientHeight+'px;max-width:'+idBox.clientWidth+'px" src="' + id1.options[photoIndex].value + '" >';
	}
	var id = document.getElementById("photoTabTdImage");	// show the photo
	id.innerHTML = html;
	id = document.getElementById("photoTitle"); 			// show the photo title
	if (id1.options.length == 0) 
		id.innerHTML = "";
	else 
		id.innerHTML = id1.options[photoIndex].text;	
}
function getPhotoListID() {
	var id1 = document.getElementById("photoList");
	if (id1) return id1;
	return "";
}
function resizePhotoBox() {
	var id1 = document.getElementById("photoList");
	if (currentPhotoIndex < 0) return;
	playPhoto();	
}
function setSpeedButton(speed) {
	setSpeed(speed);
	nextPhotoInSlideshow();
}

// shuffle photos
var shuffleArray = new Array();
var shuffle = false;
function startShuffle() {
	addClass("PhotoButtonShuffle","controlHidden");
	removeClass("PhotoButtonShuffleOff","controlHidden");
	addClass("PhotoButtonRepeatOff","controlHidden");
	removeClass("PhotoButtonRepeat","controlHidden");	
	if (shuffleArray.length > 0) clearShuffle();
	var id1 = getPhotoListID();
	if (id1 == "") return;
	// create a new shuffle array
	for (var i=0;i<id1.options.length;i++) {
		shuffleArray.push(i);
	}
	var id1 = getPhotoListID();
	if (id1 == "") return;
	for (var i = id1.options.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var temp = shuffleArray[i];
        shuffleArray[i] = shuffleArray[j];
        shuffleArray[j] = temp;
    }
	shuffle = true;
}
function stopShuffle() {
	addClass("PhotoButtonShuffleOff","controlHidden");
	removeClass("PhotoButtonShuffle","controlHidden");
	addClass("PhotoButtonRepeat","controlHidden");
	removeClass("PhotoButtonRepeatOff","controlHidden");
	shuffle = false;
	clearShuffle();
}
function clearShuffle() {
	while (shuffleArray.length > 0) shuffleArray.pop();
}
function getPhotoIndex() {
	if (shuffle) {
		return shuffleArray[currentPhotoIndex];
	} else {
		return currentPhotoIndex;
	}
}
// delete the photo in the shuffle array
// photo list: 0 1 2 3
// shuffle array: [0]=3,[1]=1,[2]=0,[3]=2
// delete photoIndex = 1: 
// new photo list: 0 (delete 1) 2 3 -> 0 1 2 
// new shuffle array: [0]=3(-1),(delete [1]=1,)[2]=0,[3]=2(-1) -> [0]=2,[1]=0,[2]=1
function deletePhotoInShuffleList(photoIndex) {
	if (!shuffle) return;
	var shuffleIndex = -1;
	for (var i=0;i<shuffleArray.length;i++) {
		if (shuffleArray[i] == photoIndex) {
			shuffleIndex = i;
			continue;
		}
		// reduce the photoIndex in the shuffleArray if the index is greater than the deleted index
		if (shuffleArray[i] > photoIndex) {
			shuffleArray[i] = shuffleArray[i] - 1;
		}
	}	
	if (shuffleIndex >= 0) shuffleArray.splice(shuffleIndex,1);	// delete photo in shuffle array
}


function setSpeed(speed) {
	clearTimeout(slideshowTimer);
	slideshowTimer = "";
	slideshowSpeed = slideshowSpeeds[speed];
	for (var i = 1; i < slideshowSpeeds.length; i++) {
		var speedId = "PhotoSpeed"+i;
		var id = document.getElementById(speedId);
		addClass(speedId, "speedColor");
		removeClass(speedId, "speedColorSelected");
	}
	addClass("PhotoSpeed"+speed, "speedColorSelected");
	removeClass("PhotoSpeed"+speed, "speedColor");
}
function nextPhotoInSlideshow() {
	var id1 = getPhotoListID();
	if (id1 == "") return;
	if (id1.options.length == 0) return;		// no photos in queue
	if ((currentPhotoIndex+1) >= id1.options.length) currentPhotoIndex = -1;  // show the first item in the queue
	currentPhotoIndex++;
	showPhoto();
	slideshowTimer = setTimeout("nextPhotoInSlideshow()", slideshowSpeed);	
}
function stopSlideshow() {
	clearTimeout(slideshowTimer);
	slideshowTimer = "";
	// show play button
	removeClass("PhotoButtonPlay", "controlHidden");
	addClass("PhotoButtonPause", "controlHidden");
}
function startSlideshow() {
	slideshowTimer = setTimeout("nextPhotoInSlideshow()", slideshowSpeed);	
	// show pause button
	removeClass("PhotoButtonPause", "controlHidden");
	addClass("PhotoButtonPlay", "controlHidden");
}