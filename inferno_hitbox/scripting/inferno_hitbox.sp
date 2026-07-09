#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <hxlib>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Revised Inferno Hitboxes",
	author = "Neburai",
	description = "Fixes inconsistent hitbox radius, and invisible spit. Implements new ways to configure the hitbox/damage of all inferno based entities",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/inferno_hitbox"
};

#define INFERNO_MASK_DAMAGE	(CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_MOVEABLE)

bool	g_bLateLoaded;
bool	g_bPluginStarted;

ConVar	g_hConVar_Radius[InfernoType_MAX];
float	g_fRadius[InfernoType_MAX];

ConVar	g_hConVar_HighGroundMult[InfernoType_MAX];
float	g_fHighGroundMult[InfernoType_MAX];

ConVar	g_hConVar_FullDamageRadiusMult[InfernoType_MAX];
float	g_fFullDamageRadiusMult[InfernoType_MAX];

ConVar	g_hConVar_DamageReductionMult[InfernoType_MAX];
float	g_fDamageReductionMult[InfernoType_MAX];

DamageReductionManager g_damageReduction;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_Radius[Inferno_Fire] = CreateConVar(
		"inferno_hitbox_radius_fire", "45.0",
		"radius of the sphere used for hit-detection with fire. vanilla is 60.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_Radius[Inferno_Fire].AddChangeHook(ConVarChanged_Update);

	g_hConVar_Radius[Inferno_Spit] = CreateConVar(
		"inferno_hitbox_radius_spit", "45.0",
		"radius of the sphere used for hit-detection with spit. vanilla is 60.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_Radius[Inferno_Spit].AddChangeHook(ConVarChanged_Update);

	g_hConVar_Radius[Inferno_Firework] = CreateConVar(
		"inferno_hitbox_radius_firework", "45.0",
		"radius of the sphere used for hit-detection with firework particles. vanilla is 60.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_Radius[Inferno_Firework].AddChangeHook(ConVarChanged_Update);

	/****************************/

	g_hConVar_HighGroundMult[Inferno_Fire] = CreateConVar(
		"inferno_hitbox_high_ground_mult_fire", "1.0",
		"if standing on solid ground, then being (radius * this) above fire will be safe. " ...
		"1.0 disables this mechanic. vanilla is 1.0",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_HighGroundMult[Inferno_Fire].AddChangeHook(ConVarChanged_Update);

	g_hConVar_HighGroundMult[Inferno_Spit] = CreateConVar(
		"inferno_hitbox_high_ground_mult_spit", "0.33333334",
		"if standing on solid ground, then being (radius * this) above spit will be safe. " ...
		"1.0 disables this mechanic. vanilla is 0.33333334",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_HighGroundMult[Inferno_Spit].AddChangeHook(ConVarChanged_Update);

	g_hConVar_HighGroundMult[Inferno_Firework] = CreateConVar(
		"inferno_hitbox_high_ground_mult_firework", "1.0",
		"if standing on solid ground, then being (radius * this) above firework particles will be safe. " ...
		"1.0 disables this mechanic. vanilla is 1.0",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_HighGroundMult[Inferno_Firework].AddChangeHook(ConVarChanged_Update);

	/****************************/

	g_hConVar_FullDamageRadiusMult[Inferno_Fire] = CreateConVar(
		"inferno_hitbox_full_damage_radius_mult_fire", "1.0",
		"fire will deal full damage when within an inner radius that's the full radius multiplied by this. " ...
		"otherwise, receive (original damage * inferno_hitbox_damage_reduction_mult_fire).",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_FullDamageRadiusMult[Inferno_Fire].AddChangeHook(ConVarChanged_Update);

	g_hConVar_FullDamageRadiusMult[Inferno_Spit] = CreateConVar(
		"inferno_hitbox_full_damage_radius_mult_spit", "1.0",
		"spit will deal full damage when within an inner radius that's the full radius multiplied by this. " ...
		"otherwise, receive (original damage * inferno_hitbox_damage_reduction_mult_spit).",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_FullDamageRadiusMult[Inferno_Spit].AddChangeHook(ConVarChanged_Update);

	g_hConVar_FullDamageRadiusMult[Inferno_Firework] = CreateConVar(
		"inferno_hitbox_full_damage_radius_mult_firework", "1.0",
		"firework particles will deal full damage when within an inner radius that's the full radius multiplied by this. " ...
		"otherwise, receive (original damage * inferno_hitbox_damage_reduction_mult_firework).",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_FullDamageRadiusMult[Inferno_Firework].AddChangeHook(ConVarChanged_Update);

	/****************************/

	g_hConVar_DamageReductionMult[Inferno_Fire] = CreateConVar(
		"inferno_hitbox_damage_reduction_mult_fire", "0.5",
		"if within a fire's radius, but outside its inner radius as defined by inferno_hitbox_full_damage_radius_mult_fire, " ...
		"then reduce damage by this multiplier.",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_DamageReductionMult[Inferno_Fire].AddChangeHook(ConVarChanged_Update);

	g_hConVar_DamageReductionMult[Inferno_Spit] = CreateConVar(
		"inferno_hitbox_damage_reduction_mult_spit", "0.5",
		"if within a spit's radius, but outside its inner radius as defined by inferno_hitbox_full_damage_radius_mult_spit, " ...
		"then reduce damage by this multiplier.",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_DamageReductionMult[Inferno_Spit].AddChangeHook(ConVarChanged_Update);

	g_hConVar_DamageReductionMult[Inferno_Firework] = CreateConVar(
		"inferno_hitbox_damage_reduction_mult_firework", "0.5",
		"if within a firework particle's radius, but outside its inner radius as defined by inferno_hitbox_full_damage_radius_mult_firework, " ...
		"then reduce damage by this multiplier.",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_DamageReductionMult[Inferno_Firework].AddChangeHook(ConVarChanged_Update);

	AutoExecConfig(_, "inferno_hitbox");
	ReadConVars();

	if (g_bLateLoaded && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

public void OnAllPluginsLoaded()
{
	if (!g_bPluginStarted && LibraryExists(HXLIB_LIBRARY))
		StartPlugin();
}

public void OnLibraryAdded(const char[] sName)
{
	if (!g_bPluginStarted && strcmp(sName, HXLIB_LIBRARY) == 0)
		StartPlugin();
}

void StartPlugin()
{
	g_bPluginStarted = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}

	for (int i = MaxClients + 1; i < MAXEDICTS; i++)
	{
		if (!IsValidEdict(i)
			|| !IsInferno(i))
			continue;

		Inferno inferno = GetInferno(i);
		inferno.radius = g_fRadius[inferno.type];
	}
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	for (any i = 0; i < InfernoType_MAX; i++)
	{
		g_fRadius[i] = g_hConVar_Radius[i].FloatValue;
		g_fHighGroundMult[i] = g_hConVar_HighGroundMult[i].FloatValue;
		g_fFullDamageRadiusMult[i] = g_hConVar_FullDamageRadiusMult[i].FloatValue;
		g_fDamageReductionMult[i] = g_hConVar_DamageReductionMult[i].FloatValue;
	}
}

/****************
 * Apply Radius
 ***************/

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (g_bPluginStarted && IsInferno(iEntity))
		SDKHook(iEntity, SDKHook_SpawnPost, OnInfernoSpawn);
}

void OnInfernoSpawn(int iEntity)
{
	Inferno inferno = GetInferno(iEntity);
	inferno.radius = g_fRadius[inferno.type];
}

/***************
 * Damage Zones
 **************/

enum struct DamageReductionManager
{
	int entref[MAXPLAYERS_L4D2 + 1];
	int tickstamp[MAXPLAYERS_L4D2 + 1];
	bool wants[MAXPLAYERS_L4D2 + 1];

	void MarkWanted(int iClient)
	{
		this.entref[iClient] = EntIndexToEntRef(iClient);
		this.tickstamp[iClient] = GetGameTickCount();
		this.wants[iClient] = true;
	}

	void Clear(int iClient)
	{
		this.wants[iClient] = false;
	}

	bool IsWanted(int iClient)
	{
		if (!this.wants[iClient])
			return false;

		if (EntIndexToEntRef(iClient) != this.entref[iClient]
			|| GetGameTickCount() > this.tickstamp[iClient])
		{
			this.Clear(iClient);
			return false;
		}

		return true;
	}
}

public void OnClientPutInServer(int iClient)
{
	if (g_bPluginStarted)
		SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, int &iWeapon, float vDamageForce[3], float vDamagePos[3])
{
	if (IsValidEdict(iInflictor) && IsInferno(iInflictor))
	{
		if (g_damageReduction.IsWanted(iVictim))
		{
			g_damageReduction.Clear(iVictim);

			Inferno inferno = GetInferno(iInflictor);
			float fReducedDamage = fDamage * g_fDamageReductionMult[inferno.type];

			/** because integer rounding, this is needed to prevent extending the initial godframes */
			if (fDamage >= 1.0 && fReducedDamage < 1.0)
				fDamage = 1.0;
			else fDamage = fReducedDamage;

			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

/*****************
 * Hit Detection
 *****************/

public Action OnIsEntityTouchingInferno(Inferno inferno, int iEntity, float &fRadius, bool &bCheckLOS, bool &bHandledResult)
{
	bHandledResult = IsTouchingCustom_Entity(inferno, iEntity, bCheckLOS);
	return Plugin_Handled;
}

bool IsTouchingCustom_Entity(Inferno inferno, int iEntity, bool bCheckLOS)
{
	float vFlamePos[3];
	float vEntityPos[3];
	Flame flame;
	float fDistanceSqr;
	float fFullDamageRadius;

	InfernoType type = inferno.type;
	int iTotalFlames = inferno.flameCount;
	float fRadius = inferno.radius;

	bool bRet = false;
	bool bTouchingInner = false;

	if (g_fFullDamageRadiusMult[type] >= 1.0
		|| !(1 <= iEntity <= MaxClients))
		bTouchingInner = true;

	for (int i = 0; i < iTotalFlames; i++)
	{
		/** 2nd spit renders invisible on client */
		if (type == Inferno_Spit && i == 1)
			continue;

		flame = inferno.GetFlame(i);

		if (g_fHighGroundMult[type] < 1.0 && IsOnGround(iEntity))
		{
			flame.GetOrigin(vFlamePos);
			GetNearestPosOnEntity(iEntity, vFlamePos, vEntityPos);

			if ((vEntityPos[2] - vFlamePos[2]) > (fRadius * g_fHighGroundMult[type]))
				continue;
		}

		flame.GetCenter(vFlamePos);
		GetNearestPosOnEntity(iEntity, vFlamePos, vEntityPos);

		fDistanceSqr = GetVectorDistance(vEntityPos, vFlamePos, true);

		if (fDistanceSqr < (fRadius * fRadius))
		{
			if (bCheckLOS)
			{
				Handle hTrace = TR_TraceRayFilterSimple(
					vEntityPos, vFlamePos, INFERNO_MASK_DAMAGE, RayType_EndPoint, iEntity, CollisionGroup_None);

				if (TR_GetFraction(hTrace) != 1.0)
				{
					delete hTrace;
					continue;
				}

				delete hTrace;
			}

			if (g_fFullDamageRadiusMult[type] < 1.0
				&& !bTouchingInner)
			{
				fFullDamageRadius = fRadius * g_fFullDamageRadiusMult[type];

				if (fDistanceSqr <= (fFullDamageRadius * fFullDamageRadius))
					bTouchingInner = true;
			}

			bRet = true;
		}

		if (bRet && bTouchingInner)
			break;
	}

	if (bRet && !bTouchingInner)
		g_damageReduction.MarkWanted(iEntity);

	return bRet;
}

public Action OnIsBoundsTouchingInferno(Inferno inferno, const float vMins[3], const float vMaxs[3], float vHandledContact[3], bool &bHandledResult)
{
	bHandledResult = IsTouchingCustom_Bounds(inferno, vMins, vMaxs, vHandledContact);
	return Plugin_Handled;
}

bool IsTouchingCustom_Bounds(Inferno inferno, const float vMins[3], const float vMaxs[3], float vFound[3])
{
	float vFlamePos[3];
	float vNearestPos[3];
	Flame flame;
	float fDistanceSqr;

	int iTotalFlames = inferno.flameCount;
	float fRadius = inferno.radius;

	for (int i = 0; i < iTotalFlames; i++)
	{
		/** don't skip 2nd spit here.
		 * if other flames are created in the same spot, they'll be invisible too.
		 * this function is primarily called to check overlap upon creating new flames */

		flame = inferno.GetFlame(i);
		flame.GetCenter(vFlamePos);
		GetNearestPos(vMins, vMaxs, vFlamePos, vNearestPos);

		fDistanceSqr = GetVectorDistance(vNearestPos, vFlamePos, true);

		if (fDistanceSqr < (fRadius * fRadius))
		{
			vFound = vNearestPos;
			return true;
		}
	}

	return false;
}

public Action OnIsNavAreaTouchingInferno(Inferno inferno, NavArea nav, bool &bHandledResult)
{
	bHandledResult = IsTouchingCustom_NavArea(inferno, nav);
	return Plugin_Handled;
}

bool IsTouchingCustom_NavArea(Inferno inferno, NavArea nav)
{
	/** vanilla has this check, so i assume null nav is possible */
	if (nav == NavArea_Null)
		return false;

	float vFlamePos[3];
	float vNearestPos[3];
	Flame flame;
	float fDistanceSqr;

	InfernoType type = inferno.type;
	int iTotalFlames = inferno.flameCount;
	float fRadius = inferno.radius;

	if (type == Inferno_Spit)
		fRadius *= 2.0;

	for (int i = 0; i < iTotalFlames; i++)
	{
		if (type == Inferno_Spit && i == 1)
			continue;

		flame = inferno.GetFlame(i);
		flame.GetCenter(vFlamePos);
		nav.GetNearestPos(vFlamePos, vNearestPos);
		vNearestPos[2] += flame.waterHeight;

		fDistanceSqr = GetVectorDistance(vNearestPos, vFlamePos, true);

		if (fDistanceSqr < (fRadius * fRadius))
			return true;
	}

	return false;
}

/***********
 * Helpers
 **********/

bool IsInferno(int iEntity)
{
	return HasEntProp(iEntity, Prop_Send, "m_fireCount");
}
