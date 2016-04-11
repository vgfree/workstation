--author: 
--remark: 批量设置用户++键的设置值
--date:    2015-01-28

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local weibo     = require('weibo')
local appfun    = require('appfun')
local cur_utils = require('clientcustom_utils')

local userlist_dbname = 'app_usercenter___usercenter'
local channel_dbname   = 'app_custom___wemecustom'
local weibo_dbname    = 'app_weibo___weibo'


local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

local G = {
	sql_check_accountID = "select accountID from userList where accountID in ( '%s' ) " ,

	---- 判断number是否存在
	sql_check_channelNumber = "select idx,accountID,inviteUniqueCode from checkSecretChannelInfo where channelStatus = 1  and  number = '%s' ",

	---- 判断用户是否加入频道
	sql_check_is_join_channel = " select validity from joinMemberList where accountID = '%s' and number = '%s' and idx = '%s' " ,

	sql_join_channel = " insert into joinMemberList(idx,number,accountID,uniqueCode,createTime,validity,talkStatus,role,actionType) " ..
						" values ('%s','%s','%s','%s',%d, 1 , 1 , 0 ,  0  )" ,
	-- 同时插入加入历史
	sql_insert_joinHistory = "insert into joinMemberListHistory(idx,number,accountID,uniqueCode,validity,talkStatus,role,actionType) " ..
						" select idx,number,accountID,uniqueCode,validity,talkStatus,role,actionType from joinMemberList " ..
						"where number = '%s' and accountID = '%s'  " ,

	sql_update_join_channel = " update joinMemberList set validity = 1 ,updateTime = %d ,actionType = 0 where validity = 0 and accountID = '%s' and number = '%s' and idx = '%s'  " ,

}

local actionType = 5
local MAX_COUNT = 100 

-->chack parameter
local function check_parameter(args)
	---- 校验参数
	---- 1 accountIDs , 使用逗号分割
	if not args['accountIDs'] or #args['accountIDs'] < 5 or string.find(args['accountIDs'],"'") then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountIDs')
	end

	---- 2 比较count总数是否大于最大阀值(MAX_COUNT) 
	if args['count'] then
		if not tonumber(args['count']) or tonumber(args['count']) > MAX_COUNT or tonumber(args['count']) < 1  then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'count')
		end
	end

	---- 3 customType :   密频道
	if not args['customType'] or tonumber(args['customType']) ~= 10 then
		only.log('D',"customType:%s",args['customType'])
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'customType')
	end
	---- 4 channelInfo:  设置频道的信息 群聊频道则输入 频道编码 
	if not args['channelInfo'] or not utils.is_number(args['channelInfo']) or #args['channelInfo'] < 5 or #args['channelInfo'] > 10 then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelInfo')
	end
	safe.sign_check(args, url_tab)
end

---- 用户加入操作判断
local function user_join_operation(accountid, channel_number, channel_idx, inviteUniqueCode, customType, adminAccountID)
	---- 用户加入群聊频道
	---- 判断用户是否加入频道
	local sql_str = string.format(G.sql_check_is_join_channel, accountid, channel_number, channel_idx)
	local ok,ret = mysql_api.cmd(channel_dbname,'select', sql_str)
	if not ok or not ret or type(ret) ~= 'table' then
		only.log('E',string.format("sql_check_is_join_channel mysql failed, sql_str %s ", sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	local cur_time = os.time()
	local sql_str = nil
	---- 20150725
	---- bug修复
	---- 忽略了validity的判断
	if #ret == 1 then
		if ret[1]['validity'] == '0' then
			sql_str = string.format(G.sql_update_join_channel,cur_time,accountid,channel_number,channel_idx)
		else
			return true
		end
	else
		sql_str = string.format(G.sql_join_channel, channel_idx, channel_number , accountid ,  inviteUniqueCode , cur_time  )
	end
	---- end
	local ok = mysql_api.cmd(channel_dbname,'insert', sql_str)
	if not ok then
		only.log('E',string.format("sql_join_channel ot update_joinMemberlist mysql failed, sql_str %s ", sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	return true
end

--设置按键
local function  set_user_keyinfo(accountid, actionType, customType, channel_number, channel_idx  )
	local ok, err_msg , err_str = cur_utils.user_set_channel_info(accountid, 
																	actionType, 
																	customType, 
																	channel_number,
																	channel_idx,
																	channel_dbname)
	if ok then
		local ok_val = cur_utils.save_user_keyinfo_to_redis(accountid, actionType, customType, channel_idx)
		if  ok_val then
			return true
		else
			only.log('E',"save_user_custominfo_to_redis error accountid:%s,actionType:%s,customType:%s channel_number:%s ", accountid, actionType, customType, channel_number)
		end
	else
		only.log('E',"user_set_channel_info error accountid:%s,actionType:%s,customType:%s channel_number:%s",accountid, actionType, customType , channel_number)
	end

	return false
end


local function batch_set_userkeyinfo( accountids , customType, channel_number )
	local success_count = 0
	---- 查询当前频道是否存在
	local str = string.format(G.sql_check_channelNumber,channel_number)
	local ok,ret = mysql_api.cmd(channel_dbname,'select',str)
	if not ok or not ret or type(ret) ~= 'table' then
		only.log('E',string.format("check_number mysql failed, sql %s ",str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		only.log('W',"cur channel_number not exits number:%s",channel_number)
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelInfo')
	end

	local channel_idx = ret[1]['idx']
	local channel_unique = ret[1]['inviteUniqueCode']
	local channel_admin = ret[1]['accountID']


	---- 把所有非法的accountID过滤掉
	local str = string.format(G.sql_check_accountID,table.concat(accountids,"','"))

	only.log('D',"debug info check_accountID sql is :%s ",str)

	local ok,ret = mysql_api.cmd(userlist_dbname,"SELECT",str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',string.format("check_accountID mysql failed,sql %s ",str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret == 0 then
		only.log('E',string.format("accountids all not exits, sql %s", str ))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountIDs')
	end

	---- 只处理有效的accountID 
	for i , account_info in pairs(ret) do
		local status = user_join_operation(account_info['accountID'], channel_number , channel_idx ,  channel_unique , customType, channel_admin )
		if status then
			local ok = set_user_keyinfo(account_info['accountID'],tonumber(actionType), customType ,channel_number , channel_idx )
			if ok then
				success_count = success_count + 1
			end
		end
	end
	return success_count
end


local function handle()
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
		args = utils.parse_url(req_body)
	end

	if not args or type(args) ~= "table" then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	url_tab['app_key'] = args['appKey']
	check_parameter(args)

	local count = tonumber(args['count']) or 0

	local accountids = {} 

	if count == 1 then
		table.insert(accountids,args['accountIDs'])
	elseif count > 1 then
		accountids = utils.str_split(args['accountIDs'],",")
	end
	if count ~= #accountids then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'count')
	end

	if not accountids or type(accountids) ~= "table" then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"accountIDs")
	end	

	local success_count = batch_set_userkeyinfo( accountids ,args['customType'],args['channelInfo'])
	local failed_count = count - success_count
	local str = string.format('{"count":"%s","success":"%s","failed":"%s"}',count,success_count,failed_count)
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)

end

safe.main_call( handle )
