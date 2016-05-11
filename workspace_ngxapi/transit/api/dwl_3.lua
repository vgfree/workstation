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


--ngx.say('http_api test')

only.log('E','dwl http post request test') --打印一条日志

local req_data = "name=123"

only.log('E','args:' .. req_data) --打印一条日志

local host_info = link["OWN_DIED"]["http"]["clienttest"]

local tmp_head = 'POST /dfsapi/v2/dwlUrl  HTTP/1.0 \r\n' ..
					'Host: %s:%s\r\n' .. 
					'Accept: */*\r\n' .. 
					'Content-Length: %d\r\n' .. 
					'Content-Type: application/x-www-form-urlencoded\r\n\r\n%s'


local req = string.format(tmp_head,host_info.host, tostring(host_info.port) , #req_data,req_data )

only.log('E' , 'post message:' .. req ) --打印一条日志

local ret = http_api.http(host_info, req , true)
if not ret then
	only.log('E',"[FAILED] %s %s HTTP post failed! feedback api ", host_info.host, tostring(host_info.port) )
end

--only.log('I' , ret)
local body = string.match(ret, '.-\r\n\r\n(.+)')
only.log('I' , body)
ngx.say(body )

ngx.say('dwl http test end')




