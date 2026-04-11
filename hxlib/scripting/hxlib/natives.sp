#pragma newdecls required
#pragma semicolon 1

void RegisterNatives()
{
	CreateNative("AddEntityHook", Native_AddEntityHook);
	CreateNative("RemoveEntityHook", Native_RemoveEntityHook);

	CreateNative("Variant.~Variant", Native_Variant_Delete);
	CreateNative("Variant.GetCell", Native_Variant_GetCell);
	CreateNative("Variant.SetCell", Native_Variant_SetCell);
	CreateNative("Variant.GetString", Native_Variant_GetString);
	CreateNative("Variant.SetString", Native_Variant_SetString);
	CreateNative("Variant.GetVector", Native_Variant_GetVector);
	CreateNative("Variant.SetVector", Native_Variant_SetVector);
	CreateNative("Variant.cell.get", Native_Variant_cell_get);
	CreateNative("Variant.cell.set", Native_Variant_cell_set);
	CreateNative("Variant.type.get", Native_Variant_type_get);
	CreateNative("Variant.type.set", Native_Variant_type_set);
	CreateNative("Variant.address.get", Native_Variant_address_get);

	CreateNative("NavLadder.entity.get", Native_NavLadder_entity_get);
	CreateNative("NavLadder.team.get", Native_NavLadder_team_get);
	CreateNative("NavLadder.length.get", Native_NavLadder_length_get);
	CreateNative("NavLadder.address.get", Native_NavLadder_address_get);
	CreateNative("NavLadder.IsUsableByTeam", Native_NavLadder_IsUsableByTeam);
	CreateNative("NavLadder.GetBottomOrigin", Native_NavLadder_GetBottomOrigin);
	CreateNative("NavLadder.GetTopOrigin", Native_NavLadder_GetTopOrigin);
	CreateNative("NavLadder.GetBottomArea", Native_NavLadder_GetBottomArea);
	CreateNative("NavLadder.GetTopArea", Native_NavLadder_GetTopArea);
	CreateNative("NavLadder.GetTopAreaEx", Native_NavLadder_GetTopAreaEx);
	CreateNative("NavLadder.GetConnection", Native_NavLadder_GetConnection);

	CreateNative("NavArea.baseAttributes.get", Native_NavArea_baseAttributes_get);
	CreateNative("NavArea.baseAttributes.set", Native_NavArea_baseAttributes_set);
	CreateNative("NavArea.spawnAttributes.get", Native_NavArea_spawnAttributes_get);
	CreateNative("NavArea.spawnAttributes.set", Native_NavArea_spawnAttributes_set);
	CreateNative("NavArea.id.get", Native_NavArea_id_get);
	CreateNative("NavArea.elevator.get", Native_NavArea_elevator_get);
	CreateNative("NavArea.address.get", Native_NavArea_address_get);
	CreateNative("NavArea.GetCenter", Native_NavArea_GetCenter);
	CreateNative("NavArea.GetFlow", Native_NavArea_GetFlow);
	CreateNative("NavArea.GetNextEscapeStep", Native_NavArea_GetNextEscapeStep);
	CreateNative("NavArea.GetNextEscapeStepEx", Native_NavArea_GetNextEscapeStepEx);
	CreateNative("NavArea.GetElevatorAreaCount", Native_NavArea_GetElevatorAreaCount);
	CreateNative("NavArea.GetElevatorArea", Native_NavArea_GetElevatorArea);
	CreateNative("NavArea.GetElevatorAreas", Native_NavArea_GetElevatorAreas);
	CreateNative("NavArea.GetElevatorAreasEx", Native_NavArea_GetElevatorAreasEx);
	CreateNative("NavArea.GetLadderCount", Native_NavArea_GetLadderCount);
	CreateNative("NavArea.GetLadder", Native_NavArea_GetLadder);
	CreateNative("NavArea.GetLadders", Native_NavArea_GetLadders);
	CreateNative("NavArea.GetLaddersEx", Native_NavArea_GetLaddersEx);
	CreateNative("NavArea.GetAdjacentCount", Native_NavArea_GetAdjacentCount);
	CreateNative("NavArea.GetAdjacentArea", Native_NavArea_GetAdjacentArea);
	CreateNative("NavArea.GetAdjacentAreas", Native_NavArea_GetAdjacentAreas);
	CreateNative("NavArea.GetAdjacentAreasEx", Native_NavArea_GetAdjacentAreasEx);
	CreateNative("NavArea.GetRandomAdjacentArea", Native_NavArea_GetRandomAdjacentArea);
	CreateNative("NavArea.GetZDeltaToArea", Native_NavArea_GetZDeltaToArea);
	CreateNative("NavArea.IsConnected", Native_NavArea_IsConnected);
	CreateNative("NavArea.GetIncomingCount", Native_NavArea_GetIncomingCount);
	CreateNative("NavArea.GetIncomingConnection", Native_NavArea_GetIncomingConnection);
	CreateNative("NavArea.GetIncomingConnections", Native_NavArea_GetIncomingConnections);
	CreateNative("NavArea.GetIncomingConnectionsEx", Native_NavArea_GetIncomingConnectionsEx);
	CreateNative("NavArea.sizeX.get", Native_NavArea_sizeX_get);
	CreateNative("NavArea.sizeY.get", Native_NavArea_sizeY_get);
	CreateNative("NavArea.sizeZ.get", Native_NavArea_sizeZ_get);
	CreateNative("NavArea.GetCorner", Native_NavArea_GetCorner);
	CreateNative("NavArea.GetZ", Native_NavArea_GetZ);
	CreateNative("NavArea.IsBlocked", Native_NavArea_IsBlocked);
	CreateNative("NavArea.IsBehindZombieBorder", Native_NavArea_IsBehindZombieBorder);
	CreateNative("NavArea.populationDensity.get", Native_NavArea_populationDensity_get);
	CreateNative("NavArea.populationDensity.set", Native_NavArea_populationDensity_set);

	CreateNative("NavAreaSet.Get", Native_NavAreaSet_Get);
	CreateNative("NavAreaSet.GetArrayList", Native_NavAreaSet_GetArrayList);
	CreateNative("NavAreaSet.GetArrayListEx", Native_NavAreaSet_GetArrayListEx);
	CreateNative("NavAreaSet.count.get", Native_NavAreaSet_count_get);
	CreateNative("NavAreaSet.count.set", Native_NavAreaSet_count_set);
	CreateNative("NavAreaSet.Push", Native_NavAreaSet_Push);
	CreateNative("NavAreaSet.Set", Native_NavAreaSet_Set);
	CreateNative("NavAreaSet.SetArrayList", Native_NavAreaSet_SetArrayList);
	CreateNative("NavAreaSet.Erase", Native_NavAreaSet_Erase);
	CreateNative("NavAreaSet.Clear", Native_NavAreaSet_Clear);
	CreateNative("NavAreaSet.Find", Native_NavAreaSet_Find);

	CreateNative("Inferno.entity.get", Native_Inferno_entity_get);
	CreateNative("Inferno.type.get", Native_Inferno_type_get);
	CreateNative("Inferno.maxFlames.get", Native_Inferno_maxFlames_get);
	CreateNative("Inferno.maxFlames.set", Native_Inferno_maxFlames_set);
	CreateNative("Inferno.startTime.get", Native_Inferno_startTime_get);
	CreateNative("Inferno.GetMins", Native_Inferno_GetMins);
	CreateNative("Inferno.GetMaxs", Native_Inferno_GetMaxs);
	CreateNative("Inferno.flameCount.get", Native_Inferno_flameCount_get);
	CreateNative("Inferno.GetFlame", Native_Inferno_GetFlame);
	CreateNative("Inferno.GetOrigin", Native_Inferno_GetOrigin);

	CreateNative("Flame.depth.get", Native_Flame_depth_get);
	CreateNative("Flame.depth.set", Native_Flame_depth_set);
	CreateNative("Flame.parent.get", Native_Flame_parent_get);
	CreateNative("Flame.spreadDuration.get", Native_Flame_spreadDuration_get);
	CreateNative("Flame.spreadDuration.set", Native_Flame_spreadDuration_set);
	CreateNative("Flame.lifetime.get", Native_Flame_lifetime_get);
	CreateNative("Flame.lifetime.set", Native_Flame_lifetime_set);
	CreateNative("Flame.GetOrigin", Native_Flame_GetOrigin);
	CreateNative("Flame.GetDirection", Native_Flame_GetDirection);

	CreateNative("HXLibRescanForwards", Native_HXLibRescanForwards);
	CreateNative("GetServerOS", Native_GetServerOS);
	CreateNative("SetSurvivorIntensity", Native_SetSurvivorIntensity);
	CreateNative("GetSurvivorIntensity", Native_GetSurvivorIntensity);
	CreateNative("IncreaseSurvivorIntensity", Native_IncreaseSurvivorIntensity);
	CreateNative("GetEntityFromAddress", Native_GetEntityFromAddress);
	CreateNative("IsPanic", Native_IsPanic);
	CreateNative("GetPanicStage", Native_GetPanicStage);
	CreateNative("GetFinaleStage", Native_GetFinaleStage);
	CreateNative("IsFinale", Native_IsFinale);
	CreateNative("IsCrescendo", Native_IsCrescendo);
	CreateNative("SetCrescendo", Native_SetCrescendo);
	CreateNative("GetFinaleType", Native_GetFinaleType);
	CreateNative("GetCompletedPanicWaves", Native_GetCompletedPanicWaves);
	CreateNative("SetCompletedPanicWaves", Native_SetCompletedPanicWaves);
	CreateNative("GetTotalPanicWaves", Native_GetTotalPanicWaves);
	CreateNative("SetTotalPanicWaves", Native_SetTotalPanicWaves);
	CreateNative("EndPanicEvent", Native_EndPanicEvent);
	CreateNative("GetLastKnownArea", Native_GetLastKnownArea);
	CreateNative("GetCurrentArea", Native_GetCurrentArea);
	CreateNative("CollectSpawnAreas", Native_CollectSpawnAreas);
	CreateNative("ResetMobTimer", Native_ResetMobTimer);
	CreateNative("StartMobTimer", Native_StartMobTimer);
	CreateNative("GetTimeUntilNextMob", Native_GetTimeUntilNextMob);
	CreateNative("ResetMobRecharge", Native_ResetMobRecharge);
	CreateNative("GetMobRechargeSize", Native_GetMobRechargeSize);
	CreateNative("SetMobRechargeSize", Native_SetMobRechargeSize);
	CreateNative("ResetSpecialTimers", Native_ResetSpecialTimers);
	CreateNative("BeginLocalScript", Native_BeginLocalScript);
	CreateNative("EndLocalScript", Native_EndLocalScript);
	CreateNative("GetRandomPZSpawnPosition", Native_GetRandomPZSpawnPosition);
	CreateNative("GetEntityTeam", Native_GetEntityTeam);
	CreateNative("GetAllNavAreas", Native_GetAllNavAreas);
	CreateNative("GetNavAreaEntity", Native_GetNavAreaEntity);
	CreateNative("GetNavArea", Native_GetNavArea);
	CreateNative("GetNearestNavAreaEntity", Native_GetNearestNavAreaEntity);
	CreateNative("GetNearestNavArea", Native_GetNearestNavArea);
	CreateNative("GetDefaultViewVector", Native_GetDefaultViewVector);
	CreateNative("IsInFieldOfView", Native_IsInFieldOfView);
	CreateNative("IsHiddenByFog", Native_IsHiddenByFog);
	CreateNative("IsVisibleToClient", Native_IsVisibleToClient);
	CreateNative("IsVisibleToTeam", Native_IsVisibleToTeam);
	CreateNative("TR_TraceRayFilterSimple", Native_TR_TraceRayFilterSimple);
	CreateNative("TR_TraceHullFilterSimple", Native_TR_TraceHullFilterSimple);
	CreateNative("IsInTransition", Native_IsInTransition);
	CreateNative("HasAnySurvivorLeftSafeArea", Native_HasAnySurvivorLeftSafeArea);
	CreateNative("AreChallengeModeScriptVariablesAllowed", Native_AreChallengeModeScriptVariablesAllowed);
	CreateNative("IsBehindZombieBorder", Native_IsBehindZombieBorder);
	CreateNative("CanZombieSpawnHere", Native_CanZombieSpawnHere);
	CreateNative("CanZombieSpawnHereEx", Native_CanZombieSpawnHereEx);
	CreateNative("HasCrescendoOccurred", Native_HasCrescendoOccurred);
	CreateNative("SetCrescendoOccurred", Native_SetCrescendoOccurred);
	CreateNative("ShouldLockTempo", Native_ShouldLockTempo);
	CreateNative("GetTempo", Native_GetTempo);
	CreateNative("SetTempo", Native_SetTempo);
	CreateNative("GetTempoFlowStamp", Native_GetTempoFlowStamp);
	CreateNative("SetTempoFlowStamp", Native_SetTempoFlowStamp);
	CreateNative("GetTempoRemainingTime", Native_GetTempoRemainingTime);
	CreateNative("SetTempoRemainingTime", Native_SetTempoRemainingTime);
	CreateNative("GetHighestFlowSurvivor", Native_GetHighestFlowSurvivor);
	CreateNative("GetPlayerFlow", Native_GetPlayerFlow);
	CreateNative("GetActiveSet", Native_GetActiveSet);
	CreateNative("GoAwayFromKeyboard", Native_GoAwayFromKeyboard);
	CreateNative("GetInferno", Native_GetInferno);
	CreateNative("SetPunchAngle", Native_SetPunchAngle);
	CreateNative("GetPunchAngle", Native_GetPunchAngle);
	CreateNative("SetTimescale", Native_SetTimescale);
	CreateNative("ShowMOTD", Native_ShowMOTD);
	CreateNative("ShowHostBanner", Native_ShowHostBanner);
	CreateNative("GetSurvivorCharacter", Native_GetSurvivorCharacter);
	CreateNative("GetSurvivorSet", Native_GetSurvivorSet);
	CreateNative("GetSurvivorCharacterName", Native_GetSurvivorCharacterName);
	CreateNative("GetSurvivorCharacterFromName", Native_GetSurvivorCharacterFromName);
	CreateNative("AddSurvivorBot", Native_AddSurvivorBot);
	CreateNative("FlashlightIsOn", Native_FlashlightIsOn);
	CreateNative("FlashlightTurnOn", Native_FlashlightTurnOn);
	CreateNative("FlashlightTurnOff", Native_FlashlightTurnOff);
	CreateNative("GetWeaponID", Native_GetWeaponID);
	CreateNative("GetTimeLastAlive", Native_GetTimeLastAlive);
	CreateNative("SetTimeLastAlive", Native_SetTimeLastAlive);
	CreateNative("SwitchWeapon", Native_SwitchWeapon);
	CreateNative("GetRestoreSecondaryWeapon", Native_GetRestoreSecondaryWeapon);
	CreateNative("SetRestoreSecondaryWeapon", Native_SetRestoreSecondaryWeapon);
	CreateNative("GetMaxReserveAmmo", Native_GetAmmoMaxCarry);
	CreateNative("GetMaxMagazineAmmo", Native_GetWeaponMaxClip);
	CreateNative("IsEntityAlive", Native_IsEntityAlive);
	CreateNative("GetLastHitGroup", Native_GetLastHitGroup);
	CreateNative("Vocalize", Native_Vocalize);
}

