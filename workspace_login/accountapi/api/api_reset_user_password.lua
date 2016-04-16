--author    : malei
--date  : 2014-06-17
--fixed : ......
--date  : ......
-- zhouzhe 2015-08-18 修改
local ngx       = require ('ngx')
local sha       = require('sha1')
local http_api  = require('http_short_api')
local utils     = require('utils')
local app_utils = require('app_utils')
local only      = require('only')
local msg       = require('msg')
local gosay     = require('gosay')
local safe      = require('safe')
local link      = require('link')
local mysql_api = require('mysql_pool_api')

local sms_srv = link["OWN_DIED"]["http"]["sendSMS"]

local sql_fmt = {

    select_from_userlist = [[SELECT mobile FROM userLoginInfo WHERE userStatus=1 AND accountID = '%s']],
    update_daokepassword_in_userlist =  [[ UPDATE userLoginInfo SET daokePassword='%s', updateTime = %d WHERE accountID='%s' ]],
    --<<--2015-08-18-->>
    -- select_from_userlist = [[SELECT userStatus, daokePassword, imei FROM userList WHERE accountID = '%s']],
    -- select_mobile_userRegisterInfo = [[SELECT mobile FROM userRegisterInfo  WHERE accountID = '%s' and checkMobile=1 and  validity=1]],
    -- update_daokepassword_in_userlist =  [[ UPDATE userList SET daokePassword='%s', updateTime = %d WHERE accountID='%s' ]],
    -- insert_userlisthistory = [[ INSERT INTO userListHistory SET daokePassword='%s', accountID='%s',userStatus='%s', updateTime=%d,imei='%s']],
    --<<--end-->>
}

local usercenter_dbname = 'app_usercenter___usercenter'

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(res)

    if not res['accountID'] or not app_utils.check_accountID(res['accountID']) then
           gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    safe.sign_check(res, url_info)
end

