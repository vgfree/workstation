---- zhouzhe
---- 2015.06.08
---- 根据原有手机号或者accountID来修改或者绑定手机号

local msg       	= require('msg')
local gosay     	= require('gosay')
local utils     	= require('utils')
local app_utils	= require('app_utils')
local only      	= require('only')
local msg       	= require('msg')
local safe      	= require('safe')
local redis_api = require('redis_pool_api')
local mysql_api 	= require('mysql_pool_api')

local user_center_dbname = 'app_usercenter___usercenter'

local cur_time = os.time()

local G = {
		-->> 得到用户信息
		sql_get_login_info= " SELECT accountID FROM userLoginInfo WHERE %s='%s' ",
		-->> 验证用户信息
		sql_check_oauthinfo = " SELECT accountID FROM thirdAccessOauthInfo WHERE %s='%s' ",
		-->> 保存用户注册信息
		sql_save_user_account_info = " INSERT INTO userLoginInfo SET accountID='%s', mobile='%s', daokePassword= '', userStatus=1,"..
							" accountSourceType=2, nickname='%s', gender=3, clientIP=INET_ATON('%s'), createTime=%d, updateTime=%d ",
		-->> 保存用户个人信息表
		sql_save_user_personal_info = " INSERT INTO userGeneralInfo SET accountID='%s', userStatus=1, createTime=%d, updateTime=%d ",
		-->> 更新用户手机号
		sql_update_loging_mobile= "UPDATE userLoginInfo SET mobile='%s', updateTime=%d WHERE accountID='%s'",

}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 得到账户编号
local function get_accountID_by_mobile( mobile )
	-->> 获取用户accountID
	local sql_str = string.format( G.sql_get_login_info,  'mobile', mobile )
	local ok, result = mysql_api.cmd(user_center_dbname,'SELECT',sql_str)
	if not ok or not result then
	    only.log('E',string.format("get login accountID failed===%s", sql_str))
	    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #result == 0 or type(result) ~= "table" then
		only.log("E", "mysql is access but result is nil")
		gosay.go_false(url_info, msg["MSG_ERROR_NOT_MOBILE_AUTH"] )
	end
	return result[1]["accountID"]
end

-- 检查参数并判断用户名类型
local function check_parameter( args)
	if ( not args )or type(args) ~= "table" then
		only.log("E", " args not is table ")
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "args")
	end

	if not args['appKey'] or #args['appKey'] > 10 or not utils.is_number(args['appKey'])  then
		gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
	end

	if(not utils.is_number(tonumber(args["newmobile"]))) or (#args["newmobile"] ~= 11) or (string.sub(args["newmobile"], 1, 1) ~= '1') then
		only.log("E", "newmobile:%s", args["newmobile"])
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'newmobile')
	end

	if args["mobile"] and args["mobile"] ~= "" then
		if(not utils.is_number(tonumber(args["mobile"]))) or (#args["mobile"] ~= 11) or (string.sub(args["mobile"], 1, 1) ~= '1') then
			only.log("E", "mobile = %s", args["mobile"])
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'mobile')
		end
	elseif args["accountID"] and args["accountID"] ~= ""  then
		if not app_utils.check_accountID( args['accountID'])  then
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
		end
	else
		only.log("E", "accountID, mobile need at least one")
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], " accountID, mobile need at least one")
	end

	safe.sign_check( args, url_info )
end 

