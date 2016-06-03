
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

local app_config_db = {[1] = 'channel_info'}

local MAX_CAPACITY = 1000

local url_tab = {
	type_name       = 'login',
	app_Key         = '',
	client_host     = '',
	client_body     = '',
}

local G = {
	sql_max_channelID = "SELECT MAX(channelID) FROM tbl_channelInfo",

	sql_create_channel = "INSERT INTO tbl_channelInfo (" ..
	"channelID," ..
	"channelName," ..
	"channelType," ..
	"chIntro," ..
	"logoURL," ..
	"admin," ..
	"aIntro," ..
	"capacity," ..
	"createTime," ..
	"updateTime," ..
	"channelStatus," ..
	"keyWords)" ..
	"VALUES" ..
	"(%d, %s, %d, %s, %s, %s, %s, %s, 1000, %d, %d, %d, %s)",

}



-- 将head 与 body 数据组装
local function parse_form_args(head, body)
	local args = {}
	args['appKey']		= head['appKey']
	args['sign']		= head['sign']
	args['tokenCode']	= head['tokenCode']
	args['timestamp']	= head['timestamp']
	args['accountID']	= head['accountID']

	if body then
		for k, v in pairs(body) do
			args[k] = v
		end
	end

	return args
end

local function check_parameter(args)

end

-- 获取当前最大channelID
local function get_max_channelID()
	local sql_str = string.format(G.sql_max_channelID)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	local ok_status, ok_config = mysql_api.cmd(app_config_db[1], 'SELECT', sql_str)

	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end
	only.log('D', 'ok_config[1] = %s', ok_config[1])

	return tonumber(ok_config[1])
end

-- 执行创建频道操作
local function ready_create_channel(args)
	local max_channelID = get_max_channelID()
	local channelID = max_channelID + 1
	local createTime = os.time()
	local updateTime = createTime
	local channelStatus = 1

	local sql_str = string.format(G.sql_create_channel,
	channelID,
	args['chName'],
	tonumber(args['chType']),
	args['chIntro'],
	args['chLogo'],
	args['accountID'],
	args['aIntro'],
	createTime,
	updateTime,
	channelStatus,
	args['keyWords']
	)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	local ok_status, ok_config = mysql_api.cmd(app_config_db[1], 'SELECT', sql_str)

	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end

	return true, ok_config[1]
end


local function handle()
	local req_header        = ngx.req.get_headers()
	local req_body          = ngx.req.get_body_data()
	local req_ip            = ngx.var.remote_addr

	url_tab['client_body']  = req_body
	local body = cjson.decode(req_body)

	local args = parse_form_args(req_header, body)
	only.log('D', 'args = %s', scan.dump(args))

	check_parameter(args)
	check_accountid(args['accountID'])

	local ok_status, chID = ready_create_channel()

	if ik_status and chID then
		local ret_str = string.format('{"chID":"%s"}', chID)
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

handle()
