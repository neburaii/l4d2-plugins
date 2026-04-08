#pragma newdecls required
#pragma semicolon 1

void InitDetours()
{
	CreateDetour("HX::Intensity::Increase",
		Detour_IntensityIncrease_Pre, Detour_IntensityIncrease_Post,
		{Forward_OnIncreaseSurvivorIntensity, Forward_OnIncreaseSurvivorIntensity_Post, -1});

	CreateDetour("HX::CDirectorScriptedEventManager::OnMapInvokedPanicEventNonVirtual",
		Detour_OnMapInvokedPanicEventNonVirtual_Pre, Detour_OnMapInvokedPanicEventNonVirtual_Post,
		{Forward_OnMapInvokedPanicEvent, Forward_OnMapInvokedPanicEvent_Post, -1});

	CreateDetour("HX::CDirectorScriptedEventManager::StartPanicEvent",
		Detour_OnStartPanicEvent_Pre, Detour_OnStartPanicEvent_Post,
		{Forward_OnStartPanicEvent, Forward_OnStartPanicEvent_Post, -1});

	CreateDetour("HX::CDirector::PostRunScript",
		_, Detour_DirectorPostRunScript_Post,
		{Forward_OnGetDirectorOptions, -1});

	CreateDetour("HX::CDirector::BeginLocalScript",
		Detour_BeginLocalScript_Pre, Detour_BeginLocalScript_Post,
		{Forward_OnBeginLocalScript, Forward_OnBeginLocalScript_Post, -1});

	CreateDetour("HX::CDirector::EndLocalScript",
		Detour_EndLocalScript_Pre, Detour_EndLocalScript_Post,
		{Forward_OnEndLocalScript, Forward_OnEndLocalScript_Post, -1});

	CreateDetour("HX::CFinaleTrigger::StartFinale",
		Detour_StartFinale_Pre, Detour_StartFinale_Post,
		{Forward_OnStartFinale, Forward_OnStartFinale_Post, -1});

	CreateDetour("HX::ZombieManager::GetRandomPZSpawnPosition",
		Detour_GetRandomPZSpawnPosition_Pre, Detour_GetRandomPZSpawnPosition_Post,
		{Forward_OnGetRandomPZSpawnPosition, Forward_OnGetRandomPZSpawnPosition_Override, Forward_OnGetRandomPZSpawnPosition_Post, -1});

	CreateDetour("HX::ZombieManager::CollectSpawnAreas",
		Detour_CollectSpawnAreas_Pre, Detour_CollectSpawnAreas_Post,
		{Forward_OnCollectSpawnAreas, Forward_OnCollectSpawnAreas_Post, -1});

	CreateDetour("HX::CDirector::ResetMobTimer",
		Detour_ResetMobTimer_Pre, Detour_ResetMobTimer_Post,
		{Forward_OnResetMobTimer, Forward_OnResetMobTimer_Post, -1});

	CreateDetour("HX::CDirector::OnMobRushStart",
		Detour_OnMobRushStart_Pre, Detour_OnMobRushStart_Post,
		{Forward_OnStartMobTimer, Forward_OnStartMobTimer_Post, -1});

	CreateDetour("HX::CDirector::ResetSpecialTimers",
		Detour_ResetSpecialTimers_Pre, Detour_ResetSpecialTimers_Post,
		{Forward_OnResetSpecialTimers, Forward_OnResetSpecialTimers_Post, -1});

	CreateDetour("HX::ZombieManager::CanZombieSpawnHere",
		Detour_CanZombieSpawnHere_Pre, Detour_CanZombieSpawnHere_Post,
		{Forward_OnCanZombieSpawnHere, Forward_OnCanZombieSpawnHere_Override, Forward_OnCanZombieSpawnHere_Post, -1});

	CreateDetour("HX::CDirector::UpdateTempo",
		Detour_UpdateTempo_Pre, Detour_UpdateTempo_Post,
		{Forward_OnUpdateTempo, Forward_OnUpdateTempo_Post, -1});

	CreateDetour("HX::TerrorNavMesh::RemoveWanderersInActiveAreaSet",
		Detour_RemoveWanderersInActiveAreaSet_Pre, Detour_RemoveWanderersInActiveAreaSet_Post,
		{Forward_OnSustainPeakPopulationClear, Forward_OnSustainPeakPopulationClear_Post, -1});

	CreateDetour("HX::CTerrorPlayer::GoAwayFromKeyboard",
		Detour_GoAwayFromKeyboard_Pre, Detour_GoAwayFromKeyboard_Post,
		{Forward_OnGoAwayFromKeyboard, Forward_OnGoAwayFromKeyboard_Post, -1});

	CreateDetour("HX::CSpitterProjectile::Create",
		Detour_SpitterProjectileCreate_Pre, Detour_SpitterProjectileCreate_Post,
		{Forward_OnCreateSpitterProjectile, Forward_OnCreateSpitterProjectile_Post, -1});

	CreateDetour("HX::CInferno::CreateFire",
		Detour_CreateFire_Pre, Detour_CreateFire_Post,
		{Forward_OnCreateFlame, Forward_OnCreateFlame_Post, -1});

	CreateDetour("HX::CBasePlayer::SetPunchAngle",
		Detour_SetPunchAngle_Pre, Detour_SetPunchAngle_Post,
		{Forward_OnSetPunchAngle, Forward_OnSetPunchAngle_Post, -1});

	CreateDetour("HX::CTerrorGun::DoViewPunch",
		Detour_GunDoViewPunch_Pre, Detour_GunDoViewPunch_Post,
		{Forward_OnGunViewPunch, Forward_OnGunViewPunch_Post, -1});

	CreateDetour("HX::CInsectSwarm::GetFlameLifetime",
		_, Detour_SpitGetFlameLifetime_Post,
		{Forward_OnGetSpitLifetime_Override, Forward_OnGetSpitLifetime_Post, -1});

	CreateDetour("HX::CBaseServer::ProcessConnectionlessPacket",
		Detour_ProcessConnectionlessPacket_Pre, Detour_ProcessConnectionlessPacket_Post,
		{Forward_OnConnectionlessPacket, Forward_OnConnectionlessPacket_Post, -1});

	CreateDetour("HX::CBaseServer::SetReservationCookie",
		_, Detour_SetReservationCookie_Post,
		{Forward_OnSetReservationCookie_Post, -1});

	CreateDetour("HX::CCSPlayer::ShowMOTD",
		Detour_ShowMOTD_Pre, Detour_ShowMOTD_Post,
		{Forward_OnShowMOTD, Forward_OnShowMOTD_Post, -1});

	CreateDetour("HX::CTerrorPlayer::ShowHostDetails",
		Detour_ShowHostDetails_Pre, Detour_ShowHostDetails_Post,
		{Forward_OnShowHostBanner, Forward_OnShowHostBanner_Post, -1});

	CreateDetour("HX::CBaseServer::GetFreeClientInternal",
		Detour_GetFreeClientInternal_Pre, Detour_GetFreeClientInternal_Post,
		{Forward_OnGetFreeClient, Forward_OnGetFreeClient_Post, -1});
}