-->> 绑定的手机号,accountID
local function bind_mobile_with_accountid(newmobile, accountID, IP )

	-->> 验证手机号是否已经被使用
	local sql_str = string.format(G.sql_get_login_info, 'mobile', newmobile)
	only.log('D', string.format("=11==check mobile loginginfo ==%s", sql_str ))
	local ok,ret = mysql_api.cmd(user_center_dbname,'SELECT',sql_str)
	if not ok or not ret then
	    only.log('E',string.format("newmobile:%s  sl_userinfo failed! sql_str:%s",newmobile, sql_str))
	    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret ~= 0 then
		only.log("E", " newmobile alread bind accountID")
		gosay.go_false(url_info, msg["MSG_ERROR_MOBILE_ALREAD_BIND"])
	end

	-->> 验证accountID是否存在 thirdAccessOauthInfo
	local sql1 = string.format(G.sql_check_oauthinfo, 'accountID', accountID)
	only.log('D', string.format("=22==check accountID oauthinfo ==%s", sql1 ))
	local ok, ret = mysql_api.cmd(user_center_dbname,'SELECT',sql1 )
	if not ok or not ret then
		only.log('E', "check accountID failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
	local isthird=false
	if #ret > 0 then
		isthird=true
	end

	-->> accountID是否存在userLoginInfo
	local sql = string.format(G.sql_get_login_info, 'accountID', accountID)
	only.log('D', string.format("=33==check accountID loginginfo ==%s", sql ))
	local ok, result = mysql_api.cmd(user_center_dbname,'SELECT',sql)
	if not ok or not result then
		only.log('E', "check accountID failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	-->> 获取用户昵称
	local ok, nickname = redis_api.cmd('private', 'get', accountID .. ':nickname')
	if not ok then
		only.log("E", "get nickname by redis failed")
		gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'] )
	end

	-->> 1）用户不存在
	if #result < 1 and not isthird then
		only.log("E", "accountID not exists")
		gosay.go_false(url_info, msg['MSG_ERROR_ACCOUNT_ID_NO_SERVICE'] )
	-->> 2）第三方用户注册2绑定手机号
	elseif #result < 1 and isthird then
		-->> 为新用户绑定手机号
		-->> 存入数据userLoginInfo
		local tab_sql = {}
		sql1 = string.format( G.sql_save_user_account_info, accountID,
															newmobile, 
															nickname or '',
															IP,
															cur_time,
															cur_time )

		-->> 存入数据userGeneralInfo
		local sql2 = string.format(G.sql_save_user_personal_info, accountID,  cur_time, cur_time )

		only.log('D', string.format("=44==save user account info==%s", sql1 ))
		only.log('D', string.format("=55==save user personal info==%s", sql2 ))
		table.insert(tab_sql, sql1 )
		table.insert(tab_sql, sql2 )
		local ok = mysql_api.cmd(user_center_dbname, 'affairs', tab_sql)
		if not ok then
			only.log("E", "insert user info is failed")
			gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
		end
	-->> 3）第三方老用户换绑手机号 \\ 4）非第三方用户绑定手机号
	else
		-->> 更新手机号
		local sql = string.format(G.sql_update_loging_mobile, newmobile, cur_time, accountID )
		only.log('D', string.format("=66==update mobile loginginfo ==%s", sql ))
		local ok,result = mysql_api.cmd(user_center_dbname,'SELECT',sql)
		if not ok or not result then
			only.log('E', "check accountID failed")
			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
		end
	end
end

function handle()
	local IP = ngx.var.remote_addr
	local body = ngx.req.get_body_data()
	if not body then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_info['client_host'] = IP
	url_info['client_body'] = body

	local args = utils.parse_url(body)

	-->> 1)检查参数并判断用户名类型
	check_parameter(args)
	url_info["app_key"] = args["appKey"]

	-->> 2)得到账户编号
	local accountID = nil
	local flag_mobile = nil
	if args["mobile"] and #args["mobile"] == 11 then
		accountID = get_accountID_by_mobile( args["mobile"] )
		flag_mobile = "mobile"
	elseif args['accountID'] and #args['accountID'] >0 then
		accountID = args["accountID"]
	else
		gosay.go_false(url_info, msg['MSG_ERROR_NOT_INPUT_PARAMETER'])
	end

	if args['accountID'] and args['accountID'] ~= '' and flag_mobile then
		if tostring(args['accountID']) ~= tostring(accountID )then
			only.log("E", "mobile_accountID and accountID is not match! %s, %s",args['accountID'], accountID )
			gosay.go_false(url_info, msg["MSG_ERROR_MOBILE_ACCOUNT_NOT_MATCH"] )
		end
	end

	if not accountID then
		only.log("E", "accountID is nil!")
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], flag_mobile or "accountID" )
	end

	-- 3)绑定的手机号,accountID
	bind_mobile_with_accountid( args["newmobile"], accountID, IP )

	gosay.go_success( url_info, msg['MSG_SUCCESS'] )
end

safe.main_call( handle )
