#pragma newdecls required
#pragma semicolon 1

void InitEntityHooks()
{
	CreateEntityHook(EntityHook_OnNavAreaChanged,
		"HX::OnNavAreaChanged", _, DHook_OnNavAreaChanged_Post);

	CreateEntityHook(EntityHook_CreateRagdollEntity,
		"HX::CreateRagdollEntity", DHook_CreateRagdollEntity_Pre, DHook_CreateRagdollEntity_Post);

	CreateEntityHook(EntityHook_EventKilled,
		"HX::Event_Killed", DHook_EventKilled_Pre, DHook_EventKilled_Post);

	CreateEntityHook(EntityHook_SetObserverTarget,
		"HX::SetObserverTarget", DHook_SetObserverTarget_Pre, DHook_SetObserverTarget_Post);

	CreateEntityHook(EntityHook_FinishReload,
		"HX::FinishReload", DHook_FinishReload_Pre, DHook_FinishReload_Post);

	CreateEntityHook(EntityHook_RemoveAmmo,
		"HX::RemoveAmmo", DHook_RemoveAmmo_Pre, DHook_RemoveAmmo_Post);

	if (g_OS == OS_Windows) {
		CreateEntityHook(EntityHook_AcceptInput,
			"HX::AcceptInput_win", DHook_AcceptInput_Pre, DHook_AcceptInput_Post);
	}
	else {
		CreateEntityHook(EntityHook_AcceptInput,
			"HX::AcceptInput", DHook_AcceptInput_Pre, DHook_AcceptInput_Post);
	}
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
		Variant params;
		Util_ReadVariant(hParams, 4, params);

		Call_StartForward_EntityHook(iReceiver, EntityHook_AcceptInput, Hook_Pre);
		Call_PushCell(iReceiver);
		Call_PushStringEx(sInput, sizeof(sInput), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(iActivator);
		Call_PushCellRef(iSource);
		Call_PushArrayEx(params, sizeof(params), SM_PARAM_COPYBACK);

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
			Util_WriteVariant(hParams, 4, params);

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
		Variant params;
		Util_ReadVariant(hParams, 4, params);

		Call_StartForward_EntityHook(iReceiver, EntityHook_AcceptInput, Hook_Post);
		Call_PushCell(iReceiver);
		Call_PushString(sInput);
		Call_PushCell(iActivator);
		Call_PushCell(iSource);
		Call_PushArray(params, sizeof(params));
		Call_PushCell(g_bHandled_AcceptInput);
		Call_Finish();

		g_bHandled_AcceptInput = false;

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

	MRESReturn DHook_CreateRagdollEntity_Pre(int pThis, DHookParam hParams)
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
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			info.damageType = iDamageType;
		}

		return MRES_Ignored;
	}

	MRESReturn DHook_CreateRagdollEntity_Post(int pThis, DHookParam hParams)
	{
		TakeDamageInfo info = hParams.Get(1);
		float vDamageForce[3];
		float vDamagePos[3];

		info.GetDamageForce(vDamageForce);
		info.GetDamagePos(vDamagePos);

		Call_StartForward_EntityHook(pThis, EntityHook_CreateRagdollEntity, Hook_Post);
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

/** EntityHook_FinishReload */
	static bool g_bHandled_FinishReload;

	MRESReturn DHook_FinishReload_Pre(int pThis, DHookParam hParams)
	{
		Call_StartForward_EntityHook(pThis, EntityHook_FinishReload, Hook_Pre);
		Call_PushCell(pThis);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_FinishReload = true;
			return MRES_Supercede;
		}

		return MRES_Ignored;
	}

	MRESReturn DHook_FinishReload_Post(int pThis, DHookParam hParams)
	{
		Call_StartForward_EntityHook(pThis, EntityHook_FinishReload, Hook_Post);
		Call_PushCell(pThis);
		Call_PushCell(g_bHandled_FinishReload);
		Call_Finish();

		g_bHandled_FinishReload = false;
		return MRES_Ignored;
	}

/** EntityHook_RemoveAmmo */
	static bool g_bHandled_RemoveAmmo;

	MRESReturn DHook_RemoveAmmo_Pre(int pThis, DHookParam hParams)
	{
		int iAmount = hParams.Get(1);
		AmmoType ammoType = hParams.Get(2);

		Call_StartForward_EntityHook(pThis, EntityHook_RemoveAmmo, Hook_Pre);
		Call_PushCell(pThis);
		Call_PushCellRef(iAmount);
		Call_PushCellRef(ammoType);
		Action result = Plugin_Continue;
		Call_Finish(result);

		if (result == Plugin_Handled)
		{
			g_bHandled_RemoveAmmo = true;
			return MRES_Supercede;
		}

		if (result == Plugin_Changed)
		{
			hParams.Set(1, iAmount);
			hParams.Set(2, ammoType);
			return MRES_ChangedHandled;
		}

		return MRES_Ignored;
	}

	MRESReturn DHook_RemoveAmmo_Post(int pThis, DHookParam hParams)
	{
		int iAmount = hParams.Get(1);
		AmmoType ammoType = hParams.Get(2);

		Call_StartForward_EntityHook(pThis, EntityHook_RemoveAmmo, Hook_Post);
		Call_PushCell(pThis);
		Call_PushCell(iAmount);
		Call_PushCell(ammoType);
		Call_PushCell(g_bHandled_RemoveAmmo);
		Call_Finish();

		g_bHandled_RemoveAmmo = false;
		return MRES_Ignored;
	}
