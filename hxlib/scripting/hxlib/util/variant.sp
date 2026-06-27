#pragma newdecls required
#pragma semicolon 1

/** offsets */
#define VARIANT_TYPE	16
#define VARIANT_EVAL	12
#define VARIANT_UNION	0

/** which data member of Variant struct does its fieldtype fit in */
enum VariantType
{
	VariantType_None,
	VariantType_Value,
	VariantType_String
};

void Util_ReadVariant(DHookParam hParams, int iParamNum, Variant output)
{
	output.type = hParams.GetObjectVar(iParamNum, VARIANT_TYPE, ObjectValueType_Int);

	int iSize = GetFieldTypeSize(output.type);
	VariantType structType = GetVariantType(output.type, iSize);

	switch (structType)
	{
		case VariantType_None:
		{
			output.type = FieldType_Void;
		}

		case VariantType_Value:
		{
			for (int i = 0; i < iSize; i++)
				output.value[i] = hParams.GetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Int);
		}

		case VariantType_String:
		{
			Address addr = hParams.GetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Int);
			LoadStringFromAddress(addr, output.string, sizeof(output.string));
		}
	}
}

void Util_WriteVariant(DHookParam hParams, int iParamNum, Variant input)
{
	hParams.SetObjectVar(iParamNum, VARIANT_TYPE, ObjectValueType_Int, input.type);

	int iSize = GetFieldTypeSize(input.type);
	VariantType structType = GetVariantType(input.type, iSize);

	switch (structType)
	{
		case VariantType_Value:
		{
			for (int i = 0; i < iSize; i++)
				hParams.SetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Int, input.value[i]);
		}

		case VariantType_String:
		{
			/** cleared at start of next frame. idk if this could cause problems or not */
			Address pString = CreateStringPointer(input.string);
			hParams.SetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Int, pString);
		}
	}
}

/**********
 * helpers
 *********/

static VariantType GetVariantType(FieldType fieldType, int iSize)
{
	if (fieldType == FieldType_String)
		return VariantType_String;

	/** object can only have 0xc bytes at most.
	 * any type exceeding this size should not be encountered. */
	if (iSize <= 0 || iSize > 0xc)
		return VariantType_None;

	return VariantType_Value;
}

/** in bytes */
static int GetFieldTypeSize(FieldType fieldType)
{
	switch (fieldType)
	{
		case FieldType_Void:
			return 0x0;
		case FieldType_Float:
			return 0x4;
		case FieldType_String:
			return 0x4;
		case FieldType_Vector:
			return 0xc;
		case FieldType_Quaternion:
			return 0x10;
		case FieldType_Int:
			return 0x4;
		case FieldType_Bool:
			return 0x1;
		case FieldType_Short:
			return 0x2;
		case FieldType_Char:
			return 0x1;
		case FieldType_Color32:
			return 0x4;
		case FieldType_Embedded:
			return 0x0; // unknown
		case FieldType_Custom:
			return 0x0; // unknown
		case FieldType_ClassPtr:
			return 0x4;
		case FieldType_EHandle:
			return 0x4;
		case FieldType_Edict:
			return 0x4;
		case FieldType_PosVector:
			return 0xc;
		case FieldType_Time:
			return 0x4;
		case FieldType_Tick:
			return 0x4;
		case FieldType_ModelName:
			return 0x4;
		case FieldType_SoundName:
			return 0x4;
		case FieldType_Input:
			return 0x4;
		case FieldType_Function:
			return (g_OS == OS_Windows) ? 0x4 : 0x8;
		case FieldType_VMatrix:
			return 0x40;
		case FieldType_VMatrixWorldspace:
			return 0x40;
		case FieldType_Matrix3X4Worldspace:
			return 0x24;
		case FieldType_Interval:
			return 0x8;
		case FieldType_ModelIndex:
			return 0x4;
		case FieldType_MaterialIndex:
			return 0x4;
		case FieldType_Vector2D:
			return 0x8;
		case FieldType_Int64:
			return 0x8;
		case FieldType_Vector4D:
			return 0x10;

		default: return 0x0;
	}
}

static Address CreateStringPointer(const char[] sValue)
{
	int iLen = strlen(sValue);
	MemoryBlock handle = new MemoryBlock(iLen + 1);

	for (int i = 0; i < iLen; i++)
		handle.StoreToOffset(i, sValue[i], NumberType_Int8);
	handle.StoreToOffset(iLen, '\0', NumberType_Int8);

	RequestFrame(DeleteVariantMemoryBlock, handle);
	return handle.Address;
}

static void DeleteVariantMemoryBlock(MemoryBlock hMemory)
{
	if (hMemory) delete hMemory;
}
