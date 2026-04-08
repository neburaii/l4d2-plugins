#pragma newdecls required
#pragma semicolon 1

#define CONFIG_COOKIES_CUSTOM	"data/cookies.txt"
#define CONFIG_COOKIES_DROP_IN	"data/cookies.d"
#define CONFIG_COOKIE_MENU		"data/cookie_menu.txt"

char g_sServerLang[MAX_LANGUAGE_CODE_LENGTH];

RegisteredCookie g_configCookie;
RegisteredDirectory g_configDirectory;
KeyValues g_hConfigInput = null;

enum ParserState
{
	ParserState_Skip,

	ParserState_LookingForRoot,
	ParserState_LookingForCookie,

	ParserState_ReadingCookie,
	ParserState_ReadingName,
	ParserState_ReadingDesc,

	ParserState_ReadingInput,
	ParserState_ReadingInputPhrase
};

ParserState g_parserState;
int g_iDirectoryParserIndex;

ArrayList g_hArray_ParserDepthData;
int g_iParserDepth;

ArrayList g_hArray_PhraseMaps;
InputPhrase g_inputPhrase;
char g_sInputPhraseSectionName[MAX_VALUE_LENGTH];

enum struct InputPhrase
{
	char defaultPhrase[MAX_LANGUAGE_CODE_LENGTH];
	StringMap phrase;

	void Init()
	{
		this.defaultPhrase = "";
		this.phrase = new StringMap();
	}

	void Destroy()
	{
		delete this.phrase;
	}

	StringMap Clone()
	{
		return this.phrase.Clone();
	}
}

void ParseConfigs()
{
	ScanCookieConfigs();
	ParseCookieMenuConfig();
}

/*************************
 * loading cookies config
 *************************/

void ScanCookieConfigs()
{
	char sPath[PLATFORM_MAX_PATH];
	g_hArray_ParserDepthData = new ArrayList();
	GetLanguageInfo(GetServerLanguage(), g_sServerLang, sizeof(g_sServerLang));

	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_COOKIES_CUSTOM);
	ParseCookieConfig(sPath);

	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_COOKIES_DROP_IN);
	DirectoryListing hDropInDir = OpenDirectory(sPath);

	if (hDropInDir != null)
	{
		char sFile[PLATFORM_MAX_PATH];
		FileType fileType;

		while (hDropInDir.GetNext(sFile, sizeof(sFile), fileType))
		{
			if (fileType != FileType_File) continue;

			BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_COOKIES_DROP_IN ... "/%s", sFile);
			ParseCookieConfig(sPath);
		}
	}

	delete g_hArray_ParserDepthData;
	if (g_hConfigInput != null) delete g_hConfigInput;
}

void ParseCookieConfig(const char[] sFile)
{
	if (!FileExists(sFile)) return;

	g_parserState = ParserState_LookingForRoot;
	g_iParserDepth = 0;
	g_hArray_ParserDepthData.Clear();

	SMCParser hParser = new SMCParser();
	hParser.OnEnterSection = SMCCookies_OnEnterSection_LookingForRoot;
	hParser.OnKeyValue = INVALID_FUNCTION;
	hParser.OnLeaveSection = SMCCookies_LeaveSection;

	hParser.ParseFile(sFile);
	delete hParser;
}

