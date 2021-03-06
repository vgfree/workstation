### 目录

> * zookeeper 分析
> * tsdb 分析
> * timport 分析
> * 向redis中写入数据

#### zookeeper分析		
功能: 集群管理tsdb配置信息, 可以实现集群扩容和缩减

`zookeeper/server001/data/myid`		
myid数字对应第几个server

`zookeeper/server001/zookeeper-3.4.6/conf/zoo.cfg`
```		
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data/zookeeper/server001/data
dataLogDir=/data/zookeeper/server001/logs
// 每个server clientPort不同
clientPort=2181
// server.X 对应myid
// 第一个端口用来集群成员的信息交换
// 第二个端口用来leader挂掉时选举使用
server.1=127.0.0.1:8881:7771
server.2=127.0.0.1:8882:7772
server.3=127.0.0.1:8883:7773
server.4=127.0.0.1:8884:7774
```

`zookeeper 命令查看`
```
[zookeeper/server001/zookeeper-3.4.6/bin]$ ./zkCli.sh –server 127.0.0.1:2181
[zk: 127.0.0.1:2181(CONNECTED) 4] ls /tsdb/RW:20160101010000:-1/0:4096
[RW:10000:MASTER:192.168.1.12:7001:7002:20160101010000:-1]
```
这里看到的是tsdb的注册信息,tsdb配置信息来自
`tsdb/data00/tsdb_/conf.json`

WARNING:
每次运行前请删除`zookeeper/server001/data/zookeeper_server.pid`



#### tsdb 分析		
Time series database 时间序列数据库

在网上暂时没找到更详细的讲解,是OpenTSDB吗

<<<<<<< HEAD
#### 向redis 中写入数据
`ngxapi/transit/test/test_newstat_BMR.sh` 运行,执行写入操作
注意需要修改token值
=======
`tsdb/data01/tsdb_conf.json` 配置分析
```
1 {
2     "smart_hander_counts": 2,
3     "smart_worker_counts": 4,
4     "smart_tasker_counts": 32,
5     "smart_monitor_times": 30,
6     "smart_protocol": "redis",
7     "swift_worker_counts": 1,
8     "swift_protocol": "redis",
9     "max_req_size": 32768,
10
	// 配置日志
11     "log_path": "./var/logs",
12     "log_file": "tsdb",
13     "log_level": 1,
14
	// 集群方式 CLUSTER SIMPLE
15     "node_type": "CLUSTER",
16     "mode": "RW",
17     "ds_id": 10000,
	// key % 8192 结果的范围区间
18     "key_set": [0,4096],
	// 时间区间
19     "time_range": [20160101010000, -1],
	// 注册zookeeper server
20     "zk_server": "192.168.1.14:2181,192.168.1.14:2182,192.168.1.14:2183,192.168.1.14:2184,192.168.1.14:2185",
21
	// 本机ip port
22     "ip": "192.168.1.12",
23     "w_port": 7001,
24     "r_port": 7002,
25
26     "work_path": "./var",
27
28     "ldb_write_buffer_size": 67108864,
29     "ldb_block_size": 32768,
30     "ldb_cache_lru_size": 1073741824,
31     "ldb_bloom_key_size": 10,
32     "ldb_compaction_speed": 1000,
33
	// 是否有从机 0 1 ，本机角色
34     "has_slave": 1,
35     "role": "MASTER",
36     "slave_ip": "192.168.1.12",
37     "slave_wport": 7001
38 }
```

`"key_set": [4096,8192]` : 对key % 8192 取模,结果落在此区间则数据存储在此data
`"time_range": [20160101010000, -1]` : 存储数据的时间范围
`has_slave` : 是否有slave
>>>>>>> 3b21bd86ca511d7138b57c8ecc1dd74ce7d941b2

