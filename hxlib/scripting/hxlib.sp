#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sourcescramble>
#include <hxlib>

#define PLUGIN_NAME	"hxlib"
#define	GAMEDATA	PLUGIN_NAME ... ".games"

#define DEBUG		0

#if DEBUG
	#include <profiler>
	Profiler g_vProf;
#endif

public Plugin myinfo =
{
	name = "hxlib",
	author = "Neburai",
	description = "library providing natives, forwards, and stocks to be used by other plugins",
	version = "1.7",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/hxlib"
};

#define MAX_FWD_LEN	64
#define Hook_MAX 	2

GameData				g_hGameData;

ServerOS				g_OS = OS_Invalid;

Handle					g_hThisPlugin;
bool					g_bLateLoaded;
bool					g_bPluginStarted;

EntityHookInstance 		g_entHook[MAXENTITIES+1][EntityHook_MAX];
EntityHookDHook 		g_entHookDHook[EntityHook_MAX];

RegisteredForward		g_forward[Forward_MAX];
ArrayList				g_hArrayDetours;
ArrayList				g_hArrayMsgHooks;

methodmap Address {}

/** content */
#include "hxlib/memory.sp"				// address and offsets
#include "hxlib/sdkcalls.sp"			// declare and create sdkcalls
#include "hxlib/convars.sp"

#include "hxlib/util/trace_wrapper.sp"
#include "hxlib/util/general.sp"
#include "hxlib/util/nav.sp"
#include "hxlib/util/director.sp"

#include "hxlib/forwards.sp"			// global forwards, EntityHookCB typeset
#include "hxlib/usermsg.sp"				// create UserMessage hooks, MsgHook/MsgPostHook callbacks
#include "hxlib/entity_hooks.sp"		// EntityHook enum
#include "hxlib/detours.sp"				// create detours, detour callbacks
#include "hxlib/natives.sp"				// register natives, native callbacks

/** internal systems abstracting and managing how the content is implemented */
#include "hxlib/framework/f_memory.sp"
#include "hxlib/framework/f_entity_hooks.sp"
#include "hxlib/framework/f_sdkcalls.sp"
#include "hxlib/framework/f_forwards.sp"

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	RegisterGlobalForwards();
	RegisterNatives();

	RegPluginLibrary("hxlib");

	g_hThisPlugin = hMyself;
	g_bLateLoaded = bLate;

	return APLRes_Success;
}

public void OnPluginStart()
{
	/** load gamedata */
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if (FileExists(sPath) == false) SetFailState("\n==========\nMissing required file: \"%s\".==========", sPath);

	g_hGameData = new GameData(GAMEDATA);
	if (g_hGameData == null) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	/** setup */
	g_OS = view_as<ServerOS>(LoadOffset("HX::OS"));
	if (g_OS != OS_Linux && g_OS != OS_Windows)
		SetFailState("%s is only compatible with linux or windows", PLUGIN_NAME);

	g_hArrayDetours = new ArrayList(sizeof(RegisteredDetour));
	g_hArrayMsgHooks = new ArrayList(sizeof(RegisteredMsgHook));

	Util_InitStringMemory();

	InitConVars();
	InitOffsets();
	InitAddresses();
	InitMemoryPatches();
	InitEntityHooks();
	InitSDKCalls();
	InitUserMsgHooks();
	InitDetours();

	/** finish up */
	delete g_hGameData;

	if (g_bLateLoaded) UpdateEnabledHooks();
	g_bPluginStarted = true;
}

public void OnAllPluginsLoaded()
{
	UpdateEnabledHooks();
}

public void OnMapStart()
{
	UpdateEnabledHooks();
}
