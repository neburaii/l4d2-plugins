#pragma newdecls required
#pragma semicolon 1

Handle g_hSDK_IntensityReset;
Handle g_hSDK_IntensityIncrease;
Handle g_hSDK_PlayerGetLastKnownArea;
Handle g_hSDK_GetScriptValueInt;
Handle g_hSDK_GetMapArcValue;
Handle g_hSDK_GameStatsPanicEventOver;
Handle g_hSDK_OnPanicEventFinished;
Handle g_hSDK_NavAreaSetPush;
Handle g_hSDK_CollectSpawnAreas;
Handle g_hSDK_ResetMobTimer;
Handle g_hSDK_ResetSpecialTimers;
Handle g_hSDK_OnMobRushStart;
Handle g_hSDK_GetScriptValueFloat;
Handle g_hSDK_BeginLocalScript;
Handle g_hSDK_EndLocalScript;
Handle g_hSDK_GetRandomPZSpawnPosition;
Handle g_hSDK_GetZDeltaAtEdgeToArea;
Handle g_hSDK_IsConnected;
Handle g_hSDK_GetNavArea_Entity;
Handle g_hSDK_GetNearestNavArea_Pos;
Handle g_hSDK_GetNavArea_Pos;
Handle g_hSDK_GetNavAreaZ;
Handle g_hSDK_IsInFieldOfView;
Handle g_hSDK_IsHiddenByFog;
Handle g_hSDK_IsVisibleToPlayer;
Handle g_hSDK_IsInTransition;
Handle g_hSDK_NavArea_IsBlocked;
Handle g_hSDK_IsBehindZombieBorder;
Handle g_hSDK_TraceFilter_ShouldHitEntity;
Handle g_hSDK_TraceFilter_GetTraceType;
Handle g_hSDK_ShouldLockTempo;
Handle g_hSDK_NavArea_GetNextEscapeStep;
Handle g_hSDK_CanZombieSpawnHere;
Handle g_hSDK_RemoveWanderersInActiveAreaSet;
Handle g_hSDK_GetHighestFlowSurvivor;
Handle g_hSDK_GameStatsDirectorRelaxed;
Handle g_hSDK_GoAwayFromKeyboard;
Handle g_hSDK_SetPunchAngle;
Handle g_hSDK_SetTimescale;
Handle g_hSDK_ShowMOTD;
Handle g_hSDK_ShowHostBanner;
Handle g_hSDK_CreateSurvivorBot;
Handle g_hSDK_FastGetSurvivorSet;
Handle g_hSDK_HandleJoinTeam;
Handle g_hSDK_FlashlightIsOn;
Handle g_hSDK_FlashlightTurnOn;
Handle g_hSDK_FlashlightTurnOff;
Handle g_hSDK_GetWeaponID;
Handle g_hSDK_WeaponSwitch;
Handle g_hSDK_MaxCarry;
Handle g_hSDK_GetMaxClip1;
Handle g_hSDK_IsAlive;
Handle g_hSDK_Vocalize;
Handle g_hSDK_SpawnTank;
Handle g_hSDK_SpawnSpecial;
Handle g_hSDK_SpawnWitch;
Handle g_hSDK_NextBotUpdate;
Handle g_hSDK_InfectedSetMobRush;
Handle g_hSDK_GameStatsEventSpawn;
Handle g_hSDK_GetFOV;
Handle g_hSDK_KeyValues_new;
Handle g_hSDK_KeyValues_KeyValues;
Handle g_hSDK_KeyValues_DeleteThis;
Handle g_hSDK_KeyValues_GetInt;
Handle g_hSDK_KeyValues_SetInt;
Handle g_hSDK_KeyValues_GetFloat;
Handle g_hSDK_KeyValues_SetFloat;
Handle g_hSDK_KeyValues_GetString;
Handle g_hSDK_KeyValues_SetString;
Handle g_hSDK_KeyValues_GetName;
Handle g_hSDK_KeyValues_SetName;
Handle g_hSDK_KeyValues_FindKey;
Handle g_hSDK_KeyValues_GetFirstSubKey;
Handle g_hSDK_KeyValues_GetNextKey;
Handle g_hSDK_KeyValues_CreateKey;
Handle g_hSDK_KeyValues_RemoveSubKey;
Handle g_hSDK_KeyValues_SaveToFile;
Handle g_hSDK_GetGameModeInfo;

