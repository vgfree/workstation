local only      = require ('only')
local redis_api = require('redis_pool_api')
local app_utils = require('app_utils')
local cjson     = require('cjson')
local link      = require('link')

local ngx        = require('ngx')
local utils     = require('utils')
local cutils    = require('cutils')
local http_api  = require('http_short_api')


---- 2014-12-31  LRU cache
local lrucache  = require('lrucache')

---- private redis只读
local read_private = "read_private"


---- LRU缓存配置数据
LRU_CACHE_INFO = { is_init = false , base_address = 0 }

module("dk_utils", package.seeall)

verify_mod_list = {
    SG900 = true,
    MG900 = true,  --2014-06-20 jiang z.s.
    TLM01 = true,  --2014-06-20 jiang z.s. 
}

----------------------------------------------------------------------

--FILE 小于300字节,过滤掉
FILE_MIN_SIZE = 300 

---- daokeIO2.0 type操作类型
DK_TYPE_CALL1       = 1
DK_TYPE_CALL2       = 2
DK_TYPE_VOICE       = 3
DK_TYPE_COMMAND     = 4 
DK_TYPE_GROUP       = 5
DK_TYPE_YES         = 6
DK_TYPE_NO          = 7
DK_TYPE_POWEROFF    = 8
DK_TYPE_PASSBY      = 9
DK_TYPE_REPLYVOICE  = 10

---- 2015-01-12 ---- begin ----
DK_TYPE_NOT_COMMAND = 11 ---- 语音命令未设置
DK_TYPE_NOT_GROUP   = 12  ---- 群组微博未设置
---- 2015-01-12 ---- end ----

DK_TYPE_TACKVOICE   = 15        ---- MG900   pic对应的amr
DK_TYPE_PHOTO       = 35         ---- MG900   上传图片JPG
----------------------------------------------------------------------

---- 音频文件默认参数 Channel Rate
DEFAULT_FILE_CHANNEL = 1
DEFAULE_FILE_BIT    = 8

---- 正常音频文件最大时常为15秒
MAX_NORMAL_FILE_DURACION = 15

---- 回复音频文件最大时常为8秒
MAX_REPLY_FILE_DURACION  = 8

---- 2014-12-05 -----------
---- 上传音频文件最大长度 20kb
MAX_FEEDBACK_FILE_LENGTH  = 20140

---- 下发音频文件最大长度 50kb
MAX_NEWSTATUS_FILE_LENGTH  = 51200

---- 2014-12-05 -----------


---- 图片文件最大100kb 2014-11-05
MAX_PHOTO_LENGTH         = 102400

---- bizid的最大长度
BIZID_LENGTH             = 34

gps_point_unit           = 10000000

----TokenCode有效期时间为48小时
TOKENCODE_EXPIRE = 48*60*60

----config一天最大访问50次 2015-06-02
MAX_CONFIG_INDEX = 50

----访问次数最大有效时间,默认为24小时,过期自动删除
CONFIGINDEX_EXPIRE = 24*60*60

----每隔48小时强制刷新缓存里的token
REFRESH_TOKEN_CODE = 48*60*60


----gps other 最大长度
MAX_OTHER_LEN = 8192


----dataCore 统计变量的最大过期时间, 72 个小时 2015-05-04
DATACORE_EXPIRE_MAXTIME = 259200 


---- 终端 IMEI 类型标志 ------------------------------
DK_IMEI_MANUFACTURE = 1    ----- IMEI 生产终端
DK_IMEI_ENGINEERING = 2    ----- IMEI 工程终端(测试硬件终端)
---- 终端 IMEI 类型标志 ------------------------------

--------------------------------------------------
----- 当前代码所属类型 ---------------------------
----- 1正式环境  2工程环境
DK_CODE_EVN_MANUFACTURE = 1   ---- feedback ,newStatus
--------------------------------------------------

---------------------------------------------------
-------------文件类型-----------------------------
---------- 1  amr文件 ---------------------------
---------- 2  jpg文件 ---------------------------
DK_FILE_TYPE_AMR = 1 
DK_FILE_TYPE_JPG = 2 
---------------------------------------------------


FEEDBACK_APPKEY = '2290837278'
FEEDBACK_SECRET = 'CEC10F39CF75BCFABF8B0D236936AF4BD6084E8E'

