#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <hxlib>

#undef REQUIRE_PLUGIN
#include <cookie_manager>
#define REQUIRE_PLUGIN

#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Headshot Feedback Sound",
	author = "Neburai",
	description = "audio feedback for hitting headshots on infected",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/headshot_sound"
};

enum TargetType
{
	Target_Common,
	Target_Special,

	Target_MAX
};

enum HeadshotType
{
	Headshot_None = -1,

	Headshot_Wound,
	Headshot_Kill,

	Headshot_MAX
};

enum WeaponType
{
	WeaponType_None = -1,

	WeaponType_Gun,
	WeaponType_Melee,

	WeaponType_MAX
};

#if defined _cookie_manager_included_
	bool g_bCookiesHooked;
#endif

bool		g_bLateLoaded;

ConVar		g_hConVar_ReqRatio;
float		g_fReqRatio;

ConVar		g_hConVar_SampleNameDefault[Target_MAX][WeaponType_MAX][Headshot_MAX];
Cookie		g_hCookie_SampleName[Target_MAX][WeaponType_MAX][Headshot_MAX];
char		g_sSampleNameDefault[Target_MAX][WeaponType_MAX][Headshot_MAX][PLATFORM_MAX_PATH];
char		g_sSampleName[MAXPLAYERS_L4D2 + 1][Target_MAX][WeaponType_MAX][Headshot_MAX][PLATFORM_MAX_PATH];

SoundCache	g_soundCache;
DamageEventManager g_damageEventManager[MAXPLAYERS_L4D2 + 1];

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_soundCache = new SoundCache();
	for (int i = 1; i <= MaxClients; i++)
		g_damageEventManager[i].Init(i);

	g_hConVar_ReqRatio = CreateConVar(
		"headshot_sound_required_ratio", "0.49",
		"if multiple shots from for example a shotgun blast hits a target, \
		at least this ratio of the shots must be headshots for the sound to trigger.",
		CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hConVar_ReqRatio.AddChangeHook(ConVarChanged_Ratio);
	g_fReqRatio = g_hConVar_ReqRatio.FloatValue;

	char sTargetType[Target_MAX][16];
	sTargetType[Target_Common] = "_ci";
	sTargetType[Target_Special] = "_si";

	char sWeaponType[WeaponType_MAX][16];
	sWeaponType[WeaponType_Gun] = "_gun";
	sWeaponType[WeaponType_Melee] = "_melee";

	char sHeadshotType[Headshot_MAX][16];
	sHeadshotType[Headshot_Wound] = "";
	sHeadshotType[Headshot_Kill] = "_kill";

	g_sSampleNameDefault[Target_Common][WeaponType_Gun][Headshot_Wound]		= "physics/concrete/rock_impact_hard4.wav";
	g_sSampleNameDefault[Target_Common][WeaponType_Gun][Headshot_Kill]		= "physics/metal/soda_can_impact_soft2.wav";
	g_sSampleNameDefault[Target_Common][WeaponType_Melee][Headshot_Wound]	= "";
	g_sSampleNameDefault[Target_Common][WeaponType_Melee][Headshot_Kill]	= "";
	g_sSampleNameDefault[Target_Special][WeaponType_Gun][Headshot_Wound]	= "physics/concrete/rock_impact_hard4.wav";
	g_sSampleNameDefault[Target_Special][WeaponType_Gun][Headshot_Kill]		= "physics/plastic/plastic_barrel_impact_bullet3.wav";
	g_sSampleNameDefault[Target_Special][WeaponType_Melee][Headshot_Wound]	= "";
	g_sSampleNameDefault[Target_Special][WeaponType_Melee][Headshot_Kill]	= "level/timer_bell.wav";

	char sName[COOKIE_MAX_NAME_LENGTH];

	for (any target = 0; target < Target_MAX; target++)
	{
		for (any weapon = 0; weapon < WeaponType_MAX; weapon++)
		{
			for (any headshot = 0; headshot < Headshot_MAX; headshot++)
			{
				FormatEx(sName, sizeof(sName), "headshot_sound%s%s%s",
					sTargetType[target], sWeaponType[weapon], sHeadshotType[headshot]);

				RegisterCookie(sName,
					g_sSampleNameDefault[target][weapon][headshot],
					g_hConVar_SampleNameDefault[target][weapon][headshot],
					g_hCookie_SampleName[target][weapon][headshot]);
			}
		}
	}

	if (g_bLateLoaded)
	{
		UpdateCookiesAll();
		if (LibraryExists(COOKIE_MANAGER_LIBRARY))
			HookCookies();
	}
}

