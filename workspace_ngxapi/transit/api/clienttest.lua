local cjson     = require('cjson')
local ngx        = require('ngx')
local http_api  = require('http_short_api')
local only      = require('only')
local link      = require('link')
local utils     = require('utils')
--local app_utils = require('app_utils')
--local cutils    = require('cutils')
local only      = require('only')
--local msg       = require('msg')
--local safe      = require('safe')
local gosay     = require('gosay')
--local socket    = require('socket')
--local cjson     = require('cjson')
--local jTTS      = require("jTTS")



local args = {
	name = 555
}



--ngx.say(req_data)
--ngx.say(host_info.host)
--ngx.say(tostring(host_info.port))




local data = "name = 555"
local host_info = link["OWN_DIED"]["http"]["clienttest"]
local head = 'POST /dfsapi/v2/yeUrl HTTP/1.0 \r\n' ..
		'Host: %s:%s\r\n' ..
		'Accept: */*\r\n' ..
	   	 'Content-Length: %d\r\n' ..
	   	 'Content-Type: application/x-www-form-urlencoded\r\n\r\n%s'

 local req = string.format(head,host_info.host, tostring(host_info.port) , #data,data )
	  only.log('E' , 'post message:' .. req )
 
 local ret = http_api.http(host_info, req , true)

 if not ret then
 	 only.log('E',"[FAILED] %s %s HTTP post failed! ", host_info.host, tostring(host_info.port) )
 end

 --local body = string.match(ret, '.-\r\n\r\n(.+)')
--if not ok then
	--ngx.say(shibai body)
--else
	--ngx.say(suceess body)
--end
	  --ngx.say(body)
ngx.say("test end")


