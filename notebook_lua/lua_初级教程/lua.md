### Unit 24 C API 概览

C 和 Lua 之间通信通过一个虚拟的 **栈**。

#### 1. 示例程序
```c
#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
int main (void)
{
        char buff[256];
        int error;
        lua_State * L = lua_open(); // opens Lua
        luaopen_base(L); // opens the basic library
        luaopen_table(L); // opens the table library
        luaopen_io(L); // opens the I/O library
        luaopen_string(L); // opens the string lib.
        luaopen_math(L); // opens the math lib.

        while (fgets(buff, sizeof(buff), stdin) != NULL)
        {
                error = luaL_loadbuffer(L, buff, strlen(buff),
                        "line") || lua_pcall(L, 0, 0, 0);
                if (error)
                {
                        fprintf(stderr, "%s", lua_tostring(L, -1));
                        lua_pop(L, 1);// pop error message from the stack
                }
        }

        lua_close(L);
        return 0;
}
```
将此头文件包含进C++程序中
```c
// lua.hpp

extern "C" {
#include <lua.h>
}
```
#### 2. 堆栈
LIFO规则

**压入元素**
```c
// API 压栈函数

void lua_pushnil (lua_State * L);
void lua_pushboolean (lua_State * L, int bool);
void lua_pushnumber (lua_State * L, double n);
void lua_pushlstring (lua_State * L, const char * s, size_t length); // 任意字符串
void lua_pushstring (lua_State * L, const char * s); // C语言风格字符串
```
```c
int lua_checkstack (lua_State * L, int sz); // 检测栈大小
```
**查询元素**
```c
int lua_is... (lua_State *L, int index); // 检查一个元素是否是一个指定的类型
// 特别的 lua_isnumber(), lua_isstring() 检查是否能转换为指定的类型
```

`lua_type()` 返回栈中元素类型           
在 lua.h 中每种类型都被定义为一个常量
`LUA_TNIL、
LUA_TBOOLEAN 、 LUA_TNUMBER 、 LUA_TSTRING 、 LUA_TTABLE 、LUA_TFUNCTION、
LUA_TUSERDATA 、 LUA_TTHREAD`

```c
// 从栈中获得值

int lua_toboolean (lua_State * L, int index);
double lua_tonumber (lua_State * L, int index);
const char * lua_tostring (lua_State * L, int index);
size_t lua_strlen (lua_State * L, int index);
```
```c
int lua_gettop (lua_State * L); // 返回栈中元素个数
void lua_settop (lua_State * L, int index); // 设置栈顶(堆栈中元素个数)为一个指定值
void lua_pushvalue (lua_State * L, int index); //
void lua_remove (lua_State * L, int index);
void lua_insert (lua_State * L, int index);
void lua_replace (lua_State * L, int index);
```
```c
lua_register(L, "C函数名(全局)"， C函数指针)；
lua_call(L, 参数个数， 返回值个数)；
luaL_loadfile(L， "test.lua"); // 执行lua脚本
```
