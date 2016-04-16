-- zhouzhe
-- 2015-07-28
-- 判定手机号是否符合注销要求并获取注销验证码

local msg   		= require('msg')
local safe  		= require('safe')
local only  		= require('only')
local link      	= require('link')
local gosay 		= require('gosay')
local utils 		= require('utils')
local cjson     	= require('cjson')
local cutils    	= require('cutils')
local app_utils 	= require('app_utils')
local mysql_api 	= require('mysql_pool_api')
local http_api 	= require('http_short_api')

local usercenter_dbname = "app_usercenter___usercenter"

local sms_srv_php = link["OWN_DIED"]["http"]["sendSmsPHP"]
local sms_srv = link["OWN_DIED"]["http"]["sendSMS"]

-- 平台编号
local platform= 1
-- 模板id
local templateID = 21109
local crl_time = os.time()

local G = {
	---- 用户信息表中检验用户信息，用户是否绑定imei
	sql_get_accountid_info = "SELECT imei, accountID FROM userLoginInfo WHERE mobile = '%s'",
	---- 用户是否已经绑定第三方账号
	sql_check_accountid_thired = "SELECT 1 FROM thirdAccessOauthInfo WHERE accountID = '%s'",
	---- check userDynamicVerifycode
	check_auth_code = "SELECT 1 FROM userDynamicVerifycode WHERE  mobile = '%s' AND validity = 1 ", 
	---- insert userDynamicVerifycode
	save_dynamic_code = "insert into userDynamicVerifycode ( mobile, content, checkMobile, createTime , updateTime, validity)" .. 
	                      " value ( '%s', '%s', 1, '%s', '%s', 1 ) ", 
	---- update userDynamicVerifycode
	update_dynamic_code = " update userDynamicVerifycode set content = '%s', updateTime = '%s' "..
							" where mobile = '%s' and  validity = 1 ",
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
		only.log("E", "mobile is error")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
	end

	safe.sign_check(args, url_info)
end

---- 创蓝等接口
local function send_sms_lan(content )
    local data_fmt = 'POST /webapi/v2/sendSms HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Length:%d\r\n' ..
    'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv['host'], sms_srv['port'], #content, content)
    local ret = http_api.http(sms_srv, data, true)
    if not ret then
        only.log('E',string.format("req data: %s",data))
        return nil 
    end

    local body = string.match(ret, '{.+}')
    if not body then
        only.log('E',string.format('ret  = %s ' , ret  ) )
        return nil
    end

    local ok, json_data = utils.json_decode(body)

    if not ok or tonumber(json_data['ERRORCODE'])~=0 then
        return nil
    else
        return json_data['RESULT']['bizid']
    end
end


---- 云通信
local function send_sms_yun(content)

    local data_fmt = 'POST /sendSMS/index.php HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Length:%d\r\n' ..
    'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv_php['host'], sms_srv_php['port'], #content, content)

    local ok,ret = cutils.http(sms_srv_php['host'], sms_srv_php['port'], data, #data)
    if not ok then
        only.log("E", "sendSms filed")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "sendSms")
    end

    if not ret then
        only.log('E',string.format("return data: %s",data))
        return false
    end

    local body = string.match(ret, '{.+}')
    only.log('D',string.format('body  = %s ' , body  ) )
    if not body then
        only.log('E',string.format('==ret: %s ' , ret  ) )
        return false
    end
    local ok, json_data = utils.json_decode(body)
    only.log('D',string.format('ERRORCODE  = %s ', json_data['ERRORCODE']))

    if not ok or tonumber(json_data['ERRORCODE'])~= 000000 then
        return false
    elseif tonumber(json_data['ERRORCODE']) == 160021 then
        only.log("W", "Same content in the same cell phone can only be issued once")
        return false
    else
        return true
    end
end

---- 选择平台发送短信
local function send_sms(appKey, mobile, pwd )
    if platform == 1 then
        local txt = string.format("验证码为:%s 有效期10分钟", pwd)
        local tab = {
            ['mobile'] = mobile,
            ['content'] = txt,
            ['appKey'] = appKey,
        }
        tab['sign'] = app_utils.gen_sign(tab)
        local content = utils.table_to_kv(tab)
        local ok = send_sms_lan(content )
        return ok
    else
        local tab = {
            ['phone'] = mobile,
            ['code'] = pwd,
            ['time'] = 10,
            ['templateID'] = templateID,
        }
        local content = utils.table_to_kv(tab)
        local ok = send_sms_yun(content )
        return ok
    end
end

-- 记录验证码和手机号信息
local function save_cancellation_code(appKey, mobile, code)

    local ok = send_sms(appKey, mobile, code )
    if not ok then
        only.log('E',string.format("send sms failed, mobile=%s ", mobile))
        gosay.go_false(url_info, msg['MSG_ERROR_SMS_SEND_FAILED'])
    end

    -- 1) 判断 当前手机号是否生成过 记录
    local sql_tmp = string.format( G.check_auth_code, mobile )
    local ok, result = mysql_api.cmd(usercenter_dbname, 'SELECT', sql_tmp)

    if not ok or not result then
        only.log('E', string.format('check user register failed !') )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result < 1 then
        ---- 1.1 没有生成记录,插入一条记录到数据库
        local sql_code = string.format(G.save_dynamic_code, mobile , code, crl_time, crl_time )
        local ok, result = mysql_api.cmd(usercenter_dbname, 'INSERT', sql_code)
        if not ok or not result  then
            only.log('E', string.format("insert user record failed , %s" , sql_code))
            gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
        end
    else
        ---- 1.2 原来生成过记录,更新数据库记录
        local sql_code = string.format(G.update_dynamic_code , code , crl_time, mobile )
        local ok = mysql_api.cmd(usercenter_dbname, 'UPDATE', sql_code)

        if not ok then
            only.log('E', string.format("update user record failed , %s" , sql_code) )
            gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
        end
    end
end

-- 检查用户是否存在
local function check_accountid( mobile )

	-- 1）判断是否是有效用户
	local sql1 = string.format(G.sql_get_accountid_info, mobile )
	local ok, ret = mysql_api.cmd(usercenter_dbname, 'select', sql1 )
	if not ok or not ret then
		only.log("E", string.format( "get_user_accountid==mysql is error, mobile=%s", mobile ))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
	end

	if #ret < 1 or type(ret) ~= "table" then
		only.log("E", "Mobile user is not exist!")
		gosay.go_false(url_info, msg['MSG_ERROR_USER_NAME_NOT_EXIST'] )
	end
	local accountID = ret[1]['accountID']
	local IMEI = ret[1]['imei']
	if #IMEI==15 then
		only.log("E", "mobile has bind imei")
		gosay.go_false(url_info, msg['MSG_ERROR_IMEI_HAS_BIND'])
	end

	-- 4) 检查是否为第三方用户
	local sql1 = string.format(G.sql_check_accountid_thired, accountID )
	local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql1 )
	if not ok then
		only.log("E", "mysql check accountID is error")
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'] )
	end
	if #result > 0 then
		only.log("E", "mobile already bind third account")
		gosay.go_false(url_info, msg['MSG_ERROR_IS_THIRD_ACCOUNT'])
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

	-- 2) 检查账号是否符合注销要求
	check_accountid( args['mobile'] )

	local code = utils.random_number(6)
	only.log("D", string.format("==[code]==[%s]===[mobile]==%s", code, args['mobile']))
	-- 3) 记录验证码和手机号信息
	save_cancellation_code(args['appKey'], args['mobile'], code)

	gosay.go_success( url_info, msg["MSG_SUCCESS"] )
end

safe.main_call( handle )
