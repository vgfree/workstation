---- zhouzhe
---- 2015-04-22 
---- 1) 通过手机号获取重置密码
---- 2) 未注册的手机号,需要重新注册生成一个
---- 2015-07-09切换到前端封装的云通信接口 zhouzhe

local ngx        = require ('ngx')
local sha        = require('sha1')
local utils      = require('utils')
local only       = require('only')
local msg        = require('msg')
local gosay      = require('gosay')
local safe       = require('safe')
local link       = require('link')
local cutils     = require('cutils')
local app_utils  = require('app_utils')
local redis_api  = require('redis_pool_api')
local mysql_api  = require('mysql_pool_api')
local http_api   = require('http_short_api')

local sms_srv_php = link["OWN_DIED"]["http"]["sendSmsPHP"]
local sms_srv = link["OWN_DIED"]["http"]["sendSMS"]
local userlist_dbname = "app_usercenter___usercenter"

local platform= 1

-- 模板id
local templateID = 21109

local sql_fmt = {
    -->> 获取mobile的accountID
    sql_check_mobile = " SELECT accountID FROM userLoginInfo WHERE mobile='%s' ",

    -- update_daokepassword =  " UPDATE userLoginInfo SET daokePassword='%s', updateTime = %d WHERE accountID='%s' ",

    check_auth_code = "SELECT 1 FROM userDynamicVerifycode WHERE  mobile = '%s' AND validity = 1 ", 
    save_dynamic_code = "insert into userDynamicVerifycode ( mobile, content ,  checkMobile, createTime , updateTime,validity)" .. 
                              " value ( '%s' , '%s' , 0 , unix_timestamp() , unix_timestamp() , 1 ) "  , 

    update_dynamic_code = " update userDynamicVerifycode set content = '%s', updateTime = unix_timestamp()  where mobile = '%s' and  validity = 1 " ,
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(args)
    -- check mobile
    local mobile = args['mobile']
    if not mobile or string.len(mobile) ~= 11 or not utils.is_number(mobile) or
      (utils.is_number(string.sub(mobile, 1, 1)) ~= 1) then
      gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
    end

    safe.sign_check(args, url_info)
end

local function send_sms_lan(content )
    local data_fmt = 'POST /webapi/v2/sendSms HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Length:%d\r\n' ..
    'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv['host'], sms_srv['port'], #content, content)
    local ret = http_api.http(sms_srv, data, true)
    if not ret then
        only.log('E',string.format("req data: %s",data))
        return nil 
    end

    local body = string.match(ret, '{.+}')
    if not body then
        only.log('E',string.format('ret  = %s ' , ret  ) )
        return nil
    end

    local ok, json_data = utils.json_decode(body)

    if not ok or tonumber(json_data['ERRORCODE'])~=0 then
        return nil
    else
        return json_data['RESULT']['bizid']
    end
end

-- 2015-07-09调用前端封装的云通信接口 /sendSMS/index.php
local function send_sms_yun(content )

    local data_fmt = 'POST /sendSMS/index.php HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Length:%d\r\n' ..
    'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv_php['host'], sms_srv_php['port'], #content, content)

    local ok,ret = cutils.http(sms_srv['host'], sms_srv['port'], data, #data)
    if not ok then
        only.log("E", "sendSms filed")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "sendSms")
    end
    -- only.log('D',string.format('==ret = %s ' , ret  ) )
    if not ret then
        only.log('E',string.format("return data: %s",data))
        return false
    end

    local body = string.match(ret, '{.+}')
    only.log('D',string.format('body  = %s ' , body  ) )
    if not body then
        only.log('E',string.format('==ret: %s ' , ret  ) )
        return false
    end
    local ok, json_data = utils.json_decode(body)
    only.log('D',string.format('ERRORCODE  = %s ', json_data['ERRORCODE']))

    if not ok or tonumber(json_data['ERRORCODE'])~= 000000 then
        return false
    elseif tonumber(json_data['ERRORCODE']) == 160021 then
        only.log("W", "Same content in the same cell phone can only be issued once")
        return false
    else
        return true
    end
end

local function send_sms(appKey, mobile, pwd )
    if platform == 1 then
        local txt = string.format("验证码为：%s，有效期10分钟。", pwd)
        local tab = {
            ['mobile'] = mobile,
            ['content'] = txt,
            ['appKey'] = appKey,
        }
        tab['sign'] = app_utils.gen_sign(tab)
        local content = utils.table_to_kv(tab)

        local ok = send_sms_lan(content )
        return ok
    else
        local tab = {
            ['phone'] = mobile,
            ['code'] = pwd,
            ['time'] = 10,
            ['templateID'] = templateID,
        }
        tab['sign'] = app_utils.gen_sign(tab)
        local content = utils.table_to_kv(tab)
        local ok = send_sms_yun(content )
        return ok
    end
end

-- 重置密码
local function reset_password(appKey, mobile, pwd)

    local ok = send_sms(appKey, mobile, pwd )
    if not ok then
        only.log('E',string.format("send sms failed,%s,%s ", mobile, pwd ))
        gosay.go_false(url_info, msg['MSG_ERROR_SMS_SEND_FAILED'])
    end
    -->> 如果新道客密码短信发送成功
    -- local password = ngx.md5(sha.sha1(pwd) .. ngx.crc32_short(pwd))
    -- local cur_time = os.time()

    -- local sql =string.format(sql_fmt.update_daokepassword, password, cur_time, accountID)

    -- local ok = mysql_api.cmd(userlist_dbname, 'UPDATE', sql)
    -- only.log('D',string.format(" reset user password == %s  ", sql ) ) 
    -- if not ok then
    --     only.log('E'," update user new password failed ")
    --     gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    -- end
    local TOKENCODE_EXPIRE = 60*10
    local tmp_key = string.format("%s:modifyCode", tostring(mobile))

    local ok = redis_api.cmd('private', 'SETEX', tmp_key, TOKENCODE_EXPIRE, pwd )
    if not ok then
        only.log('E', string.format('redis failed!,value = %s', value))
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end

    return true
end

-->> 注册新用户 
local function register_new_user(appKey, mobile, pwd)
    local ok = send_sms(appKey, mobile, pwd)
    if not ok then
        only.log('E',string.format("send sms failed, bizid=  %s ", bizid ))
        gosay.go_false(url_info, msg['MSG_ERROR_SMS_SEND_FAILED'])
    end

    -- 1) 判断 当前手机号是否生成过 记录
    local sql_tmp = string.format( sql_fmt.check_auth_code, mobile )
    local ok, result = mysql_api.cmd(userlist_dbname, 'SELECT', sql_tmp)

    if not ok or not result then
        only.log('E', string.format('check user register failed !') )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end
 
    if #result < 1 then
        ---- 1.1 没有生成记录,插入一条记录到数据库
        local sql_code = string.format(sql_fmt.save_dynamic_code, mobile , pwd )
        local ok, result = mysql_api.cmd(userlist_dbname, 'INSERT', sql_code)
        if not ok or not result  then
            only.log('E', string.format("insert user record failed , %s" , sql_code))
            gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
        end
    else
        ---- 1.2 原来生成过记录,更新数据库记录
        local sql_code = string.format(sql_fmt.update_dynamic_code , pwd , mobile )
        local ok = mysql_api.cmd(userlist_dbname, 'UPDATE', sql_code)

        if not ok then
            only.log('E', string.format("update user record failed , %s" , sql_code) )
            gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
        end
    end
    return true
end

local function handle()
    local body = ngx.req.get_body_data()
    local IP = ngx.var.remote_addr
    url_info['client_body'] = body
    url_info['client_host'] = IP

    if not body then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    local args = utils.parse_url(body)

    -->> 检查参数
    check_parameter(args)
    url_info['app_key'] = args['appKey']
    local mobile = args['mobile']
    -->> 排重mobile
    local sql_str = string.format(sql_fmt.sql_check_mobile , mobile )
    local ok, result = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)
    local accountID = nil
    if #result ==1 and type(result)=="table" then
        accountID = result[1]['accountID'] 
    end
    local pwd = utils.random_number(6)

    local ok = nil
    if #result == 0 then
        -->> 注册一个账户
        ok = register_new_user(args['appKey'], mobile, pwd )
    else
        -->> 重置密码(目前没有用到)
        ok = reset_password(args['appKey'], mobile, pwd)
    end

    if ok then
        gosay.go_success(url_info, msg["MSG_SUCCESS"])
    else
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end
end

safe.main_call( handle )