void ChangeCookieParserState(SMCParser hParser, ParserState newState)
{
	if (g_parserState == newState) return;

	switch (newState)
	{
		case ParserState_LookingForRoot:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_LookingForRoot;
			hParser.OnKeyValue = INVALID_FUNCTION;
			hParser.OnLeaveSection = SMCCookies_LeaveSection;
		}

		case ParserState_LookingForCookie:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_LookingForCookie;
			hParser.OnKeyValue = INVALID_FUNCTION;
			hParser.OnLeaveSection = SMCCookies_LeaveSection;
		}

		case ParserState_ReadingCookie:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_ReadingCookie;
			hParser.OnKeyValue = SMCCookies_OnKeyValue_ReadingCookie;
			hParser.OnLeaveSection = SMCCookies_LeaveSection;
		}

		case ParserState_ReadingName:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_Skip;
			hParser.OnKeyValue = SMCCookies_OnKeyValue_ReadingName;
			hParser.OnLeaveSection = SMCCookies_LeaveSection;
		}

		case ParserState_ReadingDesc:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_Skip;
			hParser.OnKeyValue = SMCCookies_OnKeyValue_ReadingDesc;
			hParser.OnLeaveSection = SMCCookies_LeaveSection;
		}

		case ParserState_ReadingInput:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_ReadingInput;
			hParser.OnKeyValue = SMCCookies_OnKeyValue_ReadingInput;
			hParser.OnLeaveSection = SMCCookies_OnLeaveSection_ReadingInput;
		}

		case ParserState_ReadingInputPhrase:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_Skip;
			hParser.OnKeyValue = SMCCookies_OnKeyValue_ReadingInputPhrase;
			hParser.OnLeaveSection = SMCCookies_LeaveSection;
		}

		case ParserState_Skip:
		{
			hParser.OnEnterSection = SMCCookies_OnEnterSection_Skip;
			hParser.OnKeyValue = INVALID_FUNCTION;
			hParser.OnLeaveSection = SMCCookies_LeaveSection;
		}
	}

	g_parserState = newState;
}

/** traverse sections */
SMCResult SMCCookies_EnterSection(SMCParser hParser, ParserState newState)
{
	g_hArray_ParserDepthData.Resize(g_iParserDepth + 1);
	g_hArray_ParserDepthData.Set(g_iParserDepth, g_parserState);
	g_iParserDepth++;

	ChangeCookieParserState(hParser, newState);
	return SMCParse_Continue;
}

SMCResult SMCCookies_LeaveSection(SMCParser hParser)
{
	g_iParserDepth--;
	ParserState newState = g_hArray_ParserDepthData.Get(g_iParserDepth);
	g_hArray_ParserDepthData.Resize(g_iParserDepth);

	if (g_parserState != newState)
	{
		switch (g_parserState)
		{
			case ParserState_ReadingInput:
				FinishReadingInput();

			case ParserState_ReadingCookie:
				FinishReadingCookie();

			case ParserState_ReadingInputPhrase:
				FinishReadingInputPhrase();
		}
	}

	ChangeCookieParserState(hParser, newState);
	return SMCParse_Continue;
}

SMCResult SMCCookies_OnEnterSection_LookingForRoot(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	if (strcmp(sName, "Cookies") != 0)
		return SMCCookies_EnterSection(hParser, ParserState_Skip);

	return SMCCookies_EnterSection(hParser, ParserState_LookingForCookie);
}

SMCResult SMCCookies_OnEnterSection_LookingForCookie(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	if (g_hMap_Cookies.ContainsKey(sName))
		return SMCCookies_EnterSection(hParser, ParserState_Skip);

	g_configCookie.Init(sName);
	return SMCCookies_EnterSection(hParser, ParserState_ReadingCookie);
}

SMCResult SMCCookies_OnEnterSection_ReadingCookie(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	if (strcmp(sName, "#name") == 0)
		return SMCCookies_EnterSection(hParser, ParserState_ReadingName);

	if (strcmp(sName, "#desc") == 0)
		return SMCCookies_EnterSection(hParser, ParserState_ReadingDesc);

	if (strcmp(sName, "input") == 0)
	{
		g_hConfigInput = new KeyValues(sName);
		g_hArray_PhraseMaps = new ArrayList(sizeof(InputPhrase));

		return SMCCookies_EnterSection(hParser, ParserState_ReadingInput);
	}

	return SMCCookies_EnterSection(hParser, ParserState_Skip);
}

SMCResult SMCCookies_OnEnterSection_Skip(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	return SMCCookies_EnterSection(hParser, ParserState_Skip);
}

