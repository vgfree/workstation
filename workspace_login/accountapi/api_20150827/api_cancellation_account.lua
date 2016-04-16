-- zhouzhe
-- 2015-07-07
-- 注销用户或解除账号和手机号关系

local msg   = require('msg')
local safe  = require('safe')
local only  = require('only')
local gosay = require('gosay')
local utils = require('utils')
local cjson     = require('cjson')
local link      = require('link')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

usercenter_dbname = "app_usercenter___usercenter"
client_daname   = "app_cli___cli"

local crl_time = os.time()

local G = {

	-- 1) userlist
	check_accountid_list = " SELECT 1 FROM userList WHERE accountID = '%s' ",
	-- 2) userRegister
	get_user_accountid = " SELECT accountID, username, userEmail, checkUserEmail FROM  userRegisterInfo WHERE mobile ='%s' AND checkMobile = 1 ",
	-- 2) loginType
	check_login_type = " SELECT 1 FROM loginType WHERE accountID = '%s' ",

	--==== 注销用户===
	-- 3) 更新userlist
	update_list_info = " UPDATE userList SET accountID = '%s', userStatus = 0, updateTime = %d, imei = '' WHERE accountID = '%s' ",
	-- 4) 更新userReginter
	update_cancel_register = " UPDATE userRegisterInfo SET accountID='%s', mobile = '%s', checkMobile = 0, validity = 0 WHERE accountID = '%s' AND validity = 1",
	-- 5) 更新loginType
	update_login_type = " UPDATE loginType SET accountID = '%s', userStatus=0, remarks = '%s' WHERE accountID = '%s'  ",
	-- 6) 更新userInfo
	update_user_info = " UPDATE userInfo SET accountID = '%s', mobile = '', checkMobileTime='', idNumber = '', userEmail='' WHERE accountID = '%s' ",

	--==== 解除手机号关联===
	-- 7) 更新userReginter
	update_release_register = " UPDATE userRegisterInfo SET mobile='%s', checkMobile=0 WHERE accountID='%s' AND validity=1",
	-- 8) 更新userInfo
	update_release_userinfo = " UPDATE userInfo SET mobile = '', checkMobileTime='' WHERE accountID = '%s' ",

}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 检查参数
local function check_parameter( args )
	if not args['appKey'] or #args['appKey'] ~= 10 then
		only.log("E", "appKey is error")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "appKey")
	end

	url_info['app_key'] = args['appKey']
	safe.sign_check(args, url_info)

	local mobile = args['mobile']
	local accountID = args['accountID']
	if accountID and #accountID > 0 then
		if not accountID or not app_utils.check_accountID( accountID ) then
			only.log("E", "accountID is error")
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
		end
		return 1
	-- end
	elseif mobile and #mobile > 0 then
		if not mobile  or (string.len(mobile) ~= 11) or (not utils.is_number(mobile)) or (utils.is_number(string.sub(mobile, 1, 1)) ~= 1) then
			only.log("E", "mobile is error")
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
		end
		return 2
	-- end
	else
		only.log("E", "mobile and accountID is error")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'username')
	end
end

