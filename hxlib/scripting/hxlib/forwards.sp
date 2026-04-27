#pragma newdecls required
#pragma semicolon 1

enum
{
	Forward_OnIncreaseSurvivorIntensity,		Forward_OnIncreaseSurvivorIntensity_Post,
	Forward_OnMapInvokedPanicEvent, 			Forward_OnMapInvokedPanicEvent_Post,
	Forward_OnStartPanicEvent, 					Forward_OnStartPanicEvent_Post,
	Forward_OnGetDirectorOptions,
	Forward_OnBeginLocalScript,					Forward_OnBeginLocalScript_Post,
	Forward_OnEndLocalScript,					Forward_OnEndLocalScript_Post,
	Forward_OnStartFinale,						Forward_OnStartFinale_Post,
	Forward_OnGetRandomPZSpawnPosition,			Forward_OnGetRandomPZSpawnPosition_Override, Forward_OnGetRandomPZSpawnPosition_Post,
	Forward_OnCollectSpawnAreas,				Forward_OnCollectSpawnAreas_Post,
	Forward_OnResetMobTimer,					Forward_OnResetMobTimer_Post,
	Forward_OnStartMobTimer,					Forward_OnStartMobTimer_Override, Forward_OnStartMobTimer_Post,
	Forward_OnResetSpecialTimers,				Forward_OnResetSpecialTimers_Post,
	Forward_OnCanZombieSpawnHere,				Forward_OnCanZombieSpawnHere_Override, Forward_OnCanZombieSpawnHere_Post,
	Forward_OnUpdateTempo,						Forward_OnUpdateTempo_Post,
	Forward_OnSustainPeakPopulationClear,		Forward_OnSustainPeakPopulationClear_Post,
	Forward_OnGoAwayFromKeyboard,				Forward_OnGoAwayFromKeyboard_Post,
	Forward_OnCreateSpitterProjectile,			Forward_OnCreateSpitterProjectile_Post,
	Forward_OnCreateFlame,						Forward_OnCreateFlame_Post,
	Forward_OnSetPunchAngle,					Forward_OnSetPunchAngle_Post,
	Forward_OnGunViewPunch,						Forward_OnGunViewPunch_Post,
												Forward_OnGetSpitLifetime_Override, Forward_OnGetSpitLifetime_Post,
	Forward_OnConnectionlessPacket,				Forward_OnConnectionlessPacket_Post,
												Forward_OnSetReservationCookie_Post,
	Forward_OnShowMOTD,							Forward_OnShowMOTD_Post,
	Forward_OnShowHostBanner,					Forward_OnShowHostBanner_Post,
	Forward_OnGetFreeClient,					Forward_OnGetFreeClient_Post,
	Forward_OnVocalize,							Forward_OnVocalize_Post,
	Forward_OnScenarioCheckForDeadPlayers,		Forward_OnScenarioCheckForDeadPlayers_Post,
	Forward_OnCreateSurvivorDeathModel,			Forward_OnCreateSurvivorDeathModel_Post,

	Forward_MAX
};