/** read data */

SMCResult SMCCookies_OnKeyValue_ReadingCookie(SMCParser hParser, const char[] sKey, const char[] sValue, bool bKeyQuotes, bool bValueQuotes)
{
	if (strcmp(sKey, "default_convar") == 0)
		strcopy(g_configCookie.defaultConVarName, sizeof(g_configCookie.defaultConVarName), sValue);

	return SMCParse_Continue;
}

SMCResult SMCCookies_OnKeyValue_ReadingName(SMCParser hParser, const char[] sKey, const char[] sValue, bool bKeyQuotes, bool bValueQuotes)
{
	if (g_configCookie.name.SetString(sKey, sValue))
	{
		if (!g_configCookie.defaultName[0])
			strcopy(g_configCookie.defaultName, sizeof(g_configCookie.defaultName), sKey);
	}

	return SMCParse_Continue;
}

SMCResult SMCCookies_OnKeyValue_ReadingDesc(SMCParser hParser, const char[] sKey, const char[] sValue, bool bKeyQuotes, bool bValueQuotes)
{
	if (g_configCookie.desc.SetString(sKey, sValue))
	{
		if (!g_configCookie.defaultDesc[0])
			strcopy(g_configCookie.defaultDesc, sizeof(g_configCookie.defaultDesc), sKey);
	}

	return SMCParse_Continue;
}

SMCResult SMCCookies_OnKeyValue_ReadingInputPhrase(SMCParser hParser, const char[] sKey, const char[] sValue, bool bKeyQuotes, bool bValueQuotes)
{
	if (g_inputPhrase.phrase.SetString(sKey, sValue))
	{
		if (!g_inputPhrase.defaultPhrase[0])
			strcopy(g_inputPhrase.defaultPhrase, sizeof(g_inputPhrase.defaultPhrase), sKey);
	}

	return SMCParse_Continue;
}

SMCResult SMCCookies_OnEnterSection_ReadingInput(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	if (sName[0] == '#')
	{
		g_inputPhrase.Init();
		strcopy(g_sInputPhraseSectionName, sizeof(g_sInputPhraseSectionName), sName);

		return SMCCookies_EnterSection(hParser, ParserState_ReadingInputPhrase);
	}

	g_hConfigInput.JumpToKey(sName, true);
	return SMCCookies_EnterSection(hParser, ParserState_ReadingInput);
}

SMCResult SMCCookies_OnKeyValue_ReadingInput(SMCParser hParser, const char[] sKey, const char[] sValue, bool bKeyQuotes, bool bValueQuotes)
{
	g_hConfigInput.SetString(sKey, sValue);
	return SMCParse_Continue;
}

SMCResult SMCCookies_OnLeaveSection_ReadingInput(SMCParser hParser)
{
	g_hConfigInput.GoBack();
	return SMCCookies_LeaveSection(hParser);
}

/** conclude reading data */

void FinishReadingCookie()
{
	/** defaults for name/desc is set on the first found keyvalue. empty strings mean
	 * there were none. we leave default as it is unless the server's language exists
	 * as a key */

	if (g_configCookie.defaultName[0])
	{
		if (g_configCookie.name.ContainsKey(g_sServerLang))
			strcopy(g_configCookie.defaultName, sizeof(g_configCookie.defaultName), g_sServerLang);
	}

	if (g_configCookie.defaultDesc[0])
	{
		if (g_configCookie.desc.ContainsKey(g_sServerLang))
			strcopy(g_configCookie.defaultDesc, sizeof(g_configCookie.defaultDesc), g_sServerLang);
	}

	if (IsCookieConstructed())
	{
		g_hMap_Cookies.SetValue(g_configCookie.cookie, g_hArray_Cookies.Length);
		g_hArray_Cookies.PushArray(g_configCookie);
	}
	else
		g_configCookie.Destroy();
}

