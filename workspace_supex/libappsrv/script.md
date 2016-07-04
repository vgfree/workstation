main.c 中 smart_vms_call 函数是在 g_smart_cfg_list.vmsys_init = smart_vms_init; 语句中初始化

smart_vms_init
programs/RTAP/src/smart_evcoro_lua_api.c
在这个函数中,先通过lua_register()注册函数

error = luaL_dofile(L, "lua/core/init.lua"); 通过这个函数加载open库中的文件

error = luaL_dofile(L, "lua/core/start.lua");
 app_call_by_msg();
