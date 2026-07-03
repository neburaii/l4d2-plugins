#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>		// OnEntityCreated
#include <sdktools>		// FindEntityByClassname
#include <hxlib>		// AcceptInput hooks
#include <left4dhooks>

#define WHITELIST_FILE	"data/skip_intro_whitelist.txt"
#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Skip Intro Cutscenes",
	author = "Neburai",
	description = "reliably skips intro cutscenes for all maps not in a whitelist",
	version = "1.6",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/skip_intro"
};

bool	g_bMapAllowIntro;
bool	g_bInIntro;
bool	g_bIntroSequenceStripped;
bool	g_bRoundStarted;
bool	g_bIntroOccurred;
bool	g_bAllowMovement;

bool	g_bLateLoaded;
bool	g_bPluginStarted;

Handle	g_hTimer_DelayEndIntro;
Handle	g_hTimer_SetAllowMovement;

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
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);

	if (g_bLateLoaded)
	{
		ReadBlacklist();

		if (LibraryExists(HXLIB_LIBRARY))
			StartPlugin();
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
	if (!g_bPluginStarted && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

public void OnLibraryAdded(const char[] sName)
{
	if (strcmp(sName, HXLIB_LIBRARY) == 0)
		StartPlugin();
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, HXLIB_LIBRARY) == 0)
		g_bPluginStarted = false;
}

/**********
 * hooking
 **********/

void StartPlugin()
{
	g_bPluginStarted = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		HookClient(i);
	}

	char sClass[32];
	for (int i = MaxClients + 1; i < MAXENTITIES; i++)
	{
		if (!IsValidEntity(i))
			continue;

		GetEntityClassname(i, sClass, sizeof(sClass));
		HookEntity(i, sClass);
	}
}

public void OnPluginEnd()
{
	if (!g_bPluginStarted)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		UnhookClient(i);
	}

	char sClass[32];
	for (int i = MaxClients + 1; i < MAXENTITIES; i++)
	{
		if (!IsValidEntity(i))
			continue;

		GetEntityClassname(i, sClass, sizeof(sClass));
		UnhookEntity(i, sClass);
	}
}

public void OnClientPutInServer(int iClient)
{
	if (g_bPluginStarted)
		HookClient(iClient);
}

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (g_bPluginStarted)
		HookEntity(iEntity, sClass);
}

void HookClient(int iClient)
{
	AddEntityHook(iClient, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_Player);
}

void UnhookClient(int iClient)
{
	RemoveEntityHook(iClient, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_Player);
}

void HookEntity(int iEntity, const char[] sClass)
{
	switch (sClass[0])
	{
		case 'i':
		{
			if (strcmp(sClass, "info_director") == 0)
				AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_InfoDirector);
		}

		case 'p':
		{
			if (StrContains(sClass, "point_viewcontrol_") == 0)
				AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_PointViewcontrol);
		}

		case 'e':
		{
			if (strcmp(sClass, "env_fade") == 0)
				AddEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_EnvFade);
		}
	}
}

void UnhookEntity(int iEntity, const char[] sClass)
{
	switch (sClass[0])
	{
		case 'i':
		{
			if (strcmp(sClass, "info_director") == 0)
				RemoveEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_InfoDirector);
		}

		case 'p':
		{
			if (StrContains(sClass, "point_viewcontrol_") == 0)
				RemoveEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_PointViewcontrol);
		}

		case 'e':
		{
			if (strcmp(sClass, "env_fade") == 0)
				RemoveEntityHook(iEntity, EntityHook_AcceptInput, EHook_Pre, OnAcceptInput_EnvFade);
		}
	}
}

/****************
 * manage states
 ****************/

public void OnMapStart()
{
	ReadBlacklist();
}

public void ReadBlacklist()
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
	g_bRoundStarted = false;
	g_bInIntro = true;
	g_bIntroOccurred = false;
	g_bAllowMovement = false;

	if (g_hTimer_DelayEndIntro) delete g_hTimer_DelayEndIntro;
	if (g_hTimer_SetAllowMovement) delete g_hTimer_SetAllowMovement;
}

void Event_PlayerTeam(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (g_bRoundStarted)
		return;

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClient(iClient) || IsFakeClient(iClient))
		return;

	int iTeam = hEvent.GetInt("team");
	if (iTeam != Team_Survivor)
		return;

	StartRound();
}

void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (g_bRoundStarted)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)
			|| IsFakeClient(i)
			|| GetClientTeam(i) != Team_Survivor)
			continue;

		StartRound();
		return;
	}
}

void StartRound()
{
	g_bRoundStarted = true;
	SetEndIntroDelay(g_fDelayFailsafe);
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int iClient)
{
	if (g_bInIntro && !g_bIntroOccurred)
	{
		if (g_hTimer_DelayEndIntro) delete g_hTimer_DelayEndIntro;
		g_bInIntro = false;
	}
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

/**************
 * AcceptInput
 **************/

public Action OnAcceptInput_Player(int iReceiver, char[] sInput, int &iActivator, int &iSource, Variant params)
{
	if (CanSkipIntro())
	{
		if (strcmp(sInput, "TeleportToSurvivorPosition") == 0)
		{
			if (g_bAllowMovement)
				return Plugin_Handled;

			StripIntroSequence();
			RequestFrame(ReleaseFromSurvivorPosition, EntIndexToEntRef(iReceiver));
		}
	}

	return Plugin_Continue;
}

public Action OnAcceptInput_InfoDirector(int iReceiver, char[] sInput, int &iActivator, int &iSource, Variant params)
{
    if (CanSkipIntro())
    {
        if (strcmp(sInput, "ForceSurvivorPositions") == 0)
		{
			if (g_bAllowMovement)
				return Plugin_Handled;

			StripIntroSequence();
			RequestFrame(ReleaseSurvivorPositions, EntIndexToEntRef(iReceiver));
		}

		else if (strcmp(sInput, "StartIntro") == 0)
		{
			if (g_hTimer_DelayEndIntro) delete g_hTimer_DelayEndIntro;
			g_bIntroOccurred = true;

			if (g_hTimer_SetAllowMovement) delete g_hTimer_SetAllowMovement;
			g_hTimer_SetAllowMovement = CreateTimer(0.1, Timer_SetAllowMovement);
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

bool CanSkipIntro()
{
	return (g_bInIntro || !L4D_HasAnySurvivorLeftSafeArea()) && !g_bMapAllowIntro;
}

void Timer_SetAllowMovement(Handle hTimer)
{
	g_hTimer_SetAllowMovement = null;
	g_bAllowMovement = true;
}

void ReleaseSurvivorPositions(int iEntRef)
{
	int iDirector = EntRefToEntIndex(iEntRef);
	if (iDirector == INVALID_ENT_REFERENCE)
		return;

	AcceptEntityInput(iDirector, "ReleaseSurvivorPositions");
}

void ReleaseFromSurvivorPosition(int iEntRef)
{
	int iPlayer = EntRefToEntIndex(iEntRef);
	if (iPlayer == INVALID_ENT_REFERENCE)
		return;

	AcceptEntityInput(iPlayer, "ReleaseFromSurvivorPosition");
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
