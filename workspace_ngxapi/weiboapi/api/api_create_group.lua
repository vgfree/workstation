-->authore: zhangjl
-->time :2013-03-20
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path

local ngx = require('ngx')
local utils = require('utils')
local app_utils = require('app_utils')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local only = require('only')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {
    sl_user = "SELECT 1 FROM userList WHERE accountID='%s'",
    sl_group_name = "SELECT accountID,groupName FROM groupInfo WHERE groupName='%s' OR accountID='%s'",

    sl_member = "SELECT 1 FROM userGroupInfo WHERE accountID='%s' AND groupType=2 AND validity=1 LIMIT 1",

    sl_group_abbr = "SELECT 1 FROM groupInfo WHERE groupID='%s'",

    insert_group = "INSERT INTO groupInfo (accountID,groupName,groupID,isCarFleet,isTempGroup,createTime,updateTime,callbackURL) VALUES ('%s','%s','%s',%d,%d,%d,%d,'%s')",
    insert_user_info = "INSERT INTO addGroupMemberInfo (appKey,accountID,groupID,isCarMember,memberStatus, createTime) VALUES (%s,'%s','%s',%d,1,%d)",
    sl_user_record = "SELECT 1 FROM userGroupInfo WHERE accountID='%s' AND groupID!='mirrtalkAll' AND validity=1",
    insert_user = "INSERT INTO userGroupInfo (accountID,groupID,groupType,roleType,isDefaultGroup,createTime,updateTime) VALUES ('%s','%s',%d,1,%d,%d,%d)",

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

    if not args['groupName'] or #args['groupName']>32 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupName')
    end

    local callback_url  = args['callbackURL']
    if callback_url and ((#callback_url > 512) or (not string.match(string.sub(callback_url, 1, 4), 'http'))) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'callbackURL')
    end

    
    args['isCarFleet'] = tonumber(args['isCarFleet'])
    if args['isCarFleet'] and not string.find('0,1', args['isCarFleet']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'isCarFleet')
    end
    args['isCarFleet'] = args['isCarFleet'] or 1

    args['isTempGroup'] = tonumber(args['isTempGroup'])
    if args['isTempGroup'] and not string.find('0,1', args['isTempGroup']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'isTempGroup')
    end
    args['isTempGroup'] = args['isTempGroup'] or 0

    
end

local function get_group_id(tmp_group)
    local sql, ok, result, random_abbr
    local flag = 'p'
    if tmp_group == 1 then
        flag = 't'
    end
    while true do
        random_abbr = flag .. utils.random_string(15)
        sql = string.format(sql_fmt.sl_group_abbr, random_abbr)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
        if ok and #result==0 then
            return random_abbr
        end
    end
end

local function add_group(args)  

    local sql = string.format(sql_fmt.sl_user, args['accountID'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])
    end
    if #result==0 then
        only.log('E', string.format("the record of accountID:%s is zero", args['accountID']))
        gosay.go_false(url_tab, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    elseif #result > 1 then
        only.log('S', string.format("the record of accountID:%s is more than one, call someone to handle", args['accountID']))
        gosay.go_false(url_tab, msg["MSG_ERROR_MORE_RECORD"], 'accountID')
    end


    sql = string.format(sql_fmt.sl_group_name, args['groupName'], args['accountID'])
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql)

    if not ok then
        gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])
    end
    if #result~=0 then 
		if result[1]['groupName'] == args['groupName'] then
			gosay.go_false(url_tab, msg['MSG_ERROR_GROUP_EXIST'])
		else
			gosay.go_false(url_tab, msg['MSG_ERROR_NOT_ALLOW_CREATE_GROUP'])
		end
    end

    sql = string.format(sql_fmt.sl_member, args['accountID'])
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql)

    if not ok then
        gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result ~= 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_NOT_ALLOW_CREATE_GROUP'])
    end

    local cur_time = os.time()
    local group_id = get_group_id(args['isTempGroup'])
    sql = string.format(sql_fmt.insert_group, args['accountID'], args['groupName'], group_id, args['isCarFleet'], args['isTempGroup'], cur_time, cur_time, args['callbackURL'] or '')
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
    if not ok then
        gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])
    end

    sql = string.format(sql_fmt.insert_user_info, args['appKey'], args['accountID'], group_id, args['isCarFleet'], cur_time)
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
    if not ok then
        gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])
    end

    sql = string.format(sql_fmt.sl_user_record, args['accountID'])
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
    if not ok then
        gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])
    end

    local default_group
    if #result==0 then
        default_group = 1
    else
        default_group = 0
    end

    if args['isCarFleet'] then
        sql = string.format(sql_fmt.insert_user, args['accountID'], group_id, 2, default_group, cur_time, cur_time)
    else
        sql = string.format(sql_fmt.insert_user, args['accountID'], group_id, 1, default_group, cur_time, cur_time)
    end
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
    if not ok then
        gosay.go_false(url_tab, msg["MSG_DO_MYSQL_FAILED"])
    end


    if tonumber(args['isCarFleet']) == 1 then
        redis_pool_api.cmd('private', 'sadd', args['accountID'] .. ':carFleetSet', group_id)
    end

    if args['callbackURL'] then
        redis_pool_api.cmd('private', 'set', group_id .. ':groupCallbackURL', args['callbackURL'])
    end

    if default_group == 1 then
        redis_pool_api.cmd('private', 'set', args['accountID'] .. ':defaultGroup', group_id)
    end

    return string.format('{"groupID":"%s"}', group_id)
end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_tab['client_host'] = ip
    url_tab['client_body'] = body

    if body == nil then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    only.log('D', body)

    local args = utils.parse_url(body)
    url_tab['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)

    local ret = add_group(args)
    
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end


safe.main_call( handle )