/******************
 * NATIVE CALLBACKS
 ******************/

public void Native_HXLibRescanForwards(Handle hPlugin, int iNumParams)
{
	if (g_bPluginStarted)
		UpdateEnabledHooks();
}

public any Native_GetServerOS(Handle hPlugin, int iNumParams)
{
	return g_OS;
}

/** Entity Hooks */
	public any Native_AddEntityHook(Handle hPlugin, int iNumParams)
	{
		int iEntity = GetNativeCell(1);
		EntityHook type = GetNativeCell(2);
		HookMode mode = GetNativeCell(3);
		Function func = GetNativeFunction(4);

		if (g_entHookDHook[type].Exists(mode) == false)
		{
			ThrowNativeError(SP_ERROR_INSTRUCTION_PARAM,
				"EntityHook type %i does not support %s-hooks",
				type, mode == Hook_Pre ? "pre" : "post");
			return 0;
		}

		int iSafeIndex = GetSafeEntityIndex(iEntity);

		#if DEBUG
			char sPlugin[PLATFORM_MAX_PATH];
			char sClassname[64] = "NULL";
			GetPluginFilename(hPlugin, sPlugin, sizeof(sPlugin));
			if (IsValidEntity(iEntity)) GetEntityClassname(iEntity, sClassname, sizeof(sClassname));

			DebugPrint("Plugin %s is adding an entity hook for %s[%i] (type %i | mode %s)",
				sPlugin, sClassname, iSafeIndex, type, mode == Hook_Pre ? "pre" : "post");
		#endif

		return g_entHook[iSafeIndex][type].Add(type, iEntity, mode, hPlugin, func);
	}
	public void Native_RemoveEntityHook(Handle hPlugin, int iNumParams)
	{
		int iEntity = GetNativeCell(1);
		EntityHook type = GetNativeCell(2);
		HookMode mode = GetNativeCell(3);
		Function func = GetNativeFunction(4);

		if (g_entHookDHook[type].Exists(mode) == false)
		{
			ThrowNativeError(SP_ERROR_INSTRUCTION_PARAM,
				"EntityHook type %i does not support %s-hooks",
				type, mode == Hook_Pre ? "pre" : "post");
			return;
		}

		int iSafeIndex = GetSafeEntityIndex(iEntity);

		#if DEBUG
			char sPlugin[PLATFORM_MAX_PATH];
			char sClassname[64] = "NULL";
			GetPluginFilename(hPlugin, sPlugin, sizeof(sPlugin));
			if (IsValidEntity(iEntity)) GetEntityClassname(iEntity, sClassname, sizeof(sClassname));

			DebugPrint("Plugin %s is removing an entity hook for %s[%i] (type %i | mode %s)",
				sPlugin, sClassname, iSafeIndex, type, mode == Hook_Pre ? "pre" : "post");
		#endif

		g_entHook[iSafeIndex][type].Remove(iEntity, mode, hPlugin, func);

		return;
	}

