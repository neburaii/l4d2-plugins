#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <sendproxy>
#include <hxlib>

#undef REQUIRE_PLUGIN
#include <cookie_manager>
#define REQUIRE_PLUGIN

#define CVAR_FLAGS		FCVAR_NOTIFY

#define COOKIE_WARNING	"low_ammo_warning"
#define COOKIE_PERCENT	"ammo_as_percent"

#define BLINK_OFF		false
#define BLINK_ON		true

public Plugin myinfo =
{
	name = "Ammo Display",
	author = "Neburai",
	description = "blink ammo display on low ammo, and workarounds for displaying large ammo amounts",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/ammo_display"
};

bool			g_bLateLoaded;
bool			g_bPluginStarted;

#if defined _cookie_manager_included_
	bool		g_bCookiesHooked;
#endif

ToggleCookie	g_cookieWarning;
ToggleCookie	g_cookiePercent;

WarningSound	g_warningSound;

ConVar			g_hConVar_BlinkOffDuration;
float			g_fBlinkOffDuration;

ConVar			g_hConVar_BlinkOnDuration;
float			g_fBlinkOnDuration;

ConVar			g_hConVar_LowAmmoThreshold;
float			g_fLowAmmoThreshold;

ConVar			g_hConVar_DisplayMax;
int				g_iDisplayMax;

bool			g_bBlinkState;

ReloadDelta		g_reloadDelta;
AmmoTracker		g_lowAmmo[MAXPLAYERS_L4D2 + 1];

/** purpose:
 * tracks delta of ammo moved from clip to reserve during reloads.
 * call Check() to see if low ammo with this delta accounted for.
 */
enum struct AmmoTracker
{
	int client;
	int entref;

	int delta[Ammo_MAX];

	void Init(int iClient)
	{
		this.client = iClient;
	}

	void Reset()
	{
		for (int i = 0; i < sizeof(this.delta); i++)
			this.delta[i] = 0;
		this.entref = EntIndexToEntRef(this.client);
	}

	bool VerifyDelta()
	{
		return EntIndexToEntRef(this.client) == this.entref;
	}

	int GetDelta(AmmoType ammoType)
	{
		if (!this.VerifyDelta())
			return 0;

		return this.delta[ammoType];
	}

	void SetDelta(AmmoType ammoType, int iAmount)
	{
		if (!this.VerifyDelta())
			this.Reset();

		this.delta[ammoType] = iAmount;
	}

	bool Check(AmmoType ammoType, int iAmount, int iMagazineMax, bool bCheckDelta = false)
	{
		int iReloadDelta = 0;
		if (bCheckDelta) iReloadDelta = this.GetDelta(ammoType);

		return (iAmount - iReloadDelta) <= RoundToFloor(float(iMagazineMax) * g_fLowAmmoThreshold);
	}
}

/** purpose:
 * reload delta before it becomes associated to a client.
 * track whether we're in a Reload() call, and record delta from SetAmmoCount() calls.
 */
enum struct ReloadDelta
{
	bool enabled;

	int client;
	int oldAmount[Ammo_MAX];

	void Enable()
	{
		this.enabled = true;
	}

	void Disable()
	{
		this.enabled = false;
	}

	/** record all ammo types in case another plugin changed it in pre-hook */
	void Record(int iClient)
	{
		if (!this.enabled) return;

		this.client = iClient;
		for (int i = 0; i < sizeof(this.oldAmount); i++)
			this.oldAmount[i] = GetEntProp(this.client, Prop_Send, "m_iAmmo", _, i);
	}

	int Get(AmmoType ammoType)
	{
		if (!this.enabled) return 0;

		int iNewAmount = GetEntProp(this.client, Prop_Send, "m_iAmmo", _, ammoType);
		return iNewAmount - this.oldAmount[ammoType];
	}
}

enum struct WarningSound
{
	ConVar cvar;
	bool exists;
	char sample[PLATFORM_MAX_PATH];

