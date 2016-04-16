-->owner:zhouzhe
-->time :2014-03-31
-->获得用户昵称api

local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local ngx = require('ngx')
local gosay = require('gosay')
local redis_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {
    get_user_info = "SELECT %s FROM userInfo WHERE accountID='%s' AND status=1"

}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

 local table_info = {
        'name' ,
        'nickname' ,
        'birthday' ,
        'gender' ,
        'mobile'  ,
        'bloodType' ,
        'userEmail' ,
        'drivingHabit' ,
        'drivingLicense' ,
        'drivingLicenseIssueDate' ,
        'plateNumber' ,
        'VIN',
        'drivingLicenseAddress' ,
        'insuranceCompany' ,
        'vehicleCommercialInsurance',
        'trafficCompulsoryInsurance' ,
        'insurancePeriod',
        'driverEmergencyContact',
        'driverContactRelation' ,
        'driverEmergencyMobile',
        'purchaseCar4SName' ,
        'commonUse4SName' ,
        'tyreBrand' ,
        'tyreModel' ,
        'SOSContactMobile' ,
        'constellation' ,
        'limitPassenger' ,
        'operatingLicenseNumber' ,
        'driverCertificationNumber' ,
        'checkMobileTime' ,
        'checkUserEmailTime' ,
        'idNumber' ,
        'guardianMobile', 
}


-->chack parameter
local function check_parameter(args)
    --> check username 
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
    -->> safe check
    safe.sign_check(args, url_info, 'accountID', safe.ACCESS_USER_INFO)
end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    if not body then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    local args = utils.parse_url(body)
    url_info['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)
   
    only.log('D', args['field'])
    local ok, result

    if not args['field'] or #tostring(args['field']) < 1 then

        local sql = string.format(sql_fmt.get_user_info, '*' , args['accountID'])
        ok, result = mysql_pool_api.cmd('app_cli___cli', 'select', sql)
    else
        local str_table = utils.str_split(args['field'], ',')

        --判断输入用户信息名称是否正确
        local flag = 0
        for k= 1,#str_table do
            flag= 0
            for i= 1, #table_info do
                if str_table[k] == table_info[i] then
                    flag = 1
                end
            end
            
            if flag ~= 1  then
                only.log('E',string.format(" %s is not match !", str_table[k]) )
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], str_table[k] )
            end
        end

        local str = table.concat(str_table,',')
 
        local sql = string.format(sql_fmt.get_user_info, str , args['accountID'])
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_cli___cli', 'select', sql)
        
        if not ok then
            only.log('E',string.format("get user info failed,  %s", sql) )
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end

        if #result == 0 then
            gosay.go_success(url_info, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
        end
    end

    local ok, ret_req = utils.json_encode(result[1])
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_req)
end

safe.main_call( handle )
