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


stock bool nsIsClientValid(int iClient)
{
	if(iClient < 1 || iClient > MAXPLAYERS_L4D2) return false;
	if(!IsClientInGame(iClient)) return false;
	return true;
}

stock bool nsIsEntityValid(int iEntity)
{
	if(iEntity <= MAXPLAYERS_L4D2) return false;

	if(IsValidEdict(iEntity)) return true;
	if(IsValidEntity(iEntity)) return true;

	return false;
}

stock int nsGetInfectedClass(int iClient)
{
	return GetEntProp(iClient, Prop_Send, "m_zombieClass", 4);
}

stock bool nsIsInfected(int iClient, int iClass = -1)
{
	if(!nsIsClientValid(iClient)) return false;
	if(GetClientTeam(iClient) != TEAM_INFECTED) return false;

	if(iClass < 0 || iClass > ZCLASS_TRUEMAX) return true;
	if(nsGetInfectedClass(iClient) == iClass) return true;

	return false;
}

stock bool nsIsSurvivor(int iClient)
{
	if(!nsIsClientValid(iClient)) return false;
	if(GetClientTeam(iClient) != TEAM_SURVIVOR) return false;
	return true;
}

stock int IntAbs(int n)
{
   return (n ^ (n >> 31)) - (n >> 31);
}  