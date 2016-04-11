--author: 
--remark: 批量获取用户++键的设置值
--date:    2015-01-28

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
local weibo     = require('weibo')
local appfun    = require('appfun')

local custom_dbname = 'app_custom___wemecustom'
local userlist_dbname = 'app_usercenter___usercenter'

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}
--最大值由100改成了500
--hou.y.q 2015-09-11
--减少调用服务器次数

local MAX_COUNT = 500 


local G = {
	sql_check_accountID = "select accountID from userList where accountID in ( '%s' ) " ,
	sql_select_channelName = " select name , number from checkSecretChannelInfo where number in( '%s' ) " ,
	sql_select_number   = " SELECT accountID,customType,customParameter,'' as parameterName FROM  userKeyInfo " .. 
						" WHERE actionType = 5 and accountID in ( '%s' )",
}

-->chack parameter
local function check_parameter(args)
	---- 校验参数
	---- 1 accountIDs , 使用逗号分割
	if not args['accountIDs'] or #args['accountIDs'] == 0 or string.find(args['accountIDs'],"'") then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountIDs')
	end

	---- 2 比较count总数是否大于最大阀值(MAX_COUNT) 
	if args['count'] then
		if not tonumber(args['count']) or tonumber(args['count']) > MAX_COUNT or tonumber(args['count']) < 1  then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'count')
		end
	end

	safe.sign_check(args, url_tab)
end


local function batch_fetch_userkeyinfo( accountids )
	
	local sql = string.format(G.sql_check_accountID,table.concat(accountids,"','"))
	local ok,ret = mysql_api.cmd(userlist_dbname,'SELECT',sql)
	if not ok or not ret then
		only.log('E',string.format("mysql failed , %s",sql))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if type(ret) ~= "table" or #ret == 0 then
		only.log('E',string.format("ret == 0 select userList,sql %s",sql))
		return false
	end
	local accountid = {}
	for i ,v in pairs(ret) do
		table.insert(accountid,v['accountID'])		
	end
	---- 20150617
	---- 增加返回参数，parameterName频道名
	local sql_str =  string.format(G.sql_select_number, table.concat( accountid, "','") )
	local ok , result = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
	if not ok or not result then
		only.log('E',string.format("mysql failed , %s",sql_str))
		return false
	end
	if #result == 0 or type(result)	~= "table" then
		only.log('E',string.format("result == 0 select userKeyinfo ,sql %s",sql_str))
		return false
	end

	local number_list = {}
	local channelname_list = {}
	for i ,v in pairs(result) do
		table.insert(number_list,v['customParameter'])
	end
	local sql_str = string.format(G.sql_select_channelName,table.concat(number_list,"','") )
	local ok,nameList = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
	if not ok or not nameList or type(nameList) ~= 'table' then
		return false
	end
	for i , v in pairs(nameList) do
		channelname_list[v['number']] = v['name']
	end
	for i ,v in pairs(result) do
		result[i]['parameterName'] = channelname_list[v['customParameter']] or ''
	end
	---- end

	return result
end


local function handle()
	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	local req_head = ngx.req.raw_header()

	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_tab['client_host'] = req_ip
	url_tab['client_body'] = req_body

	local req_method = ngx.var.request_method
	local args = nil
	if req_method == 'POST' then
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')
      	if not boundary then
			args = utils.parse_url(req_body)
			-- args = ngx.decode_args(req_body)
		else
			args = utils.parse_form_data(req_head, req_body)
		end
	end

	if not args or type(args) ~= "table" then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	url_tab['app_key'] = args['appKey']
	check_parameter(args)

	local count = tonumber(args['count']) or 0

	local accountids = {} 

	if count == 1 then
		table.insert(accountids,args['accountIDs'])
	elseif count > 1 then
		accountids = utils.str_split(args['accountIDs'],",")
	end
	if not accountids or type(accountids) ~= "table" then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"accountIDs")
	end

	if count ~= #accountids then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'count')
	end

	local fmt = '{"count":"%s","success":"%s","failed":"%s","list":%s}'
	local tab = batch_fetch_userkeyinfo( accountids )
	
	local str = "[]"
	if type(tab) == "table" then 
		if #tab > 0 then
			
			local failed = count - #tab
			local ok, ret = pcall(cjson.encode, tab)
			if ok and ret then
				str = string.format( fmt, count,#tab,failed, ret )
			end
		end
	end
	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], str)
end

safe.main_call( handle )
