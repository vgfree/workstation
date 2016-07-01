#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#if 1
static int isquare(lua_State *L) {
	float rtrn = lua_tonumber(L, -1);
	printf("Top of square(), nbr = %f\n", rtrn);
	lua_pushnumber(L, rtrn * rtrn);

	return 1;
}

static int icube(lua_State *L) {
	int rtrn = lua_tonumber(L, -1);
	printf("Top of cube(), cube = %d\n", rtrn);
	lua_pushnumber(L, rtrn * rtrn * rtrn);

	return 1;
}

int luaopen_power(lua_State *L) {
	lua_register (
			L,
			"square",
			isquare
		     );
	lua_register (L, "cube", icube);

	return 0;
}
#endif

#if 0

# define luaL_newlib(L,l) (lua_newtable(L), luaL_register(L,NULL,l))

int luaio_cannot_change(lua_State *L) {
	  return luaL_error(L, "table fields cannot be changed.");
}

static int isquare(lua_State *L) {
	float rtrn = lua_tonumber(L, -1);
	printf("Top of square(), nbr = %f\n", rtrn);
	lua_pushnumber(L, rtrn * rtrn);

	return 1;
}

static int icube(lua_State *L) {
	int rtrn = lua_tonumber(L, -1);
	printf("Top of cube(), cube = %d\n", rtrn);
	lua_pushnumber(L, rtrn * rtrn * rtrn);

	return 1;
}

int luaopen_power(lua_State *L) {
	luaL_Reg lib[] = {
		{ "square", isquare},
		{ "cube", icube},
		{ "__newindex", luaio_cannot_change},
		{ NULL, NULL  }

	};

	lua_createtable(L, 0, 0);

	luaL_newlib(L, lib);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	lua_pushliteral(L, "metatable is protected.");
	lua_setfield(L, -2, "__metatable");

	lua_setmetatable(L, -2);

	return 1;
}

#endif
