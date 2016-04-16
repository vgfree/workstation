-->[time]: 2015-04-14
--> 车机设备ID,获取IMEI

local msg   = require('msg')
local msg   = require('msg')
local safe  = require('safe')
local only  = require('only')
local gosay = require('gosay')
local utils = require('utils')
local cjson     = require('cjson')
local link      = require('link')
local app_utils = require('app_utils')
local http_api  = require('http_short_api')
local mysql_api = require('mysql_pool_api')

local ident_dbname = "app_ident___ident"
local reward_dbname = "app_crowd___crowd"
local payUserDeposit_server = link["OWN_DIED"]["http"]["payUserDeposit"]

local G = {
    
    check_model = " SELECT 1 FROM modelInfo WHERE validity = 1 and model = '%s' and endTime > %s ",

    get_model_appKey = "SELECT businessID,isThirdModel FROM userModelInfo WHERE validity = 1 and model = '%s' and appKey = '%s' ",

    sl_business_info = " SELECT returnType,appKey,bonusType,allowExchange,shareInfo,userBonusMax, " ..
                            " businessBonusMax,bonusReturnTarget,bonusReturnMonth FROM businessInfo WHERE businessID = %s AND parentID = 0",

    check_car_machine_exist = "SELECT imei FROM carMachineInfo WHERE validity = 1 AND deviceID = '%s' AND model = '%s' ",

    get_mirrtalk_imei = " SELECT concat(imei,nCheck) as IMEI FROM mirrtalkInfo WHERE isOccupy = 0 and model = '%s' " ..
                    " AND status = '%s' and endTime > %s and validity = 1 limit 1",

    ins_mirrtalk_history = " INSERT INTO mirrtalkHistory SET imei = %s, movement = '%s', " .. 
                                " originalStatus = '%s', endStatus = '%s', updateTime= %s, remarks = '%s' ",

    upd_mirrtalk = " UPDATE mirrtalkInfo  SET status= '%s' ,updateTime = %s ,isOccupy = 1  " ..
                        " WHERE isOccupy = 0 and concat(imei,nCheck) in(%s) ",

    set_car_machine = " INSERT INTO carMachineInfo SET appKey = '%s', deviceID = '%s', "  .. 
                         " model = '%s', imei = %s, createTime = %s ",
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(body)

    local res = utils.parse_url(body)
    if not res or type(res) ~= "table" then
    gosay.go_false(url_info,msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    -->> check appKey
    if not res['appKey'] or not utils.is_number(res['appKey']) or  #res['appKey'] < 7  then 
        only.log('D',res['appKey'])
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_FAILED_GET_SECRET"])
    end
    url_info['app_key'] = res['appKey']

    -->> check deviceID
    if not utils.is_word(res["deviceID"]) or #res["deviceID"] > 64 or string.find(res['deviceID'], "'") then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "deviceID")
    end
    -->> check model
    if not utils.is_word(res["model"]) or #res["model"] ~= 5 or string.find(res['model'], "'") then
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "model" )
    end

    -->> check sign
    safe.sign_check(res, url_info)

    return res
end

function really_payUserDeposit(depositType,imei,depositAmount,appKey)

    local  tab = {
        appKey = appKey,
        IMEI   =  imei,
        depositType = depositType,
        depositAmount = depositAmount,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)
    only.log('D',string.format("appKey=%s", appKey ))
    local post_data = 'POST /rewardapi/v2/payUserDeposit HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    if not payUserDeposit_server then
        only.log('E',"payUserDeposit_server is %s!" , payUserDeposit_server)
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], 'payUserDeposit_server')
    end

    local data_t = string.format(post_data, payUserDeposit_server['host'], payUserDeposit_server['port'], #body, body)
    
    local ret = http_api.http(payUserDeposit_server, data_t, true)
    only.log('D',string.format("depositType=%s", depositType ))
    if not ret then 
        only.log('E',"payUserDeposit failed!")
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "depositType")
    end
    local ret_val = string.match(ret,'{.+}') 
    only.log('D',string.format("ret_val=%s", ret_val ))   
    if ret_val then 

        local ok, tab = pcall(cjson.decode,ret_val) 
        if ok and tab then  
            if tab['ERRORCODE'] == "0" then 
                return true 
            end 
        end 
    end 
    only.log('E',string.format(" imei payUserDeposit failed,  %s appKey:%s ", imei , appKey  ) ) 
    gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "depositType")

end 

