#pragma newdecls required
#pragma semicolon 1

char g_sSurvivorCharacterNames[][] =
{
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",

	"Bill",
	"Zoey",
	"Louis",
	"Francis"
};

NextBot Util_GetNextBotFromEntity(int iEntity)
{
	return view_as<NextBot>(
		GetEntityAddress(iEntity) + view_as<Address>(g_iOffset_NextBotPointer));
}

methodmap NextBot < Address
{
	public void Update()
	{
		SDKCall(g_hSDK_NextBotUpdate, this);
	}
}

methodmap ZombieManager < Address
{
	property int commonSpawnCount
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ZombieManagerCommonSpawnCount), NumberType_Int32);
		}
		public set(int value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_ZombieManagerCommonSpawnCount), value, NumberType_Int32);
		}
	}

	public Address CollectSpawnAreas(LocationType location, ZombieClass class)
	{
		return SDKCall(g_hSDK_CollectSpawnAreas, this, location, class);
	}

	public bool GetRandomPZSpawnPosition(ZombieClass class, int tries, int ghost, float buffer[3])
	{
		return SDKCall(g_hSDK_GetRandomPZSpawnPosition, this, class, tries, ghost, buffer);
	}

	public bool CanZombieSpawnHere(const float pos[3], Address nav, ZombieClass class, int ghost)
	{
		if (g_OS == OS_Linux)
			return SDKCall(g_hSDK_CanZombieSpawnHere, this, pos, nav, class, false, ghost);
		else return SDKCall(g_hSDK_CanZombieSpawnHere, pos, nav, class, false, ghost);
	}

	public int SpawnWitch(const float pos[3], const float angles[3])
	{
		if (g_OS == OS_Linux)
			return SDKCall(g_hSDK_SpawnWitch, this, pos, angles);
		else return SDKCall(g_hSDK_SpawnWitch, pos, angles);
	}

	public int SpawnTank(const float pos[3], const float angles[3])
	{
		return SDKCall(g_hSDK_SpawnTank, this, pos, angles);
	}

	public int SpawnSpecial(ZombieClass class, const float pos[3], const float angles[3])
	{
		return SDKCall(g_hSDK_SpawnSpecial, this, class, pos, angles);
	}
}

void Util_SetReservedWandererStatus(int iInfected, bool bStatus)
{
	int iValue = GetEntData(iInfected, g_iOffset_InfectedReservedWandererFlags);
	bool bCurrentStatus = view_as<bool>(iValue & (1 << 0));
	if (bCurrentStatus == bStatus)
		return;

	if (bStatus)
	{
		iValue |= (1 << 0);
		g_director.numReservedWanderers++;
	}
	else
	{
		iValue &= ~(1 << 0);
		g_director.numReservedWanderers--;
	}

	SetEntData(iInfected, g_iOffset_InfectedReservedWandererFlags, iValue);
}

/**
 * Check for survivors in panic event or finale areas
 *
 * @return				returns true if any survivor is in a nav area with
 * 						NavSpawn_FINALE or NavSpawn_BATTLEFIELD spawn attribute
 */
bool Util_AreSurvivorsInBattlefieldOrFinale()
{
	NavArea nav;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)
			|| GetClientTeam(i) != Team_Survivor
			|| IsFakeClient(i)	// FakeClient check exists internally too
			|| !IsPlayerAlive(i)) continue;

		nav = GetLastKnownArea(i);
		if (nav && nav.spawnAttributes & (NavSpawn_Battlefield | NavSpawn_Finale))
			return true;
	}

	return false;
}

int Util_GetEntityTeam(int iEntity)
{
	return Util_GetEntityTeamFromAddress(GetEntityAddress(iEntity));
}

int Util_GetEntityTeamFromAddress(Address entity)
{
	return LoadFromAddress(entity + view_as<Address>(g_iOffset_EntityTeam), NumberType_Int32);
}

