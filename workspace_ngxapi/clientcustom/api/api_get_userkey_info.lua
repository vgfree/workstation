--owner:jiang z.s. 
--time :2015-05-21
--查询用户按键设置

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
local appfun    = require('appfun')


local userlist_dbname = 'app_usercenter___usercenter'
local custom_dbname   = 'app_custom___wemecustom'

local G = {
    ---- talkStatus 2015-08-06
    sql_get_userkey_info = "select actionType, customType , customParameter, 1 as talkStatus , '' as logo , '' as  parameterName , " .. 
                                " case when actionType = 3 then 'mainVoice' " ..
                                "       when actionType = 4 then 'voiceCommand' " ..
                                "       when actionType = 5 then 'groupVoice' end as actionName  " ..
                                " from userKeyInfo where validity = 1 and  accountID = '%s'  %s  ",

    sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ", 

    sql_get_secret_channel_info = "select idx , name , logoURL from checkSecretChannelInfo where number = '%s'  " ,
}

local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}

-->chack parameter
local function check_parameter(args)
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    ---- 目前actionType : DK_TYPE_VOICE / DK_TYPE_COMMAND / DK_TYPE_GROUP 
    local actionType = tonumber(args['actionType'])
    if args['actionType'] and #args['actionType'] > 0 then
        if not ( actionType == appfun.DK_TYPE_COMMAND 
                or actionType == appfun.DK_TYPE_GROUP
                or actionType == appfun.DK_TYPE_VOICE  )then
            only.log('E',string.format("**action_type is error, %s ", args['actionType'] ))
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'actionType')
        end
    end

    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
    -- safe.sign_check(args, url_tab)
end

---- 对accountID进行数据库校验
local function check_userinfo(accountid)
    local sql_str = string.format(G.sql_check_accountid,accountid)
    local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok_status or user_tab == nil then
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        only.log('W',"cur accountID is not exit [%s]",accountid)
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    if #user_tab >1 then 
        -----数据库存在错误,
        only.log('E','[***] userList accountID recordset > 1 ')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end
end

---- 获取频道信息
local function get_secret_channel_name( channel_num , accountid  )
    local sql_str = string.format(G.sql_get_secret_channel_info,channel_num)
    local ok, tmp_ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
    if ok and tmp_ret and type(tmp_ret) == "table" and #tmp_ret == 1 then
        local name = tmp_ret[1]['name']
        local logo = tmp_ret[1]['logoURL']
        local idx = tmp_ret[1]['idx']
        local ok, talkStatus = redis_api.cmd('private','hget',idx .. ":userStatusTab", accountid .. ":status")
        return name or '' , tonumber(talkStatus) or 1 , logo
    end
    return '',1,''
end


local function get_user_key_info(accountid, action_type)
    local str_filter = ""
    if action_type then
        str_filter = string.format(" and actionType = %s  " , action_type )
    end

    local sql_str = string.format(G.sql_get_userkey_info, accountid , str_filter )
    local ok_status,ok_ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)

    only.log('D',string.format("%s,actionType:%s",accountid, action_type))

    if not ok_status or not ok_ret then
        only.log('E','connect custom_dbname failed! %s ' , sql_str )
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        return false
    end

    for i = 1, #ok_ret do
        if tostring(ok_ret[i]['customParameter']) == "nil" then
            only.log('D','xxxxx find is nil')
            ok_ret[i]['customParameter'] = ""
        end

        if tonumber(ok_ret[i]['actionType']) == appfun.DK_TYPE_COMMAND and 
            tonumber(ok_ret[i]['customType']) == appfun.VOICE_COMMAND_TYPE_SECRETCHANNEL then
            ok_ret[i]['parameterName'] , ok_ret[i]['talkStatus'] , ok_ret[i]['logo'] = get_secret_channel_name(ok_ret[i]['customParameter'] , accountid)
        elseif tonumber(ok_ret[i]['actionType']) == appfun.DK_TYPE_GROUP and 
            tonumber(ok_ret[i]['customType']) == appfun.GROUP_VOICE_TYPE_SECRETCHANNEL then
            ok_ret[i]['parameterName'] , ok_ret[i]['talkStatus'] , ok_ret[i]['logo'] = get_secret_channel_name(ok_ret[i]['customParameter'] , accountid)
        end
    end

    local count = #ok_ret
    local ok_status,ok_str = pcall(cjson.encode,ok_ret)
    if not ok_status or not ok_str then
        only.log('E','cjson encode failed!')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
        return false
    end
    only.log('D',string.format("accountid:%s  result:%s ",accountid, ok_str ))
    return true,count,ok_str
end


local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    url_tab['client_host'] = req_ip
    if not req_body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_body'] = req_body

    local args = utils.parse_url(req_body)

    if not args then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
    end

    url_tab['app_key'] = args['appKey']

    check_parameter(args)

    local accountid  = args['accountID']
    check_userinfo(accountid)

    local action_type = tonumber(args['actionType'])
    local ok_status,ok_count,ok_str = get_user_key_info(accountid, action_type )
    if not ok_status then
        only.log('D',string.format("accountid:%s get user key info failed!", accountid ))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"actionType query")
    end

    only.log('D',string.format("------- accountid:%s , actionType:%s, return stauts:%s result:%s", 
                                    accountid,
                                    action_type,
                                    ok_status,
                                    ok_str ))

    if ok_count == 0 then
        ok_str = "[]"
    end
    local result = string.format('{"count":"%d","list":%s}',ok_count,ok_str)
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],result)
end

safe.main_call( handle )
