ConVar g_cAllowWaitCommand, g_cExcludeAdminFlag;
int g_iCVExcludeAdminFlag;

public Plugin myinfo = 
{
	name = "wait exclude",
	author = "Neburai",
	description = "only players with a certain admin flag are allowed to use wait command",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins"
};

public void OnPluginStart()
{
	g_cAllowWaitCommand = FindConVar("sv_allow_wait_command");
	g_cAllowWaitCommand.Flags &= ~FCVAR_REPLICATED; // ensure that it's only replicated manually from this plugin

	g_cExcludeAdminFlag = CreateConVar("wait_exclude_admin_flag", "16", "admin flag bit a player must have to be allowed to use wait command. Default is ADMFLAG_CUSTOM2 (1 << 16 bit. Refer to admin.inc)", FCVAR_NOTIFY, true, 0.0, true, 20.0);
	g_cExcludeAdminFlag.AddChangeHook(ConVarChanged_update);
	g_iCVExcludeAdminFlag = g_cExcludeAdminFlag.IntValue;
}

void ConVarChanged_update(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_iCVExcludeAdminFlag = g_cExcludeAdminFlag.IntValue;
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsFakeClient(iClient)) return;
	
	if(CheckCommandAccess(iClient, "", 1 << g_iCVExcludeAdminFlag, true)) g_cAllowWaitCommand.ReplicateToClient(iClient, "1");
	else g_cAllowWaitCommand.ReplicateToClient(iClient, "0");	
}