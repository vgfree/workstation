---- author: zhangjl (jayzh1010@gmail.com)
---- accountID解绑IMEI 
---- 2015-04-10 
---- 2015-08-13 zhouzhe修改

local ngx       = require('ngx')
local sha       = require('sha1')
local msg       = require('msg')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local safe      = require('safe')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local sql_fmt = {

    sl_accountid = "SELECT imei FROM userLoginInfo WHERE userStatus=1 AND accountID = '%s' ",

    update_userlist = "UPDATE userLoginInfo SET updateTime= %d, imei='' WHERE imei != 0 and accountID = '%s' ",

    sql_insert_login_history = " INSERT INTO userLoginInfoHistory"..
    "(accountID,username,mobile,userEmail,imei,userStatus,nickname,clientIP,createTime,updateTime,remark )"..
    "SELECT accountID,username,mobile,userEmail,imei,userStatus,nickname,clientIP,createTime,updateTime,remark "..
    "FROM userLoginInfo WHERE userStatus=1 AND accountID='%s' ",

    --- redis取设备、model默认设置频道 -- 20150921
    redis_eval_command = " local channelNumber= redis.call('GET','%s:deviceInitChannelInfo') "..
                           " if channelNumber then "..
                           "    return channelNumber "..
                           " else "..
                           "    local model= redis.call('GET','%s:modelInfo') "..
                           "    if model then "..
                           "        channelNumber = redis.call('GET', model..':deviceInitChannelInfo') "..
                           "        if channelNumber then "..
                           "            return channelNumber "..
                           "        end "..
                           "    end " ..
                           "    return nil "..
                           " end "
}

local userlist_dbname = "app_usercenter___usercenter"

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_user_is_online( account_id )
    local ok, ret = redis_api.cmd('statistic', 'sismember', 'onlineUser:set', account_id)
    return ok and ret
end

---- 获取默认频道number的idx
local function get_default_channel_idx(channel_num )
    local ok, idx = redis_api.cmd('private', 'get', channel_num .. ':channelID')
    if ok and idx then
        return idx 
    end
    return nil
end

