# Description
replaces `sv_allow_wait_command` convar with `sv_allow_wait_command_admin`. the value of this convar is a string of admin flags. if a player has these flags, then they will be allowed to use the `wait` command. if they don't, then their game will behave as if sv_allow_wait_command is 0.

# Changelog
### 1.1
- changed convar to accept a string of flag characters

### 1.0
- initial release
