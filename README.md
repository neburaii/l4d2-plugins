# l4d2-plugins
repository for plugins i've developed that are publicly available.

Most of this i make for [my own servers](https://steamcommunity.com/groups/l4d2hardx). I few are made by request of friends, and may not be present in those servers.

**all plugins are written within a sourcemod 1.12 environment, and are all compiled with 1.12**

avoid redistributing my mods. If it's only available here, then updates i push are guaranteed to reach all users. Other than that reason, i don't really care.

# Notable plugins
## [hxlib](./hxlib/README.md)
a collection of natives/forwards to provide new interfaces with the game. many of the other plugins will require it.

there's a also a stocks file called [hxstocks](./hxlib/scripting/include/hxstocks.inc). if it's all a plugin needs, then it will include that directly to avoid the hxlib requirement. but naturally you'll need that stocks include to compile those plugins.

## [cookie_manager](./cookie_manager/README.md)
one design philosophy i feel strongly about is that if something can be made optional, then it should be implemented as such via clientprefs cookies. the interface clientprefs provides for players to modify cookie values is a bit too basic in my opinion. cookie_manager was developed to provide a robust alternative to those interfaces.

any plugins in this repo implementing cookies will have this manager as a soft requirement. you don't need it installed, but installing it means those plugins will integrate with it. check the [cookie_manager README](./cookie_manager/README.md) for more information.

