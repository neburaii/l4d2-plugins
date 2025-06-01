/**
 * does not account for convar changes between map loads, where the director journal may spawn the player
 * with the old amount without re-scaling it. A convar is included that refills a survivor's ammo
 * on spawn, although this isn't a direct fix as it always fills it to max. A proper fix would be
 * to keep track of ammo before map transitions, and scale after we load in. Or, detect convar changes
 * during map transitions, revert them immediately, and queue the desired new value for when we load in. 
 * 
 * But i like the refill max ammo on spawn for my servers since it makes bs custom maps that don't give you any 
 * ammo actually fair. So for that reason, i don't care to fix this known issue.
 */

#pragma newdecls required
#pragma semicolon 1

#include <left4dhooks> // for set player reserved ammo, check if players left safe area
#include <neb_stocks> // client validity checks
#include <colors>

#define	AMMO_SMG				0
#define	AMMO_ASSAULTRIFLE		1
#define	AMMO_SHOTGUN			2
#define	AMMO_AUTOSHOTGUN		3
#define	AMMO_HUNTINGRIFLE		4
#define	AMMO_SNIPERRIFLE		5
#define	AMMO_GRENADELAUNCHER	6
#define	AMMO_M60				7

#define MAX_AMMO				8

ConVar	g_cAmmoMax[MAX_AMMO];
int		g_iCVAmmoMax[MAX_AMMO];

ConVar	g_cShouldRefillOnSpawn;
bool	g_bCVShouldRefillOnSpawn;

char	g_sWeaponList[MAX_AMMO][4][32];
int		g_iWeaponListMax[MAX_AMMO];

bool	g_bClientSpawned[MAXPLAYERS_L4D2+1], g_bStopEntityRefillTimerDone;
Handle	g_hTimerStopEntityRefill = null;

