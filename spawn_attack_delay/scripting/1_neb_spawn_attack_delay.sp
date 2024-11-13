#include <sourcemod>
#include <neb_stocks>
#include <entity_prop_stocks>

#define	CVAR_FLAGS	FCVAR_NOTIFY

ConVar	g_cBlockTime;
float	g_fConVarBlockTime;

bool	g_baClientsBlocked[MAXPLAYERS_L4D2+1];

public void OnPluginStart()
{
	g_cBlockTime = CreateConVar("si_spawn_action_delay", "1.0", "how long to block all actions from an SI immediately after they spawn (movement, attacks, etc)", CVAR_FLAGS, true, 0.1, true, 5.0);
	readConVars();
	g_cBlockTime.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("player_spawn", event_player_spawn);
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	readConVars();
}

void readConVars()
{
	g_fConVarBlockTime = g_cBlockTime.FloatValue;
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
	if(g_baClientsBlocked[client])
		return Plugin_Handled;
	return Plugin_Continue;
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	g_baClientsBlocked[iClient] = false;
	if(!nsIsInfected(iClient)) return;

	g_baClientsBlocked[iClient] = true;
	CreateTimer(g_fConVarBlockTime, unblock, iClient);
} 

Action unblock(Handle hTimer, int iClient)
{
	g_baClientsBlocked[iClient] = false;
	return Plugin_Stop;
}
