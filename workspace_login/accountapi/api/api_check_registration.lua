-->owner:chengjian
-->time :2013-01-21
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path
--> 2015-08-15 zhouzhe 修改
local ngx       = require('ngx')
local only      = require('only')
local utils     = require('utils')
local gosay     = require('gosay')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local msg       = require('msg')
local safe      = require('safe')

local sql_fmt = {
    -- sql_check_user_name = "SELECT username FROM userLoginInfo WHERE username='%s' AND validity=1",
    -- sql_check_mobile = "SELECT mobile FROM userLoginInfo WHERE mobile=%s AND validity=1",
    -- sql_check_user_email = "SELECT userEmail FROM userLoginInfo WHERE userEmail='%s' AND validity=1",
    sql_check_user_name = "SELECT 1 FROM userLoginInfo WHERE %s='%s' ", 
}

local usercenter_dbname = 'app_usercenter___usercenter'
local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(body)

    local args = utils.parse_url(body)
    url_info['app_key'] = args['appKey']

    -->> safe check
    safe.sign_check(args, url_info)

    --> check username 
    if not args['username'] then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'username')
    end

    return args
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    if body == nil then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    -->check parameter
    local args = check_parameter(body)
 
    -->check username
    local sql
    local user_name = args['username']
    -- 手机号码为1开头的11位数字
    if #user_name == 11 and utils.is_number(user_name) and string.sub(user_name, 1, 1)=='1' then
        sql = string.format(sql_fmt.sql_check_user_name, 'mobile',user_name)
    
    -- 用户邮箱字段中包含@符号
    elseif string.match(user_name, '@') then
        sql = string.format(sql_fmt.sql_check_user_name, 'userEmail', user_name)
    
    -- 用户名是由数字、下划线或字母组成，且首字母为非数字
    elseif not utils.is_number(string.sub(user_name, 1, 1))then
        sql = string.format(sql_fmt.sql_check_user_name, 'username', string.lower(user_name))
    else
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "username")
    end
    
    only.log('D', string.format("get user name", sql))
    local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql)
    if not ok then
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    --> if imei is nil
    if #result == 0 then
        gosay.go_success(url_info, msg['MSG_SUCCESS'])

    --> if imei is one record
    elseif #result  == 1 then 
        --如果只有一条记录,返回该输入的用户名已被用户绑定的错误信息,将返回-1
        gosay.go_false(url_info, msg['MSG_ERROR_USER_NAME_EXIST'])

    --> if more than one record
    else
        --如果查询结果记录为多条，将返回-2
        only.log('S', string.format('this username:%s has too many record', args['username']))
        gosay.go_false(url_info, msg['MSG_ERROR_MORE_RECORD'], 'username')
    end

end


safe.main_call( handle )
