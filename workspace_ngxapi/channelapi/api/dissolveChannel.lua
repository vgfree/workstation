-- CopyRight	: DT+
-- Author	: louis.tin
-- Date		: 05-21-2016
-- Description	: Dissolve channel


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
local cur_utils = require('clientcustom_utils')

local G = {

}

local url_tab = {
	type_name	= 'system',
	app_Key		= '',
	client_host	= '',
	client_body	= '',
}

local function check_parameter(args)
	if not args then
		only.log('E',string.format('call parse_url function return nil!'))
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_BAD_JSON"])
	end

	if not args['appKey'] or #args['appKey'] > 10 then
		only.log("E", "appKey is error")
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'appKey')
	end
	url_tab['app_Key'] = args['appKey']

	if (not app_utils.check_accountID(args['accountID'])) then
		only.log("E", "accountID is error")
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"], "accountID")
	end

	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_USER_INFO)
end

-- TODO 待补充
local function dissolve_channel_info(channelID)


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

	local args		= {}
	args['appKey']		= req_head['appKey']
	args['sign']		= req_head['sign']
	args['tokenCode']	= req_head['tokenCode']
	args['accountID']	= req_head['accountID']
	args['timestamp']	= req_head['timestamp']
	args['chID']		= body['chID']

	check_parameter(args)

	only.log('D', 'url_tab = %s', scan.dump(url_tab))
	only.log('D', 'args = %s', scan.dump(args))

	local ok = dissolve_channel_info(args['chID'])
	if ok then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], 'ok')
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

handle()

