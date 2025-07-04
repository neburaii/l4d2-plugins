#pragma newdecls required
#pragma semicolon 1

#include <host_player>
#include <neb_stocks>

public Plugin myinfo =
{
	name = "Vote Blocker",
	author = "Neburai",
	description = "block votes from being started based on who the issuer and target are",
	version = "1.0",
	url = "https://steamcommunity.com/groups/l4d2hardx"
};

char g_sIssues[][] =
{
	"kick",
	"returntolobby",
	"changealltalk",
	"restartgame",
	"changemission",
	"changechapter",
	"changedifficulty"
};

enum IssueType
{
	Issue_Null,
	Issue_Kick = 0,
	Issue_ReturnToLobby,
	Issue_ChangeAllTalk,
	Issue_RestartGame,
	Issue_ChangeMission,
	Issue_ChangeChapter,
	Issue_ChangeDifficulty,
	Issue_MAX
};

#define USER_REGULAR 1 << 0
#define USER_HOST 1 << 1
#define USER_ADMIN 1 << 2

ConVar g_cBlockVote[Issue_MAX], g_cBlockKickTarget, g_cAdminFlag, g_cRespectLevels;
int g_iCVBlockVote[Issue_MAX], g_iCVBlockKickTarget, g_iCVAdminFlag;
bool g_bCVRespectLevels;

public void OnPluginStart()
{
	char sBuffer[64];
	for(IssueType i = Issue_Kick; i < Issue_MAX; i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "vb_block_%s", g_sIssues[i]);
		g_cBlockVote[i] = CreateConVar(sBuffer, "0", "block this vote from being issued by this type of user. bitfield, add numbers together: 1 = regular | 2 = host | 4 = admin", FCVAR_NOTIFY, true, 0.0, true, 7.0);
		g_cBlockVote[i].AddChangeHook(ConVarChanged_update);
	}
	g_cAdminFlag = CreateConVar("vb_admin_flag", "0", "AdminFlag vote_blocker plugin uses to identify admins", FCVAR_NOTIFY, true, 0.0, true, 20.0);
	g_cBlockKickTarget = CreateConVar("vb_block_target_kick", "6", "block kick vote if it's targetting this type of user. bitfield, add numbers together: 1 = regular | 2 = host | 4 = admin", FCVAR_NOTIFY, true, 0.0, true, 7.0);
	g_cRespectLevels = CreateConVar("vb_admin_can_always_target", "1", "0 = no, 1 = yes | admin issuers can override votes blocked by vb_block_target_kick", FCVAR_NOTIFY);
	g_cBlockKickTarget.AddChangeHook(ConVarChanged_update);
	g_cAdminFlag.AddChangeHook(ConVarChanged_update);
	g_cRespectLevels.AddChangeHook(ConVarChanged_update);

	AutoExecConfig(true, "vote_blocker");
	readConVars();

	AddCommandListener(cmdListen_callvote, "callvote");
}

public void OnAllPluginsLoaded()
{
	if(!LibraryExists("host_player")) SetFailState("host_player.smx is not installed");
}

void ConVarChanged_update(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	readConVars();
}

void readConVars()
{
	for(IssueType i = Issue_Kick; i < Issue_MAX; i++)
	{
		g_iCVBlockVote[i] = g_cBlockVote[i].IntValue;
	}
	g_iCVBlockKickTarget = g_cBlockKickTarget.IntValue;
	g_iCVAdminFlag = g_cAdminFlag.IntValue;
	g_bCVRespectLevels = g_cRespectLevels.BoolValue;
}

Action cmdListen_callvote(int iClient, const char[] sCommand, int iArgs)
{
	static char sBuffer[32];
	int iUserType_client, iUserType_target;

	if(iArgs < 1 || !nsIsClientValid(iClient)) return Plugin_Continue;

	// get which issue is being voted
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	IssueType iIssue = getIssueType(sBuffer);
	if(iIssue == Issue_Null) return Plugin_Continue;

	// check if user is allowed to issue this command
	iUserType_client = getUserType(iClient);
	if(g_iCVBlockVote[iIssue] & iUserType_client) return Plugin_Handled;

	// is this a kick vote targetting someone?
	if(iIssue == Issue_Kick && iArgs >= 2)
	{
		int iTarget = GetClientOfUserId(GetCmdArgInt(2));

		if(nsIsClientValid(iClient))
		{
			iUserType_target = getUserType(iTarget);

			// allow admins to override block 
			if(g_bCVRespectLevels && iUserType_client == USER_ADMIN)
			{
				if(	iUserType_target < USER_ADMIN ||
					(iUserType_target == USER_ADMIN && CanUserTarget(iClient, iTarget))) return Plugin_Continue;
			}

			// check if user is allowed to issue a command against this target
			if(g_iCVBlockKickTarget & iUserType_target) return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

IssueType getIssueType(const char[] sIssue)
{
	for(IssueType i = Issue_Kick; i < Issue_MAX; i++) if(strcmp(sIssue, g_sIssues[i], false) == 0) return i;
	return Issue_Null;
}

bool isAdmin(int iClient)
{
	return CheckCommandAccess(iClient, "", 1 << g_iCVAdminFlag, true);
}

int getUserType(int iClient)
{
	if(isAdmin(iClient)) return USER_ADMIN;
	if(IsPlayerHost(iClient)) return USER_HOST;
	return USER_REGULAR;
}