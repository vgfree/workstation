-->owner:chengjian
-->time :2014-03-31
---- modify by jiang z.s. 2015-04-20 
---- 通过accountID获取账户的相关信息
---- 2015-08-14 zhouzhe 修改

local utils     = require('utils')
local only      = require('only')
local ngx       = require('ngx')
local gosay     = require('gosay')
local msg       = require('msg')
local safe      = require('safe')
local mysql_api = require('mysql_pool_api')

local sql_fmt = {
    -- get_user_info = "SELECT * FROM userInfo WHERE accountID='%s' AND status=1"

    get_user_info = " SELECT %s FROM userLoginInfo AS a, userGeneralInfo AS b WHERE "..
                    " a.userStatus=1 AND b.userStatus=1 AND a.accountID='%s' AND b.accountID='%s' ",
}

local db_value ="name, nickname,mobile, gender,drivingLicense,plateNumber,bloodType,birthday,SOSContactMobile,homeAddress,idNumber,operatingLicenseNumber"

local usercenter_dbname = 'app_usercenter___usercenter'

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    --> check username 
    if not args['username'] then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'username')
    end

    -->> safe check
    safe.sign_check(args, url_info)

end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    if body == nil then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)
    url_info['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)

    local account_id = args['username']

    local sql = string.format(sql_fmt.get_user_info, db_value, account_id, account_id )
    local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql)
    if not ok or not result then
        only.log('E',string.format("get user info failed , %s ", sql))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result==0 then
        gosay.go_success(url_info, msg['MSG_ERROR_USER_NAME_NOT_EXIST'])
    end

    local ok, ret_req = utils.json_encode(result[1])
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_req)
end

safe.main_call( handle )
