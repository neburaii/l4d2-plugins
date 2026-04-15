# Description
vanilla+ tweaks to hunter audio cues to be less jank, and easier to read.

At the moment, this only does 2 things specifically:
- hunter will shriek everytime he lunges
- hunter lunge warning will no longer play if he's already lunging

sometimes you have your back turned to them and rely purely on audio. if he does one jump, misses, and immedately jump again, the vanilla shriek cooldown will make it silent and you will not be made aware of his 2nd jump.

similarly, if you hear the lunge attack warning, you will assume he is still on the ground and you should only turn to react if you hear the lunge shriek. but in vanilla, he is able to do this lunge warning sound mid-lunge.

# Usage
i understand that these improvements may be subjective, so there is a convar for each one:
- `audio_feedback_hunter_always_shrieks`
- `audio_feedback_hunter_honest_warn`

# Changelog
### 1.1
- moved out of `neb_consistent_ability_cue`, and into its own plugin
- fixed bugs with how shriek sound was made consistent
- added feature to remove deceiving warning sounds

### 1.0
- intitial release
