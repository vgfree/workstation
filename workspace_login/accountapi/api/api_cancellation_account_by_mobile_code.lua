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
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

usercenter_dbname = "app_usercenter___usercenter"

local crl_time = os.time()

local G = {
	-- 1) 校验验证码和时间
	sql_check_userDynamicVerifycode = " SELECT updateTime, content FROM userDynamicVerifycode WHERE validity=1 AND mobile=%s  ",

	---- 获取用户accountID
	get_accountid_by_mobile = "SELECT accountID FROM userLoginInfo WHERE userStatus=1 AND mobile = '%s' ",

	---- 注销用户信息userLoginInfo
	update_userlogin_info = "UPDATE userLoginInfo SET accountID = '%s', userStatus=0, mobile=%s,remark='%s',"..
							"updateTime = %d WHERE accountID = '%s' AND mobile='%s'",

	---- 注销用户信息userGeneralInfo
	update_general_info = "UPDATE userGeneralInfo SET accountID = '%s', userStatus=0, updateTime = %d, remark='%s' WHERE accountID = '%s'",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
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
		---- modify by jiang z.s. 2015-10-04 optimize log 
		only.log("W", "mobile is error, %s ", mobile )
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
	end

	if not args['code'] or #args['code']~=6 then
		only.log("W", "code is eror, %s ", args['code'])
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'code')
	end

	safe.sign_check(args, url_info)
end

-- 检查用户是否存在
local function get_user_info( mobile, verifycode )

	-- 校验验证码和时间
	local sql_str = string.format(G.sql_check_userDynamicVerifycode, mobile)
	local ok, result = mysql_api.cmd(usercenter_dbname, 'SELECT', sql_str)
	if not ok or not result then
		only.log('E', string.format(" sql_check_userDynamicVerifycode  mysql failed, %s", sql_str ))
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #result <1 or type(result) ~= "table" then
		only.log('E', string.format("sql_check_userDynamicVerifycode  get code by mobile , records < 1  , %s ", sql_str ))
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], 'mobile')
	end

	local new_time = crl_time - 600  -- 有效期十分钟
	local upd_time = result[1]['updateTime']
	local user_code = result[1]['content']
	if new_time > tonumber(upd_time) then
		only.log('W', string.format("mobile==%s ==verifycode=%s verifycode expired ", mobile , verifycode ) )
		gosay.go_false(url_info,msg['MSG_ERROR_VERIFYCODE_EXPIRE'] )
	end

	if tonumber(user_code) ~= tonumber(verifycode)then
		only.log('W', string.format("verifycode:%s do not match database %s " , verifycode,  user_code ) )
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'verifycode')
	end

	---- 获取accountID
	local sql1 = string.format(G.get_accountid_by_mobile, mobile )
	only.log("D", string.format("get accountID by mobile ===%s", sql1))
	local ok, res = mysql_api.cmd(usercenter_dbname, 'select', sql1 )

	if not ok or not res then
		only.log("E", string.format( "sclect_user_info mysql is error, mobile==%s, %s ", mobile , sql1 ))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
	end
	if #res ~= 1 or type(res)~="table" then
		only.log("E", string.format("sclect_user_info, mobile=%s ", mobile))
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile' )
	end
	return res[1]['accountID']
end

-- 注销账号
local function cancel_account( account_id, mobile )

	local accountID = '9'..string.sub(tostring(crl_time),2 )
	local Mobile = '9'..tostring(crl_time)
	local sql_tab = {}
	
	-- 5) 注销用户login
	local sql = string.format(G.update_userlogin_info, accountID, Mobile, '用户注销'..account_id..mobile, crl_time, account_id, mobile )
	table.insert(sql_tab, sql)

	local sql = string.format(G.update_general_info, accountID, crl_time, '用户注销'..account_id, account_id)
	table.insert(sql_tab, sql)

	local ok = mysql_api.cmd(usercenter_dbname,'affairs', sql_tab)
	only.log("D", string.format("====cancel debug info====sql:====%s==", table.concat( sql_tab, "\r\n" )) )
	if not ok then
		only.log("E", "cancel account failed, %s ",  table.concat( sql_tab, "\r\n" ))
		gosay.go_false(url_info, msg['MSG_ERROR_CANCELL_ACCOUNT_FAILED'])
	end
	---- del redis
	redis_api.cmd('private', 'del', account_id .. ':nicknameURL')
	redis_api.cmd('private', 'del', account_id .. ':nickname')
	only.log("D", "del redis nicknameURL & nickname")
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
	local accountID = get_user_info( args['mobile'], args['code'] )

	-- 3) 注销用户
	cancel_account( accountID, args['mobile'] )

	gosay.go_success( url_info, msg["MSG_SUCCESS"] )
end

safe.main_call( handle )


