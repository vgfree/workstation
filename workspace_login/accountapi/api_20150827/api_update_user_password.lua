-- update user password.lua
-- author: zhangjl (jayzh1010@gmail.com)
-- company: mirrtalk.com

-- local common_path = './?.lua;../public/?.lua;../include/?.lua;'
-- package.path = common_path .. package.path

local ngx = require('ngx')
local sha = require('sha1')
local msg = require('msg')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local gosay = require('gosay')
local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local safe = require('safe')

local sql_fmt = {

    sl_account = "SELECT userStatus,daokePassword,imei FROM userList WHERE accountID='%s'   ",

    update_userlist = "UPDATE userList SET daokePassword='%s', updateTime=%d WHERE accountID='%s'",

    insert_history = "INSERT INTO userListHistory(accountID,userStatus,updateTime,daokePassword,imei) VALUES('%s', %d, %d, '%s', '%s')",

    nil
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function func(body)

    local sql = string.format(sql_fmt.sl_account, body['accountID'])
    only.log('D', sql)
    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)
    if not ok or #ret==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"], "accountID")
    elseif #ret>1 then
        only.log('S', string.format("the record of accountID:%s more than one,call someone to handle", body['accountID']))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], "accountID")
    end

    local pwd = ret[1]['daokePassword']

    local old_pwd = (body['oldPassword'])
    if old_pwd ~= '' then
        old_pwd = ngx.md5(sha.sha1(body['oldPassword']) .. ngx.crc32_short(body['oldPassword']))
    end

    local new_pwd = ngx.md5(sha.sha1(body['newPassword']) .. ngx.crc32_short(body['newPassword']))

    only.log('D', string.format('old: %s  new password:%s ', old_pwd , new_pwd) )

    if pwd~='' and pwd ~= old_pwd then
        gosay.go_false(url_info, msg["MSG_ERROR_PWD_NOT_MATCH"])
    end

    local transaction_tab = {}
    local cur_time = os.time()

    local sql = string.format(sql_fmt.update_userlist, new_pwd, cur_time, body['accountID'])
    only.log('D', sql)
    table.insert(transaction_tab, sql)
    sql = string.format(sql_fmt.insert_history, body['accountID'], ret[1]['userStatus'], cur_time, new_pwd, ret[1]['imei'])
    only.log('D', sql)
    table.insert(transaction_tab, sql)

    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'affairs', transaction_tab)
    if not ok then
        only.log('E', "commit transaction failed")
        return nil
    end

    return true

end

local function parse_body(str)

    local args = utils.parse_url(str)
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

    local handle_body = parse_body(body)

    local ret = func(handle_body)

    local result
    if ret ~= nil then
        gosay.go_success(url_info, msg["MSG_SUCCESS"])
    else
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end

end


safe.main_call( handle )

-- EOF
