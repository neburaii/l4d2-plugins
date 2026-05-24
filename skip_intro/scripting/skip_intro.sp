#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>		// OnEntityCreated
#include <sdktools>		// FindEntityByClassname
#include <hxlib>		// AcceptInput hooks

#define WHITELIST_FILE	"data/skip_intro_whitelist.txt"
#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Skip Intro Cutscenes",
	author = "Neburai",
	description = "reliably skips intro cutscenes for all maps not in a whitelist",
	version = "1.3",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/skip_intro"
};

bool	g_bMapAllowIntro;
bool	g_bInIntro;
bool	g_bIntroSequenceStripped;

bool	g_bLateLoaded;
bool	g_bHookingEnabled;

Handle	g_hTimer_DelayEndIntro;

ConVar	g_hConVar_DelayPost;
float	g_fDelayPost;

ConVar	g_hConVar_DelayFailsafe;
float	g_fDelayFailsafe;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_DelayFailsafe = CreateConVar(
		"skip_intro_delay_failsafe", "60.0",
		"if there was no \"FinishIntro\" input, then consider the intro done after this " ...
		"much time has passed since the round started.",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_DelayFailsafe.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DelayPost = CreateConVar(
		"skip_intro_delay_post", "5.0",
		"after a \"FinishIntro\" input, wait this long before considering the intro as done.",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_DelayPost.AddChangeHook(ConVarChanged_Update);

	ReadConVars();

	HookEvent("round_start_pre_entity", Event_RoundStartPreEntity);

	if (g_bLateLoaded)
	{
		OnMapStart();
		if (LibraryExists(HXLIB_LIBRARY))
			EnableHooking();
	}
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_fDelayPost = g_hConVar_DelayPost.FloatValue;
	g_fDelayFailsafe = g_hConVar_DelayFailsafe.FloatValue;
}

public void OnAllPluginsLoaded()
{
	if (!g_bHookingEnabled && LibraryExists(HXLIB_LIBRARY))
		EnableHooking();
}

public void OnLibraryAdded(const char[] sName)
{
	if (strcmp(sName, HXLIB_LIBRARY) == 0)
		EnableHooking();
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, HXLIB_LIBRARY) == 0)
		g_bHookingEnabled = false;
}

void EnableHooking()
{
	g_bHookingEnabled = true;

	int iEntity = -1;

	while ((iEntity = FindEntityByClassname(iEntity, "info_director")) != -1)
		AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_InfoDirector);

	while ((iEntity = FindEntityByClassname(iEntity, "point_viewcontrol_multiplayer")) != -1)
		AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_PointViewcontrol);

	while ((iEntity = FindEntityByClassname(iEntity, "point_viewcontrol_survivor")) != -1)
		AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_PointViewcontrol);

	while ((iEntity = FindEntityByClassname(iEntity, "env_fade")) != -1)
		AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_EnvFade);
}

public void OnPluginEnd()
{
	if (g_bHookingEnabled)
	{
		int iEntity = -1;

		while ((iEntity = FindEntityByClassname(iEntity, "info_director")) != -1)
			RemoveEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_InfoDirector);

		while ((iEntity = FindEntityByClassname(iEntity, "point_viewcontrol_multiplayer")) != -1)
			RemoveEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_PointViewcontrol);

		while ((iEntity = FindEntityByClassname(iEntity, "point_viewcontrol_survivor")) != -1)
			RemoveEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_PointViewcontrol);

		while ((iEntity = FindEntityByClassname(iEntity, "env_fade")) != -1)
			RemoveEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_EnvFade);
	}
}

public void OnMapStart()
{
	g_bMapAllowIntro = false;

	char sCurrentMap[128];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), WHITELIST_FILE);
	if (!FileExists(sPath)) return;

	char sLine[128];
	File hFile = OpenFile(sPath, "r");

	/** scan whitelist for line with string matching current map */
	while (!hFile.EndOfFile())
	{
		hFile.ReadLine(sLine, sizeof(sLine));
		for (int i = 0; i < sizeof(sLine); i++)
		{
			if (!sLine[i]) break;
			if (IsCharSpace(sLine[i]) || sLine[i] == '/')
			{
				sLine[i] = 0;
				break;
			}
		}
		if (!sLine[0]) continue;

		if (strcmp(sCurrentMap, sLine) == 0)
		{
			g_bMapAllowIntro = true;
			break;
		}
	}
}

void Event_RoundStartPreEntity(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	g_bIntroSequenceStripped = false;
	g_bInIntro = true;
	SetEndIntroDelay(g_fDelayFailsafe);
}

/*********
 * hooks
 *********/

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (g_bHookingEnabled)
	{
		if (strcmp(sClassname, "info_director") == 0)
			AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_InfoDirector);

		else if (StrContains(sClassname, "point_viewcontrol_") == 0)
			AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_PointViewcontrol);

		else if (strcmp(sClassname, "env_fade") == 0)
			AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_EnvFade);
	}
}

public Action OnAcceptInput_InfoDirector(int iReceiver, char[] sInput, int &iActivator, int &iSource, Variant params)
{
    if (CanSkipIntro())
    {
		/** aside from locking movement, ForceSurvivorPositions is also
		 * responsible for teleporting survivors to their destined info_survivor_position,
		 * which some custom maps rely on to have survivors start in the intended spot.
		 * because of this, blocking the input is a bad idea
		 */
        if (strcmp(sInput, "ForceSurvivorPositions") == 0)
		{
			StripIntroSequence();
			RequestFrame(ReleaseSurvivorPositions, iReceiver);
		}

		else if (strcmp(sInput, "StartIntro") == 0)
		{
			if (g_hTimer_DelayEndIntro) delete g_hTimer_DelayEndIntro;
			return Plugin_Handled;
		}

		else if (strcmp(sInput, "FinishIntro") == 0)
			SetEndIntroDelay(g_fDelayPost);
    }

    return Plugin_Continue;
}

public Action OnAcceptInput_PointViewcontrol(int iReceiver, char[] sInput, int &iActivator, int &iSource, Variant params)
{
    if (CanSkipIntro())
    {
        if (strcmp(sInput, "Enable") == 0 || strcmp(sInput, "StartMovement") == 0)
			return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action OnAcceptInput_EnvFade(int iReceiver, char[] sInput, int &iActivator, int &iSource, Variant params)
{
    if (CanSkipIntro())
    {
        if (strcmp(sInput, "Fade") == 0)
			return Plugin_Handled;
    }

    return Plugin_Continue;
}

/*****************
 * Local functions
 *****************/

bool CanSkipIntro()
{
	return g_bInIntro && !g_bMapAllowIntro;
}

void SetEndIntroDelay(float fDelay)
{
	if (g_hTimer_DelayEndIntro)
		delete g_hTimer_DelayEndIntro;

	if (fDelay > 0.0)
		g_hTimer_DelayEndIntro = CreateTimer(fDelay, EndIntro);
}

void EndIntro(Handle hTimer)
{
	g_hTimer_DelayEndIntro = null;
	g_bInIntro = false;
}

void ReleaseSurvivorPositions(int iDirector)
{
	AcceptEntityInput(iDirector, "ReleaseSurvivorPositions");
}

/** prevent survivor models from playing animations due to ForceSurvivorPositions input triggering the sequence from destined info_survivor_position */
void StripIntroSequence()
{
	if (g_bIntroSequenceStripped) return;
	g_bIntroSequenceStripped = true;

	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "info_survivor_position")) != -1)
		SetEntPropString(iEntity, Prop_Data, "m_iszSurvivorIntroSequence", "");
}