	void Init(const char[] sName, const char[] sValue, const char[] sDesc)
	{
		this.cvar = CreateConVar(sName, sValue, sDesc, CVAR_FLAGS);
		this.cvar.AddChangeHook(ConVarChanged_Sound);
	}

	void Update()
	{
		this.cvar.GetString(this.sample, sizeof(this.sample));
		this.exists = this.sample[0] != '\0';
	}

	void Precache()
	{
		if (this.exists)
			PrecacheSound(this.sample);
	}

	void Emit(int iClient)
	{
		if (!this.exists) return;
		EmitSoundToClient(iClient, this.sample, _, SNDCHAN_STATIC);
	}
}

enum struct ToggleCookie
{
	Cookie cookie;
	bool value[MAXPLAYERS_L4D2 + 1];

	ConVar defaultConVar;
	bool defaultValue;

	void Init(const char[] sName, const char[] sDefaultValue, const char[] sDesc)
	{
		this.cookie = new Cookie(sName, sDesc, CookieAccess_Public);

		char sCVName[40];
		char sCVDesc[330];
		FormatEx(sCVName, sizeof(sCVName),
			"cookie_%s", sName);
		FormatEx(sCVDesc, sizeof(sCVDesc),
			"default value for \"%s\" cookie. description: \n%s", sName, sDesc);

		this.defaultConVar = CreateConVar(
			sCVName, sDefaultValue, sCVDesc, CVAR_FLAGS, true, 0.0, true, 1.0);
		this.defaultConVar.AddChangeHook(ConVarChanged_Cookie);

		this.UpdateDefault();
	}

	void Update(int iClient)
	{
		if (AreClientCookiesCached(iClient))
		{
			static char sValue[2];
			this.cookie.Get(iClient, sValue, sizeof(sValue));

			switch (sValue[0])
			{
				case '0': this.value[iClient] = false;
				case '1': this.value[iClient] = true;
				default: this.value[iClient] = this.defaultValue;
			}
		}
		else this.value[iClient] = this.defaultValue;
	}

	void UpdateDefault()
	{
		this.defaultValue = this.defaultConVar.BoolValue;
	}

