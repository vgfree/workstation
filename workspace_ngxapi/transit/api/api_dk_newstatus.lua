-- ngx_newstatus.lua
-- auth: jiang z.s 
-- 2015-06-03
-- 补充功能
-- 2015-05-10 lru cache  
-- 2015-06-03 adtalk 

local utils     = require('utils')
local app_utils = require('app_utils')
local only      = require('only')
local cutils    = require('cutils')
local gosay     = require('gosay')
local cjson     = require('cjson')
local link      = require('link')
local ngx       = require('ngx')
local socket    = require('socket')
local dk_utils  = require('dk_utils')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local http_api  = require('http_short_api')

local app_url_db       = "app_url___url"
local app_newstatus_db = "app_ns___newStatus"
local app_weiboread_db = "app_weibo___weibo_read"
local app_adtalk_db    = "app_adtalk___readAdTalkInfo"

local MATH_FLOOR = math.floor
local STR_LEN    = string.len

local IS_NUMBER = utils.is_number
local IS_FLOOR  = utils.is_float
local IS_WORD   = utils.is_word
local IS_INTEGER   = utils.is_integer

local weibo_redis_pre = "weibo"
local weibo_redis_new = "weiboNew"

---- private redis只读
local read_private = "read_private"


local url_tab = { 
	type_name   = 'transit',
	app_key     = '',
	client_host = '',
	client_body = '',
}   

local MAX_TIME_UPDATE = 10800  ---最大补传时间为1个小时
local TIME_DIFF = 28800    -- 8*60*60

local G = {
	imei          = '',
	head          = '',
	ip            = '',
	body          = '',

	cur_gmtdate  = 0,	----280614(2014-06-28 GM当前时间,用来纠正异常数据的)
	cur_month     = 0,	----当前月份(201404)
	cur_time      = 0, 	----当前时间(时间戳)
	cur_accountid = '',  ----accountID or args['imei']

	redis_eval_command = " local tab = redis.call('zrange','%s:weiboPriority',0,0)  if tab and #tab > 0 then redis.call('zrem','%s:weiboPriority',tab[1])  return tab[1] end  return nil " ,
	redis_eval_file_length = "local ret = redis.call('ZINCRBY','%s',%d,%d) if not ret then return nil end local res = redis.call('ZREM','%s',%s) then  if not res then  return nil end ",

	sql_upate_read_group_weibo    = "UPDATE %s_%s SET readStatus=1, readTime = %s , readLongitude='%s', readLatitude='%s' WHERE readStatus = 0 and receiverAccountID ='%s' AND bizid='%s' ",
	sql_upate_read_personal_weibo = " UPDATE %s_%s SET readStatus=1, readTime= %s , readLongitude='%s', readLatitude='%s' WHERE readStatus = 0 and  bizid='%s' ",
	sql_save_gps_info             = "INSERT INTO GPSInfo_%s(accountID, imei, imsi, createTime, collectTime, GMTTime, longitude, latitude, direction, speed, altitude, tokenCode) values %s ",
	sql_save_urllog               = "INSERT INTO urlLog_%s SET createTime = %s ,url='%s',clientip= inet_aton('%s'),returnValue='%s' " ,


	sql_save_adtalk_info = " insert into readAdTalkInfo_%s (appKey,senderAccountID,receiverAccountID,releaseTime," ..
	" releaseLongitude,releaseLatitude,level,content,longitude,latitude," .. 
	" tokenCode,bizid,adtalkID,readStatus,readTime,readLongitude,readLatitude) " .. 
	" values (%s,'%s','%s',%s," .. 
	" %s, %s , %s , '%s', %s, %s , " .. 
	" '%s', '%s', %s , %s , %s , %s , %s ) " ,

	sql_update_adtalk_info = " update readAdTalkInfo_%s set readStatus = 1 ,readTime = %s ,readLongitude =%s ,readLatitude = %s " ..
	" where receiverAccountID = '%s'  and bizid in ('%s')  " ,
}



local tab_gpsinfo     = {}		----经纬度tab

local tab_jo
-- local tab_to_map
local tab_GPSTime
local tab_longitude
local tab_latitude
local tab_direction
local tab_speed
local tab_altitude

---- gps补传转发
local other_GPSTime = {}
local other_direction = {}
local other_speed = {}
local other_altitude = {}
local other_longitude = {}
local other_latitude = {}

local EW = {
	E = "+",
	W = "-",
}
local EW_NUMBER = {
	E = 1,
	W = -1,
}

local NS = {
	N = "+",
	S = "-",
}

local NS_NUMBER = {
	N = 1,
	S = -1,
}



local function save_urllog(returnValue)
	----- 日志写ts_db
	dk_utils.set_urlLog(G.imei,G.body,G.ip,returnValue,G.cur_time)
	local timestamp = os.time()
	local temp_min = os.date("%M", timestamp)
	local AU5_time = string.format("%s%d%d", os.date("%Y%m%d%H", timestamp), temp_min/10,(temp_min%10<5 and 0 or 5))
	local AU5_key = string.format("AU5:%s", AU5_time)
	ok, ret = redis_api.cmd("deviceinfo","sadd",AU5_key,G.imei)
	if not ok then
		only.log('E', "set_urlLog: [AU5] sadd deviceInfo. key: %s, value: %s", AU5_key, imei)
	end


	-------------debug------------
	---- 日志是否写urllog 2014-09-16
	if tonumber(dk_utils.DK_WRITE_MYSQL_WITH_URL) ~= 0 then
		local sql = string.format(G.sql_save_urllog, G.cur_month, G.cur_time, G.body,G.ip, returnValue)
		local ok,ret = mysql_api.cmd(app_url_db, "insert", sql)
		if not ok then
			only.log('E','save_url_failed!')
			return false
		end
		return true
	end
end

---- 参数异常,返回400
local function go_exit()
	only.log('D',string.format("---IMEI:%s return 400-->---",tostring(G.imei)))
	save_urllog(400)
	gosay.respond_to_httpstatus(url_tab,400)
end

---- 参数正常,没有微博,返回555
local function go_empty()

	---- 2014-11-07 用户终端禁言功能
	if G.cur_accountid then
		local shutup = dk_utils.lru_cache_get_userinfo(G.cur_accountid,"shutup")
		if (tonumber(shutup) or 0 ) == 1  then
			ngx.header['RESULT'] = '{"shutup":"1"}'
		else
			ngx.header['RESULT'] = '{"shutup":"0"}'
		end
	end

	save_urllog(555)
	gosay.respond_to_httpstatus(url_tab,555)
end


---- 连续开机超过48小时,返回666
local function go_stopnewstatus()
	save_urllog(666)
	gosay.respond_to_httpstatus(url_tab,666)
end
----2015-09-18
----hou.y.q
------ 非WEME用户连续开机超过48小时,返回667
local function tokenCode_more_than_48_hour()
	save_urllog(667)
	gosay.respond_to_httpstatus(url_tab,667)
end

local function check_parameter( args )
	--> check imei
	if (not IS_NUMBER(args["imei"])) or (STR_LEN(args["imei"]) ~= 15) or (string.find(args["imei"], "0") == 1) then
		only.log('E', "imei is error! %s" , args['imei'])
		return false
	end
	--> check imsi
	if (not IS_NUMBER(args["imsi"])) or (STR_LEN(args["imsi"]) ~= 15) then
		only.log('E', "imsi is error! %s", args['imsi'])
		return false
	end
	--> check mod
	if (not IS_WORD(args["mod"])) or (STR_LEN(args["mod"]) > 5) then
		only.log('E', "mod is error! %s ", args['mod'] )
		return false
	end

	--> check tokencode
	if (not IS_WORD(args["tokencode"])) or (STR_LEN(args["tokencode"]) ~= 10) then
		only.log('E', "tokencode is error!  %s ", args['tokencode'])
		return false
	end

	--> check other
	if args["other"] and (STR_LEN(args["other"]) > dk_utils.MAX_OTHER_LEN  ) then
		only.log('E', "other too long! ")
		return false
	end
	--> check bizid
	local bizid = args["bizid"]
	if bizid then
		args["bizid"] = {}
		for v in string.gmatch(bizid, "([^,]+)") do
			if v and STR_LEN(v) > 0 and STR_LEN(v) ~= dk_utils.BIZID_LENGTH then
				only.log('E', "bizid is error!  %s ", v )
				return false
			end
			if v and STR_LEN(v) > 0 then
				table.insert(args["bizid"], v)
			end
		end
	end
	return true
end


local function verify_parameter( args )
	local ok,tokencode = redis_api.cmd('saveTokencode','get',args["imei"] .. ":tokenCode")
	--local tokencode = dk_utils.lru_cache_get_token(args["imei"])
	if not tokencode then
		if args['mod'] == 'SG900' or args['mod'] == 'TG900' then
			only.log('W', "%s get tokencode=nil from redis! maybe tokencode over 48h -->--- 666 ", args["imei"] )
			go_stopnewstatus()
			return false
		end

		--非WEME用户开机超过48小时，返回667
		only.log('W', "%s get tokencode=nil from redis! maybe tokencode over 48h -->--- 667 ", args["imei"] )
		tokenCode_more_than_48_hour()
		return false
	end

	if tokencode ~= args["tokencode"] then
		--tokencode = dk_utils.lru_cache_refresh_token(args["imei"])
		if not tokencode or tokencode ~= args["tokencode"] then
			only.log('E', " IMEI: %s  redis tokencode  [%s] != post tokencode [%s] ",args["imei"], tokencode, args["tokencode"])
			---- tokenCode无效,返回666
			go_stopnewstatus()
			return false
		end
	end

	return true
end


local function parse_data(data)
	if not data or not string.find(tostring(data),",") then return nil end
	if not string.find(tostring(data),";") then
		local field_tab = {}
		field_tab[1] = utils.str_split(data, ',')
		return field_tab
	end
	local field_tab = {}
	local group_tab = utils.str_split(data, ';')
	for k, v in pairs(group_tab) do
		field_tab[ k ] = utils.str_split(v, ',')
	end
	return field_tab
end

local function lg(name, value)
	only.log('E',  ' %s = %s is error data!', name, tostring(value) ) 
end

local function gmttime_to_time(gmttime)
	return os.time({day=tonumber(string.sub(gmttime, 1, 2)), month=tonumber(string.sub(gmttime, 3, 4)), year=G.cur_year + tonumber(string.sub(gmttime, 5, 6)), hour=tonumber(string.sub(gmttime, 7, 8)), min=tonumber(string.sub(gmttime, 9, 10)), sec=tonumber(string.sub(gmttime, 11, 12))})
