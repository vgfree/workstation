#include <stdio.h>
#include <lua.h>        // lua_开头的基础函数 
#include <lauxlib.h>    // 定义辅助库
#include <lualib.h>
int main (void)
{
        char buff[256];
        int error;
        lua_State *L = lua_open();// 创建新的Lua环境
        luaopen_base(L);/* opens the basic library */
        luaopen_table(L); /* opens the table library */
        luaopen_io(L); /* opens the I/O library */
        luaopen_string(L); /* opens the string lib. */
        luaopen_math(L); /* opens the math lib. */

        while (fgets(buff, sizeof(buff), stdin) != NULL) 
        {
                error = luaL_loadbuffer(L, buff, strlen(buff),"line") || lua_pcall(L, 0, 0, 0);// lua_pcall 调用Lua函数
                if (error) 
                {
                        fprintf(stderr, "%s", lua_tostring(L, -1));
                        lua_pop(L, 1);/* pop error message from the stack */
                }
        }

        lua_close(L);
        return 0;
}
