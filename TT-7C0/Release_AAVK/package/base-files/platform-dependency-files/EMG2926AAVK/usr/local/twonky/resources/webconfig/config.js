// global vars

// server language file
var serverLanguageFile = new Array();
// convert-readme.txt file with license informations
var convertReadmeFile = "";
//The number of asynchronous calls that have returned from a given batch of calls.
var returnedCalls = 0;
//The number of asynchronous calls that are expected to be made for a given batch of calls.
var expectedCalls = 0;
// Reload side after overlay dialog has been closed
var setReloadSide = false;
// detect safari browser
var browser = "other";
// detect Mac OS
var os = "other";

//The currently selected left navigation item.
var activeNav;
//A boolean indicating whether or not the user has made any changes to a page of configuration settings.
var changesMade = false;
//A boolean indicating whether or not the user has clicked an input field
var inputFieldClicked = false;
//The handler to be called if the user elects to save the changes he made.
var saveHandler;

//An object containing all the data for the Status page.
var statusData = {};
var statusDataOrig = {};
//The timer that automatically updates a page at a regular increment.
var updateTimer;
//The interval at which to run the update timer, in milliseconds.
var updateTimerInterval = 30000;
//Second interval at which to run the update timer for <updateTimerInterval1Count> times.
var updateTimerInterval1 = 2000;
var updateTimerInterval1Count = 0;
// timer which clear the background spinner after 5 seconds
var loadingGraficActiv;

var multiUserSupportEnabled = false;

// 1: browse shared folder, 2: browse sync folder
var folderBrowseDialogMsg = 1;
// roleslist contains the default roles and the roles defined by the user. The index points to the first
// user defined role index
var firstUserDefinedRoleIndex = 0;
// user defined user index
var firstUserDefinedUserIndex = 0;

//An object containing all the data for the Setup page.
var setup = {};
var setupOrig = {};
//The user's currently selected navigation type for the defaultview property.
var selectedNavType;
//An object containing all the data for the Sharing page.
var sharing = {};
var sharingOrig = {};
//update receiver list
var sharingReceiverChanged = false;
//update aggregation server list
var sharingAggServerChanged = false;
//update receiver user list
var sharingReceiverUserChanged = false;
//An object containing all the data for the Aggregation page.
var aggregation = {};
var aggregationOrig = {};
//
var receiverShowMore = new Array();
//An object containing all the data for the Multi User Support page.
var multiUserSupport = {};
var multiUserSupportOrig = {};
//A list of aggregation servers the user has made modifications to. Tracked for optimization to avoid
//sending updates to TwonkyServer when data is saved except for servers the user has changed.
var changedServers = {};
//An object containing all the data for the Advanced page.
var advanced = {};
var advancedOrig = {};
// timer updating the advanced pages as long as there are not all genres populated by the server
var updateTimerIntervalAdvanced = 3000;
//An object containing all the data for the Online Services page.
var onlineservices = {};
var onlineservicesOrig = {};
//A list of media receivers the user has made modifications to. Tracked for optimization to avoid
//sending updates to TwonkyServer when data is saved except for receivers the user has changed.
var changedReceivers = {};
//A list of agg server the user has made modifications to. Tracked for optimization to avoid
//sending updates to TwonkyServer when data is saved except for agg servers the user has changed.
var changedAggServer = {};

// set the flag if an error occured
var saveViewsFailed = false;	// save the views
var saveViewsFailedString = "";	// view list, can not save the view
var saveFlag = false;			// save the disabled Multi User Support flag
var saveUserFailed = false;		// post request set_user_role_list failed
var saveUserFailedString = "";	// user list, can not add or remove the user
var saveLocationFailed = false;	// post request set_location_roles failed
var savePWDFailed = false;		// post request set_user_password failed
var savePWDFailedString = "";	// user list, can not change the user password
var setAdminPwd = "";			// is set while saving the multi user password of the admin
var saveDeviceUserFailed = false;	// request set_device_user_list failed
// current navigation
var currentHash = "status";


$(window).bind("hashchange", function(e){
    $("#leftNavContainer").show();
    $("#serverSettingsContentWrapper").show();
    $("#licenseInfoPage").hide();
	var navToHash = "navigateTo('" + currentHash + "');";
    switch (e.fragment) {
        case "":
        case "status":
            checkChanges("loadStatus();", "loadStatus();");
			currentHash = "status";
            populateSettingsNav();
            break;
        case "setup":
            checkChanges("loadSetup();", "loadSetup();");
			currentHash = "setup";
            populateSettingsNav();
            break;
        case "sharing":
            checkChanges("loadSharing();", "loadSharing();");
			currentHash = "sharing";
            populateSettingsNav();
            break;
        case "aggregation":
            checkChanges("loadAggregation();", "loadAggregation();");
			currentHash = "aggregation";
            populateSettingsNav();
            break;
        case "multiusersupport":
            checkChanges("loadMultiUserSupport();", "loadMultiUserSupport();");
			currentHash = "multiusersupport";
            populateSettingsNav();
            break;
        case "advanced":
            checkChanges("loadAdvanced();", "loadAdvanced();");
			currentHash = "advanced";
            populateSettingsNav();
            break;
        case "video":
            checkChanges("loadMediaBrowse('video');", navToHash);
            break;
        case "music":
            checkChanges("loadMediaBrowse('music');", navToHash);
            break;
        case "photo":
            checkChanges("loadMediaBrowse('photo');", navToHash);
            break;
        case "licenseinfo":
            checkChanges("showLicenseInfo();", "showLicenseInfo();");
            break;
        default:
            checkChanges("loadStatus();", "loadStatus();");
            populateSettingsNav();
            break;
    }
});

function loadMediaBrowse(hash) {
	if (multiUserSupportEnabled) document.execCommand('ClearAuthenticationCache', 'false');		// do it for IE
	navigateToUrl("/webbrowse#"+hash);
}
function navigateToUrl(param){
   window.location.href = param;
}
function navigateTo(params){
	// change hash
   window.location.href = $.param.fragment(window.location.href, params, 2);
}

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

// show the license information page
function showLicenseInfo() {
	$("#leftNavContainer").hide();
	$("#serverSettingsContentWrapper").hide();
	$("#licenseInfoPage").show();
	$("#licenseInfoPage").html(getString("mpeglicense") + "<br /><br />" + getString("copyright") + "<br /><br /><br /><br />" + 
		convertReadmeFile + "<br /><br />" + 
		"<BR><BR>License information is provided here: <br /><br /> " + 
		"<a class='inlineLink' href='http://jquery.org/license/' >http://jquery.org/license/</a> (click on 'MIT License' link)<br /><br />" +
		"<a class='inlineLink' href='http://benalman.com/about/license/' >http://benalman.com/about/license/</a> <br /><br />" + 
		"<a class='inlineLink' href='http://jplayer.org/' >http://jplayer.org/</a> (click on 'MIT License' link)<br /><br />" +
		"<a class='inlineLink' href='https://code.google.com/p/javascriptbase64/' >https://code.google.com/p/javascriptbase64/</a> (click on 'MIT License' link) <br />");
}

function getConvertReadmeFile(){
	makeGetRequest("/webconfig/convert-readme.txt", {}, function(data){
		convertReadmeFile = data;
		convertReadmeFile = convertReadmeFile.replace(/(\r\n)|(\r)|(\n)/g, "<BR>");
	});
}

//Get the value of a string given a key from the localized string translations.
//key: The key to retrieve a string for.
function getString(key){
    if (serverLanguageFile[key]) {
        return serverLanguageFile[key];
    } else {
		return key;
	}
}

//Replace the contents of all elements in html that have a "string" attribute with the matching value from the
//translation file.
//html: The HTML to perform the replacement on. 
function replaceStrings(html){
    var stringElements = $("[string]", html);
    for (var i=0;i<stringElements.length;i++) {
		var elem = stringElements[i];
		var j_elem = $(elem);	// convert to jQuery object
		j_elem.html(getString(j_elem.attr("string")));
	}

    // Update the text of "button"s.
    $.each($("input[type=button]"), function(i, element) {
    	element = $(element);
        element.attr("value", getString(element.attr("string")));
    });
}


// show or hide the content of subheaders. 
// The layout of each page will be saved. If the user comes back to a page the layout has not changed. 
function showToggleButtons(html){
	if (!(document.cookie)) return;
    var buttonElements = $(".toggleButton", html);
    for (var i=0;i<buttonElements.length;i++) {
		var elem = buttonElements[i];
		var j_elem = $(elem);	// convert to jQuery object
		var parent = j_elem.parents(".boxHeader");
		var nextHeader = $(parent).next();
		var id = j_elem.attr("id");
        var c = document.cookie;
		var a = c.split(";");
		for (var j=0;j<a.length;j++) {
			var cookieID = a[j].substring(0,a[j].indexOf("="));
			var cookieValue = a[j].substring(a[j].indexOf("=")+1, a[j].length);
			if (cookieID.indexOf(id) >= 0) {
				if (cookieValue.indexOf("show") >= 0) { 
					nextHeader.show();
					if (nextHeader.hasClass("hideSubheaderBody")) nextHeader.removeClass("hideSubheaderBody");	// for I.E.
					$(".toggleText", j_elem).text(getString("hide"));
					j_elem.removeClass("hidden");
					j_elem.addClass("showing");
				}
			}
		}
    }
}

//Call a handler function for each element in html that has a "key" attribute to display data.
//html: The HTML to perform the replacement on.
//responseData: The data object to retrieve the data from.
//handler: The handler that should be called when an element with a "key" attribute is discovered. Handlers should
//have the function signature (element, key, data) where element is the affected element, key is the data's key,
//and data is the data collection object.
function replaceData(html, responseData, handler){
    var dataElements = $("[key]", html);
	for (var i=0;i<dataElements.length;i++) {
		var dataElement = dataElements[i];
		var value = "";
		var key = "";
		for (var j=0; j<dataElement.attributes.length; j++) {
			if (dataElement.attributes[j].name == "key") {
				key = dataElement.attributes[j].value;
				value = responseData[key];
			}
		}
		var j_elem = $(dataElement);	// convert to jQuery object
        if (handler) {
            handler(j_elem, key, value);
        }
        else {
            j_elem.html(value);
        }
	}
}

//Split data using a separator character and store the resulting array.
//responseData: The data to split.
//dataCollection: The data object in which to store the data.
//dataKey: The key used to store the data.
//dataSeparator: The separator character.
function parseData(responseData, dataCollection, dataCollectionOrig, dataKey, dataSeparator){
    var responsePieces = responseData.split(dataSeparator);
    var responsePiecesOrig = responseData.split(dataSeparator);
    dataCollection[dataKey] = responsePieces;
    dataCollectionOrig[dataKey] = responsePiecesOrig;
}

//Split a collection of data that is in name/value pair form (e.g. /rpc/get_all) and store it in a data object.
//The key becomes the first part of the split, and the value becomes the second (v=0 would be stored as {"v": 0}).
//responseData: The data to split.
//dataCollection: The data object in which to store the data. The data can be changed by the user.
//dataCollectionOrig: The data object in which to store the data. These data are not changed by the user.
//separatorChar: The character that separates the name/value pairs.
function parseSeparatedData(responseData, dataCollection, dataCollectionOrig, separatorChar){
    var responsePieces = responseData.split("\n");
    for (var i=0;i<responsePieces.length;i++) {
		var elem = responsePieces[i];
		if (separatorChar == "=") {		// split always once
			var j = elem.indexOf(separatorChar);
			if (j >= 0) { 
				var name = elem.substring(0,j);
				var value = elem.substring(j+1);
				var cleanedData = value.replace(/\r/g, "");
				dataCollection[name] = cleanedData;
				dataCollectionOrig[name] = cleanedData;
			}
		} else {
			var pieceArray = elem.split(separatorChar);
			if (pieceArray.length == 2) {
				var cleanedData = pieceArray[1].replace(/\r/g, "");
				dataCollection[pieceArray[0]] = cleanedData;
				dataCollectionOrig[pieceArray[0]] = cleanedData;
			}
			else {
				var responseData = new Array(pieceArray.length - 1);
				$.each(pieceArray, function(i, value){
					if (pieceArray[i + 1]) {
						var cleanedData = pieceArray[i + 1].replace(/\r/g, "");
						responseData[i] = cleanedData;
					}
				});
				dataCollection[pieceArray[0]] = responseData;
				dataCollectionOrig[pieceArray[0]] = responseData;
			}
		}
	}
}

//A generic wrapper for making AJAX GET requests.
//url: The url to make the request to.
//params: A collection of objects to be passed as querystring arguments. Use the format {"key": value}. For example,
//[{"uuid": 1234}, {"example": true}] will be passed as ?uuid=1234&example=true in the querystring.
//callback: The callback to be called after the request finishes.
//failureCallback: The callback to be called if the request fails to finish.
function makeGetRequest2(url, params, callback, failureCallback){
    var urlParams = "";
    var separatorChar = "?";
	for (var key in params) {
		if (!params.hasOwnProperty(key)) {
			continue;
		}
		urlParams += separatorChar + key + "=" + params[key];
		separatorChar = "&";
	}
    $.get(url + urlParams, function(response){
        if (callback) {
            callback(response, url + urlParams);
        }
    }).error(function() {
        if (failureCallback) {
            failureCallback(url + urlParams);
        }
	});
}

function makeGetRequest(url, params, callback){
    makeGetRequest2(url, params, callback, null);
}

//A generic wrapper for making AJAX POST requests.
//url: The url to make the request to.
//params: A collection of objects to be passed as querystring arguments. Use the format {"key": value}. For example,
//[{"uuid": 1234}, {"example": true}] will be passed as ?uuid=1234&example=true in the querystring.
//data: The data to be passed during the POST request.
//callback: The callback to be called after the request finishes.
function makePostRequest2(url, params, data, callback, failureCallback){
    var urlParams = "";
    var separatorChar = "?";
	for (var key in params) {
		if (!params.hasOwnProperty(key)) {
			continue;
		}
		urlParams += separatorChar + key + "=" + params[key];
		separatorChar = "&";
	}
    $.post(url + urlParams, data, function(response){
        if (callback) {
            callback(response, url + urlParams);
        }
    }).error(function() {
        if (failureCallback) {
            failureCallback(url + urlParams);
        }
	});
}
function makePostRequest(url, params, data, callback){
    makePostRequest2(url, params, data, callback, null);
}

function showLoadingGraphic(){
    $(".serverSettingsContentWrapper").addClass("loading");
	if (loadingGraficActiv) window.clearInterval(loadingGraficActiv);
	loadingGraficActiv = window.setInterval("hideLoadingGraphic()", 8000);
}

function hideLoadingGraphic(){
	window.clearInterval(loadingGraficActiv);
	loadingGraficActiv = null;
	if ($(".serverSettingsContentWrapper").hasClass("loading"))
		$(".serverSettingsContentWrapper").removeClass("loading");
}

function onLanguageFetched(){
    replaceStrings($(document));
    $(window).trigger("hashchange");
}

function nameContainsSpecialCharacter(name) {
    var iChars = "~`!#$%^&*+=-[]\\\';,/{}|\":<>?";
	for (var i = 0; i < name.length; i++) {
		if (iChars.indexOf(name.charAt(i)) != -1) {
			return true;
		}
    }
	return false;
}

//Initialize the Settings application by first reading the user's language setting, then loading the language file
//and calling loadStatus.
function initPage() {
	var url = window.location.href;
	if (url.indexOf("webconfig") == -1) {
		loadMediaBrowse('video');	// initial call is the webbrowser page
		return;
	}
	// load the footer of the page
	loadFooterHtml();
	// is the page in an iframe?
	if (top != self) {
		// page is in an iFrame; show no header and footer
		$("#headWrapper").hide();
		$("#footer").hide();
	}
	// identify browser and OS
	browserIdentification();
	osIdentification();
	statusData["privacypolicy"] = "http://twonky.com/legal/dataCollection";
	$(".toggleButton").live("click", function(obj){
		toggleContainer($(obj.currentTarget));
	});
	getConvertReadmeFile();
    makeGetRequest("/rpc/get_language_file", {}, function(data, parameter){
		if (!(data == "")) {
			var s = data.split("|");
			for (var i=1;i+1<s.length;i=i+2) {
				if (serverLanguageFile[s[i]]) {
					continue;
				}
				var t = s[i+1];
				var t1 = t.replace(/\r\n/,"");
				serverLanguageFile[s[i]] = t1;
			}
			onLanguageFetched();
		}
    });
	
    // Use "makeGetRequest2" so that the failure callback is invoked.
    makeGetRequest2("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, statusData, statusDataOrig, "=");
        //Handle the version case separately. 
		//get_all, info_status and version return a "version" property. 
		//get_all.version is only set if the server comes with NMC
        statusData["fullversion"] = statusData.version;
		statusData["privacypolicy"] = "http://twonky.com/legal/dataCollection?lang="+statusData["language"];
		multiUserSupportEnabled = (statusData["multiusersupportenabled"] == 1);
		onLanguageFetched();
    },
    function(parameter) {
        // On failure ... invoke the onLanguageFetched() callback.
        onLanguageFetched();
    });
}

function loadFooterHtml(){
    makeGetRequest("/webconfig/indexFooter.htm", {}, function(response){
		var id = document.getElementById("twFooter");
		id.innerHTML = response;
	});
}

function loadScript(filename, filetype, defer){
	try {
		var fileref=document.createElement('script')
		fileref.setAttribute("type",filetype)
		fileref.setAttribute("src", filename)
		fileref.setAttribute("defer", defer)
		if (typeof fileref!="undefined")
			document.getElementsByTagName("body")[0].appendChild(fileref)
    } catch (e) {
    }
}

function onEventClick() {
	if (!(changesMade || inputFieldClicked)) {
		inputFieldClicked = true;
		// give "save"-button a new look
		$("#saveButton").addClass("confirm");
	}
}
function onEventChange(){
	if (!changesMade) {
		changesMade = true;
		// give "save"-button a new look
		if (!$("#saveButton").hasClass("confirm")) $("#saveButton").addClass("confirm");
	}
}
function resetChanged(){
	inputFieldClicked = false;
	changesMade = false;
	sharingReceiverChanged = false;
	sharingAggServerChanged = false;	
	sharingReceiverUserChanged = false;
	// reset the look of the "save"-button
	if ($("#saveButton").hasClass("confirm")) $("#saveButton").removeClass("confirm");
}

//If the user has changed any inputs on the page, display a dialog to warn them and prompt them to save changes and navigate to navFunctionStr2.
//Otherwise, navigate away to navFunctionStr.
//navFunctionStr: A string indicating the function that should be called if the changes should not be saved (cancel button)
//(e.g. "loadStatus()").
//navFunctionStr2: A string indicating the function that should be called if the changes should be saved (ok button)
//(e.g. "loadStatus()").
function checkChanges(navFunctionStr, navFunctionStr2){
    if (changesMade) {
        showDialogOverlay(function(){
            return getString("saveprompt");
        }, {}, {
            1: {
                text: getString("savechanges"),
                onclick: saveHandler + " hideDialogOverlay(); " + navFunctionStr2
            },
            2: {
                text: getString("discardchanges"),
                onclick: "changesMade = false; hideDialogOverlay(); " + navFunctionStr
            }
        });
    }
    else {
        eval(navFunctionStr);
    }
}

function populateSettingsNav(){
    if ($(".serverSettingsLeftNav").length == 0) {
        makeGetRequest("/webconfig/settings-nav.htm", {}, function(response, parameter){
            var responseHtml = $(response);
            replaceStrings(responseHtml);
            $(".serverSettingsContentWrapper").removeClass("contentDisplay");
            $("#leftNavContainer").html(responseHtml);
        });
    }
}

//Clear the selection on the currently selected left navigation item and highlight the new one. Cancel the
//udpate timer if it exists.
//currentNav: The newly clicked navigation item.
function highlightNav(currentNav){
    if (activeNav) {
        activeNav.removeClass("current");
        if (updateTimer) {
			clearInterval(updateTimer);
            //clearTimeout(updateTimer);
        }
    }
    currentNav.addClass("current");
    activeNav = currentNav;
}
// accountingstatus:
//#define ACCOUNTING_TRIAL_VERSION                            1 "TwonkyServer"
//#define ACCOUNTING_REGISTERED_VERSION_TS_ONLY               2
//#define ACCOUNTING_REGISTERED_VERSION_TSTML                 3
//#define ACCOUNTING_REGISTERED_VERSION_TSTMF                 4
//#define ACCOUNTING_PORTAL_VERSION                           5 "TwonkyServer Free"
//#define ACCOUNTING_PREMIUM_VERSION                          6 "TwonkyServer Premium"
//#define ACCOUNTING_OEM_VERSION                              7
function getServerType(accStatus) {
	var str = "TwonkyServer";
	switch (accStatus) {
        case "2": str = "TwonkyServer";
				break;
        case "5": str = "TwonkyServer free";
				break;
        case "6": str = "TwonkyServer Premium";
				break;
	}
	return str;
}

// ------------------------
// status page
// ------------------------
//Load data for the Status page.
//isInitial: Default false. /rpc/get_all is called on application load, so set isInitial to true to avoid a duplicate 
//call.
function loadStatus(isInitial){
    returnedCalls = 0;
    expectedCalls = (isInitial) ? 3 : 5;
    saveHandler = "function(){};"
	inputFieldClicked = false;
    changesMade = false;
	
	showLoadingGraphic();
    if (!isInitial) {
        makeGetRequest("/rpc/get_all", {}, function(response, parameter){
            parseSeparatedData(response, statusData, statusDataOrig, "=");
			statusData["fullversion"] = statusData.version;		// info_status returns the property "version" too
            returnedCalls++;
            if (expectedCalls == returnedCalls) {
                loadStatusHtml();
				hideLoadingGraphic();
            }
        });
    }
    
    makeGetRequest("/rpc/info_status", {}, function(response, parameter){
        parseSeparatedData(response, statusData, statusDataOrig, "|");
		statusData["serverversion"] = statusData.version;		// get_all returns the property "version" too
		// statusData["servertype"] = getServerType(statusData["licensestatus"]);
		// statusData["servertypepart2"] = statusData["servertype"];
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadStatusHtml();
			hideLoadingGraphic();
        }
    });
	// function get_server_type restored - should be retired again. See also chapter advanced!
	makeGetRequest("/rpc/get_server_type", {}, function(response, parameter){
		statusData["servertype"] = response;
		statusData["servertypepart2"] = response;
		advanced["servertype"] = response;
		returnedCalls++;
		if (expectedCalls == returnedCalls) {
			loadStatusHtml();
			hideLoadingGraphic();
		}
	});

	makeGetRequest("/rpc/get_friendlyname?fmt=xml", {}, function(response, parameter){
		statusData["friendlynamestring"] = response;
		returnedCalls++;
		if (expectedCalls == returnedCalls) {
			loadStatusHtml();
			hideLoadingGraphic();
		}
	});
    
	makeGetRequest("/rpc/info_nics", {}, function(response, parameter){
        parseData(response, statusData, statusDataOrig, "nics", "\n");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadStatusHtml();
			hideLoadingGraphic();
        }
    });
}

