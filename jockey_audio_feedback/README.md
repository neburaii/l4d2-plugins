# Description
restores cut audio for the jockey warning his target on near approach.
also modifys the sound level of his idle noises, along with their frequency. the default sound level override will make his idle sounds quieter at a distance just like other SI.

### Hard Requirements
- [hxlib](../hxlib/README.md)
- [actions](https://forums.alliedmods.net/showthread.php?t=336374)

### Soft Requirements
- [cookie_manager](../cookie_manager/README.md) (to integrate with its menu and to instantly apply cookie setting)

# Usage
### ConVars
to configure his idle noise frequency:
- `audio_feedback_jockey_vocalize_interval_min`
- `audio_feedback_jockey_vocalize_interval_max`

to configure the frequency of the new warning sound:
- `audio_feedback_jockey_warning_interval_min`
- `audio_feedback_jockey_warning_interval_max`

to configure the range of the new warning sound (range from the target he's aggro'd on):
- `audio_feedback_jockey_warning_range`

override idle noise sound levels with custom value:
- `audio_feedback_jockey_idle_sound_level`

override warning noise sound levels:
- `audio_feedback_jockey_warning_sound_level`

### Cookie
the use of the cut warning sound can be set per client. there are 3 possible settings:
- **0** : play his idle sound in place of warning sounds (no cut sounds)
- **1** : only play the cut warning sound when you're the player he's warning
- **2** : always play the cut warning sound

by default it's set to 1. the cookie to change it is:
- `jockey_warning_sound`

the default value of the cookie can be set with the convar:
- `cookie_jockey_warning_sound`

# Changelog
### 1.2
- added convar to adjust warning sound level
- added cookie/convar combo for setting if cut warning sound is audible

### 1.1
- scrapped proximity based volume adjustment in favour of replacing sound level
- added warning sound
- added control over vocalize frequency

### 1.0
- initial release
