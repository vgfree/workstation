-- api_dk_config.lua
-- auth: jiang z.s.
-- date: 2015-04-15
-- daoke I/O 2.0 

local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local link      = require('link')
local cjson     = require('cjson')
local http_api  = require('http_short_api')
local dk_utils  = require('dk_utils')

-- ---- 终端 IMEI 类型标志 ------------------------------
-- DK_IMEI_MANUFACTURE = 1    ----- IMEI 生产终端
-- DK_IMEI_ENGINEERING = 2    ----- IMEI 工程终端
-- ---- 终端 IMEI 类型标志 ------------------------------

-- --------------------------------------------------
-- ----- 当前代码所属类型 ---------------------------
-- ----- 1正式环境  0工程环境
-- DK_CODE_EVN_MANUFACTURE = 1   ---- feedback ,newStatus
-- --------------------------------------------------


local app_url_db      = { [1] = 'app_url___url' , [2] = 'app_url___url_gc' }
local app_config_db   = { [1] = 'app_mirrtalk___config', [2] = 'app_mirrtalk___config_gc'}
local app_identify_db = 'app_identify___coreIdentification'


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
	cur_type  = 1,		----- 1生产数据,2工程测试数据
	cur_time  = 0,
	accountid = nil,
	tokencode = nil,

	sql_save_urllog = "insert into urlLog_%s(createTime,url,clientip,returnValue) values(unix_timestamp() , '%s' , inet_aton('%s') , '%s' )",
	-- sql_check_imei = "select status from mirrtalkInfo where concat(imei,nCheck) = '%s' and model = '%s' and validity = 1 and unix_timestamp() <= endTime limit 1 ",
	sql_check_imei = "select status from mirrtalkInfo where imei = %d and nCheck = %d and model = '%s' and validity = 1 and unix_timestamp() <= endTime limit 1 ",
	sql_check_mod  = "select 1 as F from modelInfo   where validity = 1 and model = '%s' and unix_timestamp() <= endTime limit 1 ",
	sql_config_info = " select  '' tokencode, call1,call2,fetchdataHost,fetchdataPort, newstatusHost,newstatusPort,feedbackHost,feedbackPort," ..
					 "  customargs from configInfo where accountID = '%s' limit 1 " ..
					 " union all select '' tokencode,  call1,call2,fetchdataHost,fetchdataPort, newstatusHost,newstatusPort,feedbackHost,feedbackPort, " .. 
					 "  customargs from configInfo where accountID = '' and model='%s' limit 1 ",

	sql_user_poweron = "INSERT INTO userPowerOnInfo(createTime, accountID, imei,imsi,model, tokenCode, tokenCodeEndTime,travelID,version) values(unix_timestamp(), '%s', '%s', '%s', '%s' , '%s' , (unix_timestamp() + 48*60*60) ,%s , '%s' )",
}


local function save_urllog(returnValue )
	----- 日志写ts_db
	if G.cur_type ~= dk_utils.DK_IMEI_ENGINEERING then
		dk_utils.set_urlLog(G.imei,G.body,G.req_ip,returnValue, G.cur_time )
	end

	---- 正式生产环境/不写url日志
	if G.cur_type == dk_utils.DK_IMEI_MANUFACTURE and tonumber(dk_utils.DK_WRITE_MYSQL_WITH_URL) == 0 then
		return
	end

	---- 测试硬件终端
	local sql_str = string.format(G.sql_save_urllog,G.cur_month,G.body,G.req_ip,returnValue)
	local ok_status,ok_ret = mysql_api.cmd(app_url_db[G.cur_type],'INSERT',sql_str)
	if not ok_status then
		only.log('E','[save_urllog] insert database failed! %s ', sql_str )
	end
end

----判断用户当天config次数是否小于30次
----返回值
----第一个: false超过使用限制,或者程序出错
----        true
local function check_configindex(imei)
	----判断IMEI当天请求次数是否>30
	local configkey = string.format("%s:configIndex",imei)
	local ok_status,ok_config = redis_api.cmd('private','get', configkey)
	if not ok_status then
		only.log('E', string.format('connect redis failed when get %s  ',configkey))
		return false
	end

	local iIndex = 0 
	if ok_config then
		local iDay = string.match(ok_config,"(%d+),")
		if (tonumber(iDay) or 0 ) == tonumber(G.cur_date)  then
			iIndex = string.match(ok_config,",(%d+)")
			if (tonumber(iIndex) or 0 ) >= dk_utils.MAX_CONFIG_INDEX then
				only.log('E',string.format("[CHECK_FAILED] %s  more then 30,error", configkey))
				return false	
			end
			iIndex = tonumber(iIndex) or 0
		end
	end

	iIndex = iIndex + 1
	redis_api.cmd('private','set', configkey, string.format("%s,%s",G.cur_date, iIndex) )
	return true