void Util_GetDefaultViewVector(DefaultViewVector vector, float vBuffer[3])
{
	LoadVectorFromAddress(g_pDefaultViewVectors + view_as<Address>(view_as<int>(vector) * 12), vBuffer);
}

void Util_SendAFKUserMessage(int iClient)
{
	static char sName[32];
	GetClientName(iClient, sName, sizeof(sName));

	BfWrite hBuffer = view_as<BfWrite>(StartMessageAll("TextMsg", USERMSG_RELIABLE));
	hBuffer.WriteByte(3); // idk, just copying the game's code
	hBuffer.WriteString("#L4D_idle_spectator");
	hBuffer.WriteString(sName);

	/** 0 for each empty field (we only need 2/5) */
	hBuffer.WriteByte(0);
	hBuffer.WriteByte(0);
	hBuffer.WriteByte(0);
	EndMessage();
}

void Util_GetSurvivorCharacterName(int iCharacter, char[] sBuffer, int iBufferLen)
{
	if (iCharacter == view_as<int>(Survivor_Random))
		strcopy(sBuffer, iBufferLen, "Survivor");
	else
	{
		int iSet = SDKCall(g_hSDK_FastGetSurvivorSet);
		int iIndex = (IntAbs(iSet - 2) * 4) + iCharacter;
		strcopy(sBuffer, iBufferLen, g_sSurvivorCharacterNames[iIndex]);
	}
}

bool Util_IsVisibleToTeam(int iTeam, const float vPos[3], float fRange = 0.0, Address nav = Address_Null, int iFlags = Visibility_AnyFOV, bool bAllowNoNav = true)
{
	bool bHaveNav = (iFlags & Visibility_IgnoreObscured) || (nav == Address_Null && bAllowNoNav);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (GetClientTeam(i) != iTeam) continue;
		if (iTeam > 1 && !IsPlayerAlive(i)) continue;

		/** ruduce redundant calls */
		if (!bHaveNav)
		{
			bHaveNav = true;

			/** call it exactly how IsVisibleToPlayer does */
			nav = SDKCall(g_hSDK_GetNearestNavArea_Pos, g_pNavMesh, vPos, 0, 100.0, false, true, false);

			if (!nav)
			{
				iFlags |= Visibility_IgnoreObscured;
				bAllowNoNav = true;
				nav = Address_Null;
			}
		}

		if (SDKCall(g_hSDK_IsVisibleToPlayer, vPos, i, iTeam, iFlags, fRange, 0, nav, bAllowNoNav))
			return true;
	}

	return false;
}

/**
 * slower than calling the internal function with SDKCall. only use for custom hulls.
 */
