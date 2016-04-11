--owner:jiang z.s. 
---- 获取当前微频道详细信息

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

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 1 ",
	---- channelStatus 频道状态 
	---- 1正常
	---- 2等待审核
	---- 3关闭
	sql_get_channel_info = "select id as idx, idx as channelID , name, introduction,cityCode,cityName,catalogID,catalogName,chiefAnnouncerIntr, " ..
					  "logoURL,accountID, InviteUniqueCode ,channelStatus ,createTime , keyWords, '' as chiefAnnouncerName , 0 as onlineCount , userCount  " .. 
					  "from checkMicroChannelInfo  where channelStatus in ( 1,2 ) and number = '%s' limit 1  " ,
	sql_get_follow_userTotal = "select count(1) as count from followUserList where number = '%s' and idx = '%s' and validity = 1 ",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}


-->chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID']) or  string.find(args['accountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if not args['channelNumber'] or  string.find(args['channelNumber'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end

	-- 检测channeNumber参数
	local channel_num = args['channelNumber']
	if #tostring(channel_num) < 5 or #tostring(channel_num) > 16 or not utils.is_variable_syntax(channel_num) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
	end

	-- safe.sign_check(args, url_tab )
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
		only.log('E','connect userlist_dbname failed!')
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


local function check_follow_info( accountid , channel_num )
	local ok, channel_idx = redis_api.cmd('private', 'get', string.format("%s:channelID", channel_num ) )
	if not ok then
		only.log('E',string.format(" channel_num:%s  get user to  %s:channelID  failed  ", channel_num,  accountid   ) )
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end

	if not channel_idx or #tostring(channel_idx) < 9 then
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	local ok, ret = redis_api.cmd('private', 'SISMEMBER', string.format("%s:microChannelFollowUser", channel_idx ) , accountid )
	if ok and ret then
		return 1
	end
	return 0
end

local function get_nickname(accountID)
	local ok,nickname = redis_api.cmd('private','get',accountID..':nickname')
	if not ok then
		only.log('E',"redis get chiefAnnouncerName failed [%s]",accountID)
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	return nickname or ''

end

local function get_microchannel_info( accountid, channel_num ,show_id , onlineCount)
	local sql_str = string.format(G.sql_get_channel_info, channel_num)
	local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret then
		only.log('E',string.format('get user channel info failed!  %s ',sql_str) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0  then
		only.log('D',string.format( "channel_num:%s   get result is empty[sql:%s]", channel_num,sql_str))
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	local temp_validity = check_follow_info( accountid ,channel_num )
	ret[1]['validity'] = temp_validity

	if not show_id then
		ret[1]['channelID'] = nil
	end

	---- 获取主播名 及在线用户数和总数
	ret[1]['chiefAnnouncerName'] = get_nickname(ret[1]['accountID'])
	ret[1]['onlineCount'] = onlineCount

	local ok, str = pcall(cjson.encode,ret)
	return str
end

local function get_follow_microchannel_detail(channel_num)
	local ok, idx = redis_api.cmd('private', 'get', string.format("%s:channelID", channel_num))
	if not ok  then
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end
	if not idx or #tostring(idx) < 9 then
		only.log('D',"get_follow_microchannel_detail [***%s***]",channel_num)
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
	end

	local ok , onlineUser = redis_api.cmd('statistic','scard',idx .. ":channelOnlineUser")
	if not ok  then
		only.log('E',"get channelOnlineUser failed!")
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	return onlineUser
end

local function handle()

	local req_ip   = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
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
	---- 传入参数语法校验
	check_parameter(args)

	local accountid  = args['accountID']
	---- 对accountID进行数据库校验
	check_userinfo(accountid)

	local channel_num = args['channelNumber']
	local show_id = args['showChannelID']
	local onlineCount = get_follow_microchannel_detail(channel_num)
	local str= get_microchannel_info(accountid, channel_num, show_id , onlineCount)
	
	if str then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
