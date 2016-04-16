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

local sms_srv = link["OWN_DIED"]["http"]["sendSmsPHP"]
local userlist_dbname = "app_usercenter___usercenter"

-- 模板id
local templateID = 21109

local sql_fmt = {
    sql_check_mobile = " SELECT accountID FROM userRegisterInfo  WHERE  mobile = '%s' and validity=1  ",
    sql_data_userlist = " SELECT userStatus, imei FROM userList WHERE accountID = '%s' ",
    update_daokepassword_in_userlist =  " UPDATE userList SET daokePassword='%s', updateTime = %d WHERE accountID='%s' ",
    insert_userlisthistory = " INSERT INTO userListHistory SET daokePassword='%s', accountID='%s',userStatus='%s', updateTime=%d,imei='%s' ",

    check_auth_code = "SELECT 1 FROM userDynamicVerifycode WHERE  mobile = '%s' AND validity = 1 ", 
    save_dynamic_code = "insert into userDynamicVerifycode ( mobile, content ,  checkMobile,createTime , updateTime,validity)" .. 
                              " value ( '%s' , '%s' , 0 , unix_timestamp() , unix_timestamp() , 1 ) "  , 

    update_dynamic_code = " update userDynamicVerifycode set content = '%s', updateTime = unix_timestamp()  where mobile = '%s' and  validity = 1 " ,
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(res)
    -- check mobile
    local mobile = res['mobile']
    if not mobile == nil or (string.len(mobile) ~= 11) or (not utils.is_number(mobile)) or
      (utils.is_number(string.sub(mobile, 1, 1)) ~= 1) then
      gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
    end
    url_info['app_key'] = res['appKey']
    safe.sign_check(res, url_info)
end

local function send_sms(content)
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

-- 2015-07-09调用前端封装的云通信接口 192.168.1.3  8080 /sendSMS/index.php
-- local function send_sms(content)

--     local data_fmt = 'POST /sendSMS/index.php HTTP/1.0\r\n' ..
--     'Host:%s:%s\r\n' ..
--     'Content-Length:%d\r\n' ..
--     'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

--     local data = string.format(data_fmt, sms_srv['host'], sms_srv['port'], #content, content)

--     local ok,ret = cutils.http(sms_srv['host'], sms_srv['port'], data, #data)
--     if not ok then
--         only.log("E", "sendSms filed")
--         gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "sendSms")
--     end
--     -- only.log('D',string.format('==ret = %s ' , ret  ) )
--     if not ret then
--         only.log('E',string.format("return data: %s",data))
--         return false
--     end

--     local body = string.match(ret, '{.+}')
--     only.log('D',string.format('body  = %s ' , body  ) )
--     if not body then
--         only.log('E',string.format('==ret: %s ' , ret  ) )
--         return false
--     end
--     local ok, json_data = utils.json_decode(body)
--     only.log('D',string.format('ERRORCODE  = %s ', json_data['ERRORCODE']))

--     if not ok or tonumber(json_data['ERRORCODE'])~= 000000 then
--         return false
--     elseif tonumber(json_data['ERRORCODE']) == 160021 then
--         only.log("W", "Same content in the same cell phone can only be issued once")
--         return false
--     else
--         return true
--     end
-- end

-- 重置密码
local function reset_password(appKey, mobile, pwd, accountID )

    -- 获取用户信息userList
    local sql_str = string.format(sql_fmt.sql_data_userlist , accountID )
    local ok, result = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)

    if not ( ok or result ) then
        only.log('E', string.format("check user register failed , %s" , sql_str) )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result < 1 then
        only.log('E', "SELECT userList return is error" )
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], "accountID")
    end

    userStatus = result[1]['userStatus'] or ''
    imei = result[1]['imei'] or ''
    -- local tab = {
    --     ['phone'] = mobile,
    --     ['code'] = pwd,
    --     ['time'] = 10,
    --     ['templateID'] = templateID,
    -- }
    local txt = string.format("您本次修改道客账号的验证码为：%s,10分钟有效.", pwd)
    local tab = {
        ['mobile'] = mobile,
        ['content'] = txt,
        ['appKey'] = appKey,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    local content = utils.table_to_kv(tab)
    local ok = send_sms(content)
    if not ok then
        only.log('E',string.format("send sms failed,%s ",  content ))
        gosay.go_false(url_info, msg['MSG_ERROR_SMS_SEND_FAILED'])
    end
    --7.如果新道客密码短信发送成功
    local password = ngx.md5(sha.sha1(pwd) .. ngx.crc32_short(pwd))
    local cur_time = os.time()
    local tab_sql = {}

    table.insert(tab_sql, string.format(sql_fmt.update_daokepassword_in_userlist, password, cur_time, accountID) ) 
    table.insert(tab_sql, string.format(sql_fmt.insert_userlisthistory, password, accountID, user_status, cur_time, imei) )

    local ok = mysql_api.cmd(userlist_dbname, 'AFFAIRS', tab_sql)
    only.log('D',string.format(" reset user password ,  %s  ", table.concat( tab_sql , "\r\n" ) ) ) 
    if not ok then
        only.log('E',string.format(" update user new password failed , %s ", table.concat( tab_sql, "\r\n") ))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    return true
end

---- 注册新用户 
local function register_new_user(appKey, mobile, pwd, accountID)
    local txt = string.format("您本次注册道客账号的验证码为：%s,请认证注册,10分钟有效.", pwd)
    -- local tab = {
    --     ['phone'] = mobile,
    --     ['code'] = pwd,
    --     ['time'] = 10,
    -- }
    local tab = {
        ['mobile'] = mobile,
        ['content'] = txt,
        ['appKey'] = appKey,
    }

    tab['sign'] = app_utils.gen_sign(tab)
    local content = utils.table_to_kv(tab)
    local ok = send_sms(content)
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
    url_info['client_host'] = ngx.var.remote_addr

    if not body then
        only.log('E' , 'body is error')
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_body'] = body

    -- check parameters
    local args = utils.parse_url(body)
    check_parameter(args)
   
    local mobile = args['mobile']

    local sql_str = string.format(sql_fmt.sql_check_mobile , mobile )
    local ok, result = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)
    local accountID = nil
    if #result ==1 then
        accountID = result[1]['accountID'] 
    end
    local pwd = utils.random_number(6)

    local ok = nil
    if #result == 0 then
        ---- 需要注册一个账户
        ok = register_new_user(args['appKey'], mobile, pwd ,accountID)
    else
        ---- 重置密码
        ok = reset_password(args['appKey'], mobile, pwd ,accountID)
    end

    if ok then
        gosay.go_success(url_info, msg["MSG_SUCCESS"])
    else
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end
end

safe.main_call( handle )
