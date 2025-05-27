#pragma newdecls required
#pragma semicolon 1

#define	GAMEDATA	"neb_hardx.games"

#include <dhooks>
#include <left4dhooks> // used to get some pointers
#include <neb_stocks>

ConVar			g_cAdjacentFlowThreshold;
float			g_fCVAdjacentFlowThreshold;

bool			g_bOnMapInvokedPanicEventNonVirtualHandled, g_bBeginLocalScriptHandled, g_bEndLocalScriptHandled,
				g_bStartPanicEventHandled, g_bPanicEventResetNonVirtual;
DynamicDetour	g_hDetourOnMapInvokedPanicEventNonVirtual, g_hDetourBeginLocalScript, g_hDetourEndLocalScript,
				g_hDetourStartPanicEvent, g_hDetourResetPanicNonVirtual, g_hDetourOnFinaleStarted, g_hDetourResetChallengeNonVirtual,
				g_hDetourScavengeDisplayTurnOn, g_hDetourScavengeDisplayTurnOff, g_hDetourOnGetRandomPZSpawnPosition,
				g_hDetourOnCollectSpawnAreas, g_hDetourOnResetMobTimer,
				g_hDetourOnResetSpecialTimers;
//DynamicDetour	g_hDetourIntensityIncrease;
GlobalForward	g_hForwardOnMapInvokedPanicEvent_Pre, g_hForwardOnMapInvokedPanicEvent_Post, g_hForwardOnRunScript_Pre,
				g_hForwardOnRunScript_Post, g_hForwardOnEndLocalScript_Pre, g_hForwardOnEndLocalScript_Post, 
				g_hForwardOnStartPanicEvent_Pre, g_hForwardOnStartPanicEvent_Post, g_hForwardOnPanicEventEnded_Post,
				g_hForwardOnFinaleStarted, g_hForwardOnScavengeProgressDisplayTurnOn, g_hForwardOnScavengeProgressDisplayTurnOff,
				g_hForwardOnCollectSpawnAreas_Post, g_hForwardOnGetRandomPZSpawnPosition_Post,
				g_hForwardOnCollectSpawnAreas_Pre, g_hForwardOnGetRandomPZSpawnPosition_Pre,
				g_hForwardOnResetMobTimer, g_hForwardOnResetSpecialTimers;

Handle			g_hSDKResetNonVirtual, g_hSDKEndLocalScript, g_hSDKIntensityReset, g_hSDKGetMapArcValue, g_hSDKCollectSpawnAreas,
				g_hSDKIntensityIncrease, g_hSDKCanZombieSpawnHere, g_hSDKAreAllSurvivorsInBattlefield;

int				g_iOffsetIntensity, g_iOffsetCanZombieSpawnHere_RetryCondition;
OS_Type			g_iOS;

