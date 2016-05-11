-- ngx_newstatus.lua
-- auth: baoxue
-- Thu May 16 12:12:31 CST 2013

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

local MATH_FLOOR = math.floor
local STR_LEN    = string.len

local IS_NUMBER = utils.is_number
local IS_FLOOR  = utils.is_float
local IS_WORD   = utils.is_word


local weibo_reids_pre = "weibo"
local weibo_redis_new = "weiboNew"


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
	sql_upate_read_group_weibo    = "UPDATE %s_%s SET readStatus=1, readTime = unix_timestamp() , readLongitude='%s', readLatitude='%s' WHERE readStatus = 0 and receiverAccountID ='%s' AND bizid='%s' ",
	sql_upate_read_personal_weibo = " UPDATE %s_%s SET readStatus=1, readTime= unix_timestamp() , readLongitude='%s', readLatitude='%s' WHERE readStatus = 0 and  bizid='%s' ",
	sql_save_gps_info             = "INSERT INTO GPSInfo_%s(accountID, imei, imsi, createTime, collectTime, GMTTime, longitude, latitude, direction, speed, altitude, tokenCode) values %s ",
	sql_save_urllog               = "INSERT INTO urlLog_%s SET createTime = unix_timestamp() ,url='%s',clientip= inet_aton('%s'),returnValue='%s' " ,

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
	
	-------------debug------------
	---- 日志是否写urllog 2014-09-16
	if tonumber(dk_utils.DK_WRITE_MYSQL_WITH_URL) ~= 0 then
		local sql = string.format(G.sql_save_urllog, G.cur_month ,G.body,G.ip, returnValue)
		local ok,ret = mysql_api.cmd(app_url_db, "insert", sql)
		if not ok then
			only.log('E','save_url_failed! %s ', sql)
			return false
		end
		return true
	end
end

---- 参数异常,返回400
local function go_exit()
	only.log('D',"---IMEI:%s return 400-->---",tostring(G.imei))
	save_urllog(400)
	gosay.respond_to_httpstatus(url_tab,400)
end

---- 参数正常,没有微博,返回555
local function go_empty()

	---- 2014-11-07 用户终端禁言功能
	if G.cur_accountid then
		local ok,shutup = redis_api.cmd('private','get',string.format("%s:shutup",G.cur_accountid))
		if ok and shutup and (tonumber(shutup) or 0 ) == 1  then
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


local function check_parameter( args )
	--> check imei
	if (not IS_NUMBER(args["imei"])) or (STR_LEN(args["imei"]) ~= 15) or (string.find(args["imei"], "0") == 1) then
		only.log('E', "imei is error!")
		return false
	end
	--> check imsi
	if (not IS_NUMBER(args["imsi"])) or (STR_LEN(args["imsi"]) ~= 15) then
		only.log('E', "imsi is error!")
		return false
	end
	--> check mod
	if (not IS_WORD(args["mod"])) or (STR_LEN(args["mod"]) > 5) then
		only.log('E', "mod is error!")
		return false
	end

	--> check tokencode
	if (not IS_WORD(args["tokencode"])) or (STR_LEN(args["tokencode"]) ~= 10) then
		only.log('E', "tokencode is error!")
		return false
	end

	--> check other
	if args["other"] and (STR_LEN(args["other"]) > dk_utils.MAX_OTHER_LEN  ) then
		only.log('E', "other too long!")
		return false
	end
	--> check bizid
	local bizid = args["bizid"]
	if bizid then
		args["bizid"] = {}
		for v in string.gmatch(bizid, "([^,]+)") do
			if v and STR_LEN(v) > 0 and STR_LEN(v) ~= dk_utils.BIZID_LENGTH then
				only.log('E', "bizid is error!")
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
	local token_key = string.format('%s:tokenCode',args["imei"])
	local ok,tokencode = redis_api.cmd('private', "get", token_key )
	if not ok then
		only.log('E', "failed connect private redis!")
		return false
	end
	if not tokencode then
		only.log('W', "%s get tokencode=nil from redis! maybe tokencode over 48h -->--- 666 ", args["imei"] )
		go_stopnewstatus()
		return false
	end

	if tokencode ~= args["tokencode"] then
		only.log('E', " IMEI: %s  redis tokencode  [%s] != post tokencode [%s] ",args["imei"], tokencode, args["tokencode"])
		---- tokenCode无效,返回666
		go_stopnewstatus()
		return false
	end
	
	if not dk_utils.verify_mod_list[ args["mod"] ] then
		only.log('E', "mod of no avail! %s ", args["mod"] )
		return false
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
	only.log('E', '  %s = %s is error data!', name, value )
