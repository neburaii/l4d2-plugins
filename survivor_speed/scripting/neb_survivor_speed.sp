#include <sourcemod>
#include <left4dhooks>
#include <sdkhooks>
#include <neb_stocks>

ConVar g_cSpeedHPVeryLow, g_cSpeedHPLow, g_cSpeedAdren, g_cSpeedRunning, g_cSpeedCrouching, g_cSpeedWalking, g_cHPThresholdLow, g_cHPThresholdVeryLow, g_cSpeedWater;
float g_fSpeedHPVeryLow, g_fSpeedHPLow, g_fSpeedAdren, g_fSpeedRunning, g_fSpeedCrouching, g_fSpeedWalking, g_fHPThresholdLow, g_fHPThresholdVeryLow, g_fSpeedWater;

public Plugin myinfo = 
{
	name = "survivor speed control",
	author = "Neburai",
	description = "convars to overwrite survivor speeds when low health, in water, etc",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins"
};

public void OnPluginStart()
{
	g_cSpeedRunning =		CreateConVar("sspeed_run",						"220.0",	"survivor max (normal) running speed", FCVAR_NOTIFY);
	g_cSpeedWalking =		CreateConVar("sspeed_walk",						"85.0",		"survivor max walking speed", FCVAR_NOTIFY);
	g_cSpeedCrouching =		CreateConVar("sspeed_crouch",					"75.0",		"survivor max crouch walk speed", FCVAR_NOTIFY);
	g_cSpeedAdren =			CreateConVar("sspeed_adren",					"260.0",	"survivor max adren running speed", FCVAR_NOTIFY);
	g_cSpeedHPLow =			CreateConVar("sspeed_hp_low",					"150.0",	"survivor max (<=40hp) low hp speed", FCVAR_NOTIFY);
	g_cSpeedHPVeryLow =		CreateConVar("sspeed_hp_very_low",				"85.0",		"survivor max very (<= 1hp) low hp speed", FCVAR_NOTIFY);
	g_cHPThresholdLow =		CreateConVar("sspeed_hp_threshold_low",			"40.0",		"survivor will have low hp speed when their hp is < this", FCVAR_NOTIFY);
	g_cHPThresholdVeryLow =	CreateConVar("sspeed_hp_threshold_very_low",	"1.0",		"survivor will have very low hp speed when their hp is <= this", FCVAR_NOTIFY);
	g_cSpeedWater =			CreateConVar("sspeed_water",					"115.0",	"survivor max speed from water slowdown", FCVAR_NOTIFY);
	convarSet();
	
	g_cSpeedRunning.AddChangeHook(convarHook);
	g_cSpeedWalking.AddChangeHook(convarHook);
	g_cSpeedCrouching.AddChangeHook(convarHook);
	g_cSpeedAdren.AddChangeHook(convarHook);
	g_cSpeedHPLow.AddChangeHook(convarHook);
	g_cSpeedHPVeryLow.AddChangeHook(convarHook);
	g_cHPThresholdLow.AddChangeHook(convarHook);
	g_cHPThresholdVeryLow.AddChangeHook(convarHook);
	g_cSpeedWater.AddChangeHook(convarHook);

	AutoExecConfig(true, "neb_survivor_speed");
}

void convarHook(Handle hConvar, const char[] sOldValue, const char[] sNewValue)
{
	convarSet();
}

void convarSet()
{
	g_fSpeedRunning = g_cSpeedRunning.FloatValue;
	g_fSpeedWalking = g_cSpeedWalking.FloatValue;
	g_fSpeedCrouching = g_cSpeedCrouching.FloatValue;
	g_fSpeedAdren = g_cSpeedAdren.FloatValue;
	g_fSpeedHPLow = g_cSpeedHPLow.FloatValue;
	g_fSpeedHPVeryLow = g_cSpeedHPVeryLow.FloatValue;
	g_fHPThresholdLow = g_cHPThresholdLow.FloatValue;
	g_fHPThresholdVeryLow = g_cHPThresholdVeryLow.FloatValue;
	g_fSpeedWater = g_cSpeedWater.FloatValue;
}

public Action L4D_OnGetCrouchTopSpeed(int iTarget, float &fRetVal)
{
	if(!nsIsSurvivor(iTarget)) return Plugin_Continue;
	
	// adren
	if(g_fSpeedAdren < g_fSpeedCrouching)
	{
		if(GetEntProp(iTarget, Prop_Send, "m_bAdrenalineActive"))
		{
			fRetVal = g_fSpeedAdren;
			return Plugin_Handled;
		}
	}

	fRetVal = getFinalSpeed(g_fSpeedCrouching, iTarget);

	return Plugin_Handled;
}

public Action L4D_OnGetWalkTopSpeed(int iTarget, float &fRetVal) 
{
	if(!nsIsSurvivor(iTarget)) return Plugin_Continue;

	// adren
	if(g_fSpeedAdren < g_fSpeedWalking)
	{
		if(GetEntProp(iTarget, Prop_Send, "m_bAdrenalineActive"))
		{
			fRetVal = g_fSpeedAdren;
			return Plugin_Handled;
		}
	}

	fRetVal = getFinalSpeed(g_fSpeedWalking, iTarget);

	return Plugin_Handled;
}

public Action L4D_OnGetRunTopSpeed(int iTarget, float &fRetVal)
{
	if(!nsIsSurvivor(iTarget)) return Plugin_Continue;

	// adren
	if(GetEntProp(iTarget, Prop_Send, "m_bAdrenalineActive"))
	{
		fRetVal = g_fSpeedAdren;
		return Plugin_Handled;
	}
	
	fRetVal = getFinalSpeed(g_fSpeedRunning, iTarget);

	return Plugin_Handled;
}

float getFinalSpeed(float fRetVal, int iTarget)
{
	// water
	if(GetEntityFlags(iTarget) & FL_INWATER)
	{
		if(g_fSpeedWater < fRetVal) fRetVal = g_fSpeedWater;
	}

	// health
	float fHealth = float(GetClientHealth(iTarget)) + L4D_GetTempHealth(iTarget);
	if(fHealth <= g_fHPThresholdVeryLow)
	{
		if(g_fSpeedHPVeryLow < fRetVal) fRetVal = g_fSpeedHPVeryLow;
	}
	else if(fHealth < g_fHPThresholdLow)
	{
		if(g_fSpeedHPLow < fRetVal) fRetVal = g_fSpeedHPLow;
	}

	return fRetVal;
}