#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <hxlib>

public Plugin myinfo =
{
	name = "Round Restart Delay",
	author = "sorallll, Neburai",
	description = "convar to override delay of round restarts on mission lost",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/round_restart_delay"
};

enum
{
	Reason_Defeat = 1
};

bool	g_bLateLoaded;
bool	g_bPluginStarted;

ConVar	g_hConVar_Delay;
float	g_fDelay;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_Delay = CreateConVar(
		"round_restart_delay", "0.1",
		"override the delay between round restarts on mission lost. vanilla is 7.0",
		FCVAR_NOTIFY, true, 0.0);
	g_hConVar_Delay.AddChangeHook(ConVarChanged_Update);
	g_fDelay = g_hConVar_Delay.FloatValue;

	if (g_bLateLoaded && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

public void OnAllPluginsLoaded()
{
	if (!g_bPluginStarted && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

public void OnLibraryAdded(const char[] sName)
{
	if (!g_bPluginStarted && strcmp(sName, HXLIB_LIBRARY) == 0)
		StartPlugin();
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, HXLIB_LIBRARY) == 0)
		StopPlugin();
}

void StartPlugin()
{
	g_bPluginStarted = true;
	HookEvent("round_end", Event_RoundEnd);
}

void StopPlugin()
{
	g_bPluginStarted = false;
	UnhookEvent("round_end", Event_RoundEnd);
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fDelay = g_hConVar_Delay.FloatValue;
}

void Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (hEvent.GetInt("reason") != Reason_Defeat || GetScenarioRestartTime() <= 0.0)
		return;

	SetScenarioRestartTime(g_fDelay);
}
