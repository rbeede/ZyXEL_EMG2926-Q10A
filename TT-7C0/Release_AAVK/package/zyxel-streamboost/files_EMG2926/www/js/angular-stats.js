/*
 * Copyright (c) 2014 Qualcomm Atheros, Inc.
 *
 * All Rights Reserved.
 * Qualcomm Atheros Confidential and Proprietary
 */
angular.module('stats', ['ozker'])
    .service('stats',['$http', '$q', 'router', function($http,$q, router) {
        var self = this;
        var routerEndTime;
        var vData;
        var policycache = {},
            flowsByName = {},
            flows = [];

        var filterDateStart, filterDateEnd, vMacFilters = [];

        var g_routerDelta = 0;

        this.getFlowsTime = function(start, end, nodes, startIndex, endIndex) {
            return self.fetch(self.urls,start,end, nodes, startIndex, endIndex)
            .then(function() { 
                $("body").removeClass("loading");
                $("#divModal").hide();  
                return getByTime(vData);
                // return null;
            });
        }

        this.getFlowsBytesDown = function(start, end, nodes, startIndex, endIndex) {
            return self.fetch(self.urls,start,end, nodes, startIndex, endIndex)
            .then(function() { 
                $("body").removeClass("loading");
                $("#divModal").hide();  
                return getBytesDown(vData); 
            });
        }

        this.getFlowsBytesUp = function() {
            return self.fetch(self.urls).then(function() { return getBytesUp(vData); });
        }

        this.getFlowsEvents = function() {
            return self.fetch(self.urls).then(function() { return getEvents(vData); });
        }

        //convert bytes to Megabits 2 decimal places
        function B2Megabytes(val) {
            var nReturn = 0;

            nReturn = ((val / g_nMegSize) / g_nMegSize);

            if(nReturn < 0)
            {
                nReturn = 0;
            }

            return nReturn;
        }

        function getEvents(vData) {
            var vReturn = [];
            // 4 strata?!
            vReturn[0] = [];
            vReturn[1] = [];
            vReturn[2] = [];
            vReturn[3] = [];
            for(var i in vData) {
                var flowobj = vData[i];
                for (j = 0; j < flowobj.flows.length; j++) {
                    var o = flowobj.flows[j];
                    if (!o.close || !o.policy) continue; //unclosed or unknown
                    if (!isFilteredOut(o)) {
                        //add the guy to the end of our return
                        vReturn[0].push([o.open.time,i,o.close.time,i]);
                    }
                }
            }
            return vReturn;
        }

        function getByTime(vData)
        {
            var vReturn = [];

            vReturn.push([_t("Flow Name"), _t("Minutes")]);

            //walk the list and get the times
            for(var i in vData)
            {
                var strName = i;

                // pre-calculated by adding all times for the flowName
                var nTime = (vData[i].totalTime/1000)/60; // these are all in minutes

                //make our list
                vReturn.push([strName,nTime]);
            }

            return vReturn;
        }


        function getBytesDown(vData) {
            var vReturn = [];

            //vReturn.push(["Flow Name", "Bytes Downloaded","Tool Tip"]);

            //walk the list
            for(var i in vData)
            {
                //get name
                var strName = i;
                var nDL = 0;

                //if we have a valid download (don't show zeros)
                if(vData[i].nDownload)
                {
                    nDL = vData[i].nDownload;
                    //make our list
                    vReturn.push([strName,B2Megabytes(nDL)]);
                }
            }

            return vReturn;
        }

        function getBytesUp(vData) {
            var vReturn = [];

            //vReturn.push(["Flow Name", "Bytes Downloaded","Tool Tip"]);

            //walk the list
            for(var i in vData)
            {
                //get name
                var strName = i;
                var nDL = 0;

                //if we have a valid download (don't show zeros)
                if(vData[i].nDownload)
                {
                    nDL = vData[i].nUpload;
                    //make our list
                    vReturn.push([strName,B2Megabytes(nDL)]);
                }
            }

            return vReturn;
        }


        function isFilteredOut(dat) {
            // console.log('isFilteredOut begin');
            if (filterDateStart && (dat.open.time < filterDateStart)) 
            {
                // console.log('filterDateStart: ' + filterDateStart + ', dat.open.time: ' + dat.open.time);
                return true;
            }
            if (filterDateEnd && (dat.close.time > filterDateEnd)) 
            {
                // console.log('filterDateEnd: ' + filterDateEnd + ', dat.close.time: ' + dat.close.time);
                return true;
            }

            if (vMacFilters && vMacFilters.length) {
                fmac = vMacFilters;
                // console.log('fmac: ' + fmac + ', dat.open.mac: ' + dat.open.mac);                    
                if (fmac != dat.open.mac) 
                {
                    // console.log('fmac != dat.open.mac, filter out');                    
                    return true;
                }
            }

            return false;
        }

        var saveflows = {};

        function isRawFilteredOut(ev) {
            if (saveflows[ev.uuid]) { // mac close
                // if enddate is > self.dateEnd then truncate?
                // if startdate is < self.dateStart then trucate?
                delete saveflows[ev.uuid];
                return false;
            }
            var dattime = new Date(parseInt(ev.time)*1000 + g_routerDelta);
            if (filterDateStart && (dattime < filterDateStart)) return true;
            if (filterDateEnd && (dattime > filterDateEnd)) return true;
/*
            if (vMacFilters && vMacFilters.length) {
                var fmac;
                for (var f in vMacFilters) {
                    fmac = vMacFilters[f];
                    if (fmac == ev.mac) {
                        saveflows[uuid] = true;
                        break;
                    }
                }
                if (fmac != datmac) return true;
            }
*/
            return false;
        }

        // for a given flow name, there will be multiple "event pairs", compute a total time and bytes
        // for each flow type
        this.combineEvents = function(byflow) {
            // console.log('combineEvents');
            // console.log('combineEvents before, byflow:');
            // console.log(byflow);
            for (var i in byflow) {
                var flowobj = byflow[i]; // this is a bunch of "opens"
                flowobj.nDownload = 0;
                flowobj.nUpload = 0;
                flowobj.totalTime = 0;
                flowobj.times = [];
                for (j = 0; j < flowobj.flows.length; j++) {
                    var o = flowobj.flows[j];
                    if (!o.close || !o.policy)
                    {
                        // console.log('unclosed or unknown, continue');
                        continue; //unclosed or unknown
                    }
                    if (!isFilteredOut(o)) {
                        // console.log('nDownload accum');
                        flowobj.nDownload += o.close.details.rx_bytes;
                        flowobj.nUpload += o.close.details.tx_bytes;
                        flowobj.times.push({timeOpen: o.open.time, timeClose: o.close.time});
                        flowobj.totalTime += o.close.time - o.open.time;
                    }
                    else
                    {
                        // console.log('isFilteredOut ...');
                    }
                }
                // console.log('flowobj.nDownload: '+ flowobj.nDownload);
            }
            // console.log('combineEvents after, byflow:');
            // console.log(byflow);
            return byflow;
        }

        function getPolicyCache(policyUrl) {
            if (policycache.length) return true;
            else {
                return $http.get(policyUrl)
                .success(function(data) {
                    for (var id in data) {
                        policycache[id] = data[id];
                    }
                });
            }
        }

        var dataUrl;
        var policyUrl;

        this.fetch = function(urls, start,end,nodes, startIndex, endIndex) {
            return router.fetch()
            .then(function() {
                return getPolicyCache(urls[1]);
            })
            .then(function() {
                dataUrl = urls[0];
                g_routerDelta = 0;//old way: router.model.timedelta;
                return self.getData(start,end,nodes, startIndex, endIndex);
            })
            .then(function(byflows) {
                //compute aggregates by flow
                // console.log('start combineEvents: ');
                var aggData = self.combineEvents(byflows);
                vData = aggData;
                // console.log('vData: ');
                // console.log(vData);
                return null;
                // return aggData; // Q(aggData)
            });
        }

        function lastpath(s) {
            var slash = s.lastIndexOf("/");
            if (slash == -1) {
                slash = s.lastIndexOf(":");
            }
            if (slash == -1) return "unknown";
            else return s.substr(slash+1);
        }


        var byflows = {};

        //current router time
        var currentTime = null;
        //handy 30 day variable
        var thirtydays = 30*24*60*60*1000;

        this.validTime = function(test)
        {
            var rt = false;

            var current = currentTime.getTime();
            //get the diff between now and this data
            var diff =  current - test;

            //if the time is invalid set it to 30 days minus current router time
            if( diff > 0 &&
                diff < thirtydays)
            {
                rt = true;
            }

            return rt;
        }

        function calculateByFlow(data)
        {
            var byflows = {};
            // console.log('data: ');
            // console.log(data);
            // console.log('rawData: ');
            // console.log(rawData);

            // if (rawData == null)
            // {
            //     rawData = data;
            // }
            // else
            // {
            //     $.merge(data.events, rawData.events);
            // }
            // console.log('rawData merged: ');
            // console.log(rawData);                    
            // // console.log('data: ');
            // // console.log(data);                    

            // // data = rawData;

            // // data = rawData;

            // rawData = data;
            // if (rawData == null)
            // {
            //     console.log('rawData = data');
            //     rawData = data;
            // }
            // if (startIndex == 0)
            // {
            //     console.log('rawData: ');
            //     console.log(rawData);                        
            // }

            // console.log('rawData.events.length: ' + rawData.events.length);

            var opens = {};

            for (var i = 0; i < data.events.length; i++) {
                var flow = data.events[i];
                var nid = flow.uuid;
                // console.log('i: ' + i + ', nid: ' + nid);
                if (flow.event == "open") {
                    if (opens[nid]) {
                        // error "double id"!!!!
                        // console.log('error double open of nid: ' + nid);
                        // deferred.reject(_t("error double open"));
                    }
                    else {
                        // console.log('flow.time: ' + flow.time);
                        var nTime = parseInt(flow.time);
                        nTime *= 1000;
                        nTime += g_routerDelta;
                        // console.log('nTime: ' + nTime);

                        //if this is a valid time range
                        if(self.validTime(nTime))
                        {
                            flow.time = new Date(nTime);
                            opens[nid] = { open: flow };
                            /* temporary */
                            if (policycache[flow.details.policy_id]) {
                                opens[nid].policy = policycache[flow.details.policy_id];
                            }
                            else {
                                opens[nid].policy = {emit: lastpath(flow.details.policy_id)};
                            }
                             // console.log('opens[nid].policy: ' + opens[nid].policy);

                        }
                        else
                        {
                            // console.log('not validTime: ' + nTime);                                    
                        }
                    }
                }
                else if ((flow.event == "close") || (flow.event == "milestone")) {
                    if (!opens[nid]) {
                        // console.log('unmatched close/milestone: ' + nid);
                        // console.log(_t("unmatched close/milestone"));
                    }
                    else {
                        // console.log('flow.time: ' + flow.time);
                        var nTime = parseInt(flow.time);
                        nTime *= 1000;
                        nTime += g_routerDelta;
                        flow.time = new Date(nTime);

                        // console.log('nTime: ' + nTime);

                        //if this is a valid time range
                        if(self.validTime(nTime))
                        {
                            flow.details.rx_bytes = parseInt(flow.details.rx_bytes);
                            flow.details.tx_bytes = parseInt(flow.details.tx_bytes);
                            // console.log('rx_bytes: ' + flow.details.rx_bytes + ', tx_bytes: ' + flow.details.tx_bytes);   
                            opens[nid].close = flow;
                        }
                        else
                        {
                            // console.log('not validTime: ' + nTime);                                    
                        }                                
                    }
                }
                else if (flow.event == "oversub") {
                    //TODO: need to know what this record looks like!
                }
            }

            // console.log('opens: ');
            // console.log(opens);

            var now = new Date().getTime();

            //make sure by flows is empty!
            byflows = {};

            // now see what's left in "opens"
            // and construct our return data
            for (var o in opens) {
                if (!opens[o].close) {
                    // console.log('no closed, rx_bytes: 0, tx_bytes: 0');   
                    opens[o].close = {
                        time: now,
                        details: {tx_bytes: 0, rx_bytes: 0}
                    };
                }

                //if we don't have this is by flows
                if(typeof byflows[opens[o].policy.emit] == 'undefined')
                {
                    //create our data field
                    byflows[opens[o].policy.emit] = {};

                    //make the flows list
                    byflows[opens[o].policy.emit].flows = [];
                }

                //add this open/close set to the correct flow
                byflows[opens[o].policy.emit].flows.push(opens[o]);
            }

            // console.log('byflows: ');
            // console.log(byflows);     

            // ++g_bDisablePolling;
            // console.log('g_bDisablePolling: ' + g_bDisablePolling);
            // if (g_bDisablePolling >=3)
            // {
            //     return null;
            // }               

            //send this back now that we have it done 

            return byflows;           
        }

        //
        // This method should fill in the vData member variable
        // converted and returned by the fxStats binding methods
        //
        this.getData = function(start, end, vFilter, startIndex, endIndex) {

            // console.log('start: '+ start + ', end: ' + end + ', vFilter: ' + vFilter + ', startIndex: ' + startIndex + ', endIndex: ' + endIndex );
            filterDateStart = start;
            filterDateEnd = end;
            if (startIndex < 0)
            {
                startIndex = 0;
            }

            // console.log('vFilter :');
            // console.log(vFilter);

            vMacFilters = (vFilter && vFilter.length) ? vFilter : null;

            // console.log('vMacFilters: ');
            // console.log(vMacFilters);

            vData=[];

            var deferred = $q.defer()
            var strData = "";

            var sDate = new Date();//$( "#topFrom" ).datepicker( "getDate" );
            var eDate = new Date();//$( "#topTo" ).datepicker( "getDate" );
            byflows = {};

            //cache the current router time
            currentTime = getCurrentTime();
            // console.log('startIndex, endIndex: '+ startIndex + ', ' + endIndex);

            if (!g_bHasEventData)
            {
                // angular will fail to parse the crappy JSON
                $http.get('/cgi-bin/ozkerz?eventFlows=1&beginIndex='+startIndex+'&endIndex='+endIndex,{timeout:30*60*1000,
                    transformResponse: function(data, headersGetter) {                  
                        return data;
                    }})
                    .error(function(data, status, headers, config) {
                        deferred.reject(_t("Unable to get requested data. Please check your connection to your router."));
                    })
                    .success(function(datax, status, headers, config) {
                        //var data2 = datax.replace(/:([a-z_]+)/g,':"$1"');

                        // this filters the data to a more manageable amount (for parsing)
                        // and also handles the non-quoted strings in some of the 5-tuple data
                        var data2 = datax.replace(/{"5-tuple".*}\s*,/g,'');

                        var data = JSON.parse(data2);

                        if (rawData == null)
                        {
                            // console.log('rawData == null, rawData = data');
                            rawData = data;
                            // console.log('rawData:');
                            // console.log(rawData);
                        }
                        else
                        {
                            // console.log('merge(data, rawData), ');
                            // console.log('data:');
                            // console.log(data);
                            rawData = $.extend(true, data, rawData);  
                            //$.merge(data, rawData);
                            // console.log('rawData:');
                            // console.log(rawData);
                        }

                        refreshModalDescription(false, g_bShowDetailedLoadingMessage);

                        var dataCopied = $.extend(true, {}, rawData);                    
                        byflows = calculateByFlow(dataCopied);
                        deferred.resolve(byflows);

                    }); // .success   


            } // if (!g_bHasEventData)
            else
            {
                var dataCopied = $.extend(true, {}, rawData);                    
                byflows = calculateByFlow(dataCopied);
                deferred.resolve(byflows);
            }

            return deferred.promise;

        }



    }]);