#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdlib.h>
#include <stdio.h>

int main()
{
	lua_State *L;
	L = luaL_newstate();
	luaL_openlibs(L);
	int status = luaL_loadfile(L, "./script.lua");
	printf("status = %d\n", status);
	if (status) {
		perror("luaL_dofile error");
		exit(1);
	}
	lua_newtable(L);

	lua_call(L, 1, 0);

	lua_getglobal(L, "global");
	printf("ret = %s\n", lua_tostring( L, -1));
	lua_pushnumber(L, 1);
	printf("ret = %s\n", lua_tostring( L, -1));
	lua_gettable(L, -2);
	printf("ret = %s\n", lua_tostring( L, -1));
	/*
	   lua_pushstring( L, "sid");
	   lua_gettable( L, -2  );
	   printf("%s\n", lua_tostring( L, -1  ));
	   */
	return 0;
}