function handleStatusData(element, key, data){
    var returnValue = "";
    switch (key) {
        case "restartpending":
            returnValue = (data == 0) ? (getString("no")) : (getString("yes"));
            break;
        case "wmdrmstatus":
            returnValue = (data) ? (data.toUpperCase()) : ("");
            break;
        case "uptime":
            var days = data[0];
            var timePieces = data[1].split(":");
            returnValue = days + " " + getString("days") + ", " + timePieces[0] + " " + getString("hours") + ", " + timePieces[1] + " " + getString("minutes") + ", " + timePieces[2] + " " + getString("seconds");
            break;
		case "nics":
            if (data) {
				returnValue = "<table class='nicIp'>";
				for (var i=0;i<data.length;i++) {
                    if (data[i].length > 0 && data[i].lastIndexOf("127.0.0.1") == -1) {
                        var nicPieces = data[i].split(",");
                        var mac = (nicPieces[1]) ? (nicPieces[1]) : ("")
                        //returnValue += "<span class='nicIp'>" + nicPieces[0] + "</span>" + " " + mac + "<br />";
						returnValue += "<tr><td>" + nicPieces[0] + "</td><td>" + mac + "</td></tr>";
                    }
                }
				returnValue += "</table>";
            }
            break;
        case "cdkey":
			// show the license key
			// licensestatus 0=Trial, 2=OEM, -201..-207=error
			// licenseregistered 0=not registered, 1=registered
			if (statusData["licensestatus"] == "2") break;		// OEM-version: do not show the key
			// licenseregistered 0=server is not registered, 1=server is registered
			if (statusData["licenseregistered"] == "0") break;	// license is not registered
            if (data) {
				// show the license key under the header details
                returnValue = '<div class="serverStatusLabel floatL">' + getString("cdkey") + '</div><div class="floatL">' + data + '</div><div class="clear"></div>';
            }
            break;
        case "licensestatus":
			// enter the license key
			// licensestatus 0=Trial, 2=OEM, -201..-207=error
			// licenseregistered 0=not registered, 1=registered
			if (statusData["licenseregistered"] == "1") break;	// license is registered
            if (data >= 2) break;	// OEM
			//Remove the element's key to prevent it from being overwritten during the automatic update timer.
			element.attr("key", "nothing");
			returnValue += '<div class="boxHeader">\
			<span class="titleWrapper">\
				<span class="title">' + getString("licensekey") + '</span>\
			</span>\
			<div class="clear" />\
			</div>\
			<div><div>' +
			getString("licensekeycaption") +
			'</div><br />';
			if (os != "Mac") {
				// Windows, Linux: show 8 fields for license key
				for (var i = 0; i < 8; i++) {
					returnValue += '<input type="text" class="licenseKeyInput floatL" maxchars="4" onkeyup="onLicenseInputKeyUp(event, $(this))"></input>'
				}
			} else {
				// Mac: show one field for license key
				returnValue += '<input type="text" class="licenseKeyInputMac floatL" maxchars="39" onkeyup="onLicenseInputKeyUpMac(event)"></input>'
			}
			
			returnValue += '<a class="actionbtn floatL" onclick="saveLicenseKey()" onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)">\
					<span class="actionbtn_l"></span>\
					<span class="actionbtn_c">' + getString("enter") + '</span>\
					<span class="actionbtn_r"></span>\
				</a>\
				<div class="clear"></div>'
			
			// licensestatus 0=Trial OR -201..-207=error
			if (data >= 0) {
				returnValue += "<div class='error'>" + statusData["licensedays"] + " " + getString("daysremaining") + "</div>";
			} else {
				// show the text of the errorcode (license-201, license-203, ...)
				returnValue += "<div class='error'>" + getString("license" + data) + "</div>";
			}
			returnValue += '</div><div class="serverContentSpacer"></div>';
            break;
        case "streams":
			var indexdb = statusData["dbupdate"].indexOf("[");
			if (indexdb > 1) {
				// database update in progress
				returnValue = getString("rescancontent") + " - " + statusData["dbupdate"].substring(0,indexdb-1);
			}
            break;
        case "servertype":
			// show the server type and version
			// free: Twonky 7.1 (servertype, fullversion)
			// premium: TwonkyServer Premium 7.1  (servertype, fullversion)
			// standard: Twonky Server 7.2 (servertype, fullversion)
            var serverType = data.toLowerCase();
            if (serverType.lastIndexOf("premium") > -1) {
				returnValue = getString("twonkyserver");		// only temporarily, 2013-01-16
                //returnValue = getString("premiumserver");
            }
            else 
                if (serverType.lastIndexOf("free") > -1) {
                    returnValue = getString("freeserver");
                }
                else {
                    returnValue = getString("twonkyserver");
                }
            break;
        case "servertypepart2":
			// currently not used
			return "";
            break;
        default:
            returnValue = data;
            break;
    }
    element.html(returnValue);
}

function onLicenseInput(input){
	inputFieldClicked = true;
    if (input.val().match(/^[A-Z0-9]{4}(-[A-Z0-9]{4}){7}$/)) {
        var keyPieces = input.val().split("-");
        var inputs = $(".licenseKeyInput");
        $.each(inputs, function(i, element){
            $(element).val(keyPieces[i]);
        });
    }
    else {
        if (input.val().length > input.attr("maxchars")) {
            input.val(input.val().substring(0, input.attr("maxchars")));
        }
        if (input.val().length == input.attr("maxchars")) {
            input.next().focus();
        }
    }
}

function onLicenseInputKeyUp(event, input){
    if (event.which == 13) {
        saveLicenseKey();
		return;
    }
    if ((event.which < 48) || (event.which > 122)) return;
	onLicenseInput(input);
}
function onLicenseInputKeyUpMac(event){
    if (event.which == 13) {
        saveLicenseKey();
    }
}

function saveLicenseKey(){
    var key = "";
    resetChanged();
	if (os != "Mac") {
		var inputs = $(".licenseKeyInput");
		$.each(inputs, function(i, element){
			key += $(element).val();
			if (i != inputs.length - 1) {
				key += "-";
			}
		});
	} else key = $(".licenseKeyInputMac")[0].value;
    var data = "cdkey=" + key + "\n";
    makeGetRequest("/rpc/set_option?"+data, {}, function(response, parameter) {});
    //location.reload();
	var timerKey = setTimeout("reloadSide()",30);
}
function reloadSide() {
    location.reload();
}

function loadStatusHtml(){
    makeGetRequest("/webconfig/status.htm", {}, function(response, parameter){
        var responseHtml = $(response);
        replaceStrings(responseHtml);
        replaceData(responseHtml, statusData, handleStatusData);       
  		showToggleButtons(responseHtml);
        $(".serverSettingsContentWrapper").html(responseHtml);
  	    $("#statusSyncUrl").hide();
        highlightNav($("#nav_status"));
  		hideLoadingGraphic();
  		updateTimer = setInterval(updateStatus, updateTimerInterval);
	});
}

function updateStatus(){
	if (inputFieldClicked) return;	// don't update page if changes are made (during enter the license key)
    returnedCalls = 0;
    expectedCalls = 2;
	showLoadingGraphic();
	
    makeGetRequest("/rpc/info_status", {}, function(response, parameter){
        parseSeparatedData(response, statusData, statusDataOrig, "|");
		statusData["serverversion"] = statusData.version;		// get_all returns the property "version" too
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            replaceData($(".serverSettingsContentWrapper"), statusData, handleStatusData);
			hideLoadingGraphic();
        }
    });
    
    makeGetRequest("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, statusData, statusDataOrig, "=");
		statusData["fullversion"] = statusData.version;		// info_status returns the property "version" too
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            replaceData($(".serverSettingsContentWrapper"), statusData, handleStatusData);
			hideLoadingGraphic();
        }
    });
}


// ------------------------
// setup page
// ------------------------
// variables:
// setup["defaultview"] - default navigation tree
// setup["viewnames"] - default view names ["mobile", "simpledefault", "ipodlike", ...]
// setup["myviewnames"] - user-defined views ["My View", "My simple view", ..]
// setup["myviewnamessave"] - default=0, 1 if the view has changed, 2 if it is a new view, 8 if the view was removed, 9 if a new view was removed
// setup["viewnodes"] - all view nodes 	["music/all", "music/playlists", "music/genre", ...]
// for every default and user-defined view:
// setup["view_mobile"] - nodes of the view mobile ["music/all", "music/playlists", "music/genre", ...]
// setup["view_simpledefault"] ...
function loadSetup(){
    returnedCalls = 0;
    expectedCalls = 4;
    saveHandler = "submitSetupData();"
	inputFieldClicked = false;
    changesMade = false;

	showLoadingGraphic();
    
    makeGetRequest("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, setup, setupOrig, "=");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadSetup2();
			hideLoadingGraphic();
        }
    });
    
    makeGetRequest("/rpc/view_names", {}, function(response, parameter){
        parseData(response, setup, setupOrig, "viewnames", ",");
		var names = new Array();
		for (var i=0;i<setup["viewnames"].length;i++) {
			names[i] = getString(setup["viewnames"][i]);
		}
		setup["viewlongnames"] = names; 
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadSetup2();
			hideLoadingGraphic();
        }
    });

    makeGetRequest("/rpc/my_view_names", {}, function(response, parameter){
        parseData(response, setup, setupOrig, "myviewnames", ",");
		var saveflag = new Array();
		for (var i=0;i<setup["myviewnames"].length;i++) {
			saveflag[i] = 0;
		}
		setup["myviewnamessave"] = saveflag; 
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadSetup2();
			hideLoadingGraphic();
        }
    });

    makeGetRequest("/rpc/get_views_nodes", {}, function(response, parameter){
        parseData(response, setup, setupOrig, "viewnodes", "\n");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadSetup2();
			hideLoadingGraphic();
        }
    });
}
// read the nodes of the pre-defined and created views
function loadSetup2() {
	var names = setup["viewnames"];
	var mynames = setup["myviewnames"];
    returnedCalls = 0;
    expectedCalls = names.length + mynames.length;
	for (var i=0;i<names.length;i++) {
		if (names[i] == "") {
			returnedCalls++;
			continue;
		}
		callSetupRpc(names[i]);		// get the nodes of a view and save them in setup["view_<viewname>"]
	}
	for (i=0;i<mynames.length;i++) {
		if (mynames[i] == "") {
			returnedCalls++;
			continue;
		}
		callSetupRpc(mynames[i]);	// get the nodes of a view and save them in setup["view_<viewname>"]
	}
}
// read the nodes of a view and save them in setup["view_<viewname>"]
function callSetupRpc(viewname) {
	makeGetRequest2("/rpc/get_view_config?view="+viewname, {}, function(response, parameter){
		parseData(response, setup, setupOrig, "view_"+viewname, ",");
		returnedCalls++;
		if (expectedCalls == returnedCalls) {
			loadSetupHtml();
			hideLoadingGraphic();
		}
	}, function(parameter) {
		parseData("", setup, setupOrig, "view_"+viewname, ",");
		returnedCalls++;
		if (expectedCalls == returnedCalls) {
			loadSetupHtml();
			hideLoadingGraphic();
		}
	});
}

function loadSetupHtml(){
    makeGetRequest("/webconfig/setup.htm", {}, function(response, parameter){
        var responseHtml = $(response);
        replaceStrings(responseHtml);
		showToggleButtons(responseHtml);        
        $(".serverSettingsContentWrapper").html(responseHtml);
        highlightNav($("#nav_setup"));
		makeGetRequest("/webconfig/setupLanguage.htm", {}, function(response){
			var responseHtml = $(response);
			replaceStrings(responseHtml);
			$("#languageSelectBox").html(responseHtml);
            replaceData($(".serverSettingsContentWrapper"), setup, handleSetupData);
			$("input", "#setupContainer1").live("click", onEventClick);
			$("input,select", "#setupContainer1").live("change", onEventChange);
		});
    });
}

function handleSetupData(element, key, data){
	var html = "";
    switch (key) {
        case "friendlyname":
            element.val(data);
            break;
        case "language":
            var matchingLanguage = $("[value=" + data + "]", element);
            matchingLanguage.attr("selected", "yes");
            break;
        case "viewnames":
            html = "";
			// pre-defined views
			for (var i=0;i<data.length;i++) {
                var selected = "";
				if (data[i] == "") continue;
                if (setup["defaultview"] == data[i]) {
                    selected = "checked";
                    setNavType(data[i]);
                }
                html += '<div class="radioControlWrapper" name="div_viewname" id="div_' + data[i] + '">\
        		<input style="float: left" name="viewname" id="' + data[i] + '" ' + selected + ' type="radio" onclick="setNavType(\'' + data[i] + '\')" />\
        		<div class="radioControlTextWrapper">\
				<div class="radioHeader">' + getString(data[i]) + '</div><div class="smallFont">' + getString(data[i] + "caption") + '</div>\
        		</div>\
        		<div class="clear"></div>\
    			</div>';
            }
			// user-defined views
			var views = setup["myviewnames"];
			for (var i=0;i<views.length;i++) {
                var selected = "";
				if (views[i] == "") continue;
				if (setup["myviewnamessave"][i] > 2) continue;	// 0 default, 1 changed, 2 new
                if (setup["defaultview"] == views[i]) {
                    selected = "checked";
                    setNavType(views[i]);
                }
                html += '<div class="radioControlWrapper" name="div_viewname" id="div_' + views[i] + '">\
        		<input style="float: left" name="viewname" id="' + views[i] + '" ' + selected + ' type="radio" onclick="setNavType(\'' + views[i] + '\')" />\
        		<div class="radioControlTextWrapper">\
				<div class="radioHeader">' + views[i] + '</div><div class="smallFont">&nbsp;</div>\
        		</div>\
        		<div class="clear"></div>\
    			</div>';
            }			
            element.html(html);
            break;
        case "viewnodes":
			html = '<table class="viewBuilderTable">';
			html += '<tr>';
			html += buildViewNodes();
			html += buildViewNodesTemplates();
			html += '</tr>';
			html += buildViewNodesClearAll();
			html += '</table>';
			element.html(html);
			break;
    }
}

// remove a user defined tree from the menu Navigation Trees
function removeViewFromNavigationTree(view) {
	var viewnames = "div_viewname";
	var navtreeContainer = "div_" + view;
	var prevIndex = -1;
	if (selectedNavType == view) {		// this tree is selected
		// select the previous element in the list
		var elems = document.getElementsByName(viewnames);
		for (var i=0;i<elems.length;i++) {
			if (elemHasClass(elems[i].id, "hide")) continue;
			if (elems[i].id.substring(4) == view) {		// found tree
				if (prevIndex == -1) {		// no prev element
					if (i+1 < elems.length)
						prevIndex = i+1;
				}
				if (prevIndex >= 0) {
					var id = document.getElementById(elems[prevIndex].id.substring(4));
					id.checked = true;								// select the navigation tree
					setNavType(elems[prevIndex].id.substring(4));	// set the current selected navigation tree
				}
			}
			prevIndex = i;
		}
	}
	// hide the element
	hideHtmlElement(navtreeContainer);
	return;
}
// add a user defined view to the menu Navigation Trees
function addViewToNavigationTree(view) {
	var navtreeViewnames = "navtreeviewnames";
	var html = '<div class="radioControlWrapper" name="div_viewname" id="div_' + view + '">\
	<input style="float: left" name="viewname" id="' + view + '" type="radio" onclick="setNavType(\'' + view + '\')" />\
	<div class="radioControlTextWrapper">\
	<div class="radioHeader">' + view + '</div><div class="smallFont">&nbsp;</div>\
	</div>\
	<div class="clear"></div>\
	</div>';
	var id = document.getElementById(navtreeViewnames);
	id.innerHTML += html;
}
// set the selected navigation tree as new default view
function setNavType(navType){
    selectedNavType = navType;
}

function buildViewNodes() {
	var html = "";
	var namenodes = "viewNodeName";
	html += '<td style="width:23%">';
	html += '<span class="viewBuilderTableBold">' + getString("music") + '</span><br>';
	html += buildViewNodesFor("music");
	html += '</td><td style="width:23%">';
	html += '<span class="viewBuilderTableBold">' + getString("photo") + '</span><br>';
	html += buildViewNodesFor("picture");
	html += '</td><td style="width:23%">';
	html += '<span class="viewBuilderTableBold">' + getString("video") + '</span><br>';
	html += buildViewNodesFor("video");
	html += '</td>';
	return html;
}
function buildViewNodesTemplates() {
	var html = "";
	var viewtemplates = "viewTemplates";
	html += '<td id="' + viewtemplates + '" class="viewBuilderTableTemplate" >';
	html += '<span class="viewBuilderTableBold">' + getString("navtreetemplatedefault") + '</span><br>';
	html += buildDefaultViewNames();
	var htmlMyViews = buildUserDefinedViewNames();
	if (htmlMyViews) {
		// show the header and the user defined views
		html += '<span class="viewBuilderTableBold">' + getString("navtreetemplateuser") + '</span><br>';
		html += htmlMyViews;
	}
	html += buildSaveView();
	html += '</td>';
	return html;
}
function buildViewNodesClearAll() {
	var html = "";
	html += '<tr>';
	html += '<td class="viewBuilderTableTemplate"></td>';
	html += '<td class="viewBuilderTableTemplate viewBuilderTableCenter">';
	html += '<a class="actionbtn" onclick="clearNavTreeBuilder()" ' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("navtreeclearall") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '</td>';
	html += '<td class="viewBuilderTableTemplate"></td>';
	html += '<td class="viewBuilderTableTemplate"></td>';
	html += '</tr>';
	return html;
}
// nodetype is music, picture or video
// return the html-code (checkboxes) with all nodes of one type
function buildViewNodesFor(nodetype) {
	var html = "";
	var namenodes = "viewNodeName";
	var nodesUnsorted = getViewNodes(nodetype);
	var nodes = sortViewNodes(nodesUnsorted);
	for (var i=0;i<nodes.length;i++) {
		var n = nodes[i].split(",");		// n[0]=node ID, n[1]=node name (e.g. n[0]=all, n[1]=alltracks)
		html += '<input type="checkbox" name="' + namenodes + '" value="' + nodetype + '/' + n[0] + '" ' +
				' >' + getString(n[1]);
		html += '<br>';
	}
	return html;
}
function sortViewNodes (nodes) {
	var snodes = new Array;
	var newSNodes = new Array();
	for (var i=0;i<nodes.length;i++) {
		var n = nodes[i].split(",");		// n[0]=node ID, n[1]=node name (e.g. n[0]=all, n[1]=alltracks)
		var newNode = getString(n[1]) + "|" + nodes[i];		// the translated node name and the node with the key and the translation key name (e.g. By Folder|folder,byfolder)
		snodes.push(newNode);
	}
	snodes.sort();			// sort the view nodes
	for (var i=0;i<snodes.length;i++) {
		var n = snodes[i].split("|");		// n[0]=translated node name, n[1]=node (e.g. n[0]=By Folder, n[1]=folder,byfolder)
		newSNodes.push(n[1]);
	}
	return newSNodes;
}
// returns the nodes of one media type (music, video, photo)
// setup["viewnodes"]: ["music/all,alltracks","music/artists,artist","music/artistindex,artistindex",...]
// nodes: ["all,alltracks","artists,artist","artistindex,artistindex",...]
function getViewNodes(nodetype) {
	var allnodes = setup["viewnodes"];
	var nodes = new Array;
	for (var i=0;i<allnodes.length;i++) {
		if (allnodes[i] == "") continue;
		var allnodespart = allnodes[i].split("/");	// e.g. music/all,alltracks
		if (allnodespart[0] == nodetype) 
			nodes.push(allnodespart[1]);
	}
	return nodes;
}
function buildDefaultViewNames() {
	var html = "";
	var nameviews = "viewNameBuilder";
	var names = setup["viewnames"];
	for (var i=0;i<names.length;i++) {
		if (names[i] == "") continue;
		html += '<input type="radio" name="' + nameviews + '" value="' + names[i] + '" ' +
				' onclick="useViewAsTemplate(\'' + names[i] + '\',' + i + ',\'defaultView\')" >' + getString(names[i]);
		html += '<br>';
	}
	return html;
}
function buildUserDefinedViewNames() {
	var html = "";
	var nameviews = "viewNameBuilder";
	var names = setup["myviewnames"];
	for (var i=0;i<names.length;i++) {
		if (names[i] == "") continue;
		if (setup["myviewnamessave"][i] > 2) continue;	// 0 default, 1 changed, 2 new, 8 and 9 removed
		html += '<input type="radio" name="' + nameviews + '" value="' + names[i] + '" ' +
				' onclick="useViewAsTemplate(\'' + names[i] + '\',' + i + ',\'myView\')" >' + names[i];
		html += '<br>';
	}
	return html;
}
// add the input field to show or enter the my tree name
// add the "save my tree"-button
// add the "delete tree"-button (initial the button is hidden)
function buildSaveView() {
	var html = "";
	html += '<br><span>' + getString("navtreesaveas") + '</span><br>';
	html += '<input type="text" id="myViewNewName" value="" style="margin-bottom:3px" onkeydown="treeNameChanged()">';
	html += '<br>';
	html += '<a class="actionbtn floatL" onclick="saveView()" ' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("navtreeaddview") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '<div id="navTreeDeleteButton" class="hide"><a class="actionbtn floatL" onclick="deleteView()" ' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("navtreedeleteview") +
			'</span><span class="actionbtn_r"></span></a></div>';
	return html;
}
// a navigation tree template was selected
// set the tree name if it is a user-defined tree
// check the media nodes
// show the delete tree button if it is a user-defined tree
function useViewAsTemplate(viewname, myviewindex, viewtype) {
	// viewtypes: defaultView or myView
	var namenodes = "viewNodeName";
	var viewKeyName = "view_"+viewname;
	try {
		// set the tree name
		var id = document.getElementById("myViewNewName");
		if (viewtype == "defaultView") id.value = "";
		else id.value = viewname;
		// get the nodes as list separated by ,
		var nodes = "";
		for (var j=0;j<setup[viewKeyName].length;j++) {
			nodes += setup[viewKeyName][j] + ",";
		}
		// check the nodes
		var id = document.getElementsByName(namenodes);
		for (var i=0;i<id.length;i++) {
			if (nodes.indexOf(id[i].value) >= 0) 
				id[i].checked = true;
			else id[i].checked = false;
		}
		// show the delete tree button if it is a user-defined navigation tree
		if (viewtype == "myView") showButtonDeleteMyView();
		else hideHtmlElement("navTreeDeleteButton");
	} catch(e) {
	}
}
// show and hide the button "delete my view"
function showButtonDeleteMyView() {
	var btn = document.getElementById("navTreeDeleteButton");
	var j_btn = $(btn);
	if ($(j_btn).hasClass("hide")) {
		$(j_btn).removeClass("hide");
		$(j_btn).addClass("show");
	}
}
function hideHtmlElement(elemName) {
	var btn = document.getElementById(elemName);
	var j_btn = $(btn);
	if ($(j_btn).hasClass("show")) {
		$(j_btn).removeClass("show");
	}
	$(j_btn).addClass("hide");
}
function elemHasClass(elemName, className) {
	var btn = document.getElementById(elemName);
	var j_btn = $(btn);
	if ($(j_btn).hasClass(className)) return true;
	return false;
}
// name of the tree changed
function treeNameChanged() {
	hideHtmlElement("navTreeDeleteButton");	// hide the button "delete my view"
}
function deleteView() {
	var myviewname = "myViewNewName";
	var viewtemplates = "viewTemplates";
	var id = document.getElementById(myviewname);
	var name = id.value;
	onEventChange();		// give the save-button on the bottom of the setup page a new look
	// remove the view
	var myViewIndex = getMyViewIndex(name);
	if (myViewIndex >= 0) {
		// set the flag myviewnamessave to 8 or 9 (new tree)
		if (setup["myviewnamessave"][myViewIndex] == 2) // new tree
			setup["myviewnamessave"][myViewIndex] = 9;	// remove new tree
		else
			setup["myviewnamessave"][myViewIndex] = 8;	// remove existing tree
		// remove the view from the navigation tree
		removeViewFromNavigationTree(setup["myviewnames"][myViewIndex]);
	}
	// refresh screen
	var html = buildViewNodesTemplates();
	id = document.getElementById(viewtemplates);
	id.innerHTML = html;
	clearNavTreeBuilder();		// disable checkboxes
	clearNavTreeFileName();		// clear the filename
	hideHtmlElement("navTreeDeleteButton");	// hide the button "delete my view"
}
// "save my view" button was pressed
// check the name of the view
// add the view or save to an existing view
function saveView() {
	var namenodes = "viewNodeName";
	var myviewname = "myViewNewName";
	var viewtemplates = "viewTemplates";
	var id = document.getElementById(myviewname);
	var name = id.value;
	// check the name (name of a default view is not allowed)
	if (!checkName(name)) return;
	if (!areNodesChecked()) return;
	onEventChange();		// give the save-button on the bottom of the setup page a new look
	// get the nodes of the view and save them in setup["view_"+name]
	var viewKeyName = "view_"+name;
	var newView = new Array();
	id = document.getElementsByName(namenodes);
	var nodes = "";
	for (var i=0;i<id.length;i++) {
		if (id[i].checked) {
			newView.push(id[i].value);
		}
	}
	if (newView.length == 0) return;	// no nodes selected
	setup[viewKeyName] = newView;
	// add view: add the view name to the viewlist, 
	//			 set the flag in myviewnamessave to 2 
	//			 add the view to the menu Navigation Tree
	// change view: set the flag in myviewnamessave to 1
	var myViewIndex = getMyViewIndex(name);
	if (myViewIndex >= 0) {
		setup["myviewnamessave"][myViewIndex] = 1;
	} else {
		setup["myviewnames"].push(name);
		setup["myviewnamessave"].push(2);
		var l = setup["myviewnames"].length-1;
		addViewToNavigationTree(setup["myviewnames"][l]);
	}
	// refresh screen
	var html = buildViewNodesTemplates();
	id = document.getElementById(viewtemplates);
	id.innerHTML = html;
	clearNavTreeBuilder();		// disable checkboxes
	clearNavTreeFileName();		// clear the filename
	hideHtmlElement("navTreeDeleteButton");	// hide the button "delete my view"
}
// is the navigation tree name valid?
function checkName(name) {
	var error = false;
	if (name == "") error = true;
	if (!error) if (getViewIndex(name) >= 0) error = true;
	if (!error) if (getViewNameIndex(name) >= 0) error = true;
	if (error) {
		showDialogOverlay(function(){
			return getString("navtreenameerror");
		}, {}, [{
			text: getString("ok"),
			onclick: "hideDialogOverlay();"
		}]);	
		return false;
	}
	if (nameContainsSpecialCharacter(name)) {
		showDialogOverlay(function(){
			return getString("specialcharacterinname");
		}, {}, [{
			text: getString("ok"),
			onclick: "hideDialogOverlay();"
		}]);	
		return false;
	}
	return true;
}
// are tree nodes checked (at least one node) ?
function areNodesChecked() {
	var namenodes = "viewNodeName";	
	var id = document.getElementsByName(namenodes);
	for (var i=0;i<id.length;i++) {
		if (id[i].checked) return true;
	}
	// show error message
	showDialogOverlay(function(){
		return getString("navtreenonodeserror");
	}, {}, [{
		text: getString("ok"),
		onclick: "hideDialogOverlay();"
	}]);	
	return false;
}
function getMyViewIndex(name) {
	for (var i=0;i<setup["myviewnames"].length;i++) {
		if (setup["myviewnames"][i] == name) return i;
	}
	return -1;
}
function getViewIndex(name) {
	for (var i=0;i<setup["viewnames"].length;i++) {
		if (setup["viewnames"][i] == name) return i;
	}
	return -1;
}
function getViewNameIndex(name) {
	for (var i=0;i<setup["viewlongnames"].length;i++) {
		if (setup["viewlongnames"][i] == name) return i;
	}
	return -1;
}
// deselect the checkboxes and clear the filename
function clearNavTreeBuilder() {
	var nameviews = "viewNameBuilder";
	var namenodes = "viewNodeName";
	
	var id = document.getElementsByName(namenodes);
	// unmark nodes
	for (var i=0;i<id.length;i++) {
		id[i].checked = false;
	}
	id = document.getElementsByName(nameviews);
	// unmark templates
	for (var i=0;i<id.length;i++) {
		id[i].checked = false;
	}
}
// clear the filename
function clearNavTreeFileName() {
	var myviewname = "myViewNewName";
	// clear the view name
	id = document.getElementById(myviewname);
	id.value = "";
}

function submitSetupData(){
	if (!changesMade) return;
    returnedCalls = 0;
    expectedCalls = 1;
    hideActionButtons();
    resetChanged();
	
	// count the new and changed user-defined views (my views)
	// default = 0, view changed = 1, new view = 2, remove view = 8, remove new view = 9
	for (var i=0;i<setup["myviewnamessave"].length;i++) {
		if (setup["myviewnamessave"][i] == 1) expectedCalls++;	// update the view
		if (setup["myviewnamessave"][i] == 2) expectedCalls++;	// save the new view
		if (setup["myviewnamessave"][i] == 8) expectedCalls++;	// remove the view
	}
	// save my views
	if (expectedCalls > 1) {
		for (var i=0;i<setup["myviewnamessave"].length;i++) {
			// save views
			if ((setup["myviewnamessave"][i] == 1) || (setup["myviewnamessave"][i] == 2)) {
				var viewname = "view_" + setup["myviewnames"][i];
				var viewnodes = "";
				for (var j=0;j<setup[viewname].length;j++) {
					if (viewnodes == "") viewnodes += setup[viewname][j];
					else viewnodes += "," + setup[viewname][j];
				}
				makeGetRequest2("/rpc/set_view_config", {
						"view": setup["myviewnames"][i],
						"config": viewnodes
					}, function(response, parameter){
					if (response != "ok") {
						setSaveViewsFailed(parameter);
					}
					returnedCalls++;
					if (returnedCalls == expectedCalls) {
						finishSavingSetup();
					}
				}, function(parameter) {
					returnedCalls++;
					setSaveViewsFailed(parameter);
					if (returnedCalls == expectedCalls) {
						finishSavingSetup();
					}			
				});
			}
			// remove views
			if (setup["myviewnamessave"][i] == 8) {		
				var viewname = "view_" + setup["myviewnames"][i];
				makeGetRequest2("/rpc/delete_view_config", {
						"view": setup["myviewnames"][i]
					}, function(response, parameter){
					if (response != "ok") setSaveViewsFailed(parameter);
					returnedCalls++;
					if (returnedCalls == expectedCalls) {
						finishSavingSetup(saveViewsFailed);
					}
				}, function(parameter) {
					returnedCalls++;
					setSaveViewsFailed(parameter);
					if (returnedCalls == expectedCalls) {
						finishSavingSetup(saveViewsFailed);
					}			
				});
			}
		}
		// reset the flag myviewnamessave to 0
		for (var i=0;i<setup["myviewnamessave"].length;i++) {
			setup["myviewnamessave"][i] = 0;
		}
	}

	// save friendlyname, language and defaultview
	var data = "";
	if (setupOrig["friendlyname"] != $("#servername").val()) {
		data += "friendlyname=" + $("#servername").val() + "\n";
		setup["friendlyname"] = $("#servername").val();
	}
	var newLanguage = $("#language").val();
	if (newLanguage != null && setupOrig["language"] != newLanguage) 
	{
		data += "language=" + newLanguage + "\n";
	}	
	if (setupOrig["defaultview"] != selectedNavType) {
		data += "defaultview=" + selectedNavType + "\n";
		setup["defaultview"] = selectedNavType;
	}
	setupOrig["friendlyname"] = setup["friendlyname"];
	setupOrig["defaultview"] = setup["defaultview"];
	if (data == "") {
		returnedCalls++;
	} else {
		makePostRequest("/rpc/set_all", {}, data, function(){
			returnedCalls++;
			if (newLanguage != null && setupOrig["language"] != newLanguage) {
				setReloadSide = true;
			}
			if (returnedCalls == expectedCalls) {
				finishSavingSetup();
			}			
		});
	}
}
// add the view name to the error list
// parameter: ?view=<name>&config=<node list>
function setSaveViewsFailed(parameter) {
	saveViewsFailed = true;
	var p = "";
	try {
		var i1 = parameter.indexOf("?");
		if (i1 > 0) p = parameter.substring(i1+1, parameter.length);
		var onep = p.split("&");
		if (onep.length < 1) return;
		for (var i=0;i<onep.length;i++) {
			var pair = onep[i].split("=");
			if (pair.length == 2) {
				if (pair[0] == "view") 
					if (saveViewsFailedString == "") saveViewsFailedString = pair[1];
					else saveViewsFailedString += ", " + pair[1];
			}
		}
    } catch (e) {
    }
}
function finishSavingSetup(){
	requestFailed(); 
	finishSaving();
	hideLoadingGraphic();
}


// ------------------------
// sharing page
// ------------------------
function loadSharing(){
    returnedCalls = 0;
    expectedCalls = 2;
    saveHandler = "submitSharingData();"
	inputFieldClicked = false;
    changesMade = false;

	showLoadingGraphic();
    
	// first get the keys and values from the ini file
    makeGetRequest("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, sharing, sharingOrig, "=");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			loadSharing_more();	// get the other data
		}
    });
	// get the tls port for https
    makeGetRequest("/rpc/get_tls_port", {}, function(response, parameter){
        parseData(response, multiUserSupport, multiUserSupportOrig, "tlsport", "--");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			loadSharing_more();	// get the other data
		}
    });
}
// get all the other data
function loadSharing_more() {
    returnedCalls = 0;
    expectedCalls = 4;
	
    makeGetRequest("/rpc/info_clients", {}, function(response, parameter){
        parseData(response, sharing, sharingOrig, "clients", "\n");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			// get the multi user support data and call the function loadSharingHtml
 			getMultiUserSupport_Data(sharing["multiusersupportenabled"], loadSharingHtml);
        }
    });
    
    makeGetRequest("/rpc/info_connected_clients", {}, function(response, parameter){
        parseData(response, sharing, sharingOrig, "mediareceivers", "##########\n");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			// get the multi user support data and call the function loadSharingHtml
 			getMultiUserSupport_Data(sharing["multiusersupportenabled"], loadSharingHtml);
        }
    });

    makeGetRequest("/rpc/view_names", {}, function(response, parameter){
        parseData(response, sharing, sharingOrig, "viewnames", ",");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			// get the multi user support data and call the function loadSharingHtml
 			getMultiUserSupport_Data(sharing["multiusersupportenabled"], loadSharingHtml);
        }
    });

    makeGetRequest("/rpc/my_view_names", {}, function(response, parameter){
        parseData(response, sharing, sharingOrig, "myviewnames", ",");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			// get the multi user support data and call the function loadSharingHtml
 			getMultiUserSupport_Data(sharing["multiusersupportenabled"], loadSharingHtml);
        }
    });
}

function loadSharingHtml(){
    makeGetRequest("/webconfig/sharing.htm", {}, function(response, parameter){
        var responseHtml = $(response);
        replaceStrings(responseHtml);
        replaceData(responseHtml, sharing, handleSharingData);
		showToggleButtons(responseHtml);
        
        $(".serverSettingsContentWrapper").html(responseHtml);
		if (sharing["multiusersupportenabled"] == "1") 
			$("#clientautoenable").hide();		// remove the checkbox - devices are controlled by roles
        $("input", "#sharingContainer").live("click", onEventClick);
        $("input,select", "#sharingContainer").live("change", onEventChange);
        highlightNav($("#nav_sharing"));
		clearReceiverShowMore();
		updateSharing();
        updateTimer = setInterval(updateSharing, updateTimerInterval);
    });
}

function updateSharing(){
    makeGetRequest("/rpc/info_connected_clients", {}, function(response, parameter){
        parseData(response, sharing, sharingOrig, "mediareceivers", "##########\n");
        updateMediaReceivers($("[key=mediareceivers]"), sharing.mediareceivers)
    });
}
function updateSharingFolder(){
    makeGetRequest("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, sharing, sharingOrig, "=");
        updateSharedFolderList($("[key=contentdir]"), sharing.contentdir)
    });
}

function splitContentDirs(data){
    var delimiter = ",[-\\+\\*][AMVPDamvpd]\\|";
    var contentDirs = new Array();
    var index;
    while ((index = data.search(delimiter)) != -1) {
        contentDirs.push(data.substring(0, index));
        data = data.substring(index + 1);
    }
    contentDirs.push(data);
    return contentDirs;
}

function handleSharingData(element, key, data){
    switch (key) {
        case "rmautoshare":
            if (sharing["platform"] == "WIN32") {
                element.show();
                if (data > 0) {
                    $("input[type=checkbox]", element).attr("checked", "true");
                }
            }
            break;
        case "contentdir":
			folderBrowseDialogMsg = 1;
			updateSharedFolderList(element, data);
            break;
		case "v":
        case "clientautoenable":
            element.attr("checked", data > 0)
            break;
        case "mediareceivers":
            updateMediaReceivers(element, data);
            break;
    }
}

//A utility function used during dynamic HTML generation to determine whether a dropdown option should be selected.
//mediaKey: The value of the input in question.
//compareKey: The string to compare to.
function checkSelectedMediaOption(mediaKey, compareKey){
    return (mediaKey == compareKey) ? ("selected") : ("");
}
//mediaKey: The value of the input in question.
//compareKey: The string to compare to.
// path: sharing directory
// mediaKey for music and audiobooks is "M". 
// The audiobook paths are stored in sharing["audiobooklocations"].
function checkSelectedMediaOptionAudiobook(path, mediaKey, compareKey){
	// check for audiobook
	if (compareKey == "B") {						
		var data = sharing["audiobooklocations"].split(",");
		for (var i=0;i<data.length;i++) {
			if (data[i] == path) return "selected";	// it is an audiobook
		}
		return "";									// it is not an audiobook 
	}
	// check for music
	if ((compareKey == "M") && (mediaKey == compareKey)) {		
		var data = sharing["audiobooklocations"].split(",");
		for (var i=0;i<data.length;i++) {
			if (data[i] == path) return "";		// it is not music, it is an audiobook
		}
		return "selected";						// it is music
	}
	return "";
}
function checkSelectedUser(user, deviceUser) {
    return (user == deviceUser) ? ("selected") : ("");
}

function checkShareBox(checkbox){
    if (checkbox.is(":checked")) {
        var shareBox = $(".sharedCheckbox", checkbox.parent());
        shareBox.attr("checked", true);
    }
}

function uncheckAggregationBox(checkbox){
    if (!checkbox.is(":checked")) {
        var aggregationBox = $(".aggregationCheckbox", checkbox.parent());
        aggregationBox.attr("checked", false);
    }
}

//Display a dialog that allows the user to browse folders on his local machine. This can't be a browser control
//because browsers only allow file selection, not folder browsing.
//rowNumber: The number of the selected folder browse row. Used to track which input the user is working with.
function showFolderBrowse(rowNumber){
    showDialogOverlay(createFolderBrowseDialog, {
        onstart: makeGetRequest("/rpc/dir", {
            "path": ""
        }, function(response, parameter){
            populateDirs(response, "", "");
        })
    }, {
        1: {
            text: getString("select"),
            onclick: "selectDir('" + rowNumber + "')"
        },
        2: {
            text: getString("cancel"),
            onclick: "hideDialogOverlay()"
        }
    }, "folderBrowse");
}

//Hide the folder selection dialog and populate an input with the user's selected directory.
//rowNumber: The number of the selected folder browse row. Used to track which input the user is working with. 
function selectDir(rowNumber){
    if ($("#dirPathDisplay").html()) {
		var div = document.getElementById('divSelectDir');
		div.innerHTML = $("#dirPathDisplay").html();
        $("#pathInput" + rowNumber).val(div.firstChild.nodeValue);
		onEventChange();
        hideDialogOverlay();
    }
}

function createFolderBrowseDialog(){
	if (folderBrowseDialogMsg == 1) 
		return '<div>\
				<div class="boxHeader">\
					<span class="titleWrapper">\
						<span class="title">' + getString("selectfolder") + '</span>\
					</span>\
					<div class="clear" />\
				</div>\
				<div id="dirPathDisplay" class="dirPathDisplay"></div>\
				<div id="dirDisplayContainer"></div>\
			</div>';
	else 
		return '<div>\
				<div class="boxHeader">\
					<span class="titleWrapper">\
						<span class="title">' + getString("selectsyncfolder") + '</span>\
					</span>\
					<div class="clear" />\
				</div>\
				<div id="dirPathDisplay" class="dirPathDisplay"></div>\
				<div id="dirDisplayContainer"></div>\
			</div>';
}

//The maximum height of the directory display area before it begins scrolling, in pixels.
function getWindowHeight() {
	var windowHeight = 50;
	 if (typeof( window.innerWidth ) == 'number' ) {
		//Non-IE
		windowHeight = window.innerHeight;
	  } else if (document.documentElement && document.documentElement.clientHeight) {
		//IE 6+ in 'standards compliant mode'
		windowHeight = document.documentElement.clientHeight;
	  } else if (document.body && document.body.clientHeight) {
		//IE 4 compatible
		windowHeight = document.body.clientHeight;
	  }		
	  return windowHeight;
}

function replaceSpecialChars(stringIn) {
    var str1 = stringIn.replace(/&amp;/g, "&");
	str1 = str1.replace(/&/g, "&amp;");
	return str1;
}

//Generate HTML to display the list of directories, along with a breadcrumb and a link for the parent directory.
//response: The data containing the directory list.
//rootPath: The path of the previous directory.
//rootId: The id of the previous directory.
function populateDirs(responseIn, rootPathIn, rootId){
    ($("#dirDisplayContainer")).removeClass("scroll");
	$("#dirDisplayContainer").css("height", "auto"); 
    var html = "";
    var response = replaceSpecialChars(responseIn);
    var rootPath = replaceSpecialChars(rootPathIn);
    var responsePieces = response.split("\n");
    var platformSpecificSeparator = responsePieces[0];
    var dirDisplay = $("#dirPathDisplay");
    dirDisplay.attr("dirid", rootId);
    dirDisplay.html(rootPath);
    if (dirDisplay.attr("dirid") && rootPath && rootId) {
		var lastSlash = rootPath.lastIndexOf(platformSpecificSeparator);
        var lastPipe = rootId.lastIndexOf("|");
        //If rootPath matches the format of a file path (e.g. C:\), parentPath is everything from the start of the string
        //to the last \, beyond which is the id of the current directory.
        var parentPath = (rootPath.match(/^[A-Z]:\\$/)) ? ("") : (rootPath.substring(0, lastSlash));
        //If parentPath is now only a drive designation (e.g. C:), add the \ back on.
        if (parentPath.match(/^[A-Z]:$/)) {
            parentPath += "\\";
        }
        var parentId = rootId.substring(0, lastPipe);
        html += '<div class="parentDirRow" onclick="getDirs(\'' + escape(parentPath) + '\', \'' + parentId + '\', \'' + platformSpecificSeparator.replace(/\\/g, "\\\\") + '\')"><span class="parentDirIcon"></span><span>' + getString("parentdir") + '</span></div>';
    }
    else {
        html += '<div class="parentDirRow"></div>';
    }
    $.each(responsePieces, function(i, value){
        if (value.length > 1) {

	    // directory/file id is 3+ digits long
	    var ii = 3;
	    while ((value.charAt(ii) != "D" && value.charAt(ii) != "F") && ii < value.length) {
		ii = ii + 1;
	    }
			
	    var dirId = value.substring(0, ii);
            var fullId = dirId;
            if (rootId) {
                fullId = rootId + "|" + dirId;
            }

            var dirKey = value.charAt(ii);
            var dirPath = value.substring(ii + 1);
            var fullPath = dirPath;

            if (rootPath) {
                var separatorChar = (rootPath.lastIndexOf(platformSpecificSeparator) != rootPath.length - 1) ? (platformSpecificSeparator) : ("");
                fullPath = rootPath + separatorChar + dirPath;
            }
            if (dirKey == "D") {
                html += '<div class="dirRow" onclick="getDirs(\'' + escape(fullPath) + '\', \'' + fullId + '\', \'' + platformSpecificSeparator.replace(/\\/g, "\\\\") + '\')"><span class="dirIcon"></span><span>' + dirPath + '</span></div>';
	    }
        }
    });
    $("#dirDisplayContainer").html(html);
    //If the container is too tall, add the scroll class to it to prevent it from taking up too much real estate.
	var wHeight = getWindowHeight();
	var dirDisplayMaxHeight = wHeight - Math.round(wHeight/2) - $("#dirPathDisplay").outerHeight() - $("#dialogButtonContainer").outerHeight();
    if (parseInt($("#dirDisplayContainer").css("height")) > dirDisplayMaxHeight) {
        ($("#dirDisplayContainer")).addClass("scroll");
		if (dirDisplayMaxHeight < 150) dirDisplayMaxHeight = 150;
		$(".scroll").css("height", dirDisplayMaxHeight); 
    }
    else {
        ($("#dirDisplayContainer")).removeClass("scroll");
    }
}

