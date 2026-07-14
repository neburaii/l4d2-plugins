#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sourcescramble>

#define GAMEDATA "insta_smoke_fix.games"

public Plugin myinfo =
{
	name = "Insta-Smoke Fix",
	author = "Neburai",
	description = "Fix being instantly smoked when standing on certain props",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/insta_smoke_fix"
};

MemoryPatch	g_hPatchMask;
MemoryPatch	g_hPatchCollisionGroup;

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if (FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if (hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hPatchMask = MemoryPatch.CreateFromConf(hGameData,
		"CTongue::UpdateAirChoke::FixTraceMask");
	g_hPatchCollisionGroup = MemoryPatch.CreateFromConf(hGameData,
		"CTongue::UpdateAirChoke::FixTraceCollisionGroup");

	delete hGameData;

	g_hPatchMask.Enable();
	g_hPatchCollisionGroup.Enable();
}