local function send_sms(content)

    local data_fmt = 'POST /webapi/v2/sendSms HTTP/1.0\r\n' ..
    'Host:%s:%s\r\n' ..
    'Content-Length:%d\r\n' ..
    'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local data = string.format(data_fmt, sms_srv['host'], sms_srv['port'], #content, content)
    only.log('D', data)
    local ret = http_api.http(sms_srv, data, true)
    if not ret then return nil end
    only.log('D', ret)
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
    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body
    local args = utils.parse_url(body)

    check_parameter(args)
    url_info['app_key'] = args['appKey']
    local account_id = args["accountID"]

    local sql1 = string.format(sql_fmt.select_from_userlist, account_id)
    only.log("D", string.format("get user info ==%s", sql1))
    local ok, result = mysql_api.cmd(usercenter_dbname, 'SELECT', sql1)
    if not ok then
        only.log("E", "mysql failed get user info")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result < 1 then
        only.log("E", "return failed")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
    end
    local mobile = result[1]['mobile']
    if not utils.is_number(mobile) or (#mobile~=11) or (string.sub(mobile, 1, 1) ~= '1') then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile")
    end

    --<<--2015-08-18-->>
    --  -->> check parameters
    --  local res = check_parameter(body)
    --  local account_id = res["accountID"]
    --  local sql = string.format(sql_fmt.select_from_userlist, account_id)
    --  local ok, result = mysql_api.cmd('app_usercenter___usercenter', 'SELECT', sql)
    --  if not ok or not result then
    --      only.log('E',string.format(" check userlist failed,  %s ", sql) )
    --      gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    --  end
    --  if #result == 0 then
    --      gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_NOT_EXIST"])
    --  end

    --  if #result > 1 then
    --      gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    --  end

    --  local user_status = result[1]['userStatus']
    --  local daoke_password = result[1]['daokePassword']
    --  local imei = result[1]['imei']
    --  --4.C 如果daokePassword为空，返回用户未设置道客密码，不允许重置的错误信息     --根据业务需求于2014.10.31取消对此处旧密码为空时不能重置密码的限制
    --  -- if daoke_password  == '' then
    --  --     gosay.go_false(url_info, msg["MSG_ERROR_NO_DAOKE_PWD"])
    --  -- end
    --  --4.D 如果userStatus不为1、４或5，返回帐户不提供服务(msg中索引为MSG_ERROR_ACCOUNT_ID_NO_SERVICE)的错误信息
    --  local userstatus = tonumber(user_status)
    --  if (userstatus ~= 1  and userstatus ~= 4 and userstatus ~= 5) then
    --      only.log('E',string.format(" check user_status failed, account_id:%s user_status:%s ", account_id, userstatus) )
    --      gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NO_SERVICE"])
    --  end

    --  --4.E.其它情况进入下一步骤
    -- -- 5.根据accountID=输入的accountID and checkMobile=1 and 
    --  sql = string.format(sql_fmt.select_mobile_userRegisterInfo , account_id)
    --  local ok, result = mysql_api.cmd('app_usercenter___usercenter', 'SELECT', sql)
    --  if not ok or not result then
    --      only.log('E', string.format("check user register failed , %s" , sql) )
    --      gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    --  end

    --  --5.A 如果查询结果为空，返回该用户手机号码未验证的错误信息(此错误码需新添加一个)
    --  if #result == 0 then
    --      only.log('E',string.format('#result: %d == 0 ', #result)) 
    --      gosay.go_false(url_info, msg["MSG_ERROR_NOT_MOBILE_AUTH"])
    --  end

    --  --5.B 如果有多条记录，返回数据库数据错误，后续进行人干预（system错误）
    --  if #result > 1 then
    --      gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    --  end

    --  local mobile  = result[1]['mobile'];
    --<<--end-->>

    --6.随机生成长度为６位的数字作为用户的新密码，
    local pwd = utils.random_number(6)
    --send message to mobile
    local txt = string.format("您的道客密码已重置,新道客密码为:%s,请尽快修改.", pwd)
    local tbl = {
        ['mobile'] = mobile,
        ['content'] = txt,
        ['appKey'] = args['appKey'],
    }
    tbl['sign'] = app_utils.gen_sign(tbl);
    local content = string.format('mobile=%s&content=%s&appKey=%s&sign=%s', 
        mobile, txt, tbl['appKey'], tbl['sign'])

    local bizid = send_sms(content)
    if not bizid then
        only.log('W',string.format(" send sms failed,  %s ",  txt ))
        gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
    end
    -- send message successfully
    --7.如果新道客密码短信发送成功，
    local password = ngx.md5(sha.sha1(pwd) .. ngx.crc32_short(pwd))
    local cur_time = os.time()

    --<<--2015-08-18-->>
    -- local tab_sql = {
    --     [1] = string.format(sql_fmt.update_daokepassword_in_userlist, password, cur_time, account_id),
    --     [2] = string.format(sql_fmt.insert_userlisthistory, password, account_id, user_status, cur_time, imei)
    -- }
    -- local ok, ret = mysql_api.cmd('app_usercenter___usercenter', 'AFFAIRS', tab_sql)
    -- only.log('D', tab_sql[1])
    -- only.log('D', tab_sql[2])
    --<<--end-->>
    local sql=string.format(sql_fmt.update_daokepassword_in_userlist, password, cur_time, account_id)
    only.log("D", string.format("send sms ==%s", sql))
    local ok = mysql_api.cmd('app_usercenter___usercenter', 'UPDATE', sql)
    if not ok then
        only.log('E',"update user new password failed")
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    --8.如果以上任何一步数据库操作失败，需进行数据库回滚，然后返回数据库操作失败错误信息
    --9.如果发生任何错误，调用日志服务记录错误信息
    gosay.go_success(url_info, msg["MSG_SUCCESS"])
    --10.调用API统计日志接口保存API调用信息
    --11.API编号为S0135V2
end

safe.main_call( handle )
