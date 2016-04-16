
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api = require('http_short_api')
local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local gosay = require('gosay')
local ngx = require('ngx')
local cfg = require('config')
local msg = require('msg')
local safe = require('safe')
local link = require('link')
local sms_srv = link["OWN_DIED"]["http"]["sendSMS"]


local sql_fmt = {
    get_code = "SELECT verificationCode FROM mobileVerificationCode WHERE mobile = '%s' AND createTime >= %d ORDER BY createTime DESC",
    insert_code = "INSERT INTO mobileVerificationCode VALUES('', '%s', %d, '%s')",
    count = "SELECT count(1) as cnt FROM userRegisterInfo WHERE mobile='%s' AND validity=1"
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function get_code(mobile)

    local valid_time = os.time() - cfg.mobile_verify_time/60
    local sql = string.format(sql_fmt.get_code, mobile, valid_time)
    only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_daokeme___daokeme','select', sql)
    if ok and #res~=0 then
        return res[1]['verificationCode']
    end
--[[
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    local code = tostring(math.random(0, 9))
    while code == '0' do
        code = tostring(math.random(0, 9))
    end
    for i = 1, 15 do
        code = code .. tostring(math.random(0, 9))
    end
    local code = string.sub(code, 1, 4)
--]]

	local code = utils.random_number(4)

	while string.sub(code,1,1) == '0' do
		code = utils.random_number(4)
	end

    local cur_time = os.time()
    local sql = string.format(sql_fmt.insert_code, code, cur_time, mobile)
    only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_daokeme___daokeme', 'insert', sql)
    if not ok then
        only.log('E', "failed to insert into daokeme")
    end

    return code
end

local function get_mobile_count(mobile)

    local sql = string.format(sql_fmt.count, mobile)
    only.log('D',sql)
    local ok, res = mysql_pool_api.cmd('app_usercenter___usercenter','select', sql)
    if ok and #res~=0 then
        return res[1]['cnt']
    end
    return 0
end

local function send_sms(content)

    local data_fmt = 'POST /webapi/v2/sendSms HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Length:%d\r\n' ..
    'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv['host'], sms_srv['port'], #content, content)

    only.log('D',"data : " .. data)

    local ret = http_api.http(sms_srv, data, true)

    if not ret then return nil end

    only.log('D',"ret : " .. ret)

    local body = string.match(ret, '{.+}')

    local ok, json_data = utils.json_decode(body)

    if not ok or tonumber(json_data['ERRORCODE'])~=0 then
        return nil
    else
        return json_data['RESULT']['bizid']
    end

end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_body'] = body
    url_info['client_host'] = ngx.var.remote_addr

    local res = utils.parse_url(body)
    if not res or type(res) ~= 'table' then
	    gosay.go_false(url_info,msg['MSG_ERROR_REQ_BAD_JSON'])
    end

    if not res['appKey'] then
	    gosay.go_false('D',msg['MSG_ERROR_REQ_FAILED_GET_SECRET'])
    end

    url_info['app_key'] = res['appKey']

    --check mobile--
    local mobile = res['mobile']
    if mobile == nil or (string.len(mobile) ~= 11) or (not utils.is_number(mobile)) or (utils.is_number(string.sub(mobile, 1, 1)) ~= 1) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
    end

    safe.sign_check(res, url_info)

    only.log("D",mobile)

    local content_text = res['content']
    if not content_text then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'content')
    end

    local ok, secret = redis_pool_api.cmd("public", "hget", res["appKey"] .. ':appKeyInfo', 'secret')

    local code = get_code(mobile)

    local count = get_mobile_count(mobile)

    local txt = string.gsub(content_text, '%[code%]', code)

    --local content = string.format('{"mobile":"%s", "text":"验证码:%s。请在30分钟内使用!", "agent":"%s", "serviceType":"%s"}', mobile, code, agent, serv_type)
    local tbl = {
        ['mobile'] = mobile,
        ['content'] = txt,
        ['appKey'] = res['appKey'],
    }

    tbl['sign'] = app_utils.gen_sign(tbl, secret)

    local content = string.format('mobile=%s&content=%s&appKey=%s&sign=%s', mobile, txt, tbl['appKey'], tbl['sign'])

    local bizid = send_sms(content)
    if not bizid then
        gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
    end 
    local ret_body = string.format('{"bizid":"%s","mobile":"%s","verificationCode":"%s","mobileCount":%d}', bizid, mobile, code, count)
        
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_body)
end


safe.main_call( handle )