//Get the directories under a given directory id.
//dirPath: The path of the previous directory to be used for breadcrumb navigation.
//dirId: The id to use for the new dirs call.
function getDirs(dirPathIn, dirId, platformSpecificSeparator){
	var dirPath = unescape(dirPathIn);
    var passId = dirId.replace(/\|/g, platformSpecificSeparator)
    makeGetRequest("/rpc/dir", {
        "path": passId
    }, function(response, parameter){
        populateDirs(response, dirPath, dirId);
    });
}
//Create a new shared folder row for directory browsing. Do this only if the user hasn't chosen a directory for the last
//existing row to avoid duplicate blank rows getting stacked up.
function createNewSharedFolderRow(){
    if ($(".pathInput:last", "#share_folders_container").val()) {
        var sharingRows = $(".sharingRowWrapper", "#share_folders_container");
        //Unbind the change listener, since only the last row should be listening to add a fresh row when a value is set.
        sharingRows.unbind("change");
        var i = sharingRows.length;
        var html = getNewSharedFolderRowHtml(i);
        $("#share_folders_container").append(html);
    }
}

//Get the HTML for a new shared folder row.
//i: The row number. Use this to uniquely identify the row.
function getNewSharedFolderRowHtml(i){
	folderBrowseDialogMsg = 1;
	var html = "";
    html += '<div class="sharingRowWrapper">';
	// add the checkbox to enable/disable share
	html += '<input class="sharedCheckbox floatL" onclick="uncheckAggregationBox($(this))" type="checkbox" checked="true" title="' + 
			getString("enabledisableshare") + '"/>';
	// an entry field for the path
	html += '<input id="pathInput' + i + '" class="longInput pathInput floatL" type="text" value=""/>';
	// add the browse button
	html += '<a class="actionbtn floatL" onclick="showFolderBrowse(' +
			i +
			')" onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("browse") +
			'</span><span class="actionbtn_r"></span></a>';
	// add the media type combobox
	html += '<select class="contentTypeDropdown floatL">\
				<option value="A">'+getString("allcontenttypes")+'</option>\
				<option value="M">'+getString("music")+'</option>\
				<option value="P">'+getString("photos")+'</option>\
				<option value="V">'+getString("videos")+'</option>\
				<option value="m">'+getString("photos")+' & '+getString("videos")+'</option>\
				<option value="p">'+getString("music")+' & '+getString("videos")+'</option>\
				<option value="v">'+getString("music")+' & '+getString("photos")+'</option>\
				<option disabled value="-">&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;</option>\
				<option value="B">'+getString("audiobooks")+'</option>\
			</select>';
	// add aggregation checkbox
	html += '<div class="floatL">';		
	// add the checkbox "available for aggregation" 
	html += '<input id="aggCheckbox' + i + '" name="aggCheckbox" ' + 
			'class="floatL" onclick="checkShareBox($(this))" type="checkbox" checked="true"/>' +
			'<label for="aggCheckbox' + i + '">' + getString("shareforagg") + '</label>' +
			'</div>';
	html += '<div class="clear"></div></div>';
	return html;
}
// build the HTML for the shared folders
function updateSharedFolderList(element, data){
	// shared folder list
	element.html("");
	var html = "";
	var dirPairs = splitContentDirs(data);
	var html = "";
	// no shared folders defined
	if ((dirPairs.length == 1) && (dirPairs[0] == "")) {
		element.append(getNewSharedFolderRowHtml(0));
		return;
	}
	// list the content dirs
	$.each(dirPairs, function(i, value){
		var dirPieces = value.split("|");
		var dirPath = dirPieces[1];
		var dirKeys = dirPieces[0];
		var enabledKey = dirKeys.substring(0, 1);
		var mediaKey = dirKeys.substring(1, 2);
		var shared = (enabledKey == "+" || enabledKey == "*") ? ("checked") : ("");
		var enabledForAgg = (enabledKey == "*") ? ("checked") : ("");
		// add the checkbox to enable/disable share
		html += '<div class="sharingRowWrapper">\
				<input class="sharedCheckbox floatL" onclick="uncheckAggregationBox($(this))" type="checkbox" ' + shared + ' title="' +
				getString("enabledisableshare") + '"/>';
		// add the contentdir (path)
		html += '<input id="pathInput' + i + '" class="longInput pathInput floatL" type="text" value="' + dirPath + '"/>';
		// add the browse folder button
		html += '<a class="actionbtn floatL" onclick="showFolderBrowse(' +
				i +
				')" onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
				getString("browse") +
				'</span><span class="actionbtn_r"></span></a>';
		// add the media type combobox
		html += '<select class="contentTypeDropdown floatL">\
				<option value="A" ' +
				checkSelectedMediaOption(mediaKey, "A") +
				'>'+getString("allcontenttypes")+'</option>\
						<option value="M" ' +
				checkSelectedMediaOptionAudiobook(dirPath, mediaKey, "M") +
				'>'+getString("music")+'</option>\
						<option value="P" ' +
				checkSelectedMediaOption(mediaKey, "P") +
				'>'+getString("photos")+'</option>\
						<option value="V" ' +
				checkSelectedMediaOption(mediaKey, "V") +
				'>'+getString("videos")+'</option>\
						<option value="m" ' +
				checkSelectedMediaOption(mediaKey, "m") +
				'>'+getString("photos")+' & '+getString("videos")+'</option>\
						<option value="p" ' +
				checkSelectedMediaOption(mediaKey, "p") +
				'>'+getString("music")+' & '+getString("videos")+'</option>\
						<option value="v" ' +
				checkSelectedMediaOption(mediaKey, "v") +
				'>'+getString("music")+' & '+getString("photos")+'</option>\
						<option disabled value="-" ' +
				'>&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;</option>\
						<option value="B" ' +
				checkSelectedMediaOptionAudiobook(dirPath, mediaKey, "B") +
				'>'+getString("audiobooks")+'</option>\
			</select>';
		// add the checkbox "available for aggregation" 
		html += '<div class="floatL">';
		html += '<div><input id="aggCheckbox' + i + '" name="aggCheckbox" ' +
			'class="floatL" onclick="checkShareBox($(this))" type="checkbox" ' +
			enabledForAgg +	'/>' +
			'<label for="aggCheckbox' + i +	'">' + getString("shareforagg") + '</label>' + 
			'</div>';
		html += '</div>';
		// close the div container with the shared folders (sharingRowWrapper)
		html += '<div class="clear"></div></div>';
	});
	element.html(html);
}
// index: index of the receiver list
// receiver: the current receiver
// if multi user support is enabled -> show the user which is the default user to access this device. 
// The default user can be changed.
function buildMUSdeviceCell(index, receiver) {
	if (sharing["multiusersupportenabled"] == "0") return "";
	//var html = '<tr id="userRow' + index + '" class="deviceUserTab" ><td padding-bottom="5px">&nbsp;</td>';
	var html = '<td class="deviceDefaultUser">';
	// show the available users and check the user which is the default user for this device
	var assignedUser = getDeviceUser(receiver);
	var alluser = get_user_array(sharing["multiusersupportdefaults"], multiUserSupport["userlist"]);	// all users
	// add a combobox with all users
	html += '<select id="deviceDefaultUser' + index + '" class="deviceDefaultUser" onchange="deviceDefaultUserChanged(' + index + ')" >';
	for (var i = 0; i < alluser.length; i++) {
		html += '<option value="' + alluser[i] + '" ' + checkSelectedUser(alluser[i],assignedUser) + '>' + alluser[i] + '</option>';
	}
	html += '</select>';
	html += '</td>';
	return html;
}
// index: index of the receiver list
// receiver: the current receiver
// show more technical information of the current receiver
function buildDeviceRow(index, receiver) {
	var html = "";
	var checked = (receiver.enabled == 1) ? ("checked") : ("");
	var trClass = "deviceUserTabRow2 hide";
	if (isReceiverInfoOpen(receiver.receiverKey)) trClass = "deviceUserTabRow2";
	html += '<tr id="receiverRow' + index + '" class="' + trClass + '">';
	html += '<td><input id="checkDeviceHidden' + index + '" type="checkbox" ' + checked + ' style="display:none"/></td>';
	html += '<td colspan="5" >';
	html += '<table class="mediaReceiversTable2"><tr>';
	html += '<th><span>' + getString("mac") + '</span></th>';
	html += '<th><span>' + getString("ip") + '</span></th>';
	html += '<th><span>' + getString("receivertype") + '</span></th>';
	html += '<th><span>' + getReceiverViewHeader("navtype", receiver.hasDefaultView == 1) + '</span></th>';
	html += '</tr>';
	html += '<tr>';
	// add the mac address
	html += '<td><input class="macInput" type="text" value="' + receiver.mac + '" disabled="true" style="cursor:default" /></td>';
	// add the receiver ip
	html += '<td><input class="ipInput" type="text" value="' + receiver.ip +'" disabled="true" style="cursor:default" /></td>';
	// add the client name (media receiver type)
	html += '<td>' + getReceiverClientDropdown(receiver.clientName, index, true) + '</td>';
	// add the default navigation tree
	html += '<td>' + getReceiverViewDropdown(receiver.viewName, receiver.hasDefaultView == 1, index) + '</td>';
	// add the receiver key as hidden field
	html += '<td><input class="receiverKey" name="receiverKeyHidden" type="hidden" value="' + receiver.receiverKey +	'" /></td>';
	html += '</tr></table>';
	html += '</td></tr>';
	return html;
}
// return the default user assigned to the device
function getDeviceUser(receiver) {
	// deviceuserlist: device1=user1\ndevice2=user1\n ...
	var lines = multiUserSupport["deviceuserlist"][0].split("\n");
	for (var i=0;i<lines.length;i++) {
		var value = lines[i];
		if (value == "") continue;
		var devUser = value.split("=");
		var device = devUser[0];	// device
		var user = devUser[1];		// user assigned to the device
		if (receiver == device) return user;
	};
	return sharing["multiusersupportdefaultuser"];
}
function showMoreTechnicalDeviceInformation(index) {
	var idbutton = "receiverRowButton" + index;
	var idname = "receiverRow" + index;
	var btn = document.getElementById(idbutton);
	var j_btn = $(btn);
	var elem = document.getElementById(idname);
	var j_idname = $(elem);
	if ($(j_idname).hasClass("hide")) {
		$(j_idname).removeClass("hide");
		$(j_btn).removeClass("hidden");
		receiverInfoOpens(index);
	} else {
		$(j_idname).addClass("hide");	
		$(j_btn).addClass("hidden");	
		receiverInfoWasClosed(index);
	}
}
function receiverInfoOpens(index) {
	try {
		var idReceiverKeys = document.getElementsByName("receiverKey");
		if (!isReceiverInfoOpen(idReceiverKeys[index].value)) 
			receiverShowMore.push(idReceiverKeys[index].value);
	} catch(e) {}
}
function receiverInfoWasClosed(index) {
	try {
		var idReceiverKeys = document.getElementsByName("receiverKey");
		if (isReceiverInfoOpen(idReceiverKeys[index].value)) 
			receiverShowMore.pop(idReceiverKeys[index].value);
	} catch(e) {}
}
function isReceiverInfoOpen(receiverkey) {
	for (var i=0;i<receiverShowMore.length;i++) {
		if (receiverShowMore[i] == receiverkey) return true;
	}
	return false;
}
function clearReceiverShowMore() {
	var l = receiverShowMore.length;
	for (var i=0;i<l;i++) {
		receiverShowMore.pop();
	}
}

// update the receiver list and the aggregation server list
function updateMediaReceivers(element, data){
	// if user has made changes, do not update the receiver and aggregation server list 
	if (sharingReceiverChanged || sharingAggServerChanged || sharingReceiverUserChanged) return;
	var elementa = $("[key=aggservers]");
    if (!data) {
        element.hide();
        elementa.hide();
		return;
    }
	if (data[data.length-1].length == 0) data.pop();	//delete last element if emty
	// count the number of receivers and aggregation server
	var mrec = 0; 
	var aggs = 0;
	for (var key in data) {
		var p = data[key].split("\n");
		if (p[4] == 0) mrec ++;				// p[4] = 0 -> receiver; p[4] = 1 -> aggregation server
		else aggs ++;
	}
	// media receivers list
	var html = "";
	// set header if there are receivers
	if (mrec > 0) {
		html = '<tr><th></th>';	// enable/disable device
		html += '<th><span>' + getString("devicename") + '</span></th>';
		if (sharing["multiusersupportenabled"] == "1") 
			html += '<th><span>' + getString("defaultuser") + '</span></th>';
		html += '<th><span>' + getString("more") + '</span></th>';	// show/hide technical information
		html += '<th></th>';	// empty column
		html += '</tr>';
	}
	// aggregation server list
	var htmla = "";
	// set header if there are aggregation server
	if (aggs > 0) {
		htmla = '<tr><th></th>';
		htmla += '<th><span>' + getString("servername") + '</span></th>';
		htmla += '<th><span>' + getString("mac") + '</span></th>';
		htmla += '<th><span>' + getString("ip") + '</span></th>';
		htmla += '</tr>';
	}
	$.each(data, function(i, value){
		var receiverPieces = value.split("\n");
		var receiver = {};
		receiver["receiverKey"] = receiverPieces[0];
		receiver["id"] = receiverPieces[1];
		receiver["mac"] = receiverPieces[2];
		receiver["ip"] = receiverPieces[3];
		receiver["isAggregation"] = receiverPieces[4];
		receiver["enabled"] = receiverPieces[5];
		receiver["clientName"] = receiverPieces[6];
		receiver["icon"] = receiverPieces[7];
		receiver["iconMimeType"] = receiverPieces[8];
		receiver["viewName"] = receiverPieces[9];
		receiver["hasDefaultView"] = receiverPieces[10];
		receiver["friendlyname"] = receiverPieces[11];
		var checked = (receiver.enabled == 1) ? ("checked") : ("");
		var deviceName = (receiver["friendlyname"]) ? receiver["friendlyname"] : receiver["clientName"];
		if (receiver.isAggregation == 0) {			// media receiver
			html += '<tr id="receiverRowHeader' + i + '" class="deviceUserTabRow1">';
			// add the checkbox to enable/disable device
			html += '<td><input id="checkDevice' + i + '" onchange="receiverChanged(' + i + ')" type="checkbox" ' + checked +
					' title="' + getString("enabledisabledevice") + '" alt="' + getString("enabledisabledevice") + '" /></td>';
			// add the device name (friendly name or client name)
			html += '<td class="deviceName"><input class="deviceName" type="text" value="' + deviceName + 
					'" disabled="true" title="' + deviceName + '" alt="' + deviceName + '" style="cursor:default" /></td>';
			// add the default user if multi user support is enabled
			html += buildMUSdeviceCell(i, receiver.receiverKey);
			// add a button to see more technical information
			var buttonClass = "mediaReceiverToggleButton hidden smallestFont";
			if (isReceiverInfoOpen(receiver.receiverKey)) buttonClass = "mediaReceiverToggleButton smallestFont";
			html += '<td style="padding-top:2px;padding-bottom:0px"><a onclick="showMoreTechnicalDeviceInformation(' + i + ')" >\
						<div id="receiverRowButton' + i + '" class="' + buttonClass + '">\
						<div class="toggleText" ' + getString("show") + '></div></div>\
						<div class="toggleSpacer"></div></a></td>';
			// add the receiver key as hidden field
			html += '<td><input class="receiverKey" name="receiverKey" type="hidden" value="' + receiver.receiverKey +	'" /></td>';
			html += '<td>&nbsp;</td>';
			html += '</tr>';
			html += buildDeviceRow(i, receiver);
			html += '<tr style="height:4px"><td colspan="7"></td></tr>';	// small empty paragraph behind every device
		} else {
			// aggregation server
			htmla += '<tr id="aggServerRow' + i + '">';
			htmla += '<td><input onchange="aggServerChanged(' +	i + ')" type="checkbox" ' +	checked + 
					 ' title="' + getString("enabledisableaggserver") + '" alt="' + getString("enabledisableaggserver") + '" /></td>';
			htmla += '<td><input class="fnameInputLong" type="text" value="' + receiver.friendlyname + 
					 '" disabled="true" title="' + receiver.friendlyname + '" alt="' + receiver.friendlyname + '" style="cursor:default" /></td>';
			htmla += '<td><input class="macInput" type="text" value="' + receiver.mac +	'" disabled="true" style="cursor:default" /></td>';
			htmla += '<td><input class="ipInput" type="text" value="' +	receiver.ip + '" disabled="true" style="cursor:default" /></td>';
			htmla += '<td>' + getReceiverClientDropdown(receiver.clientName, i, false) + '</td>';
			htmla += '<td><input type="hidden" class="aggregationKey" value="' + receiver.receiverKey + '" /></td>';
			htmla += '</tr>';
		}
	});
	element.html("");
	element.show();
	element.append(html);
	elementa.html("");
	elementa.show();
	elementa.append(htmla);
}

// Get HTML for the receiver navigation view header
// str: text string
// isDefault: A boolean that indicates whether or not the user is able to update the dropdown
function getReceiverViewHeader(str, isDefault) {
    if (!isDefault) return getString(str);
	return "";
}
//Get HTML for the receiver navigation view dropdown.
//selectedView: The currently selected navigation view for the current receiver.
//isDefault: A boolean that indicates whether or not the user is able to update the dropdown. If true, a disabled
//dropdown is returned.
//i: The row number used to uniquely identify the receiver.
function getReceiverViewDropdown(selectedView, isDefault, index){
    var html = "";
    if (!isDefault) {
		// pre-definded navigation trees
		var data = sharing["viewnames"];
		html = '<select name="viewName" onchange="receiverChanged(' + index + ')">';
		for (var i=0;i<data.length;i++) {
			html += '<option value="' + data[i] + '" ' +
			checkSelectedMediaOption(data[i], selectedView) +
			'>' +
			getString(data[i]) +
			'</option>';
		}
		// user-defined navigation trees
		data = sharing["myviewnames"];
		for (var i=0;i<data.length;i++) {
			html += '<option value="' + data[i] + '" ' +
			checkSelectedMediaOption(data[i], selectedView) +
			'>' +
			data[i] +
			'</option>';
		}
		html += '</select>';
	}
    else {
        html = '';
    }
    return html;
}

//Get HTML for the receiver client type dropdown.
//selectedView: The currently selected navigation view for the current receiver.
//i: The row number used to uniquely identify the receiver.
function getReceiverClientDropdown(selectedClient, i, showBox){
    var html = '<select class="clientType" name="clientType" ';
	if (!showBox) html += 'style="display:none" ';
    html += 'onchange="receiverChanged(' + i + ')">';
    var clientPieces = sharing.clients[0].split(",");
    $.each(clientPieces, function(i, value){
        if (i % 2 == 0) {
            html += '<option value="' + value + '" ';
        }
        else {
            html += checkSelectedMediaOption(value, selectedClient) + '>' + value + '</option>';
        }
    });
    html += "</select>";
    return html;
}

//Add a changed receiver to the changedReceviers collection.
//i: The row number of the changed receiver.
function receiverChanged(i){
	sharingReceiverChanged = true;
	// change the hidden checkbox in the receiver row too
	var id = document.getElementById("checkDevice"+i);
	var idh = document.getElementById("checkDeviceHidden"+i);
	idh.checked = id.checked;
    changedReceivers[i] = $("#receiverRow" + i, ".mediaReceiversTable");
}
//Add a changed agg server to the changedAggServer collection.
//i: The row number of the changed agg server.
function aggServerChanged(i){
	sharingAggServerChanged = true;
    changedAggServer[i] = $("#aggServerRow" + i, ".aggServersTable");
}
// default user of a receiver changed
function deviceDefaultUserChanged(i) {
	sharingReceiverUserChanged = true;
}

function assignUsersToNewLocations(locations) {
	if (sharing["multiusersupportenabled"] == "0") return "";
	var newLocationUserList = "";
	var locationUserList = multiUserSupport["locationuserlist"][0].split("\n");
	var locName = "";
	var locLength = 0;
	var locUsers = "";
	for (var i=0;i<locations.length;i++) {
		var found = false;
		var locName = "";
		var locLength = 0;
		var locUsers = "";
		for (var j=0;j<locationUserList.length;j++) {
			var locationUser = locationUserList[j].split(";");
			var loc = Base64.decode(locationUser[0]);
			if (locations[i] == loc) {
				found = true;	// this is a known location
				break;
			}
			// is it a subfolder of a known folder ?
			var index = locations[i].indexOf(loc);
			if (index == 0) {
				// it is a subfolder - save the user list
				// if there are more than one parent folder take the "nearest" one  
				// example: new folder is c:\music\myMusic\favorite
				// known folders are: c:\music and c:\music\myMusic
				// the new folder get the user list from the known folder c:\music\myMusic 
				if (loc.length > locLength) {
					locName = loc;
					locLength = loc.length;
					locUsers = locationUser[1];
				}
			}
		}
		if (!found) {	// this is a new location
			if (!(locUsers == "")) {
				newLocationUserList += Base64.encode(locations[i]) + ";" + locUsers + "\n";
			}
		}
	}
	newLocationUserList = multiUserSupport["locationuserlist"][0] + newLocationUserList;
	return newLocationUserList;
}

