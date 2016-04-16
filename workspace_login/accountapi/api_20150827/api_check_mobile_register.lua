-- author:	zhouzhe
-- date:		2015.06.09
-- function:	checkMobileRegister 

local msg       	= require('msg')
local json 		= require('cjson')
local only      	= require('only')
local safe      	= require('safe')
local gosay     	= require('gosay')
local utils     	= require('utils')
local app_utils	= require('app_utils')
local mysql_api 	= require('mysql_pool_api')

local user_resgister_dbname = 'app_usercenter___usercenter'
local userinfo_dbname = 'app_cli___cli'

local G = {

	-- 验证新手机是否已经注册
	sl_userRegister = "SELECT accountID FROM userRegisterInfo WHERE mobile = '%s' AND validity = 1 ",
	-- 验证新手机号是否已经绑定
	sl_userinfo = " SELECT accountID FROM  userInfo WHERE mobile = '%s' AND status >= 1 ",
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 检查手机号是否被注册或绑定
local function check_mobile(mobile )
	local isbind = 0

	-- 验证手机是否已经注册userRegister
	local sql_str = string.format(G.sl_userRegister, mobile)
	local ok_status,res_table = mysql_api.cmd(user_resgister_dbname,'SELECT',sql_str)
	if not ok_status or res_table == nil then
	    only.log('E',sql_str)
	    only.log('E',string.format("mobile:%s  sl_userinfo failed!",mobile))
	    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #res_table ~= 0 then
		only.log("D", "mobile alresd register  %s", mobile )
		return 1 , res_table[1]['accountID']
	end

	-- 验证手机号是否已经绑定userinfo
	local sql_str = string.format(G.sl_userinfo, mobile)
	local ok_status,result = mysql_api.cmd(userinfo_dbname,'SELECT',sql_str)
	if not ok_status or result == nil then
	    only.log('E',sql_str)
	    only.log('E',string.format("mobile:%s  sl_userinfo failed!",mobile))
	    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #result ~= 0 then
		only.log("D", " mobile alread bind")
		return 1 , result[1]['accountID']
	end

	return isbind
end

-- 检查参数
local function check_parameter( args)

	if ( not args )or type(args) ~= "table" then
		only.log("E", " args not is table ")
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "args")
	end

	if (not args['appKey']) or (#args['appKey'] > 10) or (not utils.is_number(args['appKey']))  then
		only.log("E","appKey is error!")
		gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
	end

	if ( not utils.is_number(tonumber(args["mobile"]))) or (#args["mobile"] ~= 11) or (string.sub(args["mobile"], 1, 1) ~= '1') then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'mobile')
	end

	if not ( args["accountID"] or app_utils.check_accountID( args['accountID'])) then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	url_info["app_key"] = args['appKey']
	safe.sign_check( args, url_info )
end

function handle()
	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()

	if not body then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_info['client_host'] = ip
	url_info['client_body'] = body

	local args = utils.parse_url(body)

	local res_tab = {
		isbind = 0,
		ismatch = 0,
	}
	local accountID = nil
	-- 检查参数
	check_parameter(args)
	-- 检查手机号是否被注册或绑定
	res_tab['isbind'], accountID = check_mobile(args['mobile'])

	if accountID and accountID ~= "" then
		if args['accountID'] == accountID then
			res_tab['ismatch'] = 1
		end
	end
	if not res_tab then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], res_tab)
	end

	local ok, ret = pcall(json.encode, res_tab )

	if ok then
		gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'],ret)
	else
		gosay.go_false(url_info, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
