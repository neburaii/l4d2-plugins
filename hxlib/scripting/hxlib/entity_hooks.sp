#pragma newdecls required
#pragma semicolon 1

void InitEntityHooks()
{
	CreateEntityHook(EntityHook_AcceptInput,
		"HX::AcceptInput", DHook_AcceptInput_Pre, DHook_AcceptInput_Post);

	CreateEntityHook(EntityHook_OnNavAreaChanged,
		"HX::OnNavAreaChanged", _, DHook_OnNavAreaChanged_Post);

	CreateEntityHook(EntityHook_CreateRagdollEntity,
		"HX::CreateRagdollEntity", DHook_CreateRagdollEntity_Pre, DHook_CreateRagdollEntity_Post);

	CreateEntityHook(EntityHook_EventKilled,
		"HX::Event_Killed", DHook_EventKilled_Pre, DHook_EventKilled_Post);

	CreateEntityHook(EntityHook_SetObserverTarget,
		"HX::SetObserverTarget", DHook_SetObserverTarget_Pre, DHook_SetObserverTarget_Post);
}

/************
 * CALLBACKS
 ***********/

/** EntityHook_AcceptInput */
	static bool g_bHandled_AcceptInput;

	MRESReturn DHook_AcceptInput_Pre(int iReceiver, DHookReturn hReturn, DHookParam hParams)
	{
		/** param 2 */
		static char sInput[128];
		hParams.GetString(1, sInput, sizeof(sInput));

		/** param 3 */
		int iActivator = hParams.Get(2);
		if (!iActivator) iActivator = INVALID_ENT_REFERENCE;
		else iActivator = Util_GetEntityFromAddress(view_as<Address>(iActivator));

		/** param 4 */
		int iSource = hParams.Get(3);
		if (!iSource) iSource = INVALID_ENT_REFERENCE;
		else iSource = Util_GetEntityFromAddress(view_as<Address>(iSource));

		/** param 5 */
		Variant variantObject = hParams.Get(4);

		Call_StartForward_EntityHook(iReceiver, EntityHook_AcceptInput, Hook_Pre);
		Call_PushCell(iReceiver);
		Call_PushStringEx(sInput, sizeof(sInput), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(iActivator);
		Call_PushCellRef(iSource);
		Call_PushCell(variantObject);

		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_AcceptInput = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			/** changes to Variant param happen directly to memory */
			hParams.SetString(1, sInput);
			hParams.Set(2, GetEntityAddress(iActivator));
			hParams.Set(3, GetEntityAddress(iSource));
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn DHook_AcceptInput_Post(int iReceiver, DHookReturn hReturn, DHookParam hParams)
	{
		/** param 2 */
		static char sInput[128];
		hParams.GetString(1, sInput, sizeof(sInput));

		/** param 3 */
		int iActivator = hParams.Get(2);
		if (!iActivator) iActivator = INVALID_ENT_REFERENCE;
		else iActivator = Util_GetEntityFromAddress(view_as<Address>(iActivator));

		/** param 4 */
		int iSource = hParams.Get(3);
		if (!iSource) iSource = INVALID_ENT_REFERENCE;
		else iSource = Util_GetEntityFromAddress(view_as<Address>(iSource));

		/** param 5 */
		Variant variantObject = hParams.Get(4);

		Call_StartForward_EntityHook(iReceiver, EntityHook_AcceptInput, Hook_Post);
		Call_PushCell(iReceiver);
		Call_PushString(sInput);
		Call_PushCell(iActivator);
		Call_PushCell(iSource);
		Call_PushCell(variantObject);
		Call_PushCell(g_bHandled_AcceptInput);
		Call_Finish();

		g_bHandled_AcceptInput = false;

		delete variantObject;

		return MRES_Ignored;
	}

/** EntityHook_OnNavAreaChanged */
	MRESReturn DHook_OnNavAreaChanged_Post(int pThis, DHookParam hParams)
	{
		Address newArea = hParams.Get(1);
		Address oldArea = hParams.Get(2);

		Call_StartForward_EntityHook(pThis, EntityHook_OnNavAreaChanged, Hook_Post);
		Call_PushCell(pThis);
		Call_PushCell(newArea);
		Call_PushCell(oldArea);
		Call_Finish();

		return MRES_Ignored;
	}

/** EntityHook_CreateRagdollEntity */
	static bool	g_bHandled_CreateRagdollEntity;

	MRESReturn DHook_CreateRagdollEntity_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		TakeDamageInfo info = hParams.Get(1);
		float vDamageForce[3];
		float vDamagePos[3];
		int iDamageType;

		info.GetDamageForce(vDamageForce);
		info.GetDamagePos(vDamagePos);
		iDamageType = info.damageType;

		Call_StartForward_EntityHook(pThis, EntityHook_CreateRagdollEntity, Hook_Pre);
		Call_PushCell(pThis);
		Call_PushCell(info.attacker);
		Call_PushCell(info.inflictor);
		Call_PushCell(info.damage);
		Call_PushCellRef(iDamageType);
		Call_PushCell(info.weapon);
		Call_PushArray(vDamageForce, sizeof(vDamageForce));
		Call_PushArray(vDamagePos, sizeof(vDamagePos));
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_CreateRagdollEntity = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			info.damageType = iDamageType;
		}

		return MRES_Ignored;
	}

	MRESReturn DHook_CreateRagdollEntity_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		TakeDamageInfo info = hParams.Get(1);
		float vDamageForce[3];
		float vDamagePos[3];
		int iRagdoll = hReturn.Value;

		info.GetDamageForce(vDamageForce);
		info.GetDamagePos(vDamagePos);
		if (iRagdoll != INVALID_ENT_REFERENCE)
			iRagdoll &= 0xFFF;

		Call_StartForward_EntityHook(pThis, EntityHook_CreateRagdollEntity, Hook_Post);
		Call_PushCell(iRagdoll);
		Call_PushCell(pThis);
		Call_PushCell(info.attacker);
		Call_PushCell(info.inflictor);
		Call_PushCell(info.damage);
		Call_PushCell(info.damageType);
		Call_PushCell(info.weapon);
		Call_PushArray(vDamageForce, sizeof(vDamageForce));
		Call_PushArray(vDamagePos, sizeof(vDamagePos));
		Call_PushCell(g_bHandled_CreateRagdollEntity);
		Call_Finish();

		g_bHandled_CreateRagdollEntity = false;
		return MRES_Ignored;
	}

