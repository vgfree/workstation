-- author:      zhouzhe
-- date:         2015.06.24
-- function:    查询model是否为新增

local ngx           = require('ngx')
local utils         = require('utils')
local app_utils     = require('app_utils')
local gosay         = require('gosay')
local only          = require('only')
local msg           = require('msg')
local safe          = require('safe')
local link          = require('link')
local cjson         = require('cjson')
local mysql_api     = require('mysql_pool_api')

local coreIdentif_dbname = "app_ident___ident"
local config_dbname = "app_mirrtalk___config"

local sql_fmt = {
    sql_check_model = "SELECT 1 FROM modelInfo WHERE model= '%s' ",
    sql_config_info = " SELECT 1 FROM configInfo WHERE model = '%s' ",
    sql_config_infomation = " SELECT 1 FROM configInfo WHERE model = '%s' AND accountID = '%s' ",

}

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

--  检查参数
local function check_parameter(args)

    if not args or type(args) ~= "table" then
        only.log("E", " args not is table ")
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "args")
    end
    only.log("D", "appKey: %s", args['appKey'])
    if not args['appKey'] or #args['appKey'] > 10 or not utils.is_number(args['appKey'])  then
        gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
    end

    if not args['model'] or args['model'] == '' then
        only.log("E", "model is error !")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "model")
    end
    if args['accountID'] and args['accountID'] ~= '' then
        if #args['accountID'] ~= 10 then
            only.log("E", "accountID is error!")
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID")
        end
    end
    url_info['app_key'] = args['appKey']
    safe.sign_check(args, url_info)
end

local function handle()

    local body = ngx.req.get_body_data()

    if not body  then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_info['client_host'] = ngx.var.remote_addr
    url_info['client_body'] = body

    local args = utils.parse_url(body)

    -- 1)检查参数
    check_parameter(args)

    local sql = string.format(sql_fmt.sql_check_model, args['model'])
    local ok , result = mysql_api.cmd( coreIdentif_dbname, 'select', sql)
    if not ok or not result then
        only.log('E',string.format("sql check model failed , %s", sql ))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    local isnewmodel, isdefine = 0, 0
    if #result == 0 then
        only.log("E", "this model is not exists!")
        gosay.go_false(url_info, msg['MSG_ERROR_DEVICE_MODEL_INVALID'])
    end
    -- 查询用户是否设置开机参数
    if args['accountID'] and #args['accountID'] == 10  then
        local sql = string.format(sql_fmt.sql_config_infomation, args['model'], args['accountID'] )
        local ok, result = mysql_api.cmd( config_dbname, 'select', sql)
        if not ok or not result then
            only.log('E',string.format("sql check model failed , %s", sql ))
            gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end
        only.log("D","lenResult:%s, sql:%s",#result, sql)
        if #result ~= 0 then
            isdefine = 1
        end
    end

    local sql = string.format(sql_fmt.sql_config_info, args['model'] )
    local ok, result = mysql_api.cmd( config_dbname, 'select', sql)
    if not ok or not result then
        only.log('E',string.format("sql check model failed , %s", sql ))
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    only.log("D","result:%s, sql:%s",#result, sql)
    if #result == 0 then
        isnewmodel = 1
    end

    local table = {
        isdefine = isdefine,
        isnewmodel = isnewmodel,
    }
    if not table then
        only.log("E", "table is nil")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "table")
    end
    local ok,ret = pcall(cjson.encode, table )
    if not ok then
        only.log("E", ok)
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "cjson")   
    end
    gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end

safe.main_call( handle )
