#include <clients>
#include <entity>

// SI classes
#define ZCLASS_SMOKER				1
#define ZCLASS_BOOMER				2
#define ZCLASS_HUNTER				3
#define ZCLASS_SPITTER				4
#define ZCLASS_JOCKEY				5
#define ZCLASS_CHARGER				6
#define ZCLASS_WITCH				7
#define ZCLASS_TANK					8

#define ZCLASS_MAX					6
#define ZCLASS_TRUEMAX				8

// Teams
#define TEAM_SURVIVOR				2
#define TEAM_INFECTED				3

#define MAXPLAYERS_L4D2				32
#define MAXENTITES					2048


stock bool nsIsClientValid(int client)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	return true;
}

stock bool nsIsEntityValid(int entity)
{
	if(entity <= MaxClients) return false;

	if(IsValidEdict(entity)) return true;
	if(IsValidEntity(entity)) return true;

	return false;
}

stock int nsGetInfectedClass(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass", 4);
}

stock bool nsIsInfected(int client, int class = -1)
{
	if(!nsIsClientValid(client)) return false;
	if(GetClientTeam(client) != TEAM_INFECTED) return false;

	if(class < 0 || class > ZCLASS_TANK) return true;
	if(nsGetInfectedClass(client) == class) return true;

	return false;
}

stock bool nsIsSurvivor(int client)
{
	if(!nsIsClientValid(client)) return false;
	if(GetClientTeam(client) != TEAM_SURVIVOR) return false;
	return true;
}

stock int IntAbs(int n)
{
   return (n ^ (n >> 31)) - (n >> 31);
}  