	bool Enabled(int iClient)
	{
		return this.value[iClient];
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_BlinkOffDuration = CreateConVar(
		"ammo_display_blink_duration_off", "0.2",
		"when reserve ammo is in \"low warning\" display, blink it off for this many seconds.",
		CVAR_FLAGS, true, 0.1);
	g_hConVar_BlinkOffDuration.AddChangeHook(ConVarChanged_Update);

	g_hConVar_BlinkOnDuration = CreateConVar(
		"ammo_display_blink_duration_on", "0.6",
		"when reserve ammo is in \"low warning\" display, blink it on for this many seconds.",
		CVAR_FLAGS, true, 0.1);
	g_hConVar_BlinkOnDuration.AddChangeHook(ConVarChanged_Update);

	g_hConVar_LowAmmoThreshold = CreateConVar(
		"ammo_display_low_warning_threshold", "2.0",
		"when total ammo is less than or equal to this * ClipSize, consider it as low ammo.",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_LowAmmoThreshold.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DisplayMax = CreateConVar(
		"ammo_display_max_reserve", "1000",
		"if reserve ammo isn't displayed as percentage, clamp it to this max value.",
		CVAR_FLAGS, true, 0.0, true, 1023.0);
	g_hConVar_DisplayMax.AddChangeHook(ConVarChanged_Update);

	g_warningSound.Init(
		"ammo_display_low_warning_sound", "ui/beepclear.wav",
		"upon firing the shot that brings ammo below \"low warning\" threshold, play this sound.");

	ReadConVars();
	g_warningSound.Update();

	g_cookieWarning.Init(COOKIE_WARNING, "1",
		"blink the display of your primary weapon's reserve ammo when it's low on ammo");

	g_cookiePercent.Init(COOKIE_PERCENT, "0",
		"display your primary's reserve ammo as a percentage");

	CreateTimer(g_fBlinkOnDuration, BlinkOff);

	for (int i = 1; i <= MaxClients; i++)
		g_lowAmmo[i].Init(i);

	if (g_bLateLoaded)
	{
		UpdateAllCookies();
		g_warningSound.Precache();

		#if defined _cookie_manager_included_
			if (LibraryExists(COOKIE_MANAGER_LIBRARY))
				HookCookies();
		#endif

		if (LibraryExists(HXLIB_LIBRARY))
			StartPlugin();

		for (int i = MaxClients + 1; i < MAXEDICTS; i++)
		{
			if (!IsValidEdict(i)
				|| !IsTerrorGun(i))
				continue;

			HookReloadFinish(i);
		}
	}
}

public void OnMapStart()
{
	g_warningSound.Precache();
}

public void OnAllPluginsLoaded()
{
	#if defined _cookie_manager_included_
		if (!g_bCookiesHooked && LibraryExists(COOKIE_MANAGER_LIBRARY))
			HookCookies();
	#endif

	if (!g_bPluginStarted && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

public void OnLibraryAdded(const char[] sName)
{
	#if defined _cookie_manager_included_
		if (!g_bCookiesHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			HookCookies();
	#endif

	if (!g_bPluginStarted && strcmp(sName, HXLIB_LIBRARY) == 0)
		StartPlugin();
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, HXLIB_LIBRARY) == 0)
		g_bPluginStarted = false;

	#if defined _cookie_manager_included_
		else if (strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookiesHooked = false;
	#endif
}

#if defined _cookie_manager_included_
	void HookCookies()
	{
		g_bCookiesHooked = true;

		HookCookieChange(COOKIE_WARNING, OnCookieChanged);
		HookCookieChange(COOKIE_PERCENT, OnCookieChanged);
	}

	void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		UpdateCookies(iClient);
	}
#endif

public void OnClientCookiesCached(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	UpdateCookies(iClient);
}

void ConVarChanged_Cookie(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	UpdateAllCookieDefaults();
	UpdateAllCookies();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ConVarChanged_Sound(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_warningSound.Update();
	g_warningSound.Precache();
}

void ReadConVars()
{
	g_fBlinkOffDuration = g_hConVar_BlinkOffDuration.FloatValue;
	g_fBlinkOnDuration = g_hConVar_BlinkOnDuration.FloatValue;
	g_fLowAmmoThreshold = g_hConVar_LowAmmoThreshold.FloatValue;
	g_iDisplayMax = g_hConVar_DisplayMax.IntValue;
}

void UpdateAllCookieDefaults()
{
	g_cookieWarning.UpdateDefault();
	g_cookiePercent.UpdateDefault();
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
	g_cookieWarning.Update(iClient);
	g_cookiePercent.Update(iClient);
}

/***********
 * hooking
 **********/

void StartPlugin()
{
	g_bPluginStarted = true;
	HXLibRescanForwards();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)
			|| IsFakeClient(i))
			continue;

		HookClient(i);
	}
}

public void OnClientPutInServer(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	UpdateCookies(iClient);
	if (g_bPluginStarted) HookClient(iClient);
}

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (!IsValidEdict(iEntity) || !IsTerrorGun(iEntity))
		return;

	HookReloadFinish(iEntity);
}

/** hxlib requirement means we can't call this until g_bPluginStarted is true */
void HookClient(int iClient)
{
	for (any i = 1; i < Ammo_MAX; i++)
		SendProxy_HookEntity(iClient, "m_iAmmo", Prop_Int, OnSendAmmoDisplay, i);

	AddEntityHook(iClient, EntityHook_RemoveAmmo, EHook_Post, OnRemoveAmmo_Post);
}

void HookReloadFinish(int iWeapon)
{
	SDKHook(iWeapon, SDKHook_Reload, OnReload_Pre);
	SDKHook(iWeapon, SDKHook_ReloadPost, OnReload_Post);
}

/*************
 * ammo delta
 *************/

