--author	: chenzutao
--date		: 2013-12-27
--fixed		: baoxue
--date		: 2013-12-30

--[=[
local cfg = require ('config')
local ngx = require ('ngx')
local sha = require('sha1')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local http_api = require('http_short_api')
local utils = require('utils')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local app = require('app')

local link = require('link')
local account_srv = link["OWN_DIED"]["http"]["updateAccount"]
local white_list_srv = link["OWN_DIED"]["http"]["PBXwhitepost"]

local factory_info = {
    ["134"] ="移动",
    ["135"] ="移动",
    ["136"] ="移动",
    ["137"] ="移动",
    ["138"] ="移动",
    ["139"] ="移动",
    ["147"] ="移动",
    ["150"] ="移动",
    ["151"] ="移动",
    ["152"] ="移动",
    ["157"] ="移动",
    ["158"] ="移动",
    ["159"] ="移动",
    ["182"] ="移动",
    ["183"] ="移动",
    ["187"] ="移动",
    ["188"] ="移动",

    ["130"] ="联通",
    ["131"] ="联通",
    ["132"] ="联通",
    ["145"] ="联通",
    ["155"] ="联通",
    ["156"] ="联通",
    ["185"] ="联通",
    ["186"] ="联通",

    ["075"] ="电信",
    ["133"] ="电信",
    ["153"] ="电信",
    ["180"] ="电信",
    ["189"] ="电信",
}

local G = {
    secret = nil,
    factory = nil,
    mirrtalkNumber = nil,
    imsi = nil,

    userStatus = nil,
    updateTime = nil,
    daokePassword = nil,
    imei = nil,
}

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local sql_fmt = {

    get_mirrtalkNumber = [[SELECT mirrtalkNumber,userStatus,updateTime,daokePassword,imei FROM userList WHERE accountID='%s' AND (userStatus=1 or userStatus>2)]],

    get_verifyCode = [[SELECT verificationCode,UNIX_TIMESTAMP(createTime) FROM mirrtalkNumberVerificationCode WHERE mirrtalkNumber='%s' AND accountID='%s' order by createTime DESC limit 1]],
    is_mirrtalkNumber_exist = [[SELECT 1 FROM simInfo WHERE mirrtalkNumber='%s']],
    get_imsi = [[SELECT imsi FROM mirrtalkIdentification WHERE mirrtalkNumber='%s']],

    insert_to_mirr_updateHistory = [[INSERT INTO mirrtalkNumberUpdateHistory SET accountID='%s',newMirrtalkNumber='%s',oldMirrtalkNumber='%s',imsi='%s']],

    update_mirr_updateHistory = [[UPDATE mirrtalkNumberUpdateHistory SET validity=0 WHERE accountID='%s' AND newMirrtalkNumber='%s' AND oldMirrtalkNumber='%s' AND imsi='%s']],
    update_userList = [[UPDATE userList SET mirrtalkNumber='%s' WHERE accountID='%s']],
    insert_userListHistory = [[INSERT INTO userListHistory SET mirrtalkNumber='%s', accountID='%s',userStatus='%s',updateTime='%s',daokePassword='%s',imei='%s']],

    update_mirrtalkNumber = [[UPDATE mirrtalkIdentification SET mirrtalkNumber='%s' WHERE imsi='%s']],
}

local function check_parameter(body)

    local res = utils.parse_url(body)
    url_info['app_key'] = res['appKey']

    -->> check accountID
    if not utils.check_accountID(res["accountID"]) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],"accountID")
    end

    -->> check mirrtalkNumber
    if (not utils.is_number(res["mirrtalkNumber"])) or (#res["mirrtalkNumber"] ~= 11) 
            or (string.sub(res["mirrtalkNumber"], 1, 1) ~= "1")then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "mirrtalkNumber")
    end

    -->> check verificationCode
    if (not utils.is_number(res["verificationCode"])) or (#res["verificationCode"] ~= 4) 
        or (string.sub(res["verificationCode"], 1, 1) == "0")then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "verificationCode")
    end

    app.new_safe_check(res, url_info)

    return res
end

