-->owner:chengjian
-->time :2014-03-31
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path

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
    get_user_info = "SELECT name,nickname,gender,mobile,bloodType,userEmail,birthday,drivingHabit,drivingLicense,drivingLicenseIssueDate,plateNumber,VIN,drivingLicenseAddress,insuranceCompany,vehicleCommercialInsurance,trafficCompulsoryInsurance,insurancePeriod,driverEmergencyContact,driverContactRelation,driverEmergencyMobile,purchaseCar4SName,commonUse4SName,tyreBrand,tyreModel,SOSContactMobile,constellation,limitPassenger,operatingLicenseNumber,driverCertificationNumber,checkMobileTime,checkUserEmailTime,idNumber,guardianMobile FROM userInfo WHERE accountID='%s' AND status=1"
}



local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    -->> safe check
    safe.sign_check(args, url_info, 'accountID', safe.ACCESS_USER_INFO)
    
    --safe.sign_check(args, url_info)

    --> check username 
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
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

    local sql = string.format(sql_fmt.get_user_info, args['accountID'])
    only.log('D',sql)
    local ok, result = mysql_pool_api.cmd('app_cli___cli', 'select', sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result==0 then
        gosay.go_success(url_info, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end

    local ok, ret_req = utils.json_encode(result[1])

    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_req)
end

safe.main_call( handle )
