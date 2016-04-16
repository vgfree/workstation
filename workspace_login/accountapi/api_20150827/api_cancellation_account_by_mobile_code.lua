-- zhouzhe
-- 2015-07-28
-- 校验验证码和手机号注销账号

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
	-- 1) 校验验证码和时间
	sql_check_userDynamicVerifycode = " SELECT updateTime, content FROM userDynamicVerifycode WHERE validity=1 AND mobile=%s  ",

	-- 2) 获取userinfo信息
	sclect_user_info = "SELECT accountID, status, checkMobileTime, idNumber FROM userInfo WHERE mobile='%s'",

	-- 3) 更新注销userInfo
	update_user_info = " UPDATE userInfo SET accountID='%s', mobile='', checkMobileTime='', idNumber='', status=2 WHERE accountID='%s'",

	-- 4) 更新注销userlist
	update_list_info = " UPDATE userList SET accountID = '%s', userStatus=0, updateTime = %d WHERE accountID = '%s'",

	-- 5) 更新注销userReginter
	update_cancel_register = " UPDATE userRegisterInfo SET accountID='%s', mobile = '%s', checkMobile = 0,"..
								" validity = 0 WHERE accountID = '%s' AND validity = 1",
	-- 6) 失败回滚userinfo信息
	return_update_user_info = " UPDATE userInfo SET accountID='%s', status=%d, mobile='%s', checkMobileTime='%s',"..
							" idNumber='%s' WHERE accountID='%s'",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 临时存储userinfo信息
local table_info = {
	accountID = nil,
	status = nil,
	checkMobileTime = nil,
	idNumber = nil,
}

-- 检查参数
local function check_parameter( args )

	if not args['appKey'] or #args['appKey'] > 10 then
		only.log("E", "appKey is error")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "appKey")
	end

	url_info['app_key'] = args['appKey']

	local mobile = args['mobile']

	if not mobile  or (string.len(mobile) ~= 11) or (not utils.is_number(mobile)) or (utils.is_number(string.sub(mobile, 1, 1)) ~= 1) then
		only.log("E", "mobile is error")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
	end

	if not args['code'] and #args['code']~=6 then
		only.log("E", "code is eror")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'code')
	end

	safe.sign_check(args, url_info)
end

-- 检查用户是否存在
local function get_user_info( mobile, verifycode )

	-- 2) 查询userinfo表信息并临时备份  accountID, status, checkMobileTime, idNumber
	local sql1 = string.format(G.sclect_user_info, mobile )
	local ok, res = mysql_api.cmd(client_daname, 'select', sql1 )

	if not ok or not res then
		only.log("E", string.format( "sclect_user_info mysql is error, mobile==%s", mobile ))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
	end
	if #res <1 or type(res)~="table" then
		only.log("E", string.format("sclect_user_info, mobile=%s", mobile))
		go_false(url_info, msg['MSG_ERROR_REQ_ARG'], mobile )
	end
	-- 临时存储
	table_info['accountID'] = res[1]['accountID']
	table_info['status'] = res[1]['status']
	table_info['checkMobileTime'] = res[1]['checkMobileTime']
	table_info['idNumber'] = res[1]['idNumber'] or ''

	-- 校验验证码和时间
	local sql_str = string.format(G.sql_check_userDynamicVerifycode, mobile)
	local ok, result = mysql_api.cmd(usercenter_dbname, 'SELECT', sql_str)
	if not ok or not result then
		only.log('E', string.format(" sql_check_userDynamicVerifycode  mysql failed, %s", sql_str ))
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #result <1 or type(result) ~= "table" then
		only.log('E', string.format("#result = %s", #result ))
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], 'mobile')
	end

	local new_time = crl_time - 600  -- 有效期十分钟
	local upd_time = result[1]['updateTime']
	local user_code = result[1]['content']
	if new_time > tonumber(upd_time) then
		only.log('E', string.format("mobile==%s ==verifycode=%s verifycode expired ", mobile , verifycode ) )
		gosay.go_false(url_info,msg['MSG_ERROR_VERIFYCODE_EXPIRE'] )
	end

	if tonumber(user_code) ~= tonumber(verifycode)then
		only.log('E', string.format("verifycode is error!" ) )
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'verifycode')
	end
end

local function return_user_info(account_id)
	local sql_info = string.format(G.return_update_user_info, table_info['accountID'], table_info['status'],
									 table_info['checkMobileTime'], table_info['idNumber'], account_id )
	local ok = mysql_api.cmd(client_daname, 'update', sql_info)
	only.log("D", string.format("return_update_user_info==sql_info=%s", sql_info))
	if not ok then
		only.log("E", "update cancel userinfo is failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
end

-- 注销账号
local function cancel_account( )

	local account_id = table_info['accountID']
	local accountID = '9'..string.sub(tostring(crl_time),2 ) 
	local mobile = '9'..tostring(crl_time)

	-- 5) 更新userinfo status
	local sql_info = string.format(G.update_user_info, accountID, account_id )
	local ok = mysql_api.cmd(client_daname, 'update', sql_info)
	only.log("D", string.format("=update_user_info==sql_info=%s",sql_info))
	if not ok then
		only.log("E", "update cancel userinfo is failed")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	sql_tab = {}
	-- 6) 更新userlist
	local sql_list = string.format(G.update_list_info, accountID, crl_time, account_id)
	-- 7）更新userRegister
	local sql_register = string.format(G.update_cancel_register, accountID, mobile, account_id )

	table.insert(sql_tab, sql_list)
	table.insert(sql_tab, sql_register)
	local ok = mysql_api.cmd(usercenter_dbname,'affairs', sql_tab)
	only.log("D", string.format("=update_user_info==sql_list=%s==\r\n=sql_register==%s",sql_list, sql_register))
	if not ok then
		only.log("E", "cancel account failed")
		-- 回滚userinfo数据
		return_user_info(accountID)
		gosay.go_false(url_info, msg['MSG_ERROR_CANCELL_ACCOUNT_FAILED'])
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
	check_parameter(args)

	-- 2) 获取userinfo信息并临时存储
	get_user_info( args['mobile'], args['code'] )

	-- 3) 注销用户
	cancel_account()

	gosay.go_success( url_info, msg["MSG_SUCCESS"] )
end

safe.main_call( handle )


