-- api_dk_openconfig.lua

local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local link      = require('link')
local cjson     = require('cjson')
local scan	= require('scan')

local app_config_db   = { [1] = 'app_mirrtalk___config', [2] = 'app_mirrtalk___config_gc'}

local url_tab = { 
		type_name   = 'transit',
		app_key     = '',
		client_host = '',
		client_body = '',
}


local G = {
	imei      = '',
	req_ip    = '',
	body      = '',
	err_desc  = '',
	
	cur_month = nil,
	cur_date  = nil,		----
	cur_time  = 0,
	appKey = nil,
	

	sql_openconfig_info = " select customArgs from openconfigInfo where appKey='%s'",
}



---- 执行函数
local function ready_execution(appKey)
	local sql_str = string.format(G.sql_openconfig_info,appKey)
	only.log('W',"mysql select condfig info is :%s",sql_str)
	local ok_status,ok_config = mysql_api.cmd(app_config_db[1],'SELECT',sql_str)
	if not ok_status  then
		only.log('E','connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false,nil
	end
	if not ok_config then
		only.log('E','configInfo return is nil when query sql_openconfig_info')
		return false,nil
	end
	if #ok_config < 1  then
		only.log('E','[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
		return false,nil
	end

	---------------------------------------------------------------------------------------------------
	
	return true,ok_config[1]['customArgs']
end


----检查参数
local function check_parameter(appKey,sign)
	local tmp = appKey
	if not tmp or  #tmp >10 then 
		only.log('E','[CHECK_FAILED]imei: appKey=%s must be less 10 number',appKey)
		return false 
	end 
end



local function go_exit()
	local ret_str = '{"ERRORCODE":"ME01002", "RESULT":"appKey error"}'
	only.log('I','[FAIL] ___appKey error')
	gosay.respond_to_json_str(url_tab,ret_str)
end


local function handle()
	local req_head   = ngx.req.raw_header()
	local req_ip     = ngx.var.remote_addr
	local req_body   = ngx.req.get_body_data()
	local req_method = ngx.var.request_method
	local args       = ngx.req.get_uri_args()

	only.log('D', "body=%s",req_body)
	only.log('D', "method=%s",req_method)
	url_tab['client_host'] = G.req_ip
	---- get_today
	G.cur_month =  string.gsub(string.sub(ngx.get_today(),1,7),"%-","")
	G.cur_date  = string.gsub(ngx.get_today(),"%-","")
	G.cur_time = os.time()

	if req_method == "POST" then
		if not req_body then
			only.log('I', "post body is nil")
			go_exit()
			return
		end
		--args   = utils.parse_url(req_body)
		args   = ngx.decode_args(req_body)
		G.body = string.format('POST %s',req_body)

		if not args or type(args) ~= 'table' then
			only.log('I', "post bad request!")
			go_exit()
			return
		end
	else
		if not args or type(args) ~= 'table' then
			only.log('I', "get bad request!")
			go_exit()
			return
		end
		----G.body = string.format('GET %s',utils.table_to_kv(args) )
		G.body = string.format('GET %s', ngx.encode_args(args) )
	end

	url_tab['client_body'] = G.body

	G.imei      = args['imei']
	G.appKey      = args['appKey']
	
	only.log('D', "appkey=%s",args['appKey'])
	local appKey = args['appKey']
	local sgin = args['sgin']
	local imei = args['imei']
	local imsi = args['imsi']
	local mod  = args['mod']
	local version = args['verno'] or ''

	-- check appKey
	local ok_check = check_parameter(appKey,sign)
	if ok_check == false then
		go_exit()
		return
	end

	if not version or string.find(version,"'") then
		version = ""
	end
	--get openconfig sql
	local ok_status,ok_ret_str = ready_execution(appKey)
	if ok_status == false then
		go_exit()
	end

	--send
	local ret_str = string.format('{"ERRORCODE":"%s", "RESULT":%s}', "0", ok_ret_str )	
	only.log('I','[SUCCED] ___%s',ret_str)
	gosay.respond_to_json_str(url_tab,ret_str)
end

handle()
