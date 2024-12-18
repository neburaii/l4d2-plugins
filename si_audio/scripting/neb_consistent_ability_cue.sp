#include <sdktools>
#include <sourcemod>
#include <neb_stocks>
#include <left4dhooks>
#pragma newdecls required
#pragma semicolon 1

#define CONFIG "data/neb_consistent_ability_cue.cfg"
#define IDENTIFIER_CHANNEL 8

char g_saPrioritySounds[][] =
{
	"",
	"warn/smoker_warn_0",
	"", // boomer, use below array
	"attack/hunter_attackmix_0",
	"warn/spitter_spit_0",
	"", // jockey, they don't have sounds for this
	"attack/charger_charge_0"
};
char g_saZClass[][] = 
{
	"",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger"
};
// keeping them all in one array meant that all other SI with valid sounds would have 3 empty cells, wasting memory
char g_saPrioritySoundsBoomer[][] =
{
	"player/boomer/voice/warn/female_boomer_warning_",
	"player/boomer/voice/warn/male_boomer_warning_",
	"player/boomer/voice/vomit/female_boomer_vomit_",
	"player/boomer/voice/vomit/male_boomer_vomit_"
};

Handle g_htAbilityDuration[MAXPLAYERS_L4D2+1];
KeyValues g_kvVolumes;

bool g_baNoInterrupt[MAXPLAYERS_L4D2+1];
char g_saLastSound[MAXPLAYERS_L4D2+1][PLATFORM_MAX_PATH], g_saBlockedSound[MAXPLAYERS_L4D2+1][PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "Consistent Ability Cue Sounds",
	author = "Neburai",
	description = "attempt to fix SI's ability cue sounds being silent sometimes",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/si_audio"
};

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG);
	if(!FileExists(sPath)) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);
	g_kvVolumes = new KeyValues("neb_consistent_ability_cue");
	if(!g_kvVolumes.ImportFromFile(sPath)) SetFailState("\n==========\nInvalid KeyValues tree.==========");

	HookEvent("player_death", event_player_death);
	HookEvent("ability_use", event_ability_use);

	AddNormalSoundHook(soundHook);
}

public void OnMapStart()
{
	for(int i = 0; i < sizeof(g_htAbilityDuration); i++)
		g_htAbilityDuration[i] = null;
}

/**************************************************************************************************
 * sources that should re-enable the possibility for priority sounds to be interrupted by any sound
 **************************************************************************************************/

public void OnClientPutInServer(int iClient) {
	cancelPrev(iClient); }

void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast) {
	cancelPrev(GetClientOfUserId(hEvent.GetInt("userid"))); }

public void L4D2_OnChargerImpact(int iClient) {
	cancelPrev(iClient); }

public void L4D2_OnSlammedSurvivor_Post(int iVictim, int iAttacker, bool bWallSlam, bool bDeadlyCharge) {
	cancelPrev(iAttacker); }

public void L4D_OnPouncedOnSurvivor_Post(int iVictim, int iAttacker) {
	cancelPrev(iAttacker); }

public void L4D_OnShovedBySurvivor_Post(int iClient, int iVictim, const float vDir[3]) {
	cancelPrev(iVictim); }

/***************
 * Process sounds
 ***************/

// hunter's ability sound doesn't even attempt to play if it's too soon since the last time. I think this happens for the charger too, although it seems extremely rare
void event_ability_use(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iClient)) return;
	int iZClass = nsGetInfectedClass(iClient);
	if(!(iZClass == ZCLASS_HUNTER || iZClass == ZCLASS_CHARGER)) return;

	char sPath[PLATFORM_MAX_PATH];
	if(iZClass == ZCLASS_HUNTER)
	{
		if(!hEvent.GetInt("context")) return; // context of 0 is for his retreat jump, not the actual ability
		FormatEx(sPath, sizeof(sPath), "player/hunter/voice/attack/hunter_attackmix_0%i.wav", GetRandomInt(1, 3));
		EmitSoundToAll(sPath, iClient, IDENTIFIER_CHANNEL, SNDLEVEL_MINIBIKE); // why does this sound quieter? it's same as vanilla level/volume, i must be crazy
	}
	else
	{
		FormatEx(sPath, sizeof(sPath), "player/charger/voice/attack/charger_charge_0%i.wav", GetRandomInt(1, 2));
		EmitSoundToAll(sPath, iClient, IDENTIFIER_CHANNEL, SNDLEVEL_TRAIN);
	}

}

