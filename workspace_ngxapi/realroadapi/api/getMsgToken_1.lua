-- name   :	getMsgToken.lua
-- author :	louis.tin
-- data	  :	05-23-2016
-- 刷新消息服务器msgToken接口

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
local redis_api	= require('redis_pool_api')

local url_tab = {
	type_name	= 'login',
	app_Key		= '',
	client_host	= '',
	client_body	= '',
}

local function check_parameter(parameter_tab)
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

	if not parameter_tab['mirrtalkID'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'mirrtalkID')
	end

	local ok = check_mirrtalkid(parameter_tab['mirrtalkID'],parameter_tab['imei'])
	if not ok then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'mirrtalkID')
	end

	safe.sign_check(parameter_tab, url_tab)
end

local function ready_execution_msgToken(args)
	local header = {}
	header['appKey'] = args['appKey']

	if not args['accountID'] or args['accountID'] == '' then
		header['accountID'] = args['mirrtalkID']
	else
		header['accountID'] = args['accountID']
	end

	header['timestamp'] = os.time()
	local sign = app_utils.gen_sign(header)
	header['sign'] = sign

	local msg_server = link["OWN_DIED"]["http"]["msg_server"]
	local req_data = utils.compose_http_json_request(msg_server, "api/getMsgToken", header, '')
	only.log('D','req_data = %s', req_data)
	local ret = http_api.http( msg_server, req_data, true )
	only.log('D','ret = %s', ret)
	local ret_str = string.match(ret, '{.+}')
	only.log('D','ret_str = %s', ret_str)
	local ok,msg_tab = pcall(cjson.decode,ret_str)
	if not ok then
		only.log('E','cjson error when decode msg')
		return nil
	end
	local msg_token = msg_tab['RESULT']['msgToken']
	return msg_token
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

	url_tab['client_body']  = req_body

	-- 获取请求参数
	-- 将header和body中的参数组装到一个table中,方便后续check和使用
	local args		= {}
	parameter_tab['appKey']		= req_header['appKey']
	parameter_tab['sign']           = req_header['sign']
	parameter_tab['timestamp']	= req_header['timestamp']
	parameter_tab['accountID']	= req_header['accountID']
	parameter_tab['mirrtalkID']	= req_header['mirrtalkID']
	parameter_tab['tokenCode']	= req_header['tokenCode']

	url_tab['app_Key']      = parameter_tab['appKey']
	url_tab['client_host']  = req_ip

	only.log('D', 'parameter_tab = %s', scan.dump(parameter_tab))
	only.log('D', 'url_tab = %s', scan.dump(url_tab))

	-- 参数检查
	check_parameter(parameter_tab)

	-- 生成msgToken
	local ok_status, msgToken = ready_execution_msgToken()
	only.log('D', 'msgToken = %s', msgToken)

	-- 组装返回信息
	local ret_str = string.format('{"ERRORCODE":"%s", "RESULT":{"accountID":"%s", "msgToken":"%s"}}', parameter_tab["accountID"], msgToken)

	only.log('I', '[SUCCED] ___%s', ret_str)

	gosay.respond_to_json_str(url_tab, ret_str)
end

safe.main_call(handle)


--[[
1. 通过http head和body传入参数
2. 将传入参数重组为一个新的table
3. 参数检查
4. 生成msgtoken
5. 组装返回信息,返回数据
--]]
