---- author:zhangerna
---- 1 查询所有能加入的群聊频道列表
---- 2 获取管理员自己的群聊频道列表
---- 3 普通用户获取所加入的群聊频道列表
---- 4 等待验证加入/验证驳回的频道

local ngx       = require('ngx')
local app_utils = require('app_utils')
local utils     = require('utils')
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

local channel_dbname = "app_custom___wemecustom"
local userlist_dbname = "app_usercenter___usercenter"
local G = {
        sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 1 ", 
        
        ---- 得到频道详情
        sql_find_secretchannel_data = " select number,name,inviteUniqueCode,introduction,case cityCode when 0  then " ..
                                        "  '全国' else cityName end as cityName, catalogID as catalogNumber, catalogName,logoURL,openType, keyWords ,createTime , " .. 
                                        " case when capacity < userCount then ( userCount div 1000 + 1 ) * 1000 else capacity end as capacity , userCount " ..
                                         " from checkSecretChannelInfo where channelStatus = 1  %s   limit %d,%d ",

        ---- 关联键
        sql_get_userkey_info = "select actionType, customType , customParameter, " .. 
                                " case when actionType = 3 then 'mainVoice' " ..
                                "       when actionType = 4 then 'voiceCommand' " ..
                                "       when actionType = 5 then 'groupVoice' end as actionName  " ..
                                " from userKeyInfo where validity = 1 and accountID = '%s' ",

        sql_user_joined_list = " select number from joinMemberList where validity = 1 and role = 0  and accountID = '%s'  " ,

        sql_user_create_and_joined_list = " select number from joinMemberList where validity = 1 and accountID = '%s'   " ,

        ---- 查询用户正在等待验证加入的频道
        sql_user_verify_message = "select number,uniqueCode,status,applyNickname,checkRemark from userVerifyMsgInfo where applyAccountID = '%s' and status = %s",

}

local url_tab = {
    type_name = 'system',
    app_key = '',
    client_host = '',
    client_body = '',
}

local function check_parameter(args)
    ---- 检查城市编号 如果城市编号不存在显示所有的频道
    if not args['infoType'] or #tostring(args['infoType']) == 0  then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'infoType')
    end
    if not (args['infoType'] == "1" or args['infoType'] == "2" or args['infoType'] == "3" or args['infoType'] == '4')  then 
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'infoType')
    end

    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab,msg["MSG_ERROR_REQ_ARG"],'accountID')
    end 
    

    ---- FIXME #args['cityCode'] > 0
    if args['cityCode'] and #args['cityCode'] > 0 then
        if not utils.is_number(args['cityCode']) or not (#tostring(args['cityCode']) == 6 or (tonumber(args['cityCode']) or -1 ) == 0 ) 
                        or #tostring(args['cityCode'])  > 10 then

            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'cityCode')
        end
    end
    
    ---- 检查频道类型
    if args['catalogID'] and #args['catalogID'] > 0 then
        if not utils.is_number(args['catalogID']) or #tostring(args['catalogID']) < 6 or #tostring(args['catalogID'])  > 10  then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'catalogID')
        end
    end

    if args['isVerify'] and #args['isVerify'] > 0 then
        local tmp_verify = tonumber(args['isVerify'])
        if not tmp_verify or not utils.is_number(args['isVerify']) or not ( tmp_verify == 0 or tmp_verify == 1 ) then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'isVerify')
        end
    end

    ---- 检查频道编号
    ---- 频道number为9位数字
    if args['channelNumber'] and #tostring(args['channelNumber']) > 0 then
        if  #tostring(args['channelNumber']) < 5 or not utils.is_number(args['channelNumber']) then
            only.log('E'," channel_number:%s is error", args['channelNumber'])
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
        end
    end

    if args['channelName'] and #args['channelName'] > 0 then
        local channel_name = args['channelName']
        if app_utils.str_count(channel_name) < 1 or app_utils.str_count(channel_name) > 16 or string.find(channel_name,"'")  then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelName')
        end
    end
    ---- 频道关键字
    if args['channelKeyWords'] then 
        if string.find(args['channelKeyWords'],"'") then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
        end

        if #args['channelKeyWords'] > 0 then
            local tab = utils.str_split(args['channelKeyWords'],",")
            if #tab > 5 then
                only.log('D',"channelKeyWords:%s",args['channelKeyWords'])
                gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
            end

            for k , v in pairs(tab) do
                ---- 1) 频道关键字,单个最大长度为8 2015-05-25 
                if app_utils.str_count( v ) > 8 then
                    only.log('D',"channelKeyWords111111:%s",v)
                    gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
                end
            end
        end

    end

    if args['status'] and #args['status'] > 0 then
        if not  tonumber(args['status']) or not(args['status'] == '0' or args['status'] == '2') then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'status')
        end
    end

    if args['startPage'] and #args['startPage'] > 0 then
        if not tonumber(args['startPage'])  or string.find(args['startPage'],"%.") or tonumber(args['startPage']) <= 0  then
            only.log('E','startPage is error')
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'startPage')
        end
    end

    if args['pageCount'] and #args['pageCount'] > 0 then
        if  not tonumber(args['pageCount'])  or string.find(args['pageCount'],"%.") or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'pageCount')
        end
    end
    -- safe.sign_check(args,url_tab)
    -- 20150720
    -- 为io部门使用
    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

