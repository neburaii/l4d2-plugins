/**
 * - 2025-05-07 | version 2.1
 * 		- fixed memory leaks
 * 		- rewrote plugin to separate target data from the infected entity, allowing the
 * 		  plugin to fully function after the infected is disconnected
 * 		- code is just generally improved
 */

#pragma newdecls required
#pragma semicolon 1

#include <clientprefs>
#include <sdkhooks>
#include <neb_stocks>

public Plugin myinfo = 
{
	name = "Infected HP Bars",
	author = "Neburai",
	description = "Renders health bars of the SI players most recently damaged. Uses the center text hud element",
	version = "2.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/infected_hp"
};

#define CVAR_FLAGS			FCVAR_NOTIFY

// to keep alignment of bars consistent, we need 1 line within the center text
// message to be the longest, and of a static length. Any line shorter than
// the longest has their first character aligned with the first character of the
// longest line. Downside of ensuring this alignment is it takes up a lot of bytes.
// Adding additional elements to center text or extending the length of these bars
// may require this invisible line to be scrapped
#define ANCHORLINE			"                                                                                                   \10"
// separate bars into different lines with this
#define LINEBREAK			"\10"

// max length of just the bars themselves
#define BAR_LEN				40
#define BOSSBAR_LEN			60

// max length of the bars + other elements within that line
#define BAR_MAXLEN			68
#define BOSSBAR_MAXLEN		86

#define BAR_NORMAL			0
#define BAR_BOSS			1
#define MAX_BARS			2

char	g_sInfectedNames[ZCLASS_TRUEMAX+1][] = 
{
	"",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank"
};


bool	g_bRenderedThisFrame[MAXPLAYERS_L4D2+1], g_bSkipPlayerDeath[MAXPLAYERS_L4D2+1], g_bClientDied[MAXPLAYERS_L4D2+1];

		// track infected health
int		g_iInfectedHP[MAXENTITES+1], g_iInfectedMaxHP[MAXENTITES+1];

		// info of each client's personalized hp bar
int		g_iTarget[MAXPLAYERS_L4D2+1][MAX_BARS],
		g_iTargetClass[MAXPLAYERS_L4D2+1][MAX_BARS],
		g_iRecentDamage[MAXPLAYERS_L4D2+1][MAX_BARS], 
		g_iTargetDeadMaxHP[MAXPLAYERS_L4D2+1][MAX_BARS];

bool	g_bIsKiller[MAXPLAYERS_L4D2+1][MAX_BARS],
		g_bDecayRecentDamage[MAXPLAYERS_L4D2+1][MAX_BARS];

		// animation data
int		g_iDeathAnimFrame, g_iMaxDeathAnimFrames,
		g_iSubtractRecentDamage[MAXPLAYERS_L4D2+1][MAX_BARS];

		// timers for delayed effects
Handle	g_hTimerRemoveTarget[MAXPLAYERS_L4D2+1][MAX_BARS],
		g_hTimerDecayRecentDamage[MAXPLAYERS_L4D2+1][MAX_BARS];

		// ConVars
ConVar	g_cTargetTime, g_cRecentDamageTime, g_cFramesToSkip, g_cDeathAnimPattern, g_CDecayAnimLength,
		g_cWitchMaxHealth;
char	g_sCVDeathAnimPattern[16];
int		g_iCVFramesToSkip, g_iCVDecayAnimLength, g_iCVWitchMaxHealth;
float	g_fCVTargetTime, g_fCVRecentDamageTime;

		// Cookies
Handle	g_hCookieShowBar[MAX_BARS], g_hCookieShowRecentDamage,
		g_hCookieShowDeath, g_hCookieShowAll, g_hCookieUpdateOnlyMyDamage;

bool	g_bCookieShowBar[MAXPLAYERS_L4D2+1][MAX_BARS],
		g_bCookieShowRecentDamage[MAXPLAYERS_L4D2+1],
		g_bCookieShowDeath[MAXPLAYERS_L4D2+1],
		g_bCookieShowAll[MAXPLAYERS_L4D2+1],
		g_bCookieUpdateOnlyMyDamage[MAXPLAYERS_L4D2+1];

