1. 搭建地址
   ip: 192.168.71.51

2. 数据库信息
   mysql : 192.168.71.85:3306
   user :

```lua
sql_set_channel_list_verify_finished = "UPDATE tbl_channelList SET verify = 1 WHERE channelID = '%s'",

local ok_status = set_channel_list_verify_finished(args['chID'])                        
if not ok_status then                                                   
      gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])             
end

local function set_channel_list_verify_finished(channelID)                                                                            
        local sql_str = string.format(G.sql_set_channel_list_verify_finished, channelID)              
        only.log('D', 'sql_str = %s', sql_str)                                  

        local ok_status, ret_tab = mysql_api.cmd(app_config_db[1], 'select', sql_str)
        if not ok_status or not ret_tab then                                    
                only.log('E', "sql_set_channel_list_verify_finished failed %s ", sql_str )    
                gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])             
        end                                                                     

        return true                                                             
end
```
```js
sql_set_channel_list_verify_unfinish = "UPDATE tbl_channelList SET verify = 0 WHERE channelID = '%s'",

local ok_status = set_channel_list_verify_unfinish(args['chID'])                        
if not ok_status then                                                   
      gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])             
end

local function set_channel_list_verify_unfinish(channelID)                                                                            
        local sql_str = string.format(G.sql_set_channel_list_verify_unfinish, channelID)              
        only.log('D', 'sql_str = %s', sql_str)                                  

        local ok_status, ret_tab = mysql_api.cmd(app_config_db[1], 'select', sql_str)
        if not ok_status or not ret_tab then                                    
                only.log('E', "set_channel_list_verify_unfinish failed %s ", sql_str )    
                gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])             
        end                                                                     

        return true                                                             
end
```


```bash
curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"tianlongbabu", "chType":2, "reType":0, "chIntro":"武侠", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"众生皆苦,求而不得"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10009", "reType":1, "chName":"ludingji", "chIntro":"都是我老婆", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"找老婆,做大官"}' -v http://192.168.130.76/channelapi/modifyChannel

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
