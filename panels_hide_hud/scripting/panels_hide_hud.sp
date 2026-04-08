#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <sendproxy>
#include <hxstocks>

#undef REQUIRE_PLUGIN
#include <cookie_manager>

#define CONVAR_NAME_SURVIVOR	"cookie_panels_hide_hud_survivor"
#define COOKIE_NAME_SURVIVOR	"panels_hide_hud_survivor"

#define CONVAR_NAME_INFECTED	"cookie_panels_hide_hud_infected"
#define COOKIE_NAME_INFECTED	"panels_hide_hud_infected"

public Plugin myinfo =
{
	name = "Panels Hide HUD",
	author = "Neburai",
	description = "Optional via cookie. Opened panels like the admin menu, etc, will hide HUD elements likely to overlap",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/panels_hide_hud"
};

bool g_bLateLoaded;

int g_iTerrorPlayerManagerRef = INVALID_ENT_REFERENCE;
UserMessageRecord g_PZDamageUserMessageRecord;
bool g_bResendPZDamageUserMessage;
bool g_bPluginBroadcastingPZDamageMessageEvent;

Cookie g_hCookie_ShouldHideHud[2];
ConVar g_hConVar_ShouldHideHudDefault[2];

bool g_bShouldHideHudDefault[2];
bool g_bShouldHideHud[MAXPLAYERS_L4D2+1][2];

#if defined _cookie_manager_included_
	bool g_bCookiesHooked;
#endif

enum struct UserMessageRecord
{
	any buffer[16];
	int bufferSize;

	int players[MAXPLAYERS_L4D2];
	int playersNum;

	int flags;

