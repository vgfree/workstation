-- name: refreshTrustAccessToken.lua
-- auth: louis.tin
-- time: 04-21-2016
-- 信任的第三方开发者通过刷新令牌获取访问令牌

local ngx		= require ('ngx')
local sha		= require('sha1')
local redis_pool_api	= require('redis_pool_api')
local mysql_pool_api	= require('mysql_pool_api')
local http_api		= require('http_short_api')
local utils		= require('utils')
local only		= require('only')
local msg		= require('msg')
local gosay		= require('gosay')
local safe		= require('safe')
local link		= require('link')
local scan		= require('scan')
local cjson		= require('cjson')

local url_tab = {
	type_name   = 'refreshTrustAccesstoken',
	app_key     = '',
	client_host = '',
	client_body = '',
}

local function check_parameter(parameter_tab)


end


local function ready_execution(parameter_tab)
	post_data = string.format('appKey=%s&refreshToken=%s&sign=%s&grantType=refreshToken', parameter_tab['appKey'], parameter_tab['refreshToken'],parameter_tab['sign'])
	only.log('D', "post_data = %s", post_data)

	local data_fmt  = 'POST %s HTTP/1.0\r\n' ..
	'Host:%s:%s\r\n' ..
	'Content-Length:%d\r\n' ..
	'Content-Type:application/json\r\n\r\n%s'

	local app_uri   = '/oauth/v2/refreshTrustAccessToken'
	local host_info = link['OWN_DIED']['http']['refreshTrustAccessToken']
	data = string.format(data_fmt, app_uri, host_info['host'], host_info['port'], #post_data, post_data)
	local ok_status, ok_ret = cutils.http(host_info['host'], host_info['port'], data, #data)
	if not ok_status then
		only.log('E', 'http connect %s failed ', host_info['host'])
		return false, nil
	end
	if not ok_ret then
		only.log('E', 'configInfo return is nil when connect http')
		return false, nil
	end
	if #ok_ret < 1  then
                only.log('E', '[READY_FAILED]return empty when connect http')
                return false, nil
        end
	
	only.log('D', '\n data = %s', data)
	only.log('D', '\n ok_ret = %s', ok_ret)

	ret_tab = cjson.decode(string.sub(ok_ret, string.find(ok_ret, "{.+}")))
	only.log('D', 'ret_str = %s', scan.dump(ret_tab))

	return true, ret_tab
end


local function handle()
	local req_header        = ngx.req.get_headers()
	local req_ip            = ngx.var.remote_addr
	local req_body          = ngx.req.get_body_data()

	only.log('D', "req_header = \r\n %s\r\n", scan.dump(req_header))

	local parameter_tab            = {}
	parameter_tab['appKey']        = req_header['appkey']
	parameter_tab['sign']          = req_header['sign']
	parameter_tab['refreshToken']  = req_header['refreshtoken']

	url_tab['app_Key']      = parameter_tab['appKey']
	url_tab['client_host']  = req_ip
	url_tab['client_body']  = req_body

	only.log('D', 'parameter_tab = %s', scan.dump(parameter_tab))
	only.log('D', 'url_tab = %s', scan.dump(url_tab))

	-- 参数校验
	local args = check_parameter(parameter_tab)

	-- 执行生成accessToken 操作
	local ok_status, ok_ret = ready_execution(parameter_tab)
	if ok_status == false then
		gosay.go_false(url_tab, msg['MSG_DO_HTTP_FAILED'], 'accountID')
	end

	only.log('D', 'ok_ret = %s', scan.dump(ok_ret))
	
	if ok_ret['ERRORCODE'] == '0' then	
		-- 防止返回nil
		ret_str = string.format('{"accountID":"%s","accessTokenExpiration":"%s","refreshToken":"%s","accessToken":"%s","refreshTokenExpiration":"%s"}',
		(ok_ret['RESULT']['accountID'] == nil and "") or ok_ret['RESULT']['accountID'],
		(ok_ret['RESULT']['accessTokenExpiration'] == nil and "") or ok_ret['RESULT']['accessTokenExpiration'],
		(ok_ret['RESULT']['refreshToken'] == nil and "") or ok_ret['RESULT']['refreshToken'],
		(ok_ret['RESULT']['accessToken'] == nil and "") or ok_ret['RESULT']['accessToken'],
		(ok_ret['RESULT']['refreshTokenExpiration'] == nil and "") or ok_ret['RESULT']['refreshTokenExpiration']
		)
		only.log('D', 'ret_str = %s', ret_str)
	else
		gosay.go_false(url_tab, msg['MSG_ERROR_REFRESH_TOKEN_NOT_EXIST'], 'accountID')
	end

	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)
end

safe.main_call(handle)

--[[
1. 从head 中接收appkey sign refreshtoken 参数
2. 对参数进行校验
3. 通过http方式调用api_refresh_trust_access_token.lua获取返回值
4. 组装上一步的返回值,执行返回操作
注: 在返回新的accessToken 同时数据库和redis中的源数据也会更新
--]]

