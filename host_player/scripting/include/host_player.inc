#if defined _player_host_included_
	#endinput
#endif
#define _player_host_included_

#define HOST_PLAYER_LIBRARY	"host_player"

/**
 * called when the lobby host changes.
 *
 * @param oldHost	client index of the previous host
 * @param newHost	client index of the new host
 *
 * @note			either can be 0 if no old/new host
 */
forward void OnLobbyHostChanged(int oldHost, int newHost);

/**
 * get client index of the current lobby host
 *
 * @return			client index of the host, or 0 if no host
 */
native int GetLobbyHost();

public SharedPlugin __pl_player_host =
{
    name = HOST_PLAYER_LIBRARY,
    file = "host_player.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
	public void __pl_player_host_SetNTVOptional()
	{
		MarkNativeAsOptional("GetLobbyHost");
	}
#endif
