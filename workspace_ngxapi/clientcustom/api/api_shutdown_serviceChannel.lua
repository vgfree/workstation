
----  Liuyongheng
----  2015-07-16
---- 关闭审核通过的服务频道(语境公司)

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
	---- 检查服务频道所有者的语境账号ID
	sql_check_accountid = " select 1 from userList where accountID = '%s' ",
	
	---- 检查是否有该频道
	sql_check_validity = " select validity, checkStatus from checkServiceChannelInfo " .. 
					   " where accountID= '%s' and channelNumber = '%s'  ",
	
	---- 更新 userCustomDefineInfo 合法性检查
	-- sql_check_custom_define = " select 1 from userCustomDefineInfo where accountID='%s' and customType=%d ",

	---- 更新 申请表apply 服务频道有效性
	sql_update_apply_validity = " update applyServiceChannelInfo set validity = %d , updateTime = %s, remark= '%s' " ..
									" where accountID = '%s' and channelNumber= '%s' ",

	---- 更新 更新 通过表check 服务频道有效性
	sql_update_check_validity = " update checkServiceChannelInfo set validity = %d , updateTime = %s, remark= '%s' " ..
									" where accountID = '%s' and channelNumber= '%s' ",	

	---- 更新 userCustomDefineInfo
	-- sql_update_custom_define = " update userCustomDefineInfo set validity = %d , updateTime= %s , remark= '%s' "..
	-- 							" where accountID = '%s' and customType = %d ",
}

-- validity 有效性
-- 0 (无效)
-- 1 (有效)
local VALIDITY_NO  = 0
local VALIDITY_YES = 1

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-- accountID	
-- channelNumber	
-- validity	
-- remark

local function check_parameter( args )

	if not app_utils.check_accountID(args['accountID']) or  string.find(args['accountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' accountID ')
	end

	if not args['channelNumber'] or  string.find(args['channelNumber'], "'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' channelNumber ')
	end

	if not args['validity'] or  string.find(args['validity'] ,"'" )  then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' validity ')
	end
	local validity = tonumber(args['validity'])
	if not validity or not ( validity == VALIDITY_YES or validity == VALIDITY_NO ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' validity ')
	end

	if not args['remark'] or  string.find(args['remark'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' remark ')
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

 local function check_service_channel( validity, account_id, channel_number )

	-- sql_check_validity = " select validity, checkStatus from checkServiceChannelInfo " .. 
	-- 				   " where accountID= '%s' and channelNumber = '%s'  ",
	local sql_str = string.format(G.sql_check_validity, account_id, channel_number)
	local ok_status, channel_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)

	if not ok_status or not channel_tab or type(channel_tab) ~= 'table' then
		only.log('E', string.format('connect channel_dbname failed!, sql_str:[%s] ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	-- 考虑添加错误码,该账户没有此number的服务频道
	if #channel_tab == 0 then
		only.log('E', string.format('[***] applyServiceChannelInfo channel_number recordset = 0 sqlstr:[%s]', sql_str))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' channel_number ')
	end

	-- 检查该服务频道的审核状态
	-- 如果还未审核通过,没有关闭该频道的必要
	-- local check_status = tonumber(channel_tab[1]['checkStatus'])
	-- if check_status ~= cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE then
	-- 	only.log('E', string.format('shut down service channel failed sql_str:[%s]', sql_str))
	-- 	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' 这个频道还未审核通过 ')
	-- end

	-- 校验原频道有效性
	-- 若原状态与操作相同,则提示不需要再进行此操作
	-- 比如该服务频道已经关闭
	if validity ==  channel_tab[1]['validity'] then
		if validity == VALIDITY_NO then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' already set validity to 0 ')
		end

		if validity == VALIDITY_YES then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' already set validity to 1 ')
		end
	end

	-- return channel_tab[1]['customType']

end

-- local function check_custom_define_info( account_id, custom_type )

-- 	local sql_str = string.format(G.sql_check_custom_define, account_id, custom_type)
-- 	local ok_status, custom_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)

-- 	if not ok_status or not custom_tab or type(custom_tab) ~= 'table' then
-- 		only.log('E', string.format('connect channel_dbname failed!, %s ' , sql_str))
-- 		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
-- 	end
	
-- 	if #custom_tab ~= 1 then
-- 		only.log('E', string.format('Internal data error, sql_str:[%s] ' , sql_str))
-- 		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
-- 	end

-- end

local function update_service_channel( validity, remark, account_id, channel_number )

	local cur_time = os.time()
	local update_time = cur_time

	local sql_tab = {}
	---- 更新 申请表apply 服务频道有效性
	-- sql_update_apply_validity = " update applyServiceChannelInfo set validity = %d , updateTime = %s, remark= '%s' " ..
	-- 								" where accountID = '%s' and channelNumber= '%s' ",
	local sql_str = string.format(G.sql_update_apply_validity, validity, update_time, remark, account_id, channel_number)
	only.log('D', string.format('sql_str:[%s]', sql_str))
	table.insert(sql_tab, sql_str)

	---- 更新 更新 通过表check 服务频道有效性
	-- sql_update_check_validity = " update checkServiceChannelInfo set validity = %d , updateTime = %s, remark= '%s' " ..
	-- 								" where accountID = '%s' and channelNumber= '%s' ",	
	local sql_str = string.format(G.sql_update_check_validity, validity, update_time, remark, account_id, channel_number)
	only.log('D', string.format('sql_str:[%s]', sql_str))
	table.insert(sql_tab, sql_str)

	---- 更新 userCustomDefineInfo
	-- sql_update_custom_define = " update userCustomDefineInfo set validity = %d , updateTime= %s , remark= '%s' "..
	-- 							" where accountID = '%s' and customType = %d ",

	local ok_status, ret = mysql_api.cmd(channel_dbname, 'AFFAIRS', sql_tab)
	if not ok_status then
		only.log('E',string.format("do AFFAIRS failed, sql_tab: \r\n [%s]", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end


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

	check_parameter( args )

	check_userinfo( args['accountID'] )

	-- 考虑是否需要添加管理员账号ID
	-- 如有,在此添加对管理员账号的校验

	-- local customType = check_service_channel( args['validity'], args['accountID'], args['channel_number'] )
	check_service_channel( args['validity'], args['accountID'], args['channelNumber'] )

	---- 更新 userCustomDefineInfo 前做唯一性检查
	-- check_custom_define_info( args['accountID'], customType )

	local remark = args['remark']
	if args['remark'] == '' then
		remark = string.format('关闭服务频道api 设置服务频道有效性为 %s', args['validity'])
	end

	update_service_channel( args['validity'], remark, args['accountID'], args['channelNumber'] )

	-- 业务逻辑:针对用户设置的服务频道,中途被作废,则默认为路况分享回调

	gosay.go_success(url_tab, msg['MSG_SUCCESS'])
end

safe.main_call( handle )