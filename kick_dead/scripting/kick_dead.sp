#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <hxlib>

public Plugin myinfo =
{
	name = "Kick Dead SI",
	author = "Neburai",
	description = "kick a special infected's client immediately after they die",
	version = "1.5",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/kick_dead"
};

/** have to have some delay to not break display of red kill text on client */
#define KICK_DELAY	0.1

bool	g_bLateLoaded;
bool	g_bPluginStarted;

DeathData g_death;
DeathData g_incap;

RagdollData g_ragdoll;

enum struct DeathData
{
	int target;
	float pos[3];

	void OnStart(int iClient)
	{
		this.target = iClient;
		GetCollisionCenter(iClient, this.pos);
	}

	void OnEnd()
	{
		this.target = 0;
	}

	void GetPos(float vBuffer[3])
	{
		for (int i = 0; i < 3; i++)
			vBuffer[i] = this.pos[i];
	}
}

enum struct RagdollData
{
	int creating;

	int entref[MAXPLAYERS_L4D2 + 1];
	int owner[MAXPLAYERS_L4D2 + 1];

	void Check(int iEntity, const char[] sClass)
	{
		if (!this.creating || strcmp(sClass, "cs_ragdoll") != 0)
			return;

		this.entref[this.creating] = EntIndexToEntRef(iEntity);
		this.owner[this.creating] = EntIndexToEntRef(this.creating);
	}

	int Get(int iClient)
	{
		if (iClient != EntRefToEntIndex(this.owner[iClient]))
			return INVALID_ENT_REFERENCE;

		return EntRefToEntIndex(this.entref[iClient]);
	}

	void OnCreateStart(int iClient)
	{
		this.creating = iClient;
	}

	void OnCreateEnd()
	{
		this.creating = 0;
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	AddNormalSoundHook(OnNormalSound);

	if (g_bLateLoaded && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();

	// RegConsoleCmd("sm_kdspawn", Command_Spawn);
	// g_target.Init();
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
		g_bPluginStarted = false;
}

void StartPlugin()
{
	g_bPluginStarted = true;
	HXLibRescanForwards();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)
			|| !IsFakeClient(i))
			continue;

		HookClient(i);
	}
}

public void OnClientPutInServer(int iClient)
{
	if (IsFakeClient(iClient))
		HookClient(iClient);
}

void HookClient(int iClient)
{
	AddEntityHook(iClient, EntityHook_EventKilled, EHook_Pre, OnDeath_Pre);
	AddEntityHook(iClient, EntityHook_EventKilled, EHook_Post, OnDeath_Post);

	AddEntityHook(iClient, EntityHook_CreateRagdollEntity, EHook_Pre, OnRagdoll_Pre);
	AddEntityHook(iClient, EntityHook_CreateRagdollEntity, EHook_Post, OnRagdoll_Post);
}

/**********
 * ragdoll
 *********/

Action OnRagdoll_Pre(int iVictim, int iAttacker, int iInflictor, float fDamage, int &iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3])
{
	if (GetClientTeam(iVictim) == Team_Infected)
		g_ragdoll.OnCreateStart(iVictim);

	return Plugin_Continue;
}

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	g_ragdoll.Check(iEntity, sClass);
}

void OnRagdoll_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	g_ragdoll.OnCreateEnd();
}

/********
 * death
 ********/

public Action OnIncapacitatedAsTank(int iClient, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3])
{
	if (IsFakeClient(iClient))
		g_incap.OnStart(iClient);

	return Plugin_Continue;
}

public void OnIncapacitatedAsTank_Post(int iClient, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	g_incap.OnEnd();
}

Action OnDeath_Pre(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType, int &iWeapon, float vDamageForce[3], float vDamagePos[3])
{
	if (GetClientTeam(iVictim) == Team_Infected)
		g_death.OnStart(iVictim);

	return Plugin_Continue;
}

void OnDeath_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	if (g_death.target)
	{
		g_death.OnEnd();
		if (!bHandled) CreateTimer(KICK_DELAY, Timer_Kick, EntIndexToEntRef(iVictim));
	}
}

void Timer_Kick(Handle hTimer, int iEntRef)
{
	int iClient = EntRefToEntIndex(iEntRef);
	if (iClient == INVALID_ENT_REFERENCE)
		return;

	KickClient(iClient);
}

/***********
 * redirect
 ***********/

Action OnNormalSound(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int &iSeed)
{
	if (!IsSourceTarget(iEntity) || !fVolume || strcmp(sSample, "common/null.wav") == 0)
		return Plugin_Continue;

	float vPos[3];
	g_death.GetPos(vPos);
	int iRagdoll = g_ragdoll.Get(iEntity);

	if (iRagdoll == INVALID_ENT_REFERENCE)
	{
		EmitSound(iClients, iNumClients, sSample, SOUND_FROM_WORLD, SNDCHAN_STATIC, iLevel, iFlags, fVolume, iPitch, _, vPos);
		return Plugin_Handled;
	}

	iEntity = iRagdoll;
	iChannel = SNDCHAN_STATIC;
	return Plugin_Changed;
}

bool IsSourceTarget(int iEntSource)
{
	if (g_death.target && iEntSource == g_death.target)
		return true;

	if (g_incap.target && iEntSource == g_incap.target)
		return true;

	return false;
}
