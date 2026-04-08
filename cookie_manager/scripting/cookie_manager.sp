#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <multicolors>
#include <hxstocks>
#include <cookie_manager>

public Plugin myinfo =
{
	name = "Cookie Manager",
	author = "Neburai",
	description = "Cookie interface for clients. Cookies can be searched, names/descriptions translated, and accept several types of Panel-driven input",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/cookie_manager"
};

#define MAX_ROW_LENGTH				40
#define MAX_VALUE_LENGTH			255
#define MAX_LANGUAGE_CODE_LENGTH	5

#define INVALID_DIRECTORY			-1

StringMap g_hMap_Cookies;
StringMap g_hMap_CookiesInDirectory;

ArrayList g_hArray_Directories;
ArrayList g_hArray_Cookies;

StringMap g_hMap_InputTypes;
StringMap g_hMap_SpecialTypes;

PanelBrowser g_clientPanel[MAXPLAYERS_L4D2+1];
bool g_bListenForTextInput[MAXPLAYERS_L4D2+1];

CookieChangedForwards g_hMap_Forwards;

/** how should the menu system accept input for setting a cookie's value? */
enum InputType
{
	Input_None = -1,

	Input_Text,				// text, with a default prompt asking for user to type a message
	Input_Text2,			// text, but with a custom prompt asking for user to type a message
	Input_YesNo,			// bool value. true is displayed as "yes", and false as "no"
	Input_OnOff,			// bool value. true is displayed as "on", and false as "off"
	Input_MultipleChoice,	// choose value from selectable options in the panel.
	Input_Slider			// slider to increment/decrement a value within a numeric range
};

enum SpecialType
{
	Special_None			= 0,

	Special_Search			= (1 << 0),
	Special_All				= (1 << 1),
	Special_Categorized		= (1 << 2),
	Special_Uncategorized	= (1 << 3)
};

char g_sSpecialTypePhrase[][] =
{
	"#panel_item_search",
	"#panel_item_all",
	"#panel_item_categorized",
	"#panel_item_uncategorized"
};

#include "cookie_manager/registry.sp"
#include "cookie_manager/menu.sp"
#include "cookie_manager/config.sp"
#include "cookie_manager/special.sp"
#include "cookie_manager/commands.sp"
#include "cookie_manager/api.sp"

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	CreateNative("HookCookieChange", Native_HookCookieChange);
	CreateNative("UnhookCookieChange", Native_UnhookCookieChange);
}

public void OnPluginStart()
{
	LoadTranslations("cookie_manager.phrases");
	LoadTranslations("cookie_manager_directories.phrases");

	RegConsoleCmd("sm_set", Command_Set, "sm_set <cookie name> [value]");
	RegConsoleCmd("sm_cookies", Command_Cookies, "sm_cookies <name> [value]");
	RegConsoleCmd("sm_settings", Command_Settings);

	RegAdminCmd("sm_cookie_manager_reset", Command_ResetRegistries, ADMFLAG_BAN);

	g_hMap_InputTypes = new StringMap();
	g_hMap_InputTypes.SetValue("text", Input_Text);
	g_hMap_InputTypes.SetValue("text2", Input_Text2);
	g_hMap_InputTypes.SetValue("yesno", Input_YesNo);
	g_hMap_InputTypes.SetValue("onoff", Input_OnOff);
	g_hMap_InputTypes.SetValue("multiple_choice", Input_MultipleChoice);
	g_hMap_InputTypes.SetValue("slider", Input_Slider);

	g_hMap_SpecialTypes = new StringMap();
	g_hMap_SpecialTypes.SetValue("search", Special_Search);
	g_hMap_SpecialTypes.SetValue("all", Special_All);
	g_hMap_SpecialTypes.SetValue("all_categorized", Special_Categorized);
	g_hMap_SpecialTypes.SetValue("all_uncategorized", Special_Uncategorized);

	for (int i = 0; i < sizeof(g_clientPanel); i++)
		g_clientPanel[i].Init(i);

	g_hMap_Cookies = new StringMap();
	g_hMap_CookiesInDirectory = new StringMap();
	g_hMap_CachedBottomSize = new StringMap();
	g_hMap_Forwards = new CookieChangedForwards();

	g_hArray_Cookies = new ArrayList(sizeof(RegisteredCookie));
	g_hArray_Directories = new ArrayList(sizeof(RegisteredDirectory));

	RegPluginLibrary(COOKIE_MANAGER_LIBRARY);
}

public void OnAllPluginsLoaded()
{
	ParseConfigs();
	RegisterUndefinedCookies();
}

public void OnMapStart()
{
	ResetRegistries();
}

public void OnClientPutInServer(int iClient)
{
	g_bListenForTextInput[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
	OnCookiePanelClose(iClient);
}

public Action OnClientSayCommand(int iClient, const char[] sCommand, const char[] sArgs)
{
	if (g_bListenForTextInput[iClient]
		&& g_clientPanel[iClient].AcceptMsgInput(sArgs))
		return Plugin_Handled;

	return Plugin_Continue;
}

