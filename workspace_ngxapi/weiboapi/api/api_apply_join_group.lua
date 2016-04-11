-->owner:chengjian
-->time :2013-01-21
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path

local ngx = require('ngx')
local utils = require('utils')
local app_utils = require('app_utils')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api = require('http_short_api')
local only = require('only')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {
    sl_accountID = "SELECT imei FROM userList WHERE accountID='%s'",
    select_group_id = "SELECT groupName, validity FROM groupInfo WHERE groupID='%s'",
    is_in_group = "SELECT 1 FROM userGroupInfo WHERE accountID='%s' AND groupID='%s' AND validity = 1",

    is_has_group = "SELECT 1 FROM userGroupInfo WHERE accountID='%s' AND groupType=2 AND validity=1 LIMIT 1",

    insert_group_activity_info = "INSERT INTO addGroupMemberInfo SET appKey=%s, accountID='%s', groupID='%s', memberStatus=%d, createTime=%d, feedbackURL='%s'",

}

local url_tab = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    safe.sign_check(args, url_tab)

    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    --> check groupID
    if not args['groupID'] or #args['groupID'] > 16 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupID')
    end

    local feedback_url  = args['feedbackURL']
    if feedback_url and ((#feedback_url > 512) or (not string.match(string.sub(feedback_url, 1, 4), 'http'))) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'feedbackURL')
    end

end

local function send_get(url)

    -- local data = string.format('accountID=%s&name=%s&operationType=%s', account_id, nick_name, operation_type)
    -- only.log('D',data)

    local send_back = {
        host = '',
        port = '',
        path = ''
    }
    send_back['host'] = string.match(url, 'http://([%w.]+):')
    send_back['port'] = string.match(url, ':(%d+)/')
    send_back['path'] = string.match(url, 'http://[%w.]+:%d+/(.+)')


    local get_data = utils.get_data(send_back.path, send_back )
    only.log('D', get_data)
    
    local ret = http_api.http(send_back, get_data, true)
    only.log('D', ret)
    if not ret then
        only.log('D',  'post eror')
        return
    end

end



local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_tab['client_host'] = ip
    url_tab['client_body'] = body

    if body == nil then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)
    url_tab['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)

    local account_id = args['accountID']
    local group_id = args['groupID']
    local feedback_url = args['feedbackURL']

    -- check accountID
    local sql = string.format(sql_fmt.sl_accountID, account_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
    if tonumber(result[1]['imei'])==0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_IMEI_HAS_NOT_BIND'])
    end

    -- check groupID
    sql = string.format(sql_fmt.select_group_id, group_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_GROUP_ID_NOT_EXIST'])
    end

    if tonumber(result[1]['validity'])==0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_GROUP_ID_UNUSABLE'])
    end

    local name = result[1]['groupName']

    -- 判断用户是否已加入车队
    sql = string.format(sql_fmt.is_in_group, account_id, group_id)
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    only.log('D', 'record:' .. #result)

    if #result ~= 0 then
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    end

    sql = string.format(sql_fmt.is_has_group, account_id)
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result ~= 0 then
        gosay.go_success(url_tab, msg['MSG_ERROR_GROUP_MEMBER_EXIST'])
    end


    local member_status, app_key = 6, args['appKey'] 
    local cur_time = os.time()

    sql = string.format(sql_fmt.insert_group_activity_info, app_key, account_id, group_id, member_status, cur_time, feedback_url or '')
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 

    if feedback_url and #feedback_url~=0 then
        send_get(feedback_url)
    end


    gosay.go_success(url_tab, msg['MSG_SUCCESS'])

end


safe.main_call( handle )
