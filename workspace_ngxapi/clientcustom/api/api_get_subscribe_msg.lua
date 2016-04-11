--owner:jiang z.s. 
--time :2014-06-17
--获取用户所订阅消息类型

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local cjson     = require('cjson')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local userlist_dbname = 'app_usercenter___usercenter'
local weibo_dbname    = 'app_weibo___weibo'

local G = {
    sql_check_accountid  = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ",
    sql_query_subscribed_type = "select subscribedID as subIdx, subscribedValue as subName , subscribedType as catalogID, catalogName ,  0 as selected, intro  from subscribedTypeInfo where validity = 1  and viewStatus = 1   %s  order by subscribedType,subscribedTypeIndex,subscribedID ",
    sql_query_subscribed_info = "select subscribedValue from userSubscribedInfo where accountID = '%s' limit 1 "
}

------ 默认128位1的字符串


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
    local account_id = tostring(args['accountID'])
    if not account_id  or #account_id ~= 10 then
         gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID length')
    end

    local msg_type = tonumber(args['subscribedType']) or 0
    if args['msgType'] and ( msg_type < 1 or msg_type > 2 ) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'subscribedType')
    end
    ---- 2015-04-10 jiang z.s. KLD skd java
    safe.sign_check(args, url_tab,'accountID', safe.ACCESS_WEIBO_INFO)
end

---- 对accountID进行数据库校验
local function check_userinfo(account_id)
    local sql_str = string.format(G.sql_check_accountid,account_id)
    local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok_status or user_tab == nil then
        only.log('D',sql_str)
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    if #user_tab >1 then 
        -----数据库存在错误,
        only.log('E','[***] userList accountID recordset > 1 ')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end
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

    local accountID  = args['accountID']
    check_parameter(args)
    check_userinfo(accountID)
    
    local msg_type = tonumber(args['systemSubscribed']) or 0

    local sql_key = ""
    if msg_type == 1 then
        sql_key = " and subscribedType = 1 "
    else
        sql_key = " and subscribedType > 1 "
    end
    
    local sql_str = string.format(G.sql_query_subscribed_type, sql_key)
    local ok_status,result_tab = mysql_api.cmd(weibo_dbname,"SELECT",sql_str)

    -- only.log('D',sql_str)

    if not ok_status or result_tab == nil then
        only.log('E',string.format("accountID:%s  sql_query_subscribed_type failed!",accountID))
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    elseif #result_tab == 0 then
        only.log('E',string.format("accountID:%s  sql_query_subscribed_type empty!",accountID))
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    local sub_bin_length = 512
    local user_Info = string.rep("1",sub_bin_length)

    local sql_str = string.format(G.sql_query_subscribed_info, accountID)
    local ok_status,ok_tab = mysql_api.cmd(weibo_dbname,'SELECT',sql_str)
    if not ok_status or ok_tab == nil then
        only.log('D',sql_str)
        only.log('E',string.format("accountID:%s  sql_query_subscribed_info failed!",accountID))
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    elseif #ok_tab ~= 0 then
        user_Info = ok_tab[1]["subscribedValue"]
    end

    if #user_Info ~= sub_bin_length then
        only.log('E',string.format("accountID:%s  user_Info is error:%s",accountID,user_Info))
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    local ok_count = #result_tab
    local idx = 1
    while result_tab[idx] and idx <= ok_count  do
        local index = tonumber(result_tab[idx]['subIdx']) or 0
        if index > 0 then
            result_tab[idx]['selected'] = tostring(string.sub(user_Info,index,index))
        end
        idx = idx + 1
    end

    local ok_status,ok_str = pcall(cjson.encode,result_tab)
    if not ok_status or ok_str == nil then
        only.log('E',string.format("accountID:%s  user_Info is error;%s",accountID,user_Info))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_BAD_JSON'])
    end

    if ok_count == 0 then
        ok_str = "[]"
    end

    local result = string.format('{"count":"%d","list":%s}',ok_count,ok_str)
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],result)

end

safe.main_call( handle )
