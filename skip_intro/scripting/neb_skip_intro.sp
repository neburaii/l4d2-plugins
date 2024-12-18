#include <sourcemod>
#include <dhooks>
#include <left4dhooks>

#define GAMEDATA "neb_skip_intro.games"
#define DATA "data/neb_skip_intro.cfg"

Handle g_hdAcceptInput, g_htTimer;
bool g_bBlock, g_bMapEnabled;
float g_fTimerDuration;

public void OnPluginStart()
{
	// gamedata & dhook handles init //
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int offset = GameConfGetOffset(hGameData, "AcceptInput");
	if(offset == 0) SetFailState("Failed to load \"AcceptInput\", invalid offset.");

	delete hGameData;
	g_hdAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
	DHookAddParam(g_hdAcceptInput, HookParamType_CharPtr);
	DHookAddParam(g_hdAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hdAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(g_hdAcceptInput, HookParamType_Object, 20, DHookPass_ByVal|DHookPass_ODTOR|DHookPass_OCTOR|DHookPass_OASSIGNOP); //varaint_t is a union of 12 (float[3]) plus two int type params 12 + 8 = 20
	DHookAddParam(g_hdAcceptInput, HookParamType_Int);

	HookEvent("round_start_pre_entity", event_round_start_pre_entity);
}

public void OnMapStart()
{
	g_htTimer = null;
	if(L4D_IsFirstMapInScenario()) g_bMapEnabled = true;
	else g_bMapEnabled = false;
	g_fTimerDuration = 60.0;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), DATA);
	if(!FileExists(sPath)) return;

	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));
	KeyValues hFile = new KeyValues("neb_skip_intro");
	if(hFile.ImportFromFile(sPath))
	{
		if(hFile.JumpToKey(sMap))
		{
			int iValue = hFile.GetNum("skip", 2);
			if(iValue < 2) g_bMapEnabled = !!iValue;
			float fValue = hFile.GetFloat("timer", -1.0);
			if(fValue >= 0.0) g_fTimerDuration = fValue;
			if(g_fTimerDuration < 0.1) g_fTimerDuration = 0.1;
		}
	}
	delete hFile;
}

void event_round_start_pre_entity(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	g_bBlock = false;
	if(g_htTimer != null) delete g_htTimer;
}

Action block(Handle hTimer)
{
	g_htTimer = null;
	g_bBlock = true;
	return Plugin_Stop;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// these entities get created even before round_start_pre_entity, so to keep things simple we'll hook them always and check against g_bMapEnabled in the detour callback
	if(	strcmp(classname, "info_director") == 0 || strcmp(classname, "point_viewcontrol_survivor") == 0 ||
		strcmp(classname, "point_viewcontrol_multiplayer") == 0 || strcmp(classname, "env_fade") == 0)
	{
		DHookEntity(g_hdAcceptInput, false, entity);
	}
}

MRESReturn AcceptInput(int pThis, Handle hReturn, Handle hParams)
{
	if(g_bBlock || !g_bMapEnabled) return MRES_Ignored;

	char sBuffer[128];
	DHookGetParamString(hParams, 1, sBuffer, sizeof(sBuffer));
	if(	strcmp(sBuffer, "ForceSurvivorPositions") == 0 || strcmp(sBuffer, "StartIntro") == 0 ||
		strcmp(sBuffer, "Enable") == 0 || strcmp(sBuffer, "StartMovement") == 0 ||
		strcmp(sBuffer, "Fade") == 0)
	{
		DHookSetParamString(hParams, 1, "");
		if(g_htTimer == null && g_fTimerDuration >= 0.1) g_htTimer = CreateTimer(g_fTimerDuration, block, _, TIMER_FLAG_NO_MAPCHANGE);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}