void ConVarChanged_Ratio(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fReqRatio = g_hConVar_ReqRatio.FloatValue;
}

void RegisterCookie(const char[] sName, const char[] sDefaultVal, ConVar &hConVar, Cookie &hCookie)
{
	hCookie = RegClientCookie(sName, "", CookieAccess_Public);

	char sCVName[40];
	char sCVDesc[64];

	FormatEx(sCVName, sizeof(sCVName),
		"cookie_%s", sName);
	FormatEx(sCVDesc, sizeof(sCVDesc),
		"default value for \"%s\" cookie", sName);

	hConVar = CreateConVar(sCVName, sDefaultVal, sCVDesc, CVAR_FLAGS);
	hConVar.AddChangeHook(ConVarChanged_Cookie);
}

#if defined _cookie_manager_included_
	public void OnAllPluginsLoaded()
	{
		if (!g_bCookiesHooked && LibraryExists(COOKIE_MANAGER_LIBRARY))
			HookCookies();
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (!g_bCookiesHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			HookCookies();
	}

	public void OnLibraryRemoved(const char[] sName)
	{
		if (strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookiesHooked = false;
	}

	void HookCookies()
	{
		g_bCookiesHooked = true;

		char sTargetType[Target_MAX][16];
		sTargetType[Target_Common] = "_ci";
		sTargetType[Target_Special] = "_si";

		char sWeaponType[WeaponType_MAX][16];
		sWeaponType[WeaponType_Gun] = "_gun";
		sWeaponType[WeaponType_Melee] = "_melee";

		char sHeadshotType[Headshot_MAX][16];
		sHeadshotType[Headshot_Wound] = "";
		sHeadshotType[Headshot_Kill] = "_kill";

		char sName[COOKIE_MAX_NAME_LENGTH];
		for (any target = 0; target < Target_MAX; target++)
		{
			for (any weapon = 0; weapon < WeaponType_MAX; weapon++)
			{
				for (any headshot = 0; headshot < Headshot_MAX; headshot++)
				{
					FormatEx(sName, sizeof(sName), "headshot_sound%s%s%s",
						sTargetType[target], sWeaponType[weapon], sHeadshotType[headshot]);
					HookCookieChange(sName, OnCookieChanged);
				}
			}
		}
	}

	void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		UpdateCookies(iClient);
	}
#endif

public void OnClientPutInServer(int iClient)
{
	if (!IsFakeClient(iClient))
		UpdateCookies(iClient);

	SDKHook(iClient, SDKHook_OnTakeDamageAlivePost, OnSpecialTakeDamage);
	AddEntityHook(iClient, EntityHook_EventKilled, EHook_Post, OnSpecialKilled);
}

public void OnClientCookiesCached(int iClient)
{
	if (!IsFakeClient(iClient))
		UpdateCookies(iClient);
}

void ConVarChanged_Cookie(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadCookieConVars();
	UpdateCookiesAll();
}

void ReadCookieConVars()
{
	for (any target = 0; target < Target_MAX; target++)
	{
		for (any weapon = 0; weapon < WeaponType_MAX; weapon++)
		{
			for (any headshot = 0; headshot < Headshot_MAX; headshot++)
			{
				g_hConVar_SampleNameDefault[target][weapon][headshot].GetString(
					g_sSampleNameDefault[target][weapon][headshot], sizeof(g_sSampleNameDefault[][][]));
			}
		}
	}
}

void UpdateCookiesAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)
			|| IsFakeClient(i))
			continue;

		UpdateCookies(i);
	}
}

void UpdateCookies(int iClient)
{
	if (!AreClientCookiesCached(iClient))
	{
		for (any target = 0; target < Target_MAX; target++)
		{
			for (any weapon = 0; weapon < WeaponType_MAX; weapon++)
			{
				for (any headshot = 0; headshot < Headshot_MAX; headshot++)
					SetClientSoundDefault(iClient, target, weapon, headshot);
			}
		}
		return;
	}

	char sValue[PLATFORM_MAX_PATH];

	for (any target = 0; target < Target_MAX; target++)
	{
		for (any weapon = 0; weapon < WeaponType_MAX; weapon++)
		{
			for (any headshot = 0; headshot < Headshot_MAX; headshot++)
			{
				g_hCookie_SampleName[target][weapon][headshot].Get(iClient, sValue, sizeof(sValue));
				if (sValue[0] != '\0')
					SetClientSound(iClient, target, weapon, headshot, sValue);
				else SetClientSoundDefault(iClient, target, weapon, headshot);
			}
		}
	}
}

