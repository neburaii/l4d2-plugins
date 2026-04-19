## hxlib
### About
short for "Hard X Library". It's a library of forwards, natives, etc, that i originally sought out for plugins i design for [my own servers](https://steamcommunity.com/groups/l4d2hardx).

The scope of what i add to this are interfaces for existing vanilla systems. Anything that's an interface for a custom system won't be considered.

My goals while making this:
- merge what was originally scattered across many of my plugins.
- research everything being interfaced with to discover/fix bugs that came from a lack of understanding, or discover ways to expand functionality
- make everything as versatile in its usage as possible
- to learn.
In the end, much of my efforts in research and expanding functionality led to the addition of things adjacent to whatever the original focus was. I hope the result of all this is a library that more than just myself can view as useful

It being a public release influenced a lot of the design.
- I wrote documentation, and named things as best as i can.
- Its performance footprint is extremely minimal, as it only implements hooks that installed plugins need.
- I tried to keep the code well structured and easy for outside eyes to read

### Notable features/inclusions
- hooks associated with global forwards are toggled based on the existence of these forwards in plugins
- entity hook system. plugins can use AddEntityHook and RemoveEntityHook to include a function from their plugin in a private forward associated with the entity hook type (EntityHook_* enum) and entity. AcceptInput is a notable hook type.
- featureful API for nav area and director related stuff.

### Warnings
Although the gamedata fully accommodates both windows and linux, linux is the only one i actually test. I probably tested like 2% of it on windows. If you are running this on a windows server and experience issues, report it and i will fix it. This goes for any issue really.

### Its connection with this repo
Many of the plugins in this repository require this.

## [hxstocks.inc](./scripting/include/hxstocks.inc)
None of the stocks in this file require anything from the main [hxlib.inc](./scripting/include/hxlib.inc) file. It's here because idk where else to put it. It's just a random assortment of stocks, where their functions are things I found myself copy-pasting across plugins. Dumping them all into this file was the easiest solution. As such, several of my plugins will require this file to compile. hxlib itself references some of these stocks, and so will also need it to compile.

## Requirements
- [sourcescramble](https://github.com/nosoop/SMExt-SourceScramble)

# Changelog
### 1.4
- added `GetScriptValueInt` and `GetScriptValueFloat` natives
- added `bool humansOnly` param to `IsVisibleToTeam`

### 1.3
- added `SpawnCommon` and `SpawnSpecial` natives

### 1.2
- added `GetVocalizeCooldown` and `SetVocalizeCooldown` natives

### 1.1
- added `OnVocalize` and `OnVocalize_Post` forwards
- added `Vocalize` native
- added `IsHunterLunging` stock

### 1.0
- original public release.
- replaces hardx_hooks. removed hardx_hooks from the repo
- hooks implemented locally within some plugins have been moved to here, and now those plugins require this.
- neb_stocks.inc moved to hxstocks.inc. removed neb_stocks.inc from the repo.
- I reworked the naming format of everything that used to exist elsewhere. parameters in many of this pre-existing stuff was massively altered/expanded.
