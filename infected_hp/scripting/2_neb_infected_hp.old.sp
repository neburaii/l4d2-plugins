#include <sourcemod>
#include <neb_stocks>
#include <clientprefs>
#include <sdkhooks>

#define CVAR_FLAGS FCVAR_NOTIFY

// 99 spaces
#define ANCHORLINE "                                                                                                   \10"
#define LINEBREAK "\10"

// BARLEN_* refers to the amount of health representing characters are present in that respective healthbar. BARMAXLEN_* refers to the max size of the entire bar (including HP: l, and the end bezal onwards)
#define BARLEN_NORMAL 40
#define BARLEN_BOSS 60
#define BARMAXLEN_NORMAL 68
#define BARMAXLEN_BOSS 86

// index labels
#define BAR_NORMAL 0
#define BAR_BOSS 1

ConVar g_cTargetRemoveTimer, g_cTempRemoveTimer, g_cTempDecayAmount, g_cWitchHealth;

float g_fTargetTimer, g_fTempTimer;
int g_iDecayAmount;

Handle 	g_hcShowAll, g_hcShowBoss, g_hcShowNormal, g_hcShowTemp, g_hcShowKillConf, g_hcCustomKillConf, g_hcKillConfSize;
bool	g_baCookieShowAll[MAXPLAYERS_L4D2+1], g_baCookieShowBoss[MAXPLAYERS_L4D2+1], g_baCookieShowNormal[MAXPLAYERS_L4D2+1],
		g_baCookieShowTemp[MAXPLAYERS_L4D2+1], g_baCookieShowKillConf[MAXPLAYERS_L4D2+1];
char	g_saCookieCustomKillConf[MAXPLAYERS_L4D2+1][8];
int		g_iaCookieKillConfSize[MAXPLAYERS_L4D2+1];

Handle g_htClientTargetKeep[MAXPLAYERS_L4D2+1][2], g_htClientTempKeep[MAXPLAYERS_L4D2+1][2];

int g_iaClientTarget[MAXPLAYERS_L4D2+1][2], g_iaClientTempAmount[MAXPLAYERS_L4D2+1][2], g_iaPrevHP[MAXPLAYERS_L4D2+1], g_iaPrevMAX[MAXPLAYERS_L4D2+1],
	g_iaWitchMAX[MAXENTITES], g_iaWitchHP[MAXENTITES], g_iaClientDecayPortion[MAXPLAYERS_L4D2][2], g_iaVictimKilledBy[MAXENTITES];
char g_saConstructedBarsNormal[MAXPLAYERS_L4D2+1][BARMAXLEN_NORMAL], g_saConstructedBarsBoss[MAXENTITES][BARMAXLEN_BOSS];

bool g_bInPlay;
bool g_baClientInDecay[MAXPLAYERS_L4D2+1][2], g_baTankDying[MAXPLAYERS_L4D2+1], g_baTankFinalShotDistributed[MAXPLAYERS_L4D2+1],
	 g_baTargetIsWitch[MAXPLAYERS_L4D2+1];

ConVar g_cUpdateInterval, g_cDeathAnimPattern;
int	g_iUpdateInterval;
int g_iaClientUpdatePending[4]; // idc about supporting more than 4 survivors
bool g_baClientRendered[MAXPLAYERS_L4D2];
int g_iDeathAnimFrame, g_iMaxDeathAnimFrames;

