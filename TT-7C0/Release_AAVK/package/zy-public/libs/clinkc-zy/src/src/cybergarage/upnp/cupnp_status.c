/******************************************************************
*
*	CyberLink for C
*
*	Copyright (C) Satoshi Konno 2005
*
*       Copyright (C) 2006 Nokia Corporation. All rights reserved.
*
*       This is licensed under BSD-style license,
*       see file COPYING.
*
*	File: cupnp_status.c
*
*	Revision:
*
*	02/13/05
*		- first revision
*
******************************************************************/

#include <cybergarage/upnp/cupnp_status.h>
#include <cybergarage/util/clist.h>
#include <cybergarage/util/clog.h>

/****************************************
* cg_upnp_status_new
****************************************/

CgUpnpStatus *cg_upnp_status_new()
{
	CgUpnpStatus *upnpStat;

	cg_log_debug_l4("Entering...\n");

	upnpStat = (CgUpnpStatus *)malloc(sizeof(CgUpnpStatus));

	if ( NULL != upnpStat )
	{
		upnpStat->code = 0;
		upnpStat->description = cg_string_new();
	}

	return upnpStat;

	cg_log_debug_l4("Leaving...\n");
}

/****************************************
* cg_upnp_status_delete
****************************************/

void cg_upnp_status_delete(CgUpnpStatus *upnpStat)
{
	cg_log_debug_l4("Entering...\n");

	cg_string_delete(upnpStat->description);
	free(upnpStat);

	cg_log_debug_l4("Leaving...\n");
}

/****************************************
* cg_upnp_status_code2string
****************************************/

char *cg_upnp_status_code2string(int code)
{
	cg_log_debug_l4("Entering...\n");

	switch (code) {
	case CG_UPNP_STATUS_INVALID_ACTION: return "Invalid Action";
	case CG_UPNP_STATUS_INVALID_ARGS: return "Invalid Args";
	case CG_UPNP_STATUS_OUT_OF_SYNC: return "Out of Sync";
	case CG_UPNP_STATUS_INVALID_VAR: return "Invalid Var";
	case CG_UPNP_STATUS_ACTION_FAILED: return "Action Failed";
#ifdef ZYXEL_PATCH /* ZyXEL 2013, charisse*/
	case CG_UPNP_STATUS_ARG_VALUE_INVALID: return "Argument Value Invalid";
	case CG_UPNP_STATUS_ARG_VALUE_OUT_OF_RANGE: return "Argument Value Out of Range";
	case CG_UPNP_STATUS_OPT_NOT_IMPLEMENT: return "Optional Action Not Implemented";
	case CG_UPNP_STATUS_OUT_OF_MEMORY: return "Out of Memory";
	case CG_UPNP_STATUS_HUMAN_INTER_REQUIRED: return "Human Intervention Required";
	case CG_UPNP_STATUS_STRING_ARG_TOO_LONG: return "String Argument Too Long";
	//TR-064
	case CG_UPNP_STATUS_ACTION_NOT_AUTH: return "Action Not Authorized";
	case CG_UPNP_STATUS_VALUE_ALREADY_SPE: return "ValueAlreadySpecified able";
	case CG_UPNP_STATUS_VALUE_SPE_INVALID: return "ValueSpecifiedIsInvalid";
	case CG_UPNP_STATUS_INACT_CONN_REQUIRE: return "InactiveConnectionStateRequired";
	case CG_UPNP_STATUS_CONN_SETUP_FAIL: return "ConnectionSetupFailed";
	case CG_UPNP_STATUS_CONN_SETUP_INPROGRESS: return "ConnectionSetupInProgress";
	case CG_UPNP_STATUS_CONN_NOT_CONFIG: return "ConnectionNotConfigured";
	case CG_UPNP_STATUS_DISCON_INPROGESS: return "DiscconectInProgress";
	case CG_UPNP_STATUS_INVALID_L2_ADDR: return "InvalidLayer2Address";
	case CG_UPNP_STATUS_INTERNET_ACCESS_DISABLE: return "InternetAccessDisabled";
	case CG_UPNP_STATUS_INVALID_CONN_TYPE: return "InvalidConnectionType";
	case CG_UPNP_STATUS_CONN_ALREADY_TERM: return "ConnectionAlreadyTerminated";
	case CG_UPNP_STATUS_NULL_VALUE_SPE_ARRAY_IDX: return "NullValueAtSpecifiedArrayIndex";
	case CG_UPNP_STATUS_SPE_ARRAY_IDX_INVALID: return "SpecifiedArrayIndexInvalid";
	case CG_UPNP_STATUS_NO_SUCH_ENTRY_ARRAU: return "NoSuchEntryInArray";
	case CG_UPNP_STATUS_WILD_CARD_NOT_PER_IN_SRCIP: return "WildCardNotPermittedInSrcIP";
	case CG_UPNP_STATUS_WILD_CARD_NOT_PER_IN_EXTPORT: return "WildCardNotPermittedInExtPort";
	case CG_UPNP_STATUS_CONFLIC_IN_MAPENTRY: return "ConflictInMappingEntry";
	case CG_UPNP_STATUS_ACTION_DISALLOW_WHEN_AUTO_CONFIG: return "ActionDisallowedWhenAutoConfigEnabled";
	case CG_UPNP_STATUS_INVALID_DEVICE_UUID: return "InvalidDeviceUUID";
	case CG_UPNP_STATUS_INVALID_SRVID: return "InvalidServiceID";
	case CG_UPNP_STATUS_INVALID_CONSRV_SELECT: return "InvalidConnServiceSelection";
	case CG_UPNP_STATUS_SAME_PORT_VALUE_REQUIRE: return "SamePortValuesRequired";
	case CG_UPNP_STATUS_ONLY_PER_LEAS_SUPPORT: return "OnlyPermanentLeasesSupported";
	case CG_UPNP_STATUS_REMOTE_HOST_ONLY_SUPPORT_WILDCARD: return "RemoteHostOnlySupportsWildcard";
	case CG_UPNP_STATUS_EXTPORT_ONLY_SUPPORT_WILDCARD: return "ExternalPortOnlySupportsWildcard";
	case CG_UPNP_STATUS_INVALID_CHANNEL: return "InvalidChannel";
	case CG_UPNP_STATUS_INVALID_MAC_ADDR: return "InvalidMACAddress";
	case CG_UPNP_STATUS_INVALID_DATA_TRANS_RATE: return "InvalidDataTransmissionRates";
	case CG_UPNP_STATUS_INVALID_WEP_KEY: return "InvalidWEPKey";
	case CG_UPNP_STATUS_NO_WEP_KEY_SET: return "NoWEPKeyIsSet";
	case CG_UPNP_STATUS_NO_PSK_KEY_SET: return "NoPSKKeyIsSet";
	case CG_UPNP_STATUS_NO_EPA_SERVER: return "NoEAPServer";
	case CG_UPNP_STATUS_SET_MAC_NOT_PERMIT: return "SetMACAddressNotPermitted";
	case CG_UPNP_STATUS_WRITE_ACCESS_DISABLE: return "WriteAccessDisabled";
	case CG_UPNP_STATUS_SESSION_ID_EXPIRE: return "SessionIDExpired";	
#endif
	}
	 return "";

	cg_log_debug_l4("Leaving...\n");
}
