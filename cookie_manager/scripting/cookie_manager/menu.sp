#pragma newdecls required
#pragma semicolon 1

#define MAX_PANEL_KEYS			10
#define COOKIE_PANEL_TIMEOUT	60

#define SLIDER_BAR_LENGTH		20
#define SLIDER_BAR_LINE			"–"
#define SLIDER_BAR_TICK			"|"

#define PANEL_DIRECTORY_PREFIX	"▣"
#define PANEL_CURRENT_PREFIX	"▶"
#define PANEL_INDENT			"	"

#define RENDER_MAX_BUFFER_LEN	6

Handle g_hTimer_CookiePanelDuration[MAXPLAYERS_L4D2+1] = {null, ...};
StringMap g_hMap_CachedBottomSize;

enum
{
	Bottom_PrevNext,
	Bottom_Back,
	Bottom_Exit,

	Bottom_MAX
};

enum DrawType
{
	Draw_Spacer,
	Draw_Button,
	Draw_DisabledButton,
	Draw_Line,
	Draw_MultiLine
};

enum PanelType
{
	Panel_Directory,
	Panel_Cookie,
	Panel_SearchPrompt,
	Panel_Special
};

enum PanelAction
{
	Action_DoNothing,

	Action_OpenSearch,
	Action_OpenDirectory,
	Action_OpenCookie,
	Action_OpenSpecial,

	Action_SetCookieInt,
	Action_SelectCookieChoice,
	Action_SetCookieSlider,

	Action_PrevPage,
	Action_NextPage,
	Action_OpenOld,

	Action_Close
};

/** expand Panel methodmap to support indentation and word wrap */
methodmap CookiePanel < Panel
{
	public CookiePanel()
	{
		return view_as<CookiePanel>(CreatePanel());
	}

	public void DrawText(const char[] sText, bool bIndent = false)
	{
		if (!bIndent)
		{
			DrawPanelText(this, sText);
			return;
		}

		int iLen = strlen(sText);
		int iLineLen = sizeof(PANEL_INDENT) + iLen + 1;

		char[] sLine = new char[iLineLen];
		int iWrite = 0;

		iWrite += strcopy(sLine, iLineLen, PANEL_INDENT);

		for (int i = 0; i <= iLen; i++)
		{
			sLine[iWrite++] = sText[i];
			if (sText[i] == '\0')
				break;
		}

		DrawPanelText(this, sLine);
	}

	public void DrawMultiLineText(const char[] sText, bool bIndent = false)
	{
		char sLine[sizeof(PANEL_INDENT) + MAX_ROW_LENGTH + 1];

		int iStart = 0;
		int iCount;
		int iTerminator;
		int iOffset;

		for (;;)
		{
			iTerminator = 0;
			iOffset = 0;
			iCount = 0;

			if (bIndent)
			{
				iOffset = strcopy(sLine, sizeof(sLine), PANEL_INDENT);
				iCount += iOffset;
			}

			for (int i = iStart;; i++)
			{
				if (sText[i] == '\0')
				{
					iTerminator = iCount;
					break;
				}

				sLine[iCount] = sText[i];
				if (IsCharSpace(sLine[iCount]))
					iTerminator = iCount + 1;

				iCount++;
				if (iCount >= MAX_ROW_LENGTH)
				{
					if (!iTerminator) iTerminator = MAX_ROW_LENGTH;
					break;
				}
			}

			sLine[iTerminator] = '\0';
			DrawPanelText(this, sLine);

			iStart = iStart + (iTerminator - iOffset);

			if (sText[iStart] == '\0')
				return;
		}
	}
}

enum struct RenderBuffer
{
	char text[MAX_VALUE_LENGTH];
	DrawType type;

	PanelAction action;
	any data;
	bool indent;

	int size;

	void WriteSpacer()
	{
		this.type = Draw_Spacer;
		this.size = 2;
	}

	void WriteButton(const char[] sLabel, PanelAction action, any data)
	{
		this.type = Draw_Button;
		this.size =
			strcopy(this.text, sizeof(this.text), sLabel) + 1;
		this.action = action;
		this.data = data;
	}

	void WriteDisabledButton(const char[] sLabel)
	{
		this.type = Draw_DisabledButton;
		this.size =
			strcopy(this.text, sizeof(this.text), sLabel) + 1;
	}

	void WriteLine(const char[] sText, bool bIndent)
	{
		this.type = Draw_Line;
		this.size =
			strcopy(this.text, sizeof(this.text), sText) + 1;
		this.indent = bIndent;

		if (bIndent)
			this.size += sizeof(PANEL_INDENT);
	}

	void WriteMultiLine(const char[] sText, bool bIndent)
	{
		this.type = Draw_MultiLine;
		this.size = strcopy(this.text, sizeof(this.text), sText) + 1;
		this.indent = bIndent;

		int iLines = (this.size + MAX_ROW_LENGTH - 1) / MAX_ROW_LENGTH;
		this.size += iLines * (bIndent ? (sizeof(PANEL_INDENT) + 1) : 1);
	}
}

/** the `render` struct exists for organization. it's intended to be
 * used (Init to Send) in CookiePanelNavigator.Render() only. */
enum struct CookiePanelRenderer
{
	CookiePanel panel;

	int translateTarget;

	int items;
	int max;

	bool hasPrev;
	bool hasNext;
	bool hasParent;
	int skip;

	int bottomSize[Bottom_MAX];
	int reserved;

	RenderBuffer buffer[RENDER_MAX_BUFFER_LEN];
	int bufferLen;

	/** for re-use to avoid frequent allocation */
	char line[MAX_ROW_LENGTH + 1];
	char multiline[MAX_VALUE_LENGTH + 1];

	/***************
	 * Start/Finish
	 ***************/

	void Init(int iClient, int iPage, ArrayList hHistory, ArrayList hSkip)
	{
		this.panel = new CookiePanel();
		this.translateTarget = iClient;
		this.items = 0;
		this.max = MAX_PANEL_KEYS - 1;
		this.hasPrev = false;
		this.hasNext = false;
		this.hasParent = hHistory.Length > 0;

		this.InitBottomSize();
		this.reserved = this.bottomSize[this.hasParent ? Bottom_Back : Bottom_Exit];

		this.skip = 0;
		if (iPage > 0)
		{
			this.InitSkipAmount(hSkip);
			this.hasPrev = true;
			this.max -= 2;
			this.reserved += this.bottomSize[Bottom_PrevNext];
		}
	}

	void InitBottomSize()
	{
		static char sLang[MAX_LANGUAGE_CODE_LENGTH];
		static char sBuffer[MAX_ROW_LENGTH + 1];

		GetLanguageInfo(GetClientLanguage(this.translateTarget), sLang, sizeof(sLang));

		if (g_hMap_CachedBottomSize.GetArray(sLang, this.bottomSize, sizeof(this.bottomSize)))
			return;

		this.bottomSize[Bottom_PrevNext] =
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "#panel_prev_page", this.translateTarget) + 1;
		this.bottomSize[Bottom_PrevNext] +=
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "#panel_next_page", this.translateTarget) + 1;

		this.bottomSize[Bottom_Back] =
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "#panel_back", this.translateTarget) + 1;

		this.bottomSize[Bottom_Exit] =
			FormatEx(sBuffer, sizeof(sBuffer), "%T", "#panel_exit", this.translateTarget) + 1;

		g_hMap_CachedBottomSize.SetArray(sLang, this.bottomSize, sizeof(this.bottomSize));
	}

	void InitSkipAmount(ArrayList hSkipHistory)
	{
		int iTotal = 0;

		for (int i = 0; i < hSkipHistory.Length; i++)
			iTotal += hSkipHistory.Get(i);

		this.skip = iTotal;
	}

	void VerifyNextPage(int iItemAmount)
	{
		if (this.hasNext) return;

		if ((iItemAmount - this.skip) > this.max)
		{
			if (!this.hasPrev)
			{
				this.reserved += this.bottomSize[Bottom_PrevNext];
				this.max -= 2;
			}
			this.hasNext = true;
		}
	}

	void Cancel()
	{
		delete this.panel;
	}

	int Send(int iClient)
	{
		if (this.panel.Send(iClient, MenuHandler_CookiePanel, COOKIE_PANEL_TIMEOUT))
			OnCookiePanelDisplayed(iClient);
		delete this.panel;

		return this.items;
	}

	/*********
	 * CORE
	 ********/

	void AddSpacer()
	{
		this.buffer[this.bufferLen++].WriteSpacer();
	}

	void AddButton(const char[] sLabel, PanelAction action, any data)
	{
		this.buffer[this.bufferLen++].WriteButton(sLabel, action, data);
	}

	void AddDisabledButton(const char[] sLabel)
	{
		this.buffer[this.bufferLen++].WriteDisabledButton(sLabel);
	}

	void AddLine(const char[] sText, bool bIndent = false)
	{
		this.buffer[this.bufferLen++].WriteLine(sText, bIndent);
	}

	void AddMultiLine(const char[] sText, bool bIndent = false)
	{
		this.buffer[this.bufferLen++].WriteMultiLine(sText, bIndent);
	}

	bool Draw(PanelBrowser_Buttons buttons, bool bReserve = false)
	{
		int iSize;
		int iButtons;
		bool bReturn = false;

		for (int i = 0; i < this.bufferLen; i++)
		{
			iSize += this.buffer[i].size;
			if (this.buffer[i].type == Draw_Button)
				iButtons++;
		}

		if ((bReserve || iButtons <= (this.max - this.items))
			&& iSize <= (this.panel.TextRemaining - (bReserve ? 0 : this.reserved)))
		{
			for (int i = 0; i < this.bufferLen; i++)
			{
				switch (this.buffer[i].type)
				{
					case Draw_Spacer:
						this.panel.DrawItem("", ITEMDRAW_RAWLINE|ITEMDRAW_SPACER);
					case Draw_Button:
					{
						if (buttons.Map(this.panel.DrawItem(this.buffer[i].text), this.buffer[i].action, this.buffer[i].data)
							&& !bReserve)
							this.items++;
					}
					case Draw_DisabledButton:
						this.panel.DrawItem(this.buffer[i].text, ITEMDRAW_DISABLED);
					case Draw_Line:
						this.panel.DrawText(this.buffer[i].text, this.buffer[i].indent);
					case Draw_MultiLine:
						this.panel.DrawMultiLineText(this.buffer[i].text, this.buffer[i].indent);
				}
			}

			bReturn = true;
			if (bReserve)
			{
				this.reserved -= iSize;
				if (this.reserved < 0) this.reserved = 0;
			}
		}

		this.bufferLen = 0;
		return bReturn;
	}

	/************
	 * TEMPLATES
	 ************/

	void DirectoryTitle(PanelBrowser_Buttons buttons, RegisteredDirectory directory)
	{
		directory.GetName(this.line, sizeof(this.line), this.translateTarget);
		this.AddLine(this.line);
		this.AddSpacer();
		this.Draw(buttons);
	}

	void Phrase(PanelBrowser_Buttons buttons, const char[] sPhrase)
	{
		FormatEx(this.line, sizeof(this.line), "%T", sPhrase, this.translateTarget);
		this.AddLine(this.line);
		this.AddSpacer();
		this.Draw(buttons);
	}

	void CookieTitle(PanelBrowser_Buttons buttons, RegisteredCookie cookie)
	{
		cookie.GetName(this.line, sizeof(this.line), this.translateTarget);
		this.AddLine(this.line);

		/** internal name subtitle */
		if (strcmp(cookie.cookie, this.line) != 0)
			this.AddLine(cookie.cookie, true);

		this.AddSpacer();
		this.Draw(buttons);
	}

	void CookieDescription(PanelBrowser_Buttons buttons, RegisteredCookie cookie)
	{
		if (cookie.GetDescription(this.multiline, sizeof(this.multiline), this.translateTarget) > 0)
		{
			this.AddMultiLine(this.multiline);
			this.AddSpacer();
			this.Draw(buttons);
		}
	}

	void CookieValue(PanelBrowser_Buttons buttons, int iClient, RegisteredCookie cookie)
	{
		FormatEx(this.line, sizeof(this.line), "%T", "#cookie_input_current", this.translateTarget);
		this.AddLine(this.line);

		cookie.Get(iClient, this.multiline, sizeof(this.multiline));
		this.AddMultiLine(this.multiline, true);

		this.AddSpacer();
		this.Draw(buttons);
	}

	void PromptPhrase(PanelBrowser_Buttons buttons, const char[] sPhrase)
	{
		FormatEx(this.line, sizeof(this.line), "%T", sPhrase, this.translateTarget);
		this.AddButton(this.line, Action_DoNothing, 0);
		this.AddSpacer();
		this.Draw(buttons);
	}

	void Text2Input(PanelBrowser_Buttons buttons, InputData_Text2 text2)
	{
		text2.GetPrompt(this.line, sizeof(this.line), this.translateTarget);
		this.AddButton(this.line, Action_DoNothing, 0);
		this.AddSpacer();
		this.Draw(buttons);
	}

	void SpecialItems(PanelBrowser_Buttons buttons, any items)
	{
		bool bExists = false;

		for (int i = 0; i < sizeof(g_sSpecialTypePhrase); i++)
		{
			if (items & (1 << i))
			{
				FormatEx(this.line, sizeof(this.line), "%T", g_sSpecialTypePhrase[i], this.translateTarget);
				this.AddButton(this.line, Action_OpenSpecial, (1 << i));

				if (!this.Draw(buttons))
					break;

				bExists = true;
			}
		}

		if (bExists)
		{
			this.AddSpacer();
			this.Draw(buttons);
		}
	}

	void BoolInput(PanelBrowser_Buttons buttons, const char[] sTruePhrase, const char[] sFalsePhrase, int iCurrent)
	{
		if (iCurrent) FormatEx(this.line, sizeof(this.line), PANEL_CURRENT_PREFIX ... " %T", sTruePhrase, this.translateTarget);
		else FormatEx(this.line, sizeof(this.line), "%T", sTruePhrase, this.translateTarget);
		this.AddButton(this.line, Action_SetCookieInt, 1);

		if (!iCurrent) FormatEx(this.line, sizeof(this.line), PANEL_CURRENT_PREFIX ... " %T", sFalsePhrase, this.translateTarget);
		else FormatEx(this.line, sizeof(this.line), "%T", sFalsePhrase, this.translateTarget);
		this.AddButton(this.line, Action_SetCookieInt, 0);

		this.AddSpacer();
		this.Draw(buttons);
	}

	void SliderInput(PanelBrowser_Buttons buttons, InputData_Slider slider, float fValue, const char[] sDisplayValue)
	{
		static char sFormat[sizeof(this.line)];

		FormatEx(this.line, sizeof(this.line), "%T %s", "#cookie_input_current", this.translateTarget, sDisplayValue);
		this.AddLine(this.line);

		/** min */
		FormatEx(sFormat, sizeof(sFormat), "%%.%if  ", slider.precision);
		strcopy(this.multiline, sizeof(this.multiline), sFormat);

		/** bar */
		int iTickPos = RoundToFloor(
			((fValue - slider.min) / (slider.max - slider.min)) * float (SLIDER_BAR_LENGTH));

		for (int i = 0; i <= SLIDER_BAR_LENGTH; i++)
		{
			if (i == iTickPos)
				StrCat(this.multiline, sizeof(this.multiline), SLIDER_BAR_TICK);
			else
				StrCat(this.multiline, sizeof(this.multiline), SLIDER_BAR_LINE);
		}

		/** max */
		FormatEx(sFormat, sizeof(sFormat), "  %%.%if", slider.precision);
		StrCat(this.multiline, sizeof(this.multiline), sFormat);

		/** final; apply format */
		Format(this.multiline, sizeof(this.multiline), this.multiline, slider.min, slider.max);
		this.AddLine(this.multiline);

		this.AddSpacer();

		/** buttons */
		float fNewValue;

		fNewValue = fValue - slider.step;
		if (fNewValue < slider.min)
			fNewValue = slider.min;

		FormatEx(sFormat, sizeof(sFormat), "- %%.%if", slider.precision);
		FormatEx(this.line, sizeof(this.line), sFormat, slider.step);
		this.AddButton(this.line, Action_SetCookieSlider, fNewValue);

		fNewValue = fValue + slider.step;
		if (fNewValue > slider.max)
			fNewValue = slider.max;

		this.line[0] = '+';
		this.AddButton(this.line, Action_SetCookieSlider, fNewValue);

		this.AddSpacer();
		this.Draw(buttons);
	}

	void MultipleChoiceInput(PanelBrowser_Buttons buttons, ArrayList hList, const char[] sCurrent)
	{
		if (this.skip >= hList.Length)
		{
			this.skip -= hList.Length;
			return;
		}

		bool bExists = false;
		InputData_MultipleChoice choice;

		for (int i = this.skip; i < hList.Length; i++)
		{
			hList.GetArray(i, choice);
			choice.GetName(this.line, sizeof(this.line), this.translateTarget);
			strcopy(this.multiline, sizeof(this.multiline), choice.value);

			if (strcmp(this.multiline, sCurrent) == 0)
			{
				FormatEx(this.multiline, sizeof(this.multiline), PANEL_CURRENT_PREFIX ... " %s", this.line);
				this.AddButton(this.multiline, Action_SelectCookieChoice, i);
			}
			else this.AddButton(this.line, Action_SelectCookieChoice, i);

			if (!this.Draw(buttons))
				break;

			bExists = true;
		}

		if (bExists)
		{
			this.AddSpacer();
			this.Draw(buttons);
		}
	}

	void Directories(PanelBrowser_Buttons buttons, ArrayList hList)
	{
		if (this.skip >= hList.Length)
		{
			this.skip -= hList.Length;
			return;
		}

		bool bExists = false;
		RegisteredDirectory directory;
		int iRef;

		for (int i = this.skip; i < hList.Length; i++)
		{
			iRef = hList.Get(i);
			g_hArray_Directories.GetArray(iRef, directory);

			directory.GetName(this.line, sizeof(this.line), this.translateTarget);
			Format(this.multiline, sizeof(this.multiline), PANEL_DIRECTORY_PREFIX ... " %s", this.line);
			this.AddButton(this.multiline, Action_OpenDirectory, iRef);
			if (!this.Draw(buttons))
				break;

			bExists = true;
		}

		this.skip = 0;
		if (bExists)
		{
			this.AddSpacer();
			this.Draw(buttons);
		}
	}

	void Cookies(PanelBrowser_Buttons buttons, ArrayList hList)
	{
		if (this.skip >= hList.Length)
		{
			this.skip -= hList.Length;
			return;
		}

		bool bExists;
		RegisteredCookie cookie;
		int iRef;

		for (int i = this.skip; i < hList.Length; i++)
		{
			iRef = hList.Get(i);
			g_hArray_Cookies.GetArray(iRef, cookie);

			cookie.GetName(this.line, sizeof(this.line), this.translateTarget);
			this.AddButton(this.line, Action_OpenCookie, iRef);
			if (!this.Draw(buttons))
				break;

			bExists = true;
		}

		this.skip = 0;
		if (bExists)
		{
			this.AddSpacer();
			this.Draw(buttons);
		}
	}

	void CookieMatches(PanelBrowser_Buttons buttons, ArrayList hList)
	{
		if (this.skip >= hList.Length)
		{
			this.skip -= hList.Length;
			return;
		}

		bool bExists = false;
		RegisteredCookie cookie;
		int iRef;

		for (int i = this.skip; i < hList.Length; i++)
		{
			iRef = hList.Get(i);
			g_hArray_Cookies.GetArray(iRef, cookie);

			strcopy(this.line, sizeof(this.line), cookie.cookie);
			this.AddButton(this.line, Action_OpenCookie, iRef);
			cookie.GetName(this.line, sizeof(this.line), this.translateTarget);
			this.AddLine(this.line, true);
			if (!this.Draw(buttons))
				break;

			bExists = true;
		}

		this.skip = 0;
		if (bExists)
		{
			this.AddSpacer();
			this.Draw(buttons);
		}
	}

	/*********************
	 * RESERVED TEMPLATES
	 *********************/

	void BottomControls(PanelBrowser_Buttons buttons)
	{
		this.panel.CurrentKey = this.max + 1;

		if (this.hasPrev || this.hasNext)
		{
			FormatEx(this.line, sizeof(this.line), "%T", "#panel_prev_page", this.translateTarget);
			if (this.hasPrev)
				this.AddButton(this.line, Action_PrevPage, 0);
			else this.AddDisabledButton(this.line);

			FormatEx(this.line, sizeof(this.line), "%T", "#panel_next_page", this.translateTarget);
			if (this.hasNext)
				this.AddButton(this.line, Action_NextPage, 0);
			else this.AddDisabledButton(this.line);
		}

		if (this.hasParent)
		{
			FormatEx(this.line, sizeof(this.line), "%T", "#panel_back", this.translateTarget);
			this.AddButton(this.line, Action_OpenOld, 0);
		}
		else
		{
			FormatEx(this.line, sizeof(this.line), "%T", "#panel_exit", this.translateTarget);
			this.AddButton(this.line, Action_Close, 0);
		}

		this.Draw(buttons, true);
	}
}
static CookiePanelRenderer render;

