-->[author]: xuyf
-->[time]: 2014-03-13

local msg = require('msg')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local only = require('only')
local msg = require('msg')
local safe = require('safe')

local G = {
    sl_car_machine = "SELECT 1 FROM carMachineInfo WHERE deviceID = '%s' AND model = '%s' AND imei != 0",
    sl_imei = " SELECT imei FROM userList WHERE accountID = '%s' ",
    sl_model = " SELECT 1 FROM modelInfo WHERE model = '%s' and endTime > %s and validity = 1",
    sl_mirrtalk = "SELECT imei,nCheck FROM mirrtalkInfo WHERE model = 'S9YNK' AND status = '10a' and endTime > 1426649093 and validity = 1 limit 1",
    ins_mirrtalk_history = " INSERT INTO mirrtalkHistory SET imei = '%s', movement = 38, originalStatus = '10a', endStatus = '10r', updateTime= '%s', remarks = '%s' ",
    upd_mirrtalk = " UPDATE mirrtalkInfo  SET status= '10r' , updateTime = '%s' WHERE imei = '%s' ",
    ins_car_machine = " INSERT INTO carMachineInfo SET appKey = '%s', deviceID = '%s', model = '%s', imei = '%s', createTime = '%s' ",

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
    if not res['appKey'] or (#res['appKey'] > 10) then 
	gosay.go_false(url_info,msg["MSG_ERROR_REQ_FAILED_GET_SECRET"])
    end
    url_info['app_key'] = res['appKey']

    -->> check accountID
    if (not utils.is_word(res["accountID"])) or (#res["accountID"] ~= 10) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountID")
    end
    -->> check deviceID
    if (not utils.is_word(res["deviceID"])) or (#res["deviceID"] > 64) then
	gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "deviceID")
    end
    -->> check model
    if( not utils.is_word(res["model"])) or (#res["model"] ~= 5 ) then
	gosay.go_false(url_info,msg["MSG_ERROR_REQ_ARG"], "model" )
    end

    -->>SG900 and MG900 model is mirrtalk company internal using
    if(res["model"] == "SG900") or (res["model"] == "MG900")then
    	gosay.go_false(url_info,msg["MSG_ERROR_REQ_CODE"],"SG900 and MG900 model is mirrtalk company internal using!")
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
    local res = check_parameter(body)

    local appKey     = res["appKey"]
    local account_id = res["accountID"]
    local device_id  = res["deviceID"]
    local model      = res["model"]
	
    local time = os.time()

    -->> check model whether register in mirrtalk company 
    local sql = string.format( G.sl_model,model,time )
    only.log( 'D',sql )
    local ok,res = mysql_pool_api.cmd( 'app_ident___ident','SELECT',sql)
    if not ok then 
	gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end
    if #res == 0 then
	gosay.go_false(url_info,msg["MSG_ERROR_REQ_CODE"], "this model is not register!")
    end
    if #res > 1 then
	gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end
    -->> check accountID whether binding imei
    local sql = string.format(G.sl_imei, account_id )
        only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_usercenter___usercenter', 'SELECT', sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    end

    if #res > 1 then
	gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end

    if tonumber(res[1]['imei']) ~= 0 then
	-->> MSG_ERROR_ACCOUNT_ID_HAS_BIND 是新添加的错误码
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_HAS_BIND"])
    end

    -->> check car_device whether exist and binding
    sql = string.format( G.sl_car_machine, device_id,model )
    only.log('D',sql)
    local ok, res = mysql_pool_api.cmd('app_ident___ident', 'SELECT', sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res > 1 then
	gosay.go_false(url_info,msg["SYSTEM_ERROR"])
    end

    if #res == 1 then
	-->> MSG_ERROR_ACCOUNT_ID_HAS_BIND 是新添加的错误码
        gosay.go_false(url_info, msg["MSG_ERROR_DEVICE_ID_HAS_BIND"])
    end
    
    -->> select one imei from coreIdentification.mirrtalkInfo
    sql = string.format( G.sl_mirrtalk, model, time )
    only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_ident___ident', 'SELECT', sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    
    if #res==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
    end

    local imei = res[1]['imei'] .. res[1]['nCheck']
    local imei_14 = res[1]['imei']
    local remarks = "车机绑定imei号码"
    -->> insert mirrtalkHistory,update mirrtalk and insert carMachineInfo ,and
    --all of this three database action is a affairs
    local sql_tab = {}
    sql = string.format(G.ins_mirrtalk_history, imei,time,remarks)
    only.log('D', sql)
    table.insert(sql_tab, sql)
    sql = string.format(G.upd_mirrtalk, time,imei_14)
    only.log('D', sql)
    table.insert(sql_tab, sql)
    sql = string.format(G.ins_car_machine, appKey,device_id, model, imei, time)
    only.log('D',sql)
    table.insert(sql_tab, sql)
    local ok, res = mysql_pool_api.cmd('app_ident___ident', 'affairs', sql_tab)
    if not ok then
    	gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
   
    -->> return imei
    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], imei)

end

safe.main_call( handle )