end


----根据imei获取accountID
----返回值
----第一个: false调用失败, true 调用成功
----第二个: false不存在imei:accountID   true 存在imei:accountID
----第三个: 字符串,第二个如果为true,则返回 accountID  否则返回imei
local function get_accountid(imei)
	----获取accountID
	local is_exist = false
	local ok_status,accountID = redis_api.cmd('private','get' ,imei .. ':accountID')
	if not ok_status then
		only.log('E',string.format('[CHECK_FAILED]connect redis failed when get %s:accountID',imei))
		return false,false,nil
	end
	if not accountID or #accountID ~= 10 then
		is_exist = false
	else
		is_exist = true
	end 
	return true,is_exist,accountID
end

local function save_poweron_to_table( imei,imsi,mod,token_code ,version )
	---- 当前时间
	---- now 		1403933518.377
	---- time 	1403933518
	local cur_socktime = string.format("%.3f", ngx.now() )
	local cur_time     = os.date("%Y%m%d%H%M%S", G.cur_time )

	---- 当前毫秒
	local cur_millisecond = string.sub(cur_socktime,string.find(cur_socktime,"%.")+1,cur_socktime + 3 )

	local travel_id = string.format("%s%s%s", string.sub(cur_time,3,14), cur_millisecond ,string.sub(imei,11,15) )
	local travel_key = string.format("%s:travelID",imei)
	redis_api.cmd('private', 'set',travel_key , travel_id)

	G.travel_id = travel_id

	local sql_str = string.format(G.sql_user_poweron,(G.accountid or ''),imei,imsi,mod,token_code,travel_id,version)
	local ok_status,ok_ret = mysql_api.cmd(app_config_db[G.cur_type],'INSERT',sql_str)
	if not ok_status then
		only.log('E','connect database failed when insert sql_user_poweron, %s  ', sql_str) 
		return false
	end
	
	return true
end


local function save_data_to_redis(accountid)
	
	---- 开机加入在线用户列表
	redis_api.cmd('statistic', 'sadd', 'onlineUser:set', accountid )

end

---- 执行函数
local function ready_execution(imei,imsi,mod,version)
	----获取accountID
	local ok_status, is_exist,account_id  = get_accountid(imei)
	if ok_status == false then return false,nil end
	local tmp_accid = account_id or imei

	G.accountid = account_id
	

	----查询accountID对应的相关信息
	local sql_str = string.format(G.sql_config_info,tmp_accid,mod)
	local ok_status,ok_config = mysql_api.cmd(app_config_db[1],'SELECT',sql_str)
	if not ok_status  then
		only.log('E',sql_str)
		only.log('E','connect database failed when query sql_config_info, %s ', sql_str)
		return false,nil
	end
	if not ok_config then
		only.log('E','configInfo return is nil when query sql_config_info')
		return false,nil
	end
	if #ok_config < 1  then
		only.log('E','[READY_FAILED]return empty when query sql_config_info, %s ' , sql_str)
		return false,nil
	end

	----生成tokenCode  存取方式 imei:tokenCode
	local token_key = string.format("%s:tokenCode",imei)
	local token_code = utils.random_string(10)
	local ok,ret = redis_api.cmd('private', 'set', token_key, token_code)
	if not ok then
		only.log('E','connect redis failed when set %s',token_key)
		return false,nil
	end

	local ok,ret = redis_api.cmd('private','expire',token_key, dk_utils.TOKENCODE_EXPIRE )
	if not ok then
		only.log('E','connect redis failed when expire %s',token_key)
		return false,nil
	end

	G.tokencode = token_code
	------- save  powerOn  log --------------------------------------------------
	local ok_status = save_poweron_to_table(imei,imsi,mod,token_code,version)
	if not ok_status then
		return false,nil
	end
	------- save powerOn  log --------------------------------------------------

	if G.cur_type == dk_utils.DK_IMEI_MANUFACTURE then
		save_data_to_redis(tmp_accid)
	end
	---------------------------------------------------------------------------------------------------

	local custom_str = ok_config[1]['customargs']
	local ok_status , custom_tab = pcall(cjson.decode,custom_str)
	if ok_status and custom_tab then
		local ok_status,ok_voice_type = redis_api.cmd('private','get',tmp_accid .. ':voiceCommandCustomType')
		if ok_status and ok_voice_type then 
			custom_tab['voiceCommand'] = true
			ok_status , custom_str = pcall(cjson.encode,custom_tab)
			if ok_status or custom_str then
				only.log('D',"--accountid:%s change voiceCommand set true",tmp_accid)
			end
		end
	end

	ok_config[1]['customargs'] = custom_tab
	ok_config[1]['tokencode'] = token_code

	if G.cur_type == dk_utils.DK_IMEI_ENGINEERING then
		ok_config[1]['domain'] =  "s9gc.mirrtalk.com"  --"s9gc.mirrtalk.com"
		ok_config[1]['port']= "80"
	end

	local ok , result_txt = pcall(cjson.encode,ok_config[1])
	only.log('W',result_txt)
	return true,result_txt
