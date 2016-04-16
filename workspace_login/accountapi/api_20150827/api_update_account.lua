-- update account.lua
-- author: zhangjl (jayzh1010@gmail.com)
-- company: mirrtalk.com

-- local common_path = './?.lua;../public/?.lua;../include/?.lua;'
-- package.path = common_path .. package.path

local ngx = require('ngx')
local msg = require('msg')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local gosay = require('gosay')
local utils = require('utils')
local only = require('only')
local app = require('app')

local sql_fmt = {

    sl_account_by_imei = "SELECT accountID, daokePassword, mirrtalkNumber FROM userList WHERE imei='%s'",

    sl_account = "SELECT accountID, daokePassword, imei FROM userList WHERE mirrtalkNumber='%s'",

    update_userlist = "UPDATE userList SET mirrtalkNumber='%s', updateTime=%d, userStatus=%d WHERE accountID='%s'",

    insert_history = "INSERT INTO userListHistory VALUES(null, '%s', '%s', %d, %d, '%s', '%s')",

    nil
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function func(imei)

    local sql = string.format(sql_fmt.sl_account_by_imei, imei)
    only.log('D', sql)
    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #ret==0 then
        return true
    elseif #ret>1 then
        only.log('S', string.format("the record of imei:%s more than one,call someone to handle", imei))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'IMEI')
    end

    local account_id = ret[1]['accountID']
    local password = ret[1]['daokePassword']
    local db_mt_number = ret[1]['mirrtalkNumber']

    local ok, mt_number = redis_pool_api.cmd('private', 'get', imei .. ":mirrtalkNumber")
    if mt_number == db_mt_number then
        return true
    end

    local cur_time, bad_account_id = os.time(), nil
    local transaction_tab = {}

    local sql = string.format(sql_fmt.sl_account, mt_number)
    only.log('D', sql)
    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #ret==0 then 
        local sql = string.format(sql_fmt.update_userlist, mt_number, cur_time, 1, account_id)
        only.log('D', sql)
        table.insert(transaction_tab, sql)
        sql = string.format(sql_fmt.insert_history, account_id, mt_number, 1, cur_time, password or '', imei or '')
        only.log('D', sql)
        table.insert(transaction_tab, sql)
    elseif #ret==1 then
        if account_id ~= ret[1]['accountID'] then
            bad_account_id = ret[1]['accountID']
            local sql = string.format(sql_fmt.update_userlist, 0, cur_time, 5, bad_account_id)
            only.log('D', sql)
            table.insert(transaction_tab, sql)
            sql = string.format(sql_fmt.insert_history, bad_account_id, 0, 5, cur_time, ret[1]['daokePassword'] or '', ret[1]['imei'] or '')
            only.log('D', sql)
            table.insert(transaction_tab, sql)
        else
            local sql = string.format(sql_fmt.update_userlist, mt_number, cur_time, 1, account_id)
            only.log('D', sql)
            table.insert(transaction_tab, sql)
            sql = string.format(sql_fmt.insert_history, ret[1]['accountID'], mt_number, 1, cur_time, ret[1]['daokePassword'] or '', ret[1]['imei'] or '')
            only.log('D', sql)
            table.insert(transaction_tab, sql)
        end
    else
        only.log('S', "the record with mirrtalkNumber: exist more than one, call someone to handle this", mt_number)
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'IMEI')
    end

    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'affairs', transaction_tab)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    only.log('I', "accountID transaction ok")

    return true
end

local function parse_body(str)

    local res = utils.parse_url(str)
    url_info['app_key'] = res['appKey']
    
    -- check safe
    app.new_safe_check(res, url_info)

    local imei = res['IMEI']
    if (not tonumber(imei)) or tonumber(string.sub(imei,1,1))==0 or (string.len(imei) ~= 15) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'imei')
    end

    return res
end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    only.log('D', body)

    local handle_body = parse_body(body)

    local ret = func(handle_body['IMEI'])

    if ret then
        gosay.go_false(url_info, msg["MSG_SUCCESS"])
    else
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"]) 
    end
end


handle()

-- EOF
