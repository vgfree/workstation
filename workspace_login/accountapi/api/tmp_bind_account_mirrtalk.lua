-->[ower]: baoxue
-->[time]: 2013-09-02

local msg = require('msg')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local only = require('only')
local msg = require('msg')
local safe = require('safe')

local G = {
    sl_mirrtalk = "SELECT validity FROM mirrtalkInfo WHERE imei='%s' AND nCheck='%s'",

    sl_account = " SELECT 1 FROM userList WHERE imei='%s' ",
    sl_status = " SELECT userStatus,daokePassword FROM userList WHERE accountID='%s' AND userStatus>2 ",
    upd_user_list = " UPDATE userList SET userStatus=%d,updateTime=%s,imei='%s' WHERE accountID='%s' ",
    ins_history = " INSERT INTO userListHistory SET userStatus=%d,updateTime=%s,imei='%s',accountID='%s',daokePassword='%s' ",

    -->> identify
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

    -->> check imei
    if (not utils.is_number(res["IMEI"])) or (#res["IMEI"] ~= 15) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "IMEI")
    end
    -->> check accountID
    if (not utils.is_word(res["accountID"])) or (#res["accountID"] ~= 10) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountID")
    end

    safe.sign_check(res, url_info)

    return res
end

local function check_user_is_online( account_id )
	local ok, ret = redis_pool_api.cmd('statistic', 'sismember', 'onlineUser:set', account_id)
	return ok and ret
end



function handle(account_id, imei)

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body


    -->| STEP 1 |<--
    -->> check parameters
    -- local res = check_parameter(body)

    -- local imei = res["IMEI"]
    -- local account_id = res["accountID"]

    -->> check imei
    local sql = string.format(G.sl_mirrtalk, string.sub(imei, 1, -2), string.sub(imei, -1, -1))
        only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_ident___ident', 'SELECT', sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
    end

    if tonumber(res[1]['validity']) == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_UNUSABLE"])
    end

    -->| STEP 2 |<--
    -->> check if has imei in userList
    sql = string.format(G.sl_account, imei)
        only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_usercenter___usercenter', 'SELECT', sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #res~=0 then
        return
    end

    -->| STEP 3 |<--
    -->> check if has accountID in userList
    sql = string.format(G.sl_status, account_id)
        only.log('D', sql)
    local ok, res = mysql_pool_api.cmd('app_usercenter___usercenter', 'SELECT', sql)

    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    -->> has no
    if #res==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
        -->> has more than one
    elseif #res > 1 then
        only.log('S', string.format("the record of accountID:%s is more than one, call someone to handle", account_id))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], "accountID")
    end
    
    -->> has only one
    local status = tonumber(res[1]["userStatus"])
    local daoke_password = res[1]["daokePassword"]

    -->| STEP 4 |<--
    if status == 3 then
        -- gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NO_SERVICE"])
    elseif status == 5 then
        -- gosay.go_success(url_info, msg["MSG_SUCCESS"])
    elseif status == 4 then
        -->| STEP 5 |<--
        local time = os.time()
        local sql_tab = {}
        sql = string.format(G.upd_user_list, 5, time, imei, account_id)
        only.log('D', sql)
        table.insert(sql_tab, sql)
        sql = string.format(G.ins_history, 5, time, imei, account_id, daoke_password)
        only.log('D', sql)
        table.insert(sql_tab, sql)
        local ok, res = mysql_pool_api.cmd('app_usercenter___usercenter', 'affairs', sql_tab)
        if not ok then
            gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
        end

        redis_pool_api.cmd('private', 'set', account_id .. ":IMEI", imei)
        redis_pool_api.cmd('private', 'set', imei .. ":accountID", account_id)

		if check_user_is_online(imei) then
			redis_pool_api.cmd('statistic', 'srem', 'onlineUser:set', imei)
			redis_pool_api.cmd('statistic', 'sadd', 'onlineUser:set', account_id)

			local ok, ret = redis_pool_api.cmd('private', 'get', imei .. ":cityCode")
			if ok and ret then

				redis_pool_api.cmd('statistic', 'srem', ret .. 'cityOnlineUser', imei)
				redis_pool_api.cmd('statistic', 'sadd', ret .. 'cityOonlineUser', account_id)
			end
		end

        -- gosay.go_success(url_info, msg["MSG_SUCCESS"])

    end
end

--[[
local ok, result = mysql_pool_api.cmd('app_shipment___shipment', 'SELECT', "select imei from deviceConsigneeDetailInfo where tradenumber='Z1420962302482'")

for k, v in ipairs(result) do

    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'SELECT', string.format("select accountID from userRegisterInfo where username='%s'", 'caa' .. string.sub(v['imei'], -5, -1)))

    handle(result[1]['accountID'], v['imei'])
end
--]]
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'SELECT', string.format("select accountID from userRegisterInfo where username='%s'", 'caa' .. string.sub('282455622776107', -5, -1)))
    handle(result['accountID'], '282455622776107')
gosay.go_success(url_info, msg["MSG_SUCCESS"])
