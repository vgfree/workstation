#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdlib.h>
#include <stdio.h>

int main(void)
{
	int status, result, i;
	double sum;
	lua_State *L;
	L = luaL_newstate();
	luaL_openlibs(L);
	/* 把lua程序搞进来*/
	status = luaL_loadfile(L, "script.lua");
	if (status) {
		fprintf(stderr, "bad, bad file\n");
		exit(1);

	}
	lua_newtable(L);
	for (i = 1; i <= 5; i++) {
		lua_pushnumber(L, i);   /* 压入table 索引 */
		lua_pushnumber(L, i*2); /* 压入值 */
		lua_rawset(L, -3);      /* 保存这一双于table中 */
	}

	lua_setglobal(L, "foo");
	result = lua_pcall(L, 0, LUA_MULTRET, 0);
	if (result) {
		fprintf(stdout, "bad, bad script\n");
		exit(1);
	}    /* 获得堆栈顶的值*/
	sum = lua_tonumber(L, lua_gettop(L));
	if (!sum) {
		fprintf(stdout, "lua_tonumber() failed!\n");
		exit(1);
	}
	fprintf(stdout, "Script returned: %.0f\n", sum);
	lua_pop(L, 1);  /* 把返回的值弹出堆栈，既清掉这个值*/
	lua_close(L);
	return 0;

}