public void OnPluginStart()
{
	g_cWitchHealth = FindConVar("z_witch_health");	
	g_cTargetRemoveTimer = CreateConVar("neb_infectedhp_barfade", "3.0", "how long does an HP bar linger on the screen", CVAR_FLAGS);
	g_cTempRemoveTimer = CreateConVar("neb_infectedhp_recentdmgfade", "0.5", "time to pass without dmg dealt for the recent dmg section of an hp bar to fade away", CVAR_FLAGS);
	g_cTempDecayAmount = CreateConVar("neb_infectedhp_decay", "10", "when the recent damage begins to fade, decay recorded damage by this much per frame (servers with slow framerates will probably need this increased, otherwise the decay will take too long)", CVAR_FLAGS);
	g_cUpdateInterval = CreateConVar("neb_infectedhp_update_interval", "4", "render non priority updates to pending clients every X server frame. Default will be about 25fps at 100 tickrate", CVAR_FLAGS);
	g_cDeathAnimPattern = CreateConVar("neb_infectedhp_deathanim_pattern", "...,,,", "presented to its killer, an SI's empty healthbar will have its bottom bezel animated with this pattern moving along it", CVAR_FLAGS);

	g_cTargetRemoveTimer.AddChangeHook(ConVarChanged_Cvars);
	g_cTempRemoveTimer.AddChangeHook(ConVarChanged_Cvars);
	g_cTempDecayAmount.AddChangeHook(ConVarChanged_Cvars);
	g_cUpdateInterval.AddChangeHook(ConVarChanged_Cvars);
	g_cDeathAnimPattern.AddChangeHook(ConVarChanged_Cvars);

	ReadConVars();

	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("player_hurt", event_player_hurt);
	HookEvent("infected_hurt", event_infected_hurt);
	HookEvent("witch_spawn", event_witch_spawn);
	HookEvent("witch_killed", event_witch_killed);
	HookEvent("round_start_pre_entity", event_round_start_pre_entity);

	g_hcShowAll = RegClientCookie("sihp_show_all", "Show/hide all enemy healthbars [0 to hide, 1 (default) to show]", CookieAccess_Public);
	g_hcShowBoss = RegClientCookie("sihp_show_boss", "Show/hide boss hp bars [0 to hide, 1 (default) to show] (they're coded to be separate, so this won't magically make it merge with the regular hp bar. Witch/tank hp bars will never show period with this off)", CookieAccess_Public);
	g_hcShowNormal = RegClientCookie("sihp_show_normal", "Show/hide non-boss SI hp bars [0 to hide, 1 (default) to show] (hiding will only make boss bars visible! there is no option currently to merge them to share the same bar)", CookieAccess_Public);
	g_hcShowTemp = RegClientCookie("sihp_show_recent_dmg", "Show/hide the recently dealt damage (by you) representation in enemy hp bars [0 to hide, 1 (default) to show]", CookieAccess_Public);
	g_hcShowKillConf = RegClientCookie("sihp_show_kill_confirm", "Show/hide the kill confirmed indicator on dead SI's health bars (empty bars display with a unique notifier if you're the one who got the kill) [0 to hide, 1 (default) to show", CookieAccess_Public);

	CreateTimer(1.0, refreshRepeat, _, TIMER_REPEAT); // center text fades in 2 seconds, so we refresh it every 1 second to allow the plugin's convar to extend that fadeout time
	RequestFrame(updateLoop);
}

public void OnClientCookiesCached(int client)
{
	char sCookie[8];

	g_baCookieShowAll[client] = true;
	g_baCookieShowBoss[client] = true;
	g_baCookieShowNormal[client] = true;
	g_baCookieShowKillConf[client] = false;
	g_baCookieShowTemp[client] = false;
	
	GetClientCookie(client, g_hcShowAll, sCookie, sizeof(sCookie));
	if(sCookie[0] == '0') g_baCookieShowAll[client] = false;
	
	GetClientCookie(client, g_hcShowBoss, sCookie, sizeof(sCookie));
	if(sCookie[0] == '0') g_baCookieShowBoss[client] = false;

	GetClientCookie(client, g_hcShowNormal, sCookie, sizeof(sCookie));
	if(sCookie[0] == '0') g_baCookieShowNormal[client] = false;

	GetClientCookie(client, g_hcShowKillConf, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_baCookieShowKillConf[client] = true;

	GetClientCookie(client, g_hcShowTemp, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_baCookieShowTemp[client] = true;
}

public void OnConfigsExecuted()
{
	ReadConVars();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_fTargetTimer = g_cTargetRemoveTimer.FloatValue;
	g_fTempTimer = g_cTempRemoveTimer.FloatValue;
	g_iDecayAmount = g_cTempDecayAmount.IntValue;
	g_iUpdateInterval = g_cUpdateInterval.IntValue;

	char sPattern[16];
	g_cDeathAnimPattern.GetString(sPattern, sizeof(sPattern));
	g_iMaxDeathAnimFrames = strlen(sPattern);
}

public void OnClientPutInServer(int iClient)
{
	for(int i = 0; i < 2; i++)
	{
		g_iaClientTarget[iClient][i] = 0;
		g_iaClientTempAmount[iClient][i] = 0;
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

//////////////////////////
// Data handling
/////////////////////////

void event_round_start_pre_entity(Event event, const char[] name, bool dontBroadcast)
{
	g_bInPlay = false; // prevent the regular refresh timer from executing its code during loads
}

// initialize data for newly spawned SI
void event_player_spawn(Event hEvent, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iClient)) return;

	TimerSpawn(INVALID_HANDLE, hEvent.GetInt("userid"));
	CreateTimer(0.5, TimerSpawn, hEvent.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);

	if(!g_bInPlay) g_bInPlay = true;
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
////

void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim)) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) iAttacker = 0;
	if(iAttacker)
	{
		g_iaVictimKilledBy[iVictim] = GetClientUserId(iAttacker);
		updateClientBar(iAttacker);
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
		updateClientBar(iAttacker);
	}

	g_baTankDying[iVictim] = true;
	PrintHintTextToAll("++ %N is DEAD ++", iVictim);
}