enum struct PanelBrowser_HistoryRecord
{
	PanelType type;
	int ref;

	int page;
	ArrayList pageItems;
	int items;

	void Create(PanelType type, int ref, int page, ArrayList pageItems, int items)
	{
		this.type = type;
		this.ref = ref;

		this.page = page;
		this.pageItems = pageItems;
		this.items = items;
	}
}

enum struct PanelBrowser_Buttons
{
	PanelAction action[MAX_PANEL_KEYS];
	any data[MAX_PANEL_KEYS];

	void Reset()
	{
		for (int i = 0; i < sizeof(this.action); i++)
			this.action[i] = Action_DoNothing;
	}

	bool Map(int iButton, PanelAction action, any data)
	{
		if (!iButton) return false;
		iButton--;

		this.action[iButton] = action;
		this.data[iButton] = data;

		return true;
	}

	any GetData(int iButton)
	{
		return this.data[iButton - 1];
	}

	PanelAction GetAction(int iButton)
	{
		return this.action[iButton - 1];
	}
}

enum struct PanelBrowser
{
	int client;
	int userid;

	PanelType type;
	any ref;
	int page;

	int items;
	ArrayList pageItems;

	RegisteredDirectory directory;
	RegisteredCookie cookie;
	ArrayList special;

	ArrayList history;

