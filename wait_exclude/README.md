per-player value of sv_allow_wait_command. If they have the right admin flag, they're allowed to use it. Otherwise it's blocked. 

this plugin disables the server side value of sv_allow_wait_command from having any effect

default adminflag is "p" (ADMFLAG_CUSTOM2). Change it with the wait_exclude_admin_flag convar. It can only be one flag. The convar value is the bit offset. For example, the default flag is 1 << 16, so the convar value is 16. Refer to admin.inc to see other flags 