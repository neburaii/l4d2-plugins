#pragma newdecls required
#pragma semicolon 1

#define	CVAR_FLAGS	FCVAR_NOTIFY

#include <neb_stocks> // is infected stocks
#include <left4dhooks> // get survivor victim stock

ConVar	g_cDeviation, g_cDuration, g_cEnabled;
bool 	g_bCVEnabled;
float	g_fCVDeviation;
int		g_iCVDuration;

float	g_vPositions[MAXPLAYERS+1][3];
int		g_iPositionsHeldFor[MAXPLAYERS+1], g_iUID[MAXPLAYERS+1];

public void OnPluginStart()
{
	g_cEnabled = CreateConVar("despawn_stuck", "1", "enable/disable despawning of stuck SI", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cDeviation = CreateConVar("despawn_stuck_deviation", "12.0", "distance an SI must move 2 dimensionally to avoid being considered as stuck", CVAR_FLAGS, true, 0.0);
	g_cDuration = CreateConVar("despawn_stuck_duration", "15", "time (integer) in seconds an SI must be stuck to be considered as stuck", CVAR_FLAGS, true, 0.0);

	g_cEnabled.AddChangeHook(ConVarChanged);
	g_cDeviation.AddChangeHook(ConVarChanged);
	g_cDuration.AddChangeHook(ConVarChanged);

	loadConVars();

	CreateTimer(1.0, timerDespawnStuck, _, TIMER_REPEAT);
}

void ConVarChanged(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	loadConVars();
}

void loadConVars()
{
	g_bCVEnabled = g_cEnabled.BoolValue;
	g_fCVDeviation = g_cDeviation.FloatValue;
	g_iCVDuration = g_cDuration.IntValue;
}

Action timerDespawnStuck(Handle hTimer)
{
	if(!g_bCVEnabled) 
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			g_iPositionsHeldFor[i] = 0;
		}

		return Plugin_Continue;
	}

	int iZClass, iUID;
	float vPos[3];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsInfected(i)) continue;
		iZClass = nsGetInfectedClass(i);
		if(iZClass < 1 || iZClass > 6) continue;

		GetClientAbsOrigin(i, vPos);
		iUID = GetClientUserId(i);
		if(!g_iPositionsHeldFor[i] || iUID != g_iUID[i] || (FloatAbs(g_vPositions[i][0] - vPos[0]) > g_fCVDeviation || FloatAbs(g_vPositions[i][1] - vPos[1]) > g_fCVDeviation) || L4D2_GetSurvivorVictim(i) != -1)
		{
			g_iUID[i] = iUID;
			g_iPositionsHeldFor[i] = 1;
			g_vPositions[i] = vPos;
			continue;
		}

		g_iPositionsHeldFor[i]++;

		if(g_iPositionsHeldFor[i] > g_iCVDuration)
		{
			ForcePlayerSuicide(i);
			g_iPositionsHeldFor[i] = 0;
			continue;
		}
	}

	return Plugin_Continue;
}