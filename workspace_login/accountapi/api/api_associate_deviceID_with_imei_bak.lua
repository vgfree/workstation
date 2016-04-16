---- dev 
---- 2015-04-08 
---- 道客账户与第三方系统合并

local msg       = require('msg')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local mysql_api = require('mysql_pool_api')

local G = {
    sql_car_machine = "SELECT imei FROM carMachineInfo WHERE validity = 1 and deviceID = '%s' AND model = '%s'  ",
    
    ---- 校验Model
    sql_check_model = " SELECT businessID,isThirdModel, endTime FROM modelInfo WHERE validity = 1 and isThirdModel = 0 and model = '%s' limit 1 ",
    
    ---- 获取business信息
    sql_business_info = " SELECT returnType,bonusType, allowExchange,shareInfo, userBonusMax,businessBonusMax, bonusReturnTarget, " ..
                            " bonusReturnMonth FROM businessInfo WHERE validity = 1 and  businessID = %s  ",

    ---- 获取一个新的IMEI 
    sql_get_mirrtalk = "SELECT imei,nCheck FROM mirrtalkInfo WHERE validity = 1 and model = '%s' AND status = '%s' and endTime > '%s' limit 1",

    sql_mirrtalk_history = " INSERT INTO mirrtalkHistory SET imei = '%s', movement = '%s', originalStatus = '%s', endStatus = '%s', updateTime= '%s', remarks = '%s'  ",

    sql_mirrtalk_update = " UPDATE mirrtalkInfo  SET status= '%s' , updateTime = '%s' WHERE  imei = '%s' and status = '%s'  ",

    sql_insert_car_machine = " INSERT INTO carMachineInfo SET appKey = '%s', deviceID = '%s', model = '%s', imei = '%s', createTime = '%s' , validity =  1 ",

    sql_mirrtalk_deposit_info = " SELECT depositType FROM mirrtalkDepositInfo WHERE validity = 1 and  imei = '%s'   ", 

    sql_deposit_type = " SELECT depositAmount FROM depositTypeInfo WHERE validity = 1 and depositType = '%s' ", 
    
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local ident_dbname = "app_ident___ident"
local crowd_dbname = "app_crowd___crowd"

local function check_parameter(body)

    local res = utils.parse_url(body)
    if not res or type(res) ~= "table" then
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    -->> check appKey
    if not res['appKey'] or (#res['appKey'] > 10) then 
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_FAILED_GET_SECRET"])
    end

    url_info['app_key'] = res['appKey']

    -->> check deviceID
    if (not utils.is_word(res["deviceID"])) or (#res["deviceID"] > 64) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "deviceID")
    end

    -->> check model
    if( not utils.is_word(res["model"])) or (#res["model"] ~= 5 ) then
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "model" )
    end

    -->> check sign
    safe.sign_check(res, url_info)

    return res
end


function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body
    local sql,ret,imei

    -->> check parameters
    local args = check_parameter(body)

    local appKey     = args["appKey"]
    local device_id  = args["deviceID"]
    local model      = args["model"]
	
    local time = os.time()
    local status = '10a'
    local endStatus = '10r'
    local movement = 38

    local cur_time = os.time()

    -->> check model whether register in mirrtalk company 
    local sql = string.format( G.sql_check_model, model )
    local ok,res = mysql_api.cmd( ident_dbname ,'SELECT',sql)
    if not ok or not res then
        only.log('E',"sql check model failed, %s ", sql)
        gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res == 0 then
        gosay.go_false(url_info,msg["MSG_ERROR_DEVICE_MODEL_INVALID"] )
    end

    if tonumber(res[1]['endTime']) >= cur_time then
        gosay.go_false(url_info,msg["MSG_ERROR_DEVICE_MODEL_EXPIRE"] )
    end
  

    local businessID = res[1]['businessID']
    local isThirdModel = res[1]['isThirdModel']
    
    if ( tonumber(businessID) <= 0 ) then
        only.log('E',"check businessID failed %s", businessID)
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end

    -->> select returnType,bonusType,allowExchange,shareInfo,userBonusMax,businessBonusMax,bonusReturnTarget,bonusReturnMonth FROM businessInfo

    sql = string.format( G.sql_business_info, businessID )
    local ok,res = mysql_api.cmd(crowd_dbname, 'SELECT', sql )
    if not ok or not res then
        only.log('E',"sql get business info failed  %s ", sql)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res ~= 1 then
        only.log('E',"sql get business info result is empty  %s ", sql)
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end 
	
    local returnType = res[1]['returnType']
    local bonusType = res[1]['bonusType']
    local allowExchange = res[1]['allowExchange']
    local userBonusMax = res[1]['userBonusMax']
    local shareInfo = res[1]['shareInfo']
    local businessBonusMax = res[1]['businessBonusMax']
    local bonusReturnTarget = res[1]['bonusReturnTarget']
    local bonusReturnMonth = res[1]['bonusReturnMonth']
    
    -->> check car_device whether exist
    sql = string.format( G.sql_car_machine,  device_id ,  model )
    local ok, res = mysql_api.cmd( ident_dbname , 'SELECT', sql)
    if not ok or not res then
        only.log('W', " get car cachine exit failed!  %s "  , sql )
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res > 1 then
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end

    if #res == 1 then 
        if res[1]['imei'] == 0 then
            ---- 可能已经解帮,可能已经解帮,后期考虑
            gosay.go_false(url_info,msg["SYSTEM_ERROR"])
        end

        if res[1]['imei'] ~= 0  then
            ---- 已经绑定IMEI
            gosay.go_false(url_info, msg["MSG_ERROR_DEVICE_ID_HAS_BIND"])
        end
    end
    -->> select one imei from coreIdentification.mirrtalkInfo
    sql = string.format( G.sql_get_mirrtalk, model, status, cur_time )
    local ok, res = mysql_api.cmd(  ident_dbname , 'SELECT', sql)
    if not ok or not res then
        only.log('E',"sql get mirrtalk failed %s ", sql)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    
    if #res == 0 then
        only.log('E',"sql get mirrtalk empty ****** need more imei list  %s ", sql )
        gosay.go_false(url_info, msg["MSG_ERROR_DEVICE_MODEL_IMEI_EXHAUST"])
    end

    local imei = string.format("%s%s",res[1]['imei'],res[1]['nCheck'])
    local imei_14 = res[1]['imei']

    local remarks = string.format("车机绑定imei号码 %s", args['appKey'])

    -->> insert mirrtalkHistory,update mirrtalk and insert carMachineInfo ,and
    --all of this three database action is a affairs
    local sql_tab = {}
    sql = string.format(G.sql_mirrtalk_history, imei, movement, status, endStatus, cur_time, remarks)
    table.insert(sql_tab, sql)
    sql = string.format(G.sql_mirrtalk_update, endStatus,cur_time, imei_14, status )
    table.insert(sql_tab, sql)
    sql = string.format(G.sql_insert_car_machine, appKey, device_id, model, imei, cur_time)
    table.insert(sql_tab, sql)
    local ok, res = mysql_api.cmd(  ident_dbname , 'affairs', sql_tab)
    if not ok then
        only.log('E',"update mirrtalk info failed  %s", table.concat( sql_tab, " \r\n" ))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
-->对于没有发货的机器depositType=0,而depositTypeInfo表中是没有depositType=0对应的信息的
[[--
    -->> select depositType from mirrtalkDepositInfo 
    sql = string.format( G.sql_mirrtalk_deposit_info, imei )  
    local ok,res = mysql_api.cmd(crowd_dbname,'SELECT', sql )
    if not ok  or not res then
        only.log('E', "sql check mirrtalk deposit info ", sql)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res ~= 1 then
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end
    
    local depositType = res[1]['depositType']
    --> select depositAmount from depositTypeInfo  
    sql = string.format( G.sql_deposit_type, depositType )
    local ok,res = mysql_api.cmd(crowd_dbname,'SELECT', sql )
    if not ok or not res then
        only.log('E',"sql get deposit type failed , %s  ", sql )
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res ~= 1 then
        only.log('E',"sql get deposit type succ ,but result empty %s  ", sql )
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end
--]] 

    local data = {
        imei  = imei , 
        businessID = businessID,
        depositType = 2,	--目前对于第三方接入的机器，我们默认为买断机
        depositAmount  = 0,
        returnType = returnType,
        bonusType  = bonusType,
        allowExchange = allowExchange,
        shareInfo  = shareInfo,
        userBonusMax = userBonusMax,
        businessBonusMax = businessBonusMax,
        bonusReturnTarget = bonusReturnTarget,
        bonusReturnMonth = bonusReturnMonth,
    }

    local ok,ret = utils.json_encode(data)
    if ok then
        gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
    else
        gosay.go_success(url_info, msg["SYSTEM_ERROR"])
    end

end

safe.main_call( handle )