GlobalForward InitGlobalForward(int forwardIndex, char name[MAX_FWD_LEN])
{
	switch (forwardIndex)
	{
		case Forward_OnIncreaseSurvivorIntensity:
		{	name = "OnIncreaseSurvivorIntensity"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_CellByRef);
		}
		case Forward_OnIncreaseSurvivorIntensity_Post:
		{	name = "OnIncreaseSurvivorIntensity_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnMapInvokedPanicEvent:
		{	name = "OnMapInvokedPanicEvent"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Cell);
		}
		case Forward_OnMapInvokedPanicEvent_Post:
		{	name = "OnMapInvokedPanicEvent_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnStartPanicEvent:
		{	name = "OnStartPanicEvent"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef, Param_Cell);
		}
		case Forward_OnStartPanicEvent_Post:
		{	name = "OnStartPanicEvent_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnGetDirectorOptions:
		{	name = "OnGetDirectorOptions"; return CreateGlobalForward(name,
				ET_Ignore);
		}

		case Forward_OnBeginLocalScript:
		{	name = "OnBeginLocalScript"; return CreateGlobalForward(name,
				ET_Event, Param_String);
		}
		case Forward_OnBeginLocalScript_Post:
		{	name = "OnBeginLocalScript_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_String, Param_Cell);
		}

		case Forward_OnEndLocalScript:
		{	name = "OnEndLocalScript"; return CreateGlobalForward(name,
				ET_Event);
		}
		case Forward_OnEndLocalScript_Post:
		{	name = "OnEndLocalScript_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell);
		}

		case Forward_OnStartFinale:
		{	name = "OnStartFinale"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Cell);
		}
		case Forward_OnStartFinale_Post:
		{	name = "OnStartFinale_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnGetRandomPZSpawnPosition:
		{	name = "OnGetRandomPZSpawnPosition"; return CreateGlobalForward(name,
				ET_Event, Param_CellByRef, Param_CellByRef, Param_Cell);
		}
		case Forward_OnGetRandomPZSpawnPosition_Override:
		{	name = "OnGetRandomPZSpawnPosition_Override"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_CellByRef);
		}
		case Forward_OnGetRandomPZSpawnPosition_Post:
		{	name = "OnGetRandomPZSpawnPosition_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell, Param_Cell);
		}

		case Forward_OnCollectSpawnAreas:
		{	name = "OnCollectSpawnAreas"; return CreateGlobalForward(name,
				ET_Event, Param_CellByRef, Param_CellByRef);
		}
		case Forward_OnCollectSpawnAreas_Post:
		{	name = "OnCollectSpawnAreas_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnResetMobTimer:
		{	name = "OnResetMobTimer"; return CreateGlobalForward(name,
				ET_Event);
		}
		case Forward_OnResetMobTimer_Post:
		{	name = "OnResetMobTimer_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell);
		}

		case Forward_OnStartMobTimer:
		{	name = "OnStartMobTimer"; return CreateGlobalForward(name,
				ET_Event);
		}
		case Forward_OnStartMobTimer_Override:
		{	name = "OnStartMobTimer_Override"; return CreateGlobalForward(name,
				ET_Event, Param_CellByRef);
		}
		case Forward_OnStartMobTimer_Post:
		{	name = "OnStartMobTimer_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell);
		}

		case Forward_OnResetSpecialTimers:
		{	name = "OnResetSpecialTimers"; return CreateGlobalForward(name,
				ET_Event);
		}
		case Forward_OnResetSpecialTimers_Post:
		{	name = "OnResetSpecialTimers_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell);
		}

		case Forward_OnCanZombieSpawnHere:
		{	name = "OnCanZombieSpawnHere"; return CreateGlobalForward(name,
				ET_Event, Param_Array, Param_Cell, Param_Cell, Param_Cell);
		}
		case Forward_OnCanZombieSpawnHere_Override:
		{	name = "OnCanZombieSpawnHere_Override"; return CreateGlobalForward(name,
				ET_Event, Param_Array, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef);
		}
		case Forward_OnCanZombieSpawnHere_Post:
		{	name = "OnCanZombieSpawnHere_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Array, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnUpdateTempo:
		{	name = "OnUpdateTempo"; return CreateGlobalForward(name,
				ET_Event, Param_Cell);
		}
		case Forward_OnUpdateTempo_Post:
		{	name = "OnUpdateTempo_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnSustainPeakPopulationClear:
		{	name = "OnSustainPeakPopulationClear"; return CreateGlobalForward(name,
				ET_Event);
		}
		case Forward_OnSustainPeakPopulationClear_Post:
		{	name = "OnSustainPeakPopulationClear_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell);
		}

		case Forward_OnGoAwayFromKeyboard:
		{	name = "OnGoAwayFromKeyboard"; return CreateGlobalForward(name,
				ET_Event, Param_Cell);
		}
		case Forward_OnGoAwayFromKeyboard_Post:
		{	name = "OnGoAwayFromKeyboard_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell);
		}

		case Forward_OnCreateSpitterProjectile:
		{	name = "OnCreateSpitterProjectile"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
		}
		case Forward_OnCreateSpitterProjectile_Post:
		{	name = "OnCreateSpitterProjectile_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array, Param_Cell);
		}

		case Forward_OnCreateFlame:
		{	name = "OnCreateFlame"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Array, Param_Array, Param_Cell, Param_CellByRef);
		}
		case Forward_OnCreateFlame_Post:
		{	name = "OnCreateFlame_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnSetPunchAngle:
		{	name = "OnSetPunchAngle"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Array);
		}
		case Forward_OnSetPunchAngle_Post:
		{	name = "OnSetPunchAngle_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Array, Param_Cell);
		}

		case Forward_OnGunViewPunch:
		{	name = "OnGunViewPunch"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Cell);
		}
		case Forward_OnGunViewPunch_Post:
		{	name = "OnGunViewPunch_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnGetSpitLifetime_Override:
		{	name = "OnGetSpitLifetime_Override"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_CellByRef);
		}
		case Forward_OnGetSpitLifetime_Post:
		{	name = "OnGetSpitLifetime_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell);
		}

		case Forward_OnConnectionlessPacket:
		{	name = "OnConnectionlessPacket"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell);
		}
		case Forward_OnConnectionlessPacket_Post:
		{	name = "OnConnectionlessPacket_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell, Param_Cell);
		}

		case Forward_OnSetReservationCookie_Post:
		{	name = "OnSetReservationCookie_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Array);
		}

		case Forward_OnShowMOTD:
		{	name = "OnShowMOTD"; return CreateGlobalForward(name,
				ET_Event, Param_Cell);
		}
		case Forward_OnShowMOTD_Post:
		{	name = "OnShowMOTD_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell);
		}

		case Forward_OnShowHostBanner:
		{	name = "OnShowHostBanner"; return CreateGlobalForward(name,
				ET_Event, Param_Cell);
		}
		case Forward_OnShowHostBanner_Post:
		{	name = "OnShowHostBanner_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell);
		}

		case Forward_OnGetFreeClient:
		{	name = "OnGetFreeClient"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		}
		case Forward_OnGetFreeClient_Post:
		{	name = "OnGetFreeClient_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnVocalize:
		{	name = "OnVocalize"; return CreateGlobalForward(name,
				ET_Event, Param_Cell, Param_String, Param_CellByRef, Param_CellByRef);
		}
		case Forward_OnVocalize_Post:
		{	name = "OnVocalize_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell);
		}

		case Forward_OnScenarioCheckForDeadPlayers:
		{	name = "OnScenarioCheckForDeadPlayers"; return CreateGlobalForward(name,
				ET_Event, Param_CellByRef);
		}
		case Forward_OnScenarioCheckForDeadPlayers_Post:
		{	name = "OnScenarioCheckForDeadPlayers_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell);
		}

		case Forward_OnCreateSurvivorDeathModel:
		{	name = "OnCreateSurvivorDeathModel"; return CreateGlobalForward(name,
				ET_Event, Param_Cell);
		}
		case Forward_OnCreateSurvivorDeathModel_Post:
		{	name = "OnCreateSurvivorDeathModel_Post"; return CreateGlobalForward(name,
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		}
	}

	return null;
}

PrivateForward InitPrivateForward(EntityHook type, HookMode mode)
{
	switch (type)
	{
		case EntityHook_AcceptInput: switch (mode)
		{
			case Hook_Pre: return CreateForward(
				ET_Event, Param_Cell, Param_String, Param_CellByRef, Param_CellByRef, Param_Cell);

			case Hook_Post: return CreateForward(
				ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		}

		case EntityHook_OnNavAreaChanged: switch (mode)
		{
			case Hook_Post: return CreateForward(
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
		}

		case EntityHook_CreateRagdollEntity: switch (mode)
		{
			case Hook_Pre: return CreateForward(
				ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_CellByRef, Param_Cell, Param_Array, Param_Array);

			case Hook_Post: return CreateForward(
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell);
		}

		case EntityHook_EventKilled: switch (mode)
		{
			case Hook_Pre: return CreateForward(
				ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array, Param_Array);

			case Hook_Post: return CreateForward(
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell);
		}

		case EntityHook_SetObserverTarget: switch (mode)
		{
			case Hook_Pre: return CreateForward(
				ET_Event, Param_Cell, Param_CellByRef);

			case Hook_Post: return CreateForward(
				ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
		}
	}

	return null;
}