end


----检查参数
local function check_parameter(imei,imsi,mod)
	if not imei or not imsi or not mod then
		only.log('E','[CHECK_FAILED]params is nil -->imei:%s  imsi:%s, mod:%s ', imei, imsi, mod ) 
		return false
	end

	if #imei ~= 15 or #imsi ~= 15 or #mod ~= 5   then
		only.log('E','[CHECK_FAILED] IMEI:%s ,IMSI:%s , mod:%s  params length error',imei, imsi, mod )
		return false 
	end

	----检测imei是否为15位数字
	local tmp = string.match(imei,'%d+')
	if not tmp or  #tmp ~= 15 then 
		only.log('E','[CHECK_FAILED]imei:%s  must be number',imei)
		return false 
	end 

	----检测imsi是否为15位数字
	local tmp = string.match(imsi,'%d+')
	if not tmp or #tmp ~= 15 then
		only.log('E','[CHECK_FAILED]imsi:%s must be number',imei)
		return false 
	end

	----检测mod是否为大写字符+数字组合
	local tmp = string.match(mod,'%w+')
	if not tmp or #tmp ~= 5 then
		only.log('E','[CHECK_FAILED]imsi:%s mod:%s be number and letter',imsi,mod)
		return false 
	end
	if string.upper(tmp) ~= tmp then
		only.log('E','[CHECK_FAILED]imei:%s mod:%s must be uppercase letters',imei,mod)
		return false 
	end

	----检查imei数据库中是否存在,且有效
	-- local sql_str = string.format(G.sql_check_imei,imei,mod)
	---- IMEI = imei + nCheck 
	---- 拆分为2个字段 2014-09-16
	local sql_str = string.format(G.sql_check_imei, string.sub(imei,1,14),string.sub(imei,-1) ,mod)
	local ok_check,ret_check = mysql_api.cmd(app_identify_db,'SELECT',sql_str)
	if not ok_check or ret_check == nil then
		only.log('E','[CHECK_FAILED]connect database failed or get IMEI result is nil')
		return false
	end
	if #ret_check ~= 1 then
		only.log('D','[CHECK_FAILED]IMEI:%s query succed but get record is empty',imei)
		return false 
	end

	----10a、10r和11b三种状态都进入工程模式；13g为正常工作模式；**p不允许使用。注意coreIdentification.mirrtalkInfo表中，validity=0或者endTime小于当前时间都不允许使用
	if ret_check[1]['status'] == "10a" or ret_check[1]['status'] == "10r" or ret_check[1]['status'] == "11b" then
		---- 工程模式
		G.cur_type = dk_utils.DK_IMEI_ENGINEERING
	elseif (string.find(ret_check[1]['status'],"p")) then
		only.log('E',"imsi:%s -->---status is error:%s", imei, ret_check[1]['status'] ) 
		return false
	end



	----检查mod数据库中是否存在,且有效
	local sql_str = string.format(G.sql_check_mod,mod)
	local ok_check,ret_check = mysql_api.cmd(app_identify_db,'SELECT',sql_str)
	if not ok_check or ret_check == nil then
		only.log('E','[CHECK_FAILED]connect database failed or get IMSI result is nil')
		return false
	end
	if #ret_check ~= 1 then
		only.log('D','[CHECK_FAILED]mod:%s query succed but get record is empty',mod)
		return false 
	end
	----校验合法
	return true
end