/************
 * Callbacks
 ************/

/** OnIncreaseSurvivorIntensity */
	static bool g_bHandled_IntensityIncrease;

	MRESReturn Detour_IntensityIncrease_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		int iClient = GetEntityFromAddress(view_as<Address>(pThis - g_iOffset_Intensity));
		IntensityType type = hParams.Get(1);

		Call_StartForward(g_forward[Forward_OnIncreaseSurvivorIntensity].handle);
		Call_PushCell(iClient);
		Call_PushCellRef(type);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_IntensityIncrease = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.Set(1, type);
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_IntensityIncrease_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		int iClient = GetEntityFromAddress(view_as<Address>(pThis - g_iOffset_Intensity));
		IntensityType type = hParams.Get(1);

		Call_StartForward(g_forward[Forward_OnIncreaseSurvivorIntensity_Post].handle);
		Call_PushCell(iClient);
		Call_PushCell(type);
		Call_PushCell(g_bHandled_IntensityIncrease);
		Call_Finish();

		g_bHandled_IntensityIncrease = false;

		return MRES_Ignored;
	}

/** OnMapInvokedPanicEvent */
	static bool	g_bHandled_OnMapInvokedPanicEvent;

	MRESReturn Detour_OnMapInvokedPanicEventNonVirtual_Pre(DHookReturn hReturn, DHookParam hParams)
	{
		int iActivator = -1;
		if (!hParams.IsNull(1)) iActivator = hParams.Get(1);

		Call_StartForward(g_forward[Forward_OnMapInvokedPanicEvent].handle);
		Call_PushCell(iActivator);
		Call_PushCell(hParams.Get(2));
		Action result = Plugin_Continue;
		Call_Finish(result);

		if(result == Plugin_Handled)
		{
			g_bHandled_OnMapInvokedPanicEvent = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_OnMapInvokedPanicEventNonVirtual_Post(DHookReturn hReturn, DHookParam hParams)
	{
		int iActivator = -1;
		if (!hParams.IsNull(1)) iActivator = hParams.Get(1);

		Call_StartForward(g_forward[Forward_OnMapInvokedPanicEvent_Post].handle);
		Call_PushCell(iActivator);
		Call_PushCell(hParams.Get(2));
		Call_PushCell(g_bHandled_OnMapInvokedPanicEvent);
		Call_Finish();

		g_bHandled_OnMapInvokedPanicEvent = false;

		return MRES_Ignored;
	}

/** OnStartPanicEvent */
	static bool g_bHandled_StartPanicEvent;
	static bool g_bChanged_StartPanicEvent;
	static int g_iStartPanicEventWaves;
	static bool g_bStartPanicEventCrescendo;

	MRESReturn Detour_OnStartPanicEvent_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		bool bDefaultWaves = false;
		bool bCrescendo = false;
		int iWaves = hParams.Get(1);

		if (!Util_HasCrescendoOccurred()
			&& Util_AreSurvivorsInBattlefieldOrFinale() == true
			&& (!Util_AllowChallengeModeScriptVariables() || Util_GetScriptValueInt("AllowCrescendoEvents", 1)))
				bCrescendo = true;

		if (iWaves == 0)
		{
			bDefaultWaves = true;

			if (bCrescendo && Util_GetMapArcValue() > 1)
				iWaves = 2;
			else
				iWaves = 1;
		}

		int iActivator = -1;
		if (!hParams.IsNull(2)) iActivator = hParams.Get(2);

		g_iStartPanicEventWaves = iWaves;
		g_bStartPanicEventCrescendo = bCrescendo;

		Call_StartForward(g_forward[Forward_OnStartPanicEvent].handle);
		Call_PushCell(iActivator);
		Call_PushCellRef(bCrescendo);
		Call_PushCellRef(iWaves);
		Call_PushCell(bDefaultWaves);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_StartPanicEvent = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			g_bChanged_StartPanicEvent = true;
			hParams.Set(1, iWaves);
			g_bStartPanicEventCrescendo = bCrescendo;
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_OnStartPanicEvent_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		bool bDefaultWaves = hParams.Get(1) == 0;

		int iWaves;
		if (g_bHandled_StartPanicEvent) iWaves = g_iStartPanicEventWaves;
		else iWaves = GetTotalPanicWaves();

		bool bCrescendo = g_bStartPanicEventCrescendo;
		if (!g_bHandled_StartPanicEvent)
		{
			if (g_bChanged_StartPanicEvent) SetCrescendo(bCrescendo);
			else bCrescendo = IsCrescendo();
		}

		int iActivator = -1;
		if (!hParams.IsNull(2)) iActivator = hParams.Get(2);

		Call_StartForward(g_forward[Forward_OnStartPanicEvent_Post].handle);
		Call_PushCell(iActivator);
		Call_PushCell(bCrescendo);
		Call_PushCell(iWaves);
		Call_PushCell(bDefaultWaves);
		Call_PushCell(g_bHandled_StartPanicEvent);
		Call_Finish();

		g_bHandled_StartPanicEvent = false;
		g_bChanged_StartPanicEvent = false;

		return MRES_Ignored;
	}

/** OnGetDirectorOptions */
	MRESReturn Detour_DirectorPostRunScript_Post()
	{
		Call_StartForward(g_forward[Forward_OnGetDirectorOptions].handle);
		Call_Finish();

		return MRES_Ignored;
	}

/** OnBeginLocalScript */
	static bool g_bHandled_BeginLocalScript;

	MRESReturn Detour_BeginLocalScript_Pre(DHookReturn hReturn, DHookParam hParams)
	{
		static char sBuffer[1024];
		hParams.GetString(1, sBuffer, sizeof(sBuffer));

		Call_StartForward(g_forward[Forward_OnBeginLocalScript].handle);
		Call_PushStringEx(sBuffer, sizeof(sBuffer), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_BeginLocalScript = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.SetString(1, sBuffer);
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_BeginLocalScript_Post(DHookReturn hReturn, DHookParam hParams)
	{
		static char sBuffer[1024];
		hParams.GetString(1, sBuffer, sizeof(sBuffer));

		Call_StartForward(g_forward[Forward_OnBeginLocalScript_Post].handle);
		Call_PushString(sBuffer);
		Call_PushCell(g_bHandled_BeginLocalScript);
		Call_Finish();

		g_bHandled_BeginLocalScript = false;

		return MRES_Ignored;
	}

/** OnEndLocalScript */
	static bool g_bHandled_EndLocalScript;

	MRESReturn Detour_EndLocalScript_Pre(DHookParam hParams)
	{
		Call_StartForward(g_forward[Forward_OnEndLocalScript].handle);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_EndLocalScript = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_EndLocalScript_Post(DHookParam hParams)
	{
		Call_StartForward(g_forward[Forward_OnEndLocalScript_Post].handle);
		Call_PushCell(g_bHandled_EndLocalScript);
		Call_Finish();

		g_bHandled_EndLocalScript = false;

		return MRES_Ignored;
	}

/** OnStartFinale */
	static bool g_bHandled_StartFinale;

	MRESReturn Detour_StartFinale_Pre(int pThis, DHookParam hParams)
	{
		int iActivator = -1;
		if (!hParams.IsNull(1)) iActivator = hParams.Get(1);

		FinaleType type = LoadFromAddress(view_as<Address>(pThis +
			g_iOffset_FinaleTrigger_FinaleType), NumberType_Int32);

		Call_StartForward(g_forward[Forward_OnStartFinale].handle);
		Call_PushCell(iActivator);
		Call_PushCell(type);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_StartFinale = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_StartFinale_Post(int pThis, DHookParam hParams)
	{
		int iActivator = -1;
		if (!hParams.IsNull(1)) iActivator = hParams.Get(1);

		FinaleType type = LoadFromAddress(g_pDirectorScriptedEventManager +
			view_as<Address>(g_iOffset_ScriptedEventManager_FinaleType), NumberType_Int32);

		Call_StartForward(g_forward[Forward_OnStartFinale_Post].handle);
		Call_PushCell(iActivator);
		Call_PushCell(type);
		Call_PushCell(g_bHandled_StartFinale);
		Call_Finish();

		g_bHandled_StartFinale = false;

		return MRES_Ignored;
	}

/** OnGetRandomPZSpawnPosition */
	static bool g_bHandled_GetRandomPZSpawnPosition;

	MRESReturn Detour_GetRandomPZSpawnPosition_Pre(DHookReturn hReturn, DHookParam hParams)
	{
		ZombieClass zClass = hParams.Get(1);
		int iTries = hParams.Get(2);
		int iGhost = -1;
		if (!hParams.IsNull(3)) iGhost = hParams.Get(3);

		Call_StartForward(g_forward[Forward_OnGetRandomPZSpawnPosition].handle);
		Call_PushCellRef(zClass);
		Call_PushCellRef(iTries);
		Call_PushCell(iGhost);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_GetRandomPZSpawnPosition = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.Set(1, zClass);
			hParams.Set(2, iTries);

			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_GetRandomPZSpawnPosition_Post(DHookReturn hReturn, DHookParam hParams)
	{
		/** prepare params */
		ZombieClass zClass = hParams.Get(1);
		int iTries = hParams.Get(2);
		int iGhost = -1;
		if (!hParams.IsNull(3)) iGhost = hParams.Get(3);

		Address pVector = hParams.Get(4);
		float vPos[3];
		bool bSuccess = !!hReturn.Value;
		if (bSuccess)
			LoadVectorFromAddress(pVector, vPos);

		Action result = Plugin_Continue;

		/** OnSetRandomPZSpawnPosition */
		if (!g_bHandled_GetRandomPZSpawnPosition)
		{
			float vNewPos[sizeof(vPos)];
			for (int i = 0; i < sizeof(vPos); i++)
				vNewPos[i] = vPos[i];
			bool bNewSuccess = bSuccess;

			Call_StartForward(g_forward[Forward_OnGetRandomPZSpawnPosition_Override].handle);
			Call_PushCell(zClass);
			Call_PushCell(iTries);
			Call_PushCell(iGhost);
			Call_PushArrayEx(vNewPos, sizeof(vNewPos), SM_PARAM_COPYBACK);
			Call_PushCellRef(bNewSuccess);
			Call_Finish(result);

			if (result == Plugin_Handled || result == Plugin_Changed)
			{
				if (result == Plugin_Handled)
					bNewSuccess = false;

				if (bSuccess && !bNewSuccess)
				{
					for (int i = 0; i < sizeof(vPos); i++)
						vPos[i] = 0.0;
				}
				else if (result == Plugin_Changed)
					vPos = vNewPos;

				bSuccess = bNewSuccess;
			}
		}

		/** OnGetRandomPZSpawnPosition_Post */
		Call_StartForward(g_forward[Forward_OnGetRandomPZSpawnPosition_Post].handle);
		Call_PushCell(zClass);
		Call_PushCell(iTries);
		Call_PushCell(iGhost);
		Call_PushArray(vPos, sizeof(vPos));
		Call_PushCell(bSuccess);
		Call_PushCell(g_bHandled_GetRandomPZSpawnPosition);
		Call_Finish();

		g_bHandled_GetRandomPZSpawnPosition = false;

		/** result from OnSetRandomPZSpawnPosition */
		if (result == Plugin_Handled)
		{
			hReturn.Value = 0;
			return MRES_Override;
		}

		if (result == Plugin_Changed)
		{
			hReturn.Value = bSuccess ? 1 : 0;
			if (bSuccess) StoreVectorToAddress(pVector, vPos);
			return MRES_Override;
		}

		return MRES_Ignored;
	}

/** OnCollectSpawnAreas */
	static bool g_bHandled_CollectSpawnAreas;

	MRESReturn Detour_CollectSpawnAreas_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		LocationType location = hParams.Get(1);
		ZombieClass class = hParams.Get(2);

		Call_StartForward(g_forward[Forward_OnCollectSpawnAreas].handle);
		Call_PushCellRef(location);
		Call_PushCellRef(class);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_CollectSpawnAreas = true;

			/** code calling this expects a valid address to be returned */
			NavAreaSet set = view_as<NavAreaSet>(
				pThis + g_iOffset_ZombieManager_SpawnAreaSets
				+ (view_as<int>(location) * CUTLVECTOR_STRUCT_SIZE));

			set.Clear();
			hReturn.Value = set;

			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.Set(1, location);
			hParams.Set(2, class);

			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_CollectSpawnAreas_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		LocationType location = hParams.Get(1);
		ZombieClass class = hParams.Get(2);
		NavAreaSet set = hReturn.Value;

		Call_StartForward(g_forward[Forward_OnCollectSpawnAreas_Post].handle);
		Call_PushCell(location);
		Call_PushCell(class);
		Call_PushCell(set);
		Call_PushCell(g_bHandled_CollectSpawnAreas);
		Call_Finish();

		g_bHandled_CollectSpawnAreas = false;
		return MRES_Ignored;
	}

/** OnResetMobTimer */
	static bool g_bHandled_ResetMobTimer;

	MRESReturn Detour_ResetMobTimer_Pre()
	{
		Call_StartForward(g_forward[Forward_OnResetMobTimer].handle);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_ResetMobTimer = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_ResetMobTimer_Post()
	{
		Call_StartForward(g_forward[Forward_OnResetMobTimer_Post].handle);
		Call_PushCell(g_bHandled_ResetMobTimer);
		Call_Finish();

		g_bHandled_ResetMobTimer = false;
		return MRES_Ignored;
	}

/** OnStartMobTimer */
	static bool g_bHandled_StartMobTimer;

	MRESReturn Detour_OnMobRushStart_Pre()
	{
		Call_StartForward(g_forward[Forward_OnStartMobTimer].handle);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_StartMobTimer = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_OnMobRushStart_Post()
	{
		float fTime = -1.0;
		Action result = Plugin_Continue;

		if (!g_bHandled_StartMobTimer)
		{
			fTime = g_MobTimer.time;
			float fNewTime = fTime;

			Call_StartForward(g_forward[Forward_OnStartMobTimer_Override].handle);
			Call_PushCellRef(fNewTime);
			Call_Finish(result);

			if (result == Plugin_Handled || result == Plugin_Changed)
			{
				if (result == Plugin_Handled)
					fNewTime = -1.0;

				g_MobTimer.Set(fNewTime);
				fTime = fNewTime;
			}
		}

		Call_StartForward(g_forward[Forward_OnStartMobTimer_Post].handle);
		Call_PushCell(fTime);
		Call_PushCell(g_bHandled_StartMobTimer);
		Call_Finish();

		g_bHandled_StartMobTimer = false;
		return MRES_Ignored;
	}

/** OnResetSpecialTimers */
	static bool g_bHandled_ResetSpecialTimers;

	MRESReturn Detour_ResetSpecialTimers_Pre()
	{
		Call_StartForward(g_forward[Forward_OnResetSpecialTimers].handle);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_ResetSpecialTimers = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_ResetSpecialTimers_Post()
	{
		Call_StartForward(g_forward[Forward_OnResetSpecialTimers_Post].handle);
		Call_PushCell(g_bHandled_ResetSpecialTimers);
		Call_Finish();

		g_bHandled_ResetSpecialTimers = false;
		return MRES_Ignored;
	}

/** OnCanZombieSpawnHere */
	static bool g_bHandled_CanZombieSpawnHere;

	MRESReturn Detour_CanZombieSpawnHere_Pre(DHookReturn hReturn, DHookParam hParams)
	{
		float vPos[3];
		hParams.GetVector(1, vPos);
		Address nav = hParams.Get(2);
		ZombieClass class = hParams.Get(3);
		int iGhost = 0;
		if (!hParams.IsNull(5)) hParams.Get(5);

		Call_StartForward(g_forward[Forward_OnCanZombieSpawnHere].handle);
		Call_PushArray(vPos, sizeof(vPos));
		Call_PushCell(nav);
		Call_PushCell(class);
		Call_PushCell(iGhost);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_CanZombieSpawnHere = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_CanZombieSpawnHere_Post(DHookReturn hReturn, DHookParam hParams)
	{
		float vPos[3];
		hParams.GetVector(1, vPos);
		Address nav = hParams.Get(2);
		ZombieClass class = hParams.Get(3);
		int iGhost = 0;
		if (!hParams.IsNull(5)) hParams.Get(5);

		bool bSuccess = hReturn.Value;
		Action result = Plugin_Continue;

		if (!g_bHandled_CanZombieSpawnHere)
		{
			bool bNewSuccess = bSuccess;

			Call_StartForward(g_forward[Forward_OnCanZombieSpawnHere_Override].handle);
			Call_PushArray(vPos, sizeof(vPos));
			Call_PushCell(nav);
			Call_PushCell(class);
			Call_PushCell(iGhost);
			Call_PushCellRef(bNewSuccess);
			Call_Finish(result);

			if (result == Plugin_Handled || result == Plugin_Changed)
			{
				if (result == Plugin_Handled)
					bNewSuccess = false;

				bSuccess = bNewSuccess;
			}
		}

		Call_StartForward(g_forward[Forward_OnCanZombieSpawnHere_Post].handle);
		Call_PushArray(vPos, sizeof(vPos));
		Call_PushCell(nav);
		Call_PushCell(class);
		Call_PushCell(iGhost);
		Call_PushCell(bSuccess);
		Call_PushCell(g_bHandled_CanZombieSpawnHere);
		Call_Finish();

		g_bHandled_CanZombieSpawnHere = false;

		if (result != Plugin_Continue)
		{
			hReturn.Value = bSuccess;
			return MRES_Override;
		}

		return MRES_Ignored;
	}

/** OnUpdateTempo */
	static bool g_bHandled_UpdateTempo;
	static DirectorTempo g_iUpdateTempo_OldValue;

	MRESReturn Detour_UpdateTempo_Pre()
	{
		g_iUpdateTempo_OldValue = Util_GetTempo();

		Call_StartForward(g_forward[Forward_OnUpdateTempo].handle);
		Call_PushCell(g_iUpdateTempo_OldValue);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_UpdateTempo = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_UpdateTempo_Post()
	{
		DirectorTempo newValue = Util_GetTempo();

		Call_StartForward(g_forward[Forward_OnUpdateTempo_Post].handle);
		Call_PushCell(g_iUpdateTempo_OldValue);
		Call_PushCell(newValue);
		Call_PushCell(g_bHandled_UpdateTempo);
		Call_Finish();

		g_bHandled_UpdateTempo = false;
		return MRES_Ignored;
	}

/** OnRemoveWanderersInActiveAreaSet */
	static bool g_bHandled_RemoveWanderersInActiveAreaSet;

	MRESReturn Detour_RemoveWanderersInActiveAreaSet_Pre()
	{
		Call_StartForward(g_forward[Forward_OnSustainPeakPopulationClear].handle);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_RemoveWanderersInActiveAreaSet = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_RemoveWanderersInActiveAreaSet_Post()
	{
		Call_StartForward(g_forward[Forward_OnSustainPeakPopulationClear_Post].handle);
		Call_PushCell(g_bHandled_RemoveWanderersInActiveAreaSet);
		Call_Finish();

		g_bHandled_RemoveWanderersInActiveAreaSet = false;
		return MRES_Ignored;
	}

/** OnGoAwayFromKeyboard */
	static bool g_bHandled_GoAwayFromKeyboard;
	bool		g_bBlockUM_GoAwayFromKeyboard;

	MRESReturn Detour_GoAwayFromKeyboard_Pre(int pThis)
	{
		Call_StartForward(g_forward[Forward_OnGoAwayFromKeyboard].handle);
		Call_PushCell(pThis);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_GoAwayFromKeyboard = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_GoAwayFromKeyboard_Post(int pThis)
	{
		if (!g_bHandled_GoAwayFromKeyboard && !g_bBlockUM_GoAwayFromKeyboard)
		{
			g_bAllowUM_OnGoAwayFromKeyboard = true;
			Util_SendAFKUserMessage(pThis);
			g_bAllowUM_OnGoAwayFromKeyboard = false;
		}

		Call_StartForward(g_forward[Forward_OnGoAwayFromKeyboard_Post].handle);
		Call_PushCell(pThis);
		Call_PushCell(g_bHandled_GoAwayFromKeyboard);
		Call_Finish();

		g_bHandled_GoAwayFromKeyboard = false;
		return MRES_Ignored;
	}

/** OnCreateSpitterProjectile */
	static bool g_bHandled_SpitterProjectileCreate;

	MRESReturn Detour_SpitterProjectileCreate_Pre(DHookReturn hReturn, DHookParam hParams)
	{
		int iSpitter = 0;
		if (!hParams.IsNull(5)) iSpitter = hParams.Get(5);

		float vOrigin[3];
		float vAngles[3];
		float vVelocity[3];
		float vRotation[3];

		hParams.GetVector(1, vOrigin);
		hParams.GetVector(2, vAngles);
		hParams.GetVector(3, vVelocity);
		hParams.GetVector(4, vRotation);

		Call_StartForward(g_forward[Forward_OnCreateSpitterProjectile].handle);
		Call_PushCell(iSpitter);
		Call_PushArrayEx(vOrigin, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(vAngles, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(vVelocity, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(vRotation, 3, SM_PARAM_COPYBACK);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_SpitterProjectileCreate = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.SetVector(1, vOrigin);
			hParams.SetVector(2, vAngles);
			hParams.SetVector(3, vVelocity);
			hParams.SetVector(4, vRotation);
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_SpitterProjectileCreate_Post(DHookReturn hReturn, DHookParam hParams)
	{
		int iSpitter = 0;
		if (!hParams.IsNull(5)) iSpitter = hParams.Get(5);
		int iProjectile = hReturn.Value;

		float vOrigin[3];
		float vAngles[3];
		float vVelocity[3];
		float vRotation[3];

		hParams.GetVector(1, vOrigin);
		hParams.GetVector(2, vAngles);
		hParams.GetVector(3, vVelocity);
		hParams.GetVector(4, vRotation);

		Call_StartForward(g_forward[Forward_OnCreateSpitterProjectile_Post].handle);
		Call_PushCell(iSpitter);
		Call_PushCell(iProjectile);
		Call_PushArray(vOrigin, 3);
		Call_PushArray(vAngles, 3);
		Call_PushArray(vVelocity, 3);
		Call_PushArray(vRotation, 3);
		Call_PushCell(g_bHandled_SpitterProjectileCreate);
		Call_Finish();

		g_bHandled_SpitterProjectileCreate = false;
		return MRES_Ignored;
	}

/** OnCreateFlame */
	static bool g_bHandled_CreateFire;

	MRESReturn Detour_CreateFire_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		float vOrigin[3], vDirection[3];
		hParams.GetVector(1, vOrigin);
		hParams.GetVector(2, vDirection);
		Address parentFlame = hParams.Get(3);
		int iDepth = hParams.Get(4);

		Call_StartForward(g_forward[Forward_OnCreateFlame].handle);
		Call_PushCell(pThis);
		Call_PushArrayEx(vOrigin, sizeof(vOrigin), SM_PARAM_COPYBACK);
		Call_PushArrayEx(vDirection, sizeof(vDirection), SM_PARAM_COPYBACK);
		Call_PushCell(parentFlame);
		Call_PushCellRef(iDepth);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_CreateFire = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.SetVector(1, vOrigin);
			hParams.SetVector(2, vDirection);
			hParams.Set(4, iDepth);
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_CreateFire_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		float vOrigin[3], vDirection[3];
		hParams.GetVector(1, vOrigin);
		hParams.GetVector(2, vDirection);
		Address parentFlame = hParams.Get(3);
		int iDepth = hParams.Get(4);
		bool bSuccess = hReturn.Value;

		Address inferno = view_as<Address>(pThis);
		Address flame = Address_Null;

		if (bSuccess)
		{
			int iIndex = Util_Inferno_GetFlameCount(inferno) - 1;
			if (iIndex >= 0) flame = Util_Inferno_GetFlame(inferno, iIndex);
		}

		Call_StartForward(g_forward[Forward_OnCreateFlame_Post].handle);
		Call_PushCell(inferno);
		Call_PushCell(flame);
		Call_PushArray(vOrigin, sizeof(vOrigin));
		Call_PushArray(vDirection, sizeof(vDirection));
		Call_PushCell(parentFlame);
		Call_PushCell(iDepth);
		Call_PushCell(bSuccess);
		Call_PushCell(g_bHandled_CreateFire);
		Call_Finish();

		g_bHandled_CreateFire = false;
		return MRES_Ignored;
	}

/** OnSetPunchAngle */
	static bool g_bHandled_SetPunchAngle;

	MRESReturn Detour_SetPunchAngle_Pre(int pThis, DHookParam hParams)
	{
		float vAngle[3];
		hParams.GetVector(1, vAngle);

		Call_StartForward(g_forward[Forward_OnSetPunchAngle].handle);
		Call_PushCell(pThis);
		Call_PushArrayEx(vAngle, sizeof(vAngle), SM_PARAM_COPYBACK);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_SetPunchAngle = true;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.SetVector(1, vAngle);
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_SetPunchAngle_Post(int pThis, DHookParam hParams)
	{
		float vAngle[3];
		hParams.GetVector(1, vAngle);

		Call_StartForward(g_forward[Forward_OnSetPunchAngle_Post].handle);
		Call_PushCell(pThis);
		Call_PushArray(vAngle, sizeof(vAngle));
		Call_PushCell(g_bHandled_SetPunchAngle);
		Call_Finish();

		g_bHandled_SetPunchAngle = false;
		return MRES_Ignored;
	}

/** OnGunViewPunch */
	static bool g_bHandled_GunDoViewPunch;

	MRESReturn Detour_GunDoViewPunch_Pre(int pThis, DHookParam hParams)
	{
		int iClient = hParams.Get(1);

		Call_StartForward(g_forward[Forward_OnGunViewPunch].handle);
		Call_PushCell(pThis);
		Call_PushCell(iClient);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_GunDoViewPunch = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_GunDoViewPunch_Post(int pThis, DHookParam hParams)
	{
		int iClient = hParams.Get(1);

		Call_StartForward(g_forward[Forward_OnGunViewPunch_Post].handle);
		Call_PushCell(pThis);
		Call_PushCell(iClient);
		Call_PushCell(g_bHandled_GunDoViewPunch);
		Call_Finish();

		g_bHandled_GunDoViewPunch = false;
		return MRES_Ignored;
	}

/** OnGetSpitLifetime */
	MRESReturn Detour_SpitGetFlameLifetime_Post(int pThis, DHookReturn hReturn)
	{
		float fRet = hReturn.Value;
		float fNewRet = fRet;
		MRESReturn mres = MRES_Ignored;

		Call_StartForward(g_forward[Forward_OnGetSpitLifetime_Override].handle);
		Call_PushCell(pThis);
		Call_PushCellRef(fNewRet);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled || result == Plugin_Changed)
		{
			if (result == Plugin_Handled) fNewRet = 0.0;
			fRet = fNewRet;

			hReturn.Value = fRet;
			mres = MRES_Override;
		}

		Call_StartForward(g_forward[Forward_OnGetSpitLifetime_Post].handle);
		Call_PushCell(pThis);
		Call_PushCell(fRet);
		Call_Finish();

		return mres;
	}

/** OnConnectionlessPacket */
	static bool g_bHandled_ProcessConnectionlessPacket;

	MRESReturn Detour_ProcessConnectionlessPacket_Pre(DHookReturn hReturn, DHookParam hParams)
	{
		Address netpacket = hParams.Get(1);
		Address netadr = netpacket + view_as<Address>(g_iOffset_NetPacket_adr);
		Address bf = netpacket + view_as<Address>(g_iOffset_NetPacket_bf);
		Address packetData = LoadFromAddress(netpacket + view_as<Address>(g_iOffset_NetPacket_packet), NumberType_Int32);

		int iIP = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_ipv4), NumberType_Int32);

		/** big endian short. load it in reverse */
		int iPort = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 1), NumberType_Int8);
		iPort |= (LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 0), NumberType_Int8) << 8);

		NetAdrType adrType = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_type), NumberType_Int32);
		int iPacketType = LoadFromAddress(bf + view_as<Address>(g_iOffset_BfRead_info), NumberType_Int8);
		int iPacketSize = LoadFromAddress(bf + view_as<Address>(g_iOffset_BfRead_bytesLeft), NumberType_Int32);

		any[] packet = new any[iPacketSize];
		for (int i = 0; i < iPacketSize; i++)
			packet[i] = LoadFromAddress(packetData + view_as<Address>(i), NumberType_Int8);

		Call_StartForward(g_forward[Forward_OnConnectionlessPacket].handle);
		Call_PushCell(adrType);
		Call_PushCell(iIP);
		Call_PushCell(iPort);
		Call_PushCell(iPacketType);
		Call_PushArray(packet, iPacketSize);
		Call_PushCell(iPacketSize);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_ProcessConnectionlessPacket = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_ProcessConnectionlessPacket_Post(DHookReturn hReturn, DHookParam hParams)
	{
		Address netpacket = hParams.Get(1);
		Address netadr = netpacket + view_as<Address>(g_iOffset_NetPacket_adr);
		Address bf = netpacket + view_as<Address>(g_iOffset_NetPacket_bf);
		Address packetData = LoadFromAddress(netpacket + view_as<Address>(g_iOffset_NetPacket_packet), NumberType_Int32);

		int iIP = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_ipv4), NumberType_Int32);

		/** big endian short. load it in reverse */
		int iPort = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 1), NumberType_Int8);
		iPort |= (LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 0), NumberType_Int8) << 8);

		NetAdrType adrType = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_type), NumberType_Int32);
		int iPacketType = LoadFromAddress(bf + view_as<Address>(g_iOffset_BfRead_info), NumberType_Int8);
		int iPacketSize = LoadFromAddress(bf + view_as<Address>(g_iOffset_BfRead_bytesLeft), NumberType_Int32);

		any[] packet = new any[iPacketSize];
		for (int i = 0; i < iPacketSize; i++)
			packet[i] = LoadFromAddress(packetData + view_as<Address>(i), NumberType_Int8);

		Call_StartForward(g_forward[Forward_OnConnectionlessPacket_Post].handle);
		Call_PushCell(adrType);
		Call_PushCell(iIP);
		Call_PushCell(iPort);
		Call_PushCell(iPacketType);
		Call_PushArray(packet, iPacketSize);
		Call_PushCell(iPacketSize);
		Call_PushCell(g_bHandled_ProcessConnectionlessPacket);
		Call_Finish();

		g_bHandled_ProcessConnectionlessPacket = false;
		return MRES_Ignored;
	}

/** OnGetFreeClient */
	static bool g_bHandled_GetFreeClientInternal;

	MRESReturn Detour_GetFreeClientInternal_Pre(DHookReturn hReturn, DHookParam hParams)
	{
		Address netadr = hParams.Get(1);

		int iIP = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_ipv4), NumberType_Int32);

		/** big endian short. load it in reverse */
		int iPort = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 1), NumberType_Int8);
		iPort |= (LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 0), NumberType_Int8) << 8);

		NetAdrType adrType = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_type), NumberType_Int32);

		Call_StartForward(g_forward[Forward_OnGetFreeClient].handle);
		Call_PushCell(adrType);
		Call_PushCell(iIP);
		Call_PushCell(iPort);
		Action result = Plugin_Continue;
		Call_Finish();

		if (result == Plugin_Handled)
		{
			g_bHandled_GetFreeClientInternal = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_GetFreeClientInternal_Post(DHookReturn hReturn, DHookParam hParams)
	{
		Address netadr = hParams.Get(1);

		int iIP = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_ipv4), NumberType_Int32);

		/** big endian short. load it in reverse */
		int iPort = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 1), NumberType_Int8);
		iPort |= (LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_port + 0), NumberType_Int8) << 8);

		NetAdrType adrType = LoadFromAddress(netadr + view_as<Address>(g_iOffset_NetAdr_type), NumberType_Int32);

		int iClient = hReturn.Value;
		if (iClient) // not a fully initialized edict at this time, but we can get the index this way
			iClient = LoadFromAddress(view_as<Address>(iClient + g_iOffset_ClientIndex), NumberType_Int32);
		else
			iClient = -1;

		Call_StartForward(g_forward[Forward_OnGetFreeClient_Post].handle);
		Call_PushCell(adrType);
		Call_PushCell(iIP);
		Call_PushCell(iPort);
		Call_PushCell(iClient);
		Call_PushCell(g_bHandled_GetFreeClientInternal);
		Call_Finish();

		g_bHandled_GetFreeClientInternal = false;

		return MRES_Ignored;
	}

