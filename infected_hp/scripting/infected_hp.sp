#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <hxlib>

#undef REQUIRE_PLUGIN
#include <cookie_manager>

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Infected HP Bars",
	author = "Neburai",
	description = "Special infected health bars using center text HUD element.",
	version = "2.2",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/infected_hp"
};

#define CENTER_TEXT				4
#define CENTER_TEXT_MAX_BUFFER	254
#define LINEFEED				"\10"
#define WHITESPACE_TAB			"	"

enum TargetType
{
	Target_None = -1,

	Target_Common,
	Target_Special,
	Target_Boss,

	Target_MAX
};

enum
{
	Tick_Health,
	Tick_RecentDamage,
	Tick_Empty,

	Tick_MAX
};

enum PatternType
{
	Pattern_Normal,
	Pattern_KillerFeedback,

	Pattern_MAX
};

bool g_bLateLoaded;
#if defined _cookie_manager_included_
	bool g_bCookiesHooked;
#endif

char	g_sTick[Tick_MAX][][] =
{
	{"!", "!"},	// Tick_Health
	{":", ";"},	// Tick_RecentDamage
	{".", ","}	// Tick_Empty
};

StringMap		g_hMap_TargetClasses;

DisplayManager	g_displayManager;
Healthbar		g_healthbars[MAXPLAYERS_L4D2 + 1][Target_MAX];

/** convar settings */
ConVar			g_hConVar_TargetTimeout;
float			g_fTargetTimeout;

ConVar			g_hConVar_DecayDelay;
float			g_fDecayDelay;

ConVar			g_hConVar_DecayDuration;
float			g_fDecayDuration;

ConVar			g_hConVar_FrameInterval;
float			g_fFrameInterval;

ConVar			g_hConVar_AnchorLineLen;
int				g_iAnchorLineLen;

ConVar			g_hConVar_BarLen[Target_MAX];
int				g_iBarLen[Target_MAX];

ConVar			g_hConVar_KillerFeedbackPattern;
int				g_iPattern[Pattern_MAX][32];
int				g_iPatternLen[Pattern_MAX] = {1, ...};

/** cookie settings */
Cookie			g_hCookie_HealthbarEnabled[Target_MAX];
bool			g_bHealthbarEnabled[MAXPLAYERS_L4D2 + 1][Target_MAX];
ConVar			g_hConVar_HealthbarEnabledDefault[Target_MAX];
bool			g_bHealthbarEnabledDefault[Target_MAX];

Cookie			g_hCookie_RecentDamageEnabled;
bool			g_bRecentDamageEnabled[MAXPLAYERS_L4D2 + 1];
ConVar			g_hConVar_RecentDamageEnabledDefault;
bool			g_bRecentDamageEnabledDefault;

