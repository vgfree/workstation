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

local weibo_fun = require 'weibo_fun'

--local mysql_pool_api = require 'mysql_pool_api'
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
	if not (string.match(tab['multimediaURL'], 'http://[%w%.]+.*?group=.*file=.*.%a%a.') or  string.match(tab['multimediaURL'], 'http://[%w%.]+:?%d*/.+')) and  not string.match(tab['multimediaURL'], 'redis://') then
--	if not string.match(tab['multimediaURL'], 'http://[%w%.]+:?%d*/.+') and  not string.match(tab['multimediaURL'], 'redis://') then
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
    safe.sign_check(tab, url_info)

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

local function handle()

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
	if body_args['imei'] == "782256747148015" or body_args['imei'] == "756147491689308" or body_args['senderAccountID'] == "HRlYQhFvpW" or body_args['senderAccountID'] == "egQH09ks9a" then
	only.log("E","lipengwei xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
	only.log("E","lipengwei xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
	end
    check_parameters(body_args)

    if not body_args['bizid'] then
        body_args['bizid'] = weibo_fun.create_bizid('a4')
    end
	
	if body_args['imei'] == "782256747148015" or body_args['imei'] == "756147491689308" or body_args['senderAccountID'] == "HRlYQhFvpW" or body_args['senderAccountID'] == "egQH09ks9a" then
	only.log("E","lipengwei 1111111111111111111111111111111111111")
	end
	
	
	
    local ret = weibo_fun.personal_save_message_to_msgredis(body_args)
    if not ret then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    --if body_args['commentID'] then
    --    ret = weibo_fun.touch_comment_db(body_args)
    --    if not ret then
    --        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    --    end
    --end

    ret = weibo_fun.touch_media_redis(body_args)
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