/** EntityHook_EventKilled */
	static bool g_bHandled_EventKilled;

	MRESReturn DHook_EventKilled_Pre(int pThis, DHookParam hParams)
	{
		TakeDamageInfo info = hParams.Get(1);
		float vDamageForce[3];
		float vDamagePos[3];

		int iAttacker = info.attacker;
		int iInflictor = info.inflictor;
		float fDamage = info.damage;
		int iDamageType = info.damageType;
		int iWeapon = info.weapon;
		info.GetDamageForce(vDamageForce);
		info.GetDamagePos(vDamagePos);

		Call_StartForward_EntityHook(pThis, EntityHook_EventKilled, Hook_Pre);
		Call_PushCell(pThis);
		Call_PushCellRef(iAttacker);
		Call_PushCellRef(iInflictor);
		Call_PushCellRef(fDamage);
		Call_PushCellRef(iDamageType);
		Call_PushCellRef(iWeapon);
		Call_PushArrayEx(vDamageForce, sizeof(vDamageForce), SM_PARAM_COPYBACK);
		Call_PushArrayEx(vDamagePos, sizeof(vDamagePos), SM_PARAM_COPYBACK);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_EventKilled = true;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			info.attacker = iAttacker;
			info.inflictor = iInflictor;
			info.damage = fDamage;
			info.damageType = iDamageType;
			info.weapon = iWeapon;
			info.SetDamageForce(vDamageForce);
			info.SetDamagePos(vDamagePos);

			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn DHook_EventKilled_Post(int pThis, DHookParam hParams)
	{
		TakeDamageInfo info = hParams.Get(1);
		float vDamageForce[3];
		float vDamagePos[3];

		info.GetDamageForce(vDamageForce);
		info.GetDamagePos(vDamagePos);

		Call_StartForward_EntityHook(pThis, EntityHook_EventKilled, Hook_Post);
		Call_PushCell(pThis);
		Call_PushCell(info.attacker);
		Call_PushCell(info.inflictor);
		Call_PushCell(info.damage);
		Call_PushCell(info.damageType);
		Call_PushCell(info.weapon);
		Call_PushArray(vDamageForce, sizeof(vDamageForce));
		Call_PushArray(vDamagePos, sizeof(vDamagePos));
		Call_PushCell(g_bHandled_EventKilled);
		Call_Finish();

		g_bHandled_EventKilled = false;
		return MRES_Ignored;
	}

/** EntityHook_SetObserverTarget */
	static bool g_bHandled_SetObserverTarget;

	MRESReturn DHook_SetObserverTarget_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		int iTarget = hParams.Get(1);
		if (!iTarget) iTarget = INVALID_ENT_REFERENCE;
		else iTarget = Util_GetEntityFromAddress(view_as<Address>(iTarget));

		Call_StartForward_EntityHook(pThis, EntityHook_SetObserverTarget, Hook_Pre);
		Call_PushCell(pThis);
		Call_PushCellRef(iTarget);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_SetObserverTarget = true;
			hReturn.Value = 0;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			DebugPrint("setting to %i (%N)", iTarget, iTarget);
			hParams.Set(1, GetEntityAddress(iTarget));
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn DHook_SetObserverTarget_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
	{
		int iTarget = hParams.Get(1);
		if (!iTarget) iTarget = INVALID_ENT_REFERENCE;
		else iTarget = Util_GetEntityFromAddress(view_as<Address>(iTarget));

		Call_StartForward_EntityHook(pThis, EntityHook_SetObserverTarget, Hook_Post);
		Call_PushCell(pThis);
		Call_PushCell(iTarget);
		Call_PushCell(hReturn.Value);
		Call_PushCell(g_bHandled_SetObserverTarget);
		Call_Finish();

		g_bHandled_SetObserverTarget = false;
		return MRES_Ignored;
	}
