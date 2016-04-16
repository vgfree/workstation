-- author: zhangjl (jayzh1010@gmail.com) 
-- company: mirrtalk.com
-- zhouzhe 2015-08-17 修改

local ngx       = require('ngx')
local msg       = require('msg')
local safe      = require('safe')
local only      = require('only')
local gosay     = require('gosay')
local utils     = require('utils')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

local usercenter_dbname = 'app_usercenter___usercenter'
local userident_dbname = 'app_ident___ident'
local crowd_dbname = 'app_crowd___crowd'
local G = {
    sql_user_info= "SELECT imei, mobile FROM userLoginInfo WHERE userStatus=1 AND accountID='%s'",

     -->> 获取model号
    sql_get_model_by_imei = " SELECT model, nCheck FROM mirrtalkInfo WHERE imei = %s ",

    -->> 获取isThirdModel和 brandType
    sql_get_model_info = "SELECT isThirdModel, brandType FROM userModelInfo WHERE validity=1 AND model='%s'",
}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function get_imei_mobile(a_id)

    local ret_body, imei, mobile
    local checkMobile= 0
    local sql = string.format(G.sql_user_info, a_id)
    only.log('D', string.format(" sql user info ==%s",sql))
    local ok, res = mysql_api.cmd( usercenter_dbname, 'SELECT', sql)
    if not ok or not res then
        only.log('E','sl_imei connect userlist dbname failed! %s', sql )
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end

    if ok and #res ~= 0 then
        imei = res[1]['imei'] or 0
        mobile = res[1]['mobile'] or 0

        if #mobile == 11 then
            checkMobile = 1
        end
    end

    local model = ''
    local brandType = "未知设备"
    local isThirdModel = 0
    if imei and #imei == 15 then
        -->> 获取用户model号
        --modify: lvtao
        --time : 2016-1-12
        local nimei = string.sub(imei, 1, #imei -1)
        local Check = string.sub(imei, #imei, #imei)
        sql1 = string.format(G.sql_get_model_by_imei, nimei)
        only.log("D", string.format("==get user model==%s", sql1))
        local ok, ret = mysql_api.cmd(userident_dbname, 'SELECT', sql1)
        if not ok  or not ret then
            only.log('E', "get model is failed")
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end
        if #ret < 1 then
            only.log("E", "get model return error")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "IMEI")
        end
        if tonumber(ret[1]['nCheck']) ~= tonumber(Check) then 
            only.log("E", "get model nCheck is failed")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "IMEI")
        end
        -->> model
        model = ret[1]['model']
        -->> 增加是否为车机设备参数和model名称
        sql = string.format(G.sql_get_model_info, model )
        only.log("D", string.format("sql get model info ===%s", sql))
        local ok, res_third = mysql_api.cmd(crowd_dbname, 'SELECT', sql)
        if not ok then
            only.log('E', "get isThirdModel is failed")
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end
        if #res_third < 1 or type(res_third) ~= "table" then
            only.log("E", "get isThirdModel return is error")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
        end
        -->> isThirdModel, brandType
        isThirdModel = res_third[1]['isThirdModel']
        brandType = res_third[1]['brandType']
    end

    ret_body = string.format('{"imei":"%s","phone":"%s", "checkMobile":"%s", "brandType":"%s", "isThirdModel":"%s", "model":"%s"}', 
            imei or '', mobile or '', checkMobile, brandType, isThirdModel, model )

    return ret_body
end

local function check_parameter(args)
    if not args then
        only.log('E',string.format('call parse_url function return nil!'))
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
    end
    if not args['appKey'] or #args['appKey'] > 10 then
        only.log("E", "appKey is error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'appKey')
    end
    url_info['app_key'] = args['appKey']

    if (not app_utils.check_accountID(args['accountID'])) then
        only.log("E", "accountID is error")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountID")
    end
    -- 2015-07-21 zhouzhe  accessToken
    safe.sign_check(args, url_info, 'accountID', safe.ACCESS_USER_INFO)
end

local function handle()
    local body = ngx.req.get_body_data()
    local ip   = ngx.var.remote_addr
    if not body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_info['client_body'] = body
    url_info['client_host'] = ip

    local args = utils.parse_url(body)
    -- 检查参数
    check_parameter(args)
    -- 获取imei和手机号
    local ret = get_imei_mobile(args['accountID'])
    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )
