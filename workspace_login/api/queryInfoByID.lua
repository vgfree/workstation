
local utils     = require('utils')
local only      = require('only')
local ngx       = require('ngx')
local gosay     = require('gosay')
local msg       = require('msg')
local safe      = require('safe')
local mysql_api = require('mysql_pool_api')
local scan      = require('scan')

local sql_fmt = {
	get_user_info = " select accountID as accountID,nickname as nickName,headName as headPic,birthday as birthday,gender as sex, activeCity as cityName,cityCode as cityCode,introduction as introduction,carBrand as carBrand,carModels as  carModel, plateNumber as carNumber from userInfo where accountID = '%s' "
}


local weme_car = 'weme_car___car'

local url_info = { 
	type_name = 'system',
	app_key = nil,
	client_host = nil,
	client_body = nil,
	accountID = nil,
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
	url_info['app_key'] = headers['appkey']
	url_info['accountID'] = headers['accountid']
	url_info['token'] = headers['token']
	url_info['timestamp'] = headers['timestamp']
	url_info['sign'] = headers['sign']
	args['app_key'] = headers['appkey']
	args['accountID'] = headers['accountid']
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
	
	-- 检测nil,并重新组装返回结果table  20140416
	local ret 	= {}
	

	ret.accountID 	= (result[1].accountID == 'nil' and "") or result[1].accountID
	ret.nickName 	= (result[1].nickName == 'nil' and "") or result[1].nickName
	ret.headPic 	= (result[1].headPic == 'nil' and "") or result[1].headPic
	ret.birthday 	= (result[1].birthday == 'nil' and "") or result[1].birthday
	ret.sex 	= (result[1].sex == 'nil' and 0) or tonumber(result[1].sex)
	ret.cityName 	= (result[1].cityName == 'nil' and "") or result[1].cityName
	ret.cityCode 	= (result[1].cityCode == 'nil'  and "") or result[1].cityCode
	ret.introduction 	= (result[1].introduction == 'nil'  and "") or result[1].introduction
	ret.carBrand 	= (result[1].carBrand == 'nil' and "") or result[1].carBrand 
	ret.carModel 	= (result[1].carModel == 'nil' and "") or result[1].carModel
	ret.carNumber 	= (result[1].carNumber == 'nil' and "") or result[1].carNumber
	only.log('D', 'result = %s \r\n ret = %s', scan.dump(result), scan.dump(ret))	

	local ok, ret_req = utils.json_encode(ret)
	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_req)
end

safe.main_call( handle )
