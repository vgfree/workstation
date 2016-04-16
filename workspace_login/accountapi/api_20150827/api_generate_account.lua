
local ngx = require('ngx')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local http_api = require('http_short_api')
local app = require('app')

local link = require('link')

local user_info_srv = link["OWN_DIED"]["http"]["fixUserInfo"]
local reward_srv = link["OWN_DIED"]["http"]["rewardapi"]


local sql_fmt = {

    query_accountid = "SELECT accountID FROM loginType WHERE account='%s' AND loginType = %d AND userStatus in (1,3) AND accountSourceType=1",
    update_account_info = "UPDATE loginType SET token='%s',refreshToken='%s',accessToken='%s',accessTokenExpiration='%s' WHERE account='%s' AND loginType = %d AND userStatus in (1,3) AND accountSourceType=1",
    has_account = "SELECT 1 FROM userRegisterInfo WHERE accountID='%s'",
    get_registTime = "SELECT updateTime FROM userListHistory WHERE accountID='%s' ORDER BY updateTime DESC limit 1",

    get_loginTime = "SELECT lastLoginTime FROM loginLog WHERE account = '%s'",

    check_accountid = "SELECT id FROM userList WHERE accountID = '%s'",

    user_info_add_record = "INSERT INTO userInfo SET accountID='%s', status='1',nickname='%s',createTime=%d",

    user_list_add_record = "INSERT INTO userList SET accountID = '%s', userStatus = 4, updateTime = %d, createTime=%d",
    user_list_history_add_record = "INSERT INTO userListHistory SET accountID = '%s', userStatus = 4, updateTime = %d",
    login_type_add_record = "INSERT INTO loginType SET accountID = '%s', loginType = %d, createTime = %d, account = '%s', userStatus = 1,accountSourceType=1,token='%s',refreshToken='%s',accessToken='%s',accessTokenExpiration='%s'",

    update_user_info = "UPDATE userInfo SET status = '2' WHERE accountID = '%s'",

    insert_weibo_user = "INSERT INTO userGroupInfo (accountID,groupID,validity) VALUES ('%s','mirrtalkAll',1)",
    update_weibo_user = "UPDATE userGroupInfo SET validity=0 WHERE accountID='%s' AND groupID='mirrtalkAll'",

    select_wecode = "SELECT WECode FROM WECodeInfo WHERE WECodeStatus=0 AND rewardsType=%s AND amountType=%s AND disabledTime>%d",

}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function write_client_mirrtalk(account_id, nickname)

    local cur_time = os.time()
    local sql = string.format(sql_fmt.user_info_add_record, account_id, nickname or '', cur_time)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_cli___cli', 'insert', sql)

    if ok then
        sql = string.format(sql_fmt.insert_weibo_user, account_id)
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql)
    end

    return ok
end

local function update_user_info_status(account_id)

    local sql = string.format(sql_fmt.update_user_info, account_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_cli___cli', 'update', sql)

    if ok then
        sql = string.format(sql_fmt.update_weibo_user, account_id)
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'update', sql)
    end

    return ok
end

local function gen_account_id()

    local account_id, sql, ret
    while true do
        account_id = utils.random_string(10)
        sql = string.format(sql_fmt.check_accountid, account_id)
        only.log('D', sql)
        local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)
        if ok and #result==0 then
            break
        end
    end

    return account_id
end

local function update_user_list(account_id, jo)

    local cur_time = os.time()
    local sql_tab = {
        [1] = string.format(sql_fmt.user_list_add_record, account_id, cur_time, cur_time),
        [2] = string.format(sql_fmt.user_list_history_add_record, account_id, cur_time),
        [3] = string.format(sql_fmt.login_type_add_record, account_id, jo['loginType'], cur_time, jo['account'], jo["token"] or "", jo["refreshToken"] or "", jo["accessToken"] or "", jo["accessTokenExpiration"] or ""),
    }
        only.log('D', sql_tab[1])
        only.log('D', sql_tab[2])
        only.log('D', sql_tab[3])

    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'affairs', sql_tab)

    return ok
