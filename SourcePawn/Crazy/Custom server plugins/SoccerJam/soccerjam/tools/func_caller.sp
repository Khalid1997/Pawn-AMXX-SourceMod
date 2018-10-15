
typedef I_void_void = function void();
typedef I_void_i = function void(int i);

void I_Call_void_void(I_void_void func)
{
	if (func != INVALID_FUNCTION)
	{
		Call_StartFunction(INVALID_HANDLE, func);
		Call_Finish();
	}
}