function submitSharingData(){
	if (!changesMade) return;
	var args = submitSharingData.arguments.length;
    returnedCalls = 0;
	expectedCalls = 1;	// set_all
	
	// build the contentdir
	// format: +M|C:\Users\mgran.PV\Music,+P|C:\Users\mgran.PV\Pictures,+V|C:\Users\mgran.PV\Videos dbdir=C:\ProgramData\TwonkyServer\dbFormat: 
    var shareFoldersList = $(".sharingRowWrapper", $("#share_folders_container"));
	var emptyPath = false;
	var contentDirKey = "contentdir=";
    var contentDir = "";
	var audiobooklocations = "";
	var locations = new Array();	// collect the shared folders in this array
	var aggchecked = new Array();	// collect the aggregation clients availabe for aggregation
	var agg = document.getElementsByName("aggCheckbox");
	for (var i=0;i<agg.length;i++) {
		aggchecked[i] = agg[i].checked;
	}
    $.each(shareFoldersList, function(i, value){
        var dirInput = $(".pathInput", value);
        var dirPath = dirInput.val();
		locations[locations.length] = dirPath;
        if (dirPath) {
            var sharedCheckbox = $(".sharedCheckbox", value);
            var enabledKey;
            if (sharedCheckbox.is(":checked") && aggchecked[i]) {
                enabledKey = "*";
            }
            else 
                if (sharedCheckbox.is(":checked")) {
                    enabledKey = "+";
                }
                else {
                    enabledKey = "-";
                }
            var mediaKey = $(".contentTypeDropdown", value).val();
			// audiobook is saved with the media key "M". The audiobook paths are stored via set_option?audiobooklocations=<list with paths>.
			if (mediaKey == "B") {
				mediaKey = "M";
				if (audiobooklocations == "") audiobooklocations = dirPath;
				else audiobooklocations += "," + dirPath;
			}
			if (contentDir == "") contentDir += enabledKey + mediaKey + "|" + dirPath;
			else contentDir += "," + enabledKey + mediaKey + "|" + dirPath;
        }
		else emptyPath = true;
    });

	// increment the expected calls for each changed receiver and aggregation server
	// receiver
    $.each(changedReceivers, function(key, receiverRow){
		expectedCalls++;
    });
	
	// aggregation server
    $.each(changedAggServer, function(key, aggServerRow){
		expectedCalls++;
    });

	// assign users from the parent share to new shares
	var newLocationUserList = "";
	if (sharing["multiusersupportenabled"] == "1") {
		newLocationUserList = assignUsersToNewLocations(locations);
		if (newLocationUserList == multiUserSupport["locationuserlist"][0]) newLocationUserList = "";	// location user list does not changed
	}
	
	// build the device list with the user assigned to the receivers (devices)
	var newDeviceUserList = "";
	if (sharing["multiusersupportenabled"] == "1") {
		// multi user support is enabled: save the user assigned to the devices. 
		// format: DEVICE1=USER1\nDEVICE2=USER2\n... (one user per device)
		var idReceiverKeys = document.getElementsByName("receiverKey");
		if (idReceiverKeys.length == 0) newDeviceUserList = multiUserSupport["deviceuserlist"][0];	// nothing changed
		for (var index=0;index<idReceiverKeys.length;index++) {
			var idDefaultUser = document.getElementById("deviceDefaultUser"+index);
			var selIndex = idDefaultUser.selectedIndex;
			var deviceUser = idDefaultUser[selIndex].text;
			if (deviceUser == "") deviceUser = sharing["multiusersupportdefaultuser"];	// if no user is checked set the default user
			newDeviceUserList += idReceiverKeys[index].value + "=" + deviceUser + "\n";
		}
	}
	
	showLoadingGraphic();
    hideActionButtons();
    resetChanged();

	var data = "";
	data += contentDirKey + contentDir + "\n";
	sharing["contentdir"] = contentDir;	
	var autoshareCheckbox = $("#autoshareCheckbox", $(".serverSettingsContentWrapper"));
	var autoshareCheckboxValue = ((autoshareCheckbox.is(":checked")) ? (1) : (0));
	if (sharingOrig["rmautoshare"] != autoshareCheckboxValue) {
		data += "rmautoshare=" + autoshareCheckboxValue + "\n";
		sharing["rmautoshare"] = autoshareCheckboxValue;
	}
	var clientautoenable = (($("input[key=clientautoenable]").attr("checked") == true) ? ("1") : ("0"));
	if (sharingOrig["clientautoenable"] != clientautoenable) {
		data += "clientautoenable=" + clientautoenable  + "\n";
		sharing["clientautoenable"] = clientautoenable;
	}
	sharingOrig["rmautoshare"] = sharing["rmautoshare"];
	sharingOrig["clientautoenable"] = sharing["clientautoenable"];
	sharingOrig["contentdir"] = sharing["contentdir"];
	if (data == "") {
		returnedCalls++;
		if (expectedCalls == returnedCalls) 
			saveAudiobooks(args, emptyPath, contentDir, newLocationUserList, newDeviceUserList, audiobooklocations);
	} else {			
		makePostRequest("/rpc/set_all", {}, data, function(){
			returnedCalls++;
			if (expectedCalls == returnedCalls) 
				saveAudiobooks(args, emptyPath, contentDir, newLocationUserList, newDeviceUserList, audiobooklocations);
		});
	}
	
    //Only submit client_change requests for receivers that have been changed.
    $.each(changedReceivers, function(key, receiverRow){
        var receiverKey = $(".receiverKey", receiverRow).val();
        var enabled = ($("input[type=checkbox]", receiverRow).attr("checked")) ? ("1") : ("0");
        var clientId = $("select[name=clientType]", receiverRow).val();
        var viewName = $("select[name=viewName]", receiverRow).val();
        var mac = $(".macInput", receiverRow).val();
        makeGetRequest("/rpc/client_change", {
			"key": receiverKey,
            "mac": mac,
            "id": clientId,
            "enabled": enabled,
            "view": viewName
        }, function(){
            returnedCalls++;
			if (expectedCalls == returnedCalls) 
				saveAudiobooks(args, emptyPath, contentDir, newLocationUserList, newDeviceUserList, audiobooklocations);
        });
    });

    //Only submit client_change requests for agg servers that have been changed.
    $.each(changedAggServer, function(key, aggServerRow){
        var receiverKey = $(".aggregationKey", aggServerRow).val();
        var enabled = ($("input[type=checkbox]", aggServerRow).attr("checked")) ? ("1") : ("0");
        var clientId = $("select[name=clientType]", aggServerRow).val();
        var mac = $(".macInput", aggServerRow).val();
        makeGetRequest("/rpc/client_change", {
			"key": receiverKey,
            "mac": mac,
            "id": clientId,
            "enabled": enabled
        }, function(){
            returnedCalls++;
			if (expectedCalls == returnedCalls)
				saveAudiobooks(args, emptyPath, contentDir, newLocationUserList, newDeviceUserList, audiobooklocations);
        });
    });
}
// save the audiobooklocations
function saveAudiobooks(args, emptyPath, contentDir, newLocationUserList, newDeviceUserList, audiobooklocations) {
        makeGetRequest("/rpc/set_option", {
			"audiobooklocations": audiobooklocations
        }, function(){
			saveMUSData(args, emptyPath, contentDir, newLocationUserList, newDeviceUserList);
        });
}
// save multi user data
function saveMUSData(args, emptyPath, contentDir, newLocationUserList, newDeviceUserList) {
    returnedCalls = 0;
	expectedCalls = 0;	

	// multi user disabled
	if (sharing["multiusersupportenabled"] == "0") {
		finishSavingSharingData(args, emptyPath, contentDir);
		return;
	}

	// multi user enabled - save the location list and the device list
	// increment the expected calls if new shares have been added with known parent shares
	if (newLocationUserList != "") expectedCalls ++;
	// increment the expected calls if the device-user-list changed
	if (newDeviceUserList != multiUserSupport["deviceuserlist"][0]) expectedCalls++;
	
	if (returnedCalls == expectedCalls) {
		// nothing to save
		finishSavingSharingData(args, emptyPath, contentDir);
		return;
	}			
	
	// save location user list
	if (newLocationUserList != "") {
		makePostRequest2("/rpc/set_location_user_list", {}, newLocationUserList, function(response){
			if (response != "ok") saveLocationFailed = true;
			else {
				multiUserSupport["locationuserlist"][0] = newLocationUserList;
				multiUserSupportOrig["locationuserlist"][0] = newLocationUserList;
			}
			returnedCalls++;
			if (returnedCalls == expectedCalls) {
				finishSavingSharingData(args, emptyPath, contentDir);
			}
		}, function() {
			returnedCalls++;
			saveLocationFailed = true;
			if (returnedCalls == expectedCalls) {
				finishSavingSharingData(args, emptyPath, contentDir);
			}			
		});		
	}
	// save user assigned to receivers (devices)
	if (newDeviceUserList != multiUserSupport["deviceuserlist"][0]) {
		makePostRequest2("/rpc/set_device_user_list", {}, newDeviceUserList, function(response, parameter){
			if (response != "ok") saveDeviceUserFailed = true;
			else {
				multiUserSupport["deviceuserlist"][0] = newDeviceUserList;
				multiUserSupportOrig["deviceuserlist"][0] = newDeviceUserList;
			}
			returnedCalls++;
			if (returnedCalls == expectedCalls) {
				finishSavingSharingData(args, emptyPath, contentDir);
			}
		}, function(parameter) {
			returnedCalls++;
			saveDeviceUserFailed = true;
			if (returnedCalls == expectedCalls) {
				finishSavingSharingData(args, emptyPath, contentDir);
			}			
		});		
	}
}
function finishSavingSharingData(args, emptyPath, contentDir){
	requestFailed(); 
	finishSaving();
	hideLoadingGraphic();
	if ((args > 0) && emptyPath) {
		updateSharedFolderList($("[key=contentdir]"), contentDir)
	}
}
function refreshSharingScreen() {
	updateSharing();
	updateSharingFolder();
}

// ------------------------
// aggregation page
// ------------------------
function loadAggregation(){
    returnedCalls = 0;
    expectedCalls = 2;
    saveHandler = "submitAggregationData();"
	inputFieldClicked = false;
    changesMade = false;

	showLoadingGraphic();
    
    makeGetRequest("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, aggregation, aggregationOrig, "=");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadAggregationHtml();
			hideLoadingGraphic();
        }
    });
 
    //The listaggregatedservers call will fail if aggregation is disabled. If data is returned, handle it as normal.
    //Otherwise, make sure the aggregated servers collection is empty and load the HTML.
    $.ajax("/rpc/listaggregatedservers", {
        success: function(response){
            parseData(response, aggregation, aggregationOrig, "aggregatedservers", "----------");
            returnedCalls++;
            if (expectedCalls == returnedCalls) {
                loadAggregationHtml();
				hideLoadingGraphic();
            }
        },
        error: function(){
            aggregation["aggregatedservers"] = null;
            returnedCalls++;
            if (expectedCalls == returnedCalls) {
                loadAggregationHtml();
				hideLoadingGraphic();
            }
        }
    });
}

function loadAggregationHtml(){
    makeGetRequest("/webconfig/aggregation.htm", {}, function(response, parameter){
        var responseHtml = $(response);
        replaceStrings(responseHtml);
        replaceData(responseHtml, aggregation, handleAggregationData);
		showToggleButtons(responseHtml);
        
        $(".serverSettingsContentWrapper").html(responseHtml);
        //Show or hide the aggregation server container based on whether or not aggregation is enabled.
        toggleAvailableServers(aggregation["aggregation"] == 1);
        $("input,select", "#aggregationContainer").live("change", onEventChange);
        highlightNav($("#nav_aggregation"));
        updateTimer = setInterval(updateAggregation, updateTimerInterval);
    });
}

function updateAggregation(){
    //Only call to get an updated list of servers if no changes have been made.  This avoids
    //   updating HTML while a user is making changes.
    if(!changesMade) {
       $.ajax("/rpc/listaggregatedservers", {
           success: function(response){
               parseData(response, aggregation, aggregationOrig, "aggregatedservers", "----------");
               updateAggregatedServers($("[key=aggregatedservers]"), aggregation.aggregatedservers);
           },
           error: function(){
               aggregation["aggregatedservers"] = null;
           }
       });
    }
}

function handleAggregationData(element, key, data){
    switch (key) {
        case "aggregation":
            if (data == 1) {
                element.attr("checked", true);
            }
            break;
        case "aggmode":
            var matchingInput = $("input[type=radio][name=aggregationMode][value=" + data + "]", element);
            matchingInput.attr("checked", true);
            break;
        case "aggregatedservers":
            updateAggregatedServers(element, data);
            break;
    }
}

function updateAggregatedServers(element, data){
    if (data) {
        var serverHtml = "";
        //Pop the last element of the collection off, since it's an empty piece of data.
        data.pop();
        $.each(data, function(i, value){
            var serverDataPieces = value.split("<br>");
            var serverData = {};
            $.each(serverDataPieces, function(i, value){
                var dataKey = value.substring(0, 1);
                var dataValue = value.substring(2, value.length).replace(/\n/g, "");
                serverData[dataKey] = dataValue;
            });
            var musicChecked = "";
            var photosChecked = "";
            var videosChecked = "";
            switch (serverData["F"]) {
                case "A":
                    musicChecked = "checked";
                    photosChecked = "checked";
                    videosChecked = "checked";
                    break;
                case "M":
                    musicChecked = "checked";
                    break;
                case "P":
                    photosChecked = "checked";
                    break;
                case "V":
                    videosChecked = "checked";
                    break;
                case "m":
                    photosChecked = "checked";
                    videosChecked = "checked";
                    break;
                case "p":
                    musicChecked = "checked";
                    videosChecked = "checked";
                    break;
                case "v":
                    musicChecked = "checked";
                    photosChecked = "checked";
                    break;
            }
            serverHtml += '<div uuid="' + serverData["S"] + '" class="availableServerContainer">' +
            serverData["N"] +
            '<div>\
            <span class="serverMediaLabel"><input onclick="onServerChanged(\'' +
            serverData["S"] +
            '\')" name="videos" type="checkbox"' +
            videosChecked +
            '/>' +
            getString("videos") +
            ' ' +
            '</span><span class="serverMediaLabel"><input onclick="onServerChanged(\'' +
			serverData["S"] +
            '\')" name="songs" type="checkbox"' +
            musicChecked +
            '/>' +
            getString("songs") +
            ' ' +
            '</span><span class="serverMediaLabel"><input onclick="onServerChanged(\'' +
            serverData["S"] +
            '\')" name="photos" type="checkbox"' +
            photosChecked +
            '/>' +
            getString("photos") +
            ' ' +
            '</span></div>\
            <div class="radioControlWrapper">\
                <input onclick="onServerChanged(\'' +
            serverData["S"] +
            '\')" name="' +
            serverData["S"] +
            'aggmode" type="radio" ' +
            checkAggMode(0, serverData["E"]) +
            ' value="0"/>' + 
            getString("ignore") +
            '</div>\
            <div class="radioControlWrapper">\
                <input onclick="onServerChanged(\'' +
            serverData["S"] +
            '\')" name="' +
            serverData["S"] +
            'aggmode" type="radio" ' +
            checkAggMode(1, serverData["E"]) +
            ' value="1" />' + 
            getString("aggregate") +
            '</div>\
            <div class="radioControlWrapper">\
                <input onclick="onServerChanged(\'' +
            serverData["S"] +
            '\')" name="' +
            serverData["S"] +
            'aggmode" type="radio" ' +
            checkAggMode(2, serverData["E"]) +
            ' value="2" />' +
            getString("mirror") +
            '</div>\
			 <div class="clear"></div>\
		</div>';
        });
        element.show();
        element.html(serverHtml);
    }
    else {
        element.hide();
    }
}

//A utility function to determine whether a checkbox or radio input should be checked.
//aggMode: The value of the input in question.
//compareMode: The string to compare to.
function checkAggMode(aggMode, compareMode){
    return (aggMode == compareMode) ? ("checked") : ("");
}

//When a server is updated, add it to the changedServers collection.
//uuid: The uuid of the changed server.
function onServerChanged(uuid){
    changedServers[uuid] = true;
}

function toggleAvailableServers(isAggEnabled){
    (isAggEnabled) ? ($("#availableServersContainer").show()) : ($("#availableServersContainer").hide());
}

function submitAggregationData(){
	if (!changesMade) return;
    hideActionButtons();
    returnedCalls = 0;
    expectedCalls = 1;
	
	showLoadingGraphic();
    resetChanged();
	
    var aggregationEnabledCheckbox = $("#aggregationEnabledCheckbox");
    var enableAggregation = ((aggregationEnabledCheckbox.is(":checked")) ? (1) : (0));
    var aggMode = $("input[name=aggregationMode]:checked").val();
	var data = "";
	if (aggregationOrig["aggregation"] != enableAggregation) {
		data += "aggregation=" + enableAggregation + "\n";
		aggregation["aggregation"] = enableAggregation;
	}
	if (aggregationOrig["aggmode"] != aggMode) {
		data += "aggmode=" + aggMode + "\n";
		aggregation["aggmode"] = aggMode;
	}
	if (data == "") expectedCalls = 0;
    var aggregationServers = $(".availableServerContainer");
    $.each(aggregationServers, function(i, value){
        var element = $(value);
        //Only submit aggregatedserverswitch and aggregatedservercontent calls for servers that have been changed
        //(are in the changedServers collection).
        if (changedServers[element.attr("uuid")]) {
            changedServers[element.attr("uuid")] = false;
            expectedCalls += 2;
            var selectedAggregationMode = $("input[type=radio]:checked", element).val();
            var selectedContentTypes = $("input[type=checkbox]:checked", element);
            var musicChecked = false;
            var photosChecked = false;
            var videosChecked = false;
            $.each(selectedContentTypes, function(i, value){
                var checkbox = $(value);
                switch (checkbox.attr("name")) {
                    case "songs":
                        musicChecked = true;
                        break;
                    case "photos":
                        photosChecked = true;
                        break;
                    case "videos":
                        videosChecked = true;
                        break;
                }
            });
            var contentType = "";
            if (musicChecked && photosChecked && videosChecked) {
                contentType = "A";
            }
            else 
                if (musicChecked && photosChecked) {
                    contentType = "v";
                }
                else 
                    if (musicChecked && videosChecked) {
                        contentType = "p";
                    }
                    else 
                        if (photosChecked && videosChecked) {
                            contentType = "m";
                        }
                        else 
                            if (musicChecked) {
                                contentType = "M";
                            }
                            else 
                                if (photosChecked) {
                                    contentType = "P";
                                }
                                else 
                                    if (videosChecked) {
                                        contentType = "V";
                                    }
            makeGetRequest("/rpc/aggregatedserverswitch", {
                "uuid": element.attr("uuid"),
                "enabled": selectedAggregationMode
            }, function(){
                returnedCalls++;
				if (returnedCalls == expectedCalls) {
					finishSaving();
					hideLoadingGraphic();
				}
            });
            makeGetRequest("/rpc/aggregatedservercontent", {
                "uuid": element.attr("uuid"),
                "cType": contentType
            }, function(){
                returnedCalls++;
				if (returnedCalls == expectedCalls) {
					finishSaving();
					hideLoadingGraphic();
				}
            });
        }
    });
	aggregationOrig["aggregation"] = aggregation["aggregation"];
	aggregationOrig["aggmode"] = aggregation["aggmode"];
	if (!(data == "")) {
		makePostRequest("/rpc/set_all", {}, data, function(){
			returnedCalls++;
			if (returnedCalls == expectedCalls) {
				finishSaving();
				hideLoadingGraphic();
			}
		});
	} else {
		if (returnedCalls == expectedCalls) {
			finishSaving();
			hideLoadingGraphic();
		}
	}
}


// ------------------------
// multi user support page
// ------------------------
function loadMultiUserSupport(){
    returnedCalls = 0;
    expectedCalls = 2;
    saveHandler = "submitMultiUserSupportData();"
	inputFieldClicked = false;
    changesMade = false;

	showLoadingGraphic();
    
	// get first the data from the server ini file
    makeGetRequest("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, multiUserSupport, multiUserSupportOrig, "=");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			hideLoadingGraphic();
			// get the multi user support data and call the function loadMultiUserSupport_UserData and loadMultiUserSupportHtml
			getMultiUserSupport_Data(multiUserSupport["multiusersupportenabled"], loadMultiUserSupportHtml);
        }
    });
	// get the tls port for https
    makeGetRequest("/rpc/get_tls_port", {}, function(response, parameter){
        parseData(response, multiUserSupport, multiUserSupportOrig, "tlsport", "--");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
			hideLoadingGraphic();
			// get the multi user support data and call the functions loadMultiUserSupport_UserData and loadMultiUserSupportHtml
			getMultiUserSupport_Data(multiUserSupport["multiusersupportenabled"], loadMultiUserSupportHtml);
        }
    });
}
// get the multi user support data (roles, user, roles assiged to the locations and user assiged to the devices
// therefor switch to **** https ****
function getMultiUserSupport_Data(multiUserSupportEnabled, callFunction) {
	if (multiUserSupportEnabled == "0") {
		// multi user support is disabled
		callFunction();
		hideLoadingGraphic();
		return;
	}
    returnedCalls = 0;
    expectedCalls = 3;
	showLoadingGraphic();
	
    makeGetRequest2("/rpc/get_user_list", {}, function(response, parameter){
        parseData(response, multiUserSupport, multiUserSupportOrig, "userlist", "--");
		// multiUserSupport["userlist"]: user1,user2,...userN
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            callFunction();
			hideLoadingGraphic();
        }
    }, function(parameter) {
        parseData("", multiUserSupport, multiUserSupportOrig, "userlist", "--");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            callFunction();
			hideLoadingGraphic();
        }
	});

    makeGetRequest2("/rpc/get_location_user_list", {}, function(response, parameter){
        parseData(response, multiUserSupport, multiUserSupportOrig, "locationuserlist", "--");
		// multiUserSupport["locationuserlist"]: location1=user1\nlocation2=user1,user2\n... (location is base64 encoded)
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            callFunction();
			hideLoadingGraphic();
        }
    }, function(parameter) {
        parseData("", multiUserSupport, multiUserSupportOrig, "locationuserlist", "--");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            callFunction();
			hideLoadingGraphic();
        }
	});

    makeGetRequest2("/rpc/get_device_user_list", {}, function(response, parameter){
        parseData(response, multiUserSupport, multiUserSupportOrig, "deviceuserlist", "--");
		// multiUserSupport["deviceuserlist"]: mac1::index=user1\nmac2::index=user2\n...macN::index=user1\n
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            callFunction();
			hideLoadingGraphic();
        }
    }, function(parameter) {
        parseData("", multiUserSupport, multiUserSupportOrig, "deviceuserlist", "--");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            callFunction();
			hideLoadingGraphic();
        }
	});
}

function loadMultiUserSupportHtml(){
    makeGetRequest2("/webconfig/multi_user_support.htm", {}, function(response, parameter){
		// on success
        var responseHtml = $(response);
        replaceStrings(responseHtml);
        replaceData(responseHtml, multiUserSupport, handleMultiUserSupportData);
		showToggleButtons(responseHtml);       
        $(".serverSettingsContentWrapper").html(responseHtml);
		
        //Show or hide the username/password and the http/https protocol based on whether or not multi user support is enabled.
        toggleEnableMultiUserSupportPwd((multiUserSupport["multiusersupportenabled"] == 1) && multiUserSupportOrig["multiusersupportenabled"] == 0);
        //Show or hide the user/role management based on whether or not multi user support is enabled.
        toggleEnableMultiUserSupport(multiUserSupport["multiusersupportenabled"] == 1);
        $("input,select", "#multiUserContainer").live("change", onEventChange);
        highlightNav($("#nav_multiusersupport"));
    },
    function(parameter) {
        // on failure
		showDialogOverlay(function(){
			return getString("authfailed");
		}, {}, [{
			text: getString("ok"),
			onclick: "hideDialogOverlay();"
		}]);		       
    });
}


