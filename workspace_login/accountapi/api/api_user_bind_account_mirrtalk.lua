-->[ower]: baoxue
-->[time]: 2013-09-02
-->accountID与IMEI绑定
-->2015-08-13 zhouzhe修改

local msg       = require('msg')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local ngx       = require ('ngx')
local sha       = require('sha1')
local app_utils = require('app_utils')
local link      = require('link')
local http_api  = require('http_short_api')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local reward_srv = link["OWN_DIED"]["http"]["rewardapi"]

local G = {
    sl_mirrtalk = "SELECT validity,status FROM mirrtalkInfo WHERE imei = %s AND nCheck = %s",

    sl_account = " SELECT accountID FROM userLoginInfo WHERE imei='%s' limit 1 ",

    sl_status = " SELECT imei FROM userLoginInfo WHERE userStatus=1 AND accountID='%s' ",

    upd_user_list = " UPDATE userLoginInfo SET updateTime=%s,imei='%s' WHERE accountID='%s' ",

    sql_insert_login_history = " INSERT INTO userLoginInfoHistory"..
                                "(accountID,username,mobile,userEmail,imei,userStatus,nickname,clientIP,createTime,updateTime,remark )"..
                                "SELECT accountID,username,mobile,userEmail,imei,userStatus,nickname,clientIP,createTime,updateTime,remark "..
                                "FROM userLoginInfo WHERE userStatus=1 AND accountID='%s' ",

    -->> 2015-07-14 zhouzhe 满足在绑定设备时更改imei所对应的rewardsType问题
    -- 1)查询之前accountID的rewardsType
    sl_user_WECodeInfo = " SELECT rewardsType FROM WECodeInfo WHERE accountID ='%s' AND rewardsType > 2 AND amountType=2 LIMIT 1 ",
    -- 2)查询当前imei的rewardsType  userMirrtalkInfo
    sl_user_imeistatus = " SELECT rewardsType FROM userMirrtalkInfo WHERE validity=1 AND imei=%s LIMIT 1 ",
    -- 3)查询当前imei的rewardsType  businessMirrtalkInfo
    sl_business_imeistatus = " SELECT rewardsType FROM businessMirrtalkInfo WHERE validity=1 AND imei=%s LIMIT 1 ",

    sql_get_business_list = " select rewardsType,  1 as bonusTarget from userMirrtalkInfo where validity = 1 and  imei = %s \r\n" .. 
                            " union all " .. 
                            " select rewardsType,  2 as bonusTarget from businessMirrtalkInfo where validity = 1  and imei = %s " , 


    -- 4)如果是新增奖励类型插入旧数据到WECodeHistory表
    ins_wecodehistory = "INSERT INTO WECodeHistory (WECode, rewardsType, amountType, WECodeStatus, "..
                        " disabledTime, accountID, updateTime, startUsingTime, endUsingTime, "..
                        " usingLastYear, usingLastMonth) SELECT WECode, rewardsType, amountType, WECodeStatus, disabledTime, accountID , "..
                        " %s, startUsingTime, endUsingTime, usingLastYear, usingLastMonth FROM WECodeInfo WHERE rewardsType > 2 AND "..
                        " amountType=2 AND accountID ='%s' ",

    -- 5)如果是新的奖金类型更新WECodeInfo表
    upd_wecodeinfo = " UPDATE WECodeInfo SET rewardsType=%d, updateTime=%d WHERE accountID='%s' AND rewardsType=%d ",

    -- 6)从wecode中取出5条
    select_wecode = "SELECT WECode FROM WECodeInfo WHERE accountID = '' AND WECodeStatus=0 AND rewardsType=%s AND "..
                    "amountType=2 AND disabledTime>%d LIMIT %d ",
    ----2015-07-14 zhouzhe----end----

    --- redis取设备\model默认设置频道 -- 20150921
    redis_eval_command = " local channelNumber= redis.call('GET','%s:deviceInitChannelInfo') "..
                           " if channelNumber then "..
                           "    return channelNumber "..
                           " else "..
                           "    local model= redis.call('GET','%s:modelInfo') "..
                           "    if model then "..
                           "        channelNumber = redis.call('GET', model..':deviceInitChannelInfo') "..
                           "        if channelNumber then "..
                           "            return channelNumber "..
                           "        end "..
                           "    end " ..
                           "    return nil "..
                           " end "
}
 

