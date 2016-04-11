-- jiang z.s.
-- 2014-07-30
-- 用于发送微博
-- parameterType
-- 1 accountID
-- 2 phoneNumber
-- 3 IMEI


local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local weibo     = require('weibo')
local appfun    = require('appfun')
local app_cfg   = require('clientcustom_cfg')


local appKey = app_cfg.OWN_INFO.appconnect_cfg.appKey
local secret = app_cfg.OWN_INFO.appconnect_cfg.secret


local weiboServer = link.OWN_DIED.http.weiboServer

local userlist_dbname = 'app_usercenter___usercenter'

local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}

local G = {
	sql_get_account_by_phone = " SELECT accountID from userRegisterInfo where mobile = %s and checkMobile = 1 and validity = 1 limit 1  ",
}

-->chack parameter
local function check_parameter(args)

	local parameter_type = tonumber(args['parameterType']) or 1
	if not ( parameter_type >= 1 and parameter_type <= 3 ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameterType')
	end

	if parameter_type == 1 and not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	elseif parameter_type == 2 and #tostring(args['accountID']) ~= 11 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	elseif parameter_type == 3 and #tostring(args['accountID']) ~= 15 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if not args['accountID'] or string.find(args['accountID'],"'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if not args['multimediaURL'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'multimediaURL')
	end

	if not args['callbackURL'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'callbackURL')
	end

	local level = tonumber(args['level']) or 0
	if level <= 0 or level > 99 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'level')
	end

	local interval = tonumber(args['interval']) or 0
	if interval <= 0 or interval > 7*24*60*60 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'interval')
	end
	safe.sign_check(args, url_tab)
end


---- 发送个人微博
local function send_personal_weibo ( args, receiver_account_id )
	local tab        = {
		appKey            = appKey,
		level             =  args['level'],
		interval          = args['interval'] ,
		multimediaURL     = args['multimediaURL'],
		callbackURL       = args['callbackURL'],
		receiverAccountID = receiver_account_id,
		senderType        = 2,
	}

	if tonumber(tab['level']) >= 19 then
		-- modify by jiang z.s. 
		-- 针对家人连线的微博等级调整
		-- 频道为20,回复为19,需要调整为18
		tab['level'] = 18
	end

	---- return 
	---- 1 status true / false
	---- 2 status RESULT detail

	return weibo.send_weibo(weiboServer,'personal', tab, appKey, secret)
end


local function get_account_id_by_phone( temp_phone_num )
	local sql_str = string.format(G.sql_get_account_by_phone,temp_phone_num)
	local ok,ret = mysql_api.cmd(userlist_dbname,'SELECT', sql_str)
	if not ok or not ret then
		only.log('E',sql_str)
		only.log('E','sql_get_account_by_phone:%s===failed!',temp_phone_num)
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	if #ret ~= 1 then
		only.log('E','MSG_ERROR_NOT_MOBILE_AUTH:%s===failed!',temp_phone_num)
		gosay.go_false(url_tab,msg['MSG_ERROR_NOT_MOBILE_AUTH'])
	end
	local tmp_account_id = ret[1]['accountID']
	local ok,ret = redis_api.cmd('private','get',tmp_account_id .. ":IMEI")
	if not ok then
		only.log('E',string.format('sql_get_imei_by_accountid:%s===failed!',tmp_account_id))
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	if not ret or #tostring(ret) ~= 15 then
		gosay.go_false(url_tab,msg['MSG_ERROR_IMEI_HAS_NOT_BIND'])
	end
	return true,tmp_account_id
end


local function get_account_id_by_imei( temp_imei )
	local ok,ret  = redis_api.cmd('private','get', temp_imei .. ":accountID")
	if not ok then
		only.log('E',string.format('sql_get_accountid_by_imei:%s===failed!',temp_imei))
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	if not ret then
		only.log('D',string.format('sql_get_accountid_by_imei:%s===account_id is nil!',temp_imei))
		gosay.go_false(url_tab,msg['MSG_ERROR_IMEI_HAS_NOT_BIND'])
	end
	return true,ret
end

-- local function check_user_set_custom_info( account_id )
-- 	local ok,ret = redis_api.cmd('private','get',account_id .. ":voiceCommandCustomType")
-- 	if ok and ret then
-- 		ret = tonumber(ret) or 1
-- 		---- 微信,app家人连线合并为一处 2014-08-21 
-- 		if ret == appfun.VOICE_COMMAND_APP_CONNECT or ret == appfun.VOICE_COMMAND_WECHAT then
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end

local function check_user_set_custom_info( account_id )
	---- [中间吐槽按键]判断是否为家人连线 2015-05-30
	local ok,ret = redis_api.cmd('private','get',account_id .. ":mainVoiceCustomType")
	if ok and ret then
		---- 必须是家人连线才有用
		if (tonumber(ret) or 0 ) == appfun.DEFAULT_VOICE_TYPE_APPCON then
			return true
		end
	end
	only.log('W',string.format(" account_id:%s mainVoiceCustomType:%s , set is invalid ", account_id , ret ))
	return false
end


local function handle()
	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	local req_head = ngx.req.raw_header()

	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_tab['client_host'] = req_ip
	url_tab['client_body'] = req_body

	local req_method = ngx.var.request_method
	local args = nil
	if req_method == 'POST' then
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')
      	if not boundary then
			args = utils.parse_url(req_body)
			-- args = ngx.decode_args(req_body)
		else
			args = utils.parse_form_data(req_head, req_body)
		end
	end

	if not args or type(args) ~= "table" then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"")
	end

	for i,v in pairs(args) do
		only.log('D',string.format("%s  %s",i,v))
	end

	url_tab['app_key'] = args['appKey']
	check_parameter(args)


	local tmp_account_id  = args['accountID']
	local parameter_type = tonumber(args['parameterType']) or 1


	only.log('D',string.format("parameter_type:%s account_id:%s--->----",parameter_type, tmp_account_id))

	-- 1 accountID
	-- 2 phoneNumber
	-- 3 IMEI

	local ok_status,account_id = nil,nil
	if parameter_type == 1 then
		ok_status,account_id = true,tmp_account_id
	elseif parameter_type == 2 then
		ok_status,account_id = get_account_id_by_phone(tmp_account_id)
	elseif parameter_type == 3 then
		ok_status,account_id = get_account_id_by_imei(tmp_account_id)
	end
	
	if not ok_status or not account_id then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	local ok_status = check_user_set_custom_info(account_id)
	if not ok_status then
		---- MSG_ERROR_VOICECOMMAND_NOT_SETTING
		---- weme未设置+键为app连线
		gosay.go_false(url_tab, msg['MSG_ERROR_VOICECOMMAND_NOT_SETTING'])
	end

	local ok_status,result = send_personal_weibo ( args, account_id )

	if type(result) == "table" then
		for i,v in pairs(result) do
			only.log('D',string.format("result table: %s-->----%s",i,v))
		end
	end

	if ok_status and type(result) == "table" then
		local str = string.format('{"bizid":"%s"}',result['bizid'])
    		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
    	else
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],result)
    	end

end

safe.main_call( handle )
