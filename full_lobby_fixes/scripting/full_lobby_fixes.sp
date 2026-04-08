#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <hxlib>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Max Clients Fixes",
	author = "Neburai",
	description = "fixes some issues that occur in full lobbies: players unable to join. survivor players disconnecting will delete the character they played as. survivors going idle will delete their character.",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/full_lobby_fixes"
};

/** should be longer than the interval between a client's attempts at connecting (interval measured as 1.5 when testing my local server) */
#define				TIMEOUT_DURATION	3.0

ConVar				g_hConVarMinDiscardRange;
float				g_fConVarMinDiscardRange;

ConVar				g_hConVarMaxPlayers;
int					g_iMaxPlayers;

int					g_iDisconnectingPlayer = -1;
RecordedSurvivor	g_failedBotReplacements[MAXPLAYERS_L4D2+1];
int					g_iTotalFailedBotReplacements;
bool				g_bRestoringBot;

ConnectingPlayer	g_iConnectingPlayers[MAXPLAYERS_L4D2];
int					g_iTotalConnectingPlayers;
bool				g_bIsConnectingPlayer;

public void OnPluginStart()
{
	g_hConVarMinDiscardRange = CreateConVar(
		"full_lobby_fixes_min_discard_range", "800.0",
		"if a player tries to join the server when there are no free client slots, attempt to \
		free a slot by kicking an infected bot nobody will notice gone missing. any infected bots \
		within this range from any survivor will not be a candidate for discard",
		CVAR_FLAGS, true, 0.0);
	g_hConVarMinDiscardRange.AddChangeHook(ConVarChanged_Update);

	g_hConVarMaxPlayers = FindConVar("sv_maxplayers");
	g_hConVarMaxPlayers.AddChangeHook(ConVarChanged_Update);

	ReadConVars();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_fConVarMinDiscardRange = g_hConVarMinDiscardRange.FloatValue;
	g_iMaxPlayers = g_hConVarMaxPlayers.IntValue;
}

/*******************************************************************************
 * delay bot replacement for human survivors who disconnect when server is full
 *******************************************************************************/

enum struct RecordedWeapon
{
	WeaponID weaponid;

	int ammoMagazine;
	int ammoReserve;

	int upgrades;
	int ammoUpgraded;

	bool dualWielded;
	bool equipped;

	char melee[80];
}

enum struct RecordedSurvivor
{
	/** always relevant */
	bool alive;
	float pos[3];
	float vel[3];
	float angles[3];
	SurvivorCharacter character;
	char model[PLATFORM_MAX_PATH];

	RecordedWeapon weapons[WeaponSlot_MAX];
	int restoreSecondaryWeapon;

	/** alive only */
	bool incapped;
	float healthBuffer;
	int health;
	bool flashlight;
	int reviveCount;
	bool thirdStrike;

	/** dead only */
	float timeLastAlive;

	void Record()
	{
		this.alive = IsPlayerAlive(g_iDisconnectingPlayer);
		GetEntityAbsOrigin(g_iDisconnectingPlayer, this.pos);
		GetEntityAbsVelocity(g_iDisconnectingPlayer, this.vel);
		GetClientEyeAngles(g_iDisconnectingPlayer, this.angles);
		GetClientModel(g_iDisconnectingPlayer, this.model, sizeof(this.model));
		this.character = GetSurvivorCharacter(g_iDisconnectingPlayer);

		this.restoreSecondaryWeapon = GetRestoreSecondaryWeapon(g_iDisconnectingPlayer);
		if (IsValidEntity(this.restoreSecondaryWeapon))
			this.restoreSecondaryWeapon = EntIndexToEntRef(this.restoreSecondaryWeapon);

		int iCurrentWeapon = GetCurrentWeapon(g_iDisconnectingPlayer);
		int iWeapon;

		for (int i = 0; i < WeaponSlot_MAX; i++)
		{
			this.weapons[i].weaponid = Weapon_None;

			iWeapon = GetPlayerWeaponSlot(g_iDisconnectingPlayer, i);
			if (iWeapon == -1) continue;

			this.weapons[i].weaponid = GetWeaponID(iWeapon);
			if (this.weapons[i].weaponid == Weapon_Melee)
			{
				GetMeleeWeaponName(iWeapon, this.weapons[i].melee, sizeof(this.weapons[i].melee));
			}
			else
			{
				this.weapons[i].ammoMagazine = GetMagazineAmmo(iWeapon);
				this.weapons[i].ammoReserve = GetReserveAmmo(iWeapon);
				this.weapons[i].ammoUpgraded = L4D2_GetWeaponUpgradeAmmoCount(iWeapon);
				this.weapons[i].dualWielded = IsDualWielding(iWeapon);
				this.weapons[i].upgrades = L4D2_GetWeaponUpgrades(iWeapon);
			}

			this.weapons[i].equipped = iCurrentWeapon == iWeapon;
		}

		if (this.alive)
		{
			this.incapped = L4D_IsPlayerIncapacitated(g_iDisconnectingPlayer);
			this.healthBuffer = L4D_GetTempHealth(g_iDisconnectingPlayer);
			this.health = GetEntityHealth(g_iDisconnectingPlayer);
			this.flashlight = FlashlightIsOn(g_iDisconnectingPlayer);
			this.reviveCount = L4D_GetPlayerReviveCount(g_iDisconnectingPlayer);
			this.thirdStrike = L4D_IsPlayerOnThirdStrike(g_iDisconnectingPlayer);
		}
		else
		{
			this.timeLastAlive = GetTimeLastAlive(g_iDisconnectingPlayer);
		}
	}

