----author: Liuyongheng
----date: 2015-05-25
----remark: 用户获取手机重置验证码
---- 2015-07-09切换到前端封装的云通信接口 zhouzhe

local utils     = require('utils')
local app_utils = require('app_utils')
local only      = require('only')
local gosay     = require('gosay')
local ngx       = require('ngx')
local cfg       = require('config')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cutils     = require('cutils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local http_api  = require('http_short_api')

local sms_srv_normal   = link["OWN_DIED"]["http"]["sendSMS"]
local sms_srv_php   = link["OWN_DIED"]["http"]["sendSmsPHP"]

local user_dbname  = "app_usercenter___usercenter"

local cur_sms_env = 1 

local send_sms_func
-- local send_sms_func = 
-- {
--     send_sms_normal ,
--     send_sms_php,
-- }


-- 模板id
local templateID = 21109

local G = {
    --获取上次发送验证码的时间和验证码
    sel_send_freq = "select verificationCode,updateTime from mobileResetPwdVerifyCode where mobile = '%s'  ",
    --插入密码重置验证码数据
    ins_verify_info = "insert into mobileResetPwdVerifyCode (verificationCode, createTime, updateTime, mobile, useState) " .. 
                                        " values('%s', %d, %d, '%s', %d) ",
    --更新密码重置数据
    update_verify_code = "update mobileResetPwdVerifyCode set verificationCode = '%s', updateTime= %d, useState = %d  where mobile = '%s'  ",
    --检查用户输入的手机号
    sel_check_mobile = "select 1 from userRegisterInfo where mobile = '%s' and validity = 1",
}


local url_info = {
    type_name   = 'system',
    app_key     = nil,
    client_host = nil,
    client_body = nil,
}

--验证码数字长度
local verify_code_length     = '6'

--验证码有效时间（单位:分钟）
local verify_code_valid_time = '10'

--验证码使用情况(1:未使用;2:已使用)
--验证码初始状态
local verify_code_init_state = 1


local function check_parameter( args )

    local mobile = args['mobile']

    if not mobile then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
    end
    if not utils.is_number(mobile) or  string.sub(mobile, 1, 1) ~= '1' or #mobile ~= 11 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
    end

    safe.sign_check(args, url_info)
end

local function check_mobile( mobile )

    -- mobile = tonumber(mobile)
    local sql_str = string.format(G.sel_check_mobile, mobile)
    local ok_status, result_tab = mysql_api.cmd(user_dbname, 'SELECT', sql_str)
    
    if not ok_status or not result_tab then
        only.log('E', string.format('conect db [%s] failed', user_dbname))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    --表明以该手机号码注册的道客账户不存在
    if #result_tab == 0 then
        -- gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'This phone number is not registered!')
        gosay.go_false(url_info, msg['MSG_ERROR_USER_NAME_NOT_EXIST'])
    end

    if #result_tab > 1 then
        only.log('E', string.format('[***] userRegisterInfo mobile recordset >1  [sql][%s]', sql_str))
        gosay.go_false(url_info, msg['SYSTEM_ERROR'])
    end
end


local function check_last_send_info(mobile)

    local record_flag = 0
    -- mobile = tonumber(mobile)
    local sql_str = string.format(G.sel_send_freq, mobile)
    local ok_status, result_tab = mysql_api.cmd(user_dbname, 'SELECT', sql_str)
    
    if not ok_status or not result_tab then
        only.log('E', string.format('conect db [%s] failed', user_dbname))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    --表示第一次验证，表中还未有相应验证
    --#result_tab == 0 

    if #result_tab > 1 then
        only.log('E', string.format('[***] mobileResetPwdVerifyCode verifyCode recordset >1  [sql][%s]', sql_str))
        gosay.go_false(url_info, msg['SYSTEM_ERROR'])
    end

    --待校验发送验证码频次(2015/05/26)
    if #result_tab == 1 then
        record_flag = 1
    -- local update_time = result_tab[1]['updateTime']
    -- local cur_time = os.time()
    end

    return record_flag
end

local function generate_verify_code()

    local code = utils.random_number(verify_code_length)

    while string.sub(code,1,1) == '0' do
        code = utils.random_number(verify_code_length)
    end

    return code

end

local function get_secret( args)

    local ok_status, secret = redis_api.cmd("public", "hget", args["appKey"] .. ':appKeyInfo', 'secret')
    if not ok_status then
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end

    return secret
end

local function insert_verify_code_info(verify_code, mobile)

    local cur_time = os.time()
    local sql_str = string.format(G.ins_verify_info, tostring(verify_code), cur_time, cur_time, mobile, verify_code_init_state)
    local ok_status = mysql_api.cmd(user_dbname, 'INSERT', sql_str)
    
    if not ok_status then
        only.log('E', string.format('conect db [%s] failed', user_dbname))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
end

local function update_verify_code_info( verify_code, mobile )

    local cur_time  = os.time()
    local sql_str   = string.format(G.update_verify_code, tostring(verify_code), cur_time, verify_code_init_state, mobile )
    local ok_status = mysql_api.cmd(user_dbname, 'UPDATE', sql_str)
    
    if not ok_status then
        only.log('E', string.format('conect db [%s] failed [SQL][%s]', user_dbname, sql_str))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end    
    
