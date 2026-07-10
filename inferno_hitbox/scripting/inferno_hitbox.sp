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
	version = "1.1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/inferno_hitbox"
};

#define INFERNO_MASK_DAMAGE	(CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_MOVEABLE)
#define VANILLA_RADIUS		60.0
#define MAX_FIRES			64

bool	g_bLateLoaded;
bool	g_bPluginStarted;

ConVar	g_hConVar_Radius[InfernoType_MAX];
float	g_fRadius[InfernoType_MAX];

ConVar	g_hConVar_HighGround[InfernoType_MAX];
float	g_fHighGround[InfernoType_MAX];

ConVar	g_hConVar_FullDamageRadiusMult[InfernoType_MAX];
float	g_fFullDamageRadiusMult[InfernoType_MAX];

ConVar	g_hConVar_DamageReductionMult[InfernoType_MAX];
float	g_fDamageReductionMult[InfernoType_MAX];

ConVar	g_hConVar_DamageRampTime[InfernoType_MAX];
float	g_fDamageRampTime[InfernoType_MAX];

ConVar	g_hConVar_DamageRampByFlame;
bool	g_bDamageRampByFlame;

DamageModifier g_damage;

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

	g_hConVar_HighGround[Inferno_Fire] = CreateConVar(
		"inferno_hitbox_high_ground_fire", "0.0",
		"if standing on solid ground, then being this distance above fire will be safe. " ...
		"0.0 disables this mechanic. vanilla is 0.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_HighGround[Inferno_Fire].AddChangeHook(ConVarChanged_Update);

	g_hConVar_HighGround[Inferno_Spit] = CreateConVar(
		"inferno_hitbox_high_ground_spit", "20.0",
		"if standing on solid ground, then being this distance above spit will be safe. " ...
		"0.0 disables this mechanic. vanilla is 20.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_HighGround[Inferno_Spit].AddChangeHook(ConVarChanged_Update);

	g_hConVar_HighGround[Inferno_Firework] = CreateConVar(
		"inferno_hitbox_high_ground_firework", "0.0",
		"if standing on solid ground, then being this distance above firework particles will be safe. " ...
		"0.0 disables this mechanic. vanilla is 0.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_HighGround[Inferno_Firework].AddChangeHook(ConVarChanged_Update);

	/****************************/

	g_hConVar_FullDamageRadiusMult[Inferno_Fire] = CreateConVar(
		"inferno_hitbox_full_damage_radius_mult_fire", "0.75",
		"fire will deal full damage when within an inner radius that's the full radius multiplied by this. " ...
		"otherwise, receive (original damage * inferno_hitbox_damage_reduction_mult_fire).",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_FullDamageRadiusMult[Inferno_Fire].AddChangeHook(ConVarChanged_Update);

	g_hConVar_FullDamageRadiusMult[Inferno_Spit] = CreateConVar(
		"inferno_hitbox_full_damage_radius_mult_spit", "0.75",
		"spit will deal full damage when within an inner radius that's the full radius multiplied by this. " ...
		"otherwise, receive (original damage * inferno_hitbox_damage_reduction_mult_spit).",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_FullDamageRadiusMult[Inferno_Spit].AddChangeHook(ConVarChanged_Update);

	g_hConVar_FullDamageRadiusMult[Inferno_Firework] = CreateConVar(
		"inferno_hitbox_full_damage_radius_mult_firework", "0.75",
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

	/****************************/

	g_hConVar_DamageRampTime[Inferno_Fire] = CreateConVar(
		"inferno_hitbox_damage_ramp_time_fire", "2.0",
		"the amount of seconds at the start of a fire's lifetime to scale damage from 0 to the base amount. " ...
		"vanilla is 2.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_DamageRampTime[Inferno_Fire].AddChangeHook(ConVarChanged_Update);

	g_hConVar_DamageRampTime[Inferno_Spit] = CreateConVar(
		"inferno_hitbox_damage_ramp_time_spit", "2.0",
		"the amount of seconds at the start of a spit's lifetime to scale damage from 0 to the base amount. " ...
		"for spit, a hardcoded curve for base damage already exists. this applies on top of that. vanilla is 2.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_DamageRampTime[Inferno_Spit].AddChangeHook(ConVarChanged_Update);

	g_hConVar_DamageRampTime[Inferno_Firework] = CreateConVar(
		"inferno_hitbox_damage_ramp_time_firework", "2.0",
		"the amount of seconds at the start of a firework particle's lifetime to scale damage from 0 to the base amount. " ...
		"vanilla is 2.0",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_DamageRampTime[Inferno_Firework].AddChangeHook(ConVarChanged_Update);

	/****************************/

	g_hConVar_DamageRampByFlame = CreateConVar(
		"inferno_hitbox_damage_ramp_by_flame", "1",
		"should the damage ramp time be relative to the lifetime of individual flames (1)? " ...
		"or relative to the lifetime of the inferno itself (0)? vanilla is 0",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_DamageRampByFlame.AddChangeHook(ConVarChanged_Update);

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

		PatchInferno(i);
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
		g_fHighGround[i] = g_hConVar_HighGround[i].FloatValue;
		g_fFullDamageRadiusMult[i] = g_hConVar_FullDamageRadiusMult[i].FloatValue;
		g_fDamageReductionMult[i] = g_hConVar_DamageReductionMult[i].FloatValue;
		g_fDamageRampTime[i] = g_hConVar_DamageRampTime[i].FloatValue;
	}

	g_bDamageRampByFlame = g_hConVar_DamageRampByFlame.BoolValue;
}

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (g_bPluginStarted && IsInferno(iEntity))
		SDKHook(iEntity, SDKHook_SpawnPost, PatchInferno);
}

void PatchInferno(int iEntity)
{
	Inferno inferno = GetInferno(iEntity);
	InfernoType type = inferno.type;

	inferno.radius = g_fRadius[type];
}

/***************
 * Modify Damage
 **************/

enum struct DamageEvents
{
	int total;
	float hardMod[MAX_FIRES];
	float softMod[MAX_FIRES];

	void Clear()
	{
		this.total = 0;
	}

	float CalcDamage(int iIndex, float fBase)
	{
		float fDamage = fBase;
		fDamage *= this.hardMod[iIndex];

		float fPostSoft = fDamage * this.softMod[iIndex];
		if (fDamage >= 1.0 && fPostSoft < 1.0)
			fDamage = 1.0;
		else fDamage = fPostSoft;

		return fDamage;
	}

	void Push(Flame flame, Inferno inferno, InfernoType type, bool bTouchingInner)
	{
		this.hardMod[this.total] = 1.0;
		this.softMod[this.total] = 1.0;

		if (g_fDamageRampTime[type] > 0.0)
		{
			float fStartTime;
			if (g_bDamageRampByFlame)
				fStartTime = flame.lifetime.timestamp - flame.lifetime.duration;
			else fStartTime = inferno.startTime;

			float fRampEnd = fStartTime + g_fDamageRampTime[type];

			if (GetGameTime() < fRampEnd)
				this.hardMod[this.total] *= GetElapsedRatio(fRampEnd, g_fDamageRampTime[type]);
		}

		if (!bTouchingInner)
			this.softMod[this.total] *= g_fDamageReductionMult[type];

		this.total++;
	}
}

enum struct DamageModifier
{
	int playerRef[MAXPLAYERS_L4D2 + 1];
	int infernoRef[MAXPLAYERS_L4D2 + 1];
	int tickstamp[MAXPLAYERS_L4D2 + 1];

	DamageEvents events[MAXPLAYERS_L4D2 + 1];

	void Reset(int iPlayer, Inferno inferno)
	{
		this.playerRef[iPlayer] = EntIndexToEntRef(iPlayer);
		this.infernoRef[iPlayer] = EntIndexToEntRef(inferno.entity);
		this.tickstamp[iPlayer] = GetGameTickCount();

		this.events[iPlayer].Clear();
	}

	void TouchFlame(int iPlayer, Flame flame, Inferno inferno, InfernoType type, bool bTouchingInner)
	{
		this.events[iPlayer].Push(flame, inferno, type, bTouchingInner);
	}

	bool ShouldModifyDamage(int iPlayer, int iInfernoEnt)
	{
		if (!this.events[iPlayer].total)
			return false;

		if (EntIndexToEntRef(iPlayer) != this.playerRef[iPlayer]
			|| EntIndexToEntRef(iInfernoEnt) != this.infernoRef[iPlayer]
			|| GetGameTickCount() > this.tickstamp[iPlayer])
		{
			this.events[iPlayer].Clear();
			return false;
		}

		return true;
	}

	bool ModifyDamage(int iPlayer, int iInfernoEnt, float &fDamage)
	{
		if (!this.ShouldModifyDamage(iPlayer, iInfernoEnt))
			return false;

		float fHighestDmg;
		float fEventDmg;

		for (int i = 0; i < this.events[iPlayer].total; i++)
		{
			fEventDmg = this.events[iPlayer].CalcDamage(i, fDamage);

			if (!i || fEventDmg > fHighestDmg)
				fHighestDmg = fEventDmg;
		}

		this.events[iPlayer].Clear();

		if (fHighestDmg >= fDamage)
			return false;

		fDamage = fHighestDmg;
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
	if (IsValidClient(iVictim) && IsValidEdict(iInflictor) && IsInferno(iInflictor))
	{
		if (g_damage.ModifyDamage(iVictim, iInflictor, fDamage))
			return Plugin_Changed;
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
	bool bIsPlayer = 1 <= iEntity <= MaxClients;

	bool bRet = false;

	bool bTouchingInner;

	if (bIsPlayer)
		g_damage.Reset(iEntity, inferno);

	for (int i = 0; i < iTotalFlames; i++)
	{
		/** 2nd spit renders invisible on client */
		if (type == Inferno_Spit && i == 1)
			continue;

		flame = inferno.GetFlame(i);

		if (g_fHighGround[type] > 0.0 && IsOnGround(iEntity))
		{
			flame.GetOrigin(vFlamePos);
			GetNearestPosOnEntity(iEntity, vFlamePos, vEntityPos);

			if ((vEntityPos[2] - vFlamePos[2]) > g_fHighGround[type])
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

			bRet = true;

			if (bIsPlayer)
			{
				if (g_fFullDamageRadiusMult[type] >= 1.0)
					bTouchingInner = true;
				else
				{
					fFullDamageRadius = fRadius * g_fFullDamageRadiusMult[type];
					bTouchingInner = (fDistanceSqr < (fFullDamageRadius * fFullDamageRadius));
				}

				g_damage.TouchFlame(iEntity, flame, inferno, type, bTouchingInner);
			}
			else break;
		}
	}

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
	float fRadius = VANILLA_RADIUS;

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
	float fRadius = VANILLA_RADIUS;

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

float GetElapsedRatio(float fEndTime, float fDuration)
{
	float fElapsed = GetElapsedTime(fEndTime, fDuration) / fDuration;

	if (fElapsed < 0.0)
		return 0.0;
	if (fElapsed > 1.0)
		return 1.0;

	return fElapsed;
}

float GetElapsedTime(float fEndTime, float fDuration)
{
	return GetGameTime() - fEndTime + fDuration;
}

bool IsInferno(int iEntity)
{
	return HasEntProp(iEntity, Prop_Send, "m_fireCount");
}