Action OnReload_Pre(int iWeapon)
{
	g_reloadDelta.Enable();

	int iOwner = GetOwnerEntity(iWeapon);
	if (IsValidClient(iOwner))
		g_lowAmmo[iOwner].Reset();

	return Plugin_Continue;
}

public Action OnSetReserveAmmo(int iClient, int &iAmount, AmmoType &ammoType)
{
	g_reloadDelta.Record(iClient);
	return Plugin_Continue;
}

public void OnSetReserveAmmo_Post(int iClient, int iAmount, AmmoType ammoType, bool bHandled)
{
	if (bHandled) return;
	g_lowAmmo[iClient].SetDelta(ammoType, g_reloadDelta.Get(ammoType));
}

void OnReload_Post(int iWeapon, bool bSuccessful)
{
	g_reloadDelta.Disable();
}

/*******************
 * low ammo warning
 ********************/

void BlinkOn(Handle hTimer)
{
	g_bBlinkState = BLINK_ON;
	CreateTimer(g_fBlinkOnDuration, BlinkOff);
}

void BlinkOff(Handle hTimer)
{
	g_bBlinkState = BLINK_OFF;
	CreateTimer(g_fBlinkOffDuration, BlinkOn);
}

void OnRemoveAmmo_Post(int iClient, int iAmount, AmmoType ammoType, bool bHandled)
{
	if (bHandled
		|| iAmount <= 0
		|| ammoType == Ammo_Null
		|| IsAmmoTypeInfinite(ammoType))
		return;

	int iWeapon = GetWeaponFromAmmoType(iClient, ammoType);
	if (iWeapon == INVALID_ENT_REFERENCE)
		return;

	int iMagazineMax = GetMaxMagazineAmmo(iWeapon);
	if (iMagazineMax <= 0)
		return;

	int iCurrentAmmo = GetEntProp(iClient, Prop_Send, "m_iAmmo", _, ammoType);

	if (g_lowAmmo[iClient].Check(ammoType, iCurrentAmmo, iMagazineMax)
		&& !g_lowAmmo[iClient].Check(ammoType, iCurrentAmmo + iAmount, iMagazineMax, IsReloading(iClient)))
	{
		g_warningSound.Emit(iClient);
	}
}

/**********************
 * modify ammo display
 *********************/

Action OnSendAmmoDisplay(int iClient, const char[] sProp, int &iValue, int iElement, int iSendClient)
{
	if (iClient != iSendClient
		|| iValue <= 0)
		return Plugin_Continue;

	AmmoType ammoType = view_as<AmmoType>(iElement);
	int iWeapon = GetWeaponFromAmmoType(iClient, ammoType);
	if (iWeapon == INVALID_ENT_REFERENCE)
		return Plugin_Continue;

	int iReserveMax = GetMaxReserveAmmo(ammoType);
	int iMagazineMax = GetMaxMagazineAmmo(iWeapon);
	if (iReserveMax <= 0 || iMagazineMax <= 0)
		return Plugin_Continue;

	if (g_cookieWarning.Enabled(iClient) && g_lowAmmo[iClient].Check(ammoType, iValue, iMagazineMax, IsReloading(iClient)))
	{
		if (g_bBlinkState == BLINK_OFF)
		{
			iValue = 0;
			return Plugin_Changed;
		}

		return Plugin_Continue;
	}

	if (g_cookiePercent.Enabled(iClient))
	{
		iValue = RoundToCeil((float(iValue) * 100.0) / float(iReserveMax));
		return Plugin_Changed;
	}

	if (iValue > g_iDisplayMax)
	{
		iValue = g_iDisplayMax;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/**********
 * Helpers
 **********/

int GetWeaponFromAmmoType(int iClient, AmmoType ammoType)
{
	int iWeapon;
	for (int slot = 0; slot < WeaponSlot_MAX; slot++)
	{
		iWeapon = GetPlayerWeaponSlot(iClient, slot);
		if (iWeapon == -1
			|| GetAmmoType(iWeapon) != ammoType)
			continue;

		return iWeapon;
	}

	return INVALID_ENT_REFERENCE;
}
