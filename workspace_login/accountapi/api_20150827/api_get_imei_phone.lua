-- author: zhangjl (jayzh1010@gmail.com) 
-- company: mirrtalk.com
-- 优化 2015-07-21 zhouzhe

local ngx       = require('ngx')
local msg       = require('msg')
local safe      = require('safe')
local only      = require('only')
local gosay     = require('gosay')
local utils     = require('utils')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

local userlist_dbname = 'app_usercenter___usercenter'

local G = {
    sl_imei = "SELECT imei FROM userList WHERE accountID='%s'",
    sl_phone = "SELECT mobile, checkMobile FROM userRegisterInfo WHERE accountID='%s' AND validity=1",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function get_imei_mobile(a_id)

    local ret_body, imei, phone, check_mobile

    local sql = string.format(G.sl_imei, a_id)
    only.log('D', " sl_imei ,%s",sql)
    local ok, res = mysql_api.cmd( userlist_dbname, 'SELECT', sql)
    if not ok or not res then
        only.log('E','sl_imei connect userlist_dbname failed! %s', sql )
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if ok and #res ~= 0 then
        imei = res[1]['imei']
    end

    sql = string.format(G.sl_phone, a_id)
    ok, res = mysql_api.cmd( userlist_dbname, 'SELECT', sql)
    only.log('D', " sl_phone ,%s",sql)
    if not ok or not res then
        only.log('E','sl_phone connect userlist_dbname failed! %s', sql )
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    if ok and #res ~=0 then
        check_mobile = res[1]['checkMobile']
        if tonumber(check_mobile) == 1 then
            phone = res[1]['mobile']
        end
    end

    ret_body = string.format('{"imei":"%s","phone":"%s", "checkMobile":"%s"}', imei or '', phone or '', check_mobile or '')

    return ret_body
end

local function check_parameter(args)
    if not args then
        only.log('E',string.format('call parse_url function return nil!'))
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end
    if not args['appKey'] or #args['appKey'] > 10 then
        only.log("E", "appKey is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'appKey')
    end
    url_info['app_key'] = args['appKey']

    if (not app_utils.check_accountID(args['accountID'])) then
        only.log("E", "accountID is error")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountID")
    end
    -- 2015-07-21 zhouzhe  accessToken
    safe.sign_check(args, url_info, 'accountID', safe.ACCESS_USER_INFO)
end

local function handle()
    local body = ngx.req.get_body_data()
    local ip   = ngx.var.remote_addr
    if not body then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_info['client_body'] = body
    url_info['client_host'] = ip

    local args = utils.parse_url(body)
    -- 检查参数
    check_parameter(args)
    -- 获取imei和手机号
    local ret = get_imei_mobile(args['accountID'])
    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )