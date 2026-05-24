#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <actions>
#include <hxlib>

#undef REQUIRE_PLUGIN
#include <cookie_manager>
#define REQUIRE_PLUGIN

public Plugin myinfo =
{
	name = "Jockey Audio Feedback",
	author = "Neburai",
	description = "jockey plays a warning sound when he gets close to his target",
	version = "1.2",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/jockey_audio_feedback"
};

#define	CVAR_FLAGS		FCVAR_NOTIFY
#define	UPDATE_INTERVAL	0.1
#define NO_OVERRIDE		-1

#define COOKIE			"jockey_warning_sound"
#define COOKIE_DEFAULT	"cookie_jockey_warning_sound"

enum WarningSetting
{
	Warning_Disabled,
	Warning_Personal,
	Warning_Global
};

bool			g_bLateLoaded;
#if defined _cookie_manager_included_
	bool		g_bCookieHooked;
#endif

float			g_fLastUpdate[MAXPLAYERS_L4D2 + 1];
int				g_iSoundLevelOverride = NO_OVERRIDE;

StringMap		g_hMap_TargetActions;

float			g_fLastWarning[MAXPLAYERS_L4D2 + 1];
float			g_fWarningCooldown[MAXPLAYERS_L4D2 + 1];

ConVar			g_hConVar_VocalizeCooldownMin;
ConVar			g_hConVar_VocalizeCooldownMax;
float			g_fVocalizeCooldownMin;
float			g_fVocalizeCooldownMax;

ConVar			g_hConVar_WarningIntervalMin;
ConVar			g_hConVar_WarningIntervalMax;
float			g_fWarningIntervalMin;
float			g_fWarningIntervalMax;

ConVar			g_hConVar_WarningRange;
float			g_fWarningRange;

ConVar			g_hConVar_IdleSoundLevel;
int				g_iIdleSoundLevel;

ConVar			g_hConVar_WarningSoundLevel;
int				g_iWarningSoundLevel;

WarningCookie	g_hCookie_WarningEnabled;
ConVar			g_hConVar_WarningEnabledDefault;
WarningSetting	g_warning[MAXPLAYERS_L4D2 + 1];
WarningSetting	g_warningDefault;

