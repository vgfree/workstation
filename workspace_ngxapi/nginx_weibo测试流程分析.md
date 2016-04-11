### groupweibo 测试
1. 在192.168.71.196中通过 `weibo-G_conf.json` 配置weibo-G 可执行文件

  ```json
  {
        "swift_port": 4070,
        "swift_worker_counts": 1,
        "swift_protocol": "http",

        "max_req_size": 32768,

        "sniff_worker_counts": 1,
        "sharer_counts": 32,

        "log_path": "./logs/",
        "log_file": "weibo-G",
        "log_level": 0,

        "api_custom": ["/x_test", "/weibo_set_group", "/weibo_get_group","/weibo_send_group_message"]
 }
  ```
  在`./weibo-G &`启动后， 会按照配置监听4070端口, `api_custom` 是会调用的文件  

2. 客户端请求执行时会调用的文件 `/data/supex_weibo/programs/weibo-G/sniff_lua/weibo-G/code/weibo_send_group_message.lua`    
执行发送操作  

3. 在 `/data/supex_weibo/programs/weibo-G/sniff_lua/weibo-G/deploy` 中  
`link.lua` 配置了redis数据库信息

  ```lua
  module("link")
  OWN_POOL = {
          redis = {
                  weibo = {
                          host = '192.168.1.11',
                          port = 6329,
                  },
                  statistic = {
                          host = '192.168.1.11',
                          port = 6339,
                  },

          mysql = {},
  }

  OWN_DIED = {
          redis = {},
          mysql = {},
          http = {
          },
  }
  ```
  `cfg.lua` 应该配置的是打印信息

4. 在`weibo-G` 启动后，我们可以通过 `/home/shana/03.2016/supex/programs/weibo-G/test/weibo-G_client.lua` 客户端来进行请求
在进行请求前还需要对客户端进行设置.主要配置信息有以下几点：    
 * 向redis 6339 端口中的相应GID:channelOnlineUser 即群组中加入成员
 * 将客户端 `host` `port` `serv` 三者的正确值填写， 即对应服务器地址、端口和执行程序

5. 执行客户端程序, 检查redis 6329 端口中，是否正确写入了

备注： `redis-cli -h 192.168.1.11 -p 6329 keys \*weiboPriority|xargs redis-cli -h 192.168.1.11 -p 6329 del`
