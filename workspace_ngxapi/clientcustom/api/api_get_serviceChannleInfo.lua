
---- Liuyongheng
---- 2015-07-14
---- 获取服务频道的详细信息

local ngx       = require('ngx')
local msg       = require('msg')
local only      = require('only')
local safe      = require('safe')
local utils     = require('utils')
local gosay     = require('gosay')
local cjson     = require('cjson')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"


local G = {
	sql_check_accountid = "select 1 from userList where accountID='%s' limit 1 ",

	---- 检查申请者的语境账号ID是否有申请过服务频道
	sql_check_apply_record   = " select 1 from applyServiceChannelInfo where accountID='%s' and number='%s' limit 1 ",

	---- 查询申请者申请所有的服务频道
	sql_select_all_apply_channel = " select number, developerName, email, phone, address, channelUrl, channelName, logoUrl, briefIntro, checkStatus " ..
								" from applyServiceChannelInfo where accountID='%s' and number = '%s' ",
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

	if not args['number'] or string.find(args['number'], "'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'number')
	end

	safe.sign_check(args, url_tab)
end

---- 对accountID进行数据库校验
local function check_userinfo( account_id )
	local sql_str = string.format(G.sql_check_accountid, account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)
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

---- 检查申请者的语境账号ID是否有申请过服务频道
local function check_apply_info( account_id, number )

	local sql_str = string.format(G.sql_check_apply_record, account_id, number)
	local ok_status, exsits_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)

	if not ok_status or not exsits_tab or type(exsits_tab) ~= 'table' then
		only.log('E', string.format('connect channel_dbname failed!, %s ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	
	--考虑添加错误码,该账号没有申请过任何频道
	if #exsits_tab == 0 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' 此账户没有这个number的服务频道 ')
	end

 end

local function get_service_channel_info( account_id, number )
	
	local sql_str = string.format(G.sql_select_all_apply_channel, account_id, number)

	local ok_status, channle_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)
	if not ok_status or not channle_tab or type(channle_tab) ~= 'table' then
		only.log('E', string.format('connect channel_dbname failed!, sql_str:[%s] ' , sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	local ok_status, str = pcall(cjson.encode, channle_tab)
    if not ok_status or not str then
        only.log('E','cjson encode failed!')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end

    return #channle_tab ,str
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
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG']," args ")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG']," appKey ")
	end	
	url_tab['app_key'] = args['appKey']

	check_parameter(args)

	check_userinfo(args['accountID'])

	check_apply_info(args['accountID'], args['number'])

	local count, str = get_service_channel_info(args['accountID'], args['number'])

	local ret_str = string.format("{count:%d, list:%s}", count, str)

	if str then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

safe.main_call( handle )