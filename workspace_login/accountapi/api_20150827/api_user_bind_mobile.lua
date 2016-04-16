-- author:	zhouzhe
-- date:		2015.06.08
-- function:	根据原有手机号或者accountID来修改或者绑定手机号

local msg       	= require('msg')
local gosay     	= require('gosay')
local utils     	= require('utils')
local app_utils	= require('app_utils')
local only      	= require('only')
local msg       	= require('msg')
local safe      	= require('safe')
local mysql_api 	= require('mysql_pool_api')

local user_center_dbname = 'app_usercenter___usercenter'
local userinfo_dbname = 'app_cli___cli'

local G = {

	-- 验证新手机是否已经注册
	sl_userRegister = "SELECT 1 FROM userRegisterInfo WHERE mobile = '%s' AND validity = 1 ",
	-- 插入数据到数据库userRegisterInfo
	inster_userRegister = "INSERT INTO userRegisterInfo SET accountID='%s', createTime=%d, mobile = '%s', checkMobile = 1, validity=1",
	-- 验证新手机号是否已经绑定
	sl_userinfo = " SELECT 1 FROM  userInfo WHERE mobile = '%s' AND status >= 1 ",
	-- 验证accountID是否存在userRegisterInfo
	sl_userRegister_aid = " SELECT 1 FROM userRegisterInfo WHERE accountID= '%s' AND validity = 1 ",
	-- 验证accountID是否存在userList
	sl_userList_aid = " SELECT 1 FROM userList WHERE accountID= '%s' ",
	-- 获取用户acountID
	sl_userRegister_accountID = "SELECT accountID FROM userRegisterInfo WHERE mobile = '%s' AND validity = 1 ",
	-- 更新数据库userRegisterInfo
	update_userRegister = " UPDATE userRegisterInfo SET mobile = '%s', checkMobile = 1 WHERE  accountID = '%s' AND validity = 1 ",
	-- 更新数据表userInfo
	update_userInfo = " UPDATE userInfo SET mobile = '%s', checkMobileTime = '%s'  WHERE accountID = '%s' AND status >= 1  ",
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 更新数据库
local function update_user_mobile(newmobile, accountID, inst_ok )
	if not inst_ok then
		-- 用户更换手机号
		local sql_str = string.format(G.update_userRegister, newmobile, accountID)
		local ok_status,result = mysql_api.cmd(user_center_dbname,'UPDATE',sql_str)
		if not ok_status or result == nil then
			only.log('E', sql_str)
			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
		end
	end
	-- 更新数据表userInfo
	local checkMobileTime = os.time()
	local sql_userinfo = string.format(G.update_userInfo, newmobile, checkMobileTime, accountID)
	local ok,result = mysql_api.cmd(userinfo_dbname,'UPDATE',sql_userinfo)

	if not ok or result == nil then
	    only.log('E',sql_userinfo)
	    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
end

-- 得到账户编号
local function get_accountID_by_mobile( mobile )
	if not mobile then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile")
	end

	local sql_str = string.format( G.sl_userRegister_accountID, mobile )
	local ok_status, result = mysql_api.cmd(user_center_dbname,'SELECT',sql_str)
	if not ok_status or result == nil then
	    only.log('E',string.format("sl_userRegister_accountID failed! sql_str:%s", sql_str))
	    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #result == 0 or type(result) ~= "table" then
		only.log("E", "mysql is access but result is nil !  %s", sql_str)
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
	url_info["app_key"] = args["appKey"]
	safe.sign_check( args, url_info )

end 

-- 验证需要绑定的手机号,accountID
local function check_mobile(newmobile, accountID )

	-- 1)验证手机号是否已经绑定userinfo
	local sql_str = string.format(G.sl_userinfo, newmobile)
	local ok_status,result = mysql_api.cmd(userinfo_dbname,'SELECT',sql_str)
	if not ok_status or result == nil then
	    only.log('E',string.format("newmobile:%s  sl_userinfo failed! sql_str:%s",newmobile, sql_str))
	    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #result ~= 0 then
		only.log("E", " newmobile alread bind. sql_str: %s", sql_str)
		gosay.go_false(url_info, msg["MSG_ERROR_MOBILE_ALREAD_BIND"])
	end

	-- 2)验证手机是否已经注册userRegister
	local sql_str = string.format(G.sl_userRegister, newmobile)
	local ok,result = mysql_api.cmd(user_center_dbname,'SELECT',sql_str)
	if not ok or result == nil then
		only.log('E',string.format("newmobile:%s  sl_userRegister failed!,sql_str:%s",newmobile, sql_str ))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	local time = os.time()

	if #result ~= 0 then
		only.log("E", "newmobile alresd register, newmobile = %s ", newmobile)
		gosay.go_false(url_info, msg["MSG_ERROR_MOBILE_ALREAD_REGISTER"])
	end

	-- 3)验证accountID是否存在userList
	local sql = string.format(G.sl_userList_aid, accountID)
	local ok,result = mysql_api.cmd(user_center_dbname,'SELECT',sql)
	if not ok or result == nil then
		only.log('E',string.format("accountID:%s  sl_userList_aid failed!,sql:%s",accountID, sql ))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #result == 0 then
		only.log("E", "accountID not exists , sql:%s ", sql)
		gosay.go_false(url_info, msg['MSG_ERROR_ACCOUNT_ID_NO_SERVICE'] )
	end

	-- 4)验证accountID是否存在userRegisterInfo
	local sql = string.format(G.sl_userRegister_aid, accountID)
	local ok,result = mysql_api.cmd(user_center_dbname,'SELECT',sql)
	if not ok or result == nil then
		only.log('E',string.format("accountID:%s  sl_userRegister_aid failed!,sql:%s",accountID, sql ))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #result ~= 0 then
		only.log("D", "accountID alread register , sql:%s ", sql)
		return false
	else
		-- 5)为新用户绑定手机号
		local sql_stp = string.format(G.inster_userRegister, accountID, time, newmobile)
		local ok,result = mysql_api.cmd(user_center_dbname,'INSERT',sql_stp)
		if not ok or result == nil then
			only.log('E',string.format("newmobile:%s  sl_userinfo failed!sql_stp:%s",newmobile, sql_stp))
			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
		end
		return true
	end
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
	-- 1)检查参数并判断用户名类型
	check_parameter(args)
	-- 2)根据用户名得到账户编号
	local accountID = nil
	local flag_mobile = nil
	if args["mobile"] and args["mobile"] ~= "" then
		accountID = get_accountID_by_mobile( args["mobile"] )
		flag_mobile = "mobile"
	else
		accountID = args["accountID"]
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

	-- 3)验证手机是否已经注册,绑定
	local inst_ok = check_mobile( args["newmobile"], accountID )

	-- 4)更新数据库
	update_user_mobile( args["newmobile"], accountID, inst_ok )

	gosay.go_success( url_info, msg['MSG_SUCCESS'] )
end

safe.main_call( handle )


