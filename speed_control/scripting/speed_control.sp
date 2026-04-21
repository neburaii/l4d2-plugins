#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#include <hxlib>

#define	CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "speed control",
	author = "Neburai",
	description = "adds new convars for previously hardcoded top speed values under various contexts",
	version = "2.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/speed_control"
};

enum SpeedType
{
	Speed_Run,
	Speed_Walk,
	Speed_Crouch,

	Speed_MAX
}

enum PlayerType
{
	Player_Unknown = -1,
	Player_Observer,
	Player_Smoker,
	Player_Boomer,
	Player_Hunter,
	Player_Spitter,
	Player_Jockey,
	Player_Charger,
	Player_TankVersus,
	Player_Tank,
	Player_Survivor,
	Player_Ghost,

	Player_MAX
}

ConVar	g_hConVar_BaseSpeed[Player_MAX][Speed_MAX];
float	g_fBaseSpeed[Player_MAX][Speed_MAX];

ConVar	g_hConVar_SmokedSpeed;
float	g_fSmokedSpeed;

ConVar	g_hConVar_JockeyedSpeedModMin;
float	g_fJockeyedSpeedModMin;

ConVar	g_hConVar_AdrenalineSpeed;
float	g_fAdrenalineSpeed;

ConVar	g_hConVar_LimpHealth;
float	g_fLimpHealth;

ConVar	g_hConVar_DragSpeedMultiplier;
float	g_fDragSpeedMultiplier;

ConVar	g_hConVar_LimpSpeed;
float	g_fLimpSpeed;

ConVar	g_hConVar_NearDeathSpeed;
float	g_fNearDeathSpeed;

ConVar	g_hConVar_WaterSpeedVersus;
float	g_fWaterSpeedVersus;

ConVar	g_hConVar_WaterSpeed;
float	g_fWaterSpeed;

ConVar	g_hConVar_FOVSpeed;
float	g_fFOVSpeed;

