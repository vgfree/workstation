-- send user email verification.lua
-- author: zhangjl (jayzh1010@gmail.com) -- company: mirrtalk.com

-- local inc_path = '../conf/?.lua;../public/?.lua;../lib/?.lua;'
-- local inc_cpath = '../lib/?.so;'
-- package.path = inc_path .. package.path
-- package.cpath = inc_cpath .. package.cpath

local cfg = require 'config'
local ngx = require('ngx')
local msg = require('msg')
local gosay = require('gosay')
local http_api = require('http_short_api')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local safe = require('safe')

local link = require('link')
local email_srv = link["OWN_DIED"]["http"]["sendEmail"]

local sql_fmt = {

    sl_verify_code = "SELECT verificationCode, UNIX_TIMESTAMP(createTime) AS time FROM emailVerificationCode WHERE userEmail='%s' ORDER BY createTime DESC LIMIT 1",

    insert_verify_code = "INSERT INTO emailVerificationCode values(null, '%s', %d, '%s')",
    nil,
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function func(body)

    local verification_code, time_validity
    local sql = string.format(sql_fmt.sl_verify_code, body.userEmail)
    only.log('D', sql)
    local ok, ret = mysql_pool_api.cmd('app_daokeme___daokeme', 'select', sql)

    if ok and #ret ~= 0 then
        time_validity = os.time() - ret[1]['time'] - cfg.email_verify_time
    else
        time_validity = 1 -- to make the time_validity > 0, create and insert code
    end

    local cur_time = os.time()
    if tonumber(time_validity) > 0 then
        verification_code = utils.random_string(20)
        sql = string.format(sql_fmt.insert_verify_code, verification_code, cur_time, body.userEmail)
        only.log('D', sql)
        mysql_pool_api.cmd('app_daokeme___daokeme', 'insert', sql)
    else
        verification_code = ret[1]['verificationCode']
    end

    body['URL']= body['URL'] .. '&verificationCode=' .. verification_code
    body['content'] = body['content'] .. ':' .. body['URL']
    local subject = '帐户激活'

    local tbl = {
        ['content'] = body['content'],
        ['emailAddress'] = body['userEmail'],
        ['subject'] = subject,
        ['appKey'] = body['appKey'],
    }

    tbl['sign'] = app_utils.gen_sign(tbl)


    local http_body = string.format('{ "appKey":"%s", "emailAddress":"%s", "content":"%s", "subject":"%s", "sign":"%s"}', 
                            body['appKey'], 
                            body['userEmail'], 
                            utils.url_encode(body['content']), 
                            utils.url_encode(subject), 
                            tbl['sign'])

    local data_fmt = 
    'POST /sendEmail.json HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Type:application/json\r\n' ..
    'Content-Length:%s\r\n\r\n%s'

    local data = string.format(data_fmt, email_srv['host'], email_srv['port'], #http_body, http_body)
    local ret = http_api.http(email_srv, data, true)
    if not ret then
        only.log('E', string.format("http request sendEmail.json failed! %s " , body.userEmail ) )
        return nil
    end
    local ret = string.match(ret, '{.*}')
    if not ret then
        only.log('E', string.format("sendEmail.json get ret failed! %s " , body.userEmail ) )
        return nil
    end

    local ok, json_body = utils.json_decode(ret)
    if not ok or tonumber(json_body['ERRORCODE']) ~= 0 then
        return nil
    end

    return true
end

local function is_alpha_digit(str)
    if not str then return false end
    local ret = string.find(str, '^%w+$')
    return ret
end

local function check_email(email)
    if email==nil then return false end
    if string.find(email, '@') == nil then
        return false
    end
    return true
end

local function parse_body(str)

    local args = utils.parse_url(str)
    url_info['app_key'] = args['appKey']

    local email = args['userEmail']
    if (check_email(email) ~= true) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail")
    end

    local url= args['URL']
    if not url  then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "URL")
    end

    local content= args['content'] or ''

    safe.sign_check(args, url_info)

    return args
end

local function handle()

    local body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    url_info['client_host'] = ip
    url_info['client_body'] = body

    local handle_body = parse_body(body)

    local ret = func(handle_body)

    if not ret then
        gosay.go_false(url_info, msg["MSG_DO_HTTP_FAILED"])
    else
        gosay.go_success(url_info, msg["MSG_SUCCESS"])
    end

end


safe.main_call( handle )

-- EOF
