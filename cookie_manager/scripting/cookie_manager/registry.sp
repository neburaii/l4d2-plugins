#pragma newdecls required
#pragma semicolon 1

char g_sInputType[][] =
{
	"Input_None",

	"Input_Text",				// text, with a default prompt asking for user to type a message
	"Input_Text2",			// text, but with a custom prompt asking for user to type a message
	"Input_YesNo",			// bool value. true is displayed as "yes", and false as "no"
	"Input_OnOff",			// bool value. true is displayed as "on", and false as "off"
	"Input_MultipleChoice",	// choose value from selectable options in the panel.
	"Input_Slider"
};

enum struct RegisteredCookie
{
	char cookie[COOKIE_MAX_NAME_LENGTH];
	Cookie cookieHandle;

	char defaultConVarName[CONVAR_MAX_NAME_LENGTH];
	ConVar defaultConVar;

	char defaultName[MAX_LANGUAGE_CODE_LENGTH];
	StringMap name;

	char defaultDesc[MAX_LANGUAGE_CODE_LENGTH];
	StringMap desc;

	InputType input;
	Handle inputData;

	PrivateForward fwd;

	void Print()
	{
		char sLang[MAX_LANGUAGE_CODE_LENGTH];
		char sBuffer[MAX_VALUE_LENGTH];

		DebugPrint("  cookie: %s", this.cookie);
		DebugPrint("  handle: %s (0x%X)", this.Exists() ? "exists" : "null", this.cookieHandle);
		DebugPrint("");
		DebugPrint("  default value convar: %s", this.defaultConVarName);
		DebugPrint("  handle: %s (0x%X)", this.DefaultExists() ? "exists" : "null", this.defaultConVar);
		DebugPrint("");
		DebugPrint("  names (default lang: %s):", this.defaultName);
		for (int i = 0; i < GetLanguageCount(); i++)
		{
			GetLanguageInfo(i, sLang, sizeof(sLang));
			if (this.name.GetString(sLang, sBuffer, sizeof(sBuffer)))
				DebugPrint("    %s: %s", sLang, sBuffer);
		}
		DebugPrint("");
		DebugPrint("  descriptions (default lang: %s | exists: %s):",
			this.defaultDesc, this.HasDescription() ? "yes" : "no");
		for (int i = 0; i < GetLanguageCount(); i++)
		{
			GetLanguageInfo(i, sLang, sizeof(sLang));
			if (this.desc.GetString(sLang, sBuffer, sizeof(sBuffer)))
				DebugPrint("    %s: %s", sLang, sBuffer);
		}

		DebugPrint("  input (%s):", g_sInputType[this.input + view_as<InputType>(1)]);

		switch (this.input)
		{
			case Input_Text2:
			{
				InputData_Text2 text2;
				this.GetInput_Text2(text2);
				text2.Print();
			}
			case Input_MultipleChoice:
			{
				ArrayList choices = view_as<ArrayList>(this.inputData);
				InputData_MultipleChoice choice;
				for (int i = 0; i < choices.Length; i++)
				{
					DebugPrint("    choice %i:", i);
					choices.GetArray(i, choice);
					choice.Print();
				}
			}
			case Input_Slider:
			{
				InputData_Slider slider;
				view_as<DataPack>(this.inputData).ReadCellArray(slider, sizeof(InputData_Slider));
				view_as<DataPack>(this.inputData).Reset();

				slider.Print();
			}
		}
	}

	void Init(const char[] sCookie)
	{
		strcopy(this.cookie, sizeof(this.cookie), sCookie);
		this.cookieHandle = null;
		this.defaultConVarName = "";
		this.defaultConVar = null;
		this.defaultName = "";
		this.name = new StringMap();
		this.defaultDesc = "";
		this.desc = new StringMap();
		this.input = Input_Text;
		this.inputData = null;
		this.fwd = null;
	}

	void Destroy()
	{
		delete this.name;
		delete this.desc;

		if (this.inputData != null)
			delete this.inputData;
	}

	bool Exists()
	{
		if (this.cookieHandle == null)
			this.cookieHandle = FindClientCookie(this.cookie);

		return this.cookieHandle != null;
	}

	bool HasDescription()
	{
		return this.defaultDesc[0] != '\0';
	}