Cookie			g_hCookie_KillerFeedbackEnabled;
bool			g_bKillerFeedbackEnabled[MAXPLAYERS_L4D2 + 1];
ConVar			g_hConVar_KillerFeedbackEnabledDefault;
bool			g_bKillerFeedbackEnabledDefault;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hConVar_DecayDelay = CreateConVar(
		"infected_hp_recent_damage_decay_delay", "0.64",
		"how long in seconds must a client not deal damage to a target for the recent \
		damage ticks to start decaying away?",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_DecayDelay.AddChangeHook(ConVarChanged_General);

	g_hConVar_DecayDuration = CreateConVar(
		"infected_hp_recent_damage_decay_duration", "0.32",
		"how long in seconds should it take for the recent damage ticks to fully decay?",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_DecayDuration.AddChangeHook(ConVarChanged_General);

	g_hConVar_FrameInterval = CreateConVar(
		"infected_hp_animation_frametime", "0.04", // 25fps
		"if a health bar has an ongoing animated effect, how many seconds should we wait \
		between frames?",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_FrameInterval.AddChangeHook(ConVarChanged_General);

	g_hConVar_KillerFeedbackPattern = CreateConVar(
		"infected_hp_pattern_killer_feedback", "0,0,0,1,0,1,0,1",
		"pattern of character types to use when drawing HP bars when the bar's owner \
		is the killer (and this killer feedback is enabled by the client). \
		format it like \"n,n,n\". n is a number, either 0 (normal character), or 1 \
		(\"shift\" character). this pattern repeats across the length of the bar.",
		CVAR_FLAGS);
	g_hConVar_KillerFeedbackPattern.AddChangeHook(ConVarChanged_General);

	g_hConVar_TargetTimeout = CreateConVar(
		"infected_hp_timeout", "2.5",
		"how long in seconds since the healthbar target changed to remove the target?",
		CVAR_FLAGS, true, 0.1);
	g_hConVar_TargetTimeout.AddChangeHook(ConVarChanged_General);

	/**
	 * the below 4 convars contribute to the size limit of a TextMsg user message.
	 * the sum of all bar lengths + anchor length + 81 SHOULD NOT EXCEED 254. default
	 * values are very close to this limit already.
	 */

	g_hConVar_BarLen[Target_Common] = CreateConVar(
		"infected_hp_bar_len_common", "20",
		"how many ticks to draw for health bars of the \"common\" (common infected) \
		target type.",
		CVAR_FLAGS, true, 1.0, true, 171.0);
	g_hConVar_BarLen[Target_Common].AddChangeHook(ConVarChanged_General);

	g_hConVar_BarLen[Target_Special] = CreateConVar(
		"infected_hp_bar_len_special", "40",
		"how many ticks to draw for health bars of the \"special\" (all non-boss special \
		infected) target type.",
		CVAR_FLAGS, true, 1.0, true, 171.0);
	g_hConVar_BarLen[Target_Special].AddChangeHook(ConVarChanged_General);

	g_hConVar_BarLen[Target_Boss] = CreateConVar(
		"infected_hp_bar_len_boss", "60",
		"how many ticks to draw for health bars of the \"boss\" (tanks and witches) target type.",
		CVAR_FLAGS, true, 1.0, true, 171.0);
	g_hConVar_BarLen[Target_Boss].AddChangeHook(ConVarChanged_General);

	g_hConVar_AnchorLineLen = CreateConVar(
		"infected_hp_anchor_len", "50",
		"to make on-screen position of the healthbars consistent, the plugin will draw a line of \
		whitespaces. if this whitespace line is the longest line, all lines containing the bars will \
		be aligned to the left most character of the whitespace line - or rather, the \"anchor\" \
		line. this convar controls the amount of whitespace bytes to draw for this anchor line.",
		CVAR_FLAGS, true, 0.0, true, 170.0);
	g_hConVar_AnchorLineLen.AddChangeHook(ConVarChanged_General);

	RegisterCookie(g_hCookie_HealthbarEnabled[Target_Common], g_hConVar_HealthbarEnabledDefault[Target_Common],
		"hp_display_common", "0",
		"should a healthbar be displayed for targets of the \"common\" (common infected) type?");

	RegisterCookie(g_hCookie_HealthbarEnabled[Target_Special], g_hConVar_HealthbarEnabledDefault[Target_Special],
		"hp_display_special", "1",
		"should a healthbar be displayed for targets of the \"special\" (all non-boss special infected) type?");

	RegisterCookie(g_hCookie_HealthbarEnabled[Target_Boss], g_hConVar_HealthbarEnabledDefault[Target_Boss],
		"hp_display_boss", "1",
		"should a healthbar be displayed for targets of the \"boss\" (witches and tanks) type?");

	RegisterCookie(g_hCookie_RecentDamageEnabled, g_hConVar_RecentDamageEnabledDefault,
		"hp_show_recent_damage", "0",
		"should your recent damage be rendered with special ticks in infected healthbars?");

	RegisterCookie(g_hCookie_KillerFeedbackEnabled, g_hConVar_KillerFeedbackEnabledDefault,
		"hp_celebrate_your_kills", "0",
		"should healthbars of infected you kill animate with a special effect?");

	ReadGeneralConVars();
	ReadCookieConVars();

	g_hMap_TargetClasses = new StringMap();
	g_hMap_TargetClasses.SetValue("smoker", 0);
	g_hMap_TargetClasses.SetValue("boomer", 0);
	g_hMap_TargetClasses.SetValue("hunter", 0);
	g_hMap_TargetClasses.SetValue("spitter", 0);
	g_hMap_TargetClasses.SetValue("jockey", 0);
	g_hMap_TargetClasses.SetValue("charger", 0);
	g_hMap_TargetClasses.SetValue("tank", 0);
	g_hMap_TargetClasses.SetValue("player", 0);
	g_hMap_TargetClasses.SetValue("infected", 0);
	g_hMap_TargetClasses.SetValue("witch", 0);

	g_displayManager.Init();
	for (int i = 0; i < sizeof(g_healthbars); i++)
	{
		for (int t = 0; t < sizeof(g_healthbars[]); t++)
			g_healthbars[i][t].Init(i);
	}

	if (g_bLateLoaded)
	{
		UpdateCookiesAll();

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (IsFakeClient(i)) continue;

			AddEntityHook(i, EntityHook_SetObserverTarget, EHook_Post, OnSetObserverTarget_Post);
		}

		char sClass[16];
		for (int i = 1; i <= MAXEDICTS; i++)
		{
			if (!IsValidEdict(i)) continue;
			GetEntityClassname(i, sClass, sizeof(sClass));

			if (g_hMap_TargetClasses.ContainsKey(sClass))
				HookTarget(i);
		}
	}
}

void RegisterCookie(Cookie &hCookie, ConVar &hDefault, const char[] sName, const char[] sDefaultValue, const char[] sDesc)
{
	hCookie = new Cookie(sName, sDesc, CookieAccess_Public);
	#if defined _cookie_manager_included_
		if (LibraryExists(COOKIE_MANAGER_LIBRARY))
		{
			g_bCookiesHooked = true;
			HookCookieChange(sName, OnCookieChanged);
		}
	#endif

	char sConVarName[COOKIE_MAX_NAME_LENGTH + 8];
	char sConVarDesc[COOKIE_MAX_NAME_LENGTH + COOKIE_MAX_DESCRIPTION_LENGTH + 50];
	FormatEx(sConVarName, sizeof(sConVarName),
		"cookie_%s", sName);
	FormatEx(sConVarDesc, sizeof(sConVarDesc),
		"default value for the \"%s\" cookie. cookie desc: %s", sName, sDesc);

	hDefault = CreateConVar(sConVarName, sDefaultValue, sConVarDesc);
	hDefault.AddChangeHook(ConVarChanged_Cookie);
}

/*********
 * ConVars
 *********/

void ConVarChanged_General(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadGeneralConVars();
}

void ConVarChanged_Cookie(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadCookieConVars();
	UpdateCookiesAll();
}

void ReadGeneralConVars()
{
	g_fDecayDelay = g_hConVar_DecayDelay.FloatValue;
	g_fDecayDuration = g_hConVar_DecayDuration.FloatValue;
	g_fFrameInterval = g_hConVar_FrameInterval.FloatValue;
	g_iAnchorLineLen = g_hConVar_AnchorLineLen.IntValue;
	g_fTargetTimeout = g_hConVar_TargetTimeout.FloatValue;

	for (any i = 0; i < Target_MAX; i++)
		g_iBarLen[i] = g_hConVar_BarLen[i].IntValue;

	ReadPatternConVar(g_hConVar_KillerFeedbackPattern, Pattern_KillerFeedback);
}

void ReadPatternConVar(ConVar hConVar, PatternType pattern)
{
	char sBuffer[128];
	int iWrite;
	int iNum;
	hConVar.GetString(sBuffer, sizeof(sBuffer));

	for (int i = 0; i < sizeof(sBuffer); i++)
	{
		if (sBuffer[i] == '\0')
			break;

		if (CharToInt(sBuffer[i], iNum))
			g_iPattern[pattern][iWrite++] = iNum;
	}

	if (!iWrite)
		g_iPattern[pattern][iWrite++] = 0;

	g_iPatternLen[pattern] = iWrite;
}

void ReadCookieConVars()
{
	g_bRecentDamageEnabledDefault = g_hConVar_RecentDamageEnabledDefault.BoolValue;
	g_bKillerFeedbackEnabledDefault = g_hConVar_KillerFeedbackEnabledDefault.BoolValue;

	for (any i = 0; i < Target_MAX; i++)
		g_bHealthbarEnabledDefault[i] = g_hConVar_HealthbarEnabledDefault[i].BoolValue;
}

/**********
 * Cookies
 *********/

#if defined _cookie_manager_included_
	public void OnLibraryAdded(const char[] sName)
	{
		if (strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			HookCookies();
	}

	public void OnLibraryRemoved(const char[] sName)
	{
		if (g_bCookiesHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookiesHooked = false;
	}

	void HookCookies()
	{
		g_bCookiesHooked = true;

		HookCookieChange("hp_focus_damage", OnCookieChanged);
		HookCookieChange("hp_focus_cursor", OnCookieChanged);
		HookCookieChange("hp_display_common", OnCookieChanged);
		HookCookieChange("hp_display_special", OnCookieChanged);
		HookCookieChange("hp_display_boss", OnCookieChanged);
		HookCookieChange("hp_show_recent_damage", OnCookieChanged);
		HookCookieChange("hp_celebrate_your_kills", OnCookieChanged);
	}

	void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		UpdateCookies(iClient);
	}
#endif

public void OnClientPutInServer(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	UpdateCookies(iClient);
	AddEntityHook(iClient, EntityHook_SetObserverTarget, EHook_Post, OnSetObserverTarget_Post);
}

public void OnClientCookiesCached(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	UpdateCookies(iClient);
}

void UpdateCookiesAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (IsFakeClient(i)) continue;

		UpdateCookies(i);
	}
}