-----数据发送给driview
local function post_poweron_status_to_data_routing(args)
	local ok_ret = string.format('{"powerOn":true,"accountID":"%s","tokenCode":"%s","model":"%s"}',
					G.accountid or args['imei'],
					G.tokencode,
					args['mod'])
	local host_info = link['OWN_DIED']['http']['supeX']  ---- supeX 数据转发

	---- post data with json 2014-09-23 
	local data = utils.compose_http_json_request( host_info ,'publicentry', nil , ok_ret)

	local ok, ret = http_api.http_ex(host_info , data ,false,"DRIVIEW_SERVER",60)
	if not ok then
		only.log('E',"post_poweron_status_to_supeX  failed!!!  %s " , data )
		return false
	end

	only.log('D',data)

	return true
end


---------数据发送给dataCenter 2014-09-26 
local function post_poweron_status_to_dataCore( imei, accountid ,tokencode, travelid )

	local ok, preTimestamp = redis_api.cmd('private', 'get',  string.format("%s:heartbeatTimestamp",(accountid or imei)) )

	local args = {
		accountID = accountid,
		imei      = imei,
		tokenCode = tokencode ,
		travelID  = travelid,
		normal    = 10, 									---- 1正常关机,10正常开机
		preTimestamp = tonumber(preTimestamp) or 0,		---- 上一次的最后一次心跳包时间 2014-12-16 
	}

	if #tostring(args['accountID']) ~= 10 then
		args['accountID'] = ""
	end

	local body_data =  ngx.encode_args(args)
	local host_info = link["OWN_DIED"]["http"]["dataCore"]
	local data = utils.post_data('DataCore/realTime/powerOff.do', host_info, body_data)

	local ok, ret = http_api.http_ex(host_info, data ,false,"DATACORE_SERVER",60)
	if not ok then
		only.log('E', " post DataCore failed %s  ", data) 
		return false
	end

	only.log('W',data)

	return true
end



---------数据发送给dataCenter 2014-09-26 
local function post_poweron_status_to_damServer( imei, accountid ,tokencode, travelid , mod  )
	local args = {
		IMEI      = imei,
		accountID = accountid or '',
		tokenCode = tokencode ,
		travelID  = travelid,
		model     = mod , 
	}
	local data =  utils.json_encode(args)
	local host_info = link['OWN_DIED']['http']['damServer']
	local request = utils.compose_http_json_request( host_info ,'dams_transit_poweron',nil, args)

	only.log('D',request)

	local data = http_api.http_ex( host_info , request, false,'DAM_SERVER',60)

	only.log('D',data)

	return true
end



local function go_exit()
	save_urllog('400')
	gosay.respond_to_status(url_tab,false)
end


local function handle()
	local req_body   = ngx.req.get_body_data()
	local req_method = ngx.var.request_method
	local args       = ngx.req.get_uri_args()

	G.req_ip   = ngx.var.remote_addr
	url_tab['client_host'] = G.req_ip

	---- get_today 2014-06-28
	G.cur_month =  string.gsub(string.sub(ngx.get_today(),1,7),"%-","")
	G.cur_date  = string.gsub(ngx.get_today(),"%-","")
	G.cur_time = os.time()

	if req_method == "POST" then
		if not req_body then
			only.log('I', "post body is nil")
			go_exit()
			return
		end
		----args   = utils.parse_url(req_body)
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
	
	local imei = args['imei']
	local imsi = args['imsi']
	local mod  = args['mod']
	local version = args['verno'] or ''
	local ok_check = check_parameter(imei,imsi,mod)
	if ok_check == false then
		go_exit()
		return
	end
	local ok_config = check_configindex(imei)
	if ok_config == false then
		go_exit()
		return
	end

	if not version or string.find(version,"'") then
		version = ""
	end

	local ok_status,ok_ret_str = ready_execution(imei,imsi,mod,version)
	if ok_status == false then
		go_exit()
	end

	if G.cur_type ~= dk_utils.DK_IMEI_ENGINEERING then

		----driview
		post_poweron_status_to_data_routing(args)

		---- dataCore
		post_poweron_status_to_dataCore(imei,G.accountid,G.tokencode ,G.travel_id  )

		---- damServer
		---- post_poweron_status_to_damServer( imei ,G.accountid,G.tokencode ,G.travel_id , mod )

	end

	only.log('I','[SUCCED] %s______%s', imei,  ok_ret_str)

	ngx.header['RESULT'] = ok_ret_str
	save_urllog(ok_ret_str)
	gosay.respond_to_status(url_tab,true)
	
end

handle()