bool IsCookieConstructed()
{
	if (!g_configCookie.defaultName[0])
		return false;
	if (g_configCookie.input == Input_None)
		return false;

	return true;
}

void FinishReadingInputPhrase()
{
	if (g_inputPhrase.defaultPhrase[0])
	{
		if (g_inputPhrase.phrase.ContainsKey(g_sServerLang))
			strcopy(g_inputPhrase.defaultPhrase, sizeof(g_inputPhrase.defaultPhrase), g_sServerLang);
	}

	int iIndex = g_hArray_PhraseMaps.PushArray(g_inputPhrase);
	g_hConfigInput.SetNum(g_sInputPhraseSectionName, iIndex);
}

void FinishReadingInput()
{
	g_hConfigInput.Rewind();

	char sBuffer[MAX_VALUE_LENGTH];
	InputPhrase phrase;

	g_hConfigInput.GetString("type", sBuffer, sizeof(sBuffer));
	if (!GetInputType(sBuffer, g_configCookie.input))
		return;

	/** only have cases for inputs that have more than just a "type" */
	switch (g_configCookie.input)
	{
		case Input_Text2:
		{
			InputData_Text2 text2;
			text2.defaultPrompt[0] = '\0';
			DataPack hInputData = new DataPack();

			int iIndex;
			if ((iIndex = g_hConfigInput.GetNum("#prompt", -1)) != -1)
			{
				g_hArray_PhraseMaps.GetArray(iIndex, phrase);

				if (phrase.defaultPhrase[0])
				{
					strcopy(text2.defaultPrompt, sizeof(text2.defaultPrompt), phrase.defaultPhrase);
					text2.prompt = phrase.Clone();
				}
			}

			/** is input data invalid */
			if (text2.defaultPrompt[0] == '\0')
			{
				g_configCookie.input = Input_None;
				delete hInputData;
			}
			else
			{
				hInputData.WriteCellArray(text2, sizeof(text2));
				hInputData.Reset();
				g_configCookie.inputData = hInputData;
			}
		}

		case Input_MultipleChoice:
		{
			InputData_MultipleChoice choice;
			ArrayList hInputData = new ArrayList(sizeof(InputData_MultipleChoice));
			int iIndex;

			for (int i = 1;; i++)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%i", i);
				if (!g_hConfigInput.JumpToKey(sBuffer))
					break;

				choice.defaultName[0] = '\0';

				if ((iIndex = g_hConfigInput.GetNum("#name", -1)) != -1)
				{
					g_hArray_PhraseMaps.GetArray(iIndex, phrase);

					if (phrase.defaultPhrase[0])
					{
						strcopy(choice.defaultName, sizeof(choice.defaultName), phrase.defaultPhrase);
						choice.name = phrase.Clone();
					}
				}

				g_hConfigInput.GetString("value", sBuffer, sizeof(sBuffer));
				strcopy(choice.value, sizeof(choice.value), sBuffer);

				/** is input data invalid */
				if (choice.defaultName[0] == '\0'
					|| choice.value[0] == '\0')
				{
					g_configCookie.input = Input_None;

					for (int c = 0; c < hInputData.Length; c++)
					{
						hInputData.GetArray(c, choice);
						delete choice.name;
					}

					delete hInputData;
					break;
				}

				g_hConfigInput.Rewind();
				hInputData.PushArray(choice);
			}

			if (g_configCookie.input != Input_None)
				g_configCookie.inputData = hInputData;
		}

		case Input_Slider:
		{
			InputData_Slider slider;
			DataPack hInputData = new DataPack();

			g_hConfigInput.GetString("min", sBuffer, sizeof(sBuffer));
			slider.SetMin(sBuffer);

			g_hConfigInput.GetString("max", sBuffer, sizeof(sBuffer));
			slider.SetMax(sBuffer);

			g_hConfigInput.GetString("step", sBuffer, sizeof(sBuffer));
			slider.SetStep(sBuffer);

			/** is input data invalid */
			if (slider.min == slider.max
				|| slider.min > slider.max
				|| slider.max < slider.min
				|| slider.step <= 0.0
				|| slider.step > (slider.max - slider.min))
			{
				g_configCookie.input = Input_None;
				delete hInputData;
			}
			else
			{
				hInputData.WriteCellArray(slider, sizeof(slider));
				hInputData.Reset();
				g_configCookie.inputData = hInputData;
			}
		}
	}

	for (int i = 0; i < g_hArray_PhraseMaps.Length; i++)
	{
		g_hArray_PhraseMaps.GetArray(i, phrase);
		phrase.Destroy();
	}

	delete g_hConfigInput;
	delete g_hArray_PhraseMaps;
}