-- 检查用户是否存在
local function check_accountid( args, status )
	local accountID = nil
	local thi_user = false
	-- 解除关联
	if tonumber(status) == 2 then 
		-- 2）userRegister
		local sql = string.format(G.get_user_accountid, args['mobile'] )
		local ok, ret = mysql_api.cmd(usercenter_dbname, 'select', sql)
		if not ok or not ret then
			only.log("E", "accountID is error")
			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
		end

		if #ret < 1 then
			only.log("E", "Mobile number is not connection with the account")
			gosay.go_false(url_info, msg['MSG_ERROR_MOBILE_NOT_CONNECT_ACCOUNT'] )
		end

		if  type(ret) ~= "table" then
			only.log("E", "return data is error")
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "return data" )
		end
		-- 3) 检查是否为第三方用户
		local sql = string.format(G.check_login_type, ret[1]['accountID'] )
		local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql)
		if not ok or not result then
			only.log("E", "mysql check accountID is error")
			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
		end
		if #result > 0 then
			-- only.log("D", "len_result=%s", #result)
			thi_user = true
		end

		-- 是否为非第三方手机用户
		if not thi_user and not ret[1]['username'] and #ret[1]['username'] < 1 then
			if not ret[1]['userEmail'] and #ret[1]['userEmail'] < 1 then
				only.log("E","Mobile phone users is not release account connection ")
				gosay.go_false("E", msg['MSG_ERROR_MOBILE_USER_NOT_RELEASE_CONNECT'])
			end
		end
		accountID = ret[1]['accountID']
		args['accountID'] = nil
	end

	-- 注销用户
	if tonumber(status) == 1 or accountID then
		if args['accountID'] then
			local sql = string.format(G.check_login_type, args['accountID'] )
			local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql)
			if not ok or not result then
				only.log("E", "check_login_type accountID is error")
				gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
			end
			if #result > 0 then
				only.log("D", "len_result=%s", #result)
				thi_user = true
			end
		end
		-- 2）userlist
		local sql = string.format(G.check_accountid_list, args['accountID'] or accountID )
		local ok, ret = mysql_api.cmd(usercenter_dbname, 'select', sql)
		if not ok or not ret then
			only.log("E", "accountID is error")
			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
		end

		if #ret < 1 then
			only.log("E", "user is not exists or mysql is error")
			gosay.go_false(url_info, msg['MSG_ERROR_USER_NAME_NOT_EXIST'] )
		end
	end
	return accountID or args['accountID'], thi_user
end

-- 注销账号
local function cancel_account( account_id, thi_user )

	local accountID = '9'..string.sub(tostring(crl_time),2 ) 
	local mobile = '9'..tostring(crl_time)
	sql_tab = {}
	-- 3) 更新userlist
	local sql_list = string.format(G.update_list_info, accountID, crl_time, account_id)
	-- 4）更新userRegister
	local sql_register = string.format(G.update_cancel_register, accountID, mobile, account_id )

	if thi_user then
		-- 5) 更新loginType
		local remarks = account_id.."注销用户"
		local sql_login = string.format(G.update_login_type, accountID, remarks, account_id )
		table.insert(sql_tab, sql_login)
	end
	table.insert(sql_tab, sql_list)
	table.insert(sql_tab, sql_register)
	local ok = mysql_api.cmd(usercenter_dbname,'affairs', sql_tab)

	if not ok then
		only.log("E", "cancel user failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	-- 6) 更新userinfo status
	local sql_info = string.format(G.update_user_info, accountID, account_id )
	local ok = mysql_api.cmd(client_daname, 'update', sql_info)
	if not ok then
		only.log("E", "update cancel userinfo is failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
end

-- 解除账号和手机号关联
local function release_account_connect( account_id )
	local mobile = '9'..tostring(crl_time)
	-- 7) 更新userRegister
	local sql = string.format(G.update_release_register, mobile, account_id )
	local ok = mysql_api.cmd(usercenter_dbname, 'update', sql)
	if not ok then
		only.log("E", "update release register is failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
	-- 8)更新userinfo
	local sql = string.format(G.update_release_userinfo, account_id )
	local ok = mysql_api.cmd(client_daname, 'update', sql)
	if not ok then
		only.log("E", "update release userinfo is failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
end

local function handle()
	local body = ngx.req.get_body_data()
	local ip = ngx.var.remote_addr

	if not body then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_info['client_host'] = ip
	url_info['client_body'] = body

	local args = utils.parse_url(body)

	-- 1) 参数检查
	local status = check_parameter(args)
	-- only.log("D","status=%s",status)
	-- 2) 检查账号是否合法
	local account_id, thi_user = check_accountid( args, status )
	if status == 1 then
		-- 3) 注销用户
		cancel_account( args['accountID'], thi_user )
	else
		-- 4）取消用户手机号关联
		release_account_connect(account_id )
	end
	gosay.go_success( url_info, msg["MSG_SUCCESS"] )
end

safe.main_call( handle )