local crowd_dbname = "app_crowd___crowd"
local userlist_dbname =  "app_usercenter___usercenter"

local crl_time = os.time()

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(res)

    if not res['appKey'] or #res['appKey'] < 7 or not utils.is_number(res['appKey'])  then
        only.log("E","appKey is error!")
        gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
    end

    url_info['app_key'] = res['appKey']

    -- check imei
    if (not utils.is_number(res["IMEI"])) or (#res["IMEI"] ~= 15) or ( string.sub(res['IMEI'],1,1) == "0") then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "IMEI")
    end
    -- check accountID
    if (not utils.is_word(res["accountID"])) or (#res["accountID"] ~= 10) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountID")
    end
    --accountID--2015/4/11---
    safe.sign_check(res, url_info, 'accountID', safe.ACCESS_BINDMIRRTALK_INFO)

end

local function check_user_is_online( account_id )
    local ok, ret = redis_api.cmd('statistic', 'sismember', 'onlineUser:set', account_id)
    return ok and ret
end

-- 2015-07-14 zhouzhe 创建wecode  create_wecode(cur_time, j)
local function create_wecode(cur_time, reward_type)

    local cur_year, cur_month, cur_day = os.date('%Y', cur_time), os.date('%m', cur_time), os.date('%d', cur_time)
    local next_time = os.time( { year=cur_year+1, month=cur_month, day=cur_day } )

    local tab = {
        appKey = url_info['app_key'],
        rewardsType = reward_type,
        disabledTime = next_time,
        createCount = 20,
    }

    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)

    local post_body = utils.post_data('rewardapi/v2/createWECode', reward_srv, body)
    only.log('D', post_body)
    local ret_body = http_api.http(reward_srv, post_body, true)
    
    if not ret_body then
        only.log('E',string.format("call back failed! require: %s " , post_body))
        only.log('D',  'http_api post eror')
        return false
    end

    return true
end

-- 绑定wecode bind_wecode(res['accountID'], result[num]['WECode'])
local function bind_wecode(account_id, wecode)
    local tab = {
        appKey = url_info['app_key'],
        accountID = account_id,
        WECode = wecode,
    }

    tab['sign'] = app_utils.gen_sign(tab)
    local body = utils.table_to_kv(tab)

    only.log('D',string.format("body===%s=tab=", body ))
    local post_body = utils.post_data('rewardapi/v2/bindUserWECode', reward_srv, body)
    local ret = http_api.http(reward_srv, post_body, true)
    if not ret then
        only.log('E',string.format("bindUserWECode failed, require: %s ", post_body ) )
        gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
    end

    local body = string.match(ret,'{.*}')
    only.log('D',string.format("body===%s====%s===", body,wecode ))
    if not body then
        only.log('E',string.format("[rewardapi/v2/bindUserWECode] %s \r\n ****SYSTEM_ERROR: %s", post_body, ret ))
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end

    local ok, ret_body = utils.json_decode(body)
    if not ok  then
        only.log('E',string.format("MSG_ERROR_REQ_BAD_JSON: %s", body ))
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end
        only.log('E',string.format("MSG_ERROR_REQ_BAD_JSON: %s", ret_body ))

    if tonumber(ret_body['ERRORCODE']) ~= 0 then
        --如果调用bindUserWECode API 不成功,打印日志
        only.log('E',string.format('Call bindUserWECode error,ERRORCODE:%s',ret_body['ERRORCODE']))
        return ret_body
    end
    return ret_body
end

local function creat_and_bind_wecode( accountID, rewardsType )
    
    -- 从wecodeinfo中取出5条数据
    local wecode_num = 5
    local sql = string.format(G.select_wecode, rewardsType, crl_time, wecode_num )
    local ok, result = mysql_api.cmd(crowd_dbname, 'SELECT', sql)
    if not ok or not result or type(result) ~= 'table' then
        only.log('E', string.format("select_wecode failed , %s" , sql) )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end

    only.log('D', string.format("===%s,#result==%d===wecode_num===%d", accountID, #result, wecode_num ))
    if #result < wecode_num then
        local ok = create_wecode(cur_time, rewardsType)
        if not ok then
            only.log("E","create_wecode is error")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "creat wecode" )
        end
        -- 从wecodeinfo中取出5条数据
        local sql = string.format(G.select_wecode, rewardsType, crl_time, wecode_num )
        ok, result = mysql_api.cmd(crowd_dbname, 'SELECT', sql)
        if not ok or not result then
            only.log('E', string.format("select_wecode failed , %s" , sql) )
            gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
        end
    end

    for _,val in pairs(result) do
        for _, wecode_v in pairs(val) do
            local ret_body = bind_wecode(accountID, wecode_v)
            only.log('E', string.format("===%s====ERRORCODE===%s", wecode_v, ret_body['ERRORCODE'] ))
            --绑定WECode成功
            if tonumber(ret_body['ERRORCODE']) == 0  then      
                only.log('D', string.format('bind wecode successed :%s',wecode_v ))
                return true
            end
        end
    end
    return false
end

-- wecode及rewardsType处理

---------- jiang z.s. 2015-10-04 ----------------
---------- 待优化绑定weme的代码 ------------------
----------  ?????????????????????? -----------------
local function handle_rewards_type( imei, accountID )

    local sql_tab = {}
    local rewardsType = 4
    -- 查询当前imei的rewardsType  userMirrtalkInfo
    local sql_ret = string.format(G.sql_get_business_list , imei, imei)
    local ok, req_args = mysql_api.cmd(crowd_dbname, 'SELECT', sql_ret)
    if not ok or not req_args then
        only.log('E', string.format("sql_get_business_list failed , sql: %s" , sql_ret) )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #req_args == 1 then
        only.log('D', string.format(" bonusTarget:%d(1:person,2:business), rewardsType:%d, sql: %s" , req_args[1]['bonusTarget'],req_args[1]['rewardsType'], sql_ret) )
        rewardsType = tonumber(req_args[1]['rewardsType']) 
    end
    
    -- 查询之前accountID的rewardsType
    local sql_str = string.format(G.sl_user_WECodeInfo , accountID)
    local ok, req_res = mysql_api.cmd(crowd_dbname, 'SELECT', sql_str)
    if not ok or not req_res then
        only.log('E', string.format("sl_user_WECodeInfo failed , %s" , sql_str) )
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end

    -- 如果没有查到该accountID信息
    if type(req_res) == "table" and #req_res == 1 then

        only.log("D", string.format("====debug info result_rewardsType:%s, rewardsType:%s",req_res[1]['rewardsType'], rewardsType))

        if tonumber(req_res[1]['rewardsType']) == rewardsType  then
            -- 返回1 说明该imei的rewardsType=4不用设置奖金类型
            only.log('D', string.format("[ 1 ] get user rewardsType = result,rewardsType: %s" , rewardsType) )
            return 1
        else

            -- 账户存在，重新绑定的设备奖励类型不一致，需要更新账户（wecodeInfo表rewardsType）
            local sql = string.format(G.ins_wecodehistory , crl_time, accountID )
            table.insert(sql_tab, sql)
            
            -- 更新数据wecodeinfo
            local sql = string.format(G.upd_wecodeinfo , rewardsType, crl_time, accountID, req_res[1]['rewardsType'])
            table.insert(sql_tab, sql)

            local ok, result = mysql_api.cmd(crowd_dbname, 'AFFAIRS', sql_tab)

            only.log('D', string.format("===debug info upd_wecodeinfo sql :%s" , table.concat(sql_tab, '\r\n')) )

            if not ok or not result then
                only.log('E', string.format("====upd_wecodeinfo failed , sql :%s" , table.concat(sql_tab, '\r\n')) )
                gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
            end

            only.log('D', string.format("[ 2 ] get user rewardsType != result,rewardsType: %s" , rewardsType) )

            return 2
        end
    -- 如果用户没有绑定wecode则去绑定wecode
    elseif type(req_res) == "table" and #req_res < 1 then
        -- 绑定wecode尝试三次
        local isbind = false
        for i=1, 3 do

            isbind = creat_and_bind_wecode( accountID, rewardsType )
            if isbind then
                -- 返回2 说明该accountID之前没wecode现在已经绑定wecode
                only.log('D', string.format("[ 3 ] get user result = nil,creat wecode accountID: %s,rewardsType: %s" , accountID, rewardsType ) )
                return 3
            end
        end
        if not isbind then
            only.log("E", string.format("==bindimeiAPI==bind wecode failed,accountid: %s", accountID ))
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'bindUserWECode')
        end
    else
        only.log('E', string.format("sl_user_WECodeInfo return date error , %s" , sql_str) )
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], "accountID")
    end
