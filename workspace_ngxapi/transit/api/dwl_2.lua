local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
--local gosay     = require('gosay')
local utils     = require('utils')
local link      = require('link')
local cjson     = require('cjson')
local http_api  = require('http_short_api')
--local dk_utils  = require('dk_utils')
local only      = require('only')

only.log('E','dwl redis test 2') --打印一条日志

local key = "dingwenlong"
local val = "abc"
redis_api.cmd('private', 'set',key , val)

only.log('W',"key has writed")

local ok, idx = redis_api.cmd("private", 'get', key)

ngx.say(idx);

redis_api.cmd("private", 'del', key)

ngx.say('test over')
