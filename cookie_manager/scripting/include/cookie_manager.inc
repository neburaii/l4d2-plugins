#if defined _cookie_manager_included_
	#endinput
#endif
#define _cookie_manager_included_

#pragma newdecls required
#pragma semicolon 1

#define COOKIE_MANAGER_LIBRARY	"cookie_manager"

/**
 * similar to ConVarChanged hooks. Cookie handles aren't global. so the identifier
 * is its name rather than the handle.
 */

/**
 * a function called when a cookie's value changes
 *
 * @param cookie	name the cookie was registered with
 * @param client	client index of the player the cookie change is for
 * @param oldValue	value before the change
 * @param newValue	new current value of the cookie for this client
 */
typedef CookieChanged = function void (const char[] cookie, int client, const char[] oldValue, const char[] newValue);

/**
 * register a callback from your plugin to be called when a cookie's value
 * is changed.
 *
 * @param cookie	name the cookie was registered with
 * @param callback	CookieChanged callback from your plugin
 */
native void HookCookieChange(const char[] cookie, CookieChanged callback);

/**
 * unregister a callback from your plugin to be called when a cookie's value
 * is changed.
 *
 * @param cookie	name the cookie was registered with
 * @param callback	CookieChanged callback from your plugin
 */
native void UnhookCookieChange(const char[] cookie, CookieChanged callback);

public SharedPlugin __pl_cookie_manager =
{
    name = COOKIE_MANAGER_LIBRARY,
    file = "cookie_manager.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
	public void __pl_cookie_manager_SetNTVOptional()
	{
		MarkNativeAsOptional("HookCookieChange");
		MarkNativeAsOptional("UnhookCookieChange");
	}
#endif
