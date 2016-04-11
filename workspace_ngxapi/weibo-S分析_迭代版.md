# weibo-S 代码及流程分析
------
weibo-S 主要用于发送个人微博,

------
操作mysql数据库

------
`api_send_multimedia_personal_supexweibo.lua` 代码分析
实在不知道该怎么分析,那就把代码中的有价值信息提取出来     

```lua     
local function handle()
        -- 1. 获取请求参数并重新解析为table
        local req_heads = ngx.req.raw_header()
        local req_body = ngx.req.get_body_data()
        local ip = ngx.var.remote_addr

        local body_args = utils.parse_form_data(req_heads, req_body)
        ------------------------------------------------------------------------------------
        -- 2. 校验参数
        check_parameters(body_args)
        ------------------------------------------------------------------------------------
        -- 3. 生成bizid
        -- bizid = flag .. uuid
        -- uuid 经由一定算法生成，非人工指定，非人工识别，在特定范围内重复的可能性极小
        body_args['bizid'] = weibo_fun.create_bizid('a2')
        -------------------------------------------------------------------------------------
        -- 4. 保存消息到消息redis数据库
        weibo_fun.group_save_message_to_msgredis(body_args)
        ------------------------------------------------------------------------------------
        -- 5. 获取发送的目的人数,也即是发送出的条目数
        local cnt = 0
        -- channelSoundMode 设定声音模式 0 禁言 1 默认
        if body_args['channelSoundMode'] == 1 then
                cnt = touch_redis(body_args)
        end
        -----------------------------------------------------------------------------------
        -- 6. 统计appkey发送微博总数
        local cur_month = os.date('%Y%m')
        local cur_day = os.date("%Y%m%d")
        -- 每发送一次微博，redis数据库中:totalNum域总数+1
        weibo_fun.incrby_appkey( body_args['appKey'], cur_month, cur_day)
        weibo_fun.incrby_groupid( body_args['groupID'], cur_month, cur_day)
        ------------------------------------------------------------------------------------
        -- 7. 频道内最后一次说话时间(不知道为什么要这么做,应该是其他业务需要调用吧)
        weibo_fun.groupid_update_timestamp( body_args['groupID'] )
end
```

## supex weibo-S

### weibo_send_single_message.lua
> * 获取请求`args = supex.get_our_body_table()` 
> * 获取UID message label level 
> * 以上四个参数都存在时
	```
	tasks = {
		{ id = 1, label = label, message = message   },           
		{ id = 2, UID = UID, level = level, label = label  }
	}
	```
> * 执行`forward_task_redis( tasks )`
	```
	coro:addtask(work_redis_one, coro, tasks[1])                            
	coro:addtask(work_redis_two, coro, tasks[2])
	``` 
> * 函数` work_redis_two( coro, usr )`
	```
	redis_api.cmd('weibo', "", 'ZADD', usr.UID .. ":weiboPriority",
			usr.level, usr.label)
	```
> * 函数`work_redis_one( coro, usr )`
	```
	redis_api.cmd('weibo', "", 'SETEX', usr.label .. ":weibo", 300, 
			usr.message)
	```
> * 在two中存储的都是UID相关的标志位信息等,再通过label可以找到message,并且one是
    定时的,超时时间段内没有被调用执行就会销毁






