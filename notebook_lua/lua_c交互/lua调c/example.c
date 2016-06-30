/*
 * gcc -o example example.c -I/usr/local/include/ -L/usr/local/lib/ -lm -llua
 */

#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

// 待Lua调用的C注册函数
static int add2(lua_State *L)
{
	// 检查栈中参数是否合法,1数字表示lua调用时的第一个参数
	// 如果lua代码在调用时传参不为number, 该函数将报错并终止程序执行
	double op1 = luaL_checknumber(L, 1);
	double op2 = luaL_checknumber(L, 2);
	// 将函数结果压栈,如果有多个返回值, 可以多次压栈
	lua_pushnumber(L, op1 + op2);
	// 提示该C函数的返回值数量, 即压栈的返回值数量
	return 1;
}

static int sub2(lua_State *L)
{
	double op1 = luaL_checknumber(L, 1);
	double op2 = luaL_checknumber(L, 2);
	lua_pushnumber(L, op1 - op2);

	return 1;
}

const char *testfunc = "print(add2(1.0, 2.0)) print(sub2(20.1, 19))";

int main()
{
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	// 将指定的函数注册为lua的全局函数变量,其中第一个字符串参数为lua代码在
	// 调用C函数时使用的全局函数名, 第二个参数为实际C函数的指针
	lua_register(L, "add2", add2);
	lua_register(L, "sub2", sub2);
	// 在注册完所有C函数后, 即可在Lua的代码块中使用这些已经注册的C函数了
	if (luaL_dostring(L, testfunc)) {
		printf("failed to invoke.\n");
	}

	lua_close(L);

	return 0;
}
