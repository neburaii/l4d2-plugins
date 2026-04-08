#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <hxlib>
#include <multicolors>
#include <host_player>

#undef REQUIRE_PLUGIN
#include <cookie_manager>

#define COOKIE			"announce_host_change"
#define COOKIE_CONVAR	"cookie_announce_host_change"

public Plugin myinfo =
{
	name = "Players as Hosts",
	author = "Neburai",
	description = "tracks which player originally hosted/joined the lobby. It does nothing on its own. Other plugins may use its natives to provide special features for this player",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/host_player"
};

#define ANNOUNCE_ENUM_MIN	0
#define ANNOUNCE_ENUM_MAX	2

enum
{
	Announce_None		= 0,
	Announce_Affected	= 1,
	Announce_All		= 2
};

bool			g_bLateLoaded;

ConVar			g_hConVar_AdminFlags;
int				g_iAdminFlags;

ConVar			g_hConVar_ImmunityIncrease;
int				g_iImmunityIncrease;

ConVar			g_hConVar_HostRecordTimeout;
float			g_fHostRecordTimeout;

AnnounceCookie	g_hCookie_AnnounceHostChange;
ConVar			g_hConVar_AnnounceHostChange;
int				g_iAnnounceSettingDefault;
int				g_iAnnounceSetting[MAXPLAYERS_L4D2 + 1];

#if defined _cookie_manager_included_
	bool			g_bCookieHooked;
#endif

HostRecords		g_records;
int				g_iPriorityCounter = 1;

int				g_iClientIP[MAXPLAYERS_L4D2 + 1];
int				g_iClientPriority[MAXPLAYERS_L4D2 + 1] = {-1, ...};

LastKnownHost	g_lastKnownHost;
GlobalForward	g_hForward_OnHostChanged;

bool			g_bWaitingForReserver;
int				g_iReserverIP;

bool			g_bReplyingToReservationRequest;
bool			g_bReservationRequestAccepted;
int				g_iReservationCookie[2];

enum struct LastKnownHost
{
	AdminId admin;
	int userid;
	int flagsDiff;
	int immunityDiff;

	void Update()
	{
		int iNewHost = GetHostClient();
		int iOldHost = this.Get();
		if (iNewHost == iOldHost)
			return;

		if (iNewHost && iOldHost)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				if (IsFakeClient(i)) continue;

				this.AnnounceChange(i, iOldHost, iNewHost);
			}
		}

		Call_StartForward(g_hForward_OnHostChanged);
		Call_PushCell(iOldHost);
		Call_PushCell(iNewHost);
		Call_Finish();

		this.userid = iNewHost ? GetClientUserId(iNewHost) : 0;
		this.UpdateAdmin(iNewHost);
	}

	void UpdateAdmin(int iClient)
	{
		this.RemoveAdmin();

		if (!g_iAdminFlags || !iClient)
			return;

		this.admin = GetUserAdmin(iClient);
		int iSetFlags = g_iAdminFlags;

		if (this.admin == INVALID_ADMIN_ID)
		{
			this.admin = CreateAdmin();
			SetUserAdmin(iClient, this.admin, true);
		}
		else iSetFlags -= this.admin.GetFlags(Access_Real);

		this.admin.SetBitFlags(iSetFlags, true);
		this.flagsDiff = iSetFlags;

		this.immunityDiff = g_iImmunityIncrease;
		if (this.immunityDiff)
			this.admin.ImmunityLevel += this.immunityDiff;
	}

	void RemoveAdmin()
	{
		if (this.admin != INVALID_ADMIN_ID)
		{
			if (this.flagsDiff)
				this.admin.SetBitFlags(this.flagsDiff, false);

			if (this.immunityDiff)
			{
				int iNewImmunity = this.admin.ImmunityLevel - this.immunityDiff;
				if (iNewImmunity < 0) iNewImmunity = 0;
				this.admin.ImmunityLevel = iNewImmunity;
			}
		}

		this.flagsDiff = 0;
		this.immunityDiff = 0;
	}

	void AnnounceChange(int iClient, int iOldHost, int iNewHost)
	{
		switch (g_iAnnounceSetting[iClient])
		{
			case Announce_None:
				return;

			case Announce_Affected:
			{
				if (iClient != iOldHost && iClient != iNewHost)
					return;
			}
		}

		CPrintToChatEx(iClient, iNewHost, "%t %t",
			"#tag_host", "#announce_host_change", iOldHost, iNewHost);
	}

	int Get()
	{
		return GetClientOfUserId(this.userid);
	}
}

