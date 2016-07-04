192.168.71.141
/root/work/supex/lib/libappsrv/test/test
功能: 接收coreexchange 发送的数据, 并根据解析结果下发数据

netstat -anlp | grep tcp
cd /root/work/supex/lib/libappsrv/test/
./test
cd messageGateway/
./messageGateway
cd lib/libappsrv/test/
./test

192.168.71.142
cd CoreExchangeNode/
./core_exchange_node
/root/work/supex/programs/CoreExchangeNode/test
./test 1 192.168.71.142

192.168.71.143
netstat -anlp | grep tcp
cd lib/libcomm/
make lib
cd utils/
make lib
cd loginServer/
./loginServer
cd settingServer/
./settingServer
cd UserInfoApi/
./UserInfoApi &




```C++
struct app_msg
{
        size_t          vector_size;
        struct iovec    vector[MAX_SPILL_DEPTH];
};
```
```
1. /root/recyle/supex/programs/RTAP/src/main.c
g_smart_cfg_list.func_info[APPLY_FUNC_ORDER].func = (TASK_VMS_FCB)smart_vms_call; 注册回调函数

2. 要找 TASK_VMS_FCB 一路找到了 lj_smart_util.h
int smart_vms_call(void *user, union virtual_system **VMS, struct adopt_task_node *task);
再找 adopt_task_node

3. 终于在 ./lib/libevcs/include/engine/adopt_tasks/adopt_task.h 找到了
typedef int (*TASK_VMS_FCB)(void *user, union virtual_system **VMS, struct adopt_task_node *task);

struct adopt_task_node                                                          
{                                                                               
        int             id;             /**< 任务ID，任务ID在任务属性池中对应一组任务额外属性*/

        uint64_t        cid;                                                    
        int             sfd;            /**< 套接字描述符*/                     

        char            type;           /**< 任务类型：线程池中所有线程响应、单个线程响应*/
        char            origin;         /**< 任务来源：框架内部、外部接口*/     

        int             index;                                                  
        char            *deal;          /**< 完成标志，指向调用层的局部变量的指针*/
        TASK_VMS_FCB    func;           /**< 任务回调*/                         
        int             last;                                                   

        void            *data;          /**< 任务内部资源*/                     
        long            size;           /**< 任务内部资源*/                     
        bool            freeable;                                               
};

4. 在 ./programs/greatWall/src/swift_cpp_api.c 中
```


```c++
第一帧:
"bind"
第二帧:
{
  "CID":""
  "msgTime":"",
}

第一帧:
"bind"
第二帧:
{
  "CID":"",
  "UID":"",
  "msgTime":""
}
```
```json
上行:
{
    "action":"chatGroup",
    "chatToken":"abcdefghij",
    "timestamp":"1458266656",
    "content":
    {
        "fromAccountID":"15618873958",
        "fromTimestamp":"1458266656",
        "fromLat":35.12345,
        "fromLon":121.12345,
        "chatGroupID":"15618873958cg001",
        "fileType":1,
        "fileServer":0,
    }
}
下行:
{
    "action":"chatGroup",
    "chatToken":"abcdefghij",
    "timestamp":"1458266656",
    "content":
    {
        "fromAccountID":"15618873958",
        "fromTimestamp":"1458266656",
        "fromLat":35.12345,
        "fromLon":121.12345,
        "chatGroupID":"15618873958cg001",
         "chatID":"156to136_160628141414",
         "onLine":1,
        "fileType":1,
        "fileServer":0,
    }
}
```

```json
{
    "action":"chat",
    "chatToken":"abcdefghij",
    "timestamp":"1458266656",
    "imei": "147258369015935",
    "imsi": "460011234453214",
    "content":
    {
        "fromAccountID"："15618873958",
        "fromTimestamp":"1458266656",
        "fromLat":35.12345,
        "fromLon":121.12345,
        "toAccountID":"13661683669",
        "fileType":1,
        "fileServer":0,
    }
}

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
        "chatID":"156to136_160628141414"
        "onLine":0,
        "fileType":1,
        "fileServer":0,
        "fileUrl":"https://pc.foryou.com/chat/156to145_160628121212.amr"
    }
}
```

```c++
/*                                                                              
 * 数据帧格式                                                                   
 *                                                                              
 * Login server 发出的命令                                                      
 * 0 status                                                                     
 * 1 [connected]/[closed]                                                       
 * 2 CID                                                                        
 *                                                                              
 * 发送给Setting server 的命令                                                  
 * 0 setting                                                                    
 * 1 [status]/[uidmap]/[gidmap]                                                 
 * 2 CID                                                                        
 * 3 [closed]/[uid]/[gid]                                                       
 *                                                                              
 * 普通消息下发                                                                 
 * 0 downstream                                                                 
 * 1 [cid]/[uid]/[gid]                                                          
 * 2 CID/UID/GID                                                                
 *                                                                              
 * bind 消息下发                                                                
 * 0 downstream                                                                 
 * 1 [cid]                                                                      
 * 2 CID                                                                        
 * 3 [bind]                                                                     
 *                                                                              
 * bind 消息上行                                                                
 * 0 upstream                                                                   
 * 1 CID                                                                        
 * 2 [bind]                                                                     
 * 3 {UID}                                                                      
 */
```

```C++
#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <stdio.h>
int main(void){
	int status, result, i;
	double sum;
	lua_State *L;
	L = luaL_newstate();
	luaL_openlibs(L);
	/* 把lua程序搞进来*/    
	status = luaL_loadfile(L, "script.lua");
	if (status) {
		printf(stderr, "bad, bad file\n");        
		exit(1);
	}
	//正式开始。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。    
	/*     *首先我们必须准备好Lua的虚拟堆栈。     * 然后传递数据到这个堆栈里.     */     
	lua_newtable(L);    /* 堆栈里建立个table*/    
	/*
  *********************************************************     * 要把数据放入lua的堆栈。 首先放入index, 然后是数据，接着根据table在堆栈的位置（－3）     * *调用lua_rawset().     * 为什么table在堆栈的位置是－3：－3是堆栈顶往下的第3个      *      *     * <- [stack bottom] -- table, index, value [top]     *     *******************************************************
  */    
	for (i = 1; i <= 5; i++) {        
		lua_pushnumber(L, i);   /* 压入table 索引 */        
		lua_pushnumber(L, i*2); /* 压入值 */        
		lua_rawset(L, -3);      /* 保存这一双于table中 */
	}    /* lua代码中table的名字是foo */   
	lua_setglobal(L, "foo");    
	result = lua_pcall(L, 0, LUA_MULTRET, 0);    
	if (result) {        
		fprintf(stdout, "bad, bad script\n");
		exit(1);
	}    /* 获得堆栈顶的值*/      
	sum = lua_tonumber(L, lua_gettop(L));    
	if (!sum) {        
		fprintf(stdout, "lua_tonumber() failed!\n");        
		exit(1);
	}    
	fprintf(stdout, "Script returned: %.0f\n", sum);
	lua_pop(L, 1);  /* 把返回的值弹出堆栈，既清掉这个值*/    
	lua_close(L);      
	return 0;
}
```
```
-- script.lua
x = 0
for i = 1, #foo
do  print(i, foo[i])  
x = x + foo[i]
end
return x
```
