#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <hxlib>

#undef REQUIRE_PLUGIN
	#include <cookie_manager>
#define REQUIRE_PLUGIN

#define	COOKIE_ENABLE_GLOW	"enable_glow"
#define	CONVAR_ENABLE_GLOW	"cookie_enable_glow"

public Plugin myinfo =
{
	name = "Glow Cookies",
	author = "Neburai",
	description = "let's clients enable/disable glows",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/glow_cookies"
};

#if defined _cookie_manager_included_
	bool	g_bCookieHooked;
#endif

bool		g_bLateLoaded;

ConVar		g_hConVar_DisableItemGlow;
ConVar		g_hConVar_DisableSurvivorGlow;
ConVar		g_hConVar_GameMode;

GlowCookie	g_hCookie_EnableGlow;
ConVar		g_hConVar_EnableGlowDefault;
bool		g_bEnableGlowDefault;

ConVar		g_hConVar_GameModeBlacklist;
StringMap	g_hMap_GamemodeBlacklist;
bool		g_bGamemodeAllows;

methodmap GlowCookie < Cookie
{
	public GlowCookie(const char[] sName, const char[] sDesc, CookieAccess access)
	{
		return view_as<GlowCookie>(RegClientCookie(sName, sDesc, access));
	}

	public void UpdateAll()
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i)
				|| IsFakeClient(i))
				continue;

			this.Update(i);
		}
	}

	public void Update(int iClient)
	{
		if (g_bGamemodeAllows)
		{
			bool bValue = g_bEnableGlowDefault;

			if (AreClientCookiesCached(iClient))
			{
				char sValue[2];
				this.Get(iClient, sValue, sizeof(sValue));
				switch (sValue[0])
				{
					case '1': bValue = true;
					case '0': bValue = false;
				}
			}

			if (bValue)
			{
				g_hConVar_DisableItemGlow.ReplicateToClient(iClient, "0");
				g_hConVar_DisableSurvivorGlow.ReplicateToClient(iClient, "0");
			}
			else
			{
				g_hConVar_DisableItemGlow.ReplicateToClient(iClient, "1");
				g_hConVar_DisableSurvivorGlow.ReplicateToClient(iClient, "1");
			}
		}
		else
		{
			char sValue[2];

			g_hConVar_DisableItemGlow.GetString(sValue, sizeof(sValue));
			g_hConVar_DisableItemGlow.ReplicateToClient(iClient, sValue);

			g_hConVar_DisableSurvivorGlow.GetString(sValue, sizeof(sValue));
			g_hConVar_DisableSurvivorGlow.ReplicateToClient(iClient, sValue);
		}
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_DisableItemGlow = FindConVar("sv_disable_glow_faritems");
	g_hConVar_DisableSurvivorGlow = FindConVar("sv_disable_glow_survivors");
	g_hConVar_DisableItemGlow.Flags &= ~FCVAR_REPLICATED;
	g_hConVar_DisableSurvivorGlow.Flags &= ~FCVAR_REPLICATED;
	g_hConVar_DisableItemGlow.AddChangeHook(ConVarChanged_Glow);
	g_hConVar_DisableSurvivorGlow.AddChangeHook(ConVarChanged_Glow);

	g_hConVar_GameModeBlacklist = CreateConVar(
		"glow_cookies_gamemode_blacklist", "realism",
		"comma separated base gamemodes to disable glow cookies in. in a blacklisted \
		gamemode, the glow convar default values will always be replicated to clients.",
		FCVAR_NOTIFY);
	g_hConVar_GameModeBlacklist.AddChangeHook(ConVarChanged_Blacklist);

	g_hConVar_GameMode = FindConVar("mp_gamemode");
	g_hConVar_GameMode.AddChangeHook(ConVarChanged_GameMode);

	g_hCookie_EnableGlow = new GlowCookie(
		COOKIE_ENABLE_GLOW,
		"if the gamemode doesn't force item/survivor glows, then this cookie's value \
		is used to toggle the glows.", CookieAccess_Public);

	g_hConVar_EnableGlowDefault = CreateConVar(
		CONVAR_ENABLE_GLOW, "1",
		"default value for " ... COOKIE_ENABLE_GLOW ... " cookie.",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVar_EnableGlowDefault.AddChangeHook(ConVarChanged_CookieDefault);
	g_bEnableGlowDefault = g_hConVar_EnableGlowDefault.BoolValue;

	g_hMap_GamemodeBlacklist = new StringMap();
	UpdateBlackList();
	UpdateGameMode();

	if (g_bLateLoaded)
	{
		g_hCookie_EnableGlow.UpdateAll();

		#if defined _cookie_manager_included_
			if (LibraryExists(COOKIE_MANAGER_LIBRARY))
			{
				HookCookieChange(COOKIE_ENABLE_GLOW, OnCookieChanged);
				g_bCookieHooked = true;
			}
		#endif
	}
}

#if defined _cookie_manager_included_
	public void OnAllPluginsLoaded()
	{
		if (!g_bCookieHooked && LibraryExists(COOKIE_MANAGER_LIBRARY))
		{
			HookCookieChange(COOKIE_ENABLE_GLOW, OnCookieChanged);
			g_bCookieHooked = true;
		}
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (!g_bCookieHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
		{
			HookCookieChange(COOKIE_ENABLE_GLOW, OnCookieChanged);
			g_bCookieHooked = true;
		}
	}

	public void OnLibraryRemoved(const char[] sName)
	{
		if (strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookieHooked = false;
	}

	void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		g_hCookie_EnableGlow.Update(iClient);
	}
#endif

public void OnClientPutInServer(int iClient)
{
	if (!IsFakeClient(iClient))
		g_hCookie_EnableGlow.Update(iClient);
}

public void OnClientCookiesCached(int iClient)
{
	if (!IsFakeClient(iClient))
		g_hCookie_EnableGlow.Update(iClient);
}

void ConVarChanged_CookieDefault(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bEnableGlowDefault = g_hConVar_EnableGlowDefault.BoolValue;
	g_hCookie_EnableGlow.UpdateAll();
}

/** even with no replicate flag, some situations like gamemode changes can cause the client
 * side convar to still update. not sure how, but this counter should be sufficient. */
void ConVarChanged_Glow(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	RequestFrame(DelayedCookieUpdate);
}

void DelayedCookieUpdate()
{
	g_hCookie_EnableGlow.UpdateAll();
}

/*********************************
 * manage gamemode allows status
 ********************************/

void ConVarChanged_Blacklist(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	UpdateBlackList();
	UpdateGameMode();
	g_hCookie_EnableGlow.UpdateAll();
}

void ConVarChanged_GameMode(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	UpdateGameMode();
}

void UpdateBlackList()
{
	g_hMap_GamemodeBlacklist.Clear();

	char sGameModeList[128];
	g_hConVar_GameModeBlacklist.GetString(sGameModeList, sizeof(sGameModeList));
	int iWrite;
	char sBuffer[32];

	for (int i = 0; i < sizeof(sGameModeList); i++)
	{
		if (sGameModeList[i] == ',' || sGameModeList[i] == '\0')
		{
			if (iWrite)
			{
				sBuffer[iWrite] = '\0';
				g_hMap_GamemodeBlacklist.SetValue(sBuffer, true);
				iWrite = 0;
			}

			if (sGameModeList[i] == '\0') break;
			else continue;
		}

		sBuffer[iWrite++] = sGameModeList[i];
	}
}

void UpdateGameMode()
{
	char sGameMode[32];
	g_hConVar_GameMode.GetString(sGameMode, sizeof(sGameMode));
	GetGameModeInfo(sGameMode).GetBase(sGameMode, sizeof(sGameMode));

	g_bGamemodeAllows = !g_hMap_GamemodeBlacklist.ContainsKey(sGameMode);
}