#### timport 分析
重要文件： timport_conf.h start_time.txt
`timport_conf.h`
```
1 /*
2  * timport_conf.h
3  *
4  *  Created on: Nov 12, 2014
5  *      Author: chenjf
6  */
7
8 #include <stdint.h>
9 #include "./src/common.h"
10
11 #pragma once
12
13
14 /* 配置读取的数据源redis */
15 const database_t    REDIS[] = {
16                     {"192.168.1.12", 7776},
17                     {"192.168.1.12", 7777},
18                     {"192.168.1.12", 7778},
19                     {"192.168.1.12", 7779}
20 };
21 #define REDIS_SIZE ((sizeof(REDIS))/sizeof(REDIS[0]))
22
23 #ifdef TSDB_URL
24 /* tsdb_url config. */
25 const database_t    TSDB[] = {
26                     {"192.168.1.12", 7502},
27                     {"192.168.1.12", 7502},
28                     {"192.168.1.12", 7502},
29                     {"192.168.1.12", 7502},
30 };
31 #define TSDB_SIZE ((sizeof(TSDB))/sizeof(TSDB[0]))
32 #endif
33
34 /* statistics redis. */
35 const database_t    STATS = { "192.168.1.11", 6319};
36
37 /* backup path. */
38 const char          *BACKUP_PATH = "./var/backup";
39
40 /* statistics path. */
41 const char          *STATS_PATH = "./var/logs/stats.log";
42
43 /* log config. */
44 const char          *LOG_FILE = "./var/logs/access.log";
45 const int32_t       LOG_LEVEL = 5;
46
47 /* routine config. */
48 const int32_t       TIME_LIMIT = 3600; /* 2 hours. */
49 const char          *START_TIME_FILE = "./var/start_time.txt";
50
51 /* zookeeper host list */
52 const char          *ZK_SERVER = "192.168.1.14:2181,192.168.1.14:2182,192.168.1.14:2183,192.168.1.14:2184,192.168.1    .14:2185";
53
54 /* tsdb zookeeper root node */
55 const char          *ZK_RNODE = "/tsdb";
```


#### 向redis 中写入数据
`ngxapi/transit/test/test_newstat_BMR.sh` 运行,执行写入操作



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
```
[root@node6 bin]# ./zkCli.sh -server 192.168.1.14:2181
[zk: 192.168.1.14:2181(CONNECTED) 1] ls /
[YINSHI.MONITOR.ALIVE.CHECK, tsdb, root, driview, zookeeper, a]
[zk: 192.168.1.14:2181(CONNECTED) 2] ls /tsdb
[RW:20150525210000:-1]
[zk: 192.168.1.14:2181(CONNECTED) 3] ls /tsdb/RW:20150525210000:-1
[0:4096]
[zk: 192.168.1.14:2181(CONNECTED) 4] ls /tsdb/RW:20150525210000:-1/0:4096
[RW:10000:MASTER:192.168.1.12:7001:7002:20150525210000:-1]
```
从上面可以看出配置信息
192.168.1.12:/data/chenxijun/tsdb/data00/tsdb_conf.json
```
1 {
	2     "smart_hander_counts": 2,
	      3     "smart_worker_counts": 4,
	      4     "smart_tasker_counts": 32,
	      5     "smart_monitor_times": 30,
	      6     "smart_protocol": "redis",
	      7     "swift_worker_counts": 1,
	      8     "swift_protocol": "redis",
	      9     "max_req_size": 32768,
	      10
		      11     "log_path": "./var/logs",
	      12     "log_file": "tsdb",
	      13     "log_level": 1,
	      14
		      15     "node_type": "CLUSTER",
	      16     "mode": "RW",
	      17     "ds_id": 10000,
	      18     "key_set": [0,4096],
	      19     "time_range": [20150525210000, -1],
	      20     "zk_server": "192.168.1.14:2181,192.168.1.14:2182,192.168.1.14:2183,192.168.1.14:2184,192.168.1.14:2185",
	      21
		      22     "ip": "192.168.1.12",
	      23     "w_port": 7001,
	      24     "r_port": 7002,
	      25
		      26     "work_path": "./var",
	      27
		      28     "ldb_write_buffer_size": 67108864,
	      29     "ldb_block_size": 32768,
	      30     "ldb_cache_lru_size": 1073741824,
	      31     "ldb_bloom_key_size": 10,
	      32     "ldb_compaction_speed": 1000,
	      33	// 表示是否有从服务器
		      34     "has_slave": 1,  
	      35     "role": "MASTER",
	      36     "slave_ip": "192.168.1.12",
	      37     "slave_wport": 7001
		      38 }
		      ```

### 环境搭建

### 逻辑思路
		      timport(192.168.1.12) 从redis(192.168.1.12)中读取数据存放到tsdb(192.168.1.12)中,
		      tsdb的匹配文件保存在zookeeper(192.168.1.14)中

		      **timport** 	
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
**TSDB**
> * 配置文件: tsdb_conf.json 	
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


### 注意事项
在192.168.1.12://data/chenxijun/tsdb/data00 上运行tsdb
nohup ./tsdb &
记得要删除var 下的tsdb.pid

线上timport 172.16.71.123 		

使用zookeeper可以方便进行扩容
