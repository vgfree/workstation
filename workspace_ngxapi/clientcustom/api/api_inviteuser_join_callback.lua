-- jiang z.s.
-- 2014-07-30
-- customType = 1 
-- 邀请用户加入临时频道


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


local appKey = app_cfg.OWN_INFO.inviteuser_cfg.appKey
local secret = app_cfg.OWN_INFO.inviteuser_cfg.secret


local weiboServer = link.OWN_DIED.http.weiboServer


---- 邀请频道频率控制(s)  10*60 
---- 2014-11-14 jiang z.s. 
local INVITEUSER_FREQUENCY_TIME = 600


local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}


-->chack parameter
local function check_parameter(args)
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
    safe.sign_check(args, url_tab)
end


---- 用户存在临时频道则不邀请
local function check_user_exists_tempchannel( account_id )
	local ok,ret = redis_api.cmd('private','get', account_id .. ":tempChannel:groupVoice")
	if ok and ret then
		return true
	end
	return false
end

---- 发送个人微博
local function send_personal_weibo( sender_account_id, file_url, callback_url, receiver_account_id )
	local tab        = {
		appKey            = appKey,
		level             = 19,
		interval          = 300,
		senderAccountID   = sender_account_id,
		multimediaURL     = file_url,
		callbackURL       = callback_url,
		receiverAccountID = receiver_account_id,
		senderType        = 2,
	}
	---- return 
	---- 1 status true / false
	---- 2 status RESULT detail
	return weibo.send_weibo(weiboServer,'personal', tab, appKey, secret)
end


---- 邀请频道记录,限制使用频率
local function inviteuser_check_frequency(  temp_channel_id )
	local ok,ret = redis_api.cmd('private','get',temp_channel_id .. ":inviteUserTimestamp")
	ret = tonumber(ret) or 0
	if ngx.time() - ret > INVITEUSER_FREQUENCY_TIME then
		return true,0
	end
	return false, (ngx.time() - ret )
end

---- 邀请成功,设在本次邀请的时间
local function inviteuser_set_frequency_timestamp(temp_channel_id)
	redis_api.cmd('private','set',temp_channel_id .. ":inviteUserTimestamp",ngx.time())
end

local function inviteuser_check_mode( temp_channel_id )
	local ok , ret = redis_api.cmd('private','get', temp_channel_id .. ":channelSoundMode")
	if ok and ret then
		if tonumber(ret) == 0 then
			return true
		end
	end
	return false
end


---- 邀请用户加入临时频道
local function inviteuser_join_tempchannel( args )
	local sender_account_id = args['accountID']
	local temp_channel_id   = args['tempChannelID'] 
	local file_url          = args['multimediaURL'] 
	local callback_url      = args['callbackURL']

	if not inviteuser_check_mode(temp_channel_id) then
		only.log('D',string.format("%s must channelSoundMode is forbid", temp_channel_id))
		gosay.go_false(url_tab, msg['MSG_ERROR_TEMPCHANNEL'])
	end

	local ok,val = inviteuser_check_frequency(temp_channel_id)
	if not ok then
		only.log('D',string.format("%s must delay %s", temp_channel_id, val ))
		gosay.go_false(url_tab, msg['MSG_ERROR_CONTROL_FREQUENCY'],val)
	end

	if not callback_url or #tostring(callback_url) < 8 or string.sub(string.lower(callback_url),1,4) ~= "http"  then
		return false,"callbackURL"
	end
	if not file_url or #tostring(file_url) < 8 or string.sub(string.lower(file_url),1,4) ~= "http"  then
		return false,"multimediaURL"
	end
	local tmp = string.match(temp_channel_id,'%d+')
	if not tmp or tostring(tmp) ~= temp_channel_id then
		return false,"tempChannelID"
	end
	if #tmp < 5 or #tmp > 8 then
		return false,"tempChannelID"
	end

	local ok,ret = redis_api.cmd('statistic','smembers',string.format("%s:channelOnlineUser",temp_channel_id))
	if not ok or not ret then
		only.log('E',"connect redis failed when get channelOnlineUser ")
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	local temp_tab = {}
	for i,v in ipairs(ret) do
		temp_tab[tostring(v)] = tostring(v)
	end

	local ok,online_tab = redis_api.cmd('statistic','smembers',"onlineUser:set")
	if not ok or not online_tab then
		only.log('E',"connect redis failed when get onlineUser ")
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	local ntotal = #online_tab
	local nsucc = -1
	local nfilter = 0
	local detail = ""
	for k,v in ipairs(online_tab) do
		if tostring(v) ~= sender_account_id 										---- 不等于邀请者
			and weibo.check_system_subscribed_msg( v , weibo.SYS_WB_AROUND_VOICE )   ---- 订阅
			and not check_user_exists_tempchannel(v)								---- 不存在临时频道
			and not temp_tab[tostring(v)] then									---- 不在xx临时频道
			local ok_status,ok_ret = send_personal_weibo(sender_account_id, file_url, callback_url, v )
			if ok_status then
				if nsucc < 0 then nsucc = 0 end
				nsucc = nsucc + 1
			else
				detail = ok_ret
			end
		else
			only.log('D',string.format("--->----filter:%s",v))
			nfilter = nfilter + 1
		end
	end

	if nfilter == ntotal then
		nsucc = 0 
	end

	if nsucc >= 0 then
		inviteuser_set_frequency_timestamp(temp_channel_id)
		return true,string.format('{"count":%d}',nsucc)
	else
		return false,detail
	end
end

local function handle()
	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	local req_head   = ngx.req.raw_header()

	url_tab['client_host'] = req_ip
	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
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

	local accountID  = args['accountID']
	-- check_userinfo(accountID)

	local customType = tonumber(args['customType']) or 1

	local ok_status,result = nil,'DEFAULT_ERROR'
	if customType == 1 then
		ok_status,result = inviteuser_join_tempchannel(args)
	else

	end

	only.log('D',result)

	if ok_status then
    		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],result)
    	else
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],result)
    	end
end

safe.main_call( handle )
