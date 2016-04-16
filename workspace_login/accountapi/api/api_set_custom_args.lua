-- 版权声明：暂无
-- 文件名称：api_set_custom_args.lua
-- 创建者  ：梅树义
-- 创建日期：2015/05/12
-- 文件描述：本文件主要为更新/设置设备开机参数
-- 历史记录：无
-- 修改：2015-06-27 zhouzhe
-- 修改：2015-09-14 wjy add -- check accountID -- configInfo

local ngx = require('ngx')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local utils = require('utils')
local safe = require('safe')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

local config_dbname = "app_mirrtalk___config"
local user_dbname = "app_usercenter___usercenter"
local mirrtalk_dbname = "app_ident___ident"

local sql_fmt = {

	-- 检测model是否存在
	sl_model = "SELECT model from modelInfo where validity=1 AND model = '%s' ",

	-- 检测accountID是否存在
	check_accountID = "SELECT 1 from userLoginInfo where userStatus=1 AND accountID='%s' ",
	
	-- 获取开机参数
	get_customArgs_value = "select accountID,model,call1,call2,domain,port,customArgs,updateTime,remark from configInfo where "..
				" accountID = '%s' AND model = '%s' LIMIT 1 ",

	-- 存在记录，更新开机参数
	upd_args = "UPDATE configInfo SET customArgs='%s',remark='%s', updateTime='%s', domain='%s' WHERE accountID='%s' AND model='%s'",

	-- 不存在插入数据
	ins_args = "INSERT INTO configInfo(accountID,model,call1,call2,domain,port,customArgs,createTime,updateTime,remark) " ..
				" values('%s','%s','%s','%s','%s',%d,'%s','%s','%s','%s') ",
	-- 保存信息在历史表中
	ins_config_history = "INSERT INTO configHistory(accountID,model,call1,call2,domain,port,customArgs,updateTime) values "..
						" ('%s','%s','%s','%s','%s',%d,'%s','%s') ",

}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}
-- 检查参数
local function check_parameter(req_body)

    local args = utils.parse_url(req_body)

    if not args['appKey'] or not utils.is_number(args['appKey']) or  #args['appKey'] < 7 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],"appKey")
    end

	url_info['app_key'] = args['appKey']

	-- check accountID
	if args['accountID'] and args['accountID'] ~= '' then
		if not app_utils.check_accountID(args['accountID']) then
			only.log("E","accountID is error , %s", args['accountID'])
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
		end
	end

	-- check model
	if not args['model'] or #args['model'] == 0 then
		only.log("E", "model is error!")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
	end

	-- check domain
	if not args['domain'] or #args['domain'] == 0 then
		only.log("E", "domain is error!")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "domain")
	end

	-- check customArgs
	if not args['customArgs'] or #args['customArgs'] == 0 then
		only.log("E", "customArgs is error!")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "customArgs")
	end

	local ok = nil
	ok,customArgs = utils.json_decode(args['customArgs'])
	if not ok then
		only.log("E", "customArgs decode is error!, %s",args['customArgs'])
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],"customArgs decode")
	end

	if type(customArgs) ~= 'table' then
		only.log("E", "customArgs table is error!, %s",args['customArgs'])
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "customArgs table")
	end

	safe.sign_check(args, url_info)
	args['accountID'] = args['accountID'] or ''

	return args
end

