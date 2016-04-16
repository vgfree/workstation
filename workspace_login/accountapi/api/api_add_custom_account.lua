---- zhouzhe
---- 2015-08-10
---- 自定义用户注册(用户名、手机号、邮箱)

local ngx            = require ('ngx')
local sha            = require('sha1')
local utils          = require('utils')
local app_utils     = require('app_utils')
local only           = require('only')
local msg            = require('msg')
local gosay          = require('gosay')
local safe           = require('safe')
local link           = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local http_api       = require('http_short_api')

---- add by jiang z.s. 2014-09-09 set nickname
local account_utils  = require('account_utils')

local reward_srv = link["OWN_DIED"]["http"]["rewardapi"]

local usercenter_dbname = 'app_usercenter___usercenter'
local usercrowd_dbname = 'app_crowd___crowd'

local cur_time = os.time()

local G = {
    -->> 排重account
    sql_check_account_info = " SELECT 1 FROM userLoginInfo WHERE %s='%s' ",
    -->> 保存用户注册信息
    sql_save_user_account_info = " INSERT INTO userLoginInfo SET accountID='%s', %s='%s', daokePassword= '%s', userStatus=1,"..
                        " accountSourceType=1, nickname='%s', gender=%d, clientIP=INET_ATON('%s'), createTime=%d, updateTime=%d ",
    -->> 保存用户个人信息表
    sql_save_user_personal_info = " INSERT INTO userGeneralInfo SET accountID='%s', userStatus=1, createTime=%d, updateTime=%d ",
    -->> 账号绑定wecode
    sql_get_wecode_info = "SELECT WECode FROM WECodeInfo WHERE accountID = '' AND WECodeStatus=0 AND rewardsType=%d AND"..
                                                                " amountType=%d AND disabledTime > %d LIMIT %d",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(args)

    if not args or type(args) ~= "table" then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    if not args['appKey'] or #args['appKey'] < 1 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "appKey")
    end

    for key, value in pairs(args) do
        local parameter = tostring(value or '')
        local str_res = string.find(parameter, "'")
        local str_tmp = string.find(parameter, "%%")
        if str_res or str_tmp then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], key )
        end
    end

    -- sign check
    safe.sign_check(args, url_info)

    if tonumber(args["accountType"]) == 1 then
        -->> check username
        if args["username"] and #args["username"] > 0 then
            args['username'] = ngx.unescape_uri(args['username'])
            args['username'] = string.lower(args['username'])
            if ((not string.match(args["username"], '^%l[%w%_%d]+$')) or (#args["username"] > 64)) then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username")
            end
        else
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username, accountType doesn't match")
        end
    elseif tonumber(args['accountType']) == 2 then
        -->> check mobile
        if (not args['username']) and args["mobile"] and #args["mobile"] > 0 then
            if (not utils.is_number(args["mobile"])) or (#args["mobile"] ~= 11) or (string.sub(args["mobile"], 1, 1) ~= '1') then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile")
            end
        else
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile,accountType doesn't match")
        end
    elseif tonumber(args['accountType']) == 3 then
        -->> check email
        if (not args['username']) and (not args['mobile']) and args["userEmail"] and args["userEmail"] ~= "" then
            if ((not string.find(args["userEmail"], '@')) or #(args["userEmail"]) > 64) then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail")
            end
        else
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail, accountType doesn't match")
        end
    else
        -->> at least exist one
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountType")
    end

    -->> check daokePassword
    if not args["daokePassword"] or string.len(args["daokePassword"]) < 6 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "daokePassword")
    end
    
    return args
end

-- 操作间隔时间控制 20150728 zhouzhe
local function check_times(value)
    only.log('D', string.format('redis check_times==value = %s',value))
    local TIME = 5
    local ok,ret = redis_api.cmd('private','get',value..':applyTimes')
    if not ok then
        only.log('E', string.format('redis failed!,value = %s', value))
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end

    if ret then
        only.log('E', string.format('====This user apply withdraw money more than one  in 5 second ,value = %s',value))
        gosay.go_false(url_info, msg['MSG_ERROR_SYSTEM_BUSY'])
    end

    local ok,ret = redis_api.cmd('private','set',value..':applyTimes',"1")
    if not ok then
        only.log('E', string.format('redis failed!, value = %s', value))
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end

    local ok,ret = redis_api.cmd('private','expire', value..':applyTimes', TIME)
    if not ok then
        only.log('E', string.format('redis failed!, value = %s',value))
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end
end

-- 排重account
local function check_user_account( args )

    local sql, key, value
    if args['username'] and tonumber(args['accountType']) == 1 then
        key, value = 'username', args['username']
    elseif args['mobile'] and tonumber(args['accountType']) == 2 then
        key, value = 'mobile', args['mobile']
    else
        key, value = 'userEmail', args['userEmail']
    end

    sql = string.format(G.sql_check_account_info, key, value)

    only.log('D', string.format("check user account==%s", sql))
    local ok, result = mysql_api.cmd( usercenter_dbname, 'SELECT', sql )

    if not ok then
        gosay.go_false( url_info, msg["MSG_DO_MYSQL_FAILED"] )
    end

    if #result ~= 0 then
        only.log("E", "user account exist")
        gosay.go_false(url_info, msg["MSG_ERROR_USER_NAME_EXIST"])
    end
    return value
end

-->> 生成accountID
local function gen_account_id()
    local accountid, sql
    while true do
        accountid = utils.random_string(10)
        sql = string.format(G.sql_check_account_info, 'accountID', accountid)
        local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql)
        if ok and #result==0 then
            break
        end
    end
    only.log('D', "new user accountID===%s", accountid)
    return accountid
end

-->> 保存用户注册信息
local function save_user_info( args )

    -->> 确定用户账号类型和账号
    local key, value = nil, nil
    if args['username'] and tonumber(args['accountType']) == 1 then
        key, value = 'username', args['username']
    elseif args['mobile'] and tonumber(args['accountType']) == 2 then
        key, value = 'mobile', args['mobile']
    else
        key, value = 'userEmail', args['userEmail']
    end
    if not (key or value) then
        only.log("E", "user account is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "user account")
    end
    local daokePassword = ngx.md5(sha.sha1(args['daokePassword']) .. ngx.crc32_short(args['daokePassword']))
    -->> 存入数据userLoginInfo
    local tab_sql = {}
    local sql1 = string.format( G.sql_save_user_account_info, args['accountID'], 
                                                                key, value, 
                                                                daokePassword,
                                                                nickname or '',
                                                                gender or 3, 
                                                                args['IP'],
                                                                cur_time,
                                                                cur_time )

    -->> 存入数据userGeneralInfo
    local sql2 = string.format(G.sql_save_user_personal_info, args['accountID'],  cur_time, cur_time )

    only.log('D', string.format("=11==save user account info==%s", sql1 ))
    only.log('D', string.format("=22==save user personal info==%s", sql2 ))
    table.insert(tab_sql, sql1 )
    table.insert(tab_sql, sql2 )
    local ok = mysql_api.cmd(usercenter_dbname, 'affairs', tab_sql)
    if not ok then
        only.log("E", "insert user info is failed")
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
end

-->> 保存数据到 redis
function save_redis( nickname, accountID )
    local times = 3
    for i=1, times do
        -->> 保存用户昵称,转语音
        local ok = account_utils.set_nickname(accountID, nickname)
        if ok then
            only.log('D', "<<<====save nickname redis success=====>>>")
            return true
        end
        if i == times then
            only.log('E', "FAILED set nickname and client mirrtalk 3 times")
            return false
        end
    end
end

-->> 生成wecode
local function create_wecode(cur_time, reward_type)
    local cur_year = os.date('%Y', cur_time)
    local cur_month = os.date('%m', cur_time)
    local cur_day = os.date('%d', cur_time)
    local next_time = os.time( { year=cur_year+1, month=cur_month, day=cur_day } )

    local tab = {
        appKey = url_info['app_key'],
        rewardsType = reward_type,
        disabledTime = next_time,
        createCount = 50, -- 生成wecode数量
    }

    local ok, secret = redis_api.cmd("public", "hget", tab["appKey"] .. ':appKeyInfo', 'secret')
    if not ok then
        only.log("E",string.format("redis failed=appKey=%s", tab["appKey"]))
        gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
    end

    tab['sign'] = app_utils.gen_sign(tab, secret)

    local body = utils.table_to_kv(tab)
    local post_body = utils.post_data('rewardapi/v2/createWECode', reward_srv, body)
    if not post_body then
        only.log('E', string.format("==11==post data create WECode is failed==%s",body))
        return false
    end
    -- only.log('D', post_body)
    local ret_body = http_api.http(reward_srv, post_body, true)
    if not ret_body then
        only.log('E', string.format("==22==http create WECode is failed==%s",body))
        return false
    end
    return true
end

-->> 绑定wecode
local function bind_wecode(account_id, wecode)
    local tab = {
        appKey = url_info['app_key'],
        accountID = account_id,
        WECode = wecode,
    }

    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)
    local post_body = utils.post_data('rewardapi/v2/bindUserWECode', reward_srv, body)
    local ret = http_api.http(reward_srv, post_body, true)
    if not ret then
        only.log('E',string.format("bindUserWECode failed  %s ", post_body ) )
       gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
    end

    local body = string.match(ret,'{.*}')
    if not body then
        only.log('E',string.format("[rewardapi/v2/bindUserWECode] %s \r\n ****SYSTEM_ERROR: %s", post_body, ret ))
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end

    local ok, ret_body = utils.json_decode(body)
    if not ok  then
        only.log('E',string.format("MSG_ERROR_REQ_BAD_JSON: %s", body ))
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    return ret_body
end

-->> 账号绑定wecode
local function accountid_bind_user_wecode( accountID )
    local cur_time = os.time()
    local selnum = 5
    local ok, result = nil, {}
    -->> 2:酬谢金额类型 4:酬谢类型 默认
    local rewardsType = 4
    local amountType = 2

    -->> 第一次获取5条wecode
    local sql = string.format(G.sql_get_wecode_info, rewardsType, amountType, cur_time, selnum)
    only.log("D", string.format("get 5 wecode==%s", sql))
    ok, result = mysql_api.cmd(usercrowd_dbname, 'select', sql)  
    if not ok or not result then
        only.log("E", "get wecode=1111== failed")
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    -->> 不足5条生成wecode
    if #result ~= selnum then     
        -->> 生成wecode
        ok = create_wecode(cur_time, rewardsType)
        if not ok then
            gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
        end
        -->> 第二次获取5条wecode
        ok, result = mysql_api.cmd( usercrowd_dbname, 'select', sql)
        if not ok or not result then
            only.log("E", "get wecode=2222== failed")
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end
    end
    if type(result) ~= "table" then
        only.log("E", "get wecode result is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'return data')
    end

    -->> 绑定wecode
    for num=1, selnum do
        local ret_body = bind_wecode( accountID, result[num]['WECode'])
        -->> 绑定WECode成功
        if tonumber(ret_body['ERRORCODE']) == 0 then
            only.log('D', string.format('====bind wecode success with accountID====%s',result[num]['WECode']))
            break
        else
            only.log('E',string.format('post bindUserWECode error,ERRORCODE:%s',ret_body['ERRORCODE']))
        end
        if num == selnum then
            return false
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
    local args = check_parameter(args)

    url_info['app_key'] = args['appKey']
    args['IP'] = IP
    args["nickname"] = utils.url_decode(args["nickname"])

    local value = check_user_account( args )
    -->> 相同用户操作时间redis锁 5s
    check_times( value )

    -->> 生成acountID
    args['accountID'] = gen_account_id()
    local accountID = args['accountID']
    nickname  = args['nickname']

    -->> 保存 redis
    local ok= save_redis( nickname, accountID )
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
    end

    -->> 保存到sql数据库
    save_user_info( args )

    -->> accountID绑定wecode,尝试三次
    local times = 3
    
    for i=1, times do
        local ok = accountid_bind_user_wecode( accountID )
        if ok then
            break
        else
            only.log("W", string.format("=WIN===bindwecodeAPI==bind wecode failed, accountid: %s", accountID ))
        end
    end

    local ret = string.format('{"accountID":"%s"}', accountID )
    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )
