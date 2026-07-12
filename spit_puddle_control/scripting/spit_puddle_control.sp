#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <hxlib>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Spit Puddle Control",
	author = "Neburai",
	description = "configure spit puddle duration and max size",
	version = "2.3",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/spit_puddle_control"
};

#define		MIN_FLAMES		2
#define		MAX_FLAMES		64

float		g_fDefaultCurve[] = { 0.0, 5.0, 10.0, 20.0, 30.0, 30.0, 20.0, 7.0 };

bool		g_bLateLoaded;
bool		g_bPluginStarted;

Difficulty	g_difficulty;

ConVar		g_hConVar_DamageCurve;
DamageCurve g_damageCurve;

ConVar		g_hConVar_Lifetime;
float		g_fLifetime;

ConVar		g_hConVar_MaxFlames;
int			g_iMaxFlames;

enum DifficultyType
{
	Difficulty_Easy,
	Difficulty_Normal,
	Difficulty_Advanced,
	Difficulty_Expert
};

enum struct Difficulty
{
	DifficultyType value;
	ConVar z_difficulty;
	StringMap lookup;

	void Init()
	{
		this.z_difficulty = FindConVar("z_difficulty");
		this.z_difficulty.AddChangeHook(ConVarChanged_Difficulty);

		this.lookup = new StringMap();
		this.lookup.SetValue("Easy", Difficulty_Easy);
		this.lookup.SetValue("Normal", Difficulty_Normal);
		this.lookup.SetValue("Hard", Difficulty_Advanced);
		this.lookup.SetValue("Impossible", Difficulty_Expert);

		this.Update();
	}

	void Update()
	{
		char sValue[12];
		this.z_difficulty.GetString(sValue, sizeof(sValue));

		if (!this.lookup.GetValue(sValue, this.value))
			this.value = Difficulty_Normal;
	}

	DifficultyType Get()
	{
		return this.value;
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_damageCurve = new DamageCurve();
	g_difficulty.Init();

	g_hConVar_DamageCurve = CreateConVar(
		"spit_damage_curve", "0.0, 5.0, 10.0, 20.0, 30.0, 30.0, 20.0, 7.0",
		"comma separated list of numbers to draw a curve from. each number is a float, " ...
		"as damage per second. need at least 2 values. base spit damage comes from this curve " ...
		"projected over its lifetime.",
		CVAR_FLAGS);
	g_hConVar_DamageCurve.AddChangeHook(ConVarChanged_Update);

	g_hConVar_Lifetime = CreateConVar(
		"spit_lifetime", "7.0",
		"duration of spit lifetime",
		CVAR_FLAGS, true, 0.0, true, 7.0); // spit invisible if raised above 7
	g_hConVar_Lifetime.AddChangeHook(ConVarChanged_Update);

	g_hConVar_MaxFlames = CreateConVar(
		"spit_max_flames", "10",
		"spit puddles created by a projectile can grow this many times",
		CVAR_FLAGS, true, float(MIN_FLAMES), true, float(MAX_FLAMES));
	g_hConVar_MaxFlames.AddChangeHook(ConVarChanged_Update);

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

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, HXLIB_LIBRARY) == 0)
		StopPlugin();
}

void StartPlugin()
{
	g_bPluginStarted = true;
	HXLibRescanForwards();

	HookEvent("spit_burst", Event_SpitBurst);

	for (int i = MaxClients + 1; i < MAXEDICTS; i++)
	{
		if (!IsValidEdict(i)
			|| !IsSpit(i))
			continue;

		HookSpitDamage(i);
	}
}

void StopPlugin()
{
	g_bPluginStarted = false;
	UnhookEvent("spit_burst", Event_SpitBurst);
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ConVarChanged_Difficulty(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_difficulty.Update();
}

void ReadConVars()
{
	g_iMaxFlames = g_hConVar_MaxFlames.IntValue;
	g_fLifetime = g_hConVar_Lifetime.FloatValue;

	char sValue[1024];
	g_hConVar_DamageCurve.GetString(sValue, sizeof(sValue));
	g_damageCurve.SetFromString(sValue);
}

/***************
 * Damage curve
 ***************/

methodmap DamageCurve < ArrayList
{
	public DamageCurve()
	{
		return view_as<DamageCurve>(CreateArray());
	}

	public void SetFromString(const char[] sInput)
	{
		this.Clear();

		char sBuffer[32];
		int iWrite;
		float fValue;

		for (int i = 0;; i++)
		{
			if (sInput[i] == '\0' || sInput[i] == ',' || i >= 1024)
			{
				if (iWrite)
				{
					sBuffer[iWrite] = '\0';
					if (StringToFloatEx(sBuffer, fValue))
						this.Push(fValue);
				}

				if (sInput[i] == ',')
				{
					iWrite = 0;
					continue;
				}

				break;
			}

			else if (IsCharSpace(sInput[i]))
				continue;

			if (iWrite < sizeof(sBuffer) - 1)
				sBuffer[iWrite++] = sInput[i];
		}

		if (this.Length < 2)
		{
			this.Clear();

			if (sInput[0])
				LogError("ConVar \"spit_damage_curve\" is formatted incorrectly!");

			for (int i = 0; i < sizeof(g_fDefaultCurve); i++)
				this.Push(g_fDefaultCurve[i]);
		}
	}

	public float GetDamage(int iKey)
	{
		return view_as<float>(this.Get(iKey));
	}

	public float GetDamagePerSecond(Inferno spit)
	{
		float fElapsedTime = GetGameTime() - spit.startTime;
		int iTotalKeys = this.Length;

		float fPos = (fElapsedTime / g_fLifetime) * float(iTotalKeys - 1);

		if (fPos <= 0.0)
			return this.Get(0);
		else if (fPos >= float(iTotalKeys - 1))
			return this.Get(iTotalKeys - 1);

		int iKey = RoundToFloor(fPos);
		float fStart = this.GetDamage(iKey);
		float fRange = this.GetDamage(iKey + 1) - fStart;
		fPos -= float(iKey);

		if (g_difficulty.Get() == Difficulty_Easy
			&& !GetGameModeInfo().hasPlayerControlledZombies)
		{
			/** copying vanilla behaviour */
			fStart *= 0.5;
		}

		return fStart + (fRange * fPos);
	}
}

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (g_bPluginStarted && strcmp(sClass, "insect_swarm") == 0)
		HookSpitDamage(iEntity);
}

void HookSpitDamage(int iSpit)
{
	AddEntityHook(iSpit, EntityHook_GetInfernoDPS, EHook_Pre, OnGetSpitDamagePerSecond);
}

Action OnGetSpitDamagePerSecond(Inferno spit, float &fHandledResult)
{
	fHandledResult = g_damageCurve.GetDamagePerSecond(spit);
	return Plugin_Handled;
}

/***********
 * Lifetime
 **********/

public Action OnGetSpitLifetime_Override(Inferno spit, float &fLifetime)
{
	fLifetime = g_fLifetime;
	return Plugin_Changed;
}

/*************
 * Max Flames
 ************/

void Event_SpitBurst(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClient(iClient)) return;

	int iSpit = hEvent.GetInt("subject", INVALID_ENT_REFERENCE);
	if (!IsValidEdict(iSpit)) return;

	GetInferno(iSpit).maxFlames = g_iMaxFlames;
}

/**********
 * helpers
 *********/

bool IsSpit(int iEntity)
{
	static char sClass[64];
	GetEntityClassname(iEntity, sClass, sizeof(sClass));
	return strcmp(sClass, "insect_swarm") == 0;
}
