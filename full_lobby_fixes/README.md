# Description
fixes 3 annoying issues that arise from a full lobby:
1. players cannot join the game.
2. a survivor player disconnecting results in their character being deleted.
3. a survivor player going idle results in their character being deleted.

these issues happen because they all involve creating a new bot client, but with no free client slots this is not possible. due to this cause, these "fixes" are just workarounds.

## How each issue is fixed
1. when a player tries to join and are predicted to be rejected due to a full lobby, we delay their connection until room is made. room is made by kicking an infected bot. to avoid being noticeable, the only candidates for being kicked are bots no survivor have LOS of, and are beyond a configurable range (by default this range is 800.0, which is too far for a spitter/smoker ability).
2. a survivor disconnecting needs a bot to replace them. the game will create this bot before the player fully disconnects, having them exist at the same time for a brief moment. the plugin fixes this by delaying the bot replacement until after the client fully disconnects. this bot replacement method is only used in the scenario of a disconnect from a full lobby.
3. make it so a player can't idle while the lobby is full.

## ConVars
- **full_lobby_fixes_min_discard_range**: to fix players not being able to join full lobbies, a slot must be freed for them. the plugin will find an infected bot client to kick to free a slot. any infected bots within this range of any survivor cannot be a candidate.

## Hard requirements
- [hxlib](../hxlib)
- [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

# Changelog
## v1.0
- initial release
- moved the idle on full lobby block from the "block_idle" plugin to here. "block_idle" has been removed from the repo.
