----zhangerna
----1  创建者得到群聊频道在线列表
----2  普通用户得到群聊频道在线列表
local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local appfun    = require('appfun')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')


local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname = "app_custom___wemecustom"
-- local userinfo_dbname = "app_clientmirrtalk___clientmirrtalk"

local G = {
            sql_check_accountID = "SELECT 1 FROM userLoginInfo WHERE accountID='%s' ",
            sql_get_onlineInfo  = "SELECT accountID ,  '' as nickname , 0 as online  %s , role , " .. 
                                    " case when actionType = 24 then 4  " .. 
                                    "      when actionType = 16 then 5  " ..
                                    "      when actionType = 8 then 4  " ..
                                    "      else 0 end as actionType   " ..
                                    " from joinMemberList  ".. 
                                    " where validity = 1 and number = '%s' order by id limit %d,%d ",
            check_is_join_channel = "SELECT role from joinMemberList where accountID = '%s' and number = '%s' and idx = '%s' and validity = 1 ",

            sql_get_user_nickname = "select accountID,nickname from userLoginInfo where nickname != '' and  accountID in ('%s')  ",
            
}
local url_tab = {

        type_name   = 'system',
        app_key      = '',
        client_host = '',
        client_body = '',
}

local function check_parameter(args)
        if args['infoType'] and #tostring(args['infoType']) > 1 then
            if not tonumber(args['infoType']) or not (args['infoType'] == "1" or args['infoType'] == "2" )  then 
                gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'infoType')
            end
        end
        if not app_utils.check_accountID(args['accountID']) or string.find(args['accountID'],"'") then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
        end
        if not args['channelNumber'] then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
        end
        if #tostring(args['channelNumber']) < 5 or #tostring(args['channelNumber']) > 16 or not utils.is_number(args['channelNumber']) then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
        end
        if args['startPage'] then
            if not tonumber(args['startPage']) or string.find(tonumber(args['startPage']),"%.") or tonumber(args['startPage']) <= 0 then
                gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'startPage')
            end
        end
        if args['pageCount'] then
             if not tonumber(args['pageCount']) or string.find(tonumber(args['pageCount']),"%.")  or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 100 then
                 gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'pageCount')
             end
        end
        -- safe.sign_check(args,url_tab)
        -- 20150720
        -- 为io部门使用
        safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)

end

local function check_accountID(accountID)

        local sql_str = string.format(G.sql_check_accountID,accountID)
        local ok,ret  = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
        if not ok or not ret then
            only.log('E',string.format("connect failed,sql_str:%s",sql_str))
            gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
        end
        if #ret == 0 then
            only.log('E',string.format("tab is empty,sql_str:%s",sql_str))
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
        end
        if #ret > 1 then
            --数据库存在错误
             only.log('E','[***] userList accountID recordset > 1 ')
             gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
        end
end

local function get_nickname(accountID)
        local ok,nickname = redis_api.cmd('private','get',accountID..':nickname')
        if not ok then
            gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
        end
        return nickname or ''
end

local function get_channelIdx(channel_number)
    local ok,idx = redis_api.cmd('private','get',channel_number .. ':channelID')
    if not ok then
        gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
    end
    if not idx or #tostring(idx) < 9 then
        return false
    end
    return idx
end

local function check_user_is_admin( idx,accountid )
    local ok, ret = redis_api.cmd('private','hget',idx .. ':userChannelInfo', "owner")
    if not ok or not ret then
        only.log('E',string.format(" channel_num get owner failed %s " , ret ))
        gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
    end
    if ret ~= accountid then
        only.log('E',"cur user is not admin,[really_admin:%s],[cur_accountID:%s]",ret,accountid)
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_NOT_MG'])
    end
end

