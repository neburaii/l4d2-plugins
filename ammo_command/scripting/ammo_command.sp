#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hxlib>
#include <multicolors>

public Plugin myinfo =
{
	name = "Ammo Command",
	author = "Neburai",
	description = "provides sm_ammo command to check reserve ammo usage",
	version = "1.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/ammo_command"
};

public void OnPluginStart()
{
	LoadTranslations("ammo_command.phrases");

	RegConsoleCmd("sm_ammo", Command_Ammo,
		"Return usage of your weapon's reserve ammo. no args for equipped, or \
		the slot number (as they are on keyboard, 1 through 5)");
}

Action Command_Ammo(int iClient, int iArgs)
{
	int iWeapon;
	if (iArgs)
	{
		/** arg we expect is +1 from actual slot enums because that lines
		 * up with default keybinds on keyboard, which starts at 1. */
		int iSlot = GetCmdArgInt(1) - 1;

		if (iSlot < 0 || iSlot >= WeaponSlot_MAX)
			iWeapon = GetCurrentWeapon(iClient);
		else iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	}
	else iWeapon = GetCurrentWeapon(iClient);

	if (iWeapon == -1)
	{
		CReplyToCommand(iClient, "%t %t", "#tag_cmd_ammo", "#reply_fail");
		return Plugin_Handled;
	}

	int iTotal = GetMaxReserveAmmo(GetAmmoType(iWeapon));
	if (iTotal < 0)
	{
		CReplyToCommand(iClient, "%t %t", "#tag_cmd_ammo", "#reply_fail");
		return Plugin_Handled;
	}

	int iRemaining = GetReserveAmmo(iWeapon);
	int iPercent = RoundToCeil(
		(float(iRemaining) / float(iTotal)) * 100.0);

	CReplyToCommand(iClient, "%t %t", "#tag_cmd_ammo", "#reply_success",
		iRemaining, iTotal, iPercent);
	return Plugin_Handled;
}