	void Restore()
	{
		int iClient = AddSurvivorBot(this.character);
		if (iClient == -1) return;

		TeleportEntity(iClient, this.pos, this.angles, this.vel);
		SetEntityModel(iClient, this.model);

		int iWeapon;
		int iEquipSlot = -1;

		/** WeaponSlot_Carry is weird. it will be dropped automatically
		 * if any other slot is removed first. we must remove the carry
		 * slot first.
		 *
		 * when restoring the loadout, WeaponSlot_Carry must be the last
		 * weapon given to the client otherwise the carry item will be
		 * auto dropped to the ground whenever the next weapon is given.
		 * we must give the carry slot last. */

		/** remove weapon loadout */
		for (int i = WeaponSlot_MAX -1; i >= 0; i--)
		{
			iWeapon = GetPlayerWeaponSlot(iClient, i);
			if (iWeapon != -1)
			{
				RemovePlayerItem(iClient, iWeapon);
				RemoveEntity(iWeapon);
			}
		}

		/** restore weapon loadout */
		for (int i = 0; i < WeaponSlot_MAX; i++)
		{
			if (this.weapons[i].weaponid == Weapon_None)
				continue;

			if (this.weapons[i].weaponid == Weapon_Melee)
			{
				iWeapon = GivePlayerItem(iClient, this.weapons[i].melee);
				if (iWeapon == -1) continue;
			}
			else
			{
				iWeapon = GivePlayerItem(iClient, g_sWeapon[this.weapons[i].weaponid]);
				if (iWeapon == -1) continue;
				if (this.weapons[i].dualWielded)
					GivePlayerItem(iClient, g_sWeapon[this.weapons[i].weaponid]);

				SetMagazineAmmo(iWeapon, this.weapons[i].ammoMagazine);
				SetReserveAmmo(iWeapon, this.weapons[i].ammoReserve);
				L4D2_SetWeaponUpgradeAmmoCount(iWeapon, this.weapons[i].ammoUpgraded);
				L4D2_SetWeaponUpgrades(iWeapon, this.weapons[i].upgrades);
			}

			if (this.weapons[i].equipped) iEquipSlot = i;
		}

		if (iEquipSlot != -1)
			SwitchWeapon(iClient, iEquipSlot);

		iWeapon = EntRefToEntIndex(this.restoreSecondaryWeapon);
		if (iWeapon)
			SetRestoreSecondaryWeapon(iClient, this.restoreSecondaryWeapon);

		if (!this.alive)
		{
			ForcePlayerSuicide(iClient);
			SetTimeLastAlive(iClient, this.timeLastAlive);
		}
		else
		{
			L4D_SetPlayerIncapacitatedState(iClient, this.incapped);
			L4D_SetTempHealth(iClient, this.healthBuffer);
			SetEntityHealth(iClient, this.health);
			if (this.flashlight) FlashlightTurnOn(iClient, false);
			else FlashlightTurnOff(iClient, false);
			L4D_SetPlayerReviveCount(iClient, this.reviveCount);
			L4D_SetPlayerThirdStrikeState(iClient, this.thirdStrike);
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	if (IsClientConnected(iClient)
		&& !IsFakeClient(iClient)
		&& GetClientTeam(iClient) == Team_Survivor)
	{
		g_iDisconnectingPlayer = iClient;

		/** if we record it later than now, the player's weapon slots
		 * will be empty */
		g_failedBotReplacements[g_iTotalFailedBotReplacements].Record();
	}
}

public void OnGetFreeClient_Post(NetAdrType adrType, int iIP, int iPort, int iClient)
{
	if (g_iDisconnectingPlayer == -1)
		return;
	if (iClient != -1)
		return;

	if (!g_iTotalFailedBotReplacements)
		RequestFrame(RestoreFailedBotReplacements);

	if (g_iTotalFailedBotReplacements < g_iMaxPlayers)
		g_iTotalFailedBotReplacements++;
	g_iDisconnectingPlayer = -1;
}

public void OnClientDisconnect_Post(int iClient)
{
	g_iDisconnectingPlayer = -1;
}

void RestoreFailedBotReplacements()
{
	g_bRestoringBot = true;

	for (int i = 0; i < g_iTotalFailedBotReplacements; i++)
		g_failedBotReplacements[i].Restore();

	g_iTotalFailedBotReplacements = 0;
	g_bRestoringBot = false;
}

/******************************************************************
 * manage clients currently attempting to connect to a full server
 ******************************************************************/

enum struct ConnectingPlayer
{
	int ip;
	Handle timer;

	void Renew()
	{
		delete this.timer;
		this.timer = CreateTimer(3.0, Timer_Timeout, this.ip);
	}
}

void AddConnectingPlayer(int iIP)
{
	g_iConnectingPlayers[g_iTotalConnectingPlayers].ip = iIP;
	g_iConnectingPlayers[g_iTotalConnectingPlayers].timer = CreateTimer(3.0, Timer_Timeout, iIP);

	g_iTotalConnectingPlayers++;
}

void RemoveConnectingPlayer(int iIndex)
{
	g_iConnectingPlayers[iIndex].ip = 0;
	if (g_iConnectingPlayers[iIndex].timer != null)
		delete g_iConnectingPlayers[iIndex].timer;

	for (int i = iIndex + 1; i < sizeof(g_iConnectingPlayers); i++)
	{
		if (g_iConnectingPlayers[i].ip)
		{
			g_iConnectingPlayers[i - 1].ip = g_iConnectingPlayers[i].ip;
			g_iConnectingPlayers[i - 1].timer = g_iConnectingPlayers[i].timer;

			g_iConnectingPlayers[i].ip = 0;
			g_iConnectingPlayers[i].timer = null;
		}
	}

	g_iTotalConnectingPlayers--;
}

void Timer_Timeout(Handle hTimer, int iIP)
{
	hTimer = null;

	for (int i = 0; i < g_iTotalConnectingPlayers; i++)
	{
		if (g_iConnectingPlayers[i].ip == iIP)
		{
			RemoveConnectingPlayer(i);
			break;
		}
	}
}

/***********************************************************************************************
 * check if server is full, and add the client attempting to connect to the queue managed above
 ***********************************************************************************************/

public Action OnConnectionlessPacket(NetAdrType adrType, int iIP, int iPort, int iPacketType, const any[] packet, int iPacketSize)
{
	if (iPacketType != Packet_ConnectionRequest)
		return Plugin_Continue;

	/** action for player who's already queued as wanting to connect */
	for (int i = 0; i < g_iTotalConnectingPlayers; i++)
	{
		if (g_iConnectingPlayers[i].ip == iIP)
		{
			if (GetTotalFreeSlots() > 0)
			{
				g_bIsConnectingPlayer = true;
				RemoveConnectingPlayer(i);
				return Plugin_Continue;
			}
			else
			{
				AttemptToFreeSlot();
				g_iConnectingPlayers[i].Renew();
				return Plugin_Handled;
			}
		}
	}

	/** action for players not queued to connect */
	if (GetTotalFreeSlots() - g_iTotalConnectingPlayers > 0 || g_iTotalConnectingPlayers >= g_iMaxPlayers)
		return Plugin_Continue;

	AttemptToFreeSlot();
	AddConnectingPlayer(iIP);
	return Plugin_Handled;
}

public void OnConnectionlessPacket_Post(NetAdrType adrType, int iIP, int iPort, int iPacketType, const any[] packet, int iPacketSize, bool bHandled)
{
	g_bIsConnectingPlayer = false;
}

void AttemptToFreeSlot()
{
	int iChosen;
	float vPos[3];
	float fFurthestDist;
	float fDist;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsFakeClient(i)) continue;
		if (GetClientTeam(i) != Team_Infected) continue;
		if (!IsPlayerAlive(1)) // dead SI bot will be disconnected naturally soon; perfect candidate
		{
			iChosen = i;
			break;
		}
		if (GetZombieClass(i) == ZClass_Tank) continue;

		GetClientEyePosition(i, vPos);
		GetClosestPlayer(vPos, fDist, Team_Survivor);
		if (fDist < g_fConVarMinDiscardRange || (iChosen && fDist < fFurthestDist))
			continue;

		if (!IsVisibleToTeam(Team_Survivor, vPos))
		{
			iChosen = i;
			fFurthestDist = fDist;
		}
	}

	if (iChosen) KickClient(iChosen);
}

/*************************
 * general slot management
 *************************/

/** prevent idles if there's no room for the bot replacement */
public Action OnGoAwayFromKeyboard(int iClient)
{
	if (GetTotalFreeSlots() - g_iTotalConnectingPlayers - g_iTotalFailedBotReplacements <= 0)
		return Plugin_Handled;

	return Plugin_Continue;
}

/** reserve spots for delayed player connections or bot replacements */
public Action OnGetFreeClient(NetAdrType adrType, int iIP, int iPort)
{
	if ((!g_bIsConnectingPlayer && !g_bRestoringBot)
		&& (g_iTotalConnectingPlayers || g_iTotalFailedBotReplacements)
		&& (GetTotalFreeSlots() - g_iTotalConnectingPlayers - g_iTotalFailedBotReplacements <= 0))
		return Plugin_Handled;

	return Plugin_Continue;
}

int GetTotalFreeSlots()
{
	int iTotal;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidEntity(i)) iTotal++;
	}

	return MaxClients - iTotal;
}
