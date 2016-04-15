-- api_access.lua
-- auth: tianlu
-- date: 2016-04-13
-- 接收authorization-server传送的数据,存储到mysql

local ngx	= require('ngx')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local gosay	= require('gosay') 
local utils	= require('utils')
local only	= require('only')
local link	= require('link')
local cjson	= require('cjson')
local http_api	= require('http_short_api')
local dk_utils	= require('dk_utils')

-------------------------------------------------------------
-- 暂时只做参数接收并打印日志功能
-- 请求方式为GET
-- 接收的参数为 accountID accessToken accessTokenExpression
-- refreshToken refreshTokenExpression 共5个参数
-------------------------------------------------------------

local G = {
	body = '',
	sql_save_accountID = '',
	sql_save_accessToken = '',
	sql_save_accessTokenExpression = '',
	sql_save_refreshToken = '',
	sql_save_refreshTokenExpression = '',
}







local function handle()
	local req_body   = ngx.req.get_body_data()
	local req_method = ngx.var.request_method                               
	local args       = ngx.req.get_uri_args() 

	if req_method == 'GET' then
		if not args or type(args) ~= 'table' then  
			only.log('D', 'get bad request!')
			go_exit()
			return
		end
		G.body = string.format('GET %s', ngx.encode_args(args))
	end

	local accountID		= args['accountID']
	local accessToken	= args['accessToken']
	local accessTokenExpression	= args['accessTokenExpression']
	local refreshToken	= args['refreshToken']
	local refreshTokenExpression	= args['refreshTokenExpression']

	only.log('D', 'accountID : %s \r\n accessToken : %s \r\n accessTokenExpression : %s \r\n refreshToken : %s \r\n refreshTokenExpression \n')
end

handle()


