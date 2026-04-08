#pragma newdecls required
#pragma semicolon 1

enum struct SDKPrep
{
	char buffer[256];
	bool failed;

	/**
	 * Starts the preparation of an SDK call, setting the calling information
	 * from a signature in a GameData file
	 *
	 * @param type          Type of function call this will be.
	 * @param source		whether to look in Offsets or Signatures
	 * @param sName			Find this signature or offset in the GameData file
	 */
	void Start(SDKCallType type, SDKFuncConfSource source, const char[] sName)
	{
		this.failed = false;
		StartPrepSDKCall(type);

		if (source == SDKConf_Address)
		{
			/** handled SDKConf_Address this way so that our special rule for CALL::
			 * prefixed gamedata entries is handled */
			Address addr = LoadAddress(sName);

			if (!PrepSDKCall_SetAddress(addr))
			{
				LogError("failed to create SDKCall for address '%s'", sName);
				this.failed = true;
				return;
			}
		}
		else if (!PrepSDKCall_SetFromConf(g_hGameData, source, sName))
		{
			LogError("failed to create SDKCall for '%s': couldn't load from gamedata", sName);
			this.failed = true;

			return;
		}

		strcopy(this.buffer, sizeof(this.buffer), sName);
	}

	/**
	 * Adds a parameter to the calling convention. This should be called in normal ascending order.
	 *
	 * @param type          Data type to convert to/from.
	 * @param pass          How the data is passed in C++.
	 * @param decflags      Flags on decoding from the plugin to C++.
	 * @param encflags      Flags on encoding from C++ to the plugin.
	 *
	 * @error               Parameter limit for SDK calls reached.
	 */
	void Param(SDKType type, SDKPassMethod pass, int decflags=0, int encflags=0)
	{
		if (this.failed) return;

		PrepSDKCall_AddParameter(type, pass, decflags, encflags);
	}

	/**
	 * Sets the return information of an SDK call. Do not call this if there is no return data.
	 * This must be called if there is a return value (i.e. it is not necessarily safe to ignore
	 * the data).
	 *
	 * @param type          Data type to convert to/from.
	 * @param pass          How the data is passed in C++.
	 * @param decflags      Flags on decoding from the plugin to C++.
	 * @param encflags      Flags on encoding from C++ to the plugin.
	 */
	void Return(SDKType type, SDKPassMethod pass, int decflags=0, int encflags=0)
	{
		if (this.failed) return;

		PrepSDKCall_SetReturnInfo(type, pass, decflags, encflags);
	}

	/**
	 * Finalizes an SDK call preparation and set the resultant Handle.
	 *
	 * @param hSDK		Store the created SDKCall into this handle. It will be INVALID_HANDLE on failure
	 */
	void End(Handle &hSDK)
	{
		if (this.failed) return;

		hSDK = EndPrepSDKCall();
		if (hSDK == INVALID_HANDLE)
			LogError("could not create '%s' SDKCall handle!", this.buffer);
	}
}
