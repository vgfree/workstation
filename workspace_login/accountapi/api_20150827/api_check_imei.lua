-->owner:chengjian
-->time :2013-01-21

local utils = require('utils')
local only = require('only')
local ngx = require('ngx')
local cfg = require('config')
local gosay = require('gosay')
local mysql_api = require('mysql_pool_api')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {
    sql_check_imei = "SELECT 1 FROM userList WHERE imei= %s  ",
    sql_get_imei_info = "SELECT 1 FROM mirrtalkInfo WHERE imei=%s AND ncheck=%s",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->check parameter
local function check_parameter(body)

    local args = utils.parse_url(body)
    if not args or not args['appKey'] then
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_FAILED_GET_SECRET'])
    end

    url_info['app_key'] = args['appKey']

    -->> safe check
    safe.sign_check(args, url_info)

    --> check imei
    local imei = args['IMEI']
    if not imei or (not utils.is_number(imei)) or (#imei~=15) or (string.sub(imei, 1, 1)=='0') then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'IMEI')
    end
    return args
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    if not body  then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    -->check parameter
    local args = check_parameter(body)

    --> check imei record from userList	
    local sql = string.format(sql_fmt.sql_check_imei, args['IMEI'])
    local ok , result = mysql_api.cmd('app_usercenter___usercenter', 'select', sql)
    if not ok or not result then
        only.log('E',string.format("sql check imei failed , %s", sql ))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    --> if imei is nil
    local ret_req
    if #result == 0 then
        -- 输入的IMEI的前14为为新的imei，第15位作为ncheck
        local imei = string.sub(args['IMEI'], 1, 14)
        local ncheck = string.sub(args['IMEI'], -1, -1)

        -- check imei record from mirrtalkInfo
        sql = string.format(sql_fmt.sql_get_imei_info, imei, ncheck)
        ok, result = mysql_api.cmd('app_ident___ident', 'select', sql)
        if not ok or not result then
            only.log('E',string.format("sql get imei info failed , %s", sql ))
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        -- 如果查询结果为空,返回输入的imei非法的imei错误信息,将返回-1
        if #result == 0 then

            only.log('E', string.format("the IMEI is illegal %s " , args['IMEI'] ) )
            ret_req = -1

        -- 如果查询结果记录为多条,将返回-2
        elseif #result > 1 then
            only.log('S', "more than one imei record in mirrtalkInfo")
            ret_req = -2

	   -- 如果只有一条记录，以该IMEI允许绑定返回，即0
        else
            ret_req = 0
        end

    --> if imei is one record
    elseif #result  == 1 then 
        --如果只有一条记录,返回该IMEI已被用户绑定的错误信息,将返回-3
        only.log('I', "more than one accountID record in mirrtalkInfo")
        ret_req = -3

    --> if more than one record
    else
        --如果查询结果记录为多条，将返回-2
        only.log('S', "more than one accountID record in userList")
        ret_req = -2
    end

    only.log('D', string.format("IMEI:%s ret_req %s " , args['IMEI'] ,ret_req) )

    --判断返回值，确认设置是否成功，当返回值为0时返回成功
    if ret_req == 0 then
        gosay.go_success(url_info, msg['MSG_SUCCESS'])
    elseif ret_req == -1 then
        gosay.go_false(url_info, msg['MSG_ERROR_IMEI_ILLEGAL'])
    elseif ret_req == -2 then 
        gosay.go_false(url_info, msg['SYSTEM_ERROR'])
    else 
        gosay.go_false(url_info, msg['MSG_ERROR_IMEI_HAS_BIND'])
    end
end


safe.main_call( handle )
