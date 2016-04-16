---- zhouzhe
---- 2015-04-22 
---- 1) 通过手机号获取重置密码
---- 2) 未注册的手机号,需要重新注册生成一个

local ngx       = require ('ngx')
local sha       = require('sha1')
local utils     = require('utils')
local app_utils = require('app_utils')
local only      = require('only')
local msg       = require('msg')
local gosay     = require('gosay')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local http_api  = require('http_short_api')
local cutils    = require('cutils')
local cjson   = require('cjson')

local reg_custom = link["OWN_DIED"]["http"]["addCustomAccount"]

local userlist_dbname = "app_usercenter___usercenter"

local sql_fmt = {
    select_from_userlist = [[SELECT userStatus, daokePassword, imei FROM userList WHERE accountID = '%s']],
    sql_check_mobile = " SELECT accountID FROM userRegisterInfo  WHERE mobile = '%s'  and validity=1",
    update_daokepassword_in_userlist =  [[ UPDATE userList SET daokePassword='%s', updateTime = %d WHERE accountID='%s' ]],
    insert_userlisthistory = [[ INSERT INTO userListHistory SET daokePassword='%s', accountID='%s',userStatus='%s', updateTime=%d,imei='%s']],

    sql_check_userOauthVerifycode = " select updateTime , content from userOauthVerifycode where mobile = %s  and  validity = 1 ",

    sql_check_psw = "select daokePassword from userList  where accountID = '%s' ", 
    check_auth_code = "select 1 from userOauthVerifycode  where  mobile = '%s'   and  validity = 1" , 
    save_auth_code = "insert into userOauthVerifycode(mobile, content ,  checkMobile,createTime,updateTime,validity)" .. 
                              " value (%s, '%s' , 0 , unix_timestamp() , unix_timestamp() , 1 ) " , 

}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(res)
    -- only.log('D', string.format("mobile = %s, type_verifyCode = %s,#type_verifyCode= %s " , 
    -- res['mobile'], type(res['verifyCode']) ,#type(res['verifyCode'])) )
    -- only.log('D','typ_mobile = %s ',type_res['mobile']))
    -- only.log('D','ret_verifyCode = %s ',utils.is_number(res['verifyCode']))
    -- only.log('D','ret_mobile = %s ',utils.is_number(res['mobile']))
    if not res['appKey'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
    end

    -->> check mobile
    local mobile = res['mobile']
    if not mobile == nil or (string.len(mobile) ~= 11) or (not utils.is_number(mobile)) or
      (utils.is_number(string.sub(mobile, 1, 1)) ~= 1) then
      gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'mobile')
    end

    local verifycode = res['verifyCode']
    if not verifycode or (#tostring(verifycode) ~= 6 ) or (not utils.is_number(verifycode)) then
        
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'vERifyCode')
    end

    url_info['app_key'] = res['appKey']
    safe.sign_check(res, url_info)
end

---- 根据手机号以及新的验证码获取accountID 
local function check_accountid_by_mobile( account_id , mobile, verifycode  )
    ---- 根据accountID获取密码,检验密码是否正确 
    ---- 密码正确返回accountID
    local sql_tmp = string.format(sql_fmt.sql_check_psw,account_id)
    local ok, result = mysql_pool_api.cmd(userlist_dbname , 'select', sql_tmp)
    if not ok or not result then
        only.log('E', string.format("achieve  daokePassword failed , %s" , sql_tmp) )
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    
    if #result ~= 1 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'vErifyCode')
    end

    local pwd = result[1]['daokePassword']
    local psword = ngx.md5(sha.sha1(verifycode) .. ngx.crc32_short(verifycode))
    if psword == tostring(pwd) then
        return account_id
    end
end

local function post_add_custom_account(mobile, verifycode,appKey)      
    local  tab = {
        appKey = appKey,
        mobile =  mobile,
        daokePassword = verifycode,
        gender = 1 ,
        accountType = 2 ,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)

    local post_data = 'POST /accountapi/v2/addCustomAccount HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    local data = string.format(post_data, reg_custom['host'], reg_custom['port'], #body, body)
    local ret = http_api.http(reg_custom, data, true)
  
    if not ret then return nil end
    only.log('D', '====>>>ret  = %s ' , ret )
    local body = string.match(ret, '{.+}')

    local ok, json_data = utils.json_decode(body)
    if not ok or tonumber(json_data['ERRORCODE']) ~= 0 then
      return nil
    else
      return json_data['RESULT']['accountID']
    end
 end

local function get_oauth_verifycode(mobile, verifycode , appKey)
    -- 判断当前用户是否在表userOauthVerifycode中, 
    -- 1) 认证验证码有效时间,是否过期
    -- 2) 认证验证码是否正确
    local sql_str = string.format(sql_fmt.sql_check_userOauthVerifycode , mobile)
    local ok, result = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)
    if not ok or not result then
        only.log('E', string.format("check user register failed , %s" , sql_str) )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result ~= 1 then
        only.log('E', string.format("#result = %s" , #result ))
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], 'mobile')
    end

    local new_time = os.time() - 600  --有效期十分钟

    local upd_time = result[1]['updateTime']
    local user_code = result[1]['content']

    only.log('D', "  tonumber(upd_time) = %s , new_time = %s ,user_code = %s", tonumber(upd_time) ,new_time , user_code )

    if new_time > tonumber(upd_time) then
        only.log('E', string.format("%s %s verifycode is expire ", mobile , verifycode ) )
        gosay.go_false(url_info,msg['MSG_ERROR_VERIFYCODE_EXPIRE'],'verifycode' )
    end
    
    if tonumber(user_code) ~= tonumber(verifycode)then
        only.log('E', string.format("verifycode is error!" ) )
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'VerifYcode')
    end

    ----  一切验证通过,调用add_custom_account, 传递mobile, verifycode作为密码,注册方式为手机注册, 生成新的accountID返回
    local account_id = post_add_custom_account( mobile, verifycode , appKey)
    return account_id
end
    
local function handle()

    local body = ngx.req.get_body_data()
    url_info['client_host'] = ngx.var.remote_addr

    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_body'] = body

    -->> check parameters
    local args = utils.parse_url(body)
    check_parameter(args)
    local appKey = args['appKey']
    local mobile = args['mobile']
    local verifycode = args['verifyCode']
    local sql_str = string.format(sql_fmt.sql_check_mobile , mobile )

    only.log('D',"sql_str = %s" ,sql_str)

    local ok, result = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)

    if not ok or not result then
        only.log('E', string.format("check user register failed , %s" , sql_str) )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end

    local account_id = nil
    if #result == 1 then
         --- 确认密码是否正确
         account_id = check_accountid_by_mobile(result[1]['accountID'], mobile, verifycode )
    else
         --- 确认是否在表userOauthVerifycode中 
         account_id = get_oauth_verifycode (mobile, verifycode, appKey)
    end
    
    local ret = string.format('{"accountID":"%s"}', account_id)
    if account_id then
        gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
    else
        gosay.go_success(url_info, msg["SYSTEM_ERROR"])
    end

end

safe.main_call( handle )
