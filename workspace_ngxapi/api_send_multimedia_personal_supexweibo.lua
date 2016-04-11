--
-- author: zhangjl
-- date: 2014 04 12 Tue 13:54:20 CST

local ngx = require 'ngx'
local only = require 'only'
local gosay = require 'gosay'
local utils = require 'utils'
local app_utils = require 'app_utils'
local msg = require 'msg'
local safe = require('safe')
local link = require 'link'
local http_short_api = require 'http_short_api'
local cutils    = require('cutils')
local cjson = require('cjson')

local weibo_fun = require 'weibo_fun'

local mysql_pool_api = require 'mysql_pool_api'
local redis_pool_api = require 'redis_pool_api'

local url_info = {
	type_name = 'system',
	app_key = nil,
	client_host = nil,
	client_body = nil,
}

local function check_parameters(tab)

	url_info['app_key'] = tab['appKey']

	if not app_utils.check_accountID(tab['receiverAccountID']) and not app_utils.check_imei(tab['receiverAccountID']) then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiverAccountID")
	end

	-->> check interval
	tab['interval'] = tonumber(tab['interval'])
	if not tab['interval'] or tab['interval'] < 0 then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "interval")
	end

	-- about the source type, 1 represent the url, 2 represent the file
	local multimedia_file_url, file_id

	-- don't include multimediaFile when compute this argument, so set it nil
	if tab['multimediaURL'] then
		if not string.match(tab['multimediaURL'], 'http://[%w%.]+:?%d*/.+') and  not string.match(tab['multimediaURL'], 'redis://') then
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
		end
		multimedia_file_url = tab['multimediaURL']
		source_type = 1
	end

	if not tab['multimediaURL'] then
		if not tab['multimediaFile'] then
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaFile or multimediaURL")
		end
		multimedia_file_url, file_id = weibo_fun.get_dfs_url(tab['multimediaFile'], tab['appKey'])
		if not multimedia_file_url  then
			gosay.go_false(url_info, msg["MSG_DO_HTTP_FAILED"])
		end
		source_type = 2
		tab['multimediaFile'] = nil
	end

	-->> check appKey and sign
	--    safe.sign_check(tab, url_info)

	tab['fileID'] = file_id
	tab['multimediaURL'] = multimedia_file_url
	tab['sourceType'] = source_type

	-->> check level
	tab['level'] = tonumber(tab['level']) or 99
	if tab['level']>99 or tab['level']<1 then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "level")
	end

	local ok, res1, res2
	ok, res1 = weibo_fun.check_geometry_attr(tab['senderLongitude'], tab['senderLatitude'], tab['senderAltitude'], tab['senderDistance'], tab['senderDirection'], tab['senderSpeed'], 'sender')
	if not ok then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], res1)
	end

	-- because this tab is used in the store of redis
	ok, res1, res2 = weibo_fun.check_geometry_attr(tab['receiverLongitude'], tab['receiverLatitude'], tab['receiverAltitude'], tab['receiverDistance'], tab['receiverDirection'], tab['receiverSpeed'], 'receiver')
	if not ok then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], res1)
	end

	tab['direction_tab'], tab['speed_tab'] = res1, res2

	if tab['senderAccountID'] then
		if not app_utils.check_accountID(tab['senderAccountID']) and not app_utils.check_imei(tab['senderAccountID']) then
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "senderAccountID")
		end
	end

	if tonumber(tab['checkTokenCode'])==1 then
		local ok, imei
		if #tab['receiverAccountID'] == 15 then
			imei = tab['receiverAccountID']
		else
			ok, imei = redis_pool_api.cmd('private', 'get', tab['receiverAccountID'] .. ':IMEI')
		end

		local ok, res = redis_pool_api.cmd('private', 'get', imei or '' .. ':tokenCode')
		if ok and res then
			tab['tokenCode'] = res
		end
	end

	-- tab['callbackURL'], nothing to do with this argc

	tab['startTime'] = tonumber(tab['startTime'])
	if tab['startTime'] and (os.time() - tab['startTime'] < 120) then
		tab['start_time'] = tab['startTime']
	else
		tab['start_time'] = os.time()
	end
	tab['end_time'] = os.time() + tab['interval']

	if tab['end_time'] <= tab['start_time'] then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "startTime")
	end

	if tab['sourceID'] and #tab['sourceID']>32 then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "sourceID")
	end

	if tab['commentID'] then
		if #tab['commentID']>32 then
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "commentID")
		end
		tab['messageType'] = 4
	else
		tab['messageType'] = 1
	end

	tab['tipType'] = tonumber(tab['tipType']) or 0

	if not (tab['tipType'] == 0 or tab['tipType']== 1) then 
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "tipType")
	end

	tab['senderType'] = tonumber(tab['senderType']) or 3
	if tab['senderType']<1 or tab['senderType']>3 then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "senderType")
	end

	if tab['geometryType'] then
		tab['geometryType'] = tonumber(tab['geometryType'])
		if tab['geometryType'] == 4 then
			tab['bizid'] = weibo_fun.create_bizid('a6')
		elseif string.find('1,2,3,5', tab['geometryType']) then
			tab['bizid'] = weibo_fun.create_bizid('a8')
		else
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "geometryType")
		end
	end

	if tab['content'] then
		tab['content'] = utils.url_decode(tab['content'])
	end
