--
-- author: chenjf
-- date: 2014 03 12
-- desc: send weibo to all online user of specified city. Feature #1934.

local ngx = require 'ngx'
local only = require 'only'
local gosay = require 'gosay'
local utils = require 'utils'
local msg = require 'msg'
local weibo_fun = require 'weibo_fun'
local safe = require('safe')
local weibo       = require('weibo')

local redis_pool_api = require 'redis_pool_api'
local mysql_pool_api = require 'mysql_pool_api'

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameters(tab)

    url_info['app_key'] = tab['appKey']

    -->> check regionCode
    tab['regionCode'] = tonumber(tab['regionCode'])
    if not tab['regionCode'] then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "regionCode")
    end

    if tab['receiveCrowd'] then
        local ok, res = utils.json_decode( tab['receiveCrowd'])
        if not ok then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveCrowd")
        end
        if res['accountID'] then
            tab['receive_user'] = res['accountID']

            if type(tab['receive_user'])~='table' or #tab['receive_user']>150 then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveCrowd accountID")
            end
        end
    end

    -->> check interval
    tab['interval'] = tonumber(tab['interval'])
    if not tab['interval'] or tab['interval'] < 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "interval")
    end

    -- about the source type, 1 represent the url, 2 represent the file
    local multimedia_url, source_type, file_id

    -- don't include multimediaFile when compute this argument, so set it nil
    if tab['multimediaURL'] then
	if not string.match(tab['multimediaURL'], 'http://[%w%.]+:?%d*/.+') and  not string.match(tab['multimediaURL'], 'redis://') then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
        end
        multimedia_url = tab['multimediaURL']
        source_type = 1
    end

    if not tab['multimediaURL'] then
        if not tab['multimediaFile'] then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaFile or multimediaURL")
        end
        file_id, multimedia_url = weibo_fun.get_dfs_url(tab['multimediaFile'], tab['appKey'])
        if not multimedia_url  then
            gosay.go_false(url_info, msg["MSG_DO_HTTP_FAILED"])
        end

        source_type = 2

        tab['multimediaFile'] = nil
    end

    -->> check appKey and sign
    safe.sign_check(tab, url_info)

    tab['fileID'] = file_id
    tab['multimediaURL'] = multimedia_url
    tab['sourceType'] = source_type

    tab['receiveSelf'] = tonumber(tab['receiveSelf']) or 1
    if tab['receiveSelf']~=0 and tab['receiveSelf']~=1 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveSelf")
    end

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
        if #tab['senderAccountID']~=10 and #tab['senderAccountID']~=15 or (#tab['senderAccountID']==15 and (string.sub(tab['senderAccountID'],0,0)=='0')) then
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

    if tab['startTime'] and (os.time() - tonumber(tab['startTime']) < 120) then
        tab['start_time'] = tab['startTime']
    else
        tab['start_time'] = os.time()
    end
    tab['end_time'] = os.time() + tab['interval']

    if tab['content'] then
        tab['content'] = utils.url_decode(tab['content'])
    end

    if tab['commentID'] and #tab['commentID']>32 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "commentID")
    end

    tab['senderType'] = tonumber(tab['senderType']) or 3
    if tab['senderType']<1 or tab['senderType']>3 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "senderType")
    end

end


local function handle()

    local req_heads = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    url_info['client_host'] = ip
    url_info['client_body'] = req_body

    -->> parse parameters by request
    if not req_body then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_NO_BODY"])
    end

    local body_args = utils.parse_form_data(req_heads, req_body)
    if not body_args then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "Content-Type")
    end

    -->> check parameters
    check_parameters(body_args)

    body_args['bizid'] = weibo_fun.create_bizid('a6')

    -->> get region name
    local region_name = weibo_fun.get_region_name(body_args['regionCode'])
    if not region_name then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    -->> get online user lists
    local ok, tb_list = redis_pool_api.cmd( "statistic", "smembers",  body_args['regionCode'].. ":cityOnlineUser")
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
    end

	local final_user = {}
	if not body_args['receive_user'] then
		final_user = tb_list
	else
		local parent_str = table.concat(tb_list, ',')

		for i, v in ipairs(body_args['receive_user']) do
			if not string.find(parent_str, v) then
				table.remove(body_args['receive_user'], i)
			end
		end

		final_user = body_args['receive_user']

	end


    local recv_self = tonumber(body_args['receiveSelf'])
    local u_id = body_args['senderAccountID']
    local send_count = 0
    for i, v in ipairs (final_user) do

        -->> need cross the receiveSelf if recvSelf==0
        if recv_self ~= 0 or u_id ~= v then

			if body_args['senderType']~=3 or  (body_args['senderType'] == 3 and weibo.check_weibo_tj_msg(v, body_args['appKey'])) then
				body_args['receiverAccountID'] = v
				ok = weibo_fun.personal_save_message_to_msgredis(body_args)

				if ok then
					ok = weibo_fun.touch_media_redis(body_args)
				end

				if not ok then
					break
				end
				send_count = send_count + 1
			end
		end

    end
    
    weibo_fun.city_save_message_to_msgredis(body_args,region_name,send_count)
    -->> write tmp_weibo.regionWeibo
    -- local sql_insert_regionWeibo = "INSERT INTO regionWeibo_%s set regionCode='%d', regionName='%s', senderAccountID='%s',".. 
    --                                " appKey=%d, createTime=%d, bizid='%s', sendCount=%d"
    -- local sql = string.format(sql_insert_regionWeibo, os.date('%Y%m'), body_args['regionCode'], region_name, u_id or '', 
    --                                  body_args['appKey'], os.time(), body_args['bizid'], send_count )
    -- only.log('D', sql)
    -- local ok, ret = mysql_pool_api.cmd('app_weibo___weibo', "insert", sql)
    -- if not ok then
    --     only.log('E', "mysql: insert app_weibo.regionWeibo error!")
    -- end

    local cur_month = os.date('%Y%m')
    local cur_day = os.date("%Y%m%d")
    weibo_fun.incrby_appkey( body_args['appKey'], cur_month, cur_day)
    weibo_fun.incrby_citycode( body_args['regionCode'], cur_month, cur_day)

    local result = string.format('{"bizid":"%s","count":%d}', body_args['bizid'], send_count)

    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], result)
end

safe.main_call( handle )
