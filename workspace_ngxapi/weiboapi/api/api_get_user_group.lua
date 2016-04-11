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

    sl_group = "SELECT groupID, roleType FROM userGroupInfo WHERE accountID='%s' AND validity=1",

    sl_group_name = "SELECT groupName,groupID,isCarFleet,FROM_UNIXTIME(createTime) as createTime FROM groupInfo WHERE groupID='%s'",

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

    safe.sign_check(args, url_tab)
    
end

local function get_group(args)

    local sql = string.format(sql_fmt.sl_group, args['accountID'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then 
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    local ret_tab = {}

    for k, v in pairs(result) do
        sql = string.format(sql_fmt.sl_group_name, v['groupID'])
        only.log('D', sql)
        local ok, res = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
        if ok and #res~=0 then
            res[1]['roleType'] = v['roleType']
            table.insert(ret_tab, res[1])
        end
    end

    local ok, val = utils.json_encode(ret_tab)
    return val
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

    local ret = get_group(args)
    
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)


end


safe.main_call( handle )
