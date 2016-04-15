-- api_login
-- author : louis
-- date	  : 04-14-2016
-- 登录接口
local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local link      = require('link')
local cjson     = require('cjson')
local scan	= require('scan')

-- TODO 指定base userInfo 等参数的数据库
local app_config_db   = { [1] = '', [2] = ''}

local url_tab = { 
	type_name   = 'login',
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
	cur_date  = nil,
	cur_time  = 0,
	appKey = nil,


	-- sql_openconfig_info = " select customArgs from openconfigInfo where appKey='%s'",
	-----------------------------------------------------------------------
	-- TODO base roadRank sicong userInfo 的值都是从mysql中读取,表格未建立
	sql_login_info = "",
	sql_login_userInfo = ""
}


---- 执行函数
local function ready_execution(appKey)
	local sql_str = string.format(G.sql_login_info, appKey)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	-- TODO 指定执行目标数据库
	local ok_status, ok_config = mysql_api.cmd(app_config_db[1], 'SELECT', sql_str)

	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end
	if #ok_config < 1  then
		only.log('E', '[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
		return false, nil
	end

	---------------------------------------------------------------------------------------------------

	return true, ok_config[1]['base'], ok_config[1]['roadRank'], ok_config[1]['sicong']
end

local function ready_execution_userInfo(appKey)
	local sql_str = string.format(G.sql_login_userInfo, appKey)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	-- TODO 指定执行目标数据库
	local ok_status, ok_config = mysql_api.cmd(app_config_db[2], 'SELECT', sql_str)

	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end
	if #ok_config < 1  then
		only.log('E', '[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
		return false, nil
	end

	---------------------------------------------------------------------------------------------------

	return true, ok_config[1]['userInfo']
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
	only.log('E','appKey error')
	gosay.respond_to_json_str(url_tab,ret_str)
end

local function handle()
	local req_head   = ngx.req.raw_header()
	local req_ip     = ngx.var.remote_addr
	local req_body   = ngx.req.get_body_data()
	local req_method = ngx.var.request_method
	local args       = ngx.req.get_uri_args()
	-- 获取head
	local header	 = ngx.req.get_headers() 

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
	--[[
	-- 获取请求参数
	local appKey		= header['appKey']
	local sign		= header['sign']
	local accessToken	= header['accessToken']
	local timestamp		= header['timestamp']
	local accountID		= header['accountID']
	local imei		= header['imei']
	local imsi		= header['imsi']
	local modelVer		= header['modelVer']
	local androidVer	= header['androidVer']
	local baseBandVer	= header['baseBandVer']
	local kernelVer		= header['kernelVer']
	local buildVer		= header['buildVer']
	local lcdWidth		= header['lcdWidth']
	local lcdHeight		= header['lcdHeight']

	-- 检查appKey
	local ok_check = check_parameter(appKey,sign)
	if ok_check == false then
	go_exit()
	return
	end

	-- 从mysql中获取base roadRank sicong 参数
	local ok_status, ok_ret_base, ok_ret_roadRank, ok_ret_sicong = ready_execution(appKey)
	if ok_status == false then
	go_exit()
	end
	-- 从mysql中获取 userInfo 参数
	local ok_status, ok_ret_userInfo = ready_execution_userInfo(appKey)
	if ok_status == false then
	go_exit()
	end

	--]]
	-- 暂时先返回固定参数
	local appKey		= "bcYtC65Gc89"
	local sign		= "45456asdfserwerwefasdfsdf"
	local accessToken	= "1472583690"
	local timestamp		= "1458266656"
	local accountID		= "PdL1eoEl7P"
	local imei		= "147258369015935"
	local imsi		= "460011234453214"
	local modelVer		= "sony"
	local androidVer	= "5.1"
	local baseBandVer	= ""
	local kernelVer		= ""
	local buildVer		= ""
	local lcdWidth		= "1080"
	local lcdHeight		= "1920"

	-- 检查appKey
	local ok_check = check_parameter(appKey,sign)
	if ok_check == false then
		go_exit()
		return
	end

	-- 从mysql中获取base roadRank sicong 参数
	local ok_ret_base		= {}
	ok_ret_base['msgServer']	= "scsever.daoke.me"
	ok_ret_base['msgPort']		= 8282
	ok_ret_base['heart']		= 30
	ok_ret_base['fileUrl']		= "http://oss-cn-hangzhou.aliyuncs.com"
	
	-- 从mysql中获取 userInfo 参数
	local ok_ret_userInfo		= {}
	ok_ret_userInfo['sex']		= 1
	ok_ret_userInfo['nickName']	= 'louis'
	ok_ret_userInfo['headerUrl']	= "http://roadrank.daoke.me/road/img/11736.jpg"
	ok_ret_userInfo['cityName']	= "杭州市"
	
	local ok_ret_roadRank		= {}
	ok_ret_roadRank['rrIoUrl']	= "http://rtr.daoke.io/roadRankapi"
	ok_ret_roadRank['normalRoad']	= 1000
	ok_ret_roadRank['highRoad']	= 5000
	ok_ret_roadRank['askTime']	= 180
	
	local ok_ret_sicong		= {}
	ok_ret_sicong['serverType']	= 1

	-- 返回信息
	local ret_str = string.format('{"err":"%s", "result":{"token":"%s", "msgToken":"%s", "accountID":"%s", "base":"%s", "roadRank":"%s", "sicong":"%s", "userInfo":"%s"}}', "0", token, msgToken, accountID, ok_ret_base, ok_ret_roadRank, ok_ret_sicong, ok_ret_userInfo)	
	only.log('I','[SUCCED] ___%s',ret_str)
	gosay.respond_to_json_str(url_tab,ret_str)
end

handle()
