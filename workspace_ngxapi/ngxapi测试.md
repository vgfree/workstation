### 微博群消息发送功能测试
1. 打开手机，发送一条微博
2. ssh root@192.168.1.207 mirrtalk
   查看/data/nginx/clientcustom/deploy/link.lua中的配置，可以知道配置了  :channelOnlineUser的   
   redis数据库为 192.168.1.11：6339
   当我们通过
   redis-cli -h 192.168.1.11 -p 6339 --eval script.lua 000000908:channelOnlineUser , 113257 1
   命令可以向数据库中写入113257个在线用户用于测试
3. 在1中我们发送了一条微博，登陆 http://prod.mirrtalk.com/itdstable_s9/
   通过输入IMEI号可以查询到所发送的语音微博URL
4. 拿到了URL我们就可以来到http://192.168.1.217:8000/tools/index
   选择微博发送集团微博，将URL粘贴, groupid可以通过在redis中
   `keys *:channelOnlineUser`来查找
5. 在页面上选择发送， 可以通过日志来查看是否执行了发送
6. redis-cli -h 192.168.1.11 -p 6329 可以通过keys * 来查看发送信息，任选一条 *
   :weiboPriority   zrange ~ 0 -1 可以查看发送次数， 多点几次会多看到相应的条数
7. 相关命令
	./weibo-G &
	ps -ef | grep weibo-G
	redis-cli -h 192.168.1.11 -p 6339 --eval script.lua
	000000908:channelOnlineUser , 113257 1

	```
	for i = 1, ARGV[1], ARGV[2] do                                                                                          
	        redis.call('sadd', KEYS[1], tostring(1234567890 - i))
		end

		return 1

	```
	redis-cli -h 192.168.1.11 -p 6329 keys \*weiboPriority|xargs redis-cli -h 192.168.1.11 -p 6329 del


***************************************************************