end

local function touch_redis(account_id, nick_name)

    --write nickname to redis--
    if nick_name then
        redis_pool_api.cmd("private", "set", account_id .. ':nickname', nick_name)
    end

end

local function get_nick_name(account_id)
    --get nickname from redis--
    local ok, nickname = redis_pool_api.cmd("private", "get", account_id .. ':nickname')
    return nickname
end

local function check_has_account( account_id )

    local sql = string.format(sql_fmt.has_account, account_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)

    if ok and #result >= 1 then
        return 1
    else
        return 0
    end
end

local function get_register_time( account_id )

    local sql = string.format(sql_fmt.get_registTime, account_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)

    local time
    if ok and #result~=0 then
        time = result[1]["updateTime"] or ''
    else
        time = ''
    end

    return time
end

local function get_login_time( account )

    local sql = string.format(sql_fmt.get_loginTime, account)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_daokeme___daokeme', 'select', sql)

    local cur_time = os.time()
    local time
    if ok and #result~=0 then
        time = result[1]['lastLoginTime'] or ''
        -- sql = string.format(sql_fmt.update_loginTime, url_info['client_host'], cur_time, account)
        -- only.log('D', sql)
        -- mysql_pool_api.cmd('app_daokeme___daokeme', 'update', sql)

    else
        time = ''
        -- sql = string.format(sql_fmt.insert_loginTime, account, url_info['client_host'], cur_time)
        -- only.log('D', sql)
        -- mysql_pool_api.cmd('app_daokeme___daokeme', 'insert', sql)
    end


    return time
end

local function check_account( jo )

    local sql = string.format(sql_fmt.query_accountid, jo["account"], jo["loginType"])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', sql)

    if not ok then
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result==0 then
        return true
    end

    if jo["token"] then
        sql = string.format(sql_fmt.update_account_info, jo["token"], jo["refreshToken"] or "", jo["accessToken"], jo["accessTokenExpiration"], jo["account"], jo["loginType"])
        only.log('D', sql)
        mysql_pool_api.cmd('app_usercenter___usercenter', 'update', sql)
    end
    local account_id = result[1]["accountID"]

    if jo["nickname"] then
        local old_nickname = get_nick_name( account_id )
        if not old_nickname then
            local body = string.format('accountID=%s&nickname=%s', account_id, jo['nickname'])

            local post_body = utils.post_data('/v2/fixUserInfo', user_info_srv, body)

            only.log('D', post_body)
            local ret_body = http_api.http(user_info_srv, post_body, true)
            only.log('D', ret_body)
        end
    end

    local result_body = {
        ["accountID"] = account_id,
        ["isNew"] = 0,
        ["isHasDaokeAccount"] = check_has_account( account_id ),
        ["registerTime"] = get_register_time( account_id ),
        ["lastLoginTime"] = get_login_time( jo["account"] ),
        ["token"] = jo["token"],
        ["refreshToken"] = jo["refreshToken"],
        ["accessToken"] = jo["accessToken"],
        ["accessTokenExpiration"] = jo["accessTokenExpiration"],
        ["nickname"] = get_nick_name( account_id ),
    }

    local ok,data = utils.json_encode(result_body)
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], data)

end

local function create_wecode(cur_time, reward_type)

    local cur_time = os.time()
    local cur_year = os.date('%Y', cur_time)
    local cur_month = os.date('%m', cur_time)
    local cur_day = os.date('%d', cur_time)
    local next_time = os.time( { year=cur_year+1, month=cur_month, day=cur_day } )

    local tab = {
        appKey = url_info['app_key'],
        rewardsType = reward_type,
        disabledTime = next_time,
        createCount = 100,
    }

    local ok, secret = redis_pool_api.cmd("public", "get", tab["appKey"] .. ':secret')
    if not ok or secret == nil then
        return false
    end

    local sign = utils.gen_sign(tab, secret)

    local body = string.format('appKey=%s&sign=%s&rewardsType=%s&disabledTime=%s&createCount=%s', tab['appKey'], sign, tab['rewardsType'], next_time, tab['createCount'])

    local post_body = utils.post_data('rewardapi/v2/createWECode', reward_srv, body)

    only.log('D', post_body)
    local ret_body = http_api.http(reward_srv, post_body, true)
    only.log('D', ret_body)

