-- name   :     queryInfoByID.lua
-- author :     louis.tin
-- data   :     05-04-2016
-- 获取个人资料接口

local utils     = require('utils')
local only      = require('only')
local ngx       = require('ngx')
local gosay     = require('gosay')
local msg       = require('msg')
local safe      = require('safe')
local mysql_api = require('mysql_pool_api')
local scan      = require('scan')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')

local weme_car	= 'weme_car___car'

local url_tab	= {
	type_name	= 'queryInfoByID',
	app_key		= nil,
	client_host	= nil,
	client_body	= nil
}

local G		= {
	get_user_info = " select accountID as accountID,nickname as nickName,headName as headPic,birthday as birthday,gender as sex, activeCity as cityName,cityCode as cityCode,introduction as introduction,carBrand as carBrand,carModels as  carModel, plateNumber as carNumber from userInfo where accountID = '%s' "
}

local function check_parameter (parameter_tab)
	if not parameter_tab then
		only.log('E',string.format('call parse_url function return nil!'))
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_BAD_JSON"])
	end

	if not parameter_tab['appKey'] or #parameter_tab['appKey'] > 10 then
		only.log("E", "appKey is error")
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'appKey')
	end
	url_tab['app_Key'] = parameter_tab['appKey']

	if (not app_utils.check_accountID(parameter_tab['accountID'])) then
		only.log("E", "accountID is error")
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"], "accountID")
	end

	-- 检查tokenCode
	local ok_status, ok_ret = redis_api.cmd('realroad', 'GET', parameter_tab['accountID'] .. ':tokenCode')
        if not (ok_status and ok_ret) then
                gosay.go_false(url_tab, msg["MSG_DO_REDIS_FAILED"])
        end
	only.log('D', 'ok_ret = %s , tokenCode = %s', ok_ret, parameter_tab['tokenCode'])
	if ok_ret ~= parameter_tab['tokenCode'] then
		gosay.go_false(url_tab, msg["MSG_ERROR_TOKEN_CODE_NOT_MATCH"], "accountID")
	end

	safe.sign_check(parameter_tab, url_tab)
end

local function ready_execution(accountID)
	local sql_str = string.format(G.get_user_info, accountID)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	local ok_status, ok_config = mysql_api.cmd(weme_car, 'SELECT', sql_str)

	only.log('D', 'type = %s, ok_config = %s', type(ok_config), scan.dump(ok_config[1]))

	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end
	if #ok_config < 1  then
		only.log('E', '[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
		return false, nil
	end

	return true, ok_config[1]
end

local function go_exit()
	local ret_str = '{"ERRORCODE":"ME01002", "RESULT":"appKey error"}'
	gosay.respond_to_json_str(url_tab,ret_str)
end

local function handle ()

	local req_header        = ngx.req.get_headers()
	local req_body          = ngx.req.get_body_data()
	local req_ip            = ngx.var.remote_addr

	only.log('D', 'req_header = %s', scan.dump(req_header))

	parameter_tab			= {}
	parameter_tab['appKey']		= req_header['appKey']
	parameter_tab['accountID']	= req_header['accountID']
	parameter_tab['tokenCode']	= req_header['tokenCode']
	parameter_tab['timestamp']	= req_header['timestamp']
	parameter_tab['sign']		= req_header['sign']

	url_tab['client_host']  = req_ip
	url_tab['client_body']  = req_body

	only.log('D', 'parameter_tab = %s', scan.dump(parameter_tab))

	check_parameter(parameter_tab)

	-- 从mysql中获取个人资料
	local ok_status, ok_ret_userInfo = ready_execution(parameter_tab['accountID'])
	if ok_status == false then
		go_exit()
	end

	only.log('D', 'ok_ret_userInfo = %s', scan.dump(ok_ret_userInfo))

	-- 检测nil, 重新组装并返回结果
	ret_userInfo			= {}
	ret_userInfo['accountID']	= (ok_ret_userInfo['accountID'] == nil and "") or ok_ret_userInfo['accountID']
	ret_userInfo['nickName']	= (ok_ret_userInfo['nickName'] == nil and "") or ok_ret_userInfo['nickName']
	ret_userInfo['headPic']		= (ok_ret_userInfo['headPic'] == nil and "") or ok_ret_userInfo['headPic']
	ret_userInfo['birthday']	= (ok_ret_userInfo['birthday'] == nil and "") or ok_ret_userInfo['birthday']
	ret_userInfo['sex']		= (ok_ret_userInfo['sex'] == nil and 0) or tonumber(ok_ret_userInfo['sex'])
	ret_userInfo['cityName']	= (ok_ret_userInfo['cityName'] == nil and "") or ok_ret_userInfo['cityName']
	ret_userInfo['cityCode']	= (ok_ret_userInfo['cityCode'] == nil and "") or ok_ret_userInfo['cityCode']
	ret_userInfo['introduction']	= (ok_ret_userInfo['introduction'] == nil and "") or ok_ret_userInfo['introduction']
	ret_userInfo['carBrand']	= (ok_ret_userInfo['carBrand'] == nil and "") or ok_ret_userInfo['carBrand']
	ret_userInfo['carModel']	= (ok_ret_userInfo['carModel'] == nil and "") or ok_ret_userInfo['carModel']
	ret_userInfo['carNumber']	= (ok_ret_userInfo['carNumber'] == nil and "") or ok_ret_userInfo['carNumber']

	only.log('D', 'ret_userInfo = %s', scan.dump(ret_userInfo))

	-- 将指定信息以json格式存储到redis中
	local ok, ret_str = utils.json_encode(ret_userInfo)
        only.log('D', 'ret_str = %s', ret_str)
        local ok_status, ok_ret = redis_api.cmd('realroad', 'SET', ret_userInfo['accountID'] .. ':userInfo', ret_str)
        if not (ok_status and ok_ret) then
                gosay.go_false(url_tab, msg["MSG_DO_REDIS_FAILED"])
        end

	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)
end

safe.main_call( handle )

--[[
1. 接受参数
2. 校验参数
3. 从数据库中取出个人资料
4. 组装返回信息
5. 执行返回操作
--]]
