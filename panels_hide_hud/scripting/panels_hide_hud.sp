#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <sendproxy>
#include <hxstocks>

#undef REQUIRE_PLUGIN
#include <cookie_manager>

#define COOKIE_NAME_SURVIVOR	"panels_hide_hud_survivor"
#define COOKIE_NAME_INFECTED	"panels_hide_hud_infected"

public Plugin myinfo =
{
	name = "Panels Hide HUD",
	author = "Neburai",
	description = "Optional via cookie. Opened panels like the admin menu, etc, will hide HUD elements likely to overlap",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/panels_hide_hud"
};

bool g_bLateLoaded;
#if defined _cookie_manager_included_
	bool g_bCookiesHooked;
#endif

UserMessageRecord g_PZDamageUserMessageRecord;
bool g_bResendPZDamageUserMessage;

CookieEx g_hideSurvivor;
CookieEx g_hideInfected;

enum struct CookieEx
{
	ConVar defaultConVar;
	bool defaultValue;

	Cookie cookie;
	bool value[MAXPLAYERS_L4D2 + 1];

	void Init(const char[] sName, bool bDefault, const char[] sDesc)
	{
		this.cookie = new Cookie(sName, sDesc, CookieAccess_Public);

		char sCName[40];
		char sCDesc[330];
		FormatEx(sCName, sizeof(sCName), "cookie_%s", sName);
		FormatEx(sCDesc, sizeof(sCDesc), "default value for \"%s\" cookie. desc:\n\"%s\"", sName, sDesc);

		this.defaultConVar = CreateConVar(sCName, bDefault ? "1" : "0", sCDesc, FCVAR_NOTIFY, true, 0.0, true, 1.0);
		this.defaultConVar.AddChangeHook(ConVarChanged_Cookie);
	}

	void UpdateDefault()
	{
		this.defaultValue = this.defaultConVar.BoolValue;
	}

	void Update(int iClient)
	{
		if (AreClientCookiesCached(iClient))
		{
			static char sValue[2];
			this.cookie.Get(iClient, sValue, sizeof(sValue));

			switch (sValue[0])
			{
				case '1': this.value[iClient] = true;
				case '0': this.value[iClient] = false;
				default: this.value[iClient] = this.defaultValue;
			}
		}
		else this.value[iClient] = this.defaultValue;
	}
}

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
	g_hideSurvivor.Init(
		COOKIE_NAME_SURVIVOR, true,
		"survivor team only. when a panel opens, should we hide commonly overlapped HUD elements? 1 (hide) or 0 (don't hide)");

	g_hideInfected.Init(
		COOKIE_NAME_INFECTED, false,
		"infected team only. when a panel opens, should we hide commonly overlapped HUD elements? 1 (hide) or 0 (don't hide)");

	UpdateCookieDefaults();

	HookEvent("player_death", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("defibrillator_used", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("versus_marker_reached", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("survival_goal_reached", Event_OnPZDamageMessage, EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_OnPZDamageMessage, EventHookMode_Pre);

	HookUserMessage(GetUserMessageId("PZDmgMsg"), MsgHook_OnPZDamageMessage, true, MsgHookPost_OnPZDamageMessage);

	if (g_bLateLoaded)
	{
		UpdateAllCookies();

		int iEnt = FindEntityByClassname(-1, "terror_player_manager");
		if (iEnt != -1) HookTerrorPlayerManager(iEnt);

		#if defined _cookie_manager_included_
			if (LibraryExists(COOKIE_MANAGER_LIBRARY))
				HookCookies();
		#endif
	}
}

#if defined _cookie_manager_included_
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
		if (strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookiesHooked = false;
	}

	void HookCookies()
	{
		HookCookieChange(COOKIE_NAME_SURVIVOR, OnCookieChanged);
		HookCookieChange(COOKIE_NAME_INFECTED, OnCookieChanged);
		g_bCookiesHooked = true;
	}

	public void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		UpdateCookies(iClient);
	}
#endif

public void OnClientPutInServer(int iClient)
{
	UpdateCookies(iClient);
}

public void OnClientCookiesCached(int iClient)
{
	UpdateCookies(iClient);
}

void ConVarChanged_Cookie(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	UpdateCookieDefaults();
	UpdateAllCookies();
}

void UpdateCookieDefaults()
{
	g_hideSurvivor.UpdateDefault();
	g_hideInfected.UpdateDefault();
}

void UpdateAllCookies()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)
			|| IsFakeClient(i))
			continue;

		UpdateCookies(i);
	}
}

void UpdateCookies(int iClient)
{
	g_hideSurvivor.Update(iClient);
	g_hideInfected.Update(iClient);
}

/*****************
 * hide hud hooks
 ****************/

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (strcmp(sClass, "terror_player_manager") == 0)
		RequestFrame(HookTerrorPlayerManager, EntIndexToEntRef(iEntity));
}

void HookTerrorPlayerManager(int iEntRef)
{
	int iEntity = EntRefToEntIndex(iEntRef);
	if (iEntity == INVALID_ENT_REFERENCE)
		return;

	for (int i = 1; i <= MAXPLAYERS_L4D2; i++)
		SendProxy_HookEntity(iEntity, "m_iTeam", Prop_Int, HideTeamHealthHud, i);
}

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
		&& IsValidClient(iElement)
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
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		if (ShouldHideHud(i, GetClientTeam(i))) continue;

		hEvent.FireToClient(i);
	}

	hEvent.BroadcastDisabled = true;
	return Plugin_Continue;
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

/********
 * check
 *******/
bool ShouldHideHud(int iClient, int iTeam)
{
	if (GetClientMenu(iClient) == MenuSource_None)
		return false;

	switch (iTeam)
	{
		case Team_Survivor:
			return g_hideSurvivor.value[iClient];
		case Team_Infected:
			return g_hideInfected.value[iClient];
	}

	return false;
}