end

---- amr 文件拼接, 去除到第二个文件的头标示
local function append_multimedia_file(binary_first, binary_second)
	local ok_first, length_first = app_utils.check_is_amr(binary_first, #binary_first )
	local ok_second, length_second  = app_utils.check_is_amr(binary_second, #binary_second)
	if ok_first and ok_second then
		return  binary_first  .. binary_second 
	end
	if ok_first then
		return binary_first
	end
	if ok_second then
		return binary_second
	end
end

local function parse_gps_data( gps_table )
	if not gps_table or #gps_table ~= 6 then return false end

	---- 可能出现,,,-1,的数据 2014-09-26
	if #gps_table[1] < 1 or #gps_table[2] < 1  or #gps_table[3] < 1  or #gps_table[4] < 1  or #gps_table[5] < 1  or #gps_table[6] < 1 then
		only.log('E', "gps data is Exp: %s",table.concat(gps_table,",")) 
		return false
	end 

	local char_long = string.sub(gps_table[2],-1)
	---- 2014-10-22 需要考虑异常情况
	if not EW_NUMBER[ char_long ] then
		only.log('E', "longitude: %s  char_longis error",gps_table[2]  ) 
		return false
	end

	local save_info = {}

	save_info["longdir"] = EW[ char_long ]
	local char_lat = string.sub(gps_table[3],-1)

	---- 2014-10-22 需要考虑异常情况
	if not NS_NUMBER[ char_lat ] then
		only.log('E', "longitude: %s  char_lat is error",gps_table[3] )
		return false
	end
	save_info["latdir"] = NS[ char_lat ]

	--long lat
	local raw_long = tonumber( string.sub(gps_table[2], 1, -2) )
	local raw_lat = tonumber( string.sub(gps_table[3], 1, -2) )

	----经纬度转换失败的情况 2014-10-13
	if not raw_long or not raw_lat then
		only.log('E',  "longitude: %s  latitude: %s is error",gps_table[2], gps_table[3] ) 
		return false
	end

	local tmp_longitude,tmp_latitude = dk_utils.convert_gps( raw_long, raw_lat )

	save_info["longitude"] = EW_NUMBER[ char_long ] * tmp_longitude
	save_info["latitude"] = NS_NUMBER[ char_lat ] * tmp_latitude
	-- table.insert(tab_longitude, EW_NUMBER[ char_long ] * save_info["longitude"])
	-- table.insert(tab_latitude, NS_NUMBER[ char_lat ] * save_info["latitude"])

	--GMT
	local GMTtime = gps_table[1]
	if IS_NUMBER(GMTtime) and STR_LEN(GMTtime) == 11 then
		----GMTTime 错误,丢失第一位,做容错处理[;20514135752]
		if string.sub(GMTtime,1,5) == string.sub(G.cur_gmtdate,2,6) then
			----发现日期相同,需要修复
			GMTtime = string.format("%s%s",string.sub(G.cur_gmtdate,1,1),GMTtime)
		end
	end
	if (not IS_NUMBER(GMTtime)) or (STR_LEN(GMTtime) ~= 12) then lg("GMT", GMTtime) return false end

	local time_stamp = gmttime_to_time(GMTtime)

	---- 最大补传时间为3个小时, 可能大于当前时间,也可能小于当前时间 2014-09-24
	if  math.abs(tonumber(ngx.time()) - tonumber(time_stamp + TIME_DIFF ))  < MAX_TIME_UPDATE then
		---- 小于1小时内的数据不修正
		save_info["collectTime"] = time_stamp + TIME_DIFF
	else

		-- save_info["collectTime"] = ngx.time()
		only.log('E',  " %s GMTtime is ERROR data:%s===", G.imei, GMTtime) 
		return false
	end

	-- table.insert(tab_GPSTime, save_info["collectTime"])

	--direction
	save_info["direction"] = MATH_FLOOR(gps_table[4])
	-- table.insert(tab_direction, save_info["direction"])

	--speed
	save_info["speed"] = MATH_FLOOR(gps_table[5])
	-- table.insert(tab_speed, save_info["speed"])

	--altitude
	save_info["altitude"] = MATH_FLOOR(gps_table[6])
	-- table.insert(tab_altitude, save_info["altitude"])

	-------------debug------------
	if not save_info["longdir"] or not char_long then lg("longdir", string.sub(gps_table[2],-1)) return false end
	if not save_info["latdir"] or not char_lat then lg("latdir", string.sub(gps_table[3],-1)) return false end
	if (not IS_FLOOR(raw_long)) or (STR_LEN(raw_long) > 11) then lg("raw_long", raw_long) return false end
	if (tonumber(save_info["longitude"]) < 0) or (tonumber(save_info["longitude"]) > 180) then lg("longitude", save_info["longitude"]) return false end
	if (not IS_FLOOR(raw_lat)) or (STR_LEN(raw_lat) > 11) then lg("raw_lat", raw_lat)  return false end
	if (tonumber(save_info["latitude"]) < 0) or (tonumber(save_info["latitude"]) > 90) then lg("latitude", save_info["latitude"]) return false end
	if (not IS_FLOOR(save_info["direction"])) or (STR_LEN(save_info["direction"]) > 6) or ((tonumber(save_info["direction"]) < 0) and (tonumber(save_info["direction"]) ~= -1)) or (tonumber(save_info["direction"]) > 360) then lg("direction", save_info["direction"]) return false end
	if (not IS_FLOOR(save_info["speed"])) or (STR_LEN(save_info["speed"]) > 7) or (tonumber(save_info["speed"]) < 0) or (tonumber(save_info["speed"]) > 10000) then lg("speed", save_info["speed"]) return false end
	if (not IS_INTEGER(save_info["altitude"])) or (STR_LEN(save_info["altitude"]) > 6) or (tonumber(save_info["altitude"]) < -9999) or (tonumber(save_info["altitude"]) > 99999) then lg("altitude", save_info["altitude"]) return false end

	return true,save_info
end

--[[
@Description    过滤相同GPS包 未考虑 连续长时间发送含有错误时间的包后又发送了正确的包
@Date           2015-12-18
@Author         shu

@param GPS时间
@return 是否重复
--]]

--local function filter_same_package(gps_time, token_code)
--
--        local expire_time = 1200 -- redis key 超时 保证信号不好长时间未发送GPS包后能重新设置key
--        local limit_time = 600 -- 容错时间
--        local current_time = os.time() -- 系统时间
--        local GMT_new = gmttime_to_time(gps_time) + (8 * 60 *60)
--        local filter_redis = "statistic" -- 存放最新 ${token_code}:${GMT_new}
--        local flag = false
--	local timestamp_key = token_code .. ":newGPStimestamp"
--
--        if IS_NUMBER(GMT_new) and STR_LEN(GMT_new) == 11 then
--                ----GMTTime 错误,丢失第一位,做容错处理[;20514135752]
--                if string.sub(GMT_new,1,5) == string.sub(G.cur_gmtdate ,2,6) then
--                        GMT_new = string.format("%s%s",string.sub(G.cur_gmtdate,1,1),GMT_new)
--                end
--        end
--
--        GMT_new = tonumber(GMT_new)
--	-- 当前未缓存tokencode 设置${token_code}:${GMT_new}
--	local temp = math.abs(GMT_new - current_time)
--	if temp >= limit_time then
--		flag = true
--		only.log('E', " filter upload_time %s now_time %s ", tostring(GMT_new), tostring(current_time))
--	else
--		flag = false
--
--		local ok, GMT_old = redis_api.cmd(filter_redis, 'get', timestamp_key)
--		if not ok then
--			-- 命令失败不设置key，redis挂掉包过滤将失效，偶尔出错不影响
--			only.log('E', " get timestamp_key %s: failed ", token_code)
--		else
--			-- 若GMT_new > GMT_old && limit_time > temp 设置标志位并更新GMT_old
--			GMT_old = tonumber(GMT_old)
--			if GMT_old then
--				if GMT_new > GMT_old then
--					flag = false
--				else
--					flag = true
--				end
--			end
--		end
--	end
--	if not flag then
--		redis_api.cmd(filter_redis, 'setex', timestamp_key, expire_time, GMT_new)
--	end
--        return flag
--end

---- 拼装mysql,保存gps数据至数据库
---- gps_table 最基本的数据
---- accountid 用户帐号
---- imei
---- imsi 
---- token_code 
---- tab_gpsinfo   当前解析成功返回的数据
---- is_extragps 当前是否为补传gps数据,默认为false 

local function get_gps_sql( gps_table, accountid, imei,  imsi , token_code ,  is_extragps , ret_gpsinfo_tab  )
	if not gps_table then return false end

	local create_time = G.cur_time
	local tb_gps_sql = {}

	ret_gpsinfo_tab['imei']      = imei
	ret_gpsinfo_tab['count']     = 0	
	ret_gpsinfo_tab['accountID'] = accountid
	ret_gpsinfo_tab['list']      = {}

	--if not is_extragps then
	--        if ( filter_same_package(gps_table[1][1], token_code) ) then return false end
	--end

	for i=1,#gps_table do
		local ok , save_info = parse_gps_data( gps_table[i] )
		if ok and save_info then
			if not is_extragps then
				table.insert(tab_GPSTime,save_info['collectTime'])
				table.insert(tab_direction,save_info["direction"])
				table.insert(tab_speed,save_info["speed"])
				table.insert(tab_altitude,save_info["altitude"])
				table.insert(tab_longitude,save_info["longitude"])
				table.insert(tab_latitude,save_info["latitude"])
			else
				table.insert(other_GPSTime,save_info['collectTime'])
				table.insert(other_direction,save_info["direction"])
				table.insert(other_speed,save_info["speed"])
				table.insert(other_altitude,save_info["altitude"])
				table.insert(other_longitude,save_info["longitude"])
				table.insert(other_latitude,save_info["latitude"])
			end

			if ret_gpsinfo_tab['count'] == 0 then
				ret_gpsinfo_tab['collectStart'] = save_info['collectTime']
			end

			local t_GMTTime = gps_table[i][1]
			if IS_NUMBER(t_GMTTime) and STR_LEN(t_GMTTime) == 11 then
				----GMTTime 错误,丢失第一位,做容错处理[;20514135752]
				if string.sub(t_GMTTime,1,5) == string.sub(G.cur_gmtdate ,2,6) then
					----发现日期相同,需要修复
					t_GMTTime = string.format("%s%s",string.sub(G.cur_gmtdate,1,1),t_GMTTime)
				end
			end

			if tonumber(dk_utils.DK_WRITE_MYSQL_WITH_GPS) ~= 0 then
				---- gps是否写mysql
				local sqlgps = string.format("('%s', '%s', '%s' , %d , %s, '%s', %s%s, %s%s, %s, %s, %s, '%s')",
				accountid, imei, imsi,
				create_time, save_info["collectTime"], t_GMTTime , save_info["longdir"],
				MATH_FLOOR(save_info["longitude"] * dk_utils.gps_point_unit ), 
				save_info["latdir"],
				MATH_FLOOR(save_info["latitude"] * dk_utils.gps_point_unit ),
				save_info["direction"], 
				save_info["speed"], 
				save_info["altitude"], 
				token_code)
				table.insert(tb_gps_sql, 1, sqlgps)
			end

			-----数据库保存的格式：
			---- key: GPS:${imei}:${time interval}
			---- value: 600*12@ ${collectTime}|${createTime}|${imei}|${accountID}|${imsi}|${GMTTime}|${longitude}|${latitude}|${altitude}|${direction}|${speed}|${tokenCode}|...
			---- 存储至redis
			table.insert(ret_gpsinfo_tab.list,string.format("%s||||||%s|%s|%s|%s|%s|%s",
			save_info['collectTime'], 
			--create_time, imei, accountid or "", 
			--imsi,  t_GMTTime,
			MATH_FLOOR(save_info["longitude"] * dk_utils.gps_point_unit ),
			MATH_FLOOR(save_info["latitude"] * dk_utils.gps_point_unit ), 
			save_info["altitude"], 
			save_info['direction'], 
			save_info['speed'], 
			token_code))

			ret_gpsinfo_tab.count = ret_gpsinfo_tab.count + 1 

		end
	end
	---- gps data maybe ;;;;
	if ret_gpsinfo_tab.count < 1 then return false end

	---- 直接返回
	if tonumber(dk_utils.DK_WRITE_MYSQL_WITH_GPS) ~= 0 then 
		return string.format(G.sql_save_gps_info, G.cur_month , table.concat(tb_gps_sql, ",")) 
	end

end

------ 判断微博是否过期
------ true  del
------ false ok --->---send msg to user 
local function weibo_expired_new(weibo_endtime)
	if not weibo_endtime then return true end
	if type(weibo_endtime) ~= "string" then return true end
	if tonumber(weibo_endtime) < G.cur_time then
		return true
	end
	return false
end

------ 判断微博是否过期
-------- true  del
-------- false ok --->---send msg to user
local function weibo_expired_pre(weibo)
	if not weibo then return true end
	if type(weibo) == "number" or type(weibo) == "string" then return true end
	if not weibo['time'] then return true end
	if #weibo['time'] ~= 2 then return true end
	local end_time = tonumber(weibo["time"][2])
	if not end_time then return true end
	if tonumber(end_time) < G.cur_time then
		return true
	end
	return false
end

local function save_read_bizid_to_newstatus_info( accountid, args, read_bizid )

	local cur_time = os.date("%Y%m%d%H%M")
	local cur_time = math.floor(cur_time/10)

	local redis_value = string.format("%s|%s|%s|%s|%s",
	accountid or '', 
	args["imei"], 
	args["imsi"],
	os.time(), 
	args["tokencode"] 
	)
	for k,v in pairs (read_bizid) do
		local redis_key  = string.format("newstatusInfo:%s:%s",v,cur_time)
		local ok = redis_api.hash_cmd("message_hash",v ,'SADD',redis_key,redis_value)

		if not ok then
			only.log('E', string.format("save read newstatus info failed! key:%s,value:%s ",redis_key,redis_value ))
		end	
	end

end
---- 转发读取微博bizid给其他业务
local function save_read_bizid_to_read_info_new( accountid, args, read_bizid )
	local read_info = { 
		curAccountID = accountid,
		curIMEI = args['imei'],
		curIMSI = args['imsi'],
		curBizid = args["bizid"],
		curTime = G.cur_time,
		curTokenCode = args['tokencode']
	}

	if #tab_longitude > 0 then
		read_info['curLongitude'] = tab_longitude[1]
	end

	if #tab_latitude > 0 then
		read_info['curLatitude'] = tab_latitude[1]
	end

	dk_utils.post_data_to_read_weibo( read_info )
end
local function save_read_bizid_to_message_redis(accountid ,args ,read_bizid)
	--> update read bizid
	local longitude, latitude = 0 , 0 
	local cur_time = os.date("%Y%m%d%H%M")
	local cur_time = math.floor(cur_time/10)

	---- 设置最新经度
	if tab_longitude[1] and tab_latitude[1] then
		longitude = tab_longitude[1]
		latitude = tab_latitude[1]
	end

	if not read_bizid then
		only.log('E', "get read_bizid failed! %s" , read_bizid) 
		return
	end

	local bizid_tab = read_bizid
	local redis_value = string.format("%s|%s|%s|%s",accountid,os.time(),
	longitude * dk_utils.gps_point_unit,
	latitude * dk_utils.gps_point_unit
	)
	--保存已经读的信息
	for _,tmp_bizid in ipairs(bizid_tab) do 

		local redis_key = string.format("readMessage:%s",cur_time)
		local value = string.format("%s",accountid)
		local ok  = redis_api.hash_cmd("message_hash",accountid,'SADD',redis_key ,value)

		if not ok then 
			only.log('E',"save read bizid to message redis failed! key :%s,value:%s",redis_key,value)
		end

		local redis_key = string.format("readMessage:%s:%s",accountid ,cur_time)
		local value = string.format("%s|%s",os.time(),tmp_bizid)
		local ok  = redis_api.hash_cmd("message_hash",accountid,'SADD',redis_key ,value)
		if not ok then 
			only.log('E',"save read bizid to message redis failed! key :%s,value:%s",redis_key,value)
		end

		local redis_key = string.format("readMessageInfo:%s:%s",tmp_bizid,cur_time)
		local ok  = redis_api.hash_cmd("message_hash",tmp_bizid,'SADD',redis_key , redis_value )
		if not ok then 
			only.log('E',"save read bizid to message redis failed! key :%s,value:%s",redis_key,redis_value)
		end
	end

end
---- 保存已经读取的bizid微博 
local function save_read_bizid_to_read_info_pre( accountid, args, read_bizid )
	local sql_tab = {
		a1 = 'readGroupTTSWeibo',
		a2 = 'readGroupMultimediaWeibo',
		a3 = 'readPersonalTTSWeibo',
		a4 = 'readPersonalMultimediaWeibo',
		a5 = 'readPersonalTTSWeibo',
		a6 = 'readPersonalMultimediaWeibo',
	}

	--> update read bizid
	local longitude, latitude = 0 , 0 

	---- 设置最新经度
	if tab_longitude[1] and tab_latitude[1] then
		longitude = tab_longitude[1]
		latitude = tab_latitude[1]
	end

	if not read_bizid then
		only.log('E', "get read_bizid failed! %s" , read_bizid) 
		return
	end

	local bizid_tab = read_bizid
	---- 更新已经下发的微博的状态
	for _, tmp_bizid in pairs(bizid_tab) do

		local begin_bizid = string.sub(tmp_bizid, 1, 2)
		tmp_weibo_type = "personalWeibo"
		if begin_bizid == "a1" or begin_bizid == "a2" then
			tmp_weibo_type = "groupWeibo"
		end

		-- ---- 2015-05-04 读取bizid用户的列表
		-- ---- 数据部门的redis统计server
		-- ---- key: [bizid:cur_date]:reallyReadUserList
		-- ---- val: accountid
		-- local tmp_key = string.format("%s:%s:reallyReadUserList", tmp_bizid , G.cur_date )
		-- redis_api.cmd('dataCore_redis','sadd', tmp_key , G.cur_accountid )
		-- redis_api.cmd('dataCore_redis','expire', tmp_key , dk_utils.DATACORE_EXPIRE_MAXTIME )

		-- ---- key: [accountid:cur_date:]reallyReadBizidList
		-- ---- val: bizid
		-- local tmp_key = string.format("%s:%s:%s:reallyReadBizidList", G.cur_accountid , G.cur_date, tmp_weibo_type )
		-- redis_api.cmd('dataCore_redis','sadd', tmp_key , string.format("%s|%s",tmp_bizid ,ngx.time() ) )
		-- redis_api.cmd('dataCore_redis','expire', tmp_key , dk_utils.DATACORE_EXPIRE_MAXTIME )

		-- ---- key:[accountid:cur_date]:reallyReadCount
		-- ---- val:count
		-- local tmp_key = string.format("%s:%s:reallyReadCount",G.cur_accountid,G.cur_date)
		-- redis_api.cmd('dataCore_redis','incr', tmp_key)
		-- redis_api.cmd('dataCore_redis','expire', tmp_key , dk_utils.DATACORE_EXPIRE_MAXTIME )


		local sql_str = nil
		if begin_bizid == 'a1' or begin_bizid == 'a2' then
			---- a1 集团 TTS 
			---- a2 集团 语音
			sql_str = string.format(G.sql_upate_read_group_weibo,
			sql_tab[begin_bizid],
			G.cur_month,
			G.cur_time,
			longitude * dk_utils.gps_point_unit ,
			latitude * dk_utils.gps_point_unit ,
			G.cur_accountid,
			tmp_bizid)
		elseif begin_bizid == 'a3' or begin_bizid == 'a4' then
			---- a3 个人 TTS 
			---- a4 个人 语音
			sql_str = string.format(G.sql_upate_read_personal_weibo,
			sql_tab[begin_bizid],
			G.cur_month,
			G.cur_time,
			longitude * dk_utils.gps_point_unit ,
			latitude * dk_utils.gps_point_unit ,
			tmp_bizid)
		elseif begin_bizid == 'a5' or begin_bizid == 'a6' then
			---- a5 区域 TTS 
			---- a6 区域 语音
			sql_str = string.format(G.sql_upate_read_personal_weibo,
			sql_tab[begin_bizid],
			G.cur_month,
			G.cur_time,
			longitude * dk_utils.gps_point_unit ,
			latitude * dk_utils.gps_point_unit ,
			tmp_bizid)
		end
		if sql_str then
			local ok_status,ok_ret = mysql_api.cmd(app_weiboread_db,'UPDATE',sql_str)
			if not ok_status then
				only.log('E','save read weibo failed! %s ', sql_str )
			end
		end
	end
end

---- ### bizid的标识
---- * 1,3,5,7代表集团，个人，区域，分享的TTS微博
---- * 2,4,6,8代表集团，个人，区域，分享的语音微博

local function fetch_weibo_msg(user)
	local data_fmt = 'POST %s HTTP/1.0\r\n' ..
	'Host:%s:%s\r\n' ..
	'Content-Length:%d\r\n' ..
	'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

	local ret = string.format("UID=%s",user)
	local app_uri = '/weibo_recv_single_message'
	local host_info = link['OWN_DIED']['http']['fetch_weibo']
	data = string.format(data_fmt,app_uri,host_info['host'],host_info['port'],#ret,ret)
	only.log('D', 'data:' .. data)
	local ok, ret = cutils.http(host_info['host'], host_info['port'], data, #data)
	only.log('D', "ret:" .. ret)
	local raw_weibo = nil
	if ok then
		raw_weibo = string.match(ret,'{.+}')
	end
	return ok,raw_weibo
end


local function fetch_weibo_pre(user, user_type)
	local weibo_type = {
		a1 = 'groupTTSWeibo',
		a2 = 'groupMultimediaWeibo',
		a3 = 'personalTTSWeibo',
		a4 = 'personalMultimediaWeibo',
		a5 = 'readPersonalTTSWeibo',
		a6 = 'readPersonalMultimediaWeibo',
	}
	local cur_groupMsgTime = G.cur_time

	local get_groupMsgKey = string.format("%s:groupMsgTimestamp",G.imei)
	local get_weibo_key = string.format('%s:%s', user, user_type)

	local ok,raw_weibo = fetch_weibo_msg(user)
	if not ok or not raw_weibo then
		return
	end
	ok,weibo_info = pcall(cjson.decode, raw_weibo)
	if not ok then
		return
	end
	local bizid = weibo_info['bizid']
	---- 只有主动密圈,以及回复其他的密圈,才能禁止
	local ok_status,ok_groupMsg = redis_api.cmd(read_private,"get", get_groupMsgKey)
	ok_groupMsg = tonumber(ok_groupMsg) or 0

	local begin_bizid = string.sub(bizid, 1, 2)
	if begin_bizid == 'a3' or begin_bizid == 'a4' then
		---- 删除个人微博
		redis_api.cmd(weibo_redis_pre, "del", bizid .. ":weibo")
	end
	---- 判断微博有效期
	if weibo_expired_pre(weibo_info)  then
		redis_api.cmd(weibo_redis_pre, "del", bizid .. ":weibo")
		redis_api.cmd(weibo_redis_pre, 'del', bizid .. ':senderInfo')
		-- only.log('D', string.format("%s:%s--> is expired [xxxx], level:%s   content:%s  !",
		-- 			user,bizid, weibo_info['level'] , weibo_info['content'] or '' ))
	elseif   ok_groupMsg > cur_groupMsgTime and ok_groupMsg > 0  and (tonumber(weibo_info['level']) or 0)  > 21 then
		if begin_bizid == 'a3' or begin_bizid == 'a4' then
			redis_api.cmd(weibo_redis_pre, 'del', bizid .. ':senderInfo')
			-- only.log('D', string.format("%s:%s--> having groupMsg,del this msg, weiboLevel:%s curTimestamp:%s, imei:groupMsgTimestamp is %s",
			-- 						user,bizid, weibo_info['level'],cur_groupMsgTime, ok_groupMsg ))
		end
	else
		---- 统计微博读取信息情况
		---- 
		local ok,ret = redis_api.cmd(weibo_redis_pre,'get', bizid .. ':senderInfo')
		if ok and ret  then 
			only.log('D',string.format("bizid:%s  senderInfo %s", bizid, ret))
			local ok_json,ret_json = pcall(cjson.decode, ret)
			if ok_json and ret_json then
				--supex weibo-G 过滤自己发的微薄
				if ret_json['senderAccountID'] == user then
					return nil,nil
				end
				weibo_info['sender_info'] = ret_json
			end
		end
		return weibo_info,weibo_type[begin_bizid]
	end
end

local function fetch_weibo_new(user, user_type)

	local cur_groupMsgTime = G.cur_time
	local get_groupMsgKey = string.format("%s:groupMsgTimestamp",G.imei)
	local get_weibo_key = string.format('%s:%s', user, user_type)
	repeat
		---- 2015-01-12
		local ok, bizid = redis_api.cmd(weibo_redis_new ,"eval", string.format(G.redis_eval_command, user, user  ) ,0)
		if not ok or not bizid then
			return nil,nil
		else
			-------- 先删除微博队列
			------ redis_api.cmd("weibo", "zrem", get_weibo_key, bizid)
			local ok, weibo_info = redis_api.cmd(weibo_redis_new, "hgetall", bizid .. ":weibo")
			if not ok then
				only.log('E',string.format(" get %s:weibo info failed %s" ,bizid , weibo_hash))
			elseif ok and weibo_info then
				---- 只有主动密圈,以及回复其他的密圈,才能禁止
				local ok_status,ok_groupMsg = redis_api.cmd(read_private,"get", get_groupMsgKey)
				ok_groupMsg = tonumber(ok_groupMsg) or 0

				only.log('D', string.format(' User:%s --- bizid:%s ---weibo:%s ',user, bizid, weibo_info  ) )

				local begin_bizid = string.sub(bizid, 1, 2)
				if begin_bizid == 'a3' or begin_bizid == 'a4' then
					---- 删除个人微博
					redis_api.cmd(weibo_redis_new, "del", bizid .. ":weibo")
				end
				weibo_info['bizid'] = bizid

				---- 判断微博有效期
				if weibo_expired_new(weibo_info['endTime'])  then
					redis_api.cmd(weibo_redis_new, "del", bizid .. ":weibo")
					redis_api.cmd(weibo_redis_new, 'del', bizid .. ':senderInfo')
				elseif   ok_groupMsg > cur_groupMsgTime and ok_groupMsg > 0  and (tonumber(weibo_info['level']) or 0)  > 21 then
					if begin_bizid == 'a3' or begin_bizid == 'a4' then
						redis_api.cmd(weibo_redis_new, 'del', bizid .. ':senderInfo')
					end
				else
					---- 统计微博读取信息情况
					local ok,tmp_tab = redis_api.cmd(weibo_redis_new,'hgetall', bizid .. ':senderInfo')
					if ok and tmp_tab then
						weibo_info['sender_info'] = tmp_tab
					end
					return weibo_info
				end
			end
		end
	until false
end



---- 根据dfsurl获取文件内容下发
local function get_dfs_data_by_http(dfsurl)
	if not dfsurl then return false,'' end 

	--当url匹配到redis：时，语音文件从redis里取
	--fastDFS 存储压力大,将语音文件存到redis里
	--add hou.y.q 2015-09-23

	if string.match(dfsurl,"redis://") then

		local key = string.sub(dfsurl,9,-1)
		local file_type = string.sub(dfsurl,-3,-1)
		local ok, file_data = redis_api.cmd("amrBinary","GET",key)

		if not ok or not file_data then
			only.log('E','get redis date from amrBinary redis failed!')
			return false,'' 
		end

		if not app_utils.check_is_amr(file_data,#file_data) then
			only.log('E',  "redis voice file is invalid: %s", dfsurl) 
			return false, ''
		end

		return true,file_type, file_data
	end 

	local tmp_domain = nil
	local is_no_people = nil
	local is_local_file = nil
	local old_dfsapi = nil	


	is_no_people = string.match(dfsurl,"daokeFilePath=")

	is_local_file = string.match(dfsurl,"productList")	

	-->兼容老版本
	old_dfsapi = string.match(dfsurl,"tweet.daoke.me")	

	if is_no_people then
		tmp_domain = string.match(dfsurl,'(http://[%w%.]+.*?group=.*file=.*.%a%a.)%?')
	else
		tmp_domain = string.match(dfsurl,'http://[%w%.]+:?%d*/')
	end

	if is_local_file then
		tmp_domain = string.match(dfsurl,'(http://[%w%.]+.*%.%a%a%a)')
	end

	if old_dfsapi then
		tmp_domain = string.match(dfsurl,'http://[%w%.]+:?%d*/')
	end

	if not tmp_domain then return false,'' end 
	local domain = string.match(tmp_domain,'http://([%w%.]+:?%d*)/')

	local parstring = nil
	local parindex = #dfsurl


	if parindex then
		parstring = string.sub(dfsurl,#tmp_domain + 2 ,#dfsurl)
	else
		parindex = #dfsurl
	end

	local urlpath = string.sub(dfsurl,#domain+8,parindex)

	if not urlpath then return false,'' end
	local data_format =  'GET %s HTTP/1.0\r\n' ..
	'HOST:%s\r\n\r\n'

	local req = string.format(data_format,urlpath,domain)
	req = string.gsub(req,"%%%%","%%")

	local host = domain
	local port = 80
	if string.find(domain,':') then
		host = string.match(domain,'([%w%.]+)')
		port = string.match(domain,':(%d+)')
		port = tonumber(port) or 80
	end

	local filey_tpe = string.sub(dfsurl,-4,-1)
	if not filey_tpe then 
		filey_tpe = 'amr'
	else
		filey_tpe = string.match(filey_tpe,'%.(%w+)')
	end

	if host == '127.0.0.1' then
		local tmp_path = './transit/amr'
		if not string.find(urlpath,'%/',2) then
			-- dfsapi 存储失败,存放本地
			tmp_path = './transit/erramr'
		end

		local file_full_path = string.format("%s%s",tmp_path,urlpath)

		local f = io.open(file_full_path , 'r')
		if not f then 
			only.log('E',string.format("open file failed! %s", file_full_path))
			return false ,'','' 
		end

		local file_data = f:read("*all")
		f:close()

		if not app_utils.check_is_amr(file_data,#file_data) then
			only.log('E',  "local voice file is invalid: %s", dfsurl) 
			return false, '', ''
		end
		return true,filey_tpe, file_data
	end

	local ok,ret = cutils.http(host,port,req,#req)
	if not ok then
		only.log('E','get dfs data when send get request failed!')
		return false,'','' 
	end

	local split = string.find(ret,'\r\n\r\n')
	if not split then return false , '' end
	local head = string.sub(ret,1,split)
	local file_data = string.sub(ret,split+4,#ret)

	if not app_utils.check_is_amr(file_data,#file_data) then
		-- only.log('E',string.format("data length:%s",#file_data))
		-- only.log('E',string.format("data header:%s",string.sub(file_data,1,20)))
		only.log('E',  "voice file is invalid: %s", dfsurl) 
		return false, '', ''
	end

	if parstring then
		local par_tab = ngx.decode_args(parstring)
		if type(par_tab) == "table" and par_tab['daokeFilePath'] and par_tab['position']  then
			if (string.find(par_tab['daokeFilePath'] , "productList")) == 1 and ( par_tab['position'] == "1" or par_tab['position'] == "2" ) then
				local daoke_file_path = string.format("./transit/amr/%s",par_tab['daokeFilePath'])
				local f = io.open(daoke_file_path,'r')
				if f then 
					local append_data = f:read("*all")
					f:close()
					if  append_data and app_utils.check_is_amr(append_data,#append_data) and  (#append_data +  #file_data) <= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
						if par_tab['position'] == "1" then
							-- file_data = append_data .. file_data
							-- 2015-06-16 拼接文件,去除amr文件头
							file_data = append_multimedia_file(append_data,file_data)
						elseif par_tab['position'] == "2" then
							-- file_data = file_data .. append_data
							file_data = append_multimedia_file(file_data,append_data)
						end
					end
				else
					only.log('E',  "daoke file get failed  %s" , par_tab['daokeFilePath'] ) 
				end
			end
		end
	end

	return true , filey_tpe, file_data
end

local function save_read_adtalk_to_message_redis(weibo, accountid, cur_appkey )

	local cur_time = os.date("%Y%m%d%H%M")
	local cur_time = math.floor(cur_time/10)

	local redis_key = string.format("releaseAdTalk:%s:%s:%s",accountid,cur_appkey,cur_time)
	local redis_value = string.format("%s|%s",os.time(),weibo['bizid'])
	local ok  = redis_api.hash_cmd("message_hash",weibo["bizid"],"SADD",redis_key , redis_value)
	if not ok then 
		only.log("E","save release adtalk message failed !key:%s,value:%s",redis_key , redis_value)
	end

	local redis_key = string.format("releaseAdTalk:%s",cur_time)
	local redis_value = string.format("%s:%s",accountid,cur_appkey)
	local ok = redis_api.hash_cmd("message_hash",weibo["bizid"],"SADD",redis_key, redis_value)
	if not ok then 
		only.log("E","save release adtalk message failed !key:%s,value:%s",redis_key , redis_value)
	end

	-- local redis_key = string.format("releaseAdTalkID:%s",cur_time)
	-- local redis_value = string.format("%s",adtalk_id)
	-- local ok  = redis_api.cmd(redis_name,"SADD",redis_key , redis_value)
	-- if not ok then 
	-- 	only.log("E","save release adtalk message failed !key:%s,value:%s",redis_key , redis_value)
	-- end

	-- local redis_key = string.format("releaseAdTalkID:%s:%s",adtalk_id,cur_time)
	-- local redis_value = string.format("%s|%s|%s",accountid,weibo['bizid'])
	-- local ok  = redis_api.cmd(redis_name,"SADD",redis_key , redis_value)
	-- if not ok then 
	-- 	only.log("E","save release adtalk message failed !key:%s,value:%s",redis_key , redis_value)
	-- end
	return true	
end
----保存数据至mysql里面
local function save_read_adtalk_info( weibo, accountid, args , adtalk_id , cur_appkey , cur_senderAccountID , cur_longitude, cur_latitude  )
	local sql_str = string.format(G.sql_save_adtalk_info,G.cur_month, cur_appkey, 
	cur_senderAccountID, accountid, G.cur_time,
	cur_longitude * dk_utils.gps_point_unit ,cur_latitude * dk_utils.gps_point_unit ,weibo['level'],weibo['content'] or '',
	(tonumber(weibo['longitude']) or 0)  *  dk_utils.gps_point_unit ,
	(tonumber(weibo['latitude']) or 0)  *  dk_utils.gps_point_unit,
	args['tokencode'],weibo['bizid'],adtalk_id,0,0,0,0)
	local ok_status,ok_ret = mysql_api.cmd(app_adtalk_db,'INSERT',sql_str)
	if not ok_status then
		only.log('E','save read adtalk failed! %s ', sql_str )
	end
end

local function update_read_adtalk_info( accountid, bizid , cur_longitude, cur_latitude  )
	local sql_str = string.format(G.sql_update_adtalk_info,G.cur_month,  G.cur_time , 
	cur_longitude * dk_utils.gps_point_unit , 
	cur_latitude * dk_utils.gps_point_unit , 
	accountid , table.concat(bizid,"','" ))
	local ok_status,ok_ret = mysql_api.cmd(app_adtalk_db,'UPDATE',sql_str)
	if not ok_status then
		only.log('E','update read adtalk failed! %s ', sql_str )
	end
end


------ 保存已经读取的微博
local function save_read_weibo_info(weibo,accountID,args , appKey , adtalk_id )

	local cur_time = os.date("%Y%m%d%H%M")
	local cur_time = math.floor(cur_time/10)

	local redis_key = string.format("releaseMessage:%s:%s:%s",accountID,appKey,cur_time)
	local redis_value = string.format("%s|%s",os.time(),weibo['bizid'])
	local ok  = redis_api.hash_cmd("message_hash",accountID,"SADD",redis_key , redis_value)
	if not ok then 
		only.log("E","save release message failed !key:%s,value:%s",redis_key , redis_value)
	end

	local redis_key = string.format("releaseMessage:%s",cur_time)
	local redis_value = string.format("%s:%s",accountID,appKey)
	local ok  = redis_api.hash_cmd("message_hash",accountID,"SADD",redis_key , redis_value)
	if not ok then 
		only.log("E","save release message failed !key:%s,value:%s",redis_key , redis_value)
	end

	local redis_key = string.format("releaseMessageInfo:%s:%s",weibo['bizid'],cur_time)
	local redis_value = string.format("%s|%s|%s|%s|%s",
	accountID,
	os.time(),
	(tonumber(tab_longitude[1]) or 0)  * dk_utils.gps_point_unit,
	(tonumber(tab_latitude[1]) or 0)  * dk_utils.gps_point_unit,
	adtalk_id	
	)

	local ok  = redis_api.hash_cmd("message_hash",weibo["bizid"],"SADD",redis_key , redis_value)
	if not ok then 
		only.log("E","save release message info failed !key:%s,value:%s",redis_key , redis_value)
	end

	return true
end

--
--	local sql_tab = {
--		a1 = 'readGroupTTSWeibo',
--		a2 = 'readGroupMultimediaWeibo',
--		a3 = 'readPersonalTTSWeibo',
--		a4 = 'readPersonalMultimediaWeibo',
--		a5 = 'readPersonalTTSWeibo',
--		a6 = 'readPersonalMultimediaWeibo',
--	}
--	local bizid = weibo['bizid']
--	local tb_type = string.sub(bizid,1,2)
--
--	local sql_table = string.format("%s_%s",sql_tab[tb_type], G.cur_month )
--	local sender_info = weibo['sender_info']
--
--	local sender_accountID , callback_url, sender_fileid = '','',''
--	local appKey = 0
--	local fileID = ''
--	local commentID = ''
--	if sender_info then
--		sender_accountID = sender_info['senderAccountID'] or ''
--		sender_fileid    = sender_info['sourceID'] or ''
--		callback_url     = sender_info['callbackURL'] or ''
--		appKey           = tonumber(sender_info['appKey']) or 0
--		fileID           = sender_info['fileID'] or ''
--		commentID        = sender_info['commentID'] or ''
--	end
--
--	if #tab_longitude < 1 then
--		table.insert(tab_longitude,0)
--	end
--
--	if #tab_latitude < 1 then
--		table.insert(tab_latitude,0)
--	end
--
--	local speed_str = ""
--	if weibo['speed'] and type(weibo['speed']) == "table" then
--		speed_str = string.format("[%s]",table.concat(weibo['speed'],","))
--	end
--
--	local direction_str = ""
--	if weibo['direction'] and type(weibo['direction']) == "table" then
--		direction_str = string.format("[%s]",table.concat(weibo['direction'],","))
--	end
--
--	local sql_str =  string.format("insert into %s set senderAccountID = '%s', sourceID = '%s' , bizid  = '%s'  , releaseTime = %s " .. 
--									" , readStatus = 0 , releaseLongitude = %s , releaseLatitude = %s  " ..
--									" , level = %s , content = '%s' , callbackURL = '%s' " ..
--									" , speed = '%s'  , longitude = %s , latitude = %s  , distance = %s , direction = '%s' , tokenCode = '%s' "  ..
--									" , appKey = '%s', fileID = '%s' , adtalkID = '%s'  " ,
--									sql_table,sender_accountID,sender_fileid,weibo['bizid'],G.cur_time ,
--									(tonumber(tab_longitude[1]) or 0)  * dk_utils.gps_point_unit,
--									(tonumber(tab_latitude[1]) or 0)  * dk_utils.gps_point_unit,
--									weibo['level'],
--									weibo['content'] or '',
--									callback_url,
--									speed_str,
--									(tonumber(weibo['longitude']) or 0)  * dk_utils.gps_point_unit ,
--									(tonumber(weibo['latitude']) or 0)  * dk_utils.gps_point_unit ,
--									(tonumber(weibo['distance']) or 0) ,
--									direction_str,
--									args['tokencode'],
--									appKey,
--									fileID,
--									adtalk_id)
--
--	if tb_type == 'a1' or tb_type == 'a2' then
--		sql_str = sql_str .. string.format("  , receiverAccountID = '%s' , groupID = '%s', multimediaURL = '%s'   " , 
--											G.cur_accountid,
--											weibo['groupID'],
--											weibo['multimediaFileURL'] or '' )
--
--  	elseif tb_type == 'a3' or tb_type == 'a4' then
--  		---- 个人微博
--  		sql_str = sql_str .. string.format(" , commentID = '%s' , receiverAccountID = '%s'   " , commentID,  G.cur_accountid )
--  		if tb_type == 'a4' then
--  			local multimediaFile_url = weibo['multimediaFileURL'] or ''
--  			local multimediaFile_type = 'amr'
--  			if #multimediaFile_url  > 5 then
--  				local tmp_url = string.sub(multimediaFile_url,-5,-1)
--  				local find_dot = string.find(tmp_url,'%.')
--  				if find_dot then
--  					multimediaFile_type = string.sub(tmp_url,find_dot+1,#multimediaFile_url)
--  				end
--  			end
--  			sql_str = sql_str .. string.format(" , multimediaURL = '%s' , fileType = '%s'   " , 
-- 									multimediaFile_url,
--  									multimediaFile_type )
--  		end
--  	elseif tb_type == 'a5' or tb_type == 'a6' then
--  		---- 区域微博
--  		sql_str = sql_str .. string.format(" , commentID = '%s' , receiverAccountID = '%s'   " , commentID, G.cur_accountid)
--  		if tb_type == 'a6' then
--  			local multimediaFile_url = weibo['multimediaFileURL'] or ''
--  			local multimediaFile_type = 'amr'
--  			if #multimediaFile_url  > 5 then
--  				local tmp_url = string.sub(multimediaFile_url,-5,-1)
--  				local find_dot = string.find(tmp_url,'%.')
--  				if find_dot then
--  					multimediaFile_type = string.sub(tmp_url,find_dot+1,#multimediaFile_url)
--  				end
--  			end
--  			sql_str = sql_str .. string.format(" , multimediaURL = '%s' , fileType = '%s'   " , 
-- 									multimediaFile_url,
--  									multimediaFile_type )
--  		end
--  	end
--
--  	local ok_status,ok_ret = mysql_api.cmd(app_weiboread_db,'INSERT',sql_str)
--  	if not ok_status then 
--  		only.log('E',   'save read weibo failed!  %s  ', sql_str ) 
--  		return false
--  	end
--  	return true
--end
--
local function get_current_group_msg_type( channel_id, accountid )
	---- (++)加加按键默认为3
	---- (+)加按键默认为2
	local w_type = 3
	if #tostring(accountid) ~= 10 then
		return w_type
	end

	local group_val = dk_utils.lru_cache_get_userinfo( accountid, "groupVoiceChannelID")
	if tostring(group_val) == tostring(channel_id) then
		return w_type 
	end

	local voice_val = dk_utils.lru_cache_get_userinfo( accountid, "voiceCommandChannelID")
	if tostring(voice_val) == tostring(channel_id) then
		w_type = 2 
	end
	return w_type
end

---- 获取微频道昵称前缀
local function do_get_pre_sender_microchannel_name( groupid )
	if not groupid or #tostring(groupid) < 9 then
		return false,nil
	end

	---- 稍后再优化至lrucache内部2015-06-05
	--local ok,url = redis_api.cmd('private','get',groupid .. ':channelNameUrl')
	local url = dk_utils.lru_cache_get_channel_info(groupid , "channelNameUrl") 
	if url then
		local file_ok,file_type, file_data = get_dfs_data_by_http(url)
		if file_ok and file_data then
			only.log('D', "%s add channelNameUrl is url:%s ", groupid, url ) 
			return true,file_data
		end
	end
	return false,nil
end

----- 获取发送者昵称
local function do_get_pre_sender_nickname( account_id )
	if not account_id then return false,nil end
	local imei = nil
	if #account_id == 10 then
		local url = dk_utils.lru_cache_get_userinfo( account_id, "nicknameURL")
		if url then
			local file_ok,file_type, file_data = get_dfs_data_by_http(url)
			if file_ok and file_data then
				-- only.log('D', "%s add pre nickname is url:%s ", account_id, url ) 
				return file_ok,file_data
			end
		end

		local tmp_imei = dk_utils.lru_cache_get_userinfo( account_id, "IMEI")
		if tmp_imei then
			imei = tmp_imei
		end
	else
		imei = account_id
	end

	if imei and #tostring(imei) == 15 then
		---- 读取IMEI后面4位
		local cur_imeifile = string.format("./transit/amr/productList/IMEISuffix/%s.amr",string.sub(imei,-4))
		local f = io.open(cur_imeifile, 'r')
		if f then
			-- only.log('D', "%s add pre nickname is imei:%s --- ", account_id, imei )
			local file_data = f:read("*all")
			f:close()
			if app_utils.check_is_amr(file_data,#file_data) then
				return true,file_data
			else
				only.log('E', "%s.amr-->--invalid amr file!", imei ) 
			end
		end
		only.log('E', "%s get imei suffix:%s --- failed ,file:%s ", account_id, imei , cur_imeifile )
		return false,nil
	end
end

-- 判断用户是否添加前缀 
-- 没有分大类的情况下,则直接判断1,33,x
-- 默认为关闭状态
function check_add_prefix_nickname( account_id , app_type )
	if not app_type or not account_id or #account_id ~= 10 then return true end

	-- local ok_val = dk_utils.lru_cache_get_userinfo( account_id , "userMsgSubscribed" )
	-- if not ok_val or #ok_val < app_type then return  true end
	-- if app_type < 32 then 
	-- 	only.log('E',string.format("[weibo]weibo_type is error:%s ", app_type ) )
	-- 	return false 
	-- end

	-- if tostring(string.sub(ok_val,1,1)) == "1" 						---- 系统总开关
	-- 	and tostring(string.sub(ok_val,33,33)) == "1" 					---- User总开关
	-- 	and tostring(string.sub(ok_val,tonumber(app_type),tonumber(app_type))) == "1"  then
	-- 	return true
	-- end

	---- lru cache只存储第164位
	---- lru cache just save 164 index value
	local ok_val = dk_utils.lru_cache_get_userinfo( account_id , "userMsgSubscribed" )
	if not ok_val or #tostring(ok_val) < 1 then
		return true
	end

	if tostring(ok_val) == "1" then
		return true
	end

	return false
end



function split_data_with_gps( accountid, gps , imei, imsi, tokencode  )
	local gps_table = parse_data( gps )
	if type(gps_table) == "table" then
		local sql_gps = get_gps_sql(gps_table, accountid or '', imei , imsi , tokencode , false, tab_gpsinfo )
		-- gps是否写mysql 2014-09-16 
		if tonumber(dk_utils.DK_WRITE_MYSQL_WITH_GPS) ~= 0 then
			if sql_gps then
				local ok,ret = mysql_api.cmd(app_newstatus_db, "insert", sql_gps)
				if not ok then
					only.log('E',  'save gps data failed  %s ', sql_gps ) 
				end
			else
				only.log('D', "gps is error data!  %s ", gps )
			end
		end
		if tab_gpsinfo then
			dk_utils.set_gpsinfo(tab_gpsinfo,G.cur_time)
		end
	else
		only.log('E', "gps split failed! %s ", gps ) 
	end
end



local function split_data_with_extragps( accountid, extragps, imei, imsi, tokencode )
	local gps_table = parse_data( extragps )
	if type(gps_table) == "table" then
		local tab_extragpsinfo = {}
		get_gps_sql(gps_table, accountid or '', imei , imsi , tokencode , true, tab_extragpsinfo )
		if tab_extragpsinfo then
			--
			--only.log('E', "set extragps is %s",scan.dump(tab_extragpsinfo) ) 
			--dk_utils.set_extragpsinfo(tab_extragpsinfo )
		end
	else
		only.log('E', "extragps split failed! %s", extragps ) 
	end
end

local function split_data_with_other( args, accountid )

	if not args["other"] then return false end
	local tmp_tab = utils.str_split(args["other"],"|")
	if not tmp_tab or #tmp_tab < 1  then return false end

	for i,val in pairs(tmp_tab) do
		if val and (string.find(tostring(val),"extragps:")) == 1  then
			----gps补传 
			local tmp_other_str = string.sub(val,10,#val)
			split_data_with_extragps(accountid, tmp_other_str, args["imei"], args['imsi'] , args['tokencode'] )
		else
			----xxxxx
		end
	end
end

---- get_adtalk_info 2015-06-03
---- return 
---- 1 bool succed / failed
---- 2 append type 
---- 3 append binary 

local function get_adtalk_info( cur_longitude, cur_latitude, cur_appkey  )

	-- SRANDMEMBER 121.36520&31.22226:2491067261:All:20150604:0309:myshop

	local hour_tab = {
		[1] = "0309",
		[2] = "0914",
		[3] = "1420",
		[4] = "2003",
	}

	local cur_time = tonumber(os.date("%H"))
	local cur_slot = 1
	if cur_time >= 3 and cur_time < 9 then
		cur_slot = 1 
	elseif cur_time >= 9 and cur_time < 14 then
		cur_slot = 2 
	elseif cur_time >= 14 and cur_time < 20 then
		cur_slot = 3 
	elseif cur_time >= 20 or cur_time < 3 then
		cur_slot = 4 
	end


	only.log('D',"********cur_longitude:%s,cur_latitude:%s************** ", cur_longitude, cur_latitude) 
	local cur_longitude = string.format("%.2f",math.floor(tonumber(cur_longitude)*100)/100)
	local cur_latitude= string.format("%.2f",math.floor(tonumber(cur_latitude)*100)/100)

	local cur_adtalk_key = string.format("%s&%s:%s:All:%s:%s:myshop",
	cur_longitude,
	cur_latitude,
	cur_appkey,
	G.cur_date,
	hour_tab[cur_slot])

	local ok, ret = redis_api.cmd('adTalkServer','SRANDMEMBER',cur_adtalk_key,'1')

	only.log('D',"adtalk redis-key %s " , cur_adtalk_key ) 

	if ok and ret and type(ret) == "table" and #ret == 1 then
		local adtalk_id = ret[1]

		only.log('W',"IMEI:%s,cur_adtalk_key:%s adtalk_id:%s " , G.imei, cur_adtalk_key , adtalk_id )

		local ok , info = redis_api.cmd('adTalkServer','hgetall', adtalk_id )
		if ok and info then
			-- 192.168.1.13:6379> hgetall 166:ADDetail 
			-- 1) "remainNumber"
			-- 2) "1000"
			-- 3) "type"
			-- 4) "0"
			-- 5) "url"
			-- 6) "http://g4.tweet.daoke.me/group4/M03/33/53/c-dJUFVuemqAXf8pAAAGBN_SaQQ433.amr"

			local cur_append_type = tonumber(info['type']) or 0
			local cur_append_url = info['url']
			local cur_append_binary = nil
			local cur_append_status = false
			local ok, data_type, data_binary = get_dfs_data_by_http(cur_append_url)
			if ok and data_type and data_binary then
				cur_append_status = true
				cur_append_binary = data_binary
			end

			local ok , really_remain_count = redis_api.cmd('adTalkServer','HINCRBY',adtalk_id,'remainNumber',-1)
			if (tonumber(really_remain_count) or -1 ) < 1  then
				---- 广告发完了,需要清理原始redis信息
				redis_api.cmd('adTalkServer', 'srem', cur_adtalk_key,adtalk_id)
				redis_api.cmd('adTalkServer', 'del', adtalk_id)
			end

			only.log('W',"adtalk_info get status:%s adtalk_id:%s adtalk_url:%s " , tostring(cur_append_status) ,adtalk_id , cur_append_url )

			return cur_append_status, cur_append_type , cur_append_binary , cur_append_url , adtalk_id 
		elseif ok and not info then
			redis_api.cmd('adTalkServer', 'srem', cur_adtalk_key,adtalk_id)
			redis_api.cmd('adTalkServer', 'del', adtalk_id)
		end
	end
	return false,nil,nil
end



local function handle()
	local req_head   = ngx.req.raw_header()
	local req_ip     = ngx.var.remote_addr
	local req_body   = ngx.req.get_body_data()
	local req_method = ngx.var.request_method

	local args = ngx.req.get_uri_args()
	if req_method == 'POST' then
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')
		if not boundary then
			args = ngx.decode_args(req_body)
		else
			args = utils.parse_form_data(req_head, req_body)
		end
	end

	G["ip"]                = req_ip
	G["body"]              = req_body

	url_tab['client_host'] = req_ip
	url_tab['client_body'] = req_body


	local cur_date = ngx.get_today()

	G.cur_month = string.gsub(string.sub(cur_date,1,7),"%-","")
	G.cur_time = ngx.time()


	local cur_today = string.gsub(ngx.get_today(),"%-","")
	G.cur_date = cur_today

	-- 280614   2014-06-28
	G.cur_gmtdate = string.format("%s%s%s",string.sub(cur_date,9,10), string.sub(cur_date,6,7), string.sub(cur_date,3,4) )
	G.cur_year = tonumber(string.sub(cur_date,1,2)) * 100

	if not args or type(args) ~= "table" then
		only.log('E', "bad request!")
		go_exit()
	end

	if not req_body then
		G.body              =  utils.table_to_kv(args) 		----ngx.encode_args(args)
		url_tab['client_body'] = G.body
	end

	G.imei = args['imei']
	local ok = check_parameter( args )
	if not ok then
		go_exit()
	end

	local ok = verify_parameter( args )
	if not ok then
		go_exit()
	end

	only.log('D',"newstatus Notice log imei:%s  imsi:%s  tokencode:%s " , args['imei'], args['imsi'], args['tokencode'])

	local accountid = dk_utils.lru_cache_get_accountid(G.imei)
	if #tostring(accountid) == 10 then
		G.cur_accountid = accountid
	else
		G.cur_accountid = G.imei
	end

	---- 可能中途掉线
	---- 避免操作redis过于频繁
	--------------------------------------------------
	-------------debug------------
	if G.cur_time % 2 == 0 then
		redis_api.cmd('statistic', 'sadd', 'onlineUser:set', G.cur_accountid )
		redis_api.cmd('private', 'set', G.cur_accountid .. ":heartbeatTimestamp", G.cur_time )
	end


	-->| STEP 6 |<--
	-->> reset table
	tab_jo              = {}
	tab_jo['collect']   = true
	tab_jo["accountID"] = G.cur_accountid
	tab_jo["IMEI"]      = args["imei"]
	tab_jo["tokenCode"] = args["tokencode"]
	tab_jo["model"]     = args["mod"]


	tab_GPSTime         = {}
	tab_longitude       = {}
	tab_latitude        = {}
	tab_direction       = {}
	tab_speed           = {}
	tab_altitude        = {}

	-->> 保存GPS至数据库
	if args["gps"] then
		split_data_with_gps( accountid , args["gps"] ,  args["imei"], args['imsi'] , args['tokencode'] )
	end

	if args['other'] then
		split_data_with_other(args, accountid)
	end

	---- 用户当前最新的经纬度
	local cur_longitude = nil
	local cur_latitude = nil

	----  数据转发 
	if tab_GPSTime and #tab_GPSTime > 0 then

		if #tab_longitude > 0 then
			cur_longitude = tab_longitude[1]
		end

		if #tab_latitude > 0 then
			cur_latitude = tab_latitude[1]
		end

		tab_jo["GPSTime"]	= tab_GPSTime
		tab_jo["longitude"]	= tab_longitude
		tab_jo["latitude"]	= tab_latitude
		tab_jo["direction"]	= tab_direction
		tab_jo["speed"]		= tab_speed
		tab_jo["altitude"]	= tab_altitude
		if (other_GPSTime and #other_GPSTime > 0 ) then
			---- gps补传 2015-04-27 
			tab_jo['extragps'] = {}
			tab_jo['extragps']["GPSTime"]   = other_GPSTime
			tab_jo['extragps']["longitude"] = other_longitude
			tab_jo['extragps']["latitude"]  = other_latitude
			tab_jo['extragps']["direction"] = other_direction
			tab_jo['extragps']["speed"]     = other_speed
			tab_jo['extragps']["altitude"]  = other_altitude
		end

		dk_utils.post_data_to_other(tab_jo, args)
	end


	---- 保存已经读取的微博
	if args["bizid"] and #args["bizid"]  > 0 then

		save_read_bizid_to_newstatus_info(G.cur_accountid or '', args, args["bizid"])
		save_read_bizid_to_message_redis(G.cur_accountid or '', args, args["bizid"] )
		update_read_adtalk_info( G.cur_accountid, args["bizid"] , cur_longitude or 0, cur_latitude or 0 )

	end

	---- 增加静音判断
	---- mt=17936 
	if args['mt'] then
		if (tonumber(args['mt']) or 0 ) < 4095  then
			---- 用户当前是静音状态.不发音频文件 
			only.log('D', " %s volume is 0 , mt:%s ---->----return 555 " , G.cur_accountid , args['mt']  ) 
			redis_api.hash_cmd('weibo_hash', G.cur_accountid,'del', G.cur_accountid .. ':weiboPriority')
			go_empty()
		end
	end

	----cur_weibo_version 当前微博类型 
	---- 1 之前的老微博
	---- 2 为新微博
	local cur_weibo_version = nil
	local new_weibo_tab = {}

	local w_type = 1
	---- 获取微博
	weibo, weibo_type = fetch_weibo_pre( G.cur_accountid , 'weiboPriority')
	if not weibo then

		---- 2015-07-04 临时忽略取新版微博业务
		if true then
			only.log('D', " %s  get weibo empty---->----return 555 " , G.cur_accountid   )
			go_empty()
		end

		weibo = fetch_weibo_new( G.cur_accountid , 'weiboPriority' )
		if not weibo then
			only.log('D', " %s  get weibo empty---->----return 555 " , G.cur_accountid   )
			go_empty()
		end

		if weibo['direction'] and (string.find(weibo['direction'],"%[") )  then
			local tmp_tab = utils.str_split(string.match(weibo['direction'],"%[(.+)%]"),",")
			weibo['direction'] = {}
			weibo['direction'][1] = tonumber(tmp_tab[1])
			weibo['direction'][2] = tonumber(tmp_tab[2])
		end

		if weibo['speed'] and (string.find(weibo['speed'],"%[")) then
			local tmp_tab = utils.str_split(string.match(weibo['speed'],"%[(.+)%]"),",")
			weibo['speed'] = {}
			weibo['speed'][1] = tonumber(tmp_tab[1])
			weibo['speed'][2] = tonumber(tmp_tab[2])
		end

		local new_weibo_tab = {
			weibo_info = weibo,
		}

		new_weibo_tab['curAccountID'] = accountid or ''

		if #tab_longitude > 0 then
			new_weibo_tab['curLongitude'] = tab_longitude[1]
		end

		if #tab_latitude > 0 then
			new_weibo_tab['curLatitude'] = tab_latitude[1]
		end
		new_weibo_tab['curTokenCode'] = args['tokencode']
		new_weibo_tab['curTime'] = G.cur_time
		cur_weibo_version = 2 
		w_type = tonumber(weibo['messageType'])
	else
		cur_weibo_version = 1 
		w_type = tonumber(weibo['type'])
	end


	local bizid = weibo['bizid']
	local level = weibo['level']
	local dfsurl = weibo['multimediaFileURL'] or ''

	local dfs_data_isok = false
	local dfs_data_type = 'amr'
	local dfs_data_binary = ''
	if  dfsurl ~= '' then
		---- http://g1.tweet.daoke.me/group1/M00/00/00/rBALhFNNLg6ABKqHAAAotg-PQhY599.amr
		dfs_data_isok,dfs_data_type,dfs_data_binary = get_dfs_data_by_http(dfsurl)
		---- 1 true --->---succed   false  -->---failed
		---- 2 type is amr
		---- 3 binary is file data binary
	end

	if dfs_data_isok == false or not dfs_data_binary then
		only.log('E', " %s get dfsurl %s data failed---->----return 555 " , G.cur_accountid , dfsurl ) 
		go_empty()
	end

	---- 二进制文件小于300字节, 大于20K,不下发给终端 2014-11-26 
	if #dfs_data_binary < dk_utils.FILE_MIN_SIZE or #dfs_data_binary >= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
		only.log('W', " %s get dfsurl %s data succed but file length :%s [ERROR]" , G.cur_accountid , dfsurl ,#dfs_data_binary ) 
		go_empty()
	end


	---- 下发音频类型
	local w_type = tonumber(weibo['type'])
	---- 微频道增加前缀
	if weibo['groupID'] then
		--channelType=1 :主播频道，加频道名称前缀
		--channelType=2 :群聊频道，不需要频道前缀
		local channelType = dk_utils.lru_cache_get_channel_info(weibo['groupID'], "channelType")
		if (tonumber(channelType) or 0 ) == 1 then
			local ok,new_buff = do_get_pre_sender_microchannel_name(weibo['groupID'])
			if ok and new_buff then
				---- 2快音频合并总长度小于最大阀值
				if #dfs_data_binary + #new_buff <= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
					-- dfs_data_binary = new_buff .. dfs_data_binary
					---- 2015-06-16 文本拼接去除末文件头
					dfs_data_binary = append_multimedia_file( new_buff ,  dfs_data_binary )
				end
			end
		else
			---- w_type 2 voiceCommand groupMessageType
			---- w_type 3 groupCommand groupMessageType
			if w_type == 2 or w_type == 3 then
				---- 群组微博,需要判断终端设置按键
				w_type = get_current_group_msg_type( weibo['groupID'], G.cur_accountid)
				if not w_type then
					w_type = 3
				end
			end
		end
	end

	---- 添加发送着的前缀
	---- 164为添加前缀 
	---- 内部过滤 kxl1QuHKCD,OwQH5wZflD
	if weibo['sender_info'] and check_add_prefix_nickname(G.cur_accountid, 164 ) then
		local sender_info = weibo['sender_info']
		local sender_id = sender_info['senderAccountID']
		---- 只有feedback终端上来的音频文件才增加前缀
		if sender_id and sender_info['appKey'] and sender_info['appKey'] == dk_utils.FEEDBACKAPI_APPKEY then
			local ok,new_buff = do_get_pre_sender_nickname(sender_id)
			if ok and new_buff then
				---- 2快音频合并总长度小于最大阀值
				if #dfs_data_binary + #new_buff <= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
					-- dfs_data_binary = new_buff .. dfs_data_binary
					---- 2015-06-16 文本拼接去除末文件头
					dfs_data_binary = append_multimedia_file( new_buff ,  dfs_data_binary )
				end
			end
		end
	end


	local cur_adtalk_id = 0
	local cur_appkey = nil
	local cur_senderAccountID = ''

	-----添加获取广告内容 2015-06-03 
	if cur_longitude and cur_latitude then
		if weibo['sender_info'] then
			cur_appkey = weibo['sender_info']['appKey'] or ''
			cur_senderAccountID = weibo['sender_info']['senderAccountID'] or ''
		end
		---- feedbackapi, 2290837278
		---- 主播频道 , 1027395982 
		if cur_appkey and not (string.find("2290837278,1027395982", cur_appkey ) ) then
			local ok, append_type , append_binary, append_url, adtalk_id = get_adtalk_info( cur_longitude , cur_latitude ,cur_appkey )
			if ok and append_binary then
				---- 2快音频合并总长度小于最大阀值
				if #dfs_data_binary + #append_binary <= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then

					if append_type == 0 then
						-- dfs_data_binary = append_binary .. dfs_data_binary
						---- 2015-06-16 文本拼接去除末文件头
						dfs_data_binary = append_multimedia_file( append_binary ,  dfs_data_binary )
					elseif append_type == 1 then
						-- dfs_data_binary = dfs_data_binary .. append_binary
						---- 2015-06-16 文本拼接去除末文件头
						dfs_data_binary = append_multimedia_file( dfs_data_binary ,  append_binary )
					end
					cur_adtalk_id = tonumber(string.match(adtalk_id,"(%d.+):")) or 0

					-- only.log('W',"adtalk_id: %s , %s ", adtalk_id , cur_adtalk_id )
				else
					only.log('W',string.format("===adTalkServer adtalk_id:%s get url and binary is too big, will be droped==,%s %s %s, append_type:%s url is:%s  ",
					adtalk_id, cur_longitude , cur_latitude ,cur_appkey , append_type, append_url ))
				end
			end
		end
	end


	if cur_weibo_version then
		if cur_weibo_version == 1 then
			if weibo['sender_info'] then
				save_read_weibo_info(weibo, G.cur_accountid or '', args, weibo['sender_info']['appKey'] or '' ,cur_adtalk_id )
			else
				save_read_weibo_info(weibo, G.cur_accountid or '', args, '' ,cur_adtalk_id )
			end
		elseif cur_weibo_version == 2 then
			new_weibo_tab['adtalkID'] = cur_adtalk_id
			dk_utils.post_data_to_save_weibo(new_weibo_tab)
		end
	end


	---- 二进制文件小于300字节, 大于20K,不下发给终端 
	if #dfs_data_binary < dk_utils.FILE_MIN_SIZE or #dfs_data_binary >= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
		only.log('W', " %s get dfsurl %s data failed---->----return 555 file length:%s" , G.cur_accountid , dfsurl ,#dfs_data_binary ) 
		go_empty()
	end

	if cur_adtalk_id > 0 then
		---- 单独记录用户的广告下发数据
		if weibo['sender_info'] then
			save_read_adtalk_to_message_redis( weibo,G.cur_accountid , weibo['sender_info']['appKey'] or '')
		end
		save_read_adtalk_info( weibo, accountid, args , cur_adtalk_id , cur_appkey , cur_senderAccountID , cur_longitude or 0 , cur_latitude or 0 )
	end


	local result_tab = {
		bizid = weibo['bizid'],
		level = weibo['level'],
		content = {},
	}

	result_tab['type'] = w_type
	if (tonumber(weibo['longitude']) or 0 ) > 0  then
		result_tab['longitude'] = weibo['longitude']
	end

	if (tonumber(weibo['latitude']) or 0 ) > 0 then
		result_tab['latitude'] = weibo['latitude']
	end

	if tonumber(weibo['distance']) then
		result_tab['distance'] = weibo['distance']
	end

	if weibo['direction'] then
		if #weibo['direction'] == 2 and (tonumber(weibo['direction'][1]) or -1 ) ~= -1 then
			result_tab['direction'] =  weibo['direction']
		end
	end

	if weibo['speed'] then
		if #weibo['speed'] == 2 and tonumber(weibo['speed'][1]) ~= -1 then
			result_tab['speed'] =  weibo['speed']
		end
	end

	---- 2014-11-07 用户终端禁言功能
	-- local ok,shutup = redis_api.cmd('private','get',string.format("%s:shutup",G.cur_accountid))
	-- if ok and shutup and (tonumber(shutup) or 0 ) == 1  then
	-- 	result_tab['shutup'] = "1"
	-- else
	-- 	result_tab['shutup'] = "0"
	-- end

	local shutup = dk_utils.lru_cache_get_userinfo(G.cur_accountid,"shutup")
	if (tonumber(shutup) or 0 ) == 1  then
		result_tab['shutup'] = "1"
	else
		result_tab['shutup'] = "0"
	end

	if weibo['tipType'] then
		result_tab['tipType'] = tostring(weibo['tipType'])
	else
		result_tab['tipType'] = "0"
	end

	if weibo['autoReply'] then
		result_tab['autoReply'] = weibo['autoReply']
	end
	if weibo['intervalDis'] then	--in new version weibo the intervalDis willed fixed to invalidDis  
		result_tab['invalidDis'] = weibo['intervalDis']
	end


	-- ---- 2014-11-12  刘梦丽测试 微博反馈类型
	-- if (string.find("690688063102419,578539621847440,258324617103893,785209117984706",tostring(G.imei))) then

	-- 	if tostring(G.imei) == "258324617103893" then
	-- 		result_tab['tipType'] = "1"
	-- 	else
	-- 		result_tab['tipType'] = "0"
	-- 	end

	-- 	---- 2014-11-14  针对特殊IMEI,发送微博之后自动回复 
	-- 	if (string.find("785209117984706",tostring(G.imei))) then
	-- 		result_tab['autoReply'] = "1"
	-- 	end

	-- 	result_tab['invalidDis'] = "80"
	-- end

	result_tab['content']['mmfiletype'] = dfs_data_type
	result_tab['content']['mmfilelength'] = STR_LEN(dfs_data_binary)




	--每五分钟，统计一次下发语音文件大小
	--redis 只保留一个小时的数据
	--key:imei:amrfilelength
	--local cur_time = os.date("%Y%m%d%H%M")
	--if math.mod(cur_time,5) ~= 0 then
	--	cur_time = cur_time - math.mod(cur_time,5)
	--end

	--local front_time = os.date("%Y%m%d%H%M",os.time()-3600)
	--if math.mod(front_time,5) ~= 0 then
	--	front_time = front_time - math.mod(front_time,5)
	--end

	--local key  = string.format("%s:amrFileLength",args['imei'])

	--local ok, ret = redis_api.cmd("private","eval", string.format(G.redis_eval_file_length, key, result_tab['content']['mmfilelength'] ,cur_time, key ,front_time),0)
	--if not ok or not ret then 
	--	only.log('E',"save release amr file length filed! redis_eval :%s", G.redis_eval_file_length)
	--end

	local ok_status , head_result = pcall(cjson.encode,result_tab)
	if not ok_status or not head_result then
		go_exit()
	end

	---- 统计已读取微博 2014-09-23 
	---- 区分个人微博与群组微博 2014-10-20
	if weibo['groupID'] and #tostring(weibo['groupID']) > 3  then
		redis_api.cmd('statistic','HINCRBY',string.format('%s:readGroupIDWeiboTotalInfo',cur_today),string.format("%s:totalNum",weibo['groupID']),1)
	else
		redis_api.cmd('statistic','HINCRBY',string.format('%s:readPersonalWeiboTotalInfo',G.cur_month),string.format("%s:totalNum",cur_today),1)
	end

	---- 2014-11-26 下发bizid用户的列表
	---- 数据部门的redis统计server
	-- local tmp_redis_key = string.format("%s:%s:reallySendUserList", weibo['bizid'], cur_today )
	-- redis_api.cmd('dataCore_redis','sadd' , tmp_redis_key , G.cur_accountid )
	-- redis_api.cmd('dataCore_redis','expire', tmp_redis_key , dk_utils.DATACORE_EXPIRE_MAXTIME )

	---- reallySendCount
	---- 6.2: 不同业务用户下发数
	-- local tmp_appkey_info = weibo['sender_info']
	-- if tmp_appkey_info then
	-- 	tmp_redis_key = string.format("%s:%s:%s:reallySendCount",G.cur_accountid,cur_today,tmp_appkey_info['appKey'])
	-- 	redis_api.cmd('dataCore_redis','incr',tmp_redis_key )
	-- 	redis_api.cmd('dataCore_redis','expire', tmp_redis_key , dk_utils.DATACORE_EXPIRE_MAXTIME )
	-- end


	ngx.header['RESULT'] = head_result
	save_urllog(head_result)
	gosay.respond_to_binary(url_tab, dfs_data_binary)

end

handle()
