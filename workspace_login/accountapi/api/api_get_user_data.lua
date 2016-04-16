-->> zhouzhe
-->> 2014-03-31
-->> 获得用户昵称api
-->> 2015-08-14 zhouzhe 修改

local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local ngx = require('ngx')
local gosay = require('gosay')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {
    get_user_info = " SELECT %s FROM userLoginInfo AS a, userGeneralInfo AS b WHERE "..
            " a.userStatus=1 AND b.userStatus=1 AND a.accountID='%s' AND b.accountID='%s' "

}

local usercenter_dbname = 'app_usercenter___usercenter'

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}
 
local db_value ="mobile,userEmail,name,nickname,gender,drivingLicense,plateNumber,bloodType,birthday,SOSContactMobile,"..
                "homeAddress,idNumber,operatingLicenseNumber"


--  local table_info = {
--         'name' ,
--         'nickname' ,
--         'birthday' ,
--         'gender' ,
--         'mobile'  ,
--         'bloodType' ,
--         'userEmail' ,
--         'drivingHabit' ,
--         'drivingLicense' ,
--         'drivingLicenseIssueDate' ,
--         'plateNumber' ,
--         'VIN',
--         'drivingLicenseAddress' ,
--         'insuranceCompany' ,
--         'vehicleCommercialInsurance',
--         'trafficCompulsoryInsurance' ,
--         'insurancePeriod',
--         'driverEmergencyContact',
--         'driverContactRelation' ,
--         'driverEmergencyMobile',
--         'purchaseCar4SName' ,
--         'commonUse4SName' ,
--         'tyreBrand' ,
--         'tyreModel' ,
--         'SOSContactMobile' ,
--         'constellation' ,
--         'limitPassenger' ,
--         'operatingLicenseNumber' ,
--         'driverCertificationNumber' ,
--         'checkMobileTime' ,
--         'checkUserEmailTime' ,
--         'idNumber' ,
--         'guardianMobile', 
-- }


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

    -->> check parameter
    check_parameter(args)
   
    only.log('D',string.format("input data====%s",args['field']))

    local ok, result

    if not args['field'] or #args['field'] < 1 then
        -->> 获取用户信息
        local sql1 = string.format(sql_fmt.get_user_info, db_value , args['accountID'], args['accountID'] )
        only.log("D", string.format("=111=get login info==%s==", sql1))
        ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql1)
        if not ok or not result then
            only.log("E", "get login info is failed")
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end
        if #result == 0 then
            only.log("E", "=111=return error===")
            gosay.go_success(url_info, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
        end
    else
        local str_table = utils.str_split(args['field'], ',')
        --判断输入用户信息名称是否正确
        for k, v in pairs(str_table) do
            if not string.find(db_value, v ) then
                only.log("E", string.format( "==222=value is error ===%s", v ))
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], v )
            end
        end

        local str = table.concat(str_table,',')
 
        local sql2 = string.format(sql_fmt.get_user_info, str , args['accountID'], args['accountID'])
        only.log('D',string.format("==2222==get user info===%s", sql2 ))
        ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql2 )
        
        if not ok then
            only.log('E', "get user info failed,  %s" )
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end

        if #result == 0 then
            only.log("E", "=222=return error===")
            gosay.go_success(url_info, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
        end
    end

    local ok, ret_req = utils.json_encode(result[1])
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_req)
end

safe.main_call( handle )
