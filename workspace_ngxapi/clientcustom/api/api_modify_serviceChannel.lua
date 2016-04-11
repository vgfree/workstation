---- qiumaosheng
---- 2015-07-14
---- 修改服务频道详细信息


local ngx       =  require('ngx')
local msg       =  require('msg')
local only      =  require('only')
local safe      =  require('safe')
local link      =  require('link')
local gosay     =  require('gosay')
local utils     =  require('utils')
local appfun    =  require('appfun')
local app_utils =  require('app_utils')
local mysql_api =  require('mysql_pool_api')
local cur_utils =  require('clientcustom_utils')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
    -- 校验accountid是否合法
    sql_check_accountid = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1 ",

    -- 检查服务频道(id)及审核状态(申请阶段)
    sql_check_channel_exist = " SELECT channelUrl, channelName, logoUrl, briefIntro, checkStatus FROM applyServiceChannelInfo " .. 
                                " WHERE id = %s and accountID='%s' and validity = 1",

    -- 修改服务频道信息(申请阶段)
    sql_update_applyInfo = " UPDATE applyServiceChannelInfo SET channelUrl = '%s', channelName = '%s', logoUrl = '%s', briefIntro = '%s', " .. 
                            " modifyCount = modifyCount + 1, channelStatus = %d, updateTime = '%s', checkStatus = '%d', remark = '%s' " .. 
                            " WHERE id = %s and accountID= '%s' and validity = 1 " ,

    -- 检查此number服务频道是否存在(重审阶段)
    sql_check_agree_channel = " select channelUrl, channelName, logoUrl, briefIntro, applyAppKey " .. 
                            " from checkServiceChannelInfo where accountID = '%s' and channelNumber = '%s' and validity = 1 limit 1 " ,

    -- 检查频道的审核状态(重审阶段)
    sql_check_channel_check_status = " select checkStatus from applyServiceChannelInfo " .. 
                                        " where accountID = '%s' and channelNumber = '%s' and  validity = 1 ",

    -- 修改申请表的频道数据和状态(重审阶段)
    sql_update_apply_channel_info = " update applyServiceChannelInfo set channelUrl = '%s', channelName = '%s', logoUrl = '%s', briefIntro = '%s', " .. 
                                        " modifyCount = modifyCount + 1, checkStatus = %d, channelStatus = %d, updateTime = %s " .. 
                                            " where accountID = '%s' and channelNumber = '%s' and validity = 1 ",

    -- 插入新重审数据到modify重审表(重审阶段)
    sql_insert_modify_info = " insert into modifyServiceChannelInfo (accountID, channelNumber, beforeChannelUrl, beforeChannelName, beforeLogoUrl, " ..
                                " beforeBriefIntro, afterChannelUrl, afterChannelName, afterLogoUrl, afterBriefIntro, checkAccountID, checkTime, checkStatus, " .. 
                                    " checkRemark, checkAppKey, createTime, updateTime, validity, remark, applyAppKey) " ..
                                        " values( '%s', '%s', '%s', '%s', '%s', " ..
                                            " '%s', '%s', '%s', '%s', '%s', '%s', %s, %d, " .. 
                                                "  '%s', '%s', %s, %s, %d, '%s', %s )",
}

local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}