end
-->> 2015-07-14 zhouzhe<<---end---->> modify wjy 2015-09-23

---- 获取默认频道number的idx
local function get_default_channel_idx(channel_num )
    local ok, idx = redis_api.cmd('private', 'get', channel_num .. ':channelID')
    if ok and idx then
        return idx 
    end
    return nil
end

function handle()
    local IP = ngx.var.remote_addr
    local body = ngx.req.get_body_data()
    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_host'] = IP
    url_info['client_body'] = body

    local args = utils.parse_url(body)

    if not args or type(args) ~= "table" then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],"args")
    end

    check_parameter(args)

    local imei = args["IMEI"]
    local account_id = args["accountID"]
	local shortimei = string.sub(imei,1,14)
	local nCheck = string.sub(imei,15,15)
    -->> 检查imei是否合法
    local sql = string.format(G.sl_mirrtalk, shortimei, nCheck)
    local ok, res = mysql_api.cmd('app_ident___ident', 'SELECT', sql)
    only.log('D', string.format(" check imei === %s",sql ))

    if not ok or not res then
        only.log('E', string.format(" check imei failed %s",sql) )
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
    end

    if tonumber(res[1]['validity']) == 0 or res[1]['status']~='13g' then
        -- gosay.go_false(url_info, msg["MSG_ERROR_IMEI_UNUSABLE"],imei)
        -- 2015-04-10 错误码调整 jiang z.s. 
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_INVALIDITY"])
    end
    -->| STEP 2 |<--
    -->> 根据IMEI获取accountID判断IMEI是否已经绑定
    sql = string.format(G.sl_account, imei)
    local ok, res = mysql_api.cmd(userlist_dbname, 'SELECT', sql)
    only.log('D', string.format(" check account === %s",sql ))
    if not ok or not res then
        only.log('E',string.format("check imei is bind failed, %s",sql))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res > 0 then
        -->> 重复绑定
        if res[1]['accountID'] == account_id then
            only.log('W',string.format("check imei:%s is rebind, cur_accountid:%s, before accountid:%s ", imei,account_id, res[1]['accountID']))
            gosay.go_false(url_info, msg['MSG_ERROR_DEVICE_REBIND'])
        -->> 已经被其他accountID绑定
        else
            ---- modify by jiang z.s. 2015-10-04
            ---- optimize log detail 
            only.log('W',string.format("check imei:%s is bind, but is not cur accountid:%s, has bind accountid is:%s ",imei, account_id, res[1]['accountID']))
            gosay.go_false(url_info, msg["MSG_ERROR_IMEI_HAS_BIND"])
        end
    end
    -->| STEP 3 |<--
    -->> 获取accountID绑定IMEI情况
    sql = string.format(G.sl_status, account_id)
    only.log('D', string.format(" check sl status === %s",sql ))
    local ok, res = mysql_api.cmd(userlist_dbname, 'SELECT', sql)
    if not ok or not res then
        only.log('E',string.format("check accountID , %s ", sql ) )
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    -->> accountID不存在
    if #res == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    -->> accountID出现重复
    elseif #res > 1 then
        only.log('E', string.format("the record of accountID:%s is more than one, call someone to handle", account_id))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], "accountID")
    end

    local IMEI = res[1]['imei']
    -->| STEP 4 |<--
    if #IMEI == 15 then
        -->>重复绑定
        if tostring(IMEI) == tostring(imei) then
            gosay.go_false(url_info, msg['MSG_ERROR_DEVICE_REBIND'])
        -->> 已经绑定
        else
            gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_HAS_BIND"])
        end
    ---- 未绑定,开始绑定
    else
        -->| STEP 5 |<--
        local cur_time = os.time()
        local tab_sql = {}
        sql1 = string.format(G.upd_user_list, cur_time, imei, account_id)
        table.insert(tab_sql, sql1)
        sql2 = string.format(G.sql_insert_login_history, account_id)
        table.insert(tab_sql, sql2)

        only.log('D', string.format(" ===upd user list === %s \r\n===insert login history==%s",sql1,sql2 ))

        local ok = mysql_api.cmd(userlist_dbname, 'affairs', tab_sql)
        if not ok then
            only.log('E',string.format("bind accountid with imei failed "  ))
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end

        redis_api.cmd('private', 'set', account_id .. ":IMEI", imei)
        redis_api.cmd('private', 'set', imei .. ":accountID", account_id)

        if check_user_is_online(imei) then

            ---- (imei或设备对应的model号)判断是否存在设置默认频道，若无则直接取10086 --20150923 -- wjy
            local device_default_channel = 10086
            local ok, channelNumber = redis_api.cmd('private','eval', string.format(G.redis_eval_command, imei, imei  ) ,0)
            if not ok then
                only.log('W',string.format("[[1]] get imei = %s deviceInitChannelInfo, redis failed ", imei))
            end

            if channelNumber then
                only.log('W',string.format("[[2]] get imei = %s deviceInitChannelInfo, channelNumber = %s ", imei, channelNumber))
                device_default_channel = channelNumber
            end

            ---- 获取默认频道的idx
            channel_idx =  get_default_channel_idx(device_default_channel)

            ---- 从默认的客户频道剔除在线
            redis_api.cmd('statistic', 'srem', channel_idx ..':channelOnlineUser', imei)

            redis_api.cmd('statistic', 'srem', 'onlineUser:set', imei)

            redis_api.cmd('statistic', 'sadd', 'onlineUser:set', account_id)

            local ok, ret = redis_api.cmd('private','smembers',account_id .. ":userFollowMicroChannel")
            if ok and ret then
                for k, idx in pairs(ret) do
                    redis_api.cmd('statistic', 'sadd', idx .. ':channelOnlineuser', account_id)
                    only.log('I',string.format("add channelidx:%s  channelOnlineuser %s" , idx, account_id ))
                end
            end

            local ok, ret = redis_api.cmd('private', 'get', imei .. ":cityCode")
            if ok and ret then
                only.log('D',string.format("[imei bind accountid, imei] srem %s cityOnlineUser %s ",ret ,imei))
                only.log('D',string.format("[imei bind accountid, accountid] sadd %s cityOnlineUser %s ",ret ,account_id))
                redis_api.cmd('statistic', 'srem', ret .. ':cityOnlineUser', imei)
                redis_api.cmd('statistic', 'sadd', ret .. ':cityOnlineUser', account_id)
            end
            ---- 判断是否关联按键
            ---- 加入++键在线列表
            local ok, group_channel_idx = redis_api.cmd('private', 'get', account_id .. ':currentChannel:groupVoice')
            only.log("D",string.format("groupVoice channel_idx:%s", group_channel_idx))
            if ok then
                if not group_channel_idx then
                    --- 若账户没有设备群聊频道，需要把账户加入10086频道
                    local account_default_channel = 10086
                    group_channel_idx =  get_default_channel_idx(account_default_channel)
                end
                redis_api.cmd('statistic', 'sadd', group_channel_idx .. ':channelOnlineUser', account_id)
            end

            ---- 判断是否关联按键
            ---- 加入+键在线列表
            local ok, voice_channel_idx = redis_api.cmd('private', 'get', account_id .. ':currentChannel:voiceCommand')
            only.log("D",string.format("voiceCommand channel_idx:%s", voice_channel_idx))
            if ok and voice_channel_idx then
                redis_api.cmd('statistic', 'sadd', voice_channel_idx .. ':channelOnlineUser', account_id)
            end
        end
        -- 2015-07-14 查询imei的rewardsType 并检查wecode是否绑定，如果没有需要绑定wecode
        local wecode_status = handle_rewards_type( imei, account_id )

        only.log("D", string.format("handle_rewards_type status :%s", wecode_status))

        gosay.go_success(url_info, msg["MSG_SUCCESS"])
    end

    only.log('E',string.format("SYSTEM_ERROR: accountID: %s  imei:%s  %s", account_id, imei, status) )
    gosay.go_success(url_info, msg["SYSTEM_ERROR"])
end

safe.main_call( handle )