local function set_config_info(args)
	local tab = {
		call1Number = 10086,
		call2Number = 10086,
		-- domain = 's9d1.mirrtalk.com',
		port = 80,
		remark = "默认开机参数"
	}
	local sql_tab = {}
	local cur_time = os.time()

	if #args['accountID'] > 0 then
		local sql = string.format(sql_fmt.check_accountID, args['accountID'])
		local ok, ret = mysql_api.cmd(user_dbname, 'select', sql)
		if not ok or ret == nil then
			only.log('E', sql)
			gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
		end
		if #ret == 0 then
			only.log('E','accountID is not exists , sql = %s', sql)
			gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
		end
	end

	-- 从modelInfo表中查询,检查model是否存在
	local sql = string.format(sql_fmt.sl_model, args['model'])
	local ok, ret = mysql_api.cmd(mirrtalk_dbname, 'select', sql)
	if not ok or ret == nil then
		only.log('E', sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	if #ret == 0 then
		only.log('E','model is not exists  , sql = %s', sql)
		gosay.go_false(url_info, msg["MSG_ERROR_DEVICE_MODEL_INVALID"])
	end

	-- 获取config信息
	local sql = string.format(sql_fmt.get_customArgs_value, args['accountID'], args['model'] )
	local ok, res = mysql_api.cmd(config_dbname, 'select', sql)

	if not ok or res == nil then
		only.log("E", "check model and accountID whether exists, sql = %s", sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	-- 用户之前没有设置参数，设置传入的参数
	if #res == 0 then
		local sql = string.format(sql_fmt.ins_args, args['accountID'], 
													args['model'], 
													tab['call1Number'], 
													tab['call2Number'], 
													args['domain'], 
													tab['port'] ,
													args['customArgs'],
													cur_time,
													cur_time, 
													args['remark'] or tab['remark'])
		table.insert(sql_tab, sql)
	-- 用户之前设置过开机参数
	else
	
		-- 若当前用户和model存在，判断输入开机参数是否一致，一致直接返回
		if res[1]['customArgs'] == args['customArgs'] then
			only.log("W"," input_customArgs= args_customArgs , customArgs = %s",args['customArgs'])
			local ok = nil
			ok,res[1]['customArgs'] = utils.json_decode(res[1]['customArgs'])
			if not ok then
				only.log("E", "customArgs decode is error!, %s",json_decode)
				gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],"customArgs decode")
			end
			return res
		end
				
		-- 首先更新config_history
		local sql = string.format(sql_fmt.ins_config_history, res[1]['accountID'] or '', 
																res[1]['model'], 
																res[1]['call1'], 
																res[1]['call2'], 
																res[1]['domain'], 
																res[1]['port'],
																res[1]['customArgs'],
																res[1]['updateTime'])
		table.insert(sql_tab, sql)

		-- 更新configInfo表
		local sql = string.format(sql_fmt.upd_args, args['customArgs'], 
													args['remark'] or '', 
													cur_time, 
													args['domain'], 
													args['accountID'], 
													args['model'])
		table.insert(sql_tab, sql)
	end
	local ok, result = mysql_api.cmd(config_dbname, 'AFFAIRS', sql_tab)
	if not ok or result == nil then
		only.log("E", "truncate config info failed, sql = %s",table.concat(sql_tab, '\r\n'))
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	-- 获取更新后的config信息
	local sql = string.format(sql_fmt.get_customArgs_value, args['accountID'], args['model'] )
	local ok, result = mysql_api.cmd(config_dbname, 'select', sql)
	if not ok or result == nil then
		only.log("E", "get_customArgs_value failed, sql=%s ",sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end
	local ok = nil
	ok,result[1]['customArgs'] = utils.json_decode(result[1]['customArgs'])
	if not ok then
		only.log("E","json_decode failed, accountID = %s, customArgs = %s",args['accountID'], result[1]['customArgs'] )
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "decode" )
	end
	return result
end

local function handle()
	local pool_body = ngx.req.get_body_data()
	local ip = ngx.var.remote_addr

	url_info['client_host'] = ip
	url_info['client_body'] = pool_body

	if not pool_body or #pool_body == 0 then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	-- 检查参数
	local args = check_parameter(pool_body)

	-- 设置参数
	local args =  set_config_info(args)

	local ok, ret = utils.json_encode(args)
	if not ok or not ret then
		only.log("E","json_encode failed, accountID = %s, customArgs = %s",args['accountID'], result[1]['customArgs'] )
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"] )
	end

	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end

safe.main_call( handle )