	/** render output */
	PanelBrowser_Buttons buttons;

	/**
	 * initialize struct variables
	 */
	void Init(int iClient)
	{
		this.client = iClient;
		this.pageItems = null;
		this.history = new ArrayList(sizeof(PanelBrowser_HistoryRecord));
		this.special = new ArrayList();
	}

	/**
	 * client commands call this.
	 * opens a menu at its start.
	 */
	void OpenNew(PanelType type, any ref = 0)
	{
		if (this.history.Length)
		{
			PanelBrowser_HistoryRecord record;
			for (int i = 0; i < this.history.Length; i++)
			{
				this.history.GetArray(i, record);
				delete record.pageItems;
			}
		}

		if (this.pageItems != null)
			delete this.pageItems;

		this.history.Clear();
		this.userid = GetClientUserId(this.client);

		this.Open(type, ref, 0, 0);
	}

	/**
	 * we prefer menus to close via ignored button presses and MenuAction_Cancel.
	 * but when we need the panel to close forcefully, call this.
	 */
	void Close()
	{
		if (!this.IsOriginalUserID() || GetClientMenu(this.client) == MenuSource_None)
			return;

		Panel hPanel = new Panel();
		hPanel.DrawText("");
		if (hPanel.Send(this.client, MenuHandler_Close, 1))
			OnCookiePanelClose(this.client);

		delete hPanel;
	}

