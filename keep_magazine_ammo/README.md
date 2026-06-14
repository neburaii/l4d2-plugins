# Description
adds convar toggle for keeping your weapon's magazine ammo when initiating a reload.

### Known issue
the ammo display will flicker due to client prediction. i have no idea how to fix this. to satisfy the condition, a client will need to think its reserve ammo is exactly 999, or the weapon's reserve ammo convar is -2. lying to them that the convars are of that value means their ammo display ignores m_iAmmo value, and always show 999 - which is an even bigger problem.

with my current understanding, i can't see how this issue can be avoided without client modification.

### ConVar
- `keep_magazine_ammo`
1 or 0, defaults to 1

# Changelog
### 1.0
- initial release