// show or hide the page (according the multi user support flag)
function toggleEnableMultiUserSupportPwd(isEnabled) {
    (isEnabled) ? ($("#multiUserSupportEnableContainer").show()) : ($("#multiUserSupportEnableContainer").hide());
}
// show or hide the page (according the multi user support flag)
function toggleEnableMultiUserSupport(isEnabled) {
    (isEnabled) ? ($("#multiUserSupportContainer").show()) : ($("#multiUserSupportContainer").hide());
    (isEnabled) ? ($("#multiUserSupportConfigureDevicesButton").show()) : ($("#multiUserSupportConfigureDevicesButton").hide());
}
// set the focus to the user (name: addUser) or role (name: addRole) entry field
function setMUSFocus(fieldName) {
	if (multiUserSupport["multiusersupportenabled"] == 0) return;
	document.getElementById(fieldName).focus();	// set focus to the user entry field	
}
// checkbox: value multiUserSupportEnabled changed
function multiUserSupportCheckboxChanged() {
    var MUSEnabledCheckbox = $("#multiUserSupportEnabledCheckbox");
    var enableMUS = ((MUSEnabledCheckbox.is(":checked")) ? (1) : (0));
	multiUserSupport["multiusersupportenabled"] = enableMUS;
	// show the user/password and the use-https-flag
	if (multiUserSupportOrig["multiusersupportenabled"] == 0)
		toggleEnableMultiUserSupportPwd(multiUserSupport["multiusersupportenabled"] == 1);	
	// show the user and roles if the flag was enabled
	if (multiUserSupportOrig["multiusersupportenabled"] == 1) {
		toggleEnableMultiUserSupportPwd(false);		// disable the user/pwd,https part
		toggleEnableMultiUserSupport(multiUserSupport["multiusersupportenabled"] == 1);
	}
}

function handleMultiUserSupportData(element, key, data){
    switch (key) {
        case "multiusersupportenabled":
            if (data == 1) {
                element.attr("checked", true);
            }
            break;
		case "accessuser":
			var alllist = multiUserSupport["multiusersupportdefaults"];
			var defusers = alllist.split(";");
			if (defusers.length > 0) {
				var oneuser = defusers[0].split(":");
				element.html(oneuser[0]);
			} else element.html("Admin");
			break;
		case "accesspwd":
			var alllist = multiUserSupport["multiusersupportdefaults"];
			var defusers = alllist.split(";");
			if (defusers.length > 0) {
				var oneuser = defusers[0].split(":");
				element.val(oneuser[1]);
			} else element.val("Admin");
			break;
        case "userlist":
			if (multiUserSupport["multiusersupportenabled"] == 1) {
				buildMUSuser(element, data);
			}
			break;
    }
}

// Multi User Support: build the userlist
function buildMUSuser(element, data) {
	element.html("");
	var html = "";
	html += '<div id="userlistContainer">';
	var userIndex = 0;
	// add default user and show the button setPassword
	// structure of [multiusersupportdefaults]: defUser1:defPwd1:defRole1;defUser2:defPwd2:defRole2;...
	var alllist = multiUserSupport["multiusersupportdefaults"];
	var defusers = alllist.split(";");
	for (var i=0; i<defusers.length; i=i+1) {
		var oneuser = defusers[i].split(":");
		var containerID = "multiUserSupportUserList" + i;
		html += '<div class="multiUserSupportWrapperBackground" id="' + containerID + '">';
		html += '<div class="multiUserSupportWrapper" name="multiUserSupportUser">';
		html += buildMUSuser_username(getString(oneuser[0]), userIndex, "0");	// parameter: user name, user index, value of attribute adduser
		// default user: guest - checkbox access to shares, no password, 
		//				 admin - change password, 
		// other user: password, age, share list, remove user
		switch (oneuser[0]) {
			case "admin":
				html += buildMUSuser_pwd_admin(userIndex);
				break;
			case "guest":
				html += buildMUSuser_hiddenPwd(userIndex);					// for submit changes
				html += buildMUSuser_shares("guest", userIndex);			// user name, user index
				break;
			default:
				html += buildMUSuser_hiddenPwd(userIndex);					// for submit changes
				html += buildMUSuser_shares(oneuser[0], userIndex);			// user name, user index
		}
		html += '<div class="clear"></div></div></div>';
		userIndex = userIndex + 1;
	}
	firstUserDefinedUserIndex = userIndex;
	// add users, show the buttons setPassword and deleteUser and show the shares
	// structure of data (userlist): user1,user2,...
	if (!(data[0] == "")) {
		var userlist = data[0].split(",");
		$.each(userlist, function(fIndex, user) {
			if (user == "") return true;
			var containerID = "multiUserSupportUserList" + userIndex;
			html += '<div class="multiUserSupportWrapperBackground" id="' + containerID + '">';
			html += '<div class="multiUserSupportWrapper"  name="multiUserSupportUser">';
			html += buildMUSuser_username(user, userIndex, "0");		// user (adduser="0" <- this is not a new user)
			html += buildMUSuser_pwd(userIndex, true, "0");				// set password (setpwd="0" <- do not change the password)
			html += buildMUSuser_shares(user, userIndex);				// shares (user name, user index)
			html += buildMUSuser_delete(userIndex);						// delete user		
			html += '<div class="clear"></div></div></div>';
			userIndex = userIndex + 1;
		});
	}
	html += '</div>';		// id="userlistContainer"
	// add the button to add new users to the list
	html += '<div>';
	html += '<div class="multiUserSupportWrapper">';
	html += buildMUSuser_add(userIndex);										// button to add new user
	html += '<div class="clear"></div></div>';
	html += '</div>';
	element.html(html);
}
// BUILD MUS : add a container with the new user
function buildNewMUSuser(user) {
	var html = '';
	var id = document.getElementsByName("multiUserSupportUser");
	var userIndex = id.length;
	var containerID = "multiUserSupportUserList" + userIndex;
	html += '<div class="multiUserSupportWrapperBackground" id="' + containerID + '">';
	html += '<div class="multiUserSupportWrapper" name="multiUserSupportUser">';
	html += buildMUSuser_username(user, userIndex, "1");		// user (adduser="1")
	html += buildMUSuser_pwd(userIndex, true, "2");				// set password (setpwd="2" <- add the new user with password)
	html += buildMUSuser_shares(user, userIndex);				// shares (user name, user index)
	html += buildMUSuser_delete(userIndex);						// delete user		
	html += '<div class="clear"></div></div>';
	html += '</div>';
    $("#userlistContainer").append(html);
	addUser_setPwd(userIndex);			// take the password from "add new user"
	addUser_setShares(userIndex);		// take the shares from "add new user"	
}
// The password was set via the "add new user" button. Take it and set the password value in the table.
function addUser_setPwd(index) {
	var idpwd = mus_idPwd + index;			// password input field
	var idNewPwd = document.getElementById(mus_idAddPwd);			
	var id = document.getElementById(idpwd);
	id.value = idNewPwd.value;									// set the password value
}
// The shares were set via the "add new user" button. Take the share values and set the values in the table.
function addUser_setShares(index) {
	var nameshare = "MUSflags"+index;
	var flagsAdded = document.getElementsByName(mus_idAddSharesFlag);	// shares of "add new user"
	var flags = document.getElementsByName(nameshare);					// shares of last list element (the last added user)
	var idallshare = "MUSallFlag"+index;
	var allShares = true;
	for (var j=0;j<flagsAdded.length;j++) {
		var check = "";
		if (flagsAdded[j].checked) check = "checked";
		else allShares = false;
		flags[j].checked = check;
	}
	if (allShares && (flagsAdded.length > 0)) {
		var id = document.getElementById(idallshare);
		id.checked = "checked";
	}
}
// BUILD MUS : show user name
// attributes["adduser"] in HTML-element "MUSuserN" (N=user in the row N; N >= 2)
// adduser = 0 -> user from userlist
// adduser = 1 -> user is new
// adduser = 2 -> user is removed
// adduser = 8 -> remove user
// adduser = 9 -> remove a new user
var mus_idUser = "MUSuser";
function buildMUSuser_username(user, index, adduser) {
	var nameuser = "MUSuser";			// name the text fields of all users
	var iduser = mus_idUser + index;	// user text field
	var html = "";
	if (user == "") {
		// new user
		html += '<input adduser="' + adduser + '" class="usernameInput floatL" type="text" value="" ' +
				' style="cursor:default" id="' + mus_idAddUser + '" />';
	} else {
		// list user (input field is disabled - the user name can not be changed)
		html += '<input name="' + nameuser + '" id="' + iduser + '" adduser="' + adduser + '" class="usernameInput floatL" type="text" value="' +
				user +
				'" disabled="true" style="cursor:default" />';
	}
	return html;
}
// BUILD MUS : show password (setpwd="0")
// attributes["setpwd"] in HTML-element "MUSpwdN" (N=password in the row N)
// setpwd = 0 -> password was not changed
// setpwd = 1 -> password changed
var mus_idPwd = "MUSpwd";
function buildMUSuser_pwd(index, showButton, setpwd) {
	// user password: show button "set password" OR 
	//                input field to enter the password and the buttons "OK" and "cancel"
	var idpwdbtn = "MUSpwdbtn"+index;		// div container with the "set password" button
	var idpwdlabel = "MUSpwdLabel"+index;	// div container with the password input field and the buttons ok and cancel
	var idpwd = mus_idPwd + index;			// password input field
	var namepwd = "MUSpwd";					// name of all password input fields
	var html = '';
	// 	1.	show button "set password"
	if (showButton) {
		html += '<div id="' + idpwdbtn + '" class="show floatL">';
		html += '<a class="actionbtn floatL show" onclick="showChangeMUSpassword(' +
				idpwdbtn + ',' + idpwdlabel +
				');setMUSFocus(\''+ idpwd + '\')" onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
				getString("changepassword") +
				'</span><span class="actionbtn_r"></span></a>';
		html += '</div>';
	}
	// 	2.	show input field to enter the password
	html += '<div id="' + idpwdlabel + '" class="musBox hide floatL">';
	html += '<table>';
	html += '<tr><td>';
	html += '<span style="margin-left:5px">' + getString("changepassword") + '<\span><br>';
	html += '</td></tr>';
	html += '<tr><td>';
	html += '<input id="' + idpwd + '" name="' + namepwd + '" setpwd="' + setpwd + '" class="pwdInput" type="input" value="" style="cursor:default" />';
	html += '</td></tr>';
	// 	3.	show the buttons "OK" and "cancel" to save the new password or cancel the action (change/set password)
	html += '<tr><td>';
	html += '<a class="actionbtn" onclick="setMUSpassword(' +
			idpwdbtn + ',' + idpwdlabel + ',\'' + idpwd + '\',\'\')" ' + 
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("ok") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '<a class="actionbtn" onclick="cancelMUSpassword(' +
			idpwdbtn + ',' + idpwdlabel + ',\'' + idpwd + '\')" ' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("cancel") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '</td></tr>';
	html += '</table>';
	html += '</div>';
	return html;
}
// BUILD MUS : change password (for user admin)
function buildMUSuser_pwd_admin(index) {
	// user password: show button "set password" OR 
	//                input field to enter the password and the buttons "OK" and "cancel"
	var idpwdbtn = "MUSpwdbtn"+index;		// div container with the "set password" button
	var idpwdlabel = "MUSpwdLabel"+index;	// div container with the password input field and the buttons ok and cancel
	var idpwdold = "MUSpwdold"+index;		// password input field
	var idpwdnew = mus_idPwd+index;			// password input field
	var namepwdold = "MUSpwdold";			// name of all password input fields
	var namepwdnew = "MUSpwd";				// name of all password input fields
	var html = '';
	// 	1.	show button "change password"
	html += '<div id="' + idpwdbtn + '" class="show floatL">';
	html += '<a class="actionbtn floatL show" onclick="showChangeMUSpassword(' +
			idpwdbtn + ',' + idpwdlabel +
			');setMUSFocus(\''+ idpwdold + '\')" onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("changepassword") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '</div>';
	// 	2.	show input fields to enter the old password, the new password and the buttons "OK", "cancel"
	html += '<div id="' + idpwdlabel + '" class="musBox hide floatL">';
	html += '<table>';
	html += '<tr><td>';
	html += '<span>' + getString("oldpassword") + '</span>';
	html += '</td><td>';
	html += '<input id="' + idpwdold + '" name="' + namepwdold + '" setpwd="0" class="pwdInput" type="password" value="" style="cursor:default" />';
	html += '</td></tr>';
	html += '<tr><td>';
	html += '<span>' + getString("newpassword") + '</span>';
	html += '</td><td>';
	html += '<input id="' + idpwdnew + '" name="' + namepwdnew + '" setpwd="0" class="pwdInput" type="password" value="" style="cursor:default" />';
	html += '</td></tr>';
	html += '<tr><td>&nbsp;</td><td>';
	html += '<a class="actionbtn" onclick="setMUSpassword(' +
			idpwdbtn + ',' + idpwdlabel + ',\'' + idpwdnew + '\',\'admin\')" ' + 
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("ok") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '<a class="actionbtn" onclick="cancelMUSpassword(' +
			idpwdbtn + ',' + idpwdlabel + ',\'' + idpwdnew + '\')" ' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("cancel") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '</td></tr>';
	html += '</table>';
	html += '</div>';
	return html;
}
// BUILD MUS : show checkbox "access to non-restricted content" (user guest)
function buildMUSuser_hiddenPwd(index) {
	var idpwdlabel = "MUSpwdLabel"+index;	// div container with the password input field and the buttons ok and cancel
	var idpwd = mus_idPwd+index;				// password input field
	var namepwd = "MUSpwd";					// name of all password input fields
	var html = '';
	// the input field to enter the password is always hidden
	html += '<div id="' + idpwdlabel + '" class="hide">';
	html += '<input id="' + idpwd + '" name="' + namepwd + '" setpwd="0" class="pwdInput floatL" type="input" value="" style="cursor:default" />';
	html += '</div>';
	return html;
}
// BUILD MUS : delete user
function buildMUSuser_delete(index) {
	// delete user
	var iddelbtn = "MUSdelbtn"+index;
	var iddellabel = "MUSdelLabel"+index;
	var iddel = "MUSdel"+index;
	// 	show button "delete user"
	var html = '';
	html += '<div id="' + iddelbtn + '" class="floatL">';
	html += '<a class="actionbtn floatL" onclick="deleteMUSuser(' +
			index +
			')" onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("deleteuser") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '</div>';
	return html;
}
// BUILD MUS : user input field and button "add new user"
var mus_idAddBtn = "MUSaddbtn";
var mus_idAddLabel = "MUSnewUser";
var mus_idAddUser = "addUser";
var mus_idAddPwd = "addPwd";
var mus_idAddSharesBtn = "addSharesBtn";
var mus_idAddSharesLabel = "addSharesLabel";
var mus_idAddSharesFlag = "addSharesFlag";
function buildMUSuser_add(index) {
	// add new user
	var idpwdlabel = "MUSpwdLabel"+index;	// div container with the password input field and the buttons ok and cancel
	var idpwd = mus_idPwd+index;			// password input field
	var namepwd = "MUSpwd";					// name of all password input fields
	var idpwdbtn = "MUSpwdbtn"+index;		// div container with the "set password" button
	var html = "";
	// 	1.	show button "add new user"
	html += '<div id="' + mus_idAddBtn + '" class="floatL">';
	html += '<a class="actionbtn floatL" onclick="showNewMUSuser();setMUSFocus(\'addUser\')"' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("adduser") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '</div>';
	// 	2.	show input fields to enter the user name, password and the buttons "OK", "cancel"
	html += '<div id="' + mus_idAddLabel + '" class="musBoxAddUser hide floatL">';
	html += '<table>';
	html += '<tr><td>';
	html += 'User name';		// first header
	html += '</td><td>';
	html += 'Password';			// second header
	html += '</td><td>&nbsp;';	// third header
	html += '</td><td>&nbsp;';	// fourth header
	html += '</td></tr>';
	html += '<tr><td>';
	// id of the user name is addUser
	html += buildMUSuser_username("", 99, "0");		// parameter: user name, index, flag adduser
	html += '</td><td>';
	// id of the password is addPwd
	html += '<input id="' + mus_idAddPwd + '" setpwd="0" class="pwdInput floatL" type="input" value="" style="cursor:default" />';
	html += '</td><td>';
	html += buildMUSuser_shares("", 99);			// parameter: user name, user index
	html += '</td><td>';
	html += '<a class="actionbtn" style="padding-top:0px" onclick="addNewMUSuser()" ' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("ok") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '<a class="actionbtn" style="padding-top:0px" onclick="cancelNewMUSuser()" ' +
			' onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)"><span class="actionbtn_l"></span><span class="actionbtn_c">' +
			getString("cancel") +
			'</span><span class="actionbtn_r"></span></a>';
	html += '</td></tr>';
	html += '</table>';	
	html += '</div>';
	return html;
}
// show the fields user name, password and the shares to add a new user
function showNewMUSuser() {
	// button "add new user" was pressed. 
	// Show entry field to enter the user name, the password, the shares and two buttons - ok and cancel.
	var id1 = document.getElementById(mus_idAddBtn);
	var id2 = document.getElementById(mus_idAddLabel);
	$(id1).removeClass("show");
	$(id1).addClass("hide");	
	$(id2).removeClass("hide");	
	$(id2).addClass("show");	
	// open the share combobox and show the shares
	id1 = document.getElementById(mus_idAddSharesBtn);
	id2 = document.getElementById(mus_idAddSharesLabel);
	if ($(id2).hasClass("hide")) {
		$(id1).removeClass("hidden");
		$(id2).removeClass("hide");	
		$(id2).addClass("show");	
	}
}
// cancel the action "add new user"
function cancelNewMUSuser() {
	// button "add new user" was pressed and then the "cancel" button
	// clear the entry fields and show the "add new user" button
	var musAllFlag = "MUSallFlag99";
	var id = document.getElementById(mus_idAddUser);
	id.value = "";						// clear user name
	id = document.getElementById(mus_idAddPwd);
	id.value = "";						// clear password
	var flagsAdded = document.getElementsByName(mus_idAddSharesFlag);	// shares of "add new user"
	for (var j=0;j<flagsAdded.length;j++) {
		flagsAdded[j].checked = "";		// clear shares	checkboxes
	}
	if (flagsAdded.length > 0) {
		id = document.getElementById(musAllFlag);	
		id.checked = "";				// clear all shares
	}
	// show the "add new user" button and hide the row to add a new user
	var id1 = document.getElementById(mus_idAddBtn);
	var id2 = document.getElementById(mus_idAddLabel);
	$(id1).removeClass("hide");
	$(id1).addClass("show");	
	$(id2).removeClass("show");	
	$(id2).addClass("hide");	
}
// add a new user to the user list
function addNewMUSuser() {
	// is the user name valid?
	var id = document.getElementById(mus_idAddUser);
	if (id.value == "") return;
	if (nameContainsSpecialCharacter(id.value)) {
		showDialogOverlay(function(){
			return getString("specialcharacterinname");
		}, {}, [{
			text: getString("ok"),
			onclick: "hideDialogOverlay();"
		}]);
		return;
	}
	// add the user to the userlist
	if (add_user_toUserlist(id.value)) {
		buildNewMUSuser(id.value);		// update the screen and show the new user
		id.value = "";
		cancelNewMUSuser();				// clear the "add new user" fields and show the button to add a new user
	}
}
// before saving changes check if a new user was entered without saving it
function addNewMUSuserBeforeSubmit() {
	// is the user name valid?
	var id = document.getElementById(mus_idAddUser);
	if (id.value == "") return;
	if (nameContainsSpecialCharacter(id.value)) {
		saveUserFailed = true;
		if (saveUserFailedString == "") saveUserFailedString = id.value;
		else saveUserFailedString += ", " + id.value;
		return;
	}
	// add the user to the userlist
	if (isUserUnique(id.value)) {	
		if (multiUserSupport["userlist"][0] == "") multiUserSupport["userlist"][0] += id.value;
		else multiUserSupport["userlist"][0] += "," + id.value;
	} else {
		saveUserFailed = true;
		if (saveUserFailedString == "") saveUserFailedString = id.value;
		else saveUserFailedString += ", " + id.value;
		return;
	}
	buildNewMUSuser(id.value);		// update the screen and show the new user
	id.value = "";
	//cancelNewMUSuser();				// clear the "add new user" fields and show the button to add a new user
}
// BUILD MUS : grant access to shares
function buildMUSuser_shares(user, index) {
	var idsharesbtn = "MUSsharesbtn"+index;			// container with the shares
	var idshareslabel = "MUSsharesLabel"+index;
	var nameselectflags = "MUSflags"+index;
	if (user == "") {		// new user
		idsharesbtn = mus_idAddSharesBtn;
		idshareslabel = mus_idAddSharesLabel;
		nameselectflags = mus_idAddSharesFlag;
	}
	var html = '';
	html += '<div name="MUSshares" class="floatL">';
	html += '<table>';
	html += '<tr><td>';
	// 	1.	show button "grant access to shares"
	var buttonClass = "multiUserSupportToggleButtonBackground";
	html += '<a onclick="showMUSshares(' + idsharesbtn + ',' + idshareslabel + ')" >\
			<div class="' + buttonClass + '">\
			<div class="multiUserSupportToggleText" >' + getString("accesstoshares") + '</div>\
			<div id="' + idsharesbtn + '" class="multiUserSupportToggleButton hidden"></div>\
			</div>\
			<div class="toggleSpacer"></div></a>';
	html += '</td></tr><tr><td>';
	// 	2.	show the shares
	html += '<div id="' + idshareslabel + '" class="musBox hide floatL">';
	if (multiUserSupport["locationuserlist"][0] == "") {
		// no shares
		html += '<span class="multiUserSupportTextColor">' + getString("nocontentshared") + '</span>';
	} else {
		// first entry is "all" followed by the shares
		var checked = isUserAssignedToAllLocations(user);	// all-checkbox is checked if user is assigned to all shares
		html += '<input type="checkbox" id="MUSallFlag' + index + '" value="allshares" ' +
				checked + ' onclick="clickAllShares(\'' + nameselectflags + '\',\'MUSallFlag' + index + '\')" >';
		html += '<span class="multiUserSupportTextColor">' + getString("allshares") + '</span>';
		html += '<br>';
		var allshares = multiUserSupport["locationuserlist"][0].split("\n");
		for (var i=0;i<allshares.length;i++) {
			if (allshares[i] == "") continue;
			var share = allshares[i].split(";");
			var sharename = Base64.decode(share[0]);	// share is restricted
			checked = isUserAssignedToLocation(user, share[1]);
			html += '<input type="checkbox" name="' + nameselectflags + '" value="' + sharename + '" ' +
					checked + ' onclick="clickShares(\'' + nameselectflags + '\',\'MUSallFlag' + index + '\')" >';
			html += '<span class="multiUserSupportTextColor">' + sharename + '</span>';
			html += '<br>';
		}
	}
	html += '</div>';
	html += '</td></tr>';
	html += '</table>';
	html += '</div>';
	return html;
}
// is a user assigned to all locations
// user: user
// return "checked" if true, else an empty string
function isUserAssignedToAllLocations(user) {
	var allshares = multiUserSupport["locationuserlist"][0].split("\n");
	for (var i=0;i<allshares.length;i++) {
		if (allshares[i] == "") continue;
		var share = allshares[i].split(";");
		if (isUserAssignedToLocation(user, share[1]) == "") // user is not assigned to this location
			return "";
	}
	return "checked";
}
// is the user assigned to a location
// user: user
// assignedUsers: user assigned to a location as comma separated list
// return "checked" if true, else an empty string
function isUserAssignedToLocation(user, assignedUsers) {
	var userlist = assignedUsers.split(",");
	for (var i=0;i<userlist.length;i++) {
		if (userlist[i] == user) return "checked";
	}
	return "";
}
// check or uncheck all shares of a user
// inputShareName: name of the locations (location input fields)
// allShareId: id of the location entry field "All"
function clickAllShares(inputShareName, allShareId) {
	var shares = document.getElementById(allShareId);
	var checked = (shares.checked) ? "checked" : "";
	shares = document.getElementsByName(inputShareName);
	for (var i=0;i<shares.length;i++) {
		shares[i].checked = checked;
	}
}
// if all shares are selected select also share "all"
// if one share was deselected deselect alos share "all"
// inputShareName: name of the locations (location input fields)
// allShareId: id of the location entry field "All"
function clickShares(inputShareName, allShareId) {
	var checkedShares = 0;
	var shares = document.getElementsByName(inputShareName);
	for (var i=0;i<shares.length;i++) {
		if (shares[i].checked) checkedShares ++;
	}
	var allShare = document.getElementById(allShareId);
	if (checkedShares == shares.length) 
		allShare.checked = "checked";		// all shares are checked -> check the share "All"
	else
		allShare.checked = "";				// not all shares are checked -> uncheck the share "All"
}
// set password
function showChangeMUSpassword(idbtn, idpwd) {
	// button "set password" was pressed. 
	// Show entry field to enter a new password and two buttons - ok and cancel.
	$(idbtn).removeClass("show");
	$(idbtn).addClass("hide");	
	$(idpwd).removeClass("hide");	
	$(idpwd).addClass("show");	
}
function setMUSpassword(idbtn, idlabel, idpwd, user) {
	// "set password" - button "ok" was pressed:
	// Set the new password.
	// set setpwd to 1 to save the password later
	if (user == "admin") {			// admin can not have an empty password
		var namepwd = "MUSpwd";														// save passwords
		var pwds = document.getElementsByName(namepwd);		
		if (pwds[0].value == "") {	// no password
			adminPasswordMissingMsgBox();
			return;
		}
	}
	$(idlabel).removeClass("show");	
	$(idlabel).addClass("hide");	
	var id = document.getElementById(idpwd);
	if (id.attributes["setpwd"].value == "0") id.attributes["setpwd"].value = "1";
	$(idbtn).removeClass("hide");	
	$(idbtn).addClass("show");	
}
function cancelMUSpassword(idbtn, idlabel, idpwd) {
	// "set password" - button "cancel" was pressed. 
	// Cancel the action and do not set a new password.
	$(idlabel).removeClass("show");	
	$(idlabel).addClass("hide");	
	var id = document.getElementById(idpwd);
	id.value = "";		// clear the entry field
	if (id.attributes["setpwd"].value == "1") id.attributes["setpwd"].value = "0";
	$(idbtn).removeClass("hide");	
	$(idbtn).addClass("show");	
}
// delete a user from the user list
// attributes["adduser"] in HTML-element "MUSuserN" (N=user in the row N; N >= 2)
// adduser = 0 -> user from userlist
// adduser = 1 -> user is new
// adduser = 2 -> user is removed
// adduser = 8 -> remove user
// adduser = 9 -> remove a new user
function deleteMUSuser(index) {
	remove_user_fromUserlist(index);
	onEventChange();		// activate the save button at the bottom of the page
	// hide the row on the screen
	var containerID = "multiUserSupportUserList" + index;
	var id = document.getElementById(containerID);
	$(id).addClass("hide");	
	// set the user as removed
	var iduser = mus_idUser + index;
	id = document.getElementById(iduser);
	if (id.attributes["adduser"].value == "0") id.attributes["adduser"].value = "8";	// user removed
	else id.attributes["adduser"].value = "9";	// new user was removed - save nothing when the save-button is pressed
	// do not save the password if the save button is pressed
	var idpwd = mus_idPwd + index;
	id = document.getElementById(idpwd);
	id.attributes["setpwd"].value = "0";
}
// show/hide the shares
function showMUSshares(idbtn, idshares) {
	// combo box button "access to restricted shares" was pressed. 
	// show the shares
	if ($(idshares).hasClass("hide")) {
		$(idbtn).removeClass("hidden");
		$(idshares).removeClass("hide");	
		$(idshares).addClass("show");	
	} else {
		$(idbtn).addClass("hidden");
		$(idshares).removeClass("show");	
		$(idshares).addClass("hide");	
	}
}


// functions to update the userlist
// - add user to list
// - remove user from list
// structure: user1=role1,role2\nuser2=role1\n...
function add_user_toUserlist(user) {
	// add user to the userlist with the default role: username=defaultRole\n
	if (isUserUnique(user)) {	
		if (multiUserSupport["userlist"][0] == "") multiUserSupport["userlist"][0] += user;
		else multiUserSupport["userlist"][0] += "," + user;
		return true;
	} else {
		showDialogOverlay(function(){
			return getString("userexists")
		}, {}, [{
			text: getString("ok"),
			onclick: "hideDialogOverlay();"
		}]);
	}
	return false;
}
function remove_user_fromUserlist(index) {
	// delete a user from the user list
	var newList = "";
	var userlist = multiUserSupport["userlist"][0].split(",");
	var delIndex = index - firstUserDefinedUserIndex;	// in the list are the default users and the definded users
	for (var i=0;i<userlist.length-1;i++) {
		if (i != delIndex) {
			if (newList == "") newList += userlist[i];
			else newList += "," + userlist[i];
		}
	}
	multiUserSupport["userlist"][0] = newList;
}

// refresh the userlist on the screen
function refreshScreen_userlist() {
	var id = document.getElementById("userlistMainContainer");
	buildMUSuser($(id), multiUserSupport["userlist"]);
}


function isUserUnique(name) {
	// check default user names
	var alllist = multiUserSupport["multiusersupportdefaults"];
	var alldefaults = alllist.split(";");
	for (var i=0; i<alldefaults.length; i=i+1) {
		var oneuser = alldefaults[i].split(":");
		if (getString(oneuser[0]) == name) return false;
		if (oneuser[0] == name) return false;
	}
	// check user defined user names
	if (multiUserSupport["userlist"][0] == "") return true;
	var lines = multiUserSupport["userlist"][0].split(",");
	for (var i=0; i<lines.length; i++) {
		if (lines[i] == name) return false;
	}
	return true;
}

// return an user array
// return: user[0]="admin", user[1]="guest", user[2]="USER1", user[3]="USER2",...
function get_user_array(defaultUser, definedUser) {
	// defaultUser = from the server ini file
	// definedUser = user defined by the admin
	var user = new Array();
	var userIndex = 0;
	// multiusersupportdefaults: defUser1:defPwd1:defRole1;defUser2:defPwd2:defRole2;...
	var defusers = defaultUser.split(";");
	for (var i=0; i<defusers.length; i=i+1) {
		var oneuser = defusers[i].split(":");
		user[userIndex] = getString(oneuser[0]);
		userIndex = userIndex + 1;
	}
	//firstDefinedUserIndex = userIndex;
	if (definedUser[0] == "") return user;		// no defined user
	var userlist = definedUser[0].split(",");
	for (var i=0; i<userlist.length; i++) {
		user[userIndex] = userlist[i];		// user name
		userIndex = userIndex + 1;
	}	
	return user;
}


// return an array with user name, password and role of one default user
// format of multiusersupportdefaults: admin:admin:admin;guest::guest (<default user name>:>default user password>:<default user role>)
function getDefaultUserPwd(index) {
	var defusers = new Array();
	var alllist = multiUserSupport["multiusersupportdefaults"];
	defusers = alllist.split(";");
	if (index < defusers.length) {		// default user defined
		var user = defusers[index].split(":");
		return user;
	}
	return "";
}
function getAttributeValue(child, attributeName) {
	if (child.attributes == null) return "";
	for (var j = 0; j < child.attributes.length; j++) {
		if (child.attributes[j].name == attributeName)
			return child.attributes[j].value;
	}
	return "";
}
function adminPasswordMissingMsgBox() {
	showDialogOverlay(function(){
		return getString("musadminpwdempty");
	}, {}, [{
		text: getString("ok"),
		onclick: "hideDialogOverlay();"
	}]);
}
function wasAdminPasswordSet() {
    var MUSEnabledCheckbox = $("#multiUserSupportEnabledCheckbox");
    var enableMUS = ((MUSEnabledCheckbox.is(":checked")) ? (1) : (0));
	if ((multiUserSupportOrig["multiusersupportenabled"] == 0) && (enableMUS == 1)) {
		var password = $("#password", ".accountSettingsContainer").val();
		if (password == "") {
			adminPasswordMissingMsgBox();
			return false;
		}
	} 
	return true;
}

// submit Multi User - save the changes
function submitMultiUserSupportData() {
	if (!changesMade) return;
	if (!wasAdminPasswordSet()) return;
	
	var data = "";
    returnedCalls = 0;
    expectedCalls = 0;
	showLoadingGraphic();
	hideActionButtons();
	resetChanged();

	// Multi User Support flag
    var MUSEnabledCheckbox = $("#multiUserSupportEnabledCheckbox");
    var enableMUS = ((MUSEnabledCheckbox.is(":checked")) ? (1) : (0));
	// a) enable multi user support: 
	//	  1. save the multi user flag (multiusersupportenabled)
	//	  2. set default username/password (accessuser, accesspwd)
	//	  3. set the "use https" flag (multiuserusehttps)
	if ((multiUserSupportOrig["multiusersupportenabled"] == 0) && (enableMUS == 1)) {
		expectedCalls = 1;		// save multi user support flag
		// a.1) save the flag
		data = "multiusersupportenabled=1" + "\n";
		// a.2) set default username/password
		var username = "accessuser=" + $("#username", ".accountSettingsContainer").html();
		var password = "accesspwd=" + $("#password", ".accountSettingsContainer").val();
		data += username + "\n" + password + "\n";
		// a.3) set multiuseruserhttp flag (use http or https)
		var enableHttpsCheckbox = $("#multiUserUseHttpsEnabledCheckbox");
		var enableHttps = ((enableHttpsCheckbox.is(":checked")) ? (1) : (0));
		data += "multiuserusehttps=" + enableHttps + "\n";
		multiUserSupportEnabled = true;
		makePostRequest("/rpc/set_all", {}, data, function(){
			returnedCalls++;
			restartServer();
			//setReloadSide = true;
			//finishSaving();
		});
		return;	// return - there is nothing else to save
	}
	// b) disable multi user support: 
	//	  1. add new user and remove user 
	//	  2. save the user passwords 
	//    3. save the restricted locations
	//	  4. save users which have access to "all" shares
	//	  5. save the flag
	if ((multiUserSupportOrig["multiusersupportenabled"] == 1) && (enableMUS == 0)) {
		// hide the subheader User on the Multi User Support Page
		saveFlag = true;		// save multi user support flag, user and roles
		multiUserSupportEnabled = false;
	}
	// b.1 - increment the counter expectedCalls for every new user
	if ($("#MUSnewUser").hasClass("show")) addNewMUSuserBeforeSubmit();			// add the new user if the user was not saved yet
	var nameuser = "MUSuser";													// save users
	var users = document.getElementsByName(nameuser);
	for (var i=2;i<users.length;i++) {			// 0=admin, 1=guest
		if (users[i].attributes["adduser"].value == "1") expectedCalls ++;		// new user (rpc/add_user)
		if (users[i].attributes["adduser"].value == "8") expectedCalls ++;		// user removed (rpc/del_user
	}
	// b.2 - increment the counter expectedCalls for every changed password
	var namepwd = "MUSpwd";														// save passwords
	var pwds = document.getElementsByName(namepwd);
	for (var i=1;i<pwds.length;i++) {			// not the admin password at index=0
		if (pwds[i].attributes["setpwd"].value == "1") expectedCalls ++;		// set new password
	}
	
	// b.3 - increment the counter
	expectedCalls++;		// save the restricted locations of the users
	// b.4 - increment the counter
	expectedCalls++;		// user list with users which have access to all shares
	// b.1) add new user and remove user
	// attributes["adduser"] in HTML-element "MUSuserN" (N=user in the row N; N >= 2)
	// adduser = 0 -> user from userlist
	// adduser = 1 -> user is new
	// adduser = 2 -> user is removed
	// adduser = 8 -> remove user
	// adduser = 9 -> remove a new user
	for (var i=2;i<users.length;i++) {							// 0=admin, 1=guest
		if (users[i].attributes["adduser"].value == "1") {		// add user
			var data1 = "user=" + users[i].value;
			data1 += "&password=" + pwds[i].value;
			makePostRequest2("/rpc/add_user?"+data1, {}, "", function(response, parameter){
				if (response != "ok") setSaveUserFailed(parameter);
				returnedCalls++;
				if (returnedCalls == expectedCalls) {
					finishSavingUserAndRoles();
				}
			}, function(parameter) {
				returnedCalls++;
				setSaveUserFailed(parameter);
				if (returnedCalls == expectedCalls) {
					finishSavingUserAndRoles();
				}			
			});		
		}
		if (users[i].attributes["adduser"].value == "8") {		// remove user
			var data2 = "user=" + users[i].value;
			makePostRequest2("/rpc/del_user?"+data2, {}, "", function(response, parameter){
				if (response != "ok") setSaveUserFailed(parameter);
				returnedCalls++;
				if (returnedCalls == expectedCalls) {
					finishSavingUserAndRoles();
				}
			}, function(parameter) {
				returnedCalls++;
				setSaveUserFailed(parameter);
				if (returnedCalls == expectedCalls) {
					finishSavingUserAndRoles();
				}			
			});		
		}
	}
	var id = document.getElementById(mus_idAddUser);
	id.value == "";			// clear the field
	
	// b.2) save user passwords (not the admin password)
	// b.2.1) save admin password later
	var idpwdold = "MUSpwdold";
	setAdminPwd = "";
	if (pwds[0].attributes["setpwd"].value == "1") {
		setAdminPwd = "user=" + users[0].value + "&newpassword=" + pwds[0].value;
		var id = document.getElementById(idpwdold+"0");
		if (id) {
			setAdminPwd += "&oldpassword=" + id.value;
			id.value = "";
		}
	}
	pwds[0].attributes["setpwd"].value = "0";	// clear the flag "setpwd"
	pwds[0].value = "";							// clear the password
	// b.2.2) save the user password
	var nameuser = "MUSuser";
	for (var i=1;i<pwds.length;i++) {			// not the admin password at index=0
		if (pwds[i].attributes["setpwd"].value == "1") {
			var newpwd = pwds[i].value;			// read the password
			var user = users[i].value;
			var data3 = "user=" + user + "&newpassword=" + newpwd;
			var id = document.getElementById(idpwdold+i);
			if (id) {
				data3 += "&oldpassword=" + id.value;
				id.value = "";
			}
			// change password of users except user admin
			pwds[i].attributes["setpwd"].value = "0";	// clear the flag "setpwd"
			pwds[i].value = "";							// clear the password
			makePostRequest2("/rpc/set_user_password?"+data3, {}, "", function(response, parameter){
				if (response != "ok") setSavePWDFailed(parameter);
				returnedCalls++;
				if (returnedCalls == expectedCalls) {
					finishSavingUserAndRoles();
				}
			}, function(parameter) {
				returnedCalls++;
				setSavePWDFailed(parameter);
				if (returnedCalls == expectedCalls) {
					finishSavingUserAndRoles();
				}			
			});	
		}
	}
	// b.3) save the locations assigned to user
	// build a user list with users having access to all shares - b.4
	var loclist = buildEmptyLocationList();		// build a location list with all restricted locations and the default user admin
	var nameuser = "MUSuser";
	var nameshare = "MUSflags";
	var nameallshare = "MUSallFlag";
	var firstIndex = 1;				// first user is admin, start with guest
	
	// userlist with users which have access to all shares
	var userlistAllshares = "admin";			// list of all users (except admin and guest)
	var firstIndexAllShares = 2;	// first user is admin, second guest, start with the first defined user
	
	for (var i=firstIndex;i<users.length;i++) {
		if ((users[i].attributes["adduser"].value == "0") || (users[i].attributes["adduser"].value == "1")) {
			// add user to the location list
			var user = users[i].value;								// user
			var flagname = nameshare+i;
			var locflags = document.getElementsByName(flagname);
			for (var j=0;j<locflags.length;j++) {
				var loc = locflags[j].value;						// location
				var locFlag = (locflags[j].checked) ? 1 : 0;
				addUserToLocation(user, loc, locFlag, loclist);		// add the user to the location
			}
			// add user to the user list if he has access to all shares
			if ((i >= firstIndexAllShares) && (locflags.length > 0)) {
				var allflag = document.getElementById(nameallshare + i);
				if (allflag.checked) userlistAllshares += "," + users[i].value;
			}
		}
	}
	if (loclist.length > 0) {
		var newlocationuserlist = "";
		for (var i=0;i<loclist.length;i++) {
			newlocationuserlist += loclist[i] + "\n";
		}
		makePostRequest2("/rpc/set_location_user_list", {}, newlocationuserlist, function(response, parameter){
			if (response != "ok") saveLocationFailed = true;
			else {
				multiUserSupport["locationuserlist"][0] = newlocationuserlist;
				multiUserSupportOrig["locationuserlist"][0] = newlocationuserlist;
			}
			returnedCalls++;
			if (returnedCalls == expectedCalls) {
				finishSavingUserAndRoles();
			}
		}, function(parameter) {
			returnedCalls++;
			saveLocationFailed = true;
			if (returnedCalls == expectedCalls) {
				finishSavingUserAndRoles();
			}			
		});		
	} else {
		returnedCalls++;
	}

	// b.4) save users which have access to "all" shares
	makePostRequest2("/rpc/set_user_list_for_managed_folders", {}, userlistAllshares, function(response, parameter){
		returnedCalls++;
		if (returnedCalls == expectedCalls) {
			finishSavingUserAndRoles();
		}
	}, function(parameter) {
		returnedCalls++;
		if (returnedCalls == expectedCalls) {
			finishSavingUserAndRoles();
		}			
	});		
	
	// clean up screen
	// set the flag removed users (adduser=2)
	// reset the flag user (adduser=0)
	// reset the flag password (setpwd=0)
	// clear the password input field
	for (var i=1;i<users.length;i++) {						// 0=admin, 1=guest, 2..=defined user
		if (users[i].attributes["adduser"].value == "2") continue;		// user is removed
		if ((users[i].attributes["adduser"].value == "8") || (users[i].attributes["adduser"].value == "9"))
			users[i].attributes["adduser"].value = "2";		// set: user is removed
		else
			users[i].attributes["adduser"].value = "0";		// reset flag user
		pwds[i].attributes["setpwd"].value = "0";			// reset flag password
		pwds[i].value = "";									// reset password
	}
			
	if (returnedCalls == expectedCalls) {
		finishSavingUserAndRoles();		// b.4) save flag
	}
}
// can not change the user password. add the user name to the string savePWDFailedString.
// parameter: <url>?user=<username>&newpassword=<pwd>&oldpassword=<pwd>
function setSavePWDFailed(parameter) {
	savePWDFailed = true;
	var p = "";
	try {
		var i1 = parameter.indexOf("?");
		if (i1 > 0) p = parameter.substring(i1+1, parameter.length);
		var onep = p.split("&");
		if (onep.length < 1) return;
		for (var i=0;i<onep.length;i++) {
			var pair = onep[i].split("=");
			if (pair.length == 2) {
				if (pair[0] == "user") 
					if (savePWDFailedString == "") savePWDFailedString = pair[1];
					else savePWDFailedString += ", " + pair[1];
			}
		}
    } catch (e) {
    }
}
// can not add or remove the user. add the user name to the string saveUserFailedString.
// parameter: <url>?user=<username>&password=<pwd>
function setSaveUserFailed(parameter) {
	saveUserFailed = true;
	var p = "";
	try {
		var i1 = parameter.indexOf("?");
		if (i1 > 0) p = parameter.substring(i1+1, parameter.length);
		var onep = p.split("&");
		if (onep.length < 1) return;
		for (var i=0;i<onep.length;i++) {
			var pair = onep[i].split("=");
			if (pair.length == 2) {
				if (pair[0] == "user") 
					if (saveUserFailedString == "") saveUserFailedString = pair[1];
					else saveUserFailedString += ", " + pair[1];
			}
		}
    } catch (e) {
    }
}
// build an empty location list with the restricted locations and the default user admin
// format of the location list: location1;admin\nlocation2;admin\n ...
function buildEmptyLocationList() {
	// the first user in multiusersupportdefaults is the default user which has always access to all shares
	var firstuser = getDefaultUserPwd(0);
	var defUser = firstuser[0];			// default user name = admin
	// build a new location list
	var ll = new Array();
	var locs = multiUserSupport["locationuserlist"][0].split("\n");
	for (var i=0;i<locs.length;i++) {
		if (locs[i] == "") continue;
		var loc = locs[i].split(";");
		// add the restricted share and the default user admin to the location list
		ll.push(loc[0]+";"+defUser);	// format: location;default user
	}
	return ll;
}
// add users to the location list
// format of the location list: location1;admin,user1,user2\nlocation2;admin,user2\n ...
function addUserToLocation(user, loc, locFlag, ll_in) {
	var ll = ll_in;
	if (locFlag == 0) return ll;
	for (var i=0;i<ll.length;i++) {
		var loc_user = ll[i].split(";");
		var l = Base64.decode(loc_user[0]);
		if (l == loc) {						// add user to location
			if (loc_user[1] == "")	
				loc_user[1] = user;			// first user for this location (first user should be always admin)
			else
				loc_user[1] += ","+user;	// not first user for this location
			ll[i] = loc_user[0] + ";" + loc_user[1];
			return ll;
		}
	}
	return ll;
}
function finishSavingUserAndRoles() {
	// save multi user admin password
	if (setAdminPwd == "") {
		finishSavingUserAndRoles2();
	} else {	
		makePostRequest2("/rpc/set_user_password?"+setAdminPwd, {}, "", function(response, parameter){
			if (response != "ok") setSavePWDFailed(parameter);
			finishSavingUserAndRoles2();
		}, function(parameter) {
			setSavePWDFailed(parameter);
			finishSavingUserAndRoles2();
		});			
	}
}
function finishSavingUserAndRoles2() {
	if (saveFlag) {
		// save multi user support flag 
		var data = "multiusersupportenabled=0" + "\n";
		// disable https
		data += "multiuserusehttps=0" + "\n";
		multiUserSupport["multiusersupportenabled"] = 0;
		multiUserSupportOrig["multiusersupportenabled"] = 0;
		makePostRequest2("/rpc/set_all", {}, data, function(response, parameter){
			hideLoadingGraphic();
			finishDisableMultiUser();
		}, function(parameter) {
			hideLoadingGraphic();
			finishSaving();
		});		
	} else {
		requestFailed();
		hideLoadingGraphic();
		finishSaving();
		setMUSFocus(mus_idAddUser);
	}
}
function requestFailed() {
	if (saveLocationFailed || saveUserFailed || savePWDFailed || saveDeviceUserFailed || saveViewsFailed) {
		var msg = "";
		if (saveUserFailed) {
			msg += getString("mussaveerroruser") + ' ' + saveUserFailedString + '.' + '<br>';
		}
		if (savePWDFailed) {
			msg += getString("mussaveerrorpwd") + ' ' + savePWDFailedString + '.' + '<br>';
		}
		if (saveLocationFailed) {
			msg += getString("mussaveerrorlocation") + '<br>';
		}
		if (saveDeviceUserFailed) {
			msg += getString("mussaveerrordevices") + '<br>';
		}
		if (saveViewsFailed) {
			msg += getString("mussaveerrorviews") + ' ' + saveViewsFailedString + '.' + '<br>';
		}
		showDialogOverlay(function(){
			return msg;
		}, {}, [{
			text: getString("ok"),
			onclick: "hideDialogOverlay();reloadSide();"
		}]);			
	}
}
function finishDisableMultiUser() {
    showActionButtons();
	showDialogOverlay(function(){
		return getString("musdisablemessage");
	}, {}, [{
		text: getString("ok"),
		onclick: "restartServer();"
	}]);			
	
}

