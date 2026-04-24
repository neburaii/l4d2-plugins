#pragma newdecls required
#pragma semicolon 1

#define	CUTLVECTOR_STRUCT_SIZE			20
#define TRACEFILTERSIMPLE_STRUCT_SIZE	16
#define KEYVALUES_SIZE					44

Director g_director;
ScriptedEventManager g_scriptedEventManager;
ChallengeMode g_challengeMode;
ZombieManager g_zombieManager;
GameRules g_gameRules;
CUtlVector g_pSavedPlayers;
CUtlVector g_pSavedSurvivorBots;

CountdownTimer g_MobTimer;
CountdownTimer g_TempoTimer;
CountdownTimer g_PanicDelayTimer;

Address g_pDirectorTacticalServices;
Address g_pL4DGameStats;
Address g_pNavMesh;
Address g_pTheNavAreas;
Address g_pDefaultViewVectors;
Address g_pTraceFilterSimple_vtable;
Address g_pAmmoDef;
Address g_pBaseFileSystem;

MemoryPatch	g_hMemPatch_SpawnSpecialsBypassLimit;
MemoryPatch	g_hMemPatch_SpawnTankBypassLimit;
MemoryPatch	g_hMemPatch_SpawnWitchBypassLimit;

int		g_iOffset_EHandle;
int		g_iOffset_Intensity;
int		g_iOffset_DirectorChallengeModeAllowVars;
int		g_iOffset_VariantType;
int		g_iOffset_FinaleTrigger_FinaleType;
int		g_iOffset_ZombieManager_SpawnAreaSets;
int		g_iOffset_EntityTeam;
int		g_iOffset_Player_ActiveSet;
int		g_iOffset_CountdownTimer_time;
int		g_iOffset_CountdownTimer_timestamp;
int		g_iOffset_IntervalTimer_timestamp;
int		g_iOffset_Player_punchAngle;
int		g_iOffset_Player_character;
int		g_iOffset_ClientIndex;
int		g_iOffset_Player_TimeLastAlive;
int		g_iOffset_Player_DetachedWeapon;
int		g_iOffset_LastHitGroup;
int		g_iOffset_VocalizeCooldown;
int		g_iOffset_NextBotPointer;
int		g_iOffset_InfectedReservedWandererFlags;
int		g_iOffset_InfectedMobAmbient;
int		g_iOffset_ZombieManagerCommonSpawnCount;
int		g_iOffset_GameRules_WaterSlowsMovement;

/** CTraceFilterSimple */
int		g_iOffset_TraceFilterSimple_vtable;
int		g_iOffset_TraceFilterSimple_passEnt;
int		g_iOffset_TraceFilterSimple_collisionGroup;
int		g_iOffset_TraceFilterSimple_extraCallback;

/** CNavLadder */
int		g_iOffset_NavLadder_connectedNavs;
int		g_iOffset_NavLadder_ehandle;
int		g_iOffset_NavLadder_origin;
int		g_iOffset_NavLadder_length;

/** CNavArea */
int		g_iOffset_NavArea_BaseAttributes;
int		g_iOffset_NavArea_SpawnAttributes;
int		g_iOffset_NavArea_adjacentList;
int		g_iOffset_NavArea_flow;
int		g_iOffset_NavArea_id;
int		g_iOffset_NavArea_connectedLadders;
int		g_iOffset_NavArea_center;
int		g_iOffset_NavArea_elevatorConnectedAreas;
int		g_iOffset_NavArea_connectedElevator;
int		g_iOffset_NavArea_incomingList;
int		g_iOffset_NavArea_cornerNx;
int		g_iOffset_NavArea_cornerPx;
int		g_iOffset_NavArea_cornerNy;
int		g_iOffset_NavArea_cornerPy;
int		g_iOffset_NavArea_cornerNNz;
int		g_iOffset_NavArea_cornerPPz;
int		g_iOffset_NavArea_cornerPNz;
int		g_iOffset_NavArea_cornerNPz;
int		g_iOffset_NavArea_WandererPopulation;

