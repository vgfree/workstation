

---- Liuyongheng
---- 2015-07-16
---- 提交服务频道数据(提交后审核状态为审核中)


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
	
	---- 检查是否有该频道,以及频道审核状态
	sql_check_number       = " select number, checkStatus from applyServiceChannelInfo where accountID= '%s' and number = '%s' limit 2 ",
	
	---- 修改审核状态
	sql_update_checkstatus = " update applyServiceChannelInfo set checkStatus = %d  where accountID= '%s' and number = '%s' ",

}


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

	if not args['number'] or  string.find(args['number'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'number')
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

-- 服务频道审核状态
-- checkStatus   
-- 0 (待提交审核)    
-- 1 (审核中)      
-- 2 (驳回)       
-- 3 (通过)
local function check_service_number( account_id, number )

	local sql_str = string.format(G.sql_check_number, account_id, number)
	local ok_status, channel_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)

	if not ok_status or not channel_tab or type(channel_tab) ~= 'table' then
		only.log('E', string.format('connect channel_dbname failed!, sql_str:[%s] ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	
	--考虑添加错误码,该账户没有此number的服务频道
	if #channel_tab == 0 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' 此账户没有这个number的服务频道 ')
	end

	if #channel_tab > 1 then
		only.log('E', string.format('[***] applyServiceChannelInfo number recordset > 1, sql_str:[%s] ', sql_str))
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end


	local check_status = tonumber(channel_tab[1]['checkStatus'])

	if not check_status then
		only.log('E', '[***] applyServiceChannelInfo check_status is not number, sql_str:[%s] ', sql_str)
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	-- 以下考虑添加错误码
	-- 正在审核中，请等待, 状态1
	if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_CHECKING then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' 正在审核中，请等待 Under review Please wait ' )
	end

	-- 审核被驳回,请修改申请内容，然后重新提交, 状态2
	if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REJECT then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' 审核被驳回,请修改申请内容，然后重新提交 Audit was dismissed, modify the application, and then resubmit  ')
	end

	-- 审核已通过,不用再提交审核, 状态3
	if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' 审核已通过,不用再提交审核 Audit has passed, do not be submitted for review ' )
	end

end


local function update_service_checkstatus( account_id, number)

	local sql_str = string.format(G.sql_update_checkstatus, cur_utils.SERVICE_CHANNEL_STATUS_OF_CHECKING, account_id, number)
	local ok_status = mysql_api.cmd(channel_dbname, 'UPDATE', sql_str)

	if not ok_status then
		only.log('E', string.format('applyServiceChannelInfo update failed!, sql_str:[%s] ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	

	return true
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

	check_userinfo(args['accountID'])

	check_service_number(args['accountID'], args['number'])

	local ok_status = update_service_checkstatus(args['accountID'], args['number'])

	if ok_status then
		gosay.go_success(url_tab, msg['MSG_SUCCESS'])
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	
	
end

safe.main_call( handle )

