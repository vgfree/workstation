--owner:jiang z.s. 
--time :2015-05-08
--用户设置自定义按键操作

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')
local appfun    = require('appfun')
local cjson     = require('cjson')


local userlist_dbname = 'app_usercenter___usercenter'
local custom_dbname   = 'app_custom___wemecustom'

local G = {
    sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ",
    sql_check_joinchannel = " SELECT idx from joinMemberList where validity = 1 and accountID = '%s' and number = '%s'  ",
    sql_check_custom_type = " select  1 from userCustomDefineInfo where validity = 1 and actionType = %s and customType = %s "  ,
    sql_get_channel_idx = "select idx from checkSecretChannelInfo where number = '%s' " ,
}

local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}


--local default_channel = "10086"

---- 普通频道参数长度范围
local MAX_CHANNEL_LEN = 8
local MIN_CHANNEL_LEN = 5

---- 密频道参数长度范围
--local MAX_SECRETCHANNEL_LEN = 16 
--local MIN_SECRETCHANNEL_LEN = 5 
local MAX_SECRETCHANNEL_LEN = 16 
local MIN_SECRETCHANNEL_LEN = 9 



------------------------------2015-05-08-----------------------
---- 用户按键设置列表 2015-05-08
-- parameter
-- {
--     "count":"3",
--     "list": [
--         {"actionType":"3","customType":"10","customParameter":""},
--         {"actionType":"4","customType":"10","customParameter":"000000153"},
--         {"actionType":"5","customType":"10","customParameter":"000000153"},
--     ]
-- }
------按键类型
--------- 针对吐槽按键需要定制服务频道业务,里面包含ip,端口
-- actionType = 3  吐槽按键
--      customType = "10" 路况分享
--      customType = "11" 语音记事本
--      customType = "12" 家人连线

-- actionType = 4  语音命令
--      customType = "10" 群聊频道

-- actionType = 5  群组语音
--      customType = "10" 群聊频道
------------------------------2015-05-08-----------------------

-->chack parameter
local function check_parameter(args)
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    local parameter = args['parameter']
    if not parameter or #tostring(parameter) < 5 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter')
    end

    local ok, par_tab = pcall(cjson.decode,parameter)
    if not ok or not par_tab then
        only.log('W'," %s current parameter is error ", args['accountID'] ) 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter')
    end

    local count = tonumber(par_tab['count']) or 0 
    local list = par_tab['list']
    if not list then
        only.log('W'," %s current parameter list is error ", args['accountID'] ) 
       gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter') 
    end
    if count ~= #list then
        only.log('W'," %s current parameter list count != count is error ", args['accountID'] ) 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter') 
    end

    local is_error_param = false
    for k , par_info in pairs(list) do
        local tmp_action_type = tonumber(par_info['actionType']) or 0
        local tmp_custom_type = tonumber(par_info['customType']) or 0
        local tmp_parameter = par_info['customParameter']
        if  tmp_action_type == appfun.DK_TYPE_VOICE then
            ------ is ok 
        elseif tmp_action_type == appfun.DK_TYPE_COMMAND then
            if tmp_custom_type < appfun.VOICE_COMMAND_TYPE_SECRETCHANNEL 
                            or tmp_custom_type > appfun.VOICE_COMMAND_TYPE_MAXVAL  then
                only.log('E',string.format("1 action_type: %s custom_type:%s is error",tmp_action_type, tmp_custom_type ))
                is_error_param = true
                break
            end
            ---- 20150731
            ---- 允许+键设置为空
            ---- if not tmp_parameter or not  utils.is_number(tmp_parameter) or #tmp_parameter < 5   or  #tmp_parameter >  10 then
            ----     only.log('E',string.format("2 action_type: %s custom_type:%s  parameter:%s is error",
            ----                                 tmp_action_type, tmp_custom_type , tmp_parameter ))
            ----     is_error_param = true
            ----     break
            ---- end
            ---- tmp_parameter 可允许为空
            if not tmp_parameter or (#tmp_parameter > 0 and (not utils.is_number(tmp_parameter) or #tmp_parameter < 5 or #tmp_parameter > 10)) then 
                only.log('E',string.format("2 action_type:%s,custom_type:%s,parameter:%s",tmp_action_type,tmp_custom_type,tmp_parameter))
                is_error_param = true
                break
            end
            ---- end
        elseif tmp_action_type ==  appfun.DK_TYPE_GROUP then
             if tmp_custom_type < appfun.GROUP_VOICE_TYPE_SECRETCHANNEL 
                            or tmp_custom_type > appfun.GROUP_VOICE_TYPE_MAXVAL  then
                only.log('E',string.format("3 action_type: %s custom_type:%s is error",tmp_action_type, tmp_custom_type ))
                is_error_param = true
                break
            end

            if not tmp_parameter or not  utils.is_number(tmp_parameter) or #tmp_parameter < 5   or  #tmp_parameter >  10 then
                only.log('E',string.format("4 action_type: %s custom_type:%s is error",tmp_action_type, tmp_custom_type ))
                is_error_param = true
                break
            end
        else
            only.log('E',string.format("5 action_type: %s custom_type:%s is error",tmp_action_type, tmp_custom_type ))
            is_error_param = true
            break
        end
    end

    if is_error_param then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'parameter')
    end

    args['parameter_tab'] = par_tab

    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end


