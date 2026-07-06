#pragma newdecls required
#pragma semicolon 1

Action Command_ResetRegistries(int iClient, int iArgs)
{
	ResetRegistries();
	return Plugin_Handled;
}

Action Command_Settings(int iClient, int iArgs)
{
	CmdOpenMenuRoot(iClient);
	return Plugin_Handled;
}

Action Command_Set(int iClient, int iArgs)
{
	switch (iArgs)
	{
		case 0: CmdOpenMenuRoot(iClient);
		case 1: CmdSearchCookies(iClient);
		case 2: CmdSetCookie(iClient, "#tag_cmd_set");
		default: CmdSetCookieFromMultiArg(iClient, "#tag_cmd_set");
	}

	return Plugin_Handled;
}

Action Command_Cookies(int iClient, int iArgs)
{
	switch (iArgs)
	{
		case 0: PrintCookiesToConsole(iClient, "#tag_cmd_cookies");
		case 1: CmdPrintCookieValue(iClient, "#tag_cmd_cookies");
		case 2: CmdSetCookie(iClient, "#tag_cmd_cookies");
		default: CmdSetCookieFromMultiArg(iClient, "#tag_cmd_cookies");
	}

	return Plugin_Handled;
}

void CmdOpenMenuRoot(int iClient)
{
	if (!iClient)
	{
		ReplyToCommand(iClient, "%t", "#error_cmd_not_from_client");
		return;
	}

	g_clientPanel[iClient].OpenNew(Panel_Directory, 0);
}

void CmdSearchCookies(int iClient)
{
	if (!iClient)
	{
		ReplyToCommand(iClient, "%t", "#error_cmd_not_from_client");
		return;
	}

	char sQuery[COOKIE_MAX_NAME_LENGTH];
	GetCmdArg(1, sQuery, sizeof(sQuery));
	int iCookieRef = BuildSearchResults(g_clientPanel[iClient].special, sQuery);

	if (iCookieRef >= 0)
		g_clientPanel[iClient].OpenNew(Panel_Cookie, iCookieRef);
	else g_clientPanel[iClient].OpenNew(Panel_Special, Special_Search);
}

void CmdSetCookie(int iClient, const char[] sTag)
{
	if (!iClient)
	{
		ReplyToCommand(iClient, "%t", "#error_cmd_not_from_client");
		return;
	}

	static char sCookieName[COOKIE_MAX_NAME_LENGTH];
	int iRef;
	GetCmdArg(1, sCookieName, sizeof(sCookieName));

	if (!g_hMap_Cookies.GetValue(sCookieName, iRef) && !FindAndRegisterUndefinedCookie(sCookieName, iRef))
	{
		CReplyToCommand(iClient, "%t %t", sTag, "#error_cookie_not_found", sCookieName);
		return;
	}

	RegisteredCookie cookie;
	g_hArray_Cookies.GetArray(iRef, cookie);
	if (!cookie.Exists())
	{
		CReplyToCommand(iClient, "%t %t", sTag, "#error_cookie_not_found", sCookieName);
		return;
	}

	static char sCookieValue[100];
	GetCmdArg(2, sCookieValue, sizeof(sCookieValue));

	cookie.SetString(iClient, sCookieValue);
	CReplyToCommand(iClient, "%t %t", sTag, "#cmd_set_success", sCookieName, sCookieValue);
}

void CmdSetCookieFromMultiArg(int iClient, const char[] sTag)
{
	static char sArgs[250];
	int iRead;

	GetCmdArgString(sArgs, sizeof(sArgs));

	static char sCookieName[COOKIE_MAX_NAME_LENGTH];
	int iRef;
	iRead = GetNextToken(sArgs, 0, sCookieName, sizeof(sCookieName));

	if (!g_hMap_Cookies.GetValue(sCookieName, iRef) && !FindAndRegisterUndefinedCookie(sCookieName, iRef))
	{
		CReplyToCommand(iClient, "%t %t", sTag, "#error_cookie_not_found", sCookieName);
		return;
	}

	RegisteredCookie cookie;
	g_hArray_Cookies.GetArray(iRef, cookie);
	if (!cookie.Exists())
	{
		CReplyToCommand(iClient, "%t %t", sTag, "#error_cookie_not_found", sCookieName);
		return;
	}

	static char sCookieValue[100];
	bool bCheckLeadingWhitespace = true;
	int iWrite = 0;

	for (; iRead < sizeof(sArgs); iRead++)
	{
		if (bCheckLeadingWhitespace)
		{
			if (IsCharSpace(sArgs[iRead]))
				continue;

			bCheckLeadingWhitespace = false;
		}

		sCookieValue[iWrite++] = sArgs[iRead];
		if (iWrite == sizeof(sCookieValue))
		{
			sCookieValue[iWrite - 1] = '\0';
			break;
		}

		if (sArgs[iRead] == '\0')
			break;
	}

	cookie.SetString(iClient, sCookieValue);
	CReplyToCommand(iClient, "%t %t", sTag, "#cmd_set_success", sCookieName, sCookieValue);
}

