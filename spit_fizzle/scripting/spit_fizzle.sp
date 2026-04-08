#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#include <hxlib>

#define SPIT_MIN_FLAMES 2

bool	g_bLateLoaded;

ConVar	g_hConVarFizzleOnStagger;
ConVar	g_hConVarFizzleOnDeath;

bool	g_bConVarFizzleOnStagger;
bool	g_bConVarFizzleOnDeath;

int		g_iSpittersProjectile[MAXPLAYERS_L4D2+1] = {INVALID_ENT_REFERENCE, ...};
int		g_iSpittersPuddle[MAXPLAYERS_L4D2+1] = {INVALID_ENT_REFERENCE, ...};

public Plugin myinfo =
{
	name = "Spit Fizzle",
	author = "Neburai",
	description = "If a spitter dies or staggers, her spit projectile will go poof and her spit puddles stop growing",
	version = "2.2",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/spit_fizzle"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
}

public void OnPluginStart()
{
	g_hConVarFizzleOnStagger = CreateConVar(
		"spit_fizzle_on_stagger", "1",
		"When a spitter staggers, should their spit projectile be deleted and their spit puddle's growth be stopped?",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVarFizzleOnStagger.AddChangeHook(ConVarChanged_Update);

	g_hConVarFizzleOnDeath = CreateConVar(
		"spit_fizzle_on_death", "1",
		"When a spitter dies, should their spit projectile be deleted and their spit puddle's growth be stopped?",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVarFizzleOnDeath.AddChangeHook(ConVarChanged_Update);

	ReadConVars();

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("spit_burst", Event_SpitBurst);

	if (g_bLateLoaded) HXLibRescanForwards();
}

void ConVarChanged_Update(ConVar hConvar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_bConVarFizzleOnStagger = g_hConVarFizzleOnStagger.BoolValue;
	g_bConVarFizzleOnDeath = g_hConVarFizzleOnDeath.BoolValue;
}

public void OnClientPutInServer(int iClient)
{
	g_iSpittersProjectile[iClient] = INVALID_ENT_REFERENCE;
	g_iSpittersPuddle[iClient] = INVALID_ENT_REFERENCE;
}

/*********************************************
 * associate puddles/projectiles with spitters
 *********************************************/

public void OnCreateSpitterProjectile_Post(int iSpitter, int iProjectile, const float vOrigin[3], const float vAngles[3], const float vVelocity[3], const float vRotation[3], bool bHandled)
{
	if (bHandled || !IsValidClient(iSpitter)) return;
	g_iSpittersProjectile[iSpitter] = EntIndexToEntRef(iProjectile);
}

void Event_SpitBurst(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClient(iClient)) return;

	int iPuddle = hEvent.GetInt("subject", INVALID_ENT_REFERENCE);
	if (!IsValidEdict(iPuddle)) return;

	g_iSpittersPuddle[iClient] = EntIndexToEntRef(iPuddle);
}

/******************
 * trigger fizzle
 *****************/

public void L4D2_OnStagger_Post(int iClient, int iSource)
{
	OnStagger(iClient);
}

public void L4D_OnShovedBySurvivor_Post(int iClient, int iVictim, const float vDir[3])
{
	OnStagger(iVictim);
}

void OnStagger(int iClient)
{
	if (!g_bConVarFizzleOnStagger) return;
	if (!IsSpitter(iClient)) return;

	Fizzle(iClient);
}

void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (!g_bConVarFizzleOnDeath) return;
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsSpitter(iClient)) return;

	Fizzle(iClient);
}

public void OnClientDisconnect(int iClient)
{
	if (!g_bConVarFizzleOnDeath) return;
	if (!IsSpitter(iClient)) return;
	if (!IsPlayerAlive(iClient)) return;

	Fizzle(iClient);
}

void Fizzle(int iClient)
{
	int iEntity = EntRefToEntIndex(g_iSpittersProjectile[iClient]);
	if (iEntity != INVALID_ENT_REFERENCE)
		RemoveEntity(iEntity);

	iEntity = EntRefToEntIndex(g_iSpittersPuddle[iClient]);
	if (iEntity != INVALID_ENT_REFERENCE)
		GetInferno(iEntity).maxFlames = SPIT_MIN_FLAMES;
}

/*******
 * misc
 *******/

bool IsSpitter(int iEntity)
{
	return	IsValidClient(iEntity)
			&& GetClientTeam(iEntity) == Team_Infected
			&& GetZombieClass(iEntity) == ZClass_Spitter;
}