/** General */

	public void Native_SetSurvivorIntensity(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		float fValue = GetNativeCell(2);

		Address aIntensity = GetEntityAddress(iClient) + view_as<Address>(g_iOffset_Intensity);
		int iNetPropValue = 0;

		if (fValue == 0.0)
		{
			SDKCall(g_hSDK_IntensityReset, aIntensity);
		}
		else
		{
			StoreToAddress(aIntensity, fValue, NumberType_Int32);
			StoreToAddress(aIntensity + view_as<Address>(4), fValue, NumberType_Int32);
			iNetPropValue = RoundToFloor(fValue * 100.0);
		}

		/** netprop won't update on its own right away */
		SetEntProp(iClient, Prop_Send, "m_clientIntensity", iNetPropValue);
	}

	public any Native_GetSurvivorIntensity(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);

		Address aIntensity = GetEntityAddress(iClient) + view_as<Address>(g_iOffset_Intensity);

		return view_as<float>(LoadFromAddress(aIntensity, NumberType_Int32));
	}

	public void Native_IncreaseSurvivorIntensity(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		IntensityType type = GetNativeCell(2);

		SDKCall(g_hSDK_IntensityIncrease, GetEntityAddress(iClient) + view_as<Address>(g_iOffset_Intensity), type);
	}

	public any Native_GetEntityFromAddress(Handle hPlugin, int iNumParams)
	{
		Address entity = GetNativeCell(1);
		return Util_GetEntityFromAddress(entity);
	}

	public any Native_GetPanicStage(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_PanicStage), NumberType_Int32);
	}

	public any Native_IsPanic(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_PanicStage), NumberType_Int32)
			!= PanicStage_Done;
	}

	public any Native_GetFinaleStage(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_FinaleStage), NumberType_Int32);
	}

	public any Native_GetFinaleType(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_FinaleType), NumberType_Int32);
	}

	public any Native_IsFinale(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_FinaleType), NumberType_Int32)
			!= FinaleType_None;
	}

	public any Native_IsCrescendo(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_CrescendoOngoing), NumberType_Int8);
	}

	public void Native_SetCrescendo(Handle hPlugin, int iNumParams)
	{
		bool bSet = GetNativeCell(1);
		StoreToAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_CrescendoOngoing), bSet, NumberType_Int8);
	}

	public any Native_GetCompletedPanicWaves(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_CompletedPanicWaves), NumberType_Int32);
	}

	public void Native_SetCompletedPanicWaves(Handle hPlugin, int iNumParams)
	{
		int iWaves = GetNativeCell(1);
		StoreToAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_CompletedPanicWaves), iWaves, NumberType_Int32);
	}

	public any Native_GetTotalPanicWaves(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_TotalPanicWaves), NumberType_Int32);
	}

	public void Native_SetTotalPanicWaves(Handle hPlugin, int iNumParams)
	{
		int iWaves = GetNativeCell(1);
		StoreToAddress(g_pDirectorScriptedEventManager + view_as<Address>(g_iOffset_ScriptedEventManager_TotalPanicWaves), iWaves, NumberType_Int32);
	}

	/**
	 * simulate the same logic used when UpdatePanicEvents ends it naturally,
	 * as well as making the stage delay time stamp null since that naturally
	 * would have elapsed in the case of a natural end
	 */
	public void Native_EndPanicEvent(Handle hPlugin, int iNumParams)
	{
		/** ScriptedEventManager->panicStageDelay = -1.0;
		 *  ScriptedEventManager->panicStage = PanicStage_Done;
		 *  ScriptedEventManager->crescendoOngoing = false;
		 */
		g_PanicDelayTimer.timestamp = -1.0;
		StoreToAddress(g_pDirectorScriptedEventManager +
			view_as<Address>(g_iOffset_ScriptedEventManager_PanicStage), PanicStage_Done, NumberType_Int32);
		StoreToAddress(g_pDirectorScriptedEventManager +
			view_as<Address>(g_iOffset_ScriptedEventManager_CrescendoOngoing), 0, NumberType_Int8);

		/** reset mob timers */
		SDKCall(g_hSDK_OnMobRushStart, g_pDirector);
		/** update something in gamestats object */
		SDKCall(g_hSDK_GameStatsPanicEventOver, g_pL4DGameStats);
		/** increment finale stage if in a finale, and broadcast panic_event_finished game event */
		SDKCall(g_hSDK_OnPanicEventFinished, g_pDirectorScriptedEventManager);
	}

	public any Native_GetLastKnownArea(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		return SDKCall(g_hSDK_PlayerGetLastKnownArea, iClient);
	}

	/**
	 * get a nav area relative to a player's position in the exact same way as
	 * UpdateLastKnownArea does, with the exception of ignoring nav blockers. this
	 * way we get an accurate nav area returned even when a player is in nav areas
	 * flagged as blocked, unlike GetLastKnownArea
	 */
	public any Native_GetCurrentArea(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		return Util_GetNearestNavArea_Entity(iClient, GetNavFlag_CheckLOS|GetNavFlag_RequireGround|GetNavFlag_IgnoreBlockers, 50.0);
	}

	public any Native_CollectSpawnAreas(Handle hPlugin, int iNumParams)
	{
		LocationType location = GetNativeCell(1);
		ZombieClass class = GetNativeCell(2);

		return SDKCall(g_hSDK_CollectSpawnAreas, g_pZombieManager, location, class);
	}

	public void Native_ResetMobTimer(Handle hPlugin, int iNumParams)
	{
		SDKCall(g_hSDK_ResetMobTimer, g_pDirector);
	}

	public void Native_StartMobTimer(Handle hPlugin, int iNumParams)
	{
		SDKCall(g_hSDK_OnMobRushStart, g_pDirector);
	}

	public any Native_GetTimeUntilNextMob(Handle hPlugin, int iNumParams)
	{
		return g_MobTimer.GetRemaining();
	}

	public void Native_ResetMobRecharge(Handle hPlugin, int iNumParams)
	{
		float fMobMinSize = Util_GetScriptValueFloat("MobMinSize", g_fConVar_MobMinSize);

		StoreToAddress(g_pDirector + view_as<Address>(g_iOffset_Director_NextMobSize), fMobMinSize, NumberType_Int32);
		StoreToAddress(g_pDirector + view_as<Address>(g_iOffset_Director_MobRechargeProgress), 0.0, NumberType_Int32);
	}

	public any Native_GetMobRechargeSize(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirector + view_as<Address>(g_iOffset_Director_NextMobSize), NumberType_Int32);
	}

	public void Native_SetMobRechargeSize(Handle hPlugin, int iNumParams)
	{
		float fSet = GetNativeCell(1);
		StoreToAddress(g_pDirector + view_as<Address>(g_iOffset_Director_NextMobSize), fSet, NumberType_Int32);
	}

	public void Native_ResetSpecialTimers(Handle hPlugin, int iNumParams)
	{
		SDKCall(g_hSDK_ResetSpecialTimers, g_pDirector);
	}

	public void Native_BeginLocalScript(Handle hPlugin, int iNumParams)
	{
		int iLen = GetNativeStringLengthFull(1);
		char[] sScript = new char[iLen];
		GetNativeString(1, sScript, iLen);

		SDKCall(g_hSDK_BeginLocalScript, g_pDirector, sScript);
	}

	public void Native_EndLocalScript(Handle hPlugin, int iNumParams)
	{
		SDKCall(g_hSDK_EndLocalScript, g_pDirector);
	}

	public any Native_GetRandomPZSpawnPosition(Handle hPlugin, int iNumParams)
	{
		ZombieClass class = GetNativeCell(1);
		int iTries = GetNativeCell(2);
		int iGhost = GetNativeCell(4);
		float vPos[3];

		int result = SDKCall(g_hSDK_GetRandomPZSpawnPosition, g_pZombieManager, class, iTries, iGhost, vPos);
		SetNativeArray(3, vPos, sizeof(vPos));

		return view_as<bool>(result);
	}

	public any Native_GetEntityTeam(Handle hPlugin, int iNumParams)
	{
		int iEntity = GetNativeCell(1);
		return Util_GetEntityTeam(iEntity);
	}

	public any Native_GetAllNavAreas(Handle hPlugin, int iNumParams)
	{
		return g_pTheNavAreas;
	}

	public any Native_GetNavAreaEntity(Handle hPlugin, int iNumParams)
	{
		int iEntity = GetNativeCell(1);
		float fDistance = GetNativeCell(2);
		int iFlags = GetNativeCell(3);

		return SDKCall(g_hSDK_GetNavArea_Entity, g_pNavMesh, iEntity, iFlags, fDistance);
	}

	public any Native_GetNavArea(Handle hPlugin, int iNumParams)
	{
		float vPos[3];
		GetNativeArray(1, vPos, sizeof(vPos));
		float fDistance = GetNativeCell(2);

		return SDKCall(g_hSDK_GetNavArea_Pos, g_pNavMesh, vPos, fDistance);
	}

	public any Native_GetNearestNavAreaEntity(Handle hPlugin, int iNumParams)
	{
		int iEntity = GetNativeCell(1);
		float fDistance = GetNativeCell(2);
		int iFlags = GetNativeCell(3);

		return Util_GetNearestNavArea_Entity(iEntity, iFlags, fDistance);
	}

	public any Native_GetNearestNavArea(Handle hPlugin, int iNumParams)
	{
		float vPos[3];
		GetNativeArray(1, vPos, sizeof(vPos));
		float fDistance = GetNativeCell(2);
		int iFlags = GetNativeCell(3);

		return SDKCall(g_hSDK_GetNearestNavArea_Pos, g_pNavMesh, vPos, 0, fDistance,
			iFlags & GetNavFlag_CheckLOS, iFlags & GetNavFlag_RequireGround, iFlags & GetNavFlag_IgnoreBlockers);
	}

	public void Native_GetDefaultViewVector(Handle hPlugin, int iNumParams)
	{
		DefaultViewVector vector = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));

		Util_GetDefaultViewVector(vector, vBuffer);
		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

	public any Native_IsInFieldOfView(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		float vPos[3];
		GetNativeArray(2, vPos, sizeof(vPos));

		return SDKCall(g_hSDK_IsInFieldOfView, iClient, vPos);
	}

	public any Native_IsHiddenByFog(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		float vPos[3];
		GetNativeArray(2, vPos, sizeof(vPos));

		return SDKCall(g_hSDK_IsHiddenByFog, iClient, vPos);
	}

	/** renamed from IsVisibleToPlayer to IsVisibleToClient since that
	 * terminology i feel is more consistent with sourcemod's api
	 */
	public any Native_IsVisibleToClient(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		float vPos[3];
		GetNativeArray(2, vPos, sizeof(vPos));
		float fRange = GetNativeCell(3);
		Address nav = GetNativeCell(4);
		int iFlags = GetNativeCell(5);
		bool bAllowNoNav = GetNativeCell(6);

		int iTeam = GetClientTeam(iClient);

		return SDKCall(g_hSDK_IsVisibleToPlayer, vPos, iClient, iTeam, iFlags, fRange, 0, nav, bAllowNoNav);
	}

	public any Native_IsVisibleToTeam(Handle hPlugin, int iNumParams)
	{
		int iTeam = GetNativeCell(1);
		float vPos[3];
		GetNativeArray(2, vPos, sizeof(vPos));
		float fRange = GetNativeCell(3);
		Address nav = GetNativeCell(4);
		int iFlags = GetNativeCell(5);
		bool bAllowNoNav = GetNativeCell(6);

		return Util_IsVisibleToTeam(iTeam, vPos, fRange, nav, iFlags, bAllowNoNav);
	}

	public any Native_IsInTransition(Handle hPlugin, int iNumParams)
	{
		return SDKCall(g_hSDK_IsInTransition, g_pDirector);
	}

	public any Native_HasAnySurvivorLeftSafeArea(Handle hPlugin, int iNumParams)
	{
		return Util_HasAnySurvivorLeftSafeArea();
	}

	public any Native_AreChallengeModeScriptVariablesAllowed(Handle hPlugin, int iNumParams)
	{
		return Util_AllowChallengeModeScriptVariables();
	}

	public any Native_IsBehindZombieBorder(Handle hPlugin, int iNumParams)
	{
		float vPos[3];
		GetNativeArray(1, vPos, sizeof(vPos));

		return SDKCall(g_hSDK_IsBehindZombieBorder, vPos);
	}

	public any Native_CanZombieSpawnHere(Handle hPlugin, int iNumParams)
	{
		float vPos[3]; GetNativeArray(1, vPos, 3);
		Address nav = GetNativeCell(2);
		ZombieClass class = GetNativeCell(3);
		int iGhost = GetNativeCell(4);

		switch (g_OS)
		{
			case OS_Linux: return SDKCall(g_hSDK_CanZombieSpawnHere, g_pZombieManager, vPos, nav, class, false, iGhost);
			case OS_Windows: return SDKCall(g_hSDK_CanZombieSpawnHere, vPos, nav, class, false, iGhost);
		}

		return false;
	}

	public any Native_CanZombieSpawnHereEx(Handle hPlugin, int iNumParams)
	{
		float vPos[3]; GetNativeArray(1, vPos, 3);
		float vHullMin[3]; GetNativeArray(2, vHullMin, 3);
		float vHullMax[3]; GetNativeArray(3, vHullMax, 3);
		Address nav = GetNativeCell(4);
		ZombieClass class = GetNativeCell(5);
		int iGhost = GetNativeCell(6);

		return Util_CanZombieSpawnHere(vPos, vHullMin, vHullMax, nav, class, iGhost);
	}

	public any Native_TR_TraceRayFilterSimple(Handle hPlugin, int iNumParams)
	{
		float vPos[3]; GetNativeArray(1, vPos, 3);
		float vVec[3]; GetNativeArray(2, vVec, 3);
		int iMask = GetNativeCell(3);
		RayType rayType = GetNativeCell(4);
		int iEntity = GetNativeCell(5);
		CollisionGroup collisionGroup = GetNativeCell(6);
		Function extraCallback = GetNativeFunction(7);
		any filterData = GetNativeCell(8);

		g_trace.filter = new TraceFilterSimple(iEntity, collisionGroup);
		g_trace.plugin = hPlugin;
		g_trace.callback = extraCallback;

		Handle hReturnTrace = TR_TraceRayFilterEx(vPos, vVec, iMask, rayType,
			TraceEntityFilter_wrapper, filterData, g_trace.filter.GetTraceType());

		delete g_trace.filter;

		return hReturnTrace.Clone(hPlugin);
	}

	public any Native_TR_TraceHullFilterSimple(Handle hPlugin, int iNumParams)
	{
		float vPos[3]; GetNativeArray(1, vPos, 3);
		float vVec[3]; GetNativeArray(2, vVec, 3);
		float vMins[3]; GetNativeArray(3, vMins, 3);
		float vMaxs[3]; GetNativeArray(4, vMaxs, 3);
		int iMask = GetNativeCell(5);
		int iEntity = GetNativeCell(6);
		CollisionGroup collisionGroup = GetNativeCell(7);
		Function extraCallback = GetNativeFunction(8);
		any filterData = GetNativeCell(9);

		g_trace.filter = new TraceFilterSimple(iEntity, collisionGroup);
		g_trace.plugin = hPlugin;
		g_trace.callback = extraCallback;

		Handle hReturnTrace = TR_TraceHullFilterEx(vPos, vVec, vMins, vMaxs, iMask,
			TraceEntityFilter_wrapper, filterData, g_trace.filter.GetTraceType());

		delete g_trace.filter;

		return hReturnTrace.Clone(hPlugin);
	}

	public any Native_HasCrescendoOccurred(Handle hPlugin, int iNumParams)
	{
		return Util_HasCrescendoOccurred();
	}

	public void Native_SetCrescendoOccurred(Handle hPlugin, int iNumParams)
	{
		bool bValue = GetNativeCell(1);
		StoreToAddress(g_pDirectorScriptedEventManager + view_as<Address>(
			g_iOffset_ScriptedEventManager_CrescendoOccured), bValue, NumberType_Int8);
	}

	public any Native_ShouldLockTempo(Handle hPlugin, int iNumParams)
	{
		return SDKCall(g_hSDK_ShouldLockTempo, g_pDirector);
	}

	public any Native_GetTempo(Handle hPlugin, int iNumParams)
	{
		return Util_GetTempo();
	}

	public void Native_SetTempo(Handle hPlugin, int iNumParams)
	{
		DirectorTempo tempo = GetNativeCell(1);
		bool bDoAll = GetNativeCell(2);

		StoreToAddress(g_pDirector + view_as<Address>(
			g_iOffset_Director_Tempo), tempo, NumberType_Int32);

		/** set additional data as if tempo was naturally changed in CDirector::UpdateTempo */
		if (bDoAll)
		{
			switch (tempo)
			{
				case Tempo_BuildUp:
				{
					float fMinInterval = Util_GetScriptValueFloat("BuildUpMinInterval", g_fConVar_DirectorBuildUpMinInterval);
					Util_SetTempoRemainingTime(fMinInterval);
				}

				case Tempo_SustainPeak:
				{
					float fMin = Util_GetScriptValueFloat("SustainPeakMinTime", g_fConVar_DirectorSustainPeakMinTime);
					float fMax = Util_GetScriptValueFloat("SustainPeakMaxTime", g_fConVar_DirectorSustainPeakMaxTime);

					float fSet = GetRandomFloat(fMin, fMax);
					Util_SetTempoRemainingTime(fSet);

					/** clear population density from all nav areas in survivor active sets.
					 * triggers OnSustainPeakPopulationClear forward
					 */
					SDKCall(g_hSDK_RemoveWanderersInActiveAreaSet);
				}

				case Tempo_PeakFade:
				{
					Util_SetRelaxStartFlow();
				}

				case Tempo_Relax:
				{
					float fMin = Util_GetScriptValueFloat("RelaxMinInterval", g_fConVar_DirectorRelaxMinInterval);
					float fMax = Util_GetScriptValueFloat("RelaxMaxInterval", g_fConVar_DirectorRelaxMaxInterval);

					float fSet = GetRandomFloat(fMin, fMax);
					Util_SetTempoRemainingTime(fSet);

					Util_SetRelaxStartFlow();

					SDKCall(g_hSDK_GameStatsDirectorRelaxed, g_pL4DGameStats);
				}
			}
		}
	}

	public any Native_GetTempoFlowStamp(Handle hPlugin, int iNumParams)
	{
		return LoadFromAddress(g_pDirector + view_as<Address>(g_iOffset_Director_RelaxStartFlow), NumberType_Int32);
	}

	public void Native_SetTempoFlowStamp(Handle hPlugin, int iNumParams)
	{
		float fValue = GetNativeCell(1);

		StoreToAddress(g_pDirector + view_as<Address>(g_iOffset_Director_RelaxStartFlow),
			fValue, NumberType_Int32);
	}

	public any Native_GetTempoRemainingTime(Handle hPlugin, int iNumParams)
	{
		return g_TempoTimer.GetRemaining();
	}

	public void Native_SetTempoRemainingTime(Handle hPlugin, int iNumParams)
	{
		float fSet = GetNativeCell(1);

		Util_SetTempoRemainingTime(fSet);
	}

	public any Native_GetHighestFlowSurvivor(Handle hPlugin, int iNumParams)
	{
		FlowType type = GetNativeCell(1);

		return Util_GetHighestFlowSurvivor(type);
	}

	public any Native_GetPlayerFlow(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		FlowType type = GetNativeCell(2);

		return Util_GetPlayerFlow(iClient, type);
	}

	public any Native_GetActiveSet(Handle hPlugin, int iNumParams)
	{
		int iPlayer = GetNativeCell(1);
		return GetEntityAddress(iPlayer) + view_as<Address>(g_iOffset_Player_ActiveSet);
	}

	public void Native_GoAwayFromKeyboard(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		bool bNotify = GetNativeCell(2);

		if (!bNotify) g_bBlockUM_GoAwayFromKeyboard = true;
		else if (!g_forward[Forward_OnGoAwayFromKeyboard].used && !g_forward[Forward_OnGoAwayFromKeyboard_Post].used)
		{
			g_bAllowUM_OnGoAwayFromKeyboard = true;
			Util_SendAFKUserMessage(iClient);
			g_bAllowUM_OnGoAwayFromKeyboard = false;
		}

		SDKCall(g_hSDK_GoAwayFromKeyboard, iClient);
		g_bBlockUM_GoAwayFromKeyboard = false;
	}

	public any Native_GetInferno(Handle hPlugin, int iNumParams)
	{
		int iEntity = GetNativeCell(1);
		return GetEntityAddress(iEntity);
	}

	public void Native_GetPunchAngle(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));

		LoadVectorFromAddress(GetEntityAddress(iClient) + view_as<Address>(g_iOffset_Player_punchAngle), vBuffer);
		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

	public void Native_SetPunchAngle(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		float vValue[3];
		GetNativeArray(2, vValue, sizeof(vValue));

		SDKCall(g_hSDK_SetPunchAngle, iClient, vValue);
	}

	public void Native_SetTimescale(Handle hPlugin, int iNumParams)
	{
		float fValue = GetNativeCell(1);
		bool bClient = GetNativeCell(2);

		SDKCall(g_hSDK_SetTimescale, fValue);

		if (bClient)
		{
			BfWrite msg = view_as<BfWrite>(StartMessageAll("DesiredTimescale", USERMSG_RELIABLE));

			/** send all expected data for client CGameTimescale.
			 * hardcode smoothing vars to 1000.0 so that they know it's abrupt */
			msg.WriteFloat(fValue);	// desiredTimescale
			msg.WriteFloat(1000.0);	// acceleration
			msg.WriteFloat(1000.0);	// minBlendRate
			msg.WriteFloat(1000.0);	// blendDeltaMultiplier

			EndMessage();
		}
	}

	public void Native_ShowMOTD(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		SDKCall(g_hSDK_ShowMOTD, iClient);
	}

	public void Native_ShowHostBanner(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		SDKCall(g_hSDK_ShowHostBanner, iClient);
	}

	public any Native_GetSurvivorCharacter(Handle hPlugin, int iNumParams)
	{
		Address player = GetEntityAddress(GetNativeCell(1));
		return LoadFromAddress(player + view_as<Address>(g_iOffset_Player_character), NumberType_Int32);
	}

	public any Native_GetSurvivorSet(Handle hPlugin, int iNumParams)
	{
		return SDKCall(g_hSDK_FastGetSurvivorSet);
	}

	public void Native_GetSurvivorCharacterName(Handle hPlugin, int iNumParams)
	{
		int iCharacter = GetNativeCell(1);
		int iBufferLen = GetNativeCell(3);
		char[] sBuffer = new char[iBufferLen];

		Util_GetSurvivorCharacterName(iCharacter, sBuffer, iBufferLen);
		SetNativeString(2, sBuffer, iBufferLen);
	}

	public any Native_GetSurvivorCharacterFromName(Handle hPlugin, int iNumParams)
	{
		int iNameLen = GetNativeStringLengthFull(1);
		char[] sName = new char[iNameLen];
		GetNativeString(1, sName, iNameLen);

		int iCharacter = Survivor_Random;

		for (int i = 0; i < sizeof(g_sSurvivorCharacterNames); i++)
		{
			if (strcmp(sName, g_sSurvivorCharacterNames[i], false) == 0)
			{
				if (i >= 4) iCharacter = i - 4;
				else iCharacter = i;
			}
		}

		return iCharacter;
	}

	public any Native_AddSurvivorBot(Handle hPlugin, int iNumParams)
	{
		int iCharacter = GetNativeCell(1);
		static char sName[16];

		Util_GetSurvivorCharacterName(iCharacter, sName, sizeof(sName));

		int iBot = SDKCall(g_hSDK_CreateSurvivorBot, sName);
		if (IsValidClient(iBot))
			SDKCall(g_hSDK_HandleJoinTeam, iBot, Team_Survivor, iCharacter, 0);

		return iBot;
	}

	public any Native_FlashlightIsOn(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		return SDKCall(g_hSDK_FlashlightIsOn, iClient);
	}

	public void Native_FlashlightTurnOn(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		bool bPlaySound = GetNativeCell(2);

		SDKCall(g_hSDK_FlashlightTurnOn, iClient, bPlaySound);
		if (bPlaySound) EmitGameSoundToClient(iClient, "Player.FlashlightOn");
	}

	public void Native_FlashlightTurnOff(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		bool bPlaySound = GetNativeCell(2);

		SDKCall(g_hSDK_FlashlightTurnOff, iClient, bPlaySound);
		if (bPlaySound) EmitGameSoundToClient(iClient, "Player.FlashlightOff");
	}

	public any Native_GetWeaponID(Handle hPlugin, int iNumParams)
	{
		int iWeapon = GetNativeCell(1);
		return SDKCall(g_hSDK_GetWeaponID, iWeapon);
	}

	public any Native_GetTimeLastAlive(Handle hPlugin, int iNumParams)
	{
		Address clientAdr = GetEntityAddress(GetNativeCell(1));
		return LoadFromAddress(clientAdr + view_as<Address>(g_iOffset_Player_TimeLastAlive), NumberType_Int32);
	}

	public void Native_SetTimeLastAlive(Handle hPlugin, int iNumParams)
	{
		Address clientAdr = GetEntityAddress(GetNativeCell(1));
		float fTime = GetNativeCell(2);

		StoreToAddress(clientAdr + view_as<Address>(g_iOffset_Player_TimeLastAlive), fTime, NumberType_Int32);
	}

	public any Native_SwitchWeapon(Handle hPlugin, int iNumParams)
	{
		int iClient = GetNativeCell(1);
		int iSlot = GetNativeCell(2);

		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		if (iWeapon == -1) return false;

		return SDKCall(g_hSDK_WeaponSwitch, iClient, iWeapon, 0);
	}

	public any Native_GetRestoreSecondaryWeapon(Handle hPlugin, int iNumParams)
	{
		Address player = GetEntityAddress(GetNativeCell(1));
		int iWeapon = LoadEntityFromHandleAddress(player + view_as<Address>(g_iOffset_Player_DetachedWeapon));
		return iWeapon;
	}

	public void Native_SetRestoreSecondaryWeapon(Handle hPlugin, int iNumParams)
	{
		Address player = GetEntityAddress(GetNativeCell(1));
		int iWeapon = GetNativeCell(2);
		StoreEntityToHandleAddress(player + view_as<Address>(g_iOffset_Player_DetachedWeapon), iWeapon);
	}

	public any Native_GetAmmoMaxCarry(Handle hPlugin, int iNumParams)
	{
		AmmoType type = GetNativeCell(1);
		return SDKCall(g_hSDK_MaxCarry, g_pAmmoDef, type, 0);
	}

	public any Native_GetWeaponMaxClip(Handle hPlugin, int iNumParams)
	{
		int iWeapon = GetNativeCell(1);
		return SDKCall(g_hSDK_GetMaxClip1, iWeapon);
	}

	public any Native_IsEntityAlive(Handle hPlugin, int iNumParams)
	{
		int iEntity = GetNativeCell(1);
		return SDKCall(g_hSDK_IsAlive, iEntity);
	}

	public any Native_GetLastHitGroup(Handle hPlugin, int iNumParams)
	{
		Address ent = GetEntityAddress(GetNativeCell(1));
		return LoadFromAddress(ent + view_as<Address>(g_iOffset_LastHitGroup), NumberType_Int32);
	}

	public void Native_Vocalize(Handle hPlugin, int iNumParams)
	{
		int iLen = GetNativeStringLengthFull(2);
		char[] sGameSound = new char[iLen];

		int iClient = GetNativeCell(1);
		GetNativeString(2, sGameSound, iLen);
		float fCooldown = GetNativeCell(3);
		float fDurationAI = GetNativeCell(4);

		SDKCall(g_hSDK_Vocalize, iClient, sGameSound, fCooldown, fDurationAI);
	}

