#pragma newdecls required
#pragma semicolon 1

/**
 * not an SDKCall to the same internal function because that function doesn't use the flags
 * param to set the ignoreBlockers arg for GetNearestNavArea_Pos. i strongly believe it
 * should, since otherwise setting that flag here is uesless
 */
Address Util_GetNearestNavArea_Entity(int iEntity, int flags, float fDistance)
{
	Address nav;
	nav = SDKCall(g_hSDK_GetNavArea_Entity, g_pNavMesh, iEntity, flags, 120.0);
	if (!nav)
	{
		float vPos[3];
		GetEntityAbsOrigin(iEntity, vPos);

		nav = SDKCall(g_hSDK_GetNearestNavArea_Pos, g_pNavMesh, vPos, 0, fDistance,
			flags & GetNavFlag_CheckLOS, flags & GetNavFlag_RequireGround, flags & GetNavFlag_IgnoreBlockers);
	}

	return nav;
}

/************
 * NavLadder
 ***********/

enum LadderOrigin
{
	Ladder_Top,
	Ladder_Bottom
};

void Util_NavLadder_GetOrigin(Address ladder, LadderOrigin origin, float vPos[3])
{
	int iOffset = g_iOffset_NavLadder_origin
		+ (view_as<int>(origin) * 12);

	LoadVectorFromAddress(ladder + view_as<Address>(iOffset), vPos);
}


Address Util_NavLadder_GetConnection(Address ladder, any connection)
{
	return LoadFromAddress(ladder + view_as<Address>(g_iOffset_NavLadder_connectedNavs + (connection * 4)), NumberType_Int32);
}

int Util_NavLadder_GetEntity(Address ladder)
{
	return LoadEntityFromHandleAddress(ladder + view_as<Address>(g_iOffset_NavLadder_ehandle));
}

/************
 * NavArea
 ***********/

void Util_NavArea_GetCenter(Address nav, float vBuffer[3])
{
	LoadVectorFromAddress(nav + view_as<Address>(g_iOffset_NavArea_center), vBuffer);
}

float Util_NavArea_GetFlow(Address nav, int type)
{
	return LoadFromAddress(nav + view_as<Address>(
		g_iOffset_NavArea_flow + (type * 4)), NumberType_Int32);
}

CUtlVectorUltraConservative Util_NavArea_GetElevatorAreaList(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_elevatorConnectedAreas), NumberType_Int32);
}

CUtlVectorUltraConservative Util_NavArea_GetAdjacentAreaList(Address nav, int iDirection)
{
	return LoadFromAddress(nav + view_as<Address>(
		g_iOffset_NavArea_adjacentList + (iDirection * 4)), NumberType_Int32);
}

CUtlVectorUltraConservative Util_NavArea_GetIncomingConnectionList(Address nav, int iDirection)
{
	return LoadFromAddress(nav + view_as<Address>(
		g_iOffset_NavArea_incomingList + (iDirection * 4)), NumberType_Int32);
}

int Util_NavArea_GetArrayListOfAdjacentAreas(Address nav, int iDirection, ArrayList hArray)
{
	int iWritten = 0;
	CUtlVectorUltraConservative list;

	if (iDirection == view_as<int>(NavDir_All))
	{
		for (int dir = 0; dir < view_as<int>(NavDir_All); dir++)
		{
			list = Util_NavArea_GetAdjacentAreaList(nav, dir);
			iWritten += list.GetArrayListPair(hArray);
		}
	}
	else
	{
		list = Util_NavArea_GetAdjacentAreaList(nav, iDirection);
		iWritten += list.GetArrayListPair(hArray);
	}

	return iWritten;
}

int Util_NavArea_GetArrayListOfIncomingConnections(Address nav, int iDirection, ArrayList hArray)
{
	int iWritten = 0;
	CUtlVectorUltraConservative list;

	if (iDirection == view_as<int>(NavDir_All))
	{
		for (int dir = 0; dir < 4; dir++)
		{
			list = Util_NavArea_GetIncomingConnectionList(nav, dir);
			iWritten += list.GetArrayListPair(hArray);
		}
	}
	else
	{
		list = Util_NavArea_GetIncomingConnectionList(nav, iDirection);
		iWritten += list.GetArrayListPair(hArray);
	}

	return iWritten;
}

float Util_NavArea_GetZDeltaAtEdgeToArea(Address thisNav, Address externalNav)
{
	return SDKCall(g_hSDK_GetZDeltaAtEdgeToArea, thisNav, externalNav);
}

int Util_NavArea_GetBaseAttributes(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_BaseAttributes), NumberType_Int32);
}

int Util_NavArea_GetSpawnAttributes(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_SpawnAttributes), NumberType_Int32);
}

CUtlVectorUltraConservative Util_NavArea_GetLadderList(Address nav, any direction)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_connectedLadders + (direction * 4)), NumberType_Int32);
}

int Util_NavArea_GetArrayListOfLadders(Address nav, int iDirection, ArrayList hArray)
{
	CUtlVectorUltraConservative list = Util_NavArea_GetLadderList(nav, iDirection);

	return list.GetArrayList(hArray);
}

bool Util_NavArea_GetNextEscapeStepIsRecord(Address nav, float fRecordFlow, float &fNavFlow)
{
	if (Util_NavArea_GetBaseAttributes(nav) & (NavBase_TankOnly|NavBase_MobOnly|NavBase_Playerclip))
		return false;

	fNavFlow = Util_NavArea_GetFlow(nav, FlowType_Progress);
	return fNavFlow > fRecordFlow;
}

float Util_NavArea_GetCornerX_Positive(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerPx), NumberType_Int32);
}

float Util_NavArea_GetCornerX_Negative(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerNx), NumberType_Int32);
}

float Util_NavArea_GetCornerY_Positive(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerPy), NumberType_Int32);
}

float Util_NavArea_GetCornerY_Negative(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerNy), NumberType_Int32);
}

float Util_NavArea_GetCornerZ_PositivePositive(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerPPz), NumberType_Int32);
}

float Util_NavArea_GetCornerZ_PositiveNegative(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerPNz), NumberType_Int32);
}

float Util_NavArea_GetCornerZ_NegativeNegative(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerNNz), NumberType_Int32);
}

float Util_NavArea_GetCornerZ_NegativePositive(Address nav)
{
	return LoadFromAddress(nav + view_as<Address>(g_iOffset_NavArea_cornerNPz), NumberType_Int32);
}

/*************
 * NavAreaSet
 ************/

void Util_NavAreaSet_SetCount(CUtlVector set, int iNewCount)
{
	int iOldCount = set.count;
	int iDifference = iNewCount - iOldCount;

	if (iDifference == 0) return;

	if (iDifference > 0)
	{
		for (int i = 0; i < iDifference; i++)
		{
			Util_NavAreaSet_Push(set, view_as<Address>(0));
		}
	}
	else
	{
		set.count = iNewCount;
	}
}

int Util_NavAreaSet_Push(CUtlVector set, Address nav)
{
	switch (g_OS)
	{
		case OS_Linux:
		{
			/** CUtlVector<>::InsertBefore() */
			SDKCall(g_hSDK_NavAreaSetPush, set, set.count, nav);

			return set.count - 1;
		}
		case OS_Windows: // TODO - test this!! you have no idea if it works or not
		{
			int iCount = set.count;
			int iSize = set.size;

			if (iSize < iCount + 1)
			{
				/** CUtlVector<>::GrowVector() */
				SDKCall(g_hSDK_NavAreaSetPush, set, (iCount - iSize) + 1);
			}

			set.Set(iCount, nav);
			set.count = iCount + 1;
			set.ResetListPointer();

			return iCount;
		}
	}

	return 0;
}
