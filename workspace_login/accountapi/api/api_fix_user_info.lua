-->owner:chengjian
-->time :2014-03-31
-->修改用户信息
-->2015-08-14 zhouzhe 修改

local utils         = require('utils')
local app_utils     = require('app_utils')
local only          = require('only')
local ngx           = require('ngx')
local gosay         = require('gosay')
local msg           = require('msg')
local safe          = require('safe')
local http_api      = require('http_short_api')
local redis_api     = require('redis_pool_api')
local mysql_api     = require('mysql_pool_api')

---- add by jiang z.s. 2014-09-09 set nickname
local account_utils  = require('account_utils')

local usercenter_dbname = 'app_usercenter___usercenter'

local sql_fmt = {
    sql_check_accountid = "SELECT 1 FROM userLoginInfo WHERE userStatus=1 AND accountID='%s' ",

    update_login_info = "UPDATE userLoginInfo SET %s updateTime=%d WHERE accountID='%s' ",

    update_general_info = "UPDATE userGeneralInfo SET %s updateTime=%d WHERE accountID='%s'",

    select_userInfo_idNumber = " SELECT idNumber FROM userGeneralInfo WHERE idNumber = '%s' "
}

local map_server = {host = "apis.mapabc.com", port = 80}
local http_fmt = "GET /geocode/simple?resType=json&encode=utf-8&range=300&roadnum=3&crossnum=2&poinum=2&retvalue=0&key=ebfae93ca717a7dc45f6f4962c6465993808dbdadd8b280f412c4e22db13145e647323bd421ac59c&sid=7000&address='%s' HTTP/1.0\r\nHost: apis.mapabc.com:80\r\n\r\n"

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local cur_time = os.time()
local db_login_value ="name, nickname, gender"
local db_general_value ="drivingLicense,plateNumber,bloodType,birthday,SOSContactMobile,homeAddress,idNumber,operatingLicenseNumber"

-- local db_field_val = 'name,nickname,bloodType,accountID,identifyQuestion,identifyAnswer,userEmail,birthday,'..
--     'drivingHabit,drivingLicense,DrivingLicenseIssueDate,plateNumber,engineNumber,VIN,drivingLicenseAddress,'..
--     'insuranceCompany,vehicleCommercialInsurance,trafficCompulsoryInsurance,insurancePeriod,driverEmergencyContact,'..
--     'driverContactRelation,viceDriverEmergencyContact,viceDriverContactRelation,allergicDrug,medicalHistory,'..
--     'medicalFamilyHistory,medicalInsuranceNumber,lifeInsuranceContact,sinaWeiboAccount,QQWeiboAccount,carBrand,'..
--     'othersCarBrand,carSeries,carModel,carColor,purchaseCar4SName,commonUse4SName,tyreBrand,tyreModel,nextCar,'..
--     'dreamCar,constellation,operatingLicenseNumber,driverCertificationNumber,driverUsePeriod,viceDriverName,'..
--     'viceDriverLicense,viceDriverCertificationNumber,viceDriverUsePeriod,homeAddress,idNumber,yearOfPurchase'
-- local db_field_val_int = 'viceDriverEmergencyMobile,driverEmergencyMobile,carNumber,SOSContactMobile,'..
--     'limitPassenger,viceDriverMobile,status,guardianMobile'
-- local db_field_val_bool = 'gender,acceptAdvertising,shareAddress,acceptInsuranceSponsor,acceptBankSponsor,'..
--     'bindSinaWeibo,bindQQWeibo,joinMarriageTeam,synchronizeWeibo,downloadFile,publishTrack,contactSOSPerson,'..
--     'checkQuestion,viceDriverGender'

-- local bool_str = '0, 1'

-->> 参数检查
local function check_parameter(args)
    for key, value in pairs(args) do
        local parameter = tostring(value or '')
        local str_res = string.find(parameter, "'")
        local str_tmp = string.find(parameter, "%%")
        if str_res or str_tmp then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], key )
        end
    end

    if not app_utils.check_accountID( args['accountID'])  then
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
    end
    if not args['appKey'] or not utils.is_number(args['appKey']) then
        only.log("E","appKey is error!")
        gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
    end

    --> check accountID
    if not utils.is_word(args['accountID']) and string.len(args['accountID']) ~= 10 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    safe.sign_check(args, url_info, 'accountID', safe.ACCESS_USER_INFO)
    url_info['app_key'] = args['appKey']
    args['appKey'] = nil
    args['sign'] = nil
    args['accessToken'] = nil

    for k,v in pairs(args) do
        if string.find(db_login_value, k ) then
            if not v then
                only.log("E", string.format( "==111=value is error ===%s", k))
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], k)
            end
        elseif string.find(db_general_value, k ) then
            if not v then
                only.log("E", string.format( "==222=value is error ===%s", k))
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], k)
            end
        else
            if tostring(k)~='accountID' then
                only.log("E", string.format( "==333=key is not exist ===%s", k))
                gosay.go_false(url_info, msg['MSG_ERROR_FIELD_NOT_EXIST'])
            end
        end
    end
end

