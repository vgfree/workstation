--fixed     : baoxue
--date      : 2013-01-22
---- zhouzhe 20150827 xiugai
---- 无条件修改用户手机号和邮箱

local ngx       = require ('ngx')
local msg       = require('msg')
local only      = require('only')
local utils     = require('utils')
local safe      = require('safe')
local cfg       = require ('config')
local gosay     = require('gosay')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')


local usercenter_dbname = 'app_usercenter___usercenter'

local sql_fmt = {

    ---- 判断用户名的有效性
    sql_check_account = "select 1 from userLoginInfo where accountID ='%s' ",
    ---- 更新数据
    sql_update_account = " update userLoginInfo set %s='%s' where accountID='%s' ",
    ---- 判断用户是否唯一
    sql_check_user_account = " select 1 from userLoginInfo where %s='%s' ",

    -- get_userEmail = [[SELECT checkUserEmail, userEmail,accountID FROM userRegisterInfo WHERE accountID='%s' AND validity=1]],
    -- get_userMobile = [[SELECT checkMobile,mobile,accountID FROM userRegisterInfo WHERE accountID='%s' AND validity=1]],

    -- update_checkMobile =    [[UPDATE userRegisterInfo SET checkMobile=%s, mobile='%s' WHERE accountID='%s' AND validity=1]],
    -- update_checkUserEmail = [[UPDATE userRegisterInfo SET checkUserEmail=%s,userEmail='%s' WHERE accountID='%s' AND validity=1]],

    -- check_userlist_record = [[SELECT accountID FROM userList WHERE accountID='%s']],
    -- insert_mobile = [[INSERT INTO userRegisterInfo SET checkMobile=1,mobile='%s',accountID='%s',createTime=%s]],
    -- insert_email = [[INSERT INTO userRegisterInfo SET checkUserEmail=1,userEmail='%s',accountID='%s',createTime=%s]],

    -- get_userInfo = [[SELECT nickname, mobile, userEmail, checkMobileTime, checkUserEmailTime, updateTime FROM userInfo WHERE accountID='%s' AND status=1]],
    -- save_userInfoHistory = [[INSERT INTO userInfoHistory SET accountID='%s', nickname='%s', mobile='%s', userEmail='%s', checkMobileTime=%s, checkUserEmailTime=%s, updateTime=%s]],

    -- update_userInfo_email = [[UPDATE userInfo SET userEmail='%s', checkUserEmailTime='%s', updateTime='%s' WHERE accountID='%s' AND status=1]],
    -- update_userInfo_mobile = [[UPDATE userInfo SET mobile='%s', checkMobileTime='%s', updateTime='%s' WHERE accountID='%s' AND status=1]],

    -- set_validity_zero = [[UPDATE userRegisterInfo SET validity=0 WHERE accountID='%s' AND validity=1]],
}

-- local G = {
--     old_val = nil,
--     old_check = nil,
-- }

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(res)
    -->> safe check
    safe.sign_check(res, url_info)

    if not app_utils.check_accountID(res['accountID']) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountID")
    end

    -->> check email and mobile one exist
    if (res["email"] and res["mobile"] and #res["email"] > 0 and #res["mobile"] >0 ) or ((not res["email"]) and (not res["mobile"])) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "email or mobile")
    end

    -->> check email
    if res["email"] and #res['email'] > 0 and ((string.len(res["email"]) <= 3) or (not string.find(res["email"], "@"))) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "email")
    end

    -->> check mobile
    if res["mobile"] and #res['mobile'] > 0 and ((not utils.is_number(res["mobile"])) or (#res["mobile"] ~= 11) or (string.sub(res["mobile"], 1, 1) ~= '1')) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile")
    end
end

-- local function update_email_or_mobile_check( args )
--     local res_sql
--     if args['email'] and #args['email'] > 0 then
--         res_sql = string.format(sql_fmt.update_checkUserEmail, 1, args['email'], args['accountID'])
--     else
--         res_sql = string.format(sql_fmt.update_checkMobile, 1, args['mobile'], args['accountID'])
--     end
--     only.log('D',res_sql)
--     local ok , result = mysql_pool_api.cmd("app_usercenter___usercenter", 'update', res_sql)

--     return ok
-- end

-- local function insert_email_or_mobile_accout_id( args )

--     local res_sql = string.format(sql_fmt.check_userlist_record, args['accountID'])
--     only.log('D',res_sql)
--     local ok , result = mysql_pool_api.cmd("app_usercenter___usercenter", 'select', res_sql)
--     if #result == 0 then
--         gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
--     elseif #result > 1 then
--         gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'accountID')
--     end

--     local cur_time = os.time()
--     if args['email'] and #args['email'] > 0 then
--         res_sql = string.format(sql_fmt.insert_email, args['email'], args['accountID'], cur_time)
--     else
--         res_sql = string.format(sql_fmt.insert_mobile, args['mobile'], args['accountID'], cur_time)
--     end
--     only.log('D',res_sql)
--     ok , result = mysql_pool_api.cmd("app_usercenter___usercenter", 'insert', res_sql)

--     if not ok then
--         gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
--     end
-- end