local function check_model_is_validity(model, cur_time, data_appKey)

    local sql = string.format( G.check_model, model, cur_time )
    local ok,res = mysql_api.cmd( ident_dbname,'SELECT',sql)
    only.log('D' ,string.format("check_model.sql= %s", sql ))
    if not ok or not res then
        only.log('E',string.format("check model failed %s ", sql ) )
        gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end

    if type(res) ~= "table" or #res == 0 then
        only.log('E',string.format("get model not exist  %s", model ) )
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "model")
    end
    
    local sql = string.format(G.get_model_appKey, model, data_appKey )
    local ok,ret = mysql_api.cmd( reward_dbname,'SELECT',sql)
    only.log('D' ,string.format("get_model_appKey.sql= %s", sql ))
    if not ok or not ret then
        only.log('E',string.format("check model and appKey failed %s ", sql ) )
        gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end

    if type(res) ~= "table" or #ret ~= 1 then
        only.log('E',string.format("get model is error, sql = %s", sql ) )
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "model")
    end

    local isThirdModel, businessID = tonumber(ret[1]['isThirdModel']), tonumber(ret[1]['businessID'])

    only.log('D', string.format("isThirdModel= %s, businessID= %s ", isThirdModel, businessID) )
    
    -->>check model is wheher mirrtalk company internal using
    if isThirdModel == 0 then
        only.log('D', string.format(" cur model %s  is not isThirdModel ",  model ) )
         gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"],"ThirdModel") 
    end 

    if businessID == 0 then
        only.log('E', string.format(" cur model %s  is not exist businessID ",  model ) )
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end
    return businessID
end

function handle()
    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()
    
    if not body  then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_host'] = ip
    url_info['client_body'] = body
    local sql,ret,imei

    -->> check parameters
    local res = check_parameter(body)

    local cur_time = os.time()
    local data = {}
    local status = '10a'
    local endStatus = '10r'
    local movement = 38
    local device_id, model, appKey  = res["deviceID"], res["model"], res['appKey']

    -->> check model whether register in mirrtalk company 
    local businessID = check_model_is_validity(model, cur_time, appKey)

    -->> check car_device whether exist
    sql = string.format( G.check_car_machine_exist, device_id, model )
    only.log('D' ,string.format("check_car_machine_exist, sql= %s", sql ))

    local ok, res = mysql_api.cmd(ident_dbname, 'SELECT', sql)
    if not ok or not res then
        only.log('E',string.format(" get sl_car_machine failed, %s", sql ))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if type(res) ~= "table" or #res > 1 then
        only.log('E',string.format(" get mirrtalk multi rows, %s", sql ))
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end

    if #res == 1 then 
        if res[1]['imei'] and tonumber(res[1]['imei']) ~= 0 then   
            data['imei'] = res[1]['imei']
        end

    else
        -->> select one imei from coreIdentification.mirrtalkInfo
        sql = string.format( G.get_mirrtalk_imei, model, status, cur_time )
        only.log('D' ,string.format("sl_mirrtalk.sql= %s", sql ))

        local ok, res = mysql_api.cmd(ident_dbname, 'SELECT', sql)
        if not ok or not res then
            only.log('E',string.format(" get mirrtalk info failed, %s", sql ))
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end
        
        if type(res) ~= "table" or #res == 0 then
            only.log('E',string.format(" get mirrtalk info not exist, %s", sql ))
            gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
        end

        local imei = res[1]['IMEI']
        local remarks = "车机绑定imei号码"
        -->> insert mirrtalkHistory,update mirrtalk and insert carMachineInfo ,and
        --all of this three database action is a affairs
        local sql_tab = {}
        local sql = string.format(G.ins_mirrtalk_history, imei,movement, status, endStatus, cur_time, remarks)
        table.insert(sql_tab, sql)

        local sql = string.format(G.upd_mirrtalk, endStatus, cur_time, imei)
        table.insert(sql_tab, sql)

        local sql = string.format(G.set_car_machine, appKey, device_id, model, imei, cur_time)
        table.insert(sql_tab, sql)
        only.log("D", sql)

        --押金类型(depositType)为 2 表示买断机器 --押金类型默认为0类
        local depositType, depositAmount = 2, 0
        
        data["imei"]  = imei
        data["depositType"] = depositType
        data["depositAmount"] = depositAmount

        only.log('D' ,string.format("depositType= %s ,imei = %s ,depositAmount = %s ,appKey=%s ", depositType, imei, depositAmount, appKey ))
        really_payUserDeposit(depositType,imei,depositAmount,appKey)

        local ok, res = mysql_api.cmd(ident_dbname, 'AFFAIRS', sql_tab)
        if not ok or not res then
            only.log('E',string.format("[affairs] failed , %s", table.concat( sql_tab, "\r\n" ) ))
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end
    end
    
    data["model"] = model
    data["appKey"] = appKey
    data["businessID"] = businessID

    -- local ok,return_data = utils.json_encode(data)
    local ok, return_data = pcall(cjson.encode,data)
    -->> return imei
    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], return_data)

end

safe.main_call( handle )