void event_witch_spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	PrintToServer("witch health set!");
	int iEntity = hEvent.GetInt( "witchid" );
	int iHealth = (g_cWitchHealth == INVALID_HANDLE) ? 1000 : g_cWitchHealth.IntValue;
	g_iaWitchMAX[iEntity] = iHealth;
	g_iaWitchHP[iEntity] = iHealth;
	g_iaVictimKilledBy[iEntity] = 0;
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
		updateClientBar(iAttacker);
	}

	constructBar(iVictim, iAttacker, true, g_iaWitchMAX[iVictim], 0, "Witch");
}

///////////////
// update data
///////////////
// Control loop - non-priority updates will be added to a buffer, which is executed by this loop
//////////////////
void updateLoop()
{
	static int iFrameCount;
	iFrameCount++;
	if(iFrameCount >= g_iUpdateInterval)
	{
		// reset frame counter
		iFrameCount = 0;

		// update animation of kill confirmations to the next frame
		g_iDeathAnimFrame++;
		if(g_iDeathAnimFrame >= g_iMaxDeathAnimFrames) g_iDeathAnimFrame = 0;

		// render pending client updates
		static int iClient;
		for(int i = 0; i < sizeof(g_iaClientUpdatePending); i++)
		{
			if(g_iaClientUpdatePending[i])
			{
				iClient = GetClientOfUserId(g_iaClientUpdatePending[i]);
				if(iClient) updateClientBar(iClient);
				g_iaClientUpdatePending[i] = 0;
			}
		}
	}
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
		g_baClientInDecay[iAttacker][iBarIndex] = false;
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
	if(iNowHP && iNowHP > g_iaPrevHP[iVictim]) iNowHP = g_iaPrevHP[iVictim];
	else g_iaPrevHP[iVictim] = iNowHP;

	if(iMaxHP < g_iaPrevMAX[iVictim]) iMaxHP = g_iaPrevMAX[iVictim];	
	if(iMaxHP < iNowHP)
	{
		iMaxHP = iNowHP;
		g_iaPrevMAX[iVictim] = iNowHP;
	}	
	if(iMaxHP < 1) iMaxHP = 1;

	if(iAttacker) g_iaClientTempAmount[iAttacker][iBarIndex] += iDmgDealt; // Update temp health data for this attacker

	// %N will only work for clients, and since witches get passed to the same function, we should get name in these parent functions instead
	static char sClientName[MAX_NAME_LENGTH];
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
		if(IsValidHandle(g_htClientTargetKeep[iAttacker][iBarIndex])) delete g_htClientTargetKeep[iAttacker][iBarIndex];
		g_htClientTargetKeep[iAttacker][iBarIndex] = CreateTimer(g_fTargetTimer, refreshTargetRemoval, dTargetData);

		DataPack dTempData = CreateDataPack();
		dTempData.WriteCell(GetClientUserId(iAttacker));
		dTempData.WriteCell(iBarIndex);
		dTempData.Reset();		
		if(IsValidHandle(g_htClientTempKeep[iAttacker][iBarIndex])) delete g_htClientTempKeep[iAttacker][iBarIndex];
		g_htClientTempKeep[iAttacker][iBarIndex] = CreateTimer(g_fTempTimer, refreshTempRemoval, dTempData);

		// Temp decay data set
		g_iaClientDecayPortion[iAttacker][iBarIndex] = RoundToCeil(float(iMaxHP) / float(iBarIndex ? BARLEN_BOSS : BARLEN_NORMAL));
	}
}