/*****************************
 * loading cookie menu config
 ****************************/

void ParseCookieMenuConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_COOKIE_MENU);
	if (!FileExists(sPath)) return;

	g_hArray_ParserDepthData = new ArrayList();
	g_iParserDepth = 0;
	g_iDirectoryParserIndex = INVALID_DIRECTORY;

	SMCParser hParser = new SMCParser();
	hParser.OnEnterSection = SMCDirectory_OnEnterSection_Root;
	hParser.OnKeyValue = INVALID_FUNCTION;
	hParser.OnLeaveSection = SMCDirectory_LeaveSection;

	hParser.ParseFile(sPath);

	delete g_hArray_ParserDepthData;
	delete hParser;
}

SMCResult SMCDirectory_EnterSection(const char[] sNewName, bool bSkip = false)
{
	g_hArray_ParserDepthData.Resize(g_iParserDepth + 1);
	g_hArray_ParserDepthData.Set(g_iParserDepth, g_iDirectoryParserIndex);
	g_iParserDepth++;

	int iNewIndex = bSkip ? INVALID_DIRECTORY : g_hArray_Directories.Length;

	if (g_iDirectoryParserIndex != INVALID_DIRECTORY)
	{
		if (!bSkip) g_configDirectory.subdirectories.Push(iNewIndex);
		g_hArray_Directories.SetArray(g_iDirectoryParserIndex, g_configDirectory);
	}

	if (!bSkip)
	{
		g_hArray_Directories.Resize(iNewIndex + 1);
		g_configDirectory.Init(g_iDirectoryParserIndex, sNewName);
	}
	g_iDirectoryParserIndex = iNewIndex;

	return SMCParse_Continue;
}

SMCResult SMCDirectory_OnEnterSection_Root(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	hParser.OnEnterSection = SMCMenu_OnEnterSection;
	hParser.OnKeyValue = SMCMenu_OnKeyValue;

	return SMCDirectory_EnterSection("");
}

SMCResult SMCMenu_OnEnterSection(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	if (g_iDirectoryParserIndex == INVALID_DIRECTORY || sName[0] == '\0')
		return SMCDirectory_EnterSection("", true);
	else
		return SMCDirectory_EnterSection(sName);
}

SMCResult SMCDirectory_LeaveSection(SMCParser hParser)
{
	g_iParserDepth--;
	int iNewIndex = g_hArray_ParserDepthData.Get(g_iParserDepth);
	g_hArray_ParserDepthData.Resize(g_iParserDepth);

	if (g_iDirectoryParserIndex != INVALID_DIRECTORY)
	{
		if (g_configDirectory.subdirectories.Length == 0
			&& g_configDirectory.cookies.Length == 0
			&& g_configDirectory.special == Special_None)
		{
			if (g_configDirectory.parent != INVALID_DIRECTORY)
			{
				RegisteredDirectory parent;
				g_hArray_Directories.GetArray(g_configDirectory.parent, parent);

				int iChild;
				for (int i = 0; i < parent.subdirectories.Length; i++)
				{
					iChild = parent.subdirectories.Get(i);
					if (iChild == g_iDirectoryParserIndex)
					{
						parent.subdirectories.Erase(i);
						break;
					}
				}
			}

			g_configDirectory.Destroy();
			g_hArray_Directories.Erase(g_iDirectoryParserIndex);
		}
		else
		{
			g_hArray_Directories.SetArray(g_iDirectoryParserIndex, g_configDirectory);
		}
	}

	g_iDirectoryParserIndex = iNewIndex;
	if (g_iDirectoryParserIndex != INVALID_DIRECTORY)
		g_hArray_Directories.GetArray(g_iDirectoryParserIndex, g_configDirectory);

	/** there can only be 1 root */
	if (g_iParserDepth == 0)
		return SMCParse_Halt;

	return SMCParse_Continue;
}