---- 管理员得到群聊频道在线列表
local function get_online_secretChannelInfo(accountid , idx , channel_number, startPage , pageCount)

    only.log('D',"get_online_secretChannelInfo, %s %s %s %s %s ", accountid , idx , channel_number, startPage , pageCount )


    local str = " ,talkStatus  " 
    local sql_str = string.format(G.sql_get_onlineInfo ,str, channel_number , startPage , pageCount)
    local ok,tab  = mysql_api.cmd(channel_dbname , 'SELECT' , sql_str)
    if not ok or not tab or type(tab) ~= "table" then
        only.log('E',string.format("connect failed!sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #tab == 0 then
        only.log('D',"tab is empty,sql_str is %s",sql_str)
        return nil
    end
    local tmp_online_tab = {}
    local bind_key_list = {}
    local ok,ret = redis_api.cmd('statistic','smembers',string.format("%s:channelOnlineUser", idx ) )
    if ok and ret then
        only.log('D',"===statistic smembers  %s:channelOnlineUser, %s  ", idx, table.concat( ret, ", ") )
        for i,v in pairs(ret) do
            tmp_online_tab[tostring(v)] = 1
        end
    end
    local nickname_list = {}

    local accountid_list = {}
    local accountid_filter = {}
    for i, info in pairs(tab) do
        accountid_list[info['accountID']] = info['accountID']
        table.insert( accountid_filter, info['accountID'])
    end

    local sql_str = string.format(G.sql_get_user_nickname,table.concat(accountid_filter,"','"))
    local ok, nick  = mysql_api.cmd(userlist_dbname , 'SELECT' , sql_str)
    if not ok or not nick or type(nick) ~= "table" then
        only.log('E',string.format("sql_get_user_nickname connect failed!sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    for i , v in pairs(nick) do
        nickname_list[v['accountID']] = v['nickname']
    end

    for i, info in pairs(tab) do
        tab[i]['nickname'] = nickname_list[info['accountID']] or ''  ---- get_nickname(info['accountID'])
        ---- 与微频道统一
        tab[i]['online'] = tmp_online_tab[tostring(info['accountID'])] or 0
    end
 
    return tab
end

local function check_user_join_channel(idx,accountid,channel_number)
    local sql_str = string.format(G.check_is_join_channel,accountid ,channel_number,idx) 
    local ok , ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"check_is_join_channel failed,[%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('W','cur user not join channel[%s]',sql_str)
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_DID_NOT_JOINED'])
    end
    return ret[1]['role']
end

---- 普通得到在线列表
local function user_get_online_secretChannelInfo(accountid , idx , channel_number, startPage , pageCount)

    only.log('D',"user_get_online_secretChannelInfo, %s %s %s %s %s ", accountid , idx , channel_number, startPage , pageCount )

    local sql_str = string.format(G.sql_get_onlineInfo ,"", channel_number , startPage , pageCount)
    local ok,tab  = mysql_api.cmd(channel_dbname , 'SELECT' , sql_str)
    if not ok or not tab then
        only.log('E',string.format("connect failed!sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #tab == 0 then
        only.log('D',string.format("tab is empty,sql_str is %s",sql_str))
        return nil
    end
    local tmp_online_tab = {}
    local bind_key_list = {}
    local ok,ret = redis_api.cmd('statistic','smembers',string.format("%s:channelOnlineUser", idx ) )
    if ok and ret then
        for i,v in pairs(ret) do
            tmp_online_tab[tostring(v)] = 1
        end
    end
    local nickname_list = {}

    local accountid_list = {}
    local accountid_filter = {}
    for i, info in pairs(tab) do
        accountid_list[info['accountID']] = info['accountID']
        table.insert( accountid_filter, info['accountID'])
    end

    local sql_str = string.format(G.sql_get_user_nickname,table.concat(accountid_filter,"','"))
    local ok, nick  = mysql_api.cmd(userlist_dbname , 'SELECT' , sql_str)
    if not ok or not nick or type(nick) ~= "table" then
        only.log('E',string.format("sql_get_user_nickname connect failed!sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    for i , v in pairs(nick) do
        nickname_list[v['accountID']] = v['nickname']
    end
    for i, info in pairs(tab) do
        tab[i]['nickname'] = nickname_list[info['accountID']] or ''  ---- get_nickname(info['accountID'])
        ---- 与微频道统一
        tab[i]['online'] = tmp_online_tab[tostring(info['accountID'])] or 0
    end
    return tab
end



local function  handle()

    local req_ip = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()

    local req_method = ngx.var.request_method
    url_tab['client_host'] = req_ip
    if not req_body then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'])
    end
    url_tab['client_body'] = req_body

    local args = nil
    if req_method == 'POST' then
        local boundary = string.match(req_head,'boundary=(..-)\r\n')
        if not boundary then
            args = ngx.decode_args(req_body)
        else
            args = utils.parse_form_data(req_head,req_body)
        end
    end

    if not args then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
    end

    if not args['appKey'] then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"appKey")
    end
    url_tab['app_key'] = args['appKey']
    check_parameter(args)

    local accountid = args['accountID']
    check_accountID(accountid)

    local channel_number = args['channelNumber']
    local startPage = tonumber(args['startPage']) or 1
    local pageCount = tonumber(args['pageCount']) or 20
    local startIndex = (startPage - 1) * pageCount
    if startIndex < 1 then
        startIndex = 0 
    end

    ---- 得到频道的idx
    local idx = get_channelIdx(channel_number)
    if not idx or not (#tostring(idx) == 9 or #tostring(idx) == 10 ) then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
    end

    local ret = {}
    local keyInfo = {}
    ---- 检查用户是否加入当前频道
    local role = check_user_join_channel(idx,accountid,channel_number)
    if role and tonumber(role) and tonumber(role) == 0 then
        ret = user_get_online_secretChannelInfo(accountid,idx,channel_number,startIndex,pageCount )
    elseif role and tonumber(role) and (tonumber(role) == 1 or tonumber(role) == 2) then
        ret = get_online_secretChannelInfo(accountid ,idx , channel_number, startIndex , pageCount )
    end

    local count = 0
    local result = '[]'
    if ret and type(ret) == "table" and #ret > 0 then
        count = #ret
        local ok, tmp = pcall(cjson.encode,ret)
        if ok and tmp then
            result = tmp
        end
    end
    local str = string.format('{"count":"%s","list":%s}',count,result)
    if str then
        gosay.go_success(url_tab,msg['MSG_SUCCESS_WITH_RESULT'],str)
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end

end

handle()

