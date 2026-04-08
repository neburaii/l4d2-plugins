#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <multicolors>

enum IssueType
{
	Issue_None = -1,

	Issue_Kick,
	Issue_ReturnToLobby,
	Issue_ChangeAllTalk,
	Issue_RestartGame,
	Issue_ChangeMission,
	Issue_ChangeChapter,
	Issue_ChangeDifficulty,

	Issue_MAX
};

StringMap	g_hIssues;

ConVar		g_hConVar_RequiredAdminFlags[Issue_MAX];
int			g_iRequiredAdminFlags[Issue_MAX];

ConVar		g_hConVar_KickImmunity;
bool		g_bKickImmunity;

public Plugin myinfo =
{
	name = "Vote Blocker",
	author = "Neburai",
	description = "block votes from being started based on who the issuer and target are",
	version = "1.1",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/vote_blocker"
};

public void OnPluginStart()
{
	LoadTranslations("vote_blocker.phrases");

	char sIssues[Issue_MAX][] =
	{
		"kick",
		"returntolobby",
		"changealltalk",
		"restartgame",
		"changemission",
		"changechapter",
		"changedifficulty"
	};

	g_hIssues = new StringMap();
	char sBuffer[64];

	for (any i = 0; i < Issue_MAX; i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "vote_require_admin_%s", sIssues[i]);
		g_hConVar_RequiredAdminFlags[i] = CreateConVar(
			sBuffer, "", "a string of admin flags a user must have to call a vote of this type. \
			empty string means anyone can call the vote",
			FCVAR_NOTIFY);
		g_hConVar_RequiredAdminFlags[i].AddChangeHook(ConVarChanged_Update);

		g_hIssues.SetValue(sIssues[i], i);
	}

	g_hConVar_KickImmunity = CreateConVar(
		"vote_kick_immunity", "1",
		"should admin immunity level be used to block vote-kicks targetting admins of higher immunity? 1 = yes; 2 = no",
		FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hConVar_KickImmunity.AddChangeHook(ConVarChanged_Update);

	ReadConVars();
	AutoExecConfig(_, "vote_blocker");

	AddCommandListener(Listener_Callvote, "callvote");
}

void ConVarChanged_Update(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	char sFlags[AdminFlags_TOTAL + 1];

	for (any i = 0; i < Issue_MAX; i++)
	{
		g_hConVar_RequiredAdminFlags[i].GetString(sFlags, sizeof(sFlags));
		g_iRequiredAdminFlags[i] = ReadFlagString(sFlags);
	}

	g_bKickImmunity = g_hConVar_KickImmunity.BoolValue;
}

Action Listener_Callvote(int iClient, const char[] sCommand, int iArgs)
{
	if (!iClient || !iArgs)
		return Plugin_Continue;

	static char sIssueName[17];
	IssueType issue;

	GetCmdArg(1, sIssueName, sizeof(sIssueName));
	if (!g_hIssues.GetValue(sIssueName, issue))
		return Plugin_Continue;

	if (g_iRequiredAdminFlags[issue]
		&& !CheckCommandAccess(iClient, "callvote", g_iRequiredAdminFlags[issue]))
	{
		CPrintToChat(iClient, "%t %t", "#tag_callvote", "#reply_no_permission", sIssueName);
		return Plugin_Handled;
	}

	if (g_bKickImmunity && issue == Issue_Kick && iArgs >= 2)
	{
		int iTarget = GetClientOfUserId(GetCmdArgInt(2));
		if (iTarget && !CanUserTarget(iClient, iTarget))
		{
			CPrintToChatEx(iClient, iTarget, "%t %t", "#tag_callvote", "#reply_target_is_immune", iTarget);
			CPrintToChatEx(iTarget, iClient, "%t %t", "#tag_callvote", "#you_were_target_of_failed_kick", iClient);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
