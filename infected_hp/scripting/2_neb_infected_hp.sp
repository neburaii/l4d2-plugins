#include <sourcemod>
#include <neb_stocks>
#include <clientprefs>

#define CVAR_FLAGS			FCVAR_NOTIFY

// bar dimensions
#define ANCHORLINE			"                                                                                                   \10"
#define LINEBREAK			"\10"
#define BARLEN_NORMAL		40
#define BARLEN_BOSS			60
#define BARMAXLEN_NORMAL	68
#define BARMAXLEN_BOSS		86

// index labels
#define BAR_NORMAL			0
#define BAR_BOSS			1

// ConVar vars
ConVar	g_cUpdateInterval, g_cDeathAnimPattern, g_cDecayAnimLength, g_cTargetTimer, g_cTempTimer, g_cWitchHealth;
int		g_iConVarUpdateInterval, g_iConVarMaxDeathAnimFrames, g_iConVarDecayAnimLength;
float	g_fConVarTargetTimer, g_fConVarTempTimer;
char	g_sDeathAnimPattern[16];

// Cookie vars
Handle	g_hcShowAll, g_hcShowNormal, g_hcShowDeath, g_hcShowTemp, g_hcShowBoss, g_hcPriorityOnly;
bool	g_baCookieShowAll[MAXPLAYERS_L4D2+1], g_baCookieShowNormal[MAXPLAYERS_L4D2+1], g_baCookieShowTemp[MAXPLAYERS_L4D2+1], g_baCookieShowDeath[MAXPLAYERS_L4D2+1],
		g_baCookieShowBoss[MAXPLAYERS_L4D2+1], g_baCookiePriorityOnly[MAXPLAYERS_L4D2+1];

// Timers
Handle	g_htClientTargetRemove[MAXPLAYERS_L4D2+1][2], g_htClientTempDecayStart[MAXPLAYERS_L4D2+1][2];

// Data vars
int		g_iDeathAnimFrame;
int		g_iaClientUpdatePending[4], g_iaClientTarget[MAXPLAYERS_L4D2+1][2], g_iaClientTempAmount[MAXPLAYERS_L4D2+1][2], g_iaVictimKilledBy[MAXENTITES+1],
		g_iaWitchMAX[MAXENTITES+1], g_iaWitchHP[MAXENTITES+1], g_iaClientTempSubtract[MAXPLAYERS_L4D2+1][2], g_iaPrevHP[MAXPLAYERS_L4D2+1], g_iaPrevMAX[MAXPLAYERS_L4D2+1];
bool	g_baClientRendered[MAXPLAYERS_L4D2+1], g_baTargetIsWitch[MAXPLAYERS_L4D2+1], g_baTankDying[MAXPLAYERS_L4D2+1], g_baTankFinalShotDistributed[MAXPLAYERS_L4D2+1];
char	g_saConstructedBarsNormal[MAXPLAYERS_L4D2+1][BARMAXLEN_NORMAL], g_saConstructedBarsBoss[MAXENTITES+1][BARMAXLEN_BOSS];

