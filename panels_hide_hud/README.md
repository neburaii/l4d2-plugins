# Description
a menu/panel that you see from something like sourcemod's admin menu, etc, can on some custom HUDs be very difficult to use due to overlap with other HUD elements.

This plugin will auto-hide HUD elements when such a menu is opened. elements hidden:
- all health bars
- red text events (e.g "Coach killed Hunter")
- white text events (e.g "Coach gave health to Nick", "Ellis protected Rochelle", etc)

## Soft requirements
- [cookie_manager](../cookie_manager/README.md) - to make cookie changes take effect immediately, and to register the cookie for use in menus from cookie_manager
- [hxstocks](../hxlib/scripting/include/hxstocks.inc) - to compile

## Hard Requirements
- [Left4SendProxy](https://github.com/szGabu/Left4SendProxy/releases) - required for hiding health bars

# Usage
## convars
these are tied to cookies. the values of these convars are used if the client doesn't have the associated cookie set.
- `cookie_panels_hide_hud_survivor`
- `cookie_panels_hide_hud_infected`

## client cookies
because we're unable to detect if there's actual overlap, a cookie is provided if a client wants to disable the auto-hide behaviour:
- `panels_hide_hud_survivor` - 1 or 0. auto-hide panels if on survivor team
- `panels_hide_hud_infected` - 1 or 0. auto-hide panels if on infected team

# Changelog
## 1.0
- initial release