void InitSDKCalls()
{
	SDKPrep prep;

	prep.Start(SDKCall_Raw, SDKConf_Virtual, "INextBot::Update");
	prep.End(g_hSDK_NextBotUpdate);

	/** Native_SetSurvivorIntensity */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "Intensity::Reset");
	prep.End(g_hSDK_IntensityReset);

	/** Native_IncreaseSurvivorIntensity */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "Intensity::Increase");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_IntensityIncrease);

	/** Native_GetLastKnownArea */
	prep.Start(SDKCall_Player, SDKConf_Virtual, "GetLastKnownArea");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_PlayerGetLastKnownArea);

	/** util::GetScriptValueInt */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::GetScriptValueInt");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetScriptValueInt);

	/** util::GetMapArcValue */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::GetMapArcValue");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetMapArcValue);

	/** util::GetScriptValueFloat */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::GetScriptValueFloat");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Return(SDKType_Float, SDKPass_Plain);
	prep.End(g_hSDK_GetScriptValueFloat);

	/** Native_EndPanicEvent */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CL4DGameStats::Event_PanicEventOver");
	prep.End(g_hSDK_GameStatsPanicEventOver);

	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirectorScriptedEventManager::OnPanicEventFinished");
	prep.End(g_hSDK_OnPanicEventFinished);

	/** Native_CollectSpawnAreas */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "ZombieManager::CollectSpawnAreas");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_CollectSpawnAreas);

	/** Native_ResetMobTimer */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::ResetMobTimer");
	prep.End(g_hSDK_ResetMobTimer);

	/** Native_ResetSpecialTimers */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::ResetSpecialTimers");
	prep.End(g_hSDK_ResetSpecialTimers);

	/** Native_StartMobTimer */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::OnMobRushStart");
	prep.End(g_hSDK_OnMobRushStart);

	/** Native_BeginLocalScript */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::BeginLocalScript");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.End(g_hSDK_BeginLocalScript);

	/** Native_EndLocalScript */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::EndLocalScript");
	prep.End(g_hSDK_EndLocalScript);

	/** Native_GetRandomPZSpawnPosition */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "ZombieManager::GetRandomPZSpawnPosition");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
	prep.Param(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_GetRandomPZSpawnPosition);

	/** Native_NavArea_GetZDelta + Native_NavArea_GetNextEscapeStep */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CNavArea::GetZDeltaAtEdgeToArea");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_Float, SDKPass_Plain);
	prep.End(g_hSDK_GetZDeltaAtEdgeToArea);

	/** Native_NavArea_GetNextEscapeStep */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "TerrorNavArea::GetNextEscapeStep");
	prep.Param(SDKType_PlainOldData, SDKPass_ByRef);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_NavArea_GetNextEscapeStep);

	/** Native_NavArea_IsConnected */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CNavArea::IsConnected");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_IsConnected);

	/** Native_GetCurrentArea + Native_GetNearestNavArea */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CNavMesh::GetNearestNavArea_Pos");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetNearestNavArea_Pos);

	/** Native_GetCurrentArea + Native_GetNavAreaEntity */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CNavMesh::GetNavArea_Entity");
	prep.Param(SDKType_CBaseEntity, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetNavArea_Entity);

	/** Native_GetNavArea_Pos */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CNavMesh::GetNavArea_Pos");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetNavArea_Pos);

	/** Native_NavArea_GetZ */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CNavArea::GetZ");
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Return(SDKType_Float, SDKPass_Plain);
	prep.End(g_hSDK_GetNavAreaZ);

	/** Native_IsInFieldOfView*/
	prep.Start(SDKCall_Player, SDKConf_Virtual, "IsInFieldOfView");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_IsInFieldOfView);

	/** Native_IsHiddenByFog */
	prep.Start(SDKCall_Player, SDKConf_Virtual, "IsHiddenByFog");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_IsHiddenByFog);

	/** Native_IsVisibleToClient */
	prep.Start(SDKCall_Static, SDKConf_Signature, "IsVisibleToPlayer");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Param(SDKType_CBasePlayer, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Param(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
	prep.Param(SDKType_PlainOldData, SDKPass_Pointer);
	prep.Param(SDKType_Bool, SDKPass_Pointer);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_IsVisibleToPlayer);

	/** Native_IsInTransition */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::IsInTransition");
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_IsInTransition);

	/** Native_NavArea_IsBlocked */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CNavArea::IsBlocked");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_NavArea_IsBlocked);

	/** Native_IsBehindZombieBorder, Native_NavArea_IsBehindZombieBorder */
	prep.Start(SDKCall_Static, SDKConf_Signature, "CZombieBorder::IsBehindZombieBorder");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_IsBehindZombieBorder);

	/** util/trace_wrapper */
	prep.Start(SDKCall_Raw, SDKConf_Virtual, "ShouldHitEntity");
	prep.Param(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_TraceFilter_ShouldHitEntity);

	prep.Start(SDKCall_Raw, SDKConf_Virtual, "GetTraceType");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_TraceFilter_GetTraceType);

	/** Native_ShouldLockTempo */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirector::ShouldLockTempo");
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_ShouldLockTempo);

	/** Native_GoAwayFromKeyboard */
	prep.Start(SDKCall_Player, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard");
	prep.End(g_hSDK_GoAwayFromKeyboard);

	/** Native_SetPunchAngle */
	prep.Start(SDKCall_Player, SDKConf_Signature, "CBasePlayer::SetPunchAngle");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.End(g_hSDK_SetPunchAngle);

	/** Native_SetTimescale */
	prep.Start(SDKCall_Server, SDKConf_Virtual, "SetTimescale");
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.End(g_hSDK_SetTimescale);

	/** Native_ShowMOTD */
	prep.Start(SDKCall_Player, SDKConf_Signature, "CCSPlayer::ShowMOTD");
	prep.End(g_hSDK_ShowMOTD);

	/** Native_ShowHostBanner */
	prep.Start(SDKCall_Player, SDKConf_Signature, "CTerrorPlayer::ShowHostDetails");
	prep.End(g_hSDK_ShowHostBanner);

	/** Native_GetSurvivorSet */
	prep.Start(SDKCall_Static, SDKConf_Signature, "CTerrorGameRules::FastGetSurvivorSet");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_FastGetSurvivorSet);

	/** Native_AddSurvivorBot */
	prep.Start(SDKCall_Entity, SDKConf_Virtual, "HandleCommand_JoinTeam");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_HandleJoinTeam);

	/** Native_FlashlightIsOn */
	prep.Start(SDKCall_Player, SDKConf_Virtual, "FlashlightIsOn");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_FlashlightIsOn);

	/** Native_FlashlightTurnOn */
	prep.Start(SDKCall_Player, SDKConf_Virtual, "FlashlightTurnOn");
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_FlashlightTurnOn);

	/** Native_FlashlightTurnOff */
	prep.Start(SDKCall_Player, SDKConf_Virtual, "FlashlightTurnOff");
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_FlashlightTurnOff);

	/** Native_GetWeaponID */
	prep.Start(SDKCall_Entity, SDKConf_Virtual, "GetWeaponID");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetWeaponID);

	/** Native_SwitchWeapon */
	prep.Start(SDKCall_Player, SDKConf_Virtual, "Weapon_Switch");
	prep.Param(SDKType_CBaseEntity, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_WeaponSwitch);

	/** Native_GetAmmoMaxCarry */
	prep.Start(SDKCall_Raw, SDKConf_Virtual, "MaxCarry");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_MaxCarry);

	/** Native_GetWeaponMaxClip */
	prep.Start(SDKCall_Entity, SDKConf_Virtual, "GetMaxClip1");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetMaxClip1);

	/** Native_IsEntityAlive */
	prep.Start(SDKCall_Entity, SDKConf_Virtual, "IsAlive");
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_IsAlive);

	/** Native_Vocalize */
	prep.Start(SDKCall_Player, SDKConf_Signature, "CTerrorPlayer::Vocalize");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.End(g_hSDK_Vocalize);

	/** Native_GetFOV */
	prep.Start(SDKCall_Player, SDKConf_Signature, "CBasePlayer::GetFOV");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetFOV);

	/** Native_InternalKeyValues_New */
	prep.Start(SDKCall_Static, SDKConf_Signature, "KeyValues::operator.new");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_new);

	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::KeyValues");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_KeyValues);

	/** Native_InternalKeyValues_Delete */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::deleteThis");
	prep.End(g_hSDK_KeyValues_DeleteThis);

	/** Native_InternalKeyValues_GetInt */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::GetInt");
	prep.Param(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_GetInt);

	/** Native_InternalKeyValues_SetInt */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::SetInt");
	prep.Param(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_SetInt);

	/** Native_InternalKeyValues_GetFloat */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::GetFloat");
	prep.Param(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.Return(SDKType_Float, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_GetFloat);

	/** Native_InternalKeyValues_SetFloat */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::SetFloat");
	prep.Param(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	prep.Param(SDKType_Float, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_SetFloat);

	/** Native_InternalKeyValues_GetString */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::GetString");
	prep.Param(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Return(SDKType_String, SDKPass_Pointer);
	prep.End(g_hSDK_KeyValues_GetString);

	/** Native_InternalKeyValues_SetString */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::SetString");
	prep.Param(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.End(g_hSDK_KeyValues_SetString);

	/** Native_InternalKeyValues_GetSectionName */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::GetName");
	prep.Return(SDKType_String, SDKPass_Pointer);
	prep.End(g_hSDK_KeyValues_GetName);

	/** Native_InternalKeyValues_SetSectionName */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::SetName");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.End(g_hSDK_KeyValues_SetName);

	/** Native_InternalKeyValues_FindKey */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::FindKey");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_FindKey);

	/** Native_InternalKeyValues_GetFirstSubKey */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::GetFirstSubKey");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_GetFirstSubKey);

	/** Native_InternalKeyValues_GetNextSubKey */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::GetNextKey");
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_GetNextKey);

	/** Native_InternalKeyValues_SetNextSubKey */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::CreateKey");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_CreateKey);

	/** Native_InternalKeyValues_RemoveSubKey */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::RemoveSubKey");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_RemoveSubKey);

	/** Native_InternalKeyValues_SaveToFile */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "KeyValues::SaveToFile");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_KeyValues_SaveToFile);

	/** Native_GetGameModeInfo */
	prep.Start(SDKCall_Raw, SDKConf_Virtual, "GetGameModeInfo");
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Return(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GetGameModeInfo);

	/** Native_SpawnSpecial */
	prep.Start(SDKCall_Raw, SDKConf_Signature, "ZombieManager::SpawnSpecial");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Return(SDKType_CBaseEntity, SDKPass_Pointer);
	prep.End(g_hSDK_SpawnSpecial);

	prep.Start(SDKCall_Raw, SDKConf_Signature, "ZombieManager::SpawnTank");
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Return(SDKType_CBaseEntity, SDKPass_Pointer);
	prep.End(g_hSDK_SpawnTank);

	prep.Start(SDKCall_Raw, SDKConf_Signature, "CL4DGameStats::Event_SpawnZombie");
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.End(g_hSDK_GameStatsEventSpawn);

	switch (g_OS)
	{
		case OS_Linux: prep.Start(SDKCall_Raw, SDKConf_Signature, "ZombieManager::SpawnWitch");
		case OS_Windows: prep.Start(SDKCall_Static, SDKConf_Signature, "ZombieManager::SpawnWitch");
	}
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Return(SDKType_CBaseEntity, SDKPass_Pointer);
	prep.End(g_hSDK_SpawnWitch);

	switch (g_OS)
	{
		case OS_Linux: prep.Start(SDKCall_Entity, SDKConf_Signature, "Infected::AttackSurvivorTeam");
		case OS_Windows: prep.Start(SDKCall_Entity, SDKConf_Address, "CALL::Infected::AttackSurvivorTeam");
	}
	prep.End(g_hSDK_InfectedSetMobRush);

	/** Native_AddSurvivorBot */
	switch (g_OS)
	{
		case OS_Linux: prep.Start(SDKCall_Static, SDKConf_Signature, "NextBotCreatePlayerBot<SurvivorBot>");
		case OS_Windows: prep.Start(SDKCall_Static, SDKConf_Address, "CALL::NextBotCreatePlayerBot<SurvivorBot>");
	}
	prep.Param(SDKType_String, SDKPass_Pointer);
	prep.Return(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	prep.End(g_hSDK_CreateSurvivorBot);

	/** Native_CanZombieSpawnHere */
	switch (g_OS)
	{
		case OS_Linux: prep.Start(SDKCall_Raw, SDKConf_Signature, "ZombieManager::CanZombieSpawnHere");
		case OS_Windows: prep.Start(SDKCall_Static, SDKConf_Signature, "ZombieManager::CanZombieSpawnHere");
	}
	prep.Param(SDKType_Vector, SDKPass_Pointer);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_PlainOldData, SDKPass_Plain);
	prep.Param(SDKType_Bool, SDKPass_Plain);
	prep.Param(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
	prep.Return(SDKType_Bool, SDKPass_Plain);
	prep.End(g_hSDK_CanZombieSpawnHere);

	/** Native_SetTempo */
	switch (g_OS)
	{
		case OS_Linux:
		{
			prep.Start(SDKCall_Static, SDKConf_Signature, "TerrorNavMesh::RemoveWanderersInActiveAreaSet");
			prep.End(g_hSDK_RemoveWanderersInActiveAreaSet);

			prep.Start(SDKCall_Raw, SDKConf_Signature, "CL4DGameStats::Event_DirectorRelaxed");
			prep.End(g_hSDK_GameStatsDirectorRelaxed);
		}
		case OS_Windows:
		{
			prep.Start(SDKCall_Static, SDKConf_Address, "CALL::TerrorNavMesh::RemoveWanderersInActiveAreaSet");
			prep.End(g_hSDK_RemoveWanderersInActiveAreaSet);

			prep.Start(SDKCall_Raw, SDKConf_Address, "CALL::CL4DGameStats::Event_DirectorRelaxed");
			prep.End(g_hSDK_GameStatsDirectorRelaxed);
		}
	}

	/** Native_GetHighestFlowSurvivor */
	switch (g_OS)
	{
		case OS_Linux:
		{
			prep.Start(SDKCall_Raw, SDKConf_Signature, "CDirectorTacticalServices::GetHighestFlowSurvivor");
			prep.Param(SDKType_PlainOldData, SDKPass_Plain);
			prep.Return(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);
			prep.End(g_hSDK_GetHighestFlowSurvivor);
		}
		case OS_Windows:
		{
			prep.Start(SDKCall_Static, SDKConf_Signature, "CDirectorTacticalServices::GetHighestFlowSurvivor");
			prep.Param(SDKType_PlainOldData, SDKPass_Plain);
			prep.Return(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL|VDECODE_FLAG_ALLOWWORLD);
			prep.End(g_hSDK_GetHighestFlowSurvivor);
		}
	}

	/** Native_NavAreaSet_Push */
	switch (g_OS)
	{
		case OS_Linux:
		{
			prep.Start(SDKCall_Raw, SDKConf_Signature, "CUtlVector<NavArea>::InsertBefore");
			prep.Param(SDKType_PlainOldData, SDKPass_Plain);
			prep.Param(SDKType_PlainOldData, SDKPass_Pointer);
			prep.Return(SDKType_PlainOldData, SDKPass_Plain);
			prep.End(g_hSDK_NavAreaSetPush);
		}
		case OS_Windows:
		{
			prep.Start(SDKCall_Raw, SDKConf_Address, "CALL::CUtlVector<NavArea>::GrowVector");
			prep.Param(SDKType_PlainOldData, SDKPass_Plain);
			prep.End(g_hSDK_NavAreaSetPush);
		}
	}
}
