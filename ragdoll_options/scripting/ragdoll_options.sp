#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <hxlib>

#undef REQUIRE_PLUGIN
#include <cookie_manager>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define COOKIE_FADE			"ragdoll_fade"
#define	COOKIE_CI_BEGONE	"ragdoll_ci_begone"

public Plugin myinfo =
{
	name = "Ragdoll Options",
	author = "Neburai",
	description = "Per-client implementaion of ragdoll fades and commons disappearing instantly on death",
	version = "1.2",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/ragdoll_options"
};

bool	g_bLateLoaded;

#if defined _cookie_manager_included_
	bool g_bCookiesHooked;
#endif

Setting	g_fadeEnabled;
Setting	g_removeCommonRagdoll;
Fader	g_ragdollFader;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_ragdollFader.Init();

	g_removeCommonRagdoll.Init(
		COOKIE_CI_BEGONE, "toggle common infected disappearing instantly on death. \
		1 for enabled, 0 for disabled", false);

	g_fadeEnabled.Init(
		COOKIE_FADE, "toggle infected ragdolls fading on death", false);

	#if defined _cookie_manager_included_
		if (LibraryExists(COOKIE_MANAGER_LIBRARY))
			HookCookies();
	#endif

	if (g_bLateLoaded)
	{
		g_removeCommonRagdoll.UpdateAll();
		g_fadeEnabled.UpdateAll();
		g_ragdollFader.Create();
	}

	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
}

public void OnPluginEnd()
{
	g_ragdollFader.Remove();
}

void Event_RoundFreezeEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	g_ragdollFader.Refresh();
}

/**********
 * settings
 **********/

enum struct Setting
{
	Cookie cookie;
	bool value[MAXPLAYERS_L4D2 + 1];

	ConVar defaultConVar;
	bool defaultValue;

	void Init(const char[] sName, const char[] sDesc, bool bDefault)
	{
		char sConVarName[COOKIE_MAX_NAME_LENGTH + 8];
		char sConVarDesc[COOKIE_MAX_NAME_LENGTH + COOKIE_MAX_DESCRIPTION_LENGTH + 50];

		FormatEx(sConVarName, sizeof(sConVarName), "cookie_%s", sName);
		FormatEx(sConVarDesc, sizeof(sConVarDesc), "default value for \"%s\" cookie. description: %s", sName, sDesc);

		this.defaultConVar = CreateConVar(
			sConVarName, bDefault ? "1" : "0", sConVarDesc,
			CVAR_FLAGS, true, 0.0, true, 1.0);
		this.defaultConVar.AddChangeHook(ConVarChanged_Update);
		this.defaultValue = bDefault;

		this.cookie = new Cookie(sName, sDesc, CookieAccess_Public);
	}

	bool UpdateDefault()
	{
		this.defaultValue = this.defaultConVar.BoolValue;
		return this.UpdateAll();
	}

	bool UpdateAll()
	{
		bool bRet = false;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsFakeClient(i)) continue;

			if (this.Update(i)) bRet = true;
		}

		return bRet;
	}

	bool Update(int iClient)
	{
		bool bSet = this.defaultValue;

		if (AreClientCookiesCached(iClient))
		{
			char sValue[2];
			this.cookie.Get(iClient, sValue, sizeof(sValue));
			switch (sValue[0])
			{
				case '0': bSet = false;
				case '1': bSet = true;
			}
		}

		bool bRet = false;
		if (this.value[iClient] != bSet) bRet = true;

		this.value[iClient] = bSet;
		return bRet;
	}
}

#if defined _cookie_manager_included_
	void HookCookies()
	{
		g_bCookiesHooked = true;
		HookCookieChange(COOKIE_FADE, OnCookieChanged);
		HookCookieChange(COOKIE_CI_BEGONE, OnCookieChanged);
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			HookCookies();
	}

	public void OnLibraryRemoved(const char[] sName)
	{
		if (g_bCookiesHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookiesHooked = false;
	}

	void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		g_removeCommonRagdoll.Update(iClient);
		if (g_fadeEnabled.Update(iClient)) g_ragdollFader.Refresh();
	}
#endif

public void OnClientPutInServer(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	g_removeCommonRagdoll.Update(iClient);
	if (g_fadeEnabled.Update(iClient)) g_ragdollFader.Refresh();
}

public void OnClientCookiesCached(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	g_removeCommonRagdoll.Update(iClient);
	if (g_fadeEnabled.Update(iClient)) g_ragdollFader.Refresh();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_removeCommonRagdoll.UpdateDefault();
	if (g_fadeEnabled.UpdateDefault()) g_ragdollFader.Refresh();
}

/*******
 * Fade
 *******/

enum struct Fader
{
	int entref;

	void Init()
	{
		this.entref = INVALID_ENT_REFERENCE;
	}

	void Refresh()
	{
		this.Remove();
		this.Create();
	}

	void Remove()
	{
		int iEntity = EntRefToEntIndex(this.entref);
		if (iEntity != INVALID_ENT_REFERENCE)
			RemoveEntity(iEntity);
	}

	void Create()
	{
		int iEntity = CreateEntityByName("func_ragdoll_fader");
		if (iEntity == INVALID_ENT_REFERENCE)
		{
			this.entref = INVALID_ENT_REFERENCE;
			return;
		}

		SDKHook(iEntity, SDKHook_SetTransmit, OnTransmitFader);
		TeleportEntity(iEntity, {0.0, 0.0, 0.0});
		DispatchSpawn(iEntity);
		this.entref = EntIndexToEntRef(iEntity);

		SetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", {999999.0, 999999.0, 999999.0});
		SetEntPropVector(iEntity, Prop_Send, "m_vecMins", {-999999.0, -999999.0, -999999.0});
		SetEntProp(iEntity, Prop_Send, "m_nSolidType", 2);
	}
}

Action OnTransmitFader(int iEntity, int iClient)
{
	if (g_fadeEnabled.value[iClient])
		return Plugin_Continue;

	return Plugin_Handled;
}

/******************
 * commons be-gone
 *****************/

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (strcmp(sClass, "infected") == 0)
		AddEntityHook(iEntity, EntityHook_EventKilled, EHook_Post, OnKilled_Post);
}

void OnKilled_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType,
	int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	if (!bHandled) SDKHook(iVictim, SDKHook_SetTransmit, OnTransmitCommon);
}

Action OnTransmitCommon(int iEntity, int iClient)
{
	if (IsEntityAlive(iEntity))
	{
		SDKUnhook(iEntity, SDKHook_SetTransmit, OnTransmitCommon);
		return Plugin_Continue;
	}

	if (g_removeCommonRagdoll.value[iClient])
		return Plugin_Handled;

	return Plugin_Continue;
}
