# Description
plugin to add more scenarios that can despawn infected. currently it only supports stuck scenarios.

**stuck**
if infected are stuck for the time set consecutively, then they will despawn

### ConVar
- `despawn_max_stuck_time` - time they must be stuck for to despawn

## Hard requirements
- [hxlib](../hxlib/README.md)
- [actions](https://forums.alliedmods.net/showthread.php?t=336374)

# Changelog
### 1.1
- more accurate stuck detection
- all infected are now supported
- despawns from plugin now require no human survivors to have LOS of them

### 1.0
- initial release