public void OnPluginStart()
{
	g_cWitchHealth = FindConVar("z_witch_health");
	g_cUpdateInterval = CreateConVar("infectedhp_update_interval", "5", "render non priority updates to pending clients every X server frame. Default will be about 25fps at 100 tickrate", CVAR_FLAGS);
	g_cDeathAnimPattern = CreateConVar("infectedhp_deathanim_pattern", "...,.,.,", "presented to its killer, an SI's empty healthbar will have its bottom bezel animated with this pattern moving along it", CVAR_FLAGS);
	g_cDecayAnimLength = CreateConVar("infectedhp_decayanim_length", "7", "when temp health begins its fade away animation, how many frames (based on plugin's internal framerate) should this last?", CVAR_FLAGS);
	g_cTargetTimer = CreateConVar("infectedhp_target_remove_time", "2.5", "How long in seconds must a client not deal damage to a target for it to be removed as an active target?", CVAR_FLAGS);
	g_cTempTimer = CreateConVar("infectedhp_temp_decay_start_timer", "0.5", "How long in seconds must a client not deal damage to a target for its accumulated recent damage to start decaying?", CVAR_FLAGS);
	readConVars();

	g_cUpdateInterval.AddChangeHook(ConVarChanged_Cvars);
	g_cDeathAnimPattern.AddChangeHook(ConVarChanged_Cvars);
	g_cDecayAnimLength.AddChangeHook(ConVarChanged_Cvars);
	g_cTargetTimer.AddChangeHook(ConVarChanged_Cvars);
	g_cTempTimer.AddChangeHook(ConVarChanged_Cvars);

	g_hcShowAll = RegClientCookie("sihp_show_all", "Show/hide all enemy healthbars [0 to hide, 1 (default) to show]", CookieAccess_Public);
	g_hcShowNormal = RegClientCookie("sihp_show_normal", "Show/hide non-boss SI hp bars [0 to hide, 1 (default) to show] (hiding will only make boss bars visible! there is no option currently to merge them to share the same bar)", CookieAccess_Public);
	g_hcShowBoss = RegClientCookie("sihp_show_boss", "Show/hide boss hp bars [0 to hide, 1 (default) to show] (they're coded to be separate, so this won't magically make it merge with the regular hp bar. Witch/tank hp bars will never show period with this off)", CookieAccess_Public);
	g_hcShowTemp = RegClientCookie("sihp_show_temp", "Show/hide the recently dealt damage (by you) representation in enemy hp bars [0 (default) to hide, 1 to show]", CookieAccess_Public);
	g_hcShowDeath = RegClientCookie("sihp_show_death", "Show/hide the kill confirmed indicator on dead SI's health bars (empty bars display with a unique notifier if you're the one who got the kill) [0 (default) to hide, 1 to show", CookieAccess_Public);
	g_hcPriorityOnly = RegClientCookie("sihp_priority_only", "Only update healthbars from \"priority\" update triggers (when you deal damage to your target). All other update triggers (like when others damage your target) won't trigger updates", CookieAccess_Public);

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_hurt", event_player_hurt);
	HookEvent("infected_hurt", event_infected_hurt);
	HookEvent("witch_spawn", event_witch_spawn);
	HookEvent("witch_killed", event_witch_killed);


	CreateTimer(1.8, refreshBars, _, TIMER_REPEAT);
	RequestFrame(updateLoop);
}

/**********
 * ConVars
 **********/

public void OnConfigsExecuted()
{
	readConVars();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	readConVars();
}

void readConVars()
{
	g_fConVarTargetTimer = g_cTargetTimer.FloatValue;
	g_fConVarTempTimer = g_cTempTimer.FloatValue;
	g_iConVarUpdateInterval = g_cUpdateInterval.IntValue;
	g_cDeathAnimPattern.GetString(g_sDeathAnimPattern, sizeof(g_sDeathAnimPattern));
	g_iConVarMaxDeathAnimFrames = strlen(g_sDeathAnimPattern);
	g_iConVarDecayAnimLength = g_cDecayAnimLength.IntValue;
}

/************
 * Cookies
 ************/

