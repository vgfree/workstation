### Weibo-S
#### 框架结构分析   
```
.
|-- logs -- 日志打印信息
|-- Makefile
|-- sniff_lua -- weibo-G 代码
|   |-- core
|   |   |-- apply.lua
|   |   |-- init.lua
|   |   |-- start.lua
|   |   `-- weibo.lua
|   `-- weibo-G
|       |-- code
|       |   |-- weibo_get_group.lua
|       |   |-- weibo_send_group_message.lua -- 执行发送文件
|       |   |-- weibo_set_group.lua
|       |   `-- x_test.lua
|       |-- deploy
|       |   |-- cfg.lua  -- 日志打印相关信息
|       |   `-- link.lua -- 配置redis数据库host port
|       `-- list
|           |-- BYNAME_LIST.lua
|           |-- CONFIG_LIST.lua
|           `-- STATUS_LIST.lua
|-- src
|   |-- add_session_cmd.c
|   |-- add_session_cmd.h
|   |-- load_sniff_cfg.c
|   |-- load_sniff_cfg.h
|   |-- load_swift_cfg.c
|   |-- load_swift_cfg.h
|   |-- main.c
|   |-- sniff_scco_lua_api.c
|   |-- sniff_scco_lua_api.h
|   |-- swift_cpp_api.c
|   `-- swift_cpp_api.h
|-- test
|   `-- weibo-G_client.lua -- 测试文件
`-- weibo-G_conf.json -- 参数配置文件
```

#### 测试部分
