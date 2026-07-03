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
	VariantType_Bool,
	VariantType_Int,
	VariantType_Float,
	VariantType_Vector,
	VariantType_EVal,
	VariantType_String
};

void Util_ReadVariant(DHookParam hParams, int iParamNum, Variant output)
{
	output.type = hParams.GetObjectVar(iParamNum, VARIANT_TYPE, ObjectValueType_Int);
	VariantType variantType = GetVariantType(output.type);

	switch (variantType)
	{
		case VariantType_None:
			output.type = FieldType_Void;

		case VariantType_Bool:
			output.value[0] = hParams.GetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Bool);

		case VariantType_Int:
			output.value[0] = hParams.GetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Int);

		case VariantType_Float:
			output.value[0] = hParams.GetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Float);

		case VariantType_Vector:
			hParams.GetObjectVarVector(iParamNum, VARIANT_UNION, ObjectValueType_Vector, output.value);

		case VariantType_EVal:
			output.value[0] = hParams.GetObjectVar(iParamNum, VARIANT_EVAL, ObjectValueType_Int);

		case VariantType_String:
			hParams.GetObjectVarString(iParamNum, VARIANT_UNION, ObjectValueType_CharPtr, output.string, sizeof(output.string));
	}
}

void Util_WriteVariant(DHookParam hParams, int iParamNum, Variant input)
{
	hParams.SetObjectVar(iParamNum, VARIANT_TYPE, ObjectValueType_Int, input.type);
	VariantType variantType = GetVariantType(input.type);

	switch (variantType)
	{
		case VariantType_Bool:
			hParams.SetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Bool, input.value[0]);

		case VariantType_Int:
			hParams.SetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Int, input.value[0]);

		case VariantType_Float:
			hParams.SetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Float, input.value[0]);

		case VariantType_Vector:
			hParams.SetObjectVarVector(iParamNum, VARIANT_UNION, ObjectValueType_Vector, input.value);

		case VariantType_EVal:
			hParams.SetObjectVar(iParamNum, VARIANT_EVAL, ObjectValueType_Int, input.value[0]);

		case VariantType_String:
		{
			Address pString = CreateStringPointer(input.string);
			hParams.SetObjectVar(iParamNum, VARIANT_UNION, ObjectValueType_Int, pString);
		}
	}
}

/**********
 * helpers
 *********/

static VariantType GetVariantType(FieldType fieldType)
{
	switch (fieldType)
	{
		case FieldType_Bool:
			return VariantType_Bool;

		case FieldType_Char, FieldType_Short, FieldType_Int, FieldType_Color32:
			return VariantType_Int;

		case FieldType_Float:
			return VariantType_Float;

		case FieldType_Vector, FieldType_PosVector:
			return VariantType_Vector;

		case FieldType_EHandle, FieldType_ClassPtr:
			return VariantType_EVal;

		case FieldType_String:
			return VariantType_String;
	}

	return VariantType_None;
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
