-- author:zhangerna
-- 查询禁言用户api

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local channel_dbname  = "app_custom___wemecustom"
local MAX_COUNT = 50

local G = {
        sql_select_userShutUpInfo = "SELECT accountID,createTime,endTime FROM userShutUpInfo WHERE accountID in( '%s' )",
}

local url_tab = {
    type_name = 'system',
    app_key = '',
    client_host = '',
    client_body = '',
}


local function check_parameter(args)
    ---- 校验参数
    ---- accountIDs , 使用逗号分割
    if not args['accountIDs'] or #args['accountIDs'] == 0 or string.find(args['accountIDs'],"'") then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountIDs')
    end

    ---- 比较count总数是否大于最大阀值(MAX_COUNT) 
    if args['count'] then
        if not tonumber(args['count']) or tonumber(args['count']) > MAX_COUNT or tonumber(args['count']) < 1  then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'count')
        end
    end
    safe.sign_check(args, url_tab )  
end

local function user_shutup_Info(accountids)
    local sql_str = string.format(G.sql_select_userShutUpInfo,table.concat(accountids,"','"))
    local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"sql_select_userShutUpInfo failed [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        return false
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

    local count = tonumber(args['count']) or 0
    local accountids = {} 
    if count == 1 then
        table.insert(accountids,args['accountIDs'])
    elseif count > 1 then
        accountids = utils.str_split(args['accountIDs'],",")
    end
    if not accountids or type(accountids) ~= "table" then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"accountIDs")
    end

    if count ~= #accountids then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'count')
    end
    ---- 获取用户禁言
    local show_tab =  user_shutup_Info(accountids)
    local result = "[]"
    if show_tab and type(show_tab) == "table" and #show_tab > 0  then
        local ok,tmp_tab = pcall(cjson.encode,show_tab)
        if ok and tmp_tab then
            result = tmp_tab
        end
    end
    local str = string.format('{"count":"%s","list":%s}',count,result)
    if str then
        gosay.go_success(url_tab,msg['MSG_SUCCESS_WITH_RESULT'],str)
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

safe.main_call( handle )