void UpdateCookies(int iClient)
{
	bool bCached = AreClientCookiesCached(iClient);

	g_bRecentDamageEnabled[iClient] =
		GetCookieValue(g_hCookie_RecentDamageEnabled, iClient, bCached, g_bRecentDamageEnabledDefault);
	g_bKillerFeedbackEnabled[iClient] =
		GetCookieValue(g_hCookie_KillerFeedbackEnabled, iClient, bCached, g_bKillerFeedbackEnabledDefault);

	for (any i = 0; i < Target_MAX; i++)
	{
		g_bHealthbarEnabled[iClient][i] =
			GetCookieValue(g_hCookie_HealthbarEnabled[i], iClient, bCached, g_bHealthbarEnabledDefault[i]);
	}
}

bool GetCookieValue(Cookie hCookie, int iClient, bool bCached, bool bDefault)
{
	if (bCached)
	{
		static char sValue[2];
		hCookie.Get(iClient, sValue, sizeof(sValue));

		switch (sValue[0])
		{
			case '1': return true;
			case '0': return false;
		}
	}

	return bDefault;
}

/**********
 * helpers
 **********/

TargetType GetTargetType(ZombieClass class)
{
	switch (class)
	{
		case ZClass_Common:
			return Target_Common;

		case ZClass_Smoker, ZClass_Boomer, ZClass_Hunter, ZClass_Spitter, ZClass_Jockey, ZClass_Charger:
			return Target_Special;

		case ZClass_Witch, ZClass_Tank:
			return Target_Boss;
	}

	return Target_None;
}

bool HasTarget(int iClient, int iEntRef)
{
	for (int i = 0; i < sizeof(g_healthbars[]); i++)
	{
		if (g_healthbars[iClient][i].entref == iEntRef)
			return true;
	}

	return false;
}

int GetHealth(int iEntity, ZombieClass class)
{
	/** health behaves abnormally when tank is incap (death anim) */
	bool bForceZero;
	if (class == ZClass_Tank)
		bForceZero = !IsPlayerAlive(iEntity) || IsPlayerIncapacitated(iEntity);
	else bForceZero = !IsEntityAlive(iEntity);

	if (bForceZero) return 0;

	int iHealth = GetEntityHealth(iEntity);
	if (iHealth < 0) return 0;
	return iHealth;
}

/***********
 * bar data
 ***********/

enum struct Healthbar
{
	int displayID;
	int lazyTickets;

	int entref;
	Handle timeout;

	int lastKnownMax;
	ZombieClass lastKnownClass;

	bool isKiller;
	float patternAnimStart;

	Handle decayDelay;
	int recentDamage;

	Handle decayDuration;
	int decayAmount;
	float decayEnd;

	void Init(int iDisplayID)
	{
		this.displayID = iDisplayID;
		this.entref = INVALID_ENT_REFERENCE;
		this.decayDelay = null;
		this.timeout = null;
		this.decayDuration = null;
	}