char			g_sCurrentVscript[128];

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	CreateNative("hxGetCurrentVScript", Native_hxGetCurrentVScript);
	CreateNative("hxEndPanicEvent", Native_hxEndPanicEvent);
	CreateNative("hxEndLocalScript", Native_hxEndLocalScript);

	CreateNative("hxSetSurvivorIntensity", Native_hxSetSurvivorIntensity);
	CreateNative("hxGetSurvivorIntensity", Native_hxGetSurvivorIntensity);
	CreateNative("hxIntensifySurvivor", Native_hxIntensifySurvivor);

	CreateNative("hxGetMapArcValue", Native_hxGetMapArcValue);

	CreateNative("hxCollectSpawnAreas", Native_hxCollectSpawnAreas);

	CreateNative("hxGetHighestAdjacentFlow", Native_hxGetHighestAdjacentFlow);

	CreateNative("hxCanZombieSpawnHere", Native_hxCanZombieSpawnHere);

	CreateNative("hxAreAllSurvivorsInBattlefield", Native_hxAreAllSurvivorsInBattlefield);

	CreateNative("hxRecursivelyAddAdjacentAreas", Native_hxRecursivelyAddAdjacentAreas);

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cAdjacentFlowThreshold = CreateConVar("adjacent_flow_threshold", "1425.0", "The maximum difference in flow between two connected nav areas to be considered connected", FCVAR_NOTIFY, true, 0.0);
	g_cAdjacentFlowThreshold.AddChangeHook(ConVarChanged_AdjacentFlowThreshold);
	g_fCVAdjacentFlowThreshold = g_cAdjacentFlowThreshold.FloatValue;

	g_iOS = GetOSType();

	HookEvent("panic_event_finished", event_panic_event_finished);

	// load required files
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetourOnMapInvokedPanicEventNonVirtual = DynamicDetour.FromConf(hGameData, "HX::CDirectorScriptedEventManager::OnMapInvokedPanicEventNonVirtual");
	if(!g_hDetourOnMapInvokedPanicEventNonVirtual) SetFailState("could not create HX::CDirectorScriptedEventManager::OnMapInvokedPanicEventNonVirtual detour");
	g_hDetourOnMapInvokedPanicEventNonVirtual.Enable(Hook_Pre, DTR_OnMapInvokedPanicEventNonVirtual_Pre);
	g_hDetourOnMapInvokedPanicEventNonVirtual.Enable(Hook_Post, DTR_OnMapInvokedPanicEventNonVirtual_Post);

	g_hDetourBeginLocalScript = DynamicDetour.FromConf(hGameData, "HX::CDirector::RunScript");
	if(!g_hDetourBeginLocalScript) SetFailState("could not create HX::CDirector::RunScript detour");
	g_hDetourBeginLocalScript.Enable(Hook_Pre, DTR_RunScript_Pre);
	g_hDetourBeginLocalScript.Enable(Hook_Post, DTR_RunScript_Post);

	g_hDetourEndLocalScript = DynamicDetour.FromConf(hGameData, "HX::CDirector::EndLocalScript");
	if(!g_hDetourEndLocalScript) SetFailState("could not create HX::CDirector::EndLocalScript detour");
	g_hDetourEndLocalScript.Enable(Hook_Pre, DTR_EndLocalScript_Pre);
	g_hDetourEndLocalScript.Enable(Hook_Post, DTR_EndLocalScript_Post);

	g_hDetourStartPanicEvent = DynamicDetour.FromConf(hGameData, "HX::CDirectorScriptedEventManager::StartPanicEvent");
	if(!g_hDetourStartPanicEvent) SetFailState("could not create HX::CDirectorScriptedEventManager::StartPanicEvent detour");
	g_hDetourStartPanicEvent.Enable(Hook_Pre, DTR_StartPanicEvent_Pre);
	g_hDetourStartPanicEvent.Enable(Hook_Post, DTR_StartPanicEvent_Post);

	g_hDetourResetPanicNonVirtual = DynamicDetour.FromConf(hGameData, "HX::CDirectorScriptedEventManager::ResetNonVirtual");
	if(!g_hDetourResetPanicNonVirtual) SetFailState("could not create HX::CDirectorScriptedEventManager::ResetNonVirtual detour");
	g_hDetourResetPanicNonVirtual.Enable(Hook_Post, DTR_ResetPanicNonVirtual_Post);

	g_hDetourResetChallengeNonVirtual = DynamicDetour.FromConf(hGameData, "HX::CDirectorChallengeMode::ResetNonVirtual");
	if(!g_hDetourResetChallengeNonVirtual) SetFailState("could not create HX::CDirectorChallengeMode::ResetNonVirtual detour");
	g_hDetourResetChallengeNonVirtual.Enable(Hook_Pre, DTR_ResetChallengeNonVirtual_Pre);

	g_hDetourOnFinaleStarted = DynamicDetour.FromConf(hGameData, "HX::CDirectorScriptedEventManager::OnFinaleStarted");
	if(!g_hDetourOnFinaleStarted) SetFailState("could not create HX::CDirectorScriptedEventManager::OnFinaleStarted detour");
	g_hDetourOnFinaleStarted.Enable(Hook_Post, DTR_OnFinaleStarted_Post);

	g_hDetourOnGetRandomPZSpawnPosition = DynamicDetour.FromConf(hGameData, "HX::ZombieManager::GetRandomPZSpawnPosition");
	if(!g_hDetourOnGetRandomPZSpawnPosition) SetFailState("could not create HX::ZombieManager::GetRandomPZSpawnPosition detour");
	g_hDetourOnGetRandomPZSpawnPosition.Enable(Hook_Pre, DTR_OnGetRandomPZSpawnPosition_Pre);
	g_hDetourOnGetRandomPZSpawnPosition.Enable(Hook_Post, DTR_OnGetRandomPZSpawnPosition_Post);

	g_hDetourOnCollectSpawnAreas = DynamicDetour.FromConf(hGameData, "HX::ZombieManager::CollectSpawnAreas");	
	if(!g_hDetourOnCollectSpawnAreas) SetFailState("could not create HX::ZombieManager::CollectSpawnAreas detour");
	g_hDetourOnCollectSpawnAreas.Enable(Hook_Pre, DTR_OnCollectSpawnAreas_Pre);
	g_hDetourOnCollectSpawnAreas.Enable(Hook_Post, DTR_OnCollectSpawnAreas_Post);

	g_hDetourOnResetMobTimer = DynamicDetour.FromConf(hGameData, "HX::CDirector::ResetMobTimer");
	if(!g_hDetourOnResetMobTimer) SetFailState("could not create HX::CDirector::ResetMobTimer detour");
	g_hDetourOnResetMobTimer.Enable(Hook_Post, DTR_OnResetMobTimer_Post);

	g_hDetourOnResetSpecialTimers = DynamicDetour.FromConf(hGameData, "HX::CDirector::ResetSpecialTimers");
	if(!g_hDetourOnResetSpecialTimers) SetFailState("could not create HX::CDirector::ResetSpecialTimers detour");
	g_hDetourOnResetSpecialTimers.Enable(Hook_Post, DTR_OnResetSpecialTimers_Post);
	
	switch(g_iOS)
	{
		case OS_linux:
		{
			// unique signatures of these functions are only possible in linux
			g_hDetourScavengeDisplayTurnOn = DynamicDetour.FromConf(hGameData, "HX::CScavengeProgressDisplay::InputTurnOn");
			if(!g_hDetourScavengeDisplayTurnOn) SetFailState("could not create HX::CScavengeProgressDisplay::InputTurnOn detour");
			g_hDetourScavengeDisplayTurnOn.Enable(Hook_Post, DTR_OnScavengeProgressDisplayTurnOn_Post);

			g_hDetourScavengeDisplayTurnOff = DynamicDetour.FromConf(hGameData, "HX::CScavengeProgressDisplay::InputTurnOff");
			if(!g_hDetourScavengeDisplayTurnOff) SetFailState("could not create HX::CScavengeProgressDisplay::InputTurnOff detour");
			g_hDetourScavengeDisplayTurnOff.Enable(Hook_Post, DTR_OnScavengeProgressDisplayTurnOff_Post);
		}
		case OS_windows:
		{
			// for windows, we do an offset from the nearest function that does have a unique signature (within same class too, so this is unlikely to break i think)
			Address aStart = GameConfGetAddress(hGameData, "ScavengeProgressDisplay_OffsetStart");

			g_hDetourScavengeDisplayTurnOn = new DynamicDetour(aStart + view_as<Address>(hGameData.GetOffset("ScavengeProgressDisplay_TurnOn")), CallConv_THISCALL, ReturnType_Void);
			g_hDetourScavengeDisplayTurnOn.AddParam(HookParamType_Int);
			if(!g_hDetourScavengeDisplayTurnOn) SetFailState("could not create HX::CScavengeProgressDisplay::InputTurnOn detour");
			g_hDetourScavengeDisplayTurnOn.Enable(Hook_Post, DTR_OnScavengeProgressDisplayTurnOn_Post);

			g_hDetourScavengeDisplayTurnOff = new DynamicDetour(aStart + view_as<Address>(hGameData.GetOffset("ScavengeProgressDisplay_TurnOff")), CallConv_THISCALL, ReturnType_Void);
			g_hDetourScavengeDisplayTurnOff.AddParam(HookParamType_Int);
			if(!g_hDetourScavengeDisplayTurnOff) SetFailState("could not create HX::CScavengeProgressDisplay::InputTurnOff detour");
			g_hDetourScavengeDisplayTurnOff.Enable(Hook_Post, DTR_OnScavengeProgressDisplayTurnOff_Post);
		}
	}

	g_hForwardOnMapInvokedPanicEvent_Pre = CreateGlobalForward("hxOnMapInvokedPanicEvent", ET_Hook, Param_Cell, Param_Cell);
	g_hForwardOnMapInvokedPanicEvent_Post = CreateGlobalForward("hxOnMapInvokedPanicEvent_Post", ET_Ignore, Param_Cell, Param_Cell);

	g_hForwardOnRunScript_Pre = CreateGlobalForward("hxOnRunScript", ET_Hook, Param_String, Param_Cell, Param_Cell);
	g_hForwardOnRunScript_Post = CreateGlobalForward("hxOnRunScript_Post", ET_Ignore, Param_String, Param_Cell, Param_Cell);

	g_hForwardOnEndLocalScript_Pre = CreateGlobalForward("hxOnEndLocalScript", ET_Hook);
	g_hForwardOnEndLocalScript_Post = CreateGlobalForward("hxOnEndLocalScript_Post", ET_Ignore);

	g_hForwardOnStartPanicEvent_Pre = CreateGlobalForward("hxOnStartPanicEvent", ET_Hook, Param_CellByRef);
	g_hForwardOnStartPanicEvent_Post = CreateGlobalForward("hxOnStartPanicEvent_Post", ET_Ignore, Param_Cell);

	g_hForwardOnPanicEventEnded_Post = CreateGlobalForward("hxOnPanicEventEnded", ET_Ignore, Param_Cell);

	g_hForwardOnFinaleStarted = CreateGlobalForward("hxOnFinaleStarted", ET_Ignore, Param_Cell);

	g_hForwardOnScavengeProgressDisplayTurnOn = CreateGlobalForward("hxOnScavengeProgressDisplayTurnOn", ET_Ignore);
	g_hForwardOnScavengeProgressDisplayTurnOff = CreateGlobalForward("hxOnScavengeProgressDisplayTurnOff", ET_Ignore);

	g_hForwardOnCollectSpawnAreas_Pre = CreateGlobalForward("hxOnCollectSpawnAreas_Pre", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardOnCollectSpawnAreas_Post = CreateGlobalForward("hxOnCollectSpawnAreas_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	g_hForwardOnGetRandomPZSpawnPosition_Pre = CreateGlobalForward("hxOnGetRandomPZSpawnPosition_Pre", ET_Ignore);
	g_hForwardOnGetRandomPZSpawnPosition_Post = CreateGlobalForward("hxOnGetRandomPZSpawnPosition_Post", ET_Ignore);

	g_hForwardOnResetMobTimer = CreateGlobalForward("hxOnResetMobTimer", ET_Ignore);
	g_hForwardOnResetSpecialTimers = CreateGlobalForward("hxOnResetSpecialTimers", ET_Ignore);


	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::ResetNonVirtual"))
		SetFailState("could not load CDirectorScriptedEventManager::ResetNonVirtual signature!!");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKResetNonVirtual = EndPrepSDKCall();
	if(g_hSDKResetNonVirtual == null)
		SetFailState("could not create CDirectorScriptedEventManager::ResetNonVirtual SDKCall handle!");

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::EndLocalScript"))
		SetFailState("could not load CDirector::EndLocalScript signature!!");
	g_hSDKEndLocalScript = EndPrepSDKCall();
	if(g_hSDKEndLocalScript == null)
		SetFailState("could not create CDirector::EndLocalScript SDKCall handle!");

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetMapArcValue"))
		SetFailState("could not load CDirector::GetMapArcValue signature!!");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMapArcValue = EndPrepSDKCall();
	if(g_hSDKGetMapArcValue == null)
		SetFailState("could not create CDirector::GetMapArcValue SDKCall handle!");

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Intensity::Reset"))
		SetFailState("could not load Intensity::Reset signature!!");
	g_hSDKIntensityReset = EndPrepSDKCall();
	if(g_hSDKIntensityReset == null)
		SetFailState("could not create Intensity::Reset SDKCall handle!");

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::CollectSpawnAreas"))
		SetFailState("could not load ZombieManager::CollectSpawnAreas signature!!");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKCollectSpawnAreas = EndPrepSDKCall();
	if(g_hSDKCollectSpawnAreas == null)
		SetFailState("could not create ZombieManager::CollectSpawnAreas SDKCall handle!");

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Intensity::Increase"))
		SetFailState("could not load Intensity::Increase signature!!");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKIntensityIncrease = EndPrepSDKCall();
	if(g_hSDKIntensityIncrease == null)
		SetFailState("could not create Intensity::Increase SDKCall handle!");

	switch(g_iOS)
	{
		case OS_windows: StartPrepSDKCall(SDKCall_Static);
		case OS_linux: StartPrepSDKCall(SDKCall_Raw);
	}
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::CanZombieSpawnHere"))
		SetFailState("could not load ZombieManager::CanZombieSpawnHere signature!!");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKCanZombieSpawnHere = EndPrepSDKCall();
	if(g_hSDKCanZombieSpawnHere == null)
		SetFailState("could not create ZombieManager::CanZombieSpawnHere SDKCall handle!");

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::AreAllSurvivorsInBattlefield"))
		SetFailState("could not load CDirectorScriptedEventManager::AreAllSurvivorsInBattlefield signature!!");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKAreAllSurvivorsInBattlefield = EndPrepSDKCall();
	if(g_hSDKAreAllSurvivorsInBattlefield == null)
		SetFailState("could not create CDirectorScriptedEventManager::AreAllSurvivorsInBattlefield SDKCall handle!");


	g_iOffsetIntensity = hGameData.GetOffset("Intensity");
	g_iOffsetCanZombieSpawnHere_RetryCondition = hGameData.GetOffset("CanZombieSpawnHere_RetryCondition");
	PrintToServer("CanZombieSpawnHere Retry Condition Offset: %i", g_iOffsetCanZombieSpawnHere_RetryCondition);

	delete hGameData;

	RegPluginLibrary("hardx_hooks");
}

void ConVarChanged_AdjacentFlowThreshold(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_fCVAdjacentFlowThreshold = g_cAdjacentFlowThreshold.FloatValue;
}

/**********
 * Natives
 *********/

public any Native_hxSetSurvivorIntensity(Handle hPlugin, int iNumParams)
{
	float fValue = GetNativeCell(2);
	if(fValue < 0.0 || fValue > 1.0) return false;
	int iClient = GetNativeCell(1);

	if(fValue == 0.0)
	{
		SDKCall(g_hSDKIntensityReset, GetEntityAddress(iClient) + view_as<Address>(g_iOffsetIntensity));
		SetEntProp(iClient, Prop_Send, "m_clientIntensity", 0); // the netprop isn't refreshed every frame. Manually setting it to reflect the reset immediately to other plugins potentially reading this
		return true;
	}

	Address aIntensity = GetEntityAddress(iClient) + view_as<Address>(g_iOffsetIntensity);
	StoreToAddress(aIntensity, fValue, NumberType_Int32);
	StoreToAddress(aIntensity + view_as<Address>(4), fValue, NumberType_Int32);
	SetEntProp(iClient, Prop_Send, "m_clientIntensity", RoundToFloor(fValue*100.0));
	
	return true;
}

public any Native_hxGetSurvivorIntensity(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	return view_as<float>(LoadFromAddress(GetEntityAddress(iClient)+view_as<Address>(g_iOffsetIntensity), NumberType_Int32));
}

public any Native_hxIntensifySurvivor(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iStrength = GetNativeCell(2);
	SDKCall(g_hSDKIntensityIncrease, GetEntityAddress(iClient)+view_as<Address>(g_iOffsetIntensity), iStrength);
	return 0;
}

public any Native_hxGetCurrentVScript(Handle hPlugin, int iNumParams)
{
	int iMaxLen = GetNativeCell(2);
	char[] sBuffer = new char[iMaxLen];
	if(g_sCurrentVscript[0]) strcopy(sBuffer, iMaxLen, g_sCurrentVscript);

	if(sBuffer[0])
	{
		SetNativeString(1, sBuffer, iMaxLen);
		return true;
	}
	return false;
}

// cancel non-vscript events
public any Native_hxEndPanicEvent(Handle hPlugin, int iNumParams)
{
	g_bPanicEventResetNonVirtual = true;
	SDKCall(g_hSDKResetNonVirtual, L4D_GetPointer(POINTER_EVENTMANAGER));
	return 0; // void
}

// cancel vscript-based events
public any Native_hxEndLocalScript(Handle hPlugin, int iNumParams)
{
	SDKCall(g_hSDKEndLocalScript, L4D_GetPointer(POINTER_DIRECTOR));
	return 0; // void
}

public any Native_hxGetMapArcValue(Handle hPlugin, int iNumParams)
{
	return view_as<int>(SDKCall(g_hSDKGetMapArcValue, L4D_GetPointer(POINTER_DIRECTOR)));
}

public any Native_hxCollectSpawnAreas(Handle hPlugin, int iNumParams)
{
	int iDirection = GetNativeCell(1);
	int iZClass = GetNativeCell(2);

	return view_as<Address>(SDKCall(g_hSDKCollectSpawnAreas, L4D_GetPointer(POINTER_ZOMBIEMANAGER), iDirection, iZClass));
}

public any Native_hxAreAllSurvivorsInBattlefield(Handle hPlugin, int iNumParams)
{
	return SDKCall(g_hSDKAreAllSurvivorsInBattlefield, L4D_GetPointer(POINTER_EVENTMANAGER));
}

public any Native_hxGetHighestAdjacentFlow(Handle hPlugin, int iNumParams)
{
	Address aLoadedNav, aAdjacentList;
	Address aRefNav = GetNativeCell(1);
	Address aHighestNav = aRefNav;
	float fHighestFlow = L4D2Direct_GetTerrorNavAreaFlow(aRefNav);
	float fLoadedFlow;
	int iTotalAdjacent;

	for(int dir = 0; dir < 4; dir++)
	{
		aAdjacentList = LoadFromAddress(aRefNav + view_as<Address>(dir*4 + 88), NumberType_Int32);
		iTotalAdjacent = LoadFromAddress(aAdjacentList, NumberType_Int32);

		if(iTotalAdjacent > 0)
		{
			for(int i = 0; i < iTotalAdjacent; i++)
			{
				aLoadedNav = LoadFromAddress(aAdjacentList + view_as<Address>((2*i + 1)*4), NumberType_Int32);
				fLoadedFlow = L4D2Direct_GetTerrorNavAreaFlow(aLoadedNav);

				if(fLoadedFlow > fHighestFlow && fHighestFlow + g_fCVAdjacentFlowThreshold > fLoadedFlow)
				{
					aHighestNav = aLoadedNav;
					fHighestFlow = fLoadedFlow;
				}
			}
		}
	}

	return aHighestNav;
}

int	g_iRecursivelyAddAdjacentAreas_WriteCount;
int g_iRecursivelyAddAdjacentAreas_Stack;
public any Native_hxRecursivelyAddAdjacentAreas(Handle hPlugin, int iNumParams)
{
	ArrayList aList = GetNativeCell(1);
	float fRadius = GetNativeCell(2);
	Address	aLoadedNav;
	int iMax = aList.Length;
	float vStart[3];
	g_iRecursivelyAddAdjacentAreas_WriteCount = 0;
	g_iRecursivelyAddAdjacentAreas_Stack = 0;

	for(int i = 0; i < iMax; i++)
	{
		aLoadedNav = aList.Get(i);
		L4D_GetNavAreaCenter(aLoadedNav, vStart);

		g_iRecursivelyAddAdjacentAreas_Stack++;
		recursivelyAddAdjacentAreas(aLoadedNav, aLoadedNav, aList, vStart, fRadius);
		g_iRecursivelyAddAdjacentAreas_Stack--;
	}

	return g_iRecursivelyAddAdjacentAreas_WriteCount;
}

void recursivelyAddAdjacentAreas(Address aStart, Address aLast, ArrayList aList, float vStart[3], float fRadius)
{
	if(g_iRecursivelyAddAdjacentAreas_Stack > 255)
	{
		//PrintToServer("[DEBUG] [recursivelyAddAdjacentAreas] Stack overflow!");
		return; // prevent stack overflow
	}

	Address aAdjacentList;
	Address aLoaded;
	int iTotal;
	float vLoaded[3];
	float fLastFlow, fLoadedFlow;
	fLastFlow = L4D2Direct_GetTerrorNavAreaFlow(aLast);

	for(int dir = 0; dir < 4; dir++)
	{
		aAdjacentList = LoadFromAddress(aLast + view_as<Address>(dir*4 + 88), NumberType_Int32);
		iTotal = LoadFromAddress(aAdjacentList, NumberType_Int32);

		if(iTotal > 0)
		{
			for(int i = 0; i < iTotal; i++)
			{
				aLoaded = LoadFromAddress(aAdjacentList + view_as<Address>((2*i + 1)*4), NumberType_Int32);

				fLoadedFlow = L4D2Direct_GetTerrorNavAreaFlow(aLoaded);
				if(FloatAbs(fLoadedFlow - fLastFlow) > g_fCVAdjacentFlowThreshold) continue; // likely not a "walkable" connection

				L4D_GetNavAreaCenter(aLoaded, vLoaded);
				if(aList.FindValue(aLoaded) == -1 && GetVectorDistance(vStart, vLoaded) < fRadius)
				{
					aList.Push(aLoaded);
					g_iRecursivelyAddAdjacentAreas_WriteCount++;
					g_iRecursivelyAddAdjacentAreas_Stack++;
					recursivelyAddAdjacentAreas(aStart, aLoaded, aList, vStart, fRadius);
					g_iRecursivelyAddAdjacentAreas_Stack--;
				}
			}
		}
	}
}

public any Native_hxCanZombieSpawnHere(Handle hPlugin, int iNumParams)
{
	float vPos[3];
	GetNativeArray(1, vPos, sizeof(vPos));
	Address aNavArea = GetNativeCell(2);
	int iClass = GetNativeCell(3);
	int iRefClient = GetNativeCell(4);
	bool bTryTwice = GetNativeCell(5);

	bool bSuccess, bElevate;
	for(int i = 0; i < 2; i++)
	{
		switch(g_iOS)
		{
			case OS_linux: bSuccess = view_as<bool>(SDKCall(g_hSDKCanZombieSpawnHere, L4D_GetPointer(POINTER_ZOMBIEMANAGER), vPos, aNavArea, iClass, 1, iRefClient));
			case OS_windows: bSuccess = view_as<bool>(SDKCall(g_hSDKCanZombieSpawnHere, vPos, aNavArea, iClass, 1, iRefClient));
		}
		if(!bTryTwice || bSuccess || i) break;

		// no idea wtf this condition does, but it's in the original code
		if((LoadFromAddress((aNavArea + view_as<Address>(g_iOffsetCanZombieSpawnHere_RetryCondition)), NumberType_Int32) & 1 << 5) == 0) 
		{
			vPos[2] += 18.0; // same value the game uses
			bElevate = true;
		}
		else break;
	}

	if(bSuccess && bElevate) SetNativeArray(1, vPos, sizeof(vPos));

	return bSuccess;
}

/***********
 * Forwards
 **********/

MRESReturn DTR_OnMapInvokedPanicEventNonVirtual_Pre(DHookReturn hReturn, DHookParam hParams)
{
	g_bOnMapInvokedPanicEventNonVirtualHandled = false;
	
	int iClient;
	if(!hParams.IsNull(1))
	{
		iClient = hParams.Get(1);
		if(!nsIsClientValid(iClient)) iClient = 0;
	}

	Call_StartForward(g_hForwardOnMapInvokedPanicEvent_Pre);
	Call_PushCell(iClient);
	Call_PushCell(hParams.Get(2));
	Action aResult = Plugin_Continue;
	Call_Finish(aResult);

	if(aResult == Plugin_Handled)
	{
		g_bOnMapInvokedPanicEventNonVirtualHandled = true;
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_OnMapInvokedPanicEventNonVirtual_Post(DHookReturn hReturn, DHookParam hParams)
{
	if(g_bOnMapInvokedPanicEventNonVirtualHandled) return MRES_Ignored;	
	
	int iClient;
	if(!hParams.IsNull(1))
	{
		iClient = hParams.Get(1);
		if(!nsIsClientValid(iClient)) iClient = 0;
	}

	Call_StartForward(g_hForwardOnMapInvokedPanicEvent_Post);
	Call_PushCell(iClient);
	Call_PushCell(hParams.Get(2));
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_RunScript_Pre(DHookReturn hReturn, DHookParam hParams)
{
	g_bBeginLocalScriptHandled = false;

	char sScript[128];
	hParams.GetString(1, sScript, sizeof(sScript));

	Call_StartForward(g_hForwardOnRunScript_Pre);
	Call_PushString(sScript);
	Call_PushCell(hParams.Get(2));
	Call_PushCell(hParams.Get(3));
	Action aResult = Plugin_Continue;
	Call_Finish(aResult);

	if(aResult == Plugin_Handled)
	{
		g_bBeginLocalScriptHandled = true;
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_RunScript_Post(DHookReturn hReturn, DHookParam hParams)
{
	if(g_bBeginLocalScriptHandled) return MRES_Ignored;

	char sScript[128];
	hParams.GetString(1, sScript, sizeof(sScript));
	int iScope = hParams.Get(2);

	if(iScope == 2) strcopy(g_sCurrentVscript, sizeof(g_sCurrentVscript), sScript);

	Call_StartForward(g_hForwardOnRunScript_Post);
	Call_PushString(sScript);
	Call_PushCell(iScope);
	Call_PushCell(hParams.Get(3));
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_EndLocalScript_Pre(DHookReturn hReturn, DHookParam hParams)
{
	g_bEndLocalScriptHandled = false;
	Call_StartForward(g_hForwardOnEndLocalScript_Pre);
	Action aResult = Plugin_Continue;
	Call_Finish(aResult);

	if(aResult == Plugin_Handled)
	{
		g_bEndLocalScriptHandled = true;
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_EndLocalScript_Post(DHookReturn hReturn, DHookParam hParams)
{
	if(g_bEndLocalScriptHandled) return MRES_Ignored;

	g_sCurrentVscript[0] = 0;

	Call_StartForward(g_hForwardOnEndLocalScript_Post);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_StartPanicEvent_Pre(DHookReturn hReturn, DHookParam hParams)
{
	g_bStartPanicEventHandled = false;
	int iWaves = hParams.Get(1);
	int iWavesOld = iWaves;
	Call_StartForward(g_hForwardOnStartPanicEvent_Pre);
	Call_PushCellRef(iWaves);
	Action aResult = Plugin_Continue;
	Call_Finish(aResult);

	if(aResult == Plugin_Handled)
	{
		g_bStartPanicEventHandled = true;
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	if(iWaves != iWavesOld)
	{
		hParams.Set(1, iWaves);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_StartPanicEvent_Post(DHookReturn hReturn, DHookParam hParams)
{
	if(g_bStartPanicEventHandled) return MRES_Ignored;

	Call_StartForward(g_hForwardOnStartPanicEvent_Post);
	Call_PushCell(hParams.Get(1));
	Call_Finish();

	return MRES_Ignored;
}

// normally this runs at the end of CDirectorScriptedEventManager::ResetNonVirtual. In the context where it's naturally called,
// it's fine. However if manually called to cancel an ongoing event mid game, this being called at the end is bad since it takes
// the game out of ScriptedMode
MRESReturn DTR_ResetChallengeNonVirtual_Pre(DHookReturn hReturn, DHookParam hParams)
{
	if(!g_bPanicEventResetNonVirtual) return MRES_Ignored;

	hReturn.Value = 0;
	return MRES_Supercede;
}

MRESReturn DTR_ResetPanicNonVirtual_Post(DHookReturn hReturn, DHookParam hParams)
{
	g_bPanicEventResetNonVirtual = false;

	Call_StartForward(g_hForwardOnPanicEventEnded_Post);
	Call_PushCell(true);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnFinaleStarted_Post(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnFinaleStarted);
	Call_PushCell(hParams.Get(1));
	Call_Finish();

	return MRES_Ignored;
}

// detect start and end of scavenge events without requiring it to register as a proper finale
MRESReturn DTR_OnScavengeProgressDisplayTurnOn_Post(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnScavengeProgressDisplayTurnOn);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnScavengeProgressDisplayTurnOff_Post(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnScavengeProgressDisplayTurnOff);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnCollectSpawnAreas_Pre(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnCollectSpawnAreas_Pre);

	Call_PushCell(hParams.Get(1));
	Call_PushCell(hParams.Get(2));
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnCollectSpawnAreas_Post(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnCollectSpawnAreas_Post);

	Call_PushCell(hParams.Get(1));
	Call_PushCell(hParams.Get(2));
	Call_PushCell(hReturn.Value);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnGetRandomPZSpawnPosition_Pre(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnGetRandomPZSpawnPosition_Pre);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnGetRandomPZSpawnPosition_Post(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnGetRandomPZSpawnPosition_Post);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnResetMobTimer_Post(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnResetMobTimer);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_OnResetSpecialTimers_Post(DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnResetSpecialTimers);
	Call_Finish();

	return MRES_Ignored;
}

/*************
 * Event hooks
 ************/

void event_panic_event_finished(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	Call_StartForward(g_hForwardOnPanicEventEnded_Post);
	Call_PushCell(false);
	Call_Finish();
}