bool Util_CanZombieSpawnHere(float vPos[3], float vHullMin[3], float vHullMax[3], Address nav, ZombieClass class, int iGhost)
{
	float vBuffer[3];

	if (g_director.IsInTransition())
		return false;

	/** nav area checks */
	int iSpawnAttributes = Util_NavArea_GetSpawnAttributes(nav);
	int iBaseAttributes = Util_NavArea_GetBaseAttributes(nav);

	if (iBaseAttributes & NavBase_Crouch
		&& class != ZClass_Common)
		return false;

	if (iSpawnAttributes & NavSpawn_Checkpoint
		&& g_director.hasAnySurvivorLeftSafeArea)
		return false;

	if (iSpawnAttributes & NavSpawn_PlayerStart
		&& (!g_challengeMode.scriptVarsEnabled || !g_director.GetScriptValueInt("cm_TankRun", 0)))
		return false;

	if (SDKCall(g_hSDK_NavArea_IsBlocked, nav, Team_Infected, false))
		return false;

	Util_NavArea_GetCenter(nav, vBuffer);
	if (SDKCall(g_hSDK_IsBehindZombieBorder, vBuffer))
		return false;

	if (iSpawnAttributes & NavSpawn_Obscured)
	{
		float fDistance;
		if (GetClosestPlayer(vPos, fDistance, Team_Survivor)
			&& fDistance < g_fConVar_NavObscureRange)
			return false;
	}

	/** check if hull can fit */
	int iTraceMask = MASK_NPCSOLID|CONTENTS_UNUSED5;
	if (IsValidClient(iGhost))
	{
		if (GetClientTeam(iGhost) == view_as<int>(Team_Infected))
		{
			if (!IsFakeClient(iGhost)) iTraceMask |= (1 << 31);
		}
		else iTraceMask = MASK_PLAYERSOLID|CONTENTS_UNUSED5;
	}

	g_trace.filter = new TraceFilterSimple(iGhost, CollisionGroup_PlayerMovement);
	Handle hTrace = TR_TraceHullFilterEx(vPos, vPos, vHullMin, vHullMax, iTraceMask, TraceEntityFilter_internalOnly, _, g_trace.filter.GetTraceType());
	delete g_trace.filter;

	if (TR_AllSolid(hTrace) || TR_GetFraction(hTrace) < 1.0) // if doesn't fit
	{
		delete hTrace;
		return false;
	}
	delete hTrace;

	/** check survivors' LOS */
	vBuffer = vPos;

	for (int i = 0; i < 3; i++)
	{
		switch (i)
		{
			/** magic numbers match the proportion of the 3 Z levels the internal CanZombieSpawnHere checks */
			case 0: vBuffer[2] = vPos[2] + (vHullMax[2] / 1.26760563380281690141);
			case 1: vBuffer[2] = vPos[2] + (vHullMax[2] / 2.02816901408450704225);
			case 2: vBuffer[2] = vPos[2] + 1.0;
		}

		if (Util_IsVisibleToTeam(Team_Survivor, vBuffer, _, _, 3, false))
			return false;
	}

	/** all checks passed */
	return true;
}

int Util_GetHighestFlowSurvivor(FlowType type)
{
	switch (g_OS)
	{
		case OS_Linux: return SDKCall(g_hSDK_GetHighestFlowSurvivor, g_pDirectorTacticalServices, type);
		case OS_Windows: return SDKCall(g_hSDK_GetHighestFlowSurvivor, type);
	}

	return 0;
}

float Util_GetPlayerFlow(int iPlayer, FlowType type)
{
	Address nav = SDKCall(g_hSDK_PlayerGetLastKnownArea, iPlayer);

	if (nav) return Util_NavArea_GetFlow(nav, type);
	return NULL_FLOW;
}

CountdownTimer Util_GetVocalizeCooldown(int iClient)
{
	Address addr = GetEntityAddress(iClient);
	return view_as<CountdownTimer>(addr + view_as<Address>(g_iOffset_VocalizeCooldown));
}

/******************
 * Inferno + Flame
 *****************/

CountdownTimer Util_Flame_GetSpreadDuration(Address flame)
{
	return view_as<CountdownTimer>(flame + view_as<Address>(g_iOffset_Flame_spreadDuration));
}

CountdownTimer Util_Flame_GetLifetime(Address flame)
{
	return view_as<CountdownTimer>(flame + view_as<Address>(g_iOffset_Flame_lifetime));
}

int Util_Inferno_GetFlameCount(Address inferno)
{
	return LoadFromAddress(inferno + view_as<Address>(g_iOffset_Inferno_flameCount), NumberType_Int32);
}

Address Util_Inferno_GetFlame(Address inferno, int iIndex)
{
	Address list = inferno + view_as<Address>(g_iOffset_Inferno_flameList);
	return LoadFromAddress(list + view_as<Address>(iIndex * 4), NumberType_Int32);
}

/*************
 * Memory
 *************/

StringMap g_hStringMapMemoryBlocks;

void Util_InitStringMemory()
{
	g_hStringMapMemoryBlocks = new StringMap();
}

void Util_StoreToStringPtr(Address pStringPtr, const char[] sBuffer)
{
	MemoryBlock hString = Util_CreateStringMemoryBlock(pStringPtr, sBuffer);
	StoreToAddress(pStringPtr, hString.Address, NumberType_Int32);
}