	/** calls when the player is no longer valid */
	void Reset()
	{
		this.entref = INVALID_ENT_REFERENCE;
		if (this.decayDelay) delete this.decayDelay;
		if (this.timeout) delete this.timeout;

		this.lazyTickets = 0;
		this.isKiller = false;
		if (this.decayDuration) delete this.decayDuration;
	}

	void SetTarget(int iEntity)
	{
		if (this.timeout) delete this.timeout;
		this.timeout = CreateTimer(g_fTargetTimeout, Timer_OnTargetTimeout, this);

		g_displayManager.Renew(this.displayID);
		int iEntRef = EntIndexToEntRef(iEntity);

		if (iEntRef == this.entref) return;

		this.entref = iEntRef;
		this.lastKnownMax = GetEntityMaxHealth(iEntity);
		this.lastKnownClass = GetZombieClass(iEntity);

		this.recentDamage = 0;
		if (this.decayDelay) delete this.decayDelay;

		if (this.decayDuration) TriggerTimer(this.decayDuration);
		if (this.isKiller) this.RevokeKill();
		this.patternAnimStart = 0.0;
	}

	void DealDamage(int iDamage)
	{
		if (this.decayDelay) delete this.decayDelay;
		if (this.decayDuration) TriggerTimer(this.decayDuration);

		this.recentDamage += iDamage;
		this.decayDelay = CreateTimer(g_fDecayDelay, Timer_OnDecayDelayElapsed, this);
	}

	void Kill()
	{
		if (this.isKiller)
			return;

		this.isKiller = true;
		this.patternAnimStart = GetGameTime();

		this.IssueLazyTicket();
	}

	void RevokeKill()
	{
		this.isKiller = false;
		this.RevokeLazyTicket();
	}

	void StartDecay()
	{
		if (!this.IssueLazyTicket())
			return;

		this.decayAmount = this.recentDamage;
		this.decayEnd = GetGameTime() + g_fDecayDuration;

		this.recentDamage = 0;
		this.decayDuration = CreateTimer(g_fDecayDuration, Timer_OnDecayDurationElapsed, this);
	}

	bool IssueLazyTicket()
	{
		this.lazyTickets++;
		return g_displayManager.AddLazyTicket(this.displayID);
	}

	bool RevokeLazyTicket()
	{
		this.lazyTickets--;
		return g_displayManager.RemoveLazyTicket(this.displayID);
	}

