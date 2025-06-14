#pragma newdecls required
#pragma semicolon 1

#include <dhooks>

#define GAMEDATA	"ragdoll_hook.games"

DynamicDetour 	g_hDetourOnRagdollCreated;
GlobalForward	g_hForwardOnRagdollCreated_Pre, g_hForwardOnRagdollCreated_Post;
Handle 			g_hSDKCreateRagdoll;

int				g_iRagdollEntity = -1;
bool			g_bOnRagdollCreatedHandled,
				g_bPluginCreated, g_bGettingRagdollEntity;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	CreateNative("CreateRagdoll", Native_CreateRagdoll);

	return APLRes_Success;
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(!FileExists(sPath)) SetFailState("missing required file: \"%s\"", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) SetFailState("failed to load gamedata: \"%s\"", GAMEDATA);

	g_hDetourOnRagdollCreated = DynamicDetour.FromConf(hGameData, "HX::CCSPlayer::CreateRagdollEntity");
	if(g_hDetourOnRagdollCreated == null) SetFailState("failed to create detour for \"HX::CCSPlayer::CreateRagdollEntity\"");
	g_hDetourOnRagdollCreated.Enable(Hook_Pre, DTR_OnRagdollCreated_Pre);
	g_hDetourOnRagdollCreated.Enable(Hook_Post, DTR_OnRagdollCreated_Post);

	g_hForwardOnRagdollCreated_Pre = CreateGlobalForward("OnRagdollCreated", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardOnRagdollCreated_Post = CreateGlobalForward("OnRagdollCreated_Post", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::CreateRagdollEntity"))
		SetFailState("could not load CCSPlayer::CreateRagdollEntity signature!!");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKCreateRagdoll = EndPrepSDKCall();
	if(g_hSDKCreateRagdoll == null)
		SetFailState("could not create CCSPlayer::CreateRagdollEntity SDKCall handle!");
}

/***********************
 * CREATE PLAYER RAGDOLL
 **********************/

MRESReturn DTR_OnRagdollCreated_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	Call_StartForward(g_hForwardOnRagdollCreated_Pre);
	Call_PushCell(pThis);
	Call_PushCell(view_as<Address>(hParams.Get(1)));
	Call_PushCell(g_bPluginCreated);
	Action aResult = Plugin_Continue;
	Call_Finish(aResult);

	g_iRagdollEntity = -1;

	if(aResult == Plugin_Handled)
	{
		g_bPluginCreated = false;
		g_bOnRagdollCreatedHandled = true;
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bGettingRagdollEntity = true;

	return MRES_Ignored;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(!g_bGettingRagdollEntity) return;
	if(strcmp(sClassname, "cs_ragdoll") != 0) return;

	g_iRagdollEntity = iEntity;
}

MRESReturn DTR_OnRagdollCreated_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{	
	if(g_bOnRagdollCreatedHandled)
	{
		g_bOnRagdollCreatedHandled = false;
		return MRES_Ignored;
	}
	
	Call_StartForward(g_hForwardOnRagdollCreated_Post);
	Call_PushCell(pThis);
	Call_PushCell(g_iRagdollEntity);
	Call_PushCell(view_as<Address>(hParams.Get(1)));
	Call_PushCell(g_bPluginCreated);
	Call_Finish();

	g_bGettingRagdollEntity = false;

	return MRES_Ignored;
}

public any Native_CreateRagdoll(Handle hPlugin, int iNumParams)
{
	g_bPluginCreated = true;
	SDKCall(g_hSDKCreateRagdoll, GetNativeCell(1), GetNativeCell(2));
	g_bPluginCreated = false;
	return g_iRagdollEntity;
}