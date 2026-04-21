#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo =
{
	name = "wait exclude",
	author = "Neburai",
	description = "only players with a certain admin flag are allowed to use wait command",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/admin_only_wait"
};

ConVar	g_hConVar_AllowWaitCommand;

ConVar	g_hConVar_AdminFlags;
int		g_iAdminFlags;

public void OnPluginStart()
{
	g_hConVar_AllowWaitCommand = FindConVar("sv_allow_wait_command");
	g_hConVar_AllowWaitCommand.Flags &= ~FCVAR_REPLICATED;

	g_hConVar_AdminFlags = CreateConVar(
		"sv_allow_wait_command_admin", "p",
		"string of admin flags a client must have to be allowed to use wait command",
		FCVAR_NOTIFY);
	g_hConVar_AdminFlags.AddChangeHook(ConVarChanged_Update);
	ReadConVar();
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVar();
}

void ReadConVar()
{
	char sFlags[AdminFlags_TOTAL + 1];
	g_hConVar_AdminFlags.GetString(sFlags, sizeof(sFlags));
	g_iAdminFlags = ReadFlagString(sFlags);
}

public void OnClientPostAdminCheck(int iClient)
{
	if (IsFakeClient(iClient))
		return;

	if (CheckCommandAccess(iClient, "", g_iAdminFlags, true))
		g_hConVar_AllowWaitCommand.ReplicateToClient(iClient, "1");
	else g_hConVar_AllowWaitCommand.ReplicateToClient(iClient, "0");
}
