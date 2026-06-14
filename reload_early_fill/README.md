# Description
fill a weapon's magazine ammo before it finishes reloading.

### what makes this one unique?
this is relative to the duration of weapon animations.

by default, it will fill your ammo at `ReloadDuration - DeployDuration` seconds into the reload. there is an additional amount you can subtract with a ConVar, but it's 0.0 by default. `DeployDuration` refers to the animation for switching back to the item. this represents the quickest possible time you can switch away and back. subtracting any more time than this introduces a meta of swapping items to achieve shorter duration times.

unlike other mods achieving this goal, no exact durations are hardcoded or configured. it's even compatible with custom models changing animation durations.

### ConVar
if you do like that item swapping meta, use the convar:
- `reload_early_fill_exploit_duration`

its value will be how many additional seconds are subtracted after subtracting deploy animation duration. effectively, it's the amount of time possible to save by switching items.

## Requirements
- [hxlib](../hxlib/README.md)

# Changelog
### 1.0
- initial release
