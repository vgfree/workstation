-->[ower]: baoxue
-->[time]: 2013-12-31

local ngx = require("ngx")
local cfg = require('config')
local utils = require('utils')
local only = require('only')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api = require('http_short_api')
local gosay = require('gosay')
local msg = require('msg')
local app = require('app')

local link = require('link')
weibo_server = link["OWN_DIED"]["http"]["sendPersonalWeibo"]

local sql_fmt = {
    get_verify_code = [[SELECT verificationCode,UNIX_TIMESTAMP(createTime) FROM mirrtalkNumberVerificationCode WHERE mirrtalkNumber='%s' AND accountID='%s']],
    put_verifyCode = [[INSERT INTO mirrtalkNumberVerificationCode SET mirrtalkNumber='%s', accountID='%s', createTime=%d, verificationCode='%s']],
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(body)

    local res = utils.parse_url(body)

    -->> bad request
    if type(res) ~= 'table' then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'client body')
    end

    url_info['app_key'] = res['appKey']

    -->> check accountID
    if not utils.check_accountID(res["accountID"]) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    -->> check mirrtalkNumber
    if (not utils.is_number(res["mirrtalkNumber"])) or (#res["mirrtalkNumber"] ~= 11) 
            or (string.sub(res["mirrtalkNumber"], 1, 1) ~= "1") then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'mirrtalkNumber')
    end
    -->> check imei
    if (not utils.is_number(res["IMEI"])) or #res["IMEI"] ~= 15 or tonumber(string.sub(res["IMEI"],1,1)) == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'imei')
    end

    app.new_safe_check(res, url_info)

    return res
end

local function check_power_on( args )

    local ok, newstatus_timestamp = redis_pool_api.cmd('private', 'get',args['IMEI'] .. ':heartbeatTimestamp')
    local cur_time = os.time()

    if not newstatus_timestamp or (cur_time - tonumber(newstatus_timestamp) > cfg['user_online_space']) then
        gosay.go_false(url_info, msg["MSG_ERROR_NO_POWER_ON"])
    end

end

local function send_system_weibo(T, args)

    local wb = {
        ["appKey"] = args["appKey"],
        ["text"] = T["text"],
        ["receiverAccountID"] = args["accountID"],
        ["interval"] = T["interval"],
        ["level"] = 10,
    }

    local ok, secret = redis_pool_api.cmd("public", "get", args["appKey"] .. ':secret')
    if not ok or secret == nil then
        return false
    end

    local sign = utils.gen_sign(wb, secret)
    wb["sign"] = sign
    wb["text"] = utils.url_encode(wb["text"])

    local post_body = utils.format_http_form_data(wb, '__mirrtalk_captcha_bdy__')
    local post_fmt = 'POST /v2/sendTTSPersonalWeibo HTTP/1.0\r\n' ..
    'HOST:%s:%s\r\n' ..
    'Content-Length:%s\r\n' ..
    'Content-Type:content-type:multipart/form-data;boundary=__mirrtalk_captcha_bdy__\r\n\r\n%s'

    local post_data = string.format(post_fmt, weibo_server['host'], weibo_server['port'], #post_body, post_body)

    only.log('D',post_data)
    local ret = http_api.http(weibo_server, post_data, #post_data, true)
    only.log('D', ret)

    local body = string.match(ret, '{.*}')
    local status, jo = utils.json_decode(body)
    if not status or tonumber(jo['ERRORCODE'])~=0 then
        return false
    end 

    return true

end

local function get_mirrtalk_captcha( args )

    local verificationCode, save_verificationCode
    local tab_code = {}

    -->> get verificationCode from mysql
    local res_sql = string.format(sql_fmt.get_verify_code, args["mirrtalkNumber"], args['accountID'])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd('app_daokeme___daokeme', 'SELECT', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result~=0 and (os.time() - tonumber(result[1]["UNIX_TIMESTAMP(createTime)"])) < cfg["verificationCode_timeout"] then
        verificationCode = result[1]["verificationCode"]
        tab_code[1] = string.sub(verificationCode, 1, 1)
        tab_code[2] = string.sub(verificationCode, 2, 2)
        tab_code[3] = string.sub(verificationCode, 3, 3)
        tab_code[4] = string.sub(verificationCode, 4, 4)
    else
        -->> create verificationCode
        while true do
            verificationCode = utils.random_singly()
            if verificationCode ~= 0 then
                break
            end
        end

        tab_code[1] = verificationCode
        tab_code[2] = utils.random_singly()
        tab_code[3] = utils.random_singly()
        tab_code[4] = utils.random_singly()
        verificationCode = table.concat( tab_code )
    end
    save_verificationCode = table.concat( tab_code, "。")

    -->> send weibo
    local finish = send_system_weibo({text="道客暗号，" .. save_verificationCode .. "，道客暗号，" .. save_verificationCode .. "，道客暗号，" .. save_verificationCode,interval=120}, args)
    if not finish then
        gosay.go_false(url_info, msg["MSG_DO_HTTP_FAILED"])
    end

    -->> save verificationCode
    local cur_time = os.time()
    local sql = string.format(sql_fmt.put_verifyCode, args["mirrtalkNumber"], args['accountID'], cur_time, verificationCode)
    only.log('D', sql)
    local ok, ret = mysql_pool_api.cmd('app_daokeme___daokeme', 'SELECT', sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

end

function handle()
    local body = ngx.req.get_body_data()

    url_info['client_body'] = body
    url_info['client_host'] = ngx.var.remote_addr

    only.log('D', string.format("\r\n%s", body))

    -->| STEP 1 |<--
    -->> check parameters
    local res = check_parameter(body)

    -->| STEP 2 |<--
    check_power_on( res )

    -->| STEP 4 |<--
    -->> send verificationCode
    get_mirrtalk_captcha( res )

    gosay.go_success(url_info, msg["MSG_SUCCESS"])
end

handle()
