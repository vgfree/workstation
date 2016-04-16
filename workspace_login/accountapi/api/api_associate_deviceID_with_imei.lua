---- append info
---- jiang z.s. 
---- 2015-10-04 
---- 优化代码与添加注释

---- 车机设备device获取imei号
---- 1) 判断model
---- 2) 判断model与appkey是否匹配
---- 3) 如果车机deviceid存在imei则返回,否则获取一个新的imei

local msg   = require('msg')
local msg   = require('msg')
local safe  = require('safe')
local only  = require('only')
local gosay = require('gosay')
local utils = require('utils')
local cjson     = require('cjson')
local ngxsocket     = require('ngxsocket')
local link      = require('link')
local app_utils = require('app_utils')
local http_api  = require('http_short_api')
local mysql_api = require('mysql_pool_api')

local ident_dbname = "app_ident___ident"
local reward_dbname = "app_crowd___crowd"
local payUserDeposit_server = link["OWN_DIED"]["http"]["payUserDeposit"]

local G = {
    
    sql_check_model = " SELECT 1 FROM modelInfo WHERE validity = 1 and model = '%s' and endTime > %s ",

    sql_get_model_appKey = "SELECT businessID, isThirdModel FROM userModelInfo WHERE validity = 1 and model = '%s' and appKey = '%s' ",

    sql_check_car_machine_exist_imei = "SELECT imei FROM carMachineInfo WHERE validity = 1 AND model = '%s' AND deviceID = '%s' ",

    ---- 获取model中未使用过的imei号用于当前的设备
    sql_get_new_imei_by_mirrtalkinfo = " SELECT imei,nCheck FROM mirrtalkInfo WHERE isOccupy = 0 and validity = 1 and model = '%s' " ..
                            " AND status = '%s' and endTime > %s  limit 1",


    sql_save_mirrtalk_history = " INSERT INTO mirrtalkHistory SET imei = %s, movement = '%s', " .. 
                                    " originalStatus = '%s', endStatus = '%s', updateTime= %s, remarks = '%s' ",

    ---- 设置当前IMEI为10a,发货状态
    ---- 再然后需要调用发货api,把状态修改为13g
    sql_update_mirrtalkinfo_status = " UPDATE mirrtalkInfo SET status= '%s' ,updateTime = %s ,isOccupy = 1  " ..
                        " WHERE isOccupy = 0 and imei = %s",

    sql_save_car_machine_info = " INSERT INTO carMachineInfo SET appKey = '%s', deviceID = '%s', "  .. 
                         " model = '%s', imei = %s, createTime = %s ",

    sql_check_imei_status = " SELECT status FROM mirrtalkInfo WHERE imei =%s ",
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
    --safe.sign_check(res, url_info)

    return res
end


---- 对发货后imei状态的判断是否为13g
local function check_pay_deposit_imei_status_after(new_imei)

    local tmp_imei = string.sub( tostring(new_imei), 1, 14 )

    local sql = string.format( G.sql_check_imei_status, tmp_imei )
    only.log("D", sql )
    local ok,result = mysql_api.cmd(ident_dbname, 'SELECT', sql )
    if not ok and not result then
        only.log("E", "check imei status mysql is failed" )
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result == 0 then
        only.log("E", string.format("get imei status result length is zero==new_imei==%s=== ", new_imei))
        gosay.go_false(url_info , msg['MSG_ERROR_REQ_ARG'],"imei")
    end
    if tostring(result[1]['status']) == "13g" then
        only.log("D", string.format("==success== imei == %s === status === %s ===",new_imei, result[1]['status'] ) )
        return true
    elseif tostring(result[1]['status']) == '21p' then
        only.log("E", "this imei status is '21p' .")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "imei status(21p) ")
    else
        only.log("E", string.format("==failed == imei == %s === status === %s ===",new_imei, result[1]['status'] ) )
        return false
    end
end


