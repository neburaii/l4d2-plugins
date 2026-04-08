# Description
This plugin is just a framework, and does nothing on its own. It provides a basic API for other plugins to know who the lobby host of the game is, along with integration with sourcemod's admin system for server operators to have the ability to customize a lobby host's permissions.

## What determines lobby host
The lobby host is determined by using a priority system. Each player will be given a priority. Of the players in game at any given moment, the player with the highest priority will be recognized as the lobby host.

A priority is assigned either from a record of a previous priority, which is stored by Steam ID, or initialized as a new priority.
This system means players who've joined earlier will have higher priority than those who join later.

There's a special case for players who reserve the lobby. When the player who reserved the lobby joins, they will always get the highest possible priority. This only happens the first time they join. leaving and rejoining subjects them to the same process of attempting to recover a past record, or initializing with a new priority.

Record history isn't permanent. Leaving/rejoining as part of a map transition will always restore your previous record. Leaving on your own puts a timer on your record. if you rejoin too late, you will be forced to get a new record. there's a convar to configure this timeout: `host_player_timeout`.

## Soft requirements
- [cookie_manager](../cookie_manager/README.md) - to instantly apply cookie for announcement setting, along with registering the cookie for cookie_manager's menu.
- [mulicolors](https://github.com/Bara/Multi-Colors) - to compile.

## Hard requirements
- [hxlib](../hxlib/README.md)

# Usage
## Admin Flags
server operators can manage a lobby host's permissions by using the `host_player_admin_flags` convar. you set this convar to a string of admin flags - the same flags you use in other admin related config files. By default, this convar is set to **"o"**, which is the **Admin_Custom1** flag.

these flags are temporarily added to the user's real admin flags. the plugin will track which of the flags had to be newly added, and remove them automatically when the lobby host changes.

recommended usage is to set it to some custom flag, and use that as the "lobby host" permission in command overrides, etc.

## Plugin implementation
check the [include file](./scripting/include/host_player.inc).

There's a native to get the current lobby host, and a forward that calls when the lobby host changes.

implementing this can be useful for plugins who want features restricted to the lobby host, as if treating them as a pseudo-admin.

## ConVars
list:
- `host_player_timeout` - time in seconds to invalidate a priority record after a client disconnects.
- `cookie_announce_host_change` - setting for who to announce lobby host changes to in game chat.
	- **0** = announce to nobody
	- **1** = announce to affected players only
	- **2** = announce to everynyan
	the cookie below overrides this convar's value per player who sets it
- `host_player_admin_flags` - a string of admin level flags. for example, "abc". check sourcemod/configs/admin_levels.cfg for available flags. lobby hosts will inherit the flags from this convar.
- `host_player_admin_immunity` - temporarily increase the admin immunity level of a lobby host by this much.

## Cookie
there is one:
- `announce_host_change`

if unset, then the player will use the setting of the server's `cookie_announce_host_change` convar.
a player can set it. the accepted values are the same as the convar.

## Commands
list:
- `/host`
- `/host_transfer`

### /host
`/host` will list the name of the current lobby host.

### /host_transfer
`/host_transfer` will exchange your priority record with the player matching the name given as an argument. the command will fail if the target is of higher priority than you.
this command is useful if you plan to leave the game, but want your friend to inherit whatever abilities you get from being lobby host on that server.

A successful transfer doesn't necessarily make that player the new lobby host. understand the record system described at the top of this readme. an exchange either will make them host if you were host, or give them your spot in line to be the next host.

# Changelog
## 1.1
- removed detours used for reservation detection. an implementation from hxlib is now used. hxlib is therefore added as a requirement.
- complete redesign.
	- the history is now of priority numbers. new priority numbers will be +1 from the last new number.
	- lookup of a player's past priority is done by using their steamID as a key in a hash map. if deemed invalidated, then a new record overwrites this historic record
	- current lobby host is determined by getting the player with the lowest priority of the currently connected players
	- lowest possible priority token reserved for the player recognized as having reserved the lobby.
	- reservation token being changed forces a reset of history
- added convar for timeout to invalidate a historic record. players who rejoin with new UID can restore their old record if within this timeout.
- added announcement/forward for host changes.
	- added convar/cookie combo for customizing visibility of the announcement
- added `/host_transfer` command
- removed redundant `IsPlayerHost()` native
- added feature to give temporary admin flags/immunity to lobby host

## 1.0
- initial release.