bool Util_LookupStringMemoryBlock(Address pStringPtr, char sBuffer[16], MemoryBlock &hMemory)
{
	FormatEx(sBuffer, sizeof(sBuffer), "%X", pStringPtr);
	return g_hStringMapMemoryBlocks.GetValue(sBuffer, hMemory);
}

void Util_DeleteStringMemoryBlock(Address pStringPtr)
{
	static char sHash[16];
	MemoryBlock hMemory;

	if (Util_LookupStringMemoryBlock(pStringPtr, sHash, hMemory))
	{
		delete hMemory;
		g_hStringMapMemoryBlocks.Remove(sHash);
	}
}

MemoryBlock Util_CreateStringMemoryBlock(Address pStringPtr, const char[] sBuffer)
{
	static char sHash[16];
	MemoryBlock hMemory;

	if (Util_LookupStringMemoryBlock(pStringPtr, sHash, hMemory))
		delete hMemory;

	int iLength = strlen(sBuffer);
	hMemory = new MemoryBlock(iLength + 1);

	for (int i = 0; i < iLength; i++)
		hMemory.StoreToOffset(i, sBuffer[i], NumberType_Int8);

	g_hStringMapMemoryBlocks.SetValue(sHash, hMemory);

	return hMemory;
}

int Util_GetEntityFromAddress(Address entity)
{
	return LoadEntityFromHandleAddress(entity + view_as<Address>(g_iOffset_EHandle));
}

methodmap CUtlVector < Address
{
	property int count
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(g_iOffset_CUtlVector_Count), NumberType_Int32);
		}
		public set(int value)
		{
			StoreToAddress(this + view_as<Address>(g_iOffset_CUtlVector_Count), value, NumberType_Int32);
		}
	}

	property int size
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(g_iOffset_CUtlVector_Size), NumberType_Int32);
		}
		public set(int value)
		{
			StoreToAddress(this + view_as<Address>(g_iOffset_CUtlVector_Size), value, NumberType_Int32);
		}
	}

	property Address list
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(g_iOffset_CUtlVector_List), NumberType_Int32);
		}
	}

	public Address Get(int iIndex)
	{
		return LoadFromAddress(this.list + view_as<Address>(iIndex * 4), NumberType_Int32);
	}

	public void Set(int iIndex, any value)
	{
		StoreToAddress(this.list + view_as<Address>(iIndex * 4), value, NumberType_Int32);
	}

	public int GetArrayList(ArrayList hArray)
	{
		Address list = this.list;
		int iCount = this.count;
		int iWritten = 0;

		for (int i = 0; i < iCount; i++)
		{
			hArray.Push(LoadFromAddress(list + view_as<Address>(i * 4), NumberType_Int32));
			iWritten++;
		}

		return iWritten;
	}

	public void ResetListPointer()
	{
		StoreToAddress(this + view_as<Address>(g_iOffset_CUtlVector_ListPtr), this.list, NumberType_Int32);
	}
}

methodmap CUtlVectorUltraConservative < Address
{
	property int count
	{
		public get()
		{
			return LoadFromAddress(this, NumberType_Int32);
		}
	}

	public any GetPair(int iIndex, int iPairItem = 1)
	{
		return LoadFromAddress(this + view_as<Address>(
			((iIndex * 2) + iPairItem) * 4), NumberType_Int32);
	}

	public any Get(int iIndex)
	{
		return LoadFromAddress(this + view_as<Address>(
			(iIndex + 1) * 4), NumberType_Int32);
	}

	public int GetArrayListPair(ArrayList hArray, int iPairItem = 1)
	{
		int iMax = this.count;
		int iWritten = 0;

		for (int i = 0; i < iMax; i++)
		{
			hArray.Push(this.GetPair(i, iPairItem));
			iWritten++;
		}

		return iWritten;
	}

	public int GetArrayList(ArrayList hArray)
	{
		int iMax = this.count;
		int iWritten = 0;

		for (int i = 0; i < iMax; i++)
		{
			hArray.Push(this.Get(i));
			iWritten++;
		}

		return iWritten;
	}
}

