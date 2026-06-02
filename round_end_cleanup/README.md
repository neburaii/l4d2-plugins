# Description
### Problem
when the round resets, the map will do a cleanup. it removes all entities except for those of a class that's marked as "preserved". it then spawns all map entities.

when it spawns the map entities, sometimes it will spawn some and immediately remove them. these temporary entities can cause the total edicts to spike during this cleanup. in a map like passing's first chapter, this spike is massive (doubling to around 2000 total edicts).

normally this isn't a problem due to entities being removed. but among the "preserved" entity classes, there is one that can be problematic: `predicted_viewmodel`. for every client, there will be 2 of these edicts attached. they exist during that big spike in total edicts. so for every client connected when a round resets, the closer you put the server to the edict limit during map cleanup.

pair that with a higher than normal MaxClients value, and maps like passing chapter 1 have a high likelyhood of crashing the server on round reset. MaxClients will reserve edict slots for clients, effectively decreasing the edict limit when increased.

for example, if MaxClients is 32 (by using l4dtoolz) and there are at least 17 total survivors/si connected when a round resets on passing chapter 1, the server *will* crash everytime.

### Solution
this plugin uses a very simple solution to that problem. on round end, all `predicted_viewmodel` entities that are expected to re-create themselves will be removed. although that last part about the expectation is a bit experimental.

we could just kick all infected bot clients, but the 4 survivors alone will together have 8 of these viewmodel edicts. with a higher MaxClients, it'd be nice to compensate for the slots that eats up by removing as many preserved edicts as possible.

from my testing, players have their `predicted_viewmodel` edicts re-created when they spawn back in (even though they never disconnected). i didn't check the game code to verify this, it's purely from observation. hopefully that is consistent. seems to work fine though.

# Changelog
### 1.0
- initial public release
