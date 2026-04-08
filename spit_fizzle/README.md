# Description
a spitter's spit may "fizzle", meaning any spit projectile belonging to them disappears and any spit puddle belonging to them will stop growing.

what triggers this fizzle is controlled by 2 convars:
- **spit_fizzle_on_stagger**: when the spitter gets staggered
- **spit_fizzle_on_death**: when the spitter dies or gets disconnected/kicked
each convar can have a value of 1 (trigger enabled) or 0 (trigger disabled)

## Hard requirements
- [hxlib](../hxlib)
- [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

# Changelog
## v2.2
- new method for stopping puddle growth. it's more performant and precise.
- better precision in stopping puddle growth means the min size for puddles is much lower, and the chances of invisible spit are zero.
- new method for associating puddles with spitters
- simplified a lot of code
- projectile creation detour moved to hxlib. hxlib is now required

## v2.1
- identifying which spitter created which puddle is more accurate
- fizzle can trigger from a spitter staggering now
- added convars to toggle the 2 triggers (spit_fizzle_on_stagger and spit_fizzle_on_death)

## v2.0
- new method. delete projectile at spitter death, rather than letting it land and create no puddle

## v1.1
- bug fixes

## v1.0
- original release
