makes use of sourcemod cookies to add optional fancy features each client can choose to enable for themselves. Some custom fonts will cause the fancy features to look terrible, so they're off by default. You can enable them with:
/cookies cookie_name 1

the cookies:
* sihp_show_all - global toggle to show/hide every bit of the healthbars
* sihp_show_normal - show/hide the shorter healthbar reserved for non-boss SI
* sihp_show_boss - show/hide the longer healthbar reserved for boss SI (tank/witch)
* sihp_show_temp - enable/disable the "temp health" element in healthbars. This element will represent damage you (not others) recently dealt to the healthbar target. It will decay shortly after you stop dealing damage. It's meant as extra feedback for your personal contributions to a kill
* sihp_show_death - enable/disable the "death by you confirmation" element. If the healthbar target dies and you are its killer, the empty healthbar will appear in a special, animated way. This is to let you know that you got the kill, or if a teammate stole it
* sihp_priority_only - if enabled, it will block all **secondary** updates to healthbars. Read the next section about healthbar updates~

healthbars updates occur from 2 types of sources: primary and secondary.
Primary sources are from you dealing damage or killing something. They occur instantly.
Secondary sources are from any change to the bar that isn't directly caused by your personal damage. So other damage from teammates, or the next frame from one of the animated effects. These updates get queued, waiting for the next plugin managed frame.

Lastly, as some of the cookies listed above already hinted at, 2 healthbars can display alongside eachother: one reserved for the last boss infected you dealt damage to, and one for the last non-boss infected you dealt damage to. Their healthbars will persist on your screen until you either deal damage to a new target, or you don't attack anything for a duration (infectedhp_target_remove_time convar, which by default is 2.5 seconds)
