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
{
  "opt":"bind",
  "CID":""
  "msgTime":"",
  "msgID":"",
}

{
  "opt":"bind",
  "CID":"",
  "UID":"",
  "msgTime":"",
  "msgID":""
}
```