/** Variant methodmap */
	public void Native_Variant_Delete(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		Util_DeleteStringMemoryBlock(pThis);
	}

	public any Native_Variant_GetCell(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);

		return LoadFromAddress(pThis, NumberType_Int32);
	}
	public void Native_Variant_SetCell(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		any value = GetNativeCell(2);

		StoreToAddress(pThis, value, NumberType_Int32);
	}

	public any Native_Variant_GetString(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		int iBufferSize = GetNativeCell(3);
		char[] sBuffer = new char[iBufferSize];
		GetNativeString(2, sBuffer, iBufferSize);

		int iWritten = LoadStringFromPointer(pThis, sBuffer, iBufferSize);

		SetNativeString(2, sBuffer, iBufferSize);

		return iWritten;
	}
	public void Native_Variant_SetString(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		int iLength = GetNativeStringLengthFull(2);
		char[] sValue = new char[iLength];
		GetNativeString(2, sValue, iLength);

		Util_StoreToStringPtr(pThis, sValue);
	}

	public void Native_Variant_GetVector(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));

		LoadVectorFromAddress(pThis, vBuffer);
	}
	public void Native_Variant_SetVector(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		float vValue[3];
		GetNativeArray(2, vValue, sizeof(vValue));

		StoreVectorToAddress(pThis, vValue);
	}

	public any Native_Variant_cell_get(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);

		return LoadFromAddress(pThis, NumberType_Int32);
	}
	public void Native_Variant_cell_set(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		any value = GetNativeCell(2);

		StoreToAddress(pThis, value, NumberType_Int32);
	}

	public any Native_Variant_type_get(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);

		return LoadFromAddress(pThis + view_as<Address>(g_iOffset_VariantType), NumberType_Int32);
	}
	public void Native_Variant_type_set(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);
		VariantType type = GetNativeCell(2);

		StoreToAddress(pThis + view_as<Address>(g_iOffset_VariantType), type, NumberType_Int32);
	}

	public any Native_Variant_address_get(Handle hPlugin, int iNumParams)
	{
		Address pThis = GetNativeCell(1);

		return pThis;
	}

