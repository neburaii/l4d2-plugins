#pragma newdecls required
#pragma semicolon 1

/** vanila convars to find */
ConVar	g_hConVar_MobMinSize;
ConVar	g_hConVar_NavFlowMaxSurvivorClimbHeight;
ConVar	g_hConVar_NavFlowMaxSurvivorDropHeight;
ConVar	g_hConVar_NavObscureRange;
ConVar	g_hConVar_DirectorBuildUpMinInterval;
ConVar	g_hConVar_DirectorSustainPeakMinTime;
ConVar	g_hConVar_DirectorSustainPeakMaxTime;
ConVar	g_hConVar_DirectorRelaxMinInterval;
ConVar	g_hConVar_DirectorRelaxMaxInterval;
ConVar	g_hConVar_NumReservedWanderers;

float	g_fConVar_MobMinSize;
float	g_fConVar_NavFlowMaxSurvivorClimbHeight;
float	g_fConVar_NavFlowMaxSurvivorDropHeight;
float	g_fConVar_NavObscureRange;
float	g_fConVar_DirectorBuildUpMinInterval;
float	g_fConVar_DirectorSustainPeakMinTime;
float	g_fConVar_DirectorSustainPeakMaxTime;
float	g_fConVar_DirectorRelaxMinInterval;
float	g_fConVar_DirectorRelaxMaxInterval;

int		g_iConVar_NumReservedWanderers;

void InitConVars()
{
	g_hConVar_MobMinSize = FindConVar(
		"z_mob_spawn_min_size");
	g_hConVar_MobMinSize.AddChangeHook(ConVarChanged_Update);

	g_hConVar_NavFlowMaxSurvivorClimbHeight = FindConVar(
		"nav_flow_max_survivor_climb_height");
	g_hConVar_NavFlowMaxSurvivorClimbHeight.AddChangeHook(ConVarChanged_Update);

	g_hConVar_NavFlowMaxSurvivorDropHeight = FindConVar(
		"nav_flow_max_survivor_drop_height");
	g_hConVar_NavFlowMaxSurvivorDropHeight.AddChangeHook(ConVarChanged_Update);

	g_hConVar_NavObscureRange = FindConVar(
		"nav_obscure_range");
	g_hConVar_NavObscureRange.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DirectorBuildUpMinInterval = FindConVar(
		"director_build_up_min_interval");
	g_hConVar_DirectorBuildUpMinInterval.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DirectorSustainPeakMinTime = FindConVar(
		"director_sustain_peak_min_time");
	g_hConVar_DirectorSustainPeakMinTime.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DirectorSustainPeakMaxTime = FindConVar(
		"director_sustain_peak_max_time");
	g_hConVar_DirectorSustainPeakMaxTime.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DirectorRelaxMinInterval = FindConVar(
		"director_relax_min_interval");
	g_hConVar_DirectorRelaxMinInterval.AddChangeHook(ConVarChanged_Update);

	g_hConVar_DirectorRelaxMaxInterval = FindConVar(
		"director_relax_max_interval");
	g_hConVar_DirectorRelaxMaxInterval.AddChangeHook(ConVarChanged_Update);

	g_hConVar_NumReservedWanderers = FindConVar(
		"director_num_reserved_wanderers");
	g_hConVar_NumReservedWanderers.AddChangeHook(ConVarChanged_Update);

	ReadConVars();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_fConVar_MobMinSize = g_hConVar_MobMinSize.FloatValue;
	g_fConVar_NavFlowMaxSurvivorClimbHeight = g_hConVar_NavFlowMaxSurvivorClimbHeight.FloatValue;
	g_fConVar_NavFlowMaxSurvivorDropHeight = g_hConVar_NavFlowMaxSurvivorDropHeight.FloatValue;
	g_fConVar_NavObscureRange = g_hConVar_NavObscureRange.FloatValue;
	g_fConVar_DirectorBuildUpMinInterval = g_hConVar_DirectorBuildUpMinInterval.FloatValue;
	g_fConVar_DirectorSustainPeakMinTime = g_hConVar_DirectorSustainPeakMinTime.FloatValue;
	g_fConVar_DirectorSustainPeakMaxTime = g_hConVar_DirectorSustainPeakMaxTime.FloatValue;
	g_fConVar_DirectorRelaxMinInterval = g_hConVar_DirectorRelaxMinInterval.FloatValue;
	g_fConVar_DirectorRelaxMaxInterval = g_hConVar_DirectorRelaxMaxInterval.FloatValue;

	g_iConVar_NumReservedWanderers = g_hConVar_NumReservedWanderers.IntValue;
}
