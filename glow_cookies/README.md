# Description
provides a cookie to let clients toggle item/survivor glows for themselves.

there's also a convar to prevent the cookie from being used in specific gamemdoes.

### cookie
- `enable_glow`

can be 1 for enabled, 0 for disabled.
default value of the cookie is set through the convar:
- `cookie_enable_glow`

### convar
if you want server's glow settings to always apply in some gamemodes, then use:
- `glow_cookies_gamemode_blacklist`

its value expects a comma separated list of base gamemodes (the wording is important! hard 8 mutation for example is called 'mutation4' but its base gamemode is actually 'coop')

# Changelog
### 1.0
- initial release
