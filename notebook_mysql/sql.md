### 创建mysql用户
1. 创建用户
`create user 'username'@'hostname' identified by 'passwprd'`
hostname : localhost 或 % (可从任意远程主机登陆)

2. 授权
`grant all on databasename.tablename to 'username'@'hostname'`
databasename\tablename 可使用通配符 *

3. 删除用户
`drop user 'username'@'hostname'`

```sql
sql_set_channel_info_verify_finished = "UPDATE tbl_channelInfo SET verify = 1 WHERE channelID = '%s'",
sql_set_channel_info_verify_unfinish = "UPDATE tbl_channelInfo SET verify = 0 WHERE channelID = '%s'",
sql_set_channel_list_verify_finished = "UPDATE tbl_channelList SET verify = 1 WHERE channelID = '%s'",
sql_set_channel_list_verify_unfinish = "UPDATE tbl_channelList SET verify = 0 WHERE channelID = '%s'",
```

```js
sql_set_channel_info_verify_finished = "UPDATE tbl_channelInfo SET verify = 1 WHERE channelID = '%s'",

local ok_status = set_channel_info_verify_finished(args['chID'])                        
if not ok_status then                                                   
      gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])             
end

local function set_channel_info_verify_finished(channelID)                                                                            
        local sql_str = string.format(G.sql_set_channel_info_verify_finished, channelID)              
        only.log('D', 'sql_str = %s', sql_str)                                  

        local ok_status, ret_tab = mysql_api.cmd(app_config_db[1], 'select', sql_str)
        if not ok_status or not ret_tab then                                    
                only.log('E', "sql_set_channel_info_verify_finished failed %s ", sql_str )    
                gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])             
        end                                                                     

        return true                                                             
end
```
```js
sql_set_channel_info_verify_unfinish = "UPDATE tbl_channelInfo SET verify = 0 WHERE channelID = '%s'",

local ok_status = set_channel_info_verify_unfinish(args['chID'])                        
if not ok_status then                                                   
      gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])             
end

local function set_channel_info_verify_unfinish(channelID)                                                                            
        local sql_str = string.format(G.sql_set_channel_info_verify_unfinish, channelID)              
        only.log('D', 'sql_str = %s', sql_str)                                  

        local ok_status, ret_tab = mysql_api.cmd(app_config_db[1], 'select', sql_str)
        if not ok_status or not ret_tab then                                    
                only.log('E', "set_channel_info_verify_unfinish failed %s ", sql_str )    
                gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])             
        end                                                                     

        return true                                                             
end
```

```js
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
