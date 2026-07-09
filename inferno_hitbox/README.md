# Description
CInferno is an internal class that refers to fire, spit, and firework particles (like from those gascan clones that you shoot).

this plugin will:
- fix issues related to their hitbox.
- adds new configuration of things like the radius (defaults behave like vanilla)
- layered hitbox, with full damage inner and reduced damage outer layer (disabled by default)

### Hibox fixes
the hitbox is a sphere with its center elevated from the inferno surface. there is one for each "fire" within the inferno. the radius of the sphere is inconsistent in vanilla. for actual hit detection, it's always 60. but for things like computing the full extent, it's 30. the extent computation being lower is quite problematic. when checking entities to deal damage to, it first filters for entities within the bounding box of the entire inferno.

in practice, this means the safe approach distance is very inconsistent. the bounding box is rectangular, so not every "outer" fire will be at the edge of the box. those that are at the edge can be approached at most 30 units away from the closest fire's center before damage is received. but if you approach from a different side, you can enter the bounding box beyond 60 units from the closest sphere. so approaching this way has you taking damage at double the distance!!

so the first fix is to make the radius consistent everywhere it's used. now approaching from any side will have you receive damage at the same distance.

---

the 2nd issue fixed is unique to spit. for some odd reason, the client will always fail to render the 2nd created "fire" (but let's just call them patches in the context of spit) of the spit puddle.

best example to illustrate this are death puddles. these puddles will always create 2 patches. but in game, you only ever see it as one patch. that's because the 2nd never renders. but it is there and will deal damage. so on a random side of the visible patch will be an extension of the spit, and that's why it feels like the safe approach distance is random.

for the full spit puddles, this is less of a problem since the 2nd created patch rarely will be at the edge of the pool. but it is still invisible, and you can spot this empty patch in the full puddle if you look closely.

this plugin makes it so this patch is ignored in hit detection.

there are other causes for invisible patches that i've yet to discover a pattern for recognizing. but i only ever see them when increasing the puddle size to be larger than vanilla, or forcing them to spawn in positions impossible to be natural

### Layered Hitbox
every sphere now has a smaller sphere within it. contact with the smaller one will have you take normal damage. otherwise you take reduced damage. i added this as solution to make accidental touches of the edge of infernos less punishing.

it's configured as a multiplier of the base radius, ranging 0 to 1.

### Configuration
all convars exist for all 3 types. in the names, replace `<type>` with one of:
- `fire`
- `spit`
- `firework`

a config is automatically generated in `cfg/sourcemod` for easier configuration.

---

* `inferno_hitbox_radius_<type>`
the radius in absolute units. defaults to 45 for all types.
earlier when i was describing one of the hitbox issues, i said the radius in vanilla is inconsistent for outer most fires. it can be as low as 30, or as high as 60.
because hit detection uses 60, i view that as the more "intended" value. but players are used to the inconsistency allowing for nearer approaches on many occassions. 45 is in the middle of that 30-60 range, and so i figured it's a good compromise.

* `inferno_hitbox_high_ground_mult_<type>`
in vanilla, this mechanic was unique to spit. if you're on solid ground and are elevated above the surface of the inferno (surface, not hitbox center), then you'll take no damage.
it's a multiplier of the radius, ranging 0 to 1. 1 will disable the mechanic for that type.
fire and firework default to 1, and spit to 0.33333334. this perfectly matches vanilla behavior.

* `inferno_hitbox_full_damage_radius_mult_<type>`
the radius of the inner "full damage" hitbox sphere will be `this * inferno_hitbox_radius_<type>`.
if you're not touching the inner sphere of any fire, then you will receive reduced damage. specifically, `original damage * inferno_hitbox_damage_reduction_mult_<type>`.
setting to 1 disables the mechanic for that type. defaults to 1 for all types.

* `inferno_hitbox_damage_reduction_mult_<type>`
if outside any "full dammage" inner hitbox sphere as defined by `inferno_hitbox_full_damage_radius_mult_<type>`, then you will receive `this * original damage` for damage.