-- to get mirrtalkNumber from userList table by given accountID --
local function check_mirrtalkNumber( args )

    local res_sql = string.format(sql_fmt.get_mirrtalkNumber, args['accountID'])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'select', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"], "accountID")
    elseif #result > 1 then

        only.log('S', string.format('too many accountID:%s in db', args['accountID']))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], "accountID")

    elseif result[1]["mirrtalkNumber"] == args["mirrtalkNumber"] then

        gosay.go_success(url_info, msg["MSG_SUCCESS"])

    elseif tonumber(result[1]["userStatus"]) == 3 then

        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NO_SERVICE"])

    elseif tonumber(result[1]["imei"]) == 0 then

        gosay.go_false(url_info, msg["MSG_ERROR_IMEI_HAS_BIND"])

    else

        -->> check time
        local ok, update_time = redis_pool_api.cmd('private', 'get', result[1]['imei'] .. ':heartbeatTimestamp')

        if (not update_time) or ((os.time() - tonumber(update_time)) > cfg["power_on_time_space"])  then
            gosay.go_false(url_info, msg["MSG_ERROR_NO_POWER_ON"])
        end
    end
    G.mirrtalkNumber = result[1]["mirrtalkNumber"]
    G.userStatus = result[1]["userStatus"]
    G.updateTime = result[1]["updateTime"]
    G.daokePassword = result[1]["daokePassword"]
    G.imei = result[1]["imei"]

end

