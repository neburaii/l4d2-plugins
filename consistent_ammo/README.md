# Description
monitors changes to reserve ammo capacity convars. When any change, the plugin will automatically adjust every survivor's current remaining ammo to preserve the remaining/total ammo ratio. Also scales unequipped weapons in the same way.

# Changelog
## 1.2
- moved features out into separate plugins:
	- sm_ammo command ([ammo_command](../ammo_command/README.md))
	- auto-fill ammo on map transition ([autofill_ammo](../autofill_ammo/README.md))
- all ammo types now supported
- removed left4dhooks requirement
- convar value changes coming from or to a value under 0 is now handled correctly

## 1.1
- removed use of `conformed_messages_shared.phrases` translation file. moved phrases to its own.

## 1.0
- initial release