end

local function send_sms_normal(args , verify_code)

    local text = string.format("验证码%s,有效期10分钟",verify_code)

    local send_table = {
        ['mobile']  = args['mobile'],
        ['content'] = text,
        ['appKey']  = args['appKey'],
    }

    send_table['sign'] = app_utils.gen_sign(send_table, secret)

    local send_text_fmt = 'mobile=%s&content=%s&appKey=%s&sign=%s'

    local content = string.format(send_text_fmt, send_table['mobile'], text, send_table['appKey'], send_table['sign'])
    -- local content = string.format("验证码%s,有效期10分钟",verify_code)

    local data_fmt = 'POST /webapi/v2/sendSms HTTP/1.0\r\n' ..
                'Host:%s:%s\r\n' ..
                'Content-Length:%d\r\n' ..
                'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv_normal['host'], sms_srv_normal['port'], #content, content)

    only.log('D',"[in mobile reset pwd]data : " .. data)

    local ret = http_api.http(sms_srv_normal, data, true)

    if not ret then return nil end

    only.log('D',"[in mobile reset pwd]ret : " .. ret)

    local body = string.match(ret, '{.+}')

    local ok, json_data = utils.json_decode(body)

    if not ok or tonumber(json_data['ERRORCODE'])~=0 then
        only.log('D', string.format('====%s====%s====', ok, json_data['ERRORCODE']))

        return nil
    else

        return json_data['RESULT']['bizid']
    end
end

-- local function send_verify_code( args)

--     local verify_code = generate_verify_code()
--     local secret = get_secret(args)

--     local text_fmt = "密码重置验证码:%s。请在%s分钟内使用!"
--     local text = string.format(text_fmt, verify_code, verify_code_valid_time)

--     local send_table = {
--         ['mobile']  = args['mobile'],
--         ['content'] = text,
--         ['appKey']  = args['appKey'],
--     }

--     send_table['sign'] = app_utils.gen_sign(send_table, secret)

--     local send_text_fmt = 'mobile=%s&content=%s&appKey=%s&sign=%s'
--     local content = string.format(send_text_fmt, send_table['mobile'], text, send_table['appKey'], send_table['sign'])

--     local bizid = send_sms(content)

--     return bizid, verify_code

-- end

local function send_sms_php(args , verify_code)

    local send_text_fmt = 'phone=%s&code=%s&time=%s&templateID=%d'
    local content = string.format(send_text_fmt, args['mobile'], verify_code, verify_code_valid_time,templateID)

    local data_fmt = 'POST /sendSMS/index.php HTTP/1.0\r\n' ..
                        'Host:%s:%s\r\n' ..
                        'Content-Length:%d\r\n' ..
                        'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv_php['host'], sms_srv_php['port'], #content, content)

    local ok,ret = cutils.http(sms_srv_php['host'], sms_srv_php['port'], data, #data)
    if not ok then
        only.log("E", "sendSms filed")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "sendSms")
    end

    if not ret then
        only.log('E',string.format("return data: %s",data))
        return false
    end

    local body = string.match(ret, '{.+}')
    if not body then
        only.log('E',string.format('==ret: %s ' , ret  ) )
        return false
    end
    local ok, json_data = utils.json_decode(body)
    only.log('D',string.format('ERRORCODE  = %s ', json_data['ERRORCODE']))

    if not ok or tonumber(json_data['ERRORCODE'])~= 0 then
        return false
    elseif tonumber(json_data['ERRORCODE']) == 160021 then
        only.log("W", "Same content in the same cell phone can only be issued once")
        return false
    else
        return true
    end
end


local function send_verify_code( args)

    local verify_code = generate_verify_code()

    ---- // 考虑发送短信的平台扩展
    local ok = send_sms_func[cur_sms_env](args, verify_code)

    return ok, verify_code

end

send_sms_func = 
{
    send_sms_normal ,
    send_sms_php,
}

local function handle()

    local req_ip   = ngx.var.remote_addr
    local req_body = ngx.req.get_body_data()
    url_info['client_host'] = req_ip

    if not req_body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_info['client_body'] = req_body
    
    local args = utils.parse_url(req_body)
    if not args or type(args) ~= 'table' then
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_BAD_JSON'])
    end
    check_parameter(args)
    url_info['app_key'] = args['appKey']

    local mobile = args['mobile']
    check_mobile(mobile)

    --record_flag 标识是否已有验证码记录 (1:有,0:无)
    local record_flag = check_last_send_info(mobile)

    local ok, verify_code = send_verify_code(args)
    if not ok then
        gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
    end

    if ok then
        if record_flag == 0 then
            insert_verify_code_info(verify_code, args['mobile'])
        else
            update_verify_code_info(verify_code, args['mobile'])
        end
    end

    local data = string.format('{"validTime":"%s"}', verify_code_valid_time)
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], data)

end

safe.main_call( handle )
