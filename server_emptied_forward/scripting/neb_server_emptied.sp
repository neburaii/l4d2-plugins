#include <sourcemod>
#include <neb_stocks>
#include <left4dhooks>

ConVar g_hRequiredChecks;
int g_iConVarRequiredChecks;

Handle g_hChecks = null;

GlobalForward g_hOnServerEmptied;

int g_iCount;
bool g_bServerEmpty = true;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	RegPluginLibrary("server_emptied");
	CreateNative("IsServerEmpty", Native_IsServerEmpty);
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hOnServerEmptied = CreateGlobalForward("OnServerEmptied", ET_Ignore);

	g_hRequiredChecks = CreateConVar("server_emptied_required_checks", "150", "how many consecutive seconds of no human prescense until server is marked as empty. 120 seconds is the max the game by default will wait for non respondant clients during load screens, so default value is based off of that + a good amount of extra to compensate for the biggest map loads on the worst hardware possible. Most times, the forward will call long before this time elapses due to the server hibernating. Timer is just a backup", FCVAR_NOTIFY, true, 1.0);
	g_iConVarRequiredChecks = g_hRequiredChecks.IntValue;
	g_hRequiredChecks.AddChangeHook(ConVarChanged_Cvars);

	// check if the plugin was loaded midgame
	if(areHumansInGame()) g_bServerEmpty = false;
}

void ConVarChanged_Cvars(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iConVarRequiredChecks = g_hRequiredChecks.IntValue;
}

public any Native_IsServerEmpty(Handle hPlugin, int iNumParams)
{
	return g_bServerEmpty;
}

public void OnClientConnected(int iClient)
{
	if(!g_bServerEmpty) return;
	if(!IsFakeClient(iClient)) g_bServerEmpty = false;
}

public void OnClientDisconnect_Post(int iClient)
{
	if(!areHumansInGame())
	{
		if(g_hChecks != null) delete g_hChecks;
		g_iCount = 0;
		g_hChecks = CreateTimer(1.0, consecutiveChecks, _, TIMER_REPEAT);
	}
}

Action consecutiveChecks(Handle hTimer)
{
	if(areHumansInGame())
	{
		g_hChecks = null;
		return Plugin_Stop;
	}
	else g_iCount++;

	if(g_iCount >= g_iConVarRequiredChecks)
	{
		g_bServerEmpty = true;
		Call_StartForward(g_hOnServerEmptied);
		Call_Finish();
		g_hChecks = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void L4D_OnServerHibernationUpdate(bool bHibernating)
{
	if(bHibernating) // impossible for it to hibernate between map transitions. The timer method is just a backup for when server fails to hibernate
	{
		if(g_hChecks != null) delete g_hChecks;
		g_bServerEmpty = true;
		Call_StartForward(g_hOnServerEmptied);
		Call_Finish();
	}
}

bool areHumansInGame(int iSkip = 0)
{
	for(int i = 1; i <= MAXPLAYERS_L4D2; i++)
	{
		if(i == iSkip) continue;
		if(!nsIsClientValid(i)) continue;
		if(!IsFakeClient(i)) return true;
	}
	return false;
}