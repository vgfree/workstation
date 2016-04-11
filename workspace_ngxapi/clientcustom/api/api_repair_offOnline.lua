---- 田山川专用
---- 修复用户下线

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local cjson     = require('cjson')
local link      = require('link')
local redis_api = require('redis_pool_api')

local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}

local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local args     = ngx.req.get_uri_args()
    url_tab['client_host'] = req_ip
    url_tab['client_body'] = 'GET  ' .. utils.table_to_kv(args)
    if not args or type(args) ~= 'table' then
        go_exit('error')
    end

    for i,v in pairs(args) do
        only.log('D',string.format('  key:%s  val:%s',i,v))
    end

    if not args['accountID'] or #args['accountID'] ~= 10 then
        go_exit('error')
    end
    local  accountID = args['accountID']
    local ok = redis_api.cmd('statistic','sadd', 'onlineUser:set',accountID)
    if ok then
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    end

end

safe.main_call( handle )
