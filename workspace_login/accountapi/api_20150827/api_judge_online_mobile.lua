-- [author]: buyuanyuan
-- [time]: 2014-01-12
-- [company]: mirrtalk
-- 修改 2015-07-1 zhouzhe

local ngx        = require('ngx')
local utils      = require('utils')
local only       = require('only')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local gosay     = require('gosay')
local msg       = require('msg')
local safe      = require('safe')
local cfg       = require('config')

usercenter_dbname = 'app_usercenter___usercenter'

local sql_fmt = {
    getAccountIDMobileInfo = "SELECT accountID, mobile FROM userRegisterInfo WHERE checkMobile = 1 AND validity = 1 AND mobile = '%s'",
    getImeiAccountIDInfo = "SELECT imei FROM userList WHERE accountID = '%s'",
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 检查参数
local function check_parameter(body)

    local res = utils.parse_url(body)

    if not res['appKey'] or #res['appKey'] == 0 then
        only.log("E", "appKey is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "appKey")
    end

    url_info['app_key'] = res['appKey']

    if type(res) ~= 'table' then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "client body")
    end

    if not res['mobile'] or #res['mobile'] == 0 then
        only.log("E", "mobile string is nil")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "mobile nil")
    end

    safe.sign_check(res, url_info)

    if string.sub( res['mobile'] , 1,1) == ',' then
        res['mobile'] = string.sub( res['mobile'] , 2, -1)
    end

    if string.sub( res['mobile'] , -1,-1) == ',' then
        res['mobile'] = string.sub( res['mobile'] , 1, -2)
    end

    -- only.log('D', "mobile:%s", res['mobile'])
    local mobile_tab = utils.str_split(res['mobile'], ',')

    if type(mobile_tab) ~= 'table' then
        only.log("E", "mobile table is nil")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'mobile_tab type')
    end
    -- for k,v in pairs(mobile_tab) do
    --     only.log('D', "%s:%s", k, v)
    -- end

    -- check mobile
    for i=1, #mobile_tab do
        if(not utils.is_number(tonumber(mobile_tab[i]))) or (#mobile_tab[i] ~= 11) or (string.sub(mobile_tab[i], 1, 1) ~= '1') then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'mobile')
        end
    end
    res['mobile'] = mobile_tab

    return res
end

-- 通过手机号获取accountID
local function getAccountIDMobile(mobile_tab)
    local result = {}
    local bad_mobile = {}
    local sql
    for i = 1, #mobile_tab do
        sql = string.format(sql_fmt.getAccountIDMobileInfo, mobile_tab[i])
        -- only.log('D', sql)
        local ok, db_result = mysql_api.cmd( usercenter_dbname, 'SELECT', sql)

        if not ok then
            only.log("E", "getAccountIDMobile mysql is error! %s", sql)
        end

        if ok and #db_result~=0 then
            table.insert(result, db_result[1])
        else
            table.insert(bad_mobile, mobile_tab[i])
        end
    end
    return result, bad_mobile
end

-- 获取IMEI
local function getImeiAccountID(res)
    local bind_imei = {}
    local no_imei_mobile = {}
    local sql
    for i = 1, #res do
        sql = string.format(sql_fmt.getImeiAccountIDInfo, res[i]['accountID'])
        -- only.log('D', sql)
        local ok, result = mysql_api.cmd( usercenter_dbname, 'SELECT', sql)

        if not ok then
            only.log("E", "getImeiAccountID mysql is error! %s", sql)
        end

        if ok and #result~=0 and tonumber(result[1]['imei'])~= 0 then
            result[1]['accountID'] = res[i]['accountID']
            result[1]['mobile'] = res[i]['mobile']
            table.insert(bind_imei, result[1])
        else
            table.insert(no_imei_mobile, res[i]['mobile'])
        end
    end
    return bind_imei, no_imei_mobile
end

-- 判断用户是否在线
local function get_online_user(res)
    local online_tab = {}
    local offline_tab = {}

    local cur_time = os.time()
    local cfg_time = cfg['user_online_space']
    for i = 1, #res do
        -- only.log("D", "accountID:%s",res[i]['accountID'])
        local ok, ret = redis_api.cmd('private', 'get', res[i]['accountID'] .. ':heartbeatTimestamp')
        if not ok or not ret then
            only.log("E", "redis is error! %s", res[i]['accountID'] .. ':heartbeatTimestamp' )
            gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
        end
        if ok and (cur_time-tonumber(ret) < cfg_time) then
            table.insert(online_tab, res[i]['mobile'])
        else
            table.insert(offline_tab, res[i]['mobile'])
        end
    end
    return online_tab, offline_tab
end

-- 获取用户状态
local function get_user_status(res)
    -- 获取 accountID  mobile在 userRegisterInfo
    local account_mobile_info, no_account_mobile = getAccountIDMobile(res['mobile'])
    -- 获取 IMEI 、accountID 在userList
    local bind_imei, no_imei_mobile = getImeiAccountID(account_mobile_info)
    -- 判断用户是否在线
    local online_mobile, offline_mobile = get_online_user(bind_imei)

    local ret_tab = {}

    if no_account_mobile and #no_account_mobile ~= 0 then 
        -- no account id
        for i, v in pairs( no_account_mobile) do
            ret_tab[ v ] = {  status = -3  }
        end
    end
    if no_imei_mobile and #no_imei_mobile ~= 0 then
        -- no imei
        for i, v in pairs( no_imei_mobile) do
            ret_tab[ v ] = {  status = -2  }
        end
    end
    if offline_mobile and #offline_mobile ~= 0 then
        -- no newstatus timestamp
        for i, v in pairs( offline_mobile)  do
            ret_tab[ v ] = {  status = -1  }
        end
    end
    if online_mobile and #online_mobile ~= 0 then
        -- online user
        for i, v in pairs ( online_mobile) do
            ret_tab[ v ] = {  status = 0  }
        end
    end

    local ok, ret = utils.json_encode(ret_tab)

    return ret
end

function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    -- 检查参数
    local res = check_parameter(body)
    -- 获取用户状态
    local ret = get_user_status(res)

    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end


safe.main_call( handle )
