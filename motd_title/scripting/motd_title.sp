#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <hxstocks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MAX_MOTD_TITLE_LEN	192

public Plugin myinfo =
{
	name = "MOTD Title",
	author = "Neburai",
	description = "Provides ConVar for modifying the \"Message of the day\" title",
	version = "2.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/motd_title"
};

enum MOTDTitle
{
	MOTDTitle_Vanilla = 0,
	MOTDTitle_ConVar,
	MOTDTitle_Translation
};

/** convars */
ConVar		g_hConVarMOTDTitleType;
ConVar		g_hConVarMOTDTitle;

MOTDTitle	g_MOTDTitleType;
char 		g_sMOTDTitle[MAX_MOTD_TITLE_LEN];

bool		g_bSendNewMsg;

public void OnPluginStart()
{
	g_hConVarMOTDTitleType = CreateConVar(
		"motd_title_type", "1",
		"source of the title string. 0 = vanilla | 1 = convar | 2 = SM translation (sourcemod/translations/motd_title.phrases.txt)",
		CVAR_FLAGS);

	g_hConVarMOTDTitle = CreateConVar(
		"motd_title", "non-translated title",
	 	"title text that displays above motd html. only used if motd_title_type is set to 1",
		CVAR_FLAGS);

	g_hConVarMOTDTitleType.AddChangeHook(ConVarChanged_Read);
	g_hConVarMOTDTitle.AddChangeHook(ConVarChanged_Read);
	ReadConVars();

	LoadTranslations("motd_title.phrases");

	HookUserMessage(GetUserMessageId("VGUIMenu"), MsgHook_VGUIMenu, true, MsgPostHook_VGUIMenu);
}

/**********
 * ConVars
 *********/

void ConVarChanged_Read(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_MOTDTitleType = view_as<MOTDTitle>(g_hConVarMOTDTitleType.IntValue);
	g_hConVarMOTDTitle.GetString(g_sMOTDTitle, sizeof(g_sMOTDTitle));
}

/*************************
 * record/send motd buffer
 ************************/

MOTDBuffer g_motd;
enum struct MOTDBuffer
{
	int flags;
	int players[MAXPLAYERS_L4D2];
	int playersNum;

	char buffer[256];
	int bufferLen;

	void Record(BfRead hBuffer, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit, char sLine[MAX_MOTD_TITLE_LEN])
	{
		this.bufferLen = 0;

		bool bTitleFound;
		int iTotalKVIndex;

		this.AppendString("info");
		this.AppendByte(hBuffer.ReadByte()); 					// for formatting
		iTotalKVIndex = this.AppendByte(hBuffer.ReadByte());	// total kayvalue pairs

		/** the remainder of the buffer are keyvalue pairs. it alternates, starting with a key, then a value */
		bool bSkipKV;
		for (bool bKey = true; hBuffer.BytesLeft; bKey = !bKey)
		{
			hBuffer.ReadString(sLine, sizeof(sLine), true);

			if (bSkipKV)
			{
				/** bKey being true here means we're at the key of the pair after the key that set bSkipKV to true */
				if (bKey) bSkipKV = false;
				else continue;
			}

			if (bKey && strcmp(sLine, "title") == 0)
			{
				bSkipKV = true;
				bTitleFound = true;
				continue;
			}

			this.AppendString(sLine);
		}

		/** title key without value. value gets appended in post hook */
		this.AppendString("title");

		if (!bTitleFound)
			this.buffer[iTotalKVIndex] = view_as<int>(this.buffer[iTotalKVIndex]) + 1;

		this.flags = USERMSG_BLOCKHOOKS;
		if (bReliable) this.flags |= USERMSG_RELIABLE;
		if (bInit) this.flags |= USERMSG_INITMSG;

		this.playersNum = iPlayersNum;

		for (int i = 0; i < iPlayersNum; i++)
		{
			this.players[i] = iPlayers[i];
		}
	}

	void Send()
	{
		switch (g_MOTDTitleType)
		{
			case MOTDTitle_ConVar:
				this.SendUserMessage(this.players, this.playersNum, g_sMOTDTitle);

			case MOTDTitle_Translation:
			{
				static char sTranslatedTitle[MAX_MOTD_TITLE_LEN];
				int iSinglePlayer[1];

				for (int p = 0; p < this.playersNum; p++)
				{
					iSinglePlayer[0] = this.players[p];
					FormatEx(sTranslatedTitle, sizeof(sTranslatedTitle), "%t", "#MOTD_Title", p);
					this.SendUserMessage(iSinglePlayer, 1, sTranslatedTitle);
				}
			}
		}
	}

	/**********
	 * helpers
	 **********/

	void AppendString(const char[] sString)
	{
		for (int i = 0;; i++)
		{
			this.buffer[this.bufferLen++] = sString[i];
			if (sString[i] == '\0') break;
		}
	}

	int AppendByte(int iByte)
	{
		this.buffer[this.bufferLen++] = iByte;
		return this.bufferLen - 1;
	}

	void SendUserMessage(const int[] iPlayers, int iPlayersNum, const char[] sTitle)
	{
		BfWrite hBuffer = view_as<BfWrite>(StartMessage("VGUIMenu", iPlayers, iPlayersNum, this.flags));

		for (int i = 0; i < this.bufferLen; i++)
			hBuffer.WriteByte(this.buffer[i]);

		hBuffer.WriteString(sTitle);

		EndMessage();
	}
}

/**************
 * UserMessage
 *************/

Action MsgHook_VGUIMenu(UserMsg msg_id, BfRead hBuffer, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
{
	static char sLine[MAX_MOTD_TITLE_LEN];

	if (g_MOTDTitleType == MOTDTitle_Vanilla)
		return Plugin_Continue;

	hBuffer.ReadString(sLine, sizeof(sLine), true);
	if (strcmp(sLine, "info") != 0)
		return Plugin_Continue;

	g_motd.Record(hBuffer, iPlayers, iPlayersNum, bReliable, bInit, sLine);
	g_bSendNewMsg = true;

	return Plugin_Handled;
}

void MsgPostHook_VGUIMenu(UserMsg msg_id, bool bSent)
{
	if (!g_bSendNewMsg) return;
	g_bSendNewMsg = false;

	g_motd.Send();
}
