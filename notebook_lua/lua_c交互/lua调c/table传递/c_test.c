#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int get_tab(lua_State *L)
{
	// 创建table
	lua_newtable(L);

	int i;
	// k v 入栈
	char value[10] = {0};
	for (i = 0; i < 5; ++i) {
		sprintf(value, "value%d", i + 1);
		lua_pushnumber(L, i + 1);
		lua_pushstring(L, value);
		lua_settable(L, -3); // push 栈中的 -1 -2 即k v 两个元素
	}

	return 1;
}

int main()
{
	lua_State *L = luaL_newstate();
	// 加载所有lua库
	luaL_openlibs(L);
	// 注册被lua调用的函数
	lua_register(L, "gettab", get_tab);
	// 加载并执行指定的lua文件
	int error = luaL_dofile(L, "lua_test.lua");
	if (error) {
		perror("luaL_dofile error");
		exit(1);
	}
	// 获取lua中的domain函数
	lua_getglobal(L, "domain");
	// 执行domain函数
	error = lua_pcall(L, 0, 0, 0);
	if (error) {
		fprintf(stderr, "%s\n", lua_tostring(L, -1));
		lua_pop(L, -1);
	}

	lua_close(L);

	return 0;
}
