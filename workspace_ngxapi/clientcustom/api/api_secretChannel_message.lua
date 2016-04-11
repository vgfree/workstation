---- 群聊频道认证消息

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local appfun    = require('appfun')
local cjson   = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"


local G = {
        sql_check_accountid   = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1",
        -- sql_verify_channel  = "insert into userVerifyMsgInfo(accountid,role,idx,number,status,remark, applyAccountID, applyNickname, createTime)" .. 
        --                         " values('%s',1,'%s','%s',0,'%s',  '%s', '%s' , '%s') " , --accountID = '%s'
        sql_verify_message_fetch = "select id as idx , number , status , applyAccountID , applyNickname , createTime ,applyRemark  from userVerifyMsgInfo where validity = 1 and %s order by id limit %d , %d " ,
    }

local url_tab = {
    type_name = 'system',
    app_key = '',
    client_host = '',
    client_body = '',
}


local function check_parameter(args)
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
    end

    ---- status 过滤消息状态
    ---- 0未处理  1接收  2 拒绝
    if args['status'] and #args['status'] > 0 then
        if not tonumber(args['status']) or (string.find(args['status'],"%.")) or tonumber(args['status']) >= 3 or tonumber(args['status']) < 0 then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'status')
        end
    end
    if args['startPage'] and #args['startPage'] > 0 then
        if not tonumber(args['startPage'])  or string.find(args['startPage'],"%.") or tonumber(args['startPage']) <= 0  then
            only.log('E','startPage is error')
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'startPage')
        end
    end

    if args['pageCount'] and #args['pageCount'] > 0 then
        if  not tonumber(args['pageCount'])  or string.find(args['pageCount'],"%.") or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'pageCount')
        end
    end

    -- safe.sign_check(args, url_tab )  
    -- 20150720
    -- 为io部门使用
    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
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

local function secret_channel_message( accountid, start_index, page_count ,status)
    local str_filter = string.format(" accountID = '%s' " , accountid)
    if status and tonumber(status) then
        str_filter = str_filter .. string.format("  and status = %s  " , status )
    end
    local sql_str = string.format(G.sql_verify_message_fetch, str_filter, start_index, page_count )
    local ok , ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"check_accountid failed %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    return ret 
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

    local accountid = args['accountID']
    local status = args['status'] or ''
    check_accountid(accountid)


    local start_page = tonumber(args['startPage']) or 1
    local page_count = tonumber(args['pageCount']) or 20
    local start_index = (start_page-1) * page_count
    if start_index < 0 then
        start_index = 0
    end

    ---- 群聊频道认证消息
    local tab  = secret_channel_message( accountid , start_index , page_count , status )

    local count = 0 
    local result = "[]"
    if tab and type(tab) == "table" and #tab > 0 then
        local ok, val = pcall(cjson.encode,tab)
        if ok and val then
            count = #tab 
            result = val 
        end
    end

    local str = string.format('{"count":"%d","list":%s}',count , result)
    if str then
        gosay.go_success(url_tab,msg['MSG_SUCCESS_WITH_RESULT'],str)
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

safe.main_call( handle )
