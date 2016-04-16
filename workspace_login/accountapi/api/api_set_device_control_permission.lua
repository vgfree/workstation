--qiumaosheng
--2015-07-02
--用户拍照权限控制设置

local msg   = require('msg')
local safe  = require('safe')
local only  = require('only')
local gosay = require('gosay')
local utils = require('utils')
local cjson     = require('cjson')
local link      = require('link')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

userlist_dbname = "app_usercenter___usercenter"
coreident_daname = "app_ident___ident"

local G = {
    --1)检查用户账号合法性
    check_accountid  = " SELECT 1 FROM userLoginInfo WHERE accountID = '%s' ",
    --2)获取用户设备权限信息
    get_model_info  = " SELECT accountID, model, status, createTime, updateTime FROM devicePermissionInfo WHERE accountID = '%s' LIMIT 1 ",
    --3)记录设备权限信息
    insert_control_info = " INSERT INTO devicePermissionInfo ( accountID, model, status, createTime, updateTime ) VALUE ( '%s', '%s', %d, %d, %d ) ",
    --4)备份设备权限信息
    insert_control_history_info = " INSERT INTO devicePermissionInfoHistory ( accountID, model, status, createTime, updateTime ) VALUE ( '%s', '%s', %d, %d, %d ) ",
    --5)更新设备权限信息
    update_control_info = " UPDATE devicePermissionInfo SET status = '%s', updateTime =%d WHERE accountID='%s' ",

}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

--检查参数
local function check_parameter( args )
    
    if not args['appKey'] or #args['appKey'] ~= 10 then
        only.log("E", "appKey is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "appKey")
    end

    url_info['app_key'] = args['appKey']

    if not args['accountID'] or not app_utils.check_accountID(args['accountID']) then
        only.log("E", "accountID is error")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    if not args['model'] then
        only.log("E", "model is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
    end

    if not args['status'] or not string.find("0,1,2", args['status']) then
        only.log("E", "status is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "status")
    end

    safe.sign_check(args, url_info)
end

--在数据库中检查参数是否存在
local function check_data_validity( args )

    -- 1) 检查用户账号合法性
    local sql_strs = string.format( G.check_accountid,args['accountID'] )
    local ok, ret = mysql_api.cmd(userlist_dbname, 'SELECT', sql_strs)
    if not ok or not ret then
        only.log('E',"mysql is error.")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    -- 2) 获取用户设备权限信息
    local sql_strs = string.format( G.get_model_info,args['accountID'] )
    local ok , result = mysql_api.cmd(coreident_daname, 'SELECT', sql_strs)
    if not ok or not result then
        only.log('E',"mysql is error!")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result ~= 0 then
        if type(result) ~= "table" then
            only.log("E", "mysql return parameter is error")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "resultType")
        end

        return true, result[1]
    end
    
    return false
end

--设备权限信息处理update and inster
local function modify_status_info( args, bool_ok, result)

    local cur_time = os.time()
    local accountID = args['accountID']
    local model = args['model']
    local status = args['status']

    if not bool_ok then

        -- 3)记录设备权限信息
        local sql_strs = string.format( G.insert_control_info, accountID, model, status, cur_time, cur_time)
        local ok  = mysql_api.cmd(coreident_daname, 'INSERT', sql_strs)
        if not ok then
            only.log('E',"insert devicePermissionInfo fail! [SQL][%s]", sql_strs)
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

    else

        -- 4)备份数据到历史表
        local sql_strs = string.format( G.insert_control_history_info, result['accountID'], result['model'], result['status'], result['createTime'], result['updateTime'])
        local ok  = mysql_api.cmd(coreident_daname, 'INSERT', sql_strs)
        if not ok  then
            only.log('E',"insert devicePermissionInfoHistory fail! [SQL][%s]", sql_strs)
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        -- 5)更新设备权限信息
        local sql_strs = string.format( G.update_control_info, status, cur_time, accountID)
        local ok  = mysql_api.cmd(coreident_daname, 'UPDATE', sql_strs)
        if not ok then
            only.log('E',"update devicePermissionInfo fail! [SQL][%s]", sql_strs)
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

    end
end


local function handle()

    local body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_host'] = ip
    url_info['client_body'] = body

    local args = utils.parse_url(body)

    -- 1)检查参数
    check_parameter(args)

    if #args['model'] == 0 then
        args['model'] = 'MG900'
    end

    if args['model'] ~= 'MG900' then
        only.log("E", "model is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
    end

    -- 2)验证参数合法性
    local bool_ok, result = check_data_validity(args)

    -- 3)设备权限信息处理
    modify_status_info(args, bool_ok, result)

    gosay.go_success( url_info, msg["MSG_SUCCESS"] )
end

safe.main_call( handle )
