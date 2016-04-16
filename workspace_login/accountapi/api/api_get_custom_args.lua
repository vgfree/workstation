-- 版权声明：暂无
-- 文件名称：api_get_custom_args.lua
-- 创建者  ：梅树义
-- 创建日期：2015/05/12
-- 文件描述：获取设备开机参数
-- 修改：2015-06-27 zhouzhe
-- Modify  :qiu mao sheng
-- 2015-10-30

local msg 			 = require('msg')
local ngx 			 = require('ngx')
local only 			 = require('only')
local safe 			 = require('safe')
local gosay 		 = require('gosay')
local utils 		 = require('utils')
local app_utils 	 = require('app_utils')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')

local coreIdent_dbname = "app_ident___ident"
local config_dbname    = "app_mirrtalk___config"
local userList_dbname  =  "app_usercenter___usercenter"

local sql_fmt = {
	-- 检查model是否存在
	sql_sel_check_model = " SELECT 1 from modelInfo where validity=1 AND model = '%s' ",

	-- 检查accountID是否存在
	sql_sel_check_accountid = " SELECT 1 FROM userLoginInfo where accountID = '%s' ",

	-- 查询configInfo信息
	sql_sel_get_config_info = " SELECT accountID,model,call1,call2,domain,port,customArgs,remark,newstatusHost,newstatusPort,feedbackHost, " ..
						 	  " feedbackPort,fetchdataHost,fetchdataPort FROM configInfo where accountID ='%s' AND model ='%s' LIMIT 1 " ..
						 	  " UNION ALL "..
						 	  " select accountID,model,call1,call2,domain,port,customArgs,remark,newstatusHost,newstatusPort,feedbackHost, " ..
						 	  " feedbackPort,fetchdataHost,fetchdataPort FROM configInfo where model = '%s' AND accountID = '' LIMIT 1 ",
}

local url_info = {
	type_name 	= 'system',
	app_key 	= nil,
	client_host = nil,
	client_body = nil,
}

--检查参数中的 %,'
local function check_character( key,parameter )

    local str_res = string.find(parameter,"'")
    local str_tmp = string.find(parameter,"%%")
    if str_res or str_tmp then
        only.log('E', string.format('%s is error !',key))
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], key)
    end
end

-- 1)检查参数
local function check_parameter( body )

	local args = utils.parse_url(body)
	if not args or type(args) ~= "table" then
        only.log('E', "args is error! " )
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], "args")
    end

	url_info['app_key'] = args['appKey']

	--检查组参数中不能含有 %与'
    for a,v in pairs(args) do 
        check_character(a,v)
    end

	if not app_utils.check_accountID(args['accountID']) then
		only.log("E", "accountID is error , %s", args['accountID'])
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
	end

	if not args['model'] or #args['model'] ~= 5 then
		only.log("E", "model is error")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
	end

	safe.sign_check(args, url_info)

	return args
end

-- 2)检查参数是否存在数据库
local function check_data_exists( args )
	-- 检查model是否存在
	local sql = string.format(sql_fmt.sql_sel_check_model, args['model'])
	local ok, ret = mysql_pool_api.cmd(coreIdent_dbname, 'select', sql)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',"sql_sel_check_model is failed, %s ",  sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	if #ret == 0 then
		only.log("E","sql_sel_check_model is not exists, %s", sql)
		gosay.go_false(url_info, msg["MSG_ERROR_DEVICE_MODEL_INVALID"])
	end

	if #ret > 1 then
		only.log('E', "model:%s more than one, %s", args['model'], sql)
		gosay.go_false(url_info, msg["SYSTEM_ERROR"])
	end

	-- 判断accountID是否合法
	local sql = string.format(sql_fmt.sql_sel_check_accountid, args['accountID'])
	local ok, result = mysql_pool_api.cmd(userList_dbname, 'select', sql)
	if not ok or not result or type(result) ~= "table" then
		only.log('E',"sql_sel_check_accountid is failed, %s ",  sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	if #result == 0 then
		only.log("E","sql_sel_check_accountid is not exists, %s", sql)
		gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
	end

	if #result > 1 then
		only.log('E', string.format("accountID:%s more than one, %s", args['accountID']), sql)
		gosay.go_false(url_info, msg["SYSTEM_ERROR"])
	end
end

-- 3)获取config信息
local function get_config_info(args)

	-- isDefine:用户是否设置开机参数 0:否  1:是
	-- isnewModel:当前model是否为新加model（没有设置开机参数）0:否  1：是
	local isDefine
	local isnewModel

	local ret_tab = {}
	-- 获取开机参数
	local sql = string.format( sql_fmt.sql_sel_get_config_info, args['accountID'],args['model'], args['model'] )
	local ok, res = mysql_pool_api.cmd(config_dbname, 'select', sql)
	if not ok or not res or type(res) ~= "table" then
		only.log('E',"sql_sel_get_config_info is failed, %s ",  sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	-- model没有设置开机参数
	if #res == 0 then
		-- isDefine:用户是否设置开机参数 0:否  1:是
		-- isnewModel:当前model是否为新加model（没有设置开机参数）0:否  1：是
		isDefine = 0
		isnewModel = 1

		table.insert(ret_tab, {isDefine=isDefine,isnewModel=isnewModel,call1='',call2='',domain='',port='',customArgs='',
							   newstatusHost='',newstatusPort='',feedbackHost='',feedbackPort='',fetchdataHost='',fetchdataPort=''})

		local ok, ret = utils.json_encode(ret_tab)
		if not ok or not ret then
			only.log("E",string.format("json_encode is error"))
        	gosay.go_false(url_info, msg['MSG_ERROR_REQ_BAD_JSON'])
		end

		return ret

	-- 开机参数设置正确
	else
		-- isDefine:用户是否设置开机参数 0:否  1:是
		-- isnewModel:当前model是否为新加model（没有设置开机参数）0:否  1：是
		isDefine = 1
		isnewModel = 0

		local ok, result = utils.json_decode(res[1]['customArgs'])
		if not ok or not result then
			only.log("E",string.format("json_encode is error"))
        	gosay.go_false(url_info, msg['MSG_ERROR_REQ_BAD_JSON'])
		end

		table.insert(ret_tab, {isDefine=isDefine,isnewModel=isnewModel,accountID= res[1]['accountID'], remark = res[1]['remark'], 
							   call1=res[1]['call1'],call2=res[1]['call2'],domain=res[1]['domain'],port=res[1]['port'],customArgs=result,
							   newstatusHost=res[1]['newstatusHost'],newstatusPort=res[1]['newstatusPort'],feedbackHost=res[1]['feedbackHost'],
							   feedbackPort=res[1]['feedbackPort'],fetchdataHost=res[1]['fetchdataHost'],fetchdataPort=res[1]['fetchdataPort']})

		local ok, ret = utils.json_encode(ret_tab)
		if not ok or not ret then
			only.log("E",string.format("json_encode is error"))
        	gosay.go_false(url_info, msg['MSG_ERROR_REQ_BAD_JSON'])
		end

		return ret
	end
end


local function handle()

	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()

	if not body then
		only.log("D", "body is error!")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_info['client_host'] = ip
	url_info['client_body'] = body

	-- 1)检查参数
	local args = check_parameter(body)

	-- 2)检查参数是否存在数据库
	check_data_exists( args )

	-- 3)获取config信息
	local result = get_config_info(args)

	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], result)
end

safe.main_call( handle )
