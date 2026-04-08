#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hxlib>

public Plugin myinfo =
{
	name = "Kick Dead SI",
	author = "Neburai",
	description = "kick a special infected's client immediately after they die",
	version = "1.4",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/kick_dead"
};

int		g_iClientRagdoll[MAXPLAYERS_L4D2 + 1] = {-1, ...};
bool	g_bRedirectAudio[MAXPLAYERS_L4D2 + 1];

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	AddNormalSoundHook(OnNormalSound);
}

public void OnClientPutInServer(int iClient)
{
	g_iClientRagdoll[iClient] = INVALID_ENT_REFERENCE;
	g_bRedirectAudio[iClient] = false;

	AddEntityHook(iClient, EntityHook_CreateRagdollEntity, EHook_Post, OnCreateRagdollEntity_Post);
}

void Event_PlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iUserID = hEvent.GetInt("userid");
	int iVictim = GetClientOfUserId(iUserID);

	if (!IsValidClient(iVictim)
		|| !IsFakeClient(iVictim)
		|| GetClientTeam(iVictim) != Team_Infected)
		return;

	g_bRedirectAudio[iVictim] = true;
	CreateTimer(0.1, Timer_Kick, iUserID, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_PlayerIncapacitated(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClient(iVictim)
		|| !IsFakeClient(iVictim)
		|| GetClientTeam(iVictim) != Team_Infected
		|| GetZombieClass(iVictim) != ZClass_Tank)
		return;

	g_bRedirectAudio[iVictim] = true;
}

void OnCreateRagdollEntity_Post(int iRagdoll, int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	if (bHandled || !IsValidClient(iVictim) || !IsValidEdict(iRagdoll))
		return;

	g_iClientRagdoll[iVictim] = EntIndexToEntRef(iRagdoll);
}

void Timer_Kick(Handle hTimer, int iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	if (!iClient) return;

	KickClient(iClient);
}

Action OnNormalSound(int iClients[64], int &iClientsNum, char sSample[256], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags)
{
	if (!IsValidClient(iEntity)
		|| !g_bRedirectAudio[iEntity]
		|| GetClientTeam(iEntity) != Team_Infected)
		return Plugin_Continue;

	int iEmitFromEnt = EntRefToEntIndex(g_iClientRagdoll[iEntity]);
	float vPos[3];

	if (iEmitFromEnt == INVALID_ENT_REFERENCE)
	{
		GetClientAbsOrigin(iEntity, vPos);
		iEmitFromEnt = 0;
	}

	EmitSound(iClients, iClientsNum, sSample, iEmitFromEnt, _, iLevel, iFlags, fVolume, iPitch, _, iEmitFromEnt ? NULL_VECTOR : vPos);
	return Plugin_Handled;
}
