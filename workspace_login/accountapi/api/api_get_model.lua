-- 版权声明：暂无
-- 文件名称：api_get_model.lua
-- 创建者  ：梅树义
-- 创建日期：2015/05/20
-- 文件描述：获取model类型的相关参数
-- 历史记录：无 

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

	sl_model = "SELECT company,model,validity,businessID,isThirdModel from modelInfo where model = '%s'",
}

local url_info = {
	type_name = 'system',
	app_key = nil,
	client_host = nil,
	client_body = nil,
}
local function get_model(str)

	local args = utils.parse_url(str)
	url_info['app_key'] = args['appKey']

	safe.sign_check(args, url_info)
	
	if not args['model'] or #args['model'] == 0 then
        		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
	end

	local sql = string.format(sql_fmt.sl_model, args['model'])
	only.log('D', sql)
	local ok, ret = mysql_pool_api.cmd('app_ident___ident', 'select', sql)
	if not ok then
		only.log('E',"select from mysql failed !")
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end
	if #ret == 0 then
		only.log('D',"model not exist !")
		gosay.go_false(url_info, msg["MSG_ERROR_DEVICE_MODEL_INVALID"])

	elseif #ret > 1 then
		only.log('D', string.format('too many record of model:%s in coreIdentification.modelInfo', args['model']))
		gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'model')
	end

	local ok, res = utils.json_encode(ret)

	return res
end

local function handle()

	local pool_body = ngx.req.get_body_data()
	local ip = ngx.var.remote_addr

	url_info['client_host'] = ip
	url_info['client_body'] = pool_body

	local ret = get_model(pool_body)

	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end

safe.main_call( handle )
