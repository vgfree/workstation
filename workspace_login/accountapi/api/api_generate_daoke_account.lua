---- zhouzhe
---- 2015-08-11
---- 第三方用户注册：1）获取第三方用户授权信息(生成accountID)

local ngx       = require('ngx')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local only      = require('only')
local gosay     = require('gosay')
local utils     = require('utils')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local http_api  = require('http_short_api')
local account_utils  = require('account_utils')

local reward_srv    = link["OWN_DIED"]["http"]["rewardapi"]

local usercenter_dbname = 'app_usercenter___usercenter'
local usercrowd_dbname = 'app_crowd___crowd'

local cur_time = os.time()

local third_plat = {
    5,  -- 微信注册
    7,  -- 凯立德账号注册
}

local G = {

    -->> 检查是否存在第三方注册表
    sql_check_account_info = " SELECT 1 FROM userLoginInfo WHERE accountID='%s' ",

    -->> 保存数据到第三方注册数据库
    sql_save_register_info="INSERT INTO thirdAccessOauthInfo SET account='%s', accountID='%s', userStatus=1, loginType=%d,"..
        "createTime=%d, updateTime=%d, token='%s', refreshToken='%s', accessToken='%s', accessTokenExpiration='%s'",

    -->> 获取第三方用户注册信息
    sql_get_oauth_info = "SELECT * FROM thirdAccessOauthInfo WHERE account='%s'",

    -->> 账号绑定wecode
    sql_get_wecode_info = "SELECT WECode FROM WECodeInfo WHERE accountID = '' AND WECodeStatus=0 AND"..
                                    " rewardsType=%s AND amountType=%s AND disabledTime>%d LIMIT %d",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->> 检查参数
local function check_parameter(args)
    if not args or type(args) ~= "table" then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    for key, value in pairs(args) do
        local parameter = tostring(value or '')
        local str_res = string.find(parameter, "'")
        local str_tmp = string.find(parameter, "%%")
        if str_res or str_tmp then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], key )
        end
    end

    if not args['appKey'] or #args['appKey'] < 1 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "appKey")
    end

    local isthird = nil
    for _, value in pairs(third_plat) do
        if tonumber(args['loginType']) == tonumber(value) then
            isthird = true
            break
        end
    end
    if not isthird then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "loginType")
    end

    if not args['account'] or #args['account'] <1 or #args['account'] >= 64 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "account")
    end
    safe.sign_check(args, url_info)
end

-->> 生成accountID
local function gen_account_id()
    local accountid, sql
    while true do
        accountid = utils.random_string(10)
        sql = string.format(G.sql_check_account_info, accountid)
        local ok, result = mysql_api.cmd(usercenter_dbname, 'select', sql)
        if ok and #result==0 then
            break
        end
    end
    only.log('D', "new user accountID===%s", accountid)
    return accountid
end

-->> 保存昵称到 redis
function save_userinfo_redis( accountID, nickname )
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

-->> 获取昵称
local function get_nick_name(account_id)
    local ok, nickname = redis_api.cmd("private", "get", account_id .. ":nickname")
    return nickname or ""
end

-->> 数据库检查参数，判断新老用户
local function check_user_account( account )
    -->> 检查是否存在第三方注册表
    sql = string.format(G.sql_get_oauth_info, account)
    only.log('D', string.format("==22==check user account==%s", sql))
    local ok, result = mysql_api.cmd( usercenter_dbname, 'SELECT', sql )
    if not ok or not result then
        gosay.go_false( url_info, msg["MSG_DO_MYSQL_FAILED"] )
    end
    if #result > 0 then
        -- 不是新注册用户
        return 0, result[1]
    else
        -- 新注册用户
        return 1, nil
    end
end

-->> 保存数据到第三方注册数据库
local function save_third_Info(args)

    local sql = string.format(G.sql_save_register_info, args['account'],
                                                    args['accountID'],
                                                    args['loginType'], cur_time, cur_time, 
                                                    args['token'],
                                                    args['refreshToken'],
                                                    args['accessToken'],
                                                    args['accessTokenExpiration'] )
    only.log('D', string.format("save register info==%s", sql))
    local ok = mysql_api.cmd( usercenter_dbname, 'INSERT', sql )
    if not ok then
        gosay.go_false( url_info, msg["MSG_DO_MYSQL_FAILED"] )
    end
end

-->> 判断用户是否为道客用户
local function get_user_loginiInfo( accountID )
    sql = string.format(G.sql_check_account_info, accountID)
    only.log('D', string.format("=11=check login info==%s", sql))
    local ok, result = mysql_api.cmd( usercenter_dbname, 'SELECT', sql )
    if not ok then
        gosay.go_false( url_info, msg["MSG_DO_MYSQL_FAILED"] )
    end
    if #result >0 then
        -->> 已有道客用户账号
        return 1
    else
        -->> 没有道客用户账号
        return 0
    end
end

-->> 生成wecode
local function create_wecode( reward_type)
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
        ok = create_wecode(rewardsType)
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
            only.log('D', string.format('==Last select_wecode_result is ==:%s',result[num]['WECode']))
            break
        else
            only.log('E',string.format('Call bindUserWECode error,ERRORCODE:%s',ret_body['ERRORCODE']))
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
    check_parameter(args)
    url_info['app_key'] = args['appKey']
    if args['nickname'] and #args['nickname']> 0 then
        args['nickname'] = utils.url_decode(args['nickname'])
    end

    local account = args['account']
    local nickname, accountID = args['nickname'], nil
    local isNew, res_table = check_user_account( account )
    local result_body={}

    -->> 新用户
    if tonumber(isNew)==1 then
        -->> 生成acountID
        accountID = gen_account_id()
        args['accountID'] = accountID
        -->> 保存第三方注册用户信息
        save_third_Info(args)

        result_body = {
            ["accountID"] = accountID,
            ["nickname"] = nickname,
            ["isNew"] = isNew,
            ["isHasDaokeAccount"] = get_user_loginiInfo( accountID ),
            ["registerTime"] = cur_time,
            ["lastLoginTime"] = cur_time,
            ["token"] = args['token'],
            ["refreshToken"] = args['refreshToken'],
            ["accessToken"] = args['accessToken'],
            ["accessTokenExpiration"] = args['accessTokenExpiration'],
        }
        if nickname and #nickname >0 then
            -->> 保存nickname redis
            local ok= save_userinfo_redis( accountID, nickname )
            if not ok then
                gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
            end
        end

        -->> accountID绑定wecode,尝试三次
        local times = 3
        for i=1, times do
            local ok = accountid_bind_user_wecode( accountID )
            if ok then
                break
            else
                only.log("W", string.format("=WIN===bindimeiAPI==bind wecode failed, accountid: %s", accountID ))
            end
        end
    end

    -->> 已有用户
    if tonumber(isNew)==0  then
        accountID = res_table['accountID']
        result_body = {
            ["accountID"] = accountID,
            ["nickname"] = get_nick_name( accountID ),
            ["isNew"] = isNew,
            ["isHasDaokeAccount"] = get_user_loginiInfo( accountID ),
            ["registerTime"] = res_table['createTime'],
            ["lastLoginTime"] = res_table['updateTime'],
            ["token"] = res_table['token'],
            ["refreshToken"] = res_table['refreshToken'],
            ["accessToken"] = res_table['accessToken'],
            ["accessTokenExpiration"] = res_table['accessTokenExpiration'],
        }
    end

    local ok, ret = utils.json_encode(result_body)

    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end

safe.main_call( handle )
