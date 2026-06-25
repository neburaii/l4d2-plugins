#pragma newdecls required
#pragma semicolon 1

void RegisterGlobalForwards()
{
	for (int i = 0; i < Forward_MAX; i++)
	{
		g_forward[i].handle = InitGlobalForward(i, g_forward[i].name);
		g_forward[i].detours = new ArrayList();
		g_forward[i].msgHooks = new ArrayList();

		if (g_forward[i].handle == null)
			LogError("forward index %i failed to register", i);
		#if DEBUG
			else DebugPrint("forward registered! index: %i | name: %s", i, g_forward[i].name);
		#endif
	}
}

/*************
 * Structs
 ************/

enum struct RegisteredForward
{
	char name[MAX_FWD_LEN];
	GlobalForward handle;

	ArrayList detours;
	ArrayList msgHooks;

	bool linked;
	bool used;

	void SetLinked()
	{
		this.linked = true;

		#if DEBUG
			DebugPrint("  linked to forward: %s", this.name);
		#endif
	}

	void LinkDetour(int index)
	{
		this.detours.Push(index);
		this.SetLinked();
	}

	void LinkMsgHook(int index)
	{
		this.msgHooks.Push(index);
		this.SetLinked();
	}

	void MarkEnabledHooks(bool[] bEnabledDetours, bool[] bEnabledMsgHooks)
	{
		for (int i = 0; i < this.detours.Length; i++)
			bEnabledDetours[this.detours.Get(i)] = true;

		for (int i = 0; i < this.msgHooks.Length; i++)
			bEnabledMsgHooks[this.msgHooks.Get(i)] = true;
	}
}

enum struct RegisteredDetour
{
	DynamicDetour handle;
	DHookCallback callback[Hook_MAX];
	bool enabled;
	bool forced;

	bool Toggle(bool bSet)
	{
		if (this.forced) bSet = true;

		if (bSet == this.enabled) return false;

		for (int mode = 0; mode < Hook_MAX; mode++)
		{
			if (this.callback[mode] == INVALID_FUNCTION) continue;

			if (bSet)
			{
				if (this.handle.Enable(view_as<HookMode>(mode), this.callback[mode]))
					this.enabled = true;
				else
					LogError("failed to enable detour %x %s-hook",
						this.handle, view_as<EHookMode>(mode) == EHook_Pre ? "pre" : "post");
			}
			else
			{
				this.handle.Disable(view_as<HookMode>(mode), this.callback[mode]);
				this.enabled = false;
			}
		}

		return true;
	}
}

enum struct RegisteredMsgHook
{
	UserMsg msg_id;
	bool intercept;
	MsgHook callback_pre;
	MsgPostHook callback_post;

	bool enabled;
	bool forced;

	bool Toggle(bool bSet)
	{
		if (this.forced) bSet = true;
		if (bSet == this.enabled) return false;

		if (bSet) HookUserMessage(this.msg_id, this.callback_pre, this.intercept, this.callback_post);
		else UnhookUserMessage(this.msg_id, this.callback_pre, this.intercept);

		return true;
	}
}

/********************
 * Hook constructors
 ********************/

enum struct DetourPrep
{
	DynamicDetour handle;
	bool failed;

	/**
	 * call either this or FromAddress first.
	 * intitializes DynamicDetour handle through a Functions key in gamedata
	 *
	 * @param sFunction			key name from "Functions" section in gamedata
	 */
	void FromFunction(const char[] sFunction)
	{
		this.failed = false;

		this.handle = DynamicDetour.FromConf(g_hGameData, sFunction);
		if (this.handle == null)
		{
			LogError("failed to create detour from function '%s': gamedata could not be read", sFunction);
			delete this.handle;
			this.failed = true;
			return;
		}

		#if DEBUG
			DebugPrint("[CreateDetour] gamedata function: %s", sFunction);
		#endif
	}

	/**
	 * call either this or FromFunction first.
	 * initializes DynamicDetour handle through an Addresses key in gamedata
	 *
	 * @param sAddress			key name from "Addresses" section in gamedata
	 * @param callConv			calling convention of the function
	 * @param returnType		type of the return value
	 * @param thisType			Type of this pointer or ignore (ignore can be used if not needed)
	 */
	void FromAddress(const char[] sAddress, CallingConvention callConv, ReturnType returnType = ReturnType_Void, ThisPointerType thisType = ThisPointer_Ignore)
	{
		this.failed = false;

		this.handle = new DynamicDetour(LoadAddress(sAddress), callConv, returnType, thisType);
		if (this.handle == null)
		{
			LogError("failed to create detour from address '%s': gamedata could not be read", sAddress);
			delete this.handle;
			this.failed = true;
			return;
		}

		#if DEBUG
			DebugPrint("[CreateDetour] gamedata address: %s", sAddress);
		#endif
	}

	/**
	 * add param for detours created with FromAddress
	 *
	 * @param type				Parameter type
	 */
	void Param(HookParamType type)
	{
		if (this.failed) return;
		this.handle.AddParam(type);
	}

