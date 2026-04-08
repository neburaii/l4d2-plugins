#pragma newdecls required
#pragma semicolon 1

/**
 * last minute addition. the design of registered cookies being wiped
 * and re-registered on map loads to account for possible config changes
 * is already set in stone. moving from a single global forward to this
 * private forward system requires a separate string map to manage the
 * forwards.
 *
 * RegisteredCookie struct will cache the private forward handles when
 * its cookie's value is set, but the forward's existence and state is
 * all managed here.
 */

methodmap CookieChangedForwards < StringMap
{
	public CookieChangedForwards()
	{
		return view_as<CookieChangedForwards>(CreateTrie());
	}

	public PrivateForward GetForward(const char[] sCookie)
	{
		PrivateForward hForward;
		if (this.GetValue(sCookie, hForward))
			return hForward;

		hForward = new PrivateForward(ET_Ignore, Param_String, Param_Cell, Param_String, Param_String);
		this.SetValue(sCookie, hForward);

		return hForward;
	}

	public void Hook(const char[] sCookie, Handle hPlugin, Function callback)
	{
		PrivateForward hForward = this.GetForward(sCookie);
		hForward.AddFunction(hPlugin, callback);
	}

	public void Unhook(const char[] sCookie, Handle hPlugin, Function callback)
	{
		PrivateForward hForward = this.GetForward(sCookie);
		hForward.RemoveFunction(hPlugin, callback);

		if (hForward.FunctionCount == 0)
		{
			this.Remove(sCookie);
			delete hForward;
		}
	}
}

public void Native_HookCookieChange(Handle hPlugin, int iNumParams)
{
	char sCookie[COOKIE_MAX_NAME_LENGTH];
	GetNativeString(1, sCookie, sizeof(sCookie));
	Function callback = (GetNativeFunction(2));

	g_hMap_Forwards.Hook(sCookie, hPlugin, callback);
}

public void Native_UnhookCookieChange(Handle hPlugin, int iNumParams)
{
	char sCookie[COOKIE_MAX_NAME_LENGTH];
	GetNativeString(1, sCookie, sizeof(sCookie));
	Function callback = GetNativeFunction(2);

	g_hMap_Forwards.Unhook(sCookie, hPlugin, callback);
}