public void OnPluginStart()
{
	g_hConVar_SmokedSpeed = FindConVar("tongue_victim_max_speed");
	g_hConVar_SmokedSpeed.AddChangeHook(ConVarChanged_Update);

	g_hConVar_JockeyedSpeedModMin = FindConVar("z_jockey_min_mounted_speed");
	g_hConVar_JockeyedSpeedModMin.AddChangeHook(ConVarChanged_Update);

	g_hConVar_AdrenalineSpeed = FindConVar("adrenaline_run_speed");
	g_hConVar_AdrenalineSpeed.AddChangeHook(ConVarChanged_Update);

	g_hConVar_LimpHealth = FindConVar("survivor_limp_health");
	g_hConVar_LimpHealth.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DragSpeedMultiplier = FindConVar("survivor_drag_speed_multiplier");
	g_hConVar_DragSpeedMultiplier.AddChangeHook(ConVarChanged_Update);

	g_hConVar_LimpSpeed = CreateConVar(
		"speed_limping", "150.0",
		"limit survivor movement speeds to this when health is < survivor_limp_health",
		CVAR_FLAGS, true, 1.0);
	g_hConVar_LimpSpeed.AddChangeHook(ConVarChanged_Update);

	g_hConVar_NearDeathSpeed = CreateConVar(
		"speed_near_death", "85.0",
		"limit survivor movement speeds to this when at 1 hp",
		CVAR_FLAGS, true, 1.0);
	g_hConVar_NearDeathSpeed.AddChangeHook(ConVarChanged_Update);

	g_hConVar_WaterSpeedVersus = CreateConVar(
		"speed_water_versus", "170.0",
		"limit survivor movement speeds to this when in water in versus mode",
		CVAR_FLAGS, true, 1.0);
	g_hConVar_WaterSpeedVersus.AddChangeHook(ConVarChanged_Update);

	g_hConVar_WaterSpeed = CreateConVar(
		"speed_water", "115.0",
		"limit survivor movement speeds to this when in water",
		CVAR_FLAGS, true, 1.0);
	g_hConVar_WaterSpeed.AddChangeHook(ConVarChanged_Update);

	g_hConVar_FOVSpeed = CreateConVar(
		"speed_scoped", "85.0",
		"limit survivor movement speeds to this when zooming a weapon",
		CVAR_FLAGS, true, 1.0);
	g_hConVar_FOVSpeed.AddChangeHook(ConVarChanged_Update);

	/** there is an unused vanilla var for hunter running speed, called z_hunter_speed.
	 * however, its default value is faster than what the actual hardcoded value.
	 * it feels wrong to force the convar's value on plugin start, as that would
	 * clash with configs. it also feels wrong to have the plugin essentially buff
	 * hunter out of the box.
	 * so with that reasoning, we will keep that convar unused. */
	g_hConVar_BaseSpeed[Player_Ghost][Speed_Run] = FindConVar("z_ghost_speed");
	g_hConVar_BaseSpeed[Player_Smoker][Speed_Run] = FindConVar("z_gas_speed");
	g_hConVar_BaseSpeed[Player_Boomer][Speed_Run] = FindConVar("z_exploding_speed");
	g_hConVar_BaseSpeed[Player_Spitter][Speed_Run] = FindConVar("z_spitter_speed");
	g_hConVar_BaseSpeed[Player_Jockey][Speed_Run] = FindConVar("z_jockey_speed");
	g_hConVar_BaseSpeed[Player_TankVersus][Speed_Run] = FindConVar("z_tank_speed_vs");
	g_hConVar_BaseSpeed[Player_Tank][Speed_Run] = FindConVar("z_tank_speed");
	g_hConVar_BaseSpeed[Player_Tank][Speed_Walk] = FindConVar("z_tank_walk_speed");
	g_hConVar_BaseSpeed[Player_Survivor][Speed_Crouch] = FindConVar("survivor_crouch_speed");

	char sDefault[Player_MAX][Speed_MAX][6];
	sDefault[Player_Observer][Speed_Run]		= "900.0";
	sDefault[Player_Observer][Speed_Walk]		= "900.0";
	sDefault[Player_Observer][Speed_Crouch]		= "900.0";
	sDefault[Player_Smoker][Speed_Walk]			= "85.0";
	sDefault[Player_Smoker][Speed_Crouch]		= "75.0";
	sDefault[Player_Boomer][Speed_Walk]			= "85.0";
	sDefault[Player_Boomer][Speed_Crouch]		= "75.0";
	sDefault[Player_Hunter][Speed_Run]			= "250.0";
	sDefault[Player_Hunter][Speed_Walk]			= "85.0";
	sDefault[Player_Hunter][Speed_Crouch]		= "75.0";
	sDefault[Player_Spitter][Speed_Walk]		= "85.0";
	sDefault[Player_Spitter][Speed_Crouch]		= "75.0";
	sDefault[Player_Jockey][Speed_Walk]			= "85.0";
	sDefault[Player_Jockey][Speed_Crouch]		= "75.0";
	sDefault[Player_Charger][Speed_Run]			= "250.0";
	sDefault[Player_Charger][Speed_Walk]		= "85.0";
	sDefault[Player_Charger][Speed_Crouch]		= "75.0";
	sDefault[Player_TankVersus][Speed_Walk]		= "100.0";
	sDefault[Player_TankVersus][Speed_Crouch]	= "75.0";
	sDefault[Player_Tank][Speed_Crouch]			= "75.0";
	sDefault[Player_Survivor][Speed_Run]		= "220.0";
	sDefault[Player_Survivor][Speed_Walk]		= "85.0";
	sDefault[Player_Ghost][Speed_Walk]			= "450.0";
	sDefault[Player_Ghost][Speed_Crouch]		= "450.0";

	char sPlayerName[Player_MAX][9];
	sPlayerName[Player_Observer]	= "observer";
	sPlayerName[Player_Smoker]		= "smoker";
	sPlayerName[Player_Boomer]		= "boomer";
	sPlayerName[Player_Hunter]		= "hunter";
	sPlayerName[Player_Spitter]		= "spitter";
	sPlayerName[Player_Jockey]		= "jockey";
	sPlayerName[Player_Charger]		= "charger";
	sPlayerName[Player_TankVersus]	= "tank_vs";
	sPlayerName[Player_Tank]		= "tank";
	sPlayerName[Player_Survivor]	= "survivor";
	sPlayerName[Player_Ghost]		= "ghost";

	char sSpeedName[Speed_MAX][7];
	sSpeedName[Speed_Run]		= "run";
	sSpeedName[Speed_Walk]		= "walk";
	sSpeedName[Speed_Crouch]	= "crouch";

	char sConVarName[64];
	char sConVarDesc[256];

	for (any p = 0; p < Player_MAX; p++)
	{
		for (any s = 0; s < Speed_MAX; s++)
		{
			if (!g_hConVar_BaseSpeed[p][s])
			{
				if (!sDefault[p][s][0])
					SetFailState("no default value for [%s][%s]", sPlayerName[p], sSpeedName[s]);

				FormatEx(sConVarName, sizeof(sConVarName),
					"speed_base_%s_%s", sPlayerName[p], sSpeedName[s]);
				FormatEx(sConVarDesc, sizeof(sConVarDesc),
					"default '%s' top speed for %s", sSpeedName[s], sPlayerName[p]);

				g_hConVar_BaseSpeed[p][s] = CreateConVar(
					sConVarName, sDefault[p][s], sConVarDesc, CVAR_FLAGS, true, 1.0);
			}
			g_hConVar_BaseSpeed[p][s].AddChangeHook(ConVarChanged_Update);
		}
	}

	ReadConVars();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	for (any p = 0; p < Player_MAX; p++)
	{
		for (any s = 0; s < Speed_MAX; s++)
			g_fBaseSpeed[p][s] = g_hConVar_BaseSpeed[p][s].FloatValue;
	}

	g_fSmokedSpeed = g_hConVar_SmokedSpeed.FloatValue;
	g_fJockeyedSpeedModMin = g_hConVar_JockeyedSpeedModMin.FloatValue;
	g_fAdrenalineSpeed = g_hConVar_AdrenalineSpeed.FloatValue;
	g_fNearDeathSpeed = g_hConVar_NearDeathSpeed.FloatValue;
	g_fLimpHealth = g_hConVar_LimpHealth.FloatValue;
	g_fLimpSpeed = g_hConVar_LimpSpeed.FloatValue;
	g_fWaterSpeedVersus = g_hConVar_WaterSpeedVersus.FloatValue;
	g_fWaterSpeed = g_hConVar_WaterSpeed.FloatValue;
	g_fFOVSpeed = g_hConVar_FOVSpeed.FloatValue;
	g_fDragSpeedMultiplier = g_hConVar_DragSpeedMultiplier.FloatValue;
}

