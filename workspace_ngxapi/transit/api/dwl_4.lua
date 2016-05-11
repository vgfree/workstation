local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local link      = require('link')
local cjson     = require('cjson')
local http_api  = require('http_short_api')

local lhttp_api = require('lhttp_pool_api')

local dk_utils  = require('dk_utils')
local only      = require('only')


--ngx.say('http_api test')

only.log('E','dwl lhttp test') --打印一条日志

ngx.say('post request start')

local req_data = "name=123"

local host_info = link["OWN_DIED"]["http"]["clienttest"]
local url = 'dfsapi/v2/dwlUrl2'

local data = utils.post_data(url , host_info , req_data)
local ret = http_api.http(host_info, data, true)

if not ret then
    ngx.say('error')
    return nil
end
local body = string.match(ret, '.-\r\n\r\n(.+)')

ngx.say(body)
ngx.say('post request over')


