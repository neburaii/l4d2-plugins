# Description
depending on how a sound is emitted, it can override an already playing sound. this is commonly heard in SI voice audio. for example, a charger could make the charging sound but then immediately after make the sound from getting LOS with you. in this scenario, the charge sound cue could go completely silent if that follow up sound came quick enough.

this plugin gives you a way to define priority for sounds. sounds with a priority higher than a sound expected to interrupt it will cause that sound to not play at all, ensuring the priority sound is heard in its entirety.

in the charger example, we could set his charge sound to priority of 3. if a sound expected to interrupt it comes along with a priority of 1, then it will be blocked from being played because 3 > 1. if both the currently playing sound and incoming sound are the same priority or the incoming one is of a higher priority, then it is let through - replacing/stopping the existing sound.

any sound with an undefined priority will be 0, the minimum value, by default. 0 priority sounds can always be interrupted.

### Default configuration
the plugin requires sounds to have defined priorities to do anything. the files here include a configuration file for this already. it's configured to make important SI voice sounds prioritized.

that example i gave of the charger earlier is addressed, among many similar scenarios. if a special infected spawns, the distinct sound alerting you of their spawn will go uninterrupted by idle sounds. same goes for audio cues of their abilities, or their abilities being canceled/countered, etc. never hear a silent spawn, or smoke/charge/hunter/whatever ever again.

## Soft requirements
- [hxstocks](../hxlib/scripting/include/hxstocks.inc) - to compile

# Usage
the plugin on its own does nothing. it will treat every sound with 0 priority by default.

[the data file](./data/priority_sounds.txt) is where you configure sounds to have priority. for any given sound, you can set a **duration** and a **priority**. this data will be used only when the sound is being played in a scenario where an already playing sound is expected to be replaced by it.

the comments in that file go into detail on configuration, along with a summary of what the plugin does. the basics are:
- sound names are defined as sections. they must be paths relative to the sound folder, using forward slashes and all lowercase
- duration/priority are defined as keyvalues within any given section.

for example:
```
"path/from/sound/folder/sound_01.wav"
{
	"duration"	"2.0"
	"priority"	"1"
}
"path/from/sound/folder/sound_02.wav"
{
	"duration"	"1.5"
	"priority"	"2"
}
```

### Sound duration limitation
one problem with dedicated servers is that we have no way to determine the duration of sound files. the sound files don't exist in the server installation, and the code for getting the sound duration is compiled out.

because we already need to configure a priority level for sounds we want to have priority, we use the same configuration to specify the sound duration. it is annoying, but it works. you can also give shorter values if you only want it to be uninterrupted for a shorter amount of time.

# Changelog
## 2.0
- moved/renamed (originally neb_consistent_ability_cue)
- redesigned to be versatile. can support more sound replace cases, on any edict.
- can configure priority/durations for any sound
- priority is a numeric value now. interrupt if priority is >= that of the currently playing sound on that source/entchannel
- default configuration greatly expanded

## 1.0
- initial release
