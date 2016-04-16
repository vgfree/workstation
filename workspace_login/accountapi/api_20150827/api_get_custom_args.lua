-- 版权声明：暂无
-- 文件名称：api_get_custom_args.lua
-- 创建者  ：梅树义
-- 创建日期：2015/05/12
-- 文件描述：获取设备开机参数
-- 修改：2015-06-27 zhouzhe

local ngx = require('ngx')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local app_utils = require('app_utils')
local safe = require('safe')

local sql_fmt = {
	sl_model = "SELECT model from modelInfo where model = '%s'",
	-- sl_args = "SELECT call1,call2,domain,port,customArgs FROM configInfo WHERE accountID='%s' AND model='%s'",
	-- sl_default = "SELECT call1,call2,domain,port,customArgs FROM configInfo WHERE model='%s' AND accountID=''",
	sl_registerInfo = "SELECT accountID FROM userList where accountID = '%s'",
	sl_config_info = "select accountID,call1,call2,domain,port,customArgs from configInfo where accountID = '%s' AND model = '%s' "..
	" UNION ALL select accountID,call1,call2,domain,port,customArgs from configInfo where model = '%s' AND accountID = '' LIMIT 1 "

}

local url_info = {
	type_name = 'system',
	app_key = nil,
	client_host = nil,
	client_body = nil,
}
local function check_parameter(args)

	if not args['appKey'] and #args['appKey'] > 10 then
		only.log("E", "appKey is error!")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "appKey")
	end

	url_info['app_key'] = args['appKey']
	safe.sign_check(args, url_info)

	if args['accountID'] and args['accountID'] ~= '' then
		if not app_utils.check_accountID(args['accountID']) then
			only.log("E", "accountID is error , %s", args['accountID'])
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
		end
	end

	if not args['model'] or #args['model'] == 0 then
		only.log("E", "model is error")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
	end
end

local function check_data_exists( args )

	if not args or type(args) ~= "table" then
		only.log("E", "args is error")
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "args")
	end
	-- 检查model是否存在
	local sql = string.format(sql_fmt.sl_model, args['model'])
	local ok, ret = mysql_pool_api.cmd('app_ident___ident', 'select', sql)
	if not ok then
		only.log('E', sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end
	if #ret == 0 then
		only.log("E","model is not exists, %s", args['model'])
		gosay.go_false(url_info, msg["MSG_ERROR_DEVICE_MODEL_INVALID"])
	end

	-- 判断accountID是否合法
	if args['accountID'] and args['accountID'] ~= '' then
		local sql = string.format(sql_fmt.sl_registerInfo, args['accountID'])
		local ok, res = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)
		if not ok then
			only.log('E', sql)
			gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
		end

		if #res == 0 then
			only.log("E", "accountID is not exists, %s", args['accountID'])
			gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
		end
	end
end

local function get_custom_args(args)

	local isDefine = 0
	local isnewModel = 0
	local ret_tab = {}
	-- 获取开机参数
	local sql = string.format( sql_fmt.sl_config_info, args['accountID'],args['model'], args['model'] )
	local ok, res = mysql_pool_api.cmd('app_mirrtalk___config', 'select', sql)
	if not ok or res == nil then
		only.log('E', sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	-- model没有设置开机参数
	if #res == 0 then
		only.log("E", "model is not set custom args , %s", args['model'])
		table.insert(ret_tab,{isDefine=isDefine,isnewModel=isnewModel,call1='',call2='',domain='',port='',customArgs=''})
		local ok,ret = utils.json_encode(ret_tab)
		if not ok then
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "ret_tab encode")
		end
		return ret
		
	-- 开机参数设置有误,数据库存储有误
	elseif #res > 1 then
		only.log('E', string.format('too many record of model in configInfo, %s', sql))
		gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], "model" )

	-- 开机参数设置正确
	else
		if args['accountID'] and  #args['accountID'] == 10 then
			if res[1]['accountID'] and #res[1]['accountID'] == 10 and tostring(res[1]['accountID']) == tostring(args['accountID']) then
				isDefine = 1
			end
		else
			isDefine = 0
		end
		isnewModel = 1
		ok,res[1]['customArgs'] = utils.json_decode(res[1]['customArgs'])
		if not ok then
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "decode")
		end
		table.insert(ret_tab,{isDefine=isDefine,isnewModel=isnewModel,call1=res[1]['call1'],call2=res[1]['call2'],domain=res[1]['domain'],port=res[1]['port'],customArgs=res[1]['customArgs']})
		local ok,ret = utils.json_encode(ret_tab)
		if not ok then
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "ret_tab encode")
		end
		return ret
	end
end

local function handle()

	local pool_body = ngx.req.get_body_data()
	local ip = ngx.var.remote_addr

	if not pool_body or #pool_body == 0 then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_info['client_host'] = ip
	url_info['client_body'] = pool_body

	local args = utils.parse_url(pool_body)
	-- 检查参数
	check_parameter(args)

	args['accountID'] = args['accountID'] or ''
	-- 检查参数书否存在数据库
	check_data_exists( args )	
	-- 获取config信息
	local ret = get_custom_args(args)
	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end

safe.main_call( handle )
