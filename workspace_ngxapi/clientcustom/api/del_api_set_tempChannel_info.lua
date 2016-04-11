--jiang z.s. 
--2014-07-28
-- 临时频道的操作
-- 1: 正常(允许WEME使用++按键)
-- 2: 禁言(禁止WEME使用++按键)
-- 3: 解散临时频道

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local appfun    = require('appfun')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local weibo     = require('weibo')
local app_cfg   = require('clientcustom_cfg')

local weibo_dbname    = 'app_weibo___weibo'


local appKey = app_cfg.OWN_INFO.tempchannel_cfg.appKey
local secret = app_cfg.OWN_INFO.tempchannel_cfg.secret


local weiboServer = link.OWN_DIED.http.weiboServer
local txt2voice   = link.OWN_DIED.http.txt2voice


local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}


local default_channel = "10086"

local MAX_FORBID_TIME = 30*60

local G = {
    callback_url = "",
}

-->chack parameter
local function check_parameter(args)

    local tmp_custom_type = tonumber(args['customType']) or 1
    if not (tmp_custom_type == 1 or tmp_custom_type == 2 or tmp_custom_type == 3  ) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'customType')
    end

    if not args['tempChannelID'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'tempChannelID')
    end

    local tmp = string.match(args['tempChannelID'],'%d+')
    if not tmp or tostring(tmp) ~= args['tempChannelID'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'tempChannelID')
    end

    if #tmp < 5 or #tmp > 8 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'tempChannelID length')
    end

    safe.sign_check(args, url_tab )
end

---- 设置声音模式
---- 0 禁言,禁止WEME说话给其他WEME听见
---- 1 默认,允许WEME说话给其他WEME听见
local function set_channel_sound_mode( tmp_channel_id, val )
    redis_api.cmd('private','set',tmp_channel_id .. ":channelSoundMode",val)

    ---- 设置最大禁言时间 MAX_FORBID_TIME
    redis_api.cmd('private','expire',tmp_channel_id .. ":channelSoundMode",MAX_FORBID_TIME)
    return true
end

---- 获取当前频道的模式
local function get_channel_sound_mode( tmp_channel_id )
    local ok,ret = redis_api.cmd('private','get',tmp_channel_id .. ":channelSoundMode")
    if not ok or not ret then
        return 1
    end
    return tonumber(ret) or 1
end

-- 判断频道是否被解散
local function get_channel_is_disband( tmp_channel_id )
    local ok,ret = redis_api.cmd('private','get',tmp_channel_id .. ":channelSoundMode")
    if not ok or not ret then
        return 1
    end
    return 0
end

local function set_channel_info_to_db(accountid, tmp_channel_id, app_key,  val )
    local sql_fmt = "insert into userTempChannelInfo(accountID,channelID,channelStatus,appKey,createTime)" ..
                        "values ('%s', '%s', '%s',  %d , unix_timestamp() ) "
    local sql_str = string.format(sql_fmt,accountid,tmp_channel_id,val,app_key)
    local ok,ret = mysql_api.cmd(weibo_dbname,"INSERT",sql_str)
    if not ok then
        only.log('E',sql_str)
        only.log('E',"save userTempChannelInfo failed! == api_set_tempChannel_info!")
        return false
    end
    return true
end

---- 更新用户频道列表
local function update_user_channel_list( accountid , ok_tmp_channel )
    
    redis_api.cmd('private','del', accountid .. ":tempChannel:groupVoice")
    redis_api.cmd('statistic', 'srem', ok_tmp_channel .. ':channelOnlineUser', accountid )

    local VOICE_COMMAND_CHANNEL = 2
    
    local ok_status,ok_channel = redis_api.cmd('private','get',accountid .. ':currentChannel:groupVoice')
    ok_channel = ok_channel or default_channel
    ---- ++按键对应的频道在线列表
    redis_api.cmd('statistic','sadd', ok_channel .. ":channelOnlineUser" , accountid)
    

    local ok_status,ok_voice_type = redis_api.cmd('private','get',accountid .. ':voiceCommandCustomType')
    if ok_status and ok_voice_type then
        if tonumber(ok_voice_type) == VOICE_COMMAND_CHANNEL then
            local ok_status,ok_channel = redis_api.cmd('private','get',accountid .. ':currentChannel:voiceCommand')
            if ok_status then
                ok_channel = ok_channel or default_channel
                redis_api.cmd('statistic','sadd', ok_channel .. ':channelOnlineUser',accountid)
            end
        end
    end
    return true
end

local function disband_channel_list( tmp_channel_id )

    set_channel_sound_mode(tmp_channel_id,1) 

    redis_api.cmd('private','del',tmp_channel_id .. ":channelSoundMode")

    local ok_status,ok_tab = redis_api.cmd('statistic','smembers',tmp_channel_id .. ':channelOnlineUser')
    if not ok_status or not ok_tab then
        only.log('E',string.format("statistic smembers %s channelOnlineUser failed", tmp_channel_id ) )
        return false
    end

    for i,v in pairs(ok_tab) do
        only.log('D',string.format(" accountid:%s tempChannelID %s  " , v , tmp_channel_id ))
        update_user_channel_list(v, tmp_channel_id)
    end
    return true
end


