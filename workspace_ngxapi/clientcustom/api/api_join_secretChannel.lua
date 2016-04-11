-- author:zhangerna
-- 用户申请加入群聊频道 

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local appfun    = require('appfun')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')
local cjson     = require('cjson')


local channel_capacity = 1500000
local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"


local G = {
        sql_check_accountid   = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1",

        sql_check_join_capacity = " select count(1) as count from joinMemberList where  validity = 1 and  idx = '%s' and number = '%s'  " , 

        sql_check_join_channel = " SELECT  validity  from joinMemberList where accountID = '%s' and number = '%s' and idx = '%s'  ",

        sql_join_channel_first    = "insert into joinMemberList(idx , number, uniqueCode , accountID, createTime) "..
                                    " values( '%s', '%s', '%s', '%s', %d )",

        sql_update_user_count     =  " update checkSecretChannelInfo set userCount = userCount + 1 where  idx = '%s' and  number = '%s'  " ,

        sql_join_channel_history =  "insert into joinMemberListHistory (idx, number, accountID,uniqueCode," .. 
                                        " updateTime,validity, talkStatus, role )  " ..
                                        " select idx, number, accountID,uniqueCode,updateTime,validity,talkStatus,role from  joinMemberList  " .. 
                                        " where accountID = '%s' and idx = '%s' and number = '%s' " ,

        sql_join_channel_second    = "update joinMemberList set validity = 1 , uniqueCode = '%s', updateTime = %d  where idx = '%s' and  number = '%s'  and accountID ='%s'  "    ,                          

        ---- 校验频道参数与邀请码
        sql_get_sercet_info = "SELECT idx,capacity,inviteUniqueCode,isVerify, accountID FROM checkSecretChannelInfo WHERE channelStatus = 1 and  number = '%s' limit 1 " ,

        sql_verify_channel  = "insert into userVerifyMsgInfo(accountid ,role , idx , number , status , uniqueCode, applyAccountID, applyNickname ,applyRemark , createTime)" .. 
                                " values('%s',1,'%s','%s',0,'%s',  '%s', '%s' , '%s', %s ) " , 


        sql_check_verify_channel = " select id as idx , status  from userVerifyMsgInfo where  status = 0  and  accountID = '%s' and idx = '%s' and number = '%s' and applyAccountID = '%s'  " , 


        sql_update_verify_channel = " update userVerifyMsgInfo set applyCount = applyCount + 1 , isNeedBindKey = 0  , updateTime = %s , uniqueCode = '%s' , applyRemark = '%s'  where status = 0 and accountID = '%s' and idx = '%s' and number = '%s' and applyAccountID = '%s'  " ,  

        sql_get_verify_idx = " select id as idx from userVerifyMsgInfo where status = 0 and accountID = '%s' and idx = '%s' and number = '%s' and applyAccountID = '%s' " ,

        sql_update_join_member_list = " update joinMemberList set validity = 1 ,updateTime = %d ,actionType = 0 where validity = 0 and accountID = '%s' and number = '%s' and idx = '%s'  "  ,

}

local url_tab = {
    type_name = 'system',
    app_key = '',
    client_host = '',
    client_body = '',
}


local function check_parameter(args)
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
    end

    ---- 1 加入频道邀请码
    if not args['uniqueCode'] or #tostring(args['uniqueCode']) < 32 
            or #tostring(args['uniqueCode']) > 64 
            or (string.find(args['uniqueCode'],"'")) 
            or string.find(args['uniqueCode'],"%.") 
            or not (string.find(args['uniqueCode'],"|") ) then
        only.log('E',string.format("cur user uniqueCode is not exit,uniqueCode is %s",args['uniqueCode']))
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'uniqueCode')
    end

    ---- 加入频道备注信息
    if args['remark'] and #args['remark'] > 0 then
        if string.find(args['remark'],"'") then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'remark')
        end
        if app_utils.str_count(args['remark']) > 128 then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'remark')
        end
    end

    -- safe.sign_check(args, url_tab )
    -- 20150720
    -- 为io部门使用
    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)  
end

local function check_accountid(accountID)
    local sql_str = string.format(G.sql_check_accountid,accountID)
    local ok,ret = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"check_accountid failed %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',"cur accountID is not exit,sql_str is %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
end

