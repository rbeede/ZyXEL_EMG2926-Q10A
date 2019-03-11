Readme for new DeviceDB
=======================

Starting with version 7.0 the old single ClientDB text file is replaced by one
or multiple DeviceDB XML files. By default Twonky server and client import all
files with the extension .xml recursively. Other files or files without the
mandatory XML elements are ignored as are also entries with duplicate device
names.


Entry for a client
------------------

This is a description for clients such as PS3, XBox, Twonky manager etc.

<Client>
	<Name>Unique name of the device</Name>
	...
</Client>


Entry for a server
------------------

This is a description to handle servers.

<Server>
	<Name>Unique name of the device</Name>
	...
</Server>


Multiple devices in a file
--------------------------

DeviceDB files may contain either one client or one server entry,
but it is also possible to list several entries:

<DeviceDB>
	<Client> ... </Client>
	...
	<Server> ... </Server>
	...
</DeviceDB>

Client and server entries may be arbitrary mixed. Several files may be in this
format. All entries are merged to already existing entries. Entries with
duplicate names are ignored (ie. the first one is kept).


Device template with description
--------------------------------

Note: All XML values must be escaped and in UTF-8 format!

<Client|Server>

	<!--
		Unique name of this device.
		The server will list this name in its clientlist. The entry is not
		used to match against any strings sent by the device.
		Example: ZyXEL DMA
		Old tag: NA
		Mandatory, exactly once.
	-->
	<Name>Devicename</Name>


	<!-- *** Device identification elements *** -->

	<!--
		User agent in HTTP requests.
		Example: Allegro-Software-WebClient/4.61 DLNADOC/1.0
		Old tag: HH
		Optional, at most once. Mandatory, if HeaderId2 is listed.
	-->
	<UserAgent>HTTP header field</UserAgent>

	<!--
		Second header field in HTTP requests.
		This tag is only valid in combination with the UserAgent element. The
		device is identified, if the strings in UserAgent OR HeaderId2 match.
		Example: Streamium/1.0
		Old tag: H2
		Optional, at most once.
	-->
	<HeaderId2>Second HTTP header field</HeaderId2>

	<!--
		If the device has a device description, then this entry can be used to
		identify it.
		Example: &lt;modelName&gt;Windows Media Player Sharing&lt;/modelName&gt;
		Old tag: DD
		Optional, at most once. Mandatory if DeviceId2 is listed.
	-->
	<DeviceId>Device description entry</DeviceId>

	<!--
		Second entry in the device description.
		This tag is only valid in combination with the DeviceId element. The
		device is identified, if the strings in DeviceId AND DeviceId2 match.
		Example: &lt;modelNumber&gt;4.0&lt;/modelNumber&gt;
		Old tag: D2
		Optional, at most once.
	-->
	<HeaderId2>Second device description entry</HeaderId2>

	<!--
		The device is identified, if a browse request contains the provided
		BrowseFlag, ObjectID, Filter, StartingIndex, RequestCount and
		SortCriteria. All of the listed elements have to be present.
		If specified, then element HeaderIdAfterBrowse also has to be
		specified and both must match the request.
		Example: &lt;BrowseFlag&gt;BrowseDirectChildren&lt;/BrowseFlag&gt;
				 &lt;ObjectID&gt;0&lt;/ObjectID&gt;
				 &lt;Filter&gt;upnp:class,dc:date,res,res@size&lt;/Filter&gt;
				 &lt;RequestedCount&gt;120&lt;/RequestedCount&gt;
		Old tag: MB
		Optional, at most once. Required if HeaderIdAfterBrowse is specified.
	-->
	<BrowseRequestId>Escaped browse request</BrowseRequestId>

	<!--
		The device is identified, if the header of a browse request contains the
		provided entry.
		Example: UPnP/1.0 DLNADOC/1.50 Intel_SDK_for_UPnP_devices/1.2
		Old tag: HB
		Optional, at most once. Required if BrowseRequestId is specified.
	-->
	<HeaderIdAfterBrowse>HTTP header field</HeaderIdAfterBrowse>

	<!--
		Specifies the dynamic adaptation of the client list in case of detection.
		Allowed values:
			FIX			Setting can only be overruled by the user manually.
			FIXPC		This client runs on a PC, always detected by UA, e.g. Twonky
			FIXPC1		This client runs on a PC, sometimes changes UA, highest priority, e.g. CTT, LPTT, UPNP
			FIXPC2		This client runs on a PC, manual selected. no detection possible, e.g. Linn
			FIXPC3		This client runs on a PC, sometimes changes UA, e.g. WMP
			AUTO		This setting can be overruled if another client is detected.
		Old tag: DB
		Optional, at most once.
		Generic incoming requests will always be mapped to FIXPC1, 2, or 3 if available.
	-->
	<DataBase>Config</DataBase>


	<!-- *** Device adaptation elements *** -->

	<!--
		Used to specify that only specific media types are supported.
		Allowed values: 
			Music		music only device
		Old tag: AV
		Optional, at most once.
	-->
	<SupportedMediaType>Media type</SupportedMediaType>

	<!--
		Specifies the device description file to be sent to this client
		instead of the default one. The file is taken from the resources
		directory. Default is devicedescription-dlna-1-5.xml.
		Example: devicedescription-win7.xml
		Old tag: DF
		Optional, at most once.
	-->
	<DescriptionFile>Device description file</DescriptionFile>

	<!--
		Used to specify that specific DLNA settings have to be applied.
		Allowed values: 
			MP4DLNA		force specific MPEG4 settings
		Old tag: DL
		Optional, at most once.
	-->
	<DlnaSettings>One setting</DlnaSettings>

	<!--
		Specifies the default view to be sent to this client in browse requests.
		The value is the name as specified by the name attribute in the view
		files located in resources/views.
		Example: advanceddefault
		Old tag: DV
		Optional, at most once.
	-->
	<DefaultView>View name</DefaultView>

	<!--
		Specifies that the server should behave like another server.
		Allowed values:
			REDSONIC	For clients like DSM 520 which need the resonic string
						to enable nice UI.
			WMC			For clients which need a WMC compliant device
						description.
			SAMSUNGFEATLIST
						For samsung C-series TVs to skip 1st level of
						navigation tree.
		Old tag: DX
		Optional, at most once.
	-->
	<PretendDevice>Device</PretendDevice>

	<!--
		Used to turn off events to be sent to the device.
		Allowed values: 
			NO
		Old tag: ET
		Optional, at most once.
	-->
	<Eventing>Eventing config</Eventing>

	<!--
		Used to configure responses to requests.
		Allowed values:
			LIVEWITHLENGTH		Return content length in HTTP response
			LIVEPSPLENGTH		Special PSP header for live content
			chunked				Enable chunked response (disabled by default)
			1.0RESPONSE			Client requires 1.0 response on 1.0 request
			1.0PROXYRESPONSE	Client requires 1.0 response when proxying
		Note: Value close is no longer supported.
		Old tag: HP
		Optional, can appear multiple times.
	-->
	<HttpSettings>One setting</HttpSettings>

	<!--
		Lists a translation from the MIME type of the original resource to the
		one expected by the client.
		Each MimeTypeMapping contains exactly one MimeTypeIn element
		containing exactly one original MIME type, and exactly one MimeTypeOut
		element containing exactly one translated MIME type.
		Example:
			<MimeTypeIn>application/ogg</MimeTypeIn>
			<MimeTypeOut>audio/x-ogg</MimeTypeOut>

		To suppress a MIME type so that a client does not receive a res
		element with the corresponding MIME type, replace the MimeTypeOut
		element with this: 
			<MimeTypeSuppress>1</MimeTypeSuppress>
		Old tag: MT
		Optional, can appear multiple times.
	-->
	<MimeTypeMapping>
        <MimeTypeIn>Original MIME type</MimeTypeIn>
        <MimeTypeOut>Translated MIME type</MimeTypeOut>
    </MimeTypeMapping>
	<MimeTypeMapping>
        <MimeTypeIn>Original MIME type</MimeTypeIn>
		<MimeTypeSuppress>1</MimeTypeSuppress>
    </MimeTypeMapping>

	<!--
		Lists specific features.
		Allowed values: 
			supports_icy	Pass through Shoutcast
		Old tag: OS
		Optional, at most once
	-->
	<Feature>One feature</Feature>

	<!--
		Lists specific search behavior.
		Allowed values: 
			roku		give special Roku search capabilities
		Note: nodups is no longer supported.
		Old tag: SC
		Optional, at most once
	-->
	<Search>Search behavior</Search>

	<!--
		Lists specific parameters to the transcoder.
		Currently this is only supported for MP4.
		Each TranscoderParameter contains exactly one Target element with one
		stream type, and exactly one Parameter element with the parameters for
		the corresponding transcoder tool.
		Example:
			<Target>MP4</Target>
			<Parameter>-suppress_amr -add_isom -update_stss</Parameter>
		Old tag: TP
		Optional, at most once
	-->
    <TranscoderParameter>
        <Target>Stream type</Target>
        <Parameter>Transcoder parameters</Parameter>
    </TranscoderParameter>

	<!--
		Comma-separated list of transcoded formats supported by the device.
		Allowed values:
			FLV
			JPEG<x-resolution>x<y-resolution>
			JPEGORG		original JPEG resource
			JPEG_TN
			JPEG_SM
			JPEG_MED
			JPEG_LRG
			MP3
			MP4
			MPEG
			WAV
			WMV
		Example:
			JPEG120x90,JPEG720x576,MP3,WAV,WMV
		Old tag: TR
		Optional, at most once
	-->
    <TranscodingProfiles>List of transcoding formats</TranscodingProfiles>

	<!--
		Lists an alternative web browse provided by the server
		Allowed values:
			webbrowse-n95	reduced mobile style
		Old tag: WB
		Optional, at most once
	-->
    <WebBrowseStyle>Style</WebBrowseStyle>

	<!--
		Lists additional device specific behavior.
		The value consists always of one behavior. To specify multiple
		behaviors, add the element multiple times.
		Allowed values:
			AASCALE#JPEG<x-resolution>x<y-resolution>
						  	    scaled AlbumArt, e.g. AASCALE#JPEG320x320
			AGGREGATION			this client is an aggregation server and gets
								special added properties for allowed
								aggregated items
			AARES				add album art uri as res element

			SAMSUNGFEATLIST		for samsung C-series TVs to skip 1st level 
								of navigation tree
			CANNOTREGISTERDEVICE
								force "Action failed" on
								X_MS_MediaReceiverRegistrar:RegisterDevice
			DLNA10				force DLNA 1.0
			DLNA15				force DLNA 1.5
			DATETIME			add time to date for clients which can use the
								time info as well
			DIDL255				return less than 255 bytes in the DIDL-Lite
								attributes
			DLNANO				do not give DLNA extensions to this client
			EXACTPROTOCOLINFO	calculate protocol info based on shared items
								(deprecated - this behaviour is deprecated and
								may be removed in the future)
			FORCE_4TH_FIELD		always include the 4th field in the
								protocol info
			FORCE_DURATION		always give a duration for audio and video
								files
			FORCERES			include res even if does not match provided
								filter
			FORCE_VIDEOBITRATE	always give a video bitrate
			IGNORESORT			ignore sort order for browse and search
			NOARTISTROLECOMPOSER
								suppress <upnp:artist role="Composer">
								metadata from browse responses (some clients
								may display this instead of upnp:artist)
			NOBITRATE			suppress bitrate in res elements
			NOEMBEDDEDALBUMART	suppress embedded albumart and thumbnails
			NO_KEYFRAME_SEEK	do not seek to key frames
			NOPROXYURL			client does not need proxied URLs
			NOTRPICS			give only original pictures, no transcoded
								pictures
			noutf8				do enhanced ASCII instead of UTF-8
			PHILIPSSEARCH		special handling for Philips searches
			PHILIPSSRT			Philips subtitle support
			RESTRICTEDUPLOAD	only allow CreateObject of known content types
								listed in protocolInfo
			TV4IDS				client needs the old Twonky 4.4 style object
								IDs: Music==1, Picture==2, Video==3
			UNLIMITED			do not use DLNA limit of 200k for generated
								XML
			VALIDATEDSEARCHCRITERIA
								strictly validate the CDS:Search experession -
								not done by default because of potentially
								slow implementation
			VALIDATEDSORT		validate sort string in Browse and CDS:Search
								against server's known properties - not by
								default because some clients do not ask the
								sort criterias from servers
			VIERA_DIVXPROFILE	add client specific profile for DivX
			NO_KEYFRAME_SEEK	the client requires not using keyframe based seek
		Old tag: XM
		Optional, may appear multiple times.
	-->
	<SpecificBehavior>One behavior</SpecificBehavior>

	<capabilities>
		<DTCP />	device supports DTCP
	</capabilities>
</Client|Server>


Device template
---------------

Copy 00Template.txt in this directory to a correctly named .xml file and adapt
all entries accordingly.
Please remember to use UTF-8 encoded values, XML values need to be
escaped. Do not use line-breaks or tabs in the values, unless these should be
really part of them.
