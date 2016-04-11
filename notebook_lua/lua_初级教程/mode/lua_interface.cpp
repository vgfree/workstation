extern "C"{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

LUA_API int luaopen_luainterface(lua_State *L);
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <iostream>

#include "./add.hpp"

//extern "C" LUA_API int luaopen_luainterface(lua_State *L);
using namespace std;
/* ===== INITIALISATION ===== */

#if !defined(LUA_VERSION_NUM) || LUA_VERSION_NUM < 502

/* Compatibility for Lua 5.1.
 *
 * luaL_setfuncs() is used to create a module table where the functions have
 * json_config_t as their first upvalue. Code borrowed from Lua 5.2 source.
 */
static void luaL_setfuncs(lua_State *l, const luaL_Reg *reg, int nup)
{
        int i;

        luaL_checkstack(l, nup, "too many upvalues");

        for (; reg->name != NULL; reg++) {              /* fill the table with given functions */
                for (i = 0; i < nup; i++) {             /* copy upvalues to the top */
                        lua_pushvalue(l, -nup);
                }

                lua_pushcclosure(l, reg->func, nup);            /* closure with those upvalues , and pop all of them*/
                lua_setfield(l, -(nup + 2), reg->name);
        }

        lua_pop(l, nup);        /* remove upvalues */
}
#endif

static int lua_add(lua_State *L)
{
        if (lua_gettop(L) != 2)
        {
                return luaL_error(L, "%s", "argument error");
        }

        int a = lua_tonumber(L, 1);
        if (a == NULL)
        {
                return luaL_error(L, "%s", "input == NULL");
        }

        int b = lua_tonumber(L, 2);
        if (b == NULL)
        {
                return luaL_error(L, "%s", "output == NULL");
        }

        add(a, b);
        
        return 0;
}

static const struct luaL_Reg lib[] = {
        { "lua_add", lua_add},
        { NULL, NULL}
};

int luaopen_luainterface(lua_State *L)
{
        luaL_register(L, "interface", lib);

        return 1;
}