methodmap AnnounceCookie < Cookie
{
	public AnnounceCookie(const char[] sName, const char[] sDesc, CookieAccess access)
	{
		return view_as<AnnounceCookie>(RegClientCookie(sName, sDesc, access));
	}

	public void UpdateAll()
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;

			this.Update(i);
		}
	}

	public void Update(int iClient)
	{
		if (AreClientCookiesCached(iClient))
		{
			int iValue;
			static char sValue[12];

			this.Get(iClient, sValue, sizeof(sValue));
			if ((StringToIntEx(sValue, iValue) > 0)
				&& (ANNOUNCE_ENUM_MIN <= iValue <= ANNOUNCE_ENUM_MAX))
			{
				g_iAnnounceSetting[iClient] = iValue;
				return;
			}
		}

		g_iAnnounceSetting[iClient] = g_iAnnounceSettingDefault;
	}
}

enum struct UserHostRecord
{
	int priority;
	int userid;
	float disconnectTime;

	void Init(int iUserID, bool bReserver = false)
	{
		this.priority = bReserver ? 0 : g_iPriorityCounter++;
		this.userid = iUserID;
		this.disconnectTime = -1.0;
	}
}

methodmap HostRecords < StringMap
{
	public HostRecords()
	{
		return view_as<HostRecords>(CreateTrie());
	}

	public void Reset()
	{
		g_iPriorityCounter = 1;
		this.Clear();
	}

	public bool GetUserRecord(int iClient, char sKey[12], UserHostRecord recordBuffer, bool bReserver = false)
	{
		int iSteamID = GetSteamAccountID(iClient);
		int iUserID = GetClientUserId(iClient);

		IntToString(iSteamID, sKey, sizeof(sKey));

		if (!bReserver && this.GetArray(sKey, recordBuffer, sizeof(recordBuffer)))
		{
			if (iUserID == recordBuffer.userid)
			{
				this.Touch(recordBuffer);
				return true;
			}

			if (recordBuffer.disconnectTime >= 0.0
				&& (GetGameTime() - recordBuffer.disconnectTime) < g_fHostRecordTimeout)
			{
				this.Touch(recordBuffer);
				return true;
			}
		}

		recordBuffer.Init(iUserID, bReserver);
		return false;
	}

	public void Touch(UserHostRecord record)
	{
		record.disconnectTime = -1.0;
	}

	public void SetPriority(int iClient)
	{
		char sKey[12];
		UserHostRecord record;

		if (!this.GetUserRecord(iClient, sKey, record))
			this.SetArray(sKey, record, sizeof(record));

		g_iClientPriority[iClient] = record.priority;
	}

	public void SetReserverPriority(int iClient)
	{
		char sKey[12];
		UserHostRecord record;

		this.GetUserRecord(iClient, sKey, record, true);
		this.SetArray(sKey, record, sizeof(record));

		g_bWaitingForReserver = false;
		g_iClientPriority[iClient] = record.priority;
	}

	public void SetDisconnectTime(int iClient)
	{
		char sKey[12];
		UserHostRecord record;

		this.GetUserRecord(iClient, sKey, record);

		record.disconnectTime = GetGameTime();
		this.SetArray(sKey, record, sizeof(record));
	}

	public void Transfer(int from, int to)
	{
		char sFromKey[12];
		UserHostRecord fromRecord;
		this.GetUserRecord(from, sFromKey, fromRecord);
		int iUserIDSwap = fromRecord.userid;

		char sToKey[12];
		UserHostRecord toRecord;
		this.GetUserRecord(to, sToKey, toRecord);

		fromRecord.userid = toRecord.userid;
		this.SetArray(sToKey, fromRecord, sizeof(fromRecord));
		g_iClientPriority[to] = fromRecord.priority;

		toRecord.userid = iUserIDSwap;
		this.SetArray(sFromKey, toRecord, sizeof(toRecord));
		g_iClientPriority[from] = toRecord.priority;
	}

	/**
	 * when plugin loads late, we lose out on a lot of information.
	 * this method is a best attempt at setting the records to
	 * something usable, which is ranking priority by how long
	 * clients have been connected.
	 */
	public void Infer()
	{
		int iClients[MAXPLAYERS_L4D2 + 1];
		float fTimes[MAXPLAYERS_L4D2 + 1];
		int iAmount;

		float fTimeSwap;
		int iClientSwap;

		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client)) continue;
			if (IsFakeClient(client)) continue;

			iClients[iAmount] = client;
			fTimes[iAmount] = GetClientTime(client);

			/** sort */
			for (int i = iAmount; i > 0; i--)
			{
				if (fTimes[i] > fTimes[i - 1])
				{
					fTimeSwap = fTimes[i];
					iClientSwap = iClients[i];

					fTimes[i] = fTimes[i - 1];
					iClients[i] = iClients[i - 1];

					fTimes[i - 1] = fTimeSwap;
					iClients[i - 1] = iClientSwap;
				}
				else break;
			}

			iAmount++;
		}

		char sKey[12];
		UserHostRecord record;

		for (int i = 0; i < iAmount; i++)
		{
			if (!this.GetUserRecord(iClients[i], sKey, record))
				this.SetArray(sKey, record, sizeof(record));

			g_iClientPriority[iClients[i]] = record.priority;
		}
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	CreateNative("GetLobbyHost", Native_GetHostClient);
	g_bLateLoaded = bLate;

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_AdminFlags = CreateConVar(
		"host_player_admin_flags", "o",
		"temporary admin flags to grant players who are lobby host.",
		FCVAR_NOTIFY);
	g_hConVar_AdminFlags.AddChangeHook(ConVarChanged_Admin);

	g_hConVar_ImmunityIncrease = CreateConVar(
		"host_player_admin_immunity_increase", "1",
		"temporarily increase a lobby host's admin immunity level by this amount.",
		FCVAR_NOTIFY);
	g_hConVar_ImmunityIncrease.AddChangeHook(ConVarChanged_Admin);
	ReadAdminFlagConVar();

	g_hConVar_HostRecordTimeout = CreateConVar(
		"host_player_timeout", "600.0",
		"time in seconds since a player disconnects for their recorded priority to be the host is invalidated.",
		FCVAR_NOTIFY, true, 0.0);
	g_hConVar_HostRecordTimeout.AddChangeHook(ConVarChanged_Timeout);
	g_fHostRecordTimeout = g_hConVar_HostRecordTimeout.FloatValue;

	g_hConVar_AnnounceHostChange = CreateConVar(
		COOKIE_CONVAR, "1",
		"default value for the " ... COOKIE ... " cookie. determines if changes \
		to the lobby host should be announced to clients. \
		0 = off | 1 = to affected only | 2 = to everyone",
		FCVAR_NOTIFY, true, float(ANNOUNCE_ENUM_MIN), true, float(ANNOUNCE_ENUM_MAX));

	g_hConVar_AnnounceHostChange.AddChangeHook(ConVarChanged_Announce);
	g_iAnnounceSettingDefault = g_hConVar_AnnounceHostChange.IntValue;

	g_hCookie_AnnounceHostChange = new AnnounceCookie(
		COOKIE, "how do you want to receive an announcement for when the lobby \
		host changes? 0 = don't announce | 1 = only if my host status is changed | \
		2 = always announce", CookieAccess_Public);

	g_hForward_OnHostChanged = new GlobalForward(
		"OnLobbyHostChanged", ET_Ignore, Param_Cell, Param_Cell);

	LoadTranslations("host_player.phrases");
	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_host", Command_Host,
		"Prints the name of the lobby host.");
	RegConsoleCmd("sm_host_transfer", Command_TransferPriority,
		"Exchange host priority with a player whose priority is \
		lower than yours. Usage: /host_transfer <player name>");

	g_records = new HostRecords();

	if (g_bLateLoaded)
	{
		g_hCookie_AnnounceHostChange.UpdateAll();
		g_records.Infer();
		g_lastKnownHost.Update();

		#if defined _cookie_manager_included_
			if (LibraryExists(COOKIE_MANAGER_LIBRARY))
			{
				HookCookieChange(COOKIE, OnCookieChanged);
				g_bCookieHooked = true;
			}
		#endif
	}

	RegPluginLibrary(HOST_PLAYER_LIBRARY);
}