	int ConcatToRender(int iViewer, char[] sRender, int iRenderLen, int iBarLen)
	{
		if (this.entref == INVALID_ENT_REFERENCE)
			return 0;

		int iNowHP;
		int iMaxHP;
		ZombieClass class;

		/** get entity data */
		int iEntity = EntRefToEntIndex(this.entref);
		if (iEntity == INVALID_ENT_REFERENCE)
		{
			iNowHP = 0;
			iMaxHP = this.lastKnownMax;
			class = this.lastKnownClass;
		}
		else
		{
			class = GetZombieClass(iEntity);
			iNowHP = GetHealth(iEntity, class);
			iMaxHP = GetEntityMaxHealth(iEntity);

			this.lastKnownMax = iMaxHP;
			this.lastKnownClass = class;
		}

		/** get ticks to draw */
		float fCurrentTime = GetGameTime();
		int iTickAmount[Tick_MAX];
		int iTickIndex = 0;

		iTickAmount[Tick_Health] = RoundToCeil((float(iNowHP) / float(iMaxHP)) * float(iBarLen));
		if (g_bRecentDamageEnabled[iViewer])
		{
			int iRecentDamage;
			if (this.recentDamage)
				iRecentDamage = this.recentDamage;
			else if (this.decayDuration && fCurrentTime < this.decayEnd)
			{
				iRecentDamage = RoundToCeil(
					float(this.decayAmount) * ((this.decayEnd - fCurrentTime) / g_fDecayDuration));
			}

			if (iRecentDamage > 0)
			{
				iTickAmount[Tick_RecentDamage] = RoundToCeil(
					(float(iNowHP + iRecentDamage) / float(iMaxHP)) * float(iBarLen) - iTickAmount[Tick_Health]);
			}
		}
		iTickAmount[Tick_Empty] = iBarLen - iTickAmount[Tick_RecentDamage] - iTickAmount[Tick_Health];

		/** determine pattern to use for tick drawing */
		PatternType pattern = Pattern_Normal;
		if (this.isKiller && g_bKillerFeedbackEnabled[iViewer])
			pattern = Pattern_KillerFeedback;

		int iPatternIndex = 0;
		if (this.patternAnimStart)
		{
			int iFramesPassed = RoundToFloor(
				(fCurrentTime - this.patternAnimStart) / g_fFrameInterval);
			if (iFramesPassed > 0)
				iPatternIndex = iFramesPassed % g_iPatternLen[pattern];
		}

		/** draw */
		int iWritten = StrCat(sRender, iRenderLen, "HP: ");
		bool bAbort = false;

		for (int i = 0; i < iBarLen; i++)
		{
			while (iTickAmount[iTickIndex] <= 0)
			{
				iTickIndex++;
				if (iTickIndex >= Tick_MAX)
				{
					bAbort = true;
					break;
				}
			}
			if (bAbort) break;

			iWritten += StrCat(sRender, iRenderLen,
				g_sTick[iTickIndex][g_iPattern[pattern][iPatternIndex]]);

			iPatternIndex++;
			if (iPatternIndex >= g_iPatternLen[pattern])
				iPatternIndex = 0;

			iTickAmount[iTickIndex]--;
		}

		static char sDetails[32];
		FormatEx(sDetails, sizeof(sDetails), "l  [ %i ]  %s", iNowHP, g_sZClass[class]);
		iWritten += StrCat(sRender, iRenderLen, sDetails);

		return iWritten;
	}
}

void Timer_OnTargetTimeout(Handle hTimer, Healthbar bar)
{
	bar.timeout = null;
	if (!g_displayManager.RemoveLazyTicket(bar.displayID, bar.lazyTickets))
		return;

	bar.Reset();
	g_displayManager.QueueUpdate(bar.displayID);
}

void Timer_OnDecayDelayElapsed(Handle hTimer, Healthbar bar)
{
	bar.decayDelay = null;
	bar.StartDecay();
}

void Timer_OnDecayDurationElapsed(Handle hTimer, Healthbar bar)
{
	bar.decayDuration = null;
	bar.RevokeLazyTicket();
}

/***************
 * display manager
 ***************/

enum struct DisplayManager
{
	int userid[MAXPLAYERS_L4D2 + 1];

	int lazyTickets[MAXPLAYERS_L4D2 + 1];
	Handle keepAlive[MAXPLAYERS_L4D2 + 1];
	float lastUpdateTime[MAXPLAYERS_L4D2 + 1];

	bool updateQueued[MAXPLAYERS_L4D2 + 1];

	void Init()
	{
		for (int i = 0; i < sizeof(this.keepAlive); i++)
			this.keepAlive[i] = null;
	}