local function check_parameter(args)

    if not args['accountID'] or string.find(args['accountID'] , "'") or not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    if not args['infoType'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
    end
    local info_type = tonumber(args['infoType'])
    if not ( info_type == cur_utils.SERVICE_CHANNEL_APPLY_PERIOD or
            info_type == cur_utils.SERVICE_CHANNEL_RECHECK_PERIOD) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
    end

    if info_type == cur_utils.SERVICE_CHANNEL_APPLY_PERIOD then
        if  not (#args['channelID'] > 0) or string.find(args['channelID'], "%.") or not tonumber(args['channelID'])  then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelID')
        end
    end

    if info_type == cur_utils.SERVICE_CHANNEL_RECHECK_PERIOD  then
        if (not (#args['channelNumber'] > 0)) or string.find(args['channelNumber'], "'") then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
        end
    end

    if args['channelUrl'] and string.find(args['channelUrl'] , "'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelUrl')
    end

    if args['channelName'] and string.find(args['channelName'] , "'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
    end

    if args['logoUrl'] and string.find(args['logoUrl'] , "'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'logoUrl')
    end

    if args['briefIntro'] and string.find(args['briefIntro'] , "'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'briefIntro')
    end

    safe.sign_check(args, url_tab)
end


-- 检查当前的accountid是否合法
local function check_userinfo( account_id )
    local sql_str = string.format(G.sql_check_accountid, account_id)
    local ok,ret = mysql_api.cmd(userlist_dbname ,'SELECT', sql_str)

    if not ok or not ret or type(ret) ~= "table" then
        only.log('E', string.format('connect userlist_dbname failed!, %s ' , sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #ret == 0 then
        only.log('E', string.format('accountID recordset == 0, sql_str:[%s]' , sql_str))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
end


-- check服务频道有没有申请过并且查看当前的状态是否可以修改服务频道信息
local function check_apply_channel_exist(args)

    local sql_str = string.format(G.sql_check_channel_exist, args['channelID'], args['accountID'])
    local ok, ret_tab = mysql_api.cmd(channel_dbname ,'SELECT', sql_str)

    if not ok or not ret_tab or type(ret_tab) ~= "table" then
        only.log('E', string.format('connect channel_dbname failed!, sql_str:[%s] ' , sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    -- 该语境账户没有此id的服务频道, 考虑是否添加此错误码
    if #ret_tab == 0 then
        only.log('E',sql_str)
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelID')
    end

    -- id为主键,不做行大于1的检查

    -- 考虑变更错误码
    if tonumber(ret_tab[1]['checkStatus']) == cur_utils.SERVICE_CHANNEL_STATUS_OF_CHECKING then -- 0待审核
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'can not modify,pls waiting for check')
    end

    -- 考虑变更错误码
    if tonumber(ret_tab[1]['checkStatus']) == cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE then -- 2审核通过
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'already checked')
    end

    return ret_tab[1]
end


-- 修改服务频道信息
local function modify_apply_channel_info(args, res_tab)

    local cur_time       = os.time()
    local check_status   = cur_utils.SERVICE_CHANNEL_STATUS_OF_CHECKING
    local remark         = '修改申请阶段的服务频道信息'
    local channel_status = cur_utils.SERVICE_CHANNEL_USER_STATUS_CHECKING

    -- 支持修改一个字段或多个字段的服务频道信息 
    for k,_ in pairs(res_tab) do
        if args[k] and args[k] ~= '' then
            res_tab[k] = args[k]
        end
    end

    local sql_str = string.format(G.sql_update_applyInfo, res_tab['channelUrl'], 
                                                            res_tab['channelName'], 
                                                            res_tab['logoUrl'], 
                                                            res_tab['briefIntro'],
                                                            channel_status,
                                                            cur_time, 
                                                            check_status, 
                                                            remark, 
                                                            args['channelID'], 
                                                            args['accountID'])

    local ok_status = mysql_api.cmd(channel_dbname ,'UPDATE', sql_str)
    if not ok_status then
        only.log('E',"update applyServiceChannelInfo fail! sql_str:[%s]", sql_str)
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

end

local function check_approved_channel_exist( account_id, channel_number )

    local sql_str = string.format(G.sql_check_agree_channel, account_id, channel_number)

    local ok_status, check_tab = mysql_api.cmd(channel_dbname ,'SELECT', sql_str)
    if not ok_status or not check_tab or type(check_tab) ~= 'table' then
        only.log('E',"connect channel_dbname fail! sql_str:[%s]", sql_str)
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    -- 考虑添加错误码
    if #check_tab == 0 then
        only.log('E'," accountID channelNumber recordset == 0, sql_str:[%s]", sql_str)
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channel_number')
    end

    return check_tab[1]

end

-- 修改审核通过的服务频道(重审阶段)
-- 1.修改申请表的频道数据和状态
-- 2.插入新重审数据到modify重审表
local function modify_channel_info( check_tab, args )

    local account_id     = args['accountID']
    local channel_number = args['channelNumber']

    local channel_url  = not (args['channelUrl'] == '' or not args['channelUrl']) and args['channelUrl'] or check_tab['channelUrl']
    local channel_name = not (args['channelName'] == '' or not args['channelName']) and args['channelName'] or check_tab['channelName']
    local logo_url     = not (args['logoUrl'] == '' or not args['logoUrl']) and args['logoUrl'] or check_tab['logoUrl']
    local brief_intro  = not (args['briefIntro'] == '' or not args['briefIntro']) and args['briefIntro'] or check_tab['briefIntro']

    local sql_tab = {}
    -- APPLY
    -- 修改申请表的频道数据和状态(重审阶段)
    -- " update applyServiceChannelInfo set channelUrl = '%s', channelName = '%s', logoUrl = '%s', briefIntro = '%s' " .. 
    --                                 " modifyCount = modifyCount + 1, checkStatus = %d, channelStatus = %d, updateTime = %s " .. 
    --                                     " where accountID = '%s' and channelNumber = '%s' and validity = 1 ",

    local check_status = cur_utils.SERVICE_CHANNEL_STATUS_OF_RECHECKING -- 3重审中
    local channel_status = cur_utils.SERVICE_CHANNEL_USER_STATUS_CHECKING -- 0待审核
    local cur_time = os.time()

    local sql_str = string.format(G.sql_update_apply_channel_info, channel_url, 
                                                                channel_name, 
                                                                logo_url, 
                                                                brief_intro,
                                                                check_status, 
                                                                channel_status, 
                                                                cur_time, 
                                                                account_id, 
                                                                channel_number)
    only.log('D', string.format("sql_str:[%s]", sql_str))
    table.insert(sql_tab, sql_str)

    -- MODIFY
    -- 插入新重审数据到modify重审表(重审阶段)
    -- " insert into modifyServiceChannelInfo (accountID , channelNumber, beforeChannelUrl, beforeChannelName, beforeLogoUrl, " ..
    --                             " beforeBriefIntro, afterChannelUrl, afterChannelName, afterLogoUrl, afterBriefIntro, checkAccountID, checkTime, checkStatus, " .. 
    --                                 " checkRemark, checkAppKey, createTime, updateTime, validity, remark, applyAppKey " ..
    --                                     " values( '%s', '%s', '%s', '%s', '%s', " ..
    --                                         " '%s', '%s', '%s', '%s', '%s', '%s', %s, %d, " .. 
    --                                             "  '%s', %s, %s, %s, %d, '%s', %s )",
    local check_accountID = ''
    local check_time      = 0
    local check_status    = cur_utils.SERVICE_CHANNEL_STATUS_OF_RECHECKING
    local check_remark    = ''
    local check_appKey    = ''
    local create_time     = cur_time
    local update_time     = cur_time
    local validity        = 1
    local remark          = ''
    local apply_appKey    = check_tab['applyAppKey']

    sql_str = string.format(G.sql_insert_modify_info, account_id, channel_number, 
                                                    check_tab['channelUrl'], -- 原频道数据
                                                    check_tab['channelName'], 
                                                    check_tab['logoUrl'],
                                                    check_tab['briefIntro'],
                                                    channel_url,             -- 改之后的频道数据
                                                    channel_name,
                                                    logo_url,
                                                    brief_intro,
                                                    -- args['channelUrl'],      
                                                    -- args['channelName'],
                                                    -- args['logoUrl'],
                                                    -- args['briefIntro'],
                                                    check_accountID,         -- 审核信息
                                                    check_time,
                                                    check_status,
                                                    check_remark,
                                                    check_appKey,
                                                    create_time,             -- 其他
                                                    update_time,
                                                    validity,
                                                    remark,
                                                    apply_appKey)
    only.log('D', string.format("sql_str:[%s]", sql_str))
    table.insert(sql_tab, sql_str)

    local ok_status, ret = mysql_api.cmd(channel_dbname, 'AFFAIRS', sql_tab)
    if not ok_status then
        only.log('E',string.format("do AFFAIRS failed, sql_tab: \r\n [%s]", table.concat( sql_tab, "\r\n")) )
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end

end

-- 从 apply 表检查频道审核状态(重审阶段)
local function check_channel_check_status( account_id, channel_number )
    
    local sql_str = string.format(G.sql_check_channel_check_status, account_id, channel_number)

    local ok_status, ret_tab = mysql_api.cmd(channel_dbname ,'SELECT', sql_str)
    if not ok_status or not ret_tab or type(ret_tab) ~= "table" then
        only.log('E', string.format('connect channel_dbname failed!, %s ', sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #ret_tab == 0 then
        only.log('D', string.format('accountID channelNumber recordset == 0, sql_str:[%s]', sql_str))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
    end

    -- checkStatus    0待审核  1驳回  2审核成功 3重审中 4重审成功 5重审驳回
    -- 只有审核状态为(2审核成功)或(4重审成功)修改, 前者表示首次修改，后者表示再次修改
    local check_status = tonumber(ret_tab[1]['checkStatus'])

    if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_RECHECKING then
        only.log('D', string.format(' check_channel_check_status check_status:[%s], sql_str:[%s]', check_status, sql_str))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'pls waiting for recheck')
    end

    -- 审核成功         表示第一次修改
    -- 重审成功,重审驳回  表示再次修改
    -- 待审核,驳回       表示频道还未审核通过(申请阶段)
    if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_CHECKING or 
        check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REJECT then
        -- check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REDISMISSED then
        only.log('D', string.format(' check_channel_check_status check_status:[%s], sql_str:[%s]', check_status, sql_str))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channel is not approved ')
    end

end

local function handle()

    local body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    if not body then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    url_tab['client_host'] = ip
    url_tab['client_body'] = body

    local args = utils.parse_url(body)
    if not args then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
    end

    -- 检查参数
    check_parameter(args)

    -- 检查当前的accountid是否合法
    check_userinfo(args['accountID'])

    local info_type = tonumber(args['infoType'])
    -- 修改申请阶段的服务频道信息
    if info_type == cur_utils.SERVICE_CHANNEL_APPLY_PERIOD then

        -- 检查该aid是否存在此id的服务频道
        -- 并根据频道状态是否可以修改服务频道信息
        res_tab = check_apply_channel_exist(args)

        -- 修改频道信息
        modify_apply_channel_info(args, res_tab)
    end

    -- 修改重审阶段的服务频道信息
    if info_type == cur_utils.SERVICE_CHANNEL_RECHECK_PERIOD then

        -- 检查存在性
        local check_tab = check_approved_channel_exist( args['accountID'], args['channelNumber'] )

        -- 检查频道审核状态
        check_channel_check_status(args['accountID'], args['channelNumber'])

        modify_channel_info(check_tab, args)

    end

    gosay.go_success( url_tab, msg["MSG_SUCCESS"] )
end


safe.main_call( handle )