public void OnClientCookiesCached(int iClient)
{
	char sCookie[8];

	// enforce defaults
	g_baCookieShowAll[iClient] = true;
	g_baCookieShowNormal[iClient] = true;
	g_baCookieShowBoss[iClient] = true;
	g_baCookieShowDeath[iClient] = false;
	g_baCookieShowTemp[iClient] = false;
	g_baCookiePriorityOnly[iClient] = false;

	// read cookies, overriding defaults
	GetClientCookie(iClient, g_hcShowAll, sCookie, sizeof(sCookie));
	if(sCookie[0] == '0') g_baCookieShowAll[iClient] = false;
	GetClientCookie(iClient, g_hcShowNormal, sCookie, sizeof(sCookie));
	if(sCookie[0] == '0') g_baCookieShowNormal[iClient] = false;
	GetClientCookie(iClient, g_hcShowBoss, sCookie, sizeof(sCookie));
	if(sCookie[0] == '0') g_baCookieShowBoss[iClient] = false;
	GetClientCookie(iClient, g_hcShowDeath, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_baCookieShowDeath[iClient] = true;
	GetClientCookie(iClient, g_hcShowTemp, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_baCookieShowTemp[iClient] = true;
	GetClientCookie(iClient, g_hcPriorityOnly, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_baCookiePriorityOnly[iClient] = true;
}

/*****************
 * Data handling
 *****************/

public void OnClientPutInServer(int iClient)
{
	for(int i = 0; i < 2; i++)
	{
		g_iaClientTarget[iClient][i] = 0;
		g_iaClientTempAmount[iClient][i] = 0;
		g_iaClientTempSubtract[iClient][i] = 0;
	}
	g_baTargetIsWitch[iClient] = false;
	g_saConstructedBarsNormal[iClient][0] = 0;
	g_saConstructedBarsBoss[iClient][0] = 0;
	g_baTankDying[iClient] = false;
	g_baTankFinalShotDistributed[iClient] = false;
	g_iaPrevMAX[iClient] = -1;
	g_iaPrevHP[iClient] = -1;
	g_iaVictimKilledBy[iClient] = 0;
	g_baClientRendered[iClient] = false;
}

// initialize data for newly spawned SI
void event_player_spawn(Event hEvent, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iClient)) return;

	TimerSpawn(INVALID_HANDLE, hEvent.GetInt("userid"));
	CreateTimer(0.5, TimerSpawn, hEvent.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
}

Action TimerSpawn(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if(iClient && IsClientInGame(iClient))
	{
		int iVal = GetEntProp(iClient, Prop_Send, "m_iMaxHealth") & 0xffff;
		g_iaPrevMAX[iClient] = (iVal <= 0) ? iVal : 1;
		g_iaPrevHP[iClient] = 999999;
	}
	return Plugin_Stop;
}

void event_witch_spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iEntity = hEvent.GetInt( "witchid" );
	int iHealth = (g_cWitchHealth == INVALID_HANDLE) ? 1000 : g_cWitchHealth.IntValue;
	g_iaWitchMAX[iEntity] = iHealth;
	g_iaWitchHP[iEntity] = iHealth;
	g_iaVictimKilledBy[iEntity] = 0;
}

/****************
 * Update triggers
 *****************/

// RequestFrame neverending loop
void updateLoop()
{
	static int iFrameCount;
	iFrameCount++;
	if(iFrameCount >= g_iConVarUpdateInterval)
	{
		// reset frame counter
		iFrameCount = 0;

		// update animation of kill confirmations to the next frame
		g_iDeathAnimFrame++;
		if(g_iDeathAnimFrame >= g_iConVarMaxDeathAnimFrames) g_iDeathAnimFrame = 0;

		// render pending client updates
		static int iClient;
		bool bKeepGoing;
		for(int i = 0; i < sizeof(g_iaClientUpdatePending); i++)
		{
			if(g_iaClientUpdatePending[i])
			{
				iClient = GetClientOfUserId(g_iaClientUpdatePending[i]);
				if(iClient)
				{
					for(int j = 0; j < 2; j++)
					{
						// temp decay anim
						if(g_iaClientTempSubtract[iClient][j]) g_iaClientTempAmount[iClient][j] -= g_iaClientTempSubtract[iClient][j];
						if(g_iaClientTempAmount[iClient][j] <= 0)
						{
							g_iaClientTempAmount[iClient][j] = 0;
							g_iaClientTempSubtract[iClient][j] = 0;
						}

						// should this frame remove client from update pending queue
						if(bKeepGoing) continue;
						if(g_iaClientTempSubtract[iClient][j])
						{
							bKeepGoing = true;
							continue;
						}
						if(g_baTargetIsWitch[iClient] && j == BAR_BOSS)
						{
							if(GetClientUserId(iClient) == g_iaVictimKilledBy[g_iaClientTarget[iClient][j]])
								bKeepGoing = true;
						}
						else if(GetClientUserId(iClient) == g_iaVictimKilledBy[GetClientOfUserId(g_iaClientTarget[iClient][j])])
							bKeepGoing = true;
					}
					if(!g_baCookiePriorityOnly[iClient]) renderBars(iClient, false);
				}
				if(!bKeepGoing) g_iaClientUpdatePending[i] = 0;
			}
		}
	}
	RequestFrame(updateLoop);
}

// repeat-timer callback to refresh bars for all clients at a slow frequency. Its purpose is to help enforce consistent bar disappearance times, especially if it's supposed to be longer than 2 seconds
Action refreshBars(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsSurvivor(i)) continue;
		if(g_iaClientTarget[i][BAR_NORMAL] || g_iaClientTarget[i][BAR_BOSS]) queue(i);
	}

	return Plugin_Continue;
}

