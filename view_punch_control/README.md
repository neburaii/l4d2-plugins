# Description
provides convars to modify camera view punch from individual sources. one of these sources, weapon recoil, can optionally be set to allow clients to set it for themselves via a cookie.

sources covered:
- hit by SI
- hit by CI
- friendly fire
- being shoved
- being vomitted on
- recoil from shooting your gun

## notes on recoil view punch
there are vanilla convars for this, called `z_gun_vertical_punch` and `z_gun_horiz_punch`.
`z_gun_horiz_punch` is off by default, while `z_gun_vertical_punch` is on by default.

due to the view punch from recoil not having any notable gameplay impact (assuming it's vanilla recoil), a client cookie is available to set this. relying on these vanilla convars alone doesn't allow a per-client implementation.

if a client doesn't set their cookie or the `view_punch_use_recoil_cookie` convar is set to 0, we need a "global toggle" type value to fall back to. the vanilla convars consist of 2, meaning 4 possible combinations. it's not suitable as a "toggle" value fallback.
the decision was made to have our own convar to act as a global toggle for recoil punch for when a fallback value is needed.

because you could set only one of, both, or none of the vanilla convars - the values used will take effect when the plugin's convars/cookie allow punch to preserve the server operator's desired combination. this means that you could set both vanilla convars to 0, and that will make it impossible for the plugin's convars/cookie to enable punch from recoil. intentional design choice, and should be noted.

**it's recommended to NOT set both `z_gun_vertical_punch` and `z_gun_horiz_punch` to 0. view them as configuration for punch direction when punch is allowed by this plugin**

## Soft requirements
- [cookie_manager](../cookie_manager/README.md) - to instantly update plugin on cookie value change, and to register our cookie for use in the manager's menu.

## Hard requirements
- [hxlib](../hxlib/README.md)
- [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

# Usage
## ConVars
the following take a multiplier as a value. punch will be multiplied by the respective convar's value:
- `view_punch_mult_vomit`
- `view_punch_mult_friendly_fire`
- `view_punch_mult_common_hit`
- `view_punch_mult_special_hit`
- `view_punch_mult_shove`

to allow or disallow the client cookie for recoil view punch from being used, use this convar:
- `view_punch_use_recoil_cookie`

if `view_punch_use_recoil_cookie` is true, the following convar will be used as a default value for clients who haven't set the recoil cookie. otherwise, it will be used as a global toggle.
- `cookie_view_punch_recoil`

## Client Cookie
clients can customize their own personal toggle for recoil view punch using a cookie. this cookie's value will be ignored if the `view_punch_use_recoil_cookie` convar is set to 1.

the cookie is called:
- `view_punch_recoil`

# Changelog
## 3.0
- removed the reliance on dhooks. detours were moved to [hxlib](../hxlib/README.md)
- removed the roll angle cookie. it's been moved to [roll_angle](../roll_angle/README.md)
- improved how replication of vanilla weapon recoil convars is handled
- weapon recoil cookie: added support for [cookie_manager](../cookie_manager/README.md)
- renamed everything
- you can now set a default value for the recoil cookie
- every source of view punch except weapon recoil is now a multiplier instead of a toggle

## 2.0
- changed where view punch is blocked.
- added detection for several sources calling the function for our view punch hook. tracked sources:
	- from being shoved
	- from being shot at
	- from being hit by a common infected
	- from being hit by a special infected
	- from being vomitted on
	- from gun recoil
- each detected source has a convar toggle (except gun recoil. that's still a cookie).

## 1.0
- initial release.
