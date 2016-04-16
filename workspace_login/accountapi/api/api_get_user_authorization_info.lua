
local utils = require('utils')
local app_utils = require('app_utils')
local only = require('only')
local ngx = require('ngx')
local gosay = require('gosay')
local redis_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {

    sle_info = "SELECT refreshTokenExpiration, accessTokenExpiration,accessToken FROM userAccessTokenInfo WHERE accountID='%s' AND validity=1",
    ins_history = "INSERT INTO userAccessTokenHistoryInfo SET accountID='%s',appKey=%s,refreshToken='%s',refreshTokenExpiration=%s,accessToken='%s',accessTokenExpiration=%s,updateTime=%s,validity=%s,remark='%s'",
    upd_info = "UPDATE userAccessTokenInfo SET accessToken='%s',accessTokenExpiration=%d,updateTime=%d,appKey=%d,remark='用户更新授权信息' WHERE id=%s",
}



local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    -->> safe check
    safe.sign_check(args, url_info)

    if not app_utils.check_accountID(res["accountID"]) then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'accountID')
    end

    --> check username 
    if not args['refreshToken'] or #args['refreshToken']~=32 then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'refreshToken')
    end
end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    if body == nil then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)
    url_info['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)


    local sql = string.format(sql_fmt.sle_info, args['accountID'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_auth___auth', 'select', sql)
    if not ok then
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_NO_AUTH"])
    elseif #result > 1 then
        only.log('S', string.format("%s:the record of accountID:%s more than one", sql, args['accountID']))
        gosay.go_false(url_info, msg["SYSTEM_ERROR"])
    end

    local cur_time = os.time()

    local ret_req
    if tonumber(result[1]['refreshTokenExperiation'])>cur_time and tonumber(result[1]['accessTokenExpiration'])>cur_time then
        ret_req = string.format('{"accessToken":"%s","accessTokenExpiration":"%s"}', result[1]['accessToken'], result[1]['accessTokenExpiration'])
    else

        if result[1]['refreshTokenExpiration'] < cur_time then
            gosay.go_false(url_info, msg["MSG_ERROR_AUTH_EXPIRE"])
        end

        local db_id = result[1]['id']

        if result[1]['accessTokenExpiration'] < cur_time then
            local sql = string.format(sql_fmt.ins_history, args['accountID'], result[1]['appKey'], result[1]['refreshToken'], result[1]['refreshTokenExpiration'],
                result[1]['accessToken'], result[1]['accessTokenExpiration'], result[1]['updateTime'],result[1]['validity'],result[1]['remark'])

            only.log('D', sql)
            local ok, result = mysql_pool_api.cmd('app_auth___auth', 'insert', sql)
            if not ok then
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
            end

            local access_token = utils.create_uuid()
            local expire = cur_time + 7*24*3600

            local sql = string.format(sql_fmt.ins_history, access_token, expire, cur_time, args['appKey'], id)
            only.log('D', sql)
            local ok, result = mysql_pool_api.cmd('app_auth___auth', 'update', sql)
            if not ok then
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
            end

            ret_req = string.format('{"accessToken":"%s","accessTokenExpiration":"%s"}', access_token, expire)
            end
    end


    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret_req)
end

safe.main_call( handle )
