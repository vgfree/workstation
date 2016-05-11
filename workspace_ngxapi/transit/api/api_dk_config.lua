-- api_dk_config.lua
-- auth: jiang z.s.
-- date: 2014-04-01

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
local ssdb = require('ssdb')
local scan 	= require('scan')

-- ---- 终端 IMEI 类型标志 ------------------------------
-- DK_IMEI_MANUFACTURE = 1    ----- IMEI 生产终端
-- DK_IMEI_ENGINEERING = 2    ----- IMEI 工程终端
-- ---- 终端 IMEI 类型标志 ------------------------------

-- --------------------------------------------------
-- ----- 当前代码所属类型 ---------------------------
-- ----- 1正式环境  0工程环境
-- DK_CODE_EVN_MANUFACTURE = 1   ---- feedback ,newStatus
-- --------------------------------------------------

---- private redis只读
local read_private = "read_private"
local private = "private"
local redis_args = 'deviceinfo'
local ssdblink= link.OWN_DIED.redis.ssdbserv

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
	model_version  = '',		----- 1生产数据,2工程测试数据
	cur_time  = 0,
	accountid = nil,
	tokencode = nil,
	
	redis_get_channel_number = "local channel_num = redis.call('get','%s:deviceInitChannelInfo') if channel_num then return channel_num end  local channel_num = redis.call('get','%s:deviceInitChannelInfo')"				   .." if channel_num then return channel_num else return nil end ",
	sql_save_urllog = "insert into urlLog_%s(createTime,url,clientip,returnValue) values( %s , '%s' , inet_aton('%s') , '%s' )",
	sql_check_imei = "select status from mirrtalkInfo where imei = %d and nCheck = %d and model = '%s' and validity = 1 and %s <= endTime limit 1 ",
	sql_check_mod  = "select version from modelInfo   where validity = 1 and model = '%s' and  %s <= endTime limit 1 ",
	sql_config_info =  " select  '' tokencode, accountID,call1,call2,domain,port,customArgs as customargs from configInfo where accountID = '%s' and model= '%s' limit 1 " ..
					" union all select '' tokencode,   accountID,call1,call2,domain,port,customArgs as customargs from configInfo where accountID = '' and model='%s' limit 1 ",


	sql_config_info_is_io_2 = " select  '' tokencode, call1,call2,fetchdataHost,fetchdataPort, domain as newstatusHost,port as newstatusPort,feedbackHost,feedbackPort," ..
					 "  customArgs as customargs from configInfo where accountID = '%s'  and model= '%s'  limit 1 " ..
					 " union all select '' tokencode,  call1,call2,fetchdataHost,fetchdataPort, domain as newstatusHost, port as newstatusPort,feedbackHost,feedbackPort, " .. 
					 "  customArgs as customargs from configInfo where accountID = '' and model='%s' limit 1 ",

	sql_user_poweron = "INSERT INTO userPowerOnInfo_%s(createTime, accountID, imei,imsi,model, tokenCode, tokenCodeEndTime,travelID,version,androidVer,modelVer,kernelVer,basebandVer,buildVer,appID) values(%s, '%s', %s, %s, '%s' , '%s' , %s ,%s , '%s','%s','%s','%s','%s','%s','%s')",
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
	local sql_str = string.format(G.sql_save_urllog,G.cur_month, G.cur_time ,G.body,G.req_ip,returnValue)
	local ok_status,ok_ret = mysql_api.cmd(app_url_db[G.cur_type],'INSERT',sql_str)
	if not ok_status then
		only.log('E','[save_urllog] insert database failed! %s ', sql_str )
	end
end

