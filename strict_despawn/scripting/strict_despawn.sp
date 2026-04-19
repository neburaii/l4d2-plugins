#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <actions>
#include <hxlib>

#define	CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Despawner",
	author = "Neburai",
	description = "despawn stuck infected",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/strict_despawn"
};

Despawner	g_despawner;

ConVar		g_hConVar_ZombieDiscardRangeDefault;
float		g_fZombieDiscardRangeDefault;

ConVar		g_hConVar_MaxStuckTime;
float		g_fMaxStuckTime;

StringMap	g_hMap_TargetBehaviors;

enum struct Despawner
{
	ArrayList candidates;
	Handle updater;

	void Init()
	{
		this.candidates = new ArrayList(sizeof(CandidateData));
		this.updater = null;
	}

	void AddCandidate(int iCandidate)
	{
		int iEntRef = EntIndexToEntRef(iCandidate);
		CandidateData data;
		int iIndex = this.GetCandidate(iEntRef, data);

		data.Init(iEntRef);

		if (iIndex >= 0)
			this.candidates.SetArray(iIndex, data);
		else this.candidates.PushArray(data);

		if (!this.updater)
			this.updater = CreateTimer(0.5, Timer_DespawnerUpdate, _, TIMER_REPEAT);
	}

	void RemoveCandidate(int iCandidate)
	{
		this.candidates.Erase(iCandidate);
		if (this.candidates.Length <= 0 && this.updater)
			delete this.updater;
	}

	int GetCandidate(int iEntRef, CandidateData data)
	{
		for (int i = 0; i < this.candidates.Length; i++)
		{
			this.candidates.GetArray(i, data);
			if (iEntRef == data.entref)
				return i;
		}

		return -1;
	}

	void SetStuck(int iCandidate, bool bStuckStatus)
	{
		CandidateData data;
		int iIndex = this.GetCandidate(EntIndexToEntRef(iCandidate), data);

		if (iIndex >= 0 && data.stuck != bStuckStatus)
		{
			data.stuck = bStuckStatus;
			if (bStuckStatus) data.stuckTime = GetGameTime();

			this.candidates.SetArray(iIndex, data);
		}
	}

	void Update()
	{
		CandidateData candidate;
		int iEntIndex;
		int i;

		while (i < this.candidates.Length)
		{
			this.candidates.GetArray(i, candidate);
			iEntIndex = EntRefToEntIndex(candidate.entref);

			if (iEntIndex == INVALID_ENT_REFERENCE)
			{
				this.RemoveCandidate(i);
				continue;
			}

			if (candidate.ShouldDespawn())
			{
				float vPos[3];
				GetCollisionCenter(iEntIndex, vPos);
				float fDespawnRange = GetScriptValueFloat("ZombieDiscardRange", g_fZombieDiscardRangeDefault);

				if (!IsVisibleToTeam(Team_Survivor, vPos, fDespawnRange, _, 0, false, true))
				{
					RemoveEntity(iEntIndex);
					this.RemoveCandidate(i);
					continue;
				}
			}

			i++;
		}
	}
}

enum struct CandidateData
{
	int entref;

	bool stuck;
	float stuckTime;

	void Init(int iEntRef)
	{
		this.entref = iEntRef;
		this.stuck = false;
	}

	bool ShouldDespawn()
	{
		if (g_fMaxStuckTime >= 0.0 && this.stuck && (GetGameTime() - this.stuckTime) >= g_fMaxStuckTime)
			return true;

		return false;
	}
}

public void OnPluginStart()
{
	g_hConVar_ZombieDiscardRangeDefault = FindConVar("z_discard_range");
	g_hConVar_ZombieDiscardRangeDefault.AddChangeHook(ConVarChanged_Update);

	g_hConVar_MaxStuckTime = CreateConVar(
		"despawn_max_stuck_time", "15.0",
		"time in seconds an infected must be stuck to be a candidate \
		for being despawned. -1.0 to disable stuck despawns",
		CVAR_FLAGS, true, -1.0);
	g_hConVar_MaxStuckTime.AddChangeHook(ConVarChanged_Update);

	ReadConVars();

	g_hMap_TargetBehaviors = new StringMap();
	g_hMap_TargetBehaviors.SetValue("SmokerBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("BoomerBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("HunterBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("SpitterBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("JockeyBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("ChargerBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("TankBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("WitchBehavior", 0);
	g_hMap_TargetBehaviors.SetValue("InfectedBehavior", 0);

	g_despawner.Init();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_fZombieDiscardRangeDefault = g_hConVar_ZombieDiscardRangeDefault.FloatValue;
	g_fMaxStuckTime = g_hConVar_MaxStuckTime.FloatValue;
}

void Timer_DespawnerUpdate(Handle hTimer)
{
	g_despawner.Update();
}

public void OnActionCreated(BehaviorAction action, int iActor, const char[] sName, ActionId id)
{
	if (g_hMap_TargetBehaviors.ContainsKey(sName))
	{
		g_despawner.AddCandidate(iActor);
		action.OnStuckPost = OnStuck;
		action.OnUnStuckPost = OnUnStuck;
	}
}

Action OnStuck(BehaviorAction action, int iActor, ActionDesiredResult result)
{
	g_despawner.SetStuck(iActor, true);
	return Plugin_Continue;
}

Action OnUnStuck(BehaviorAction action, int iActor, ActionDesiredResult result)
{
	g_despawner.SetStuck(iActor, false);
	return Plugin_Continue;
}
