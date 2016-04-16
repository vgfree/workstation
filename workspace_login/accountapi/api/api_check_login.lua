---- zhouzhe
---- 2015-08-12
---- 用户账号登录

local ngx       = require('ngx')
local msg       = require('msg')
local sha       = require('sha1')
local safe      = require('safe')
local only      = require('only')
local utils     = require('utils')
local gosay     = require('gosay')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local sql_fmt = {
    -->> 获取用户信息
    sql_get_user_info = "SELECT accountID, name, nickname, mobile, daokePassword FROM userLoginInfo WHERE userStatus=1 AND %s='%s' ",

    -->> 更新登录ip
    sql_update_loginLog = "UPDATE userLoginInfo SET clientIP = INET_ATON('%s'), updateTime =%d WHERE accountID='%s' ",

    -- 登录时APP版本
    sql_save_version_info = "INSERT INTO userLoginLog (accountID, %s, appVersion, phoneBrand, phoneSystems, appKey, createTime, remark) "..
                                                    " value ('%s', '%s', '%s', '%s', '%s', %s, %s, '%s') ",
}

local crowd_dbname = 'app_crowd___crowd'
local userident_dbname = 'app_ident___ident'
local usercenter_dbname = 'app_usercenter___usercenter'

local cur_time = os.time()

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->> 检查参数
local function check_parameter( args )

    for key, val in pairs(args) do
        local value = tostring( val or '')
        local str_res = string.find(value, "'")
        local str_tmp = string.find(value, "%%")
        if str_res or str_tmp then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], key )
            only.log("E", string.format("parameter is error==key=%s===value=%s", key, value ))

        end
    end

    if not args or type(args) ~= "table" then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "table")
    end

    if ( not args['appKey'] ) or ( #args['appKey'] > 10 ) or ( not utils.is_number(args['appKey']))  then
        gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
    end

    if not args['daokePassword'] or (#args['daokePassword'] < 6) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'daokePassword')
    end

    safe.sign_check(args, url_info)

end


local function get_user_login_info( args )

    local sql=''
    local loginType
    -- 手机号码为1开头的11位数字
    if #args['username'] == 11 and utils.is_number(args['username']) and tonumber(string.sub(args['username'], 1, 1)) == 1 then
        sql = string.format(sql_fmt.sql_get_user_info, 'mobile', args['username'])
        loginType = 'mobile'

    -- 用户邮箱字段中包含@符号
    elseif string.match(args['username'], '@') then
        sql = string.format(sql_fmt.sql_get_user_info, 'userEmail', args['username'])
        loginType = 'userEmail'

    -- 用户名是由数字、下划线或字母组成，且首字母为非数字
    elseif utils.is_word(string.sub(args['username'], 1, 1)) then
        sql = string.format(sql_fmt.sql_get_user_info, 'username', string.lower(args['username']))
        loginType = 'username'

    else
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'username')
    end

    only.log('D',string.format("get user info ===%s", sql))
    local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql)

    if not ok or not result then 
        only.log('E',string.format("get_accountID_by===%s",sql))
        gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end
    if type(result)~="table" then
        only.log("E", "get user info return failed")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "get username info return")
    end

    if #result < 1 then
        gosay.go_false(url_info, msg["MSG_ERROR_USER_NAME_NOT_EXIST"])
    elseif #result>1 then
        only.log('E', string.format('this username:%s has too many record', args['username']))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'username')
    else
        return result[1], loginType
    end
end


local function save_login_log( ret_tab, args, loginType )

    only.log('D', string.format("[ save_login_log ], loginType = %s , %s", loginType, args['username']))
    local sql_table = {}
    local appVersion = args['appVersion'] or ''                         -- APP版本
    local phoneBrand = args['phoneBrand'] or ''                         -- 手机品牌（华为p7、苹果5s、oppo等）
    local phoneSystems = args['phoneSystems'] or ''                     -- 手机系统（ios、安卓）

    local password = ngx.md5(sha.sha1(args['daokePassword']) .. ngx.crc32_short(args['daokePassword']))
    if tostring(password) ~= ret_tab['daokePassword'] then
        gosay.go_false(url_info, msg["MSG_ERROR_PWD_NOT_MATCH"])
    end

    -->> 更新用户ip
    local sql = string.format(sql_fmt.sql_update_loginLog, args['clientIP'], cur_time, ret_tab['accountID'])
    table.insert(sql_table, sql)

    -- accountID, username, mobile, userEmail, appVersion, phoneBrand, phoneSystems, appKey, createTime, remark
    local sql = string.format(sql_fmt.sql_save_version_info, loginType, 
                                                             ret_tab['accountID'],                                      
                                                             args['username'], 
                                                             appVersion, 
                                                             phoneBrand, 
                                                             phoneSystems, 
                                                             args['appKey'], cur_time, '账户登录')
    table.insert(sql_table, sql)
    local ok ,ret = mysql_api.cmd(usercenter_dbname, 'AFFAIRS', sql_table)
    if not ok then
        only.log('E',string.format("update user login failed, %s", table.concat(sql_table, '\r\n')))
    end

end

function handle()
    local IP = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_host'] = IP
    url_info['client_body'] = body

    local args = utils.parse_url(body)

    -->> 检查参数
    check_parameter( args )
    if args['username'] and #args['username'] >0 then
        args['username'] = string.lower(args['username'])
    end
    url_info['app_key'] = args['appKey']
    args['clientIP'] = IP

    -->> 获取用户信息
    local ret_tab, loginType = get_user_login_info( args )

    -->> 根据IMEI获取其他参数
    save_login_log( ret_tab, args, loginType )
    local return_tab={}
    return_tab['mobile'] = ret_tab['mobile'] or ''
    return_tab['accountID'] = ret_tab['accountID']
    return_tab['nickname'] = ret_tab['nickname'] or ''
    return_tab['name'] = ret_tab['name'] or ''
    local ok, ret = utils.json_encode(return_tab)
    if not ok then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_BAD_JSON'])
    end
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end

safe.main_call( handle )
