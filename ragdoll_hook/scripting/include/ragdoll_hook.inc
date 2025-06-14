#if defined _hardx_included_
	#endinput
#endif
#define _hardx_included_

/**
 * Forwards for when a ragdoll is being created for a player
 * @param	iPlayer			the player client to create a ragdoll for
 * @param	aTakeDamageInfo	CTakeDamageInfo object used for the ragdoll creation
 * @param	bPluginCreated	true if the function was called via the native CreateRagdoll, false if called by the game
 * 
 * @return 	Action			Plugin_Handled to block function from running, Plugin_Continue to allow it		
 */
forward Action OnRagdollCreated(int iPlayer, Address aTakeDamageInfo, bool bPluginCreated);

/**
 * Forwards for when a ragdoll is being created for a player
 * @param	iPlayer			the player client to create a ragdoll for
 * @param	iRagdoll		the ragdoll entity index that is being created
 * @param	aTakeDamageInfo	CTakeDamageInfo object used for the ragdoll creation
 * @param	bPluginCreated	true if the function was called via the native CreateRagdoll, false if called by the game
 * 
 * @return 	void	
 */
forward void OnRagdollCreated_Post(int iPlayer, int iRagdoll, Address aTakeDamageInfo, bool bPluginCreated);

/**
 * Creates a ragdoll for a player
 * @param	iPlayer			the player client to create a ragdoll for
 * @param	aTakeDamageInfo	CTakeDamageInfo object used for the ragdoll creation
 * 
 * @return 	int				the entity index of the created ragdoll, or -1 on failure
 */
native int CreateRagdoll(int iPlayer, Address aTakeDamageInfo);