void event_infected_hurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = hEvent.GetInt("entityid");
	if(!nsIsEntityValid(iVictim) || g_iaWitchHP[iVictim] == -1) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) iAttacker = 0;
	
	int iDmgDealt = hEvent.GetInt("amount");
	if(iDmgDealt > g_iaWitchHP[iVictim]) iDmgDealt = g_iaWitchHP[iVictim];	
	
	int iNowHP = g_iaWitchHP[iVictim] - iDmgDealt;
	if(iNowHP <= 0 || g_iaWitchMAX[iVictim] < 0) iNowHP = 0;
	if(iNowHP && iNowHP > g_iaWitchHP[iVictim]) iNowHP = g_iaWitchHP[iVictim];
	else g_iaWitchHP[iVictim] = iNowHP;
	
	int iMaxHP = g_iaWitchMAX[iVictim];
	if(iMaxHP < 1) iMaxHP = 1;

	if(iAttacker)
	{
		// Update this attacker's target
		if(g_iaClientTarget[iAttacker][BAR_BOSS] != iVictim)
		{
			g_iaClientTempAmount[iAttacker][BAR_BOSS] = 0;
		}
		g_iaClientTarget[iAttacker][BAR_BOSS] = iVictim;
		g_baTargetIsWitch[iAttacker] = true;

		// Update temp health data for this attacker
		g_iaClientTempAmount[iAttacker][BAR_BOSS] += iDmgDealt;
	}

	constructBar(iVictim, iAttacker, true, iMaxHP, iNowHP, "Witch");

	// Start data reset timers
	if(iAttacker)
	{
		DataPack dTargetData = CreateDataPack();
		dTargetData.WriteCell(GetClientUserId(iAttacker));
		dTargetData.WriteCell(BAR_BOSS);
		dTargetData.Reset();
		if(IsValidHandle(g_htClientTargetKeep[iAttacker][BAR_BOSS])) delete g_htClientTargetKeep[iAttacker][BAR_BOSS];
		g_htClientTargetKeep[iAttacker][BAR_BOSS] = CreateTimer(g_fTargetTimer, refreshTargetRemoval, dTargetData);

		DataPack dTempData = CreateDataPack();
		dTempData.WriteCell(GetClientUserId(iAttacker));
		dTempData.WriteCell(BAR_BOSS);
		dTempData.Reset();
		if(IsValidHandle(g_htClientTempKeep[iAttacker][BAR_BOSS])) delete g_htClientTempKeep[iAttacker][BAR_BOSS];
		g_htClientTempKeep[iAttacker][BAR_BOSS] = CreateTimer(g_fTempTimer, refreshTempRemoval, dTempData);

		// Temp decay data set
		g_baClientInDecay[iAttacker][BAR_BOSS] = false;
		g_iaClientDecayPortion[iAttacker][BAR_BOSS] = RoundToCeil(float(iMaxHP) / float(BARLEN_BOSS));
	}
}

// refresh triggers
Action refreshRepeat(Handle hTimer)
{
	if(!g_bInPlay) return Plugin_Continue;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsSurvivor(i)) continue;
		if(g_iaClientTarget[i][BAR_NORMAL] || g_iaClientTarget[i][BAR_BOSS]) updateClientBar(i);
	}
	return Plugin_Continue;
}

Action refreshTempRemoval(Handle hTimer, DataPack dData)
{
	int iClient = GetClientOfUserId(dData.ReadCell());
	if(!nsIsSurvivor(iClient))
	{
		delete dData;
		return Plugin_Handled;
	}
	int iBarIndex = dData.ReadCell();	

	// INSTANT
	/*g_iaClientTempAmount[iClient][iBarIndex] = 0;
	updateClientBar(iClient);
	delete dData;*/

	// DECAY
	dData.WriteCell(0);
	dData.Reset();
	g_baClientInDecay[iClient][iBarIndex] = true;
	RequestFrame(decayTemp, dData);

	return Plugin_Handled;
}

void decayTemp(DataPack dData)
{
	int iClient = GetClientOfUserId(dData.ReadCell());	
	if(iClient)
	{
		int iBarIndex = dData.ReadCell();
		if(g_baClientInDecay[iClient][iBarIndex])
		{
			DataPackPos dpPosition = GetPackPosition(dData);
			int iCount = dData.ReadCell();
			iCount++;	

			g_iaClientTempAmount[iClient][iBarIndex] -= g_iDecayAmount;
			if(g_iaClientTempAmount[iClient][iBarIndex] < 0) g_iaClientTempAmount[iClient][iBarIndex] = 0;

			if((iCount*g_iDecayAmount) >= g_iaClientDecayPortion[iClient][iBarIndex] || !g_iaClientTempAmount[iClient][iBarIndex])
			{
				updateClientBar(iClient);
				iCount = 0;
			}
			SetPackPosition(dData, dpPosition);
			dData.WriteCell(iCount);
			dData.Reset();

			if(g_iaClientTempAmount[iClient][iBarIndex])
			{
				RequestFrame(decayTemp, dData);
				return;
			}
		}		
	}	
	delete dData;
	return;
}

