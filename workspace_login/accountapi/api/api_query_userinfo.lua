
local utils     = require('utils')
local only      = require('only')
local ngx       = require('ngx')
local gosay     = require('gosay')
local msg       = require('msg')
local safe      = require('safe')
local mysql_api = require('mysql_pool_api')
local scan      = require('scan')

local sql_fmt = {

	get_user_info = " select accountID as accountID,nickname as nickName,headName as headPic,birthday as birthday,gender as sex, city as cityName,'' as cityCode,introduction as introduction,carBrand as carBrand,carModels as  carModel, plateNumber as carNumber from userInfo where accountID = '%s' "
}


local weme_car = 'weme_car___car'

local url_info = { 
	type_name = 'system',
	app_key = nil,
	client_host = nil,
	client_body = nil,
	accountId = nil,
	token = nil,
	timestamp = nil,
	sign = nil
}

-->chack parameter
local function check_parameter(args)


	-->> safe check
--	safe.sign_check(args, url_info)

end

local function handle()

	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()
	local headers = ngx.req.get_headers()
	only.log('D','%s',scan.dump(headers))
	local args= {}

	url_info['client_host'] = ip
	url_info['client_body'] = body
	url_info['app_key'] = headers['appKey']
	url_info['accountID'] = headers['accountID']
	url_info['token'] = headers['token']
	url_info['timestamp'] = headers['timestamp']
	url_info['sign'] = headers['sign']
	args['app_key'] = headers['appKey']
	args['accountID'] = headers['accountID']
	args['token'] = headers['token']
	args['timestamp'] = headers['timestamp']
	args['sign'] = headers['sign']

	-->check parameter
	check_parameter(args)

	local account_id = args['accountID']

	local sql = string.format(sql_fmt.get_user_info, account_id )
	local ok, result = mysql_api.cmd(weme_car, 'select', sql)
	if not ok or not result then
		only.log('E',string.format("get user info failed , %s ", sql))
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	if #result==0 then
		gosay.go_success(url_info, msg['MSG_ERROR_USER_NAME_NOT_EXIST'])
	end
	only.log('D','%s',scan.dump(result))

	local ok, ret_req = utils.json_encode(result[1])
	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_req)
end

safe.main_call( handle )
