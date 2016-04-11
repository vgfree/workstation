
----modify: Liuyongheng
----remark: 获取服务频道内容
----date:   2015-06-12

local ngx       = require('ngx')
local msg       = require('msg')
local safe      = require('safe')
local only      = require('only')
local cjson     = require('cjson')
local utils     = require('utils')
local gosay     = require('gosay')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')

local userlist_dbname = 'app_usercenter___usercenter'
local channel_dbname  = "app_custom___wemecustom"

local G = {
    sql_check_accountid         = " select 1 from userList where accountID='%s' ",
    sql_get_servcie_content     =" select msgid, serverID, case when contentType = 1 then 'text'  " ..
                                                                         "   when contentType = 2 then 'image' " ..
                                                                         "   when contentType = 3 then 'voice' " ..
                                                                         "   when contentType = 4 then 'video' " ..
                                                                         "   when contentType = 5 then 'news'  " ..
                                                                         "   end as msgtype, " ..
                                        " content, createTime, accountID, receiveAccountID " ..
                                        -- " from serviceChannelContentInfo where accountID = '%s' and serverID = %s and  validity = 1 %s limit %d,%d ",
                                        --1.不需要发送者accountID便能唯一确认服务频道,删去accountID
                                        --2.此为接受者收取频道消息,accountID为参数名,实际上是对应数据库表中receiveAccountID字段
                                        " from serviceChannelContentInfo where serverID = %s and  validity = 1 and receiveAccountID in ('', '%s')  limit %d,%d ",
	--设置了按键且关注才能获取待添加
}

local url_info = {
	type_name   = 'system',
	app_key     = nil,
	client_host = nil,
	client_body = nil,
}

--消息内容类型输入输出为字符串,存储时为数字
--替换为case when (2015/06/14)
-- local MSG_MAP_TABLE = {
--     [1] = 'text',   --文本消息
--     [2] = 'image',  --图片消息
--     [3] = 'voice',  --音频消息
--     [4] = 'video',  --视频消息
--     [5] = 'news',   --图文消息
-- }

local function check_parameter(args)


    local accountID = args['accountID']
    --不能不传
    if not accountID then 
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
    if accountID and accountID ~= ''  then
        if not app_utils.check_accountID(accountID) then
            gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'accountID')
        end
    end

    if not args['serviceID'] or string.find(args['serviceID'],"%.")  then
    	gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'serviceID')
    end
    local serviceID = tonumber(args['serviceID'])
    if not serviceID or serviceID < 10 then
    	gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'serviceID')
    end

	if args['startPage'] then 
		if not tonumber(args['startPage']) or string.find(tonumber(args['startPage']),"%.") or tonumber(args['startPage']) <= 0 then
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'startPage')
		end
	end

	if args['pageCount'] then
		if not tonumber(args['pageCount']) or string.find(tonumber(args['pageCount']),"%.")  or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'pageCount')
		end
	end

    safe.sign_check(args, url_info)

end


---- 对accountID进行数据库校验
local function check_userinfo(account_id)
    local sql_str = string.format(G.sql_check_accountid, account_id)
    local ok_status,user_tab = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)
    if not ok_status or not user_tab or type(user_tab) ~= 'table' then
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #user_tab == 0 then
        only.log('W',"cur accountID is not exit [%s]", account_id)
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'AccountID ')
    end
end


local function get_servcie_content( args, start_index, page_count)
    local account_id = args['accountID']
    local service_id = args['serviceID']
    local count      = args['count']
    local sql_str = string.format(G.sql_get_servcie_content, service_id, account_id, start_index, page_count)
    local ok_status, tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)
    if not ok_status or not tab or type(tab) ~= 'table' then
        only.log('E','connect channel_dbname failed!')
        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
    end
    if #tab == 0 then
        return nil
    end
    return tab

end


local function assemble_content_tab( content_tab )
    local count = #content_tab
    local messages = {}
    for i=1,count do 
        local msgtype = content_tab[i]['msgtype']
        messages[i] = {}
        messages[i]['msgid'] = content_tab[i]['msgid']
        messages[i]['touser'] = content_tab[i]['receiveAccountID']
        messages[i]['fromuser'] = content_tab[i]['accountID']
        messages[i]['channel'] = content_tab[i]['serverID']
        messages[i]['createtime'] = content_tab[i]['createTime']
        messages[i]['msgtype'] = msgtype
        --解析json字符串为lua table
        local ok_status, ok_tab = pcall(cjson.decode, content_tab[i]['content'])
        if not ok_status or not ok_tab then
            only.log('E','cjson encode failed!')
            gosay.go_false(url_info, msg['SYSTEM_ERROR'])
            return false
        end
        messages[i][msgtype] = ok_tab
    end
    return messages
end



local function handle()

    url_info['client_host'] = ngx.var.remote_addr
    local req_body = ngx.req.get_body_data()
    if not req_body then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_info['client_body'] = req_body

    local args = utils.parse_url(req_body)

    if not args then
        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],"args")
    end

	url_info['app_key'] = args['appKey']
    check_parameter(args)

	local start_page = tonumber(args['startPage']) or 1
	local page_count = tonumber(args['pageCount']) or 20
	if start_page < 1 then
		start_page = 1 
	end
	local start_index = ( start_page - 1 ) * page_count

    local accountID = args['accountID']
    --检查接受者的账号ID
    check_userinfo(accountID)
	
    local content_tab = get_servcie_content(args, start_index, page_count)
    local count = 0
    local ret = "[]"
    if content_tab and type(content_tab) == "table" and #content_tab > 0 then
        count = #content_tab
        local modified_content_tab = assemble_content_tab(content_tab)
        local ok_status, ok_str = pcall(cjson.encode, modified_content_tab)
        if not ok_status or not ok_str then
            only.log('E','cjson encode failed!')
            gosay.go_false(url_info, msg['SYSTEM_ERROR'])
            return false
        end
        ret = ok_str
    end
    local return_str = string.format('{"count":"%s","list":%s}', count, ret)
    gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], return_str)

end

safe.main_call( handle )

