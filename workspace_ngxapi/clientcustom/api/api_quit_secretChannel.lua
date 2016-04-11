-- author:zhangerna
-- 用户退出群聊频道

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


local channel_capacity = 2000
local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"


local G = {
        -- 检查accountID
        -- 获取名为1的列的内容(从accountID=给定值 的频道成员列表中取一个值)
        sql_check_accountid   = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1",

        -- 检查加入的频道
        -- 获取validity 关注状态, talkStatus 用户状态 列(从满足条件的joinMemberList表中)
        sql_check_join_channel = " SELECT  validity, talkStatus  from joinMemberList where accountID = '%s' and number = '%s' and idx = '%s'  ",

        ---- 校验频道参数
        -- 获取编号
        sql_get_sercet_info = "SELECT  idx  FROM checkSecretChannelInfo WHERE channelStatus = 1 and  number = '%s'  limit 1 " , 

        -- 检查加入的密频道
        -- 获取关注状态 按键类型 身份
        sql_check_join_secret_channel = " select validity, actionType, role from joinMemberList where accountID = '%s' and idx = '%s' and number = '%s'  " , 

        -- 退出密频道
        -- UPDATE 表名称 SET 列名称 = 新值 WHERE 列名称 = 某值
        sql_quit_secret_channel = " update joinMemberList set validity = 0 ,updateTime = %s  where validity = 1 and  accountID = '%s' and idx = '%s' and number = '%s'   " , 

        -- 更新用户数
        sql_update_user_count    = " update checkSecretChannelInfo set userCount = userCount - 1  where idx = '%s' and number = '%s' and userCount > 0  " ,

        -- 退出密频道历史
        -- 当目标数据库中要插入数据的表已经存在时  
        sql_quit_secret_channel_history =  "insert into joinMemberListHistory (idx, number, accountID,uniqueCode," .. 
        " updateTime,validity, talkStatus , role )  " ..
        " select idx, number, accountID,uniqueCode,updateTime,validity,talkStatus,role from  joinMemberList  " .. 
        " where accountID = '%s' and idx = '%s' and number = '%s' " ,

}

-- url
-- 协议
-- 存有该资源的主机IP地址
-- 主机资源的具体地址(目录、文件名等)
--
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

        ---- 用户退出群聊频道
        if not args['channelNumber'] or not tonumber(args['channelNumber']) or  #args['channelNumber'] < 5 or  #args['channelNumber'] > 50 then
                gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
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


---- 获取密频道详细信息
local function get_secret_channel_info(accountid, channelnum)
        local sql_str  = string.format(G.sql_get_sercet_info, channelnum )
        local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
        if not ok or not ret then
                only.log('E',string.format("get_secret_channel_info failed %s ", sql_str ))
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
        end
        if #ret ~= 1 then
                return false
        end
        return ret[1]['idx']
end


local function quit_secret_channel( accountid , channel_idx ,channel_num )
        local sql_str = string.format(G.sql_check_join_secret_channel , accountid , channel_idx , channel_num   )
        local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
        if not ok or not ret then
                only.log('E',string.format("quit_secret_channel sql check join secret channel  failed %s ", sql_str ))
                gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
        end

        if #ret ~= 1 then
                only.log('W',string.format("user did not join this channel %s ", sql_str ))
                gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_DID_NOT_JOINED'])
        end

        if ret[1]['validity'] == "0" then
                only.log('W',string.format("user already quit this channel %s ", sql_str ))
                gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_DID_NOT_JOINED'])
        end

        if ret[1]['actionType'] ~= "0" then
                only.log('W',string.format("user already bind weme key with this channel %s ", sql_str ))
                gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IS_BINDED'])
        end

        if ret[1]['role'] == "1" then
                only.log('W',string.format("current is creater , deny quit  %s ", sql_str ))
                gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_QUIT_SELF'])
        end


        local cur_time = os.time()
        local sql_tab = {}

        local sql_str = string.format(G.sql_quit_secret_channel , cur_time, accountid , channel_idx , channel_num )
        table.insert(sql_tab , sql_str)

        local sql_str = string.format(G.sql_quit_secret_channel_history , accountid, channel_idx , channel_num  )
        table.insert(sql_tab , sql_str)

        ---- 更新用户总人数
        local sql_str = string.format(G.sql_update_user_count, channel_idx , channel_num )
        table.insert(sql_tab , sql_str)


        local ok,sql_ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
        only.log('E',"sql: %s ", table.concat( sql_tab, "\r\n") )
        if not ok or not sql_ret then
                only.log('E',"mysql  failed, %s ", table.concat( sql_tab, "\r\n") )
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
        end

        return true

end


local function handle()

        local req_ip = ngx.var.remote_addr
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

        local channel_num = args['channelNumber']

        ---- 判断频道是否存在
        local channel_idx = get_secret_channel_info(accountid, channel_num )
        if not channel_idx  then
                ---- 当前频道编码错误
                gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
        end

        ---- 用户退出群聊频道
        local ok = quit_secret_channel( accountid, channel_idx ,channel_num )
        if ok then
                gosay.go_success(url_tab,msg['MSG_SUCCESS'])
        else
                gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
        end
end

safe.main_call( handle )
