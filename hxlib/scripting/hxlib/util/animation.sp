#pragma newdecls required
#pragma semicolon 1

#define HASH_VALUE_TYPE_SIZE	16

StudioHdr Util_GetStudioHdr(int iEntity)
{
	Address addr = GetEntityAddress(iEntity);
	return LoadFromAddress(addr + view_as<Address>(g_iOffset_StudioHdr), NumberType_Int32);
}

methodmap StudioHdr < Address
{
	property ActivityToSequenceMapper activityToSequenceMapper
	{
		public get()
		{
			Address pMapper = LoadFromAddress(this + view_as<Address>(
				g_iOffset_ActivityToSequenceMapper), NumberType_Int32);

			if (pMapper == Address_Null)
			{
				pMapper = SDKCall(g_hSDK_FindActivityToSequenceMapper, this);
				StoreToAddress(this + view_as<Address>(
					g_iOffset_ActivityToSequenceMapper), pMapper, NumberType_Int32);
			}

			return view_as<ActivityToSequenceMapper>(pMapper);
		}
	}
}

methodmap ActivityToSequenceMapper < Address
{
	property SequenceTupleList sequenceTuples
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ActivityToSequenceMapper_SequenceTuples), NumberType_Int32);
		}
	}

	property int sequenceTuplesCount
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_ActivityToSequenceMapper_SequenceTuplesCount), NumberType_Int32);
		}
	}

	property CUtlHash hashMapper
	{
		public get()
		{
			return view_as<CUtlHash>(this + view_as<Address>(g_iOffset_ActivityToSequenceMapper_Hash));
		}
	}

	/** not SDKCall because i couldn't find it in windows binary (not called anywhere, likely optimized out) */
	public SequenceTupleList GetSequencesForActivity(int iActivity, int &iSeqTotal, int &iSeqWeight)
	{
		HashValueType element;
		if (!this.hashMapper.GetElement(iActivity, element))
			return SequenceTupleList_Null;

		SequenceTupleList list = this.sequenceTuples + view_as<SequenceTupleList>(element.startingIdx * 4);
		iSeqTotal = element.count;
		iSeqWeight = element.weight;

		return list;
	}

	public SequenceTupleList GetSequences(int &iSeqTotal)
	{
		iSeqTotal = this.sequenceTuplesCount;
		return this.sequenceTuples;
	}
}

methodmap CUtlHash < CUtlVector
{
	property bool powerOfTwo
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_CUtlHash_powerOfTwo), NumberType_Int8);
		}
	}

	property any modMask
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_CUtlHash_modMask), NumberType_Int32);
		}
	}

	public bool GetElement(int iActivity, HashValueType &element)
	{
		int key = SDKCall(g_hSDK_HashInt, iActivity);

		/** get bucket through modulo of key */
		if (this.powerOfTwo)
			key = key & this.modMask;
		else key = key % this.count;

		if (key >= this.count || key < 0)
			return false;

		HashBucketList bucket = this.Get(key);
		int iBucketSize = bucket.count;

		for (int i = 0; i < iBucketSize; i++)
		{
			element = bucket.Get(i);
			if (iActivity == element.activity)
				return true;
		}

		return false;
	}

	public HashBucketList Get(int iIndex)
	{
		return view_as<HashBucketList>(this.list + view_as<Address>(iIndex * CUTLVECTOR_STRUCT_SIZE));
	}
}

methodmap HashBucketList < CUtlVector
{
	public HashValueType Get(int iIndex)
	{
		return view_as<HashValueType>(this.list + view_as<Address>(iIndex * HASH_VALUE_TYPE_SIZE));
	}
}

methodmap HashValueType < Address
{
	property int activity
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_HashValueType_activity), NumberType_Int32);
		}
	}

	property int startingIdx
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_HashValueType_startingIdx), NumberType_Int32);
		}
	}

	property int count
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_HashValueType_count), NumberType_Int32);
		}
	}

	property int weight
	{
		public get()
		{
			return LoadFromAddress(this + view_as<Address>(
				g_iOffset_HashValueType_weight), NumberType_Int32);
		}
	}
}


