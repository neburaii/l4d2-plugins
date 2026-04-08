# Description
options per client to remove infected ragdolls.

## Hard requirements
- [hxlib](../hxlib/README.md)

## Soft requirements
- [cookie_manager](../cookie_manager/README.md)

# Usage
2 client cookies:
- `ragdoll_fade`: ragdolls will fade
- `ragdoll_ci_begone`: commons disappear instantly on death

this is done per client, so if someone prefers ragdolls to never fade while another player in the same game prefers them to fade, both can be satisfied.

there are convars to set default values for each of these cookies:
- `cookie_ragdoll_fade`
- `cookie_ragdoll_ci_begone`

# Changelog
## 1.2
- added hxlib as a requirement
- refactored code
- added support for cookie_maanger

## 1.1
- fix `ragdoll_ci_begone` cookie from making commons spawn invisible

## 1.0
- initial release
