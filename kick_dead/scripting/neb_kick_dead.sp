#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Kick Dead SI",
	author = "Neburai",
	description = "kick a special infected's client immediately after they die",
	version = "1.2",
	url = "https://github.com/neburaii/l4d2-plugins"
};

#define	GAMEDATA "neb_kick_dead.games"

#include <sdktools>
#include <sdkhooks>
#include <ragdoll_hook>
#include <neb_stocks>

ConVar g_cQuickerTankDeath;

int	g_iClientRagdoll[MAXPLAYERS_L4D2+1];
bool g_bClientDied[MAXPLAYERS_L4D2+1], g_bCVQuickerTankDeath;

public void OnPluginStart()
{
	g_cQuickerTankDeath = CreateConVar("skip_tank_death_animation", "1", "make tank die sooner by skipping its death animation. Has a gameplay side effect of preventing his collision from lingering after death", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cQuickerTankDeath.AddChangeHook(ConVarChanged_QuickerTankDeath);
	g_bCVQuickerTankDeath = g_cQuickerTankDeath.BoolValue;

	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	AddNormalSoundHook(soundHook);
}

void ConVarChanged_QuickerTankDeath(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_bCVQuickerTankDeath = cConvar.BoolValue;
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

	if(g_bCVQuickerTankDeath) ForcePlayerSuicide(iTank);
	else g_bClientDied[iTank] = true;
}

// get ragdoll entity so that we can emit sounds from it
public void OnRagdollCreated_Post(int iPlayer, int iRagdoll, Address aTakeDamageInfo, bool bPluginCreated)
{
	if(bPluginCreated) return;
	if(!nsIsInfected(iPlayer)) return;
	if(!nsIsEntityValid(iRagdoll)) return;

	g_iClientRagdoll[iPlayer] = iRagdoll;
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
				EmitSound(iaClients, iNumClients, sSample, 0, _, iLevel, iFlags, fVolume, iPitch, _, vPos);
			}
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}