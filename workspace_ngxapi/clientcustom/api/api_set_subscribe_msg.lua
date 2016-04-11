--owner:jiang z.s. 
--time :2014-06-13
--设置用户所订阅消息类型

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local cutils    = require('cutils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local userlist_dbname = 'app_usercenter___usercenter'
local weibo_dbname    = 'app_weibo___weibo'

local G = {
    sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ",
    sql_check_imei      = "select status from mirrtalkInfo where imei = %s AND nCheck = %s and validity = 1 and unix_timestamp() <= endTime limit 1 ",

    sql_get_max_idx = "SELECT max(subscribedID) as maxval FROM  subscribedTypeInfo where subscribedType = %d  and validity = 1 ",

    sql_query_subscribed = "select subscribedValue as subscribedValue from userSubscribedInfo where accountID = '%s' limit 1 ",

    sql_insert_subscribed =  "insert into userSubscribedInfo(accountID,subscribedValue,createTime,updateTime) " .. 
                                        " values('%s', '%s', unix_timestamp(),unix_timestamp() ) ",

    sql_update_subscribed_info = "update userSubscribedInfo set  subscribedValue = '%s',updateTime = unix_timestamp() where accountID = '%s'  ",

    sql_backup_subscribed_info = "insert into userSubscribedHistory(accountID,subscribedValue,updateTime) " ..
                                          " select accountID,subscribedValue,updateTime from userSubscribedInfo  " ..
                                          " where accountID = '%s'  " 
}


local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}


---- 对accountID进行数据库校验
local function check_userinfo(account_id)
    local sql_str = string.format(G.sql_check_accountid,account_id)
    local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok_status or user_tab == nil then
        only.log('D',sql_str)
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    if #user_tab >1 then 
        -----数据库存在错误,
        only.log('E','[***] userList accountID recordset > 1 ')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end
end

