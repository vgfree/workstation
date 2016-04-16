---- author: zhangjl (jayzh1010@gmail.com)
---- accountID解绑IMEI 
---- 2015-04-10 

local ngx       = require('ngx')
local sha       = require('sha1')
local msg       = require('msg')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local safe      = require('safe')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local sql_fmt = {

    sl_accountid = "SELECT daokePassword, userStatus, imei FROM userList WHERE accountID = '%s' AND userStatus IN(1,4,5)  ",

    insert_userlist_history = "INSERT INTO userListHistory( accountID, userStatus, updateTime, daokePassword, imei )"..
                                                            " VALUES('%s', %d, %s, '%s', '%s')",

    update_userlist = "UPDATE userList SET userStatus = 4, updateTime= %s, imei=0 WHERE imei != 0 and accountID = '%s' ",

}

local userlist_dbname = "app_usercenter___usercenter"

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_user_is_online( account_id )
	local ok, ret = redis_api.cmd('statistic', 'sismember', 'onlineUser:set', account_id)
	return ok and ret
end

local function disconnect_accountid(a_id)

    local sql = string.format(sql_fmt.sl_accountid, a_id)
    local ok, ret = mysql_api.cmd(userlist_dbname, 'select', sql)
    if not ok or not ret then

        only.log('E',string.format(" check accountID failed, %s ", sql)) 
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #ret == 0 then
        only.log('E', string.format("the record of accountID:%s is zero", a_id))
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
    elseif #ret > 1 then
        only.log('E', string.format("the record of accountID:%s is more than one, call someone to handle", a_id))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'accountID')
    end

    local status = tonumber(ret[1]['userStatus'])
    local passwd = ret[1]['daokePassword']
    local imei = ret[1]['imei']
    --local model = ret[1]['model']
    local userStatus = ret[1]['userStatus']

    if tonumber(status) == 4 then
        only.log('D',string.format("current accountid is not bind imei %s ", a_id) )
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNTID_NOT_BIND"])
    end

    local sql_tab = {}
    local cur_time = os.time()

    local sql = string.format(sql_fmt.update_userlist, cur_time, a_id)
    table.insert(sql_tab, sql)

    sql = string.format(sql_fmt.insert_userlist_history, a_id, userStatus, cur_time, passwd, imei)
    table.insert(sql_tab, sql)

    local ok, ret = mysql_api.cmd(userlist_dbname, 'affairs', sql_tab)
    if not ok then
        only.log('E', "commit transaction failed %s", table.concat( sql_tab, "\r\n"))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if tonumber(imei) ~= 0 then
        redis_api.cmd('private', 'del', imei .. ":accountID")
        redis_api.cmd('private', 'del', a_id .. ":IMEI")

        if check_user_is_online(a_id) then

            redis_api.cmd('statistic', 'srem', 'onlineUser:set', a_id)

            ---- 2015-04-10 jiang z.s. 
            ---- 获取微频道用户的关注列表,自动剔除下线
            local ok, ret = redis_api.cmd('statistic','smembers',a_id .. ":userFollowMicroChannel")
            if ok and ret then
                for k, idx in pairs(ret) do
                    redis_api.cmd('statistic', 'srem', idx .. ':channelOnlineuser', a_id)
                    only.log('I',string.format("srem channelidx:%s  channelOnlineuser %s" , idx, a_id ))
                end
            end

            redis_api.cmd('statistic', 'sadd', 'onlineUser:set', imei)

            local ok, ret = redis_api.cmd('private', 'get', a_id .. ":cityCode")
            if ok and ret then
                only.log('W',string.format("srem %s cityOnlineUser %s",ret,a_id))
                only.log('W',string.format("sadd %s cityOnlineUser %s" ,ret ,imei))
                redis_api.cmd('statistic', 'srem', ret .. ':cityOnlineUser', a_id)
                redis_api.cmd('statistic', 'sadd', ret .. ':cityOnlineUser', imei)
            end 
        end 

    end

    return true
end

local function parse_body(str)

    local args_tab = utils.parse_url(str) 

    url_info['app_key'] = args_tab['appKey']
    ---accountID--2015/4/11---
    safe.sign_check(args_tab, url_info,'accountID', safe.ACCESS_BINDMIRRTALK_INFO)

    if not app_utils.check_accountID(args_tab['accountID']) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    return args_tab
end

local function handle()

    local body = ngx.req.get_body_data()

    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    if not body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args_tab = parse_body(body)

    disconnect_accountid(args_tab['accountID'])

    gosay.go_success(url_info, msg["MSG_SUCCESS"])

end


safe.main_call( handle )

