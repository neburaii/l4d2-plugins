#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Kick Dead SI",
	author = "Neburai",
	description = "kick a special infected's client immediately after they die",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins"
};

#include <sdktools>
#include <neb_stocks>

public void OnPluginStart()
{
	HookEvent("player_death", event_player_death);
	AddNormalSoundHook(soundHook);
}

void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim)) return;
	
	int iVictimClass = nsGetInfectedClass(iVictim);

	// kick so that they immediately disconnect, freeing up their slot much sooner
	if(1 <= iVictimClass <= 6 || iVictimClass == ZCLASS_TANK) KickClient(iVictim);
}

/******************************
 * fix death sounds not playing
 *****************************/

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

Action soundHook(int iaClients[MAXPLAYERS], int& iNumClients, char sSample[PLATFORM_MAX_PATH], int& iEntity, int& iChannel, float& fVolume, int& iLevel, int& iPitch, int& iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	if(!nsIsInfected(iEntity)) return Plugin_Continue;

	for(int i = 0; i < sizeof(g_sDeathSounds); i++)
	{
		if(StrContains(sSample, g_sDeathSounds[i]) == 0)
		{
			float vPos[3];
			GetClientAbsOrigin(iEntity, vPos);
			EmitSound(iaClients, iNumClients, sSample, 0, iChannel, iLevel, iFlags, fVolume, iPitch, _, vPos);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}