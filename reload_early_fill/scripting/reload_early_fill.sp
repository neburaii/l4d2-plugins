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

ReloadManager g_reload;

enum struct ReloadManager
{
	int entref[MAXEDICTS];
	Handle timer[MAXEDICTS];
	float deployDuration[MAXEDICTS];

	bool Verify(int iWeapon)
	{
		return EntIndexToEntRef(iWeapon) == this.entref[iWeapon];
	}

	void Init(int iWeapon)
	{
		this.SetDeployDuration(iWeapon);
		this.entref[iWeapon] = EntIndexToEntRef(iWeapon);
	}

	void SetDeployDuration(int iWeapon)
	{
		int iActivity = GetDeployActivity(iWeapon);

		int iSeqTotal;
		SequenceTupleList list = GetSequencesForActivity(iWeapon, iActivity, iSeqTotal);

		float fDurationRecord = 0.0;
		float fDuration;
		for (int i = 0; i < iSeqTotal; i++)
		{
			fDuration = GetSequenceDuration(iWeapon, list.Get(i).sequence);

			if (!i || fDuration < fDurationRecord)
				fDurationRecord = fDuration;
		}

		if (fDurationRecord < 0.0)
			fDurationRecord = 0.0;

		this.deployDuration[iWeapon] = fDurationRecord;
	}

	void Start(int iWeapon)
	{
		if (this.timer[iWeapon])
			delete this.timer[iWeapon];

		if (!this.Verify(iWeapon))
			this.Init(iWeapon);

		/** shouldn't be 0 if sequences were found last time */
		else if (!this.deployDuration[iWeapon])
			this.SetDeployDuration(iWeapon);

		if (!this.deployDuration[iWeapon] && !g_fExploitDuration)
			return;

		if (IsWeaponSingleReloadOnly(iWeapon))
			return;

		float fNow = GetGameTime();
		float fThreshold = GetReloadEndTimestamp(iWeapon) - this.deployDuration[iWeapon] - g_fExploitDuration;

		float fDiff = fThreshold - fNow;
		if (fDiff < 0.1) return;

		// CreateTimer
	}

	void End(int iWeapon)
	{
		this.timer[iWeapon] = null;
		if (EntIndexToEntRef(iWeapon) != this.entref[iWeapon])
			return;

		if (!IsWeaponReloading(iWeapon))
			return;

		int iOwner = GetOwnerEntity(iWeapon);
		if (!IsValidClient(iOwner))
			return;

		EarlyFill(iWeapon, iOwner);
	}
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
}

/*********
 * helpers
 *********/

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
