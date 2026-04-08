# Description
## the problem
special infected bots remain a connected client for ~7 seconds after death. the director only starts spawn timers for that SI's slot after the disconnect. so a 15 second respawn interval means 22 seconds, and any respawn timer < 7 seconds is impossible.

this also is extremely problematic when the server is constantly near/at the client limit.

## solution
kick the client the moment they die. issues that come from doing this have included fixes (no cutoff death sounds, red "Player Killed Infected" text still displays).

the kick isn't instant, but 0.1 seconds after the death. this is due to clients with high ping refusing to display the red kill text when the infected bot disconnects too quickly.

## Hard requirements
- [hxlib](../hxlib/README.md)

# Changelog
## 1.4
- ragdoll_hook requirement replaced with hxlib.
- moved convar to skip death animation into its own plugin.

## 1.3
- removed detours. moved them to ragdoll_hook

## 1.2
- add convar to skip tank death animation, making him die and have his client removed slightly sooner

## 1.1
- fix tank death sounds not playing
- make post-death sounds emit from the ragdoll entity
- delay kick to give time for client to receive/process the player_death event with the killed infected still in the game

## 1.0
- initial release