local function check_accountID(accountid)
    local sql_str = string.format(G.sql_check_accountid,accountid)
    local ok,ret  = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"connect mysql failed %s ", sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',"cur accountid is not exit")
        gosay.go_false(url_tab,msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
    if #ret > 1 then
        only.log('E',"cur mysql error #ret > 1,%s ",sql_str)
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

---- 显示所有能加入的密频道
local function display_can_join_page( pageCount,startIndex,cityCode,catalogID,channelNumber,channelName,channelKeyWords , is_verify )

    ---- 20150708
    ---- 去掉自己不能查询自己频道的限制
    local str_filter = "  and  openType = 1 "
    if cityCode and #cityCode > 0 then 
        str_filter = str_filter .. string.format("  and  cityCode = %s  ", cityCode )
    end

    if channelNumber and #channelNumber > 0 then 
        str_filter = str_filter .. string.format("  and  (number like '%%%s%%' )", channelNumber)
    end

    if channelName and #channelName > 0 then 
        str_filter = str_filter .. string.format("  and  ( upper(name) like upper('%%%s%%') or  upper(cityName) like  upper('%%%s%%') or number like '%%%s%%'  )", channelName , channelName , channelName )
    end

    if catalogID and tonumber(catalogID) then
        str_filter = str_filter .. string.format("  and  catalogID = %s  ", catalogID )
    end
    if channelKeyWords and #channelKeyWords > 0 then
        str_filter = str_filter .. string.format(" and (upper(keyWords) like upper('%%%s%%') )",channelKeyWords)
    end

    if is_verify then
        str_filter = str_filter .. string.format(" and ( isVerify = %s ) ", is_verify )
    end

    
    str_filter = str_filter .. "   order by userCount desc  "

    local sql_str = string.format(G.sql_find_secretchannel_data, str_filter, startIndex, pageCount)
    local ok,tab = mysql_api.cmd(channel_dbname,'SELECT',sql_str)

    only.log('D', string.format('sql_find_secretchannel_data secretchannel data sql is %s' , sql_str))

    if not ok or type(tab) ~= "table" or not tab then
        only.log('E', 'show secretchannel data is %s' , sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    
    if #tab == 0  then
        return nil
    end
    return tab
end

---- 显示自己创建的群聊频道列表
local function display_owner_channelList(accountid ,startIndex, pageCount) 
    local str_filter = string.format(" and accountID = '%s'  ",accountid)
    local sql_str = string.format(G.sql_find_secretchannel_data, str_filter ,startIndex,pageCount)
    local ok, ret  = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E', string.format('display_owner_channelList failed is %s' , sql_str) )
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #ret == 0 then
        return nil
    end

    return ret
end

---- 显示自己所加入的群聊频道列表
local function display_user_join_channelList(accountid,startIndex,pageCount)
    local sql_str = string.format(G.sql_user_joined_list, accountid )
    local ok, channel_tab  = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not channel_tab then
        only.log('E', 'display_user_join_channelList failed is %s' , sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    local tmp_tab = {}
    for k , v  in  pairs(channel_tab) do
        table.insert(tmp_tab , v['number'])
    end

    local str_filter = string.format(" and number in ('%s') ",table.concat(tmp_tab,"','"))
    local sql_str = string.format(G.sql_find_secretchannel_data, str_filter ,startIndex, pageCount)
    local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E', string.format('display_user_join_channelList failed is %s' , sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        return nil
    end
    return ret
end

local function display_user_create_and_join_channelList(accountid, startIndex, pageCount ) 
    local sql_str = string.format(G.sql_user_create_and_joined_list, accountid )
    local ok, channel_tab  = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not channel_tab  or type(channel_tab) ~= "table" then
        only.log('E', 'sql_user_create_and_joined_list failed is %s' , sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #channel_tab < 1 then
        return nil
    end

    local tmp_tab = {}
    for k , v  in  pairs(channel_tab) do
        table.insert(tmp_tab , v['number'])
    end
    local str_filter = string.format(" and number in ('%s')   order by userCount desc   ",table.concat(tmp_tab,"','"))
    local sql_str = string.format(G.sql_find_secretchannel_data, str_filter ,startIndex, pageCount)
    local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E', '[****]display_user_create_and_join_channelList failed is %s' , sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        return nil
    end
    return ret
end


local function display_user_get_key_info( accountid )
    ---- 关联键
    local sql_str = string.format(G.sql_get_userkey_info, accountid )
    local  ok , ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E',"sql_get_userkey_info failed [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        return nil
    end
    return  ret
end 

local function display_user(accountid,status)
    local sql_str = string.format(G.sql_user_verify_message,accountid,status)
    local ok,ret = mysql_api.cmd(channel_dbname,'select',sql_str)
    only.log('D',"sql_user_verify_message, [%s]",sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E',"1 sql_user_verify_message failed [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('W',"2 sql_user_verify_message failed [%s]",sql_str)
        return nil
    end
    return ret
end

local function handle()

    local req_ip = ngx .var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()

    local req_method = ngx.var.request_method
    url_tab['client_host'] = req_ip
    if not req_body then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'])
    end
    url_tab['client_body'] = req_body

    local args = nil
    if req_method == 'POST' then
            args = ngx.decode_args(req_body)
    end

    if not args then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
    end

    if not args['appKey'] then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"appKey")
    end
    check_parameter(args)

    url_tab['app_key'] = args['appKey']
    local accountid = args['accountID']
    check_accountID(accountid)

    local infoType = tonumber(args['infoType'])
    local cityCode = args['cityCode']
    local catalogID = tonumber(args['catalogID'])
    local channelNumber =args['channelNumber']
    local channelName  = args['channelName']
    local channelKeyWords = args['channelKeyWords']
    local status = tonumber(args['status']) or 0

    local  is_verify = tonumber(args['isVerify'])

    local start_page = tonumber(args['startPage']) or 1
    local pageCount = tonumber(args['pageCount']) or 20
    local startIndex = (start_page-1) * pageCount
    if startIndex < 0 then
        startIndex = 0 
    end
    
    ---- infoType 
    -- 1 查询所有的可以加入的群聊频道 
    -- 2 管理员的到自己的群聊频道列表 
    -- 3 普通用户获取所加入的群聊频道列表
    -- 4 用户获取我创建的频道以及我加入的频道 ( 2 + 3 )
    local show_tab = nil
    local key_tab  = nil
    local user_key_list = "[]"
    if infoType == 1 then
        ---- 查询所有可以加入的群聊频道
        show_tab = display_can_join_page( pageCount, startIndex, cityCode , catalogID ,channelNumber, channelName,channelKeyWords , is_verify )
    elseif infoType == 2 then
        ---- 管理员查询自己的群聊频道列表
        show_tab = display_owner_channelList(accountid ,startIndex,pageCount)
    elseif infoType == 3 then
        ---- 显示自己所加入的群聊频道
        show_tab = display_user_join_channelList(accountid,startIndex,pageCount)
        key_tab  = display_user_get_key_info(accountid)
    elseif infoType == 4 then
        -- 4 用户获取我创建的频道以及我加入的频道 ( 2 + 3 )
        show_tab = display_user_create_and_join_channelList(accountid,startIndex,pageCount)
        key_tab  = display_user_get_key_info(accountid)
    end
    
    local count = 0
    local result = "[]"
    if show_tab and type(show_tab) == "table" and #show_tab > 0  then
        count = #show_tab
        local ok,tmp_tab = pcall(cjson.encode,show_tab)
        if ok and tmp_tab then
            result = tmp_tab
        end
    end

    if key_tab and type(key_tab) == "table" and #key_tab > 0 then
         local ok,tmp_tab = pcall(cjson.encode,key_tab)
        if ok and tmp_tab then
            user_key_list = tmp_tab
        end
    end

    local str = string.format('{"count":"%s","list":%s,"keyList":%s}',count,result,user_key_list)
    if str then
        ---- SUCCESS
        gosay.go_success(url_tab,msg['MSG_SUCCESS_WITH_RESULT'],str)
    else
        ---- FAILED
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

safe.main_call( handle )
