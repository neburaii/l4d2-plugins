#pragma newdecls required
#pragma semicolon 1

#include <dhooks>
#include <left4dhooks>
#include <neb_stocks>

#define GAMEDATA "neb_spitfizzle.l4d2"

#define INSECT_SWARM_CLASS "insect_swarm"
#define SPITTER_PROJECTILE_CLASS "spitter_projectile"

// having this too low can cause invisible spit
#define SPIT_MIN_SPREAD 6

int g_iInfernoSpreadCount[MAXENTITES+1], g_iSpittersProjectile[MAXPLAYERS_L4D2+1];
bool g_bInfernoSpreadStaggerCancelled[MAXENTITES+1];
DynamicDetour g_hDetourSpitterProjectileCreate, g_hDetourInfernoStart;

ConVar g_cDeleteOnStagger, g_cDeleteOnDeath;
bool g_bCVDeleteOnStagger, g_bCVDeleteOnDeath;

public Plugin myinfo = 
{
	name = "Spit Fizzle",
	author = "Neburai",
	description = "Killing a spitter causes her spit projectile to fizzle out, preventing it from reaching the ground to create a puddle",
	version = "2.1.1",
	url = "https://steamcommunity.com/groups/l4d2hardx"
};

public void OnPluginStart()
{
	g_cDeleteOnStagger = CreateConVar("spit_fizzle_on_stagger", "1", "should the spit projectile be deleted when the spitter staggers?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cDeleteOnDeath = CreateConVar("spit_fizzle_on_death", "1", "should the spit projectile be deleted when the spitter dies or disconnects?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cDeleteOnStagger.AddChangeHook(ConVarChanged_Hook);
	g_cDeleteOnDeath.AddChangeHook(ConVarChanged_Hook);
	readConVars();

	// GAMEDATA AND DHOOK INIT
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"gamedata/%s.txt\".==========", GAMEDATA);
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetourSpitterProjectileCreate = DynamicDetour.FromConf(hGameData, "neb::CSpitterProjectile::Create");
	if(!g_hDetourSpitterProjectileCreate) SetFailState("Failed to load projectile detour");
	g_hDetourSpitterProjectileCreate.Enable(Hook_Post, DTR_OnSpitterProjectileCreate);

	g_hDetourInfernoStart = DynamicDetour.FromConf(hGameData, "neb::CInferno::StartBurning");
	if(!g_hDetourInfernoStart) SetFailState("Failed to load puddle detour");
	g_hDetourInfernoStart.Enable(Hook_Post, DTR_OnInfernoStart);
	
	// EVENT HOOKS INIT
	HookEvent("player_death", event_player_death);
	HookEvent("spit_burst", event_spit_burst);
}

void ConVarChanged_Hook(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	readConVars();
}

void readConVars()
{
	g_bCVDeleteOnStagger = g_cDeleteOnStagger.BoolValue;
	g_bCVDeleteOnDeath = g_cDeleteOnDeath.BoolValue;
}

/************
 * projectile
 ***********/

// DHOOK callback - register the projectile to its owning spitter and reset that spitter's puddle related vars
MRESReturn DTR_OnSpitterProjectileCreate(DHookReturn hReturn, DHookParam hParams)
{
	int iSpitter = hParams.Get(5);
	if(!nsIsClientValid(iSpitter)) return MRES_Ignored;

	g_iSpittersProjectile[iSpitter] = hReturn.Value;

	return MRES_Ignored;
}

public void L4D2_OnStagger_Post(int iClient, int iSource)
{
	if(!g_bCVDeleteOnStagger) return;
	if(!nsIsInfected(iClient, ZCLASS_SPITTER)) return;

	deleteProjectile(iClient);
}

public void L4D_OnShovedBySurvivor_Post(int iClient, int iVictim, const float vDir[3])
{
	if(!g_bCVDeleteOnStagger) return;
	if(!nsIsInfected(iVictim, ZCLASS_SPITTER)) return;

	deleteProjectile(iVictim);
}

// remove any projectile registered to this spitter
void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_bCVDeleteOnDeath) return;
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if(!nsIsInfected(iClient, ZCLASS_SPITTER)) return;

	deleteProjectile(iClient);
}

public void OnClientDisconnect(int iClient)
{
	if(!g_bCVDeleteOnDeath) return;
	if(!nsIsInfected(iClient, ZCLASS_SPITTER)) return;

	deleteProjectile(iClient);
}

void deleteProjectile(int iClient)
{
	if(nsIsEntityValid(g_iSpittersProjectile[iClient]))
	{
		if(isThisClassName(g_iSpittersProjectile[iClient], SPITTER_PROJECTILE_CLASS))
		{
			RemoveEntity(g_iSpittersProjectile[iClient]);
			g_iSpittersProjectile[iClient] = 0;
		}
	}
}

// Un-register the projectile from this spitter
void event_spit_burst(Event event, const char[] name, bool dontBroadcast)
{
	int iSpitter = GetClientOfUserId(event.GetInt("userid"));
	if(!nsIsClientValid(iSpitter)) return;
	
	g_iSpittersProjectile[iSpitter] = 0;
}

/***************
 * puddle growth
 ***************/

// reset growth count for new inferno entity
MRESReturn DTR_OnInfernoStart(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	g_iInfernoSpreadCount[pThis] = 0;
	g_bInfernoSpreadStaggerCancelled[pThis] = false;
	return MRES_Ignored;
}

// Cancel growth of existing spit puddle on her death
public Action L4D2_OnSpitSpread(int iOwner, int iInferno, float &x, float &y, float &z)
{
	if(!nsIsEntityValid(iInferno)) return Plugin_Continue;
	if(!isThisClassName(iInferno, INSECT_SWARM_CLASS)) return Plugin_Continue;

	bool bCancelGrowth;

	// check if it should cancel
	if(!nsIsClientValid(iOwner) || !IsPlayerAlive(iOwner))
	{
		// convar condition here so that the else if is only for the connected/alive condition
		if(g_bCVDeleteOnDeath) bCancelGrowth = true;
	}
	else if(g_bCVDeleteOnStagger && L4D_IsPlayerStaggering(iOwner))
	{
		g_bInfernoSpreadStaggerCancelled[iInferno] = true;
		bCancelGrowth = true;
	}
	else if(g_bInfernoSpreadStaggerCancelled[iInferno]) bCancelGrowth = true;

	g_iInfernoSpreadCount[iInferno]++;

	// cancel
	if(bCancelGrowth && g_iInfernoSpreadCount[iInferno] >= SPIT_MIN_SPREAD) return Plugin_Handled;

	// continue growth	
	return Plugin_Continue;	
}

/******
 * misc
 *****/

bool isThisClassName(int iInferno, const char[] sClassName)
{
	static char sBuffer[32];
	GetEntityClassname(iInferno, sBuffer, sizeof(sBuffer));

	if(strcmp(sBuffer, sClassName) == 0) return true;
	return false;
}