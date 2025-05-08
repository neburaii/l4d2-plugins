An infected HP bar plugin using the center text hud element. 
Interesting features:
* there are 2 bars that can display at once. One is reserved for witches and tanks, the other for all other SI
* updates healthbars after any source of damage was dealt to a player's healthbar target
* position on screen is fixed
* animated "recent damage" element
* animated variant of an empty healthbar for when you were the one to kill it

Some of its features are off by default due to some custom fonts making them look terrible. Players can toggle elements of the healthbar via client cookies:
/cookies cookie_name 1

the cookies:
* sihp_show_all - global toggle to show/hide every bit of the healthbars
* sihp_show_normal - show/hide the shorter healthbar reserved for non-boss SI
* sihp_show_boss - show/hide the longer healthbar reserved for boss SI (tank/witch)
* sihp_show_temp - enable/disable the "recent damage" element in healthbars. This element will represent damage you (not others) recently dealt to the healthbar target. It will decay shortly after you stop dealing damage. It's meant as extra feedback for your personal contributions to a kill
* sihp_show_death - enable/disable the "death by you confirmation" element. If the healthbar target dies and you are its killer, the empty healthbar will appear in a special, animated way. This is to let you know that you got the kill
* sihp_priority_only - if enabled, it will force the plugin to only update your health bars when the target takes damage from you. Disabled means it will update after the target is damaged from any source.
