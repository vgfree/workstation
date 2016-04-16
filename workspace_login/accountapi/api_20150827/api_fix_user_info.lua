-->owner:chengjian
-->time :2014-03-31
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path

local utils          = require('utils')
local app_utils     = require('app_utils')
local only           = require('only')
local ngx            = require('ngx')
local gosay          = require('gosay')
local msg            = require('msg')
local safe           = require('safe')
local http_api       = require('http_short_api')
local redis_api      = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')

---- add by jiang z.s. 2014-09-09 set nickname
local account_utils  = require('account_utils')

local sql_fmt = {
    -- 2015-06-10 取消修改手机号功能 zhouzhe
    -- update_mobile_check = "UPDATE userRegisterInfo SET checkMobile = 0 WHERE mobile=%s",
    update_email_check = "UPDATE userRegisterInfo SET checkUserEmail = 0 WHERE userEmail='%s'",

    get_userInfo = "SELECT * FROM userInfo WHERE accountID='%s' AND status=1",

    update_userInfo = "UPDATE userInfo SET %s updateTime=%d WHERE accountID='%s'", 
    save_to_userInfoHistory = "INSERT INTO userInfoHistory SET %s updateTime=%s, accountID='%s'",
    -- 2015-06-01 zhouzhe idNumber 
    select_userInfo_idNumber = " SELECT idNumber FROM userInfo WHERE idNumber = '%s' "
}

local map_server = {host = "apis.mapabc.com", port = 80}
local http_fmt = "GET /geocode/simple?resType=json&encode=utf-8&range=300&roadnum=3&crossnum=2&poinum=2&retvalue=0&key=ebfae93ca717a7dc45f6f4962c6465993808dbdadd8b280f412c4e22db13145e647323bd421ac59c&sid=7000&address='%s' HTTP/1.0\r\nHost: apis.mapabc.com:80\r\n\r\n"

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local db_field_val = 'name,nickname,bloodType,accountID,identifyQuestion,identifyAnswer,userEmail,birthday,'..
    'drivingHabit,drivingLicense,DrivingLicenseIssueDate,plateNumber,engineNumber,VIN,drivingLicenseAddress,'..
    'insuranceCompany,vehicleCommercialInsurance,trafficCompulsoryInsurance,insurancePeriod,driverEmergencyContact,'..
    'driverContactRelation,viceDriverEmergencyContact,viceDriverContactRelation,allergicDrug,medicalHistory,'..
    'medicalFamilyHistory,medicalInsuranceNumber,lifeInsuranceContact,sinaWeiboAccount,QQWeiboAccount,carBrand,'..
    'othersCarBrand,carSeries,carModel,carColor,purchaseCar4SName,commonUse4SName,tyreBrand,tyreModel,nextCar,'..
    'dreamCar,constellation,operatingLicenseNumber,driverCertificationNumber,driverUsePeriod,viceDriverName,'..
    'viceDriverLicense,viceDriverCertificationNumber,viceDriverUsePeriod,homeAddress,idNumber,yearOfPurchase'
local db_field_val_int = 'viceDriverEmergencyMobile,driverEmergencyMobile,carNumber,SOSContactMobile,'..
    'limitPassenger,viceDriverMobile,status,guardianMobile'
local db_field_val_bool = 'gender,acceptAdvertising,shareAddress,acceptInsuranceSponsor,acceptBankSponsor,'..
    'bindSinaWeibo,bindQQWeibo,joinMarriageTeam,synchronizeWeibo,downloadFile,publishTrack,contactSOSPerson,'..
    'checkQuestion,viceDriverGender'

local bool_str = '0,1'
--"check_status" part is updated in 2014.11.04.
--添加这一处的判断的原因是：避免用户多次请求而造成多次修改。添加这一判断后如果用户请求过以后再来请求就不会执行下面的程序，直接返回
-- local function check_fix_status(accountID)
--     --check fixstatus
--     local ok,ret = redis_pool_api.cmd('private','get',accountID .. 'fixUserInfo')
--     if not ok then
--         gosay.go_false(url_info, msg['SYSTEM_ERROR'])
--     end

--     if ret then                                        --Have already fixed                        
--             gosay.go_false(url_info, msg['MSG_ERROR_REQ_CODE'],"Has been set successfully")
--     end
--     --add fixstatus
--     redis_pool_api.cmd('private','set',accountID .. 'fixUserInfo',"1")
--     --make fixstatus validity is 3 second
--     redis_pool_api.cmd('private','expire',accountID .. 'fixUserInfo',3)
-- end

-- 2015-07-27 zhouzhe 参数中不能出现%号（代码错误）和'号（数据库错误)
local function check_character( parameter )
    local str_res = string.find(parameter,"'")
    local str_tmp = string.find(parameter,"%%")
    if str_res or str_tmp then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "parameter")
    end
end

