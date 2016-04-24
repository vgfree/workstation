-- name: refreshTrustAccessToken.lua 
-- auth: louis.tin 
-- time: 04-21-2016 
-- 信任的第三方开发者通过刷新令牌获取访问令牌
--[[
程序思路:	
1. 从head 中接收appkey sign refreshtoken 参数
2. 对参数进行校验
3. 通过http方式调用api_refresh_trust_access_token.lua获取返回值
4. 组装上一步的返回值,执行返回操作
--]]



local ngx	= require ('ngx')                                                     
local sha	= require('sha1')                                                     
local redis_pool_api	= require('redis_pool_api')                                
local mysql_pool_api	= require('mysql_pool_api')                                
local http_api	= require('http_short_api')                                      
local utils	= require('utils')                                                                                   
local only	= require('only')                                                    
local msg	= require('msg')                                                      
local gosay	= require('gosay')                                                  
local safe	= require('safe')                                                    
local link	= require('link') 
local scan	= require('scan')
local cjson     = require('cjson') 

local url_tab = {
	type_name   = 'refreshTrustAccesstoken',
        app_key     = '',
        client_host = '',
        client_body = '',
}


local function handle()
	
	local req_header	= ngx.req.get_headers()
	local req_ip     	= ngx.var.remote_addr	
	local req_body   	= ngx.req.get_body_data()


	only.log('D', "req_header = \r\n %s\r\n", scan.dump(req_header))

	local result		= {}
	result['appKey']	= req_header['appkey']
	result['sign']		= req_header['sign']
	result['refreshToken']	= req_header['refreshtoken']
	
	url_tab['app_Key']	= result['appKey']
	url_tab['client_host'] 	= req_ip
	url_tab['client_body']	= req_body

	-- 参数校验	
	
	-- 组装http请求
	--[[ 
	local post_data = {
		appKey	= result['appKey'],
		sign	= result['sign'],
		refreshToken	= result['refreshToken'],
		grantType	= 'refreshToken'
	}
	--]]
	--[[
	local post_data = {
		appKey	= "984810830",
		sign	= "45456asdfserwerwefasdfsdf",
		refreshToken	= "2b9c5cd9f0c6cf2654c3cdfdc7b57709",
		grantType	= 'refreshToken'
	}
	--]]
--	post_data = "appKey=984810830&refreshtoken=2b9c5cd9f0c6cf2654c3cdfdc7b57709&sign=45456asdfserwerwefasdfsdf&grantType=refreshToken"
	
	post_data = string.format('appKey=%s&refreshToken=%s&sign=%s&grantType=refreshToken', result['appKey'], result['refreshToken'],result['sign'])

--	only.log('D', "post_data = %s\r\n", scan.dump(post_data))
	only.log('D', "\n post_data = %s", post_data)
	local ok_status, ret = pcall(cjson.encode, post_data)                   
	if not ok_status then                                                   
		only.log('E', 'pcall cjson encode args failed!')                 
	end        
	
	only.log('D', '\n ret : ' .. ret)
	
	ret = string.sub(ret, 2, -2)	
	
	only.log('D', '\n ret : ' .. ret)

	local data_fmt	= 'POST %s HTTP/1.0\r\n' ..                              
			  'Host:%s:%s\r\n' ..                                                     
			  'Content-Length:%d\r\n' ..                                              
			  'Content-Type:application/json\r\n\r\n%s'

	local app_uri	= '/oauth/v2/refreshTrustAccessToken'
	local host_info = link['OWN_DIED']['http']['refreshTrustAccessToken']
	data = string.format(data_fmt, app_uri, host_info['host'], host_info['port'], #ret, ret)
	local ok, result = cutils.http(host_info['host'], host_info['port'], data, #data)
	
	only.log('D', '\n data : ' .. data)
	only.log('D', '\n result : ' .. result)
	
	only.log('D', 'type = %s', type(result))	
	-------------------------------------------------------------------------------------------
	ret = cjson.decode(string.sub(result, string.find(result, "{.+}")))
	
	accessToken = ret['RESULT']['accessToken']	
	
	-------------------------------------------------------------------------------------------
	-- 组装上一步的返回值
	local ret_str = string.format('{"accountID":"%s","accessTokenExpiration":"%s","refreshToken":"%s","accessToken":"%s","refreshTokenExpiration":"%s"}', 
		(ret['RESULT']['accountID'] == nil and "") or ret['RESULT']['accountID'], 
		(ret['RESULT']['accessTokenExpiration'] == nil and "") or ret['RESULT']['accessTokenExpiration'], 
		(ret['RESULT']['refreshToken'] == nil and "") or ret['RESULT']['refreshToken'], 
		(ret['RESULT']['accessToken'] == nil and "") or ret['RESULT']['accessToken'], 
		(ret['RESULT']['refreshTokenExpiration'] == nil and "") or ret['RESULT']['refreshTokenExpiration']
	)
	
	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)
	--gosay.respond_to_json_str(url_tab,ret_str)
end

safe.main_call(handle)
