---- jiang z.s 
---- 2015-05-22
---- 获取服务频道详情

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local appfun    = require('appfun')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
		sql_get_server_list = " select codeMenu, actionType, customType , defineName,defineLogo, isSystem, briefIntro from userCustomDefineInfo where validity = 1  %s  order by  actionType, sortIndex limit %d,%d  ",
		sql_get_empty_menu_server_list = " select \"\" as codeMenu, actionType, customType , defineName,defineLogo, isSystem, briefIntro from userCustomDefineInfo where validity = 1  %s  order by  actionType, sortIndex limit %d,%d  ",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-->chack parameter
local function check_parameter(args)

	if args['startPage'] then 
		if not tonumber(args['startPage']) or string.find(tonumber(args['startPage']),"%.") or tonumber(args['startPage']) <= 0 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'startPage')
		end
	end

	if args['pageCount'] then
		if not tonumber(args['pageCount']) or string.find(tonumber(args['pageCount']),"%.")  or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'pageCount')
		end
	end

	if args['defineName'] and app_utils.str_count(args['defineName']) > 64 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'defineName')
	end

	if args['actionType'] and #args['actionType'] > 0 then
		local tmp_type = tonumber(args['actionType']) or 0
		if not ( tmp_type == appfun.DK_TYPE_VOICE 
				or tmp_type == appfun.DK_TYPE_COMMAND 
				or tmp_type == appfun.DK_TYPE_GROUP ) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'actionType')
		end
	end

	--放开限制,仅为数字即可(2015/06/02 liuyongheng)
	if args['customType'] and #args['customType'] > 0 then
		local tmp_type = tonumber(args['customType'])

		if not tmp_type then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'customType')
		end
	end

	--校验是否返回频道菜单的依据,仅为数字1才返回
	if args['isDetail'] and #args['isDetail'] > 0 then
		local is_detail = tonumber(args['isDetail'])

		if not is_detail or is_detail ~= 1 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'isDetail')
		end
	end
	safe.sign_check(args, url_tab)
end

local function get_server_list( start_index, page_count, define_name, action_type, custom_type, is_detail )

	local sql_filter = "" 
	if define_name and #tostring(define_name) > 0 then
		sql_filter = string.format(" and ( defineName like '%%%s%%' ) ", define_name )
	end

	if action_type then
		sql_filter = sql_filter .. string.format("  and actionType = %s   " , action_type ) 
	end

	if custom_type then
		sql_filter = sql_filter .. string.format("  and customType = %s   " , custom_type ) 
	end

	local sql_str = nil
	if is_detail == 1 then
		sql_str = string.format(G.sql_get_server_list, sql_filter, start_index, page_count)
	else
		sql_str = string.format(G.sql_get_empty_menu_server_list, sql_filter, start_index, page_count)
	end

	local ok , ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table"  then 
		only.log('E',sql_str )
		only.log('E',string.format(" get server list info failed %s " , sql_str ))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	return ret
end

local function handle()
	local req_ip   = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	local req_method = ngx.var.request_method

	url_tab['client_host'] = req_ip
	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_body'] = req_body

	local args = nil
	if req_method == 'POST' then
		---- 解析表单形式 
		args = utils.parse_url(req_body)
	end

	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		only.log('E',"appKey is ===============")
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
	end

	url_tab['app_key'] = args['appKey']

	check_parameter(args)

	local define_name = args['defineName'] or ''
	local action_type = tonumber(args['actionType'])
	local custom_type = tonumber(args['customType'])
	local is_detail = tonumber(args['isDetail'])

	local start_page = tonumber(args['startPage']) or 1
	local page_count = tonumber(args['pageCount']) or 20
	if start_page < 1 then
		start_page = 1 
	end
	local start_index = ( start_page - 1 ) * page_count

	local ret = get_server_list( start_index ,page_count , define_name , action_type, custom_type, is_detail)
	local count = 0

	local resut = ""
	if not ret or type(ret) ~= "table" or #ret == 0 then
		resut = "[]"
	else
		count = #ret
		local ok, tmp_ret = pcall(cjson.encode,ret)
		if ok and tmp_ret then
			resut = tmp_ret
		end
	end
	local str = string.format('{"count":"%s","list":%s}',count,resut)
	if str then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
