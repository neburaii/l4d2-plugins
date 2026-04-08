#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <hxstocks>

public Plugin myinfo =
{
	name = "Consistent Ammo",
	author = "Neburai",
	description = "preserve the ratio of remaining/total ammo when reserve ammo for weapons is updated",
	version = "1.2",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/consistent_ammo"
};

ConVar	g_hConVar_Reserve[Ammo_MAX];

public void OnPluginStart()
{
	g_hConVar_Reserve[Ammo_None]			= null;
	g_hConVar_Reserve[Ammo_Pistol]			= FindConVar("ammo_pistol_max");
	g_hConVar_Reserve[Ammo_PistolMagnum]	= g_hConVar_Reserve[Ammo_Pistol];
	g_hConVar_Reserve[Ammo_AssaultRifle]	= FindConVar("ammo_assaultrifle_max");
	g_hConVar_Reserve[Ammo_Minigun]			= FindConVar("ammo_minigun_max");
	g_hConVar_Reserve[Ammo_Smg]				= FindConVar("ammo_smg_max");
	g_hConVar_Reserve[Ammo_M60]				= FindConVar("ammo_m60_max");
	g_hConVar_Reserve[Ammo_Shotgun]			= FindConVar("ammo_shotgun_max");
	g_hConVar_Reserve[Ammo_Autoshotgun]		= FindConVar("ammo_autoshotgun_max");
	g_hConVar_Reserve[Ammo_HuntingRifle]	= FindConVar("ammo_huntingrifle_max");
	g_hConVar_Reserve[Ammo_SniperRifle]		= FindConVar("ammo_sniperrifle_max");
	g_hConVar_Reserve[Ammo_Turret]			= FindConVar("ammo_turret_max");
	g_hConVar_Reserve[Ammo_PipeBomb]		= FindConVar("ammo_pipebomb_max");
	g_hConVar_Reserve[Ammo_Molotov]			= FindConVar("ammo_molotov_max");
	g_hConVar_Reserve[Ammo_VomitJar]		= FindConVar("ammo_vomitjar_max");
	g_hConVar_Reserve[Ammo_PainPills]		= FindConVar("ammo_painpills_max");
	g_hConVar_Reserve[Ammo_FirstAid]		= FindConVar("ammo_firstaid_max");
	g_hConVar_Reserve[Ammo_GrenadeLauncher]	= FindConVar("ammo_grenadelauncher_max");
	g_hConVar_Reserve[Ammo_Adrenaline]		= FindConVar("ammo_adrenaline_max");
	g_hConVar_Reserve[Ammo_Chainsaw]		= null;
	g_hConVar_Reserve[Ammo_CarriedItem]		= null;

	for (any i = 0; i < Ammo_MAX; i++)
	{
		if (g_hConVar_Reserve[i] == null || i == Ammo_PistolMagnum)
			continue;

		g_hConVar_Reserve[i].AddChangeHook(ConVarChanged_Update);
	}
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	int iOldValue = StringToInt(sOldValue);
	int iNewValue = StringToInt(sNewValue);
	bool bFixedUpdate = (iOldValue < 0 && iNewValue >= 0) || iNewValue < 0;

	for (any i = 0; i < Ammo_MAX; i++)
	{
		if (hConVar != g_hConVar_Reserve[i])
			continue;

		if (bFixedUpdate) UpdateAmmoFixed(i, iNewValue);
		else UpdateAmmoRatio(i, iOldValue, iNewValue);
	}
}

void UpdateAmmoFixed(AmmoType type, int iAmount)
{
	for (int i = MaxClients + 1; i <= MAXEDICTS; i++)
	{
		if (IsValidWeaponOfType(i, type))
			SetReserveAmmo(i, iAmount);
	}
}

void UpdateAmmoRatio(AmmoType type, int iOldMax, int iNewMax)
{
	float fMult = float(iNewMax) / float(iOldMax);

	for (int i = MaxClients + 1; i <= MAXEDICTS; i++)
	{
		if (IsValidWeaponOfType(i, type))
			SetReserveAmmo(i, RoundToFloor(float(GetReserveAmmo(i)) * fMult));
	}
}

bool IsValidWeaponOfType(int entity, AmmoType type)
{
	return	IsValidEdict(entity)
			&& IsWeapon(entity)
			&& GetAmmoType(entity) == type;
}