#if defined _cookie_manager_included_
	public void OnAllPluginsLoaded()
	{
		if (!g_bCookieHooked && LibraryExists(COOKIE_MANAGER_LIBRARY))
		{
			HookCookieChange(COOKIE, OnCookieChanged);
			g_bCookieHooked = true;
		}
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (!g_bCookieHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
		{
			HookCookieChange(COOKIE, OnCookieChanged);
			g_bCookieHooked = true;
		}
	}

	public void OnLibraryRemoved(const char[] sName)
	{
		if (g_bCookieHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookieHooked = false;
	}

	public void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		g_hCookie_AnnounceHostChange.Update(iClient);
	}
#endif

public void OnPluginEnd()
{
	g_lastKnownHost.RemoveAdmin();
}

void ConVarChanged_Timeout(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fHostRecordTimeout = g_hConVar_HostRecordTimeout.FloatValue;
}

void ConVarChanged_Admin(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadAdminFlagConVar();
	g_lastKnownHost.UpdateAdmin(g_lastKnownHost.Get());
}

void ReadAdminFlagConVar()
{
	char sFlags[22];
	g_hConVar_AdminFlags.GetString(sFlags, sizeof(sFlags));
	g_iAdminFlags = ReadFlagString(sFlags);

	g_iImmunityIncrease = g_hConVar_ImmunityIncrease.IntValue;
}

void ConVarChanged_Announce(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_iAnnounceSettingDefault = g_hConVar_AnnounceHostChange.IntValue;
	g_hCookie_AnnounceHostChange.UpdateAll();
}

public void OnClientCookiesCached(int iClient)
{
	if (!IsFakeClient(iClient))
		g_hCookie_AnnounceHostChange.Update(iClient);
}

/************
 * Commands
 ************/

Action Command_Host(int iClient, int iArgs)
{
	int iHost = GetHostClient();

	if (iHost == -1)
	{
		CReplyToCommand(iClient, "%t %t", "#tag_cmd_host", "#reply_no_host");
		return Plugin_Handled;
	}

	if (iHost == iClient)
	{
		CReplyToCommand(iClient, "%t %t", "#tag_cmd_host", "#reply_you_are_host");
		return Plugin_Handled;
	}

	CReplyToCommandEx(iClient, iHost, "%t %t", "#tag_cmd_host", "#reply_host_name", iHost);
	return Plugin_Handled;
}

Action Command_TransferPriority(int iClient, int iArgs)
{
	if (!iArgs)
	{
		CReplyToCommand(iClient, "%t %t", "#tag_cmd_host_transfer", "#reply_transfer_no_args");
		return Plugin_Handled;
	}

	static char sTarget[MAX_NAME_LENGTH];
	static char sBuffer[MAX_NAME_LENGTH];

	sTarget = "";
	int iLen;
	for (int i = 1; i <= iArgs; i++)
	{
		GetCmdArg(i, sBuffer, sizeof(sBuffer));
		iLen += StrCat(sTarget, sizeof(sTarget), sBuffer);
		if (i != iArgs) iLen += StrCat(sTarget, sizeof(sTarget), " ");
	}
	sTarget[iLen + 1] = '\0';

	int iTarget = FindTarget(iClient, sTarget, true, false);
	if (iTarget == -1)
		return Plugin_Handled;

	if (IsFakeClient(iTarget))
	{
		CReplyToCommandEx(iClient, iTarget, "%t %t", "#tag_cmd_host_transfer", "#reply_target_is_a_bot", iTarget);
		return Plugin_Handled;
	}

	if (g_iClientPriority[iTarget] <= g_iClientPriority[iClient])
	{
		CReplyToCommandEx(iClient, iTarget, "%t %t", "#tag_cmd_host_transfer", "#reply_target_must_be_higher", iTarget);
		return Plugin_Handled;
	}

	g_records.Transfer(iClient, iTarget);
	g_lastKnownHost.Update();

	CReplyToCommandEx(iClient, iTarget, "%t %t", "#tag_cmd_host_transfer", "#reply_transfer_successful", iTarget);
	return Plugin_Handled;
}

/********************************************
 * watch for clients connecting/disconnecting
 ********************************************/

public void OnGetFreeClient_Post(NetAdrType adrType, int iIP, int iPort, int iClient, bool bHandled)
{
	if (iClient > 0)
		g_iClientIP[iClient] = iIP;
}

public void OnClientPutInServer(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	g_hCookie_AnnounceHostChange.Update(iClient);
}

/** wait until this before doing host related stuff on a client so that they correctly
 * get their expected admin id before we mess around giving them the temp admin flags.*/
public void OnClientPostAdminCheck(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	if (g_bWaitingForReserver && g_iClientIP[iClient] == g_iReserverIP)
		g_records.SetReserverPriority(iClient);
	else g_records.SetPriority(iClient);

	g_lastKnownHost.Update();
}

public void OnClientDisconnect(int iClient)
{
	if (!IsClientConnected(iClient) || IsFakeClient(iClient))
		return;

	g_records.SetDisconnectTime(iClient);
	g_iClientPriority[iClient] = -1;

	g_lastKnownHost.Update();
}

/***********************************
 * detect reservation cookie changes
 **********************************/

public Action OnConnectionlessPacket(NetAdrType adrType, int iIP, int iPort, int iPacketType, const any[] packet, int iPacketSize)
{
	if (iPacketType == Packet_ReservationRequest)
		g_bReplyingToReservationRequest = true;

	return Plugin_Continue;
}

public void OnSetReservationCookie_Post(const int iCookie[2])
{
	if (g_bReplyingToReservationRequest)
		g_bReservationRequestAccepted = true;

	if (iCookie[0] == g_iReservationCookie[0]
		&& iCookie[1] == g_iReservationCookie[1])
		return;

	g_iReservationCookie[0] = iCookie[0];
	g_iReservationCookie[1] = iCookie[1];

	/** some servers may purposefully unreserve a server while a game with
	 * players is ongoing. records should only clear when the cookie changes
	 * to a non-zero number */
	if (!iCookie[0] && !iCookie[1])
		return;

	g_records.Reset();
	g_lastKnownHost.Update();
}

public void OnConnectionlessPacket_Post(NetAdrType adrType, int iIP, int iPort, int iPacketType, const any[] packet, int iPacketSize, bool bHandled)
{
	if (g_bReservationRequestAccepted)
	{
		g_bWaitingForReserver = true;
		g_iReserverIP = iIP;
	}

	g_bReplyingToReservationRequest = false;
	g_bReservationRequestAccepted = false;
}

/***********
 * Get host
 **********/

public any Native_GetHostClient(Handle hPlugin, int iNumParams)
{
	return g_lastKnownHost.Get();
}

int GetHostClient()
{
	int iLowestClient = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		if (g_iClientPriority[i] == -1) continue;

		if (iLowestClient == 0)
		{
			iLowestClient = i;
			continue;
		}

		if (g_iClientPriority[i] < g_iClientPriority[iLowestClient])
			iLowestClient = i;
	}

	return iLowestClient;
}