---- 对accountID进行数据库校验
local function check_imei(account_id)
    local sql_str = string.format(G.sql_check_iemi,account_id)
    local ok_status,user_tab = mysql_api.cmd(imei_dbname,'SELECT',sql_str)
    if not ok_status or user_tab == nil then
        only.log('D',sql_str)
        only.log('E','IMEI connect imei_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    if #user_tab >1 then 
        -----数据库存在错误,
        only.log('E','[***] IMEI userList accountID recordset > 1 ')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end

end

-->chack parameter
local function check_parameter(args)
    local account_id = tostring(args['accountID'])
    if not account_id then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
    if not args['systemSubscribed'] or (tonumber(args['systemSubscribed']) or 0) ~= 1 then
        if not app_utils.check_accountID(args['accountID']) then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
        end
        if not account_id  or #account_id ~= 10 then
             gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID length')
        end
        check_userinfo(accountID)
    else
        if #account_id == 10 then
            check_userinfo(accountID)
        elseif #account_id == 15 then
            check_imei(accountID)
        else
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
        end
    end
    ---- 2015-04-10 jiang z.s. KLD skd java 
    safe.sign_check(args, url_tab,  'accountID', safe.ACCESS_WEIBO_INFO )
end

local function get_max_val( sql_str )
    local ok_status,ok_tab = mysql_api.cmd(weibo_dbname,"SELECT",sql_str)
    if not ok_status or ok_tab == nil then 
        only.log('D',sql_str)
        only.log('E','=====get_max_val====failed!')
        return 0
    end
    return tonumber(ok_tab[1]['maxval']) or 0
end

local function bin_str_to_tab( str )
    local tab = {}
    local max = #str
    for i = 1 ,  max do
        tab[i] =  string.sub(str,i,i)
    end
    return tab
end

local function insert_system_subscribed(account_id,sub_val)
    local sql_str = string.format(G.sql_insert_subscribed,account_id,sub_val)
    local ok_status,ok_tab = mysql_api.cmd(weibo_dbname,'INSERT',sql_str)
    if not ok_status then
        only.log('E',sql_str)
        only.log('D',"INSERT database failed!--==")
        return false
    end
    return true
end

local function update_system_subscribed(account_id,sub_val)
    local sql_str = string.format(G.sql_update_subscribed_info,sub_val, account_id)
    only.log('D',sql_str)
    local ok_status,ok_tab = mysql_api.cmd(weibo_dbname,'UPDATE',sql_str)
    if not ok_status then
        only.log('E',sql_str)
        only.log('D',"UPDATE database failed!--==")
        return false
    end
    return true
end

local function backup_subscribed_info(account_id )
    local sql_str = string.format(G.sql_backup_subscribed_info, account_id )
    local ok_status,ok_tab = mysql_api.cmd(weibo_dbname,'INSERT',sql_str)
    if not ok_status then
        only.log('E',sql_str)
        only.log('D',"backup_subscribed_info database failed!--==")
        return false
    end
    return true
end

local function save_subscribed_info_to_redis(account_id, isum)
    
    local tmp_key = string.format("%s:userMsgSubscribed",account_id,isum)

    only.log('D',string.format("save_subscribed_info_to_redis  key:%s   val:%s", tmp_key,isum))

    local ok_status,ok_tab = redis_api.cmd('private','set', tmp_key , isum)
    if not ok_status then 
        only.log('D',"update systemSubscribed with redis  failed --==")
        return false
    end
    return true

end

local function really_set_subscribed( account_id, parameter , issystem) 
    ---- 1:1|12:0|8:0|4:0
    local sql_str = string.format(G.sql_query_subscribed,account_id)
    local ok_status,ok_tab = mysql_api.cmd(weibo_dbname,'SELECT',sql_str)
    if not ok_status or not ok_tab then
        only.log('D',sql_str)
        only.log('E','connect weibo_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    local is_update = false
    ------默认最大长度为512----
    local sub_bin_length = 512
    local sub_bin_val = string.rep("1",sub_bin_length)
    if #ok_tab == 1 then
        is_update = true
        if ok_tab[1]['subscribedValue'] and #ok_tab[1]['subscribedValue'] == sub_bin_length then
            sub_bin_val = ok_tab[1]['subscribedValue']
        end
    end

    only.log('D',string.format("is exists:%s  val:%s", is_update, sub_bin_val))


    local tmp_tab = utils.str_split(parameter,"|")      ---- 分割字符串|
    local par_tab = {}
    for i,v in pairs(tmp_tab) do
        local new_tmp_tab = utils.str_split(v,":")        ---- 分割字符串子值 1:0
        if new_tmp_tab and #new_tmp_tab == 2 then
            par_tab[new_tmp_tab[1]] = new_tmp_tab[2]
        else
            only.log('E',string.format(" account_id:%s  ----  %s format is error [%s]  ", account_id, parameter, v ))
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter format')
        end
    end

    -----------------二进制字符串更新开始,从左至右边----------------------
    local sys_max_index = 32
    local isum = 0
    local new_tab = bin_str_to_tab(sub_bin_val)          ----所有字符串转换为tab,更新设置的值
    for k,v in pairs(par_tab) do
        if issystem == 1 and ( ( tonumber(k) or 100) >  sys_max_index  or (tonumber(v) or -1 ) > 1 or ( tonumber(v) or -1 ) < 0 ) then
            only.log('E',string.format("system maxval:%s  index:%s val:%s ", sys_max, k , v ) )
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter val')
        elseif issystem == 0 and ( ( tonumber(k) or 0)  > sub_bin_length or ( tonumber(k) or 0) <  sys_max_index  or (tonumber(v) or -1 ) > 1 or ( tonumber(v) or -1 ) < 0 ) then
            only.log('E',string.format("user app maxval:%s  index:%s val:%s ", sys_max, k , v ) )
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter val')
        end
        new_tab[tonumber(k)] = tonumber(v)
    end


    local mysql_val_str = table.concat( new_tab, "")

    local ok_status = nil
    if is_update then
        only.log('D',"=====is---update===")
        ok_status = update_system_subscribed(account_id,mysql_val_str)
    else
        only.log('D',"=====is---insert===")
        ok_status = insert_system_subscribed(account_id,mysql_val_str)
    end

    if not ok_status then return false end

    if backup_subscribed_info(account_id) then
        ok_status = save_subscribed_info_to_redis(account_id,mysql_val_str)
    else
        return false
    end

    only.log('D',string.format("----end-----accountID:%s  val:%s", account_id, mysql_val_str) )

    return ok_status

end


local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    url_tab['client_host'] = req_ip
    if not req_body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_body'] = req_body

    local args = utils.parse_url(req_body)
    if not args then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
    end

    if not args['subParameter'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"subParameter")
    end

    url_tab['app_key'] = args['appKey']

    local accountID  = args['accountID']
    local isSystem = tonumber(args['systemSubscribed']) or 0
    
    
    local ok_status = really_set_subscribed(accountID,args['subParameter'],isSystem)
    

    if not ok_status then
         gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],"ok!")
end

safe.main_call( handle )
