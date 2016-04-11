---- jiang z.s. 
---- 2014-11-03 
---- 获取管理员微频道所有关注用户列表 --boss

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

	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' ",

	sql_channel_number = "SELECT idx FROM checkMicroChannelInfo WHERE accountID = '%s' and number = '%s' and channelStatus != 3 limit 1 ",

	sql_channel_info = "   SELECT accountID, uniqueCode ,'' as nickname, 0 as online ,createTime FROM followUserList " ..
						" WHERE number = '%s' and validity = 1 limit %d ,%d ",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-->chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID'])  then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end
	if not args['channelNumber'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end
	-- 检测channeNumber参数
	local channel_num = args['channelNumber']
	if #tostring(channel_num) < 5 or #tostring(channel_num) > 16 or not utils.is_variable_syntax(channel_num) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
	end

	if args['startPage'] then 
		if not tonumber(args['startPage']) or string.find(tonumber(args['startPage']),"%.") or tonumber(args['startPage']) <= 0 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'startPage')
		end
	end

	if args['pageCount'] then
		if not tonumber(args['pageCount']) or string.find(tonumber(args['pageCount']),"%.")  or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'pageCount')
		end
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
		only.log('E', string.format('connect userlist_dbname failed!, %s ' , sql_str) )
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

local function get_nickname(accountid)
	local ok,nickname = redis_api.cmd('private','get',accountid .. ':nickname')
	if not ok then
		gosay.go_false(url_info,msg['MSG_DO_REDIS_FAILED'])
	end
	return nickname or ''
end

---- 
local function get_boss_followlist_microchannel( accountid , channel_num , startIndex , pageCount )
	local sql_str = string.format(G.sql_channel_number, accountid, channel_num )
	local ok,tmp  = mysql_api.cmd(channel_dbname,'SELECT',sql_str)

	if not ok or not tmp  then 
		only.log('E', string.format('get channel num failed %s ' ,sql_str ) )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #tmp == 0 then		
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])                             
	end

	local channel_idx = tmp[1]['idx']
	if not channel_idx or #tostring(channel_idx) < 9 then
		only.log('E', string.format('get channel idx failed %s ' ,sql_str ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end
	
	local sql_str = string.format(G.sql_channel_info, channel_num ,startIndex , pageCount)
	local ok,tmp = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not tmp  then 
		only.log('E', string.format('get channel info failed %s ' ,sql_str ) )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #tmp == 0 then 
		return nil
	end

	-- tmp[i]['isOnline'] = is_online
	local tmp_online_tab = {}
	local ok, ret = redis_api.cmd('statistic', 'smembers' , channel_idx .. ":channelOnlineUser" )
	if ok and ret then
		for i, v in pairs(ret) do
			tmp_online_tab[tostring(v)] = "1"
			only.log('D',v)
		end
	end

	for i, info in pairs(tmp) do
		tmp[i]['nickname'] = get_nickname(info['accountID']) 
		tmp[i]['online'] = tonumber(tmp_online_tab[tostring(info['accountID'])]) or 0
	end
	
	return tmp
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
	local startPage = tonumber(args['startPage']) or 1
	local pageCount = tonumber(args['pageCount']) or 20
	local startIndex = (startPage - 1) * pageCount
	
	---- 获取自己的微频道所有关注用户列表
	local ret = get_boss_followlist_microchannel(accountid,channel_num ,startIndex , pageCount) 
	local str = "[]"
	local count = 0
	if ret then 
		count = #ret
		local ok, tmp_str = pcall(cjson.encode ,ret)
		if ok and tmp_str then
			str = tmp_str
		end
	end
		
	local str = string.format('{"count":"%s","list":%s}',count,str)

	if str then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

safe.main_call( handle )
