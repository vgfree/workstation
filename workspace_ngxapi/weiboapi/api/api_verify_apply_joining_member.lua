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

    sel_group_id = "SELECT validity, isCarFleet FROM groupInfo WHERE groupID='%s'",

    sl_accountID = "SELECT accountID FROM addGroupMemberInfo WHERE groupID='%s' AND memberStatus=6",

    upd_account = "UPDATE addGroupMemberInfo SET memberStatus=%d,yes=%d,yesTime=%d,yesCallbackURL='%s' WHERE accountID='%s' AND groupID='%s'",

    sel_user_group = "SELECT groupType,roleType,isDefaultGroup,validity,updateTime FROM userGroupInfo WHERE accountID = '%s' AND groupID= '%s'",

    ins_history = "INSERT INTO userGroupHistoryInfo SET accountID='%s',groupID='%s',groupType=%s,roleType=%s,isDefaultGroup=%s,validity=%s,updateTime=%s",

    upd_user_group = "UPDATE userGroupInfo SET validity=1, isDefaultGroup=%d,updateTime=%d WHERE accountID = '%s' AND groupID= '%s'",

    ins_user_group = "INSERT INTO userGroupInfo SET validity=1,isDefaultGroup=%d,accountID='%s', groupID='%s',groupType=%d,createTime=%d,updateTime=%d",
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

    if not app_utils.check_accountID(args['creatorAccountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    --> check groupID
    if not args['groupID'] or #args['groupID'] > 16 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupID')
    end

    args['yes'] = tonumber(args['yes'])
    if not args['yes'] or not string.find('0,1', args['yes']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'yes')
    end

    args['account_tab'] = utils.str_split(args['applyAccountID'], ',')

    if type(args['account_tab']) ~= 'table' or #args['account_tab']==0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyAccountID')
    end

    for i, v in ipairs(args['account_tab']) do
        if not app_utils.check_accountID(v) then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyAccountID')
        end
    end

    local callback_url  = args['callbackURL']
    if callback_url and ((#callback_url > 512) or (not string.match(string.sub(callback_url, 1, 4), 'http'))) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'callbackURL')
    end

end


local function update_user_group(account_id, group_id, is_car_fleet )

    sql = string.format(sql_fmt.sel_user_group, account_id, group_id)
    only.log('D', sql) 
    ok, res = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql)
    if not ok then
        only.log('E', res)
    end

    local user_group_info = res[1]

    local has_default_group, group_type = 0, 1
    local ok, default_group = redis_pool_api.cmd('private', 'get', account_id .. ':defaultGroup')
    ---- modify by jiang z.s. 2014-05-01 
    if ok and default_group and default_group ~= 'mirrtalkAll'  then
        has_default_group = 1
    end


    if #res==1 and tonumber(res[1]['groupType'])==2 then
        group_type = 1
    end

    local is_default_group = 1 - has_default_group

    local cur_time = os.time()
    if #res == 1 then

        -- insert the old information into history
        sql = string.format(sql_fmt.ins_history, account_id, group_id, user_group_info['groupType'], user_group_info['roleType'], user_group_info['isDefaultGroup'], user_group_info['validity'], user_group_info['updateTime'])
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
        if not ok then
            gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        end

        sql = string.format(sql_fmt.upd_user_group, is_default_group, cur_time, account_id, group_id)
        only.log('D', sql) 
        ok, res = mysql_pool_api.cmd('app_weibo___weibo', 'update', sql)
        if not ok  then
            only.log('D', res)
        end 
    else
        sql = string.format(sql_fmt.ins_user_group, is_default_group, account_id, group_id, group_type, cur_time, cur_time)
        only.log('D', sql) 
        ok, res = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql)
        if not ok  then
            only.log('D', res)
        end 
    end

    if has_default_group == 0 then
        redis_pool_api.cmd('private', 'set', account_id .. ':defaultGroup', group_id)
    end

    if is_car_fleet == 1 then
        redis_pool_api.cmd('private','sadd', account_id .. ':carFleetSet', group_id)
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

    local group_id = args['groupID']
    local callback_url = args['callbackURL']

    -- check groupID
    sql = string.format(sql_fmt.sel_group_id, group_id)
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

    local is_car_fleet = tonumber(result[1]['isCarFleet'])

    -- select the applying status member
    local sql = string.format(sql_fmt.sl_accountID, group_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql)
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    local tab = {}
    if #result ~= 0 then
        for i, v in ipairs(result) do
            table.insert(tab, v['accountID'])
        end
    end

    local tab_str = table.concat(tab, ',')
    local ret_tab = {}
    local valid_account_tab = {}

    for _, v in pairs(args['account_tab']) do
        if not string.find(tab_str, v) then
            table.insert(ret_tab, {accountID=v, status=-1})
        else
            table.insert(ret_tab, {accountID=v, status=0})
            table.insert(valid_account_tab, v)
        end
    end

    local status, yes, yes_time = 7, args['yes'], os.time()
    if args['yes'] == 0 then
        status = 8
    end


    for _, v in ipairs(valid_account_tab) do

        local sql = string.format(sql_fmt.upd_account, status, yes, yes_time, callback_url or '', v, group_id)
        only.log('D', sql)
        local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql)
        if not ok then
            gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        end

        update_user_group(v, group_id, is_car_fleet )

    end

    if callback_url and #callback_url~=0 then
        send_get(callback_url)
    end

    local ok, ret = utils.json_encode(ret_tab)

    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end


safe.main_call( handle )