FEEDBACKAPI_APPKEY = "257131325"
FEEDBACKAPI_SECRET = "B0BBAEF41E81F8B6A9D7333C5E430F4E4A9A21A1"


------------------------------------------------
---- 0  不写数据库
---- 1  写数据库
---- gps是否写mysql
DK_WRITE_MYSQL_WITH_GPS = 0

---- 日志是否写urllog
DK_WRITE_MYSQL_WITH_URL = 0
-------------------------------------------------


--------========LRU Cache ======================
VALUE_UPDATE_MAX_TIMEOUT = 300
SHUTUP_UPDATE_MAX_TIMEOUT = 600
CHANNEL_UPDATE_MAX_TIMEOUT = 600
--------========LRU Cache ======================


--------转发数据给大坝,的失败时间戳
DAM_FAILED_TIME = 0 
DAM_RETRY_MAX_TIME = 120

local poweron_table = {
        driview          = {4} ,
}

local GPS_table = {
    driview                = {4},
}

local function table_resvert( tab )
    local tmp_tab = {}
    for i = #tab , 1 , -1 do
        table.insert(tmp_tab,tab[i])
    end
    return tmp_tab
end

local function check_gps_data_is_sort( tab_jo )
    if tab_jo['GPSTime'] and #tab_jo['GPSTime'] > 2  then
        if tab_jo['GPSTime'][1] > tab_jo['GPSTime'][2] then
            return 
        else
            tab_jo['GPSTime']   = table_resvert(tab_jo['GPSTime'])
            tab_jo['longitude'] = table_resvert(tab_jo['longitude'])
            tab_jo['latitude']  = table_resvert(tab_jo['latitude'])
            tab_jo['direction'] = table_resvert(tab_jo['direction'])
            tab_jo['speed']     = table_resvert(tab_jo['speed'])
            tab_jo['altitude']  = table_resvert(tab_jo['altitude'])
            if tab_jo['extragps'] and tab_jo['extragps']["GPSTime"] and #tab_jo['extragps']["GPSTime"] > 2  then
                    tab_jo['extragps']["GPSTime"]   = table_resvert(tab_jo['extragps']["GPSTime"])
                    tab_jo['extragps']["longitude"] = table_resvert(tab_jo['extragps']["longitude"])
                    tab_jo['extragps']["latitude"]  = table_resvert(tab_jo['extragps']["latitude"])
                    tab_jo['extragps']["direction"] = table_resvert(tab_jo['extragps']["direction"])
                    tab_jo['extragps']["speed"]     = table_resvert(tab_jo['extragps']["speed"])
                    tab_jo['extragps']["altitude"]  = table_resvert(tab_jo['extragps']["altitude"])
            end
        end
    end
end

--[[
        @Description    过滤相同GPS包 未考虑 连续长时间发送含有错误时间的包后又发送了正确的包
        @Date           2015-12-18
        @Author         shu

        @param GPS时间
        @return 是否重复
--]]

local function filter_same_package(tab_jo, token_code)

        local expire_time = 1200 -- redis key 超时 保证信号不好长时间未发送GPS包后能重新设置key
        local limit_time = 600 -- 容错时间
        local current_time = os.time() -- 系统时间
        local filter_redis = "statistic" -- 存放最新 ${token_code}:${GMT_new}
	local timestamp_key = token_code .. ":newGPStimestamp"


	local ok, GMT_old = redis_api.cmd(filter_redis, 'get', timestamp_key)
	if not ok then
		-- 命令失败不设置key，redis挂掉包过滤将失效，偶尔出错不影响
		only.log('E', " get timestamp_key %s: failed ", token_code)
		GMT_old = nil
	end
	GMT_old = tonumber(GMT_old)
	for i = #tab_jo['GPSTime'], 1, -1 do
		local flag = false
		local GMT_new = tonumber(tab_jo['GPSTime'][i])
		local temp = math.abs(GMT_new - current_time)
		if temp >= limit_time then
			flag = true
			only.log('W', " filter upload_time %s now_time %s ", tostring(GMT_new), tostring(current_time))
		else
			flag = false

			-- 若GMT_new > GMT_old && limit_time > temp 设置标志位并更新GMT_old
			if GMT_old then
				if GMT_new > GMT_old then
					flag = false
				else
					flag = true
				end
			end
		end
		if flag then
			table.remove(tab_jo['GPSTime']   , i)
			table.remove(tab_jo['longitude'] , i)
			table.remove(tab_jo['latitude']  , i)
			table.remove(tab_jo['direction'] , i)
			table.remove(tab_jo['speed']     , i)
			table.remove(tab_jo['altitude']  , i)
		else
			break
		end
	end
	if tab_jo['GPSTime'] and #tab_jo['GPSTime'] > 0 then
		-- 当前未缓存tokencode 设置${token_code}:${GMT_new}
		redis_api.cmd(filter_redis, 'setex', timestamp_key, expire_time, tab_jo['GPSTime'][1])
	end
