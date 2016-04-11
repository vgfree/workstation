---- jiang z.s. 
---- 临时用于处理消息
---- 8173


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
local cur_utils = require('clientcustom_utils')
local http_api  = require('http_short_api')
local appfun    = require('appfun')


local channel_dbname = "app_custom___wemecustom"

local clientcustom_srv = link["OWN_DIED"]["http"]["clientCustom"]

---- 群里面最大用户数
local max_capacity = 1000


local G = {

	sql_get_all_err_msg = " select * from userVerifyMsgInfo where status = 0 and id >= %s order by id limit %s ",

}


local url_tab = {
	type_name = 'system',
	app_key = '',
	client_host = '',
	client_body = '',
}

local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab,msg["MSG_ERROR_REQ_ARG"],'accountID')
	end

	if args['accountID'] ~= "kxl1QuHKCD" then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	if not args['msgCount'] or not utils.is_number(args['msgCount']) or tonumber(args['msgCount']) < 1 or tonumber(args['msgCount']) > 500 then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'msgCount')
	end

	if args['applyIdx'] and #args['applyIdx'] ~= 0 then  
		if not utils.is_number(args['applyIdx']) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
		end
	end

	-- safe.sign_check(args, url_tab )
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)

end


local function get_no_check_msg(msg_count, applyIdx)

	local sql_str = string.format(G.sql_get_all_err_msg, applyIdx, msg_count)
	only.log('E',string.format("sql_check_join_channel sql:>>--%s ",sql_str))
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= 'table' then
		only.log('E',string.format("sql_check_join_channel mysql  failed, %s ",sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	---- 查询所有数据
	return ret
end

-- 调用userVerifyMsgInfo api
local function user_verify_msg_info(admin, apply_accountid, apply_idx, check_status, check_remark)
    local tab = {
        appKey = url_tab['app_key'],
        accountID = admin,
        applyAccountID = apply_accountid,
        checkRemark = check_remark,
        checkStatus = check_status,
        applyIdx = apply_idx,
    }

    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)
    local post_body = utils.post_data('clientcustom/v2/veritySecretChannelMessage', clientcustom_srv, body)
    local ret = http_api.http(clientcustom_srv, post_body, true)
    if not ret then
        only.log('E',string.format("userVerifyMsgInfo failed  %s ", post_body ) )
       gosay.go_false(url_tab, msg['MSG_DO_HTTP_FAILED'])
    end

    local body = string.match(ret,'{.*}')
    if not body then
        only.log('E',string.format("[clientcustom/v2/veritySecretChannelMessage] %s \r\n ****SYSTEM_ERROR: %s", post_body, ret ))
        gosay.go_false(url_tab, msg["SYSTEM_ERROR"])
    end

    local ok, ret_body = utils.json_decode(body)
    if not ok  then
        only.log('E',string.format("MSG_ERROR_REQ_BAD_JSON: %s", body ))
        gosay.go_false(url_tab, msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    return ret_body
end

---- 调用自动审核业务的api
---- 成功返回true,失败返回false
local function check_msg_join_secretchannel( admin, apply_accountid,apply_idx, check_status, check_remark )

	-- 调用userVerifyMsgInfo api
	local ret_body = user_verify_msg_info( admin, apply_accountid, apply_idx, check_status, check_remark )
	if tonumber(ret_body['ERRORCODE']) == 0 then
        return true
    end

    return false
end

local function auto_check_msg_for_secretchannel(msg_info)
	---- 调用验证消息的api,返回总共多少条消息,以及总共处理了多少条消息
	local total = #msg_info
	local succ = 0 

	local check_status = 1 ----表示审核通过
	local check_remark = "系统api自动审核通过"

	for k , v in pairs(msg_info) do
		local ok = check_msg_join_secretchannel(v['accountID'],v['applyAccountID'],v['id'],check_status,check_remark)
		if ok then
			succ = succ + 1 
		end
	end
	return total,succ
end

local function  handle()

	local req_ip = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()

	local req_method = ngx.var.request_method
	url_tab['client_host'] = req_ip
	if not req_body then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'])
	end
	url_tab['client_body'] = req_body

	local args = nil
	if req_method == 'POST' then
		local boundary = string.match(req_head,'boundary=(..-)\r\n')
		if not boundary then
			args = ngx.decode_args(req_body)
		else
			args = utils.parse_form_data(req_head,req_body)
		end
	end

	if not args then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"appKey")
	end

	url_tab['app_key'] = args['appKey']
	appkey = args['appKey']
	check_parameter(args)

	local accountid = args['accountID']
	local msg_count = tonumber(args['msgCount']) or 100 
	if not args['applyIdx'] or #args['applyIdx'] ==0 then 
		args['applyIdx'] = '8173'
	end
	
	local msg_info = get_no_check_msg(msg_count, args['applyIdx'])
	if msg_info then
		local total,count = auto_check_msg_for_secretchannel(msg_info)
		local ret = string.format('{"msgTotal":"%s","succeed":"%s"}',total,count)
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],ret)
	end

	----FAILED
	gosay.go_false(url_tab, msg['SYSTEM_ERROR'])

end

safe.main_call( handle )
