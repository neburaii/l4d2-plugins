#if defined _server_emptied_included_
	#endinput
#endif
#define _server_emptied_included_

/**
 * return if the server is currently empty
 * @return bool
 */
native bool IsServerEmpty();

/**
 * runs when the server first properly empties
 */
forward void OnServerEmptied();