/****************
 * setting speed
 ***************/

enum struct SpeedConstructor
{
	int client;
	float base;
	float final;

	PlayerType type;

	void Init(int iClient, SpeedType speedType)
	{
		this.type = GetPlayerType(iClient);

		if (speedType != Speed_Run && this.type == Player_Survivor && IsStaggering(iClient))
			speedType = Speed_Run;

		if (this.type != Player_Unknown)
			this.base = g_fBaseSpeed[this.type][speedType];
		else this.base = 1.0;

		this.final = this.base;
		this.client = iClient;
	}

	float Get()
	{
		return this.final;
	}

	/******************************
	 * set final speed by scenario
	 *****************************/

	bool SetSmoked()
	{
		if (!IsSmoked(this.client))
			return false;

		this.final = g_fSmokedSpeed;
		return true;
	}

	bool SetJockeyed()
	{
		if (!IsJockeyed(this.client))
			return false;

		float fMod = float(GetEntityHealth(this.client)) / float(GetEntityMaxHealth(this.client));
		if (g_fJockeyedSpeedModMin > fMod)
			fMod = g_fJockeyedSpeedModMin;

		this.final = this.base * fMod;
		this.ModifyWater();
		return true;
	}

	bool SetAdrenaline()
	{
		if (!AdrenalineActive(this.client))
			return false;

		this.final = g_fAdrenalineSpeed;
		this.ModifyFOV();
		return true;
	}

	bool SetNearDeath()
	{
		float fTempHP = L4D_GetTempHealth(this.client);
		int iHP = GetEntityHealth(this.client);

		if (GetEntProp(this.client, Prop_Send, "m_isGoingToDie", 1) == 0
			|| fTempHP > 0.0
			|| iHP > 1)
			return false;

		this.final = g_fNearDeathSpeed;
		this.ModifyWater();
		this.ModifyFOV();
		return true;
	}

	bool SetLimping()
	{
		float fHP = float(GetEntityHealth(this.client));
		fHP += L4D_GetTempHealth(this.client);

		if (fHP >= g_fLimpHealth)
			return false;

		this.final = g_fLimpSpeed;
		this.ModifyWater();
		this.ModifyFOV();
		return true;
	}

	void SetBase()
	{
		this.final = this.base;
		this.ModifyWater();
		this.ModifyFOV();
	}

	/*********************
	 * Modify final speed
	 ********************/

	void ModifyWater()
	{
		if (!IsPlayerInWater(this.client) || !DoesWaterSlowMovement())
			return;

		float fWaterSpeed;
		if (L4D_HasPlayerControlledZombies())
			fWaterSpeed = g_fWaterSpeedVersus;
		else fWaterSpeed = g_fWaterSpeed;

		if (fWaterSpeed < this.final)
			this.final = fWaterSpeed;
	}

	void ModifyFOV()
	{
		if (GetFOV(this.client) >= GetDefaultFOV(this.client))
			return;

		if (g_fFOVSpeed < this.final)
			this.final = g_fFOVSpeed;
	}