	/**
	 * to verify if the client still points to the same userid as the one who
	 * originally started the menu.
	 * most likely redundancy
	 */
	bool IsOriginalUserID()
	{
		if (!IsClientInGame(this.client))
			return false;

		return GetClientUserId(this.client) == this.userid;
	}

	/***************
	 * ACCEPT INPUTS
	 ***************/

	void PressButton(int iButton)
	{
		if (!this.IsOriginalUserID())
			return;

		PanelAction action = this.buttons.GetAction(iButton);
		any data = this.buttons.GetData(iButton);

		switch (action)
		{
			case Action_OpenDirectory:
				this.OpenChild(Panel_Directory, data);

			case Action_OpenCookie:
				this.OpenChild(Panel_Cookie, data);

			case Action_OpenSpecial:
			{
				switch (data)
				{
					case Special_Search:
						this.OpenChild(Panel_SearchPrompt, 0);

					case Special_All, Special_Categorized, Special_Uncategorized:
					{
						if (BuildAutoDir(this.special, data))
							this.OpenChild(Panel_Special, data);
					}
				}
			}

			case Action_SelectCookieChoice:
			{
				InputData_MultipleChoice choice;
				view_as<ArrayList>(this.cookie.inputData).GetArray(data, choice);

				this.cookie.SetString(this.client, choice.value);

				if (this.history.Length > 0)
					this.OpenParent();
			}

			case Action_SetCookieSlider:
			{
				this.cookie.SetFloat(this.client, data);
				this.Render();
			}

			case Action_SetCookieInt:
			{
				this.cookie.SetInt(this.client, data);

				if (this.history.Length > 0)
					this.OpenParent();
			}

			case Action_PrevPage:
				this.PrevPage();

			case Action_NextPage:
				this.NextPage();

			case Action_OpenOld:
				this.OpenParent();

			// case Action_Close:
			// 	this.Close();
		}
	}

