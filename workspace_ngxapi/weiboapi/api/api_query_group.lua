
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
    sel_user = "SELECT 1 FROM userList WHERE accountID='%s' AND userStatus>3",
    sel_group = "SELECT groupID, groupName FROM groupInfo WHERE groupName LIKE '%%%s%%' AND isCarFleet=%d AND endTime=0",
    sel_header = "SELECT accountID FROM userGroupInfo WHERE groupID='%s' AND roleType=1",

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
    
    -- if not app_utils.check_accountID(args['accountID']) then
    --     gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    -- end

    if not args['groupName'] or #args['groupName'] > 30 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupName')
    end

    if args['groupType'] then
        args['groupType'] = tonumber(args['groupType'])
        if not args['groupType'] or not string.find('0,1,2', args['groupType']) then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupType')
        end
    end

    args['groupType'] = args['groupType'] or 1

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
    local name = args['groupName']

    -- local sql = string.format(sql_fmt.sel_user, account_id)
    -- only.log('D', sql)
    -- local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql) 
    -- if not ok then
    --     gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    -- end
    -- if #result==0 then
    --     gosay.go_false(url_tab, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    -- end

    local sql = string.format(sql_fmt.sel_group, name, args['groupType'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result==0 then
        local empty_array = '[]'
        gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], empty_array)
    end

    for i, v in ipairs(result) do
        sql = string.format(sql_fmt.sel_header, v['groupID'])
        only.log('D', sql)
        local ok, ret = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
        if ok and #ret~=0 then
            result[i]['header'] = ret[1]['accountID']
        else
            result[i]['header'] = ''
        end
    end

    local ok, json_ret = utils.json_encode(result)
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], json_ret)
end


safe.main_call( handle )
