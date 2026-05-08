# Description
play audio feedback for hitting headshots on infected. the sound to play for a total of 8 set of circumstances are configurable.

### Soft requirements
- [cookie_manager](../cookie_manager/README.md) - to integrate with its menu, and to apply cookie changes instantly

### Hard requirements
- [hxlib](../hxlib/README.md)

## Configuration
### sounds to play
we have 3 layers of context behind headshots.

**target type**:
- Common infected (`ci`)
- Special infected (`si`)

**weapon type**
- Guns (`gun`)
- Melee (`melee`)

**headshot type**
- Wounded (blank)
- Kill/lethal (`kill`)

for each combination, there is a cookie. the cookies are named like so:
`headshot_sound_<target>_<weapon><_headshot>`

the underscore before headshot type won't be present if it's empty (which is wounded). the exact text for each value i put in brackets in the list of them above. so as an example:
- `headshot_sound_ci_gun_kill` will refer to lethal headshots using a gun against common infected targets.
- `headshot_sound_si_melee` will refer to non-lethal melee strikes to a special infected's head.

each cookie has an associated convar to set its default value for clients who haven't configured it. the names of the convars are the same but with the prefix:
- `cookie_`

### Shotgun ratio
lastly, you can configure a ratio used to dermine if buckshot hits should play the sound. the plugin will record all damage events for a frame, and then at the start of next frame it processes it as a batch. if there are more than 1 hit on a target, it will check the ratio of: `headshots / total shots`. the ratio must be >= the following convar's value in order to be recognized as a headshot:
- `headshot_sound_required_ratio`

# Changelog
### 1.0
- initial release