// timer callback for when a temp health decay animation should start for a client's target's hp bar. Next frame of updateLoop wil recognize this
Action startDecay(Handle hTimer, DataPack dData)
{
	int iClient = GetClientOfUserId(dData.ReadCell());
	if(!nsIsSurvivor(iClient))
	{
		delete dData;
		return Plugin_Stop;
	}
	int iBarIndex = dData.ReadCell();
	delete dData;
	
	g_iaClientTempSubtract[iClient][iBarIndex] = g_iaClientTempAmount[iClient][iBarIndex] / g_iConVarDecayAnimLength;
	queue(iClient);
	
	return Plugin_Stop;
}

// timer callback for when a client's target should be removed, which should trigger an update so that the bar for that target disappears
Action removeTarget(Handle hTimer, DataPack dData)
{
	int iClient = GetClientOfUserId(dData.ReadCell());
	if(!nsIsSurvivor(iClient))
	{
		delete dData;
		return Plugin_Stop;
	}
	int iBarIndex = dData.ReadCell();
	delete dData;

	if(iBarIndex) g_baTargetIsWitch[iClient] = false;	
	g_iaClientTarget[iClient][iBarIndex] = 0;
	queue(iClient);

	return Plugin_Stop;
}

void event_player_hurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim) || !IsPlayerAlive(iVictim)) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) iAttacker = 0;
	
	int iBarIndex;
	int iZClass = nsGetInfectedClass(iVictim);
	if(iZClass && iZClass <= ZCLASS_MAX) iBarIndex = BAR_NORMAL;
	else if(iZClass == ZCLASS_TANK) iBarIndex = BAR_BOSS;
	else return;

	if(iAttacker)
	{
		g_iaClientTempSubtract[iAttacker][iBarIndex] = 0;
		// Update this attacker's target
		if(g_iaClientTarget[iAttacker][iBarIndex] != GetClientUserId(iVictim))
		{
			g_iaClientTempAmount[iAttacker][iBarIndex] = 0;
		}
		g_iaClientTarget[iAttacker][iBarIndex] = GetClientUserId(iVictim);	
		if(iBarIndex) g_baTargetIsWitch[iAttacker] = false;
	}
	
	// get current/max health
	int iNowHP = hEvent.GetInt("health") & 0xffff;
	int iMaxHP = GetEntProp(iVictim, Prop_Send, "m_iMaxHealth") & 0xffff;
	int iDmgDealt = hEvent.GetInt("dmg_health");

	// verify values are valid, correcting them if not
	if(iNowHP <= 0 || g_iaPrevMAX[iVictim] < 0 || g_baTankDying[iVictim])
	{
		if(!g_baTankFinalShotDistributed[iVictim])
		{
			g_baTankFinalShotDistributed[iVictim] = true;
			if(iNowHP > 0) iDmgDealt += iNowHP;
		}
		iNowHP = 0;
	}

	if(iDmgDealt > g_iaPrevHP[iVictim]) iDmgDealt = g_iaPrevHP[iVictim];
	if(iAttacker) g_iaClientTempAmount[iAttacker][iBarIndex] += iDmgDealt; // Update temp health data for this attacker

	if(iNowHP && iNowHP > g_iaPrevHP[iVictim]) iNowHP = g_iaPrevHP[iVictim];
	else g_iaPrevHP[iVictim] = iNowHP;

	if(iMaxHP < g_iaPrevMAX[iVictim]) iMaxHP = g_iaPrevMAX[iVictim];	
	if(iMaxHP < iNowHP)
	{
		iMaxHP = iNowHP;
		g_iaPrevMAX[iVictim] = iNowHP;
	}	
	if(iMaxHP < 1) iMaxHP = 1;

	// %N will only work for clients, and since witches get passed to the same function, we should get name in these parent functions instead
	char sClientName[MAX_NAME_LENGTH];
	GetClientName(iVictim, sClientName, sizeof(sClientName));

	// Finally, pass all this to the bar constructor function
	constructBar(iVictim, iAttacker, !!iBarIndex, iMaxHP, iNowHP, sClientName);

	// Start data reset timers
	if(iAttacker)
	{
		DataPack dTargetData = CreateDataPack();
		dTargetData.WriteCell(GetClientUserId(iAttacker));
		dTargetData.WriteCell(iBarIndex);
		dTargetData.Reset();
		if(IsValidHandle(g_htClientTargetRemove[iAttacker][iBarIndex])) delete g_htClientTargetRemove[iAttacker][iBarIndex];
		g_htClientTargetRemove[iAttacker][iBarIndex] = CreateTimer(g_fConVarTargetTimer, removeTarget, dTargetData);

		DataPack dTempData = CreateDataPack();
		dTempData.WriteCell(GetClientUserId(iAttacker));
		dTempData.WriteCell(iBarIndex);
		dTempData.Reset();		
		if(IsValidHandle(g_htClientTempDecayStart[iAttacker][iBarIndex])) delete g_htClientTempDecayStart[iAttacker][iBarIndex];
		g_htClientTempDecayStart[iAttacker][iBarIndex] = CreateTimer(g_fConVarTempTimer, startDecay, dTempData);
	}
}

