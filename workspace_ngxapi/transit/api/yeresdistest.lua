local ngx = require('ngx')
local redis_api = require('redis_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local link      = require('link')
local cjson     = require('cjson')
local http_api  = require('http_short_api')
local only      = require('only')
key = "hallo"
val = "word"

local ok,rt = redis_api.cmd('public','set',key,val)

if not ok then
        ngx.say("set is error")
else
        ngx.say("set is sucess")

end

local ok,wt = redis_api.cmd('public','get',key,val)

if not ok then
        ngx.say("read is error")
else
        ngx.say("read is sucess")
end
        ngx.say("test end")

