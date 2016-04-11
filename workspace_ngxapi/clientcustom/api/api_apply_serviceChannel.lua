
---- Liuyongheng
---- 2015-07-13
---- 用户申请服务频道

local ngx       = require('ngx')
local msg       = require('msg')
local only      = require('only')
local safe      = require('safe')
local utils     = require('utils')
local gosay     = require('gosay')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"


local G = {

	---- 检查申请者的语境账号ID
	sql_check_accountid   = " select 1 from userList where accountID='%s' ",
		
	---- 判断是否重复提交多次 (暂定包括关闭的频道)
	sql_same_apply        = " select 1 from applyServiceChannelInfo where accountID= '%s' and channelName = '%s' limit 1 ",
	
	---- 限制最多申请 SERVICE_CHANNEL_APPLY_QUANTITY_LIMIT 个服务频道 (暂定包括关闭的频道)
	sql_count_apply_num   = " select count(1) as count from applyServiceChannelInfo where accountID = '%s' " , 
	
	---- 保存申请成功的数据
	sql_insert_apply_data = " insert into applyServiceChannelInfo ( accountID, channelNumber, channelUrl, channelName, logoUrl, " .. 
							" briefIntro, modifyCount, checkAccountID, checkTime, checkStatus, checkRemark, checkAppKey, " .. 
							" channelStatus, createTime, updateTime, validity, remark, applyAppKey) " .. 
							" values('%s', '%s', '%s', '%s', '%s', " .. 
							       " '%s', %d, '%s', %s, %d, '%s', %s, " .. 
							       " %d, %s, %s, %d, '%s', %s) ",
	---- 查询插入新数据之后的id
	sql_get_channel_id = " select id from applyServiceChannelInfo where accountID = '%s' and channelName = '%s' and validity = 1 "
 }

--申请服务频道的最大数量
-- local MAX_APPLY_COUNT = 5


local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}


local function check_parameter( args )

	if not app_utils.check_accountID(args['accountID']) or  string.find(args['accountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if not args['channelUrl'] or  string.find(args['channelUrl'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelUrl')
	end

	if not args['channelName'] or  string.find(args['channelName'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
	end

	if not args['logoUrl'] or  string.find(args['logoUrl'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'logoUrl')
	end

	if not args['briefIntro'] or  string.find(args['briefIntro'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'briefIntro')
	end

	safe.sign_check(args, url_tab)
end


---- 对accountID进行数据库校验
local function check_userinfo( account_id )

	local sql_str = string.format(G.sql_check_accountid, account_id)
	local ok_status, user_tab = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)

	if not ok_status or not user_tab or type(user_tab) ~= 'table' then
		only.log('E', string.format('connect userlist_dbname failed!, %s ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	
	if #user_tab == 0 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' accountID ')
	end
	if #user_tab >1 then
		only.log('E', '[***] userList accountID recordset > 1')
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

 end




local function check_same_apply( account_id, channel_name )

	local sql_str = string.format(G.sql_same_apply, account_id, channel_name)
	local ok_status, ret_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)

	if not ok_status or not ret_tab or type(ret_tab) ~= 'table' then
        only.log('E', string.format('connect channel_dbname failed!, [%s] ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	--考虑添加错误码,该账号下已经申请过该名称的服务频道
	if #ret_tab == 1 then
		only.log('E',string.format(" servicechannel same apply accountid:%s channel_name:%s ", accountid , channel_name ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' same channelName apply ')
	end

end

local function check_max_apply_count( account_id )

	
	local sql_str = string.format(G.sql_count_apply_num, account_id)
	local ok_status, ret_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)

	if not ok_status or not ret_tab or type(ret_tab) ~= 'table' then
        only.log('E', string.format('connect channel_dbname failed!, [%s] ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	--考虑添加错误码, 该账号下已经申请的服务频道超过最大限制
	-- if tonumber(ret_tab[1]['count']) >= MAX_APPLY_COUNT then
	if tonumber(ret_tab[1]['count']) >= cur_utils.SERVICE_CHANNEL_APPLY_QUANTITY_LIMIT then
		only.log('E',string.format(" servicechannel max apply sql_str:[%s] ", sql_str ))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' service channel max apply ')
	end
end


local function apply_service_channel(account_id, 
										-- developer_name,
										-- email,
										-- phone,
										-- address,
										channel_url,
										channel_name,
										channel_logoUrl,
										channel_briefIntro,
										apply_appKey)

	local channel_number = ''
	local modify_count = 0
	-- 审核信息
	local check_accountID = ''
	local check_time = 0
	local check_status = 0
	local check_remark = ''
	local check_appKey = 0
	-- 用户可见的频道状态
	local channelStatus = 0

	local createTime = os.time()
	local updateTime = createTime
	local validity = 1
	local remark = "申请服务频道"

	
	-- accountID channelNumber channelUrl channelName logoUrl 
	-- briefIntro modifyCount checkAccountID checkTime checkStatus
	-- checkRemark checkAppKey channelStatus createTime updateTime
	-- validity remark applyAppKey
	local sql_str = string.format(G.sql_insert_apply_data, account_id,
															channel_number, 
															channel_url,
															channel_name,
															channel_logoUrl,
															channel_briefIntro,
															modify_count,
															check_accountID,
															check_time,
															check_status,
															check_remark,
															check_appKey,
															channelStatus,
															createTime,
															updateTime,
															validity,
															remark,
															apply_appKey)
	only.log('D', string.format("sql_str:[%s]", sql_str)) --[ddd]
	
	local ok_status , res_tab = mysql_api.cmd(channel_dbname, "INSERT", sql_str)
	if not ok_status then
		only.log('E', string.format("INSERT failed, sql_str: [%s]", sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end


	sql_str = string.format(G.sql_get_channel_id, account_id, channel_name)
	only.log('D', string.format("sql_str:[%s]", sql_str)) --[ddd]

	local ok_status , id_tab = mysql_api.cmd(channel_dbname, "INSERT", sql_str)
	if not ok_status or not id_tab or type(id_tab) ~= 'table' then
		only.log('E', string.format("INSERT failed, sql_str: [%s]", sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	-- 一个语境账户id只能申请一个同名频道
	if #id_tab ~= 1 then
		only.log('E', string.format("accountID channelName recordset ~= 1, sql_str: [%s]", sql_str))
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	
	local id = id_tab[1]['id']
	only.log('D', string.format("=========id:[%s]========", id)) --[ddd]

	return true, id
end


local function handle()

	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	url_tab['client_host'] = req_ip

	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_body'] = req_body
	
	local args = utils.parse_url(req_body)
	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
	end	
	url_tab['app_key'] = args['appKey']

	check_parameter(args)

	local account_id         = args['accountID']
	-- local developer_name  = args['developerName']
	-- local email           = args['email']
	-- local phone           = args['phone']
	-- local address         = args['address']
	local channel_url        = args['channelUrl']
	local channel_name       = args['channelName']
	local channel_logoUrl    = args['logoUrl']
	local channel_briefIntro = args['briefIntro']
	local apply_appKey       = args['appKey']

	check_userinfo( account_id )

	--重复申请判断
	check_same_apply(account_id, channel_name)

	--考虑是否添加对该申请账号下申请的频道数限制
	check_max_apply_count(account_id)

	local ok_status, id = apply_service_channel(account_id, 
													-- developer_name,
													-- email,
													-- phone,
													-- address,
													channel_url,
													channel_name,
													channel_logoUrl,
													channel_briefIntro,
													apply_appKey)

	local ret_str = string.format('{id:"%s"}', id)

	if ok_status then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	
	
end

safe.main_call( handle )