local function get_home_lon_lat(args)
    do
        return nil, nil
    end

    local encode_home = utils.url_encode(args['homeAddress'])
    local data = string.format(http_fmt, encode_home)
    local ret = http_api.http(map_server, data, #data)

    if not ret then
        only.log('E',string.format("http api failed==data=%s",data))
        gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
    end

    local lon = string.match(ret, '"x":"([%d%.]-)"')
    local lat = string.match(ret, '"y":"([%d%.]-)"')

    return lon, lat
end

local function get_city_code(lon, lat)

    if not lon or not lat then
        return nil
    end

    local city_code, json_tab
    local grid_no = string.format('%d&%d', math.floor(lon * 100), math.floor(lat * 100))

    only.log('D', grid_no)
    local ok, ret = redis_api.cmd('mapGridOnePercent', 'get', grid_no)
    if ok then
        ok, json_tab = utils.json_decode(ret)
    end
    if ok then
        return json_tab['cityCode']
    end
    return nil
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    if not body then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)

    if not args then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_BAD_JSON'])
    end

    -->> 参数检查
    check_parameter(args)

    for k,v in pairs(args) do
        if #v <1 then
            args[k] = nil
        end
    end

    -->> 检查accountID是否存在
    local res_sql = string.format(sql_fmt.sql_check_accountid, args['accountID'])
    local ok, result  = mysql_api.cmd(usercenter_dbname, 'select', res_sql)
    if not ok or not result then
        only.log('E',res_sql)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result <1 then
        only.log('E',"%s: not find in mysql",args['accountID'])
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    end

    -->> redis修改nickname
    local ok, res, old_nick_name
    if args['nickname'] and args['nickname'] ~= "" then
        ok, old_nick_name = redis_api.cmd('private', 'get', args['accountID'] .. ':nickname')
        -- modify by jiang z.s. 2014-09-09
        ok,res = account_utils.set_nickname(args['accountID'], args['nickname'])
        if not ok then
            only.log("E", string.format("redis save failed! nickname==%s", args['nickname']))
            gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
        end
    end

    -- -->> 修改邮箱
    -- if args['userEmail'] and string.find(args["userEmail"], '@')) then
    --     local sql = string.format(sql_fmt.update_email_check, args['userEmail'])
    --     only.log('D',string.format("update user email", sql))
    --     local ok = mysql_api.cmd(usercenter_dbname, 'update', sql)
    --     if not ok then
    --         only.log("E", "mysql update failed %s", sql)
    --         gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    --     end
    -- end

    -- 修改归属地
    local home_city_code=''
    if args['homeAddress'] then
        if args['homeAddress'] == '' then
            ok, home_city_code = redis_api.cmd('private', 'get', args['accountID'] .. ':homeCityCode')
            redis_api.cmd('private', 'del', args['accountID'] .. ':homeCityCode')
        else
            ok, home_city_code = redis_api.cmd('private', 'get', args['accountID'] .. ':homeCityCode')
            local lon, lat = get_home_lon_lat(args)
            if lon and lat then
                local city_code = get_city_code(lon, lat)
                if city_code then
                    redis_api.cmd('private', 'set', args['accountID'] .. ':homeCityCode', city_code)
                end

                args['homeLongitude'] = lon * 10000000
                args['homeLatitude'] = lat * 10000000
            end
        end
    end
    local account_id = args['accountID']
    args['accountID'] = nil

    -->> 2015-06-01 zhouzhe 增加一个用户身份证最多绑定5个账号
    if args['idNumber'] and #args['idNumber'] > 0 then 
        sql_id = string.format(sql_fmt.select_userInfo_idNumber, args['idNumber'])
        local ok, res_id = mysql_api.cmd(usercenter_dbname, 'select', sql_id )
        if not ( ok or res_id ) then
            only.log('E',string.format("mysql is error ==== %s", sql_id))
            gosay.go_false( url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        -->> 一个用户身份证最多绑定5个账号
        if #res_id > 4 then 
            only.log('E', "idNumber reaches the upper limit!%s", args['idNumber'])
            gosay.go_false( url_info, msg['MSG_ERROR_IDNUMBER__UPPER_LIMIT'])
        end
    end

    local str1, str2 ='', ''
    for k,v in pairs(args) do
        local tmp = ''
        if string.find(db_login_value, tostring(k) ) then
            -- only.log("D", "222222=k==%s===v=%s",k,v)
            tmp=string.format("%s='%s',", k, v)
            str1=str1..tmp
        else
            -- only.log("D", "11111111=k==%s===v=%s",k,v)
            tmp=string.format("%s='%s',", k, v)
            str2=str2..tmp
        end
    end
    -- only.log("D", "==str1===%s===%d", str1, #str1)
    -- only.log("D", "==str2===%s===%d", str2, #str2)
    local sql1, sql2, sql_tab='', '' ,{}
    if #str1>0 then
        sql1 = string.format(sql_fmt.update_login_info, str1, cur_time, account_id )
        table.insert(sql_tab, sql1 )
    end

    if #str2>0 then
        sql2 = string.format(sql_fmt.update_general_info, str2, cur_time, account_id )
        table.insert(sql_tab, sql2 )
    end
    only.log('D',string.format("update login info===%s", sql1))
    only.log('D',string.format("update general info===%s", sql2))

    local ok = mysql_api.cmd(usercenter_dbname, 'affairs', sql_tab)

    -- 如果更新失败，将之前修改的值恢复
    if not ok then
        if args['nickname'] then
            -- modify by jiang z.s. 2014-09-09
            ok,res = account_utils.set_nickname(account_id, old_nick_name)
        end
        -- if args['homeAddress'] then
        --     redis_api.cmd('private', 'set', account_id .. ':homeCityCode', home_city_code)
        -- end
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    gosay.go_success(url_info, msg['MSG_SUCCESS'])
end

safe.main_call( handle )