/** NavLadder methodmap */
	public any Native_NavLadder_entity_get(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		return Util_NavLadder_GetEntity(ladder);
	}

	public any Native_NavLadder_team_get(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		int entity = Util_NavLadder_GetEntity(ladder);
		return Util_GetEntityTeam(entity);
	}

	public any Native_NavLadder_length_get(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		return LoadFromAddress(ladder + view_as<Address>(g_iOffset_NavLadder_length), NumberType_Int32);
	}

	public any Native_NavLadder_address_get(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		return ladder;
	}

	public any Native_NavLadder_IsUsableByTeam(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		int iEntity = Util_NavLadder_GetEntity(ladder);
		if (!IsValidEntity(iEntity)) return true;

		int ladderTeam = Util_GetEntityTeam(iEntity);
		if (ladderTeam == Team_Unassigned) return true;

		int queryTeam = GetNativeCell(2);
		return queryTeam == ladderTeam;

	}

	public void Native_NavLadder_GetBottomOrigin(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		float vPos[3];
		GetNativeArray(2, vPos, sizeof(vPos));

		Util_NavLadder_GetOrigin(ladder, Ladder_Bottom, vPos);

		SetNativeArray(2, vPos, sizeof(vPos));
	}

	public void Native_NavLadder_GetTopOrigin(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		float vPos[3];
		GetNativeArray(2, vPos, sizeof(vPos));

		Util_NavLadder_GetOrigin(ladder, Ladder_Top, vPos);

		SetNativeArray(2, vPos, sizeof(vPos));
	}

	public any Native_NavLadder_GetBottomArea(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		return Util_NavLadder_GetConnection(ladder, LadderConnection_Bottom);
	}

	public any Native_NavLadder_GetTopArea(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		Address nav;

		for (int i = LADDER_CONNECTION_TOP_MIN; i <= LADDER_CONNECTION_TOP_MAX; i++)
		{
			nav = Util_NavLadder_GetConnection(ladder, i);
			if (nav) return nav;
		}

		return 0x0;
	}

	public any Native_NavLadder_GetTopAreaEx(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		Address nav = GetNativeCellRef(2);

		int iStartIndex = GetNativeCell(3);
		iStartIndex++;
		if (iStartIndex > LADDER_CONNECTION_TOP_MAX)
			return -1;

		for (int i = iStartIndex; i <= LADDER_CONNECTION_TOP_MAX; i++)
		{
			nav = Util_NavLadder_GetConnection(ladder, i);
			if (nav)
			{
				SetNativeCellRef(2, nav);
				return i;
			}
		}

		return -1;
	}

	public any Native_NavLadder_GetConnection(Handle hPlugin, int iNumParams)
	{
		Address ladder = GetNativeCell(1);
		int connection = GetNativeCell(2);
		return Util_NavLadder_GetConnection(ladder, connection);
	}

