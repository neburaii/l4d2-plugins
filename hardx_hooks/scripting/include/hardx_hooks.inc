#if defined _hardx_hooks_included_
	#endinput
#endif
#define _hardx_hooks_included_

// int values for the panic event type argument passed for map invoked panic events
#define	PANIC_GENERIC	0
#define	PANIC_CAR_ALARM	1
#define	PANIC_SCRIPTED	3

#define VSCRIPT_SCOPE_DIRECTORSCRIPT	0
#define VSCRIPT_SCOPE_SCRIPTEDMODE		1
#define VSCRIPT_SCOPE_LOCALSCRIPT 		2

////////////////////////////////////////
// NATIVES
////////////////////////////////////////

/**
 * Get the string of the current LocalScript scope vscript loaded by info_director
 * 
 * @param sOutput		buffer to store returned string
 * @param iOutputSize	size of return buffer
 * @return				true if bytes were written, false otherwise (no vscript loaded currently)
 */
native bool hxGetCurrentVScript(const char[] sOutput, int iOutputSize);

/**
 * Set the intensity of this survivor
 * 
 * @param iClient		client index of the survivor
 * @param fIntensity	desired intensity (must be between 0.0 to 1.0 inclusive)
 * @return				true on success, false on failure
 * @error				client is invalid
 */
native bool hxSetSurvivorIntensity(int iClient, float fIntensity);

/**
 * Get the intensity of this survivor
 * 
 * @param iClient		client index of the survivor
 * @return				float value of intensity
 * @error				client is invalid
 */
native float hxGetSurvivorIntensity(int iClient);

// quick explanation of these:
// 1 is used naturally in a single case, which is infected dying nearby
// 2 - 4 are used mostly from damage sources. 3 is always used for ledge hangs, 4 sometimes used instead of 5 for damage while incapped, infected deaths can sometimes be any of these 3
// 5 is almost exlusively used for revival or death type sources. So coming out of a rescue closet, being defibbed, etc
// Which values are used in which vanilla context doesn't matter too much. These are just notes to give you a frame of reference
// The important thing to know is that small number makes intensity rise by a tiny bit, with a short timer until decay, while big number makes inensity skyrocket with longer timer until decay
// Also, it has to be a number 1 through 5. MINOR, MAJOR, and CRITICAL are the proper terms used for 2, 3, 4 in the context of survivors taking damage. I had to make up the other 2 for the sake of giving them all a constant
// Lastly, the exact value intensity increases by is tied to the intensity_factor convar
#define INTENSITY_PAIN_MIN			1
#define INTENSITY_PAIN_MINOR		2
#define INTENSITY_PAIN_MAJOR		3
#define INTENSITY_PAIN_CRITICAL		4
#define INETNSITY_PAIN_MAX			5
/**
 * Increment a survivor's total accumulated intensity (resets decay timer too)
 * 
 * @param iClient		client index of target survivor
 * @param iStrength		Strength of this instensity source. See INTENSITY_PAIN_* constants (a value 1 through 5)
 * @error				client is invalid
 */
native void hxIntensifySurvivor(int iClient, int iStrength);

/**
 * End any ongoing event managed by director scripted event manager (PanicEvent, ScriptedPanicEvent, car alarm, etc)
 */
native void hxEndPanicEvent();

/**
 * Unload any vscript loaded in the LocalScript scope (use this to end a vscript-based event)
 */
native void hxEndLocalScript();

/**
 * Used to predict how many panic waves there'll be when no amount is specified (PanicEvent input started ones, for example)
 * It returns a number representing how early or far the map is into the total maps of the campaign. It's not the same as the
 * map number.
 * 
 * @return	int
 */
native int hxGetMapArcValue();

/**
 * return list of valid nav areas for SI spawns for the given parameters
 * 
 * @param iDirection	direction pool to use (Values for PreferredSpecialDirection, and similar script variables. -1 (*_NO_PREFERENCE) isn't a pool!!!)
 * @param iZClass		SI class to do some checks for (doesn't really make much of a difference)
 * 
 * @return Address		It returns a pointer to the start of a small data structure. 
 * 						1st 4byte cell is a pointer to the start of the actual nav area list, 
 * 						while the 3rd 4byte cell is the total number of nav areas in that list.
 */
native Address hxCollectSpawnAreas(int iDirection, int iZClass);

/**
 * given a nav area, it will return the address of the highest flow nav area that's adjacent to it
 * 
 * @param aRefNav		check nav areas adjacent to this one
 * 
 * @return 				address
 */
native Address hxGetHighestAdjacentFlow(Address aRefNav);

/**
 * given an SI class, vector position, nav area, and reference client, determine if the SI can spawn there
 * 
 * @param vPos			position to check
 * @param aNavArea		nav area to check
 * @param iZClass		SI class to check for
 * @param iRefClient	client the check is relative to
 * @param bTryTwice		emulate the logic the game uses for running this a second time with vPos[2] raised by 18.0
 * 
 * @return bool			true if the SI can spawn there, false otherwise
 * 
 * NOTE: omitted bool parameter for "is it a mob rush?". The game calls this function with that as true even for SI, so it's best to do the same
 */
native bool hxCanZombieSpawnHere(float vPos[3], Address aNavArea, int iZClass, int iRefClient, bool bTryTwice);

native bool hxAreAllSurvivorsInBattlefield();

/**
 * given an X and Y coordinate that's within a nav area, it returns the correct Z coordinate
 * 
 * @param aNavArea	nav area to check
 * @param X			X coordinate to check
 * @param Y			Y coordinate to check
 */
native float hxGetNavAreaZ(Address aNavArea, float X, float Y);

////////////////////////////////////////
// FORWARDS
////////////////////////////////////////

/**
 * Called when a map triggers an event through the director scripted event manager
 * 
 * @param iClient	who triggered it? 0 if no client
 * @param iType		what type of source triggered it? (check PANIC_* constants)
 * @return			Plugin_Handled to block function from running, Plugin_Continue to allow it
 */
forward Action hxOnMapInvokedPanicEvent(int iClient, int iType);

/**
 * Called when a map triggers an event through the director scripted event manager
 * 
 * @param iClient	who triggered it? 0 if no client
 * @param iType		what type of source triggered it? (check PANIC_* constants)
 */
forward void hxOnMapInvokedPanicEvent_Post(int iClient, int iType);

/**
 * Called when a vscript is about to be executed
 * 
 * @param sScript		name of the vscript without the extension nor any parent directories
 * @param iScope		which vscript scope is this being ran under?
 * @param bAddon		were *_addon scripts ran?
 * @return				Plugin_Handled to block function from running, Plugin_Continue to allow it
 */
forward Action hxOnRunScript(const char[] sScript, int iScope, bool bAddon);

/**
 * Called when a vscript is executed
 * 
 * @param sScript		name of the vscript without the extension nor any parent directories
 * @param iScope		which vscript scope is this being ran under?
 * @param bAddon		were *_addon scripts ran?
 * @return				Plugin_Handled to block function from running, Plugin_Continue to allow it
 */
forward void hxOnRunScript_Post(const char[] sScript, int iScope, bool bAddon);

/**
 * Called when the LocalScript vscript scope is about to be cleared of any running scripts
 * 
 * @return			Plugin_Handled to block function from running, Plugin_Continue to allow it
 */
forward Action hxOnEndLocalScript();

/**
 * Called when the LocalScript vscript scope is cleared of any running scripts
 */
forward void hxOnEndLocalScript_Post();

/**
 * Called when a director scripted event managed panic event is about to start
 * 
 * @param iWaves	amount of waves (each wave is separated by about 20 seconds. MegaMobSize director var controls the amount of commons per wave. If left as 0, the game will make it either 1 or 2 later depending on how far the current chapter is into the campaign) 
 * @return			Plugin_Handled to block function from running, Plugin_Continue to allow it
 */
forward Action hxOnStartPanicEvent(int &iWaves);

/**
 * Called when the LocalScript vscript scope is cleared of any running scripts
 * 
 * @param iWaves	amount of waves (each wave is separated by about 20 seconds. MegaMobSize director var controls the amount of commons per wave. If left as 0, the game will make it either 1 or 2 later depending on how far the current chapter is into the campaign) 
 */
forward void hxOnStartPanicEvent_Post(int iWaves);

/**
 * Called when a panic event ends
 * 
 * @param bInterrupt	if it was ended with hxEndPanicEvent native, this will be true
 */
forward void hxOnPanicEventEnded(bool bInterrupt);

/**
 * called when a finale is starting
 * 
 * @param iFinaleType	type of finale (gauntlet, regular)
 */
forward void hxOnFinaleStarted(int iFinaleType);

/**
 * called when a scavenge progress display hud element is turned on
 */
forward void hxOnScavengeProgressDisplayTurnOn();

/**
 * called when a scavenge progress display hud element is turned off
 */
forward void hxOnScavengeProgressDisplayTurnOff();

/**
 * called just after a pool of nav areas for a direction is generated
 * 
 * @param iDirection	the spawn direction pool used
 * @param iZClass		the SI class used to generate it
 * @param aReturn		a pointer
 */
forward void hxOnCollectSpawnAreas_Pre(int iDirection, int iZClass);
forward void hxOnCollectSpawnAreas_Post(int iDirection, int iZClass, Address aReturn);

forward void hxOnResetMobTimer();
forward void hxOnResetSpecialTimers();

// solely for the forwards
forward void hxOnGetRandomPZSpawnPosition_Pre();
forward void hxOnGetRandomPZSpawnPosition_Post();
