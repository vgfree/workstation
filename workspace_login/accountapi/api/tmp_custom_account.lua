--author	: chenzutao
--date		: 2013-12-27
--fixed		: baoxue
--date		: 2013-12-30

-- update by zhangjl (jayzh1010 at gmail.com) 2014-01-20

local ngx = require ('ngx')
local sha = require('sha1')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api = require('http_short_api')
local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local safe = require('safe')

local link = require('link')
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
    update_info = [[ UPDATE userInfo SET status=2 WHERE accountID='%s' ]],
    insert_weibo_user = [[ INSERT INTO userGroupInfo (accountID,groupID,validity) VALUES ('%s','mirrtalkAll',1) ]],
    update_weibo_user = [[ UPDATE userGroupInfo SET validity=0 WHERE accountID='%s' AND groupID='mirrtalkAll' ]],

    select_wecode = "SELECT WECode FROM WECodeInfo WHERE WECodeStatus=0 AND rewardsType=%s AND amountType=%s AND disabledTime>%d",
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(body)

    local res = utils.parse_url(body)
    url_info['app_key'] = res['appKey']

    res["accountType"] = tonumber(res["accountType"])
    -->> check username
    if res["username"] then
        if ((not string.find(res["username"], '^%w[%w%_%d]+$')) or (#res["username"] > 64)) then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username")
        end
        if res["accountType"] ~= 1 then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username, accountType doesn't match")
        end

    end
    -->> check mobile
    if (not res['username']) and res["mobile"]  then
        if ((not utils.is_number(res["mobile"])) or (#res["mobile"] ~= 11) or (string.sub(res["mobile"], 1, 1) ~= '1')) then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile")
        end 
        if res["accountType"] ~= 2 then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mobile, accountType doesn't match")
        end 
    end 
    -->> check email
    if (not res['username']) and (not res['mobile']) and res["userEmail"] then
        if ((not string.find(res["userEmail"], '@')) or #(res["userEmail"]) > 64) then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail")
        end 
        if res["accountType"] ~= 3 then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "userEmail, accountType doesn't match")
        end 
    end 

    -- at least exist one
    if not (res["username"] or res["mobile"] or res["userEmail"]) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "username, mobile, userEmail, need at least one")
    end 

    -->> check daokePassword
    if (not res["daokePassword"]) or (string.len(res["daokePassword"]) < 6) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "daokePassword")
    end 

    -->> check nickname
    if not res["nickname"] then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "nickname")
    end 
    -- res["nickname"] = utils.url_decode(res["nickname"])

    -- if res["name"] then
    --     res["name"] = utils.url_decode(res["name"])
    -- end

    -- if res["plateNumber"] then
    --     res["plateNumber"] = utils.url_decode(res["plateNumber"])
    -- end

    if res["gender"] and not string.find('0,1', res['gender']) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "nickname")
    end 
    safe.sign_check(res, url_info)

    return res
end

local function check_user_account( res )

    local sql, key, val
    if res['username'] then
        key, val = 'username', string.lower(res['username'])
    elseif res['mobile'] then
        key, val = 'mobile', res['mobile']
    else
        key, val = 'userEmail', res['userEmail']
    end
    sql = string.format(sql_fmt.check_user, key, val)

    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'SELECT', sql)

    if ok and #result ~= 0 then
        -- gosay.go_false(url_info, msg["MSG_ERROR_IS_EXIST"], key)
        return false
    end
    return true
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

    res_sql = string.format(sql_fmt.insert_weibo_user, args["accountID"])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'INSERT', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

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

    local res_sql = string.format(sql_fmt.update_info, account_id)
    only.log('D', res_sql)
    mysql_pool_api.cmd('app_cli___cli', 'UPDATE', res_sql)

    res_sql = string.format(sql_fmt.update_weibo_user, account_id)
    only.log('D', res_sql)
    mysql_pool_api.cmd('app_weibo___weibo', 'UPDATE', res_sql)

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
        tab_sql[3] = string.format(sql_fmt.insert_userRegisterInfo .. add_sql, args['accountID'], string.lower(username), cur_time)
    elseif account_type == 2 then
        local add_sql = ",checkMobile=1,mobile='%s',checkUserEmail=0"
        tab_sql[3] = string.format(sql_fmt.insert_userRegisterInfo .. add_sql, args['accountID'], string.lower(username),cur_time, args["mobile"] or "")
    else
        local add_sql = ",checkUserEmail=1,checkMobile=0,userEmail='%s'"
        tab_sql[3] = string.format(sql_fmt.insert_userRegisterInfo .. add_sql, args['accountID'], string.lower(username),cur_time, args["userEmail"] or "" )
    end

    if args["loginType"] == 2 then
        tab_sql[4] = string.format(sql_fmt.update_register_status, 'checkMobile', args['accountID'])
    elseif args["loginType"] == 3 then
        tab_sql[4] = string.format(sql_fmt.update_register_status, 'checkUserEmail', args['accountID'])
    end

    only.log('D', tab_sql[1])
    only.log('D', tab_sql[2])
    only.log('D', tab_sql[3])
    only.log('D', tab_sql[4])

    local ok, ret = mysql_pool_api.cmd('app_usercenter___usercenter', 'AFFAIRS', tab_sql)
    if not ok then
        only.log('E',string.format('transaction failed, tab:[%s],[%],[%s],[%s]', tab_sql[1], tab_sql[2], tab_sql[3], tab_sql[4] or ''))

        --> update status to 2
        update_user_status(args['accountID'])
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
end