public void OnPluginStart()
{
	// events
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("witch_spawn", event_witch_spawn);

	HookEvent("player_hurt", event_player_hurt);
	HookEvent("infected_hurt", event_infected_hurt);

	HookEvent("player_death", event_player_death);
	HookEvent("player_incapacitated", event_player_incapacitated);
	HookEvent("witch_killed", event_witch_killed);

	// convars
	g_cWitchMaxHealth = FindConVar("z_witch_health");
	g_cTargetTime = CreateConVar("infectedhp_target_remove_time", "2.5", "How long in seconds must a client not deal damage to a target for it to be removed as an active target?", CVAR_FLAGS, true, 0.1);
	g_cRecentDamageTime = CreateConVar("infectedhp_recent_damage_time", "0.64", "How long in seconds must a client not deal damage to a target for the recent damage to start decaying away?", CVAR_FLAGS, true, 0.1);
	g_cFramesToSkip = CreateConVar("infectedhp_frames_to_skip", "4", "How many server frames to skip between bar updates?", CVAR_FLAGS, true, 0.0);
	g_cDeathAnimPattern = CreateConVar("infectedhp_death_anim_pattern", "...,.,.,", "The pattern of the 'killed by you' animation", CVAR_FLAGS);
	g_CDecayAnimLength = CreateConVar("infectedhp_decay_anim_length", "8", "How long in seconds the 'killed by you' animation should last", CVAR_FLAGS, true, 1.0);

	g_cTargetTime.AddChangeHook(OnConVarChanged);
	g_cRecentDamageTime.AddChangeHook(OnConVarChanged);
	g_cFramesToSkip.AddChangeHook(OnConVarChanged);
	g_cDeathAnimPattern.AddChangeHook(OnConVarChanged);
	g_CDecayAnimLength.AddChangeHook(OnConVarChanged);
	g_cWitchMaxHealth.AddChangeHook(OnConVarChanged);

	readConVars();

	// cookies
	g_hCookieShowAll = RegClientCookie("sihp_show_all", "Show/hide all enemy healthbars [0 to hide, 1 (default) to show]", CookieAccess_Public);
	g_hCookieShowBar[BAR_NORMAL] = RegClientCookie("sihp_show_normal", "Show/hide non-boss SI hp bars [0 to hide, 1 (default) to show] (hiding will only make boss bars visible! there is no option currently to merge them to share the same bar)", CookieAccess_Public);
	g_hCookieShowBar[BAR_BOSS] = RegClientCookie("sihp_show_boss", "Show/hide boss hp bars [0 to hide, 1 (default) to show] (they're coded to be separate, so this won't magically make it merge with the regular hp bar. Witch/tank hp bars will never show period with this off)", CookieAccess_Public);
	g_hCookieShowRecentDamage = RegClientCookie("sihp_show_temp", "Show/hide the recently dealt damage (by you) representation in enemy hp bars [0 (default) to hide, 1 to show]", CookieAccess_Public);
	g_hCookieShowDeath = RegClientCookie("sihp_show_death", "Show/hide the kill confirmed indicator on dead SI's health bars (empty bars display with a unique notifier if you're the one who got the kill) [0 (default) to hide, 1 to show", CookieAccess_Public);
	g_hCookieUpdateOnlyMyDamage = RegClientCookie("sihp_priority_only", "Update HP bar only when you deal damage [0 (default) to update whenever your target takes damage from any source, 1 to update only when you deal damage (behaviour of most center text based hp scripts)]", CookieAccess_Public);

	// init timers as null
	nullifyTimers();	

	// load cookies if clients are in game already (plugin restart)
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsClientValid(i)) continue;
		loadCookies(i);
	}
}

public void OnMapEnd()
{
	nullifyTimers();
}

void nullifyTimers()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		for(int bar = 0; bar < MAX_BARS; bar++)
		{
			g_hTimerRemoveTarget[client][bar] = null;
			g_hTimerDecayRecentDamage[client][bar] = null;
		}
	}
}