	int GetName(char[] sBuffer, int iBufferLen, int iTranslateTarget)
	{
		return GetCookiePhrase(sBuffer, iBufferLen, iTranslateTarget, this.name, this.defaultName);
	}

	int GetDescription(char[] sBuffer, int iBufferLen, int iTranslateTarget)
	{
		if (!this.HasDescription())
		{
			sBuffer[0] = '\0';
			return 0;
		}

		return GetCookiePhrase(sBuffer, iBufferLen, iTranslateTarget, this.desc, this.defaultDesc);
	}

	void GetInput_Text2(InputData_Text2 text2)
	{
		view_as<DataPack>(this.inputData).ReadCellArray(text2, sizeof(InputData_Text2));
		view_as<DataPack>(this.inputData).Reset();
	}

	/**
	 * get all data required to display the slider panel:
	 * 1. the slider struct
	 * 2. cookie's current float value
	 * 3. precision (total fractional digits minus trailing zeros) of float value
	 *
	 * returned data will be modified if invalid (like clamping to min/max)
	 *
	 * @param iClient	client to get cooke value of
	 * @param slider	output slider struct to this
	 * @param precision	output precision to this
	 *
	 * @return			float value of cookie for iClient
	 */
	float GetInput_Slider(int iClient, InputData_Slider slider, char[] sDisplayValue, int iDisplayValueLen)
	{
		view_as<DataPack>(this.inputData).ReadCellArray(slider, sizeof(InputData_Slider));
		view_as<DataPack>(this.inputData).Reset();

		this.Get(iClient, sDisplayValue, iDisplayValueLen);
		float fResult;

		int iSize = StringToFloatEx(sDisplayValue, fResult);
		if (!iSize) fResult = this.GetDefaultFloat();

		if (fResult < slider.min)
			fResult = slider.min;
		else if (fResult > slider.max)
			fResult = slider.max;

		/** intended as an integer */
		if (!slider.precision)
		{
			fResult -= FloatFraction(fResult);

			for (int i = 0; i < iSize; i++)
			{
				if (sDisplayValue[i] == '.')
				{
					sDisplayValue[i] = '\0';
					break;
				}
			}

			return fResult;
		}

		int iPrecision = 0;
		bool bReadingFractional = false;
		int iTrailingZeros = 0;
		int iDotPos;

		for (int i = 0; i < iSize; i++)
		{
			if (!bReadingFractional)
			{
				if (sDisplayValue[i] == '.')
				{
					iDotPos = i;
					bReadingFractional = true;
				}
				continue;
			}

			if (sDisplayValue[i] == '0')
				iTrailingZeros++;
			else iTrailingZeros = 0;

			iPrecision++;
		}

		iPrecision -= iTrailingZeros;
		if (slider.precision > iPrecision)
			iPrecision = slider.precision;

		sDisplayValue[iDotPos + 1 + iPrecision] = '\0';
		return fResult;
	}

	float GetDefaultFloat()
	{
		return this.DefaultExists() ? this.defaultConVar.FloatValue : 0.0;
	}

	bool DefaultExists()
	{
		if (this.defaultConVarName[0] == '\0')
			return false;

		if (this.defaultConVar == null)
		{
			this.defaultConVar = FindConVar(this.defaultConVarName);
			return this.defaultConVar != null;
		}

		return true;

	}

	void Get(int iClient, char[] sBuffer, int iBufferLen)
	{
		this.cookieHandle.Get(iClient, sBuffer, iBufferLen);

		if (sBuffer[0] == '\0' && this.DefaultExists())
			this.defaultConVar.GetString(sBuffer, iBufferLen);
	}

	int GetInt(int iClient, int iDefaultValue = 0)
	{
		char sBuffer[12];
		this.Get(iClient, sBuffer, sizeof(sBuffer));

		int iValue;
		if (!StringToIntEx(sBuffer, iValue))
			iValue = iDefaultValue;

		return iValue;
	}

	void Set(int iClient, const char[] sNewValue)
	{
		static char sOldValue[100];
		this.cookieHandle.Get(iClient, sOldValue, sizeof(sOldValue));

		if (strcmp(sNewValue, sOldValue) == 0)
			return;

		this.cookieHandle.Set(iClient, sNewValue);

		if (this.fwd == null && !g_hMap_Forwards.GetValue(this.cookie, this.fwd))
			return;

		Call_StartForward(this.fwd);
		Call_PushString(this.cookie);
		Call_PushCell(iClient);
		Call_PushString(sOldValue);
		Call_PushString(sNewValue);
		Call_Finish();
	}

