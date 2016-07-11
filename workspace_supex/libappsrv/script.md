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

********************************************************************************
上行
0 upstream
1 CID
2 {content}

bind
{"uid":"UID"}

聊天时

0 status
1 conneted/closed
2 CID

下行
0 setting
1 status/uidmap/gidmap
2 CID
3 closed/uid/gid

0 downstream
1 cid/uid/gid
2 CID/UID/GID
3 {content}  (包含CID)

单聊
{
    "action":"chat",
    "chatToken":"abcdefghij",
    "timestamp":"1458266656",
    "content":
    {
        "fromAccountID"："15618873958",
        "fromTimestamp":"1458266656",
        "fromLat":35.12345,
        "fromLon":121.12345,
        "toAccountID":"13661683669",
        "chatID"："136616836691366168366913661683669",
        "fileType":0,
        "duration":5,
        "isBytes":1,
        "fileServer":0,
        "fileUrl":""
    }
}
群聊
{
    "action":"chatGroup",
    "chatToken":"abcdefghij",
    "timestamp":"1458266656",
    "content":
    {
        "fromAccountID"："15618873958",
        "fromTimestamp":"1458266656",
        "fromLat":35.12345,
        "fromLon":121.12345,
        "chatGroupID":"15618873958cg001",
        "chatID"："136616836691366168366913661683669",
        "duration":5,
        "isBytes":1,
        "fileType":1,
        "fileServer":0,
        "fileUrl":""
    }
}

```js
local zmq_api = require('zmq_api')                                              

module('settings', package.seeall)                                              


local function power_on_settings()                                              
        local tag = cjson.encode(                                               
        {                                                                       
                ["powerOn"] = {                                                 
                        [1] = supex.get_our_body_table()["IMEI"]                
                }                                                               
        }                                                                       
        )                                                                       
        local result_tab = {                                                    
                [1] = tag,                                                      
                [2] = supex.get_our_body_data()                                 
        }                                                                       
        local ok = zmq_api.cmd("damR", "send_table", result_tab)    
				// damR 下发服务iqi, 需要在link.lua中配置
				// send_table 调用的zmq下发函数
				// result_tab 需要下发的table
				// 那么我需要首先配置gateway 和 login 两个服务器ip point
				// 然后在lua中封装调用发送的数据table             
end

```
