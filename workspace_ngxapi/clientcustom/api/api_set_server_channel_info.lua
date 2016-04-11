
----modify: wangjiayi
----remark: 设置服务频道信息(发送消息)
----date:   2015-06-12


local msg       = require('msg')
local safe      = require('safe')
local only      = require('only')
local gosay     = require('gosay')
local utils     = require('utils')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')

local url_tab = {
	type_name   = 'system',
	app_key     = nil,
	client_host = nil,
	client_body = nil
}


local userlist_dbname = 'app_usercenter___usercenter'
local channel_dbname  = "app_custom___wemecustom"


local G = {
	
	sel_user_serverID = " SELECT 1 from userCustomDefineInfo where accountID='%s' and customType=%s ",
												 
	ins_user_serverID = " INSERT serviceChannelContentInfo (serverID, accountID, receiveAccountID, contentType, content, createTime, msgid) values(%s, '%s', '%s', %s, '%s', %s, '%s') ",
	--用于生成唯一消息id的检测
	sql_check_uniq_msgid =  " select 1 from serviceChannelContentInfo where msgid = '%s' limit 1 ",
	--检查接受者道客账号是否存在
	sql_check_account_id =  " select 1 from userList where accountID = '%s'  limit 2",
}



--消息内容类型输入输出为字符串,存储时为数字
local MSG_MAP_TABLE = {
	['text']  = 1,	--文本消息
	['image'] = 2,	--图片消息
	['voice'] = 3,	--音频消息
	['video'] = 4,	--视频消息
	['news']  = 5,	--图文消息
}


local function check_parameter(args)

	safe.sign_check(args, url_tab)

	-- if not args['serverID'] or string.len(args['serverID']) ==0 or string.len(args['serverID'])>10 then
	if not args['serverID'] or string.find(args['serverID'], '%.') then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'serverID')
	end
	local server_id = tonumber(args['serverID'])
	if not server_id or server_id < 10 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'serverID')
	end

	if not args['accountID'] or string.len(args['accountID']) ==0 or string.len(args['accountID'])>10 or string.find(args['accountID'],"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	local receiveAccountID = args['receiveAccountID']
    if not receiveAccountID then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'receiveAccountID')
    end
    if receiveAccountID and receiveAccountID ~= ''  then
        if not app_utils.check_accountID(receiveAccountID) then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'receiveAccountID')
        end
    end


	-- if not args['content'] or string.len(args['content'])>512 or string.find(args['content'],"'" ) then
	if not args['content'] or app_utils.str_count(args['content'])>512 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'content')
	end

	-- if not args['contentType'] or string.find(args['contentType'], "%.") then
	-- 	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'contentType')
	-- end

	local exist_flag = MSG_MAP_TABLE[args['contentType']]
	if not args['contentType'] or not exist_flag then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'contentType')
	end


	-- local contentType = tonumber(args['contentType']) or 0
	-- if contentType~=1 and contentType~=2 and contentType~=3 then
	--暂定支持10种消息格式,格式内容具体不限定(2015/06/13)

	-- again 
	-- if contentType < 1 or contentType > 10 then
	-- 	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'contentType')
	-- end

	-- 格式内容具体不限定(2015/06/13)
	-- local tmp_content=args['content']
	-- local err_status=false
	-- if contentType==3 then
	-- 	if (string.find(tmp_content,"http://")) == 1 then
	-- 		local suffix = string.sub(tmp_content,-5)
	-- 		if suffix then
	-- 			if  ( (string.find(suffix,"%.png")) or (string.find(suffix,"%.jpg")) or 
	-- 				(string.find(suffix,"%.jpeg"))  or (string.find(suffix,"%.gif")) or 
	-- 				(string.find(suffix,"%.bmp"))  or (string.find(suffix,"%.ico")) ) then
	-- 				err_status = true
	-- 			end
	-- 		end
	-- 	end
	-- elseif contentType==2 then
	-- 	if (string.find(tmp_content,"http://")) == 1 then
	-- 		local suffix = string.sub(tmp_content,-5)
	-- 		if suffix then
	-- 			if  ( (string.find(suffix,"%.mp3")) or (string.find(suffix,"%.amr")) or (string.find(suffix,"%.wav"))) then
	-- 				err_status = true
	-- 			end
	-- 		end
	-- 	end
	-- elseif contentType==1 then
	-- 	err_status = true
	-- end
	-- if not err_status then
	-- 	only.log('E',string.format(" content is error, %s " , tmp_content ))
	-- 	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'content')
	-- end


	--added by liuyongheng (2015/06/13)
	--app需求:内容跳转链接
	-- if not args['url'] then
	-- 	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'url')
	-- end