----判断用户当天config次数是否小于 x 次
----返回值
----第一个: false超过使用限制,或者程序出错
----        true
local function check_configindex(imei)
	----判断IMEI当天请求次数是否 > x 
	local configkey = string.format("%s:%s:configIndex",G.cur_date,imei)
	local ok_status,ok_config = redis_api.cmd(private,'INCR', configkey)
	--only.log('D', string.format('xxxxxxxxx configIndex is %s,value is %s  ',configkey,ok_config))
	if not ok_status then
		only.log('E', string.format('connect redis failed when get %s  ',configkey))
		return false
	end
	local ok = redis_api.cmd(private,'EXPIRE', configkey,'86400')

	local iIndex = 0 
	if ok_config then
		iIndex = ok_config
		if (tonumber(iIndex) or 0 ) > dk_utils.MAX_CONFIG_INDEX then
			only.log('E',string.format("[CHECK_FAILED] %s  more then %s, error", configkey, dk_utils.MAX_CONFIG_INDEX ))
			return false	
		end
	end

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
	local ok_status,accountID = redis_api.cmd(read_private,'get' ,imei .. ':accountID')
	if not ok_status then
		only.log('E',string.format('[CHECK_FAILED]connect redis failed when get %s:accountID',imei))
		return false,false,nil
	end

	only.log('W',string.format('debug info get %s:accountID val:%s ',imei,accountID))

	if not accountID or #accountID ~= 10 then
		is_exist = false
	else
		is_exist = true
	end 
	return true,is_exist,accountID
end

local function save_poweron_to_table( args,token_code )
	---- 当前时间
	---- now 	1403933518.377
	---- time 	1403933518
	local cur_socktime = string.format("%.3f", ngx.now() )
	local cur_time     = os.date("%Y%m%d%H%M%S", G.cur_time )

	---- 当前毫秒
	local cur_millisecond = string.sub(cur_socktime,string.find(cur_socktime,"%.")+1,cur_socktime + 3 )

	local travel_id = string.format("%s%s%s", string.sub(cur_time,3,14), cur_millisecond ,string.sub(args['imei'],11,15) )
	local travel_key = string.format("%s:travelID",args['imei'])

	redis_api.cmd('private', 'set',travel_key , travel_id)
	G.travel_id = travel_id

	local sql_str = string.format(G.sql_user_poweron,G.cur_month,G.cur_time  ,(G.accountid or ''), args['imei'],args['imsi'],args['mod'],token_code, (G.cur_time + 48*60*60) ,travel_id,args['verno'],args['androidver'],args['modelver'],args['kernelver'],args['basebandver'],args['buildver'],args['appid'])
	--only.log('D','user poweron sql is, %s  ', sql_str) 
	local ok_status,ok_ret = mysql_api.cmd(app_config_db[G.cur_type],'INSERT',sql_str)
	if not ok_status then
		only.log('E','connect database failed when insert sql_user_poweron, %s  ', sql_str) 
		return false
	end
	return true
end

---- add by jiang z.s. 2015-06-04
---- 用户按键重新定义
local function get_default_channel_idx(channel_num )
	local ok, idx = redis_api.cmd(read_private, 'get', channel_num .. ':channelID')
	if ok and idx then
		return idx 
	end
	return nil
end

---- add by h.y.q 2015-08-23
---- model 获得默认频道
---- 1.所有车机机器默认同一个频道
-----2.部分车机机器默认同一个频道

local function get_model_default_channel(model,imei)
	only.log('W',"******model:%s,imei is :%s*****************",model , imei)	
	local ok, res= redis_api.cmd(read_private, 'eval',string.format(G.redis_get_channel_number,imei, model),0)
	if ok and res then
		return res
	end

	return nil
end

