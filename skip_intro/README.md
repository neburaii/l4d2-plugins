# Description
skips intro cutscenes reliably for all maps (not just first maps of campaign)

## Hard requirements
- [hxlib](../hxlib/README.md)
- [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

# Usage
if you want an intro scene on a particular map to play, edit `sourcemod/data/skip_intro_whitelist.txt`. add map names there, each on a separate line

# Changelog
### 1.2
- improved late loading support

### 1.1
- moved AcceptInput hooks out of this plugin and into hxlib. rewritten to use hxlib
- simplified configuration. replaced keyvalues data file with simple whitelist
- on first player leaving the safe area replaces the use of a timer for determining if we're at the start of a map
- ForceSurvivorPositions info_director input no longer blocked, and instead reverted one frame later to fix bug where players don't spawn in the right positions in some maps
- added support for late loading the plugin

### 1.0
- original release
