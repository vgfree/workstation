-- zhouzhe 2015-08-18 修改
local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local only      = require('only')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local gosay     = require('gosay')
local msg       = require('msg')
local safe      = require('safe')
local cfg       = require('config')

coreIdentif_dbname = "app_ident___ident"
userCenter_dbname = "app_usercenter___usercenter"

local sql_fmt = {
    sel_imei  = "SELECT imei FROM userLoginInfo WHERE accountID = '%s'",
    sel_model = "SELECT model FROM mirrtalkInfo WHERE imei='%s'",
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}
-- 检查参数
local function check_parameter(args)

    if not args['appKey'] or #args['appKey'] ~= 10 then
        only.log("E", "appKey is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "appKey")
    end

    url_info['app_key'] = args['appKey']

    if not args['accountID'] or not app_utils.check_accountID(args['accountID']) then
        only.log("E", "accountID is error")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    safe.sign_check(args, url_info)
end

-- 获取用户状态
local function get_user_status(a_id)

    local sql = string.format(sql_fmt.sel_imei, a_id)
    local ok, result = mysql_api.cmd( userCenter_dbname, 'SELECT', sql)

    if not ok then
        only.log('E', sql)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result == 0 then
        only.log('E', string.format("the record of accountID:%s is zero", a_id))
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    elseif #result > 1 then
        only.log('S', string.format("the record of accountID:%s is more than one, call someone to handle", a_id))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'accountID')
    end

    local imei = result[1]['imei']

    if tonumber(imei) == 0 then
        return '{"model":"","online":0}'
    end

    imei = string.sub(imei, 1, 14)

    local res_sql = string.format(sql_fmt.sel_model, imei)
    
    local ok, result = mysql_api.cmd( coreIdentif_dbname, 'select', res_sql)
    if not ok then
        only.log('E', res_sql)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result == 0 then
        only.log('E', string.format("no record of imei:%s", imei))
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
    elseif #result > 1 then
        only.log('E', string.format("the record of imei:%s is more than one, call someone to handle", imei))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'imei')
    end

    local model = result[1]['model']
    local online_status = 0

    local cur_time = os.time()
    local cfg_time = cfg['user_online_space']
    local ok, ret = redis_api.cmd('private', 'get', a_id .. ':heartbeatTimestamp')
    -- only.log("E", "=cur_time:"..cur_time.."==ret:"..ret)
    if (not ok) or (not ret) or (cur_time-tonumber(ret) > cfg_time) then
        online_status = 0
    else
        online_status = 1
    end
    return string.format('{"model":"%s","online":%d}', model, online_status)
end

function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    local args = utils.parse_url(body)
    
    -- 检查参数
    check_parameter(args)

    -- 获取用户状态
    local ret = get_user_status(args['accountID'])

    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end


safe.main_call( handle )
