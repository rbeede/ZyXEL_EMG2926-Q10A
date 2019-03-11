/*
 * Copyright (c) 2014 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary
 */
////////////////////////////////////////////////////////////////////////
/*
    Function: loadScript

    Inject a script into the local DOM of the current function/html
    document.

    Parameters:
            strPathName - Name and path of the javascript to load

        Returns:
            nothing.

        See also:
            nothing.
*/
////////////////////////////////////////////////////////////////////////
function loadScript(strFilename)
{
    //add the javascript path to the file
    var strPathName = g_path.js + strFilename;

    $.ajaxSetup({async:false,cache: true});

    $.getScript(strPathName)
        .done(function(script, textStatus)
        {
            //console.log( textStatus );
        })
        .fail(function(jqxhr, settings, exception) {
            console.log( "unable to load script:" + strPathName);
        });

    $.ajaxSetup({async:true});
}

/*
    Variable: g_path

    Global variable to set up all the paths to assets.
    If these variables aren't all set correctly none of the
    flux library will work

    Library dependent paths:
    images      - web images
    js'         - javascript files
    css         - cascading style sheets
    ozker       - ozker api call path / append normal calls here
    cloud       - cloud images
    strings     - cloud strings and licenses
    lstrings    - local strings and licenses (when cloud isnt available and local only resources)
*/

var g_path = {
    'images'    : "/luci-static/resources/streamboost/images/",
    'js'        : "/js/",
    'css'       : "/css/",
    'ozker'     : "/cgi-bin/ozker",
    'cloud'     : "http://static.nbg6716.zyxel.streamboost.yeti.bigfootnetworks.com/luci-app-streamboost-assets/latest/luci-static/resources/streamboost/images/",
    'strings'   : "http://static.nbg6716.zyxel.streamboost.yeti.bigfootnetworks.com/luci-app-streamboost-assets/latest/luci-static/resources/streamboost/trans/",
    'resources' : "http://static.nbg6716.zyxel.streamboost.yeti.bigfootnetworks.com/luci-app-streamboost-assets/latest",
    'lstrings'  : "/trans/",
}

//set our time out constant
var g_nTime = 2000000;

//here are some common colors
var g_rgbSelected   = "#FFFFFF";
var g_rgbNormal     = "#A9A9A9";
var g_rgbHover      = "#3D464E";
var g_rgbMenu       = "#63ADCD";
var g_rgbWorkText   = "#2B65EC";

////////////////////////////////////////////////////////////////////////
/*
    Function: isSBEnabled()

    This function must be implemented in a platform specific manner
    allowing the rest of the application to call this function to get
    streamboost state.

    Parameters:

        Returns:
            true

        See also:
            nothing.
*/
////////////////////////////////////////////////////////////////////////
function isSBEnabled()
{
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //!!! replace this with your platform specific method to get  !!!
    //!!! the runtime state of streamboost return true if enabled !!!
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    var bReturn = false;

    //get the value of the hidden div for this
    var strText = $("#streamboost_state").text();

    //if we have something valid
    if(strText == "0" || strText == "1")
    {
        bReturn = parseInt(strText);
    }

    return bReturn;
}

////////////////////////////////////////////////////////////////////////
/*
    Function: getSBLink()

    This function must be implemented in a platform specific manner
    allowing the rest of the application to call this function to get
    streamboost state.

    Parameters:

        Returns:
            the page link path to the sb settings

        See also:
            nothing.
*/
////////////////////////////////////////////////////////////////////////
function getSBLink()
{
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //!!! replace this with your platform specific method to get  !!!
    //!!! the runtime state of streamboost return true if enabled !!!
    //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    var strFullPath     = window.location.pathname;
    var nCookieStart    = strFullPath.indexOf(";");
    var nCookieEnd      = strFullPath.indexOf("/",nCookieStart);
    var strPrepend      = strFullPath.substring(0,nCookieEnd);

    var strReturn = strPrepend + "/admin/streamboost/bandwidth";

    return strReturn;
}

//global width adjust to account for router specific layouts
var g_WorkWidthAdjuster = 10;

//global adjust to the area to display in inside of the workspace
var g_ViewPortAdjuster = 128;

//make adjustments for webkit
if($.browser.webkit)
{
    g_WorkWidthAdjuster = 55;
}

//Priority page save routine call back in case
//you need to externally save the nodes
function saveNodes(nodes)
{
}

//what to do when the user cancels a
//priority change
function cancelSave()
{
    //reload the page on cancel
    window.location = window.location.href;
    window.location.reload(true);
}

$(document).ready(function()
{
    if(isSBEnabled() == false)
    {
        $(".ng-scope").css("display","none");
    }

    //get the current browser path
    var strPath = window.location.pathname;

    //check to see if we just logged in
    if(strPath.indexOf("admin/status/overview") != -1)
    {
        //set time out for a page load check
        setTimeout(function(){
            //check to see if the help button exists
            if($("#helpBT").length == 0)
            {
                //if the button doesn't exist the page
                //failed to load after a login!
                //Try to reload the page...
                location.reload();
            }
        },10000);
    }
})