/**********
 * CONVARS
 *********/

void OnConVarChanged(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	readConVars();
}

void readConVars()
{
	g_fCVTargetTime = g_cTargetTime.FloatValue;
	g_fCVRecentDamageTime = g_cRecentDamageTime.FloatValue;
	g_iCVFramesToSkip = g_cFramesToSkip.IntValue;
	g_cDeathAnimPattern.GetString(g_sCVDeathAnimPattern, sizeof(g_sCVDeathAnimPattern));
	g_iMaxDeathAnimFrames = strlen(g_sCVDeathAnimPattern);
	g_iCVDecayAnimLength = g_CDecayAnimLength.IntValue;
	g_iCVWitchMaxHealth = g_cWitchMaxHealth.IntValue;
}

/**********
 * COOKIES
 *********/

public void OnClientCookiesCached(int iClient)
{
	loadCookies(iClient);
}

void loadCookies(int iClient)
{
	static char sCookie[8];

	// enforce defaults
	g_bCookieShowAll[iClient] = true;
	g_bCookieShowBar[iClient][BAR_NORMAL] = true;
	g_bCookieShowBar[iClient][BAR_BOSS] = true;
	g_bCookieShowRecentDamage[iClient] = false;
	g_bCookieShowDeath[iClient] = false;
	g_bCookieUpdateOnlyMyDamage[iClient] = false;

	// read cookies, overriding defaults
	GetClientCookie(iClient, g_hCookieShowAll, sCookie, sizeof(sCookie));
	if(sCookie[0] == '0') g_bCookieShowAll[iClient] = false;
	for(int i = 0; i < MAX_BARS; i++)
	{
		GetClientCookie(iClient, g_hCookieShowBar[i], sCookie, sizeof(sCookie));
		if(sCookie[0] == '0') g_bCookieShowBar[iClient][i] = false;
	}
	GetClientCookie(iClient, g_hCookieShowRecentDamage, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_bCookieShowRecentDamage[iClient] = true;
	GetClientCookie(iClient, g_hCookieShowDeath, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_bCookieShowDeath[iClient] = true;
	GetClientCookie(iClient, g_hCookieUpdateOnlyMyDamage, sCookie, sizeof(sCookie));
	if(sCookie[0] == '1') g_bCookieUpdateOnlyMyDamage[iClient] = true;
}

/*****************************
 * RESET CLIENT'S TARGET DATA
 ****************************/

public void OnClientPutInServer(int iClient)
{
	for(int bar = 0; bar < MAX_BARS; bar++)
	{
		if(g_hTimerRemoveTarget[iClient][bar] != null) delete g_hTimerRemoveTarget[iClient][bar];
		if(g_hTimerDecayRecentDamage[iClient][bar] != null) delete g_hTimerDecayRecentDamage[iClient][bar];
		g_bDecayRecentDamage[iClient][bar] = false;
		g_iTargetDeadMaxHP[iClient][bar] = -1;
		g_iRecentDamage[iClient][bar] = 0;
		g_iTarget[iClient][bar] = -1;
	}

	g_bSkipPlayerDeath[iClient] = false;
	g_bClientDied[iClient] = false;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	g_iInfectedHP[iEntity] = -1;
	g_iInfectedMaxHP[iEntity] = -1;
}

/**************
 * TRACK MAXHP
 **************/

void event_player_spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iClient)) return;

	g_iInfectedMaxHP[iClient] = GetEntProp(iClient, Prop_Send, "m_iMaxHealth");
	g_iInfectedHP[iClient] = GetEntProp(iClient, Prop_Send, "m_iHealth");
}

void event_witch_spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iWitch = hEvent.GetInt("witchid");
	if(!nsIsEntityValid(iWitch)) return;

	g_iInfectedMaxHP[iWitch] = (g_cWitchMaxHealth == null) ? 1000 : g_iCVWitchMaxHealth;
	g_iInfectedHP[iWitch] = g_iInfectedMaxHP[iWitch];
}

/**************
 * TRACK DAMAGE
 *************/

