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

local function ready_execution_msgToken()

	post_data = ""
	local ok_status, ret = pcall(cjson.encode, post_data)
        if not ok_status then
                only.log('E', 'pcall cjson encode args failed!')
        end
	ret = string.sub(ret, 2, -2)

        only.log('D', '\n ret : ' .. ret)

	local data_fmt  = 'POST %s HTTP/1.0\r\n' ..
			'Host:%s:%s\r\n' ..
			'Content-Length:%d\r\n' ..
			'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

        local app_uri   = '/index.php/User/addgetRandChar'
        local host_info = link['OWN_DIED']['http']['addgetRandChar']
        data = string.format(data_fmt, app_uri, host_info['host'], host_info['port'], #ret, ret)
        local ok, result = cutils.http(host_info['host'], host_info['port'], data, #data)

        only.log('D', '\n data : %s', data)
        only.log('D', '\n result : %s', result)

        only.log('D', 'type = %s', type(result))

        msgToken = string.match(result, ".+%\r%\n%\r%\n(.*)")

	return ok, msgToken
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
	req_body		= cjson.decode(req_body)

	-- 获取请求参数
	-- 将header和body中的参数组装到一个table中,方便后续check和使用
	local parameter_tab			= {}
	parameter_tab['appKey']		= req_header['appKey']
	parameter_tab['sign']           = req_header['sign']
	parameter_tab['tokenCode']	= req_header['tokenCode']
	parameter_tab['timestamp']	= req_header['timestamp']
	parameter_tab['accountID']	= req_header['accountID']
	parameter_tab['mirrtalkID']	= req_header['mirrtalkID']

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
4. 从mysql中取出base Roadrank sicong userInfo数据
5. 生成token msgtoken
6. 组装返回信息,返回数据
--]]
