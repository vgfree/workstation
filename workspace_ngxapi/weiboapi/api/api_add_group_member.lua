-->owner:chengjian
-->time :2013-01-21
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path
--
local ngx = require('ngx')
local utils = require('utils')
local app_utils = require('app_utils')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api = require('http_short_api')
local only = require('only')
local msg = require('msg')
local safe = require('safe')
local link = require('link')

local weibo_srv = link.OWN_DIED.http.weiboapi
local callback_srv = link.OWN_DIED.http.callbackapi
local txt2voice_srv = link.OWN_DIED.http.dfsapi_txt2voice

local sql_fmt = {
    sl_accountID = "SELECT imei FROM userList WHERE accountID='%s'",
    select_group_id = "SELECT groupName, validity FROM groupInfo WHERE groupID='%s'",
    is_in_group = "SELECT 1 FROM userGroupInfo WHERE accountID='%s' AND groupID='%s' AND validity = 1",

    is_has_group = "SELECT 1 FROM userGroupInfo WHERE accountID='%s' AND groupType=2 AND validity=1 LIMIT 1",

    update_group_activity_info = "UPDATE addGroupMemberInfo SET memberStatus = %d, bizid = '' WHERE accountID='%s' AND groupID='%s'",
    insert_group_activity_info = "INSERT INTO addGroupMemberInfo SET appKey = %s, accountID = '%s', groupID = '%s', isCarMember = %d, bizid = '%s', feedbackURL='%s', memberStatus=%d, createTime=%d",

}

local url_tab = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    --> check groupID
    if not args['groupID'] or #args['groupID'] > 16 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupID')
    end

    -- check feedbackURL
    local feedback_url  = args['feedbackURL']
    if feedback_url and ((#feedback_url > 255) or (not string.match(string.sub(feedback_url, 1, 4), 'http'))) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'feedbackURL')
    end

    -- check isCarMember
    local is_car_member = tonumber(args['isCarMember'])
    if is_car_member ~= 1 and is_car_member ~= 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'isCarMember')
    end

    safe.sign_check(args, url_tab)

end

local function txt_to_voice_url(srv, txt, app_key)

    local url = 'dfsapi/v2/txt2voice'
    local tab = {
        text = txt,
        appKey = app_key,
    }
    local sign = app_utils.gen_sign(tab)
    local body = string.format('appKey=%s&sign=%s&text=%s', app_key, sign, utils.url_encode(txt))
    local data = utils.post_data(url, srv, body)

    only.log('D', data)
    local ret = http_api.http(srv, data, true)
    only.log('D', ret)

    if not ret then return nil end

    local body = string.match(ret, '{.*}')
    local status, jo = utils.json_decode( body)
    if not status or tonumber(jo['ERRORCODE'])~=0 then
        return nil
    else
        return jo['RESULT']['url']
    end

end



local function send_personal_fleet_weibo(name, account_id, group_id, is_car_member, feedback_url, app_key)

    local txt = string.format('%s车队，邀请你加入', name)

    local reply_txt = string.format("http://%s:%d/callbackapi/v2/addGroupMember?isCarMember=%s&groupID=%s", callback_srv['host'], callback_srv['port'], is_car_member, group_id)
    if feedback_url and #feedback_url~=0 then
        reply_txt = reply_txt .. '&feedbackURL=' .. feedback_url
    end


    local url = nil
    local ok, ret = redis_pool_api.cmd('private','hget','fleetInviteVoiceURL',string.format("%s:inviteURL", ngx.md5(txt) )  )
    if ok and ret then
        url = ret
    else
        url = txt_to_voice_url(txt2voice_srv, txt, app_key)
        if url then
            redis_pool_api.cmd('private','hmset','fleetInviteVoiceURL',string.format("%s:inviteURL", ngx.md5(txt) ) , url , string.format("%s:inviteText", ngx.md5(txt) ) , txt  )
        end
    end

    if not url then
        ---- 2014-12-01 jiang z.s. 
        only.log('E', string.format('txt to voice url failed,%s',txt) )
        return nil
    end

    local wb = {
        appKey            = app_key,
        multimediaURL     = url,
        level             = 18,   ----邀请加入车队等级太低,避免因为有频道消息而过滤掉 2014-10-21
        interval          = 24 * 3600,
        callbackURL       = reply_txt,
        content            = txt,
        receiverAccountID = account_id,
    }

    local ok, secret = redis_pool_api.cmd('public', 'hget', wb['appKey'] .. ':appKeyInfo', 'secret')
    wb['sign'] = app_utils.gen_sign(wb, secret)

    local post_body = utils.format_http_form_data(wb, '___mirrtalk___fleet___')

    local post_head = 'POST /weiboapi/v2/sendMultimediaPersonalWeibo HTTP/1.0\r\n' ..
                        'HOST:' .. weibo_srv['host'] .. ":" .. tostring(weibo_srv['port']) .. '\r\n' ..
                        'Content-Length:' .. tostring(#post_body) .. '\r\n' ..
                        'Content-Type:content-type:multipart/form-data;boundary=___mirrtalk___fleet___\r\n\r\n'

    local post_data = post_head .. post_body
    only.log('D',post_data)

    local ret = http_api.http(weibo_srv, post_data, true)
    only.log('D', ret)

    if not ret then return nil end
    local body = string.match(ret, '{.*}')
    local status, jo = utils.json_decode( body)
    if not status or tonumber(jo['ERRORCODE'])~=0 then
        return nil
    else
        return jo['RESULT']['bizid']
    end

end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_tab['client_host'] = ip
    url_tab['client_body'] = body

    if body == nil then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)
    if not args or type(args) ~= "table" then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_tab['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)

    local account_id = args['accountID']
    local is_car_member = tonumber(args['isCarMember'])
    local group_id = args['groupID']
    local feedback_url = args['feedbackURL']

    -- check accountID
    local sql = string.format(sql_fmt.sl_accountID, account_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
    if tonumber(result[1]['imei'])==0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_IMEI_HAS_NOT_BIND'])
    end

    sql = string.format(sql_fmt.select_group_id, group_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_GROUP_ID_NOT_EXIST'])
    end

    if tonumber(result[1]['validity'])==0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_CODE_GROUP_ID_UNUSABLE'])
    end

    local name = result[1]['groupName']

    -- 判断用户是否已加入该车队
    sql = string.format(sql_fmt.is_in_group, account_id, group_id)
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    -- local member_status, app_key = 0, 1473802167 
    local member_status, app_key = 0, args['appKey'] 
    if #result ~= 0 then
        member_status = 1
        sql = string.format(sql_fmt.update_group_activity_info, member_status, account_id, group_id)
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'update', sql) 
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    else

        sql = string.format(sql_fmt.is_has_group, account_id)
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
        if not ok then
            gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        end

        if #result ~= 0 then
            gosay.go_false(url_tab, msg['MSG_ERROR_GROUP_MEMBER_EXIST'])
        end

        local bizid
        if feedback_url then
            bizid = send_personal_fleet_weibo(name, account_id, group_id, is_car_member, feedback_url, args['appKey'])
        else
            bizid = send_personal_fleet_weibo(name, account_id, group_id, is_car_member, '', args['appKey'])
        end
        if bizid then
            member_status = 2
        else
            member_status = 3
        end

        sql = string.format(sql_fmt.insert_group_activity_info, app_key, account_id, group_id, is_car_member, bizid or '', feedback_url or '', member_status, os.time())
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    end

end


safe.main_call( handle )