end

---- link 
---- 0/6/7 driview
---- 8 java server 
---- 9 checkequipment
----10 releaseServer
function post_data_to_other(tab_jo, args)

    check_gps_data_is_sort(tab_jo)
    filter_same_package(tab_jo, args['tokencode'])

    local ok, result = pcall(cjson.encode, tab_jo)
    if ok then
        ---- driview 
        local host_info = { host = "127.0.0.1" ,port = "80" }
        ---- MDDS|roadRank 
        ---- 2015-01-12 
		--driview 扩容，根据IMEI经行HASH

        if not DAM_FAILED_TIME or (ngx.time() - tonumber(DAM_FAILED_TIME) or 0) > DAM_RETRY_MAX_TIME then
            local request = utils.compose_http_json_request2( host_info ,'publicentry',nil, result)
            local dams_key = ""

            for key,value in pairs(GPS_table) do
                local index = cutils.custom_hash(tab_jo['IMEI'] or '',#value,1)
                dams_key = dams_key .. value[index].."|"
            end

            dams_key = string.sub(dams_key,1,-2)
            ----only.log('W',"***dams_key:%s*****",dams_key)
            
            local ok, ret = redis_api.cmd("damServer","lpushx",dams_key,request)

            -- local index = cutils.custom_hash(tab_jo['IMEI'] or '',#cfg_driview,1)
            -- local ok, ret = redis_api.cmd("damServer","lpushx",string.format("1|2|3|4|5|%d|8|9|10",cfg_driview[index]),request)
            if not ok then
                DAM_FAILED_TIME = ngx.time()
            end
        end
    end
end


---- 通过大坝转发开机信号
function post_data_to_power_info(hash_key ,  body_data  )
    ---- driview 
    local host_info = { host = "127.0.0.1" ,port = "80" }
    if not DAM_FAILED_TIME or (ngx.time() - tonumber(DAM_FAILED_TIME) or 0) > DAM_RETRY_MAX_TIME then
        local request = utils.compose_http_json_request2( host_info ,'publicentry',nil, body_data)
        local dams_key = ""
         for key,value in pairs(poweron_table) do
                 local index = cutils.custom_hash(hash_key or '',#value,1)
                 dams_key = dams_key ..value[index].."|"
         end
         dams_key = string.sub(dams_key,1,-2)
         ----only.log('W',"***=======dams_key:%s*****",dams_key)

         local ok, ret = redis_api.cmd("damServer","lpushx",dams_key,request)

        -- local index = cutils.custom_hash(hash_key or '',#cfg_driview,1)
        -- local ok, ret = redis_api.cmd("damServer","lpushx",string.format("%d|8",cfg_driview[index]),request)
        if not ok then
            DAM_FAILED_TIME = ngx.time()
        end
    end
end



function post_data_to_save_weibo( info )

    local ok, result = pcall(cjson.encode, info)
    if ok then
        local host_info = link['OWN_DIED']['http']['saveWeiboServer']
        local request = utils.compose_http_json_request( host_info ,'weidb_issued', nil , result)

        only.log('D',request)

        local data = http_api.http_ex(host_info, request, false,'weidb_issued_send',60)
    end
end


function post_data_to_read_weibo( info )

    local ok, result = pcall(cjson.encode, info)
    if ok then
        local host_info = link['OWN_DIED']['http']['readWeiboServer']
        local request = utils.compose_http_json_request( host_info ,'weidb_update', nil , result)

        only.log('D',request)

        local data = http_api.http_ex(host_info, request, false,'weidb_issued_read',60)
    end

end


----- 经纬度转换
function convert_gps(lon, lat)
    if not lon or not lat then
        only.log('E'," convert_gps error %s  %s " , lon, lat  )
        return nil,nil
    end
    local o_lon = string.format("%.7f",math.floor(lon/100) + lon%100/60)
    local o_lat = string.format("%.7f",math.floor(lat/100) + lat%100/60)
    return tonumber(o_lon), tonumber(o_lat)
end


---- bizid的标识
---- * 1,3,5,7代表集团，个人，区域，分享的TTS微博
---- * 2,4,6,8代表集团，个人，区域，分享的语音微博


---- tab转表单形式
function keys_binary_to_req(host_ip, host_port , url_path, args, file_name, file_binary)

    local head_boundary = string.format("----WebKitFormBoundaryDcO1SS%dMTDfpuu%skkU",ngx.time(),  ngx.time() )

    local head_format =   'POST /%s HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Length:%d\r\n' ..
    'Content-Type: multipart/form-data; boundary=' .. head_boundary .. '\r\n\r\n%s'

    local body_boundary = '--' .. head_boundary
    local body_suffix   = body_boundary .. '--'
    local body_prefix   = '%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n'

    local body_tab = {}
    for i , v in pairs(args) do
        table.insert(body_tab,string.format(body_prefix,body_boundary,i,v))
    end

    local body_data = table.concat(body_tab,"")
    if file_name and file_binary then
        body_data = body_data .. string.format('%s\r\nContent-Disposition: form-data; name="mmfilename"; filename="%s"\r\n' ..
        'Content-Type: application/octet-stream\r\n\r\n%s\r\n',
        body_boundary, file_name , file_binary)
    end
    body_data =  body_data .. body_suffix
    local req_data = string.format(head_format, url_path, host_ip, tostring(host_port), #body_data, body_data)
    return req_data
end

-->> write urlLog to Redis.
function set_urlLog(imei, url, clientip, return_value, cur_time)
    -->> check imei
    if not imei or #imei ~= 15 then
        if type(imei) == "string" then
            only.log('E',"set_urlLog: [URLLOG] imei is error. imei: %s ",  imei) 
        elseif type(imei) == "table" then
            ---- 2015-02-04
            only.log('E',"[set_data_error]set_urlLog: [URLLOG] imei is error. table imei: %s ",  table.concat( imei, "|") )
        end
        return false
    end

    if url and (string.find(url,"#!AMR")) then
        only.log('E',"set_urlLog: [URLLOG] imei %s  url exist binary", imei )
        return false
    end

    -->> get time.
    local timestamp = cur_time
    local timeinterval = string.format("%s%d", os.date("%Y%m%d%H", timestamp), os.date("%M", timestamp)/10)

    -->> key format: URL:${imei}:${timeinterval}, like this: URL:956317345830618:201405121.
    local key = string.format("URL:%s:%s", imei, timeinterval)

    -->> field format: ${timestamp}.
    -- local field = timestamp

    -->> value format: ${timestamp}|${url}|${clientip}|${return_value}.
    local value = string.format("%s|%s|%s|%s", timestamp, url or "", clientip or "", return_value or "")

    -->> set redis.
    local ok, ret = redis_api.hash_cmd("url_hash",imei,"sadd",key,value)
    if not ok then
        only.log('E', "set_urlLog: [URLLOG] sadd tsdb_redis error. key: %s, value: %s", key, value)
        return false
    end

    -->> active user key format: ACTIVEUSER:${timeinterval}.
    local akey = string.format("ACTIVEUSER:%s", timeinterval)

    -->> set redis.
    ok, ret = redis_api.hash_cmd("url_hash",imei,"sadd",akey,imei)
    if not ok then
        only.log('E', "set_urlLog: [URLLOG] sadd tsdb_redis error. key: %s, value: %s", akey, imei)
        return false
    end

    return true
end

-->> set gpsinfo.
-->> input   1. gps_tab(table)
-->> output: 1. if succeed return true, else return false.
function set_gpsinfo(gps_tab,cur_time)
    local imei = gps_tab["imei"]
    -->> check tab.
    if not gps_tab then
        only.log('I', "[redis] set_gpsinfo: [GPS] is nil.")
        return true
    end

    -->> check gps count.
    if not gps_tab['count'] or tonumber(gps_tab['count']) == 0 then
        -- only.log('I', "[redis] set_gpsinfo: [GPS] gpsinfo count is 0.")
        return false
    end

    -->> check imei.
    if not gps_tab or not imei or #imei ~= 15 then
        only.log('E', "[redis] set_gpsinfo: [GPS] imei is error. imei: %s  " , (gps_tab['imei'] or ""))
        return false
    end

    -->> check collect_time.
    local timestamp = tonumber(gps_tab['collectStart'])
    if not timestamp or string.len(timestamp) ~= 10 then 
        only.log('I', "[redis] set_gpsinfo: collect_time format error. %s", gps_tab['collectStart'])
        return false
    end


    -->> get time.
    --local timestamp = os.time()
    local timeinterval = string.format("%s%d", os.date("%Y%m%d%H", timestamp), os.date("%M", timestamp)/10)

    -->> set active user.
    local key = string.format("ACTIVEUSER:%s", timeinterval)
    local value = gps_tab['imei']
    local ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,value)
    if not ok then
        only.log('E', "set_gpsinfo: [GPS] sadd tsdb_redis error. key: %s, value: %s", key, value)
        return false
    end

    -- -->> compact GPS info.
    -- local val_tab = {}
    key = string.format("GPS:%s:%s", imei, timeinterval)
    -->> set redis.
    ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,unpack(gps_tab['list']))
    if not ok then
        only.log('E', "set_gpsinfo: [GPS] sadd tsdb_redis error. key: %s", key)
        return false
    end

    return true
end

-->> set gsensorinfo.
-->> input   1. gs_tab (table): gsensor table.
-->> output: 1. if succeed return true, else return false.
function set_gsensorinfo(gs_tab,cur_time)
    local imei = gs_tab["imei"]
    -->> check tab.
    if not gs_tab then
        only.log('I', "[redis] set_gsensorinfo: [GSENSOR] is nil")
        return true
    end

    -->> check gsensor count.
    if not gs_tab['count'] or tonumber(gs_tab['count']) == 0 then
        -- only.log('I', "[redis] set_gsensorinfo: [GSENSOR] gsensorinfo count is 0.")
        return false
    end

    -->> check imei.
    if not gs_tab or not imei or #imei ~= 15 then
        only.log('E', "[redis] set_gsensorinfo: [GSENSOR] imei is error. imei: %s  ", (gs_tab['imei'] or ""))
        return false
    end

    -->> check collect_time.
    local timestamp = tonumber(gs_tab['collectStart'])
    if not timestamp or string.len(timestamp) ~= 10 then 
        only.log('I', "[redis] set_gsensorinfo: collect_time format error. %s", gs_tab['collectStart'])
        return false
    end

    -->> get time.
    --local timestamp = os.time()
    local timeinterval = string.format("%s%d", os.date("%Y%m%d%H", timestamp), os.date("%M", timestamp)/10)

    -->> set active user.
    local key = string.format("ACTIVEUSER:%s", timeinterval)
    local value = gs_tab['imei']
    local ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,value)
    if not ok then
        only.log('E', "[redis] set_gsensorinfo: [GSENSOR] sadd tsdb_redis error. key: %s, value: %s", key, value)
        return false
    end

    -->> compact accinfo.
    -- local val_tab = {}
    key = string.format("GSENSOR:%s:%s", imei, timeinterval)
    
    -->> set redis.
    ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,unpack(gs_tab['list']))
    if not ok then
        only.log('E', "set_gsensorinfo: [GSENSOR] sadd tsdb_redis error. key: %s", key)
        return false
    end
    return true
end


-->> set gsensorinfo.
-->> input   1. gps_tab (table): gsensor table.
-->> output: 1. if succeed return true, else return false.
function set_extragpsinfo(gps_tab )
    local imei = gps_tab["imei"]
    -->> check tab.
    if not gps_tab then
        only.log('I', "[redis] set_extragpsinfo: [GPS] is nil.")
        return true
    end

    -->> check gps count.
    if not gps_tab['count'] or tonumber(gps_tab['count']) == 0 then
        -- only.log('I', "[redis] set_extragpsinfo: [GPS] gpsinfo count is 0.")
        return false
    end

    -->> check imei.
    if not gps_tab or not imei or #imei ~= 15 then
        only.log('E', "[redis] set_extragpsinfo: [GPS] imei is error. imei: %s " , gps_tab['imei'] )
        return false
    end

    -->> check collect_time.
    local timestamp = tonumber(gps_tab['collectStart'])
    if not timestamp or string.len(timestamp) ~= 10 then 
        only.log('I', "[redis] set_extragpsinfo: collect_time format error. %s", gps_tab['collectStart'])
        return false
    end

    -->> get time.
    --local timestamp = os.time()
    local timeinterval = string.format("%s%d", os.date("%Y%m%d%H", timestamp), os.date("%M", timestamp)/10)

    -->> set active user.
    local key = string.format("RACTIVEUSER:%s", timeinterval)
    local value = gps_tab['imei']
    local ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,value)
    if not ok then
        only.log('E', "set_extragpsinfo: [GPS] sadd tsdb_redis error. key: %s, value: %s", key, value)
        return false
    end

    -- -->> compact GPS info.
    -- local val_tab = {}
    key = string.format("RGPS:%s:%s", imei, timeinterval)
    -->> set redis.
    ok, ret = redis_api.hash_cmd("tsdb_hash",imei,"sadd",key,unpack(gps_tab['list']))
    if not ok then
        only.log('E', "set_extragpsinfo: [GPS] sadd tsdb_redis error. key: %s", key)
        return false
    end

    return true
