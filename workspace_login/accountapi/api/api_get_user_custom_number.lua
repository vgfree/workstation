
local ngx = require('ngx')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local app_utils = require('app_utils')
local safe = require('safe')

local sql_fmt = {

    sl_user_config = "SELECT call1,call2,model FROM configInfo WHERE accountID='%s'",
    sl_default_config = "SELECT call1,call2 FROM configInfo WHERE accountID='' AND model='%s'",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}


local function func(a_id, number_type)

    local sql = string.format(sql_fmt.sl_user_config, a_id)
    only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_mirrtalk___config', 'select', sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    elseif #res > 1 then
        only.log('D', string.format('too many record of accountID:%s in config.configInfo', a_id))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'accountID')
    end

    local model = res[1]['model']
    local call1 = res[1]['call1']
    local call2 = res[1]['call2']

    sql = string.format(sql_fmt.sl_default_config, model)
    only.log('D', sql)
    ok, res = mysql_pool_api.cmd('app_mirrtalk___config', 'select', sql)

    local default_call1 = res[1]['call1']
    local default_call2 = res[1]['call2']

    if call1 == default_call1  then
        call1 = 0
    end
    if call2 == default_call2  then
        call2 = 0
    end

    local ret
    if number_type == 1 then
        ret = string.format('{"call1Number":"%s"}', call1)
    elseif number_type == 4 then
        ret = string.format('{"call2Number":"%s"}', call2)
    else
        ret = string.format('{"call1Number":"%s","call2Number":"%s"}', call1, call2)
    end

    return ret
end

local function parse_body(str)

    local args = utils.parse_url(str)
    url_info['app_key'] = args['appKey']

    safe.sign_check(args, url_info)

    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
    end

    local type_range = '0,1,4'
    if not (args['numberType'] and string.find(type_range, args['numberType'])) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "numberType")
    end

    return args
end

local function handle()

    local pool_body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    url_info['client_host'] = ip
    url_info['client_body'] = body

    local handle_body = parse_body(pool_body)

    local ret = func(handle_body['accountID'], tonumber(handle_body['numberType']))

    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end

safe.main_call( handle )