void event_infected_hurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = hEvent.GetInt("entityid");
	if(!nsIsEntityValid(iVictim) || g_iaWitchHP[iVictim] == -1) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) iAttacker = 0;

	if(iAttacker)
	{
		g_iaClientTempSubtract[iAttacker][BAR_BOSS] = 0;
		// Update this attacker's target
		if(g_iaClientTarget[iAttacker][BAR_BOSS] != iVictim)
		{
			g_iaClientTempAmount[iAttacker][BAR_BOSS] = 0;
		}
		g_iaClientTarget[iAttacker][BAR_BOSS] = iVictim;
		g_baTargetIsWitch[iAttacker] = true;
	}
	
	int iDmgDealt = hEvent.GetInt("amount");
	if(iDmgDealt > g_iaWitchHP[iVictim]) iDmgDealt = g_iaWitchHP[iVictim];
	if(iAttacker) g_iaClientTempAmount[iAttacker][BAR_BOSS] += iDmgDealt;	
	
	int iNowHP = g_iaWitchHP[iVictim] - iDmgDealt;
	if(iNowHP <= 0 || g_iaWitchMAX[iVictim] < 0) iNowHP = 0;
	if(iNowHP && iNowHP > g_iaWitchHP[iVictim]) iNowHP = g_iaWitchHP[iVictim];
	else g_iaWitchHP[iVictim] = iNowHP;
	
	int iMaxHP = g_iaWitchMAX[iVictim];
	if(iMaxHP < 1) iMaxHP = 1;	

	constructBar(iVictim, iAttacker, true, iMaxHP, iNowHP, "Witch");

	// Start data reset timers
	if(iAttacker)
	{
		DataPack dTargetData = CreateDataPack();
		dTargetData.WriteCell(GetClientUserId(iAttacker));
		dTargetData.WriteCell(BAR_BOSS);
		dTargetData.Reset();
		if(IsValidHandle(g_htClientTargetRemove[iAttacker][BAR_BOSS])) delete g_htClientTargetRemove[iAttacker][BAR_BOSS];
		g_htClientTargetRemove[iAttacker][BAR_BOSS] = CreateTimer(g_fConVarTargetTimer, removeTarget, dTargetData);

		DataPack dTempData = CreateDataPack();
		dTempData.WriteCell(GetClientUserId(iAttacker));
		dTempData.WriteCell(BAR_BOSS);
		dTempData.Reset();
		if(IsValidHandle(g_htClientTempDecayStart[iAttacker][BAR_BOSS])) delete g_htClientTempDecayStart[iAttacker][BAR_BOSS];
		g_htClientTempDecayStart[iAttacker][BAR_BOSS] = CreateTimer(g_fConVarTempTimer, startDecay, dTempData);
	}
}

void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim)) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) iAttacker = 0;
	if(iAttacker)
	{
		g_iaVictimKilledBy[iVictim] = GetClientUserId(iAttacker);
		if(g_baCookieShowDeath[iAttacker])
		{
			renderBars(iAttacker, true);
			queue(iAttacker);
		}
	}

	g_iaPrevMAX[iVictim] = -1;
	g_iaPrevHP[iVictim] = -1;
}

