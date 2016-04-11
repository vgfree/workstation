-- 
-- author: chenjf
-- date: 2014 03 15
-- desc: send weibo to all online user of specified group. Feature #1935.

local ngx = require 'ngx'
local only = require 'only'
local gosay = require 'gosay'
local utils = require 'utils'
local msg = require 'msg'
local weibo_fun = require 'weibo_fun'
local safe = require('safe')

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

    -->> check groupID
    if not tab['groupID'] then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "groupID")
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
        if not string.match(tab['multimediaURL'], 'http://[%w.]+:?%d*/.+') then
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

    if tab['checkTokenCode'] then
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
end     

local function get_send_user(region_code, group_id, receive_list, refuse_userid)

    local ret_tab = {}

    -->> get the specified city online users
    local ok, online_list = redis_pool_api.cmd( "statistic", "smembers", region_code.. ":cityOnlineUser")
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
        only.log('E', "get the specified city online users erro!")
        return false
    end
    if #online_list<1 then
        only.log('I', "no online user!")
        return true, ret_tab
    end
    
    -->> get the group users
    local sql = string.format("SELECT accountID  FROM userGroupInfo WHERE groupID='%s'", group_id)
    only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_weibo___weibo', 'SELECT', sql)
    if not ok then
        only.log('E', "select mysql userGroupInfo error!")
        return false
    end
    if #res<1 then
        only.log('E', "groupID is error!")
        return false
    end

    local group_list = {}
    for _, v in ipairs(res) do
        table.insert(group_list, v['accountID'])
    end

    -->> get the intersection-set(online_list, receive_list, group_list) - refuse_userid
    local group_str = table.concat(group_list, ',')
    local receive_str = table.concat(receive_list, ',')

    for k, v in ipairs(online_list) do

        if refuse_userid ~= v then

            if string.find(group_str, a_id) and ( not receive_list or string.find(receive_str, a_id) ) then
                table.insert(ret_tab, v)
            end

        end
    end

    return ret_tab
end
    
local function handle()

    local req_heads = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    url_info['client_host'] = ip
    url_info['client_body'] = req_body

    -->> parse parameters
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

    -->> get receiveSelf userid
    local u_id = body_args['senderAccountID']

    -->> get userid list and send weibo
    local ok, tb_list = get_send_user(body_args['regionCode'], body_args['groupID'], body_args['receive_user'], refuse_userid)

    body_args['type'] = 3
    local send_count = 0
    if ok then

        for i=1, #tb_list do

            body_args['receiverAccountID'] = tb_list[i]
            ok = weibo_fun.touch_media_db(body_args)
            
            if ok then
                ok = weibo_fun.touch_media_redis(body_args)
            end

            if not ok then
                break
            end
            send_count = send_count + 1
        end
    end

    -->> write tmp_weibo.regionWeibo
    local sql_insert_regionWeibo = "INSERT INTO regionWeibo_%s set regionCode='%d', regionName='%s', groupID='%s', senderAccountID='%s', "..
                                   "appKey=%d, createTime=%d, bizid='%s', sendCount='%d' "
    local sql = string.format(sql_insert_regionWeibo, os.date('%Y%m'), body_args['regionCode'], region_name, body_args['groupID'], u_id or '', 
                                    body_args['appKey'], os.time(), body_args['bizid'], send_count )

    only.log('D', sql)
    local ok, ret = mysql_pool_api.cmd('app_weibo___weibo', "insert", sql)
    if not ok then
        only.log('W', 'mysql: Insert app_weibo.regionWeibo error.')
    end

    local cur_month = os.date('%Y%m')
    local cur_day = os.date("%Y%m%d")
    weibo_fun.incrby_appkey( body_args['appKey'], cur_month, cur_day)
    weibo_fun.incrby_groupid( body_args['groupID'], cur_month, cur_day)
    

    local result = string.format('{"bizid":"%s","count":%d}', body_args['bizid'], send_count)

    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], result)
end

safe.main_call( handle )