	bool AcceptMsgInput(const char[] sInput)
	{
		g_bListenForTextInput[this.client] = false;

		if (!this.IsOriginalUserID())
			return false;

		switch (this.type)
		{
			case Panel_SearchPrompt:
			{
				int iCookieRef = BuildSearchResults(this.special, sInput);

				if (iCookieRef >= 0)
					this.OpenChild(Panel_Cookie, iCookieRef);
				else
					this.OpenChild(Panel_Special, Special_Search);
			}

			case Panel_Cookie:
			{
				this.cookie.SetString(this.client, sInput);

				if (this.history.Length > 0)
					this.OpenParent();
				else this.Close();
			}
		}

		return true;
	}

	/************
	 * NAVIGATE
	 ***********/

	void OpenChild(PanelType type, any ref)
	{
		PanelBrowser_HistoryRecord record;
		record.Create(this.type, this.ref, this.page, this.pageItems, this.items);
		this.history.PushArray(record);

		this.pageItems = new ArrayList();
		this.Open(type, ref, 0, 0);
	}

	void OpenParent()
	{
		delete this.pageItems;

		PanelBrowser_HistoryRecord record;
		this.history.GetArray(this.history.Length - 1, record);
		this.history.Erase(this.history.Length - 1);

		this.pageItems = record.pageItems;
		this.Open(record.type, record.ref, record.page, record.items);
	}

	void Open(PanelType type, any ref, int page, int items)
	{
		this.type = type;
		this.ref = ref;
		this.page = page;
		this.items = items;

		switch (this.type)
		{
			case Panel_Directory:
				g_hArray_Directories.GetArray(this.ref, this.directory);

			case Panel_Cookie:
				g_hArray_Cookies.GetArray(this.ref, this.cookie);
		}

		this.Render();
	}

	void PrevPage()
	{
		this.page--;
		this.pageItems.Resize(this.page);

		this.Render();
	}

	void NextPage()
	{
		this.page++;
		this.pageItems.Resize(this.page);
		this.pageItems.Set(this.page - 1, this.items);

		this.Render();
	}

	/********************
	 * DISPLAY TO CLIENT
	 *******************/

