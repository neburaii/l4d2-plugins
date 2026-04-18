#pragma newdecls required
#pragma semicolon 1

/** 1.3 - reorganized members/functions belonging to director and its
 * componenets to these methodmaps, as they were annoyingly cluttered before */

methodmap Director < Address
{
	property int numReservedWanderers
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
					g_iOffset_Director_NumReservedWanderers), NumberType_Int32);
		}
		public set(int value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_Director_NumReservedWanderers), value, NumberType_Int32);
		}
	}

	property bool hasAnySurvivorLeftSafeArea
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_Director_SurvivorsLeftSafeArea), NumberType_Int8);
		}
	}

	property DirectorTempo tempo
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_Director_Tempo), NumberType_Int32);
		}
		public set(DirectorTempo value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_Director_Tempo), value, NumberType_Int32);
		}
	}

	property float mobRechargeSize
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_Director_NextMobSize), NumberType_Int32);
		}
		public set(float value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_Director_NextMobSize), value, NumberType_Int32);
		}
	}

	property float mobRechargeScaler
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_Director_MobRechargeProgress), NumberType_Int32);
		}
		public set(float value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_Director_MobRechargeProgress), value, NumberType_Int32);
		}
	}

	property float relaxStartFlow
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_Director_RelaxStartFlow), NumberType_Int32);
		}
		public set(float value)
		{
			StoreToAddress(this + view_as<Address>(g_iOffset_Director_RelaxStartFlow),
				value, NumberType_Int32);
		}
	}

	public void RenewRelaxStartFlow()
	{
		float fFlow;
		int iHighestPlayer = Util_GetHighestFlowSurvivor(FlowType_Progress);

		if (!iHighestPlayer) fFlow = NULL_FLOW;
		else fFlow = Util_GetPlayerFlow(iHighestPlayer, FlowType_Progress);

		StoreToAddress(this + view_as<Address>(g_iOffset_Director_RelaxStartFlow),
			fFlow, NumberType_Int32);
	}

	public int GetMapArcValue()
	{
		return SDKCall(g_hSDK_GetMapArcValue, this);
	}

	public int GetScriptValueInt(const char[] scriptVar, int defaultValue)
	{
		return SDKCall(g_hSDK_GetScriptValueInt, this, scriptVar, defaultValue);
	}

	public float GetScriptValueFloat(const char[] scriptVar, float defaultValue)
	{
		return SDKCall(g_hSDK_GetScriptValueFloat, this, scriptVar, defaultValue);
	}

	public bool ShouldLockTempo()
	{
		return SDKCall(g_hSDK_ShouldLockTempo, this);
	}

	public void StartMobTimer()
	{
		SDKCall(g_hSDK_OnMobRushStart, this);
	}

	public void ResetMobTimer()
	{
		SDKCall(g_hSDK_ResetMobTimer, this);
	}

	public void ResetSpecialTimers()
	{
		SDKCall(g_hSDK_ResetSpecialTimers, this);
	}

	public void BeginLocalScript(const char[] script)
	{
		SDKCall(g_hSDK_BeginLocalScript, this, script);
	}

	public void EndLocalScript()
	{
		SDKCall(g_hSDK_EndLocalScript, this);
	}

	public bool IsInTransition()
	{
		return SDKCall(g_hSDK_IsInTransition, this);
	}
}

methodmap ScriptedEventManager < Address
{
	property bool crescendoOccurred
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_CrescendoOccured), NumberType_Int8);
		}
		public set(bool value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_CrescendoOccured), value, NumberType_Int8);
		}
	}

	property bool crescendoOngoing
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_CrescendoOngoing), NumberType_Int8);
		}
		public set(bool value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_CrescendoOngoing), value, NumberType_Int8);
		}
	}

	property int completedPanicWaves
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_CompletedPanicWaves), NumberType_Int32);
		}
		public set(int value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_CompletedPanicWaves), value, NumberType_Int32);
		}
	}

	property int totalPanicWaves
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_TotalPanicWaves), NumberType_Int32);
		}
		public set(int value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_TotalPanicWaves), value, NumberType_Int32);
		}
	}

	property FinaleType finaleType
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_FinaleType), NumberType_Int32);
		}
		public set(FinaleType value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_FinaleType), value, NumberType_Int32);
		}
	}

	property PanicStage panicStage
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_PanicStage), NumberType_Int32);
		}
		public set(PanicStage value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_PanicStage), value, NumberType_Int32);
		}
	}

	property FinaleStage finaleStage
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_FinaleStage), NumberType_Int32);
		}
		public set(FinaleStage value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ScriptedEventManager_FinaleStage), value, NumberType_Int32);
		}
	}

	public void OnPanicEventFinished()
	{
		SDKCall(g_hSDK_OnPanicEventFinished, this);
	}
}

methodmap ChallengeMode < Address
{
	property bool scriptVarsEnabled
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_DirectorChallengeModeAllowVars), NumberType_Int8);
		}
	}
}
