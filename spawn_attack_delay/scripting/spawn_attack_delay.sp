#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <actions>
#include <hxstocks>

#define	CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Delay Special Infected Action On Spawn",
	author = "Neburai",
	description = "Set a delay before special infected can move/attack since spawning",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/spawn_attack_delay"
};

ConVar	g_hConVar_Delay;
float	g_fDelay;

Handle	g_hTimer_Blocked[MAXPLAYERS_L4D2 + 1];

public void OnPluginStart()
{
	g_hConVar_Delay = CreateConVar(
		"spawn_attack_delay", "1.0",
		"how long to block all actions from special infected on spawn",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_Delay.AddChangeHook(ConVarChanged_Update);
	g_fDelay = g_hConVar_Delay.FloatValue;

	HookEvent("player_spawn", Event_PlayerSpawn);
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fDelay = g_hConVar_Delay.FloatValue;
}

public void OnClientPutInServer(int iClient)
{
	if (g_hTimer_Blocked[iClient])
		delete g_hTimer_Blocked[iClient];
}

void Event_PlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!iClient) return;

	if (g_fDelay >= 0.1 && IsFakeClient(iClient) && GetClientTeam(iClient) == Team_Infected)
		g_hTimer_Blocked[iClient] = CreateTimer(g_fDelay, RemoveBlock, iClient);
}

void RemoveBlock(Handle hTimer, int iClient)
{
	g_hTimer_Blocked[iClient] = null;
}

public void OnActionCreated(BehaviorAction action, int iActor, const char[] sName, ActionId id)
{
	if ((1 <= iActor <= MaxClients) && GetClientTeam(iActor) == Team_Infected)
	{
		action.OnUpdate = InterceptAction;
		action.OnContact = InterceptAction;
	}
}

Action InterceptAction(BehaviorAction action, int iActor)
{
	if (!IsValidClient(iActor))
		return Plugin_Continue;

	return g_hTimer_Blocked[iActor] ? Plugin_Handled : Plugin_Continue;
}