/** CUtlVector */
int		g_iOffset_CUtlVector_List;
int		g_iOffset_CUtlVector_Count;
int		g_iOffset_CUtlVector_Size;
int		g_iOffset_CUtlVector_ListPtr;

/** CDirector */
int		g_iOffset_Director_MobRechargeProgress;
int		g_iOffset_Director_NextMobSize;
int		g_iOffset_Director_Tempo;
int		g_iOffset_Director_RelaxStartFlow;
int		g_iOffset_Director_SurvivorsLeftSafeArea;
int		g_iOffset_Director_NumReservedWanderers;

/** CDirectorScriptedEventManager */
int		g_iOffset_ScriptedEventManager_CrescendoOccured;
int		g_iOffset_ScriptedEventManager_TotalPanicWaves;
int		g_iOffset_ScriptedEventManager_CompletedPanicWaves;
int		g_iOffset_ScriptedEventManager_FinaleStage;
int		g_iOffset_ScriptedEventManager_FinaleType;
int		g_iOffset_ScriptedEventManager_CrescendoOngoing;
int		g_iOffset_ScriptedEventManager_PanicStage;

/** CInferno */
int		g_iOffset_Inferno_type;
int		g_iOffset_Inferno_maxFires;
int		g_iOffset_Inferno_startTime;
int		g_iOffset_Inferno_minBounds;
int		g_iOffset_Inferno_maxBounds;
int		g_iOffset_Inferno_flameCount;
int		g_iOffset_Inferno_flameList;
int		g_iOffset_Inferno_Origin;

/** FlameInfo */
int		g_iOffset_Flame_depth;
int		g_iOffset_Flame_parent;
int		g_iOffset_Flame_spreadDuration;
int		g_iOffset_Flame_lifetime;
int		g_iOffset_Flame_origin;
int		g_iOffset_Flame_direction;

/** netpacket_s */
int		g_iOffset_NetAdr_type;
int		g_iOffset_NetAdr_ipv4;
int		g_iOffset_NetAdr_port;
int		g_iOffset_NetPacket_adr;
int		g_iOffset_NetPacket_packet;
int		g_iOffset_NetPacket_bf;
int		g_iOffset_BfRead_info;
int		g_iOffset_BfRead_bytesLeft;

/** CTakeDamageInfo */
int		g_iOffset_TakeDamageInfo_attacker;
int		g_iOffset_TakeDamageInfo_inflictor;
int		g_iOffset_TakeDamageInfo_damage;
int		g_iOffset_TakeDamageInfo_damageType;
int		g_iOffset_TakeDamageInfo_damageForce;
int		g_iOffset_TakeDamageInfo_damagePos;
int		g_iOffset_TakeDamageInfo_weapon;