methodmap CountdownTimer < Address
{
	property float time
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_CountdownTimer_time), NumberType_Int32);
		}
		public set(float value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_CountdownTimer_timestamp), value, NumberType_Int32);
		}
	}

	property float timestamp
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_CountdownTimer_timestamp), NumberType_Int32);
		}
		public set(float value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_CountdownTimer_timestamp), value, NumberType_Int32);
		}
	}

	public float GetRemaining()
	{
		float fNow = GetGameTime();
		return this.timestamp - fNow;
	}

	public void Set(float value)
	{
		float fNow = GetGameTime();

		this.time = value;
		this.timestamp = fNow + value;
	}
}

methodmap IntervalTimer < Address
{
	property float timestamp
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_IntervalTimer_timestamp), NumberType_Int32);
		}
		public set(float value)
		{
			StoreToAddress(this + view_as<Address>(
				g_iOffset_IntervalTimer_timestamp), value, NumberType_Int32);
		}
	}

	public float GetRemaining()
	{
		float fNow = GetGameTime();
		return this.timestamp - fNow;
	}

	public void SetRelative(float value)
	{
		float fNow = GetGameTime();
		this.timestamp = fNow + value;
	}
}

/**
 * maybe this should be in the include instead. no forward/native currently references it
 * directly. i wanted to stay consistent with SDKHook's forwards for the forwards that do
 * involve it. but that choice meant pushing each data member as a separate param rather
 * than a single param as this methodmap.
 * as of now it's only directly used internally. moving it to include would only be for
 * things outside of hxlib. i feel like anything in the include should have a direct
 * connection to at least one other thing in hxlib, so idk.
 * this explanation goes for some of the other methodmaps that are internal only.
 */
methodmap TakeDamageInfo < Address
{
	property int attacker
	{
		public get()
		{
			return LoadEntityFromHandleAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_attacker));
		}

		public set(int value)
		{
			if (!IsValidEntity(value))
				StoreToAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_attacker), INVALID_ENT_REFERENCE, NumberType_Int32);
			else StoreEntityToHandleAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_attacker), value);
		}
	}

	property int inflictor
	{
		public get()
		{
			return LoadEntityFromHandleAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_inflictor));
		}

		public set(int value)
		{
			if (!IsValidEntity(value))
				StoreToAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_inflictor), INVALID_ENT_REFERENCE, NumberType_Int32);
			else StoreEntityToHandleAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_inflictor), value);
		}
	}

	property float damage
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damage), NumberType_Int32);
		}

		public set(float value)
		{
			StoreToAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damage), value, NumberType_Int32);
		}
	}

	property int damageType
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damageType), NumberType_Int32);
		}

		public set(int value)
		{
			StoreToAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damageType), value, NumberType_Int32);
		}
	}

	property int weapon
	{
		public get()
		{
			return LoadEntityFromHandleAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_weapon));
		}

		public set(int value)
		{
			if (!IsValidEntity(value))
				StoreToAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_weapon), INVALID_ENT_REFERENCE, NumberType_Int32);
			else StoreEntityToHandleAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_weapon), value);
		}
	}

	public void GetDamageForce(float buffer[3])
	{
		LoadVectorFromAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damageForce), buffer);
	}
	public void SetDamageForce(float value[3])
	{
		StoreVectorToAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damageForce), value);
	}

	public void GetDamagePos(float buffer[3])
	{
		LoadVectorFromAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damagePos), buffer);
	}
	public void SetDamagePos(float value[3])
	{
		StoreVectorToAddress(this + view_as<Address>(g_iOffset_TakeDamageInfo_damagePos), value);
	}
}