void event_player_incapacitated(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim, ZCLASS_TANK)) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) iAttacker = 0;
	if(iAttacker)
	{
		g_iaVictimKilledBy[iVictim] = GetClientUserId(iAttacker);
		if(g_baCookieShowDeath[iAttacker]) queue(iAttacker);
	}

	g_baTankDying[iVictim] = true;
	PrintHintTextToAll("++ %N is DEAD ++", iVictim);

	int iMaxHP = GetEntProp(iVictim, Prop_Send, "m_iMaxHealth") & 0xffff;
	if(iMaxHP < g_iaPrevMAX[iVictim]) iMaxHP = g_iaPrevMAX[iVictim];	
	if(iMaxHP < 1) iMaxHP = 1;

	char sClientName[MAX_NAME_LENGTH];
	GetClientName(iVictim, sClientName, sizeof(sClientName));
	constructBar(iVictim, iAttacker, true, iMaxHP, 0, sClientName);
}

void event_witch_killed(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = hEvent.GetInt("witchid");
	if(!nsIsEntityValid(iVictim)) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsSurvivor(iAttacker)) iAttacker = 0;
	if(iAttacker)
	{
		g_iaVictimKilledBy[iVictim] = GetClientUserId(iAttacker);
		if(g_baCookieShowDeath[iAttacker]) queue(iAttacker);
	}

	constructBar(iVictim, iAttacker, true, g_iaWitchMAX[iVictim], 0, "Witch");
}

/*****************************
 * Queue non-priority updates
 *****************************/

void queue(int iClient)
{
	int iThisOne, iQueuedClient;
	for(int i = 0; i < sizeof(g_iaClientUpdatePending); i++)
	{
		iQueuedClient = GetClientOfUserId(g_iaClientUpdatePending[i]);
		if(!iQueuedClient && !iThisOne) iThisOne = i+1;
		if(iQueuedClient == iClient)
		{
			iThisOne = 0;
			break;
		}
	}
	if(iThisOne)
	{
		g_iaClientUpdatePending[iThisOne-1] = GetClientUserId(iClient);
		iThisOne = 0;
	}
}

void queueByVictim(int iVictim, int iBarIndex)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsSurvivor(i) || !g_iaClientTarget[i][iBarIndex]) continue;
		if(iBarIndex && g_baTargetIsWitch[i])
		{
			if(g_iaClientTarget[i][iBarIndex] != iVictim) continue;
		}
		else
		{
			if(nsIsClientValid(iVictim))
			{
				if(g_iaClientTarget[i][iBarIndex] != GetClientUserId(iVictim)) continue;
			}
			else
			{
				if(g_iaClientTarget[i][iBarIndex] != iVictim) continue;				
			}
		}

		queue(i);
	}
}

/*************
 * Render Bars
 **************/

// construct the base hp bar for an SI
void constructBar(int iVictim, int iPriorityClient, bool bIsBoss, int iMaxHP, int iNowHP, const char[] sClientName)
{
	int iLength = bIsBoss ? BARLEN_BOSS : BARLEN_NORMAL;
	int iAmount = RoundToCeil((float(iNowHP) / float(iMaxHP)) * float(iLength));
	int i;	
	char sBar[128];
	
	sBar[0] = 0;
	for(i = 0; i < iAmount && i < iLength; i ++) StrCat(sBar, iLength+2, "!");
	for(; i < iLength; i ++) StrCat(sBar, iLength+2, ".");

	if(bIsBoss) FormatEx(g_saConstructedBarsBoss[iVictim], BARMAXLEN_BOSS, "HP: %sl  [ %d ]  %s", sBar, iNowHP, sClientName);
	else FormatEx(g_saConstructedBarsNormal[iVictim], BARMAXLEN_NORMAL, "HP: %sl  [ %d ]  %s", sBar, iNowHP, sClientName);
	
	if(iPriorityClient) renderBars(iPriorityClient, true); // save processing time for this client's perspective
	queueByVictim(iVictim, bIsBoss ? BAR_BOSS : BAR_NORMAL);
}