void InitOffsets()
{
	g_iOffset_Intensity =
		LoadOffset("Intensity");
	g_iOffset_EHandle =
		LoadOffset("EHandle");
	g_iOffset_DirectorChallengeModeAllowVars =
		LoadOffset("CDirectorChallengeMode::allow_script_variables");
	g_iOffset_VariantType =
		LoadOffset("variant_t::type");
	g_iOffset_FinaleTrigger_FinaleType =
		LoadOffset("CFinaleTrigger::finaleType");
	g_iOffset_ZombieManager_SpawnAreaSets =
		LoadOffset("ZombieManager::spawnAreaVectors");
	g_iOffset_EntityTeam =
		LoadOffset("CBaseEntity::teamNumber");
	g_iOffset_Player_ActiveSet =
		LoadOffset("CTerrorPlayer::activeSet");
	g_iOffset_CountdownTimer_time =
		LoadOffset("CountdownTimer::time");
	g_iOffset_CountdownTimer_timestamp =
		LoadOffset("CountdownTimer::timestamp");
	g_iOffset_IntervalTimer_timestamp =
		LoadOffset("IntervalTimer::timestamp");
	g_iOffset_Player_punchAngle =
		LoadOffset("CBasePlayer::punchAngle");
	g_iOffset_Player_character =
		LoadOffset("CTerrorPlayer::character");
	g_iOffset_ClientIndex =
		LoadOffset("CGameClient::index");
	g_iOffset_Player_TimeLastAlive =
		LoadOffset("CTerrorPlayer::timeLastAlive");
	g_iOffset_Player_DetachedWeapon =
		LoadOffset("CTerrorPlayer::detachedWeapon");
	g_iOffset_LastHitGroup =
		LoadOffset("CBaseCombatCharacter::lastHitGroup");
	g_iOffset_VocalizeCooldown =
		LoadOffset("CTerrorPlayer::vocalizeCooldown");
	g_iOffset_NextBotPointer =
		LoadOffset("NextBotPointer");
	g_iOffset_InfectedReservedWandererFlags =
		LoadOffset("Infected::reservedWandererFlags");
	g_iOffset_InfectedMobAmbient =
		LoadOffset("Infected::m_mobAmbient");
	g_iOffset_ZombieManagerCommonSpawnCount =
		LoadOffset("ZombieManager::commonSpawnCount");
	g_iOffset_GameRules_WaterSlowsMovement =
		LoadOffset("CTerrorGameRules::waterSlowsMovement");

	/** CTraceFilterSimple */
	g_iOffset_TraceFilterSimple_vtable =
		LoadOffset("CTraceFilterSimple::vtablePtr");
	g_iOffset_TraceFilterSimple_passEnt =
		LoadOffset("CTraceFilterSimple::passEnt");
	g_iOffset_TraceFilterSimple_collisionGroup =
		LoadOffset("CTraceFilterSimple::collisionGroup");
	g_iOffset_TraceFilterSimple_extraCallback =
		LoadOffset("CTraceFilterSimple::extraCallback");

	/** CNavLadder */
	g_iOffset_NavLadder_connectedNavs =
		LoadOffset("CNavLadder::connectedNavs");
	g_iOffset_NavLadder_ehandle =
		LoadOffset("CNavLadder::ehandle");
	g_iOffset_NavLadder_origin =
		LoadOffset("CNavLadder::topOrigin");
	g_iOffset_NavLadder_length =
		LoadOffset("CNavLadder::length");

	/** CNavArea */
	g_iOffset_NavArea_BaseAttributes =
		LoadOffset("CNavArea::baseAttributes");
	g_iOffset_NavArea_SpawnAttributes =
		LoadOffset("CNavArea::spawnAttributes");
	g_iOffset_NavArea_adjacentList =
		LoadOffset("CNavArea::adjacentAreas");
	g_iOffset_NavArea_flow =
		LoadOffset("CNavArea::flow");
	g_iOffset_NavArea_id =
		LoadOffset("CNavArea::id");
	g_iOffset_NavArea_connectedLadders =
		LoadOffset("CNavArea::connectedLadders");
	g_iOffset_NavArea_center =
		LoadOffset("CNavArea::center");
	g_iOffset_NavArea_connectedElevator =
		LoadOffset("CNavArea::connectedElevator");
	g_iOffset_NavArea_elevatorConnectedAreas =
		LoadOffset("CNavArea::elevatorConnectedAreas");
	g_iOffset_NavArea_incomingList =
		LoadOffset("CNavArea::incomingConnections");
	g_iOffset_NavArea_cornerNx =
		LoadOffset("CNavArea::cornerNx");
	g_iOffset_NavArea_cornerPx =
		LoadOffset("CNavArea::cornerPx");
	g_iOffset_NavArea_cornerNy =
		LoadOffset("CNavArea::cornerNy");
	g_iOffset_NavArea_cornerPy =
		LoadOffset("CNavArea::cornerPy");
	g_iOffset_NavArea_cornerNNz =
		LoadOffset("CNavArea::cornerNNz");
	g_iOffset_NavArea_cornerPPz =
		LoadOffset("CNavArea::cornerPPz");
	g_iOffset_NavArea_cornerPNz =
		LoadOffset("CNavArea::cornerPNz");
	g_iOffset_NavArea_cornerNPz =
		LoadOffset("CNavArea::cornerNPz");
	g_iOffset_NavArea_WandererPopulation =
		LoadOffset("CNavArea::wandererPopulation");

	/** CUtlVector */
	g_iOffset_CUtlVector_List =
		LoadOffset("CUtlVector::list");
	g_iOffset_CUtlVector_Count =
		LoadOffset("CUtlVector::count");
	g_iOffset_CUtlVector_Size =
		LoadOffset("CUtlVector::size");
	g_iOffset_CUtlVector_ListPtr =
		LoadOffset("CUtlVector::listPtr");

	/** CDirector */
	g_iOffset_Director_NextMobSize =
		LoadOffset("CDirector::nextMobSize");
	g_iOffset_Director_MobRechargeProgress =
		LoadOffset("CDirector::mobRechargeProgress");
	g_iOffset_Director_Tempo =
		LoadOffset("CDirector::tempo");
	g_iOffset_Director_RelaxStartFlow =
		LoadOffset("CDirector::relaxStartFlow");
	g_iOffset_Director_SurvivorsLeftSafeArea =
		LoadOffset("CDirector::survivorsLeftSafeArea");
	g_iOffset_Director_NumReservedWanderers =
		LoadOffset("CDirector::numReservedWanderers");

	/** CDirectorScriptedEventManager */
	g_iOffset_ScriptedEventManager_CrescendoOccured =
		LoadOffset("CDirectorScriptedEventManager::crescendoHasOccured");
	g_iOffset_ScriptedEventManager_TotalPanicWaves =
		LoadOffset("CDirectorScriptedEventManager::totalPanicWaves");
	g_iOffset_ScriptedEventManager_CompletedPanicWaves =
		LoadOffset("CDirectorScriptedEventManager::completedPanicWaves");
	g_iOffset_ScriptedEventManager_FinaleStage =
		LoadOffset("CDirectorScriptedEventManager::finaleStage");
	g_iOffset_ScriptedEventManager_FinaleType =
		LoadOffset("CDirectorScriptedEventManager::finaleType");
	g_iOffset_ScriptedEventManager_CrescendoOngoing =
		LoadOffset("CDirectorScriptedEventManager::crescendoOngoing");
	g_iOffset_ScriptedEventManager_PanicStage =
		LoadOffset("CDirectorScriptedEventManager::panicStage");

	/** CInferno */
	g_iOffset_Inferno_type =
		LoadOffset("CInferno::type");
	g_iOffset_Inferno_maxFires =
		LoadOffset("CInferno::maxFires");
	g_iOffset_Inferno_startTime =
		LoadOffset("CInferno::startTime");
	g_iOffset_Inferno_minBounds =
		LoadOffset("CInferno::minBounds");
	g_iOffset_Inferno_maxBounds =
		LoadOffset("CInferno::maxBounds");
	g_iOffset_Inferno_flameCount =
		LoadOffset("CInferno::flameCount");
	g_iOffset_Inferno_flameList =
		LoadOffset("CInferno::flameList");
	g_iOffset_Inferno_Origin =
		LoadOffset("CInferno::origin");

	/** FireInfo */
	g_iOffset_Flame_depth =
		LoadOffset("FireInfo::depth");
	g_iOffset_Flame_parent =
		LoadOffset("FireInfo::parent");
	g_iOffset_Flame_spreadDuration =
		LoadOffset("FireInfo::spreadDuration");
	g_iOffset_Flame_lifetime =
		LoadOffset("FireInfo::lifetime");
	g_iOffset_Flame_origin =
		LoadOffset("FireInfo::origin");
	g_iOffset_Flame_direction =
		LoadOffset("FireInfo::direction");

	/** netpacket_s */
	g_iOffset_NetAdr_type =
		LoadOffset("netadr_s::type");
	g_iOffset_NetAdr_ipv4 =
		LoadOffset("netadr_s::ipv4");
	g_iOffset_NetAdr_port =
		LoadOffset("netadr_s::port");
	g_iOffset_NetPacket_adr =
		LoadOffset("netpacket_s::from");
	g_iOffset_NetPacket_packet =
		LoadOffset("netpacket_s::packet");
	g_iOffset_NetPacket_bf =
		LoadOffset("netpacket_s::bitbuffer");
	g_iOffset_BfRead_info =
		LoadOffset("CBitRead::info");
	g_iOffset_BfRead_bytesLeft =
		LoadOffset("CBitRead::bytesLeft");

	/** CTakeDamageInfo */
	g_iOffset_TakeDamageInfo_attacker =
		LoadOffset("CTakeDamageInfo::attacker");
	g_iOffset_TakeDamageInfo_inflictor =
		LoadOffset("CTakeDamageInfo::inflictor");
	g_iOffset_TakeDamageInfo_damage =
		LoadOffset("CTakeDamageInfo::damage");
	g_iOffset_TakeDamageInfo_damageType =
		LoadOffset("CTakeDamageInfo::damageType");
	g_iOffset_TakeDamageInfo_damageForce =
		LoadOffset("CTakeDamageInfo::damageForce");
	g_iOffset_TakeDamageInfo_damagePos =
		LoadOffset("CTakeDamageInfo::damagePos");
	g_iOffset_TakeDamageInfo_weapon =
		LoadOffset("CTakeDamageInfo::weapon");
}