-- check parameter
local function check_parameter(args)
    --  2015-07-27 zhouzhe 
    local str_parameter = ""
    for _,v in pairs(args) do
        if not v then
            v = ""
        end
        local str = tostring(v)
        str_parameter = str_parameter..str
    end
    check_character(str_parameter)

    if not app_utils.check_accountID( args['accountID'])  then
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
    end
    if (not args['appKey']) or (#args['appKey'] > 10) or not utils.is_number(args['appKey'])  then
        only.log("E","appKey is error!")
        gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
    end

    url_info['app_key'] = args['appKey']

    safe.sign_check(args, url_info, 'accountID', safe.ACCESS_USER_INFO)
    -- safe.sign_check(args, url_info)

    args['appKey'] = nil
    args['sign'] = nil
    args['accessToken'] = nil

    --> check accountID
    if not utils.is_word(args['accountID']) and string.len(args['accountID']) ~= 10 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    for k, v in pairs(args) do

        if string.find(db_field_val_int, k) then
            if tonumber(v) == nil then
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], k)
            end
        elseif string.find(db_field_val_bool, k) then
            if not string.find(bool_str, v) then
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], k)
            end
        elseif string.find(db_field_val, k) then
            if k == 'accountID' and not app_utils.check_accountID(v) then
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], k)
            elseif k == 'yearOfPurchase' and not string.match(db_field_val,'yearOfPurchase') then
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], k)
            end
        else
            gosay.go_false(url_info, msg['MSG_ERROR_FIELD_NOT_EXIST'])
        end
    end
    -- nickname, userEmail,  and so on
end

local function get_home_lon_lat(args)

    do
        return nil, nil
    end

    local encode_home = utils.url_encode(args['homeAddress'])
    local data = string.format(http_fmt, encode_home)
    local ret = http_api.http(map_server, data, #data)
    -- 2015-07-27 zhouzhe
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
    local ok, ret = redis_pool_api.cmd('mapGridOnePercent', 'get', grid_no)
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

    if not args['appKey']  then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_FAILED_GET_SECRET'])
    end

    if not args['accountID']  then
        gosay.go_false(url_info, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end 

    --> 检查是否重复设置
    -- check_fix_status(args['accountID'])

    --> check parameter
    check_parameter(args)

    --> 修改nickname
    local ok, res, old_nick_name
    if args['nickname'] and args['nickname'] ~= "" then
        ok, old_nick_name = redis_api.cmd('private', 'get', args['accountID'] .. ':nickname')
        -- ok, res = redis_api.cmd('private', 'set', args['accountID'] .. ':nickname', args['nickname'])
        -- modify by jiang z.s. 2014-09-09
        ok,res = account_utils.set_nickname(args['accountID'], args['nickname'])
        if not ok then
            -- 2015-07-27 zhouzhe
            only.log("E", string.format("redis save failed! nickname====%s", args['nickname']))
            gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
        end
    end

    -- 修改归属地
    local home_city_code
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

    -- 修改手机或邮箱 2015-06-08取消修改手机号功能 zhouzhe
    -- if args['mobile'] or args['userEmail'] then
    if args['userEmail'] then
        -- local sql
        -- if args['mobile'] then
        --     sql = string.format(sql_fmt.update_mobile_check, args['mobile'])
        --     only.log('D',sql)
        --     mysql_pool_api.cmd('app_usercenter___usercenter', 'update', sql)
        -- end

        -- if args['userEmail'] then
        local sql = string.format(sql_fmt.update_email_check, args['userEmail'])
        -- only.log('D',sql)
        local ok = mysql_pool_api.cmd('app_usercenter___usercenter', 'update', sql)
        if not ok then
            only.log("E", "mysql update failed %s", sql)
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end
        -- end  
    end

    -- get info from userInfo
    local res_sql = string.format(sql_fmt.get_userInfo, args['accountID'])
    local ok, result = mysql_pool_api.cmd("app_cli___cli", 'select', res_sql)
    if not ( ok or result )then
        only.log('E',res_sql)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    ---fix hyq 2015-05-15 
    if #result ==0 then
        only.log('D',"%s: not find in mysql",args['accountID'])
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    end

    -- because the accountID should be in table
    local account_id = args['accountID']
    args['accountID'] = nil

    local str1 = ''
    local str2 = ''

    local info = result[1]

    if not next(args) then
        gosay.go_success(url_info, msg['MSG_SUCCESS'])
    end

    -- 2015-06-01 zhouzhe 增加一个用户身份证最多绑定10个账号
    if args['idNumber'] and args['idNumber'] ~= "" then 
        sql_id = string.format(sql_fmt.select_userInfo_idNumber, args['idNumber'])
        local ok, res_id = mysql_pool_api.cmd('app_cli___cli', 'select', sql_id )
        if not ( ok or res_id ) then
            only.log('E',string.format("mysql is error ==== %s", sql_id))
            gosay.go_false( url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        -- 一个用户身份证最多绑定10个账号
        if #res_id > 4 then 
            only.log('E', "idNumber reaches the upper limit!%s", info['idNumber'])
            gosay.go_false( url_info, msg['MSG_ERROR_IDNUMBER__UPPER_LIMIT'])
        end
    end

    for k, v in pairs (args) do
        str1 = str1 .. string.format("%s='%s',", k, v)
        str2 = str2 .. string.format("%s='%s',", k, info[k])
    end

    local cur_time = os.time()

    local sql = {
        [1] = string.format(sql_fmt.update_userInfo, str1, cur_time, account_id),
        [2] = string.format(sql_fmt.save_to_userInfoHistory, str2, result[1]['updateTime'], account_id),
    }

    only.log('D',sql[1])
    only.log('D',sql[2])

    local ok, result = mysql_pool_api.cmd("app_cli___cli", 'affairs', sql)

    -- 如果更新失败，将之前修改的值恢复
    if not ok then
        if args['nickname'] then
            -- ok, res = redis_api.cmd('private', 'set', account_id .. ':nickname', old_nick_name)

            -- modify by jiang z.s. 2014-09-09
            ok,res = account_utils.set_nickname(account_id, old_nick_name)
        end
        if args['homeAddress'] then
            redis_api.cmd('private', 'set', account_id .. ':homeCityCode', home_city_code)
        end
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    gosay.go_success(url_info, msg['MSG_SUCCESS'])
end

safe.main_call( handle )
