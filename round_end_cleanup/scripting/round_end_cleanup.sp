#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <hxstocks>

public Plugin myinfo =
{
	name = "Round End Cleanup",
	author = "Neburai",
	description = "dispose of viewmodels on round end.",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/round_end_cleanup"
};

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
}

void Event_RoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iOwner;
	int iTeam;
	static char sClass[32];

	for (int i = MaxClients + 1; i < MAXEDICTS; i++)
	{
		if (!IsValidEdict(i))
			continue;

		GetEntityClassname(i, sClass, sizeof(sClass));
		if (strcmp(sClass, "predicted_viewmodel") != 0)
			continue;

		iOwner = GetEntPropEnt(i, Prop_Data, "m_hOwner");
		if (!IsValidClient(iOwner))
			continue;

		iTeam = GetClientTeam(iOwner);
		if (iTeam != Team_Survivor && iTeam != Team_Infected)
			continue;

		RemoveEdict(i);
	}
}
