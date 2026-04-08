#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hxlib>

public Plugin myinfo =
{
	name = "Skip Tank Death Animation",
	author = "Neburai",
	description = "replace the slow tank death animation with an instant ragdoll",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/skip_tank_death_anim"
};

ConVar	g_hConVar_Enabled;
int		g_iKiller[MAXPLAYERS_L4D2 + 1];

public void OnPluginStart()
{
	g_hConVar_Enabled = CreateConVar(
		"skip_tank_death_animation", "1",
		"make tank die sooner by skipping its death animation. Has a gameplay \
		side effect of preventing his collision from lingering after death",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVar_Enabled.AddChangeHook(ConVarChanged_Update);

	if (g_hConVar_Enabled.BoolValue)
		HookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (g_hConVar_Enabled.BoolValue)
		HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	else UnhookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

void Event_PlayerIncapacitated(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!iClient
		|| GetClientTeam(iClient) != Team_Infected
		|| GetZombieClass(iClient) != ZClass_Tank)
		return;

	AddEntityHook(iClient, EntityHook_EventKilled, EHook_Pre, OnKilled_Pre);
	g_iKiller[iClient] = hEvent.GetInt("attacker");

	ForcePlayerSuicide(iClient);
}

Action OnKilled_Pre(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType,
	int &iWeapon, float vDamageForce[3], float vDamagePos[3])
{
	int iKiller = GetClientOfUserId(g_iKiller[iVictim]);
	if (iKiller)
	{
		iAttacker = iKiller;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