---- 对accountID进行数据库校验
local function check_userinfo(account_id)
    local sql_str = string.format(G.sql_check_accountid,account_id)
    local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok_status or user_tab == nil then
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
end


---- 判断用户是否在当前频道的黑名单中 2015-05-08 
local function check_is_black( accountid , channel_num, channel_idx  )
    local ok, ret = redis_api.cmd('private','get', string.format("%s:channelStatus", channel_idx))
    if not ok  then
        only.log('E',string.format("check is black and channelType failed %s " , channel_idx ))
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end

    if tostring(ret) ~= "1" then
        ---- 当前频道已经被关闭
        only.log('W',string.format(" accountid:%s channel_num:%s channel_idx is closed ", accountid, channel_num, channel_idx ))
        gosay.go_false(url_tab, msg['MSG_ERROR_CURRENT_CHANNEL_IS_CLOSE'])
    end

    local ok, ret = redis_api.cmd('private','hget',channel_idx .. ":userStatusTab",accountid .. ":status")
    if not ok then
        only.log('E',string.format("check is black and get userStatusTab  %s %s failed " , channel_idx , accountid  ))
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end

    ---- 当前是拉黑状态
    if tostring(ret) == "3" then
        return true
    end
    return false
end

---- 得到频道编号
local function get_channel_idx(parameter)
    local sql_str = string.format(G.sql_get_channel_idx ,parameter)
    local ok , ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E',"get_channel_idx failed [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'number')
    end
    return ret[1]['idx']

end
---- 检查用户是否加入频道 
---- 2015-05-21 

