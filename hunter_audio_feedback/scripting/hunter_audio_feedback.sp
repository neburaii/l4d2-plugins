#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hxlib>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Hunter Audio Feedback",
	author = "Neburai",
	description = "hunter will always shriek when he lunges",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/hunter_audio_feedback"
};

ConVar	g_hConVar_AlwaysShriek;
bool	g_bAlwaysShriek;

ConVar	g_hConVar_HonestWarn;
bool	g_bHonestWarn;

int		g_iOffset_PounceSoundCooldown;
bool	g_bLateLoaded;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_AlwaysShriek = CreateConVar(
		"audio_feedback_hunter_always_shrieks", "1",
		"hunters will always shriek when they lunge",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_AlwaysShriek.AddChangeHook(ConVarChanged_Update);

	g_hConVar_HonestWarn = CreateConVar(
		"audio_feedback_hunter_honest_warn", "1",
		"hunters won't warn about their lunge if they're already lunging",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_HonestWarn.AddChangeHook(ConVarChanged_Update);

	ReadConVars();

	HookEvent("ability_use", Event_AbilityUse);
	g_iOffset_PounceSoundCooldown = FindSendPropInfo("CTerrorPlayer", "m_pounceStartPosition");
	g_iOffset_PounceSoundCooldown += 52;

	if (g_bLateLoaded) HXLibRescanForwards();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_bAlwaysShriek = g_hConVar_AlwaysShriek.BoolValue;
	g_bHonestWarn = g_hConVar_HonestWarn.BoolValue;
}

void Event_AbilityUse(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (!g_bAlwaysShriek) return;

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient && GetZombieClass(iClient) == ZClass_Hunter && hEvent.GetInt("context"))
		SetEntData(iClient, g_iOffset_PounceSoundCooldown, -1.0);
}

public Action OnVocalize(int iClient, char sGameSound[64], float &fCooldown, float &fDurationAI)
{
	if (!g_bHonestWarn || !IsValidClient(iClient) || GetZombieClass(iClient) != ZClass_Hunter)
		return Plugin_Continue;

	if (IsHunterLunging(iClient) && strcmp(sGameSound, "HunterZombie.Warn") == 0)
		return Plugin_Handled;

	return Plugin_Continue;
}
