
----author: Liuyongheng
----date: 2015-05-25
----remark: 手机用户根据验证码重置新密码

local ngx       = require('ngx')
local msg       = require('msg')
local only      = require('only')
local safe      = require('safe')
local gosay     = require('gosay')
local sha       = require('sha1')
local utils     = require('utils')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')


local user_dbname  = "app_usercenter___usercenter"

local G = {

    --检查用户输入的手机号
    sel_check_mobile        = " select accountID from userRegisterInfo where mobile='%s' and validity = 1  ",
    --校验accountID
    sel_check_account       = " select accountID,userStatus,daokePassword,imei from userList where accountID='%s' limit 2  ",
    --获取验证码和及其时间(增加获取验证码使用状态 2015/05/26)
    sel_check_verify_info   = " select verificationCode,updateTime,useState from mobileResetPwdVerifyCode where mobile = '%s'  ",
    --重置用户密码
    update_password         = " update userList set daokePassword='%s', updateTime=%d where accountID='%s' ",
    --维护维护userList历史表
    insert_userlist_history = " insert into userListHistory(accountID,userStatus,updateTime,daokePassword,imei) VALUES('%s', %s, %s, '%s', %s) ",
    --更新验证码使用状态(2015/05/26)
    update_verify_code_info = " update mobileResetPwdVerifyCode set updateTime= %d, useState = %d where mobile = '%s'  ",
}

local url_info = {
    type_name   = 'system',
    app_key     = nil,
    client_host = nil,
    client_body = nil,
}


--验证码使用情况(1:未使用;2:已使用)
--验证码已使用状态
local verify_code_used_state = 2

--验证码有效时间（单位:秒）
local VALIDITY_PERIOD = 600  -- 10 * 60

local function check_parameter( args )

    local mobile = args['mobile']
    local verify_code = args['verifyCode']
    local new_password = args['newPassword']

    if not mobile or not utils.is_number(mobile) or string.sub(mobile, 1, 1) ~= '1' or #mobile ~= 11 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'Mobile number')
    end

    if not verify_code or #verify_code~=6 or not utils.is_number(verify_code) then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'Verify code')
    end

    --明确密码明文格式之后待修改
    if not new_password or #new_password>64 or #new_password<6 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'New password')
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

    --该手机号还未注册为道客账户
    if #result_tab == 0 then
        gosay.go_false(url_info, msg['MSG_ERROR_USER_NAME_NOT_EXIST'])
    end

    if #result_tab > 1 then
        only.log('E', string.format('[***] userRegisterInfo mobile recordset >1  [sql][%s]', sql_str))
        gosay.go_false(url_info, msg['SYSTEM_ERROR'])
    end

    return result_tab[1]['accountID']

end

local function check_accountID( accountID )
    
    local sql_str = string.format(G.sel_check_account, accountID)
    local ok_status,user_tab = mysql_api.cmd(user_dbname, 'SELECT', sql_str)
    if not ok_status or not user_tab then
        only.log('E', string.format('connect userlist_dbname failed! [SQL][%s]', sql_str))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    return user_tab

end

local function check_verify_info( args )
    
    mobile = args['mobile']
    local sql_str = string.format(G.sel_check_verify_info, mobile)
    local ok_status, result_tab = mysql_api.cmd(user_dbname, 'SELECT', sql_str)
    
    if not ok_status or not result_tab then
        only.log('E', string.format('conect db [%s] failed', user_dbname))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    --没有重置密码的验证码记录(即还未获取重置密码的验证码)
    if #result_tab == 0 then
        gosay.go_false(url_info, msg['MSG_ERROR_NO_VERIFY_CODE'])
    end

    --校验验证码是否过期
    local valid_end_time = result_tab[1]['updateTime'] + VALIDITY_PERIOD
    local cur_time = os.time()
    if cur_time > valid_end_time then
        gosay.go_false(url_info, msg['MSG_ERROR_VERIFY_CODE_EXPIRED'])
    end

    --校验验证码是否匹配
    local verify_code = result_tab[1]['verificationCode']
    if verify_code ~= args['verifyCode'] then
        gosay.go_false(url_info, msg['MSG_ERROR_VERIFY_CODE_NOT_MATCH'])
    end

    --校验验证码使用状态
    local use_state = result_tab[1]['useState']
    if tonumber(use_state) == verify_code_used_state then
        gosay.go_false(url_info, msg['MSG_ERROR_VERIFY_CODE_USED'])
    end

end

local function reset_password( args, accountID, user_tab)

    local sql_tab = {}

    local cur_time = os.time()
    local password = ngx.md5(sha.sha1(args['newPassword']) .. ngx.crc32_short(args['newPassword']))
    local sql_str  = string.format(G.update_password, password, cur_time, accountID)
    table.insert(sql_tab, sql_str)

    local sql_str = string.format(G.insert_userlist_history, user_tab[1]['accountID'],
                                                             user_tab[1]['userStatus'],
                                                             cur_time,
                                                             user_tab[1]['daokePassword'],
                                                             user_tab[1]['imei']
                                                             )
    table.insert(sql_tab, sql_str)

    local ok_status, ret = mysql_api.cmd(user_dbname,'AFFAIRS',sql_tab)
    if not ok_status then
        only.log('E', string.format("reset mobile user password failed! %s ", table.concat( sql_tab, "\r\n")))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
end


local function update_verify_code_use_state( mobile )

    local cur_time  = os.time()
    local sql_str   = string.format(G.update_verify_code_info, cur_time, verify_code_used_state, mobile)
    local ok_status = mysql_api.cmd(user_dbname, 'UPDATE', sql_str)
    if not ok_status then
        only.log('E', string.format('connect userlist_dbname failed! [SQL][%s]', sql_str))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
end


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
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_BAD_JSON'])
    end
    check_parameter(args)
    url_info['app_key'] = args['appKey']

    --检查手机号码
    local accountID = check_mobile(args['mobile'])
    --校验accountID
    local user_tab = check_accountID(accountID)
    --检查输入的验证码是否匹配
    check_verify_info(args)
    --设置新密码
    reset_password(args, accountID, user_tab)
    ----更新验证码状态为已使用状态
    update_verify_code_use_state(args['mobile'])

    gosay.go_success(url_info, msg["MSG_SUCCESS"])

end

safe.main_call(handle)