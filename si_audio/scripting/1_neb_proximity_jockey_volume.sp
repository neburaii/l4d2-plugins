#include <sourcemod>
#include <sdktools>
#include <neb_stocks>
#pragma newdecls required
#pragma semicolon 1

// sounds processed will be emttied outside of the standard channel range, allowing an optimized way to distinguish them in the sound hook
#define CHANNEL_OFFSET 8

ConVar g_cMaxVolThreshold, g_cMaxQuietVol, g_cMinQuietVol, g_cMaxRange;
float g_fConVarMaxVolThreshold, g_fConVarMaxQuietVol, g_fConVarMinQuietVol, g_fConVarMaxRange;

char g_saLastSound[MAXPLAYERS_L4D2+1][PLATFORM_MAX_PATH], g_saUseSound[MAXPLAYERS_L4D2+1][PLATFORM_MAX_PATH];
int g_iaLastChannelAmount[MAXPLAYERS_L4D2+1];

public Plugin myinfo =
{
	name = "Proximity-based Jockey Volume",
	author = "Neburai",
	description = "proximity based volume for jockey's idle voice sounds",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/si_audio"
};

public void OnPluginStart()
{
	g_cMaxVolThreshold = CreateConVar("jockey_proxvol_loud_threshold", "510.0", "jockeys within this range will have their idle sounds at max volume", FCVAR_NOTIFY);
	g_cMaxQuietVol = CreateConVar("jockey_proxvol_max_quiet_vol", "0.6", "beteen max range and the threshold range, volume will scale linearly between min quiet volume, and max quiet volume", FCVAR_NOTIFY);
	g_cMinQuietVol = CreateConVar("jockey_proxvol_min_quiet_vol", "0.2", "beteen max range and the threshold range, volume will scale linearly between min quiet volume, and max quiet volume", FCVAR_NOTIFY);
	g_cMaxRange = CreateConVar("jockey_proxvol_max_range", "2000.0", "at this range and further, volume will be the min quiet volume.", FCVAR_NOTIFY);
	readConVars();
	g_cMaxVolThreshold.AddChangeHook(ConVarChanged_Cvars);
	g_cMaxQuietVol.AddChangeHook(ConVarChanged_Cvars);
	g_cMinQuietVol.AddChangeHook(ConVarChanged_Cvars);
	g_cMaxRange.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("player_death", event_player_death);

	AddNormalSoundHook(soundHook);
}
public void OnPluginEnd()
{
	RemoveNormalSoundHook(soundHook);
}

/*public void OnMapStart()
{
	for(int i = 0; i < sizeof(g_saJockeySounds); i++)
		PrecacheSound(g_saJockeySounds[i]);
}*/

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	readConVars();
}

void readConVars()
{
	g_fConVarMaxVolThreshold = g_cMaxVolThreshold.FloatValue;
	g_fConVarMaxQuietVol = g_cMaxQuietVol.FloatValue;
	g_fConVarMinQuietVol = g_cMinQuietVol.FloatValue;
	g_fConVarMaxRange = g_cMaxRange.FloatValue;
}

Action soundHook(int iaClients[MAXPLAYERS], int& iNumClients, char sSample[PLATFORM_MAX_PATH], int& iEntity, int& iChannel, float& fVolume, int& iLevel, int& iPitch, int& iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	if(iChannel > 7) return Plugin_Continue;
	if(!fVolume || !nsIsInfected(iEntity, ZCLASS_JOCKEY)) return Plugin_Continue;

	if(StrContains(sSample, "player/jockey/voice/idle/", false) == 0) // start filtering for samples we want to apply proximity volume to
	{
		strcopy(g_saUseSound[iEntity], PLATFORM_MAX_PATH, sSample);
		RequestFrame(processSound, GetClientUserId(iEntity)); // keeping it all in the same frame i think was causing out of heap errors
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void processSound(int iEntity)
{
	iEntity = GetClientOfUserId(iEntity);
	if(!nsIsClientValid(iEntity)) return;

	stopPrevSound(iEntity);

	int iListener;
	for(int i = 1; i <= MAXPLAYERS_L4D2; i++)
	{
		iListener = 0;
		if(!nsIsClientValid(i)) continue;
		if(IsFakeClient(i)) continue;
		
		if(IsClientObserver(i))
		{
			iListener = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			if(!nsIsClientValid(iListener)) continue;
		}
		else if(IsPlayerAlive(i))
			iListener = i;
		else continue;

		EmitSoundToClient(i, g_saUseSound[iEntity], iEntity, rotateChannel(iEntity), SNDLEVEL_HELICOPTER, _, getVolume(iListener, iEntity));		
	}
	if(g_iaLastChannelAmount[iEntity]) strcopy(g_saLastSound[iEntity], PLATFORM_MAX_PATH, g_saUseSound[iEntity]);
}

public void OnClientPutInServer(int iClient)
{
	g_saLastSound[iClient][0] = 0;
	g_iaLastChannelAmount[iClient] = 0;
}

void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(nsIsInfected(iClient, ZCLASS_JOCKEY)) stopPrevSound(iClient);
}

/********
 * functions
 ********/

float getVolume(int iListener, int iEmitter)
{
	float vListenerPos[3], vEmitterPos[3];
	GetClientAbsOrigin(iListener, vListenerPos);
	GetClientAbsOrigin(iEmitter, vEmitterPos);

	float fDistance = GetVectorDistance(vListenerPos, vEmitterPos);

	if(fDistance <= g_fConVarMaxVolThreshold) return 1.0; // LOUD range
	else if(fDistance > g_fConVarMaxRange) return g_fConVarMinQuietVol; // MOST QUIET range
	else // QUIET range
	{
		float fReturn = ( ((g_fConVarMaxQuietVol-g_fConVarMinQuietVol)/(g_fConVarMaxRange-g_fConVarMaxVolThreshold)) * (g_fConVarMaxRange-fDistance) ) + g_fConVarMinQuietVol;
		if(fReturn < 0.0) fReturn = 0.0;
		else if(fReturn > 1.0) fReturn = 1.0;
		return fReturn;
	}
}

void stopPrevSound(int iEntity)
{
	if(!g_saLastSound[iEntity][0] || !g_iaLastChannelAmount[iEntity]) return;

	for(int i = CHANNEL_OFFSET; i < g_iaLastChannelAmount[iEntity]+CHANNEL_OFFSET; i++)
		StopSound(iEntity, i, g_saLastSound[iEntity]);

	g_saLastSound[iEntity][0] = 0;
	g_iaLastChannelAmount[iEntity] = 0;
}

// because we play the same sound multiple times at different volumes, we have them each in a separate channel to avoid sounds cutting eachother off
int rotateChannel(int iEntity)
{
	g_iaLastChannelAmount[iEntity]++;
	return g_iaLastChannelAmount[iEntity] + CHANNEL_OFFSET -1;
}