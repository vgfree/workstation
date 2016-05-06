-- name   :	login.lua
-- author :	louis.tin
-- data	  :	04-23-2016
-- 登录接口

local ngx	= require('ngx')
local only	= require('only')
local mysql_api = require('mysql_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local link      = require('link')
local cjson     = require('cjson')
local scan      = require('scan')
local safe      = require('safe')
local app_utils = require('app_utils')
local msg	= require('msg')

local app_config_db	= { [1] = 'login_config___config', [2] = 'weme_car___car' }

local url_tab = {
	type_name	= 'login',
	app_Key		= '',
	client_host	= '',
	client_body	= '',
}

local G = {
	sql_login_info 		= "SELECT base,roadRank,sicong FROM loginConfig WHERE appKey='%s'",
	sql_login_userInfo 	= "SELECT gender as sex,nickname as nickName,headName as headerUrl,activeCity as cityName FROM userInfo WHERE accountID='%s'"
}

local function ready_execution(appKey)
	local sql_str = string.format(G.sql_login_info, appKey)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	local ok_status, ok_config = mysql_api.cmd(app_config_db[1], 'SELECT', sql_str)
	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end

	return true, ok_config[1]['base'], ok_config[1]['roadRank'], ok_config[1]['sicong']
end

local function ready_execution_userInfo(accountID)
	local sql_str = string.format(G.sql_login_userInfo, accountID)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	local ok_status, ok_config = mysql_api.cmd(app_config_db[2], 'SELECT', sql_str)

	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end

	return true, ok_config[1]
end


local function check_parameter(parameter_table)
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

	safe.sign_check(parameter_tab, url_tab, 'accountID', safe.ACCESS_USER_INFO)
end

local function go_exit()
	local ret_str = '{"ERRORCODE":"ME01002", "RESULT":"appKey error"}'
	only.log('E','appKey error')
	gosay.respond_to_json_str(url_tab, ret_str)
end

local function handle()
	local req_header	= ngx.req.get_headers()
	local req_body		= ngx.req.get_body_data()
	local req_ip		= ngx.var.remote_addr

	only.log('D', 'req_header = %s', scan.dump(req_header))
	only.log('D', 'req_body = %s', req_body)

	url_tab['client_host']  = req_ip
	url_tab['client_body']  = req_body

	body			= cjson.decode(req_body)

	-- 获取请求参数
	-- 将header和body中的参数组装到一个table中,方便后续check和使用
	parameter_tab			= {}
	parameter_tab['appKey']		= req_header['appkey']
	parameter_tab['sign']           = req_header['sign']
	parameter_tab['accessToken']	= req_header['accesstoken']
	parameter_tab['timestamp']	= req_header['timestamp']
	parameter_tab['accountID']	= req_header['accountid']
	parameter_tab['imei']           = body['imei']
	parameter_tab['imsi']           = body['imsi']
	parameter_tab['modelVer']      	= body['modelVer']
	parameter_tab['androidVer']     = body['androidVer']
	parameter_tab['baseBandVer']    = body['baseBandVer']
	parameter_tab['kernelVer']      = body['kernelVer']
	parameter_tab['buildVer']       = body['buildVer']
	parameter_tab['lcdWidth']       = body['lcdWidth']
	parameter_tab['lcdHeight']      = body['lcdHeight']

	url_tab['app_Key']      = parameter_tab['appKey']

	only.log('D', 'parameter_tab = %s', scan.dump(parameter_tab))
	only.log('D', 'url_tab = %s', scan.dump(url_tab))

	-- 参数检查
	check_parameter(parameter_tab)

	-- 从mysql中获取base roadRank sicong 参数
	local ok_status, ok_ok_ret_base, ok_ok_ret_roadRank, ok_ok_ret_sicong = ready_execution(parameter_tab['appKey'])
	if ok_status == false then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_FAILED_GET_SECRET'], 'appKey')
	end

	local ok_ret_base, ret_base, base = {}, {}, {}
	if ok_ok_ret_base == nil then
		base = '{}'
	else
		ok_ret_base			= cjson.decode(ok_ok_ret_base)
		ret_base['msgServer']		= (ok_ret_base['msgServer'] == nil and "") or ok_ret_base['msgServer']
		ret_base['msgPort']		= (ok_ret_base['msgPort'] == nil and 0) or tonumber(ok_ret_base['msgPort'])
		ret_base['heart']		= (ok_ret_base['heart'] == nil and 0) or tonumber(ok_ret_base['heart'])
		ret_base['fileUrl']		= (ok_ret_base['fileUrl'] == nil and "") or ok_ret_base['fileUrl']
		base				= cjson.encode(ret_base)
	end

	local ok_ret_roadRank, ret_roadRank, roadRank = {}, {}, {}
	if ok_ok_ret_roadRank == nil then
		roadRank = "{}"
	else
		ok_ret_roadRank			= cjson.decode(ok_ok_ret_roadRank)
		ret_roadRank['rrIoUrl']		= (ok_ret_roadRank['rrIoUrl'] == nil and "") or ok_ret_roadRank['rrIoUrl']
		ret_roadRank['normalRoad']	= (ok_ret_roadRank['normalRoad'] == nil and 0) or tonumber(ok_ret_roadRank['normalRoad'])
		ret_roadRank['highRoad']	= (ok_ret_roadRank['highRoad'] == nil and 0) or tonumber(ok_ret_roadRank['highRoad'])
		ret_roadRank['askTime']		= (ok_ret_roadRank['askTime'] == nil and 0) or tonumber(ok_ret_roadRank['askTime'])
		roadRank			= cjson.encode(ret_roadRank)
	end

	local ok_ret_sicong, ret_sicong, sicong = {}, {}, {}
	if ok_ok_ret_sicong == nil then
		sicong   = "{}"
	else
		ok_ret_sicong			= cjson.decode(ok_ok_ret_sicong)
		ret_sicong['serverType']	= (ok_ret_sicong['serverType'] == nil and 0) or tonumber(ok_ret_sicong['serverType'])
		sicong  		 	= cjson.encode(ret_sicong)
	end

	-- 从mysql中获取 userInfo 参数
	local ok_status, ok_ret_userInfo = ready_execution_userInfo(parameter_tab['accountID'])
	local ret_userInfo, userInfo = {}, {}
	if ok_status == false then
		gosay.go_false(url_tab, msg['MSG_ERROR_ACCOUNT_ID_NO_MONEY'], 'accountID')
	end

	if ok_ret_userInfo == nil then
		userInfo = "{}"
	else
		ret_userInfo['sex']		= (ok_ret_userInfo['sex'] == nil and 0) or tonumber(ok_ret_userInfo['sex'])
		ret_userInfo['nickName']	= (ok_ret_userInfo['nickName'] == nil and "") or ok_ret_userInfo['nickName']
		ret_userInfo['headerUrl']	= (ok_ret_userInfo['headerUrl'] == nil and "") or ok_ret_userInfo['headerUrl']
		ret_userInfo['cityName']	= (ok_ret_userInfo['cityName'] == nil and "") or ok_ret_userInfo['cityName']
		userInfo			= cjson.encode(ret_userInfo)
	end

	only.log('D', 'ok_ret_base = %s', base)
	only.log('D', 'ok_ret_roadRank = %s', roadRank)
	only.log('D', 'ok_ret_sicong = %s', sicong)
	only.log('D', 'ok_ret_userInfo = %s', userInfo)

	-- 生成token
	-- TODO msgToken 需要调用田山川接口生成
	local token      = utils.random_string(10)
	local msgToken   = 1478523690

	-- 组装返回信息
	local ret_str = string.format('{"ERRORCODE":"%s", "RESULT":{"token":"%s", "msgToken":"%s", "accountID":"%s", "base":%s, "roadRank":%s, "sicong":%s, "userInfo":%s}}',
	"0",
	(token == nil and "") or token,
	(msgToken == nil and "") or msgToken,
	(parameter_tab['accountID'] == nil and "") or parameter_tab['accountID'],
	base,
	roadRank,
	sicong,
	userInfo)

	only.log('D', 'url_tab = %s, ret_str = %s', type(url_tab), type(ret_str))
	only.log('I', '[SUCCED] ___%s', ret_str)

	gosay.respond_to_json_str(url_tab, ret_str)
end

safe.main_call(handle)


--[[
1. 通过http head和body传入参数
2. 将传入参数重组为一个新的table
3. 参数检查
4. 从mysql中取出base Roadrank sicong userInfo数据
5. 生成token msgtoken
6. 组装返回信息,返回数据
--]]