local function update_channel_info_to_redis(accountid, imei, model, voiceCommand )
	if not accountid then
		return true
	end

	---- 开机加入在线用户列表
	---- 所有在线用户
	redis_api.cmd('statistic', 'sadd', 'allOnlineUser:set', accountid )

	---- 2015-10-29 jiang z.s. 
	if G.model_version == '2' then
		---- 当前是IO 2.0协议
		---- 不初始化 频道信息
		-- IO 2.0 在线用户
		redis_api.cmd('statistic', 'sadd', 'io2OnlineUser:set', accountid )
		return true
	end

	redis_api.cmd('statistic', 'sadd', 'onlineUser:set', accountid )

	if #accountid == 15 then
		---- 设置++按键,没有默认值直接加到10086
		--local default_channel = "10086"
		local default_channel = get_model_default_channel(model,accountid)		
		only.log('W',"**********default_channel is %s**************",default_channel)		
		default_channel = default_channel or "10086" 
		local ok_channel =  get_default_channel_idx(default_channel)
		if ok_channel and #tostring(ok_channel) >= 9 then
			---- 2015-08-26 判断群聊频道用户状态
			if not dk_utils.check_user_black_in_secret_channel(accountid, ok_channel) then
				redis_api.cmd('statistic',  'sadd', ok_channel .. ':channelOnlineUser', accountid)
				only.log('W',string.format("[init ] %s device sadd %s:channelOnlineUser ]", accountid , ok_channel ) )
			end
		end
		return true
	end

	---- 设置++按键
	local default_channel = "10086"
	local ok_status,ok_channel = redis_api.cmd(read_private, 'get', accountid .. ':currentChannel:groupVoice')
	if ok_status then
		if not ok_channel then
			ok_channel =  get_default_channel_idx(default_channel)
		end

		if ok_channel then
			---- 2015-08-26 判断群聊频道用户状态
			if not dk_utils.check_user_black_in_secret_channel(accountid, ok_channel) then
				redis_api.cmd('statistic',  'sadd', ok_channel .. ':channelOnlineUser', accountid)
				only.log('W',string.format("[init ] %s currentChannel:groupVoice sadd %s:channelOnlineUser ]", accountid , ok_channel ) )
			end
		end
	end

	if voiceCommand then
		---- 设置+按键 2015-07-05 + 按键未设置则为空
		local ok_status,ok_channel = redis_api.cmd(read_private,  'get', accountid .. ':currentChannel:voiceCommand')
		if ok_status and ok_channel and #tostring(ok_channel) >= 9 then
			---- 2015-08-26 判断群聊频道用户状态
			if not dk_utils.check_user_black_in_secret_channel(accountid, ok_channel) then
				redis_api.cmd('statistic',  'sadd', ok_channel .. ':channelOnlineUser', accountid)
				only.log('W',string.format("[init ] %s currentChannel:voiceCommand sadd %s:channelOnlineUser ]", accountid , ok_channel ) )
			end
		end
	end

	---- 设置用户关注的微频道
	local ok, ret = redis_api.cmd(read_private,'smembers', string.format("%s:userFollowMicroChannel",accountid))
	if not ( not ok or not ret or type(ret) ~= "table" or #ret < 1 ) then
		for i, channel_id in pairs(ret) do
			---- 微频道可以忽略判断用户状态
			redis_api.cmd('statistic','sadd',string.format("%s:channelOnlineUser",channel_id),accountid)
			only.log('W',string.format("[init follow_channellist] %s sadd %s:channelOnlineUser ]", accountid , channel_id ) )
		end
	end

end

local function device_power_init_redis( args )
	
	---- imei 相关的信息 2015-08-14 hou.y.q. 
	--imei 与 imsi 对应关系用于流量查询使用
	--model 与 imei对应关系用于异常关机使用
	--poweronTime 开机时间
	redis_api.cmd('private','mset', args['imei'] .. ":IMSIInfo", args['imsi'], 
				        args['imsi'] .. ":IMEIInfo", args['imei'],
					args['imei'] .. ":modelInfo",args['mod'],
					args['imei'] .. ":poweronTime",os.time()
		     )

end


---- 执行函数
local function ready_execution(args)
	local imei = args['imei']
	local imsi = args['imsi']
	local mod  = args['mod']
	local verno = args['verno'] or ''
	----获取accountID
	local ok_status, is_exist,account_id  = get_accountid(imei)
	if ok_status == false then return false,nil end
	local tmp_accid = account_id or imei

	G.accountid = account_id

	----查询accountID对应的相关信息
	local sql_str = string.format(G.sql_config_info,tmp_accid,mod,mod)
	if G.model_version == '2' then
		------ 临时使用,使用IO 2.0 
		sql_str = string.format(G.sql_config_info_is_io_2,tmp_accid,mod,mod)
	end

	only.log('W',"mysql select condfig info is :%s",sql_str)
	local ok_status,ok_config = mysql_api.cmd(app_config_db[1],'SELECT',sql_str)
	if not ok_status  then
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
	local ok,ret = redis_api.cmd('saveTokencode', 'setex', token_key,dk_utils.TOKENCODE_EXPIRE, token_code)
	if not ok then
		only.log('E','connect redis failed when set %s',token_key)
		return false,nil
	end

	G.tokencode = token_code
	------- save  powerOn  log --------------------------------------------------
	local ok_status = save_poweron_to_table(args,token_code)
	if not ok_status then
		return false,nil
	end
	------- save currentInfo --------------------------------------------------
	
	local currentInfo_valua = string.format("%s|%s|%s|%s|%s|%s|%s",G.cur_time,imei,mod,imsi,G.tokencode,G.travel_id,verno)
	local ok,ret = redis_api.cmd(redis_args, 'set', imei..':currentInfo', currentInfo_valua)

	local custom_str = ok_config[1]['customargs']
	local ok_status , custom_tab = pcall(cjson.decode,custom_str)
	if ok_status and custom_tab then
		local ok_status,ok_voice_type = redis_api.cmd(read_private,'get',tmp_accid .. ':voiceCommandCustomType')
		if ok_status and ok_voice_type then 
			custom_tab['voiceCommand'] = true
			-- ok_status , custom_str = pcall(cjson.encode,custom_tab)
			-- if ok_status or custom_str then
			-- 	only.log('D',"--accountid:%s change voiceCommand set true",tmp_accid)
			-- end
		end
	end


	if G.cur_type == dk_utils.DK_IMEI_MANUFACTURE then
		update_channel_info_to_redis(tmp_accid, imei, mod, custom_tab['voiceCommand'] )
	end
	---------------------------------------------------------------------------------------------------

	local return_tab = ok_config[1]
	return_tab['customargs'] = custom_tab


	local cur_doman = ok_config[1]['domain']
	local cur_port  = ok_config[1]['port']
	if G.cur_type == dk_utils.DK_IMEI_ENGINEERING then
		---- 工程测试环境
		return_tab['domain'] = "s9gc.mirrtalk.com" 
		return_tab['port'] = "80"
	end

	---- port is number 2015-11-04 
	return_tab['port'] = tonumber(return_tab['port'])

	return_tab['tokencode'] = token_code

	local ok, result_txt = pcall(cjson.encode,return_tab)
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
	local sql_str = string.format(G.sql_check_imei, string.sub(imei,1,14),string.sub(imei,-1) ,mod, G.cur_time  )
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
	local sql_str = string.format(G.sql_check_mod, mod, G.cur_time )
	local ok_check,ret_check = mysql_api.cmd(app_identify_db,'SELECT',sql_str)
	if not ok_check or ret_check == nil then
		only.log('E','[CHECK_FAILED]connect database failed or get IMSI result is nil')
		return false
	end
	if #ret_check ~= 1 then
		only.log('D','[CHECK_FAILED]mod:%s query succed but get record is empty',mod)
		return false 
	else
		G.model_version = ret_check[1]['version']
	end
	----校验合法
	return true
end



-----数据发送给driview
local function post_poweron_status_to_data_routing(args)
	local body_data = string.format('{"powerOn":true,"accountID":"%s","tokenCode":"%s","model":"%s","IMEI":"%s"}',
					G.accountid or args['imei'],
					G.tokencode,
					args['mod'],
					args['imei'])
	
	only.log('D',"post_poweron_status_to_data_routing %s", body_data)

	dk_utils.post_data_to_power_info(args['imei'],body_data)
	return true
end


---------数据发送给dataCenter 2014-09-26 
local function post_poweron_status_to_dataCore( imei, accountid ,tokencode, travelid )

	local ok, preTimestamp = redis_api.cmd(read_private, 'get',  string.format("%s:heartbeatTimestamp",(accountid or imei)) )

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

	only.log('W',request)

	local data = http_api.http_ex( host_info , request, false,'DAM_SERVER',60)

	only.log('D',data)

	return true
end
local function set_config_his(args,ret)
	----检测imei是否为15位数字
	local tmp = string.match(args['imei'],'%d+')
	if not tmp or  #tmp ~= 15 then 
		return 
	end 
	
	local db = ssdb:new()
	local ok, err = db:set_timeout(5000)
	local ok, err = db:connect(ssdblink['host'], ssdblink['port'])
	if not ok then
    		only.log('E',"failed to connect ssdb:%s", err)
    		return
	end
	local key = string.format("ACTIVEUSER:%s", G.cur_date)
	local ok,err = db:hincr(key,args['imei'])
	if not ok then
		only.log('E', "set_config_his ssdb %s error. key: %s, value: %s",err, key, value)
	end


	local CFG_key = string.format("CFG:%s:%s",args['imei'],G.cur_date)
	local CFG_value = string.format("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s",
	G.cur_time,
	ret,
	args['imei'] or '',
	args['imsi'] or '',
	args['mod'] or '',
	args['buildver'] or '',
	args['androidver'] or '',
	args['kernelver'] or '',
	args['basebandver'] or '',
	args['modelver'] or '',
	args['verno'] or '' )

	local ok,err = db:qpush_front(CFG_key,CFG_value)
	local ok, err = db:close()
	if not ok then
		only.log('E',string.format("db close err: %s ",err) )
		db:close()
	end

end

local function go_exit_configover50()
	save_urllog('667')
	gosay.respond_to_httpstatus(url_tab,667)
end

local function go_exit()
	save_urllog('400')
	gosay.respond_to_status(url_tab,false)
end

--存储参数，KV取代MYSQL存储方式，供业务查询
local function saveinfo(args)
	local imei = args['imei']
	local imsi = args['imsi']
	local mod = args['mod']
	local buildver = args['buildver']
	local androidver = args['androidver']
	local kernelver = args['kernelver']
	local basebandver = args['basebandver']
	local modelver = args['modelver']
	local verno = args['verno']
	
	if buildver then
		local ok = redis_api.cmd(redis_args,'sadd', buildver .. ':build',imei)
		if not ok then
			only.log('E',string.format("%s redis error in saveinfo",redis_args) )
			return
		end
	end
	if androidver then
		redis_api.cmd(redis_args,'sadd', androidver .. ':android',imei)
	end
	if kernelver then
		redis_api.cmd(redis_args,'sadd', kernelver .. ':kernel',imei)
	end
	if basebandver then
		redis_api.cmd(redis_args,'sadd', basebandver .. ':baseband',imei)
	end
	if modelver then
		redis_api.cmd(redis_args,'sadd', modelver .. ':model',imei)
	end
	if verno then
		redis_api.cmd(redis_args,'sadd', verno .. ':verno',imei)
	end

	local ok = redis_api.cmd(redis_args,'set',imei .. ':deviceInfo',androidver)
	if not ok then
		only.log('E',string.format("%s redis error in saveinfo",redis_args) )
	end
	return
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
	
	only.log('D', 'args = %s', scan.dump(args))


	url_tab['client_body'] = G.body

	G.imei      = args['imei']
	
	local imei = args['imei']
	local imsi = args['imsi']
	local mod  = args['mod']
	local version = args['verno'] or ''


	local ok_check = check_parameter(imei,imsi,mod)
	if ok_check == false then
		set_config_his(args,'400')
		go_exit()
		return
	end
	local ok_config = check_configindex(imei)
	if ok_config == false then
		set_config_his(args,'667')
		go_exit_configover50()
		return
	end
	
	--save all args to redis
	saveinfo(args)

	if not version or string.find(version,"'") then
		version = ""
	end

	--local ok_status,ok_ret_str = ready_execution(imei,imsi,mod,version)
	local ok_status,ok_ret_str = ready_execution(args)
	if ok_status == false then
		set_config_his(args,'400')
		go_exit()
	end

	if G.cur_type ~= dk_utils.DK_IMEI_ENGINEERING then

		device_power_init_redis(args)

		----driview
		post_poweron_status_to_data_routing(args)

		---- dataCore
		post_poweron_status_to_dataCore(imei,G.accountid,G.tokencode ,G.travel_id  )

		---- damServer  属于废弃 2015-08-26 
		---- post_poweron_status_to_damServer( imei ,G.accountid,G.tokencode ,G.travel_id , mod )

	end

	only.log('I','[SUCCED] %s______%s', imei,  ok_ret_str)

	ngx.header['RESULT'] = ok_ret_str
	set_config_his(args,'200')
	save_urllog(ok_ret_str)
	gosay.respond_to_status(url_tab,true)
	
end

handle()
