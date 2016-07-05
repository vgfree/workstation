main.c 中 smart_vms_call 函数是在 g_smart_cfg_list.vmsys_init = smart_vms_init; 语句中初始化

smart_vms_init
programs/RTAP/src/smart_evcoro_lua_api.c
在这个函数中,先通过lua_register()注册函数

error = luaL_dofile(L, "lua/core/init.lua"); 通过这个函数加载open库中的文件

error = luaL_dofile(L, "lua/core/start.lua");
app_call_by_msg();

可调用redis mysql


1. 初始化线程池, 将task_worker与线程绑定bind
2. 启动for循环接收  recv_app_msg(&recv_msg, &more, -1)
3. 有数据时, 执行report操作
task_report(void *user, void *task)  也即是将接收到的数据执行push
4. 在bind程序中 执行任务的是work函数, 而work函数中, lookup函数主要监视task中是否有数据,
task_handle负责具体的执行
lookup函数在task中有数据时, 将数据pull出来
5. 现在要执行task_handle 函数, 这里的操作比较多
首先拿数据
*p_task = &((struct user_task *)evcoro->task)[step]
然后,判断lua虚拟机是否存在
if (p_VMS->L) {
	L = p_VMS->L;
}
else {
	L = lua_vm_init();
	evcoro->VMS[step].L = L;
}
存在就直接用, 不存在就要init了
init内容也很多lua_vm_init 也要初始化redis mysql
OK, 准备工作做完了, 后面就是轻车熟路了
