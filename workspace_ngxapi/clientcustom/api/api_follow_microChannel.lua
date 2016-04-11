---- jiang z.s. 
---- 2014-10-30 
---- 关注微频道  

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

-- 密频道最大支持的人数
local MAX_USER_COUNT = 100 

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {

	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ",
	----检查邀请码
	sql_check_uniquecode = " SELECT idx ,number,accountID, userCount from  checkMicroChannelInfo where  channelStatus in (  1 , 2 )  and   inviteUniqueCode = '%s'  limit 1  " , 
	----判断是否关注
	sql_check_follow_info  = " select validity from followUserList where idx = '%s' and number = '%s' and accountID = '%s' limit 1   " , 
	
	sql_insert_follow_info = " insert into followUserList ( idx , number , accountID , uniqueCode , createTime , validity)  " ..
							" values ( '%s' , '%s' , '%s' , '%s' , unix_timestamp(),  1 ) " ,

	sql_update_follow_info = " update followUserList set uniqueCode = '%s', validity = %s, updateTime = unix_timestamp() where idx = '%s' and number = '%s' and  accountID = '%s'  "  ,

	sql_history_follow_info  = "  insert into followUserListHistory ( idx, number, accountID, uniqueCode , updateTime ,validity, appKey ) " ..
								" values ( '%s' , '%s', '%s', '%s' ,unix_timestamp(),%s , %s )  " , 

	----更新用户关注用户数量 2015-06-04
	sql_update_follow_user_count_increase = " update  checkMicroChannelInfo set userCount = userCount + 1  where idx = '%s' and number = '%s' " ,

	sql_update_follow_user_count_decrease = " update  checkMicroChannelInfo set userCount = userCount - 1  where idx = '%s' and number = '%s' and userCount > 0   " ,


	----获取当前微频道粉丝总数
	sql_get_microchannel_usercount = " select count(1) as count from followUserList where validity = 1 and idx = '%s' and number = '%s'  " ,

	----更新当前频道粉丝总数
	sql_init_microchannel_usercount = " update checkMicroChannelInfo set userCount = %d  where  idx = '%s' and number = '%s'  " ,

}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}



-->chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID'])  then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end


	---- 1 关注   /   2 取消关注
	local follow_type = args['followType'] 
	if not follow_type then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'followType')
	end

	if not ( follow_type == "1" or follow_type == "2" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'followType')
	end

	if follow_type == "1" then
		if not args['uniqueCode'] or  string.find(args['uniqueCode'] ,"'" ) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'uniqueCode')
		end

		local tmp_uniquecode = args['uniqueCode']
		--local tmp_uniquecode = string.match(uniquecode,"%w+")
		if not tmp_uniquecode or  #tostring(tmp_uniquecode)  < 32 or #tostring(tmp_uniquecode) >64  or not string.find(tmp_uniquecode , '|')  then
			only.log('E',string.format(" uniqueCode:%s is error", tmp_uniquecode ))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'uniqueCode')
		end
	---- 取消关注
	elseif follow_type == "2" then
		---- 取消关注的频道
		if not args['channelNumber'] or  string.find(args['channelNumber'] ,"'" ) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
		end

		local channel_num = args['channelNumber']
		
		---- 频道编号
		---- %w 字母和数字
		local tmp_channel_num = string.match(channel_num,"%w+")
		if not tmp_channel_num or tmp_channel_num ~= channel_num or #tostring(tmp_channel_num) < 5 or  #tostring(tmp_channel_num) > 16  then
			only.log('E',string.format(" channel_number:%s is error", channel_num ))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
		end

		---- 第一位必须要为字母
		local tmp_start = string.sub(tmp_channel_num,1,1)
		if (tonumber(tmp_start) or -1 ) >= 0 then
			only.log('E',string.format(" channel_number:%s first char not Letters ", channel_num ))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
		end
	end
	-- safe.sign_check(args, url_tab )
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
	
end

