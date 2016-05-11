
local only      = require('only')
only.log('E','halloword test')

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

