#include <sourcemod>
#include <dhooks>
#include <left4dhooks>
#include <neb_stocks>

#define GAMEDATA "neb_spitfizzle.l4d2"

bool g_baDeadSpitter[MAXPLAYERS_L4D2+1];
int g_iaSpittersSpit[MAXPLAYERS_L4D2+1], g_iaSpitInstancesCounted[MAXPLAYERS_L4D2+1], g_iaSpittersProjectile[MAXPLAYERS_L4D2+1];
float g_vaSpitterDeathXY[MAXPLAYERS_L4D2+1][2];

DynamicDetour g_dSpitterProjectileCreate;

public Plugin myinfo = 
{
	name = "Spit Fizzle",
	author = "Neburai",
	description = "Killing a spitter causes her spit projectile to fizzle out, preventing it from reaching the ground to create a puddle",
	version = "2.0",
	url = "https://steamcommunity.com/groups/l4d2hardx"
};

public void OnPluginStart()
{
	// GAMEDATA AND DHOOK INIT
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"gamedata/%s.txt\".==========", GAMEDATA);
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	g_dSpitterProjectileCreate = DynamicDetour.FromConf(hGameData, "neb::CSpitterProjectile::Create");
	if(!g_dSpitterProjectileCreate) SetFailState("Failed to load detour");
	g_dSpitterProjectileCreate.Enable(Hook_Post, dhOnSpitterProjectileCreate);
	
	// EVENT HOOKS INIT
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_death", event_player_death);
	HookEvent("spit_burst", event_spit_burst);
}

// DHOOK callback - register the projectile to its owning spitter and reset that spitter's puddle related vars
MRESReturn dhOnSpitterProjectileCreate(DHookReturn hReturn, DHookParam hParams)
{
	int iSpitter = hParams.Get(5);
	if(!nsIsClientValid(iSpitter)) return MRES_Ignored;

	g_iaSpitInstancesCounted[iSpitter] = 0;
	g_iaSpittersSpit[iSpitter] = 0;
	g_iaSpittersProjectile[iSpitter] = hReturn.Value;

	return MRES_Ignored;
}

// Reset vars on new spawn
void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_baDeadSpitter[client] = false;
	g_iaSpittersProjectile[client] = 0;
	g_iaSpitInstancesCounted[client] = 0;
	g_iaSpittersSpit[client] = 0;
}

// Set death-relevant vars and remove any projectile registered to this spitter
void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!nsIsInfected(client, ZCLASS_SPITTER)) return;

	g_baDeadSpitter[client] = true;
	g_vaSpitterDeathXY[client][0] = event.GetFloat("victim_x");
	g_vaSpitterDeathXY[client][1]= event.GetFloat("victim_y");

	if(g_iaSpittersProjectile[client] && nsIsEntityValid(g_iaSpittersProjectile[client]))
	{
		static char sClassName[32];
		GetEntityClassname(g_iaSpittersProjectile[client], sClassName, sizeof(sClassName));
		if(strcmp(sClassName, "spitter_projectile", false) == 0)
		{
			RemoveEntity(g_iaSpittersProjectile[client]);
			g_iaSpittersProjectile[client] = 0;
		}
	}
	return;
}

// Un-register the projectile from this spitter
void event_spit_burst(Event event, const char[] name, bool dontBroadcast)
{
	int iSpitter = GetClientOfUserId(event.GetInt("userid"));
	if(!nsIsClientValid(iSpitter)) return;
	
	g_iaSpittersProjectile[iSpitter] = 0;
}

// Cancel growth of existing spit puddle on her death
public Action L4D2_OnSpitSpread(int spitter, int projectile, float &x, float &y, float &z)
{
	if(!nsIsEntityValid(projectile)) return Plugin_Continue;
	static char sBuffer[32];
	GetEntityClassname(projectile, sBuffer, sizeof(sBuffer));
	if(strcmp(sBuffer, "insect_swarm", false) != 0) return Plugin_Continue;
	
	// Infer that this spit puddle came from a projectile
	if(!g_iaSpittersSpit[spitter])
	{
		bool bDistanceChecked;		
		if(g_baDeadSpitter[spitter])
		{
			float vProjVec[3];
			GetEntPropVector(projectile, Prop_Send, "m_vecOrigin", vProjVec);			
			if(!(vProjVec[0] == g_vaSpitterDeathXY[spitter][0] && vProjVec[1] == g_vaSpitterDeathXY[spitter][1]))
				bDistanceChecked = true;
		}
		if(!g_baDeadSpitter[spitter] || bDistanceChecked) g_iaSpittersSpit[spitter] = projectile;
		else return Plugin_Continue;
	}
	else if(projectile != g_iaSpittersSpit[spitter]) return Plugin_Continue;

	// stunt its growth
	if(g_baDeadSpitter[spitter])
	{
		if(!g_iaSpitInstancesCounted[spitter])
		{
			RemoveEntity(projectile);
			return Plugin_Handled;
		}
		else if(g_iaSpitInstancesCounted[spitter] > 2) return Plugin_Handled;
	}
	g_iaSpitInstancesCounted[spitter]++;
	
	return Plugin_Continue;
}