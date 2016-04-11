--jiang z.s. 
--2014-07-28
--设置用户的临时频道

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')


local weibo_dbname    = 'app_weibo___weibo'


local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}


local default_channel = "10086"

local MAX_FORBID_TIME = 30*60

-->chack parameter
local function check_parameter(args)
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    local tmp_custom_type = tonumber(args['customType']) or 1
    if not (tmp_custom_type == 1 or tmp_custom_type == 2 ) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'customType')
    end

    if tmp_custom_type == 1 then
        ----1 Set tempChannelID
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
    end

    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end


---- 判断用户是否在线
local function check_user_is_online( account_id )
    local ok_status,ok_ret = redis_api.cmd('statistic','sismember',"onlineUser:set",account_id)
    return ok_status and ok_ret
end


---- 更新用户频道列表
local function update_user_channel_list( accountid , ok_tmp_channel )
    local VOICE_COMMAND_CHANNEL = 2

    if  ok_tmp_channel  then
        ---- 用户存在临时频道 
        ---- 先删除++按键对应的频道在线列表
        local ok_status,ok_channel = redis_api.cmd('private','get',accountid .. ':currentChannel:groupVoice')
        ok_channel = ok_channel or default_channel
        
        redis_api.cmd('statistic','srem', ok_channel .. ':channelOnlineUser',accountid)
        
        ---- 设置临时频道在线列表
        redis_api.cmd('statistic','sadd', ok_tmp_channel .. ":channelOnlineUser" , accountid)
    else
        ---- 用户不存在临时频道
        local ok_status,ok_channel = redis_api.cmd('private','get',accountid .. ':currentChannel:groupVoice')
        ok_channel = ok_channel or default_channel
        if ok_channel ~= ok_tmp_channel then
            ---- 设置临时频道在线列表
            redis_api.cmd('statistic','sadd', ok_channel .. ":channelOnlineUser" , accountid)
        end
    end

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

local function remove_pre_temp_channel_list( account_id )
    local ok_status,ok_prechannel = redis_api.cmd('private','get', account_id .. ":tempChannel:groupVoice")
    if ok_status and ok_prechannel then
        redis_api.cmd('private','del', account_id .. ":tempChannel:groupVoice")
        redis_api.cmd('statistic','srem',ok_prechannel .. ':channelOnlineUser',account_id)
    end
end

---- 设置新的临时频道
local function set_user_temp_channel_id( account_id,tmp_channel_id )
    remove_pre_temp_channel_list(account_id)
    local ok_status,ok_ret = redis_api.cmd('private','set', account_id .. ":tempChannel:groupVoice",tmp_channel_id)
    if not ok_status then
        -- MAX_FORBID_TIME
        ---- 设置最大禁言时间 MAX_FORBID_TIME
        redis_api.cmd('private','expire',account_id .. ":tempChannel:groupVoice" ,MAX_FORBID_TIME)
        only.log('D',string.format("private %s set tempChannelID failed!", account_id , tmp_channel_id ) )
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
        return false
    end
    return update_user_channel_list(account_id,tmp_channel_id)
end


---- 删除临时频道
local function del_user_temp_channel_id( account_id )
    remove_pre_temp_channel_list(account_id)
    return update_user_channel_list(account_id)
end

local function set_channel_info_to_db(accountid, tmp_channel_id, app_key, token_code,  val )
    local sql_fmt = "insert into userTempChannelInfo(accountID,tokenCode,channelID,channelStatus,appKey,createTime)" ..
                        "values ('%s', '%s' , '%s', %d,  '%s' , unix_timestamp() ) "
    local sql_str = string.format(sql_fmt,accountid,token_code,tmp_channel_id,tonumber(val) + 10, app_key )
    local ok,ret = mysql_api.cmd(weibo_dbname,"INSERT",sql_str)
    if not ok then
        only.log('E',sql_str)
        only.log('E',"save userTempChannelInfo failed! == api_set_usertempChannel!")
        return false
    end
    return true
end

local function get_token_code( accountid )
    local  ok,ret = redis_api.cmd('private','get', accountid .. ":tokenCode")
    if ok and ret then
        return ret
    end
    return ''
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

    local account_id  = args['accountID']
    local tmp_channel_id = args['tempChannelID']
    local tmp_custom_type = tonumber(args['customType']) or 1

    ----  操作类型 
    ---- 1 设置用户的临时频道
    ---- 2 删除用户的临时频道

    local ok_status = nil
    local tmp_flag = 1
    if tmp_custom_type == 1 then
        if not check_user_is_online(account_id) then
            gosay.go_false(url_tab, msg['MSG_ERROR_OFFLINE'])
        end
        ok_status = set_user_temp_channel_id(account_id,tmp_channel_id)
    else
        ok_status = del_user_temp_channel_id(account_id)
        tmp_flag = 0
    end

    if ok_status then
        only.log('D',string.format("%s join tempChannelID:%s succed", account_id, tmp_channel_id ) )
        local token_code = get_token_code(account_id)
        set_channel_info_to_db(account_id, tmp_channel_id, url_tab['app_key'], token_code,  tmp_flag )
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    end
    gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    
end

safe.main_call( handle )