local function check_is_joinchannel(accountid,channel_num)
    local sql_str = string.format(G.sql_check_joinchannel,accountid,channel_num)
    local ok , ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
    if not ok  then
        only.log('E',"sql check joinchannel failed [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if not ret or #ret == 0 then
        only.log('E',"cur user not have join channel [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_DID_NOT_JOINED'])
    end
    return ret[1]['idx']
end


function check_custom_type( action_type, custom_type )
    local sql_str = string.format(G.sql_check_custom_type, action_type, custom_type) 
    local ok ,ret = mysql_api.cmd(custom_dbname,"SELECT",sql_str)
    if not ok or not ret then
        only.log('E',string.format("sql check server channel sql failed,  %s  " ,  sql_str ))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret ~= 1 then
        return false
    end
    return true
end

---- 设置用户语音命令按键
---- 默认为群聊频道
---- 2015-05-21 jiang z.s. 

local function set_voicecommand_v2(accountid , action_type , custom_type,   parameter  )

    only.log('D',string.format("==============set_voicecommand_v2==%s %s %s %s ================",
                            accountid , action_type , custom_type,   parameter))

    local parameter_id = nil
    if not parameter or #parameter == 0 then
        local ok ,err_msg,sql_str = cur_utils.set_channel_is_empty(accountid,action_type,custom_type,custom_dbname)
        if not ok then
            only.log('E',string.format("[set channel is empty]accountid:%s,sql_str:%s",accountid,sql_str))
            gosay.go_false(url_tab,msg[err_msg])
        end
        return true
    end
    ---- 20150606
    ---- 设置按键时，跳过10086频道加入判断
    if parameter == cur_utils.default_channel then
        only.log('D',"parameter:%s,default_channel:%s",parameter,cur_utils.default_channel)
        parameter_id = get_channel_idx(parameter)
    else
        only.log('D',"[***]parameter:%s,default_channel:%s",parameter,cur_utils.default_channel)
        parameter_id = check_is_joinchannel(accountid,parameter)
    end
    ----
    if #parameter > 0 then
        if check_is_black(accountid, parameter, parameter_id) then
            only.log('W',string.format("voice accountid:%s in blacklist -->--- parameter:%s parameter_id:%s  ",
                             accountid, parameter, parameter_id))
            return false
        end
    end
    local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, parameter_id , custom_dbname )
    if not ok then
        only.log('E',string.format("user set channel info account_id: %s  actionType :%s customType: %s customPar:%s secretChannel:%s \r\n sql:%s ",
                                        accountid,  action_type, custom_type , parameter, parameter_id , err_sql))

        gosay.go_false(url_tab, msg[err_msg])
    end
    return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter_id )
end


local function  set_groupvoice_v2(accountid , action_type , custom_type,   parameter  )
    
    only.log('D',string.format("==============set_groupvoice_v2===%s %s %s %s ===============", 
                    accountid , action_type , custom_type,   parameter ))

    local parameter_id = nil
     ---- 20150606
    ---- 设置按键时，跳过10086频道加入判断
    if parameter == cur_utils.default_channel then
        only.log('D',"***groupvoice==parameter:%s,default_channel:%s",parameter,cur_utils.default_channel)
        parameter_id = get_channel_idx(parameter)
    else
        only.log('D',"-----groupvoice==parameter:%s,default_channel:%s",parameter,cur_utils.default_channel)
        parameter_id = check_is_joinchannel(accountid,parameter)
    end
    ----- 
    if check_is_black(accountid, parameter, parameter_id) then
        only.log('W',string.format("group accountid:%s in blacklist -->--- parameter:%s parameter_id:%s  ",
                         accountid, parameter, parameter_id))
        return false
    end
    local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, parameter_id , custom_dbname )
    if not ok then
        only.log('E',string.format("user set channel info account_id: %s  actionType :%s customType: %s customPar:%s secretChannel:%s \r\nsql:%s ",
                                        accountid,  action_type, custom_type , parameter, parameter_id , err_sql))
        gosay.go_false(url_tab, msg[err_msg])
    end
    return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter_id )
end

local function set_default_voice_v2(accountid , action_type , custom_type,   parameter  )
    only.log('W',"==============set_default_voice_v2===%s %s %s %s ===============", 
                    accountid , action_type , custom_type,   parameter )

    if not check_custom_type(action_type, custom_type) then
        gosay.go_false(url_tab,msg['MSG_ERROR_CURRENT_CUSTOMTYPE_NOT_EXIT'])
    end

    local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, nil , custom_dbname )
    if not ok then
        only.log('E',string.format("user set channel info account_id: %s  actionType :%s customType: %s customPar:%s\r\n sql:%s ",
                                        accountid,  action_type, custom_type , parameter , err_sql))
        gosay.go_false(url_tab, msg[err_msg])
    end
    return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter )
end

---- modify by jiang z.s. 2015-05-08 
---- 重新定义用户按键功能 
---- +/++/吐槽/都允许设置
---- 先+/++频道按键

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
    url_tab['app_key'] = args['appKey']
    check_parameter(args)

    local accountid  = args['accountID']
   
    check_userinfo(accountid)

    local cur_error_code = nil
    local par_tab = args['parameter_tab']
    local count  = tonumber(par_tab['count'])
    local list = par_tab['list']
    for k , par_info in pairs(list) do
        local tmp_action_type = tonumber(par_info['actionType']) or 0
        local tmp_custom_type = tonumber(par_info['customType']) or 0
        local tmp_parameter = par_info['customParameter']
        if  tmp_action_type == appfun.DK_TYPE_VOICE then
            ------ is ok 
            only.log('D',"tmp_action_type:%s,tmp_custom_type:%s,tmp_parameter:%s",tmp_action_type,tmp_custom_type,tmp_parameter)
            list[k]['status'], cur_error_code = set_default_voice_v2(accountid,tmp_action_type,tmp_custom_type,tmp_parameter)
        elseif tmp_action_type == appfun.DK_TYPE_COMMAND then
            if tmp_custom_type < appfun.VOICE_COMMAND_TYPE_SECRETCHANNEL 
                            or tmp_custom_type > appfun.VOICE_COMMAND_TYPE_MAXVAL  then
                
                break
            end
            -- if not tmp_parameter or not ( #tmp_parameter > 0 and utils.is_number(tmp_parameter) and #tmp_parameter > 5   and  #tmp_parameter < 10 )
            --              or tmp_parameter ~= ''  then
            ---- 20150803
            ---- 4 + 键可为空
            if not tmp_parameter or (#tmp_parameter > 0 and (not utils.is_number(tmp_parameter) or #tmp_parameter < 5 or #tmp_parameter > 10)) then 
                only.log('E',string.format("actionType = 4 tmp_parameter:%s is error",tmp_parameter))
                break
            end
            if tmp_custom_type == appfun.VOICE_COMMAND_TYPE_SECRETCHANNEL then
                list[k]['status'], cur_error_code = set_voicecommand_v2(accountid,tmp_action_type,tmp_custom_type,tmp_parameter)
            end
        elseif tmp_action_type ==  appfun.DK_TYPE_GROUP then
             if tmp_custom_type < appfun.GROUP_VOICE_TYPE_SECRETCHANNEL 
                            or tmp_custom_type > appfun.GROUP_VOICE_TYPE_MAXVAL  then
                break
            end
            if not tmp_parameter or not  utils.is_number(tmp_parameter) or #tmp_parameter < 5   or  #tmp_parameter >  10 then
                break
            end
            if tmp_custom_type == appfun.GROUP_VOICE_TYPE_SECRETCHANNEL then
                list[k]['status'], cur_error_code = set_groupvoice_v2(accountid,tmp_action_type,tmp_custom_type,tmp_parameter)
            end
        end

        ------ modify by jiang z.s. 2015-10-04
        ------ optimize log detail
        only.log('D',string.format("=========debug info action_type:%s custom_type:%s reuslt: %s %s ", 
                                tmp_action_type,tmp_custom_type,
                                list[k]['status'], cur_error_code ))

        if cur_error_code then
            only.log('W',string.format(" error: %s , accountID: %s actionType:%s , customType:%s customParameter:%s  count:%s  " , 
                                            cur_error_code , accountid , tmp_action_type, tmp_custom_type , tmp_parameter , count ))
            gosay.go_false(url_tab, msg[cur_error_code],"customParameter")
        end
    end

    if not cur_error_code then
        local ok, ret = pcall(cjson.encode,args['parameter_tab'])
        gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],ret)
    end

end


safe.main_call( handle )
