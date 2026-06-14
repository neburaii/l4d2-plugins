#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <hxlib>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Reload Fills Ammo Early",
	author = "Neburai",
	description = "fill ammo when the remaining reload duration is at most the time it'd take to switch away and back to the item",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/reload_early_fill"
};

bool	g_bLateLoaded;
bool	g_bPluginStarted;

ConVar	g_hConVar_ExploitDuration;
float	g_fExploitDuration;

DeployDurationManager g_deployDuration;
EarlyFillTracker g_earlyFill;

enum struct DeployDurationManager
{
	int entref[MAXEDICTS];
	float time[MAXEDICTS];

	void Set(int iWeapon)
	{
		int iActivity = GetDeployActivity(iWeapon);

		int iSeqTotal;
		SequenceTupleList list = GetSequencesForActivity(iWeapon, iActivity, iSeqTotal);

		float fShortest = 0.0;
		float fDuration;
		for (int i = 0; i < iSeqTotal; i++)
		{
			fDuration = GetSequenceDuration(iWeapon, list.Get(i).sequence);

			if (fShortest <= 0.0 || fDuration < fShortest)
				fShortest = fDuration;
		}

		if (fShortest < 0.0)
			this.time[iWeapon] = 0.0;
		else this.time[iWeapon] = fShortest;

		this.entref[iWeapon] = EntIndexToEntRef(iWeapon);
	}

	float Get(int iWeapon)
	{
		/** sequence durations will never be 0.0, so that means we failed to find sequences last time */
		if (!this.time[iWeapon] || EntIndexToEntRef(iWeapon) != this.entref[iWeapon])
			this.Set(iWeapon);

		return this.time[iWeapon];
	}
}

enum struct EarlyFillTracker
{
	int entref[MAXEDICTS];
	bool filled[MAXEDICTS];

	void Reset(int iWeapon)
	{
		this.Set(iWeapon, false);
	}

	void SetFilled(int iWeapon)
	{
		this.Set(iWeapon, true);
	}

	void Set(int iWeapon, bool bValue)
	{
		this.filled[iWeapon] = bValue;
		this.entref[iWeapon] = EntIndexToEntRef(iWeapon);
	}

	bool HasFilled(int iWeapon)
	{
		if (EntIndexToEntRef(iWeapon) != this.entref[iWeapon])
			this.Reset(iWeapon);

		return this.filled[iWeapon];
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = true;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_ExploitDuration = CreateConVar(
		"reload_early_fill_exploit_duration", "0.0",
		"aditionally subtract this many seconds from reload durations after subtracting time to swap to that item",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_ExploitDuration.AddChangeHook(ConVarChanged_Update);

	g_fExploitDuration = g_hConVar_ExploitDuration.FloatValue;

	if (g_bLateLoaded && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fExploitDuration = g_hConVar_ExploitDuration.FloatValue;
}

public void OnAllPluginsLoaded()
{
	if (!g_bPluginStarted && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

public void OnLibraryAdded(const char[] sName)
{
	if (!g_bPluginStarted && strcmp(sName, HXLIB_LIBRARY) == 0)
		StartPlugin();
}

void StartPlugin()
{
	g_bPluginStarted = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		SDKHook(i, SDKHook_PostThinkPost, OnClientThink);
	}

	for (int i = MaxClients + 1; i < MAXEDICTS; i++)
	{
		if (!IsValidEdict(i)
			|| !IsTerrorGun(i))
			continue;

		SDKHook(i, SDKHook_Reload, OnReloadStart);
	}
}

public void OnClientPutInServer(int iClient)
{
	if (!g_bPluginStarted)
		return;

	SDKHook(iClient, SDKHook_PostThinkPost, OnClientThink);
}

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (!g_bPluginStarted || !IsTerrorGun(iEntity))
		return;

	SDKHook(iEntity, SDKHook_Reload, OnReloadStart);
}

Action OnReloadStart(int iWeapon)
{
	g_earlyFill.Reset(iWeapon);
	return Plugin_Continue;
}

void OnClientThink(int iClient)
{
	int iWeapon = GetCurrentWeapon(iClient);
	if (!IsValidEdict(iWeapon) || !IsTerrorGun(iWeapon))
		return;

	if (!IsWeaponReloading(iWeapon)
		|| g_earlyFill.HasFilled(iWeapon)
		|| IsWeaponSingleReloadOnly(iWeapon))
		return;

	float fNow = GetGameTime();
	float fThreshold = GetReloadEndTimestamp(iWeapon) - g_deployDuration.Get(iWeapon) - g_fExploitDuration;

	if (fNow > fThreshold)
		EarlyFill(iWeapon, iClient);
}

void EarlyFill(int iWeapon, int iOwner)
{
	int iMaxMagazine = GetMaxMagazineAmmo(iWeapon);
	if (iMaxMagazine < 0)
		return;

	AmmoType ammoType = GetAmmoType(iWeapon);
	if (ammoType == Ammo_None)
		return;

	int iReserve = IsAmmoTypeInfinite(ammoType) ? 999 : GetClientAmmo(iOwner, ammoType);
	if (iReserve <= 0)
		return;

	int iMagazine = GetMagazineAmmo(iWeapon);

	int iFill = iMaxMagazine - iMagazine;
	if (iFill > iReserve)
		iFill = iReserve;

	RemoveAmmo(iOwner, iFill, ammoType);
	SetMagazineAmmo(iWeapon, iMagazine + iFill);
	g_earlyFill.SetFilled(iWeapon);
}

int GetClientAmmo(int iClient, AmmoType ammoType)
{
	return GetEntProp(iClient, Prop_Send, "m_iAmmo", _, ammoType);
}

bool IsWeaponSingleReloadOnly(int iWeapon)
{
	return GetEntProp(iWeapon, Prop_Data, "m_bReloadsSingly", 1);
}

float GetReloadEndTimestamp(int iWeapon)
{
	return GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
}
