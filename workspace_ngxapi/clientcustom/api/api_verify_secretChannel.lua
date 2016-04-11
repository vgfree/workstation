---- auth: zhangerna 
---- 管理员接收/拒绝用户加入群聊频道

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
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')


local channel_dbname = "app_custom___wemecustom"
local userlist_dbname = "app_usercenter___usercenter"
local G = {

	sql_check_accountid   = " SELECT 1 FROM userList WHERE accountID = '%s'   " , 

	---- modify 2015-08-05 增加
	sql_check_message      = " select  number, idx, status, uniqueCode, applyAccountID from userVerifyMsgInfo where validity = 1 and  accountID = '%s' and id = %s " ,

	sql_operate_user_join = "update userVerifyMsgInfo set status = %s , updateTime = %s , checkRemark = '%s' where validity = 1  and status = 0  and id = %s  and accountID = '%s'   " ,

	sql_update_user_joined = " update joinMemberList set  validity = 1 , updateTime = %s , uniqueCode  = '%s' , talkStatus = 1  where accountID = '%s' and number = '%s' and idx = '%s'  " ,

	sql_insert_user_join = " insert joinMemberList ( idx, number, accountID, uniqueCode, createTime, validity, talkStatus, role ) " ..
									" values ( '%s', '%s', '%s', '%s', %s , 1, 1 , 0 ) "  ,

	sql_check_user_is_joined = " select validity, talkStatus from joinMemberList where accountID = '%s' and number = '%s' and idx = '%s'  ", 

	sql_join_channel_history =  "insert into joinMemberListHistory (idx, number, accountID,uniqueCode," .. 
                                        " updateTime,validity, talkStatus, role )  " ..
                                        " select idx, number, accountID,uniqueCode,updateTime,validity,talkStatus,role from  joinMemberList  " .. 
                                        " where accountID = '%s' and idx = '%s' and number = '%s' " ,

	sql_update_user_count    = " update checkSecretChannelInfo set userCount = userCount + 1  where idx = '%s' and number = '%s' and userCount > 0  " ,

}

local url_tab = {
    type_name = 'system',
    app_key = '',
    client_host = '',
    client_body = '',
}


local  STATUS_ALLOW   = "1"
local  STATUS_REJECT  = "2"

local  function check_parameter( args )
	
	---- 校验管理员的账号
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	---- 校验用户的账号
	if not app_utils.check_accountID(args['applyAccountID']) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'applyAccountID')
	end

	if args['checkRemark'] then
		if string.find(args['checkRemark'],"'") or app_utils.str_count(args['checkRemark']) > 64 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelRemark')
		end
	end
	----  1成功  2拒绝
	if not args['checkStatus'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
	end

	if not ( args['checkStatus'] == STATUS_REJECT or args['checkStatus'] == STATUS_ALLOW ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
	end

	if not args['applyIdx'] or not utils.is_number(args['applyIdx']) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
	end
	-- safe.sign_check(args, url_tab )
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end


local function verify_secretChannel(accountid , apply_accountid , check_remark,  apply_idx , check_status)

	local sql_str = string.format(G.sql_check_message, accountid, apply_idx)
	local ok ,tab = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not tab then
		only.log('E','connect userlist_dbname failed!  %s ', sql_str )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #tab ~= 1 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
	end

	if tab[1]['status'] ~= "0" then
		---- 当前消息已经处理 
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_MSG_DEAL'])
	end

	if apply_accountid ~= tab[1]['applyAccountID'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyAccountID')
	end

	local channel_idx = tab[1]['idx']
	local unique_code = tab[1]['uniqueCode']
	local channel_number = tab[1]['number']

	local cur_time = ngx.time()

	local sql_tab = {}
	local sql_str = string.format(G.sql_operate_user_join, check_status , cur_time , check_remark , apply_idx ,  accountid  )
	table.insert(sql_tab,sql_str)
	if check_status == STATUS_ALLOW then

		local sql_str = string.format(G.sql_check_user_is_joined , apply_accountid , channel_number, channel_idx )
		local ok ,new_tab = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
		if not ok or not new_tab then
			only.log('E','connect channel_dbname failed!  %s ', sql_str )
			gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
		end

		only.log('D', " check user is joined : %s", sql_str)

		if #new_tab == 1 then
			if new_tab[1]['validity'] == "1" and new_tab[1]['talkStatus'] ~= "4" then
				gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_ALREADY_JOINED'])
			elseif new_tab[1]['validity'] == "1" and new_tab[1]['talkStatus'] == "4" then
				redis_api.cmd('private','hset', channel_idx .. ':userStatusTab', apply_accountid..":status", 1 )
			end
			local sql_str = string.format(G.sql_update_user_joined , cur_time , unique_code , apply_accountid , channel_number , channel_idx )
			table.insert(sql_tab, sql_str)
		else

			local sql_str = string.format(G.sql_insert_user_join , channel_idx , channel_number , apply_accountid, unique_code , cur_time )
			table.insert(sql_tab, sql_str)
		end
		---- 20150615
		---- 插入历史表
		local  sql_str = string.format(G.sql_join_channel_history,apply_accountid,channel_idx,channel_number)
		table.insert(sql_tab , sql_str)
		---- end

		---- 更新用户总人数
		local sql_str = string.format(G.sql_update_user_count, channel_idx , channel_number )
		table.insert(sql_tab , sql_str)

	end

	only.log('D',"verify secretChannel mysql %s ", table.concat( sql_tab, "\r\n") )

	local ok,sql_ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
	if not ok or not sql_ret then
		only.log('E',"mysql  failed, %s ", table.concat( sql_tab, "\r\n") )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	-- 修复拒绝时redis key置成1
	-- modify:qiumaosheng
	if check_status == STATUS_ALLOW then
		redis_api.cmd('private','hset', channel_idx .. ':userStatusTab', apply_accountid..":status", 1 )
	end
	
	return true
end


local function check_userinfo(accountid)
	local sql_str = string.format(G.sql_check_accountid, accountid )
	local ok ,tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok or not tab then
		only.log('E','connect userlist_dbname failed!  %s ', sql_str )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #tab == 1 then
		return true
	end
	return false
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
	local apply_accountid  = args['applyAccountID']
	if not check_userinfo( accountid ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if not check_userinfo( apply_accountid ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyAccountID')
	end

	local check_remark = args['checkRemark'] or ''
	local check_status = args['checkStatus']
	local apply_idx = tonumber(args['applyIdx'])

	---- 验证频道用户是否通过
	local  ok , ret = verify_secretChannel(accountid ,apply_accountid ,check_remark, apply_idx, check_status)
	if ok then
		gosay.go_success(url_tab,msg['MSG_SUCCESS'])
	else
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )



