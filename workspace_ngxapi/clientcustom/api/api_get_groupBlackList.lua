--owner:
--time :2014-09-24
--查询频道黑名单信息

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cjson     = require('cjson')

local userlist_dbname = 'app_usercenter___usercenter'
local weibo_dbname    = 'app_weibo___weibo'

local G = {
	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID = '%s' limit 2",
	sql_get_blacklist   = "SELECT accountID FROM groupBlacklistInfo WHERE groupID = '%s' and groupType = %d and validity = 1  limit 10",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-->check parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'])
	end

	local group_type = args['groupType'] or '3'
	if not (group_type == '1' or group_type == '2' or group_type == '3') then
		only.log('E','groupType error')
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'groupType')
	end

	if not args['groupID'] then
		only.log('E','groupID error')
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'groupID')
	end
	
	local len = string.match(args['groupID'],'%d+')
	if #len < 5 or #len >8 then
		only.log('E','groupID error')
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'groupID')
	end
	safe.sign_check(args,url_tab)
	--OK
end

-->检查用户名是否存在
local function check_userinfo(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,ok_ret = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status or ok_ret == nil then
		only.log('D',sql_str)
		only.log('E','connect userlist_dbname failed')
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ok_ret == 0 then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'])
	end

	if #ok_ret > 1 then
		only.log('E','[***] userList accountID recordset > 1')
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end
end

-->获取黑名单用户帐号
local function get_group_blacklist(group_id,group_type)
	local sql_str = string.format(G.sql_get_blacklist,group_id,group_type)
	local ok_status,ok_ret = mysql_api.cmd(weibo_dbname,'SELECT',sql_str)
	--only.log('D',sql_str)
	if not ok_status or ok_ret == nil then
		only.log('E',sql_str)
		only.log('E','connect weibo_dbname failed')
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
		return false
	end
	
	local count = #ok_ret
	for key,value in pairs(ok_ret) do
		local nickname_key = string.format('%s:nickname',value["accountID"])
		local ok_status,ok_nickname = redis_api.cmd('private','get',nickname_key)
		if not ok_status then
			only.log('E',nickname_key)
			gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
		end
		value["nickname"] = ok_nickname or ''
	end
	local ok_status,ok_str = pcall(cjson.encode,ok_ret)
	if not ok_status or ok_str == nil then
		only.log('E','cjson encode failed')
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
		return false
	end
	--返回查到的数据和数目
	return true,count,ok_str
end

local function handle()
	local req_ip   = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	url_tab['client_host'] = req_ip
	if not req_body then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_body'] = req_body

	--POST key-value
	local args = utils.parse_url(req_body)
	if not args then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
	end
	url_tab['app_key'] = args['appKey']
	--check parameter
	check_parameter(args)

	local account_id = args['accountID']
	--check accountID
	check_userinfo(account_id)

	local group_id   = args['groupID']
	local group_type = args['groupType']
	local ok_status,ok_count,ok_ret = get_group_blacklist(group_id,group_type)
	if not ok_status then
		only.log('D',string.format("accountID:%s get_group_blacklist failed",accountID))
		gosay.go_false(url_tab,mgs['MSG_ERROR_REQ_ARG'])
	end

	--[[only.log('D',string.format("------ accountID:%s, groupID:%s, groupType:%s, return stauts:%s result:%s",												
								account_id,
								group_id,
								group_type,
								ok_status,
								ok_ret))--]]
	
	if ok_count == 0 then
		ok_ret = "[]"
	end
	local result = string.format('{"count": %d,"list": %s}',ok_count,ok_ret)
	gosay.go_success(url_tab,msg['MSG_SUCCESS_WITH_RESULT'],result)
end

safe.main_call( handle )
