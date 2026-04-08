#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>
#include <left4dhooks>
#include <hxlib>

#undef REQUIRE_PLUGIN
#include <cookie_manager>

#define CVAR_FLAGS				FCVAR_NOTIFY

#define	COOKIE_RECOIL			"view_punch_recoil"
#define CONVAR_DEFAULT_RECOIL	"cookie_view_punch_recoil"

public Plugin myinfo =
{
	name = "View Punch Control",
	author = "Neburai",
	description = "Provides ConVars to modify view punch from many sources. view punch from weapon recoil uses a cookie as a toggle",
	version = "3.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/view_punch_control"
};

/**
 * recoil isn't a source we want to multiply, but toggle on/off instead.
 *
 * for recoil, punch angle will stack off of previous punch angles.
 * increasing beyond 1.0 will make automatic weapons literally revolve
 * the player's camera around them. implementing a multiplier for this
 * would need to be done differently.
 *
 * the other issue is that part of the recoil is client sided. the client
 * is replicated the punch convars for recoil, along with relevant
 * variables from the weapon database. multiplier < 1.0 isn't noticeable
 * at all, even if you adjusted the implementation with the > 1.0 values
 * in mind. the only accurate way to set a smaller multiplier is via
 * a weapon script.
 *
 * to make < 1.0 work, we'd need to find a way to lie to the client about
 * variables from the weapon database. this is only if we want it to be
 * done per-client though. you don't even need this plugin if you want
 * to do it globally only. just modify weapon scripts for that.
 *
 * personally i can't be bothered since i hate the recoil and rather
 * it fully disabled. with no incentive, i opted to take the easy route
 * by making recoil a toggle rather than a multiplier.
 */

enum MultSource
{
	MultSource_None = -1,

	MultSource_Vomit,
	MultSource_FF,
	MultSource_CIHit,
	MultSource_SIHit,
	MultSource_Shoved,

	MultSource_MAX
};

bool			g_bLateLoaded;

MultSource 		g_source = MultSource_None;

ConVar			g_hConVar_PunchMult[MultSource_MAX];
float			g_fPunchMult[MultSource_MAX];

ConVar			g_hConVar_EnableRecoilCookie;
bool			g_bEnableRecoilCookie;

ConVar			g_hConVar_RecoilCookieDefault;
RecoilCookie	g_hCookie_Recoil;

bool			g_bRecoilEnabledDefault;
bool			g_bRecoilEnabled[MAXPLAYERS_L4D2 + 1];

VanillaRecoil	g_vanillaRecoil;

#if defined _cookie_manager_included_
	bool g_bCookieHooked;
#endif

methodmap RecoilCookie < Cookie
{
	public RecoilCookie(const char[] sName, const char[] sDesc, CookieAccess access)
	{
		return view_as<RecoilCookie>(RegClientCookie(sName, sDesc, access));
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
		bool bSet = g_bRecoilEnabledDefault;

		if (AreClientCookiesCached(iClient))
		{
			char sValue[2];
			this.Get(iClient, sValue, sizeof(sValue));
			switch (sValue[0])
			{
				case '0': bSet = false;
				case '1': bSet = true;
			}
		}

		g_bRecoilEnabled[iClient] = bSet;
	}
}

/**
 * recoil view punch is special. there are vanilla convars for horizontal and vertical
 * punch. blocking the SetPunchAngle function doesn't completely remove the punch in
 * some recoil cases. a bit of the punch happens client side. disabling these vanilla
 * convars client side will fix this problem, but disabling them server side means
 * no view punch for anybody.
 *
 * this is problematic due to the option of allowing per-client setting of recoil punch.
 *
 * solution is to keep server value as whatever the server operator wants, and replicate
 * either these original values or 0 depending on if a client should see punch or not.
 */
enum struct VanillaRecoil
{
	ConVar	z_gun_vertical_punch;
	ConVar	z_gun_horiz_punch;

	char	vertical[2];
	char	horizontal[2];

	void Init()
	{
		this.z_gun_vertical_punch = FindConVar("z_gun_vertical_punch");
		this.z_gun_horiz_punch = FindConVar("z_gun_horiz_punch");

		this.z_gun_vertical_punch.Flags &= ~FCVAR_REPLICATED;
		this.z_gun_horiz_punch.Flags &= ~FCVAR_REPLICATED;

		this.z_gun_vertical_punch.AddChangeHook(ConVarChanged_UpdateVanillaRecoil);
		this.z_gun_horiz_punch.AddChangeHook(ConVarChanged_UpdateVanillaRecoil);

		this.Update();
	}

	void Update()
	{
		this.z_gun_vertical_punch.GetString(this.vertical, sizeof(this.vertical));
		this.z_gun_horiz_punch.GetString(this.horizontal, sizeof(this.horizontal));
	}