end

local function bind_wecode(account_id, wecode)

    local tab = {
        appKey = url_info['app_key'],
        accountID = account_id,
        WECode = wecode,
    }

    local ok, secret = redis_pool_api.cmd("public", "get", tab["appKey"] .. ':secret')
    if not ok or secret == nil then
        return false
    end

    local sign = utils.gen_sign(tab, secret)

    local body = string.format('WECode=%s&appKey=%s&sign=%s&accountID=%s', wecode, tab['appKey'], sign, account_id)

    local post_body = utils.post_data('rewardapi/v2/bindUserWECode', reward_srv, body)

    only.log('D', post_body)
    local ret_body = http_api.http(reward_srv, post_body, true)
    only.log('D', ret_body)

end

local function parse_body(str)

    local res = utils.parse_url(str)
    url_info['app_key'] = res['appKey']

    ---check loginType---
    res['loginType']= tonumber(res['loginType'])
    if res['loginType']~=5 and res['loginType']~=6 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "loginType")
    end

    ---check account---
    if (not res['account'] or #res['account'] >= 64) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "account")
    end

    --- these arguments is bound together ---
    if not ( ((not res["token"]) and (not res["accessToken"]) and (not res["accessTokenExpiration"])) or (res["token"] and res["accessToken"] and res["accessTokenExpiration"]) ) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "token")
    end

    ---nickname is selectable---
    if res['nickname'] then
        res['nickname'] = utils.url_decode(res['nickname'])
    end

    app.new_safe_check(res, url_info)

    return res 
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    only.log('D', body)

    local handle_body = parse_body(body)

    -->> check accout
    check_account( handle_body )

    local account_id = gen_account_id()

    local result = write_client_mirrtalk(account_id, handle_body['nickname'])

    if not result then
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    result = update_user_list(account_id, handle_body)

    if not result then
        result = update_user_info_status(account_id)
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    touch_redis(account_id, handle_body['nickname'])

    local types = {
        [1] = { 3 },
        [2] = { 4 },
    }

    local cur_time = os.time()
    for i, v in ipairs(types) do

        for _, j in ipairs(v) do
            local sql = string.format(sql_fmt.select_wecode, j, i, cur_time)
            only.log('D', sql)
            local ok, result = mysql_pool_api.cmd('app_crowd___crowd', 'select', sql)
            if not ok then
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
            end

            if #result == 0 then

                -- create wecode
                create_wecode(cur_time, j)
                local sql = string.format(sql_fmt.select_wecode, j, i, cur_time)
                only.log('D', sql)
                ok, result = mysql_pool_api.cmd('app_crowd___crowd', 'select', sql)

                if not ok then
                    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
                end
            end

            -- bind wecode
            bind_wecode(account_id, result[1]['WECode'])
        end
    end

    local result_body = {
        ["accountID"] = account_id,
        ["isNew"] = 1,
        ["isHasDaokeAccount"] = check_has_account( account_id ),
        ["registerTime"] = get_register_time( account_id ),
        ["lastLoginTime"] = get_login_time( handle_body["account"] ),
        ["token"] = handle_body["token"],
        ["refreshToken"] = handle_body["refreshToken"],
        ["accessToken"] = handle_body["accessToken"],
        ["accessTokenExpiration"] = handle_body["accessTokenExpiration"],
        ["nickname"] = get_nick_name( account_id ),
    }

    local ok,data = utils.json_encode(result_body)

    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], data)
end


handle()

-- EOF
