#pragma newdecls required
#pragma semicolon 1

#define	GAMEDATA	"camera_options.games"
#define	CVAR_FLAGS	FCVAR_NOTIFY

#include <dhooks>
#include <sdkhooks>
#include <clientprefs>
#include <left4dhooks>
#include <neb_stocks>

#define COOKIE_DISABLE_PUNCH	"camera_disable_recoil"
#define COOKIE_ROLL_ANGLE		"camera_roll"

// find convars
ConVar			g_cRollAngle, g_cVerticalPunch,

// plugin convars
				g_cBlockPunchVomit, g_cBlockPunchFF, g_cBlockPunchCI, g_cBlockPunchSI,
				g_cBlockPunchShoved;
bool			g_bCVBlockPunchVomit, g_bCVBlockPunchFF, g_bCVBlockPunchCI, g_bCVBlockPunchSI,
				g_bCVBlockPunchShoved;

DynamicDetour	g_hDetourOnSetPunchAngle, g_hDetourOnWeaponRecoil, g_hDetourTakeDamageAlive,
				g_hDetourOnShoved, g_hDetourOnTraceAttack;

// cookies
Cookie			g_hCookieDisablePunch, g_hCookieRollAngle;
bool			g_bClientDisableRecoil[MAXPLAYERS_L4D2+1];
int				g_iClientRollAngle[MAXPLAYERS_L4D2+1];

PunchSource 	g_iPunchSource = PunchSource_None;

enum PunchSource
{
	PunchSource_None,
	PunchSource_Vomit,
	PunchSource_Recoil,
	PunchSource_FF,
	PunchSource_CIHit,
	PunchSource_SIHit,
	PunchSource_Shoved
};

public Plugin myinfo = 
{
	name = "Camera Options",
	author = "Neburai",
	description = "per-client gun punch and roll angle. Toggles of other camera punch sources for all players",
	version = "2.0",
	url = "https://steamcommunity.com/groups/l4d2hardx"
};

