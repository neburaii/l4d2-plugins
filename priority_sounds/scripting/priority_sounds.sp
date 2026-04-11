#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hxstocks>

#define DATA_FILE	"data/priority_sounds.txt"

public Plugin myinfo =
{
	name = "Priority Sounds",
	author = "Neburai",
	description = "Configures priority sounds that cannot be interrupted",
	version = "2.0",
	url = "https://github.com/neburaii/l4d2-plugins/tree/main/priority_sounds"
};

#define MIN_SUPPORTED_SNDCHAN	SNDCHAN_WEAPON // 1
#define MAX_SUPPORTED_SNDCHAN	SNDCHAN_STREAM // 5

PlayingSound g_lastSound[MAXEDICTS + 1][MAX_SUPPORTED_SNDCHAN + 1];

StringMap	g_hMap_Sounds;
SoundParser g_soundParser;

public void OnPluginStart()
{
	g_hMap_Sounds = new StringMap();
	g_soundParser.LoadSoundData();

	for (int e = 0; e < sizeof(g_lastSound); e++)
	{
		for (int c = MIN_SUPPORTED_SNDCHAN; c < sizeof(g_lastSound[]); c++)
			g_lastSound[e][c].Init();
	}

	AddNormalSoundHook(OnNormalSound);

	RegAdminCmd("sm_priority_si_sounds_reset", Command_Reset, ADMFLAG_ROOT);
}

Action Command_Reset(int iClient, int iArgs)
{
	g_hMap_Sounds.Clear();
	g_soundParser.LoadSoundData();

	return Plugin_Handled;
}

/**********************
 * track playing sounds
 **********************/

enum struct Sound
{
	float duration;
	int priority;
}

enum struct PlayingSound
{
	int entref;
	Handle timer;
	int priority;

	void Init()
	{
		this.entref = INVALID_ENT_REFERENCE;
		this.timer = null;
	}

	Action Play(int iEntity, Sound soundData)
	{
		if (this.timer
			&& EntRefToEntIndex(this.entref) != INVALID_ENT_REFERENCE
			&& soundData.priority < this.priority)
			return Plugin_Handled;

		if (this.timer) delete this.timer;

		if (soundData.priority)
		{
			this.priority = soundData.priority;
			this.entref = EntIndexToEntRef(iEntity);

			if (soundData.duration >= 0.1)
				this.timer = CreateTimer(soundData.duration, Timer_SoundFinish, this);
		}

		return Plugin_Continue;
	}
}

void Timer_SoundFinish(Handle hTimer, PlayingSound sound)
{
	sound.timer = null;
}

Action OnNormalSound(int iClients[64], int &iNumClients, char sOriginalSample[PLATFORM_MAX_PATH], int &iEntity,
	int &iOriginalChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sSoundEntry[256], int &iSeed)
{
	int iChannel = iOriginalChannel;
	if (!IsValidEdict(iEntity) || !ProcessChannel(sOriginalSample, iChannel))
		return Plugin_Continue;

	static char sSample[sizeof(sOriginalSample)];
	Sound soundData;

	CorrectSample(sOriginalSample, sSample, sizeof(sSample));
	if (!g_hMap_Sounds.GetArray(sSample, soundData, sizeof(soundData)))
		soundData.priority = 0;

	return g_lastSound[iEntity][iChannel].Play(iEntity, soundData);
}

/** prefix of sample names for networked messages. up to the first 2 characters can have these chars.
 * the client will process the sound using the name as it appears after these characters. */
enum
{
	SndChar_Stream			= '*',		// indicates streaming wav data
	SndChar_UserVOX			= '?',		// indicates user realtime voice data
	SndChar_Sentence		= '!',		// indicates sentence wav
	SndChar_DryMix			= '#',		// indicates wav bypasses dsp fx
	SndChar_Doppler			= '>',		// indicates doppler encoded stereo wav: left wav (incomming) and right wav (outgoing).
	SndChar_Directional		= '<',		// indicates stereo wav has direction cone: mix left wav (front facing) with right wav (rear facing) based on soundfacing direction
	SndChar_DistVariant		= '^',		// indicates distance variant encoded stereo wav (left is close, right is far)
	SndChar_Omni			= '@',		// indicates non-directional wav (default mono or stereo)
	SndChar_HRTF			= '~',		// indicates wav should use HRTF spatialization for non-owners.
	SndChar_Radio			= '+',		// indicates a 'radio' sound -- should be played without spatialization
	SndChar_SpatialStereo	= ')',		// indicates spatialized stereo wav
	SndChar_DirStereo		= '(',		// indicates directional stereo wav (like doppler)
	SndChar_FastPitch		= '}',		// forces low quality, non-interpolated pitch shift
	SndChar_Subtitled		= '$'		// indicates the subtitles are forced
}

bool IsSoundChar(char c)
{
	return	c == SndChar_Stream || c == SndChar_UserVOX
			|| c == SndChar_Sentence || c == SndChar_DryMix
			|| c == SndChar_Doppler || c == SndChar_Directional
			|| c == SndChar_DistVariant || c == SndChar_Omni
			|| c == SndChar_HRTF || c == SndChar_Radio
			|| c == SndChar_SpatialStereo || c == SndChar_DirStereo
			|| c == SndChar_FastPitch || c == SndChar_Subtitled;
}

bool HasSoundChar(const char[] sSample, char c)
{
	for (int i = 0; i < PLATFORM_MAX_PATH; i++)
	{
		if (!IsSoundChar(sSample[i]))
			break;

		if (sSample[i] == c)
			return true;
	}

	return false;
}

/**
 * correct channel to what it's expected to translate to client side.
 * returns true if this expected channel is targetted by the plugin.
 */
bool ProcessChannel(const char[] sSample, int &iChannel)
{
	if (iChannel > 7) iChannel %= 8;

	if (iChannel != SNDCHAN_STREAM && iChannel != SNDCHAN_VOICE && iChannel != SNDCHAN_STATIC
		&& HasSoundChar(sSample, SndChar_Stream))
	{
		iChannel = SNDCHAN_STREAM;
		return true;
	}

	return MIN_SUPPORTED_SNDCHAN <= iChannel <= MAX_SUPPORTED_SNDCHAN;
}

void CorrectSample(const char[] sOriginal, char[] sBuffer, int iBufferLen)
{
	int iWrite = 0;
	for (int i = 0; iWrite < iBufferLen; i++)
	{
		if (!iWrite && IsSoundChar(sOriginal[i]))
			continue;

		if (IsCharAlpha(sOriginal[i]))
			sBuffer[iWrite++] = CharToLower(sOriginal[i]);
		else if (sOriginal[i] == '\\')
			sBuffer[iWrite++] = '/';
		else sBuffer[iWrite++] = sOriginal[i];

		if (sOriginal[i] == '\0') return;
	}
}

/******************
 * parse data file
 *****************/

enum ParserState
{
	Parser_LookingForSound,
	Parser_ReadingSound,
	Parser_Skip
};

enum struct SoundParser
{
	SMCParser parser;
	ParserState state;
	ArrayList stateHistory;

	Sound sound;
	char soundName[PLATFORM_MAX_PATH];

	void LoadSoundData()
	{
		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), DATA_FILE);
		if (!FileExists(sPath)) return;

		this.parser = new SMCParser();
		this.parser.OnEnterSection = SMC_OnEnterSound;
		this.parser.OnKeyValue = INVALID_FUNCTION;
		this.parser.OnLeaveSection = SMC_OnLeaveSection;

		this.state = Parser_LookingForSound;
		this.stateHistory = new ArrayList();

		this.parser.ParseFile(sPath);

		delete this.parser;
		delete this.stateHistory;
	}

	void SetState(ParserState state)
	{
		if (this.state == state) return;

		switch (state)
		{
			case Parser_LookingForSound:
			{
				this.parser.OnEnterSection = SMC_OnEnterSound;
				this.parser.OnKeyValue = INVALID_FUNCTION;
			}
			case Parser_ReadingSound:
			{
				this.parser.OnEnterSection = SMC_OnSkipSection;
				this.parser.OnKeyValue = SMC_OnKeyValue;
			}
			case Parser_Skip:
			{
				this.parser.OnEnterSection = SMC_OnSkipSection;
				this.parser.OnKeyValue = INVALID_FUNCTION;
			}
		}

		this.state = state;
	}

	void OpenSound(const char[] sName)
	{
		strcopy(this.soundName, sizeof(this.soundName), sName);
		this.sound.duration = 0.0;
		this.sound.priority = 0;
	}

	void CommitSound()
	{
		g_hMap_Sounds.SetArray(this.soundName, this.sound, sizeof(this.sound));
	}

	SMCResult EnterSection(ParserState newState)
	{
		this.stateHistory.Push(this.state);
		this.SetState(newState);

		return SMCParse_Continue;
	}

	SMCResult LeaveSection()
	{
		int iNewSize = this.stateHistory.Length - 1;
		ParserState newState = this.stateHistory.Get(iNewSize);
		this.stateHistory.Resize(iNewSize);

		if (this.state == Parser_ReadingSound)
			this.CommitSound();

		this.SetState(newState);

		return SMCParse_Continue;
	}

	SMCResult Read(const char[] sKey, const char[] sValue)
	{
		if (strcmp(sKey, "duration") == 0)
		{
			float fValue = StringToFloat(sValue);
			this.sound.duration = fValue;
		}
		else if (strcmp(sKey, "priority") == 0)
		{
			int iValue = StringToInt(sValue);
			this.sound.priority = iValue;
		}

		return SMCParse_Continue;
	}
}

SMCResult SMC_OnEnterSound(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	g_soundParser.OpenSound(sName);
	return g_soundParser.EnterSection(Parser_ReadingSound);
}

SMCResult SMC_OnSkipSection(SMCParser hParser, const char[] sName, bool bOptQuotes)
{
	return g_soundParser.EnterSection(Parser_Skip);
}

SMCResult SMC_OnKeyValue(SMCParser hParser, const char[] sKey, const char[] sValue, bool bKeyQuotes, bool bValueQuotes)
{
	return g_soundParser.Read(sKey, sValue);
}

SMCResult SMC_OnLeaveSection(SMCParser hParser)
{
	return g_soundParser.LeaveSection();
}