int GetNextToken(const char[] sReadFrom, int iStartFrom, char[] sWriteTo, int iWriteMax)
{
	int iWrite = 0;

	if (sReadFrom[0] == '\"')
	{
		for (int i = iStartFrom; i < 250; i++)
		{
			if (sReadFrom[i] == '\"' || sReadFrom[i] == '\0')
			{
				sReadFrom[iWrite] = '\0';
				return iWrite;
			}

			sWriteTo[iWrite++] = sReadFrom[i];
			if (iWrite == iWriteMax)
			{
				sReadFrom[iWrite - 1] = '\0';
				return iWriteMax;
			}
		}
	}

	for (int i = iStartFrom; i < 250; i++)
	{
		if (sReadFrom[i] == '\"' || sReadFrom[i] <= ' ')
			break;

		sWriteTo[iWrite++] = sReadFrom[i];
		if (iWrite == iWriteMax)
		{
			sReadFrom[iWrite - 1] = '\0';
			return iWriteMax;
		}
	}

	sWriteTo[iWrite] = '\0';
	return iWrite;
}

void CmdPrintCookieValue(int iClient, const char[] sTag)
{
	if (!iClient)
	{
		ReplyToCommand(iClient, "%t", "#error_cmd_not_from_client");
		return;
	}

	char sInternalName[COOKIE_MAX_NAME_LENGTH];
	GetCmdArg(1, sInternalName, sizeof(sInternalName));

	Cookie hCookie = FindClientCookie(sInternalName);
	if (hCookie == null)
	{
		CReplyToCommand(iClient, "%t %t", sTag, "#error_cookie_not_found", sInternalName);
		return;
	}

	if (hCookie.AccessLevel == CookieAccess_Private)
	{
		CReplyToCommand(iClient, "%t %t", sTag, "#error_cookie_not_found", sInternalName);
		delete hCookie;
		return;
	}

	char sDisplayName[MAX_ROW_LENGTH];
	char sDescription[COOKIE_MAX_DESCRIPTION_LENGTH];

	int iRef;
	if (g_hMap_Cookies.GetValue(sInternalName, iRef))
	{
		RegisteredCookie cookie;
		g_hArray_Cookies.GetArray(iRef, cookie);
		cookie.GetName(sDisplayName, sizeof(sDisplayName), iClient);
		cookie.GetDescription(sDescription, sizeof(sDescription), iClient);
	}
	else
	{
		Handle hIterator = GetCookieIterator();
		CookieAccess access;
		char sBufferName[COOKIE_MAX_NAME_LENGTH];

		while (ReadCookieIterator(hIterator, sBufferName, sizeof(sBufferName), access, sDescription, sizeof(sDescription)))
		{
			sDescription[0] = '\0';

			if (access == CookieAccess_Private || strcmp(sBufferName, sInternalName) != 0)
				continue;

			if (access == CookieAccess_Public)
				RegisterUndefinedCookie(sInternalName, sDescription);

			break;
		}

		delete hIterator;
	}

	char sValue[100];
	hCookie.Get(iClient, sValue, sizeof(sValue));

	CReplyToCommand(iClient, "%t %t", sTag, "#cookie_value", sInternalName, sValue);

	if (sDisplayName[0] && strcmp(sDisplayName, sInternalName) != 0)
		CReplyToCommand(iClient, "	{olive}%s", sDisplayName);
	if (sDescription[0])
		ReplyToCommand(iClient, "	- %s", sDescription);

	delete hCookie;
}

void PrintCookiesToConsole(int iClient, const char[] sTag)
{
	if (iClient) CReplyToCommand(iClient, "%t %t", sTag, "#printing_cookie_list");

	RegisteredCookie cookie;
	int iRef;

	Handle hIterator = GetCookieIterator();
	CookieAccess access;
	int iCount = 1;

	char sInternalName[COOKIE_MAX_NAME_LENGTH];
	char sInternalDesc[COOKIE_MAX_DESCRIPTION_LENGTH];

	char sDisplayName[MAX_ROW_LENGTH + 1];
	char sDisplayDesc[MAX_VALUE_LENGTH + 1];

	PrintToConsole(iClient, "%t:", "#cookie_list_header");
	while (ReadCookieIterator(hIterator, sInternalName, sizeof(sInternalName), access, sInternalDesc, sizeof(sInternalDesc)))
	{
		if (access == CookieAccess_Private)
			continue;

		if (!g_hMap_Cookies.GetValue(sInternalName, iRef))
		{
			iRef = -1;
			if (access == CookieAccess_Public)
				RegisterUndefinedCookie(sInternalName, sInternalDesc);
		}

		if (iRef >= 0)
		{
			g_hArray_Cookies.GetArray(iRef, cookie);
			cookie.GetName(sDisplayName, sizeof(sDisplayName), iClient);
			cookie.GetDescription(sDisplayDesc, sizeof(sDisplayDesc), iClient);

			if (strcmp(sDisplayName, sInternalName) != 0)
				PrintToConsole(iClient, "[%03i] %s (%s) - %s", iCount++, sInternalName, sDisplayName, sDisplayDesc[0] ? sDisplayDesc : sInternalDesc);
			else PrintToConsole(iClient, "[%03i] %s - %s", iCount++, sInternalName, sDisplayDesc[0] ? sDisplayDesc : sInternalDesc);
		}
		else PrintToConsole(iClient, "[%03i] %s - %s", iCount++, sInternalName, sInternalDesc);
	}

	delete hIterator;
}