void SetClientSound(int iClient, TargetType target, WeaponType weapon, HeadshotType headshot, const char[] sSource)
{
	strcopy(g_sSampleName[iClient][target][weapon][headshot], sizeof(g_sSampleName[][][][]), sSource);
	g_soundCache.AddSound(g_sSampleName[iClient][target][weapon][headshot]);
}

void SetClientSoundDefault(int iClient, TargetType target, WeaponType weapon, HeadshotType headshot)
{
	strcopy(g_sSampleName[iClient][target][weapon][headshot], sizeof(g_sSampleName[][][][]),
		g_sSampleNameDefault[target][weapon][headshot]);
	g_soundCache.AddSound(g_sSampleName[iClient][target][weapon][headshot]);
}

/****************
 * sound caching
 ***************/

methodmap SoundCache < StringMap
{
	public SoundCache()
	{
		return view_as<SoundCache>(CreateTrie());
	}

	public void Refresh()
	{
		this.Clear();

		/** add defaults */
		for (any target = 0; target < Target_MAX; target++)
		{
			for (any weapon = 0; weapon < WeaponType_MAX; weapon++)
			{
				for (any headshot = 0; headshot < Headshot_MAX; headshot++)
				{
					this.AddSound(g_sSampleNameDefault
						[target][weapon][headshot]);
				}
			}
		}

		/** add those set by clients */
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client)
				|| IsFakeClient(client))
				continue;

			for (any target = 0; target < Target_MAX; target++)
			{
				for (any weapon = 0; weapon < WeaponType_MAX; weapon++)
				{
					for (any headshot = 0; headshot < Headshot_MAX; headshot++)
					{
						this.AddSound(g_sSampleName
							[client][target][weapon][headshot]);
					}
				}
			}
		}
	}

	public void AddSound(const char sSample[PLATFORM_MAX_PATH])
	{
		if (sSample[0] == '\0' || this.ContainsKey(sSample))
			return;

		this.SetValue(sSample, 0, false);
		PrecacheSound(sSample);
	}
}

public void OnMapStart()
{
	g_soundCache.Refresh();
}

/******************
 * Damage tracking
 ******************/

enum struct DamageEvent
{
	int entref;
	WeaponType weaponUsed;
	HeadshotType headshotType;
	TargetType targetType;

	int headshots;
	int bodyshots;

	void Init(int iEntRef, WeaponType weapon, TargetType targetType)
	{
		this.entref = iEntRef;
		this.weaponUsed = weapon;
		this.headshotType = Headshot_None;
		this.targetType = targetType;

		this.headshots = 0;
		this.bodyshots = 0;
	}

	bool AddShot(int iEntRef, WeaponType weapon, HeadshotType type)
	{
		if (iEntRef != this.entref || weapon != this.weaponUsed)
			return false;

		if (type == Headshot_None)
			this.bodyshots++;
		else this.headshots++;

		if (type > this.headshotType)
			this.headshotType = type;

		return true;
	}
}

enum struct DamageEventManager
{
	int client;
	int userid;
	ArrayList damageEvents;

	bool recording;

	void Init(int iClient)
	{
		this.client = iClient;
		this.userid = 0;
		this.damageEvents = new ArrayList(sizeof(DamageEvent));
		this.recording = false;
	}

	void RecordEvent(int iEntity, TargetType targetType, WeaponType weapon, HeadshotType headshotType)
	{
		if (IsFakeClient(this.client))
			return;

		int iUserID = GetClientUserId(this.client);
		if (!this.recording)
		{
			RequestFrame(ExecuteDamageEvents, this);
			this.recording = true;
			this.userid = iUserID;
			this.damageEvents.Clear();
		}
		else if (iUserID != this.userid)
		{
			this.userid = iUserID;
			this.damageEvents.Clear();
		}

		int iEntRef = EntIndexToEntRef(iEntity);
		int iMax = this.damageEvents.Length;
		DamageEvent damageEvent;

		for (int i = 0; i < iMax; i++)
		{
			this.damageEvents.GetArray(i, damageEvent);
			if (damageEvent.AddShot(iEntRef, weapon, headshotType))
			{
				this.damageEvents.SetArray(i, damageEvent);
				return;
			}
		}

		damageEvent.Init(iEntRef, weapon, targetType);
		damageEvent.AddShot(iEntRef, weapon, headshotType);
		this.damageEvents.PushArray(damageEvent);
	}

