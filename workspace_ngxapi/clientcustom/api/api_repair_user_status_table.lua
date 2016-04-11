---- huanglonghan
---- 临时用于处理消息
---- status=2


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
local appfun    = require('appfun')

local channel_dbname = "app_custom___wemecustom"

local G = {
	
	sql_get_all_err_msg = " SELECT applyAccountID,idx FROM userVerifyMsgInfo WHERE status=2 AND  validity=1 ",

	sql_get_join_menber_list = " SELECT talkStatus FROM joinMemberList WHERE validity=1 AND accountID='%s' AND idx='%s' ",

}


local url_tab = {
	type_name = 'system',
	app_key = '',
	client_host = '',
	client_body = '',
}

local  succeed_tab = {}
local  failed_tab = {}

local function get_no_check_msg()

	local sql_str = G.sql_get_all_err_msg
	only.log('D',string.format("sql_check_join_channel sql:>>--%s ",sql_str))
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= 'table' then
		only.log('E',string.format("sql_check_join_channel mysql  failed, %s ",sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	---- 查询所有数据
	return ret
end

---- 调用自动审核业务的api
---- 成功返回true,失败返回false
local function check_msg_join_secretchannel( accountID, idx)

	local sql_str = string.format(G.sql_get_join_menber_list, accountID, idx)
	--only.log('D',string.format("sql_get_join_menber_list sql:>>--%s ",sql_str))
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= 'table' then
		only.log('E',string.format("sql_get_join_menber_list mysql  failed, %s ",sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret > 1 then 
		only.log('E',string.format(" mysql  failed, %s ",sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	elseif #ret == 0 then 
		local ok, result = redis_api.cmd('private','hdel', idx .. ':userStatusTab', accountID..":status")
		if ok then
			only.log('D',string.format("-->>hdel<<--accountID:%s--idx:%s--",accountID,idx))
			table.insert(succeed_tab,string.format("--accountID:%s--idx:%s--",accountID,idx))
        	return true
        end
	elseif #ret == 1 then 
		local ok, result = redis_api.cmd('private','hset', idx .. ':userStatusTab', accountID..":status",ret[1]['talkStatus'])
		if ok then 
			only.log('D',string.format("-->>hset<<--accountID:%s--idx:%s--talkStatus:%s--",accountID, idx, ret[1]['talkStatus']))
			table.insert(succeed_tab,string.format("--accountID:%s--idx:%s--",accountID,idx))
        	return true
        end
	end

	only.log('D',string.format("--->>failed<<---accountID:%s--idx:%s--",accountID,idx))
	table.insert(failed_tab,string.format("--accountID:%s--idx:%s--",accountID,idx))

    return false
end

local function auto_check_msg_for_secretchannel(msg_info)
	---- 调用验证消息的api,返回总共多少条消息,以及总共处理了多少条消息
	local total = #msg_info
	local succ = 0 

	for k , v in pairs(msg_info) do
		local ok = check_msg_join_secretchannel(v['applyAccountID'], v['idx'])
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

	url_tab['client_host'] = req_ip

	local msg_info = get_no_check_msg()
	if msg_info then
		local total,count = auto_check_msg_for_secretchannel(msg_info)
		for a,v in pairs(succeed_tab) do
			only.log("D",string.format("--%s--succeed_tab:>>--%s",a,v))
		end
		for a,v in pairs(failed_tab) do
			only.log("D",string.format("--%s--failed_tab:>>---%s",a,v))
		end
		local ret = string.format('{"msgTotal":"%s","succeed":"%s"}',total,count)
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],ret)
	end

	----FAILED
	gosay.go_false(url_tab, msg['SYSTEM_ERROR'])

end

safe.main_call( handle )