end

-- 添加
-- 2016-03-12

function touch_media_redis(args_tab)

	-- %s is special in redis, we should escape it

	local media_url = utils.escape_redis_text(args_tab['multimediaURL'])

	local weibo_tab = {
		multimediaFileURL = media_url,
		time = {args_tab['start_time'], args_tab['end_time']},
		tokenCode = args_tab['tokenCode'],

		content = args_tab['content'],
		bizid = args_tab['bizid'],
		level = args_tab['level'],
		type = args_tab['messageType'] or 1,
		longitude = args_tab['receiverLongitude'],
		latitude = args_tab['receiverLatitude'],
		distance = args_tab['receiverDistance'],
		direction = args_tab['direction_tab'],
		speed = args_tab['speed_tab'],
		tipType = args_tab['tipType'],	
	}

	local ok_status, message = pcall(cjson.encode, weibo_tab)
	if not ok_status then
		only.log('E','pcall cjson encode args failed!')
	end

	local post_data = {
		level = args_tab['level'] .. args_tab['start_time'],
		UID = args_tab['receiverAccountID'],
		label = args_tab['bizid'],
		message = message,
	}

	local ok_status, ret = pcall(cjson.encode, post_data)
	if not ok_status then
		only.log('E','pcall cjson encode args failed!')
	end

	local data_fmt = 'POST %s HTTP/1.0\r\n' ..
	'Host:%s:%s\r\n' ..
	'Content-Length:%d\r\n' ..
	'Content-Type:application/json\r\n\r\n%s'

	local app_uri = '/weibo_send_single_message'
	local host_info = link['OWN_DIED']['http']['weibo-S']
	data = string.format(data_fmt,app_uri,host_info['host'],host_info['port'],#ret,ret)
	only.log('D', 'data:' .. data)
	local ok, ret = cutils.http(host_info['host'], host_info['port'], data, #data)
	only.log('D', "ret:" .. ret)

	local sender_info = {
		senderAccountID = args_tab['senderAccountID'],
		callbackURL = args_tab['callbackURL'],
		sourceID = args_tab['sourceID'],
		fileID = args_tab['fileID'],
		appKey = args_tab['appKey'],
		commentID = args_tab['commentID'],
	}
	--
	if next(sender_info) then
		local ok, json_string = utils.json_encode(sender_info)
		if not ok then
			return false
		end
		-- 
		local key  = string.format("%s:senderInfo",args_tab['bizid']) 
		local value  = json_string
		local expire_time  = args_tab['interval'] or 300

		only.log('D', string.format('setex key:%s expire_time:%s value:%s', key ,expire_time,value))
		ok, ret = redis_pool_api.cmd('weibo', 'setex', key , expire_time , value)
		if not ok then
			only.log('E', string.format('setex key:%s expire_time:%s value:%s', key ,expire_time,value))
			return false
		end
		--]]
	end

	return true
end

