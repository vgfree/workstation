--
-->authore: zhangjl
-->time :2013-03-20
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path

local ngx = require('ngx')
local utils = require('utils')
local app_utils = require('app_utils')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local only = require('only')
local msg = require('msg')
local safe = require('safe')

local url_tab = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    safe.sign_check(args, url_tab)
    
end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_tab['client_host'] = ip
    url_tab['client_body'] = body

    if body == nil then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)
    url_tab['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)

    local ok, group = redis_pool_api.cmd('private', 'get', args['accountID'] .. ':defaultGroup')
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end

    local ret = string.format('{"defaultGroup":"%s"}', group or '')

    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)


end


safe.main_call( handle )
