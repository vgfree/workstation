local scan = require('scan')
local only = require('only')
local req_head   = ngx.req.raw_header()

local req_ip     = ngx.var.remote_addr
local req_body   = ngx.req.get_body_data()
local req_method = ngx.var.request_method
local args       = ngx.req.get_uri_args()


only.log('D', 'req_body = %s', scan.dump(req_body))
only.log('D', 'grgs = %s', scan.dump(args))




--url_tab['client_host']
--=
--G.req_ip
----os.execute("sleep
--5")
----ngx.say(a)
--ngx.say(req_head)
--ngx.say(req_method)
--ngx.say(req_body)
--ngx.say(scan.dump(args))
local fd = io.open("/data/nginx/realroadapi/api/success.html","r")
local str = fd:read("*a")
fd:close()
ngx.say(str)