function save_redis( args )
    -->> connect redis
    for i=1, 3 do
        -->> set nickname
        local ok, ret = redis_pool_api.cmd('private', 'set', args["accountID"] .. ":nickname", args["nickname"])
        -->> set client
        if ok then
            return true
        end
        if i == 3 then
            only.log(url_info, "FAILED set nickname and client_mirrtalk 3 count")
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
 --updated by xuyafei in 2014.11.18  
 --更新详情：将原来获取secret的方式由kv方式变为哈系方式，open/public/utils.lua中封装了一个函数：function get_secret( app_key )，传入appkey值后这个函数就会以hget的方式去获取secret。
    local secret = app_utils.get_secret(tab["appKey"])
    if not secret  then
        only.log('E','get secret failed from redis!')
        gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
    end

    local sign = app_utils.gen_sign(tab, secret)

    local body = string.format('WECode=%s&appKey=%s&sign=%s&accountID=%s', wecode, tab['appKey'], sign, account_id)

    local post_body = utils.post_data('rewardapi/v2/bindUserWECode', reward_srv, body)

    only.log('D', post_body)
    local ret_body = http_api.http(reward_srv, post_body, true)
    only.log('D', ret_body)

end



local function handle(tmp_imei)



    -- local body = ngx.req.get_body_data()
    -- url_info['client_body'] = body

    -- only.log('D', body)

    -->| STEP 1 |<--
    -->> check parameters
    -- local res = check_parameter(body)

    local res = {}
    res['appKey'] = 286302235
    url_info['app_key'] = res['appKey']
    url_info['client_host'] = ngx.var.remote_addr

    res['username'] =  'caa' .. tmp_imei
    res['accountType'] = 1
  --  res['daokePassword'] = 'na' .. string.sub(tmp_imei, -4, -1)
    res['daokePassword'] = 'caa123456'
    res['nickname'] =  'caa' .. string.sub(tmp_imei, -4, -1)

    local ret = check_user_account( res )

                only.log('D', ret)
                only.log('D', tmp_imei)

    if not ret then
        return
    end

    only.log('D', os.time())
    -->> gen accountID
    res["accountID"] = gen_account_id( )

    -->> save userInfo
    save_user_info( res )

    -->> save redis
    save_redis( res )

    -->> save userCenter
    save_user_center( res )

    local types = {
        [2] = { 4 },
    }

    local cur_time = os.time()
    for i, v in pairs(types) do

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
            bind_wecode(res['accountID'], result[1]['WECode'])
        end
    end


    local ret = string.format('{"accountID":"%s"}', res["accountID"])

    -- gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)

end

--[[
local ok, result = mysql_pool_api.cmd('app_shipment___shipment', 'SELECT', "SELECT imei FROM deviceConsigneeDetailInfo where tradeNumber='Z1420962302482'")

only.log('D', ok)
only.log('D', result)

for k, v in pairs(result) do
    only.log('D', v['imei'])
    handle(string.sub(v['imei'], -5, -1))
end
--]]
    handle(string.sub('282455622776107', -5, -1))
gosay.go_success(url_info, msg["MSG_SUCCESS"])