void InitAddresses()
{
	/** addresses */
	g_director =
		LoadAddress("CDirector");
	g_pL4DGameStats =
		LoadAddress("CL4DGameStats");
	g_zombieManager =
		LoadAddress("ZombieManager");
	g_pNavMesh =
		LoadAddress("CNavMesh");
	g_pTheNavAreas =
		LoadAddress("AllNavAreas");
	g_pDefaultViewVectors =
		LoadAddress("DefaultViewVectors");
	g_pTraceFilterSimple_vtable =
		LoadAddress("CTraceFilterSimple_vtable");
	g_pAmmoDef =
		LoadAddress("CAmmoDef");
	g_gameRules =
		LoadAddress("CGameRules");
	g_pSavedPlayers =
		LoadAddress("SavedPlayers");
	g_pSavedSurvivorBots =
		LoadAddress("SavedSurvivorBots");
	g_pBaseFileSystem =
		LoadAddress("BaseFileSystem");

	/** address + offset */
	g_challengeMode =
		LoadAddressOffset(g_director, "CDirectorChallengeMode");
	g_scriptedEventManager =
		LoadAddressOffset(g_director, "CDirectorScriptedEventManager");
	g_pDirectorTacticalServices =
		LoadAddressOffset(g_director, "CDirectorTacticalServices");
	g_MobTimer =
		LoadAddressOffset(g_director, "CDirector::mobTimer");
	g_TempoTimer =
		LoadAddressOffset(g_director, "CDirector::tempoTimer");
	g_PanicDelayTimer =
		LoadAddressOffset(g_scriptedEventManager, "CDirectorScriptedEventManager::panicStageDelayTimer");
}

void InitMemoryPatches()
{
	g_hMemPatch_SpawnSpecialsBypassLimit =
		LoadMemoryPatch("CTerrorPlayer::HandleCommand_JoinTeam::bypassLimits");
	g_hMemPatch_SpawnTankBypassLimit =
		LoadMemoryPatch("ZombieManager::SpawnTank::bypassLimit");
	g_hMemPatch_SpawnWitchBypassLimit =
		LoadMemoryPatch("ZombieManager::SpawnWitch::bypassLimit");
}
