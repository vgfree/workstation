---- owner:zhangkai 
---- time :2014-11-08
---- 重置频道当前邀请的惟一码

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
local appfun    = require('appfun')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
	sql_check_accountid = "select 1 from userList WHERE accountID='%s' limit 1",

	sql_reset_micro = "update checkMicroChannelInfo set inviteUniqueCode = '%s', updateTime = unix_timestamp() where accountID = '%s' and number = '%s' ",
	sql_save_inviteuniquecode = "insert into inviteLinksHistory(idx,number,accountID,inviteUniqueCode,channelType,crateTime,appKey)" ..
								"value('%s', '%s', '%s', '%s', %d, unix_timestamp(), '%s' ) ",

	sql_reset_secret = "update checkSecretChannelInfo set inviteUniqueCode = '%s' , updateTime = unix_timestamp() where accountID = '%s' and number = '%s' and channelStatus = 1",
	
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if not args['channelNumber'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end
	local channel_type = args['channelType']
	if not channel_type or not ( channel_type == '1' or channel_type == '2'  ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelType')
	end

	-- 频道编号
	local channel_num = args['channelNumber']
	if args['channelType'] == '1' then
		if #tostring(channel_num) < 5 or  #tostring(channel_num) > 16 or not utils.is_variable_syntax(channel_num)  then
			only.log('E',string.format(" channel_number:%s is error", channel_num ))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
		end
	elseif args['channelType'] == '2' then
		if  not tonumber(args['channelNumber']) or #tostring(args['channelNumber']) < 5 or not utils.is_number(args['channelNumber']) then
        		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
    		end
    	else
    		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelType')
	end
	
	-- safe.sign_check(args, url_tab)
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

---- 对accountID进行数据库校验
local function check_userinfo(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status or user_tab == nil then
		only.log('D',sql_str)
		only.log('E',string.format('connect userlist_dbname failed, %s ',sql_str) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #user_tab == 0 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if #user_tab >1 then 
		-----数据库存在错误,
		only.log('E','[***] userList accountID recordset > 1 ')
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end


local function reset_micro_inviteuniquecode(accountid , invite_unique_code, channel_num, channel_type, app_key )

	local ok, channel_idx = redis_api.cmd('private','get' , string.format("%s:channelID",channel_num))
	if not ok or not channel_idx or #tostring(channel_idx) ~= 9 then
		only.log('E',string.format("cur channel_num:%s get channel_idx failed [redis]",channel_num))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end

	local ok ,channel_owner = redis_api.cmd('private','hget',string.format("%s:userChannelInfo",channel_idx),"owner") 
	if not ok or not channel_owner or not app_utils.check_accountID(accountid)  then
		only.log('E',string.format("cur channel_num:%s get channel_idx failed [redis]",channel_owner))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if accountid ~= channel_owner then
		only.log('E',string.format("%s:%s",accountid,channel_owner))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	local sql_tab = {}
	local new_invite_unique_code = string.format("%s|%s",channel_num, invite_unique_code)
	local sql_str = string.format(G.sql_reset_micro , new_invite_unique_code, accountid, channel_num )
	table.insert(sql_tab,sql_str)
	local sql_str = string.format(G.sql_save_inviteuniquecode, channel_idx , channel_num ,accountid, new_invite_unique_code,channel_type, app_key )
	table.insert(sql_tab,sql_str)
	local ok, ret = mysql_api.cmd(channel_dbname,"AFFAIRS",sql_tab)
	if not ok then
		only.log('E',"reset invite unique_code failed, %s", table.concat( sql_tab, "\r\n"))
		return false
	end

	local ok ,ret =redis_api.cmd('private','set',string.format("%s:inviteUniqueCode",channel_idx), new_invite_unique_code)
	if not ok then
		only.log('E',"[redis]reset invite unique_code failed, channelID: %s invite code: %s  ",  channel_idx, new_invite_unique_code )
		return false
	end
	return true
end 

local function reset_secret_inviteuniquecode(accountid , invite, channel_num, channel_type,  app_key )
	--得到频道的idx
	local ok, channel_idx = redis_api.cmd('private','get' , string.format("%s:channelID",channel_num))
	if not ok or not channel_idx or #tostring(channel_idx) ~= 9 then
		only.log('E',string.format("cur channel_num:%s get channel_idx failed [redis]",channel_num))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end
	-- 判断频道状态
	local ok ,channel_status = redis_api.cmd('private','get',string.format("%s:channelStatus",channel_idx))
	if not ok or not channel_status then
		only.log('E',"redis get channel_status failed [idx:%s]",channel_idx)
		gosay.go_false(url_tab,msg['MSG_ERROR_DO_REDIS_FILED'])
	end
	if channel_status == '2' then
		only.log('W',"cur channel is close [idx:%s]",channel_idx)
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end
	--判断用户是否是管理员
	local ok ,channel_owner = redis_api.cmd('private','hget',string.format("%s:userChannelInfo",channel_idx),"owner") 
	if not ok or not channel_owner or not app_utils.check_accountID(accountid)  then
		only.log('E',string.format("cur channel_num:%s get channel_idx failed [redis]",channel_owner))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if accountid ~= channel_owner then
		only.log('E',string.format("[cur user not admin]cur_accountID:%s,really_admin:%s",accountid,channel_owner))
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_NOT_MG'])
	end

	--生成新的邀请码
	local sql_tab = {}
	local new_invite_unique_code = string.format("%s|%s",channel_num, invite)
	
	--将新的邀请码保存在数据库，更新redis
	local sql_str = string.format(G.sql_reset_secret , new_invite_unique_code, accountid, channel_num )
	table.insert(sql_tab,sql_str)

	local sql_str = string.format(G.sql_save_inviteuniquecode, channel_idx , channel_num ,accountid, new_invite_unique_code,channel_type, app_key )
	table.insert(sql_tab,sql_str)

	local ok, ret = mysql_api.cmd(channel_dbname,"AFFAIRS",sql_tab)
	if not ok  or not ret then
		only.log('E',"reset invite unique_code failed, %s", table.concat( sql_tab, "\r\n"))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	local ok , ret = redis_api.cmd('private','set',string.format("%s:inviteUniqueCode",channel_idx), new_invite_unique_code)
	if not ok then
		only.log('E',"[redis]reset invite unique_code failed, channelID: %s invite code: %s  ",  channel_idx, new_invite_unique_code )
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	return true
end

local function handle()

	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	local req_head = ngx.req.raw_header()
	local req_method = ngx.var.request_method

	url_tab['client_host'] = req_ip
	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_body'] = req_body

	local args = nil	
	if req_method == 'POST' then		
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')		
		if not boundary then		
			args = ngx.decode_args(req_body)		
		else		
		---- 解析表单形式 		
			args = utils.parse_form_data(req_head, req_body)		
		end		
	end
	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
	end

	url_tab['app_key'] = args['appKey']

	check_parameter(args)

	local channel_num = args['channelNumber']
	local channel_type = args['channelType']
	local account_id  = args['accountID']
	check_userinfo(account_id)

	local invite = utils.create_uuid()
	local ok = nil
	if channel_type == "1" then
		ok = reset_micro_inviteuniquecode(account_id , invite, channel_num, channel_type, args['appKey'] )
	elseif channel_type == "2" then
		ok = reset_secret_inviteuniquecode(account_id , invite, channel_num, channel_type, args['appKey'] )
	end
	if ok then
		gosay.go_success(url_tab, msg['MSG_SUCCESS'])
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