	void ReplicateAll()
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (IsFakeClient(i)) continue;

			this.Replicate(i);
		}
	}

	void Replicate(int iClient)
	{
		bool bSendOriginal = true;

		if (g_bEnableRecoilCookie)
			bSendOriginal = g_bRecoilEnabled[iClient];
		else bSendOriginal = g_bRecoilEnabledDefault;

		if (bSendOriginal)
		{
			this.z_gun_horiz_punch.ReplicateToClient(iClient, this.horizontal);
			this.z_gun_vertical_punch.ReplicateToClient(iClient, this.vertical);
		}
		else
		{
			this.z_gun_horiz_punch.ReplicateToClient(iClient, "0");
			this.z_gun_vertical_punch.ReplicateToClient(iClient, "0");
		}
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
}

public void OnPluginStart()
{
	g_vanillaRecoil.Init();

	g_hConVar_PunchMult[MultSource_Vomit] = CreateConVar(
		"view_punch_mult_vomit", "1.0",
		"should being vomitted on cause view punch to occur?",
		CVAR_FLAGS);

	g_hConVar_PunchMult[MultSource_FF] = CreateConVar(
		"view_punch_mult_friendly_fire", "1.0",
		"should a teammate shooting you cause view punch to occur?",
		CVAR_FLAGS);

	g_hConVar_PunchMult[MultSource_CIHit] = CreateConVar(
		"view_punch_mult_common_hit", "1.0",
		"should being hit by a common infected cause view punch to occur?",
		CVAR_FLAGS);

	g_hConVar_PunchMult[MultSource_SIHit] = CreateConVar(
		"view_punch_mult_special_hit", "1.0",
		"should being hit by a special infected cause view punch to occur?",
		CVAR_FLAGS);

	g_hConVar_PunchMult[MultSource_Shoved] = CreateConVar(
		"view_punch_mult_shove", "1.0",
		"should a teammate shoving you cause view punch to occur?",
		CVAR_FLAGS);

	for (any i = 0; i < MultSource_MAX; i++)
		g_hConVar_PunchMult[i].AddChangeHook(ConVarChanged_UpdatePunchMults);

	ReadPunchMultConVars();

	g_hConVar_EnableRecoilCookie = CreateConVar(
		"view_punch_use_recoil_cookie", "1",
		"are clients allowed to configure if view punch is enabled for their weapon recoil via the " ... COOKIE_RECOIL ... " cookie?",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_EnableRecoilCookie.AddChangeHook(ConVarChanged_CookieEnabled);
	g_bEnableRecoilCookie = g_hConVar_EnableRecoilCookie.BoolValue;

	g_hConVar_RecoilCookieDefault = CreateConVar(
		CONVAR_DEFAULT_RECOIL, "1",
		"if view_punch_use_recoil_cookie is set to 1, this convar will behave \
		as a default value for clients who don't have the cookie set. otherwise \
		its value is enforced regardless of that cookie's value.",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_RecoilCookieDefault.AddChangeHook(ConVarChanged_CookieDefault);
	g_bRecoilEnabledDefault = g_hConVar_RecoilCookieDefault.BoolValue;

	AutoExecConfig(true, "view_punch_control");

	g_hCookie_Recoil = new RecoilCookie(
		COOKIE_RECOIL,
		"Toggle for punching your camera view up when firing your weapon (recoil). 1 for on, 0 for off",
		CookieAccess_Public);

	if (g_bLateLoaded)
	{
		g_hCookie_Recoil.UpdateAll();
		g_vanillaRecoil.ReplicateAll();

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;

			AddSDKHooks(i);
		}

		#if defined _cookie_manager_included_
			if (LibraryExists(COOKIE_MANAGER_LIBRARY))
			{
				HookCookieChange(COOKIE_RECOIL, OnCookieChanged);
				g_bCookieHooked = true;
			}
		#endif
	}
}

void AddSDKHooks(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(iClient, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlive_Post);

	SDKHook(iClient, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(iClient, SDKHook_TraceAttackPost, OnTraceAttack_Post);
}

public void OnClientPutInServer(int iClient)
{
	AddSDKHooks(iClient);

	if (IsFakeClient(iClient))
		return;

	g_hCookie_Recoil.Update(iClient);
	g_vanillaRecoil.Replicate(iClient);
}

/** convars */
void ConVarChanged_UpdatePunchMults(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadPunchMultConVars();
}

void ConVarChanged_UpdateVanillaRecoil(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_vanillaRecoil.Update();
	g_vanillaRecoil.ReplicateAll();
}

void ConVarChanged_CookieEnabled(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bEnableRecoilCookie = g_hConVar_EnableRecoilCookie.BoolValue;
	g_vanillaRecoil.ReplicateAll();
}

void ConVarChanged_CookieDefault(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bRecoilEnabledDefault = g_hConVar_RecoilCookieDefault.BoolValue;
	g_hCookie_Recoil.UpdateAll();
	g_vanillaRecoil.ReplicateAll();
}

void ReadPunchMultConVars()
{
	for (any i = 0; i < MultSource_MAX; i++)
		g_fPunchMult[i] = g_hConVar_PunchMult[i].FloatValue;
}

/** cookies */
public void OnClientCookiesCached(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	g_hCookie_Recoil.Update(iClient);
	g_vanillaRecoil.Replicate(iClient);
}

#if defined _cookie_manager_included_
	public void OnAllPluginsLoaded()
	{
		if (!g_bCookieHooked && LibraryExists(COOKIE_MANAGER_LIBRARY))
		{
			HookCookieChange(COOKIE_RECOIL, OnCookieChanged);
			g_bCookieHooked = true;
		}
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (!g_bCookieHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
		{
			HookCookieChange(COOKIE_RECOIL, OnCookieChanged);
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
		g_hCookie_Recoil.Update(iClient);
		g_vanillaRecoil.Replicate(iClient);
	}
#endif

/*********************
 * Track Punch Source
 *********************/

Action OnTakeDamageAlive(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	if (IsValidClient(iAttacker))
	{
		if (GetClientTeam(iAttacker) == Team_Infected)
			g_source = MultSource_SIHit;
	}

	else if (IsValidEdict(iAttacker) && IsCommonInfected(iAttacker))
		g_source = MultSource_CIHit;

	return Plugin_Continue;
}
void OnTakeDamageAlive_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType)
{
	g_source = MultSource_None;
}

public Action L4D2_OnEntityShoved(int iClient, int iEntity, int iWeapon, float vDir[3], bool bIsHighPounce)
{
	g_source = MultSource_Shoved;
}
public void L4D2_OnEntityShoved_Post(int iClient, int iEntity, int iWeapon, const float vDir[3], bool bIsHighPounce)
{
	g_source = MultSource_None;
}
public void L4D2_OnEntityShoved_PostHandled(int iClient, int iEntity, int iWeapon, const float vDir[3], bool bIsHighPounce)
{
	g_source = MultSource_None;
}

Action OnTraceAttack(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iAmmoType, int iHitbox, int iHitgroup)
{
	if ((IsValidClient(iVictim) && IsOfSurvivorTeam(iVictim))
		&& (IsValidClient(iAttacker) && IsOfSurvivorTeam(iAttacker)))
		g_source = MultSource_FF;

	return Plugin_Continue;
}
void OnTraceAttack_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iAmmoType, int iHitbox, int iHitgroup)
{
	g_source = MultSource_None;
}

public Action L4D_OnVomitedUpon(int iVictim, int &iAttacker, bool &bBoomerExplosion)
{
	g_source = MultSource_Vomit;
	return Plugin_Continue;
}
public void L4D_OnVomitedUpon_Post(int iVictim, int iAttacker, bool bBoomerExplosion)
{
	g_source = MultSource_None;
}
public void L4D_OnVomitedUpon_PostHandled(int iVictim, int iAttacker, bool bBoomerExplosion)
{
	g_source = MultSource_None;
}

public Action L4D2_OnHitByVomitJar(int iVictim, int &iAttacker)
{
	g_source = MultSource_Vomit;
	return Plugin_Continue;
}
public void L4D2_OnHitByVomitJar_Post(int iVictim, int iAttacker)
{
	g_source = MultSource_None;
}
public void L4D2_OnHitByVomitJar_PostHandled(int iVictim, int iAttacker)
{
	g_source = MultSource_None;
}

/********
 * BLOCK
 *******/

public Action OnGunViewPunch(int iWeapon, int iClient)
{
	if (g_bEnableRecoilCookie)
	{
		/** use this client, or the human spectator of the client if bot */
		int iCookieClient;
		if (IsFakeClient(iClient))
		{
			iCookieClient = L4D_GetIdlePlayerOfBot(iCookieClient);
			if (iCookieClient == -1) iCookieClient = iClient;
		}
		else iCookieClient = iClient;

		return g_bRecoilEnabled[iCookieClient] ? Plugin_Continue : Plugin_Handled;
	}

	return g_bRecoilEnabledDefault ? Plugin_Continue : Plugin_Handled;
}

public Action OnSetPunchAngle(int iClient, float vAngle[3])
{
	if (g_source == MultSource_None || !IsValidClient(iClient))
		return Plugin_Continue;

	switch (g_fPunchMult[g_source])
	{
		case 0.0: return Plugin_Handled;
		case 1.0: return Plugin_Continue;
	}

	for (int i = 0; i < sizeof(vAngle); i++)
		vAngle[i] *= g_fPunchMult[g_source];

	return Plugin_Changed;
}
