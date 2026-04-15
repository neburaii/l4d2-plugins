# Description
restores cut audio for the jockey warning his target on near approach.
also modifys the sound level of his idle noises, along with their frequency. the default sound level override will make his idle sounds quieter at a distance just like other SI.

## Hard Requirements
- [hxlib](../hxlib/README.md)
- [actions](https://forums.alliedmods.net/showthread.php?t=336374)

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

# Changelog
### 1.1
- scrapped proximity based volume adjustment in favour of replacing sound level
- added warning sound
- added control over vocalize frequency

### 1.0
- initial release
