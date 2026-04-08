# Description
render healthbars of infected you've recently killed or dealt damage to. these healthbars use the center text hud element

only 1 healthbar of each target type can be displayed. the target types are:
- Common infected
- Non-boss special infected
- Boss special infected

there are many options to configure. many of which are done by the client through cookies. these include representing recently dealt damage in the healthbar, or animating empty healthbars of infected you've killed.

## Hard requirements
- [hxlib](../hxlib/README.md)

## Soft requrements
- [cookie_manager](../cookie_manager/README.md)

# Usage
## ConVars
configure recent damage. some context to understand these convars:
when a player deals damage, it's recorded as recent damage. this will persist for `infected_hp_recent_damage_decay_delay` length of time. the time resets if new damage is dealt. if no damage is dealt for that duration, then it will be removed. the healthbar (if the client chose to have it visible) won't have the recent damage instantly disappear. it will do an animation of decaying away. this is just visual. it can be canceled by new damage being dealt. but if not canceled, it will take `infected_hp_recent_damage_decay_duration` for it to visually fully decay.
- `infected_hp_recent_damage_decay_delay`
- `infected_hp_recent_damage_decay_duration`

any animated effect needs constant updates to the client. the following convar is the frame interval to use for spacing these type of updates out:
- `infected_hp_animation_frametime`

patterns can be configured. another form of animation depends on the pattern, which comes from circumstances. at the moment there is only 1 pattern, the "killer feedback". this pattern is in effect for healthbars whose target was killed by the owner of the healthbar.
- `infected_hp_pattern_killer_feedback`
so the value of this is a series of numbers separated by commas. each number represents a frame in the pattern's animation. since applying the pattern, it will move through each of these frames. the number has to be either 0 (normal character) or 1 (shifted character). the default value for example is: **"0,0,0,1,0,1,0,1"**. so if there are let's say 16 ticks that make up a healthbar and you aare on frame 3, then we start with the 3rd index of the list you game and move up for each tick and wrap back to first frame when we reach end of the list.

i designed it to be expandable. so maybe it's a bit complicated considering there's only 1 pattern with 2 possible values per frame, but whatever. experiment or look at the code if you want more clarity.

the length of healthbars for each target type can be configured. before version 2.2, these lengths were hardcoded. although they are configurable now, you should be warned: all healthbars plus the anchor line detailed below share the same 254 byte limit of the message they're sent as to clients. this limit is unavoidable. if healthbars are too long and all displayed together, be aware that this can surpass the 254 byte limit and nothing will be sent to the client at all. in a future update maybe i will add a system to automatically downsize lengths to keep under this limit dynamically, but for now there is no such system.
if you add up the fluff around each healthbar, that can take up at most 81 bytes. that's with all 3 displayed at once, mind you. that leaves a budget of 173 to split between the below 4 convars. default values just barely fit within this budget. if you want longer bars, consider sacking the anchor line. the tradeoff is that the horizontal position of healthbars on screen will fluctuate without the anchor line being long enough.

length of health bars per target type:
- `infected_hp_bar_len_common` for common infected
- `infected_hp_bar_len_special` for non-boss special infected
- `infected_hp_bar_len_boss` for boss special infected (tanks and witches)

length of anchor line. this is an invisible line that's used to anchor the lines containing healthbars so that they consistently appear in the same position on screen.
- `infected_hp_anchor_len`
note: the length is measured in TABS. so each character takes up more space than usual. as long as it's as long or longer than the longest displayed healthbar, all healthbars will render with their left most character aligned with the start of this anchor line

lastly, there's a convar to configure how long since setting a target for a healthbar for that target to be removed (meaning the healthbar will disappear)
- `infected_hp_timeout`

there's also a convar that pairs with each cookie. these are for default values of the cookies. read next section.

## Client cookies
there's a cookie to toggle visibility of healthbars for each target type:
- `hp_display_common` - for common infected targets
- `hp_display_special` - for non-boss special infected
- `hp_display_boss` - for boss special infected (tanks and witches)

if you want a portion of healthbars to represent damage you've recently dealt to the target, toggle it on/off with:
- `hp_show_recent_damage`

if you want the healthbars to give feedback when you're the one who killed the target, you can toggle an animated effect to play in this scenario with:
- `hp_celebrate_your_kills`

note: the last 2 cookies can look terrible in some fonts. in vanilla font, all characters used are the same spacing which is the intended look. if the spacing varies too much in your font, it may look too ugly.

all cookies can have their default value configured with a convar named with like
- `cookie_*`
where the '*' is the cookie name.

all cookie values can either be 1 (on) or 0 (off).

# Changelog
## 2.2
- added hxlib as a hard requirement
- simplified how data is tracked.
- redesigned to minimize updates to health bars, reducing overkill network traffic
	- health changes of targets always trigger immediate updates
	- ongoing animations use a new lazy update system, only re-rendering the bars after a configurable time has passed since last update.
	- while bars have an active target, a "keep alive" update is issued infrequently.
- added common infected target type
- improved how healthbars propogate to spectators
- removed `sihp_priority_only` cookie
- added support for cookie_manager

## 2.1.1
- fixed exception from trying to using a non-edict index in an array too small

## 2.1
- spectators can now view the healthbars specific to the player they're spectating
- memory leak fixes
- redesigned to be more reliable, many bugs fixed

## 2.0
- death indicator changed from static "uwu" to animated bar bezzle
- added `sihp_priority_only` cookie to disable 3rd party damage sources from updating the bar
- improved the temp health decay effect

## 1.0
- initial release
