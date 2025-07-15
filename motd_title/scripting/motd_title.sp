#pragma newdecls required
#pragma semicolon 1

#define GAMEDATA "motd_title.games"

public Plugin myinfo = 
{
	name = "MOTD Title",
	author = "Neburai",
	description = "Provides ConVar for modifying the \"Message of the day\" title",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/motd_title"
};

#include <dhooks>
#include <neb_stocks>

Handle g_hSDKShowMOTD;
DynamicDetour g_hDetourKeyValueSetString, g_hDetourShowMOTD;
bool g_bIsMOTD;

ConVar g_cMOTDTitle;
char g_sCVMOTDTitle[256];

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_hDetourKeyValueSetString = DynamicDetour.FromConf(hGameData, "HX::KeyValues::SetString");
	if(!g_hDetourKeyValueSetString) SetFailState("could not create HX::KeyValues::SetString detour");
	g_hDetourKeyValueSetString.Enable(Hook_Pre, DTR_KeyValueSetString);

	g_hDetourShowMOTD = DynamicDetour.FromConf(hGameData, "HX::CCSPlayer::ShowMOTD");
	if(!g_hDetourShowMOTD) SetFailState("could not create HX::CCSPlayer::ShowMOTD detour");
	g_hDetourShowMOTD.Enable(Hook_Pre, DTR_ShowMOTD_Pre);
	g_hDetourShowMOTD.Enable(Hook_Post, DTR_ShowMOTD_Post);

	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::ShowMOTD"))
		SetFailState("could not load CCSPlayer::ShowMOTD signature!!");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKShowMOTD = EndPrepSDKCall();
	if(g_hSDKShowMOTD == null)
		SetFailState("could not create CCSPlayer::ShowMOTD SDKCall handle!");

	delete hGameData;

	HookUserMessage(GetUserMessageId("VGUIMenu"), umHook, true);

	// Setup convars
	g_cMOTDTitle = CreateConVar("motd_title", "Message of the day", "title text that displays above motd html", FCVAR_NOTIFY);
	g_cMOTDTitle.AddChangeHook(updateConVar);
	g_cMOTDTitle.GetString(g_sCVMOTDTitle, sizeof(g_sCVMOTDTitle));
}

void updateConVar(ConVar cConvar, const char[] sOldValue, const char[] sNewValue)
{
	g_cMOTDTitle.GetString(g_sCVMOTDTitle, sizeof(g_sCVMOTDTitle));
}

MRESReturn DTR_ShowMOTD_Pre(DHookReturn hReturn, DHookParam hParams)
{
	g_bIsMOTD = true;
	return MRES_Ignored;
}

MRESReturn DTR_ShowMOTD_Post(DHookReturn hReturn, DHookParam hParams)
{
	g_bIsMOTD = false;
	return MRES_Ignored;
}

Action umHook(UserMsg umID, BfRead bfMsg, const int[] iPlayers, int iTotalPlayers, bool bReliable, bool bInit)
{
	static char sMsg[32];

	// we need MOTD to display via CCSPlayer::ShowMOTD so that the KeyValues data containing our title change is passed
	if(!g_bIsMOTD)
	{
		bfMsg.ReadString(sMsg, sizeof(sMsg));
		if(strcmp(sMsg, "info") == 0)
		{			
			if(iTotalPlayers > 0)
			{
				for(int i = 0; i < iTotalPlayers; i++)
				{
					SDKCall(g_hSDKShowMOTD, iPlayers[i]);
				}
			}			
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

MRESReturn DTR_KeyValueSetString(DHookReturn hReturn, DHookParam hParams)
{
	if(g_bIsMOTD)
	{
		static char sKey[8];
		hParams.GetString(1, sKey, sizeof(sKey));
		if(strcmp(sKey, "title") == 0)
		{
			hParams.SetString(2, g_sCVMOTDTitle);
			return MRES_ChangedHandled;
		}
	}

	return MRES_Ignored;
}