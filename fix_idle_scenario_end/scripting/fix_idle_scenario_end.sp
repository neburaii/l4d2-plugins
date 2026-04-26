#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <hxlib>

public Plugin myinfo =
{
	name = "Fix Idle Scenario End",
	author = "Neburai",
	description = "prevent a scenario from ending if idle survivors remain",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/fix_idle_scenario_end"
};

bool	g_bLateLoaded;

ConVar	g_hConVar_MaxIdleTime;
float	g_fMaxIdleTime;

float	g_fIdleStart[MAXPLAYERS_L4D2 + 1];

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_MaxIdleTime = CreateConVar(
		"fix_idle_scenario_end_max_idle", "30.0",
		"if a survivor player has been idle for less than this amount of seconds, \
		then prevent them from causing a round to restart/fail. -1.0 to allow any \
		amount of time, 0.0 to disable plugin.",
		FCVAR_NOTIFY, true, 0.0);
	g_hConVar_MaxIdleTime.AddChangeHook(ConVarChanged_Update);
	g_fMaxIdleTime = g_hConVar_MaxIdleTime.FloatValue;

	if (g_bLateLoaded)
	{
		int iPlayer;
		float fNow = GetGameTime();

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)
				|| !IsFakeClient(i)
				|| !IsSurvivorBot(i))
				continue;

			iPlayer = GetIdlePlayer(i);
			if (!iPlayer) continue;

			g_fIdleStart[iPlayer] = fNow;
		}
	}
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fMaxIdleTime = g_hConVar_MaxIdleTime.FloatValue;
}

public void OnGoAwayFromKeyboard_Post(int iClient, bool bHandled)
{
	if (!bHandled) g_fIdleStart[iClient] = GetGameTime();
}

public Action OnScenarioCheckForDeadPlayers(bool &bSkipClamp)
{
	if (g_fMaxIdleTime == 0.0)
		return Plugin_Continue;

	int iPlayer;
	float fNow = GetGameTime();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)
			|| !IsFakeClient(i)
			|| !IsSurvivorBot(i)
			|| GetClientTeam(i) != Team_Survivor
			|| !IsPlayerAlive(i))
			continue;

		iPlayer = GetIdlePlayer(i);
		if (!iPlayer) continue;

		if (g_fMaxIdleTime != -1.0
			&& (fNow - g_fIdleStart[iPlayer]) >= g_fMaxIdleTime)
			continue;

		bSkipClamp = true;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