// render the most up-to-date version of this client hud's healthbars
void renderBars(int iClient, bool bForce)
{
	if(!g_baCookieShowAll[iClient] || !nsIsClientValid(iClient)) return;

	// prevent updates coinciding in the same frame
	if(g_baClientRendered[iClient] && !bForce) return;
	else
	{
		if(!g_baClientRendered[iClient]) RequestFrame(removeRenderedFlag, iClient);
		g_baClientRendered[iClient] = true;
	}

	char sBarModifiedNormal[BARMAXLEN_NORMAL], sBarModifiedBoss[BARMAXLEN_BOSS];

	// FORMAT: normal
	int iVictim = GetClientOfUserId(g_iaClientTarget[iClient][BAR_NORMAL]);
	if(g_baCookieShowNormal[iClient] && iVictim && g_saConstructedBarsNormal[iVictim][0])
	{
		sBarModifiedNormal = g_saConstructedBarsNormal[iVictim];
		if(g_baCookieShowTemp[iClient] && g_iaClientTempAmount[iClient][BAR_NORMAL])
			formatTemp(sBarModifiedNormal, g_iaClientTempAmount[iClient][BAR_NORMAL], GetEntProp(iVictim, Prop_Send, "m_iMaxHealth") & 0xffff, GetEntProp(iVictim, Prop_Send, "m_iHealth"), BARLEN_NORMAL);
		if(g_baCookieShowDeath[iClient] && g_iaVictimKilledBy[iVictim] == GetClientUserId(iClient))
			formatDeath(sBarModifiedNormal, BARLEN_NORMAL);
	}

	// FORMAT: boss
	iVictim = 0;
	if(g_baTargetIsWitch[iClient])
	{
		if(nsIsEntityValid(g_iaClientTarget[iClient][BAR_BOSS]))
		{
			char sClassName[32];
			GetEntityClassname(g_iaClientTarget[iClient][BAR_BOSS], sClassName, sizeof(sClassName));
			if(strcmp(sClassName, "witch") == 0)
			{
				iVictim = g_iaClientTarget[iClient][BAR_BOSS];
			}
		}
	}
	else iVictim = GetClientOfUserId(g_iaClientTarget[iClient][BAR_BOSS]);

	if(g_baCookieShowBoss[iClient] && iVictim && g_saConstructedBarsBoss[iVictim][0])
	{
		sBarModifiedBoss = g_saConstructedBarsBoss[iVictim];
		if(g_baTargetIsWitch[iClient])
		{
			if(g_baCookieShowTemp[iClient] && g_iaClientTempAmount[iClient][BAR_BOSS])
				formatTemp(sBarModifiedBoss, g_iaClientTempAmount[iClient][BAR_BOSS], g_iaWitchMAX[iVictim], g_iaWitchHP[iVictim], BARLEN_BOSS);
			if(g_baCookieShowDeath[iClient] && g_iaVictimKilledBy[iVictim] == iClient)
				formatDeath(sBarModifiedBoss, BARLEN_BOSS);
		}
		else
		{
			if(g_baCookieShowTemp[iClient] && g_iaClientTempAmount[iClient][BAR_BOSS])
				formatTemp(sBarModifiedBoss, g_iaClientTempAmount[iClient][BAR_BOSS], (GetEntProp(iVictim, Prop_Send, "m_iMaxHealth") & 0xffff), (GetEntProp(iVictim, Prop_Send, "m_iHealth")), BARLEN_BOSS);
			if(g_baCookieShowDeath[iClient] && g_iaVictimKilledBy[iVictim] == GetClientUserId(iClient))
				formatDeath(sBarModifiedBoss, BARLEN_BOSS);			
		}
	}
	PrintCenterText(iClient, "%s%s%s%s", ANCHORLINE, sBarModifiedNormal, LINEBREAK, sBarModifiedBoss);
}

// RequestFrame callback
void removeRenderedFlag(int iClient)
{
	g_baClientRendered[iClient] = false;
}

void formatTemp(const char[] sModify, int iTempAmount, int iMaxHP, int iNowHP, int iLength)
{
	iTempAmount = RoundToCeil((float(iNowHP+iTempAmount)/float(iMaxHP))*float(iLength)) - RoundToCeil((float(iNowHP)/float(iMaxHP))*float(iLength));
	for(int i = 4; (i < (iLength + 5)) && iTempAmount; i++)
	{
		if(sModify[i] == '.')
		{
			sModify[i] = ':';
			iTempAmount--;
		}
	}
}

void formatDeath(const char[] sModify, int iLength)
{
	int iFrame = g_iDeathAnimFrame;
	for(int i = 4; i < (iLength + 5); i++)
	{
		if(g_sDeathAnimPattern[iFrame] == ',')
		{
			if(sModify[i] == '.') sModify[i] = ',';
			else if(sModify[i] == ':') sModify[i] = ';';
		}
		iFrame++;
		if(iFrame >= g_iConVarMaxDeathAnimFrames) iFrame = 0;
	}
}