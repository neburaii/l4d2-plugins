#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <hxlib>

public Plugin myinfo =
{
	name = "Autofill Ammo On Spawn",
	author = "Neburai",
	description = "automatically fill ammo of players/weapons who've just spawned",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/autofill_ammo"
};

ConVar	g_hConVar_Enabled;

public void OnPluginStart()
{
	g_hConVar_Enabled = CreateConVar(
		"autofill_ammo_on_spawn", "1",
		"should players/weapons always spawn with full ammo?",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVar_Enabled.AddChangeHook(ConVarChanged_Update);

	if (g_hConVar_Enabled.BoolValue)
		DHookAddEntityListener(ListenType_Created, Listen_OnEntityCreated);
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (g_hConVar_Enabled.BoolValue)
		DHookAddEntityListener(ListenType_Created, Listen_OnEntityCreated);
	else DHookRemoveEntityListener(ListenType_Created, Listen_OnEntityCreated);
}

void Listen_OnEntityCreated(int iEntity, const char[] sClass)
{
	if (IsWeapon(iEntity))
		RequestFrame(RefillAmmo, EntIndexToEntRef(iEntity));
}

/** OnEntityCreated will happen before vanilla ammo restoration. */
void RefillAmmo(int iEntRef)
{
	int iWeapon = EntRefToEntIndex(iEntRef);
	if (iWeapon == INVALID_ENT_REFERENCE)
		return;

	AmmoType ammo = GetAmmoType(iWeapon);
	if (ammo <= Ammo_None)
		return;

	SetReserveAmmo(iWeapon, GetMaxReserveAmmo(ammo));
	SetMagazineAmmo(iWeapon, GetMaxMagazineAmmo(iWeapon));
}