public void OnPluginStart()
{
	// load gamedata
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	// load detours - the call to block for punch toggles
	g_hDetourOnSetPunchAngle = DynamicDetour.FromConf(hGameData, "HX::CBasePlayer::SetPunchAngle");
	if(!g_hDetourOnSetPunchAngle) SetFailState("could not create HX::CBasePlayer::SetPunchAngle detour");
	g_hDetourOnSetPunchAngle.Enable(Hook_Pre, DTR_OnSetPunchAngle);

	// load detours - keep track of the stack to know what called 
	g_hDetourOnWeaponRecoil = DynamicDetour.FromConf(hGameData, "HX::CTerrorGun::DoViewPunch");
	if(!g_hDetourOnWeaponRecoil) SetFailState("could not create HX::CTerrorGun::DoViewPunch detour");
	g_hDetourOnWeaponRecoil.Enable(Hook_Pre, DTR_OnRecoil_Pre);
	g_hDetourOnWeaponRecoil.Enable(Hook_Post, DTR_OnRecoil_Post);

	g_hDetourTakeDamageAlive = DynamicDetour.FromConf(hGameData, "HX::CTerrorPlayer::OnTakeDamage_Alive");
	if(!g_hDetourTakeDamageAlive) SetFailState("could not create HX::CTerrorPlayer::OnTakeDamage_Alive detour");
	g_hDetourTakeDamageAlive.Enable(Hook_Pre, DTR_OnTakeDamageAlive_Pre);
	g_hDetourTakeDamageAlive.Enable(Hook_Post, DTR_OnTakeDamageAlive_Post);

	g_hDetourOnShoved = DynamicDetour.FromConf(hGameData, "HX::CTerrorWeapon::OnHit");
	if(!g_hDetourOnShoved) SetFailState("could not create HX::CTerrorWeapon::OnHit detour");
	g_hDetourOnShoved.Enable(Hook_Pre, DTR_OnShoved_Pre);
	g_hDetourOnShoved.Enable(Hook_Post, DTR_OnShoved_Post);

	g_hDetourOnTraceAttack = DynamicDetour.FromConf(hGameData, "HX::CCSPlayer::TraceAttack");
	if(!g_hDetourOnTraceAttack) SetFailState("could not create HX::CCSPlayer::TraceAttack detour");
	g_hDetourOnTraceAttack.Enable(Hook_Pre, DTR_OnTraceAttack_Pre);
	g_hDetourOnTraceAttack.Enable(Hook_Post, DTR_OnTraceAttack_Post);

	delete hGameData;

	// create plugin convars
	g_cBlockPunchVomit = CreateConVar("camera_block_punch_boom", "0", "camera punch caused by boomer effect. 0 = allow it / vanilla | 1 = block", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cBlockPunchFF =	 CreateConVar("camera_block_punch_ff",	 "0", "camera punch caused by friendly fire. 0 = allow it / vanilla | 1 = block", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cBlockPunchCI =	 CreateConVar("camera_block_punch_ci",	 "0", "camera punch caused by common infected hitting you. 0 = allow it / vanilla | 1 = block", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cBlockPunchSI =	 CreateConVar("camera_block_punch_si",	 "0", "camera punch caused by special infected hitting you. 0 = allow it / vanilla | 1 = block", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cBlockPunchShoved =CreateConVar("camera_block_punch_shoved", "0", "camera punch caused by being shoved. 0 = allow it / vanilla | 1 = block", CVAR_FLAGS, true, 0.0, true, 1.0);

	g_cBlockPunchVomit.AddChangeHook(ConVarChanged_update);
	g_cBlockPunchFF.AddChangeHook(ConVarChanged_update);
	g_cBlockPunchCI.AddChangeHook(ConVarChanged_update);
	g_cBlockPunchSI.AddChangeHook(ConVarChanged_update);
	g_cBlockPunchShoved.AddChangeHook(ConVarChanged_update);
	readConVars();
	
	AutoExecConfig(true, "camera_options");

	// get roll angle convar
	g_cRollAngle = FindConVar("sv_rollangle");
	g_cVerticalPunch = FindConVar("z_gun_vertical_punch");
	g_cRollAngle.Flags &= ~FCVAR_REPLICATED;
	g_cVerticalPunch.Flags &= ~FCVAR_REPLICATED;

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

void ConVarChanged_update(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	readConVars();
}

void readConVars()
{
	g_bCVBlockPunchVomit = g_cBlockPunchVomit.BoolValue;
	g_bCVBlockPunchFF = g_cBlockPunchFF.BoolValue;
	g_bCVBlockPunchCI = g_cBlockPunchCI.BoolValue;
	g_bCVBlockPunchSI = g_cBlockPunchSI.BoolValue;
	g_bCVBlockPunchShoved = g_cBlockPunchShoved.BoolValue;
}

public void OnClientPutInServer(int iClient)
{
	if(IsFakeClient(iClient)) return;

	updateClientPunch(iClient);
	updateClientRollAngle(iClient);
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
			
			readClientPunch(iClient, !!iValue);
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
	readClientPunch(iClient, !!g_hCookieDisablePunch.GetInt(iClient));
	readClientRollAngle(iClient, g_hCookieRollAngle.GetInt(iClient));
}

/************
 * ROLL ANGLE
 ************/

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

/*************
 * VIEW PUNCH
 *************/

// reading/updating from cookie value
void readClientPunch(int iClient, bool bDisablePunch)
{
	g_bClientDisableRecoil[iClient] = bDisablePunch;

	if(!nsIsClientValid(iClient)) return;
	if(IsFakeClient(iClient)) return;

	updateClientPunch(iClient);
}

void updateClientPunch(int iClient)
{
	static char sValue[16];
	FormatEx(sValue, sizeof(sValue), "%i", g_bClientDisableRecoil[iClient] ? 0 : 1);
	g_cVerticalPunch.ReplicateToClient(iClient, sValue);
}

// function to block
MRESReturn DTR_OnSetPunchAngle(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	if(nsIsClientValid(pThis))
	{
		bool bSupercede;

		switch(g_iPunchSource)
		{
			case PunchSource_Recoil: if(g_bClientDisableRecoil[pThis]) bSupercede = true;
			case PunchSource_Vomit: if(g_bCVBlockPunchVomit) bSupercede = true;
			case PunchSource_FF: if(g_bCVBlockPunchFF) bSupercede = true;
			case PunchSource_CIHit: if(g_bCVBlockPunchCI) bSupercede = true;
			case PunchSource_SIHit: if(g_bCVBlockPunchSI) bSupercede = true;
			case PunchSource_Shoved: if(g_bCVBlockPunchShoved) bSupercede = true;
		}	

		if(bSupercede)
		{
			hReturn.Value = 0;
			return MRES_Supercede;
		}
	}

	// failsafe to make sure it unsets
	g_iPunchSource = PunchSource_None;

	return MRES_Ignored;
}

// sources of punch
MRESReturn DTR_OnRecoil_Pre(DHookReturn hReturn, DHookParam hParams)
{
	g_iPunchSource = PunchSource_Recoil;
	return MRES_Ignored;
}
MRESReturn DTR_OnRecoil_Post(DHookReturn hReturn, DHookParam hParams)
{
	g_iPunchSource = PunchSource_None;
	return MRES_Ignored;
}

public Action L4D_OnVomitedUpon(int iVictim, int &iAttacker, bool &bBoomerExplosion)
{
	g_iPunchSource = PunchSource_Vomit;
	return Plugin_Continue;
}
public void L4D_OnVomitedUpon_Post(int iVictim, int iAttacker, bool bBoomerExplosion)
{
	g_iPunchSource = PunchSource_None;
}
public void L4D_OnVomitedUpon_PostHandled(int iVictim, int iAttacker, bool bBoomerExplosion)
{
	g_iPunchSource = PunchSource_None;
}

public Action L4D2_OnHitByVomitJar(int iVictim, int &iAttacker)
{
	g_iPunchSource = PunchSource_Vomit;
	return Plugin_Continue;
}
public void L4D2_OnHitByVomitJar_Post(int iVictim, int iAttacker)
{
	g_iPunchSource = PunchSource_None;
}
public void L4D2_OnHitByVomitJar_PostHandled(int iVictim, int iAttacker)
{
	g_iPunchSource = PunchSource_None;
}

// the purpose is to identify the source SetPunchAngle is called from.
// sdkhooks' OnTakeDamageAlive hook isn't the CTerrorPlayer version i'm pretty sure,
// so we have our own detour.
// side note: doesn't seem like survivor on survivor damage leads to SetPunchAngle being called from this.
// The condition is covered anyways just in case. TraceAttack is the primary ff source
MRESReturn DTR_OnTakeDamageAlive_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	int iAttacker = hParams.GetObjectVar(1, 52, ObjectValueType_EhandlePtr);

	if(nsIsSurvivor(pThis))
	{		
		if(nsIsClientValid(iAttacker))
		{
			switch(GetClientTeam(iAttacker))
			{
				case TEAM_SURVIVOR: g_iPunchSource = PunchSource_FF;
				case TEAM_INFECTED: g_iPunchSource = PunchSource_SIHit;
			}
		}
		else if(nsIsCommonInfected(iAttacker)) g_iPunchSource = PunchSource_CIHit;
	}	

	return MRES_Ignored;
}
MRESReturn DTR_OnTakeDamageAlive_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	g_iPunchSource = PunchSource_None;
	return MRES_Ignored;
}

// left4dhook's version has 3 conditions that can prevent the forwards from pushing.
// we don't really care about 2 of those conditions, so it's best to detour it ourselves
// to ensure this source is identified always
MRESReturn DTR_OnShoved_Pre(DHookReturn hReturn, DHookParam hParams)
{
	if(nsIsSurvivor(hParams.GetObjectVar(1, 76, ObjectValueType_CBaseEntityPtr))) g_iPunchSource = PunchSource_Shoved;
	return MRES_Ignored;
}
MRESReturn DTR_OnShoved_Post(DHookReturn hReturn, DHookParam hParams)
{
	g_iPunchSource = PunchSource_None;
	return MRES_Ignored;
}

MRESReturn DTR_OnTraceAttack_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	if(nsIsSurvivor(pThis) && nsIsSurvivor(hParams.GetObjectVar(1, 52, ObjectValueType_EhandlePtr)))
		g_iPunchSource = PunchSource_FF;

	return MRES_Ignored;
}
MRESReturn DTR_OnTraceAttack_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	g_iPunchSource = PunchSource_None;
	return MRES_Ignored;
}