Action soundHook(int iaClients[MAXPLAYERS], int& iNumClients, char sSample[PLATFORM_MAX_PATH], int& iEntity, int& iChannel, float& fVolume, int& iLevel, int& iPitch, int& iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	// filter out irrelevant sounds. do less expensive checks first
	if(!(iChannel == SNDCHAN_VOICE || iChannel == IDENTIFIER_CHANNEL)) return Plugin_Continue;
	if(!fVolume) return Plugin_Continue;
	if(!nsIsInfected(iEntity)) return Plugin_Continue;
	int iZClass = nsGetInfectedClass(iEntity);
	if(!(iZClass && iZClass <= ZCLASS_MAX) || iZClass == ZCLASS_JOCKEY) return Plugin_Continue;

	// determine if this is a "priority" sound
	bool bIsPriority;
	if(iZClass == ZCLASS_BOOMER)
	{
		for(int i = 0; i < sizeof(g_saPrioritySoundsBoomer); i++)
		{
			if(StrContains(sSample, g_saPrioritySoundsBoomer[i], false) == 0)
			{
				bIsPriority = true;
				break;
			}
		}
	}
	else
	{
		char sBuffer[PLATFORM_MAX_PATH];
		FormatEx(sBuffer, sizeof(sBuffer), "player/%s/voice/%s", g_saZClass[iZClass], g_saPrioritySounds[iZClass]);
		if(StrContains(sSample, sBuffer, false) == 0) bIsPriority = true;
	}

	// if it's a non-priority sound, make sure it can't play if a priority sound is still playing, or let it play and stop function here
	if(!bIsPriority && iChannel == SNDCHAN_VOICE)
	{
		if(g_baNoInterrupt[iEntity])
		{
			g_saBlockedSound[iEntity] = sSample;
			RequestFrame(forgetBlocked, iEntity);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}

	// any samples making it this far are priority sounds
	// in the case of hunters and chargers, there will be many times where vanilla does successfully play their cue sound. This line will avoid the sound from playing twice by forcing our version of it coming from the ability_use hook
	if((iZClass == ZCLASS_HUNTER || iZClass == ZCLASS_CHARGER) && iChannel == SNDCHAN_VOICE) return Plugin_Handled;

	// set up non-priority sound block for this entity, with a termination timer set
	if(g_htAbilityDuration[iEntity] != null) delete g_htAbilityDuration[iEntity];
	g_baNoInterrupt[iEntity] = true;
	g_htAbilityDuration[iEntity] = CreateTimer(getDuration(sSample), allowInterrupt, iEntity, TIMER_FLAG_NO_MAPCHANGE);
	
	// record this as last sound play so that we can interrupt it manually
	g_saLastSound[iEntity] = sSample;

	// move hunter/charger sounds to the correct channel. (it's originally in channel IDENTIFIER_CHANNEL for identification reasons)
	if(iZClass == ZCLASS_HUNTER || iZClass == ZCLASS_CHARGER)
	{
		iChannel = SNDCHAN_VOICE;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

// remember last blocked for only a tick. This way, we can check if the string has content as a way of knowing that a sound got blocked in the same tick where we allow them to go through again
void forgetBlocked(int iEntity)
{
	g_saBlockedSound[iEntity][0] = 0;
}

Action allowInterrupt(Handle hTimer, int iEntity)
{
	g_htAbilityDuration[iEntity] = null;
	g_baNoInterrupt[iEntity] = false;
	return Plugin_Stop;
}

/****************
 * other functions
 ****************/

float getDuration(const char[] sSample)
{
	char sBuffer[PLATFORM_MAX_PATH];
	for(int i = 0; i < PLATFORM_MAX_PATH; i++)
	{
		if(!sSample[i]) break;
		if(IsCharUpper(sSample[i])) sBuffer[i] = CharToLower(sSample[i]);
		else if(sSample[i] == '/') sBuffer[i] = ':';
		else sBuffer[i] = sSample[i];
	}
	return g_kvVolumes.GetFloat(sBuffer, 0.75);
}

/* Alternative function to get sound duration, although it requires the sound files to exist server side. Check the cfg in the data folder for which files to upload if you plan to use this alternative
// return duration of sound file. This function only works for 16bit, 44.1khz, mono wav files
#define WAV_HEADER_SIZE 44
float getDuration(const char[] sSample)
{
	char sPath[PLATFORM_MAX_PATH];
	FormatEx(sPath, sizeof(sPath), "sound/%s", sSample);
	for(int i = 0; i < sizeof(sPath); i++)
	{
		if(!sPath[i]) break;
		if(IsCharUpper(sPath[i])) sPath[i] = CharToLower(sPath[i]);
	}	
	if(!FileExists(sPath)) return 0.1;

	int iByteSize = FileSize(sPath);

	return (float(iByteSize - WAV_HEADER_SIZE) / 2.0) / 44100.0;
}
*/

void cancelPrev(int iClient)
{
	if(g_htAbilityDuration[iClient] != null) delete g_htAbilityDuration[iClient];

	if(g_baNoInterrupt[iClient] && g_saLastSound[iClient][0]) StopSound(iClient, SNDCHAN_VOICE, g_saLastSound[iClient]);

	g_baNoInterrupt[iClient] = false;		
	g_saLastSound[iClient][0] = 0;

	// plays sounds that got block before this within the same tick
	if(!nsIsClientValid(iClient)) return;
	if(IsPlayerAlive(iClient) && g_saBlockedSound[iClient][0])
	{
		EmitSoundToAll(g_saBlockedSound[iClient], iClient, SNDCHAN_VOICE, SNDLEVEL_HELICOPTER);
	}
}