methodmap WarningCookie < Cookie
{
	public WarningCookie(const char[] sName, const char[] sDesc)
	{
		return view_as<WarningCookie>(RegClientCookie(sName, sDesc, CookieAccess_Public));
	}

	public void UpdateAll()
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			this.Update(i);
		}
	}

	public void Update(int iClient)
	{
		if (!IsFakeClient(iClient) && AreClientCookiesCached(iClient))
		{
			static char sValue[2];
			this.Get(iClient, sValue, sizeof(sValue));

			if (!CharToInt(sValue[0], g_warning[iClient]))
				g_warning[iClient] = g_warningDefault;
		}
		else g_warning[iClient] = g_warningDefault;
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoaded = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hMap_TargetActions = new StringMap();
	g_hMap_TargetActions.SetValue("JockeyAttack", 0);
	g_hMap_TargetActions.SetValue("JockeyAssault", 0);

	g_hConVar_VocalizeCooldownMin = CreateConVar(
		"audio_feedback_jockey_vocalize_interval_min", "1.15",
		"min time between repeated idle/recognize cries from jockeys (vanilla is 2.0)",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_VocalizeCooldownMin.AddChangeHook(ConVarChanged_Update);

	g_hConVar_VocalizeCooldownMax = CreateConVar(
		"audio_feedback_jockey_vocalize_interval_max", "1.8",
		"max time between repeated idle/recognize cries from jockeys (vanilla is 3.5)",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_VocalizeCooldownMax.AddChangeHook(ConVarChanged_Update);

	g_hConVar_WarningIntervalMin = CreateConVar(
		"audio_feedback_jockey_warning_interval_min", "5.0",
		"min time between repeated warning cries from jockey being in range of its target",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_WarningIntervalMin.AddChangeHook(ConVarChanged_Update);

	g_hConVar_WarningIntervalMax = CreateConVar(
		"audio_feedback_jockey_warning_interval_max", "6.0",
		"max time between repeated warning cries from jockey being in range of its target",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_WarningIntervalMax.AddChangeHook(ConVarChanged_Update);

	g_hConVar_WarningRange = CreateConVar(
		"audio_feedback_jockey_warning_range", "510.0",
		"range a jockey must be from its target to emit warning cries",
		CVAR_FLAGS, true, 0.0);
	g_hConVar_WarningRange.AddChangeHook(ConVarChanged_Update);

	g_hConVar_IdleSoundLevel = CreateConVar(
		"audio_feedback_jockey_idle_sound_level", "85",
		"force idle voice sounds to be of this sound level in decibels. " ...
		"in vanilla: jockey 105, all other SI 85",
		CVAR_FLAGS, true, 0.0, true, 180.0);
	g_hConVar_IdleSoundLevel.AddChangeHook(ConVarChanged_Update);

	g_hConVar_WarningSoundLevel = CreateConVar(
		"audio_feedback_jockey_warning_sound_level", "87",
		"force warning voice sounds to be of this sound level in decibels.",
		CVAR_FLAGS, true, 0.0, true, 180.0);
	g_hConVar_WarningSoundLevel.AddChangeHook(ConVarChanged_Update);

	g_hCookie_WarningEnabled = new WarningCookie(
		COOKIE, "should jockeys warn you on approach using a cut sound? " ...
			"0 = no; 1 = when approaching me; 2 = when approaching anyone");

	g_hConVar_WarningEnabledDefault = CreateConVar(
		COOKIE_DEFAULT, "1",
		"default value for \"" ... COOKIE ... "\" cookie. " ...
		"description: \"should jockeys warn you on approach using a cut sound? " ...
		"0 = no; 1 = when approaching me; 2 = when approaching anyone\"",
		CVAR_FLAGS, true, 0.0, true, 2.0);
	g_hConVar_WarningEnabledDefault.AddChangeHook(ConVarChanged_Cookie);

	AutoExecConfig(_, "jockey_audio_feedback");
	ReadCookieConVar();
	ReadConVars();

	AddNormalSoundHook(OnNormalSound);

	if (g_bLateLoaded)
	{
		HXLibRescanForwards();
		g_hCookie_WarningEnabled.UpdateAll();

		#if defined _cookie_manager_included_
			if (LibraryExists(COOKIE_MANAGER_LIBRARY))
				HookCookie();
		#endif
	}
}

#if defined _cookie_manager_included_
	public void OnAllPluginsLoaded()
	{
		if (!g_bCookieHooked && LibraryExists(COOKIE_MANAGER_LIBRARY))
			HookCookie();
	}

	public void OnLibraryAdded(const char[] sName)
	{
		if (!g_bCookieHooked && strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			HookCookie();
	}

	public void OnLibraryRemoved(const char[] sName)
	{
		if (strcmp(sName, COOKIE_MANAGER_LIBRARY) == 0)
			g_bCookieHooked = false;
	}

	void HookCookie()
	{
		g_bCookieHooked = true;
		HookCookieChange(COOKIE, OnCookieChanged);
	}

	void OnCookieChanged(const char[] sCookie, int iClient, const char[] sOldValue, const char[] sNewValue)
	{
		g_hCookie_WarningEnabled.Update(iClient);
	}
#endif

public void OnClientPutInServer(int iClient)
{
	g_fLastUpdate[iClient] = -1.0;
	g_fLastWarning[iClient] = -1.0;

	g_hCookie_WarningEnabled.Update(iClient);
}

public void OnClientCookiesCached(int iClient)
{
	g_hCookie_WarningEnabled.Update(iClient);
}

void ConVarChanged_Cookie(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadCookieConVar();
	g_hCookie_WarningEnabled.UpdateAll();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadCookieConVar()
{
	g_warningDefault = view_as<WarningSetting>(g_hConVar_WarningEnabledDefault.IntValue);
}

void ReadConVars()
{
	g_fVocalizeCooldownMin = g_hConVar_VocalizeCooldownMin.FloatValue;
	g_fVocalizeCooldownMax = g_hConVar_VocalizeCooldownMax.FloatValue;

	g_fWarningIntervalMin = g_hConVar_WarningIntervalMin.FloatValue;
	g_fWarningIntervalMax = g_hConVar_WarningIntervalMax.FloatValue;

	g_fWarningRange = Pow(g_hConVar_WarningRange.FloatValue, 2.0);

	g_iIdleSoundLevel = g_hConVar_IdleSoundLevel.IntValue;
	g_iWarningSoundLevel = g_hConVar_WarningSoundLevel.IntValue;
}

public Action OnVocalize(int iClient, char sGameSound[64], float &fCooldown, float &fDurationAI)
{
	if (GetZombieClass(iClient) == ZClass_Jockey && strcmp(sGameSound, "JockeyZombie.Recognize") == 0)
	{
		fCooldown = GetRandomFloat(g_fVocalizeCooldownMin, g_fVocalizeCooldownMax);
		g_iSoundLevelOverride = g_iIdleSoundLevel;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void OnVocalize_Post(int iClient, const char sGameSound[64], float fCooldown, float fDurationAI, bool bHandled)
{
	g_iSoundLevelOverride = NO_OVERRIDE;
}

Action OnNormalSound(int clients[64], int &numClients, char sSample[PLATFORM_MAX_PATH], int &iEntity,
	int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sSoundEntry[256], int &iSeed)
{
	if (g_iSoundLevelOverride != NO_OVERRIDE)
	{
		iLevel = g_iSoundLevelOverride;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/**********
 * warning
 **********/

methodmap BehaviorJockey < BehaviorAction
{
	public int GetTarget()
	{
		return this.GetHandleEntity(0x3c);
	}
}

public void OnActionCreated(BehaviorAction action, int iActor, const char[] sName, ActionId id)
{
	if ((1 <= iActor <= MaxClients) && g_hMap_TargetActions.ContainsKey(sName))
		action.OnUpdatePost = Attack_OnUpdatePost;
}

void Attack_OnUpdatePost(BehaviorJockey action, int iActor, float fInterval, ActionResult result)
{
	float fNow = GetGameTime();
	if ((fNow - g_fLastUpdate[iActor]) < UPDATE_INTERVAL || HasVictim(iActor))
		return;

	g_fLastUpdate[iActor] = fNow;

	int iTarget = action.GetTarget();
	if (!IsValidEdict(iTarget)) return;

	float vActorPos[3];
	float vTargetPos[3];
	GetClientEyePosition(iActor, vActorPos);
	GetCollisionCenter(iTarget, vTargetPos);
	float fDistance = GetVectorDistance(vActorPos, vTargetPos, true);

	if (fDistance <= g_fWarningRange)
	{
		Handle hTrace = TR_TraceRayFilterSimple(
			vActorPos, vTargetPos, MASK_PLAYERSOLID, RayType_EndPoint, iActor, CollisionGroup_Player, TraceEntityFilter_Warn);

		if (!TR_DidHit(hTrace))
		{
			if (TryWarning(iActor, iTarget))
			{
				delete hTrace;
				return;
			}
		}
		delete hTrace;
	}
}

bool TraceEntityFilter_Warn(int iEntity, int iContentMask)
{
	if (IsCombatCharacter(iEntity))
		return false;

	return true;
}

bool TryWarning(int iJockey, int iTarget)
{
	float fNow = GetGameTime();
	if ((fNow - g_fLastWarning[iJockey]) < g_fWarningCooldown[iJockey])
		return false;

	EmitWarning(iJockey, iTarget, "JockeyZombie.Warn", true);
	EmitWarning(iJockey, iTarget, "JockeyZombie.Recognize", false);

	SetVocalizeCooldown(iJockey, GetRandomFloat(g_fVocalizeCooldownMin, g_fVocalizeCooldownMax));
	g_fWarningCooldown[iJockey] = GetRandomFloat(g_fWarningIntervalMin, g_fWarningIntervalMax);
	g_fLastWarning[iJockey] = fNow;

	return true;
}

void EmitWarning(int iJockey, int iTarget, const char[] sGameSound, bool bIsWarning)
{
	int iChannel;
	int iLevel;
	float fVolume;
	int iPitch;
	static char sSample[PLATFORM_MAX_PATH];

	int[] iRecipients = new int[MaxClients];
	int iNumRecipients = 0;

	float vSource[3];
	GetClientEyePosition(iJockey, vSource);

	GetGameSoundParams(sGameSound,
		iChannel,
		iLevel,
		fVolume,
		iPitch,
		sSample,
		sizeof(sSample),
		iJockey);
	iLevel = bIsWarning ? g_iWarningSoundLevel : g_iIdleSoundLevel;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)
			|| WantsWarningSound(i, iTarget) != bIsWarning)
			continue;

		iRecipients[iNumRecipients++] = i;
	}
	if (!iNumRecipients) return;

	FilterClientsByAttenuation(iRecipients, iNumRecipients, vSource, iLevel);

	EmitSound(iRecipients, iNumRecipients, sSample, iJockey, iChannel, iLevel, _, fVolume, iPitch);
}

bool WantsWarningSound(int iClient, int iTarget)
{
	switch (g_warning[iClient])
	{
		case Warning_Disabled:
			return false;

		case Warning_Personal:
			return iClient == iTarget;

		case Warning_Global:
			return true;
	}

	return false;
}
