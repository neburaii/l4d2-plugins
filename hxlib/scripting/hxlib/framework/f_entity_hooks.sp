#pragma newdecls required
#pragma semicolon 1

static int g_iTotalHooksGlobal;
static int g_iTotalHooksEntity[MAXENTITIES+1];

enum struct EntityHookInstance
{
	int id[2];
	PrivateForward fwd[2];
	bool active;

	bool Add(EntityHook type, int iEntity, HookMode mode, Handle hPlugin, Function func)
	{
		if (!this.active) this.Create(type, iEntity);
		if (this.active) return this.fwd[mode].AddFunction(hPlugin, func);

		return false;
	}

	void Remove(int iEntity, HookMode mode, Handle hPlugin, Function func)
	{
		if (!this.active) return;

		this.fwd[mode].RemoveFunction(hPlugin, func);
		if (this.GetFunctionCount() < 1) this.Destroy(iEntity);
	}

	void Create(EntityHook type, int iEntity)
	{
		bool bCreated = false;

		for (any m = 0; m < 2; m++)
		{
			if (g_entHookDHook[type].Exists(m) == false) continue;
			if (this.Exists(m) == true) continue;

			this.id[m] = g_entHookDHook[type].Hook(m, iEntity);
			if (this.id[m] == INVALID_HOOK_ID) continue;

			this.fwd[m] = InitPrivateForward(type, m);

			#if DEBUG
				DebugPrint("  created %s-hook", m == Hook_Pre ? "pre" : "post");
			#endif

			bCreated = true;
		}

		if (bCreated) IncrementTotalEntityHooks(iEntity);
		this.active = bCreated;
	}

	void Destroy(int iEntity)
	{
		bool bDestroyed = false;

		for (any m = 0; m < 2; m++)
		{
			if (this.Exists(m) == false) continue;

			delete this.fwd[m];

			DynamicHook.RemoveHook(this.id[m]);
			this.id[m] = INVALID_HOOK_ID;

			bDestroyed = true;

			#if DEBUG
				DebugPrint("  destroyed %s-hook", m == Hook_Pre ? "pre" : "post");
			#endif
		}

		if (bDestroyed) DecrementTotalEntityHooks(iEntity);
		this.active = false;
	}

	int GetFunctionCount()
	{
		int iTotal;

		for (any m = 0; m < 2; m++)
		{
			if (this.Exists(m) == false) continue;
			iTotal += this.fwd[m].FunctionCount;
		}

		return iTotal;
	}

	bool Exists(HookMode mode)
	{
		return this.id[mode] != INVALID_HOOK_ID;
	}
}

enum struct EntityHookDHook
{
	DynamicHook handle;
	DHookCallback callback[2];

	int Hook(HookMode mode, int iEntity)
	{
		int id = this.handle.HookEntity(mode, iEntity, this.callback[mode]);

		if (id == INVALID_HOOK_ID)
		{
			LogError("failed to %s-hook entity %i",
				mode == Hook_Pre ? "pre" : "post", iEntity);
		}

		return id;
	}

	bool Exists(HookMode mode)
	{
		return this.callback[mode] != INVALID_FUNCTION;
	}
}

/**
 * initialize this entity hook
 *
 * @param type				EntityHook enum of the type to initialize
 * @param sFunction 		name of the function in the game data file (Games/left4dead2/Functions/)
 * @param callback_pre 		pre-hook callback for the DynamicHook
 * @param callback_post 	post-hook callback for the DynamicHook
 */
void CreateEntityHook(EntityHook type, const char[] sFunction, DHookCallback callback_pre = INVALID_FUNCTION, DHookCallback callback_post = INVALID_FUNCTION)
{
	g_entHookDHook[type].handle = DynamicHook.FromConf(g_hGameData, sFunction);
	if (g_entHookDHook[type].handle == null)
	{
		LogError("failed to create dhook for '%s': gamedata could not be read", sFunction);
		delete g_entHookDHook[type].handle;
		return;
	}

	g_entHookDHook[type].callback[EHook_Pre] = callback_pre;
	g_entHookDHook[type].callback[EHook_Post] = callback_post;

	#if DEBUG
		DebugPrint("[CreateEntityHook] gamedata function: %s", sFunction);
	#endif
}

/**
 * wrapper function of Call_StartForward, to ensure the entity hook's
 * forward handle is being accessed with a safe entity index
 */
void Call_StartForward_EntityHook(int iEntity, EntityHook type, HookMode mode)
{
	int iSafeIndex = GetSafeEntityIndex(iEntity);
	Call_StartForward(g_entHook[iSafeIndex][type].fwd[mode]);
}

/*****************
 * Hook removal
 *****************/

void IncrementTotalEntityHooks(int iEntity)
{
	int iSafeIndex = GetSafeEntityIndex(iEntity);

	if (!g_iTotalHooksGlobal)
		DHookAddEntityListener(ListenType_Deleted, ListenCB_OnEntityDestroyed);

	g_iTotalHooksEntity[iSafeIndex]++;
	g_iTotalHooksGlobal++;

	#if DEBUG
		DebugPrint("++incrementing entity hook instance amount for index %i (ent %i | global %i)",
			iSafeIndex, g_iTotalHooksEntity[iSafeIndex], g_iTotalHooksGlobal);
	#endif
}

void DecrementTotalEntityHooks(int iEntity)
{
	int iSafeIndex = GetSafeEntityIndex(iEntity);

	g_iTotalHooksEntity[iSafeIndex]--;
	g_iTotalHooksGlobal--;

	if (!g_iTotalHooksGlobal)
		DHookRemoveEntityListener(ListenType_Deleted, ListenCB_OnEntityDestroyed);

	#if DEBUG
		DebugPrint("--decrementing entity hook instance amount for index %i (ent %i | global %i)",
			iSafeIndex, g_iTotalHooksEntity[iSafeIndex], g_iTotalHooksGlobal);
	#endif
}

void ListenCB_OnEntityDestroyed(int iEntity)
{
	int iSafeIndex = GetSafeEntityIndex(iEntity);

	if (!g_iTotalHooksEntity[iSafeIndex]) return;

	#if DEBUG
		DebugPrint("OnEntityDestroyed removing entity hooks for %i (has %i hooks)",
			iSafeIndex, g_iTotalHooksEntity[iSafeIndex]);
	#endif

	for (any i = 0; i < EntityHook_MAX; i++)
	{
		g_entHook[iSafeIndex][i].Destroy(iEntity);
	}
}
