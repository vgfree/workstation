--
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

    sel_group = "SELECT id,accountID,groupID,groupType,roleType,isDefaultGroup,validity,updateTime FROM userGroupInfo WHERE accountID='%s' AND validity=1 AND (isDefaultGroup=1 OR groupID='%s')",

    ins_history = "INSERT INTO userGroupHistoryInfo SET accountID='%s',groupID='%s',groupType=%s,roleType=%s,isDefaultGroup=%s,validity=%s,updateTime=%s",

    upd_group = "UPDATE userGroupInfo SET isDefaultGroup=%d, updateTime=%d WHERE id=%d",

}

local url_tab = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    if not args['groupID'] or #args['groupID']>16 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupID')
    end

    safe.sign_check(args, url_tab)
    
end

local function update_group(args, res1, res2)

    local cur_time = os.time()
    local sql = string.format(sql_fmt.ins_history, res1['accountID'], res1['groupID'], res1['groupType'], res1['roleType'], res1['isDefaultGroup'], res1['validity'], res1['updateTime'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
    if not ok then 
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    sql = string.format(sql_fmt.upd_group, 1, cur_time, res1['id'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'update', sql) 
    if not ok then 
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    redis_pool_api.cmd('private', 'set', args['accountID'] .. ':defaultGroup', args['groupID'])
    if not ok then 
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end

    if res2 then

        sql = string.format(sql_fmt.ins_history, res1['accountID'], res1['groupID'], res1['groupType'], res1['roleType'], res1['isDefaultGroup'], res1['validity'], res1['updateTime'])
        only.log('D', sql)
        local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
        if not ok then 
            gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        end

        sql = string.format(sql_fmt.upd_group, 0, cur_time, res2['id'])
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'update', sql) 
        if not ok then 
            gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        end
    end

end

local function set_group(args)

    local sql = string.format(sql_fmt.sel_group, args['accountID'], args['groupID'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then 
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_CODE_USER_NO_GROUP'])
    elseif #result==1 then
        if result[1]['groupID']~=args['groupID'] then
            gosay.go_false(url_tab, msg['MSG_ERROR_CODE_USER_NO_GROUP'])
        elseif tonumber(result[1]['isDefaultGroup'])==1 then
            gosay.go_success(url_tab, msg['MSG_SUCCESS'])
        else
            update_group(args, result[1])
        end
    elseif #result == 2 then
        if result[1]['groupID'] == result[1]['groupID'] then
            only.log('S', string.format("the record of accountID:%s,groupID is more than one, call someone to handle", args['accountID'], args['groupID']))
        elseif result[1]['groupID']== args['groupID'] then
            if tonumber(result[1]['isDefaultGroup'])==1 then
                gosay.go_success(url_tab, msg['MSG_SUCCESS'])
            else
                update_group(args, result[1], result[2])
            end
        elseif result[2]['groupID'] == args['groupID'] then
            if tonumber(result[2]['isDefaultGroup'])==1 then
                gosay.go_success(url_tab, msg['MSG_SUCCESS'])
            else
                update_group(args, result[1], result[2])
            end
        end
    else
        only.log('S', string.format("the record of accountID:%s,groupID is more than one, call someone to handle", args['accountID'], args['groupID']))
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

    set_group(args)
    
    gosay.go_success(url_tab, msg['MSG_SUCCESS'])


end


safe.main_call( handle )