end

local function gmttime_to_time(gmttime)
	return os.time({day=tonumber(string.sub(gmttime, 1, 2)), month=tonumber(string.sub(gmttime, 3, 4)), year=G.cur_year + tonumber(string.sub(gmttime, 5, 6)), hour=tonumber(string.sub(gmttime, 7, 8)), min=tonumber(string.sub(gmttime, 9, 10)), sec=tonumber(string.sub(gmttime, 11, 12))})
end


local function parse_gps_data( gps_table )
	if not gps_table or #gps_table ~= 6 then return false end

	---- 可能出现,,,-1,的数据 2014-09-26
	if #gps_table[1] < 1 or #gps_table[2] < 1  or #gps_table[3] < 1  or #gps_table[4] < 1  or #gps_table[5] < 1  or #gps_table[6] < 1 then
		only.log('E',"gps data is Exp: %s",table.concat(gps_table,","))
		return false
	end 

	local char_long = string.sub(gps_table[2],-1)
	---- 2014-10-22 需要考虑异常情况
	if not EW_NUMBER[ char_long ] then
		only.log('E',"longitude: %s  char_longis error",gps_table[2] )
		return false
	end

	local save_info = {}

	save_info["longdir"] = EW[ char_long ]
	local char_lat = string.sub(gps_table[3],-1)

	---- 2014-10-22 需要考虑异常情况
	if not NS_NUMBER[ char_lat ] then
		only.log('E',"longitude: %s  char_lat is error",gps_table[3] )
		return false
	end
	save_info["latdir"] = NS[ char_lat ]

	--long lat
	local raw_long = tonumber( string.sub(gps_table[2], 1, -2) )
	local raw_lat = tonumber( string.sub(gps_table[3], 1, -2) )

	----经纬度转换失败的情况 2014-10-13
	if not raw_long or not raw_lat then
		only.log('E',string.format("longitude: %s  latitude: %s is error",gps_table[2], gps_table[3] ))
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
	if  math.abs(tonumber( G.cur_time ) - tonumber(time_stamp + TIME_DIFF ))  < MAX_TIME_UPDATE then
		---- 小于1小时内的数据不修正
		save_info["collectTime"] = time_stamp + TIME_DIFF
	else

		-- save_info["collectTime"] = ngx.time()
		only.log('E',string.format("%s ERROR data:%s===", G.imei, GMTtime))
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
	if (not utils.is_integer(save_info["altitude"])) or (STR_LEN(save_info["altitude"]) > 6) or (tonumber(save_info["altitude"]) < -9999) or (tonumber(save_info["altitude"]) > 99999) then lg("altitude", save_info["altitude"]) return false end
	
	return true,save_info
