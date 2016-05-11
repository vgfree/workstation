local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local link      = require('link')
local cjson     = require('cjson')
local http_api  = require('http_short_api')
local dk_utils  = require('dk_utils')
local only      = require('only')

only.log('E','dingwenlong test') --打印一条日志

--要使用的数据库
local app_config_db   = { [1] = 'app_mirrtalk___config', [2] = 'app_mirrtalk___config_gc'}

local sql_str = "select * from openconfigInfo"

local ok_status,ok_ret = mysql_api.cmd(app_config_db[1],'SELECT',sql_str)

if not ok_status  then
	only.log('E','connect database failed when query sql_openconfig_info, %s ', sql_str)
end
if not ok_ret then
	only.log('E','configInfo return is nil when query sql_openconfig_info')
end
if #ok_ret < 1  then
	only.log('E','[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
end

for key, val in pairs(ok_ret[1]) do
    if type(val) == "table" then
        ngx.say(key, ": ", table.concat(val, ", "))
    else
        ngx.say(key, ": ", val)
    end
end

only.log('D' , "db success！！！")

local request_method = ngx.var.request_method  
local args = nil  
 

ngx.say('处理htpp请求，get或post请求的参数如下')  
  
if "GET" == request_method then  
    ngx.say("get请求")  
    args = ngx.req.get_uri_args()  
elseif "POST" == request_method then  
    ngx.say("post请求")  
    ngx.req.read_body()  
    args = ngx.req.get_post_args()  
end  
for key, val in pairs(args) do  
    if type(val) == "table" then  
        ngx.say(key, ": ", table.concat(val, ", "))  
    else  
        ngx.say(key, ": ", val)  
    end  
end  
ngx.say('get or post request over')