Action refreshTargetRemoval(Handle hTimer, DataPack dData)
{
	int iClient = GetClientOfUserId(dData.ReadCell());
	if(!nsIsSurvivor(iClient))
	{
		delete dData;
		return Plugin_Handled;
	}
	int iBarIndex = dData.ReadCell();
	if(iBarIndex) g_baTargetIsWitch[iClient] = false;
	delete dData;

	g_iaClientTarget[iClient][iBarIndex] = 0;
	updateClientBar(iClient);

	return Plugin_Handled;
}

void refreshVictim(int iVictim, int iBarIndex)
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
			if(g_iaClientTarget[i][iBarIndex] != GetClientUserId(iVictim)) continue;
		}
		updateClientBar(i);	
	}
}

// update/render bar for a client
void updateClientBar(int iClient)
{
	if(!g_baCookieShowAll[iClient]) return;

	// prevent updates coinciding in the same frame
	if(g_baClientRendered[iClient]) return;
	else
	{
		g_baClientRendered[iClient] = true;
		RequestFrame(removeRenderedFlag, iClient);
	}

	char sBarModifiedNormal[BARMAXLEN_NORMAL], sBarModifiedBoss[BARMAXLEN_BOSS];
	int iVictim = GetClientOfUserId(g_iaClientTarget[iClient][BAR_NORMAL]);

	if(g_baCookieShowNormal[iClient] && iVictim && g_saConstructedBarsNormal[iVictim][0])
	{
		sBarModifiedNormal = g_saConstructedBarsNormal[iVictim];
		if(g_iaClientTempAmount[iClient][BAR_NORMAL])
			formatPersonalized(sBarModifiedNormal, g_iaClientTempAmount[iClient][BAR_NORMAL], GetEntProp(iVictim, Prop_Send, "m_iMaxHealth") & 0xffff, GetEntProp(iVictim, Prop_Send, "m_iHealth"), BARLEN_NORMAL);
		if(g_iaVictimKilledBy[iVictim] == GetClientUserId(iClient))
			formatDeathByYou(sBarModifiedNormal, BARLEN_NORMAL, g_iaCookieKillConfSize[iClient], g_saCookieCustomKillConf[iClient]);
	}
	
	iVictim = 0;
	if(g_baTargetIsWitch[iClient])
	{
		if(nsIsEntityValid(g_iaClientTarget[iClient][BAR_BOSS]))
		{
			static char sClassName[32];
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
		if(g_baCookieShowTemp[iClient] && g_iaClientTempAmount[iClient][BAR_BOSS])
			formatPersonalized(sBarModifiedBoss, g_iaClientTempAmount[iClient][BAR_BOSS], (g_baTargetIsWitch[iClient] ? g_iaWitchMAX[iVictim] : (GetEntProp(iVictim, Prop_Send, "m_iMaxHealth") & 0xffff)), (g_baTargetIsWitch[iClient] ? g_iaWitchHP[iVictim] : GetEntProp(iVictim, Prop_Send, "m_iHealth")), BARLEN_BOSS);
		if(g_iaVictimKilledBy[iVictim] == GetClientUserId(iClient))
			formatDeathByYou(sBarModifiedBoss, BARLEN_BOSS, g_iaCookieKillConfSize[iClient], g_saCookieCustomKillConf[iClient]);
	}
	PrintCenterText(iClient, "%s%s%s%s", ANCHORLINE, sBarModifiedNormal, LINEBREAK, sBarModifiedBoss);
}

void removeRenderedFlag(int iClient)
{
	g_baClientRendered[iClient] = false;
}

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
	
	if(iPriorityClient) updateClientBar(iPriorityClient); // save processing time for this client's perspective
	refreshVictim(iVictim, bIsBoss ? BAR_BOSS : BAR_NORMAL);
}

void formatPersonalized(const char[] sModify, int iTempAmount, int iMaxHP, int iNowHP, int iLength)
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

void formatDeathByYou(char[] sModify, int iLength, int iSize, const char[] sIndicator)
{
	for(int i = (iLength/2); i < ((iLength/2) + 8); i++)
		sModify[i] = '&'; // mark what to replace
	/*char sSearch[24];
	for(int i = 0; i < iSize; i++)
		sSearch[i] = '&';*/
	ReplaceString(sModify, (iLength > BARLEN_NORMAL) ? BARMAXLEN_BOSS : BARMAXLEN_NORMAL, "&&&&&&&&", "uwu");
}
