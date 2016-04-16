-- update user password.lua
-- author: zhangjl (jayzh1010@gmail.com)
-- company: mirrtalk.com
-- local common_path = './?.lua;../public/?.lua;../include/?.lua;'
-- package.path = common_path .. package.path
-- zhouzhe 2015-08-09 修改
local ngx       = require('ngx')
local sha       = require('sha1')
local msg       = require('msg')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local safe      = require('safe')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local sql_fmt = {

    sql_get_old_pwd = "SELECT daokePassword FROM userLoginInfo WHERE userStatus=1 AND accountID='%s'",

    sql_update_user_pwd = "UPDATE userLoginInfo SET daokePassword='%s', updateTime=%d WHERE accountID='%s'",

    -- sl_account = "SELECT userStatus,daokePassword,imei FROM userList WHERE accountID='%s'   ",

    -- update_userlist = "UPDATE userList SET daokePassword='%s', updateTime=%d WHERE accountID='%s'",

    -- insert_history= "INSERT INTO userListHistory(accountID,userStatus,updateTime,daokePassword,imei)VALUES('%s',%d,%d,'%s','%s')"
}

local usercenter_dbname = 'app_usercenter___usercenter'

local url_info = {
    type_name = 'system',                                                                                                                                                                                                                                                             
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function modify_user_pwd(body)
    -->> 获取旧密码
    local sql = string.format(sql_fmt.sql_get_old_pwd, body['accountID'])
    only.log('D', string.format("get old pwd==%s", sql))
    local ok, ret = mysql_api.cmd(usercenter_dbname, 'select', sql)
    if not ok or #ret==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    elseif #ret>1 then
        only.log('S', string.format("the record of accountID:%s more than one,call someone to handle", body['accountID']))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], "accountID")
    end

    local pwd = ret[1]['daokePassword']

    local old_pwd = body['oldPassword']
    if old_pwd ~= '' then
        old_pwd = ngx.md5(sha.sha1(body['oldPassword']) .. ngx.crc32_short(body['oldPassword']))
    end

    if not pwd or tostring(pwd)~=tostring(old_pwd) then
        gosay.go_false(url_info, msg["MSG_ERROR_PWD_NOT_MATCH"])
    end

    local new_pwd = ngx.md5(sha.sha1(body['newPassword']) .. ngx.crc32_short(body['newPassword']))

    only.log('D', string.format('===old: %s new password:%s ', old_pwd , new_pwd))

    -->> 修改密码
    -- local transaction_tab = {}
    local cur_time = os.time()
    local sql = string.format(sql_fmt.sql_update_user_pwd, new_pwd, cur_time, body['accountID'])
    only.log('D', string.format("==update user pwd==%s", sql))
    local ok = mysql_api.cmd(usercenter_dbname, 'UPDATE', sql)
    if not ok then
        only.log("E", "mysql failed update user pwd")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    -- local sql = string.format(sql_fmt.update_userlist, new_pwd, cur_time, body['accountID'])
    -- only.log('D', sql)
    -- table.insert(transaction_tab, sql)
    -- sql = string.format(sql_fmt.insert_history, body['accountID'], ret[1]['userStatus'], cur_time, new_pwd, ret[1]['imei'])
    -- only.log('D', sql)
    -- table.insert(transaction_tab, sql)

    -- local ok, ret = mysql_api.cmd(usercenter_dbname, 'affairs', transaction_tab)
    -- if not ok then
    --     only.log('E', "commit transaction failed")
    --     return nil
    -- end
    return true
end

local function parse_body(args)

    if not args or type(args) ~= 'table' then
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_BAD_JSON'])
    end
    url_info['app_key'] = args['appKey']

    safe.sign_check(args, url_info)

    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    -- if (#args['oldPassword'] < 6) then
    --     gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "oldPassword")
    -- end

    if (#args['newPassword'] < 6) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "newPassword")
    end

    if (args['newPassword'] == args['oldPassword']) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "newPassword equal oldPassword")
    end

    return args
end

local function handle()

    local head = ngx.req.raw_header()
    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body
    local args = utils.parse_url(body)
    parse_body(args)

    local ret = modify_user_pwd(args)

    if ret then
        gosay.go_success(url_info, msg["MSG_SUCCESS"])
    else
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end
end


safe.main_call( handle )

