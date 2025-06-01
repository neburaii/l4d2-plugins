#pragma newdecls required
#pragma semicolon 1

#include <dhooks>
#include <neb_stocks>
#include <multicolors>

#define	GAMEDATA	"host_player.games"

public Plugin myinfo = 
{
	name = "Players as Hosts",
	author = "Neburai",
	description = "tracks which player originally hosted/joined the lobby. It does nothing on its own. Other plugins may use its natives to provide special features for this player",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/host_player"
};

/***********
 * HOOK VARS
 ***********/
DynamicDetour	g_hDetourReplyReservationRequest, g_hDetourSetReservationCookie;
Handle 			g_hSDKNetAdrToString;

bool 			g_bReserveRequested;
Address 		g_aReserveRequesterNetAdr;

/************
 * HOST VARS
 ***********/
int				g_iPlayerHostUID = -1, g_iHostHistory[MAXPLAYERS_L4D2+1];
bool			g_bHostIrreplaceable, g_bHostIrreplaceableHistory[MAXPLAYERS_L4D2+1], g_bWaitingForReserveHost;
char			g_sReserveHostIP[128];

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	CreateNative("IsPlayerHost", Native_IsPlayerHost);
	CreateNative("GetHostClient", Native_GetHostClient);

	return APLRes_Success;
}

public void OnPluginStart()
{
	// load required files
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetourReplyReservationRequest = DynamicDetour.FromConf(hGameData, "HX::CBaseServer::ReplyReservationRequest");
	if(!g_hDetourReplyReservationRequest) SetFailState("could not create HX::CBaseServer::ReplyReservationRequest detour");
	g_hDetourReplyReservationRequest.Enable(Hook_Pre, DTR_ReplyReservationRequest_Pre);
	g_hDetourReplyReservationRequest.Enable(Hook_Post, DTR_ReplyReservationRequest_Post);

	g_hDetourSetReservationCookie = DynamicDetour.FromConf(hGameData, "HX::CBaseServer::SetReservationCookie");
	if(!g_hDetourSetReservationCookie) SetFailState("could not create HX::CBaseServer::SetReservationCookie detour");
	g_hDetourSetReservationCookie.Enable(Hook_Post, DTR_SetReservationCookie_Post);

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "netadr_s::ToString"))
		SetFailState("could not load netadr_s::ToString signature!!");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Plain);
	g_hSDKNetAdrToString = EndPrepSDKCall();
	if(g_hSDKNetAdrToString == null)
		SetFailState("could not create netadr_s::ToString SDKCall handle!");

	// event exposes IP of connecting client, so we need this hook to compare in lobby reservation scenarios
	HookEvent("player_connect", event_player_connect);

	LoadTranslations("host_player.phrases");
	RegConsoleCmd("sm_host", cmdHost, "Return the name of the current host");

	RegPluginLibrary("host_player");
}

Action cmdHost(int iClient, int iArgs)
{
	if(g_iPlayerHostUID == -1)
	{
		CReplyToCommand(iClient, "%t %t", "tag_cmd_host", "msg_cmd_host_none");
		return Plugin_Handled;
	}

	int iHostClient = GetClientOfUserId(g_iPlayerHostUID);
	if(!nsIsClientValid(iHostClient))
	{
		CReplyToCommand(iClient, "%t %t", "tag_cmd_host", "msg_cmd_host_invalid");
		return Plugin_Handled;
	}

	if(iHostClient == iClient) CReplyToCommand(iClient, "%t %t", "tag_cmd_host", "msg_cmd_host_self");
	else CReplyToCommand(iClient, "%t %t", "tag_cmd_host", "msg_cmd_host_other", iHostClient);

	return Plugin_Handled;
}

/*******
 * LOBBY RESERVE HOOKS
 *******/

// get IP of client who requested a reservation
MRESReturn DTR_ReplyReservationRequest_Pre(DHookReturn hReturn, DHookParam hParams)
{
	g_bReserveRequested = true;
	g_aReserveRequesterNetAdr = view_as<Address>(hParams.Get(1));
	return MRES_Ignored;
}

MRESReturn DTR_ReplyReservationRequest_Post(DHookReturn hReturn, DHookParam hParams)
{
	g_bReserveRequested = false;
	return MRES_Ignored;
}

MRESReturn DTR_SetReservationCookie_Post(DHookReturn hReturn, DHookParam hParams)
{
	if(!g_bReserveRequested) return MRES_Ignored;

	g_bWaitingForReserveHost = true;
	SDKCall(g_hSDKNetAdrToString, g_aReserveRequesterNetAdr, g_sReserveHostIP, sizeof(g_sReserveHostIP), false);

	return MRES_Ignored;
}

/********************
 * HOST MANAGEMENT
 ********************/

void event_player_connect(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(!g_bWaitingForReserveHost) return;

	static char sAddress[128];
	hEvent.GetString("address", sAddress, sizeof(sAddress));

	// if address matches then this is the client who orignally hosted the game through lobby
	if(strcmp(g_sReserveHostIP, sAddress) == 0)
	{
		g_bWaitingForReserveHost = false;
		setHost(hEvent.GetInt("userid"), true);
	}
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient)) return;

	if(g_iPlayerHostUID == -1)
	{
		setHost(GetClientUserId(iClient), true);
	}
	else if(!g_bHostIrreplaceable)
	{
		int iUID = GetClientUserId(iClient);
		tryToReplaceHost(iUID);
	}
}

public void OnServerEmptied()
{
	removeHost();
	clearHostHistory();
}

public void OnClientDisconnect(int iClient)
{
	int iUID = GetClientUserId(iClient);
	if(iUID == g_iPlayerHostUID)
	{
		removeHost();
		addToHostHistory(iUID);
		transferHostToNextPlayer();
	}
}

void setHost(int iUID, bool bIrreplaceable = false)
{
	g_iPlayerHostUID = iUID;
	g_bHostIrreplaceable = bIrreplaceable;

	// irreplaceable host is the OG host. Having them set makes current host history worthless
	if(bIrreplaceable) clearHostHistory();
}

void removeHost()
{
	g_iPlayerHostUID = -1;
	g_bHostIrreplaceable = false;
}

void transferHostToNextPlayer()
{
	float fTime, fOldestTime = -1.0;
	int iOldestClient = -1;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsClientValid(i)) continue;
		if(IsFakeClient(i)) continue;
		
		fTime = GetClientTime(i);
		if(fTime > fOldestTime)
		{
			fOldestTime = fTime;
			iOldestClient = i;
		}
	}

	if(!nsIsClientValid(iOldestClient)) return;

	// don't need to check history of being irreplaceable. If they were, they would've took over upon initially connecting
	setHost(GetClientUserId(iOldestClient));
}

/**************
 * HOST HISTORY
 *************/
void addToHostHistory(int iUID, bool bIrreplaceable = false)
{
	for(int i = MAXPLAYERS_L4D2; i > 0; i--)
	{
		g_iHostHistory[i] = g_iHostHistory[i-1];
		g_bHostIrreplaceableHistory[i] = g_bHostIrreplaceableHistory[i-1];
	}
	g_iHostHistory[0] = iUID;
	g_bHostIrreplaceableHistory[0] = bIrreplaceable;
}

void clearHostHistory()
{
	for(int i = 0; i <= MAXPLAYERS_L4D2; i++)
	{
		g_iHostHistory[i] = 0;
		g_bHostIrreplaceableHistory[i] = false;
	}
}

void tryToReplaceHost(int iUID)
{
	bool bTooNew;

	// end of array are the oldest. Reverse loop, if current host comes up first, it can be concluded that this player is a newer host if they do exist in history.
	// Oldest host is preferred, but if a host has a history of being irreplaceable (true original host), then they become new host regardless of age within history
	for(int i = MAXPLAYERS_L4D2; i >= 0; i--)
	{
		if(g_iHostHistory[i] == g_iPlayerHostUID) bTooNew = true;
		if(g_iHostHistory[i] == iUID)
		{
			if(bTooNew && !g_bHostIrreplaceableHistory[i]) return;

			setHost(g_iHostHistory[i], g_bHostIrreplaceableHistory[i]);
			return;
		}
	}
}

/*****
 * NATIVE
 *****/

public any Native_IsPlayerHost(Handle hPlugin, int iNumParams)
{
	return g_iPlayerHostUID == GetClientUserId(GetNativeCell(1));
}

public any Native_GetHostClient(Handle hPlugin, int iNumParams)
{
	return view_as<int>(GetClientOfUserId(g_iPlayerHostUID));
}