public void OnPluginStart()
{
	LoadTranslations("consistent_ammo.phrases");

	g_cAmmoMax[AMMO_SMG] = FindConVar("ammo_smg_max");
	g_cAmmoMax[AMMO_SMG].AddChangeHook(ConVarChanged_smg);
	g_sWeaponList[AMMO_SMG][0] = "weapon_smg_mp5";
	g_sWeaponList[AMMO_SMG][1] = "weapon_smg_silenced";
	g_sWeaponList[AMMO_SMG][2] = "weapon_smg";
	g_iWeaponListMax[AMMO_SMG] = 3;

	g_cAmmoMax[AMMO_ASSAULTRIFLE] = FindConVar("ammo_assaultrifle_max");
	g_cAmmoMax[AMMO_ASSAULTRIFLE].AddChangeHook(ConVarChanged_assaultrifle);
	g_sWeaponList[AMMO_ASSAULTRIFLE][0] = "weapon_rifle_ak47";
	g_sWeaponList[AMMO_ASSAULTRIFLE][1] = "weapon_rifle_desert";
	g_sWeaponList[AMMO_ASSAULTRIFLE][2] = "weapon_rifle_sg552";
	g_sWeaponList[AMMO_ASSAULTRIFLE][3] = "weapon_rifle";
	g_iWeaponListMax[AMMO_ASSAULTRIFLE] = 4;

	g_cAmmoMax[AMMO_SHOTGUN] = FindConVar("ammo_shotgun_max");
	g_cAmmoMax[AMMO_SHOTGUN].AddChangeHook(ConVarChanged_shotgun);
	g_sWeaponList[AMMO_SHOTGUN][0] = "weapon_pumpshotgun";
	g_sWeaponList[AMMO_SHOTGUN][1] = "weapon_shotgun_chrome";
	g_iWeaponListMax[AMMO_SHOTGUN] = 2;
	
	g_cAmmoMax[AMMO_AUTOSHOTGUN] = FindConVar("ammo_autoshotgun_max");
	g_cAmmoMax[AMMO_AUTOSHOTGUN].AddChangeHook(ConVarChanged_autoshotgun);
	g_sWeaponList[AMMO_AUTOSHOTGUN][0] = "weapon_autoshotgun";
	g_sWeaponList[AMMO_AUTOSHOTGUN][1] = "weapon_shotgun_spas";
	g_iWeaponListMax[AMMO_AUTOSHOTGUN] = 2;

	g_cAmmoMax[AMMO_HUNTINGRIFLE] = FindConVar("ammo_huntingrifle_max");
	g_cAmmoMax[AMMO_HUNTINGRIFLE].AddChangeHook(ConVarChanged_huntingrifle);
	g_sWeaponList[AMMO_HUNTINGRIFLE][0] = "weapon_hunting_rifle";
	g_iWeaponListMax[AMMO_HUNTINGRIFLE] = 1;

	g_cAmmoMax[AMMO_SNIPERRIFLE] = FindConVar("ammo_sniperrifle_max");
	g_cAmmoMax[AMMO_SNIPERRIFLE].AddChangeHook(ConVarChanged_sniperrifle);
	g_sWeaponList[AMMO_SNIPERRIFLE][0] = "weapon_sniper_awp";
	g_sWeaponList[AMMO_SNIPERRIFLE][1] = "weapon_sniper_military";
	g_sWeaponList[AMMO_SNIPERRIFLE][2] = "weapon_sniper_scout";
	g_iWeaponListMax[AMMO_SNIPERRIFLE] = 3;

	g_cAmmoMax[AMMO_GRENADELAUNCHER] = FindConVar("ammo_grenadelauncher_max");
	g_cAmmoMax[AMMO_GRENADELAUNCHER].AddChangeHook(ConVarChanged_grenadelauncher);
	g_sWeaponList[AMMO_GRENADELAUNCHER][0] = "weapon_grenade_launcher";
	g_iWeaponListMax[AMMO_GRENADELAUNCHER] = 1;

	g_cAmmoMax[AMMO_M60] = FindConVar("ammo_m60_max");
	g_cAmmoMax[AMMO_M60].AddChangeHook(ConVarChanged_m60);
	g_sWeaponList[AMMO_M60][0] = "weapon_m60";
	g_iWeaponListMax[AMMO_M60] = 1;

	for(int i = 0; i < MAX_AMMO; i++)
	{
		g_iCVAmmoMax[i] = g_cAmmoMax[i].IntValue;
	}

	// custom cvar
	g_cShouldRefillOnSpawn = CreateConVar("ammo_refill_on_spawn", "1", "should players spawn in saferooms with full reserve ammo? 0 = no, 1 = yes", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cShouldRefillOnSpawn.AddChangeHook(ConVarChanged_RefillOnSpawn);
	g_bCVShouldRefillOnSpawn = g_cShouldRefillOnSpawn.BoolValue;

	// hook event
	HookEvent("round_start_pre_entity", event_round_start_pre_entity);	
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	RegConsoleCmd("sm_ammo", cmdCheckAmmo, "Return total reserve ammo for your primary weapon. Vanilla can only show 3 digits, so hgih reserve ammo won't display on hud correctly, hence the existence of this command.");

	// fix plugin reload issue
	for(int i = 1; i <= MaxClients; i++)
	{
		if(nsIsSurvivor(i))
		{
			g_bStopEntityRefillTimerDone = true;
			break;
		}
	}
}

Action cmdCheckAmmo(int iClient, int iArgs)
{
	if(nsIsSurvivor(iClient) && IsPlayerAlive(iClient))
	{
		int iClientWeapon = GetPlayerWeaponSlot(iClient, 0);
		if(iClientWeapon != -1)
		{
			static char sWeaponName[32];
			GetEntityClassname(iClientWeapon, sWeaponName, sizeof(sWeaponName));

			int iAmmotType;
			for(int ammo = 0; ammo < MAX_AMMO; ammo++)
			{
				for(int i = 0; i < g_iWeaponListMax[ammo]; i++)
				{
					if(strcmp(sWeaponName, g_sWeaponList[ammo][i]) == 0)
					{
						iAmmotType = ammo;
						break;
					}
				}
			}

			int iRemaining = L4D_GetReserveAmmo(iClient, iClientWeapon);
			int iPercent = RoundToCeil((float(iRemaining) / float(g_iCVAmmoMax[iAmmotType])) * 100.0);

			CReplyToCommand(iClient, "%t %t", "tag_cmd_ammo", "msg_ammo_check_success", iRemaining, g_iCVAmmoMax[iAmmotType], iPercent);
			return Plugin_Handled;
		}		
	}

	CReplyToCommand(iClient, "%t %t", "tag_cmd_ammo", "msg_ammo_check_fail");
	return Plugin_Handled;
}

void event_round_start_pre_entity(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(g_hTimerStopEntityRefill != null) delete g_hTimerStopEntityRefill;
	g_bStopEntityRefillTimerDone = false;
	
	for(int i = 1; i <= MaxClients; i++)
		g_bClientSpawned[i] = false;
}

/*****************************
 * REFILL AMMO ON FIRST SPAWN
 ****************************/

void event_player_spawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{	
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!nsIsSurvivor(iClient)) return;

	if(g_bClientSpawned[iClient]) return;
	g_bClientSpawned[iClient] = true;

	if(g_hTimerStopEntityRefill == null && !g_bStopEntityRefillTimerDone)
		g_hTimerStopEntityRefill = CreateTimer(10.0, timerStopEntityRefill, _, TIMER_FLAG_NO_MAPCHANGE);

	if(!g_bCVShouldRefillOnSpawn) return;

	// refill this survivor's equipped weapon
	RequestFrame(refillClientAmmo, GetClientUserId(iClient));
}