void event_player_hurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim) || g_bClientDied[iVictim]) return;

	int iAmount = hEvent.GetInt("dmg_health");
	if(iAmount > g_iInfectedHP[iVictim]) iAmount = g_iInfectedHP[iVictim];

	g_iInfectedHP[iVictim] = hEvent.GetInt("health");
	if(g_iInfectedHP[iVictim] < 0) g_iInfectedHP[iVictim] = 0;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) return;

	int iClass = nsGetInfectedClass(iVictim);

	updateBar(iAttacker, iVictim, iClass, iAmount);
}

void event_infected_hurt(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = hEvent.GetInt("entityid");
	if(!nsIsEntityValid(iVictim) || g_iInfectedMaxHP[iVictim] <= 0) return;

	int iAmount = hEvent.GetInt("amount");
	if(iAmount <= 0) return;

	g_iInfectedHP[iVictim] -= iAmount;
	if(g_iInfectedHP[iVictim] < 0) g_iInfectedHP[iVictim] = 0;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if(!nsIsSurvivor(iAttacker)) return;

	updateBar(iAttacker, iVictim, ZCLASS_WITCH, iAmount);
}

/***************
 * TRACK DEATHS
 ***************/

void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iVictim) || g_bSkipPlayerDeath[iVictim]) return;

	g_bClientDied[iVictim] = true;

	int iClass = nsGetInfectedClass(iVictim);
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	if(nsIsSurvivor(iAttacker)) updateBar(iAttacker, iVictim, iClass, 0, true);		
	setTargetAsDead(iVictim, iClass, g_iInfectedMaxHP[iVictim]);
}

void event_witch_killed(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iWitch = hEvent.GetInt("witchid");
	if(!nsIsEntityValid(iWitch)) return;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("userid"));

	if(nsIsSurvivor(iAttacker)) updateBar(iAttacker, iWitch, ZCLASS_WITCH, 0, true);
	setTargetAsDead(iWitch, ZCLASS_WITCH, g_iInfectedMaxHP[iWitch]);
}

// tank should be labeled dead here instead of player_death
void event_player_incapacitated(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iTank = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsInfected(iTank, ZCLASS_TANK)) return;

	g_bClientDied[iTank] = true;
	g_bSkipPlayerDeath[iTank] = true;

	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	if(nsIsSurvivor(iAttacker)) updateBar(iAttacker, iTank, ZCLASS_TANK, 0, true);
	setTargetAsDead(iTank, ZCLASS_TANK, g_iInfectedMaxHP[iTank]);
}

// in case an SI was kicked from admin etc, the plugin should treat this as death
public void OnClientDisconnect(int iClient)
{
	if(g_bClientDied[iClient] || !nsIsInfected(iClient)) return;

	g_bClientDied[iClient] = true;

	int iClass = nsGetInfectedClass(iClient);	
	setTargetAsDead(iClient, iClass, g_iInfectedMaxHP[iClient]);
}

// if it dies and disconnects, its maxHP will be missing. This function will remember the maxHP for
// this client's target, and it also acts as a label for it being dead, avoiding checking the entity index later
void setTargetAsDead(int iTarget, int iClass, int iMaxHP)
{
	int iBar = BAR_NORMAL;
	if(iClass == ZCLASS_WITCH || iClass == ZCLASS_TANK) iBar = BAR_BOSS;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsSurvivor(i) || !IsPlayerAlive(i)) continue;
		if(g_iTarget[i][iBar] == iTarget) g_iTargetDeadMaxHP[i][iBar] = iMaxHP;
	}
}

/*********
 * UPDATES
 *********/

