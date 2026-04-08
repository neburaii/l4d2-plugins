#pragma newdecls required
#pragma semicolon 1

TraceWrapper g_trace;

methodmap TraceFilter < MemoryBlock
{
	public bool ShouldHitEntity(int iEntity, int iMask)
	{
		return SDKCall(g_hSDK_TraceFilter_ShouldHitEntity, this.Address, iEntity, iMask);
	}

	public TraceType GetTraceType()
	{
		return SDKCall(g_hSDK_TraceFilter_GetTraceType, this.Address);
	}
}

methodmap TraceFilterSimple < TraceFilter
{
	public TraceFilterSimple(int iEntity, CollisionGroup collisionGroup)
	{
		MemoryBlock hFilter = new MemoryBlock(TRACEFILTERSIMPLE_STRUCT_SIZE);
		hFilter.StoreToOffset(g_iOffset_TraceFilterSimple_vtable, g_pTraceFilterSimple_vtable, NumberType_Int32);
		hFilter.StoreToOffset(g_iOffset_TraceFilterSimple_collisionGroup, collisionGroup, NumberType_Int32);
		hFilter.StoreToOffset(g_iOffset_TraceFilterSimple_extraCallback, 0, NumberType_Int32);

		Address entAddress = Address_Null;
		if (iEntity != INVALID_ENT_REFERENCE)
			entAddress = GetEntityAddress(iEntity);
		hFilter.StoreToOffset(g_iOffset_TraceFilterSimple_passEnt, entAddress, NumberType_Int32);

		return view_as<TraceFilterSimple>(hFilter);
	}
}

enum struct TraceWrapper
{
	TraceFilter filter;
	Handle plugin;
	Function callback;
}

bool TraceEntityFilter_wrapper(int iEntity, int iMask, any data)
{
	if (g_trace.filter.ShouldHitEntity(iEntity, iMask) == false)
		return false;

	if (g_trace.callback != INVALID_FUNCTION)
	{
		Call_StartFunction(g_trace.plugin, g_trace.callback);
		Call_PushCell(iEntity);
		Call_PushCell(iMask);
		Call_PushCell(data);
		bool bResult;
		Call_Finish(bResult);

		return bResult;
	}

	return true;
}

bool TraceEntityFilter_internalOnly(int iEntity, int iMask)
{
	return g_trace.filter.ShouldHitEntity(iEntity, iMask);
}