void refillClientAmmo(int iUID)
{
	int iClient = GetClientOfUserId(iUID);
	if(!iClient) return;
	
	int iClientWeapon = GetPlayerWeaponSlot(iClient, 0);
	if(iClientWeapon == -1) return;

	static char sClientWeapon[32];
	GetEntityClassname(iClientWeapon, sClientWeapon, sizeof(sClientWeapon));
	
	for(int ammo = 0; ammo < MAX_AMMO; ammo++)
	{
		for(int i = 0; i < g_iWeaponListMax[ammo]; i++)
		{
			if(strcmp(sClientWeapon, g_sWeaponList[ammo][i]) == 0)
			{
				L4D_SetReserveAmmo(iClient, iClientWeapon, g_iCVAmmoMax[ammo]);
				return;
			}
		}
	}
}

// following 2 event callbacks are to make sure idling/leaving/joining etc will always correctly transfer spawn count
void event_player_bot_replace(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iPlayer = GetClientOfUserId(hEvent.GetInt("player"));
	int iBot = GetClientOfUserId(hEvent.GetInt("bot"));

	bool bTmp = g_bClientSpawned[iBot];
	g_bClientSpawned[iBot] = g_bClientSpawned[iPlayer];
	g_bClientSpawned[iPlayer] = bTmp;
}

void event_bot_player_replace(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iPlayer = GetClientOfUserId(hEvent.GetInt("player"));
	int iBot = GetClientOfUserId(hEvent.GetInt("bot"));

	bool bTmp = g_bClientSpawned[iPlayer];
	g_bClientSpawned[iPlayer] = g_bClientSpawned[iBot];
	g_bClientSpawned[iBot] = bTmp;
}

/**************************************************************
 * REFILL UNEQUIPPED WEAPONS AS THEY'RE CREATED AT ROUND START
 *************************************************************/

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	// check timer too in case it's some shit custom map with no starting safe room
	if(!g_bCVShouldRefillOnSpawn || (g_bStopEntityRefillTimerDone && L4D_HasAnySurvivorLeftSafeArea())) return;

	RequestFrame(refillEntityAmmo, iEntity);	
}

void refillEntityAmmo(int iEntity)
{
	if(!nsIsEntityValid(iEntity)) return;
	static char sClassName[32];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));

	for(int ammo = 0; ammo < MAX_AMMO; ammo++)
	{
		for(int name = 0; name < g_iWeaponListMax[ammo]; name++)
		{
			if(strcmp(sClassName, g_sWeaponList[ammo][name]) == 0)
			{
				if(GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity") == -1)
					SetEntProp(iEntity, Prop_Send, "m_iExtraPrimaryAmmo", g_iCVAmmoMax[ammo]);
				return;
			}
		}
	}
}

// timer stuff
public void OnMapEnd()
{
	g_hTimerStopEntityRefill = null;
}

Action timerStopEntityRefill(Handle hTimer)
{
	g_hTimerStopEntityRefill = null;
	g_bStopEntityRefillTimerDone = true;
	return Plugin_Stop;
}

