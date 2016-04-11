#ifndef _MODULE_H_
#define _MODULE_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef USERDATADEMO1_EXPORTS
#define USERDATADEMO1_EXPORTS _declspec(dllexport)
#else
#define USERDATADEMO1_EXPORTS _declspec(dllimport)
#endif

USERDATADEMO1_EXPORTS int luaopen_userdatademo1(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif