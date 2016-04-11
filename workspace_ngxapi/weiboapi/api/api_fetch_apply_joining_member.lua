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

    sel_group_id = "SELECT validity FROM groupInfo WHERE accountID='%s' AND groupID='%s'",

    sel_accountID = "SELECT DISTINCT accountID FROM addGroupMemberInfo WHERE groupID='%s' AND memberStatus=6",

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

end

local function get_nickname(a_id)

    local ok, nickname = redis_pool_api.cmd('private', 'get', a_id .. ':nickname')
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end

    return nickname or ''

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

    -- check groupID
    sql = string.format(sql_fmt.sel_group_id, account_id, group_id)
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

    local sql = string.format(sql_fmt.sel_accountID, group_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql)
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    local ok, ret
    if #result == 0 then
        ret = '[ ]'
    else
        local tab = {}
        for i, v in ipairs(result) do
            local name = get_nickname(v['accountID'])
            table.insert(tab, { accountID = v['accountID'], name = name })
        end
        ok, ret = utils.json_encode(tab)
    end

    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end


safe.main_call( handle )
