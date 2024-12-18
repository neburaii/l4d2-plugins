#include <sourcemod>
#include <neb_stocks>
#include <sdktools>

#define LOG_FILE "_audio_test.txt"

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

public Plugin myinfo =
{
	name = "SI voice sound logging",
	author = "Neburai",
	description = "a tool to help understand the timing of when sounds play, or if they play at all when expected",
	version = "0.1b",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/si_audio"
};

public void OnPluginStart()
{
	HookEvent("ability_use", event_ability_use);
	RegAdminCmd("sm_silent", cmdBookmark, ADMFLAG_BAN);
	AddNormalSoundHook(soundHook);
}

Action cmdBookmark(int iClient, int iArgs)
{
	if(!iArgs)
	{
		ReplyToCommand(iClient, "use it right pls. /silent classname (e.g /silent charger)");
		return Plugin_Handled;
	}
	char sClassname[16];
	GetCmdArg(1, sClassname, sizeof(sClassname));
	logActivity(iClient, "[BOOKMARK] silent %s!", sClassname);
	ReplyToCommand(iClient, "successfully logged bookmark to Path_SM/logs/%s", LOG_FILE);
	return Plugin_Handled;
}

void event_ability_use(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(!nsIsInfected(iClient)) return;
	if(!(nsGetInfectedClass(iClient) && nsGetInfectedClass(iClient) <= ZCLASS_MAX)) return;

	char sAbility[32];
	event.GetString("ability", sAbility, sizeof(sAbility), "null");
	logActivity(iClient, "[ability_use] %s - context: %i", sAbility, event.GetInt("context", 99999));
}

Action soundHook(int iaClients[MAXPLAYERS], int& iNumClients, char sSample[PLATFORM_MAX_PATH], int& iEntity, int& iChannel, float& fVolume, int& iLevel, int& iPitch, int& iFlags, char sSoundEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	if(!nsIsInfected(iEntity)) return Plugin_Continue;
	int iZClass = nsGetInfectedClass(iEntity);
	if(!(iZClass && iZClass <= ZCLASS_MAX)) return Plugin_Continue;

	char sBuffer[PLATFORM_MAX_PATH];
	FormatEx(sBuffer, sizeof(sBuffer), "player/%s/voice/", g_saZClass[iZClass]);
	bool bInVoiceDir = StrContains(sSample, sBuffer) == 0;
	logActivity(iEntity, "[soundHook] %schannel: %i (%f) | %s", bInVoiceDir ? "VOICEFOLDER | " : "", iChannel, fVolume, sSample);
	
	return Plugin_Continue;
}

/**
 * logging
 */

void logActivity(int iEntity, const char[] format, any ...)
{
	char sBuffer[512], sPath[PLATFORM_MAX_PATH];
	VFormat(sBuffer, sizeof(sBuffer), format, 3);
	BuildPath(Path_SM, sPath, sizeof(sPath), "logs/%s", LOG_FILE);
	LogToFile(sPath, "| [tick: %i] | [entity: %i (%N)] | %s", GetGameTickCount(), iEntity, iEntity, sBuffer);
}