/** OnSetReservationCookie */
	MRESReturn Detour_SetReservationCookie_Post(DHookParam hParams)
	{
		int iCookie[2];
		iCookie[0] = hParams.Get(1);
		iCookie[1] = hParams.Get(2);

		/** scrapped because i don't feel like figuring out what to do with the variable format args,
		 * and none of my plugins care for these params */
		// static char sReason[128];
		// hParams.GetString(3, sReason, sizeof(sReason));

		Call_StartForward(g_forward[Forward_OnSetReservationCookie_Post].handle);
		Call_PushArray(iCookie, sizeof(iCookie));
		// Call_PushString(sReason);
		Call_Finish();

		return MRES_Ignored;
	}

/** OnShowMOTD */
	static bool g_bHandled_ShowMOTD;

	MRESReturn Detour_ShowMOTD_Pre(int pThis)
	{
		Call_StartForward(g_forward[Forward_OnShowMOTD].handle);
		Call_PushCell(pThis);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_ShowMOTD = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_ShowMOTD_Post(int pThis)
	{
		Call_StartForward(g_forward[Forward_OnShowMOTD_Post].handle);
		Call_PushCell(pThis);
		Call_PushCell(g_bHandled_ShowMOTD);
		Call_Finish();

		g_bHandled_ShowMOTD = false;
		return MRES_Ignored;
	}

/** OnShowHostBanner */
	static bool g_bHandled_ShowHostDetails;

	MRESReturn Detour_ShowHostDetails_Pre(int pThis)
	{
		Call_StartForward(g_forward[Forward_OnShowHostBanner].handle);
		Call_PushCell(pThis);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_ShowHostDetails = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn Detour_ShowHostDetails_Post(int pThis)
	{
		Call_StartForward(g_forward[Forward_OnShowHostBanner_Post].handle);
		Call_PushCell(pThis);
		Call_PushCell(g_bHandled_ShowHostDetails);
		Call_Finish();

		g_bHandled_ShowHostDetails = false;
		return MRES_Ignored;
	}
