
local ngx = require('ngx')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local gosay = require('gosay')
local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {

    sl_own_config = "SELECT model,call1,call2,domain,port,plusURL,plusPlusURL,customArgs FROM configInfo WHERE accountID='%s'",

    sl_basic_config = "SELECT call1, call2 FROM configInfo WHERE model='%s' AND accountID=''",

    ins_config_history = "INSERT INTO configInfoHistory(accountID,model,call1,call2,domain,port,plusURL,plusPlusURL,customArgs) values('%s','%s','%s','%s','%s',%d,'%s','%s','%s')",

    update_info = "UPDATE configInfo SET %s WHERE accountID='%s'",
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function chack_parameter(body)

    local res = utils.parse_url(body)
    url_info['app_key'] = res['appKey']

    --> check accountID
    if not app_utils.check_accountID(res['accountID']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
    end

    --> check  number_type --
    local allow_type = '0,1,4'
    if not string.find(allow_type, res['numberType'])  then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'number_type')
    end

    return res
end

-->update config
local function update_config(args, own_config)

    --从默认表中获取basicConfig
    local res_sql = string.format(sql_fmt.sl_basic_config, own_config['model'])
    only.log('D',  res_sql)
    local ok, result = mysql_pool_api.cmd("app_mirrtalk___config", 'select', res_sql )
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result == 0 then
        gosay.go_false(url_info, msg['MSG_ERROR_CONFIG_NOT_EXIST'])

    --> if config more than one record
    elseif #result > 1 then
        only.log('S', "the record of default config is more than one, call someone to handle")
        gosay.go_false(url_info, msg['MSG_ERROR_MORE_RECORD'],"default config")
    end

    local default_call1 = result[1]['call1']
    local default_call2 = result[1]['call2']

    local res_sql = string.format(sql_fmt.ins_config_history, args['accountID'], own_config['model'], own_config['call1'], own_config['call2'], own_config['domain'], own_config['port'], own_config['plusURL'], own_config['plusPlusURL'], own_config['customArgs'])
    only.log('D',  res_sql)
    local ok, result = mysql_pool_api.cmd("app_mirrtalk___config", 'insert', res_sql )


    local number_type = tonumber(args['numberType'])
    local sql_str
    -->numberType 等于 0 或 4, 将sos恢复为默认值
    if number_type == 0 then	
        sql_str = string.format("call1='%s',call2='%s'", default_call1, default_call2)
    elseif number_type == 1 then
        sql_str = string.format("call1='%s'", default_call1)
    else
        sql_str = string.format("call2='%s'", default_call2)
    end

    res_sql = string.format(sql_fmt.update_info, sql_str, args['accountID'])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd("app_mirrtalk___config", 'update', res_sql )
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    return true
end

local function handle()
    
    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()
    url_info['client_host'] = ip
    url_info['client_body'] = body
    
    if body == nil then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    -->check parameter
    local args = chack_parameter(body)

    --获取用户设置
    local res_sql = string.format(sql_fmt.sl_own_config, args['accountID'])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd("app_mirrtalk___config", 'select', res_sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result == 0 then
        gosay.go_false(url_info, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])

    --> if config more than one record
    elseif #result > 1 then
        only.log('S', string.format("the record of accountID:%s is more than one, call someone to handle", args['accountID']))
        gosay.go_false(url_info, msg['MSG_ERROR_MORE_RECORD'],"configInfo")
    end

    -->更新数据库
    update_config(args, result[1])

    gosay.go_success(url_info, msg['MSG_SUCCESS'])

end

safe.main_call( handle )