local function remind_user_tempchannel_info( accountid , tmp_channel_id , text )
    local ok,user_tab = redis_api.cmd('statistic','smembers', tmp_channel_id .. ":channelOnlineUser")
    if not ok or not user_tab then
        only.log('D',"online user_tab get failed...")
        return false
    end

    if user_tab and #user_tab < 1 then
        only.log('D',string.format("%s count onlineUser is 0--->----", tmp_channel_id ))
        return false
    end
    local tab = {
        appKey = appKey,
        text = text,
        speechRate = speed,
        speechAnnouncer = announcer,
    }
    tab['sign'] = app_utils.gen_sign(tab,secret)
    tab['text'] = utils.url_encode(tab['text'])
    local ok, url = appfun.txt2voice(txt2voice, tab)
    if not ok or not url then
        only.log('D',string.format("--tmp_channel_id--:%s----remind_user_tempchannel_info--txt_to_voice_failed!",tmp_channel_id))
        return false
    end
    for i,v in pairs(user_tab) do
        local tab        = {
            appKey            = appKey,
            level             = 19,
            interval          = 300,
            sourceID          = fileid,
            content           = text,
            senderAccountID   = accountid ,
            multimediaURL     = url,
            callbackURL       = G.callback_url,
            receiverAccountID = v,
            senderType        = 2,
        }
        local ok,ret =  weibo.send_weibo(weiboServer,'personal', tab, appKey, secret)
        if ok and ret then
            only.log('D',string.format(" %s succed %s  " , v , ret['bizid'] ))
        end
    end
    return true
end


local function remind_user_tempchannel_start( accountid , tmp_channel_id )
    local text = string.format("频道%s开始直播,可以直接按加加键与主持人互动.",appfun.number_to_chinese(tmp_channel_id) )
    return remind_user_tempchannel_info(accountid,tmp_channel_id, text)
end

local function remind_user_tempchannel_end(accountid, tmp_channel_id )
    local text = string.format("频道%s直播结束,你已经回到之前的频道",appfun.number_to_chinese(tmp_channel_id) )
    return remind_user_tempchannel_info(accountid,tmp_channel_id, text)
end



local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_body = ngx.req.get_body_data()
    url_tab['client_host'] = req_ip
    if not req_body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_body'] = req_body

    -- local args = utils.parse_url(req_body)
    local args = ngx.decode_args(req_body)
    if not args then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
    end
    url_tab['app_key'] = args['appKey']
    check_parameter(args)


    local tmp_channel_id = args['tempChannelID']
    local tmp_custom_type = tonumber(args['customType']) or 1

    G.callback_url = string.format("http://dj.daoke.me/topicReplyURL?channelID=%s",tmp_channel_id)

    -- 临时频道的操作
    -- 1: 正常(允许WEME使用++按键) default 
    -- 2: 禁言(禁止WEME使用++按键)
    -- 3: 解散临时频道

    --- 自动识别模式
    local tmp_autoMode = tonumber(args['customAutoMode']) or 0

    only.log('D',string.format("%s   customType:%s [1:normal] [2:live mode] [3:disband]  customAutoMode:%s [1:autoMode]", tmp_channel_id, tmp_custom_type  , tmp_autoMode ))
    if tmp_autoMode == 1 then
        ---- 已经被解散
        if get_channel_is_disband(tmp_channel_id) == 1 then
            tmp_custom_type = 2
        else 
            tmp_custom_type = 3
        end
    end

    local tmp_accountid = args['accountID'] or ''
    if string.find(tmp_accountid,"'") then
        ---- DJ accountID user Save to log 
        tmp_accountid = ""
    end

    local ok_status = nil
    local tmp_flag = 1
    if tmp_custom_type == 1 then
        ---- 正常 (允许WEME使用++按键) default 
        ok_status = set_channel_sound_mode(tmp_channel_id,1)
    elseif tmp_custom_type == 2 then

        if get_channel_sound_mode(tmp_channel_id) == 0 then
            ---- 已经在直播模式了
            only.log('E',string.format("%s is live mode---- re live mode failed!" , tmp_channel_id ) )
            gosay.go_false(url_tab, msg['MSG_ERROR_TEMPCHANNEL_LIVE_MODE'])
        end

        ---- 开始直播,禁言 (禁止WEME使用++按键)
        ok_status = set_channel_sound_mode(tmp_channel_id,0)
        if ok_status then
            remind_user_tempchannel_start(tmp_accountid,tmp_channel_id)
        end
        tmp_flag = 0
    elseif tmp_custom_type == 3 then

        if get_channel_is_disband(tmp_channel_id) == 1 then
             ---- 解散模式
            only.log('E',string.format("%s is disband mode---- re disband mode failed!",tmp_channel_id ) )
            gosay.go_false(url_tab, msg['MSG_ERROR_TEMPCHANNEL_DISBAND_MODE'])
        end

        ---- 解散 临时频道
        remind_user_tempchannel_end(tmp_accountid,tmp_channel_id)
        ok_status = disband_channel_list(tmp_channel_id)
        tmp_flag = 2
    end

    only.log('D',string.format("%s   customType:%s  status:%s", tmp_channel_id, tmp_custom_type, ok_status ))

    if ok_status then
        set_channel_info_to_db(tmp_accountid,tmp_channel_id,url_tab['app_key'],tmp_flag)
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    end

    gosay.go_false(url_tab, msg['SYSTEM_ERROR'])

end

safe.main_call( handle )
