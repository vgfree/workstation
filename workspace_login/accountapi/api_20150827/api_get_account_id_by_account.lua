-- get accountid by account.lua
-- author: zhangjl (jayzh1010@gmail.com)
-- company: mirrtalk.com

-- local common_path = './?.lua;../public/?.lua;../include/?.lua;'
-- package.path = common_path .. package.path

local ngx = require('ngx')
local sha = require('sha1')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local safe = require('safe')

local sql_fmt = {

    sl_accountid = "SELECT accountID FROM loginType WHERE account='%s' AND loginType=%d AND userStatus = 1",
    sl_user_info = "SELECT accountID, name, nickname FROM userInfo WHERE accountID='%s' AND status=1",
    update_loginLog = "UPDATE loginLog SET clientIP = INET_ATON('%s'), lastLoginTime =%d WHERE account='%s'",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function func(body)

    local ret_body
    local sql = string.format(sql_fmt.sl_accountid, body['account'], body['loginType'])
    only.log('D', sql)
    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #ret==0 then
        only.log('E',"ret : %d", #ret)
        ret_body = nil
    else
        local a_id = ret[1]['accountID']
        sql = string.format(sql_fmt.sl_user_info, a_id)
        only.log('D',sql)
        ok, result = mysql_pool_api.cmd("app_cli___cli", 'select', sql)

        if ok and #result~=0 then
            ok, ret_body = utils.json_encode(result[1])
        end
    end

    sql = string.format(sql_fmt.update_loginLog, body['clientIP'], os.time(), body['account'])
    only.log('D', sql)
    ok, ret = mysql_pool_api.cmd('app_daokeme___daokeme', 'update', sql)


    return ret_body

end

local function parse_body(str)

    local args = utils.parse_url(str)
    url_info['app_key'] = args['appKey']

    safe.sign_check(args, url_info)

    ---check loginType---
    if (not utils.is_number(args['loginType'])) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "loginType")
    end

    ---check account---
    if args['account'] == nil then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "account")
    end

    ---check clientIP---
    if args['clientIP'] == nil or (string.match(args['clientIP'], '%d+%.%d+%.%d+%.%d+') == nil ) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "clientIP")
    end

    return args
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_body'] = body
    url_info['client_host'] = ngx.var.remote_addr

    local handle_body = parse_body(body)

    local ret = func(handle_body) 

    if not ret then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_NOT_EXIST"], "account")
    end

    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )

-- EOF
