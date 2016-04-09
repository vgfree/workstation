### 目录功能
#### TSDB lib
> * jmalloc 内存管理性能优于malloc
> * leveldb 高效k-v数据库
> * libev 事件驱动的编程框架,系统异步模型
> * libuv 高性能网络编程库
> * snappy  C++ 的用来压缩和解压缩的开发包
> * zookeeper 开源分布式应用程序协调服务

###

key 存储格式: `gps`		




###
> 1. mtdk@172.16.51.31 `/data/trasit_1/transit/deploy/link.lua` 	
	tsdb - gps
	message - weibo		
	url -		
> 2. 172.16.71.124 mtdk@123 	
  /tsdb/data00/config.json查看配置 	
	可以找到zk_server配置 `172.16.71.121:2181`

> 3. ./zkCli.sh -server 172.16.71.121:2181 远程连接 	
	$ls /tsdb/RW:20160111200000:-1 	
	[5120:6144, 4096:5120, 7168:8192, 0:1024, 3072:4096, 6144:7168, 2048:3072, 1024:2048]



### 环境搭建

### 逻辑思路
timport(192.168.1.12) 从redis(192.168.1.12)中读取数据存放到tsdb(192.168.1.12)中,
tsdb的匹配文件保存在zookeeper(192.168.1.14)中

*****timport**
Q1. timport 如何获取从哪个redis读取数据
> 配置文件: timport/timport_conf.h
```
/* redis config. */
const database_t REDIS[] = {
	{"192.168.1.12", 7776},
	{"192.168.1.12", 7777},
	{"192.168.1.12", 7778},
	{"192.168.1.12", 7779}
};
```
Q2. timport 关联哪个zookeeper server
```
/* zookeeper host list */
const char *ZK_SERVER = "192.168.1.14:2181,192.168.1.14:2182,192.168.1.14:2183,192.168.1.14:2184,192.168.1.14:2185";
```
**zookeeper**
> 配置文件: zookeeper/server001/zookeeper-3.4.6/conf/zoo.cfg
```
clientPort=2181
server.1=127.0.0.1:8881:7771
server.2=127.0.0.1:8882:7772
server.3=127.0.0.1:8883:7773
server.4=127.0.0.1:8884:7774
server.5=127.0.0.1:8885:7775
```
********TSDB**
> * ****配置文件: tsdb_conf.json
配置读取key的范围
配置zk_server地址
```
"node_type": "CLUSTER",
"mode": "RW",
"ds_id": 50006,
"key_set": [6144,7168],
"time_range": [20160111200000, -1],
"zk_server": "172.16.71.121:2181,172.16.71.151:2181,172.16.71.152:2181",

"ip": "172.16.71.124",
"w_port": 17051,
"r_port": 17052,
```



#### 192.168.1.14 zookeeper
/data/zookeeper
	保存TSDB配置文件,可以对应多个TSDB
	/data/zoo_tsdb/zoo_timport/timport_conf.h
```
/* redis config. */
const database_t REDIS[] = {
	{"192.168.1.12", 7776},
	{"192.168.1.12", 7777},
	{"192.168.1.12", 7778},
	{"192.168.1.12", 7779}
};
```


#### 192.168.1.12 timport
配置读取的redis和注册到哪个zookeeper
/data/tsdb/TSDB/utils/timport/timport_conf.h
redis配置
```
/* redis config. */
const database_t    REDIS[] = {
	{"192.168.1.12", 7776},
	{"192.168.1.12", 7777},
	{"192.168.1.12", 7778},
	{"192.168.1.12", 7779}
};

```
start_time 设置		
/data/tsdb/TSDB/utils/timport/var/start_time.txt

注册zookeeper 配置
```
/* tsdb config. */
const database_t TSDB[] = {
	{ "192.168.1.14", 7501 },
	{ "192.168.1.14", 7503 }
};
```
#### 192.168.71.55 transit










### redis中gps数据存储
/supex/programs/transit/dk_utils.lua
```lua
--> set active user.                                                   
local key = string.format("ACTIVEUSER:%s", timeinterval)                
local value = gps_tab['imei']                                           
local ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,value)
```
```lua
key = string.format("GPS:%s:%s", imei, timeinterval)                    
-->> set redis.
ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,unpack(gps_tab['list']))
```
```lua
-->> set active user.                                                   
local key = string.format("RACTIVEUSER:%s", timeinterval)               
local value = gps_tab['imei']                                           
local ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,value)
```
```lua
-->> compact GPS info.                                               
key = string.format("RGPS:%s:%s", imei, timeinterval)                   
-->> set redis.                                                         
ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,unpack(gps_tab['list']))
```
