--author	: chenzutao
--date		: 2013-12-27
--fixed		: baoxue
--date		: 2013-12-30

-- update by zhangjl (jayzh1010 at gmail.com) 2014-01-20
local ngx            = require ('ngx')
local sha            = require('sha1')
local utils          = require('utils')
local app_utils     = require('app_utils')
local only           = require('only')
local msg            = require('msg')
local gosay          = require('gosay')
local safe           = require('safe')
local link           = require('link')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api       = require('http_short_api')

---- add by jiang z.s. 2014-09-09 set nickname
local account_utils  = require('account_utils')

local reward_srv = link["OWN_DIED"]["http"]["rewardapi"]

local sql_fmt = {

    check_user = [[ SELECT 1 FROM userRegisterInfo where %s = '%s']],

    check_accountid = [[SELECT id FROM userList WHERE accountID = '%s']],

    save_user_info = [[ INSERT INTO userInfo SET accountID='%s',status=1,nickname='%s',mobile=%s,userEmail='%s',gender=%s,name='%s',plateNumber='%s',createTime=%d,updateTime=%d ]],

    update_check_time = [[ UPDATE userInfo SET %s=%d WHERE accountID='%s' ]],

    insert_userList = [[ INSERT INTO userList SET daokePassword='%s', accountID='%s',userStatus=4, createTime=%d, updateTime=%d ]],
    insert_userListHistory = [[ INSERT INTO userListHistory SET daokePassword='%s', accountID='%s',userStatus=4, updateTIme=%d]],
    insert_userRegisterInfo = [[ INSERT INTO userRegisterInfo SET accountID='%s', username='%s',createTime=%d,validity=1 ]],
    update_register_status = [[ UPDATE userRegisterInfo SET %s=1 WHERE accountID='%s' ]],
    update_info = [[ UPDATE userInfo SET status=2, updateTime=%d WHERE accountID='%s' ]],

    -- insert_weibo_user = [[ INSERT INTO userGroupInfo (accountID,groupID,validity) VALUES ('%s','mirrtalkAll',1) ]],
    -- update_weibo_user = [[ UPDATE userGroupInfo SET validity=0 WHERE accountID='%s' AND groupID='mirrtalkAll' ]],

    select_wecode = "SELECT WECode FROM WECodeInfo WHERE accountID = '' AND WECodeStatus=0 AND rewardsType=%s AND amountType=%s AND disabledTime>%d LIMIT %d",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-- 2015-06-02zhouzhe 参数中不能出现%号（代码错误）和'号（数据库错误)
local function check_character( parameter )

    local str_res = string.find(parameter,"'")
    local str_tmp = string.find(parameter,"%%")
    if str_res or str_tmp then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "Parameter")
    end
end

