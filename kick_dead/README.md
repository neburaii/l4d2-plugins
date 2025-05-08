normally when an SI dies, their client stays connected to the server for a while before finally disconnecting. This can be a minor problem in a mode like hard 28 since it acts as a hard limit to how frequent spawns can happen, due to the 32 client limit staying filled for longer durations than expected.

This plugin will immediately disconnect an SI's client right after they die, along with making sure their death sound still plays in its entirety

known issues:
* if you have a plugin on your server that relies on their clients existing briefly after death for some of its functions, it may not work right
* the red text telling who killed who can bug out and not show sometimes. Seems ping based. I

windows hasn't been tested