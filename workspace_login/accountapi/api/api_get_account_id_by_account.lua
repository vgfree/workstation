-- get accountid by account.lua
-- author: zhangjl (jayzh1010@gmail.com)
-- company: mirrtalk.com
-- local common_path = './?.lua;../public/?.lua;../include/?.lua;'
-- package.path = common_path .. package.path
-- 2015-08-17 zhouzhe修改

local ngx       = require('ngx')
local sha       = require('sha1')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local utils     = require('utils')
local only      = require('only')
local msg       = require('msg')
local gosay     = require('gosay')
local safe      = require('safe')

local sql_fmt = {
    sql_get_user_accountid = " SELECT accountID FROM thirdAccessOauthInfo WHERE userStatus=1 AND account='%s' ",
    sql_get_account_info = "SELECT accountID, name, nickname FROM userLoginInfo WHERE userStatus=1 AND accountID='%s' "
}

local usercenter_dbname = 'app_usercenter___usercenter'

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}
-->> 第三方用户类型
local login_str = '5, 7'

local function get_accountid_info(args)

    -->> 根据account获取accountID
    local sql1 = string.format(sql_fmt.sql_get_user_accountid, args['account'])
    only.log('D',string.format("get user info==%s", sql1))
    local ok, ret = mysql_api.cmd(usercenter_dbname, 'select', sql1)

    if not ok and not ret then
        only.log("E", "mysql get user info failed")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret <1 then
        only.log("E", "account is not exist")
        gosay.go_false(url_info, msg['MSG_ERROR_ACCOUNT_NOT_EXIST'])
    end
    local accountid = ret[1]['accountID']

    -->> 根据accountID 获取用户信息
    local sql2 = string.format(sql_fmt.sql_get_account_info, accountid )
    only.log('D',string.format("get accountid info==%s", sql2))
    local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql2)

    if not ok and not result then
        only.log("E", "mysql get accountID info failed")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result <1 then
        only.log("E", "get accountID info return failed")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "return")
    end

    local ok, ret_body = utils.json_encode(result[1])
    if ok then
        return ret_body
    else
        return false
    end
end

local function check_parameter(args)
    ---check loginType---
    if (not utils.is_number(args['loginType'])) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "loginType")
    end

    ---check account---
    if not args['account'] then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "account")
    end

    if not string.find(login_str, args['loginType']) then
        only.log("E", "loginType is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "loginType")
    end
    safe.sign_check(args, url_info)
end

local function handle()

    local body = ngx.req.get_body_data()
    local IP   = ngx.var.remote_addr
    url_info['client_body'] = body
    url_info['client_host'] = ngx.var.remote_addr
    local args = utils.parse_url(body)

    -->检查参数
    check_parameter(args)
    url_info['app_key'] = args['appKey']

    local ret = get_accountid_info(args) 

    if not ret then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_NOT_EXIST"], "account")
    end

    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )
