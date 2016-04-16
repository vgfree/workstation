--fixed : chengjian
--date  : 2014-03-28

local ngx = require('ngx')
local sha = require('sha1')
local redis_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local utils = require('utils')
local only = require('only')
local msg = require('msg')
local gosay = require('gosay')
local safe = require('safe')

local sql_fmt = {
    get_accountID_by_name = "SELECT accountID FROM userRegisterInfo WHERE username='%s' AND validity=1",
    get_accountID_by_mobile = "SELECT accountID, checkMobile FROM userRegisterInfo WHERE mobile=%s AND validity=1",
    get_accountID_by_email = "SELECT accountID, checkUserEmail FROM userRegisterInfo WHERE userEmail='%s' AND validity=1",
    check_userlist_record = "SELECT accountID, imei, daokePassword FROM userList WHERE accountID='%s' AND userStatus IN(4,5)",
    -->> 获取model号
    sql_get_model_by_imei = " SELECT model FROM mirrtalkInfo WHERE CONCAT(imei,nCheck) IN (%s) ",
    -->> 获取isThirdModel和 brandType
    sql_get_model_info = "SELECT isThirdModel, brandType FROM userModelInfo WHERE validity=1 AND model='%s' ",
    -- 2015-06-08 返回值增加手机号 zhouzhe
    sl_user_info = "SELECT accountID, name, nickname, mobile FROM userInfo WHERE accountID='%s' AND status=1",

}

local url_info = {
    app_key = nil,
    type_name = 'system',
    client_host = nil,
    client_body = nil,
}

-- 2015-07-27 zhouzhe 参数中不能出现%号（代码错误）和'号（数据库错误)
local function check_character( parameter )

    local str_res = string.find(parameter,"'")
    local str_tmp = string.find(parameter,"%%")
    if str_res or str_tmp then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "Parameter")
    end
end

local function check_parameter(args)
    -- 2015-07-27 zhouzhe
    local str_parameter = ""
    for _,v in pairs(args) do
        if not v then
            v = ""
        end
        local str = tostring(v)
        str_parameter = str_parameter..str
    end 
    check_character(str_parameter)

    if not args or type(args) ~= "table" then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "table")
    end

    if ( not args['appKey'] ) or ( #args['appKey'] > 10 ) or ( not utils.is_number(args['appKey']))  then
        only.log("E", "appKey is error!" )
        gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
    end

    if not args['daokePassword'] or (#args['daokePassword'] < 6) then
        only.log("E", "daokePassword is error!")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'daokePassword')
    end

    if args['clientIP'] then
        if args['clientIP'] == nil or (string.match(args['clientIP'], '%d+%.%d+%.%d+%.%d+') == nil ) then
            only.log("E", "clientIP is error! ")
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "clientIP")
        end
    end
    url_info['app_key'] = args['appKey']
    safe.sign_check(args, url_info)
end

function handle()
    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()
    
    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_info['client_host'] = ip
    url_info['client_body'] = body

    local args = utils.parse_url(body)

    -->> check parameters
    check_parameter( args )

    local sql

    -- 手机号码为1开头的11位数字
    if #args['username'] == 11 and utils.is_number(args['username']) and tonumber(string.sub(args['username'], 1, 1)) == 1 then
        sql = string.format(sql_fmt.get_accountID_by_mobile, args['username'])
        -- 用户邮箱字段中包含@符号
    elseif string.match(args['username'], '@') then
        sql = string.format(sql_fmt.get_accountID_by_email, args['username'])

        -- 用户名是由数字、下划线或字母组成，且首字母为非数字
    elseif utils.is_word(string.sub(args['username'], 1, 1)) then
        sql = string.format(sql_fmt.get_accountID_by_name, string.lower(args['username']))
    else
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'username')
    end

    -- only.log('D',sql)
    local ok, result = mysql_pool_api.cmd("app_usercenter___usercenter", 'select', sql)

    if not ok or not result then 
        only.log('E',string.format("get_accountID_by===%s",sql))
        gosay.go_false(url_info,msg["MSG_DO_MYSQL_FAILED"])
    end

    -- 判断该用户名是否存在
    if #result == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_USER_NAME_NOT_EXIST"])
    elseif #result>1 then
        only.log('E', string.format('this username:%s has too many record', args['username']))
        gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], 'username')
    end

    local a_id = result[1]['accountID']

    -- 如果输入的是手机或邮箱  验证他们是否有效
    if (result[1]['checkMobile'] and tonumber(result[1]['checkMobile']) ~= 1) or (result[1]['checkUserEmail'] and tonumber(result[1]['checkUserEmail']) ~= 1) then
        gosay.go_false(url_info, msg["MSG_ERROR_USER_NAME_UNUSABLE"])
    end

    -- 判断accountID 和密码是否有效
    local password = ngx.md5(sha.sha1(args['daokePassword']) .. ngx.crc32_short(args['daokePassword']))
    sql = string.format(sql_fmt.check_userlist_record, a_id)
    ok, result = mysql_pool_api.cmd("app_usercenter___usercenter", 'select', sql)
    if not ok then
        only.log('E',string.format("check_userlist_record failed, %s",sql))                                              
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result == 0 then
        gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NO_SERVICE"])
    elseif result[1]['daokePassword'] ~= password then
        gosay.go_false(url_info, msg["MSG_ERROR_PWD_NOT_MATCH"])
    end

    local imei = result[1]['imei']
    local brandType = "未知设备"
    local isThirdModel = 0
    if #imei==15 then
        ------============
        -->> 获取用户model号
        sql1 = string.format(sql_fmt.sql_get_model_by_imei, imei )
        only.log("D", string.format("==get user model==%s", sql1))
        local ok, ret = mysql_pool_api.cmd('app_ident___ident', 'SELECT', sql1)
        if not ok  or not ret then
            only.log('E', "get model is failed")
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end
        if #ret < 1 then
            only.log("E", "get model return error")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "IMEI")
        end
        -->> model
        model = ret[1]['model']
        -->> 增加是否为车机设备参数和model名称
        sql = string.format(sql_fmt.sql_get_model_info, model )
        local ok, res_third = mysql_pool_api.cmd('app_crowd___crowd', 'SELECT', sql)
        if not ok then
            only.log('E', "get isThirdModel is failed")
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end
        if #res_third < 1 or type(res_third) ~= "table" then
            only.log("E", "get isThirdModel return is error")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
        end
        brandType = res_third[1]['brandType']
        isThirdModel = res_third[1]['isThirdModel']
        -----=============
    end
    sql = string.format(sql_fmt.sl_user_info, a_id)
    only.log('D',sql)
    ok, result = mysql_pool_api.cmd("app_cli___cli", 'select', sql)

    if not ok or result == nil then
        only.log('E',string.format("sl_user_info failed, %s",sql))
        gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #result == 0 then
        only.log("E", "mysql is sccess but return value is nil ")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "result" )
    end

    result[1]['brandType'] = brandType

    result[1]['isThirdModel'] = isThirdModel

    local ok, ret_req = utils.json_encode(result[1])
    if not ok then
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_BAD_JSON'])
    end
    
    gosay.go_success(url_info,msg['MSG_SUCCESS_WITH_RESULT'], ret_req)

end

safe.main_call( handle )
