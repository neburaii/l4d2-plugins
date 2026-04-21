# Description
vanilla gives you very little control over the movement speed of players. many of the speed values to use are hardcoded. this plugin reimplements the code for getting these speed values, but designed around each value being its own convar.

convars can be viewed in 2 categories: base speeds, and modified speeds.

a modified speed is either a clamping value, which gets set if the base speed is faster. for example, water slowdown works because its convar clamps higher speeds to its value. lower speeds are left untouched. some other modifiers are multipliers.

not all valid modifies will be applied. for example, a smoked survivor will have the modifier for being smoked apply but not a modifier for being in water. the logic for how they apply mirrors vanilla's.

base speeds are split into 3:
- **run**
- **walk**
- **crouch**

they're self explanatory. each type of player will each have their own convar of these 3 base speeds. the player types are:
- **observer**
- **smoker**
- **boomer**
- **hunter**
- **spitter**
- **jockey**
- **charger**
- **tank**
- **tank_vs** (tanks in versus gamemode)
- **ghost** (player SI ghosts)

there are 2 player types for tanks because that pattern already exists in vanilla, even if the default values of their convars aren't different.

observers of course can't actually crouch. the convar exists just to keep the design simple.

**note on bug**
clients seem to want to predict what speeds will be. for example, setting water speed modifier to match base running speed will have clients experience a subtle rubber band as they transition from land to water. this is only noticeable for massive changes to certain speeds, more so if it's being set higher than default.
in the case of water movement speed, i don't recommend using this plugin if you just want to remove water slowdown. do it properly with the WaterSlowsMovement gamerule (can be set with the director variable of the same name)

### ConVars
modifers:
- `tongue_victim_max_speed`: vanilla. value is replacement of base speed when a survivor is being pulled by a smoker.
- `z_jockey_min_mounted_speed`: vanilla. value is min multiplier. when survivors are being ridden by jockeys, their base speed will be multiplied by the ratio of their current health / max health. if that ratio dips below this convar's value, then the convar value will be used instead as the ratio.
- `adrenaline_run_speed`: vanilla. value is replacement of base speed when a survivor is under the effects of adrenaline.
- `survivor_limp_health`: vanilla. health threshold required for "speed_limping" modifier to apply. survivor's health must be below this value
- `speed_limping`: new. clamp base speed to this value if survivor's health is under the "survivor_limp_health" threshold.
- `speed_near_death`: new. clamp base speed to this value if a survivor is at 1 hp.
- `survivor_drag_speed_multiplier`: vanilla. multiply final speed if survivor is dragging an entity? (not sure what this mechanic refers to. didn't feel like researching it. but it is implemented for parity with vanilla)
- `speed_water`: new. clamp base speed to this value if a survivor is in water, and the WaterSlowsMovement gamerule is active.
- `speed_water_versus`: new. same as "speed_water" but for versus. vanilla hardcoded a different value for each mode, which is why 2 were implemented.
- `speed_scoped`: new. clamp base speed to this value if a survivor is using weapon zoom.

the base speed convars are many. the new ones all follow a predictable naming scheme:
- `speed_base_x_y`

where x is the player type, and y is the speed type. a list for these types can be seen above.

but the pre-existing vanilla convars for base speeds aren't so predictably named. i will list them out along with notes:
- `z_ghost_speed`: previously used for all speed types, but now is only used for run type.
- `z_gas_speed`: smoker running speed.
- `z_exploding_speed`: boomer running speed.
- `z_spitter_speed`: spitter running speed.
- `z_jockey_speed`: jockey running speed.
- `z_tank_speed`: tank running speed.
- `z_tank_speed_vs`: tank running speed in versus gamemodes.
- `z_tank_walk_speed`: tank walking speed. previously used for both versus and non-versus. now it's only used for non-versus.
- `survivor_crouch_speed`: survivors speed while crouching.

### Scrapped ConVars
**some convars have been scrapped**. first of all, there was an already unused convar called "z_hunter_speed" which presumably would be used for hunter running speed. this isn't restored. hunter running speed convar is a new one using the naming format described above.
meanwhile there were convars in use, but they clashed with the plugin's design. i will list them here:
- *z_speed*: this was originally used as running speeds for the hunter and charger AND common infected. scrapped for hunters and chargers so they can have their own convars.
- *z_crouch_speed*: same case as the above, but for crouching speed and it also included all other SI aside from tank.
- *survivor_fumes_walk_speed*: survivor walk speed if HP is at 1. default value made it identical to walk speed and hardcoded 1 HP speed for crouch/run. it didn't make sense to me for this to be configurable per speed type. our convar is a clamp modifier that applies to any speed type.
- *survivor_limp_walk_speed*: this one is probably bugged. likely doesn't even get used, although i didn't look at every code involved to know for sure. regardless, as it's implemented now it's kind of pointless. presumably it's intended to be used for survivors walking with their HP under the limp threshold. but our convar chose to make limp walk speed a speed clamp used across all speed types.

## Hard Requirements
- [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)
- [hxlib](../hxlib/README.md)

# Changelog
### 2.0
- fixed jockeys who are riding survivors not modifying speed.
- fixed smokers pulling survivors not modifying their speed.
- redesigned to have perfect parity with how vanilla deterimines the various scenarios for applying different speeds
- added many new convars
	- base speeds for crouch, run, walk
	- can configure base speeds for survivors, special infected, observers, ghosts
	- versus/non-versus convars for water modifier and tank speeds
- removed redundant convars, reverted to using their respective vanilla convars.
- renamed all convars.
- hxlib is now required

### 1.2
- check for weapon zoom more reliable

### 1.1
- fixed weapon zoom not slowing player down.
- weapon zoom speed convar added

### 1.0
- intial release
