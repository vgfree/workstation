-- qiumaosheng
-- 2015-07-03
-- 查询用户拍照权限控制

local msg   = require('msg')
local safe  = require('safe')
local only  = require('only')
local gosay = require('gosay')
local utils = require('utils')
local cjson     = require('cjson')
local link      = require('link')
local mysql_api = require('mysql_pool_api')

coreident_daname = "app_ident___ident"

local G = {
    -- 获取用户设备权限信息
    get_status_info  = " SELECT accountID, status FROM devicePermissionInfo WHERE model = 'MG900' and accountID = '%s' ",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 检查参数
local function check_parameter(res)
    if not res['appKey'] or #res['appKey'] == 0 then
        only.log("E", "appKey is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "appKey")
    end

    url_info['app_key'] = res['appKey']

    if not res['accountIDs'] or #res['accountIDs'] == 0 then
        only.log("E", "accountIDs string is nil")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountIDs nil")
    end

    safe.sign_check(res, url_info)

    if string.sub( res['accountIDs'] , 1,1) == ',' then
        res['accountIDs'] = string.sub( res['accountIDs'] , 2, -1)
    end

    if string.sub( res['accountIDs'] , -1,-1) == ',' then
        res['accountIDs'] = string.sub( res['accountIDs'] , 1, -2)
    end

    local accountIDs_tab = utils.str_split(res['accountIDs'], ',')

    if type(accountIDs_tab) ~= 'table' then
        only.log("E", "accountIDs table is nil")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'mobile_tab type')
    end

    -- check accountIDs
    for i=1, #accountIDs_tab do
        if #accountIDs_tab[i] ~= 10 then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountIDs')
        end
    end
    res['accountIDs'] = accountIDs_tab
end


-- 获取用户拍照权限
local function get_user_status(res)
    local res_tab = {}
    local tab_res = {}
    for i = 1, #res['accountIDs'] do
        local sql = string.format(G.get_status_info, res['accountIDs'][i])
        local ok, db_result = mysql_api.cmd(coreident_daname, 'SELECT', sql)

        if not ok then
            only.log("E", "get_user_status mysql is error! %s", sql)
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        if #db_result ~= 0 then
            table.insert(res_tab, db_result[1])
        end

        if #db_result == 0 then
            tab_res['accountID'] = res['accountIDs'][i]
            tab_res['status']    = '1'
            table.insert(res_tab, tab_res)
        end
    end

    local ok, ret = utils.json_encode(res_tab)
    if not ok then
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end
    return ret
end


local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local res = utils.parse_url(body)

    -- 1)检查参数
    check_parameter(res)

    -- 2)获取用户拍照权限
    local ret = get_user_status(res)

    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end


safe.main_call( handle )