#pragma newdecls required
#pragma semicolon 1

#include <neb_stocks>

ConVar	g_cWelcomeMessageDelay;
float	g_fCVWelcomeMessageDelay;

GlobalForward g_hForwardOnWelcomeMessage;

bool	g_bWelcomeQueued[MAXPLAYERS_L4D2+1];
int		g_iLastUID;

public void OnPluginStart()
{
	g_cWelcomeMessageDelay = CreateConVar("neb_welcome_message_delay", "5.0", "call forward after this many seconds since player joined", FCVAR_NOTIFY, true, 0.1);
	g_cWelcomeMessageDelay.AddChangeHook(ConVarChanged_Delay);
	g_fCVWelcomeMessageDelay = g_cWelcomeMessageDelay.FloatValue;

	HookEvent("player_team", event_player_team);

	g_hForwardOnWelcomeMessage = CreateGlobalForward("OnWelcomeMessage", ET_Ignore, Param_Cell);
}

void ConVarChanged_Delay(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_fCVWelcomeMessageDelay = g_cWelcomeMessageDelay.FloatValue;
}

public void OnClientPutInServer(int iClient)
{
	g_bWelcomeQueued[iClient] = false;

	int iUID = GetClientUserId(iClient);
	if(iUID > g_iLastUID)
	{
		g_iLastUID = iUID;
		if(!IsFakeClient(iClient)) g_bWelcomeQueued[iClient] = true;
	}
}

void event_player_team(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(hEvent.GetBool("disconnect")) return;
	if(hEvent.GetInt("team") < 2) return;

	int iUID = hEvent.GetInt("userid");
	int iClient = GetClientOfUserId(iUID);
	if(!nsIsClientValid(iClient)) return;	

	if(g_bWelcomeQueued[iClient])
	{
		g_bWelcomeQueued[iClient] = false;
		CreateTimer(g_fCVWelcomeMessageDelay, welcomeMessage, iUID, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void welcomeMessage(Handle hTimer, int iUID)
{
	int iClient = GetClientOfUserId(iUID);
	if(!iClient) return;

	Call_StartForward(g_hForwardOnWelcomeMessage);
	Call_PushCell(iClient);
	Call_Finish();
}