	void SetString(int iClient, const char[] sValue)
	{
		this.Set(iClient, sValue);
	}

	void SetInt(int iClient, int iValue)
	{
		static char sValue[12];
		IntToString(iValue, sValue, sizeof(sValue));

		this.Set(iClient, sValue);

	}

	void SetFloat(int iClient, float fValue)
	{
		static char sValue[32];
		FloatToString(fValue, sValue, sizeof(sValue));

		this.Set(iClient, sValue);
	}
}

enum struct InputData_Text2
{
	char defaultPrompt[MAX_LANGUAGE_CODE_LENGTH];
	StringMap prompt;

	void Print()
	{
		char sLang[MAX_LANGUAGE_CODE_LENGTH];
		char sBuffer[MAX_VALUE_LENGTH];

		DebugPrint("    prompt (default lang: %s):", this.defaultPrompt);
		for (int i = 0; i < GetLanguageCount(); i++)
		{
			GetLanguageInfo(i, sLang, sizeof(sLang));
			if (this.prompt.GetString(sLang, sBuffer, sizeof(sBuffer)))
				DebugPrint("      %s: %s", sLang, sBuffer);
		}
	}

	int GetPrompt(char[] sBuffer, int iBufferLen, int iTranslateTarget)
	{
		return GetCookiePhrase(sBuffer, iBufferLen, iTranslateTarget, this.prompt, this.defaultPrompt);
	}
}

enum struct InputData_MultipleChoice
{
	char defaultName[MAX_LANGUAGE_CODE_LENGTH];
	StringMap name;
	char value[MAX_VALUE_LENGTH];

	void Print()
	{
		char sLang[MAX_LANGUAGE_CODE_LENGTH];
		char sBuffer[MAX_VALUE_LENGTH];

		DebugPrint("      name (default lang: %s):", this.defaultName);
		for (int i = 0; i < GetLanguageCount(); i++)
		{
			GetLanguageInfo(i, sLang, sizeof(sLang));
			if (this.name.GetString(sLang, sBuffer, sizeof(sBuffer)))
				DebugPrint("        %s: %s", sLang, sBuffer);
		}
		DebugPrint("      value: %s", this.value);
	}

	int GetName(char[] sBuffer, int iBufferLen, int iTranslateTarget)
	{
		return GetCookiePhrase(sBuffer, iBufferLen, iTranslateTarget, this.name, this.defaultName);
	}
}

enum struct InputData_Slider
{
	float min;
	float max;
	float step;

	int precision;

	void Print()
	{
		DebugPrint("    min: %f", this.min);
		DebugPrint("    max: %f", this.max);
		DebugPrint("    step: %f", this.step);
		DebugPrint("    precision: %i", this.precision);
	}

	int SetMin(const char[] sValue)
	{
		return this.SetPrivate(sValue, this.min);
	}

	int SetMax(const char[] sValue)
	{
		return this.SetPrivate(sValue, this.max);
	}

	int SetStep(const char[] sValue)
	{
		return this.SetPrivate(sValue, this.step);
	}

	int SetPrivate(const char[] sValue, float &output)
	{
		int iSize = StringToFloatEx(sValue, output);
		int iPrecision = 0;
		bool bReadingFractional = false;

		for (int i = 0; i < iSize; i++)
		{
			if (!bReadingFractional)
			{
				if (sValue[i] == '.')
					bReadingFractional = true;
				continue;
			}

			iPrecision++;
		}

		if (iPrecision > this.precision)
			this.precision = iPrecision;

		return iSize;
	}
}

enum struct RegisteredDirectory
{
	int parent;
	ArrayList subdirectories;
	ArrayList cookies;
	SpecialType special;

	bool nameIsPhrase;
	char name[MAX_ROW_LENGTH + 1];

	void Print()
	{
		DebugPrint("  parent: %i", this.parent);
		DebugPrint("  subdirectories (%i):", this.subdirectories.Length);
		for (int i = 0; i < this.subdirectories.Length; i++)
			DebugPrint("    [%i] ref %i", i, this.subdirectories.Get(i));
		DebugPrint("  cookies (%i):", this.cookies.Length);
		for (int i = 0; i < this.cookies.Length; i++)
			DebugPrint("    [%i] ref %i", i, this.cookies.Get(i));
		DebugPrint("");
		DebugPrint("  name%s: %s", this.nameIsPhrase ? " (phrase)" : "", this.name);
	}

