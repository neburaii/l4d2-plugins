#pragma newdecls required
#pragma semicolon 1

#define	GAMEDATA	"camera_options.games"

#include <dhooks>
#include <clientprefs>
#include <neb_stocks>

#define COOKIE_DISABLE_PUNCH	"camera_disable_recoil"
#define COOKIE_ROLL_ANGLE		"camera_roll"

// roll angle
ConVar			g_cRollAngle;

// disable punch
DynamicDetour	g_hDetourOnViewPunch;

// cookies
Cookie			g_hCookieDisablePunch, g_hCookieRollAngle;
bool			g_bClientDisablePunch[MAXPLAYERS_L4D2+1];
int				g_iClientRollAngle[MAXPLAYERS_L4D2+1];

public Plugin myinfo = 
{
	name = "Camera Options",
	author = "Neburai",
	description = "Per-client implementaion of camera view roll and recoil",
	version = "1.0",
	url = "https://steamcommunity.com/groups/l4d2hardx"
};

public void OnPluginStart()
{
	// load detour
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetourOnViewPunch = DynamicDetour.FromConf(hGameData, "HX::CTerrorGun::DoViewPunch");
	if(!g_hDetourOnViewPunch) SetFailState("could not create HX::CTerrorGun::DoViewPunch detour");
	g_hDetourOnViewPunch.Enable(Hook_Pre, DTR_OnViewPunch);

	delete hGameData;

	// get roll angle convar
	g_cRollAngle = FindConVar("sv_rollangle");
	g_cRollAngle.Flags &= ~FCVAR_REPLICATED;

	// register cookies
	g_hCookieDisablePunch = new Cookie(COOKIE_DISABLE_PUNCH, "default: 0 | 1 or 0 | Set to 1 to disable camera recoil, 0 to keep it enabled", CookieAccess_Public);
	g_hCookieRollAngle = new Cookie(COOKIE_ROLL_ANGLE, "default: 0 | 0 disables it. Any number > 0 is the max angle your camera will roll", CookieAccess_Public);

	AddCommandListener(cmdListenCookies, "sm_cookies");

	// recover data from plugin restart
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!nsIsClientValid(i)) continue;
		if(IsFakeClient(i)) continue;

		readCookies(i);
	}
}

/*********
 * COOKIES
 *********/

Action cmdListenCookies(int iClient, const char[] sCommand, int iArgs)
{
	if(nsIsClientValid(iClient) && iArgs == 2)
	{
		char sCookie[64];
		GetCmdArg(1, sCookie, sizeof(sCookie));
		int iValue = GetCmdArgInt(2);

		if(strcmp(sCookie, COOKIE_DISABLE_PUNCH) == 0)
		{
			if(!(0 <= iValue <= 1))
			{
				ReplyToCommand(iClient, "%s only accepts 1 or 0 as a value (1 = disable, 0 = enable).", sCookie);
				return Plugin_Handled;
			}
			
			g_bClientDisablePunch[iClient] = !!iValue;
		}
		else if(strcmp(sCookie, COOKIE_ROLL_ANGLE) == 0)
		{
			if(iValue < 0)
			{
				ReplyToCommand(iClient, "%s only accepts a value >= 0. (0 = disable, > 0 = max angle to roll)", sCookie);
				return Plugin_Handled;
			}

			readClientRollAngle(iClient, iValue);
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
	g_bClientDisablePunch[iClient] = !!g_hCookieDisablePunch.GetInt(iClient);
	readClientRollAngle(iClient, g_hCookieRollAngle.GetInt(iClient));
}

/*************
 * VIEW PUNCH
 *************/

MRESReturn DTR_OnViewPunch(DHookReturn hReturn, DHookParam hParams)
{
	int iClient = hParams.Get(1);
	if(!nsIsClientValid(iClient)) return MRES_Ignored;

	if(g_bClientDisablePunch[iClient])
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

/************
 * ROLL ANGLE
 ************/

public void OnClientPutInServer(int iClient)
{
	if(!nsIsClientValid(iClient)) return;
	if(IsFakeClient(iClient)) return;

	updateClientRollAngle(iClient);
}

void readClientRollAngle(int iClient, int iAngle)
{
	g_iClientRollAngle[iClient] = iAngle;

	if(!nsIsClientValid(iClient)) return;
	if(IsFakeClient(iClient)) return;

	updateClientRollAngle(iClient);
}

void updateClientRollAngle(int iClient)
{
	static char sValue[16];
	IntToString(g_iClientRollAngle[iClient], sValue, sizeof(sValue));
	g_cRollAngle.ReplicateToClient(iClient, sValue);
}