end


local function gen_uniq_msgid()

    local msgid = nil

    while true do

        msgid = utils.create_uuid()
        sql_str = string.format(G.sql_check_uniq_msgid, msgid)

        local ok_status, result = mysql_pool_api.cmd(channel_dbname, 'select', sql_str)
        if ok_status and #result == 0 then
            break
        end
    end
    return msgid
end

local function get_msg_number_type( content_type )

	local number_type = MSG_MAP_TABLE[content_type]
	return number_type

end


local function fun_set_serviceChannelContentInfo( args, content)

	local cur_time = os.time()
	local sql = string.format(G.sel_user_serverID, args['accountID'], args['serverID'])

	local ok,ret = mysql_api.cmd(channel_dbname, 'select', sql)
	if not ok or not ret or type(ret) ~= 'table' then
		only.log("E",string.format("the sql select error : [[%s]]",sql))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret==0 then
		gosay.go_false(url_tab,msg['MSG_ERROR_CURRENT_USER_NOT_EXIT_SERVERID'])
	end

	local msgid = gen_uniq_msgid()
	local number_type = get_msg_number_type(args['contentType'])

	only.log('D', string.format("--------------------[msgid=%s]----------------------", msgid))
	local sql = string.format(G.ins_user_serverID, args['serverID'], args['accountID'], args['receiveAccountID'], number_type, content, cur_time, msgid)

	local ok,ret = mysql_api.cmd(channel_dbname, 'insert', sql)
	if not ok then
		only.log("E",string.format("the sql insert error : [[%s]]", sql))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

end

local function modify_content( content )
	
	--替换单引号为空
	content = string.gsub(content, "%'", '')

	--替换其他特殊符号待添加
	--

	return content

end


local function check_account_id( receive_account_id )
	
    local sql_str = string.format(G.sql_check_account_id, receive_account_id)
    local ok_status,user_tab = mysql_api.cmd(userlist_dbname, 'SELECT', sql_str)
    if not ok_status or not user_tab or type(user_tab) ~= 'table'  then
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        only.log('W',"cur accountID is not exit [%s]", receive_account_id)
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], ' receiveAccountID ')
    end

    if #user_tab >1 then 
        -----数据库存在错误,
        only.log('E','[***] userList accountID recordset > 1 ')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end

end

function handle()

	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	local req_head = ngx.req.raw_header()

	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_tab['client_host'] = req_ip
	url_tab['client_body'] = req_body

	local req_method = ngx.var.request_method
	local args = nil
	if req_method == 'POST' then
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')
      	if not boundary then
			args = utils.parse_url(req_body)
			-- args = ngx.decode_args(req_body)
		else
			args = utils.parse_form_data(req_head, req_body)
		end
	end

	if not args or type(args) ~= "table" then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG']," args ")
	end


	url_tab['app_key'] = args['appKey']
	check_parameter(args)

	if args['receiveAccountID'] and args['receiveAccountID'] ~= '' then
		check_account_id(args['receiveAccountID'])
	end

	--修饰消息内容
	local content = modify_content(args['content'])

	fun_set_serviceChannelContentInfo(args, content)
	gosay.go_success(url_tab, msg['MSG_SUCCESS'])

end

safe.main_call( handle )