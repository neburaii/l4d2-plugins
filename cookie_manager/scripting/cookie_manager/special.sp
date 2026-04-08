#pragma newdecls required
#pragma semicolon 1

#define FUZZY_MATCH_THRESHOLD		0.5

#define SEARCH_RESULT_BLOCK_REF		0
#define SEARCH_RESULT_BLOCK_SCORE	1

methodmap SearchResultArray < ArrayList
{
	public SearchResultArray()
	{
		return view_as<SearchResultArray>(CreateArray(2));
	}

	public void Push(int iRef, float fScore)
	{
		any block[2];
		block[SEARCH_RESULT_BLOCK_REF] = iRef;
		block[SEARCH_RESULT_BLOCK_SCORE] = fScore;

		this.PushArray(block);
	}

	public float GetScore(int iIndex)
	{
		return this.Get(iIndex, SEARCH_RESULT_BLOCK_SCORE);
	}

	public int GetRef(int iIndex)
	{
		return this.Get(iIndex, SEARCH_RESULT_BLOCK_REF);
	}
}

/**
 * @return		cookie ref if an exact match, -1 otherwise
 */
int BuildSearchResults(ArrayList hOutput, const char[] sQuery)
{
	hOutput.Clear();
	SearchResultArray hResults = new SearchResultArray();

	int iLen = strlen(sQuery) + 1;
	char[] sNormalizedQuery = new char[iLen];

	NormalizeString(sNormalizedQuery, iLen, sQuery);

	int iReturn = -1;

	Handle hIterator = GetCookieIterator();
	CookieAccess access;
	static char sCookieName[COOKIE_MAX_NAME_LENGTH];
	static char sNormalizedCookieName[COOKIE_MAX_NAME_LENGTH];
	static char sCookieDesc[COOKIE_MAX_DESCRIPTION_LENGTH];
	int iRef;
	float fScore;

	while (ReadCookieIterator(hIterator, sCookieName, sizeof(sCookieName), access, sCookieDesc, sizeof(sCookieDesc)))
	{
		if (access != CookieAccess_Public)
			continue;

		/** client likely doesn't care for viewing results if it's an exact match */
		if (strcmp(sQuery, sCookieName) == 0)
		{
			if (!g_hMap_Cookies.GetValue(sCookieName, iReturn))
				iReturn = RegisterUndefinedCookie(sCookieName, sCookieDesc);

			if (iReturn != -1)
				break;
		}

		NormalizeString(sNormalizedCookieName, sizeof(sNormalizedCookieName), sCookieName);
		fScore = FuzzyMatch(sNormalizedQuery, sNormalizedCookieName);

		if (fScore >= FUZZY_MATCH_THRESHOLD)
		{
			if (!g_hMap_Cookies.GetValue(sCookieName, iRef))
				iRef = RegisterUndefinedCookie(sCookieName, sCookieDesc);

			if (iRef != -1)
				hResults.Push(iRef, fScore);
		}
	}

	if (iReturn == -1)
	{
		if (hResults.Length > 1)
			hResults.SortCustom(SearchResultSort_Compare);

		for (int i = 0; i < hResults.Length; i++)
			hOutput.Push(hResults.GetRef(i));
	}

	delete hIterator;
	delete hResults;

	return iReturn;
}

int SearchResultSort_Compare(int index1, int index2, SearchResultArray hResults, Handle nullHandle)
{
	float fScore1 = hResults.GetScore(index1);
	float fScore2 = hResults.GetScore(index2);

	if (fScore1 == fScore2)
		return 0;
	else if (fScore1 > fScore2)
		return -1;

	return 1;
}

void NormalizeString(char[] sOutput, int iOutputLen, const char[] sSource)
{
	int i;
	for (i = 0; i < iOutputLen; i++)
	{
		sOutput[i] = sSource[i];
		if (sOutput[i] == '\0')
			return;

		if (IsCharUpper(sOutput[i]))
			sOutput[i] |= (1 << 5);
		else if (IsCharSpace(sOutput[i]))
			sOutput[i] = '_';
	}
	sOutput[i] = '\0';
}

/**
 * return a score of 0.0 to 1.0 for how similar the 2 strings are.
 *
 * @param str1			one string of the pair to compare
 * @param str2			other string of the pair to compare
 *
 * @return				1.0 for perfect match, 0.0 for no similarity, and ranging anywhere in between
 */
stock float FuzzyMatch(const char[] str1, const char[] str2)
{
	int str1Len = strlen(str1);
	int str2Len = strlen(str2);

	if (str1Len > str2Len)
		return FuzzyMatch(str2, str1);

	if (!str1Len) return 0.0;
	if (!str2Len) return 0.0;

	int[] prevRow = new int[str2Len + 1];
	int[] currRow = new int[str2Len + 1];
	int min;

	for (int i = 0; i <= str2Len; i++)
		prevRow[i] = i;

	/** str1 to str2 edit distance */
	for (int a = 1; a <= str1Len; a++)
	{
		currRow[0] = a;

		for (int b = 1; b <= str2Len; b++)
		{
			if (str1[a - 1] == str2[b - 1])
			{
				currRow[b] = prevRow[b - 1];
			}
			else
			{
				/** insert */
				min = currRow[b - 1];
				/** remove */
				if (prevRow[b] < min) min = prevRow[b];
				/** replace */
				if (prevRow[b - 1] < min) min = prevRow[b - 1];

				currRow[b] = 1 + min;
			}
		}

		for (int i = 0; i <= str2Len; i++)
			prevRow[i] = currRow[i];
	}

	float score = float(str2Len - currRow[str2Len]) / float(str2Len);
	return score;
}

bool BuildAutoDir(ArrayList hOutput, SpecialType type)
{
	hOutput.Clear();

	Handle hIterator = GetCookieIterator();
	CookieAccess access;
	static char sCookieName[COOKIE_MAX_NAME_LENGTH];
	static char sCookieDesc[COOKIE_MAX_DESCRIPTION_LENGTH];
	int iRef;

	if (type == Special_All)
	{
		while (ReadCookieIterator(hIterator, sCookieName, sizeof(sCookieName), access, sCookieDesc, sizeof(sCookieDesc)))
		{
			if (access != CookieAccess_Public)
				continue;

			if (!g_hMap_Cookies.GetValue(sCookieName, iRef))
				iRef = RegisterUndefinedCookie(sCookieName, sCookieDesc);

			if (iRef != -1)
				hOutput.Push(iRef);
		}
	}

	else // filtered
	{
		bool bFilter = (type == Special_Categorized);

		while (ReadCookieIterator(hIterator, sCookieName, sizeof(sCookieName), access))
		{
			if (access != CookieAccess_Public)
				continue;

			if (g_hMap_CookiesInDirectory.GetValue(sCookieName, iRef) == bFilter)
			{
				if (!bFilter)
				{
					if (!g_hMap_Cookies.GetValue(sCookieName, iRef))
						iRef = RegisterUndefinedCookie(sCookieName, sCookieDesc);

					if (iRef == -1) continue;
				}

				hOutput.Push(iRef);
			}
		}
	}

	delete hIterator;

	return hOutput.Length > 0;
}