/** NavArea methodmap */
	public any Native_NavArea_populationDensity_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_WandererPopulation), NumberType_Int32);
	}
	public void Native_NavArea_populationDensity_set(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int value = GetNativeCell(2);
		StoreToAddress(nav + view_as<Address>(g_iOffset_NavArea_WandererPopulation), value, NumberType_Int32);
	}

	public any Native_NavArea_baseAttributes_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_BaseAttributes), NumberType_Int32);
	}
	public void Native_NavArea_baseAttributes_set(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int value = GetNativeCell(2);
		StoreToAddress(nav + view_as<Address>(g_iOffset_NavArea_BaseAttributes), value, NumberType_Int32);
	}

	public any Native_NavArea_spawnAttributes_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		return Util_NavArea_GetSpawnAttributes(nav);
	}
	public void Native_NavArea_spawnAttributes_set(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int value = GetNativeCell(2);
		StoreToAddress(nav + view_as<Address>(g_iOffset_NavArea_SpawnAttributes), value, NumberType_Int32);
	}

	public any Native_NavArea_id_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);

		return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_id), NumberType_Int32);
	}

	public any Native_NavArea_address_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		return nav;
	}

	public any Native_NavArea_elevator_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);

		Address elevator = LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_connectedElevator), NumberType_Int32);
		if (!elevator) return -1;

		return Util_GetEntityFromAddress(elevator);
	}

	public void Native_NavArea_GetCenter(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));

		Util_NavArea_GetCenter(nav, vBuffer);
		SetNativeArray(2, vBuffer, 3);
	}

	public any Native_NavArea_IsBehindZombieBorder(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);

		float vCenter[3];
		Util_NavArea_GetCenter(nav, vCenter);

		return SDKCall(g_hSDK_IsBehindZombieBorder, vCenter);
	}

	public any Native_NavArea_IsBlocked(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iTeam = GetNativeCell(2);
		bool bFlow = GetNativeCell(3);

		return SDKCall(g_hSDK_NavArea_IsBlocked, nav, iTeam, bFlow);
	}

	public any Native_NavArea_GetFlow(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int type = GetNativeCell(2);

		return Util_NavArea_GetFlow(nav, type);
	}

	public any Native_NavArea_GetElevatorAreaCount(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		CUtlVectorUltraConservative list = Util_NavArea_GetElevatorAreaList(nav);

		return list.count;
	}

	public any Native_NavArea_GetElevatorArea(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		CUtlVectorUltraConservative list = Util_NavArea_GetElevatorAreaList(nav);
		int iIndex = GetNativeCell(2);

		return list.GetPair(iIndex);
	}

	public any Native_NavArea_GetElevatorAreas(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		CUtlVectorUltraConservative list = Util_NavArea_GetElevatorAreaList(nav);

		ArrayList hArray = new ArrayList();
		list.GetArrayListPair(hArray);

		return hArray;
	}

	public any Native_NavArea_GetElevatorAreasEx(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		CUtlVectorUltraConservative list = Util_NavArea_GetElevatorAreaList(nav);
		ArrayList hArray = GetNativeCell(2);

		return list.GetArrayListPair(hArray);
	}

	public any Native_NavArea_GetLadderCount(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);

		CUtlVectorUltraConservative list = Util_NavArea_GetLadderList(nav, iDirection);
		return list.count;
	}

	public any Native_NavArea_GetLadder(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);
		int iIndex = GetNativeCell(3);

		CUtlVectorUltraConservative list = Util_NavArea_GetLadderList(nav, iDirection);
		return list.Get(iIndex);
	}

	public any Native_NavArea_GetLadders(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);
		ArrayList hArray = new ArrayList();

		Util_NavArea_GetArrayListOfLadders(nav, iDirection, hArray);
		return hArray;
	}

	public any Native_NavArea_GetLaddersEx(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);
		ArrayList hArray = GetNativeCell(3);

		return Util_NavArea_GetArrayListOfLadders(nav, iDirection, hArray);
	}

	public any Native_NavArea_GetAdjacentCount(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);

		CUtlVectorUltraConservative list;
		int iTotal = 0;

		if (iDirection == view_as<int>(NavDir_All))
		{
			for (int dir = 0; dir < 4; dir++)
			{
				list = Util_NavArea_GetAdjacentAreaList(nav, dir);
				iTotal += list.count;
			}
		}
		else
		{
			list = Util_NavArea_GetAdjacentAreaList(nav, iDirection);
			iTotal = list.count;
		}

		return iTotal;
	}

	public any Native_NavArea_GetAdjacentArea(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);
		int iIndex = GetNativeCell(3);

		CUtlVectorUltraConservative list = Util_NavArea_GetAdjacentAreaList(nav, iDirection);
		return list.GetPair(iIndex);
	}

	public any Native_NavArea_GetAdjacentAreas(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);
		ArrayList hArray = new ArrayList();

		Util_NavArea_GetArrayListOfAdjacentAreas(nav, iDirection, hArray);

		return hArray;
	}

	public any Native_NavArea_GetAdjacentAreasEx(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		ArrayList hArray = GetNativeCell(2);
		int iDirection = GetNativeCell(3);

		return Util_NavArea_GetArrayListOfAdjacentAreas(nav, iDirection, hArray);
	}

	public any Native_NavArea_GetRandomAdjacentArea(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);

		if (iDirection == view_as<int>(NavDir_All))
		{
			int iTotals[4];
			int iTotalSum;
			CUtlVectorUltraConservative list[4];

			for (int dir = 0; dir < 4; dir++)
			{
				list[dir] = Util_NavArea_GetAdjacentAreaList(nav, dir);
				iTotals[dir] = list[dir].count;
				iTotalSum += iTotals[dir];
			}

			if (iTotalSum == 0) return Address_Null;

			int iRandomNum = GetRandomInt(1, iTotalSum);
			int iIndexOffset;
			int iCount;

			for (int dir = 0; dir < 4; dir++)
			{
				iCount += iTotals[dir];

				if (iRandomNum <= iCount)
				{
					int iIndex = iRandomNum - iIndexOffset - 1;
					return list[dir].GetPair(iIndex);
				}

				iIndexOffset = iCount;
			}
		}
		else
		{
			CUtlVectorUltraConservative list = Util_NavArea_GetAdjacentAreaList(nav, iDirection);
			int iTotal = list.count;

			if (iTotal == 0) return Address_Null;

			int iRandomNum = GetRandomInt(0, iTotal - 1);

			return list.GetPair(iRandomNum);
		}

		return Address_Null;
	}

	public any Native_NavArea_GetIncomingCount(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);

		CUtlVectorUltraConservative list;
		int iTotal = 0;

		if (iDirection == view_as<int>(NavDir_All))
		{
			for (int dir = 0; dir < 4; dir++)
			{
				list = Util_NavArea_GetIncomingConnectionList(nav, dir);
				iTotal += list.count;
			}
		}
		else
		{
			list = Util_NavArea_GetIncomingConnectionList(nav, iDirection);
			iTotal = list.count;
		}

		return iTotal;
	}

	public any Native_NavArea_GetIncomingConnection(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);
		int iIndex = GetNativeCell(3);

		CUtlVectorUltraConservative list = Util_NavArea_GetIncomingConnectionList(nav, iDirection);
		return list.GetPair(iIndex);
	}

	public any Native_NavArea_GetIncomingConnections(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		int iDirection = GetNativeCell(2);
		ArrayList hArray = new ArrayList();

		Util_NavArea_GetArrayListOfIncomingConnections(nav, iDirection, hArray);

		return hArray;
	}

	public any Native_NavArea_GetIncomingConnectionsEx(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		ArrayList hArray = GetNativeCell(2);
		int iDirection = GetNativeCell(3);

		return Util_NavArea_GetArrayListOfIncomingConnections(nav, iDirection, hArray);
	}

	public any Native_NavArea_GetNextEscapeStep(Handle hPlugin, int iNumParams)
	{
		Address thisNav = GetNativeCell(1);
		return SDKCall(g_hSDK_NavArea_GetNextEscapeStep, thisNav, 0);
	}

	/** original function fucks up how it determines the TraverseType for
	 * elevators going down. they're given the same enum as downward ladders.
	 * no way it's not a bug, but just to be safe i'd rather use a sourcepawn
	 * recreation that fixes it than do a memory patch.
	 * it's identical with the only exception being that going down an elevator
	 * will become Traverse_ElevatorDown rather than Traverse_LadderDown. all other
	 * enums align with how the original assigns them.
	 */
	public any Native_NavArea_GetNextEscapeStepEx(Handle hPlugin, int iNumParams)
	{
		Address thisNav = GetNativeCell(1);
		any type = Traverse_None;

		Address recordNav = thisNav;
		float fRecordFlow = Util_NavArea_GetFlow(recordNav, FlowType_Progress);

		CUtlVectorUltraConservative list;
		int iListLen;

		Address nav;
		float fNavFlow;

		/** adjacent nav areas */
		float fZDelta;

		for (int dir = 0; dir < 4; dir++)
		{
			list = Util_NavArea_GetAdjacentAreaList(thisNav, dir);
			iListLen = list.count;

			for (int i = 0; i < iListLen; i++)
			{
				nav = list.GetPair(i);
				if (Util_NavArea_GetNextEscapeStepIsRecord(nav, fRecordFlow, fNavFlow))
				{
					fZDelta = Util_NavArea_GetZDeltaAtEdgeToArea(thisNav, nav);

					if (fZDelta <= g_fConVar_NavFlowMaxSurvivorClimbHeight
						&& -fZDelta <= g_fConVar_NavFlowMaxSurvivorDropHeight)
					{
						type = dir;
						recordNav = nav;
						fRecordFlow = fNavFlow;
					}
				}
			}
		}

		/** ladders */
		Address ladder;
		int ladderEnt;
		int team;
		int connectionMin, connectionMax;

		for (int dir = 0; dir < 2; dir++)
		{
			list = Util_NavArea_GetLadderList(thisNav, dir);
			iListLen = list.count;

			switch (dir)
			{
				case LadderDir_Up:
				{
					connectionMin = LADDER_CONNECTION_TOP_MIN;
					connectionMax = LADDER_CONNECTION_TOP_MAX;
				}
				case LadderDir_Down:
				{
					connectionMin = LadderConnection_Bottom;
					connectionMax = LadderConnection_Bottom;
				}
			}

			for (int i = 0; i < iListLen; i++)
			{
				ladder = list.Get(i);
				ladderEnt = Util_NavLadder_GetEntity(ladder);

				if (IsValidEntity(ladderEnt))
				{
					team = GetEntityTeam(ladderEnt);
					if (team != Team_Survivor && team != Team_Unassigned)
						continue;
				}

				for (int connection = connectionMin; connection <= connectionMax; connection++)
				{
					nav = Util_NavLadder_GetConnection(ladder, connection);
					if (!nav) continue;

					if (Util_NavArea_GetNextEscapeStepIsRecord(nav, fRecordFlow, fNavFlow))
					{
						type = 4 + dir;
						recordNav = nav;
						fRecordFlow = fNavFlow;
					}
				}
			}
		}

		/** elevators */
		if (Util_NavArea_GetBaseAttributes(thisNav) & NavBase_NavMeshHasElevator)
		{
			list = Util_NavArea_GetElevatorAreaList(thisNav);
			iListLen = list.count;

			for (int i = 0; i < iListLen; i++)
			{
				nav = list.GetPair(i);

				if (Util_NavArea_GetNextEscapeStepIsRecord(nav, fRecordFlow, fNavFlow))
				{
					type = Traverse_ElevatorDown;
					recordNav = nav;
					fRecordFlow = fNavFlow;
				}
			}
		}

		if (type == Traverse_ElevatorDown)
		{
			float fThisHeight = LoadFromAddress(thisNav + view_as<Address>(g_iOffset_NavArea_center + 8), NumberType_Int32);
			float fReturnHeight = LoadFromAddress(recordNav + view_as<Address>(g_iOffset_NavArea_center + 8), NumberType_Int32);

			if (fThisHeight < fReturnHeight) type = Traverse_ElevatorUp;
		}

		SetNativeCellRef(2, type);
		return recordNav;
	}

	public any Native_NavArea_GetZDeltaToArea(Handle hPlugin, int iNumParams)
	{
		Address thisNav = GetNativeCell(1);
		Address externalNav = GetNativeCell(2);

		return Util_NavArea_GetZDeltaAtEdgeToArea(thisNav, externalNav);
	}

	public any Native_NavArea_IsConnected(Handle hPlugin, int iNumParams)
	{
		Address thisNav = GetNativeCell(1);
		Address goalNav = GetNativeCell(2);
		NavDir direction = GetNativeCell(3);

		/** NavDir_All is recognized by this function */
		return SDKCall(g_hSDK_IsConnected, thisNav, goalNav, direction);
	}

	public any Native_NavArea_sizeX_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);

		return Util_NavArea_GetCornerX_Positive(nav) - Util_NavArea_GetCornerX_Negative(nav);
	}

	public any Native_NavArea_sizeY_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);

		return Util_NavArea_GetCornerY_Positive(nav) - Util_NavArea_GetCornerY_Negative(nav);
	}

	public any Native_NavArea_sizeZ_get(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);

		/** set to corner index 0 */
		float fLowest = Util_NavArea_GetCornerZ_NegativeNegative(nav);
		float fHighest = fLowest;
		float fValue;

		for (int i = 1; i < 4; i++)
		{
			switch (i)
			{
				case NavCorner_NegativePositive: fValue = Util_NavArea_GetCornerZ_NegativePositive(nav);
				case NavCorner_PositivePositive: fValue = Util_NavArea_GetCornerZ_PositivePositive(nav);
				case NavCorner_PositiveNegative: fValue = Util_NavArea_GetCornerZ_PositiveNegative(nav);
			}

			if (fValue < fLowest) fLowest = fValue;
			else if (fValue > fHighest) fHighest = fValue;
		}

		return fHighest - fLowest;
	}

	public void Native_NavArea_GetCorner(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));
		NavCorner corner = GetNativeCell(3);

		switch (corner)
		{
			case NavCorner_NegativeNegative:
			{
				vBuffer[0] = Util_NavArea_GetCornerX_Negative(nav);
				vBuffer[1] = Util_NavArea_GetCornerY_Negative(nav);
				vBuffer[2] = Util_NavArea_GetCornerZ_NegativeNegative(nav);
			}
			case NavCorner_NegativePositive:
			{
				vBuffer[0] = Util_NavArea_GetCornerX_Negative(nav);
				vBuffer[1] = Util_NavArea_GetCornerY_Positive(nav);
				vBuffer[2] = Util_NavArea_GetCornerZ_NegativePositive(nav);
			}
			case NavCorner_PositivePositive:
			{
				vBuffer[0] = Util_NavArea_GetCornerX_Positive(nav);
				vBuffer[1] = Util_NavArea_GetCornerY_Positive(nav);
				vBuffer[2] = Util_NavArea_GetCornerZ_PositivePositive(nav);
			}
			case NavCorner_PositiveNegative:
			{
				vBuffer[0] = Util_NavArea_GetCornerX_Positive(nav);
				vBuffer[1] = Util_NavArea_GetCornerY_Negative(nav);
				vBuffer[2] = Util_NavArea_GetCornerZ_PositiveNegative(nav);
			}
		}

		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

	public any Native_NavArea_GetZ(Handle hPlugin, int iNumParams)
	{
		Address nav = GetNativeCell(1);
		float x = GetNativeCell(2);
		float y = GetNativeCell(3);

		return SDKCall(g_hSDK_GetNavAreaZ, nav, x, y);
	}

