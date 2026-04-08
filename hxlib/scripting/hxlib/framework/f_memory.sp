#pragma newdecls required
#pragma semicolon 1

/**
 * load offset from gamedata
 *
 * @param sKey		Offset key in gamedata to read from
 *
 * @return			offset as an integer
 */
int LoadOffset(const char[] sKey)
{
	int offset = g_hGameData.GetOffset(sKey);
	if (offset == -1)
		SetFailState("failed to load offset: %s", sKey);

	return offset;
}

/**
 * load address from gamedata
 *
 * @param sKey		Address key in gamedata to read from
 *
 * @return 			address
 */
Address LoadAddress(const char[] sKey)
{
	Address addr = g_hGameData.GetAddress(sKey);
	if (!addr)
		SetFailState("failed to load address: %s", sKey);

	/** label that this address is for a CALL (e8) instruction. follow the offset
	 * in the instruction to instead return the address of the function it points to
	 */
	if (StrContains(sKey, "CALL::") == 0)
	{
		addr += LoadFromAddress(addr, NumberType_Int32) + view_as<Address>(4);
	}

	return addr;
}

/**
 * get an address from an already loaded address and an offset from gamedata
 *
 * @param addr		the base address to offset from
 * @param sKey		Offset key in gamedata to read from
 *
 * @return			address at addr + offset
 */
any LoadAddressOffset(Address addr, const char[] sKey)
{
	int offset = LoadOffset(sKey);

	Address result = LoadFromAddress(addr + view_as<Address>(offset), NumberType_Int32);
	if (result == Address_Null)
		SetFailState("[LoadAddressOffset] failed to load 0x%X + %i", addr, offset);

	return result;
}