local function really_payUserDeposit(imei, depositType, depositAmount,appKey)
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
        only.log('E',"*********payUserDeposit_server is %s!" , payUserDeposit_server)
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], 'payUserDeposit_server')
    end
    only.log('D',"xxx0000") 

    local data_t = string.format(post_data, payUserDeposit_server['host'], payUserDeposit_server['port'], #body, body)

    local ok,result = ngxsocket.short_http(payUserDeposit_server['host'], payUserDeposit_server['port'], 
                                                data_t, #data_t,1,2000)
     
    -- ----处理返回信息
    -- if not result then
    --     only.log("E", "result is  : %s", result)
    --     return false
    -- end

    -- only.log('D',string.format("depositType=%s", depositType ))
    if not result then
        only.log('E',"payUserDeposit failed!")
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "depositType")
    end

    local ret_val = string.match(result,'{.*}')
    only.log('D',string.format("ret_val=%s", ret_val ))

    if ret_val then
        local ok, tab = pcall(cjson.decode,ret_val)
        if ok and tab then
            if tab['ERRORCODE'] == "0" then
                -- return true
                ---- 2015-12-04 zhouzhe 对发货后imei状态的判断是否为13g
    only.log('D',"xxx1111") 
                return check_pay_deposit_imei_status_after(imei)
            end 
        end 
    end
    only.log('E',string.format("**********imei payUserDeposit failed,  %s appKey:%s ", imei , appKey  ) ) 
    gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "imei")
end 



local function check_model_is_validity(model, cur_appKey, cur_time)
    ---- 确认当前model是否合法
    local sql = string.format( G.sql_check_model, model, cur_time )
    local ok,res = mysql_api.cmd( ident_dbname,'SELECT',sql)
    if not ok or not res then
        only.log('E',string.format("check model failed %s ", sql ) )
        gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end

    if type(res) ~= "table" or #res ~= 1 then
        only.log('E',string.format("get model not exist  %s, %s ", model, sql ) )
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "model")
    end
    
    ---- 确认当前model与appkey是否匹配
    local sql = string.format(G.sql_get_model_appKey, model, cur_appKey )
    local ok,ret = mysql_api.cmd( reward_dbname,'SELECT',sql)
    if not ok or not ret then
        only.log('E',string.format("check model and appKey failed %s ", sql ) )
        gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end

    if type(ret) ~= "table" or #ret ~= 1 then
        only.log('E',string.format("check model and appKey succed , but records is empty, sql = %s", sql ) )
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "model")
    end

    local isThirdModel, businessID = tonumber(ret[1]['isThirdModel']), tonumber(ret[1]['businessID'])

    only.log('D', string.format("isThirdModel= %s, businessID= %s ", isThirdModel, businessID) )
    
    ----
    ---- 当前不是第三方的model,禁止使用 
    ---- 
    if isThirdModel == 0 then
        only.log('W', string.format(" cur model %s  is not isThirdModel ",  model ) )
        gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"],"model") 
    end 

    ---- 当前model不存在企业编号,禁止使用
    if businessID == 0 then
        only.log('E', string.format("*************cur model %s  is not exist businessID ",  model ) )
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end

    return businessID
end

---- 判断之前是否已经有imei号
local function get_device_exists_imei( device_id, model  )
    ---- 检测当前deviceid与model是否已经获取过imei号
    local sql = string.format( G.sql_check_car_machine_exist_imei, model, device_id )
    local ok, res = mysql_api.cmd(ident_dbname, 'SELECT', sql)
        only.log('D',string.format(" sql_check_car_machine_exist_imei---> %s", sql ))
    if not ok or not res then
        only.log('E',string.format(" get sl_car_machine failed, %s", sql ))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if type(res) ~= "table" or #res > 1 then
        only.log('E',string.format(" get mirrtalk multi rows, %s", sql ))
        gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end
    ---- imei状态是否为13g标志
    local imeiStatusOK = false
    if #res == 1 then
        if  res[1]['imei'] and #res[1]['imei'] == 15 then
            ---- 判断imei的状态是否为13g 2015-12-04 zhouzhe
            local ok = check_pay_deposit_imei_status_after(res[1]['imei'])
            
            if ok then
                imeiStatusOK = true
                return res[1]['imei'], imeiStatusOK
            else
                return res[1]['imei'], imeiStatusOK
            end
        end
    else
        return false, imeiStatusOK
    end
end