	void Reset(int iClient)
	{
		this.userid[iClient] = 0;
		this.lazyTickets[iClient] = 0;
		this.lastUpdateTime[iClient] = 0.0;
		if (this.keepAlive[iClient]) delete this.keepAlive[iClient];

		for (any i = 0; i < sizeof(g_healthbars[]); i++)
			g_healthbars[iClient][i].Reset();
	}

	bool Verify(int iClient)
	{
		if (IsClientInGame(iClient))
		{
			int iUserID = GetClientUserId(iClient);
			if (iUserID == this.userid[iClient])
				return true;
		}

		this.Reset(iClient);
		return false;
	}

	void Renew(int iClient)
	{
		if (!this.Verify(iClient))
			this.userid[iClient] = GetClientUserId(iClient);
	}

	bool AddLazyTicket(int iClient, int iCount = 1)
	{
		if (!this.Verify(iClient)) return false;

		if (!this.lazyTickets[iClient])
			SDKHook(iClient, SDKHook_PostThinkPost, LazyUpdateOnThink);

		this.lazyTickets[iClient] += iCount;
		return true;
	}

	bool RemoveLazyTicket(int iClient, int iCount = 1)
	{
		if (!this.Verify(iClient)) return false;

		if (!this.lazyTickets[iClient]) return true;
		this.lazyTickets[iClient] -= iCount;

		if (this.lazyTickets[iClient] <= 0)
		{
			this.lazyTickets[iClient] = 0;
			SDKUnhook(iClient, SDKHook_PostThinkPost, LazyUpdateOnThink);
		}

		return true;
	}

	/**
	 * call this instead of Update() directly to avoid multiple updates in
	 * the same frame.
	 */
	void QueueUpdate(int iClient)
	{
		if (this.updateQueued[iClient])
			return;

		this.updateQueued[iClient] = true;
		RequestFrame(ProcessQueuedUpdate, iClient);
	}

	void Update(int iClient)
	{
		if (!this.Verify(iClient)) return;

		this.Render(iClient, iClient);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == iClient) continue;
			if (!IsClientInGame(i)) continue;
			if (!IsClientObserver(i)) continue;
			if (GetObserverTarget(i) != iClient) continue;

			this.Render(i, iClient);
		}

		this.lastUpdateTime[iClient] = GetGameTime();
		if (this.keepAlive[iClient]) delete this.keepAlive[iClient];

		for (int i = 0; i < sizeof(g_healthbars[]); i++)
		{
			if (g_healthbars[iClient][i].entref != INVALID_ENT_REFERENCE)
			{
				this.keepAlive[iClient] = CreateTimer(1.0, Timer_KeepAlive, iClient);
				break;
			}
		}
	}

	void Render(int iViewer, int iOwner)
	{
		/**
		 * TO-DO:
		 * determine total bytes for message. if > 254, then write some algorithm
		 * that downsizes anchor/bar lengths to fit.
		 */

		static char sRender[CENTER_TEXT_MAX_BUFFER];
		sRender[0] = '\0';
		int iWritten = 0;

		for (int i = 0; i < sizeof(g_healthbars[]); i++)
		{
			if (g_bHealthbarEnabled[iViewer][i])
				iWritten += g_healthbars[iOwner][i].ConcatToRender(iViewer, sRender, sizeof(sRender), g_iBarLen[i]);
			StrCat(sRender, sizeof(sRender), LINEFEED);
		}

		if (iWritten)
		{
			for (int i = 0; i < g_iAnchorLineLen; i++)
				StrCat(sRender, sizeof(sRender), WHITESPACE_TAB);
		}

		/** PrintCenterText() native will format the user message with 4 trailing bytes,
		 * which represent the (up to) 4 arguments expected. but in the case of center
		 * text, no such arguments are expected. the byte limit considers these trailing
		 * bytes, so opting to display the text this way means we save 4 bytes. */
		int iRecipients[1];
		iRecipients[0] = iViewer;
		BfWrite msg = view_as<BfWrite>(StartMessage("TextMsg", iRecipients, sizeof(iRecipients), USERMSG_RELIABLE));

		msg.WriteByte(CENTER_TEXT);
		msg.WriteString(sRender);

		EndMessage();
	}
}