	void Init(int iParent, const char[] sName)
	{
		this.parent = iParent;
		strcopy(this.name, sizeof(this.name), sName);

		this.nameIsPhrase = false;
		this.subdirectories = new ArrayList();
		this.cookies = new ArrayList();
		this.special = Special_None;
	}

	void Destroy()
	{
		delete this.subdirectories;
		delete this.cookies;
	}

	bool ExceedsMax(int iMax)
	{
		return (this.subdirectories.Length + this.cookies.Length) > iMax;
	}

	void GetName(char[] sBuffer, int iBufferLen, int iTranslateTarget)
	{
		if (this.nameIsPhrase)
			FormatEx(sBuffer, iBufferLen, "%T", this.name, iTranslateTarget);
		else strcopy(sBuffer, iBufferLen, this.name);
	}

	/** total items this directory will draw to a panel */
	int GetItemAmount()
	{
		return this.subdirectories.Length + this.cookies.Length;
	}
}

int GetCookiePhrase(char[] sBuffer, int iBufferLen, int iTranslateTarget, StringMap phrases, char sDefaultPhrase[MAX_LANGUAGE_CODE_LENGTH])
{
	static char sLangCode[MAX_LANGUAGE_CODE_LENGTH];
	bool bUseDefault = true;

	if (iTranslateTarget)
	{
		GetLanguageInfo(GetClientLanguage(iTranslateTarget), sLangCode, sizeof(sLangCode));

		if (phrases.ContainsKey(sLangCode))
			bUseDefault = false;
	}

	int iRet;
	phrases.GetString(bUseDefault ? sDefaultPhrase : sLangCode, sBuffer, iBufferLen, iRet);
	return iRet;
}

void ResetRegistries()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		g_clientPanel[i].Close();
	}

	RegisteredCookie cookie;
	RegisteredDirectory directory;
	for (int i = 0; i < g_hArray_Cookies.Length; i++)
	{
		g_hArray_Cookies.GetArray(i, cookie);
		cookie.Destroy();
	}
	for (int i = 0; i < g_hArray_Directories.Length; i++)
	{
		g_hArray_Directories.GetArray(i, directory);
		directory.Destroy();
	}
	delete g_hMap_Cookies;
	delete g_hMap_CookiesInDirectory;
	delete g_hArray_Cookies;
	delete g_hArray_Directories;

	g_hMap_Cookies = new StringMap();
	g_hMap_CookiesInDirectory = new StringMap();
	g_hArray_Cookies = new ArrayList(sizeof(RegisteredCookie));
	g_hArray_Directories = new ArrayList(sizeof(RegisteredDirectory));

	ParseConfigs();
	RegisterUndefinedCookies();
}

void RegisterUndefinedCookies()
{
	Handle hIterator = GetCookieIterator();
	char sBufferName[COOKIE_MAX_NAME_LENGTH];
	char sBufferDesc[COOKIE_MAX_DESCRIPTION_LENGTH];
	CookieAccess access;

	while (ReadCookieIterator(hIterator, sBufferName, sizeof(sBufferName), access, sBufferDesc, sizeof(sBufferDesc)))
	{
		if (access != CookieAccess_Public || g_hMap_Cookies.ContainsKey(sBufferName))
			continue;

		RegisterUndefinedCookie(sBufferName, sBufferDesc);
	}

	delete hIterator;
}

/**
 * @return		cookie ref. -1 on failure
 */
int RegisterUndefinedCookie(const char sName[COOKIE_MAX_NAME_LENGTH], const char sDesc[COOKIE_MAX_DESCRIPTION_LENGTH])
{
	static RegisteredCookie cookie;
	cookie.Init(sName);

	if (!cookie.name.SetString("en", sName))
	{
		cookie.Destroy();
		return -1;
	}
	cookie.defaultName = "en";

	if (cookie.desc.SetString("en", sDesc))
		cookie.defaultDesc = "en";

	int iCookieIndex = g_hArray_Cookies.PushArray(cookie);
	g_hMap_Cookies.SetValue(sName, iCookieIndex);

	return iCookieIndex;
}
