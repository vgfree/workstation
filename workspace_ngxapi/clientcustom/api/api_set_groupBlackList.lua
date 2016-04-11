--owner:yujiabin
--time :2014-09-23
--设置黑名单用户

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

local userlist_dbname = 'app_usercenter___usercenter'
local weibo_dbname    = 'app_weibo___weibo'

local G = {
	sql_check_accountid  = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ",
	sql_check_blacklist  = "select validity from groupBlacklistInfo where accountID = '%s' and groupID = '%s' and groupType = %d",
	sql_update_blacklist = "update groupBlacklistInfo set validity = %d ,updateTime = unix_timestamp() ,operAccountID = '' where accountID = '%s' and groupID = '%s' and groupType = %d ",
 	sql_insert_blacklist = "insert into groupBlacklistInfo (groupID,groupType,accountID,validity,createTime,updateTime,operAccountID) " ..
					" values('%s',%d,'%s',1,unix_timestamp(),unix_timestamp(),'')",
	sql_insert_history = "insert into groupBlackListHistory(groupID,groupType,accountID,validity,updateTime,operAccountID)"..
					"values('%s',%d,'%s',%d,unix_timestamp(),'')",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}
--chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	local group_type = tonumber(args['groupType']) or 3
	if not (group_type == 1 or group_type == 2 or group_type == 3  ) then
           gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupType')
    end

	if not args['groupID'] then
		only.log('E','groupID error')
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'groupID')
	end
	--groupID length
	local len = string.match(args['groupID'],'%d+')
	if #len < 5 or #len > 8 then
		only.log('E','groupID error')
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'groupID')
	end
	safe.sign_check(args, url_tab)
end

--检测用户信息
local function check_userinfo(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_user,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_user or user_tab == nil then
		only.log('E',sql_str)
		only.log('E','connect userlist_dbname failed!')
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	
	if #user_tab == 0 then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	if #user_tab > 1 then
		only.log('E','[***] userList accountID recordset >1')
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end
	--OK
end

--将黑名单变化插入历史记录表
local function ins_history(account_id,group_id,group_type,validity)
	local sql_history = string.format(G.sql_insert_history,group_id,group_type,account_id,validity)
	local ok_status = mysql_api.cmd(weibo_dbname,'INSERT',sql_history)
	only.log('D',sql_history)
	if not ok_status then
		only.log('E',sql_history)
		only.log('E',"insert groupBlackListHistory failed!")
		return false
	end

	return true
end

--插入或修改用户为黑名单
local function insert_blacklist(account_id, group_id,group_type)
	local sql_str = string.format(G.sql_check_blacklist,account_id,group_id,group_type)
	local ok_status,ok_ret = mysql_api.cmd(weibo_dbname,'SELECT',sql_str)
	if not ok_status or ok_ret == nil then
		only.log('E',sql_str)
		only.log('E',"select groupBlacklistInfo failed!")
		return false
	end

	if #ok_ret == 0 then
		local sql_insert = string.format(G.sql_insert_blacklist,group_id,group_type,account_id)
		local ok_status = mysql_api.cmd(weibo_dbname,'INSERT',sql_insert)
		if not ok_status then
			only.log('E',sql_insert)
			only.log('E',"insert groupBlacklistInfo failed!")
			return false
		end
		local ok_sta = ins_history(account_id,group_id,group_type,1)
		if not ok_sta then
			return false
		end
		return true
	end

	--若存在记录则判断validity的值
	if #ok_ret == 1 then
	--[[
		for key,value in pairs(ok_ret) do
			if type(value) == "table" then
			for k,v in pairs(value) do							
					only.log('D',string.format(" idx :%s    %s = %d" , key ,k,v))
				end
			end
		end--]]
		--only.log('D',string.format(" %d" ,ok_ret[1]["validity"]))
		--原来无效则改为有效
		if tonumber(ok_ret[1]["validity"]) == 0 then
			local sql_update = string.format(G.sql_update_blacklist,1,account_id,group_id,group_type)
			local ok_status = mysql_api.cmd(weibo_dbname,'UPDATE',sql_update)
			if not ok_status then
				only.log('E',sql_update)
				only.log('E',"insert groupBlacklistInfo failed!")
				return false
			end
			local ok_sta = ins_history(account_id,group_id,group_type,1)
			if not ok_sta then
				return false
			end
		end
		--原来有效则直接返回
		return true
	end
	
	if #ok_ret > 1 then
		only.log('E','[***] groupBlacklistInfo accountID recordset >1')
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end

	return false
end

local function backout_blacklist(account_id,group_id,group_type)
	local sql_str = string.format(G.sql_check_blacklist,account_id,group_id,group_type)
	local ok_status,ok_ret = mysql_api.cmd(weibo_dbname,'SELECT',sql_str)
	if not ok_status or ok_ret == nil then
		only.log('E',sql_str)
		only.log('E',"select groupBlacklistInfo failed!")
		return false
	end
	--only.log('D',sql_str)
	if #ok_ret == 0 then
		return true
	end

	--若存在记录则判断validity的值
	if #ok_ret == 1 then
		--only.log('D',string.format(" %d" ,ok_ret[1]["validity"]))
		--原来有效则改为无效
		if tonumber(ok_ret[1]["validity"]) == 1 then
			local sql_backout = string.format(G.sql_update_blacklist,0,account_id,group_id,group_type)
			local ok_status = mysql_api.cmd(weibo_dbname,'UPDATE',sql_backout)
			if not ok_status then
				only.log('E',sql_backout)
				only.log('E',"backout groupBlacklistInfo failed!")
				return false
			end
			--only.log('D',sql_backout)
			local ok_sta = ins_history(account_id,group_id,group_type,0)
			if not ok_sta then
				return false
			end
		end
		--无效则返回
		return true
	end
	
	if #ok_ret > 1 then
		only.log('E','[***] groupBlacklistInfo accountID recordset >1')
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end

	return false
end


local function handle()
	local req_ip   = ngx.var.remore_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	--only.log('D',req_body)
	if not req_body then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_tab['client_host'] = req_ip
	url_tab['client_body'] = req_body

	----POST key-value

	local args = utils.parse_url(req_body)
	if not args then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
	end
	url_tab['app_key'] = args['appKey']

	--check accountID groupType groupID
	check_parameter(args)

	local account_id = args['accountID']
	local group_id   = args['groupID']
	local group_type = args['groupType']or 3

	check_userinfo(account_id)
	--判断操作类型
	local op_type = args['opType']
	only.log('D',string.format("%s",type(op_type)))
	if op_type == '1' then
		local ok_status = insert_blacklist(account_id,group_id,group_type)
		if not ok_status then
			gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
		end
	elseif op_type == '2' then 
		local ok_status = backout_blacklist(account_id,group_id,group_type)
		if not ok_status then
			gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
		end
	else
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'blacklistopType')
	end
	
	gosay.go_success(url_tab,msg['MSG_SUCCESS_WITH_RESULT'],"ok")			  
end

safe.main_call(handle)
