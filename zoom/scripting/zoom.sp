#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hxlib>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Zoom Fix",
	author = "Neburai",
	description = "fixes zoom issues with high tickrate, along with exposing new convars to configure zoom",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/zoom"
};

ConVar	g_hConVar_ZoomDuration;
float	g_fZoomDuration;

ConVar	g_hConVar_UnZoomDuration;
float	g_fUnZoomDuration;

public void OnPluginStart()
{
	g_hConVar_ZoomDuration = CreateConVar(
		"zoom_in_duration", "0.3",
		"duration in seconds it takes to transition to a weapon's zoom level",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_ZoomDuration.AddChangeHook(ConVarChanged_Update);

	g_hConVar_UnZoomDuration = CreateConVar(
		"zoom_out_duration", "0.1",
		"duration in seconds it takes to transition from a weapon's zoom level to default FOV",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_UnZoomDuration.AddChangeHook(ConVarChanged_Update);

	ReadConVars();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_fZoomDuration = g_hConVar_ZoomDuration.FloatValue;
	g_fUnZoomDuration = g_hConVar_UnZoomDuration.FloatValue;
}

public Action OnCycleZoom(int iWeapon)
{
	CustomCycleZoom(iWeapon);
	return Plugin_Handled;
}

void CustomCycleZoom(int iWeapon)
{
	int iClient = GetOwnerEntity(iWeapon);
	if (!IsValidClient(iClient)) return;

	bool bZoomed = IsZoomed(iClient);
	int iZoomLevel = GetZoomLevel(iWeapon);

	if (bZoomed)
	{
		SetFOV(iClient, 0, g_fUnZoomDuration);
	}
	else
	{
		if (ShouldUnZoom(iClient))
			return;

		SetFOV(iClient, iZoomLevel, g_fZoomDuration);
	}

	EmitAttenuationFilteredGameSound(iWeapon, "Default.Zoom");

	Event hEvent = CreateEvent("weapon_zoom", true);
	hEvent.SetInt("userid", GetClientUserId(iClient));
	FireEvent(hEvent);
}

bool IsZoomed(int iClient)
{
	return IsValidEntity(GetEntPropEnt(iClient, Prop_Send, "m_hZoomOwner"));
}

bool ShouldUnZoom(int iClient)
{
	return	!IsOnGround(iClient)
			|| IsSmoked(iClient)
			|| IsPounced(iClient)
			|| IsJockeyed(iClient)
			|| IsPlayerIncapacitated(iClient)
			|| IsReloading(iClient);
}

void EmitAttenuationFilteredGameSound(int iEntity, const char[] sGameSound)
{
	int iChannel;
	int iLevel;
	float fVolume;
	int iPitch;
	static char sSample[PLATFORM_MAX_PATH];

	GetGameSoundParams(sGameSound,
		iChannel,
		iLevel,
		fVolume,
		iPitch,
		sSample,
		sizeof(sSample));

	int[] iRecipients = new int[MaxClients];
	int total;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		iRecipients[total++] = i;
	}

	float vSource[3];
	GetEntityAbsOrigin(iEntity, vSource);
	FilterClientsByAttenuation(iRecipients, total, vSource, iLevel);

	EmitSound(iRecipients, total, sSample, iEntity, iChannel, iLevel, _, fVolume, iPitch);
}