void ProcessQueuedUpdate(int iClient)
{
	g_displayManager.updateQueued[iClient] = false;
	g_displayManager.Update(iClient);
}

void LazyUpdateOnThink(int iClient)
{
	if ((GetGameTime() - g_displayManager.lastUpdateTime[iClient]) < g_fFrameInterval)
		return;

	g_displayManager.QueueUpdate(iClient);
}

void Timer_KeepAlive(Handle hTimer, int iClient)
{
	g_displayManager.keepAlive[iClient] = null;
	g_displayManager.QueueUpdate(iClient);
}

/**********
 * events
 **********/

static int	g_iHealthPre;
static int	g_iHealthPreDeath;

static bool	g_bTakingDamage;

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (g_hMap_TargetClasses.ContainsKey(sClassName))
		HookTarget(iEntity);
}

void HookTarget(int iEntity)
{
	SDKHook(iEntity, SDKHook_OnTakeDamage, OnTakeDamage_Pre);
	SDKHook(iEntity, SDKHook_OnTakeDamagePost, OnTakeDamage_Post);

	AddEntityHook(iEntity, EntityHook_EventKilled, EHook_Pre, OnKilled_Pre);
	AddEntityHook(iEntity, EntityHook_EventKilled, EHook_Post, OnKilled_Post);
}

Action OnTakeDamage_Pre(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	g_bTakingDamage = true;
	g_iHealthPre = GetHealth(iVictim, GetZombieClass(iVictim));
	return Plugin_Continue;
}

void OnTakeDamage_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType)
{
	g_bTakingDamage = false;

	if (fDamage <= 0.0) return;

	ZombieClass class = GetZombieClass(iVictim);
	TargetType type = GetTargetType(class);

	if (IsValidClient(iAttacker) && type != Target_None)
	{
		g_healthbars[iAttacker][type].SetTarget(iVictim);

		int iHealth = GetHealth(iVictim, class);
		int iDamage = g_iHealthPre - iHealth;

		if (iDamage > 0)
			g_healthbars[iAttacker][type].DealDamage(iDamage);
	}

	int iEntRef = EntIndexToEntRef(iVictim);
	for (int i = 1; i <= MaxClients; i++)
		if (HasTarget(i, iEntRef)) g_displayManager.QueueUpdate(i);
}

Action OnKilled_Pre(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType,
	int &iWeapon, float vDamageForce[3], float vDamagePos[3])
{
	g_iHealthPreDeath = GetHealth(iVictim, GetZombieClass(iVictim));
	return Plugin_Continue;
}

void OnKilled_Post(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType,
	int iWeapon, const float vDamageForce[3], const float vDamagePos[3], bool bHandled)
{
	if (bHandled) return;

	TargetType type = GetTargetType(GetZombieClass(iVictim));

	if (IsValidClient(iAttacker) && type != Target_None)
	{
		g_healthbars[iAttacker][type].SetTarget(iVictim);
		g_healthbars[iAttacker][type].Kill();

		/** some weird scenarios have infected die outside of taking
		 * damage while still having health (i.e headshot killing commons) */
		if (!g_bTakingDamage && g_iHealthPreDeath > 0)
			g_healthbars[iAttacker][type].DealDamage(g_iHealthPre);
	}

	int iEntRef = EntIndexToEntRef(iVictim);
	for (int i = 1; i <= MaxClients; i++)
		if (HasTarget(i, iEntRef)) g_displayManager.QueueUpdate(i);
}

void OnSetObserverTarget_Post(int iObserver, int iTarget, bool bSuccess, bool bHandled)
{
	if (!bSuccess || !IsValidClient(iTarget) || !IsPlayerAlive(iTarget))
		return;

	g_displayManager.Verify(iTarget);
	g_displayManager.Render(iObserver, iTarget);
}