function finishSaving(){
    if (returnedCalls == expectedCalls) {
        showActionButtons();
        makeGetRequest("/rpc/info_status", {}, function(data, parameter){
            var dataPieces = data.split("\n");
            $.each(dataPieces, function(i, value){
                var pieces = value.split("|");
                if (pieces[0] == "restartpending") {
                    var restartPending = (pieces[1] == 1);
                    if (restartPending) {
                        showDialogOverlay(function(){
                            return getString("restartprompt")
                        }, {}, [{
                            text: getString("ok"),
                            onclick: "restartServer();"
                        }, {
                            text: getString("cancel"),
                            onclick: "hideDialogOverlay();"
                        }]);
                    } else {
						if (setReloadSide) reloadSide();
						setReloadSide = false;				
					}
                    return false;
                } 
            });
        });
    }
}


// ------------------------
// advanced page
// ------------------------
function loadAdvanced(){
    returnedCalls = 0;
    expectedCalls = 5;
    saveHandler = "submitAdvancedData();"
	inputFieldClicked = false;
    changesMade = false;

	showLoadingGraphic();
    
    // function get_server_type restored - should be retired again.
	makeGetRequest("/rpc/get_server_type", {}, function(response, parameter){
		advanced["servertype"] = response;
		returnedCalls++;
		if (expectedCalls == returnedCalls) {
            loadAdvancedHtml();
			hideLoadingGraphic();
		}
	});
	
	makeGetRequest("/rpc/get_all", {}, function(response, parameter){
        parseSeparatedData(response, advanced, advancedOrig, "=");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadAdvancedHtml();
			hideLoadingGraphic();
        }
    });

    makeGetRequest("/rpc/info_status", {}, function(response, parameter){
		parseSeparatedData(response, advanced, advancedOrig, "|");
		// advanced["servertype"] = getServerType(advanced["licensestatus"]);
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadAdvancedHtml();
			hideLoadingGraphic();
        }
    });

	makeGetRequest("/rpc/get_music_genres", {}, function(response, parameter){
		advanced["music_genres"] = response;
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadAdvancedHtml();
			hideLoadingGraphic();
        }
    });

    makeGetRequest("/rpc/info_views", {}, function(response, parameter){
		parseSeparatedData(response, advanced, advancedOrig, "|");
        returnedCalls++;
        if (expectedCalls == returnedCalls) {
            loadAdvancedHtml();
			hideLoadingGraphic();
        }
    });
}

function loadAdvancedHtml(){
    makeGetRequest("/webconfig/advanced.htm", {}, function(response, parameter){
        var responseHtml = $(response);
        replaceStrings(responseHtml);
        replaceData(responseHtml, advanced, handleAdvancedData);
		showToggleButtons(responseHtml);
        
        $(".serverSettingsContentWrapper").html(responseHtml);
		// with multi user support enabled disable username and password on the advanced page
		// add property disabled="true" 
		if (advanced["multiusersupportenabled"] == "1") {
			var id = document.getElementById("username");
			id.disabled = true;
			id = document.getElementById("password");
			id.disabled = true;
			id = document.getElementById("multiuserenabledsecure");
			$(id).removeClass("hide");
		}
		// "By folder" Navigation
		// enable/disable the checkbox "show the file extension"
		useFilenameChanged();
		// show the file extension 1=no, 2=yes
		if (advanced["usefilenameinfolderview"] == "1")
			$("#showfilenameextensionCheckbox").attr("checked", false);
		if (advanced["usefilenameinfolderview"] == "2")
			$("#showfilenameextensionCheckbox").attr("checked", true);
		
        $("input", "#advancedContainer").live("click", onEventClick);
        $("input,select", "#advancedContainer").live("change", onEventChange);
        highlightNav($("#nav_advanced"));
		if (advanced["viewsready"] == 0) {
			// start timer and refresh the audiobook genres
			updateTimer = setTimeout(updateAdvancedData, updateTimerIntervalAdvanced);
		} else {
			// hide the message that the server is scanning for genres (Scanning for genres - In Progress...)
			var id = document.getElementById("updatingmusicgenres");
			id.style.display = "none";
		}			
    });
}

// the option usefilenameinfolderview changed. enable/disable the checkbox "show the file names with file extension"
function useFilenameChanged() {
	if ($("#usefilenameinfolderviewCheckbox").attr("checked") == true)
		$("#showfilenameextensionCheckbox").attr("disabled", false);
	else {
		$("#showfilenameextensionCheckbox").attr("disabled", true);
		$("#showfilenameextensionCheckbox").attr("checked", false);
	}
}

function handleAdvancedData(element, key, data){
	var serverType = advanced["servertype"];
    switch (key) {
		case "accessuser":
			element.val(data);
			break;
        case "accesspwd":
			if (data.length > 0) element.val("_twonkypassword_");
			break;
		case "myexperiencecheckbox":
			// Improve my experience by allowing Twonky Server to share information in accordance with the Twonky Data Collection Policy.
			var reporting = (advanced["enablereporting"] != "0") ? ("checked") : ("");
			var pbreporting = getString("playbackbeamreportingcaption");
			pbreporting = pbreporting.replace("Twonky Data Collection Policy", "<a class=\'inlineLink\' href=\'" + statusData["privacypolicy"] + "\' target=\'_blank\'>Twonky Data Collection Policy</a>");
			returnValue = '<input id="pbreportingCheckbox" type="checkbox" ' + reporting + ' /><span>' + 
			pbreporting +
			'</span>\
			<div class="serverContentSpacer"></div>';
			element.html(returnValue);
			break;
        case "compilationsdir":
		case "ignoredir":
        case "scantime":
            element.val(data);
            break;
		case "audiobookgenres":
			// show a genre list which shall be taken as audiobooks
			var html = '<div>';
			html += buildAudiobookGenres(data);
			html += '<div class="clear"></div></div>';
			element.html(html);
			break;
		case "usefilenameinfolderview":
		case "nicrestart":
		case "v":
            element.attr("checked", data > 0)
            break;
	}
}

// build checkboxes for each music genre and check the genre if it is taken as audiobook
var namegenre = "audiobookGenres";
function buildAudiobookGenres(data) {
	var html = "";
	// put the music and audiobook genres into an array
	var aGenres = data.split(",");
	var mGenres = advanced["music_genres"].split(",");
	var genres = aGenres.concat(mGenres);
	genres.sort();			// sort the genres
	var checked = "";
	for (var i=0;i<genres.length;i++) {
		if (genres[i].length < 1) continue;
		if (genreIsAudiobook(genres[i], data)) {
			checked = "checked";
		} else {
			checked = "";
		}
		if (genres[i] == "Audiobook") {
			// only in Twonky 8.1 - default type audiobook is disabled and cannot be changed (deselected) 
			html += '<div class="floatL" style="width:150px;margin-right:10px">';
			html += '<input type="checkbox" name="' + namegenre + '" onclick="audiobookGenreClicked()" value="' + genres[i] + '" ' + checked + ' disabled >' + genres[i];
			html += '</div>';
		} else {
			html += '<div class="floatL" style="width:150px;margin-right:10px">';
			html += '<input type="checkbox" name="' + namegenre + '" onclick="audiobookGenreClicked()" value="' + genres[i] + '" ' + checked + ' >' + genres[i];
			html += '</div>';
		}
	}
	return html;
}
// check if the genre is already taken as audiobook.
function genreIsAudiobook(genre, audiobookGenres) {
	var aGenres = audiobookGenres.split(",");
	for (var i=0;i<aGenres.length;i++) {
		if (aGenres[i] == genre) return true;
	}
	return false;
}


// as long as the navigation tree is under construction the viewsready status flag is 0
// update the subheader audiobook genres as long as the viewsready-status is 0
function updateAdvancedData(){
	makeGetRequest("/rpc/info_views", {}, function(response, parameter){
		parseSeparatedData(response, advanced, advancedOrig, "|");
		makeGetRequest("/rpc/get_music_genres", {}, function(response, parameter){
			advanced["music_genres"] = response;
			updateAudiobookGenres($("[key=audiobookgenres]"), advanced["audiobookgenres"])
			if (advanced["viewsready"] == 0) {
				// start timer and refresh the audiobook genres
				updateTimer = setTimeout(updateAdvancedData, updateTimerIntervalAdvanced);
			} else {
				// hide the message that the server is scanning for genres (Scanning for genres - In Progress...)
				var id = document.getElementById("updatingmusicgenres");
				id.style.display = "none";
			}			
		});
	});
}
// stop updating the audiobook genres if the user clicked on a genre 
// to select or deselect it as audiobook genre
function audiobookGenreClicked() {
	clearTimeout(updateTimer);	
	var id = document.getElementById("updatingmusicgenres");
	id.style.display = "none";
}
// update the list with the audiobook genres
function updateAudiobookGenres(element, data) {
	var html = '<div>';
	html += buildAudiobookGenres(data);
	html += '<div class="clear"></div></div>';
	element.html(html);
}

function clearPassword() {
	$("#password").val("");
}

function submitAdvancedData(){
	if (!changesMade) return;
	var accessCredentialChanged = false;
    hideActionButtons();
    returnedCalls = 0;
    expectedCalls = 1;

	showLoadingGraphic();
    resetChanged();

    var compilations = $("#compilations", ".accountSettingsContainer").val();
    var ignoredir = $("#ignoredirs", ".accountSettingsContainer").val();
    var usefilenameinfolderview = (($("#usefilenameinfolderviewCheckbox").attr("checked") == true) ? ("1") : ("0"));
	if (usefilenameinfolderview == 1) {
		// if use filenames in folder view with filename extensions: usefilenameinfolderview = 2 
		usefilenameinfolderview = (($("#showfilenameextensionCheckbox").attr("checked") == true) ? ("2") : ("1"));
	}
    var rescan = $("#rescan", ".accountSettingsContainer").val();
    var nicrestart = (($("#nicRestartEnabledCheckbox").attr("checked") == true) ? ("1") : ("0"));
	// reportdevice was replaced by enablereporting (since 7.1)
    //var myexperience = (($("#myExperienceEnabledCheckbox").attr("checked") == true) ? ("1") : ("0"));
    var reporting = (($("#pbreportingCheckbox").attr("checked") == true) ? ("15") : ("0"));
    var loggingEnabled = (($("#loggingEnabledCheckbox").attr("checked") == true) ? ("4095") : ("0"));
	// genres taken as audiobooks
	var genres = document.getElementsByName(namegenre);
	var audiobookGenres = "";			// no entry
	for (var j=0;j<genres.length;j++) {
		var genre = genres[j].value;	// genre
		if (genres[j].checked) {
			// add genre to the list of audiobook genres
			if (audiobookGenres == "") 
				audiobookGenres = genre;
			else 	
				audiobookGenres += "," + genre;
		}
	}
	 
	var data = "";
	if (advancedOrig["compilationsdir"] != compilations) {
		data += "compilationsdir=" + compilations + "\n";
		advanced["compilationsdir"] = compilations;
		advancedOrig["compilationsdir"] = compilations;
	}
	if (advancedOrig["ignoredir"] != ignoredir) {
		data += "ignoredir=" + ignoredir + "\n";
		advanced["ignoredir"] = ignoredir;
		advancedOrig["ignoredir"] = ignoredir;
	}
	if (advancedOrig["usefilenameinfolderview"] != usefilenameinfolderview) {
		data += "usefilenameinfolderview=" + usefilenameinfolderview + "\n";
		advanced["usefilenameinfolderview"] = usefilenameinfolderview;
		advancedOrig["usefilenameinfolderview"] = usefilenameinfolderview;
	}
	if (advancedOrig["scantime"] != rescan) {
		data += "scantime=" + rescan + "\n";
		advanced["scantime"] = rescan;
		advancedOrig["scantime"] = rescan;
	}
	if (advancedOrig["nicrestart"] != nicrestart) {
		data += "nicrestart=" + nicrestart + "\n";
		advanced["nicrestart"] = nicrestart;
		advancedOrig["nicrestart"] = nicrestart;
	}
	// reportdevice was replaced by enablereporting (since 7.1)
	//if (advancedOrig["myexperience"] != myexperience) data += "reportdevice=" + myexperience + "\n";
	if (advancedOrig["enablereporting"] != reporting) {
		data += "enablereporting=" + reporting + "\n";
		advanced["enablereporting"] = reporting;
		advancedOrig["enablereporting"] = reporting;
	}
	if (advancedOrig["v"] != loggingEnabled) {
		data += "v=" + loggingEnabled + "\n";
		advanced["v"] = loggingEnabled;
		advancedOrig["v"] = loggingEnabled;
	}
	if (advancedOrig["audiobookgenres"] != audiobookGenres) {
		data += "audiobookgenres=" + audiobookGenres + "\n";
		advanced["audiobookgenres"] = audiobookGenres;
		advancedOrig["audiobookgenres"] = audiobookGenres;
	}

	if (!($("#password", ".accountSettingsContainer").val() == "_twonkypassword_")) {
		var username = "accessuser=" + $("#username", ".accountSettingsContainer").val();
		var password = "accesspwd=" + $("#password", ".accountSettingsContainer").val();
		if (((username.length > 11) && (password.length > 10)) || ((username.length == 11) && (password.length == 10))) {
			// set new username password
			data += username + "\n" + password + "\n";
			accessCredentialChanged = true;
		} else {
			// reset username and password (only username or password was entered)
			$("#username").val(advancedOrig["accessuser"]);
			if (advancedOrig["accesspwd"].length > 0) $("#password").val("_twonkypassword_");
			else $("#password").val("");
			showDialogOverlay(function(){
				return getString("notchanged")
			}, {}, [{
				text: getString("ok"),
				onclick: "hideDialogOverlay();"
			}]);
		}
	}
	if (!(data == "")) {
		makePostRequest("/rpc/set_all", {}, data, function(){
			returnedCalls++;
			hideLoadingGraphic();
			if (accessCredentialChanged) {
				setReloadSide = true;
			}
			finishSaving();
	   });
	} else {
		returnedCalls++;
		hideLoadingGraphic();
		finishSaving();
	}
}


var restartTest;
function restartServer(){
    makeGetRequest("/rpc/restart", {}, function(){
        showDialogOverlay(function(){
            return "<div class='spinner floatL'></div><div style='padding: 5px 0px 0px 10px;' class='floatL'>" + getString("serverrestarting") + "</div>"
        }, {}, {});
        restartTest = setInterval(function(){
            makeGetRequest("/rpc/get_all", {}, function(response, parameter){
				//if (response == "") break;
                clearInterval(restartTest);
                hideDialogOverlay();
                // Update aggregation info after the restart is complete on the Aggregation page to display the list of servers more quickly.
                if (window.location.hash == '#aggregation') {
                    // Callback must be on a short timeout in order to work since rpc call needs a short amount of time to popuplate list of
                    //      aggregation servers after restarting, if call is done without timeout, response is still empty.
                    setTimeout("updateAggregation()", 1500);
                }
                if (window.location.hash == '#multiusersupport') {
					window.location.reload();
				}
            })
        }, 1000);
    });
}

function rescanFolders(){
    makeGetRequest("/rpc/rescan", {}, null);
}

//Display a dialog that prompts the user before completing a server reset.
function promptReset(){
    showDialogOverlay(function(){
        return getString("resetprompt");
    }, null, {
        1: {
            text: getString("ok"),
            onclick: "hideDialogOverlay(); resetServer()"
        },
        2: {
            text: getString("cancel"),
            onclick: "hideDialogOverlay()"
        }
    });
}

var resetTest;
function resetServer(){
    makeGetRequest("/rpc/reset", {}, function(){
        showDialogOverlay(function(){
            return "<div class='spinner floatL'></div><div style='padding: 5px 0px 0px 10px;' class='floatL'>" + getString("serverrestarting") + "</div>"
        }, {}, {});
		var t = setTimeout("waitingForServer()", 3000);
    });
}
function waitingForServer() {
	resetTest = setInterval(function(){
		makeGetRequest("/rpc/get_all", {}, function(response){
			if (response != "") {
				clearInterval(resetTest);
				setReloadSide = true;
				hideDialogOverlay();
			}
		})
	}, 2000);
}

function clearCache(){
    makeGetRequest("/rpc/clear_cache", {}, null);
}


var resetTest;
function resetClients(){
    makeGetRequest("/rpc/resetclients", {}, function(){
        showDialogOverlay(function(){
            return "<div class='spinner floatL'></div><div style='padding: 5px 0px 0px 10px;' class='floatL'>" + getString("clientreset") + "</div>"
        }, {}, {});
        resetTest = setInterval(function(){
            makeGetRequest("/rpc/get_all", {}, function(){
                clearInterval(resetTest);
                hideDialogOverlay();
                loadSharing();
            })
        }, 1000);
    });
}

function viewLog(){
    window.open("/rpc/log_getfile", "_blank");
}

function clearLog(){
    makeGetRequest("/rpc/log_clear", {}, null);
}

//Add the active class to a button when the mouse is pressed.
function onButtonMouseDown(button){
    var button = $(button);
    button.addClass("active");
}

//Remove the active class from a button when the mouse is released.
function onButtonMouseUp(button){
    var button = $(button);
    button.removeClass("active");
}

function cancelSettings(){
    resetChanged();
    $(window).trigger("hashchange");
}

function showActionButtons(){
    $("#actionButtonContainer").show();
    $("#spinnerContainer").hide();
}

function hideActionButtons(){
    $("#actionButtonContainer").hide();
    $("#spinnerContainer").show();
}

//Display a dialog overlay and opaque the background to prevent the user from interacting with the page until
//the dialog is closed.
//contentConstructor: The function to be called in order to populate the contents of the dialog.
//contentArgs: Arguments to be passed to the content constructor.
//buttons: A collection of buttons to include in the dialog. Buttons should be in the format {"text": text, "onclick":
//"onClickFunction()"}, where text is the text to be shown on the button and onclick is the function to be called
//when the button is clicked, expressed as a string ("onClickFunction()" rather than onClickFunction). 
function showDialogOverlay(contentConstructor, contentArgs, buttons, widthClass){
    var dialog = $("#dialogOverlay");
    if (dialog) {
        dialog.remove();
    }
    var body = $(document.body);
    var contentHtml = contentConstructor(contentArgs);
    var buttonHtml = makeButtons(buttons);
    var overlay = $("#overlay");
    if (overlay.length < 1) {
        body.append("<div id='overlay' class='overlay'></div>");
    }
    body.append('<div id="dialogOverlay" class="dialogWrapper ' + widthClass + '"> \
	<b class="dialogTop"><b class="d1"></b><b class="d2"></b><b class="d3"></b><b class="d4"></b></b> \
		<div class="dialogContentWrapper">\
			<div class="dialogContent">\
				' +
    contentHtml +
    '\
				<div class="dialogButtonContainer" id ="dialogButtonContainer">\
					' +
    buttonHtml +
    '\
				</div>\
				<div class="clear"></div>\
			</div>\
		</div>\
	<b class="dialogBottom"><b class="d4"></b><b class="d3"></b><b class="d2"></b><b class="d1"></b></b></div>');
    var dialog = $("#dialogOverlay");
    var dialogWidth = dialog.outerWidth();
    var left = (body.width() / 2) - (dialogWidth / 2);
    dialog.css("left", left);
    if (contentArgs && contentArgs.onstart) {
        contentArgs.onstart();
    }
}

//Iterate through the collection of buttons to produce the HTML for them.
//buttons: The collection of button objects.
function makeButtons(buttons){
    var buttonHtml = "";
	for (var key in buttons) {
		if (!buttons.hasOwnProperty(key)) {
			continue;
		}
        buttonHtml += '\
			<a class="actionbtnmd floatL" onclick="' + buttons[key].onclick + '" onmousedown="onButtonMouseDown(this)" onmouseup="onButtonMouseUp(this)">\
				<span class="actionbtn_l"></span>\
				<span class="actionbtn_c">' +
        buttons[key].text +
        '</span>\
				<span class="actionbtn_r"></span>\
			</a>';
    }
    return buttonHtml;
}

//Remove the dialog and opaque overlay.
function hideDialogOverlay(){
    var overlay = $("#overlay");
    overlay.remove();
    var dialog = $("#dialogOverlay");
    dialog.remove();
	if (setReloadSide) reloadSide();
	setReloadSide = false;
}

//A function to wrap retrieved JSON data in parentheses for eval-ing to prevent errors.
function parseJson(jsonData){
    return eval("(" + jsonData + ")");
}


function toggleContainer(clickedButton)
{
	var parent = clickedButton.parents(".boxHeader");
	var toggleElement = $(parent).next();
	var elementID = clickedButton.attr("id");
	if (toggleElement.css("display") == "none") {
		toggleElement.show();
		$(".toggleText", clickedButton).text(getString("hide"));
		clickedButton.removeClass("hidden");
		clickedButton.addClass("showing");
		document.cookie = elementID + "=show;";
	}
	else {
		toggleElement.hide();
		$(".toggleText", clickedButton).text(getString("show"));
		clickedButton.removeClass("showing");
		clickedButton.addClass("hidden");
		document.cookie = elementID + "=hide;";
	}
}
function showContainer(elementID) {
	document.cookie = elementID + "=show;";
}