function personal_save_message_to_msgredis(args)

	local cur_time = os.date("%Y%m%d%H%M")
	local cur_time = math.floor(cur_time/10)

	--当senderAccountID存在时，按照senderAccountID进行HASH
	--当senderAccountID不存在时，按照appKey进行HASH,同时senderAccountID 的值用常量“unknow”替换

	if args['senderAccountID'] then
		only.log('D',"key:%s",args['senderAccountID'])
		message_redis_name = hash_function(args['senderAccountID'])
	else
		message_redis_name = hash_function(args['appKey'])
	end

	senderAccountID = args['senderAccountID'] or "unknow"

	--一个用户发送消息的记录
	--KEY:[senderAccountID:appkey:time]:sendmessage value:time|bizid
	local key = string.format("sendMessage:%s:%s:%s",senderAccountID,args['appKey'],cur_time)
	local ok = redis_pool_api.cmd(message_redis_name,'SADD',key,string.format("%s|%s",os.time(),args['bizid']))

	if not ok then 
		only.log('E',string.format(" **save personal message to redis failed! key:%s ,value:%s **", key, args['bizid']))
	end

	--KEY:time:sendmessage VALUE:senderAccountID:appkey
	local key = string.format("sendMessage:%s",cur_time)
	local value = string.format("%s:%s",senderAccountID,args['appKey'])
	local ok = redis_pool_api.cmd(message_redis_name,'SADD',key,value)

	if not ok then 
		only.log('E',string.format(" **save personal message to redis failed! key:%s ,value:%s **", key, value))
	end

	--KEY : bizid:fileLocation Value: URL
	--按照bizid 进行HASH
	local key = string.format("fileLocation:%s",args['bizid'])
	local message_redis_name = hash_function(args['bizid'])
	local ok = redis_pool_api.cmd(message_redis_name,'SET',key,args['multimediaURL'])

	if not ok then 
		only.log('E',string.format(" **save personal message to redis failed! key:%s ,value:%s **", key,args['multimediaURL'] ))
	end

	--存储地理有关的信息
	--KEY: gridID:time:GEOtoMessage
	local media_url,sender_lon,sender_lat,receiver_lon,receiver_lat,city_code,city_name = save_geography_message_info(args,cur_time,"personal")

	local commentID = args['commentID'] or ''
	if city_code and tonumber(args['senderType']) == 1 and commentID == '' then

		--城市语音批量拉取
		--KEY：cityCode:time
		--value: cityCode
		local message_redis_name = hash_function(city_code)
		local key = string.format("cityCode:%s",cur_time)
		local ok = redis_pool_api.cmd(message_redis_name,'SADD',key,city_code)

		if not ok then 
			only.log('E',string.format(" **save city voice message to redis failed! key:%s ,value:%s **", key,city_code))
		end

		--KEY :cityCodeMessage:cityCode:time
		--value: bizd
		local key = string.format("cityCodeMessage:%s:%s",city_code,cur_time)
		local ok = redis_pool_api.cmd(message_redis_name,'SADD',key,args['bizid'])

		if not ok then 
			only.log('E',string.format(" **save city voice message to redis failed! key:%s ,value:%s **", key,args['bizid'] ))
		end

	end

	--存储个人微博的具体信息
	save_personal_message_info(args,cur_time,media_url,sender_lon,sender_lat,receiver_lon,receiver_lat,city_code,city_name)

	return true
end





local function handle()
	-- 获取请求信息 heads body ip
	local req_heads = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	local ip = ngx.var.remote_addr

	url_info['client_host'] = ip
	url_info['client_body'] = req_body

	if not req_body then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_NO_BODY"])
	end

	local body_args = utils.parse_form_data(req_heads, req_body)
	if not body_args then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "Content-Type")
	end
	-- 检查参数
	check_parameters(body_args)

	if not body_args['bizid'] then
		body_args['bizid'] = weibo_fun.create_bizid('a4')
	end
	-- 保存消息到消息数据库
	local ret = weibo_fun.personal_save_message_to_msgredis(body_args)
	--   local ret = personal_save_message_to_msgredis(body_args)
	if not ret then
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	--    ret = weibo_fun.touch_media_redis(body_args)
	ret = touch_media_redis(body_args)

	if not ret then
		gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
	end

	local cur_month = os.date('%Y%m')
	local cur_day = os.date("%Y%m%d")
	weibo_fun.incrby_appkey( body_args['appKey'], cur_month, cur_day)
	weibo_fun.incrby_personal( cur_month, cur_day)

	local result = string.format('{"bizid":"%s","count":1}', body_args['bizid'])

	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], result)
end

safe.main_call( handle )
