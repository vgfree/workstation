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

only.log('E' , "post form start ")

ngx.say('form start')

local cfg = {

        ip = "192.168.71.84" ,

        port = 80 ,

        path = '/dfsapi/v2/dwlUrl3' ,

        body ='{"name":"dwl","pwd":"123456"}'
}
local host_info = link["OWN_DIED"]["http"]["clienttest"]

local status, res = pcall(cjson.decode, cfg.body)

for k, v in pairs(res) do
    if type(v) == 'table' then
	res[k] = cjson.encode(v)
    end
end


local boundary = '-----------abc123456789'

local http_body = ''

for k, v in pairs(res) do
	http_body = http_body .. string.format('--%s\r\nContent-Disposition:form-data;name="%s"\r\n\r\n%s\r\n', boundary, k, v)
end

http_body = string.format('%s--%s--', http_body, boundary) 
local data = 'POST ' .. cfg.path ..  ' HTTP/1.0\r\n' ..
    'Host: 192.168.71.84:80\r\n' ..
    'Accept: */*' .. '\r\n' ..
	'Content-Length:' .. tostring(#http_body) .. '\r\n' ..
    'Content-Type:multipart/form-data;boundary=-----------abc123456789\r\n\r\n' ..
    http_body

only.log('E' , data)

local ret = http_api.http(host_info, data , true)

if not ret then
	only.log('E',"[FAILED] %s %s HTTP post failed! feedback api ", host_info.host, tostring(host_info.port) )
end

--local body = string.match(ret, '.-\r\n\r\n(.+)')

ngx.say(ret)
ngx.say('form post  end')

only.log('E' , 'form request end')


