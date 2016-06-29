#include <stdio.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

lua_State *L;

int luaadd(int x, int y)
{
	int sum;
	// 函数名入栈(lua中的函数名)
	lua_getglobal(L, "ad");
	// 第一个参数入栈
	lua_pushnumber(L, x);
	// 第二个参数入栈
	lua_pushnumber(L, y);
	// 调用函数, 两个输入参数, 一个返回值
	lua_call(L, 2, 1);
	// 获取结果
	sum = (int)lua_tonumber(L, -1);
	// 清空返回值
	lua_pop(L, 1);

	return sum;
}

int main()
{
	int sum;
	// 初始化虚拟栈
	L = lua_open();
	// 加载虚拟栈
	luaL_openlibs(L);
	// 加载脚本文件
	luaL_dofile(L, "add.lua");
	// 调用add函数
	sum = luaadd(10, 15);

	printf("The sum is %d\n", sum);

	// 清空虚拟栈
	lua_close(L);

	return 0;
}