---- 对accountID进行数据库校验
local function check_userinfo(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status or user_tab == nil then
		only.log('D',sql_str)
		only.log('E','connect userlist_dbname failed!')
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #user_tab == 0 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if #user_tab >1 then 
		-----数据库存在错误,
		only.log('E','[***] userList accountID recordset > 1 ')
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

----频道用户关注数量为0,需要初始化用户数量
local function init_current_microchannel_usercount( channel_id, channel_num )
	local sql_str = string.format(G.sql_get_microchannel_usercount, channel_id , channel_num )
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table"  then
		only.log('E', string.format('check sql_get_microchannel_user_count failed, %s', sql_str ) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	local current_follow_usercount = ret[1]['count']
	local sql_str = string.format(G.sql_init_microchannel_usercount, current_follow_usercount , channel_id , channel_num )
	local ok,ret = mysql_api.cmd(channel_dbname,'UPDATE',sql_str)
	if not ok  then
		only.log('E', string.format('check sql_get_microchannel_user_count failed, %s', sql_str ) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
end

---- 1 关注微频道
local function follow_microchannel( accountid, uniquecode ,app_key  )
	local sql_str = string.format(G.sql_check_uniquecode, uniquecode)			--//1.检查uniquecode
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret  then
		only.log('E', string.format('check uniquecode failed, %s', sql_str ) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret ~= 1 then
		only.log('E', string.format('check uniquecode is not exists , %s', sql_str ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_UNIQUECODE'])
	end

	local cur_channel_id = ret[1]['idx']
	local cur_channel_num = ret[1]['number']

	local cur_user_count = tonumber(ret[1]['userCount'])
	if cur_user_count == 0  then
		init_current_microchannel_usercount(cur_channel_id,cur_channel_num)
	end

	only.log('D', string.format(" [********8] %s %s  %s " , cur_channel_id, cur_channel_num ,accountid  ) )

	if tostring(ret[1]['accountID']) == tostring(accountid) then 			--//2.判断自己关注自己
		only.log('E', string.format('accountid:%s follow self create channel %s ', accountid ,  cur_channel_num ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_FOLLOW_SELF'])
	end

	local sql_str = string.format(G.sql_check_follow_info , cur_channel_id, cur_channel_num, accountid ) 		--//3.判断关注情况
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret  then
		only.log('E', string.format('check follow info failed, %s', sql_str ) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret == 1 and ret[1]['validity']  == "1" then 		--//3.判断关注情况
		only.log('E', string.format('current is followed  %s, channel_num %s, uniquecode:%s', accountid ,cur_channel_num , uniquecode ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_FOLLOWED'])
	end

	local sql_tab = {}
	if #ret == 0  then
		----insert 
		local sql_str = string.format(G.sql_insert_follow_info, cur_channel_id , cur_channel_num, accountid , uniquecode) --// 4.insert follow info
		table.insert(sql_tab,sql_str)
	else
		local sql_str = string.format(G.sql_update_follow_info, uniquecode, 1  , cur_channel_id, cur_channel_num, accountid)  --// 4.以前取消关注，现重现关注
		table.insert(sql_tab,sql_str)
	end

	---- 更新用户关注的粉丝数量 2015-06-04
	local sql_str = string.format(G.sql_update_follow_user_count_increase, cur_channel_id, cur_channel_num )
	table.insert(sql_tab,sql_str)


	local sql_str = string.format(G.sql_history_follow_info , cur_channel_id, cur_channel_num, accountid , uniquecode , 1 , app_key ) --//5.插入关注历史表中
	table.insert(sql_tab,sql_str)

	local ok, ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
	if not ok then
		only.log('E',string.format(" user follow microchannel failed!  %s ", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	----- 每个频道里面所关注的用户列表
	local ok, ret = redis_api.cmd('private', 'sadd', string.format("%s:microChannelFollowUser", cur_channel_id ), accountid )
	if not ok then
		only.log('E',string.format(" accountid:%s  save user to  %s:microchannelFollowUser  failed ,channelNumber:%s ", accountid,  cur_channel_id , cur_channel_num  ) )
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end

	---- 每个用户所关注的频道列表
	local ok, ret = redis_api.cmd('private', 'sadd', string.format("%s:userFollowMicroChannel", accountid ),  cur_channel_id)
	if not ok then
		only.log('E',string.format(" accountid:%s  save channel to  %s:userFollowMicroChannel  failed ,channelNumber:%s ", accountid,  cur_channel_id , cur_channel_num  ) )
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end

	---- 用户在线则自动加入到当前订阅的频道 2014-11-25
	local ok, is_online = redis_api.cmd('statistic','sismember', "onlineUser:set", accountid ) 
	if ok and is_online == true then
		redis_api.cmd('statistic', 'sadd', string.format("%s:channelOnlineUser", cur_channel_id ), accountid )
	end

	return true
end

---- 2 取消关注
local function unfollow_microchannel(accountid, channel_num , app_key )
	local ok, cur_channel_id = redis_api.cmd('private', 'get', string.format("%s:channelID", channel_num))
	if not ok  then
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end

	if #tostring(channel_num) < 5 or  #tostring(channel_num) > 64  then 
		only.log('E',string.format("accountid:%s  channel_num:%s get channel_idx:%s  failed " , accountid, channel_num , cur_channel_id ))
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	only.log('D', string.format(" [*****-----] %s %s  %s " , cur_channel_id, channel_num ,accountid  ) )

	local sql_str = string.format(G.sql_check_follow_info, cur_channel_id, channel_num, accountid )
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret  then
		only.log('E', string.format('check unfollow info failed, %s', sql_str ) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret ~= 1 then
		only.log('E', string.format('unfollow info failed before not follow this channel_num, %s', sql_str ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_UNFOLLOW'])
	end

	if #ret == 1 and ret[1]['validity']  == "0" then
		only.log('E', string.format('current is unfollowed  %s, channel_num %s,  ', accountid ,channel_num  ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_UNFOLLOWED'])
	end

	local sql_tab = {}
	local sql_str = string.format(G.sql_update_follow_info, '', 0 , cur_channel_id, channel_num, accountid )
	table.insert(sql_tab, sql_str)

	local sql_str = string.format(G.sql_history_follow_info , cur_channel_id, channel_num , accountid , '' , 0 , app_key )
	table.insert(sql_tab,sql_str)

	---- 更新用户关注的粉丝数量 2015-06-04
	local sql_str = string.format(G.sql_update_follow_user_count_decrease, cur_channel_id, channel_num)
	table.insert(sql_tab,sql_str)

	local ok, ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
	if not ok then
		only.log('E',string.format(" user follow channel failed!  %s ", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	----- 每个频道里面所关注的用户列表
	local ok, ret = redis_api.cmd('private', 'srem', string.format("%s:microChannelFollowUser", cur_channel_id ), accountid )
	if not ok then
		only.log('E',string.format(" accountid:%s  save user to  %s:channelFollowUser  failed ,channelNumber:%s ", accountid,  cur_channel_id , cur_channel_num  ) )
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end

	---- 每个用户所关注的频道列表
	local ok, ret = redis_api.cmd('private', 'srem', string.format("%s:userFollowMicroChannel", accountid ),  cur_channel_id)
	if not ok then
		only.log('E',string.format(" accountid:%s  save channel to  %s:userFollowChannel  failed ,channelNumber:%s ", accountid,  cur_channel_id , cur_channel_num  ) )
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end

	---- 从在线频道里面移除用户 2014-11-25 
	redis_api.cmd('statistic', 'srem', string.format("%s:channelOnlineUser", cur_channel_id ), accountid )

	return true

end


local function handle()

	local req_ip   = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	local req_method = ngx.var.request_method
	url_tab['client_host'] = req_ip
	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_body'] = req_body

	local args = nil	
	if req_method == 'POST' then		
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')		
		if not boundary then		
			args = ngx.decode_args(req_body)		
		else		
		---- 解析表单形式 		
			args = utils.parse_form_data(req_head, req_body)		
		end		
	end

	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
	end

	url_tab['app_key'] = args['appKey']
	---- 传入参数语法校验
	check_parameter(args)

	---- 审核人
	local accountid  = args['accountID']
	---- 对accountID进行数据库校验
	check_userinfo(accountid)

	local follow_type = args['followType'] 
	local app_key = args['appKey']

	local ok = nil
	---- 关注微频道
	if 	follow_type == "1" then
		local uniquecode = args['uniqueCode']
		ok = follow_microchannel(accountid, uniquecode , app_key )
	---- 取消关注微频道
	elseif follow_type == "2" then
		local channel_num = args['channelNumber'] 
		ok = unfollow_microchannel(accountid, channel_num , app_key )
	end

	if ok then
		----SUCCED
		gosay.go_success(url_tab, msg['MSG_SUCCESS'])
	else
		----FAILED
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	
end

safe.main_call( handle )
