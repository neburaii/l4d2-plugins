#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Kick Dead SI",
	author = "Neburai",
	description = "kick a special infected's client immediately after they die",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins"
};

#define	GAMEDATA "neb_kick_dead.games"

#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <neb_stocks>

DynamicDetour g_hDetourOnRagdollCreated;

int	g_iClientRagdoll[MAXPLAYERS_L4D2+1], g_iGettingRagdoll = -1;
bool g_bClientDied[MAXPLAYERS_L4D2+1];

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(!FileExists(sPath)) SetFailState("missing required file: \"%s\"", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("failed to load gamedata: \"%s\"", GAMEDATA);

	g_hDetourOnRagdollCreated = DynamicDetour.FromConf(hGameData, "HX::CCSPlayer::CreateRagdollEntity");
	if(g_hDetourOnRagdollCreated == null) SetFailState("failed to create detour for \"HX::CCSPlayer::CreateRagdollEntity\"");
	g_hDetourOnRagdollCreated.Enable(Hook_Pre, DTR_OnRagdollCreated_Pre);
	g_hDetourOnRagdollCreated.Enable(Hook_Post, DTR_OnRagdollCreated_Post);

	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	AddNormalSoundHook(soundHook);
}

// reset client data
public void OnClientPutInServer(int iClient)
{
	g_iClientRagdoll[iClient] = -1;
	g_bClientDied[iClient] = false;
}

// mark as dead so the soundhook knows the context is right
void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim)) return;

	g_bClientDied[iVictim] = true;

	CreateTimer(0.1, delayedKick, GetClientUserId(iVictim), TIMER_FLAG_NO_MAPCHANGE);
}

// delayed to fix red kill text not showing up for players with high ping
void delayedKick(Handle hTimer, int iUID)
{
	int iClient = GetClientOfUserId(iUID);
	if(!nsIsClientValid(iClient)) return;

	KickClient(iClient);
}

// marking tank as dead should happen here, since he makes his death sound after incap but before proper death
void event_player_incapacitated(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iTank = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iTank, ZCLASS_TANK)) return;

	g_bClientDied[iTank] = true;
}

// get ragdoll entity so that we can emit sounds from it
MRESReturn DTR_OnRagdollCreated_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	if(!nsIsInfected(pThis)) return MRES_Ignored;
	g_iGettingRagdoll = pThis;
	return MRES_Ignored;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(g_iGettingRagdoll == -1) return;
	if(strcmp(sClassname, "cs_ragdoll") != 0) return;

	g_iClientRagdoll[g_iGettingRagdoll] = iEntity;
}

// can't for the life of me figure out how to get an entity index from the return value. this 3 step solution works just as well though
MRESReturn DTR_OnRagdollCreated_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	g_iGettingRagdoll = -1;
	return MRES_Ignored;
}

// sounds to match as death sounds
char g_sDeathSounds[][] =
{
	"player/smoker/death/",
	"player/smoker/voice/death/",
	"player/hunter/voice/death/",
	"player/spitter/voice/die/",
	"player/jockey/voice/death/",
	"player/charger/voice/die/",
	"player/tank/voice/die/"
};

// redirect sound
Action soundHook(int iaClients[MAXPLAYERS], int& iNumClients, char sSample[PLATFORM_MAX_PATH], int& iEntity, int& iChannel, float& fVolume, int& iLevel, int& iPitch, int& iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	if(!nsIsInfected(iEntity) || !g_bClientDied[iEntity]) return Plugin_Continue;

	for(int i = 0; i < sizeof(g_sDeathSounds); i++)
	{
		if(StrContains(sSample, g_sDeathSounds[i]) == 0)
		{
			// prefer emitting from ragdoll as the sound will follow moving ragdolls this way
			if(nsIsEntityValid(g_iClientRagdoll[iEntity])) EmitSound(iaClients, iNumClients, sSample, g_iClientRagdoll[iEntity], iChannel, iLevel, iFlags, fVolume, iPitch);
			else
			{
				// failsafe in case ragdoll wasn't created
				float vPos[3];
				GetClientAbsOrigin(iEntity, vPos);
				EmitSound(iaClients, iNumClients, sSample, _, iChannel, iLevel, iFlags, fVolume, iPitch, _, vPos);
			}
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}