end


----=============================2014-12-31================================----
----====================以下是transit使用cache代码块====================----
function lru_cache_init()
    -- cache 初始化
    local MAX_CACHE_SIZE = 40000
    local MAX_VALUE_SIZE = -1
    local base_address , err = lrucache.init(MAX_CACHE_SIZE,MAX_VALUE_SIZE)
    if not base_address then
        only.log('E',"[****]lrucache init failed! %s", err)
        return nil
    end
    LRU_CACHE_INFO.is_init = true
    LRU_CACHE_INFO.base_address = base_address

    only.log('W'," lru_cache_init succeed,base_address is %s ", base_address )

end


function lru_cache_set_value( key, val )
    if not LRU_CACHE_INFO.is_init then
        lru_cache_init()
        only.log('E',"[****]set value--lrucache not init, key: %s, val: %s", key, val)
    end

    local ok, err = lrucache.setValue(LRU_CACHE_INFO.base_address, key, val, #val)
    if not ok then
        only.log('E',"[****]set value--failed [%s], key:%s, val:%s ", err , key, val )
        return nil
    end

    only.log('D',"[SUCCED]set value-- key:%s, val:%s ", key, val )
    return true
end

function lru_cache_get_value(key)
    if not LRU_CACHE_INFO.is_init then
        lru_cache_init()
        only.log('E',"[****]get value--lrucache not init")
        return nil,nil
    end

    local ok, val = lrucache.getValue(LRU_CACHE_INFO.base_address, key)

    --only.log('W',"[****]get value- key:%s  ok:%s, val:%s ", key, ok, val )

    if not ok then
        --only.log('E',"[____]get value--failed key:%s ",key )
        return nil,nil
    end
    return true,val
end


function get_tmptime( tmp_key )
    local ok, ret = lru_cache_get_value( tmp_key )
    if not ok or not ret then
        return 0
    end

    if ok and ret then
        return tonumber(ret) or 0
    end
    return 0
end
--[[
function lru_cache_refresh_token(imei)
    local pre_timekey = string.format("%s:configTimestamp", imei )
    local tmp_key1 = string.format("%s:tokenCode", imei )
    local tmp_key2 = string.format("%s:poweronTime", imei )

    local read, value = redis_api.cmd(read_private,'mget', tmp_key1 ,tmp_key2)

    only.log("D","mget reids value: %s %s >> %s  %s",tmp_key1, tmp_key2, value[1],value[2])
    if read and value and #value == 2 then
        if value[1] then
            lru_cache_set_value( tmp_key1 , value[1] )
            lru_cache_set_value( pre_timekey , tostring(value[2]) )
            return value[1]
        else
            lru_cache_set_value( tmp_key1 , "" )
            lru_cache_set_value( pre_timekey , tostring(value[2]) )
        end
    end
    return nil
end
]]--
---- 根据imei获取tokenCode
---- 不需要考虑过期
--[[
function lru_cache_get_token( imei )

    local pre_timekey = string.format("%s:configTimestamp", imei )
    local pre_timeval = get_tmptime(pre_timekey)

    if pre_timeval == 0 or ngx.time() - pre_timeval >= REFRESH_TOKEN_CODE then
        local ret  = lru_cache_refresh_token(imei)
        return ret

    else
        local tmp_key = string.format("%s:tokenCode", imei )
        local ok, ret = lru_cache_get_value( tmp_key )
        only.log("D","lru value:>>%s",ret)
        if ok and ret and #ret > 1 then
            return ret
        end
    end

    return nil
end
]]--

function lru_cache_set_token( imei , tokencode )

    local tmp_key = string.format("%s:tokenCode", imei )

    redis_api.cmd('private', 'SETEX',tmp_key, TOKENCODE_EXPIRE, tokencode )

    lru_cache_set_value( tmp_key , tokencode )

    local pre_timekey = string.format("%s:configTimestamp", imei )
    lru_cache_set_value( pre_timekey , tostring(ngx.time() ) )
end


function lru_cache_get_shutup( imei, must_update )
     local pre_timekey = string.format("%s:deviceTimestamp", imei )
    local pre_timeval = get_tmptime(pre_timekey)
    local tmp_key = string.format("%s:shutup", imei )
    if must_update or ( ngx.time() - pre_timeval > SHUTUP_UPDATE_MAX_TIMEOUT ) then
        local read,value = redis_api.cmd(read_private,'get', tmp_key )
        if read and value then
            lru_cache_set_value( tmp_key , value )
            return value
        end
    else
        ---- read data from cache
        local ok, ret = lru_cache_get_value( tmp_key )
        if ok and ret then
            return ret
        end
    end
end

function lru_cache_get_accountid( imei, must_update )

    local pre_timekey = string.format("%s:deviceTimestamp", imei )
    local pre_timeval = get_tmptime(pre_timekey)
    local tmp_key = string.format("%s:accountID", imei )
    if must_update or pre_timeval < 1 or ( ngx.time() - pre_timeval > VALUE_UPDATE_MAX_TIMEOUT ) then

        ---- read data from_redis and set cache
        local read,value = redis_api.cmd(read_private,'get', tmp_key )
        if read and value then
            lru_cache_set_value( tmp_key , value )
            lru_cache_set_value( pre_timekey , tostring(ngx.time() ) )
            return value
        end

        ---- IMEI只取未绑定accountID的shutup
        lru_cache_get_shutup(imei,true)

        lru_cache_set_value( pre_timekey , tostring(ngx.time() ) )
        return nil
    else
        ---- read data from cache
        local ok, ret = lru_cache_get_value( tmp_key )
        if ok and ret then
            return ret
        end
    end
    return nil
end

function update_user_online( accountid )
    redis_api.cmd('statistic', 'sadd', 'onlineUser:set', accountid )
    redis_api.cmd('private', 'set', accountid .. ":heartbeatTimestamp", ngx.time() )
end

function lru_cache_update_online( accountid )
    update_user_online(accountid)
end

function lru_cache_update_userinfo( accountid, key )
    ---- shutup
    ---- nicknameURL
    ---- IMEI 
    ---- userMsgSubscribed
    ---- voiceCommandChannelID
    ---- groupVoiceChannelID

    --only.log('W',"[lru_cache_update_userinfo] accountid: %s key: %s  " , accountid, key  )

    local tmp_tab = {}
	local ok, ret = redis_api.cmd(read_private,'mget', accountid..":shutup",
                                                            accountid..":nicknameURL", 
                                                            accountid..":IMEI",
                                                            accountid..":userMsgSubscribed",
                                                            accountid..":currentChannel:voiceCommand",
                                                            accountid..":currentChannel:groupVoice")
	if ok and ret then
		
		--only.log('W',"mget table:%s",table.concat(ret,','))
		--accountid:shutup
		if ret[1] then
			tmp_tab[ accountid .. ":shutup" ] = ret[1]
			lru_cache_set_value( accountid .. ":shutup" , ret[1] )
		else
			tmp_tab[ accountid .. ":shutup" ] = "0"
			lru_cache_set_value( accountid .. ":shutup" , "0" )
		end
		--accountid:nicknameURL
		if ret[2] then
			tmp_tab[ accountid .. ":nicknameURL" ] = ret[2]
			lru_cache_set_value( accountid .. ":nicknameURL" , ret[2] )
		end
		--accountid:IMEI
		if ret[3] then
			tmp_tab[ accountid .. ":IMEI" ] = ret[3]
			lru_cache_set_value( accountid .. ":IMEI" , ret[3] )
		end
		--accountid:userMsgSubscribed
		if ret[4] and #tostring(ret[4]) == 512 then
			local tmp_msg_subscribed = "0"
			local msg_index = 164
			if tostring(string.sub(ret[4],1,1)) == "1"                      ---- 系统总开关
			and tostring(string.sub(ret[4],msg_index,msg_index)) == "1"  then
				tmp_msg_subscribed = "1"
			end
			tmp_tab[ accountid .. ":userMsgSubscribed" ] = tmp_msg_subscribed
			lru_cache_set_value( accountid .. ":userMsgSubscribed" , tmp_msg_subscribed )
		else
			tmp_tab[ accountid .. ":userMsgSubscribed" ] = ""
			lru_cache_set_value( accountid .. ":userMsgSubscribed" , "" )
		end

		--accountid:currentChannel:voiceCommand
        ---- fixed 2015-07-09 修复按键缓存
		if ret[5] and #tostring(ret[5]) >= 9  then
			tmp_tab[ accountid .. ":voiceCommandChannelID" ] = ret[5]
			lru_cache_set_value( accountid .. ":voiceCommandChannelID" , ret[5] )
		end
		--accountid:currentChannel:groupVoice
		if ret[6] then
			tmp_tab[ accountid .. ":groupVoiceChannelID" ] = ret[6]
			lru_cache_set_value( accountid .. ":groupVoiceChannelID" , ret[6] )
		end
    end

    update_user_online(accountid)

    local pre_timekey = string.format("%s:updateTimestamp", accountid )
    lru_cache_set_value(pre_timekey,tostring(ngx.time()))
    return tmp_tab[tostring( accountid .. ":" .. key )]
end

function lru_cache_get_userinfo( accountid, key )

    if #tostring(accountid) ~= 10 then
        ---- IMEI cache
        local ok, ret = lru_cache_get_value( string.format("%s:%s", accountid, key ) )
        if ok and ret then
            return ret
        end
        return nil
    end

    local pre_timekey = string.format("%s:updateTimestamp", accountid )
    local pre_timeval = get_tmptime(pre_timekey)
    local tmp_key = string.format("%s:%s", accountid, key )
    if ngx.time() - pre_timeval > VALUE_UPDATE_MAX_TIMEOUT then
        return lru_cache_update_userinfo(accountid, key )
    else
        local ok, val = lru_cache_get_value( tmp_key )
        if ok then
            return val
        end
    end
    return nil 
end

---- 2015-06-18 初始化redis数据
function lru_cache_update_channel_info( groupid )
    ---- 通过redis获取channel info 设置
    local ok, tab = redis_api.cmd(read_private,'mget', groupid .. ":channelType" , groupid .. ":channelNameUrl")
    if ok and tab then
        local tab_info = {}
        local channel_type_val = (tostring(tab[1]) or '2' ) 
        local channel_nameurl_val = tab[2] or ''
        lru_cache_set_value( groupid .. ":channelType" , channel_type_val )
        lru_cache_set_value( groupid .. ":channelNameUrl" , channel_nameurl_val )
        
        tab_info[ groupid .. ":channelType" ] = channel_type_val
        tab_info[ groupid .. ":channelNameUrl" ] = channel_nameurl_val

        local pre_timekey = string.format("%s:channelUpdateTimestamp", groupid )
        lru_cache_set_value(pre_timekey,tostring(ngx.time()))
        return tab_info
    end
    return nil
end

---- 获取数据,有限读取cache, cache过期则重新初始化
function lru_cache_get_channel_info( groupid , key  )
    ---- key 
    ---- 1) channelType
    ---- 2) channelNameUrl

    local pre_timekey = string.format("%s:channelUpdateTimestamp", groupid )
    local pre_timeval = get_tmptime(pre_timekey)

    local tmp_key = groupid .. ":" .. key 
    if ngx.time() - pre_timeval > CHANNEL_UPDATE_MAX_TIMEOUT then
        ----通过redis重新获取
        local tab_info = lru_cache_update_channel_info(groupid)
        if tab_info then
            return tab_info[ tmp_key  ]
        end
    else
        ----直接通过cache获取,
        local ok, val = lru_cache_get_value( tmp_key )
        if ok then
            return val
        end
    end
end



function check_user_black_in_secret_channel(accountid,channel_id)
    -- 判断用户当前所在频道的状态
    -- 1 正常 / 2 禁言 / 3 拉黑 / 4 未审核通过
    -- 针对 3 / 4 的情况,不允许把用户加入在线用户列表
    local ok, ret = redis_api.cmd(read_private,'hget', channel_id .. ":userStatusTab", accountid .. ":status")
    if tonumber(ret) == 3 or tonumber(ret) == 4 then
        return true
    end
    return false
end


