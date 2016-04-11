---- zhangerna
---- 管理员得到群聊频道的详细信息
---- 用户的到群聊频道的详细信息

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}

local G = {
    sql_check_accountID = "SELECT 1 FROM userList WHERE accountID = '%s' ",

    ---- 得到频道详情
    sql_get_secretInfo  = "SELECT idx as channelID,number,name ,introduction ,cityCode , case cityCode when 0 then '全国' else cityName end as cityName " ..
                            " ,catalogID , catalogName ,logoURL ,"..
                            " accountID , InviteUniqueCode ,openType , capacity ,createTime ,keyWords , '' as adminName ,isVerify , userCount ,0 as bindKey ,0 as onlineCount ,0 as isJoined FROM checkSecretChannelInfo "..
                            " WHERE channelStatus = 1  and number = '%s' limit 1",   
    sql_get_joinMember_info = "select actionType from joinMemberList where validity = 1 and  accountID = '%s'  and number = '%s'  " ,
}

local function check_parameter(args)
    if not app_utils.check_accountID( args['accountID'])  then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
    end
    if  not tonumber(args['channelNumber']) or #tostring(args['channelNumber']) < 5 or not utils.is_number(args['channelNumber']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
    end

    -- safe.sign_check(args,url_tab)
    -- 20150720
    -- 为io部门使用
    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

local function check_accountid(accountID)
    local sql_str = string.format(G.sql_check_accountID,accountID)
    local ok,ret  = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok or not ret  then
        only.log('E',string.format("cur userList tab is empty,sql_str:%s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',string.format("cur userList tab is empty,sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
    if #ret > 1 then
        only.log('E','[***] userList accountID recordset > 1 ')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end
end

---- 得到用户昵称
local function get_nickname(accountID)
    if not accountID then
        return ''
    end
    local ok,nickname = redis_api.cmd('private','get',accountID..':nickname')
    if not ok then
        only.log('E',"redis get chiefAnnouncerName failed [%s]",accountID)
        gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
    end
    return nickname or ''

end

local function get_secretchannel_info( account_id, channel_num , show_id ,is_joined ,bindkey ,onlineUser)
    local sql_str = string.format(G.sql_get_secretInfo, channel_num)
    local ok , ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E',string.format('get user channel info failed!  %s ',sql_str) )
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #ret == 0  then
        only.log('W',string.format( "channel_num:%s   get result is empty", sql_str))
        gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_IDX'])
    end

    if not show_id then
        ret[1]['channelID'] = nil
    end

    ret[1]['bindKey'] = tonumber(bindkey) or 0
    ret[1]['onlineCount'] = tonumber(onlineUser) or 0
    ret[1]['isJoined'] = tonumber(is_joined) or 0
    --adminName
    ret[1]['adminName'] = get_nickname(ret[1]['accountID'])
    local ok, str = pcall(cjson.encode,ret)

    return str,total
end


local function get_secretchannel_detail( account_id, channel_num )
    local ok, idx = redis_api.cmd('private', 'get', string.format("%s:channelID", channel_num))
    if not ok  then
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end
    if not tonumber(idx) or #idx < 9 then
         only.log('D',"get_secretchannel_detail:%s",idx)
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
    end
    only.log('D',"account_id:%s,channel_num:%s",account_id,channel_num)
    local sql_str = string.format(G.sql_get_joinMember_info, account_id, channel_num)
    local ok , ret = mysql_api.cmd(channel_dbname ,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',string.format('get secret channel info failed!  %s ',sql_str) )
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    local joined = "0"
    local bindkey = "0"
    if #ret == 1 then
        local tmp_action_val = tonumber(ret[1]['actionType']) or 0 
        if tmp_action_val == 24 or tmp_action_val == 8  then
            --- 2 ** ( actionType -1  )
            bindkey = "4" 
        elseif tmp_action_val ==16 then
            bindkey = "5"
        end
        joined = "1"
    end
    local ok , onlineUser = redis_api.cmd('statistic','scard', idx .. ":channelOnlineUser")
    if not ok  then
        only.log('E',"get channelOnlineUser failed!, %s", idx )
        gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
    end
    return joined, bindkey,onlineUser
end

local function handle()

    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local req_method = ngx.var.request_method
    url_tab['client_host'] = req_ip
    if not req_body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_body'] = req_body

    local args = nil
    if req_method == 'POST' then
        local boundary = string.match(req_head, 'boundary=(..-)\r\n')
        if not boundary then
            args = ngx.decode_args(req_body)
        else
            -- 解析表单形式 
            args = utils.parse_form_data(req_head, req_body)
        end
    end
    if not args then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
    end

    if not args['appKey'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
    end

    url_tab['app_key'] = args['appKey']
    check_parameter(args)

    local account_id = args['accountID']
    check_accountid(account_id)

    local channel_num =  args['channelNumber']
    local show_id = args['showChannelID']

    local is_joined , bindkey ,onlineUser  = get_secretchannel_detail( account_id, channel_num ) 

    local str = get_secretchannel_info( account_id, channel_num , show_id ,is_joined , bindkey ,onlineUser )

    if str then
        gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end

end

safe.main_call( handle )