/*****************************
 * SCALE AMMO ON CONVAR CHANGE
 ****************************/

void scaleReserveAmmo(int iAmmoType, int iOldMax, int iNewMax)
{
	int iClientWeapon;
	float fRatio;
	static char sClientWeapon[32];

	// update ammo of all equipped weapons
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!nsIsSurvivor(client)) continue;
		if(!IsPlayerAlive(client)) continue;

		iClientWeapon = GetPlayerWeaponSlot(client, 0);
		if(iClientWeapon == -1) continue;

		GetEntityClassname(iClientWeapon, sClientWeapon, sizeof(sClientWeapon));

		for(int i = 0; i < g_iWeaponListMax[iAmmoType]; i++)
		{
			if(strcmp(sClientWeapon, g_sWeaponList[iAmmoType][i]) == 0)
			{
				fRatio = float(L4D_GetReserveAmmo(client, iClientWeapon)) / float(iOldMax);
				L4D_SetReserveAmmo(client, iClientWeapon, RoundToCeil(fRatio*iNewMax));
				break;
			}
		}
	}

	// update ammo of all unequipped weapons
	int iOldCurrent, iEnt;
	for(int i = 0; i < g_iWeaponListMax[iAmmoType]; i++)
	{
		iEnt = -1;
		for(;;)
		{
			iEnt = FindEntityByClassname(iEnt, g_sWeaponList[iAmmoType][i]);
			if(iEnt == -1) break;
			if(GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") != -1) continue;
			
			iOldCurrent = GetEntProp(iEnt, Prop_Send, "m_iExtraPrimaryAmmo");
			if(iOldCurrent <= 0) continue;
			
			fRatio = float(iOldCurrent) / float(iOldMax);
			SetEntProp(iEnt, Prop_Send, "m_iExtraPrimaryAmmo", RoundToCeil(fRatio*iNewMax));
		}
	}
}

/*********************
 * ConVar Change Hooks
 *********************/

void ConVarChanged_RefillOnSpawn(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_bCVShouldRefillOnSpawn = g_cShouldRefillOnSpawn.BoolValue;
}

void ConVarChanged_smg(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_SMG] = g_cAmmoMax[AMMO_SMG].IntValue;
	scaleReserveAmmo(AMMO_SMG, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_SMG]);
}

void ConVarChanged_assaultrifle(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_ASSAULTRIFLE] = g_cAmmoMax[AMMO_ASSAULTRIFLE].IntValue;
	scaleReserveAmmo(AMMO_ASSAULTRIFLE, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_ASSAULTRIFLE]);
}

void ConVarChanged_shotgun(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_SHOTGUN] = g_cAmmoMax[AMMO_SHOTGUN].IntValue;
	scaleReserveAmmo(AMMO_SHOTGUN, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_SHOTGUN]);
}

void ConVarChanged_autoshotgun(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_AUTOSHOTGUN] = g_cAmmoMax[AMMO_AUTOSHOTGUN].IntValue;
	scaleReserveAmmo(AMMO_AUTOSHOTGUN, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_AUTOSHOTGUN]);
}

void ConVarChanged_huntingrifle(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_HUNTINGRIFLE] = g_cAmmoMax[AMMO_HUNTINGRIFLE].IntValue;
	scaleReserveAmmo(AMMO_HUNTINGRIFLE, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_HUNTINGRIFLE]);
}

void ConVarChanged_sniperrifle(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_SNIPERRIFLE] = g_cAmmoMax[AMMO_SNIPERRIFLE].IntValue;
	scaleReserveAmmo(AMMO_SNIPERRIFLE, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_SNIPERRIFLE]);
}

void ConVarChanged_grenadelauncher(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_GRENADELAUNCHER] = g_cAmmoMax[AMMO_GRENADELAUNCHER].IntValue;
	scaleReserveAmmo(AMMO_GRENADELAUNCHER, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_GRENADELAUNCHER]);
}

void ConVarChanged_m60(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVAmmoMax[AMMO_M60] = g_cAmmoMax[AMMO_M60].IntValue;
	scaleReserveAmmo(AMMO_M60, StringToInt(sOldValue), g_iCVAmmoMax[AMMO_M60]);
}
