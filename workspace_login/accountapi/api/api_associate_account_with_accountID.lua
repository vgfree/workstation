-->owner:chengjian
-->time :2013-01-21
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path

local msg       = require('msg')
local safe      = require('safe')
local utils     = require('utils')
local only      = require('only')
local ngx       = require('ngx')
local cfg       = require('config')
local gosay     = require('gosay')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local app_utils = require('app_utils')


local sql_fmt = {
    get_account_id = "SELECT accountID, id FROM thirdAccessOauthInfo WHERE userStatus=1 AND account='%s' AND loginType=%d ",
    insert_record = "INSERT INTO thirdAccessOauthInfo SET accountID='%s', loginType=%d, account='%s',token='%s', refreshToken='%s', accessToken='%s', accessTokenExpiration=%d",
    update_record = "UPDATE thirdAccessOauthInfo SET token='%s', refreshToken='%s', accessToken='%s', accessTokenExpiration=%d WHERE id=%d",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(args)
   
    ---check account---

    local account = args['account']
    if account == nil or (string.len(account) >= 64) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'account')
    end

    ---check accountID---
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    ---check loginType---
    if not utils.is_number(args['loginType']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'loginType')
    end

    -- check token
    if args['token'] == nil or args['refreshToken'] == nil or args['accessToken'] == nil then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'token')
    end

    -- check accessTokenExpiration
    if not utils.is_number(args['accessTokenExpiration']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accessTokenExpiration')
    end

    safe.sign_check(args, url_info)
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_body'] = body
    url_info['client_host'] = ngx.var.remote_addr

    if body == nil then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)

    url_info['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args) 

    local account = args['account']
    local login_type = args['loginType']
    local sql = string.format(sql_fmt.get_account_id, account, login_type)
    only.log('D', sql)
    local ok, result = mysql_api.cmd('app_usercenter___usercenter', 'select', sql)

    local id, db_accountID, ret_req
    local account_id = args['accountID']
    -- 没有记录则插入一条记录到userCenter.loginType表中
    if #result == 0 then
        sql = string.format(sql_fmt.insert_record, account_id, login_type, account, args['token'], args['refreshToken'], args['accessToken'], args['accessTokenExpiration'])
        only.log('D', sql)
        ok, ret_req = mysql_api.cmd('app_usercenter___usercenter', 'insert', sql)

    else
        local db_accountID = result[1]['accountID']
        local id = result[1]['id']

        -- 如果已有记录且accountID与输入的accountID不一致则返回输入的第三方账户已经存在的错误信息    
        if db_accountID ~= account_id then
            gosay.go_false(url_info, msg['MSG_ERROR_ACCOUNT_EXIST'])
        end

        -- 如果已有记录且accountID与输入的accountID一致，根据id更新token、refreshToken、accessToken、accessTokenExpiration的值
        sql = string.format(sql_fmt.update_record, args['token'], args['refreshToken'], args['accessToken'], args['accessTokenExpiration'], id)
        only.log('D', sql)
        ok, ret_req = mysql_api.cmd('app_usercenter___usercenter', 'update', sql)

    end

    gosay.go_success(url_info, msg['MSG_SUCCESS'])
end


safe.main_call( handle )
