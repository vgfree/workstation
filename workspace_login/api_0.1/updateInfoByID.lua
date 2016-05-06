-- name         : updateInfoByID.lua
-- author       : louis.tin
-- date         : 04-16-2016
-- 修改个人资料

local ngx	= require('ngx')
local only	= require('only')
local msg	= require('msg')
local gosay	= require('gosay')
local redis_api	= require('redis_pool_api')
local mysql_api	= require('mysql_pool_api')
local utils	= require('utils')
local app_utils = require('app_utils')
local safe	= require('safe')
local scan	= require('scan')
local cjson	= require('cjson')

local update_info = "update_info___info"

local G		= {
	select_user_accountid = "SELECT * FROM userInfo WHERE accountID = '%s'",
	upd_user_info = "UPDATE userInfo SET nickname='%s' , headName='%s', birthday='%s', gender=%d, activeCity='%s', cityCode='%s', introduction='%s', carBrand='%s', carModels='%s', plateNumber='%s' WHERE accountID='%s'",
	ins_user_info = "INSERT INTO userInfo (accountID, nickname, headName, birthday, gender, activeCity, cityCode, introduction, carBrand, carModels, plateNumber) VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')"
}

local url_tab	= {
	type_name	= 'updateInfoByID',
	app_Key		= nil,
	client_host	= nil,
	client_body	= nil,
}

local function check_parameter(parameter_tab)
	if not parameter_tab then
		only.log('E',string.format('call parse_url function return nil!'))
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_BAD_JSON"])
	end

	if not parameter_tab['appkey'] or #parameter_tab['appkey'] > 10 then
		only.log("E", "appKey is error")
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'appKey')
	end

	if (not app_utils.check_accountID(parameter_tab['accountid'])) then
		only.log("E", "accountID is error")
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"], "accountID")
	end

	safe.sign_check(parameter_tab, url_tab, 'accountid', safe.ACCESS_USER_INFO)
end

local function check_accountid(parameter_tab)
	local sql_str = string.format(G.select_user_accountid, parameter_tab['accountid'])
	only.log('W', "mysql select condfig info is :%s", sql_str)

	local ok_status, ok_config = mysql_pool_api.cmd(update_info, 'SELECT', sql_str)
	-- 打印返回信息
	only.log('D', 'type = %s, ok_config = %s', type(ok_config), scan.dump(ok_config[1]))

	if not ok_status  then
		only.log('E', 'connect database failed when query select_user_accountid %s ', sql_str)
		return false, nil
	end
	if not ok_config[1] then
		only.log('E', 'configInfo return is nil when query select_user_accountid')
		return false, nil
	end

	return true, ok_config
end

local function insert_userinfo(info_table)
	local sql_str = string.format(G.ins_user_info, info_table.accountID, info_table.nickname, info_table.headname, info_table.birthday, info_table.gender, info_table.activeCity, info_table.cityCode, info_table.introduction, info_table.carBrand, info_table.carModel, info_table.plateNumber)
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

	return true, ok_config
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

	return true, ok_config
end

local function go_exit()
	local ret_str = '{"ERRORCODE":"ME01002", "RESULT":"appKey error"}'
	only.log('E','appKey error')
	gosay.respond_to_json_str(url_tab,ret_str)
end

local function handle()
	local req_ip            = ngx.var.remote_addr
	local req_body          = ngx.req.get_body_data()
	local req_header	= ngx.req.get_headers()

	only.log('D', 'req_body = %s', req_body)

	url_tab['client_host']		= req_ip
	url_tab['client_body']		= req_body
	-- 获取的body为json
	local body = cjson.decode(req_body)

	only.log('D', 'body = %s', scan.dump(body))
	only.log('D', 'req_header = %s', scan.dump(req_header))

	parameter_tab			= {}
	parameter_tab['appkey']         = req_header['appkey']
	parameter_tab['sign']           = req_header['sign']
	parameter_tab['accesstoken']	= req_header['accesstoken']
	parameter_tab['timestamp']      = req_header['timestamp']
	parameter_tab['accountid']	= req_header['accountid']
	parameter_tab['nickname']	= body['nickName']
	parameter_tab['headname']	= body['headPic']
	parameter_tab['birthday']	= body['birthday']
	parameter_tab['gender']		= tonumber(body['sex'])
	parameter_tab['carBrand']	= body['carBrand']
	parameter_tab['carModel']	= body['carModel']
	parameter_tab['plateNumber']	= body['carNumber']
	parameter_tab['activeCity']	= body['cityName']
	parameter_tab['introduction']	= body['introduction']
	parameter_tab['cityCode']	= body['cityCode']

	url_tab['app_Key']		= parameter_tab['appkey']

	only.log('D', 'parameter_tab = %s', scan.dump(parameter_tab))
	only.log('D', 'url_tab = %s', scan.dump(url_tab))

	-- 参数校验
	check_parameter(parameter_tab)

	-- accountid校验
	local ok_status, ok_ret = check_accountid(parameter_tab)
	if ok_ret == nil then
		-- accountid不存在则执行插入操作
		local ok_status, ok_ret = insert_userinfo(parameter_tab)
		if ok_status == false then
			only.log("E", "insert userInfo failed")
			gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"], "accountid")
		end
	else
		-- accountid存在,则执行更新资料操作
		local ok_status, ok_ret = ready_update(parameter_tab)
		if ok_status == false then
			only.log("E", "update userInfo failed")
			gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"], "accountid")
		end
	end

	local ret = 'ok';

	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end

safe.main_call( handle )

--[[
1. 接受参数,组合参数,校验参数
2. 当accountid在数据库中不存在时,将传入数据insert到数据库中
当accountid在数据库中存在时,执行资料更新操作
--]]
