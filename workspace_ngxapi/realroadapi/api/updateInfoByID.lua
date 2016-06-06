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
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_BAD_JSON"], 'accountID')
	end

	if not parameter_tab['appKey'] or #parameter_tab['appKey'] > 10 then
		only.log("E", "appKey is error")
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'appKey')
	end

	url_tab['app_Key']		= parameter_tab['appKey']

	if (not app_utils.check_accountID(parameter_tab['accountID'])) then
		only.log("E", "accountID is error")
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"], "accountID")
	end

	-- tokenCode检查
	only.log('D', 'accountID = %s', parameter_tab['accountID'])
	local ok_status, ok_ret = redis_api.cmd('realroad', 'GET', parameter_tab['accountID'] .. ':tokenCode')
        if not (ok_status and ok_ret) then
                gosay.go_false(url_tab, msg["MSG_DO_REDIS_FAILED"])
        end

        if ok_ret ~= parameter_tab['tokenCode'] then
                gosay.go_false(url_tab, msg["MSG_ERROR_TOKEN_CODE_NOT_MATCH"], "accountID")
        end

	safe.sign_check(parameter_tab, url_tab)
end

local function check_accountid(parameter_tab)
	local sql_str = string.format(G.select_user_accountid, parameter_tab['accountID'])
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
	local sql_str = string.format(G.ins_user_info, info_table.accountID, info_table.nickName, info_table.headPic, info_table.birthday, info_table.sex, info_table.cityName, info_table.cityCode, info_table.introduction, info_table.carBrand, info_table.carModel, info_table.carNumber)
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
	local sql_str = string.format(G.upd_user_info, info_table.nickName, info_table.headPic, info_table.birthday, info_table.sex, info_table.cityName, info_table.cityCode, info_table.introduction, info_table.carBrand, info_table.carModel, info_table.carNumber, info_table.accountID)
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

	local parameter_tab			= {}
	parameter_tab['appKey']         = req_header['appKey']
	parameter_tab['sign']           = req_header['sign']
	parameter_tab['tokenCode']	= req_header['tokenCode']
	parameter_tab['timestamp']      = req_header['timestamp']
	parameter_tab['accountID']	= req_header['accountID']
	parameter_tab['nickName']	= body['nickName']
	parameter_tab['headPic']	= body['headPic']
	parameter_tab['birthday']	= body['birthday']
	parameter_tab['sex']		= tonumber(body['sex'])
	parameter_tab['carBrand']	= body['carBrand']
	parameter_tab['carModel']	= body['carModel']
	parameter_tab['carNumber']	= body['carNumber']
	parameter_tab['cityName']	= body['cityName']
	parameter_tab['introduction']	= body['introduction']
	parameter_tab['cityCode']	= body['cityCode']


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
			gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"], "accountID")
		end
	else
		-- accountid存在,则执行更新资料操作
		local ok_status, ok_ret = ready_update(parameter_tab)
		if ok_status == false then
			only.log("E", "update userInfo failed")
			gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"], "accountID")
		end
	end

	-- 更新redis数据库中的信息
	local ret_userInfo              = {}
        ret_userInfo['accountID']       = parameter_tab['accountID']
        ret_userInfo['nickName']        = (parameter_tab['nickName'] == nil and "") or parameter_tab['nickName']
        ret_userInfo['headPic']         = (parameter_tab['headPic'] == nil and "") or parameter_tab['headPic']
        ret_userInfo['birthday']        = (parameter_tab['birthday'] == nil and "") or parameter_tab['birthday']
        ret_userInfo['sex']             = (parameter_tab['sex'] == nil and 0) or tonumber(parameter_tab['sex'])
        ret_userInfo['cityName']        = (parameter_tab['cityName'] == nil and "") or parameter_tab['cityName']
        ret_userInfo['cityCode']        = (parameter_tab['cityCode'] == nil and "") or parameter_tab['cityCode']
        ret_userInfo['introduction']    = (parameter_tab['introduction'] == nil and "") or parameter_tab['introduction']
        ret_userInfo['carBrand']        = (parameter_tab['carBrand'] == nil and "") or parameter_tab['carBrand']
        ret_userInfo['carModel']        = (parameter_tab['carModel'] == nil and "") or parameter_tab['carModel']
        ret_userInfo['carNumber']       = (parameter_tab['carNumber'] == nil and "") or parameter_tab['carNumber']

        local ok, ret_info = utils.json_encode(ret_userInfo)
        only.log('D', 'ret_userInfo = %s', ret_info)
        local ok_status, ok_ret = redis_api.cmd('realroad', 'SET', parameter_tab['accountID'] .. ':userInfo', ret_info)
        if not (ok_status and ok_ret) then
               gosay.go_false(url_tab, msg["MSG_DO_REDIS_FAILED"])
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