---- 获取用户当前的状态
local function get_secret_channelidx( accountid, channelnum )
    local ok, ret = redis_api.cmd('private','get', channelnum .. ":channelID")
    if not ok then
        only.log('E',string.format(" accountid %s  channelnum %s get channelID failed", accountid, channelnum))
        gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
    end
    if not ret then
        only.log('E',string.format(" accountid %s  channelnum %s get channelID failed", accountid, channelnum))
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"channelNumber")
    end
    return ret
end


local function join_secret_channel(accountid, uniquecode, channel_remark , channel_idx ,channel_num, is_verify)

    --判断用户是否已经加入
    local sql_str = string.format(G.sql_check_join_channel, accountid , channel_num, channel_idx )
    local ok,sql_ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not sql_ret then
        only.log('E',"mysql  failed, %s ",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end


    only.log('D'," check join channel : %s ", sql_str )

    local is_joined = 0
    if #sql_ret == 1 and sql_ret[1]['validity']  == "1" then
        is_joined = 1
        only.log('E'," accountid %s rejoin  %s", accountid ,  channel_idx) 
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_ALREADY_JOINED'])
    end
    
    ---- 2015-01-29 
    ---- 判断是否为管理员或创建者,如果是,跳过最大人数的限制 
    local ok , is_admin = redis_api.cmd('private','hget',channel_idx .. ":userChannelInfo","owner")
    if not ok or not is_admin or #is_admin < 10 then
        only.log('E',"redis check_is_admin failed,channel_idx %s",channel_idx)
        gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
    end

    if is_admin == accountid then
        only.log('W',string.format(" accountid %s channel_idx %s  join yourself secret channel  ", accountid, channel_idx))
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_JOIN_SELF'])
    end


    ---- 非管理员加入判断是否已经达到人数上线
    local sql_str = string.format(G.sql_check_join_capacity, channel_idx, channel_num )
    local ok, ret = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
    if not ok or not ret or type(ret) ~= 'table' then
        only.log('E'," sql_check_join_capacity mysql failed  %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    ---- 数据导入临时取消 2015-05-27 
    local cur_channel_count = ret[1]['count']
    if (tonumber(cur_channel_count) or 0) >= channel_capacity then
        ---- 用户已经达到上线
        only.log('W',string.format(" accountid %s channel_idx %s count %s  max %s ", accountid, channel_idx, cur_channel_count , channel_capacity ))
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_LIST_MAX_COUNT'])
    end

    local cur_time = os.time()
    local sql_tab = {}
    local sql_str = nil
    if tonumber(is_verify) == 0 then
        ---- 不需要验证
        if is_joined == 0 then
            ---- 20150725
            ---- bug修复
            ---- 忽略了validity的判断
            if #sql_ret == 1 and sql_ret[1]['validity'] == '0' then
                sql_str = string.format(G.sql_update_join_member_list,cur_time ,accountid , channel_num , channel_idx)
            else
                sql_str = string.format(G.sql_join_channel_first,channel_idx,channel_num,uniquecode,accountid,cur_time)
            end
            ---- end
            table.insert(sql_tab,sql_str)
        else
            sql_str = string.format(G.sql_join_channel_second , uniquecode , cur_time, channel_idx,channel_num,accountid)
            table.insert(sql_tab,sql_str)
        end
        ---- 20150616
        ---- 增加查入joinMemberListHistory的操作
        sql_str = string.format(G.sql_join_channel_history, accountid , channel_idx,channel_num)
        table.insert(sql_tab,sql_str)
        ---- end

        ---- 更新用户总人数 
        local sql_str = string.format(G.sql_update_user_count , channel_idx, channel_num)
        table.insert(sql_tab,sql_str)

    else

        ---- 2015-08-27 
        ---- 检查是否有未通过的消息,存在则更新申请次数,不存在则新增记录
        local sql_str = string.format(G.sql_check_verify_channel, is_admin , channel_idx , channel_num , accountid )
        local ok, ret = mysql_api.cmd(channel_dbname ,"SELECT" , sql_str)
        if not ok or not ret or type(ret) ~= "table" then
            only.log('E'," 1 sql_check_verify_channel mysql failed  %s",sql_str)
            gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
        end

        if #ret == 1 then
            local apply_idx = ret[1]['idx']
            ---- 需验证加入 如果verifyMsg表中有当前的accountID
            local sql_str = string.format(G.sql_update_verify_channel, cur_time , uniquecode , channel_remark, is_admin , channel_idx , channel_num , accountid )
            local ok , ret = mysql_api.cmd(channel_dbname ,"UPDATE" , sql_str)
            if not ok or not ret then
                only.log('E'," 2 sql_update_verify_channel mysql failed  %s",sql_str)
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
            end
            only.log('D'," current is rejoin add message  %s" ,sql_str  )
            return true,apply_idx
        elseif #ret > 1 then
            only.log('E',"[**SYSTEM_ERROR**]current is join message  is error " ,sql_str  )
            gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
        end

        local ok, nickname = redis_api.cmd('private','get', accountid .. ":nickname")
        if not ok then
            only.log('E',"redis get %s:nickname  failed,channel_idx %s",accountid)
            gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
        end

        ---- 需要验证  重新插入一条记录 sql_verify_channel 
        sql_str = string.format(G.sql_verify_channel ,is_admin ,channel_idx, channel_num , uniquecode , accountid, nickname or '', channel_remark , cur_time)
        table.insert(sql_tab,sql_str)
    end

    only.log('D',"debug mysql, %s ", table.concat( sql_tab, "\r\n") )

    local ok,sql_ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
    if not ok or not sql_ret then
        only.log('E',"exec mysql  failed, %s ", table.concat( sql_tab, "\r\n") )
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if tonumber(is_verify) == 0 then
         only.log('D',"succ current channel is not need verify, %s", accountid ,   channel_num )
        return true,nil
    end

    local sql_str  = string.format( G.sql_get_verify_idx , is_admin , channel_idx , channel_num , accountid )
    local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"3 sql_get_verify_idx mysql  failed, %s ", sql_str )
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #ret ~= 1 then
        only.log('E',"4 sql_get_verify_idx mysql  succed but resut is empty , %s ", sql_str )
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    return true,ret[1]['idx']
end

---- 获取密频道详细信息
---- 频道idx
---- 频道类型(密频道,微频道)
---- 频道状态(正常,关闭)
---- 频道最大人数为1500000人
local function get_secret_channel_info(accountid, channelnum, uniquecode)
    local sql_str  = string.format(G.sql_get_sercet_info, channelnum )
    local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',string.format("get_secret_channel_info failed %s ", sql_str ))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret ~= 1 then
        only.log('E',string.format("%s, channelnum is error, sql_str is %s ", uniquecode , sql_str))
        return nil
    end
    if ret[1]['inviteUniqueCode'] ~= uniquecode then
        return nil
    end
    return ret[1]['idx'], (tonumber(ret[1]['isVerify']) or 0) , ret[1]['accountID']
end


local function handle()

    local req_ip = ngx .var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local req_method = ngx.var.request_method

    url_tab['client_host'] = req_ip
    if not req_body then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"body")
    end
    url_tab['client_body'] = req_body

    local args = nil
    if req_method == 'POST' then
        local boundary = string.match(req_head,'boundary=(..-)\r\n')
        if not boundary then
            args = ngx.decode_args(req_body)
        else
            args = utils.parse_form_data(req_head,req_body)
        end
    end
  
    if not args then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
    end
    if not args['appKey'] then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"appKey")
    end

    url_tab['app_key'] = args['appKey']
    check_parameter(args)

    local accountid = args['accountID']
    check_accountid(accountid)

    local uniquecode = args['uniqueCode']

    local channel_remark = args['remark'] or ""

    channel_remark = string.gsub(channel_remark,'"',"")

    local tmp_info = utils.str_split(uniquecode,"|")
    if not tmp_info or #tmp_info ~= 2 then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"uniqueCode")
    end

    local channel_num = tmp_info[1]
    ---- 判断频道是否存在
    local channel_idx, is_verify , manager = get_secret_channel_info(accountid, channel_num, uniquecode)
    if not channel_idx  then
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_UNIQUECODE'])
    end

    ---- 加入群聊频道
    local ok , apply_idx   = join_secret_channel( accountid,uniquecode, channel_remark , channel_idx ,channel_num, is_verify)

    local str = string.format('{"isVerify":"%d","channelNumber":"%s","applyIdx":"%s","manager":"%s","applyRemark":"%s"}',is_verify, channel_num, tonumber(apply_idx) or -1, manager, channel_remark )
    if ok then
        gosay.go_success(url_tab,msg['MSG_SUCCESS_WITH_RESULT'],str)
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

safe.main_call( handle )
 