	void Record(BfRead msg, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
	{
		this.bufferSize = 0;
		while (msg.BytesLeft)
			this.buffer[this.bufferSize++] = msg.ReadByte();

		this.playersNum = 0;
		for (int i = 0; i < iPlayersNum; i++)
			this.players[this.playersNum++] = iPlayers[i];

		this.flags = USERMSG_BLOCKHOOKS;
		if (bReliable) this.flags |= USERMSG_RELIABLE;
		if (bInit) this.flags |= USERMSG_INITMSG;
	}

	void Send()
	{
		int[] iPlayers = new int[this.playersNum];
		int iPlayersNum;
		for (int i = 0; i < this.playersNum; i++)
		{
			if (!IsClientInGame(this.players[i])) continue;
			if (IsFakeClient(this.players[i])) continue;
			if (ShouldHideHud(this.players[i], GetClientTeam(this.players[i]))) continue;

			iPlayers[iPlayersNum++] = this.players[i];
		}

		if (!iPlayersNum) return;

		BfWrite msg = view_as<BfWrite>(StartMessage("PZDmgMsg", iPlayers, iPlayersNum, this.flags));

		for (int i = 0; i < this.bufferSize; i++)
			msg.WriteByte(this.buffer[i]);

		EndMessage();
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_ShouldHideHudDefault[Team_Survivor - 2] = CreateConVar(
		CONVAR_NAME_SURVIVOR, "1",
		"set the default value for the " ...  COOKIE_NAME_SURVIVOR ... " cookie. 1 or 0",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVar_ShouldHideHudDefault[Team_Survivor - 2].AddChangeHook(ConVarChanged_Update);

	g_hConVar_ShouldHideHudDefault[Team_Infected - 2] = CreateConVar(
		CONVAR_NAME_INFECTED, "0",
		"set the default value for the " ... COOKIE_NAME_INFECTED ... " cookie. 1 or 0",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVar_ShouldHideHudDefault[Team_Infected - 2].AddChangeHook(ConVarChanged_Update);

	ReadConVars();

	g_hCookie_ShouldHideHud[Team_Survivor - 2] = new Cookie(COOKIE_NAME_SURVIVOR,
		"survivor team only. when a panel opens, should we hide commonly overlapped HUD elements? 1 (hide) or 0 (don't hide)",
		CookieAccess_Public);

	g_hCookie_ShouldHideHud[Team_Infected - 2] = new Cookie(COOKIE_NAME_INFECTED,
		"infected team only. when a panel opens, should we hide commonly overlapped HUD elements? 1 (hide) or 0 (don't hide)",
		CookieAccess_Public);

	HookEvent("player_death", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("defibrillator_used", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("versus_marker_reached", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("survival_goal_reached", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_OnPZDamageMessage, EventHookMode_Pre);

	HookUserMessage(GetUserMessageId("PZDmgMsg"), MsgHook_OnPZDamageMessage, true, MsgHookPost_OnPZDamageMessage);

	if (!g_bLateLoaded) return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;

		if (AreClientCookiesCached(i))
		{
			ReadCookies(i);
			continue;
		}

		ReadDefaults(i);
	}

	int iTerrorPlayerManager = GetTerrorPlayerManager();
	if (iTerrorPlayerManager != INVALID_ENT_REFERENCE)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			SendProxy_HookArrayProp(iTerrorPlayerManager, "m_iTeam", i, Prop_Int, HideTeamHealthHud);

			if (!IsFakeClient(i))
				ReadCookies(i);
		}
	}

	#if defined _cookie_manager_included_
		if (LibraryExists(COOKIE_MANAGER_LIBRARY))
			HookCookies();
	#endif
}

#if defined _cookie_manager_included_
	void HookCookies()
	{
		HookCookieChange(COOKIE_NAME_SURVIVOR, OnCookieChanged);
		HookCookieChange(COOKIE_NAME_INFECTED, OnCookieChanged);
		g_bCookiesHooked = true;
	}

	public void OnAllPluginsLoaded()
	{
		if (!g_bCookiesHooked && LibraryExists(COOKIE_MANAGER_LIBRARY))
			HookCookies();
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (!g_bCookiesHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			HookCookies();
	}

	public void OnLibraryRemoved(const char[] sName)
	{
		if (g_bCookiesHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookiesHooked = false;
	}

	public void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		ReadCookies(iClient);
	}
#endif

public void OnClientConnected(int iClient)
{
	ReadDefaults(iClient);
}

public void OnClientPutInServer(int iClient)
{
	int iTerrorPlayerManager = GetTerrorPlayerManager();
	if (iTerrorPlayerManager != INVALID_ENT_REFERENCE)
		SendProxy_HookArrayProp(iTerrorPlayerManager, "m_iTeam", iClient, Prop_Int, HideTeamHealthHud);
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	for (int i = 0; i < 2; i++)
		g_bShouldHideHudDefault[i] = g_hConVar_ShouldHideHudDefault[i].BoolValue;
}

public void OnClientCookiesCached(int iClient)
{
	ReadCookies(iClient);
}

void ReadDefaults(int iClient)
{
	for (int i = 0; i < 2; i++)
		g_bShouldHideHud[iClient][i] = g_bShouldHideHudDefault[i];
}

void ReadCookies(int iClient)
{
	for (int i = 0; i < 2; i++)
		g_bShouldHideHud[iClient][i] = !!g_hCookie_ShouldHideHud[i].GetInt(iClient, g_bShouldHideHudDefault[i]);
}

/*******
 * util
 *******/

int GetTerrorPlayerManager()
{
	int iEnt = EntRefToEntIndex(g_iTerrorPlayerManagerRef);
	if (iEnt != INVALID_ENT_REFERENCE)
		return iEnt;

	iEnt = FindEntityByClassname(-1, "terror_player_manager");

	if (iEnt != -1)
	{
		g_iTerrorPlayerManagerRef = EntIndexToEntRef(iEnt);
		return iEnt;
	}

	return INVALID_ENT_REFERENCE;
}

bool ShouldHideHud(int iClient, int iTeam)
{
	iTeam -= 2;
	if (iTeam < 0 || iTeam >= 2) return false;

	return g_bShouldHideHud[iClient][iTeam] && GetClientMenu(iClient) != MenuSource_None;
}

/*****************
 * hide hud hooks
 ****************/

/** health.
 * note on versus:
 * if you're on the infected team, there is no "non infected team" we can
 * use as our lied value that result in you and your teammate's name as
 * the expected red colour.
 * for survivors, we have the "fake survivor team" used in examples like
 * passing map 1. players on this team have their name appear as blue still,
 * so nothing appears out of the ordinary.
 *
 * for infected players, everyone's name in chat will appear the wrong colour.
 * this bug is only visible to you. the issue is client sided.
 *
 * there's a cookie for each team you could be on to help. infected default to
 * off due to the buggy behaviour described
 */
Action HideTeamHealthHud(const int iEntity, const char[] cPropName, int &iValue, const int iElement, const int iClient)
{
	if ((iValue == Team_Survivor || iValue == Team_Infected)
		&& iValue == GetClientTeam(iClient)
		&& ShouldHideHud(iClient, iValue))
	{
		switch (iValue)
		{
			case Team_Survivor: iValue = Team_Actors;
			case Team_Infected: iValue = Team_Unassigned;
		}

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/** red text */
Action Event_OnPZDamageMessage(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (g_bPluginBroadcastingPZDamageMessageEvent)
		return Plugin_Continue;

	g_bPluginBroadcastingPZDamageMessageEvent = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		if (ShouldHideHud(i, GetClientTeam(i))) continue;

		hEvent.FireToClient(i);
	}

	g_bPluginBroadcastingPZDamageMessageEvent = false;
	return Plugin_Handled;
}

/** white text */
Action MsgHook_OnPZDamageMessage(UserMsg msg_id, BfRead msg, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
{
	if (iPlayersNum == 1)
	{
		if (ShouldHideHud(iPlayers[0], GetClientTeam(iPlayers[0])))
			return Plugin_Handled;
	}

	/** vanilla always sends to 1 player at a time.
	 * this is to support the user message being sent
	 * by a mod that has > 1 recipient */
	else
	{
		g_PZDamageUserMessageRecord.Record(msg, iPlayers, iPlayersNum, bReliable, bInit);
		g_bResendPZDamageUserMessage = true;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void MsgHookPost_OnPZDamageMessage(UserMsg msg_id, bool sent)
{
	if (g_bResendPZDamageUserMessage)
	{
		g_bResendPZDamageUserMessage = false;
		g_PZDamageUserMessageRecord.Send();
	}
}
