-- jiang z.s.
-- 2015-05-27
-- 解散群聊频道

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
local custom_dbname   = "app_custom___wemecustom"


local G = {

	sql_check_accountid   = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1  ",

	------------- update info  

	sql_check_accountid_password   = "SELECT daokePassword password FROM userList WHERE accountID = '%s' limit 1  ",


	sql_check_channel_exist = "select idx from  checkSecretChannelInfo where channelStatus = 1 and accountID = '%s' and number = '%s'  " , 

	sql_get_userkey_info = " select accountID , actionType , customType from userKeyInfo " ..  
	" where actionType in (4 ,5 ) and customType in ( 10 ) and  customParameter = '%s'     " , 


	dissolve_secret_channel = " update checkSecretChannelInfo set channelStatus = 3 , updateTime = '%s' ,userCount = 0  where accountID = '%s' and number = '%s'   " ,

	invalid_verify_message = " update userVerifyMsgInfo set  validity = 0  where validity = 1 and accountID = '%s' and number = '%s' "  ,

	invalid_join_member_list = " update joinMemberList set  validity = 0 , actionType = 0 , updateTime = '%s'  where validity = 1 and number = '%s'   ",

	insert_join_member_history = "insert into joinMemberListHistory( idx ,number , accountID , uniqueCode ,updateTime ,validity ,talkStatus , actionType , role  ) " ..
	" select idx ,number , accountID , uniqueCode ,updateTime ,validity ," ..
	"  talkStatus , actionType , role from joinMemberList where accountID = '%s' and number = '%s'  " ,
	---- 保存到userAdminInfo表中
	sql_update_userAdminInfo = "update userAdminInfo set dissolve = dissolve + 1 , updateTime = unix_timestamp() where accountID = '%s'",

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

	if not args['channelNumber'] or #args['channelNumber'] < 5 or  #args['channelNumber'] > 50 or (string.find(args['channelNumber'],"'")) then
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
		only.log('E',"cur accountid password is not match, accountid:%s, password:%s , database pwd:%s", accountid , password , ret[1]['password'] )
		gosay.go_false(url_tab,msg['MSG_ERROR_PWD_NOT_MATCH'])
	end
	return true
end

---- 获取用户当前的状态
local function get_secret_channelidx( channelnum )
	local ok, ret = redis_api.cmd('private','get', channelnum .. ":channelID")
	if not ok then
		only.log('E',string.format(" channelnum %s get channelID failed",  channelnum))
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	if not ret then
		only.log('E',string.format(" channelnum %s get channelID failed", channelnum))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"channelNumber")
	end
	return ret
end



local function set_voicecommand_v2(accountid , action_type , custom_type,   parameter , parameter_id  )

	only.log('D',string.format("==============set_voicecommand_v2==%s %s %s %s ================",
	accountid , action_type , custom_type,   parameter))

	local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, parameter_id , custom_dbname )
	if not ok then
		only.log('E',string.format("user set channel info account_id: %s  actionType :%s customType: %s customPar:%s secretChannel:%s \r\n  %s \r\n sql:%s ",
		accountid,  action_type, custom_type , parameter, parameter_id ,err_msg, err_sql))
		gosay.go_false(url_tab, msg[err_msg])
	end
	return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter_id )
end


local function  set_groupvoice_v2(accountid , action_type , custom_type,   parameter , parameter_id   )

	only.log('D',string.format("==============set_groupvoice_v2===%s %s %s %s ===============", 
	accountid , action_type , custom_type,   parameter ))

	local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, parameter_id , custom_dbname )
	if not ok then
		only.log('E',string.format("user set channel info account_id: %s  actionType :%s customType: %s customPar:%s secretChannel:%s \r\n  %s \r\n sql:%s ",
		accountid,  action_type, custom_type , parameter, parameter_id ,err_msg, err_sql))
		gosay.go_false(url_tab, msg[err_msg])
	end
	return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter_id )
end


local function dissolve_secret_channel_info( accountid, channel_num  )
	local sql_str = string.format(G.sql_check_channel_exist, accountid , channel_num )
	local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',string.format("sql check channel exist failed %s ", sql_str ))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret == 0  then
		only.log('D',string.format("sql check channel exist succ, but result is empty, %s ", sql_str ))
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	local channel_idx = ret[1]["idx"]

	only.log('D', "dissolve_secret_channel info  get channel_idx , %s \r\nchannel_idx:%s  ", sql_str, channel_idx )

	local cur_time = os.time()

	local sql_tab = {}

	local sql_str = string.format(G.dissolve_secret_channel ,  cur_time ,  accountid , channel_num  )
	table.insert(sql_tab, sql_str)

	local sql_str = string.format(G.invalid_verify_message  , accountid , channel_num  )
	table.insert(sql_tab, sql_str)

	local sql_str = string.format(G.invalid_join_member_list ,cur_time, channel_num )
	table.insert(sql_tab, sql_str)

	local sql_str = string.format(G.insert_join_member_history,accountid,channel_num)
	table.insert(sql_tab, sql_str)


	---- 20150616
	---- 保存到userAdminInfo表中
	local sql_str = string.format(G.sql_update_userAdminInfo,accountid)
	table.insert(sql_tab ,sql_str)
	---- end

	only.log('D',"debug mysql, %s ", table.concat( sql_tab, "\r\n") )

	local ok,sql_ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
	if not ok  then
		only.log('E',"mysql  failed, %s ", table.concat( sql_tab, "\r\n") )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	---- 设置频道编号与频道ID对应的关系
	redis_api.cmd('private','del',
	channel_num .. ":channelID",
	channel_idx .. ":channelNumber",
	channel_idx .. ":channelType",
	channel_idx .. ":channelStatus",
	channel_idx .. ":channelNameUrl",
	channel_idx .. ":userChannelInfo",
	channel_idx .. ":userStatusTab",
	channel_idx .. ":channelOnlineUser" )

	----  去除用户按键设置
	local sql_str = string.format(G.sql_get_userkey_info, channel_num )
	local ok, tab = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not tab or type(tab) ~= "table" then
		only.log('E',string.format("sql_get_userkey_info failed %s ", sql_str ))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	local parameter = appfun.default_channel
	local parameter_id = get_secret_channelidx( parameter)

	for k ,v in pairs(tab) do
		local ok , ret = nil , nil 
		if tonumber(v['actionType']) == appfun.DK_TYPE_COMMAND then
			ok, ret = set_voicecommand_v2 (v['accountID'] , tonumber(v['actionType']) , tonumber(v['customType']),   parameter , parameter_id  )
		elseif tonumber(v['actionType']) == appfun.DK_TYPE_GROUP then
			ok, ret = set_groupvoice_v2 (v['accountID'] , tonumber(v['actionType']) , tonumber(v['customType']),   parameter , parameter_id  )
		end
		if not ok then
			only.log('E',"[logic is error]accountID:%s actionType:%s customType:%s parameter:%s parameter_id:%s , ret:%s " , v['accountID'] , v['actionType'] , v['customType'],   parameter , parameter_id  ) 
		end
	end
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

	local channel_num = args['channelNumber']

	local ok = dissolve_secret_channel_info( accountid, channel_num  )
	if ok then
		gosay.go_success(url_tab,msg['MSG_SUCCESS'])
	else
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