	/**
	 * called last. register into framework for managing enabled status
	 *
	 * @param	callback_pre	callback for the pre-hook
	 * @param	callback_post	callback for the post-hook
	 * @param	fwd				forwards to link this detour to.
	 * @param	bForced			always enable this detour
	 *
	 * @note					if bForced is false, the detour will only be enabled if one of the
	 * 							forwards in the fwd array is used by another plugin
	 * @note					use the forward enum identifiers found in hxlib/forwards.sp, and
	 * 							end the array with the sentinel value -1
	 */
	void Register(DHookCallback callback_pre = INVALID_FUNCTION, DHookCallback callback_post, any[] fwd = {-1}, bool bForced = false)
	{
		if (this.failed) return;

		RegisteredDetour detour;

		detour.handle = this.handle;
		detour.callback[EHook_Pre] = callback_pre;
		detour.callback[EHook_Post] = callback_post;
		detour.forced = bForced;

		int detourIndex = g_hArrayDetours.Length;

		for (int i = 0; i < Forward_MAX; i++)
		{
			if (fwd[i] < 0 || fwd[i] >= Forward_MAX)
				break;

			g_forward[fwd[i]].LinkDetour(detourIndex);
		}

		g_hArrayDetours.PushArray(detour);
	}
}

/**
 * register a UserMsg hook, whose enabled status is managed by the plugin's framework
 *
 * @param sMsg				name of the usermessage to derive a msg_id from
 * @param callback_pre		callback for the pre-hook (required)
 * @param callback_post		callback for the post-hook
 * @param intercept			should the pre-hook intercept?
 * @param fwd				forwards to link this UserMsg hook to
 * @param bForced			should this UserMsg hook be forced enabled always?
 *
 * @note					if bForced is false, the UserMsg hook will only be enabled if one of the
 * 							forwards in the fwd array is used by another plugin
 * @note					use the forward enum identifiers found in hxlib/forwards.sp, and
 * 							end the array with the sentinel value -1
 */
void CreateUserMsgHook(const char[] sMsg, MsgHook callback_pre, MsgPostHook callback_post = INVALID_FUNCTION, bool intercept = false, any[] fwd = {-1}, bool bForced = false)
{
	RegisteredMsgHook msg;

	UserMsg msg_id = GetUserMessageId(sMsg);
	if (msg_id == INVALID_MESSAGE_ID)
	{
		LogError("failed to create usermessage hook for '%s': msg does not exist", sMsg);
		return;
	}

	msg.msg_id = msg_id;
	msg.callback_pre = callback_pre;
	msg.callback_post = callback_post;
	msg.intercept = intercept;
	msg.forced = bForced;

	int msgIndex = g_hArrayMsgHooks.Length;

	#if DEBUG
		DebugPrint("[CreateUserMsgHook] msg: %s | forced: %s", sMsg, bForced ? "true" : "false");
	#endif

	for (int i = 0; i < Forward_MAX; i++)
	{
		if (fwd[i] < 0 || fwd[i] >= Forward_MAX)
			break;

		g_forward[fwd[i]].LinkMsgHook(msgIndex);
	}

	g_hArrayMsgHooks.PushArray(msg);
}

/*************************
 * the important function
 ************************/

void UpdateEnabledHooks()
{
	Handle hPluginIterator;
	Handle hPlugin;
	bool bFound;

	bool[] bEnabledDetours = new bool[g_hArrayDetours.Length];
	bool[] bEnabledMsgHooks = new bool[g_hArrayMsgHooks.Length];

	for (int fwd = 0; fwd < Forward_MAX; fwd++)
	{
		g_forward[fwd].used = false;

		if (g_forward[fwd].linked == false)
			continue;

		bFound = false;
		hPluginIterator = GetPluginIterator();

		while (MorePlugins(hPluginIterator))
		{
			hPlugin = ReadPlugin(hPluginIterator);
			if (hPlugin == g_hThisPlugin) continue;

			if (GetFunctionByName(hPlugin, g_forward[fwd].name) != INVALID_FUNCTION)
			{
				bFound = true;
				break;
			}
		}

		delete hPluginIterator;

		if (bFound)
		{
			#if DEBUG
				DebugPrint("forward found to be in use: %s", g_forward[fwd].name);
				DebugPrint("  marking hooks to be enabled: %i detours",
					g_forward[fwd].detours.Length);
			#endif

			g_forward[fwd].MarkEnabledHooks(bEnabledDetours, bEnabledMsgHooks);
			g_forward[fwd].used = true;
		}
	}

	RegisteredDetour detour;
	for (int i = 0; i < g_hArrayDetours.Length; i++)
	{
		g_hArrayDetours.GetArray(i, detour);
		if (detour.Toggle(bEnabledDetours[i]))
		{
			#if DEBUG
				DebugPrint("[TOGGLE] detour %s (%i, %x%s)",
					detour.enabled ? "on" : "off", i, detour.handle, detour.forced ? ", FORCED" : "");
			#endif

			g_hArrayDetours.SetArray(i, detour);
		}
	}

	RegisteredMsgHook msg;
	for (int i = 0; i < g_hArrayMsgHooks.Length; i++)
	{
		g_hArrayMsgHooks.GetArray(i, msg);
		if (msg.Toggle(bEnabledMsgHooks[i]))
		{
			#if DEBUG
				DebugPrint("[TOGGLE] msgHook %s (%i, %i%s)",
					msg.enabled ? "on" : "off", i, msg.msg_id, msg.forced ? ", FORCED" : "");
			#endif

			g_hArrayMsgHooks.SetArray(i, msg);
		}
	}
}