/** NavAreaSet methodmap */
	public any Native_NavAreaSet_Get(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		int iIndex = GetNativeCell(2);

		return set.Get(iIndex);
	}

	public any Native_NavAreaSet_GetArrayList(Handle hPlugin, int iNumParams)
	{
		ArrayList hArray = new ArrayList();
		CUtlVector set = GetNativeCell(1);

		set.GetArrayList(hArray);
		return hArray;
	}

	public any Native_NavAreaSet_GetArrayListEx(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		ArrayList hArray = GetNativeCell(2);

		return set.GetArrayList(hArray);
	}

	public any Native_NavAreaSet_count_get(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		return set.count;
	}
	public void Native_NavAreaSet_count_set(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		int iNewCount = GetNativeCell(2);

		Util_NavAreaSet_SetCount(set, iNewCount);
	}

	public void Native_NavAreaSet_Clear(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		set.count = 0;
	}

	public any Native_NavAreaSet_Push(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		Address nav = GetNativeCell(2);

		return Util_NavAreaSet_Push(set, nav);
	}

	public void Native_NavAreaSet_Set(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		int iIndex = GetNativeCell(2);
		Address nav = GetNativeCell(3);

		set.Set(iIndex, nav);
	}

	public void Native_NavAreaSet_SetArrayList(Handle hPlugin, int iNumParams)
	{
		CUtlVector navSet = GetNativeCell(1);
		ArrayList hArray = GetNativeCell(2);

		Util_NavAreaSet_SetCount(navSet, hArray.Length);
		Address navList = navSet.list;
		int iCount = navSet.count;

		for (int i = 0; i < iCount; i++)
		{
			StoreToAddress(navList + view_as<Address>(i * 4), hArray.Get(i), NumberType_Int32);
		}
	}

	public void Native_NavAreaSet_Erase(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		int iIndex = GetNativeCell(2);
		int iCount = set.count;

		Address list = set.list;
		Address nav;

		for (int i = iIndex + 1; i < iCount; i++)
		{
			nav = LoadFromAddress(list + view_as<Address>(i * 4), NumberType_Int32);
			StoreToAddress(list + view_as<Address>((i - 1) * 4), nav, NumberType_Int32);
		}

		Util_NavAreaSet_SetCount(set, iCount - 1);
	}

	public any Native_NavAreaSet_Find(Handle hPlugin, int iNumParams)
	{
		CUtlVector set = GetNativeCell(1);
		Address query = GetNativeCell(2);
		int iStartingIndex = GetNativeCell(3);

		int iCount = set.count;
		Address list = set.list;

		Address nav;
		for (int i = iStartingIndex; i < iCount; i++)
		{
			nav = LoadFromAddress(list + view_as<Address>(i * 4), NumberType_Int32);
			if (query == nav)
				return i;
		}

		return -1;
	}

