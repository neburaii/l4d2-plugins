#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <cookie_manager>

#define COOKIE_ROLL_ANGLE	"roll_angle"

public Plugin myinfo =
{
	name = "Roll Angle Setting",
	author = "Neburai",
	description = "Per-client setting for the sv_rollangle convar",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/roll_angle"
};

bool			g_bLateLoaded;

ConVar			g_hConVar_RollAngle;
char			g_sRollAngleDefault[12];

RollAngleCookie	g_hCookie_RollAngle;

#if defined _cookie_manager_included_
	bool g_bCookieHooked;
#endif

methodmap RollAngleCookie < Cookie
{
	public RollAngleCookie(const char[] sName, const char[] sDesc, CookieAccess access)
	{
		return view_as<RollAngleCookie>(RegClientCookie(sName, sDesc, access));
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
		bool bUseDefault = true;
		static char sValue[12];

		if (AreClientCookiesCached(iClient))
		{
			this.Get(iClient, sValue, sizeof(sValue));
			if (IsCharNumeric(sValue[0]))
				bUseDefault = false;
		}

		g_hConVar_RollAngle.ReplicateToClient(iClient, bUseDefault ? g_sRollAngleDefault : sValue);
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
}

public void OnPluginStart()
{
	g_hCookie_RollAngle = new RollAngleCookie(
		COOKIE_ROLL_ANGLE,
		"set the sv_rollangle convar for yourself. must be an integer from 0 through 360.",
		CookieAccess_Public);

	g_hConVar_RollAngle = FindConVar("sv_rollangle");
	g_hConVar_RollAngle.Flags &= ~FCVAR_REPLICATED;
	g_hConVar_RollAngle.AddChangeHook(ConVarChanged_Update);
	g_hConVar_RollAngle.GetString(g_sRollAngleDefault, sizeof(g_sRollAngleDefault));

	if (g_bLateLoaded)
	{
		g_hCookie_RollAngle.UpdateAll();

		#if defined _cookie_manager_included_
			if (LibraryExists(COOKIE_MANAGER_LIBRARY))
			{
				HookCookieChange(COOKIE_ROLL_ANGLE, OnCookieChanged);
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
			HookCookieChange(COOKIE_ROLL_ANGLE, OnCookieChanged);
			g_bCookieHooked = true;
		}
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (!g_bCookieHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
		{
			HookCookieChange(COOKIE_ROLL_ANGLE, OnCookieChanged);
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
		g_hCookie_RollAngle.Update(iClient);
	}
#endif

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_hConVar_RollAngle.GetString(g_sRollAngleDefault, sizeof(g_sRollAngleDefault));
	g_hCookie_RollAngle.UpdateAll();
}

public void OnClientPutInServer(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	g_hCookie_RollAngle.Update(iClient);
}

public void OnClientCookiesCached(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	g_hCookie_RollAngle.Update(iClient);
}