-- local function update_info( args )
--     -->> get info from userInfo
--     local res_sql = string.format(sql_fmt.get_userInfo, args['accountID'])
--     only.log('D',res_sql)
--     local ok, result = mysql_pool_api.cmd("app_cli___cli", 'select', res_sql)
--     if (not ok) or (#result == 0) then
--         return false
--     end

--     local time = os.time()

--     -->> save info to userInfoHistory
--     local sql = {}
--     sql[1] = string.format(sql_fmt.save_userInfoHistory, args['accountID'], result[1]["nickname"], result[1]["mobile"], result[1]["userEmail"], result[1]["checkMobileTime"], result[1]["checkUserEmailTime"], result[1]["updateTime"]) 
--     only.log('D',sql[1])

--     -->> update userInfo
--     if args['email'] and #args['email'] > 0 then
--         sql[2] = string.format(sql_fmt.update_userInfo_email, args["email"], time, time, args['accountID'])
--     else
--         sql[2] = string.format(sql_fmt.update_userInfo_mobile, args["mobile"], time, time, args['accountID'])
--     end
--     only.log('D',sql[2])
--     ok, result = mysql_pool_api.cmd("app_cli___cli", 'affairs', sql)

--     return ok
-- end

-- local function update_email_or_mobile_back( res, flag)
--     local sql
--     if flag == 0 then
--         local cur_time = os.time()
--         if res['email'] and #res['email'] > 0 then
--             sql = string.format(sql_fmt.update_checkUserEmail, G.old_check, G.old_val, cur_time, res['accountID'])
--         else
--             sql = string.format(sql_fmt.update_checkMobile, G.old_check, G.old_val, cur_time, res['accountID'])
--         end
--     else
--         sql = string.format(sql_fmt.set_validity_zero, res['accountID'])
--     end
--     only.log('D',sql)
--     local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'update', sql)

--     if not ok then
--         gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
--     end
-- end

function handle()
    local body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    url_info['client_host'] = ip
    url_info['client_body'] = body
    local args = utils.parse_url(body)
    ---- 检查参数
    check_parameter( args )
    url_info['app_key'] = args['appKey']

    ---- 检查参数合法性
    local sql1 = string.format(sql_fmt.sql_check_account, args['accountID'])
    only.log('D',string.format("check accountID ===%s", sql1))
    local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql1)
    if not ok or not result then
        only.log("E","mysql check accountID failed")
        gosay.go_false(url_info , msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result ~= 1 then
        only.log("E", "accountID is not exists")
        gosay.go_false(url_info, msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
    ---- 识别输入参数类型
    local key, value
    if args['mobile'] and #args['mobile'] == 11 then
        key, value = 'mobile', args['mobile']
    else
        key, value = 'userEmail', args['email']
    end

    ---- 判断用户输入更改参数的是否唯一
    local sql3 = string.format(sql_fmt.sql_check_user_account, key, value )
    only.log('D',string.format("check user account ===%s", sql3))
    local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql3)
    if not ok then
        only.log("E","mysql check user account failed")
        gosay.go_false(url_info , msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result > 0 then
        if key == 'mobile' then
            only.log("E", "mobile already registered")
            gosay.go_false(url_info, msg['MSG_ERROR_MOBILE_ALREAD_REGISTER'])
        else
            only.log("E", "userEmail already registered")
            gosay.go_false(url_info, msg['MSG_ERROR_EMAIL_HAS_EXISTS'] )
        end
    end

    ---- 更新数据
    local sql2 = string.format(sql_fmt.sql_update_account, key, value, args['accountID'])
    only.log('D',string.format("update accountID===%s", sql2))
    local ok = mysql_api.cmd(usercenter_dbname, 'update', sql2)
    
    if not ok then
        only.log("E", "update account is failed")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    else
        gosay.go_success(url_info, msg["MSG_SUCCESS"])
    end
end

safe.main_call( handle )

    -- if res['email'] and #res['email'] > 0 then
    --     sql = string.format(sql_fmt.get_userEmail, res['accountID'])
    -- else
    --     sql = string.format(sql_fmt.get_userMobile, res['accountID'])
    -- end
    -- only.log('D',sql)
    -- local ok, result = mysql_pool_api.cmd("app_usercenter___usercenter", 'select', sql)

    -- if not ok or not result then
    --     only.log("E", "mysql check accountID failed")
    --     gosay.go_false(url_info , msg['MSG_DO_MYSQL_FAILED'])
    -- end

    -- if #result < 1 or type(result) ~= "table" then
    --     only.log("E", " check accountID return failed")
    --     gosay.go_false(url_info , msg['MSG_ERROR_REQ_ARG'], "accountID") 
    -- end

    -- if not result[1]['accountID'] or #result[1]['accountID'] < 1 then
    --     only.log("E", " accountID  is not exists or accountID abnormity")
    --     gosay.go_false(url_info , msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    -- end
    -- -- 判断查询结果是否为空，如果不为空更新check和新的手机号或邮箱到userRegister表中
    -- local flag
    -- if #result > 0  then
    --     if res['email'] and #res['email'] > 0 then
    --         G.old_val = result[1]['checkUserEmail']
    --         G.old_check = result[1]['userEmail']
    --     else
    --         G.old_val = result[1]['checkMobile']
    --         G.old_check = result[1]['mobile']
    --     end

    --     local st = update_email_or_mobile_check( res )
    --     flag = 0

    --     -- 如果为空，根据输入的accountID查找useriList表，如果有一条记录，那么插入check、accountID 和新的手机号或邮箱到userRegister表中
    -- else
    --     insert_email_or_mobile_accout_id( res )
    --     flag = 1
    -- end

    -->> save userInfo into userInfoHistory, update userInfo
    -- ok = update_info( res )
    -- if not ok then
    --     update_email_or_mobile_back( res, flag)
    -- end

