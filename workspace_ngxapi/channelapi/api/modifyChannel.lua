-- CopyRight	: DT+
-- Author	: louis.tin
-- Date		: 05-23-2016
-- Description	: Modify channel information


local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local appfun    = require('appfun')
local cjson     = require('cjson')
local sha       = require('sha1')
local mysql_api = require('mysql_pool_api')

local G = {

}

local url_tab = {
	type_name	= 'system',
	app_Key		= '',
	client_host	= '',
	client_body	= '',
}

local function check_parameter(args)
	if  not app_utils.check_accountID(args['accountID'])  then
		only.log('E',"accountID is error")
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

end

-- 从mysql中去检查accountID
local function check_accountID(accountID, chID)
	local sql_str = string.format(G.sql_check_accountID, accountID)
	local ok,ret  = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)
	if not ok or not ret then
		only.log('E',string.format("userList tab connect failed!sql_str is %s", sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		only.log('E', string.format("cur user is not exit,sql_str is %s", sql_str))
		gosay.go_false(url_tab, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
	end
	if #ret > 1 then
		only.log('E', "[*****]check_accountID SYSTEM_ERROR ")
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end



-- TODO 待补充
local function dissolve_channel_info(channelID)


end

local function parse_form_args(head, body)
	local args = {}
	for k, v in pairs(head) do
		args[k] = v
	end

	if body then
		for k, v in pairs(body) do
			args[k] = v
		end
	end

	return args
end


local function handle()

	local req_ip = ngx .var.remote_addr
	local req_head = ngx.req.get_headers()
	local req_body = ngx.req.get_body_data()
	local req_method = ngx.var.request_method

	url_tab['client_host'] = req_ip
	if not req_body then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], "body")
	end
	url_tab['client_body'] = req_body

	body = cjson.decode(req_body)

	local args = parse_form_args(req_head, body)

	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'args')
	end
	if not args['appKey'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'appKey')
	end

	url_tab['app_Key'] = args['appKey']

	only.log('D', 'args = %s', scan.dump(args))


	check_parameter(args)

	only.log('D', 'url_tab = %s', scan.dump(url_tab))
	only.log('D', 'args = %s', scan.dump(args))


	-- 检查accountID在数据库中是否存在
	check_accountID(args['accountID'], args['chID'])

	-- 得到频道详情,并检查用户是否为admin
	local chName, chIntro, aIntro, chLogo, keyWords = get_channel_info(args['accountID'], args['chID'])

	-- 执行修改操作
	local ok = modify_channel_info(
	args['accountID'],
	args['chID'],
	args['chName'] or chName,
	args['chIntro'] or chIntro,
	args['aIntro'] or aIntro,
	args['chLogo'] or chLogo,
	args['keyWords'] or keyWords)

	if ok then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], 'ok')
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	--]]
end

handle()