	void ExecuteEvents()
	{
		this.recording = false;
		if (IsFakeClient(this.client) || GetClientUserId(this.client) != this.userid)
			return;

		StringMap hPlayedSounds = new StringMap();
		DamageEvent damageEvent;

		int iMax = this.damageEvents.Length;
		for (int i = 0; i < iMax; i++)
		{
			this.damageEvents.GetArray(i, damageEvent);
			if (damageEvent.headshotType == Headshot_None)
				continue;

			if (g_sSampleName[this.client][damageEvent.targetType][damageEvent.weaponUsed][damageEvent.headshotType]
				[0]	== '\0')
				continue;

			if (damageEvent.bodyshots
				&& float(damageEvent.headshots) / (float(damageEvent.headshots) + float(damageEvent.bodyshots)) < g_fReqRatio)
				continue;

			if (!hPlayedSounds.SetValue(
				g_sSampleName[this.client][damageEvent.targetType][damageEvent.weaponUsed][damageEvent.headshotType],
				true, false))
				continue;

			EmitSoundToClient(this.client,
				g_sSampleName[this.client][damageEvent.targetType][damageEvent.weaponUsed][damageEvent.headshotType],
				_, SNDCHAN_STATIC);
		}

		delete hPlayedSounds;
	}
}

void ExecuteDamageEvents(DamageEventManager damageEventManager)
{
	damageEventManager.ExecuteEvents();
}

public void OnEntityCreated(int iEntity, const char[] sClass)
{
	if (strcmp(sClass, "infected") == 0)
	{
		SDKHook(iEntity, SDKHook_OnTakeDamageAlivePost, OnCommonTakeDamage);
		AddEntityHook(iEntity, EntityHook_EventKilled, EHook_Post, OnCommonKilled);
	}
	else if (strcmp(sClass, "witch") == 0)
	{
		SDKHook(iEntity, SDKHook_OnTakeDamageAlivePost, OnSpecialTakeDamage);
		AddEntityHook(iEntity, EntityHook_EventKilled, EHook_Post, OnSpecialKilled);
	}
}

void OnSpecialTakeDamage(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3])
{
	if ((1 <= iVictim <= MaxClients) && (GetClientTeam(iVictim) != Team_Infected || IsPlayerIncapacitated(iVictim)))
		return;

	ProcessDamageEvent(iVictim, iAttacker, fDamage, iWeapon, Target_Special);
}

void OnCommonTakeDamage(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3])
{
	ProcessDamageEvent(iVictim, iAttacker, fDamage, iWeapon, Target_Common);
}

void OnSpecialKilled(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	if (bHandled || ((1 <= iVictim <= MaxClients) && (GetClientTeam(iVictim) != Team_Infected || IsPlayerIncapacitated(iVictim))))
		return;

	ProcessKilledEvent(iVictim, iAttacker, iWeapon, Target_Special);
}

void OnCommonKilled(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	if (bHandled)
		return;

	ProcessKilledEvent(iVictim, iAttacker, iWeapon, Target_Common);
}

public void OnIncapacitatedAsTank_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType, int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	if (bHandled)
		return;

	ProcessKilledEvent(iVictim, iAttacker, iWeapon, Target_Special);
}

void ProcessDamageEvent(int iVictim, int iAttacker, float fDamage, int iWeapon, TargetType targetType)
{
	if (!fDamage
		|| !IsValidClient(iAttacker)
		|| !IsValidEdict(iWeapon)
		|| !IsWeapon(iWeapon))
		return;

	WeaponType weaponType = GetWeaponType(iWeapon);
	if (weaponType == WeaponType_None)
		return;

	HeadshotType headshotType = Headshot_None;
	if (GetLastHitGroup(iVictim) == HitGroup_Head)
		headshotType = Headshot_Wound;

	g_damageEventManager[iAttacker].RecordEvent(iVictim, targetType, weaponType, headshotType);
}

void ProcessKilledEvent(int iVictim, int iAttacker, int iWeapon, TargetType targetType)
{
	if (!IsValidClient(iAttacker)
		|| !IsValidEdict(iWeapon)
		|| !IsWeapon(iWeapon))
		return;

	WeaponType weaponType = GetWeaponType(iWeapon);
	if (weaponType == WeaponType_None)
		return;

	HeadshotType headshotType = Headshot_None;
	if (GetLastHitGroup(iVictim) == HitGroup_Head)
		headshotType = Headshot_Kill;

	g_damageEventManager[iAttacker].RecordEvent(iVictim, targetType, weaponType, headshotType);
}

/**********
 * helpers
 *********/

WeaponType GetWeaponType(int iWeapon)
{
	if (IsTerrorGun(iWeapon))
		return WeaponType_Gun;

	if (GetWeaponID(iWeapon) == Weapon_Melee)
		return WeaponType_Melee;

	return WeaponType_None;
}
