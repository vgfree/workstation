
local ngx = require('ngx')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local gosay = require('gosay')
local only = require('only')
local utils = require('utils')
local app_utils = require('app_utils')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {

    sl_own_config = "SELECT model,call1,call2,domain,port,plusURL,plusPlusURL,customArgs FROM configInfo WHERE accountID='%s'",

    sl_imei = "SELECT imei FROM userList WHERE accountID='%s'",
    sl_model = "SELECT model FROM mirrtalkInfo WHERE imei='%s'",

    sl_default_config = "SELECT domain,port,customArgs FROM configInfo  WHERE model='%s' AND accountID=''",

    ins_config = "INSERT INTO configInfo(accountID,model,call1,call2,domain,port,plusURL,plusPlusURL,customArgs) values('%s','%s','%s','%s','%s',%d,'%s','%s','%s')",

    update_info = "UPDATE configInfo SET %s WHERE accountID='%s'",
    ins_config_history = "INSERT INTO configInfoHistory(accountID,model,call1,call2,domain,port,plusURL,plusPlusURL,customArgs) values('%s','%s','%s','%s','%s',%d,'%s','%s','%s')",

}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(body)

    local args = utils.parse_url(body)
    url_info['app_key'] = args['appKey']

    safe.sign_check(args, url_info)

    --> check accountID
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    --> check tweet_number --
    if args['call1Number'] and not utils.is_number(args['call1Number']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'call1Number')
    end

    --> check record_number--
    if args['call2Number'] and not utils.is_number(args['call2Number']) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'call2Number')
    end

    if not args['call1Number'] and not args['call2Number'] then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'call1Number or call2Number')
    end

    return args
end

--> get tsp_location
local function get_model(args)

    local res_sql = string.format(sql_fmt.sl_imei, args['accountID'])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd("app_usercenter___usercenter", 'select', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    if #result==0 or result[1]['imei']=='0' then
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_HAS_BIND"])
    end

    local imei = result[1]['imei']

    res_sql = string.format(sql_fmt.sl_model, imei)
    only.log('D', res_sql)
    ok, result = mysql_pool_api.cmd("app_ident___ident", 'select', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    if #result==0 then
        only.log('E', string.format("no record of imei:%s", imei))
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
    elseif #result>1 then
        only.log('S', string.format("the record of imei:%s is more than one, call someone to handle", imei))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'imei')
    end

    return result[1]['model']
end

-->insert info
local function update_basic_config(args, tab)
    if args['recordNumber'] then
        tab[1]['basicConfig'] = string.gsub(tab[1]['basicConfig'], "sos=%w+", string.format("sos=%s", args['recordNumber']))
    end

    --如果tweetNumber存在，就将tweetNumber替换callcenter的值
    if args['tweetNumber'] then
        tab[1]['basicConfig'] = string.gsub(tab[1]['basicConfig'], "callcenter=%w+", string.format("callcenter=%s", args['tweetNumber']))
    end
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
    local args = check_parameter(body)

    --> get basicConfig	
    local res_sql = string.format(sql_fmt.sl_own_config, args['accountID'])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd("app_mirrtalk___config", 'select', res_sql)
    if not ok  then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result > 1 then
        only.log('E', "more than one accountID record in configInfo")
        gosay.go_false(url_info, msg['MSG_ERROR_MORE_RECORD'], 'accountID')
    end

    if  #result == 0 then
        local model = get_model(args)

        -->从config表中获取默认设置信息
        res_sql = string.format(sql_fmt.sl_default_config, model)
        only.log('D', res_sql)
        ok, tab = mysql_pool_api.cmd("app_mirrtalk___config", 'select', res_sql )
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


        local sql = string.format(sql_fmt.ins_config, args['accountID'], model, args['call1Number'], args['call2Number'], tab['domain'], tab['port'], tab['plusURL'], tab['plusPlusURL'], tab['customArgs'])
        only.log('D',  sql)
        mysql_pool_api.cmd("app_mirrtalk___config", 'insert', sql )

        --> if config is one record
    else 

        local own_config = result[1]

        local res_sql = string.format(sql_fmt.ins_config_history, args['accountID'], own_config['model'], own_config['call1'], own_config['call2'], own_config['domain'], own_config['port'], own_config['plusURL'], own_config['plusPlusURL'], own_config['customArgs'])
        only.log('D',  res_sql)
        local ok, tab = mysql_pool_api.cmd("app_mirrtalk___config", 'insert', res_sql )

        local sql_str
        -->numberType 等于 0 或 4, 将sos恢复为默认值
        if args['call1Number'] then	
            sql_str = string.format("call1='%s'", args['call1Number'])
        end
        if args['call2Number'] then
            sql_str = string.format("%s,call2='%s'", sql_str, args['call2Number'])
        end

        res_sql = string.format(sql_fmt.update_info, sql_str, args['accountID'])
        only.log('D', res_sql)
        local ok, result = mysql_pool_api.cmd("app_mirrtalk___config", 'update', res_sql )
        if not ok then
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end

    end

    gosay.go_success(url_info, msg['MSG_SUCCESS'])
end


safe.main_call( handle )
