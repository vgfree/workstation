-- name 	: api_updateInfoByID
-- author 	: louis.tin
-- date 	: 04-16-2016
-- 修改个人资料

local ngx = require('ngx')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local app_utils = require('app_utils')
local safe = require('safe')
local scan = require('scan')
local cjson = require('cjson')

local update_info = "update_info___info"



local G = {
	
    upd_user_info = "UPDATE userInfo SET nickname='%s' , headName='%s', birthday='%s', gender=%d, activeCity='%s', cityCode='%s', introduction='%s', carBrand='%s', carModels='%s', plateNumber='%s' WHERE accountID='%s'"
}

local url_info = {
    type_name = 'system',
    app_Key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(args)

	-- check accountID
	if args['accountID'] then
		if #args['accountID']>0 then
		    if not app_utils.check_accountID(args['accountID']) then
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
		    end
		end
	end
	args['accountID']=args['accountID'] or ''

-- TODO 暂时不检查
--	safe.sign_check(args, url_info)

	return args
end

local function ready_update(info_table)

	local sql_str = string.format(G.upd_user_info, info_table.nickname, info_table.headname, info_table.birthday, info_table.gender, info_table.activeCity, info_table.cityCode, info_table.introduction, info_table.carBrand, info_table.carModel, info_table.plateNumber, info_table.accountID)
        only.log('W', "mysql select condfig info is :%s", sql_str)
	
	local ok_status, ok_config = mysql_pool_api.cmd(update_info, 'SELECT', sql_str)

	if not ok_status  then
                only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
                return false, nil
        end
        if not ok_config then
                only.log('E', 'configInfo return is nil when query sql_openconfig_info')
                return false, nil
        end
--        if #ok_config < 1  then
  --              only.log('E', '[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
    --            return false, nil
--        end
	
end

local function go_exit()
        local ret_str = '{"ERRORCODE":"ME01002", "RESULT":"appKey error"}'
        only.log('E','appKey error')
        gosay.respond_to_json_str(url_tab,ret_str)
end

local function handle()

	local req_ip 		= ngx.var.remote_addr
        local req_body 		= ngx.req.get_body_data()
        local req_headers 	= ngx.req.get_headers()
	
	local body = cjson.decode(req_body)	

	local info_table 	= {}
	info_table.accountID 	= req_headers.accountid
	info_table.nickname 	= body.nickName
	info_table.headname	= body.headPic
	info_table.birthday 	= body.birthday
	info_table.gender 	= tonumber(body.sex)
	info_table.carBrand 	= body.carBrand
	info_table.carModel	= body.carModel
	info_table.plateNumber	= body.carNumber
	info_table.activeCity 	= body.cityName
	info_table.introduction = body.introduction
	info_table.cityCode 	= body.cityCode	
	
	only.log('D', 'req_body = %s', req_body)
	only.log('D', 'info_table = %s', scan.dump(info_table))
	
	local args = check_parameter(info_table)
	
	local ok_status, ok_ret = ready_update(info_table)
        if ok_status == false then
	             go_exit()
      	end

	local ret = "ok";

	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end

safe.main_call( handle )