	void ModifyDrag()
	{
		int iDragTarget = GetEntPropEnt(this.client, Prop_Send, "m_dragTarget");
		if (!IsValidEntity(iDragTarget))
			return;

		this.final *= g_fDragSpeedMultiplier;
	}

	void ModifyBaseClamp()
	{
		if (this.base < this.final)
			this.final = this.base;
	}
}

PlayerType GetPlayerType(int iClient)
{
	if (IsPlayerGhost(iClient))
		return Player_Ghost;

	if ((GetPhysicsFlags(iClient) & PFlag_Observer) || !IsPlayerAlive(iClient))
		return Player_Observer;

	if (IsOfSurvivorTeam(iClient))
		return Player_Survivor;

	switch (GetZombieClass(iClient))
	{
		case ZClass_Smoker: return Player_Smoker;
		case ZClass_Boomer: return Player_Boomer;
		case ZClass_Hunter: return Player_Hunter;
		case ZClass_Spitter: return Player_Spitter;
		case ZClass_Jockey: return Player_Jockey;
		case ZClass_Charger: return Player_Charger;

		case ZClass_Tank:
		{
			if (L4D_HasPlayerControlledZombies())
				return Player_TankVersus;
			else return Player_Tank;
		}
	}

	return Player_Unknown;
}

/**********
 * detours
 **********/

public Action L4D_OnGetRunTopSpeed(int iClient, float &fRetVal)
{
	SpeedConstructor speed;
	speed.Init(iClient, Speed_Run);

	switch (speed.type)
	{
		case Player_Survivor:
		{
			if (!speed.SetSmoked()
				&& !speed.SetJockeyed())
			{
				if (speed.SetAdrenaline()
					|| speed.SetNearDeath()
					|| speed.SetLimping())
					speed.ModifyDrag();

				else
				{
					speed.SetBase();
					speed.ModifyDrag();
				}
			}
		}

		case Player_Smoker:
		{
			if (IsSmokerAbilityActive(iClient) || GetStamina(iClient) > 2500.0)
			{
				fRetVal = 1.0;
				return Plugin_Handled;
			}
		}

		case Player_Boomer:
		{
			if (GetStamina(iClient) > 2500.0)
			{
				fRetVal = 1.0;
				return Plugin_Handled;
			}
		}

		case Player_Charger:
		{
			if (IsPummeling(iClient))
			{
				fRetVal = 1.0;
				return Plugin_Handled;
			}
		}
	}

	fRetVal = speed.Get();
	return Plugin_Handled;
}

public Action L4D_OnGetWalkTopSpeed(int iClient, float &fRetVal)
{
	SpeedConstructor speed;
	speed.Init(iClient, Speed_Walk);

	if (speed.type == Player_Survivor)
	{
		if (!speed.SetSmoked())
		{
			if (speed.SetAdrenaline()
				|| speed.SetNearDeath()
				|| speed.SetLimping())
				speed.ModifyBaseClamp();

			else speed.SetBase();
		}
	}

	fRetVal = speed.Get();
	return Plugin_Handled;
}

public Action L4D_OnGetCrouchTopSpeed(int iClient, float &fRetVal)
{
	SpeedConstructor speed;
	speed.Init(iClient, Speed_Crouch);

	if (speed.type == Player_Survivor)
	{
		if (speed.SetAdrenaline()
			|| speed.SetNearDeath()
			|| speed.SetLimping())
			speed.ModifyBaseClamp();

		else speed.SetBase();
	}

	fRetVal = speed.Get();
	return Plugin_Handled;
}

/*******
 * Misc
 *******/

bool IsStaggering(int iClient)
{
	if (GetGameTime() >= GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1))
		return false;

	float vStaggerDir[3];
	float vOrigin[3];
	float fDistance;

	GetEntityAbsOrigin(iClient, vOrigin);
	GetEntPropVector(iClient, Prop_Send, "m_staggerDir", vStaggerDir);
	fDistance = GetEntPropFloat(iClient, Prop_Send, "m_staggerDist");

	if (GetVectorDistance(vOrigin, vStaggerDir) > fDistance)
		return false;

	return true;
}

bool IsPummeling(int iClient)
{
	int iVictim = GetEntPropEnt(iClient, Prop_Send, "m_pummelVictim");
	return IsValidEntity(iVictim);
}

bool IsSmokerAbilityActive(int iClient)
{
	int iAbility = GetEntPropEnt(iClient, Prop_Send, "m_customAbility");
	if (!IsValidEntity(iAbility))
		return false;

	return GetEntProp(iAbility, Prop_Send, "m_tongueState");
}

float GetStamina(int iClient)
{
	return GetEntPropFloat(iClient, Prop_Send, "m_flStamina");
}
