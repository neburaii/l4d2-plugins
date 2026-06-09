# Description
2 things:
- workarounds for buggy display of reserve ammo amounts > 1023
- low ammo warning

### workarounds
2 solutions are offered. one as a optional alternative, and the other as the fallback.

the fallback will just clamp the display to 1000 (amount configurable) whenever it's above that. it won't decrease at all until the real amount starts to dip below 1000.

the alternate option will display it as a percentage of 0 through 100.

### low ammo warning
maybe a bit out of place. but the percentage display had an issue of abstracting the absolute amount of bullets even when you're low on ammo.

the percentage display is good for a high level overview, but when a player is low on ammo the exact amount of bullets becomes important.

a good solution is to make it switch from percent display to absolute whenever the player becomes low ammo. but it would be confusing to tell if the switch happened.

enter the warning: the display will blink on/off whenever you're low ammo, along with playing an audible warning sound when you first dip below the threshold.

so now when we switch to absolute display, it will also switch to the blinking display. no confusion that way.

### Compatibility note
the low ammo audio warning relies on the game removing ammo from your reserve pool naturally.
using a script such as [this](https://steamcommunity.com/sharedfiles/filedetails/?id=3339719078) will break the feature.

## Requirements
- [hxlib](../hxlib/README.md)
- [sendproxy](https://github.com/jensewe/Left4SendProxy)

**optional:**
- [cookie_manager](../cookie_manager/README.md)

# Usage
### Cookies
each feature of the plugin has a toggle exposed via cookies:
- `low_ammo_warning`
- `ammo_as_percent`

they both accept 1 or 0 as values. set the default values through these convars:
- `cookie_low_ammo_warning`
- `cookie_ammo_as_percent`

### ConVars
some of the small details are configurable via convars.

use the following to adjust the blinking speed for low ammo display:
- `ammo_display_blink_duration_off`
- `ammo_display_blink_duration_on`

the threshold for low ammo is configured by a multiplier. the actual threshold is determined by that weapon's magazine capacity multiplied by this ConVar. so a value of 2 means 60 for military rifle (because 30 mag size), 100 for smgs, and so on.
- `ammo_display_low_warning_threshold`

when we need to clamp the ammo display, you can set the value to clamp to with:
- `ammo_display_max_reserve`

when a player's ammo first dips below the low ammo threshold, warn them by playing this sound (leave empty for no sound):
- `ammo_display_low_warning_sound`

# Changelog
### 1.0
- initial release