---- 
local function get_new_mirrtalk_imei(model, cur_appKey, cur_time , deposit_type, deposit_amount, device_id)

    ---- 获取一个未初始化过的设备号
    local init_status = "10a"
    local movement = 38
    local end_status = '10r'

    local sql = string.format( G.sql_get_new_imei_by_mirrtalkinfo, model, init_status, cur_time )
    
    local ok, res = mysql_api.cmd(ident_dbname, 'SELECT', sql)
    if not ok or not res or type(res) ~= "table" then
        only.log('E',string.format("sql_get new_mirrtalk_imei failed, %s", sql ))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res == 0 then
        ---- 当前IMEI已经用完了,应该给予特定的错误码
        only.log('E',string.format("*********sql_get_new mirrtalk_imei all imei isOccupy, %s", sql ))
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
    end

    local new_imei = res[1]['imei']..res[1]['nCheck']
    local imei_tmp = res[1]['imei']

    local remarks = "车机绑定imei号码v2"

    local sql_tab = {}
    ---- 备份IMEI的状态
    local sql = string.format(G.sql_save_mirrtalk_history, new_imei, movement, init_status, end_status, cur_time, remarks)
    table.insert(sql_tab, sql)

    ---- 更新IMEI的状态
    local sql = string.format(G.sql_update_mirrtalkinfo_status, end_status, cur_time, imei_tmp)
    table.insert(sql_tab, sql)

    ---- 记录车机设备的唯一号
    local sql = string.format(G.sql_save_car_machine_info, cur_appKey, device_id, model, new_imei, cur_time)
    table.insert(sql_tab, sql)

    local ok, res = mysql_api.cmd(ident_dbname, 'AFFAIRS', sql_tab)
    if not ok or not res then
        only.log('E',string.format("[affairs] failed , %s", table.concat( sql_tab, "\r\n" ) ))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    ---- 押金类型(depositType)为 2 表示买断机器 --押金类型默认为0类
    only.log('D' ,string.format("==****==depositType= %s ,imei = %s ,depositAmount = %s ,appKey=%s ", 
                                        deposit_type, new_imei, deposit_amount, cur_appKey ))

    -- return new_imei
    ---- 此处之前存在调用发货代码失败的数据，导致数据缺失(已做调整自动修复这类数据)
    local checkImeiTimes = 3

    for i=0, checkImeiTimes do
        local ok = really_payUserDeposit(new_imei, deposit_type, deposit_amount,cur_appKey)
        if ok then
            return new_imei
        else
            only.log("W", string.format("====== payUserDeposit is failed ====  %d Times==", i ))
        end
    end
    only.log("E", "==****=== payUserDeposit is failed ==== 3 Times==")
    gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "payUserDeposit ")
end


local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()
    
    if not body  then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_host'] = ip
    url_info['client_body'] = body
    local sql,ret,imei

    ---- check parameters
    local res = check_parameter(body)
    only.log("D", "======xxxxxxxxxxxxxxxxx====")

    local cur_time = os.time()
    local data = {}

    local device_id, model, appKey  = res["deviceID"], res["model"], res['appKey']

    ---- 检测当前model与appkey是否有效
    local businessID = check_model_is_validity(model, appKey, cur_time)

    local cur_imei, status_ok = get_device_exists_imei(device_id, model)

    ---- 押金类型(depositType)为 2 表示买断机器 
    ---- 押金金额默认为0 , 
    ---- 表示为0元买断机器 2015-10-04
    local depositType, depositAmount = 2, 0

    if cur_imei and #tostring(cur_imei) == 15 and status_ok then
        only.log("W", "======aaaaaaaaaaaaaa====")
        ---- IMEI之前已经存在,且状态正确
        data['imei'] = cur_imei

    ----  此处自动修复之前存在调用发货代码失败的数据 2015-12-04 zhouzhe
    elseif cur_imei and #tostring(cur_imei) == 15 and not status_ok then
        only.log("W", "======bbbbbbbbbbbbb====") 
        local checkImeiTimes = 3

        for i=0, checkImeiTimes do
            local ok = really_payUserDeposit(cur_imei, depositType, depositAmount, appKey)
            if ok then
                data['imei'] = cur_imei
                break
            elseif checkImeiTimes == 3 then
                only.log("E", "==######=== payUserDeposit is failed ==== 3 Times==")
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "payUserDeposit ")
            else
                only.log("W", string.format("====##== payUserDeposit is failed ===###=  %d Times==", i ))
            end
        end
    else
        only.log("W", "======ccccccccccccc====")
        data["imei"] = get_new_mirrtalk_imei(model, appKey, cur_time, depositType, depositAmount, device_id)
    end

    -- data["imei"]  = cur_imei
    data["depositType"] = depositType
    data["depositAmount"] = depositAmount
    data["model"] = model
    data["appKey"] = appKey

    ---- data["businessID"] = businessID
    ---- 针对当前api只需要返回imei,理论上其他参数都可以屏蔽掉 
    ---- 2015-10-05
    data["businessID"] = 0 

    local ok, return_data = pcall(cjson.encode,data)

    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], return_data)

end

safe.main_call( handle )
