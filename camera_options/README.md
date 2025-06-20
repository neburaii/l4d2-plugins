provides client cookies for camera movement stuff.
Current cookies:
* **camera_disable_recoil**: disables the camera punch from shooting. This is 99% just a visual thing, players opting to use this won't have an advantage. 
* **camera_roll**: angle of camera view roll/tilt, like what's seen in games like black mesa. Can set it to whatever angle you want

Clients must opt into each one. Defaults are vanilla

The rest of the mod does not use client cookies, even though it technically could. The reason is because the gameplay is affected wayy too much. Having them unblocked by default with an option to opt in gives all players who are aware of the option an unfair advantage. Meanwhile the opposite where it's blocked by default with option to opt out - it makes no sense for players to want to choose to give themselves a disadvantage.
The ConVars:
* **camera_block_punch_boom**
* **camera_block_punch_ff**
* **camera_block_punch_ci**
* **camera_block_punch_si**
* **camera_block_punch_shoved**
all are 0 by default. Set to 1 to block that source of camera punch

## COMPLETELY UNTESTED ON WINDOWS!!
i don't host windows servers, so i don't care to test the signatures. Some of them took enough inference for me to not be 100% confident they'll work (although i'm like 95% confident)
