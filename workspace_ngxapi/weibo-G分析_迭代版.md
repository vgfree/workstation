

## supex weibo-G 

### weibo_send_group_message.lua 
> * 获取请求args
> * 获取GID
> * 通过GID从luakv/redis中取出所有成员并放入table users
> * 在users成员不为0时,将args中level label message赋给tasks
> * 执行`forward_task_redis(users,tasks)`函数
> * 在上面的函数中,执行`redis_api.cmd('weibo', "", 'SETEX', tasks.label .. 
		>   ':weibo', 300, tasks.message)`
> * 在函数`forward_task_redis(users,tasks)`中,以50个为一组,执行协程发送任务
		>   `coro:addtask(set_userweibo_redis, coro, task_data)`
> * 在上面的函数中,执行`redis_api.cmd('weibo', "", 'ZADD', usr.uid ..
		>   ":weiboPriority", usr.tasks.level, usr.tasks.label)`

### api_send_multimedia_group_supexweibo.lua 
> * 获取客户端请求信息req_heads req_body ip
> * 解析head和body	
	`body_args = utils.parse_form_data(req_heads, req_body)`
> * 校验参数	
	`check_parameters(body_args)`
> * 生成bizid	
	`body_args['bizid'] = weibo_fun.create_bizid('a2')`
> * 保存消息到redis数据库	
	`weibo_fun.group_save_message_to_msgredis(body_args)`	
	**此处请看下面详述**
> * 在默认声音模式下,获取发送的目的人数(即发送出的条目数)	
	`cnt = touch_redis(body_args)`		
	**此处请看下面详述**
> * 统计所有appKey发送微博的总记录数 和 统计群组集团微博发送次数	
	`weibo_fun.incrby_appkey( body_args['appKey'], cur_month, cur_day )`	       
	`weibo_fun.incrby_groupid( body_args['groupID'], cur_month, cur_day )`	
> * 频道内最后一次说话时间	
	`weibo_fun.groupid_update_timestamp( body_args['groupID'] )`	
**************
#### weibo_fun.group_save_message_to_msgredis(body_args)
> * 利用哈希函数计算message_redis_name	
   当senderAccountID存在时，按照senderAccountID进行HASH                  
   当senderAccountID不存在时，按照appKey进行HASH,同时senderAccountID的值用常量
   "unknow"替换