void updateBar(int iClient, int iTarget, int iClass, int iDamage, bool bDeath = false)
{
	int iBar = BAR_NORMAL;
	if(iClass == ZCLASS_WITCH || iClass == ZCLASS_TANK) iBar = BAR_BOSS;

	// update this client's active target
	if(g_hTimerRemoveTarget[iClient][iBar] != null) delete g_hTimerRemoveTarget[iClient][iBar];
	if(g_iTarget[iClient][iBar] != iTarget) g_iRecentDamage[iClient][iBar] = 0;
	g_iTarget[iClient][iBar] = iTarget;
	g_hTimerRemoveTarget[iClient][iBar] = CreateTimer(g_fCVTargetTime, iBar ? timerRemoveBossTarget : timerRemoveTarget, iClient, TIMER_FLAG_NO_MAPCHANGE);

	// update this client's recent damage
	if(g_hTimerDecayRecentDamage[iClient][iBar] != null) delete g_hTimerDecayRecentDamage[iClient][iBar];
	g_iRecentDamage[iClient][iBar] += iDamage;
	g_bDecayRecentDamage[iClient][iBar] = false;
	g_hTimerDecayRecentDamage[iClient][iBar] = CreateTimer(g_fCVRecentDamageTime, iBar ? timerDecayRecentBossDamage : timerDecayRecentDamage, iClient, TIMER_FLAG_NO_MAPCHANGE);

	// update this client's target class
	g_iTargetClass[iClient][iBar] = iClass;

	// update the killer status of this client
	g_bIsKiller[iClient][iBar] = false;
	g_iTargetDeadMaxHP[iClient][iBar] = -1;
	if(bDeath) g_bIsKiller[iClient][iBar] = true;

	// render now for this client only
	renderBars(iClient, iClient);
}

void timerRemoveTarget(Handle hTimer, int iClient)
{
	g_hTimerRemoveTarget[iClient][BAR_NORMAL] = null;
	removeTarget(iClient, BAR_NORMAL);
}

void timerRemoveBossTarget(Handle hTimer, int iClient)
{
	g_hTimerRemoveTarget[iClient][BAR_BOSS] = null;
	removeTarget(iClient, BAR_BOSS);
}

void removeTarget(int iClient, int iBar)
{
	g_iTarget[iClient][iBar] = -1;

	if(g_hTimerDecayRecentDamage[iClient][iBar] != null) delete g_hTimerDecayRecentDamage[iClient][iBar];
	g_iRecentDamage[iClient][iBar] = 0;

	g_iTargetClass[iClient][iBar] = -1;

	g_iTargetDeadMaxHP[iClient][iBar] = -1;
	g_bIsKiller[iClient][iBar] = false;
}

void timerDecayRecentDamage(Handle hTimer, int iClient)
{
	g_hTimerDecayRecentDamage[iClient][BAR_NORMAL] = null;
	decayRecentDamage(iClient, BAR_NORMAL);
}

void timerDecayRecentBossDamage(Handle hTimer, int iClient)
{
	g_hTimerDecayRecentDamage[iClient][BAR_BOSS] = null;
	decayRecentDamage(iClient, BAR_BOSS);
}

void decayRecentDamage(int iClient, int iBar)
{
	g_bDecayRecentDamage[iClient][iBar] = true;
	g_iSubtractRecentDamage[iClient][iBar] = g_iRecentDamage[iClient][iBar] / g_iCVDecayAnimLength;
}

/********
 * RENDER
 ********/

public void OnGameFrame()
{
	static int iFramesSkipped;
	iFramesSkipped++;
	if(iFramesSkipped >= g_iCVFramesToSkip)
	{
		iFramesSkipped = 0;

		// update death animation frame
		g_iDeathAnimFrame++;
		if(g_iDeathAnimFrame >= g_iMaxDeathAnimFrames) g_iDeathAnimFrame = 0;		

		// decay recent damage
		for(int i = 1; i <= MaxClients; i++)
		{
			for(int bar = 0; bar < MAX_BARS; bar++)
			{
				if(g_bDecayRecentDamage[i][bar])
				{
					g_iRecentDamage[i][bar] -= g_iSubtractRecentDamage[i][bar];
					if(g_iRecentDamage[i][bar] < 0) g_iRecentDamage[i][bar] = 0;
					if(!g_iRecentDamage[i][bar]) g_bDecayRecentDamage[i][bar] = false;
				}
			}
		}

		// render bars
		int iClient;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!nsIsSurvivor(i) || g_bCookieUpdateOnlyMyDamage[i]) continue;			

			// is this player seeing their own bars, or spectating those of another player?
			if(IsClientObserver(i))
			{
				iClient = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				if(!nsIsSurvivor(iClient)) continue;
			}
			else if(IsPlayerAlive(i)) iClient = i;
			else continue;

			renderBars(i, iClient);
		}
	}
}

void renderBars(int iViewer, int iOwner)
{
	if(g_bRenderedThisFrame[iViewer] || !g_bCookieShowAll[iViewer]) return;
	g_bRenderedThisFrame[iViewer] = true;
	RequestFrame(resetRenderedThisFrame, iViewer);

	static char sBar[BAR_MAXLEN], sBossBar[BOSSBAR_MAXLEN];
	
	constructBar(sBar, BAR_NORMAL, BAR_LEN, BAR_MAXLEN, iViewer, iOwner);
	constructBar(sBossBar, BAR_BOSS, BOSSBAR_LEN, BOSSBAR_MAXLEN, iViewer, iOwner);

	PrintCenterText(iViewer, "%s%s%s%s", ANCHORLINE, sBar, LINEBREAK, sBossBar);
}

void constructBar(char[] sBar, int iBarType, int iBarLength, int iMaxLength, int iViewer, int iOwner)
{
	static char sBarTemplate[BOSSBAR_MAXLEN];
	int iNowHP, iMaxHP, iAmount, i;

	sBar[0] = 0;
	if(g_bCookieShowBar[iViewer][iBarType])
	{
		if(g_iTargetDeadMaxHP[iOwner][iBarType] > 0)
		{
			iNowHP = 0;
			iMaxHP = g_iTargetDeadMaxHP[iOwner][iBarType];
		}
		else if(g_iTarget[iOwner][iBarType] != -1)
		{
			iNowHP = g_iInfectedHP[g_iTarget[iOwner][iBarType]];
			iMaxHP = g_iInfectedMaxHP[g_iTarget[iOwner][iBarType]];
		}

		if(iMaxHP > 0)
		{
			iAmount = RoundToCeil((float(iNowHP) / float(iMaxHP)) * float(iBarLength));

			sBarTemplate[0] = 0;
			for(i = 0; i < iAmount && i < iBarLength; i++) StrCat(sBarTemplate, iBarLength+2, "!");
			for(; i < iBarLength; i++) StrCat(sBarTemplate, iBarLength+2, ".");
			
			FormatEx(sBar, iMaxLength, "HP: %sl  [ %d ]  %s", sBarTemplate, iNowHP, g_sInfectedNames[g_iTargetClass[iOwner][iBarType]]);

			// modify - add recent damage indicator
			if(g_bCookieShowRecentDamage[iViewer] && g_iRecentDamage[iOwner][iBarType])
			{
				int iRecentDamage = RoundToCeil((float(iNowHP+g_iRecentDamage[iOwner][iBarType])/float(iMaxHP))*float(iBarLength)) - RoundToCeil((float(iNowHP)/float(iMaxHP))*float(iBarLength));
				for(i = 4; (i < (iBarLength + 5)) && iRecentDamage; i++)
				{
					if(sBar[i] == '.')
					{
						sBar[i] = ':';
						iRecentDamage--;
					}
				}
			}

			// modify - add "killed by you" effect
			if(g_bCookieShowDeath[iViewer] && !iNowHP && g_bIsKiller[iOwner][iBarType])
			{
				int iIndex = g_iDeathAnimFrame;
				for(i = 4; i < (iBarLength + 5); i++)
				{
					if(g_sCVDeathAnimPattern[iIndex] == ',')
					{
						if(sBar[i] == '.') sBar[i] = ',';
						else if(sBar[i] == ':') sBar[i] = ';';
					}
					iIndex++;
					if(iIndex >= g_iMaxDeathAnimFrames) iIndex = 0;
				}
			}
		}
	}
}

void resetRenderedThisFrame(int iClient)
{
	g_bRenderedThisFrame[iClient] = false;
}