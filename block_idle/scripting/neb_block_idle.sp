#pragma newdecls required
#pragma semicolon 1

#define GAMEDATA	"block_idle.games"

#include <dhooks>
#include <neb_stocks>
#include <left4dhooks>

DynamicDetour g_hDetourOnAutomaticIdle;

ConVar	g_cIdleMessage;
Handle	g_hUnblockTimer[MAXPLAYERS_L4D2+1] = {null, ...};
bool	g_bBlockIdle[MAXPLAYERS_L4D2+1], g_bForceTakeOver[MAXPLAYERS_L4D2+1] = {true, ...};
bool	g_bBypassCheck, g_bDisplayMessage;

public Plugin myinfo = 
{
	name = "Block Idle",
	author = "Neburai",
	description = "prevents some idle exploits, along with preventing idle when there are too many clients",
	version = "1.1",
	url = "https://steamcommunity.com/groups/l4d2hardx"
};

public void OnPluginStart()
{
	g_cIdleMessage = CreateConVar("idle_message_in_chat", "1", "bool. Should \"PLAYER is now idle.\" display in chat?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cIdleMessage.AddChangeHook(ConVarChanged_Hook);
	g_bDisplayMessage = g_cIdleMessage.BoolValue;

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata!", GAMEDATA);

	g_hDetourOnAutomaticIdle = DynamicDetour.FromConf(hGameData, "neb::CTerrorPlayer::GoAwayFromKeyboard");
	if(!g_hDetourOnAutomaticIdle) SetFailState("could not create neb::CTerrorPlayer::GoAwayFromKeyboard detour");
	g_hDetourOnAutomaticIdle.Enable(Hook_Pre, DTR_OnAutomaticIdle);

	delete hGameData;

	HookEvent("charger_carry_end", event_charger_carry_end);
	HookEvent("charger_pummel_end", event_charger_pummel_end);
	HookEvent("player_bot_replace", event_player_bot_replace);
	HookEvent("bot_player_replace", event_bot_player_replace);

	HookUserMessage(GetUserMessageId("TextMsg"), umTextMsgHook, true);
}

void ConVarChanged_Hook(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_bDisplayMessage = g_cIdleMessage.BoolValue;
}

public void OnMapStart()
{
	// prevent first bot take over after map load from causing bugs
	for(int i = 1; i <= MAXPLAYERS_L4D2; i++)
	{
		g_bForceTakeOver[i] = true;
	}
}

// keep track of which survivors already had their first bot takeover
void event_player_bot_replace(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iBot = GetClientOfUserId(hEvent.GetInt("bot"));
	g_bForceTakeOver[iBot] = false;
}

void event_bot_player_replace(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iPlayer = GetClientOfUserId(hEvent.GetInt("player"));
	g_bForceTakeOver[iPlayer] = false;
}

public void OnClientPutInServer(int iClient)
{
	if(g_hUnblockTimer[iClient] != null) delete g_hUnblockTimer[iClient];
	g_bBlockIdle[iClient] = false;
}

// go_away_from_keyboard command listener doesn't cover afk from timeouts. This detour covers both
// Automatic idles going through without checking botClientAvailable can be very bad in modes like hard 28
MRESReturn DTR_OnAutomaticIdle(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	g_bForceTakeOver[pThis] = false;
	if(!allowIdle(pThis) || !botClientAvailable())
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	if(g_bDisplayMessage) PrintToChatAll("%N is now idle.", pThis);
	return MRES_Ignored;
}

public Action L4D_OnTakeOverBot(int iClient)
{	
	if(g_bBypassCheck)
	{
		g_bBypassCheck = false;
		return Plugin_Continue;
	}	

	if(!L4D_IsPlayerIdle(iClient)) return Plugin_Continue;

	int iBot = L4D_GetBotOfIdlePlayer(iClient);
	if(g_bForceTakeOver[iBot]) return Plugin_Continue;

	if(!allowIdle(iBot))
	{
		RequestFrame(queueTakeOver, GetClientUserId(iClient));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void queueTakeOver(int iUID)
{
	int iClient = GetClientOfUserId(iUID);
	if(iClient)
	{
		int iBot = L4D_GetBotOfIdlePlayer(iClient);
		if(iBot == -1) return;

		if(!allowIdle(iBot))
		{
			RequestFrame(queueTakeOver, GetClientUserId(iClient));
			return;
		}

		if(GetClientTeam(iClient) != 0) ChangeClientTeam(iClient, 0);
		L4D_SetHumanSpec(iBot, iClient);
		g_bBypassCheck = true; // allowIdle already checked true this frame
		L4D_TakeOverBot(iClient);
	}
}

/*********
 * checks
 ********/

bool allowIdle(int iClient)
{
	if(g_bBlockIdle[iClient]) return false;
	if(isReloading(iClient)) return false;
	if(L4D_IsPlayerStaggering(iClient)) return false;
	if(isInBlockedAnim(iClient)) return false;
	return true;
}

bool botClientAvailable()
{
	for(int i = 1; i <= MAXPLAYERS_L4D2; i++)
	{
		if(!IsClientConnected(i)) return true;
	}
	return false;
}

bool isReloading(int iClient)
{
	int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if(nsIsEntityValid(iWeapon))
	{
		if(GetEntProp(iWeapon, Prop_Send, "m_bInReload")) return true;
	}
	return false;
}

bool isInBlockedAnim(int iClient)
{
	int iActivity = PlayerAnimState.FromPlayer(iClient).GetMainActivity();

	switch(iActivity)
	{
		case	L4D2_ACT_TERROR_SHOVED_FORWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_BACKWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_LEFTWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_RIGHTWARD_MELEE,
				\
				L4D2_ACT_TERROR_POUNCED_TO_STAND,
				\
				L4D2_ACT_TERROR_HIT_BY_TANKPUNCH,
				L4D2_ACT_TERROR_IDLE_FALL_FROM_TANKPUNCH,
				L4D2_ACT_TERROR_TANKPUNCH_LAND,
				\
				L4D2_ACT_TERROR_CHARGERHIT_LAND_SLOW,
				\
				L4D2_ACT_TERROR_HIT_BY_CHARGER,
				\
				L4D2_ACT_TERROR_IDLE_FALL_FROM_CHARGERHIT:
			return true;
	}

	return false;
}

// idling immediately after carry end can somewhat break the transition to pummel
void event_charger_carry_end(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));
	if(!nsIsClientValid(iVictim)) return;

	g_bBlockIdle[iVictim] = true;
	if(g_hUnblockTimer[iVictim] != null) delete g_hUnblockTimer[iVictim];
	g_hUnblockTimer[iVictim] = CreateTimer(1.0, unblockIdle, iVictim);
}

// small window of time to prevent animation if you idle just after pummel end (to do: make sure this doesn't exist with other dominator si)
void event_charger_pummel_end(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));
	if(!nsIsClientValid(iVictim)) return;

	g_bBlockIdle[iVictim] = true;
	if(g_hUnblockTimer[iVictim] != null) delete g_hUnblockTimer[iVictim];
	g_hUnblockTimer[iVictim] = CreateTimer(1.0, unblockIdle, iVictim);
}

Action unblockIdle(Handle hTimer, int iClient)
{
	g_hUnblockTimer[iClient] = null;
	g_bBlockIdle[iClient] = false;
	return Plugin_Stop;
}

/**************************
 * block idle message spam
 *************************/

Action umTextMsgHook(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	static char sBuffer[32];
	msg.ReadString(sBuffer, sizeof(sBuffer));
	if(StrContains(sBuffer, "L4D_idle_spectator", true) != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}