SMCResult SMCMenu_OnKeyValue(SMCParser hParser, const char[] sKey, const char[] sValue, bool bKeyQuotes, bool bValueQuotes)
{
	if (g_iDirectoryParserIndex == INVALID_DIRECTORY)
		return SMCParse_Continue;

	if (strcmp(sKey, "translate") == 0)
		g_configDirectory.nameIsPhrase = StringToBool(sValue);

	else if (strcmp(sKey, "cookie") == 0 && sValue[0])
	{
		/** copy to truncate longer strings */
		char sCookie[COOKIE_MAX_NAME_LENGTH];
		strcopy(sCookie, sizeof(sCookie), sValue);

		int iCookieIndex;
		bool bValidCookie;

		bValidCookie = g_hMap_Cookies.GetValue(sCookie, iCookieIndex);
		if (!bValidCookie) bValidCookie = FindAndRegisterUndefinedCookie(sCookie, iCookieIndex);

		if (bValidCookie)
		{
			g_hMap_CookiesInDirectory.SetValue(sCookie, iCookieIndex, false);
			g_configDirectory.cookies.Push(iCookieIndex);
		}
	}

	else if (strcmp(sKey, "special") == 0)
	{
		SpecialType flag;
		if (g_hMap_SpecialTypes.GetValue(sValue, flag))
			g_configDirectory.special |= flag;
	}

	return SMCParse_Continue;
}

/**
 * this will auto-create one with generic text input type,
 * and use the name/description from clientprefs (if found).
 */
bool FindAndRegisterUndefinedCookie(const char sCookie[COOKIE_MAX_NAME_LENGTH], int &iIndex)
{
	Cookie hCookie = FindClientCookie(sCookie);
	if (FindClientCookie(sCookie) == null)
		return false;

	if (hCookie.AccessLevel != CookieAccess_Public)
	{
		delete hCookie;
		return false;
	}
	delete hCookie;

	g_configCookie.Init(sCookie);
	if (!g_configCookie.name.SetString("en", sCookie))
	{
		g_configCookie.Destroy();
		return false;
	}

	g_configCookie.defaultName = "en";

	Handle hIterator = GetCookieIterator();
	char sBufferName[COOKIE_MAX_NAME_LENGTH];
	char sBufferDesc[COOKIE_MAX_DESCRIPTION_LENGTH];
	bool bFound;
	CookieAccess access;

	while (ReadCookieIterator(hIterator, sBufferName, sizeof(sBufferName), access, sBufferDesc, sizeof(sBufferDesc)))
	{
		if (access != CookieAccess_Public || strcmp(sCookie, sBufferName) != 0)
			continue;

		bFound = true;
		break;
	}

	delete hIterator;

	if (bFound)
	{
		iIndex = RegisterUndefinedCookie(sCookie, sBufferDesc);
		return iIndex != -1;
	}

	g_configCookie.Destroy();
	return false;
}

/*********
 * helpers
 *********/

bool StringToBool(const char[] sString)
{
	bool bValue;
	if (strcmp(sString, "true") == 0) bValue = true;

	return bValue;
}

bool GetInputType(const char[] sKey, InputType &result)
{
	if (!g_hMap_InputTypes.GetValue(sKey, result))
	{
		result = Input_None;
		return false;
	}

	return true;
}
