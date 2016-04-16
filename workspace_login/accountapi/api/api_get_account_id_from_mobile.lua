--> [author]: buyuanyuan
--> [time]: 2014-01-12
--> [company]: mirrtalk
--> zhouzhe 2015-08-17 修改
local ngx       = require('ngx')
local utils     = require('utils')
local only      = require('only')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local gosay     = require('gosay')
local msg       = require('msg')
local safe      = require('safe')

local sql_fmt = {
    sl_account_id_mobile = "SELECT accountID, mobile FROM userLoginInfo WHERE userStatus=1 AND mobile = '%s'"
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(body)
    local res = utils.parse_url(body)

    local mobile_tab = utils.str_split(res['mobile'], ',')
    if type(mobile_tab) ~= 'table' then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'mobile')
    end

    -->> check mobile
    for i=1, #mobile_tab do
        if(not utils.is_number(tonumber(mobile_tab[i]))) or (string.len(mobile_tab[i]) ~= 11) or (string.sub(tostring(mobile_tab[i]), 1, 1) ~= '1') then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'mobile')
        end
    end

    safe.sign_check(res, url_info)
    res['mobile'] = mobile_tab

    return res
end

local function get_nickname(a_id)
    local ok, name = redis_api.cmd('private', 'get', a_id .. ':nickname')
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"]) 
    end

    return name or ''
end

local function touch_db(mobile_tab)

    local tab = {}
    local sql
    for _, v in pairs(mobile_tab) do

        sql = string.format(sql_fmt.sl_account_id_mobile, v)
        only.log('D', sql)
        local ok, result = mysql_api.cmd('app_usercenter___usercenter', 'SELECT', sql)
        if not ok or #result == 0 then
            table.insert(tab, {mobile=v, accountID='', nickname=''})
        else
            local name = get_nickname(result[1]['accountID'])
            table.insert(tab, {mobile=v, accountID=result[1]['accountID'], nickname=name})
        end
    end

    local ok, ret = utils.json_encode(tab)

    return ret
end

function handle()

    local body = ngx.req.get_body_data()
    url_info['client_body'] = body
    url_info['client_host'] = ngx.var.remote_addr
    if not body or #body ==0 then
        only.log("E", "body is nil")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    -->>| STEP 1 |<<--
    -->> check parameter
    
    local res = check_parameter(body)
    url_info['app_key'] = res['appKey']
    -->>| STEP 2 |<<--
    -->> update database
    local ret = touch_db(res['mobile'])

    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end


safe.main_call( handle )

