### 存取redis key-value

personal_save_message_to_msgredis

一个用户发送消息的记录
key = string.format("sendMessage:%s:%s:%s",senderAccountID,args['appKey'],cur_time)     
redis_pool_api.cmd(message_redis_name,'SADD',key,string.format("%s|%s",os.time(),args['bizid']))


key = string.format("sendMessage:%s",cur_time)
value = string.format("%s:%s",senderAccountID,args['appKey'])
redis_pool_api.cmd(message_redis_name,'SADD',key,value)


key = string.format("fileLocation:%s",args['bizid'])
message_redis_name = hash_function(args['bizid'])
redis_pool_api.cmd(message_redis_name,'SET',key,args['multimediaURL'])


城市语音批量拉取
message_redis_name = hash_function(city_code)
key = string.format("cityCode:%s",cur_time)
redis_pool_api.cmd(message_redis_name,'SADD',key,city_code)


key = string.format("cityCodeMessage:%s:%s",city_code,cur_time)                                                                                          redis_pool_api.cmd(message_redis_name,'SADD',key,args['bizid'])
