#if defined _nebstocks_included_
	#endinput
#endif
#define _nebstocks_included_

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

stock char g_sZClassNames[][] =
{
	"",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch",
	"tank"
};

/**
 * Is a survivor being dominated by an SI?
 *
 * @param iSurvivor client index of survivor
 * @return 			bool
 */
stock bool nsIsDominated(int iSurvivor)
{
	if(	GetEntPropEnt(iSurvivor, Prop_Send, "m_tongueOwner") != -1 ||
		GetEntPropEnt(iSurvivor, Prop_Send, "m_pounceAttacker") != -1 ||
		GetEntPropEnt(iSurvivor, Prop_Send, "m_jockeyAttacker") != -1 ||
		GetEntPropEnt(iSurvivor, Prop_Send, "m_carryAttacker") != -1 ||
		GetEntPropEnt(iSurvivor, Prop_Send, "m_pummelAttacker") != -1) return true;

	return false;
}

/**
 * is this an index of a valid client?
 * 
 * @param iClient	client index to check
 * @return			bool
 */
stock bool nsIsClientValid(int iClient)
{
	if(iClient < 1 || iClient > MaxClients) return false;
	if(!IsClientInGame(iClient)) return false;
	return true;
}

/**
 * is this an index of a valid entity?
 * 
 * @param iEntity	entity index to check
 * @return			bool
 */
stock bool nsIsEntityValid(int iEntity)
{
	if(iEntity <= MaxClients) return false;

	if(IsValidEdict(iEntity)) return true;
	if(IsValidEntity(iEntity)) return true;

	return false;
}

/**
 * get the SI class of this infected
 * 
 * @param iClient	SI client index to get class of
 * @return			int of class (one of the ZCLASS_* constants)
 */
stock int nsGetInfectedClass(int iClient)
{
	return GetEntProp(iClient, Prop_Send, "m_zombieClass", 4);
}

/**
 * is this client an infected? optionally check if it's of a specified class
 * 
 * @param iClient	client index to check
 * @param iClass	optional. If a valid class is passed, it will only return true if the client also matches this class
 * @return			bool
 */
stock bool nsIsInfected(int iClient, int iClass = -1)
{
	if(!nsIsClientValid(iClient)) return false;
	if(GetClientTeam(iClient) != TEAM_INFECTED) return false;

	if(iClass < 0 || iClass > ZCLASS_TRUEMAX) return true;
	if(nsGetInfectedClass(iClient) == iClass) return true;

	return false;
}

/**
 * is this client a survivor?
 * 
 * @param iClient	client index to check
 * @return			bool
 */
stock bool nsIsSurvivor(int iClient)
{
	if(!nsIsClientValid(iClient)) return false;
	if(GetClientTeam(iClient) != TEAM_SURVIVOR) return false;
	return true;
}

/**
 * is this entity a common infected?
 * 
 * @param iEntity	entity index to check
 * @return			bool
 */
stock bool nsIsCommonInfected(int iEntity)
{
	if(nsIsEntityValid(iEntity))
	{
		static char sClassName[64];
		GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
		if(strcmp(sClassName, "infected") == 0) return true;
	}
	return false;
}

/**
 * get the absolute value of an integer
 * 
 * @param n	input integer
 * @return	output integer
 */
stock int IntAbs(int n)
{
   return (n ^ (n >> 31)) - (n >> 31);
}  