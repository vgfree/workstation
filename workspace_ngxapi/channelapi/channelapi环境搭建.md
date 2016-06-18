1. 搭建地址
   ip: 192.168.71.51

2. 数据库信息
   mysql : 192.168.71.85:3306
   user :

```js
local luasql    = require('luasql.mysql')

env = assert(luasql.mysql())                                                    
conn = assert(env:connect(link.OWN_POOL.mysql.channel_info___info.database, link.OWN_POOL.mysql.channel_info___info.user, link.OWN_POOL.mysql.channel_info___info.password, link.OWN_POOL.mysql.channel_info___info.host, link.OWN_POOL.mysql.channel_info___info.port))

sql_start_transaction = "START TRANSACTION",                            
sql_commit = "COMMIT",                                                  
sql_rollback = "ROLLBACK",

-- mysql 事务开始                                                       
conn:execute(G.sql_start_transaction)

local ok_status = save_info_to_redis(args['accountID'], channelID, ok_ret_channel)

if ok_status then                                                       
      conn:execute(G.sql_commit)                                      
else                                                                    
      conn:execute(G.sql_rollback)                                    
      gosay.go_false(url_tab, msg["MSG_DO_REDIS_FAILED"])             
end

local cursor, errorString = conn:execute(sql_str)                     

if not cursor then                                              
      return false, nil                                       
end
```


```bash
curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"tianlongbabu", "chType":2, "reType":0, "chIntro":"武侠", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"众生皆苦,求而不得"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10001", "reType":1, "chName":"ludingji", "chIntro":"都是我老婆", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"找老婆,做大官"}' -v http://192.168.130.76/channelapi/modifyChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10014"}' -v http://192.168.130.76/channelapi/dissolveChannel

curl -H "appKey:1858017065" -H "accountID:1234567891" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10009"}' -v http://192.168.130.76/channelapi/quitChannel

curl -H "appKey:1858017065" -H "accountID:1234567891" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10011", "remark":"炎发灼眼"}' -v http://192.168.130.76/channelapi/joinChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10009"}' -v http://192.168.130.76/channelapi/getChannelInfo

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":["10001", "10002", "10009"]}' -v http://192.168.130.76/channelapi/subscribeChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10009", "blkID":["1234567890", "1234567891"], "setType":1}' -v http://192.168.130.76/channelapi/setChannelBlackList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10009"}' -v http://192.168.130.76/channelapi/getChannelUserList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"UID":"e8O1W0ytqy"}' -v http://192.168.130.76/channelapi/getChannelList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10009", "UID":"e8O1W0ytqy", "setType":1}' -v http://192.168.130.76/channelapi/adminReview

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10009"}' -v http://192.168.130.76/channelapi/getChannelBlackList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10011", "jockeyList":["e8O1W0ytqy"]}' -v http://192.168.130.76/channelapi/setJockeyList
```
