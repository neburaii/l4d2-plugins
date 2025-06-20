#pragma newdecls required
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <neb_stocks>

#define COOKIE_FADE			"ragdoll_fade"
#define	COOKIE_CI_BEGONE	"ragdoll_ci_begone"

Cookie	g_hCookieEnableFader, g_hCookieEnableCIGone;

int		g_iRagdollFader;
bool	g_bClientEnableFader[MAXPLAYERS_L4D2+1], g_bClientEnableCIGone[MAXPLAYERS_L4D2+1];

public Plugin myinfo = 
{
	name = "Ragdoll Options",
	author = "Neburai",
	description = "Per-client implementaion of ragdoll fades and commons disappearing instantly on death",
	version = "1.1",
	url = "https://steamcommunity.com/groups/l4d2hardx"
};

public void OnPluginStart()
{
	g_hCookieEnableFader = new Cookie(COOKIE_FADE, "default: 0 | 1 or 0 | enable/disable ragdolls fading", CookieAccess_Public);
	g_hCookieEnableCIGone = new Cookie(COOKIE_CI_BEGONE, "default: 0 | 1 or 0 | enable/disable common infected disappearing instantly on death", CookieAccess_Public);

	AddCommandListener(cmdListenCookies, "sm_cookies");

	HookEvent("round_freeze_end", event_round_freeze_end);
	HookEvent("player_death", event_player_death);

	// recover data from plugin restart
	bool bCreateFader;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsClientValid(i)) continue;
		bCreateFader = true;
		if(IsFakeClient(i)) continue;

		readCookies(i);
	}

	if(bCreateFader) createRagdollFader();
}

public void OnPluginEnd()
{
	deleteRagdollFader();
}

/*********
 * COOKIES
 *********/

Action cmdListenCookies(int iClient, const char[] sCommand, int iArgs)
{
	if(nsIsClientValid(iClient) && iArgs == 2)
	{
		char sCookie[64];
		int iCase;
		GetCmdArg(1, sCookie, sizeof(sCookie));

		if(strcmp(sCookie, COOKIE_FADE) == 0) iCase = 1;
		else if(strcmp(sCookie, COOKIE_CI_BEGONE) == 0) iCase = 2;

		if(iCase)
		{
			int iValue = GetCmdArgInt(2);
			if(!(0 <= iValue <= 1))
			{
				ReplyToCommand(iClient, "%s only accepts 1 or 0 as a value (1 = enable, 0 = disable).", sCookie);
				return Plugin_Handled;
			}

			switch(iCase)
			{
				case 1:
				{
					g_bClientEnableFader[iClient] = !!iValue;
					if(!g_bClientEnableFader[iClient]) recreateRagdollFader();
				}
				case 2: g_bClientEnableCIGone[iClient] = !!iValue;
			}
		}
	}	

	return Plugin_Continue;
}

public void OnClientCookiesCached(int iClient)
{
	readCookies(iClient);
}

void readCookies(int iClient)
{
	g_bClientEnableFader[iClient] = !!g_hCookieEnableFader.GetInt(iClient, 0);
	g_bClientEnableCIGone[iClient] = !!g_hCookieEnableCIGone.GetInt(iClient, 0);
}

/********
 * FADER
 *******/

void event_round_freeze_end(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(g_iRagdollFader && EntRefToEntIndex(g_iRagdollFader) != INVALID_ENT_REFERENCE)
		return;
	
	createRagdollFader();
}

void recreateRagdollFader()
{
	deleteRagdollFader();
	createRagdollFader();
}

void createRagdollFader()
{
	if(g_iRagdollFader && EntRefToEntIndex(g_iRagdollFader) != INVALID_ENT_REFERENCE)
		return;

	int iFaderEnt = CreateEntityByName("func_ragdoll_fader");
	if(iFaderEnt != -1)
	{
		SDKHook(iFaderEnt, SDKHook_SetTransmit, SetTransmit_Fader);
		DispatchSpawn(iFaderEnt);
		SetEntPropVector(iFaderEnt, Prop_Send, "m_vecMaxs", view_as<float>({ 999999.0, 999999.0, 999999.0 }));
		SetEntPropVector(iFaderEnt, Prop_Send, "m_vecMins", view_as<float>({ -999999.0, -999999.0, -999999.0 }));
		SetEntProp(iFaderEnt, Prop_Send, "m_nSolidType", 2);
		g_iRagdollFader = EntIndexToEntRef(iFaderEnt);
	}
}

void deleteRagdollFader()
{
	int iFaderEnt = EntRefToEntIndex(g_iRagdollFader);
	if(g_iRagdollFader && iFaderEnt != INVALID_ENT_REFERENCE)
	{
		RemoveEntity(iFaderEnt);
		g_iRagdollFader = 0;
	}
}

public Action SetTransmit_Fader(int iEntity, int iClient)
{
    if(g_bClientEnableFader[iClient]) return Plugin_Continue;
    return Plugin_Handled;
}

/************
 * CI-BE-GONE
 ***********/

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if(nsIsCommonInfected(iEntity))
	{
		// it's supposed to happen when their entities are destroyed.
		// Somehow a common later spawns with same entity index but invisible because it never unhooked.
		// No errrors from unhooking here - even for ones that aren't hooked - so this works i guess
		SDKUnhook(iEntity, SDKHook_SetTransmit, SetTransmit_CI_BeGone);
	}
}

void event_player_death(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(nsIsClientValid(GetClientOfUserId(hEvent.GetInt("userid")))) return;

	int iInfected = hEvent.GetInt("entityid");
	if(!nsIsCommonInfected(iInfected)) return;

	SetEntityCollisionGroup(iInfected, 1); // no collision with player
	SDKHook(iInfected, SDKHook_SetTransmit, SetTransmit_CI_BeGone);
}

public Action SetTransmit_CI_BeGone(int iEntity, int iClient)
{
    if(g_bClientEnableCIGone[iClient]) return Plugin_Handled;
    return Plugin_Continue;
}