local function disconnect_accountid(a_id)

    local sql = string.format(sql_fmt.sl_accountid, a_id)
    local ok, ret = mysql_api.cmd(userlist_dbname, 'select', sql)
    if not ok or not ret then

        only.log('E',string.format(" check accountID failed, %s ", sql)) 
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #ret == 0 then
        only.log('E', string.format("the record of accountID:%s is zero", a_id))
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    elseif #ret > 1 then
        only.log('E', string.format("the record of accountID:%s is more than one, call someone to handle", a_id))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'accountID')
    end

    local imei = ret[1]['imei']

    local sql_tab = {}
    local cur_time = os.time()
    local sql1 = string.format(sql_fmt.update_userlist, cur_time, a_id)
    table.insert(sql_tab, sql1)
    local sql2 = string.format(sql_fmt.sql_insert_login_history, a_id)
    table.insert(sql_tab, sql2)

    local ok = mysql_api.cmd(userlist_dbname, 'affairs', sql_tab)
    only.log('D', "update user login info==sql== %s", table.concat( sql_tab, "\r\n"))
    if not ok then
        only.log("E", "update user imei failed")
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if tonumber(imei) ~= 0 then
        redis_api.cmd('private', 'del', imei .. ":accountID")
        redis_api.cmd('private', 'del', a_id .. ":IMEI")

        if check_user_is_online(a_id) then

            redis_api.cmd('statistic', 'srem', 'onlineUser:set', a_id)

            ---- 2015-04-10 jiang z.s. 
            ---- 获取微频道用户的关注列表,自动剔除下线
            local ok, ret = redis_api.cmd('statistic','smembers',a_id .. ":userFollowMicroChannel")
            if ok and ret then
                for k, idx in pairs(ret) do
                    redis_api.cmd('statistic', 'srem', idx .. ':channelOnlineuser', a_id)
                    only.log('I',string.format("srem channelidx:%s  channelOnlineuser %s" , idx, a_id ))
                end
            end

            local ok, ret = redis_api.cmd('private', 'get', a_id .. ":cityCode")
            if ok and ret then
                only.log('W',string.format("srem %s cityOnlineUser %s",ret,a_id))
                only.log('W',string.format("sadd %s cityOnlineUser %s" ,ret ,imei))
                redis_api.cmd('statistic', 'srem', ret .. ':cityOnlineUser', a_id)
                redis_api.cmd('statistic', 'sadd', ret .. ':cityOnlineUser', imei)
            end

            local default_channel = 10086
            ---- 获取++键关联频道 result
            local ok, channel_idx = redis_api.cmd('private', 'get', a_id .. ':currentChannel:groupVoice')
            only.log("D",string.format("groupVoice channel_idx:%s", channel_idx))
            if not ok then
                only.log("E", string.format('get currentChannel:groupVoice redis failed, accountID:%s', a_id))
            end

            ---- 判断是否设置过++键  
            ---- 没有设置过，清除 idx:channelOnlineUser aid   把imei设置到默认频道在线列表  idx:channelOnlineUser imei
            ---- 设置过  清除之前频道在线列表，把imei设置到默认频道在线列表  idx:channelOnlineUser imei
            if not channel_idx then

                ---- 获取默认频道的idx
                channel_idx =  get_default_channel_idx(default_channel)
                only.log("D",string.format("10086 groupVoice channel_idx:%s", channel_idx))
            end
            ---- 清除aid和idx  
            if channel_idx and #tostring(channel_idx) >= 9 then

                redis_api.cmd('statistic',  'srem', channel_idx .. ':channelOnlineUser', a_id)
            end

            ---- 清除+按键  判断用户是否设置过
            ---- 设置过+键  移除此用户在线列表
            local ok, channel_idx = redis_api.cmd('private', 'get', a_id .. ':currentChannel:voiceCommand')
            if not ok then
                only.log("E", string.format('get currentChannel:voiceCommand redis failed, accountID:%s', a_id))
            end

            if channel_idx then

                ---- 清除在线信息
                redis_api.cmd('statistic',  'srem', channel_idx .. ':channelOnlineUser', a_id)
            end

            redis_api.cmd('statistic', 'sadd', 'onlineUser:set', imei)

            ---- (imei或设备对应的model号)判断是否存在设置默认频道，若无则直接取10086 --20150923 --
            local ok, channelNumber = redis_api.cmd('private','eval', string.format(sql_fmt.redis_eval_command, imei, imei  ) ,0)
            if not ok then
                only.log('W',string.format("[[1]] get imei = %s deviceInitChannelInfo, redis failed ", imei))
            end

            if channelNumber then
                only.log('W',string.format("[[2]] get imei = %s deviceInitChannelInfo, channelNumber = %s ", imei, channelNumber))
                default_channel = channelNumber
            end

            local channel_idx =  get_default_channel_idx(default_channel)
            ---- 关联imei和idx
            redis_api.cmd('statistic', 'sadd', channel_idx .. ':channelOnlineUser', imei)
            only.log('D',string.format("[init ] %s device sadd %s:channelOnlineUser ]", imei , channel_idx ) )

        end
    end
    return true
end

local function check_paremeter(args)

    if not args['appKey'] or #args['appKey'] < 7 or not utils.is_number(args['appKey'])  then
        only.log("E","appKey is error!")
        gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
    end

    url_info['app_key'] = args['appKey']
    
    ---accountID--2015/4/11---
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    safe.sign_check(args, url_info,'accountID', safe.ACCESS_BINDMIRRTALK_INFO)
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    if not body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body) 
    if not args or type(args) ~= "table" then
        gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"], 'args')
    end

    check_paremeter(args)

    disconnect_accountid(args['accountID'])

    gosay.go_success(url_info, msg["MSG_SUCCESS"])

end


safe.main_call( handle )