--get verificationCode and createTime from mirrtalkNumberVerificationCode table by
-- input mirrtalkNumber and accountID
local function check_verifyCode(args)

    local res_sql = string.format(sql_fmt.get_verifyCode, args["mirrtalkNumber"], args['accountID'])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd('app_daokeme___daokeme', 'select', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if (#result==0) or (result[1]["verificationCode"] ~= args["verificationCode"]) then

        gosay.go_false(url_info, msg["MSG_ERROR_CODE_IS_ILLEGAL"], "verificationCode" )

    elseif (os.time() - tonumber(result[1]["UNIX_TIMESTAMP(createTime)"])) > cfg["verificationCode_timeout"] then

        gosay.go_false(url_info, msg["MSG_ERROR_CODE_IS_EXPIRE"], "verificationCode")
    end
end

local function check_simInfo(args)

    local res_sql = string.format(sql_fmt.is_mirrtalkNumber_exist, args["mirrtalkNumber"])
    only.log('D', res_sql)
    local ok, result = mysql_pool_api.cmd('app_ident___ident', 'select', res_sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end

    if #result ~= 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_IS_EXIST"], "mirrtalkNumber")
    end
end

local function update_account_info(args)

    if tonumber(G["userStatus"]) == 5 then
        -->> call api update mirrtalkNumber
        local tab_req = {
            ["appKey"] = args["appKey"],
            ["IMEI"] = G["imei"],
        }
        tab_req["sign"] = utils.gen_sign(tab_req, G["secret"])

        local ok, body = utils.json_encode(tab_req)
        local data = utils.post_data("updateAccount", account_srv, body)

        only.log('D', data)
        local result = http_api.http(account_srv, data, true)
        only.log('D', result)
    end
end

local function get_imsi(imei)

    local ok, mt_number = redis_pool_api.cmd("private", "get", imei .. ':mirrtalkNumber')
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_REDIS_FAILED"])
    end

    local sql = string.format(sql_fmt.get_imsi, mt_number)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_ident___ident', 'select', sql)
    if not ok then
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
    if #result==0 then
        gosay.go_false(url_info, msg["MSG_ERROR_IS_NOT_EXIST"], 'mirrtalkNumber')
    end

    G.imsi = result[1]['imsi']
    G.mirrtalkNumber = mt_number

end

local function recode_mirrtalkNumber(args)
    local tab_sql = {
        [1] = string.format(sql_fmt.insert_to_mirr_updateHistory, args['accountID'],args['mirrtalkNumber'], G.mirrtalkNumber or "", G.imsi or ""),
        [2] = string.format(sql_fmt.update_userList, args['mirrtalkNumber'], args['accountID']),
        [3] = string.format(sql_fmt.insert_userListHistory, args['mirrtalkNumber'], args['accountID'], G.userStatus or "", G.updateTime or "", G.daokePassword or "", G.imei or ""),
    }

    only.log('D',tab_sql[1])
    only.log('D',tab_sql[2])
    only.log('D',tab_sql[3])

    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'affairs', tab_sql)

    only.log('D', ok)
    if not ok then
        only.log('E','FAILED sqls:[' .. tab_sql[1] .. '],[' .. tab_sql[2] .. '],[' .. tab_sql[3] .. ']')
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
end

local function reback_mirrtalkNumber(args)
    local tab_sql = {
        [1] = string.format(sql_fmt.update_mirr_updateHistory, args['accountID'],args['mirrtalkNumber'],G.mirrtalkNumber or "", G.imsi or ""),
        [2] = string.format(sql_fmt.update_userList, G.mirrtalkNumber, args['accountID']),
        [3] = string.format(sql_fmt.insert_userListHistory, G.mirrtalkNumber, args['accountID'],G.userStatus or "", G.updateTime or "", G.daokePassword or "", G.imei or ""),
    }

    local ok, result = mysql_pool_api.cmd('app_usercenter___usercenter', 'affairs', tab_sql)
    if not ok then
        only.log('E','FAILED sqls:[' .. tab_sql[1] .. '],[' .. tab_sql[2] .. '],[' .. tab_sql[3] .. ']')
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
end
local function recode_imsi(args)

    local sql = string.format(sql_fmt.update_mirrtalkNumber, args['mirrtalkNumber'], G.imsi)

    only.log('D',sql)

    local ok, result = mysql_pool_api.cmd('app_ident___ident', 'update', sql)

    if not ok then
        -->> back mirrtalkNumber recode
        reback_mirrtalkNumber(args)
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
    end
end


local function handle()

    local head = ngx.req.raw_header()
    local ip = ngx.var.remote_addr

    local body = ngx.req.get_body_data()
    url_info['client_host'] = ip
    url_info['client_body'] = body

    only.log('D', "\r\n" .. body)

    -->| STEP 1 |<--
    -->> check parameters
    local res = check_parameter(body)

    -->| STEP 3 |<--
    -->> check mirrtalkNumber
    check_mirrtalkNumber( res )

    -->> check verifyCode
    check_verifyCode( res )

    -->> check simInfo
    check_simInfo( res )

    -->> get factory
    G.factory = factory_info[ string.sub(res["mirrtalkNumber"], 1, 3) ]
    if not G.factory then
        gosay.go_false(url_info, msg["MSG_ERROR_NO_SOURCE_INFO"], 'mirrtalkNumber')
    end

    -->> get mirrtalkNumber
    update_account_info( res )

    -->> get imsi
    get_imsi(G['imei'])

    -->> recode mirrtalkNumber
    recode_mirrtalkNumber( res )

    -->> recode imsi
    recode_imsi( res )

    -->| STEP 5 |<--

    -->> reset accountID
    local ok, old_accountID = redis_pool_api.cmd("private", "get", G.mirrtalkNumber .. ':accountID')
    redis_pool_api.cmd("private", "del", G.mirrtalkNumber .. ':accountID')
    if old_accountID then
        redis_pool_api.cmd("private", "set", res["mirrtalkNumber"] .. ':accountID', old_accountID)
    else
        redis_pool_api.cmd("private", "del", res["mirrtalkNumber"] .. ':accountID')
    end
    redis_pool_api.cmd("private", "set", G.imei .. ':mirrtalkNumber', res['mirrtalkNumber'])


    -->> add to white list
    if cfg["on_off_white_list"] then
        only.log('I', "add mirrtalkNumber=" .. res["mirrtalkNumber"] .. " to white list!")
        -->> do api
        local data = "POST /PBXwhitepost.php HTTP/1.0\r\n" ..
        "Access-Control-Allow-Origin: *\r\n" ..
        "Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept\r\n" ..
        "User-Agent: curl/7.33.0\r\n" ..
        "Content-Type: application/x-www-form-urlencoded\r\n" ..
        "Host: 172.16.11.200：80\r\n" ..
        "Connection: close\r\n" ..
        "Content-Length: 23\r\n" ..
        "Accept: */*\r\n\r\nwhietnumber=" .. res["mirrtalkNumber"]

        local result = http_api.http(white_list_srv, data, true)
        if result then
            only.log('D', result)
        else
            gosay.go_false(url_info, msg["MSG_DO_HTTP_FAILED"])
        end
    end

    gosay.go_success(url_info, msg["MSG_SUCCESS"])
end


handle()
]=]
