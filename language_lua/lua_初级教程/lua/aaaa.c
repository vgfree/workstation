#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define lua_c

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"
typedef struct  
{  
    int x;  
    int y;  
    int z;  
}TData;  
  
static int getAttribute(lua_State* L)  
{  
    TData *data = (TData*)lua_touserdata(L, 1);   
    char * attribute = luaL_checkstring(L, 2);   
    int result = 0;  
    if(attribute == "x")  
    {     
        result = data->x;  
    }     
    else if(attribute == "y")  
    {     
        result = data->y;  
    }     
    else  
    {     
        result = data->z;  
    }  
    lua_pushnumber(L, result);  
    return 1;  
}  
  
static struct luaL_reg dataLib[] = {  
    {"__index", getAttribute},  
    {NULL, NULL}  
};  
  
void getMetaTable(lua_State* L, luaL_reg* methods)  
{  
    lua_pushlightuserdata(L, methods);  
    lua_gettable(L, LUA_REGISTRYINDEX);  
    if (lua_isnil(L, -1)) {  
        /* not found */  
        lua_pop(L, 1);  
  
        lua_newtable(L);  
        luaL_register(L, NULL, methods);  
  
        lua_pushlightuserdata(L, methods);  
        lua_pushvalue(L, 1);  
        lua_settable(L, LUA_REGISTRYINDEX);  
    }  
}  
  
int main()  
{  
    const char* filename = "testa.lua";  
    lua_State *lua = lua_open();  
    if (lua == NULL)  
    {  
        fprintf(stderr, "open lua failed");  
        return -1;  
    }  
    luaL_openlibs(lua);  
  
    TData input = {1, 2, 999};  
    lua_pushlightuserdata(lua, &input);  
    getMetaTable(lua, dataLib);  
    lua_setmetatable(lua, -2);  
    lua_setglobal(lua, "input");  
    if (luaL_dofile(lua, filename))  
    {  
        printf("load file %s failed", filename);  
    }  
    lua_getglobal(lua, "get");  
    int output = lua_tointeger(lua, 0);  
    printf("output=%d\n",output);
    return 0;  
}