/** Inferno methodmap */
	public any Native_Inferno_entity_get(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		return Util_GetEntityFromAddress(inferno);
	}

	public any Native_Inferno_type_get(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		return LoadFromAddress(inferno + view_as<Address>(g_iOffset_Inferno_type), NumberType_Int32);
	}

	public any Native_Inferno_maxFlames_get(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		return LoadFromAddress(inferno + view_as<Address>(g_iOffset_Inferno_maxFires), NumberType_Int32);
	}
	public void Native_Inferno_maxFlames_set(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		int iValue = GetNativeCell(2);
		StoreToAddress(inferno + view_as<Address>(g_iOffset_Inferno_maxFires), iValue, NumberType_Int32);
	}

	public any Native_Inferno_startTime_get(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		IntervalTimer timer = view_as<IntervalTimer>(inferno + view_as<Address>(g_iOffset_Inferno_startTime));
		return timer.timestamp;
	}

	public void Native_Inferno_GetMins(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, 3);

		LoadVectorFromAddress(inferno + view_as<Address>(
			g_iOffset_Inferno_minBounds), vBuffer);
		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

	public void Native_Inferno_GetMaxs(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, 3);

		LoadVectorFromAddress(inferno + view_as<Address>(
			g_iOffset_Inferno_maxBounds), vBuffer);
		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

	public any Native_Inferno_flameCount_get(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		return Util_Inferno_GetFlameCount(inferno);
	}

	public any Native_Inferno_GetFlame(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		int iIndex = GetNativeCell(2);

		return Util_Inferno_GetFlame(inferno, iIndex);
	}

	public void Native_Inferno_GetOrigin(Handle hPlugin, int iNumParams)
	{
		Address inferno = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));

		LoadVectorFromAddress(inferno + view_as<Address>(g_iOffset_Inferno_Origin), vBuffer);
		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

/** Flame methodmap */
	public any Native_Flame_depth_get(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		return LoadFromAddress(flame + view_as<Address>(g_iOffset_Flame_depth), NumberType_Int32);
	}
	public void Native_Flame_depth_set(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		int iValue = GetNativeCell(2);

		StoreToAddress(flame + view_as<Address>(g_iOffset_Flame_depth), iValue, NumberType_Int32);
	}

	public any Native_Flame_parent_get(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		return LoadFromAddress(flame + view_as<Address>(g_iOffset_Flame_parent), NumberType_Int32);
	}

	public any Native_Flame_spreadDuration_get(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		CountdownTimer timer = Util_Flame_GetSpreadDuration(flame);

		return timer.GetRemaining();
	}
	public any Native_Flame_spreadDuration_set(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		CountdownTimer timer = Util_Flame_GetSpreadDuration(flame);
		float fValue = GetNativeCell(2);

		return timer.Set(fValue);
	}

	public any Native_Flame_lifetime_get(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		CountdownTimer timer = Util_Flame_GetLifetime(flame);

		return timer.GetRemaining();
	}
	public any Native_Flame_lifetime_set(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		CountdownTimer timer = Util_Flame_GetLifetime(flame);
		float fValue = GetNativeCell(2);

		return timer.Set(fValue);
	}

	public void Native_Flame_GetOrigin(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));

		LoadVectorFromAddress(flame + view_as<Address>(g_iOffset_Flame_origin), vBuffer);
		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

	public void Native_Flame_GetDirection(Handle hPlugin, int iNumParams)
	{
		Address flame = GetNativeCell(1);
		float vBuffer[3];
		GetNativeArray(2, vBuffer, sizeof(vBuffer));

		LoadVectorFromAddress(flame + view_as<Address>(g_iOffset_Flame_direction), vBuffer);
		SetNativeArray(2, vBuffer, sizeof(vBuffer));
	}

