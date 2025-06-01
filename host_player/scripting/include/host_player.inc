#if defined _player_host_included_
	#endinput
#endif
#define _player_host_included_

/**
 * check if this player is the host of the server
 * 
 * @param iClient	client index
 * @return bool		true if the player is the host, false otherwise
 */
native bool IsPlayerHost(int iClient);

/**
 * get client index of current host of the server
 * @return int		client index of the host, or 0 if no host
 */
native int GetHostClient();