end

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

			local tmp_create_time = create_time
			if is_extragps then
				tmp_create_time = ""
			end

			table.insert(ret_gpsinfo_tab.list,string.format("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s",
											save_info['collectTime'], tmp_create_time, imei, accountid or "", 
											imsi,  t_GMTTime,
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
------ true  del
------ false ok --->---send msg to user 
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
	local sql_str = string.format("INSERT INTO newStatusInfo_%s(accountID, imei,imsi, createTime, tokenCode, bizid) values('%s', '%s', '%s' , unix_timestamp(), '%s', '%s')", 
														G.cur_month, 
														accountid or '', 
														args["imei"], 
														args["imsi"], 
														args["tokencode"], 
														table.concat( read_bizid , "," ) )
	
	local ok,ret = mysql_api.cmd(app_newstatus_db, "INSERT", sql_str)
	if not ok then
		only.log('E', "insert failed! %s ", sql_str )
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
	for _, v in pairs(bizid_tab) do

		---- 2014-11-26 读取bizid用户的列表
		---- 数据部门的redis统计server
		-- redis_api.cmd('dataCore_redis','sadd',string.format("%s:%s:reallyReadUserList", v , G.cur_month ) , G.cur_accountid )
		-- redis_api.cmd('dataCore_redis','expire',string.format("%s:%s:reallyReadUserList", v , G.cur_month ) , dk_utils.DATACORE_EXPIRE_MAXTIME )

		local sql_str = nil
		local begin_bizid = string.sub(v, 1, 2)
		if begin_bizid == 'a1' or begin_bizid == 'a2' then
			---- a1 集团 TTS 
			---- a2 集团 语音
			sql_str = string.format(G.sql_upate_read_group_weibo,
						sql_tab[begin_bizid],
						 G.cur_month,
						 longitude * dk_utils.gps_point_unit ,
						 latitude * dk_utils.gps_point_unit ,
						 G.cur_accountid,
						 v)
		elseif begin_bizid == 'a3' or begin_bizid == 'a4' then
			---- a3 个人 TTS 
			---- a4 个人 语音
			sql_str = string.format(G.sql_upate_read_personal_weibo,
						 sql_tab[begin_bizid],
						 G.cur_month,
						 longitude * dk_utils.gps_point_unit ,
						 latitude * dk_utils.gps_point_unit ,
						 v)
		elseif begin_bizid == 'a5' or begin_bizid == 'a6' then
			---- a5 区域 TTS 
			---- a6 区域 语音
			sql_str = string.format(G.sql_upate_read_personal_weibo,
						 sql_tab[begin_bizid],
						 G.cur_month,
						 longitude * dk_utils.gps_point_unit ,
						 latitude * dk_utils.gps_point_unit ,
						 v)
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

	---- 只有主动密圈,以及回复其他的密圈,才能禁止
	local ok_status,ok_groupMsg = redis_api.cmd("private","get", get_groupMsgKey)
	ok_groupMsg = tonumber(ok_groupMsg) or 0 

	repeat

		-- local ok,info = redis_api.cmd("weibo", "zrange", get_weibo_key, 0, 0)
		-- if not ok or not info then return nil,nil end
		-- local bizid = info[1] 

		---- 2015-01-12 
		local ok, bizid = redis_api.cmd(weibo_reids_pre,"eval", string.format(G.redis_eval_command, user, user  ) ,0)
		if not ok or not bizid then
			return nil,nil
		else
			-------- 先删除微博队列
			------ redis_api.cmd("weibo", "zrem", get_weibo_key, bizid)
			local ok,raw_weibo = redis_api.cmd(weibo_reids_pre, "get", bizid .. ":weibo")
			if not ok then
				only.log('E',string.format(" get %s:weibo info failed %s" ,bizid , raw_weibo))
			elseif ok and raw_weibo then

				only.log('D', string.format(' User:%s --- bizid:%s ---weibo:%s ',user, bizid, raw_weibo) )
				
				local begin_bizid = string.sub(bizid, 1, 2)
				if begin_bizid == 'a3' or begin_bizid == 'a4' then
					---- 删除个人微博
					redis_api.cmd(weibo_reids_pre, "del", bizid .. ":weibo")
				end
				ok,weibo_info = pcall(cjson.decode, raw_weibo)
				if not ok then
					only.log('E', weibo_info)
				else
					---- 判断微博有效期
					if weibo_expired_pre(weibo_info)  then
						redis_api.cmd(weibo_reids_pre, "del", bizid .. ":weibo")
						redis_api.cmd(weibo_reids_pre, 'del', bizid .. ':senderInfo')
					elseif   ok_groupMsg > cur_groupMsgTime and ok_groupMsg > 0  and (tonumber(weibo_info['level']) or 0)  > 21 then
						if begin_bizid == 'a3' or begin_bizid == 'a4' then
							redis_api.cmd(weibo_reids_pre, 'del', bizid .. ':senderInfo')
						end
					else
						---- 统计微博读取信息情况
						local ok,ret = redis_api.cmd(weibo_reids_pre,'get', bizid .. ':senderInfo')
						if ok and ret  then 
							local ok_json,ret_json = pcall(cjson.decode, ret)
							if ok_json and ret_json then 
								weibo_info['sender_info'] = ret_json
							end
						end
						return weibo_info,weibo_type[begin_bizid]
					end
				end
			end
		end
	until false
end



---- ### bizid的标识
---- * 1,3,5,7代表集团，个人，区域，分享的TTS微博
---- * 2,4,6,8代表集团，个人，区域，分享的语音微博

local function fetch_weibo_new(user, user_type)

	local cur_groupMsgTime = G.cur_time
	local get_groupMsgKey = string.format("%s:groupMsgTimestamp",G.imei)
	local get_weibo_key = string.format('%s:%s', user, user_type)

	---- 只有主动密圈,以及回复其他的密圈,才能禁止
	local ok_status,ok_groupMsg = redis_api.cmd("private","get", get_groupMsgKey)
	ok_groupMsg = tonumber(ok_groupMsg) or 0 

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
	local tmp_domain = string.match(dfsurl,'http://[%w%.]+:?%d*/')
	if not tmp_domain then return false,'' end 
	local domain = string.match(tmp_domain,'http://([%w%.]+:?%d*)/')

	local parstring = nil
	local parindex = string.find(dfsurl,"%?")
	if parindex then
		parstring = string.sub(dfsurl,parindex + 1 ,#dfsurl)
		parindex = parindex - 1
	else
		parindex = #dfsurl
	end

	local urlpath = string.sub(dfsurl,#tmp_domain,parindex)

	if not urlpath then return false,'' end
	local data_format =  'GET %s HTTP/1.0\r\n' ..
						'HOST:%s\r\n\r\n'

	local req = string.format(data_format,urlpath,domain)

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
			only.log('E',"open file failed! %s", file_full_path)
			return false ,'','' 
		end

		local file_data = f:read("*all")
		f:close()
		return true,filey_tpe, file_data
	end

	local ok,ret = cutils.http(host,port,req,#req)
	if not ok then
		only.log('E','get dfs data  failed when send get request  %s ', dfsurl )
		return false,'','' 
	end

	local split = string.find(ret,'\r\n\r\n')
	if not split then return false , '' end
	local head = string.sub(ret,1,split)
	local file_data = string.sub(ret,split+4,#ret)

	if not app_utils.check_is_amr(file_data,#file_data) then
		-- only.log('E',string.format("data length:%s",#file_data))
		-- only.log('E',string.format("data header:%s",string.sub(file_data,1,20)))
		only.log('E',"voice file format is invalid: %s", dfsurl)
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
							file_data = append_data .. file_data
						elseif par_tab['position'] == "2" then
							file_data = file_data .. append_data
						end
					end
				else
					only.log('E',"daoke file get failed  %s" , par_tab['daokeFilePath'] )
				end
			end
		end
	end

	return true , filey_tpe, file_data
end

------ 保存已经读取的微博
local function save_read_weibo_info(weibo,accountID,args )
	local sql_tab = {
		a1 = 'readGroupTTSWeibo',
		a2 = 'readGroupMultimediaWeibo',
		a3 = 'readPersonalTTSWeibo',
		a4 = 'readPersonalMultimediaWeibo',
		a5 = 'readPersonalTTSWeibo',
		a6 = 'readPersonalMultimediaWeibo',
	}
	local bizid = weibo['bizid']
	local tb_type = string.sub(bizid,1,2)

	local sql_table = string.format("%s_%s",sql_tab[tb_type], G.cur_month )
	local sender_info = weibo['sender_info']

	local sender_accountID , callback_url, sender_fileid = '','',''
	local appKey = 0
	local fileID = ''
	local commentID = ''
	if sender_info then
		sender_accountID = sender_info['senderAccountID'] or ''
		sender_fileid    = sender_info['sourceID'] or ''
		callback_url     = sender_info['callbackURL'] or ''
		appKey           = tonumber(sender_info['appKey']) or 0
		fileID           = sender_info['fileID'] or ''
		commentID        = sender_info['commentID'] or ''
	end

	if #tab_longitude < 1 then
		table.insert(tab_longitude,0)
	end

	if #tab_latitude < 1 then
		table.insert(tab_latitude,0)
	end

	local speed_str = ""
	if weibo['speed'] and type(weibo['speed']) == "table" then
		speed_str = string.format("[%s]",table.concat(weibo['speed'],","))
	end

	local direction_str = ""
	if weibo['direction'] and type(weibo['direction']) == "table" then
		direction_str = string.format("[%s]",table.concat(weibo['direction'],","))
	end

	local sql_str =  string.format("insert into %s set senderAccountID = '%s', sourceID = '%s' , bizid  = '%s'  , releaseTime = %s " .. 
									" , readStatus = 0 , releaseLongitude = %s , releaseLatitude = %s  " ..
									" , level = %s , content = '%s' , callbackURL = '%s' " ..
									" , speed = '%s'  , longitude = %s , latitude = %s  , distance = %s , direction = '%s' , tokenCode = '%s' "  ..
									" , appKey = '%s', fileID = '%s' " ,
									sql_table,sender_accountID,sender_fileid,weibo['bizid'],G.cur_time ,
									(tonumber(tab_longitude[1]) or 0)  * dk_utils.gps_point_unit,
									(tonumber(tab_latitude[1]) or 0)  * dk_utils.gps_point_unit,
									weibo['level'],
									weibo['content'] or '',
									callback_url,
									speed_str,
									(tonumber(weibo['longitude']) or 0)  * dk_utils.gps_point_unit ,
									(tonumber(weibo['latitude']) or 0)  * dk_utils.gps_point_unit ,
									(tonumber(weibo['distance']) or 0) ,
									direction_str,
									args['tokencode'],
									appKey,
									fileID)

	if tb_type == 'a1' or tb_type == 'a2' then
		sql_str = sql_str .. string.format("  , receiverAccountID = '%s' , groupID = '%s', multimediaURL = '%s'   " , 
											G.cur_accountid,
											weibo['groupID'],
											weibo['multimediaFileURL'] or '' )

  	elseif tb_type == 'a3' or tb_type == 'a4' then
  		---- 个人微博
  		sql_str = sql_str .. string.format(" , commentID = '%s' , receiverAccountID = '%s'   " , commentID,  G.cur_accountid )
  		if tb_type == 'a4' then
  			local multimediaFile_url = weibo['multimediaFileURL'] or ''
  			local multimediaFile_type = 'amr'
  			if #multimediaFile_url  > 5 then
  				local tmp_url = string.sub(multimediaFile_url,-5,-1)
  				local find_dot = string.find(tmp_url,'%.')
  				if find_dot then
  					multimediaFile_type = string.sub(tmp_url,find_dot+1,#multimediaFile_url)
  				end
  			end
  			sql_str = sql_str .. string.format(" , multimediaURL = '%s' , fileType = '%s'   " , 
 									multimediaFile_url,
  									multimediaFile_type )
  		end
  	elseif tb_type == 'a5' or tb_type == 'a6' then
  		---- 区域微博
  		sql_str = sql_str .. string.format(" , commentID = '%s' , receiverAccountID = '%s'   " , commentID, G.cur_accountid)
  		if tb_type == 'a6' then
  			local multimediaFile_url = weibo['multimediaFileURL'] or ''
  			local multimediaFile_type = 'amr'
  			if #multimediaFile_url  > 5 then
  				local tmp_url = string.sub(multimediaFile_url,-5,-1)
  				local find_dot = string.find(tmp_url,'%.')
  				if find_dot then
  					multimediaFile_type = string.sub(tmp_url,find_dot+1,#multimediaFile_url)
  				end
  			end
  			sql_str = sql_str .. string.format(" , multimediaURL = '%s' , fileType = '%s'   " , 
 									multimediaFile_url,
  									multimediaFile_type )
  		end
  	end

  	local ok_status,ok_ret = mysql_api.cmd(app_weiboread_db,'INSERT',sql_str)
  	if not ok_status then 
  		only.log('E', 'save read weibo failed!  %s  ', sql_str ) 
  		return false
  	end
  	return true
end


local function get_current_group_msg_type( current_channel_id, cur_accountid )
	---- 判断是否为频道
	local w_type = 3 
	local filter_channel_id = string.match(current_channel_id,"(%d+)")
	if tostring(filter_channel_id) ~= tostring(current_channel_id) then
		---- 当前为车队
		return w_type
	end

	local ok_status,ok_voice_type = redis_api.cmd('private','get',cur_accountid .. ':voiceCommandCustomType')
	---- VOICE_COMMAND_CHANNEL = 2 
	if (tonumber(ok_voice_type) or 0) == 2 then
		---- 加按键设置了频道,需要判断
		---- 优先判断加加按键设置的频道
		local ok,groupvoice_channel_id  = redis_api.cmd('private','get', cur_accountid .. ":currentChannel:groupVoice")
		groupvoice_channel_id = groupvoice_channel_id or "10086"
		if tostring(groupvoice_channel_id) == tostring(current_channel_id) then
			return w_type
		end

		---- 优先判断加加 以及临时频道
		local ok,temp_channel_id = redis_api.cmd('private','get',cur_accountid .. ':tempChannel:groupVoice')
		if ok and temp_channel_id then
			if tostring(temp_channel_id) == tostring(current_channel_id) then
				return w_type
			end
		end

		---- 判断失败,需要设置为加键群组类型2
		w_type = 2 
		return w_type
	end

	---- 加按键设置了频道,加按键未设置了频道,默认为3
	return w_type
end

---- 获取微频道昵称前缀
local function do_get_pre_sender_microchannel_name( groupid )
	if not groupid or #tostring(groupid) < 9 then
		return false,nil
	end

	local ok,url = redis_api.cmd('private','get',groupid .. ':channelNameUrl')
	if ok and url then
		local file_ok,file_type, file_data = get_dfs_data_by_http(url)
		if file_ok and file_data then
			only.log('D',"%s add channelNameUrl is url:%s ", groupid, url )
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
		local ok,url = redis_api.cmd('private','get',account_id .. ':nicknameURL')
		if ok and url then
			local file_ok,file_type, file_data = get_dfs_data_by_http(url)
			if file_ok and file_data then
				only.log('D',"%s add pre nickname is url:%s ", account_id, url )
				return file_ok,file_data
			end
		end
		local ok,tmp_imei = redis_api.cmd('private','get', account_id .. ":IMEI")
		if ok and tmp_imei then
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
			only.log('D',string.format("%s add pre nickname is imei:%s --- ", account_id, imei ))
			local file_data = f:read("*all")
			f:close()
			if app_utils.check_is_amr(file_data,#file_data) then
				return true,file_data
			else
				only.log('E',"get local file failed,  %s.amr-->--invalid amr file!",string.sub(imei,-4))
			end
		end
		only.log('E',"%s get imei suffix:%s --- failed ,file:%s ", account_id, imei , cur_imeifile )
		return false,nil
	end
end

-- 判断用户是否添加前缀 
-- 没有分大类的情况下,则直接判断1,33,x
-- 默认为关闭状态
function check_add_prefix_nickname( accountid , app_type )
	if not app_type or not accountid or #accountid ~= 10 then return true end
	local ok_status,ok_val = redis_api.cmd('private','get', accountid .. ':userMsgSubscribed')
	if not ok_status or not ok_val or #ok_val < app_type then return  true end
	if app_type < 32 then 
		return false 
	end

	if tostring(string.sub(ok_val,1,1)) == "1" 						---- 系统总开关
		and tostring(string.sub(ok_val,33,33)) == "1" 					---- User总开关
		and tostring(string.sub(ok_val,tonumber(app_type),tonumber(app_type))) == "1"  then
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
					only.log('E', 'save gps data failed  %s ', sql_gps )
				end
			else
				only.log('D', "gps is error data!")
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
			dk_utils.set_extragpsinfo(tab_extragpsinfo )
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

local function split_data( str_val )
	return utils.str_split(string.match(str_val,"%[(.+)%]"),",")
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
			-- args = utils.parse_url(req_body)
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
	G.cur_time = os.time()


	local cur_today = string.gsub(ngx.get_today(),"%-","")

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

	local ok, accountid = redis_api.cmd('private', "get", G.imei .. ':accountID')-->accountid maybe nil
	if not ok then
		only.log('E','get imei %s accountid failed!', G.imei )
		go_exit()
	end

	G.cur_accountid = accountid or G.imei

	---- 可能中途掉线
	---- 避免操作redis过于频繁
	--------------------------------------------------
	-------------debug------------
	-- if G.cur_time % 2 == 0 then
		redis_api.cmd('statistic', 'sadd', 'onlineUser:set', G.cur_accountid )
		redis_api.cmd('private', 'set', G.cur_accountid .. ":heartbeatTimestamp", G.cur_time )
	-- end
	
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
		split_data_with_other(args,accountid)
	end

	----  数据转发 
	if tab_GPSTime and #tab_GPSTime > 0 then
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

		dk_utils.post_data_to_other(tab_jo)

	end


	---- 保存已经读取的微博
	if args["bizid"] and #args["bizid"]  > 0 then

		save_read_bizid_to_newstatus_info(accountid, args, args["bizid"])

		save_read_bizid_to_read_info_pre( accountid, args, args["bizid"] )

		-- save_read_bizid_to_read_info_new( accountid, args, args["bizid"] )

	end

	---- 增加静音判断
	---- mt=17936 
	if args['mt'] then
		if (tonumber(args['mt']) or 0 ) < 4095  then
			---- 用户当前是静音状态.不发音频文件 
			only.log('D', " %s volume is 0 , mt:%s ---->----return 555 " , G.cur_accountid , args['mt']  ) 
			go_empty()
		end
	end

	local w_type = 1

	---- 获取微博
	weibo = fetch_weibo_pre( G.cur_accountid , 'weiboPriority')
	if not weibo then
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

		local weibo_tab = {
			weibo_info = weibo,
		}

		weibo_tab['curAccountID'] = accountid or ''

		if #tab_longitude > 0 then
			weibo_tab['curLongitude'] = tab_longitude[1]
		end

		if #tab_latitude > 0 then
			weibo_tab['curLatitude'] = tab_latitude[1]
		end

		weibo_tab['curTokenCode'] = args['tokencode']
		weibo_tab['curTime'] = G.cur_time

		dk_utils.post_data_to_save_weibo(weibo_tab)

		w_type = tonumber(weibo['messageType'])

	else
		
		save_read_weibo_info(weibo,accountid,args)

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

	---- 微频道增加前缀
	if weibo['groupID'] then
		local ok,new_buff = do_get_pre_sender_microchannel_name(weibo['groupID'])
		if ok and new_buff then
			---- 2快音频合并总长度小于最大阀值
			if #dfs_data_binary + #new_buff <= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
				dfs_data_binary = new_buff .. dfs_data_binary
			end
		end

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

	---- 添加发送着的前缀
	---- 164为添加前缀 
	---- 内部过滤 kxl1QuHKCD,OwQH5wZflD
	if weibo['sender_info'] and check_add_prefix_nickname(G.cur_accountid, 164 ) then
		local sender_info = weibo['sender_info']
		local sender_id = sender_info['senderAccountID']
		---- 只有feedback终端上来的音频文件才增加前缀
		if sender_id and #tostring(sender_id) >= 10 and sender_info['appKey'] and sender_info['appKey'] == dk_utils.FEEDBACKAPI_APPKEY then
			local ok,new_buff = do_get_pre_sender_nickname(sender_id)
			if ok and new_buff then
				---- 2快音频合并总长度小于最大阀值
				if #dfs_data_binary + #new_buff <= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
					dfs_data_binary = new_buff .. dfs_data_binary
				end
			end
		end
	end

	---- 二进制文件小于300字节, 大于20K,不下发给终端 
	if #dfs_data_binary < dk_utils.FILE_MIN_SIZE or #dfs_data_binary >= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
		only.log('W', " the result %s get dfsurl %s data failed---->----return 555 file length:%s" , G.cur_accountid , dfsurl ,#dfs_data_binary ) 
		go_empty()
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

	if (tonumber(weibo['distance']) or 0 ) >  0  then
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
	local ok,shutup = redis_api.cmd('private','get',string.format("%s:shutup",G.cur_accountid))
	if ok and shutup and (tonumber(shutup) or 0 ) == 1  then
		result_tab['shutup'] = "1"
	else
		result_tab['shutup'] = "0"
	end

	if weibo['tipType'] then
		result_tab['tipType'] = weibo['tipType']
	else
		result_tab['tipType'] = "0"
	end

	if weibo['autoReply'] then
		result_tab['autoReply'] = weibo['autoReply']
	end
	if weibo['intervalDis'] then
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
	-- redis_api.cmd('dataCore_redis','sadd',string.format("%s:%s:reallySendUserList", weibo['bizid'], G.cur_month ) , G.cur_accountid )
	-- redis_api.cmd('dataCore_redis','expire',string.format("%s:%s:reallySendUserList", weibo['bizid'], G.cur_month ) , dk_utils.DATACORE_EXPIRE_MAXTIME )

	-- only.log('D', " %s really send weibo %s END NEWSTATUS |---> %s", G.cur_accountid ,  bizid , head_result) 

	ngx.header['RESULT'] = head_result
	save_urllog(head_result)
	gosay.respond_to_binary(url_tab, dfs_data_binary)
	
end

handle()