	void Render()
	{
		g_bListenForTextInput[this.client] = false;

		this.buttons.Reset();
		render.Init(this.client, this.page, this.history, this.pageItems);

		switch (this.type)
		{
			case Panel_Directory:
			{
				render.VerifyNextPage(this.directory.GetItemAmount());

				render.DirectoryTitle(this.buttons, this.directory);
				render.SpecialItems(this.buttons, this.directory.special);
				render.Directories(this.buttons, this.directory.subdirectories);
				render.Cookies(this.buttons, this.directory.cookies);
			}

			case Panel_SearchPrompt:
			{
				g_bListenForTextInput[this.client] = true;
				render.PromptPhrase(this.buttons, "#panel_search_prompt");
			}

			case Panel_Special:
			{
				render.VerifyNextPage(this.special.Length);

				render.Phrase(this.buttons, "#panel_title_special");
				if (this.ref == Special_Search)
					render.CookieMatches(this.buttons, this.special);
				else render.Cookies(this.buttons, this.special);
			}

			case Panel_Cookie:
			{
				if (!this.cookie.Exists())
				{
					render.Cancel();
					return;
				}

				render.CookieTitle(this.buttons, this.cookie);
				render.CookieDescription(this.buttons, this.cookie);

				switch (this.cookie.input)
				{
					case Input_None, Input_Text:
					{
						g_bListenForTextInput[this.client] = true;

						render.CookieValue(this.buttons, this.client, this.cookie);
						render.PromptPhrase(this.buttons, "#cookie_input_text_prompt");
					}

					case Input_Text2:
					{
						g_bListenForTextInput[this.client] = true;

						render.CookieValue(this.buttons, this.client, this.cookie);

						InputData_Text2 text2;
						this.cookie.GetInput_Text2(text2);
						render.Text2Input(this.buttons, text2);
					}

					case Input_OnOff:
					{
						render.BoolInput(this.buttons,
							"#cookie_input_on", "#cookie_input_off",
							this.cookie.GetInt(this.client));
					}

					case Input_YesNo:
					{
						render.BoolInput(this.buttons,
							"#cookie_input_yes", "#cookie_input_no",
							this.cookie.GetInt(this.client));
					}

					case Input_MultipleChoice:
					{
						render.VerifyNextPage(view_as<ArrayList>(this.cookie.inputData).Length);

						char sValue[100];
						this.cookie.Get(this.client, sValue, sizeof(sValue));
						render.MultipleChoiceInput(this.buttons, view_as<ArrayList>(this.cookie.inputData), sValue);
					}

					case Input_Slider:
					{
						InputData_Slider slider;
						static char sDisplayValue[32];
						float fValue = this.cookie.GetInput_Slider(this.client, slider, sDisplayValue, sizeof(sDisplayValue));

						render.SliderInput(this.buttons, slider, fValue, sDisplayValue);
					}
				}
			}
		}

		render.BottomControls(this.buttons);
		this.items = render.Send(this.client);
	}
}

void MenuHandler_CookiePanel(Menu hNullPanel, MenuAction action, int iClient, int iButton)
{
	switch (action)
	{
		case MenuAction_Select:
			g_clientPanel[iClient].PressButton(iButton);
		case MenuAction_Cancel:
			OnCookiePanelClose(iClient);
	}
}

void MenuHandler_Close(Menu hNullPanel, MenuAction action, int iClient, int iButton)
{}

/*******************************
 * track panel visibility state
 ******************************/

void OnCookiePanelDisplayed(int iClient)
{
	if (g_hTimer_CookiePanelDuration[iClient] != null)
		delete g_hTimer_CookiePanelDuration[iClient];

	g_hTimer_CookiePanelDuration[iClient] = CreateTimer(float(COOKIE_PANEL_TIMEOUT), Timer_OnCookiePanelDurationFinish, iClient);
}

void OnCookiePanelClose(int iClient)
{
	g_bListenForTextInput[iClient] = false;

	if (g_hTimer_CookiePanelDuration[iClient] != null)
		delete g_hTimer_CookiePanelDuration[iClient];
}

void Timer_OnCookiePanelDurationFinish(Handle hTimer, int iClient)
{
	g_bListenForTextInput[iClient] = false;
	g_hTimer_CookiePanelDuration[iClient] = null;
}