local function check_parameter(body)

    local res = utils.parse_url(body)
    if not res or type(res) ~= "table" then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end

    if not res['appKey'] then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_FAILED_GET_SECRET"])
    end

    -- 2015-06-02 zhouzhe 
    local str_parameter = ""
    for _,v in pairs(res) do
        if not v then
            v = ""
        end
        local str = tostring(v)
        str_parameter = str_parameter..str
    end 
    check_character(str_parameter)
    -- 2015-06-02 zhouzhe  end

    --only.log('D',string.format('res from body:%s',res))
    url_info['app_key'] = res['appKey']

    res["accountType"] = tonumber(res["accountType"])

    if res["accountType"] == 1 then
        -->> check username
        if res["username"] and res["username"] ~="" then

            res['username'] = ngx.unescape_uri(res['username'])

            res['username'] = string.lower(res['username'])
            if ((not string.match(res["username"], '^%l[%w%_%d]+$')) or (#res["username"] > 64)) then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username")
            end
        else
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username, accountType doesn't match")
        end
            -- if res["accountType"] ~= 1 then
            --     gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username, accountType doesn't match")
            -- end
        -- end

    elseif res['accountType'] == 2 then
        -->> check mobile
        if (not res['username']) and res["mobile"] and res["mobile"] ~= "" then

            if ((not utils.is_number(res["mobile"])) or (#res["mobile"] ~= 11) or (string.sub(res["mobile"], 1, 1) ~= '1')) then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile")
            end
        else
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile, accountType doesn't match")
        end
        --     if res["accountType"] ~= 2 then
        --         gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile, accountType doesn't match")
        --     end
        -- end 
    elseif res['accountType'] == 3 then
        -->> check email
        if (not res['username']) and (not res['mobile']) and res["userEmail"] and res["userEmail"] ~= "" then
            if ((not string.find(res["userEmail"], '@')) or #(res["userEmail"]) > 64) then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail")
            end
        else
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail, accountType doesn't match")
        end
        --     if res["accountType"] ~= 3 then
        --         gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail, accountType doesn't match")
        --     end 
        -- end 
    else
        -- at least exist one
        if not (res["username"] or res["mobile"] or res["userEmail"]) then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username, mobile, userEmail, need at least one")
        end
    end

    -->> check daokePassword
    if (not res["daokePassword"]) or (string.len(res["daokePassword"]) < 6) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "daokePassword")
    end

    -->> check nickname
    if not res["nickname"] then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "nickname")
    end
    -- sign check
    safe.sign_check(res, url_info)

    res["nickname"] = utils.url_decode(res["nickname"])
    -- if res["name"] then
    --     res["name"] = utils.url_decode(res["name"])
    -- end

    -- if res["plateNumber"] then
    --     res["plateNumber"] = utils.url_decode(res["plateNumber"])
    -- end

    if res["gender"] and not string.find('0,1', res['gender']) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "nickname")
    end 

    return res
end

-- 操作间隔时间控制 20150728 zhouzhe
local function check_times(value)
    only.log('D', string.format('redis check_times==value = %s',value))
    local TIME = 5 -- 5s
    local ok,ret = redis_pool_api.cmd('private','get',value..':applyTimes')
    if not ok then
        only.log('E', string.format('redis failed!,value = %s', value))
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end
    if ret then
        only.log('E', string.format('====This user apply withdraw money more than one  in 5 second ,value = %s',value))
        gosay.go_false(url_info, msg['MSG_ERROR_SYSTEM_BUSY'])
    end

    local ok,ret = redis_pool_api.cmd('private','set',value..':applyTimes',"1")
    if not ok then
        only.log('E', string.format('redis failed!, value = %s', value))
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end

    local ok,ret = redis_pool_api.cmd('private','expire', value..':applyTimes', TIME)
    if not ok then
        only.log('E', string.format('redis failed!, value = %s',value))
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end
end

local function check_user_account( res )

    local sql, key, val
    if res['username'] then
        key, val = 'username', res['username']
    elseif res['mobile'] then
        key, val = 'mobile', res['mobile']
    else
        key, val = 'userEmail', res['userEmail']
    end
    sql = string.format(sql_fmt.check_user, key, val)

    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'SELECT', sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if ok and #result ~= 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_USER_NAME_EXIST"])
    end
    return val
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

local function save_user_info( args )

    local cur_time = os.time()
    local res_sql = string.format(sql_fmt.save_user_info, args["accountID"], args["nickname"] or '', args["mobile"] or 0, args["userEmail"] or '', args["gender"] or 3, args["name"] or '', args["plateNumber"] or '', cur_time, cur_time)
    only.log('D', res_sql)

    local ok, result = mysql_pool_api.cmd('app_cli___cli', 'INSERT', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    -- res_sql = string.format(sql_fmt.insert_weibo_user, args["accountID"])
    -- only.log('D', res_sql)
    -- local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'INSERT', res_sql)
    -- if not ok then
    --     gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    -- end

    if args["accountType"] == 2 then
        res_sql = string.format(sql_fmt.update_check_time, 'checkMobileTime', cur_time, args["accountID"])
    elseif args["accountType"] == 3 then
        res_sql = string.format(sql_fmt.update_check_time, 'checkUserEmailTime', cur_time, args["accountID"])
    else
        return
    end
    only.log('D', res_sql)

    local ok, result = mysql_pool_api.cmd('app_cli___cli', 'UPDATE', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

end

local function update_user_status(account_id)

    local cur_time = os.time()
    local res_sql = string.format(sql_fmt.update_info, cur_time, account_id)
    only.log('D', res_sql)
    mysql_pool_api.cmd('app_cli___cli', 'UPDATE', res_sql)

    -- res_sql = string.format(sql_fmt.update_weibo_user, account_id)
    -- only.log('D', res_sql)
    -- mysql_pool_api.cmd('app_weibo___weibo', 'UPDATE', res_sql)

end

local function save_user_center(args)
    local tab_sql = {}
    local username = args['username'] or ''

    local cur_time = os.time()
    local password = ngx.md5(sha.sha1(args['daokePassword']) .. ngx.crc32_short(args['daokePassword']))
    tab_sql[1] = string.format(sql_fmt.insert_userList, password, args['accountID'], cur_time, cur_time)
    tab_sql[2] = string.format(sql_fmt.insert_userListHistory, password, args['accountID'], cur_time)
    local account_type = tonumber(args["accountType"])

    if account_type == 1 then
        local add_sql = ",checkMobile=0,checkUserEmail=0"
        tab_sql[3] = string.format(sql_fmt.insert_userRegisterInfo .. add_sql, args['accountID'], username, cur_time)
    elseif account_type == 2 then
        local add_sql = ",checkMobile=1,mobile='%s',checkUserEmail=0"
        tab_sql[3] = string.format(sql_fmt.insert_userRegisterInfo .. add_sql, args['accountID'], username, cur_time, args["mobile"] or "")
    else
        local add_sql = ",checkUserEmail=1,checkMobile=0,userEmail='%s'"
        tab_sql[3] = string.format(sql_fmt.insert_userRegisterInfo .. add_sql, args['accountID'], username, cur_time, args["userEmail"] or "" )
    end

    if args["loginType"] == 2 then
        tab_sql[4] = string.format(sql_fmt.update_register_status, 'checkMobile', args['accountID'])
    elseif args["loginType"] == 3 then
        tab_sql[4] = string.format(sql_fmt.update_register_status, 'checkUserEmail', args['accountID'])
    end

    only.log('D',string.format(" sql : %s " ,table.concat( tab_sql, "\r\n") ))

    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'AFFAIRS', tab_sql)
    if not ok then
        only.log('E',string.format('transaction failed, tab:[%s],[%s],[%s],[%s]', tab_sql[1], tab_sql[2], tab_sql[3], tab_sql[4] or ''))

        --> update status to 2
        update_user_status(args['accountID'])
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
end

function save_redis( args )
    -->> connect redis
    for i=1, 3 do
        -->> set nickname
        -- local ok, ret = redis_pool_api.cmd('private', 'set', args["accountID"] .. ":nickname", args["nickname"])
        -- modify by jiang z.s. 2014-09-09 set nickname succ then save the url to redis
        local ok,res = account_utils.set_nickname(args["accountID"], args["nickname"])
        -->> set client
        if ok then
            return true
        end
        if i == 3 then
            only.log('E', "FAILED set nickname and client_mirrtalk 3 count")
        end
    end

    --> update status to 2
    update_user_status(args['accountID'])

    gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
end

local function create_wecode(cur_time, reward_type)

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

    local ok, secret = redis_pool_api.cmd("public", "hget", tab["appKey"] .. ':appKeyInfo', 'secret')
    if not ok or not secret then
        return false
    end

    local sign = app_utils.gen_sign(tab, secret)

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

    local ok, ret__body = utils.json_decode(body)
    if not ok  then
        only.log('E',string.format("MSG_ERROR_REQ_BAD_JSON: %s", body ))
	   gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end
    if tonumber(ret__body['ERRORCODE']) ~= 0 then                         --如果调用bindUserWECode API 不成功,打印日志
         only.log('E',string.format('Call bindUserWECode error,ERRORCODE:%s',ret__body['ERRORCODE']))
         return ret__body
    end
    return ret__body
end

local function handle()

    local body = ngx.req.get_body_data()
    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    if not body then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    -->> check parameters
    local res = check_parameter(body)

    local val = check_user_account( res )

    check_times(val)

    -->> gen accountID
    res["accountID"] = gen_account_id( )

    -->> save userInfo
    save_user_info( res )

    -->> save redis
    save_redis( res )

    -->> save userCenter
    save_user_center( res )
    -- 2:押金类型 4:奖励类型
    local types = {
        [2] = { 4 },
    }

    -- 以下部分程序于2014.10.28进行了更新，更新后解决了在多线程情况下如果两个或多个用户取到了同一个WECode，而产生的绑定冲突的问题，
    -- 具体解决办法为：根据给定条件同时从数据库中取出5条WECode记录，并放入result表中，然后在绑定时如果出现冲突，就依次从result表中往下取下面的记录                                   
    local result = {}           --存放WECode记录
    local selnum = 5		     --要取的WECode记录条数
    local cur_time = os.time()
    for i, v in pairs(types) do
        for _, j in ipairs(v) do
            local sql = string.format(sql_fmt.select_wecode, j, i, cur_time,selnum)
            local ok, result = mysql_pool_api.cmd('app_crowd___crowd', 'select', sql)  
            if not ok or not result then
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
            end

           if #result ~= selnum then     --如果取出的条数不够5条，就去创建
                -- create wecode
                create_wecode(cur_time, j)
                ok, result = mysql_pool_api.cmd('app_crowd___crowd', 'select', sql)
                if not ok then
                    gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
                end
            end

            -- bind wecode
            local lastnum = 0
            for num = 1 ,selnum do	
                local ret__body =  bind_wecode(res['accountID'], result[num]['WECode'])
                if tonumber(ret__body['ERRORCODE']) == 0  then		--绑定WECode成功
                    --only.log('D', string.format('==Last select_wecode_result is ==:%s',result[num]['WECode']))
                    break
                elseif ret__body['ERRORCODE'] == 'ME18040' then           
                           --如果绑定冲突，继续取下面的记录,错误码ME18040为绑定冲突返回的错误码
                    num = num + 1
                    lastnum = num
                end
            end

            if lastnum >= selnum + 1 then           --循环五次后仍然存在冲突的情况
                --only.log('E',string.format('bindUserWECode Conflict,ERRORCODE:%s',ret_body['ERRORCODE']))
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'bindUserWECode')
            end
        end
    end

    local ret = string.format('{"accountID":"%s"}', res["accountID"])
    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )
