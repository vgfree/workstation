-- jiang z.s.
-- 2015-05-27
-- 群聊频道转移

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local appfun    = require('appfun')
local cjson     = require('cjson')
local sha       = require('sha1')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')



local channel_capacity = 15000

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"


local G = {

        sql_check_accountid   = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1  ",

        

        sql_check_join_capacity = " select count(1) as count from joinMemberList where  validity = 1 and  idx = '%s' and number = '%s'  " , 

        sql_check_join_channel = " SELECT  validity  from joinMemberList where accountID = '%s' and number = '%s' and idx = '%s'  ",

        sql_join_channel_first    = "insert into joinMemberList(idx , number, uniqueCode , accountID, createTime) "..
                                    " values( '%s', '%s', '%s', '%s', %d )",

        sql_join_channel_history =  "insert into joinMemberListHistory (idx, number, accountID,uniqueCode," .. 
                                        " updateTime,validity, talkStatus, role )  " ..
                                        " select idx, number, accountID,uniqueCode,updateTime,validity,talkStatus,role from  joinMemberList  " .. 
                                        " where accountID = '%s' and idx = '%s' and number = '%s' " ,

        sql_join_channel_second    = "update joinMemberList set validity = 1 , uniqueCode = '%s', updateTime = %d  where idx = '%s' and  number = '%s'  and accountID ='%s'  "    ,                          

        ---- 校验频道参数与邀请码
        sql_get_sercet_info = "SELECT idx,capacity,inviteUniqueCode,isVerify FROM checkSecretChannelInfo WHERE channelStatus = 1 and  number = '%s' limit 1 " ,

        sql_verify_channel  = "insert into userVerifyMsgInfo(accountid ,role , idx , number , status , uniqueCode, applyAccountID, applyNickname ,applyRemark , createTime)" .. 
                                " values('%s',1,'%s','%s',0,'%s',  '%s', '%s' , '%s', %s ) " , 


        sql_check_verify_channel = " select 1 from userVerifyMsgInfo where  status = 0  and  accountID = '%s' and idx = '%s' and number = '%s' and applyAccountID = '%s'  " , 


        sql_update_verify_channel = " update userVerifyMsgInfo set applyCount = applyCount + 1 , updateTime = %s , uniqueCode = '%s' , applyRemark = '%s'  where status = 0 and accountID = '%s' and idx = '%s' and number = '%s' and applyAccountID = '%s'  " ,  


        ------------- update info  

        sql_check_accountid_password   = "SELECT daokePassword password FROM userList WHERE accountID = '%s' limit 1  ",


        sql_check_channel_exist = "select idx from  checkSecretChannelInfo where channelStatus = 1 and accountID = '%s' and number = '%s'  " , 

        sql_check_receiver_is_join = "select  validity  from joinMemberList where accountID = '%s' and number = '%s'  " , 

        sql_update_secret_channel_info = " update checkSecretChannelInfo set  accountID = '%s' , updateTime = '%s' where accountID = '%s' and idx = '%s'  "  , 

        sql_update_receiver_accountid_role = " update joinMemberList set updateTime = '%s' , validity = 1  , role = 1  where accountID = '%s'  and  number = '%s'   ", 

        sql_insert_receiver_accountid_role =  " insert into joinMemberList(idx,number,accountID,uniqueCode,createTime,updateTime,validity,talkStatus,role , actionType)  " .. 
                                                    " values ( '%s', '%s', '%s' , '' , '%s', '%s', 1 , 1 , 1 , 0 ) " ,


        sql_update_manager_role = " update joinMemberList set updateTime = '%s' ,  role = 0 where accountID = '%s' and number = '%s'  " ,  

        sql_update_verify_msg  = " update userVerifyMsgInfo set accountID = '%s' where  status = 0 and  accountID = '%s' and  number  = '%s'   " ,  


        sql_update_user_count    = " update checkSecretChannelInfo set userCount = userCount + 1  where idx = '%s' and number = '%s' and userCount > 0  " ,

        ---- 检查当前用户申请频道数是否超过10个
        sql_accountID_apply_channel_is_full = "select count(1) as count from checkSecretChannelInfo where accountID = '%s' and channelStatus = 1",

        ---- 转移频道信息
        sql_inert_transferInfo = " insert into transferInfo(accountID,receiveAccountID,createTime,number) values('%s','%s' , %d , '%s') " ,

        ---- 存入userAdminInfo表中
        sql_insert_userAdminInfo = " update userAdminInfo set transfer = transfer + 1 , updateTime = unix_timestamp() where accountID = '%s' " ,

        ---- 判断接收频道者是否在当前频道
        sql_check_receiver_accountid = "select 1 from  joinMemberList where validity = 1 and number='%s' and accountID = '%s'  ",
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

    if not args['password'] or #args['password'] < 1 then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'password')
    end

    if not args['receiverAccountID'] or not app_utils.check_accountID(args['receiverAccountID']) then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'receiverAccountID')
    end

    if not args['channelNumber'] or #args['channelNumber'] < 5 or  #args['channelNumber'] > 50 or (string.find(args['channelNumber'],"'")) then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
    end

    if args['receiverAccountID'] == args['accountID'] then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'receiverAccountID')
    end

    -- safe.sign_check(args, url_tab )
    -- 20150720
    -- 为io部门使用
    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)

end

local function check_accountid(accountID, number)
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

    local sql_str = string.format(G.sql_check_receiver_accountid, number, accountID)
    local ok,ret = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)
    if not ok or not ret then
        only.log('E'," receiver accountid failed %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',"receiver accountID is not join in ,sql_str is %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_DID_NOT_JOINED'])
    end
end

local function check_accountid_password(accountid, password )
    local sql_str = string.format(G.sql_check_accountid_password,accountid)
    local ok,ret = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',"check_accountid failed %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',"cur accountid is not exit,sql_str is %s",sql_str)
        gosay.go_false(url_tab,msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end

    local hash_password = ngx.md5(sha.sha1(password) .. ngx.crc32_short(password))
    if ret[1]['password'] ~= hash_password then
        only.log('E',"cur accountid password is not match, accountid:%s, password:%s , database pwd:%s ", accountid , password , ret[1]['password'] )
        gosay.go_false(url_tab,msg['MSG_ERROR_PWD_NOT_MATCH'])
    end
    return true
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


local function transfer_secret_channel_info( accountid, channel_num , receiver_accountid )
    ---- 判断用户申请频道数是否超过10个
    ---- 2015-06-11
    ---- 如果是李晓天的账号，要跳过频道数限制
    if receiver_accountid ~= 'kxl1QuHKCD' then
        local sql_str = string.format(G.sql_accountID_apply_channel_is_full,receiver_accountid)
        local ok ,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
        if not ok or not ret or type(ret) ~= "table" then
            only.log('E',string.format("check user apply channel is full failed %s ", sql_str ))
            gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
        end
        if tonumber(ret[1]['count']) >= 10 then
            only.log('E',"cur channel is full [%s]",sql_str)
            gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_MAX_COUNT'])
        end
    end
    local sql_str = string.format(G.sql_check_channel_exist, accountid , channel_num )
    local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
     if not ok or not ret or type(ret) ~= "table" then
        only.log('E',string.format("get secret channel info failed %s ", sql_str ))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if #ret == 0  then
         only.log('D',string.format("get secret channel info succ, but result is empty, %s ", sql_str ))
         gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
    end

    local channel_idx = ret[1]["idx"]


    local sql_tab = {}

    local sql_str = string.format(G.sql_check_receiver_is_join, receiver_accountid , channel_num )
    local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E',string.format("joinMemberList failed %s ", sql_str ))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    local receiver_exist = false
    if #ret ~= 0 then
        receiver_exist = true
        if tonumber(ret[1]['validity']) == 0 then
            ---- 更新用户总人数
            local sql_str = string.format(G.sql_update_user_count, channel_idx , channel_num )
            table.insert(sql_tab , sql_str)
        end
    else
        ---- not exist 
        ---- 更新用户总人数
        local sql_str = string.format(G.sql_update_user_count, channel_idx , channel_num )
        table.insert(sql_tab , sql_str)
    end
    
    local cur_time = os.time()
    local sql_str = string.format(G.sql_update_secret_channel_info , receiver_accountid , cur_time , accountid , channel_idx )
    table.insert(sql_tab, sql_str)

    if receiver_exist then
        local sql_str = string.format(G.sql_update_receiver_accountid_role , cur_time , receiver_accountid , channel_num)
        table.insert(sql_tab, sql_str)
    else

        local sql_str = string.format(G.sql_insert_receiver_accountid_role , channel_idx , channel_num , receiver_accountid , cur_time, cur_time )
        table.insert(sql_tab, sql_str)
        ---- 20150618
        ---- 插入joinMemberListHistory
        local sql_str = string.format(G.sql_join_channel_history,receiver_accountid,channel_idx,channel_num)
        table.insert(sql_tab,sql_str)
        ---- end
    end

    local sql_str = string.format(G.sql_update_manager_role, cur_time ,  accountid, channel_num )
    table.insert(sql_tab, sql_str)

    local sql_str = string.format(G.sql_update_verify_msg, receiver_accountid , accountid ,channel_num  )
    table.insert(sql_tab, sql_str)

    ---- 2015-06-11
    ---- 转移频道信息 保存到transInfo表中
    local sql_str = string.format(G.sql_inert_transferInfo,accountid,receiver_accountid,cur_time,channel_num)
    table.insert(sql_tab , sql_str)
    ---- end

    ---- 20150616
    ---- 保存到userAdminInfo表中
    local sql_str = string.format(G.sql_insert_userAdminInfo,accountid)
    table.insert(sql_tab , sql_str)
    ---- end

    only.log('D',"debug mysql, %s ", table.concat( sql_tab, "\r\n") )

    local ok,sql_ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
    if not ok or not sql_ret then
        only.log('E',"mysql  failed, %s ", table.concat( sql_tab, "\r\n") )
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    ---- 20150618
    ---- 更新redis中的userChannelInfo owner
    redis_api.cmd('private','hmset',string.format("%s:userChannelInfo",channel_idx), 
                            "owner", receiver_accountid )
    ---- end
    return true    
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

    local args = ngx.decode_args(req_body)
    if not args then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
    end
    if not args['appKey'] then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"appKey")
    end

    url_tab['app_key'] = args['appKey']
    check_parameter(args)

    local accountid = args['accountID']
    local password = args['password']
    check_accountid_password(accountid, password )

    local receiver_accountid = args['receiverAccountID']
    local channel_num = args['channelNumber']
    check_accountid(receiver_accountid, channel_num)
    local ok = transfer_secret_channel_info( accountid, channel_num , receiver_accountid )
    if ok then
        gosay.go_success(url_tab,msg['MSG_SUCCESS'])
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

safe.main_call( handle )
