-- zhouzhe
-- 2015-07-29
-- 修改手机用户密码

local ngx   = require('ngx')
local sha   = require('sha1')
local msg   = require('msg')
local only  = require('only')
local safe  = require('safe')
local gosay = require('gosay')
local utils = require('utils')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

local G = {

        select_account = "SELECT accountID FROM userLoginInfo WHERE userStatus=1 AND mobile='%s'",

        update_user_pwd = "UPDATE userLoginInfo SET daokePassword='%s', updateTime=%d WHERE accountID='%s'",

        -- select_account = "SELECT accountID FROM userRegisterInfo WHERE validity=1 AND mobile='%s'",

        -- select_user_list = "SELECT accountID, userStatus, imei, daokePassword FROM userList WHERE accountID='%s' AND userStatus IN(1,4,5)",

        -- update_user_list = "UPDATE userList SET daokePassword='%s', updateTime=%d WHERE accountID='%s'",

        -- insert_user_history = "INSERT INTO userListHistory(accountID, userStatus, updateTime, daokePassword, imei )"..
        --                     "VALUES('%s', %d, '%s', '%s', '%s')",
}

local cur_time =os.time()
local user_dbname  = "app_usercenter___usercenter"

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function modify_password_by_mobile(args)
    local mobile = args['mobile']
    local password = ngx.md5(sha.sha1( args['newPassword'] ) .. ngx.crc32_short( args['newPassword'] )) 

    -->> 1) 根据手机号获取accountID
    local sql1 = string.format(G.select_account, mobile)
    only.log('D',string.format("select_account_by_mobile:%s", sql1 ))
    local ok, ret = mysql_api.cmd(user_dbname, 'select', sql1)
    if not ok or not ret then
        only.log("E", string.format("get user accountid is failed= mobile=%s=", mobile))
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"] )
    end

    if #ret <1 or type(ret)~= "table" then
        only.log("E", "select accountID return error")
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "mobile")
    end
    local accountID = ret[1]['accountID']

    -->> 2)根据accountID修改手机用户密码 
    local sql2 = string.format(G.update_user_pwd, password, cur_time, accountID )
    only.log('D',string.format("update user pwd===%s", sql2 ))
    local ok = mysql_api.cmd(user_dbname, 'update', sql2)
    if not ok then
        only.log('E',"mysql failed update user failed")
        gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"] )
    end

    -- -- 2) 根据accountID获取userLIst表信息
    -- local sql2 = string.format(G.select_user_list, accountID)
    -- only.log('D',string.format("select_user_list:%s", sql2 ))
    -- local ok, res = mysql_api.cmd(user_dbname, 'select', sql2)

    -- if not ok or not res then
    --     only.log('E',"mysql failed select_user_list")
    --     gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"] )
    -- end

    -- if #res <1 or type(res)~= "table" then
    --     only.log("E", "select accountID return error")
    --     gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "mobile")
    -- end

    -- local transaction_tab = {}
    -- local cur_time = os.time()

    -- -- 3) 修改密码并备份
    -- local sql3 = string.format(G.update_user_list, password, cur_time, accountID )
    -- local sql4 = string.format(G.insert_user_history, accountID, res[1]['userStatus'], cur_time, res[1]['daokePassword'], res[1]['imei'])
    -- table.insert(transaction_tab, sql3)
    -- table.insert(transaction_tab, sql4)
    -- only.log('D', string.format("update_user_list==:%s", sql3))
    -- only.log('D', string.format("insert_user_history==:%s", sql4))
    -- local ok = mysql_api.cmd(user_dbname, 'affairs', transaction_tab)
    -- if not ok then
    --     only.log("E", "modify password failed")
    --     gosay.go_false(url_info, msg['MSG_ERROR_MODEFY_PSW_FAILED'])
    -- end
end

-- 检查参数
local function check_parameter(args)

    if not args or type(args) ~= 'table' then
        gosay.go_false(url_info,msg['MSG_ERROR_REQ_BAD_JSON'])
    end

    url_info['app_key'] = args['appKey']
    local mobile=args['mobile']
    if(not utils.is_number(tonumber(mobile))) or (string.len(mobile) ~= 11) or (string.sub(tostring(mobile), 1, 1) ~= '1') then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'mobile')
    end

    if (#args['newPassword'] < 6) or string.find(args['newPassword'], "'") then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "newPassword")
    end
    safe.sign_check(args, url_info)
end

local function handle()

    local head = ngx.req.raw_header()
    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_info['client_host'] = ip
    url_info['client_body'] = body

    local args = utils.parse_url(body)
    -- 检查参数
    check_parameter(args)
    -- 修改密码
    modify_password_by_mobile(args)

    gosay.go_success(url_info, msg["MSG_SUCCESS"])
end

safe.main_call( handle )
