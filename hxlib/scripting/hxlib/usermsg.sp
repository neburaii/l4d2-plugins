#pragma newdecls required
#pragma semicolon 1

void InitUserMsgHooks()
{
	CreateUserMsgHook("TextMsg",
		MsgHook_L4D_idle_spectator, _, true,
		{Forward_OnGoAwayFromKeyboard, Forward_OnGoAwayFromKeyboard_Post, -1});
}

/*************
 * CALLBACKS
 ************/

/** manage spam from OnGoAwayFromKeyboard returning Plugin_Handled, as
 * well as making sure the "notify" param from GoAwayFromKeyboard native
 * doesn't interfere */

bool g_bAllowUM_OnGoAwayFromKeyboard;

Action MsgHook_L4D_idle_spectator(UserMsg msg_id, BfRead msg, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
{
	static char sBuffer[32];

	if (g_bAllowUM_OnGoAwayFromKeyboard)
		return Plugin_Continue;

	msg.ReadByte();
	msg.ReadString(sBuffer, sizeof(sBuffer));
	if (strcmp(sBuffer, "#L4D_idle_spectator") != 0)
		return Plugin_Continue;

	return Plugin_Handled;
}
