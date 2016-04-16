-- 版权声明：暂无
-- 文件名称：api_set_model.lua
-- 创建者  ：梅树义
-- 创建日期：2015/05/16
-- 文件描述：本文件主要为更新/设置model
-- 历史记录：无
--

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
	sl_model = "SELECT model from modelInfo where model = '%s' ",
	upd_args = "UPDATE modelInfo SET company='%s', businessID='%s', isThirdModel='%s', createTime='%s', endTime=unix_timestamp('%s'), validity='%s' WHERE model='%s' ",
	ins_args = "INSERT INTO modelInfo(company,businessID,isThirdModel,createTime,endTime,validity,model) values('%s','%s','%s','%s',unix_timestamp('%s'),'%s','%s')",

}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(str)

	local args = utils.parse_url(str)
	url_info['app_key'] = args['appKey']

	safe.sign_check(args, url_info)

	-- check model
	if not args['model'] or #args['model'] == 0 then
		only.log('E',"model is error !")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
	end

	-- check company
	if not args['company'] or #args['company'] == 0 then
		only.log('E',"company is error !")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "company")
	end

	-- check businessID
	if not args['businessID'] or #args['businessID'] == 0 then
		only.log('E',"businessID is error !")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "businessID")
	end

	-- check isThirdModel
	if not args['isThirdModel'] or #args['isThirdModel'] == 0 then
		only.log('E',"isThirdModel is error !")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "isThirdModel")
	end

	-- check validity
	if not args['validity'] or #args['validity'] == 0 then
		only.log('E',"validity is error !")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "validity")
	end

	-- check endTime
	if not args['endTime'] or #args['endTime'] == 0 then
		only.log('E',"endTime is error !")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "endTime")
	end

	return args
end


local function set_update_model(args)

	local cur_time = os.time()

	-- 从modelInfo表中查询,检查model是否存在
	local sql = string.format(sql_fmt.sl_model, args['model'])
--	only.log('D', sql)
	local ok, ret = mysql_pool_api.cmd('app_ident___ident', 'select', sql)
	if not ok then
		only.log('E',"select mysql failed!")
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	-- 若不存在，在表中插入新数据
	if #ret == 0 then
		local insert_sql = string.format(sql_fmt.ins_args,args['company'], args['businessID'], args['isThirdModel'], cur_time, args['endTime'], args['validity'], args['model'])
		only.log('D', insert_sql)
		local ok, ret = mysql_pool_api.cmd('app_ident___ident', 'INSERT', insert_sql)
		if not ok then
			only.log('E',"insert mysql failed!")
			gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
		end

	-- 表中记录有多条
	elseif #ret > 1 then
		only.log('D', string.format('too many record of model:%s in coreIdentification.modelInfo', args['model']))
		gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'model')

	else
	-- 表中已有model类型的数据，更新原有数据
		local update_sql = string.format(sql_fmt.upd_args,args['company'], args['businessID'], args['isThirdModel'], cur_time, args['endTime'], args['validity'], args['model'])
		only.log('D', update_sql)
		local ok, ret = mysql_pool_api.cmd('app_ident___ident', 'UPDATE', update_sql)
		if not ok then
			only.log('E',"update mysql failed!")
			gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
		end
	end

	local ok, ret = utils.json_encode(args)
	if not ok then
		gosay.go_false(url_info, msg["SYSTEM_ERROR"])
	end
	return ret
end

local function handle()

	local body = ngx.req.get_body_data()
	local ip = ngx.var.remote_addr

	url_info['client_host'] = ip
	url_info['client_body'] = body

	if not body or #body == 0 then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	local args = check_parameter(body)

	local ret = set_update_model(args)

	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end

safe.main_call( handle )
