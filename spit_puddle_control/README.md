# Description
provides a few convars to tweak spit puddles.

### ConVars
- `spit_damage_curve`
it should be a comma separated list of damage/sec values. for reference, the vanilla curve would be "0.0, 5.0, 10.0, 20.0, 30.0, 30.0, 20.0, 7.0".
the curve gets scaled to lifetime. how far into that lifetime is the position in the curve we get DPS from, interpolating when needed.
set it to nothing ("") to fallback to vanilla curve. incorrect formatting will also have it fallback to vanilla.
**NOTE**: it's important to understand that these are damage **per second**. it will be scaled to damage tick interval (0.2 seconds) afterwards to get final base damage.

- `spit_lifetime`
how long should the spit be toxic?
due to a limitation of not being able to influence the render duration of the client side sprite, values above 7 (vanilla) are not allowed, because that would mean invisible spit during the extended time. likewise, shorter durations won't see the puddle fully removed client side. but it will stop fizzling.

- `spit_max_flames`
same as inferno_max_flames, but for spit (exluding death puddles). "flames" may be misleading, but it was named to be consistent with that existing convar. the flames here are each individual patch of spit created through its spreading. can be between 2 and 64. vanilla is 10 for reference.

## Requirements
- [hxlib](../hxlib/README.md)

# Changelog
### 2.3
- initial public release
- can now configure damage curve. curve now correctly scales to `spit_lifetime`
