-- author:zhangerna
-- 用户禁言api

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"


local G = {
        sql_check_accountid   = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1",
        sql_insert_userShutUpInfo = "insert into userShutUpInfo(accountID,createTime,endTime)  values('%s',%s,%s)",
}

local url_tab = {
    type_name = 'system',
    app_key = '',
    client_host = '',
    client_body = '',
}


local function check_parameter(args)
    if #tostring(args['accountID']) == 10 then
            if not app_utils.check_accountID(args['accountID']) then
                gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
            end
    elseif #tostring(args['accountID']) == 15 then
        if not app_utils.check_imei(args['accountID']) then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
        end
    else
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
    end

    ---- 禁言时间  秒数
    if not args['totalTime'] or  not tonumber(args['totalTime']) then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'totalTime')
    end
    ---- 1 禁言 0 不禁言
    if not args['status'] or not tonumber(args['status']) or  not (args['status'] == '1' or args['status'] == '0') then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'status')

    end
    safe.sign_check(args, url_tab )  
end

local function check_accountid(accountID)
    local sql_str = string.format(G.sql_check_accountid,accountID)
    local ok,ret = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"check_accountid failed %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',"cur accountID is not exit,sql_str is %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
end

local function user_shutup(accountID,totalTime,status)
    redis_api.cmd('private','setex',string.format("%s:shutup",accountID), totalTime,status)
    local time = os.time()
    local sql_str = string.format(G.sql_insert_userShutUpInfo,accountID,time,time+totalTime)
    local ok , ret = mysql_api.cmd(channel_dbname,'insert',sql_str)
    if not ok or not ret then
        only.log('E',"sql_insert_userShutUpInfo failed [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    return true
end

local function handle()

    local req_ip = ngx .var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local req_method = ngx.var.request_method

    url_tab['client_host'] = req_ip
    if not req_body then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"body")
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

    local accountID = args['accountID']
    if #tostring(accountID) == 10 then
        check_accountid(accountID)
    end
    ---- 用户禁言
    local ok =  user_shutup(accountID,args['totalTime'],args['status'])
    
    if ok then
        gosay.go_success(url_tab,msg['MSG_SUCCESS'])
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

safe.main_call( handle )
