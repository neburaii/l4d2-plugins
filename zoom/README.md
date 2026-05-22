# Description
this primarily just fixes janky zoom bugs.

when the server forcefully un-zooms your weapon, it will spam the zoom out sound until you fully zoom out.

it won't spam the actual action of zooming out. although it checks this by seeing if your current FOV is equal to the weapon zoom level. so in especially high tickrate, the tick immediately after for some weapons can still see your fov as equal (since it's an integer). this causes the zoom out action itself to get spammed, locking the player in their scope for the duration of being under this "force zoom out" condition.

checking your FOV is a common pattern in the original code for determining if it should zoom out or in. but there is a much better way to check this. this plugin rewrites the function responsible for this to use a more accurate method to determine zoom state. this fixes all high tickrate bugs, and even janky behaviour when you spam the zoom key.

### ConVars
because the method i went with meant rewriting the original code, it meant it was an easy opportunity to expose 2 hardcoded numbers through new convars:
- `zoom_in_duration`
- `zoom_out_duration`

they are what the name implies. the duration for the transition between zoom states, for both directions.

### Hard requirements
- [hxlib](../hxlib/README.md)

# Changelog
### 1.0
- initial release
