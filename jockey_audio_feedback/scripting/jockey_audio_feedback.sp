#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <actions>
#include <hxlib>

public Plugin myinfo =
{
	name = "Jockey Audio Feedback",
	author = "Neburai",
	description = "jockey plays a warning sound when he gets close to his target",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/jockey_audio_feedback"
};

#define		CVAR_FLAGS		FCVAR_NOTIFY
#define		UPDATE_INTERVAL	0.1

bool		g_bLateLoaded;

float		g_fLastUpdate[MAXPLAYERS_L4D2 + 1];
bool		g_bInterceptRecognize;

StringMap	g_hMap_TargetActions;

float		g_fLastWarning[MAXPLAYERS_L4D2 + 1];
float		g_fWarningCooldown[MAXPLAYERS_L4D2 + 1];

ConVar		g_hConVar_VocalizeCooldownMin;
ConVar		g_hConVar_VocalizeCooldownMax;
float		g_fVocalizeCooldownMin;
float		g_fVocalizeCooldownMax;

ConVar		g_hConVar_WarningIntervalMin;
ConVar		g_hConVar_WarningIntervalMax;
float		g_fWarningIntervalMin;
float		g_fWarningIntervalMax;

ConVar		g_hConVar_WarningRange;
float		g_fWarningRange;

ConVar		g_hConVar_IdleSoundLevel;
int			g_iIdleSoundLevel;

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
		"force idle voice sounds to be of this sound level in decibels. \
		in vanilla: jockey 105, all other SI 85",
		CVAR_FLAGS, true, 0.0, true, 180.0);
	g_hConVar_IdleSoundLevel.AddChangeHook(ConVarChanged_Update);

	ReadConVars();

	AddNormalSoundHook(OnNormalSound);

	if (g_bLateLoaded) HXLibRescanForwards();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_fVocalizeCooldownMin = g_hConVar_VocalizeCooldownMin.FloatValue;
	g_fVocalizeCooldownMax = g_hConVar_VocalizeCooldownMax.FloatValue;

	g_fWarningIntervalMin = g_hConVar_WarningIntervalMin.FloatValue;
	g_fWarningIntervalMax = g_hConVar_WarningIntervalMax.FloatValue;

	g_fWarningRange = Pow(g_hConVar_WarningRange.FloatValue, 2.0);

	g_iIdleSoundLevel = g_hConVar_IdleSoundLevel.IntValue;
}

public void OnClientPutInServer(int iClient)
{
	g_fLastUpdate[iClient] = -1.0;
	g_fLastWarning[iClient] = -1.0;
}


public Action OnVocalize(int iClient, char sGameSound[64], float &fCooldown, float &fDurationAI)
{
	if (GetZombieClass(iClient) == ZClass_Jockey && strcmp(sGameSound, "JockeyZombie.Recognize") == 0)
	{
		fCooldown = GetRandomFloat(g_fVocalizeCooldownMin, g_fVocalizeCooldownMax);
		g_bInterceptRecognize = true;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void OnVocalize_Post(int iClient, const char sGameSound[64], float fCooldown, float fDurationAI, bool bHandled)
{
	g_bInterceptRecognize = false;
}

Action OnNormalSound(int clients[64], int &numClients, char sSample[PLATFORM_MAX_PATH], int &iEntity,
	int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sSoundEntry[256], int &iSeed)
{
	if (g_bInterceptRecognize)
	{
		iLevel = g_iIdleSoundLevel;
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
			if (TryWarning(iActor))
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

bool TryWarning(int iJockey)
{
	float fNow = GetGameTime();
	if ((fNow - g_fLastWarning[iJockey]) < g_fWarningCooldown[iJockey])
		return false;

	g_fWarningCooldown[iJockey] = GetRandomFloat(g_fWarningIntervalMin, g_fWarningIntervalMax);
	g_fLastWarning[iJockey] = fNow;

	Vocalize(iJockey, "JockeyZombie.Warn", GetRandomFloat(g_fVocalizeCooldownMin, g_fVocalizeCooldownMax));
	return true;
}
