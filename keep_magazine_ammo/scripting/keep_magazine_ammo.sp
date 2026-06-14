#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sourcescramble>

#define GAMEDATA "keep_magazine_ammo.games"

public Plugin myinfo =
{
	name = "Keep Magazine Ammo On Reload",
	author = "Neburai",
	description = "simple implementation of a toggle to keep magazine ammo when you reload",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/keep_magazine_ammo"
};

ConVar		g_hConVar_Enabled;
bool		g_bEnabled;

MemoryPatch	g_hPatch;

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if (FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if (hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hPatch = MemoryPatch.CreateFromConf(hGameData, "CTerrorGun::Reload::KeepAmmo");

	delete hGameData;

	g_hConVar_Enabled = CreateConVar(
		"keep_magazine_ammo", "1",
		"should a weapon's magazine ammo be preserved when initiating a reload?",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVar_Enabled.AddChangeHook(ConVarChanged_Update);
	g_bEnabled = g_hConVar_Enabled.BoolValue;

	if (g_bEnabled) g_hPatch.Enable();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bEnabled = g_hConVar_Enabled.BoolValue;

	if (g_bEnabled) g_hPatch.Enable();
	else g_hPatch.Disable();
}
