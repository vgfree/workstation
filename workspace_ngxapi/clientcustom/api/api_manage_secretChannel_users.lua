----author:zhangerna
----管理员管理群聊频道里用户的状态(管理密频道)
----公司管理群聊频道

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')
local appfun    = require('appfun')

local channel_dbname = "app_custom___wemecustom"
local custom_dbname   = "app_custom___wemecustom"

local G = {
	sql_check_join_secret_channel = " select 1 from joinMemberList where accountID = '%s' and idx = '%s' and number = '%s' and validity = 1  " , 


	sql_update_joinMemberList = "update joinMemberList set talkStatus = %s , updateTime = '%s' where number = '%s' and accountID = '%s' ",


	---- 关闭频道
	sql_close_channel   = "update checkSecretChannelInfo set channelStatus = %s , updateTime = %s  where number = '%s' and idx = '%s'  ",

	sql_remove_joinMemberList = "update joinMemberList set validity = 0, updateTime = %s where number = '%s' and idx = '%s' and validity = 1",

	sql_dissolve_userAdmin = "update userAdminInfo set dissolve = dissolve + 1 ,updateTime = %s where accountID = '%s'   ",


	sql_get_channel_userkey = "	select accountID, actionType,customType from userKeyInfo " .. 
							" 	where validity = 1 and actionType in ( 4 ,5  )  and customParameter = '%s'  %s    ",


}

---- 2015-05-22 
---- [channelID]:userStatusTab 
----    存放频道用户的状态

local url_tab = {
	type_name = 'clientcustom',
	app_key = '',
	client_host = '',
	client_body = '',
}

local function check_parameter(args)
	--检查 adminAccountID
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	---- 检查频道编号
    ---- 频道number为9位数字
    if args['channelNumber'] and #tostring(args['channelNumber']) > 0 then
        if  #tostring(args['channelNumber']) < 5 or not utils.is_number(args['channelNumber']) then
            only.log('E',string.format(" channel_number:%s is error", args['channelNumber']))
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
        end
    end

	if not args['infoType'] or #tostring(args['infoType']) == 0 or not tonumber(args['infoType']) or not (tonumber(args['infoType']) == 1 or tonumber(args['infoType']) == 2) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'infoType')
	end

	if args['infoType'] == "1" then
		------  设置频道状态
		------  curStatus 
		------   1) 正常
		------   2) 关闭
		------  频道状态和用户状态共用一下接口
		if not (args['curStatus'] == "1" or args['curStatus'] == "2"  ) then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'curStatus')
		end
	else
		---- 校验普通用户的accountID
		if not app_utils.check_accountID(args['userAccountID']) then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'userAccountID')
		end

		if args['accountID'] == args['userAccountID'] then
			gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_MG_SELF'])
		end
		-- 设置用户状态
		-- curStatus 
		-- 1) 正常
		-- 2) 禁言
		-- 3) 拉黑
		if not (args['curStatus'] == "1" or args['curStatus'] == "2" or args['curStatus']  == "3" ) then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'curStatus')
		end
	end
	-- safe.sign_check(args,url_tab)
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

local function get_secret_channel_id( channel_num )
	local ok, channelid = redis_api.cmd('private','get', channel_num .. ":channelID")
	if not ok or not channelid or #channelid < 9 then
		return false
	end
	return channelid
end

local function get_secret_channel_admin(channelid)
	local ok, ret = redis_api.cmd('private','hget',channelid .. ':userChannelInfo', "owner")
	if not ok or not ret then
		only.log('E',string.format(" channel_num get owner failed %s " , ret ))
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	return ret
end

---- 检查用用户是否在当前频道
local function check_user_in_secret_channel_num(accountid,channelid,channel_num)
	local sql_str = string.format(G.sql_check_join_secret_channel,accountid,channelid,channel_num)
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret then
		only.log('E',string.format("userKeyInfo_db connect failed %s",sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_DID_NOT_JOINED'])
	end
end

local function get_user_status(accountid,channelid)
	local ok,status = redis_api.cmd('private','hget',channelid .. ':userStatusTab',accountid..":status")
	if not ok then
		only.log('E',string.format("accountid channelid get status failed %s,%s",accountid,channelid))
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	return status
end

---- 管理频道内的用户
local function manage_secret_channel_user( admin_accountid, channel_num, channelid, cur_status, accountid )
	--判断当前频道是否解散
	local ok,status = redis_api.cmd('private','get',channelid .. ":channelStatus")
	if not ok then
		only.log('E',"get channelStatus error [%s]",channelid)
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	if not status or #tostring(status) == 0 then
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	if status and status == '2' then
		---- 当前频道已经关闭
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	---- 获取真正的管理员   
	local really_owner = get_secret_channel_admin(channelid)
	if not really_owner then
		only.log('E',"get really_owner failed [%s]",channelid)
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end
	if admin_accountid ~= really_owner then
		---- 当前不是管理员
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_NOT_MG'])
	end

	if admin_accountid == accountid then
		---- 不能管理自己
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_MG_SELF'])
	end

	----   1) 判断用户是否已经在当前频道
	check_user_in_secret_channel_num(accountid,channelid,channel_num)

	----  2) 判断用户当前的状态是否与设置最新的状态是否相同,相同不更新,返回true
	local user_status = get_user_status(accountid,channelid)

	---- 如果redis的状态表中没有数据，则状态为1   redis中存放状态为2 禁言，3拉黑的数据
	if not user_status  or #tostring(user_status) == 0 then 
		if cur_status == '1' then
			return true
		end
	else
		--和redis的Status表中的状态比较
		if cur_status == user_status then
			return true
		end
		--用户如果原先为拉黑3或禁言2，改为正常1,要删除原先在usrStatusTab中的数据
		if cur_status == '1' then
			redis_api.cmd('private','hdel',channelid .. ":userStatusTab", accountid .. ":status",user_status)
		end
	end

	---- 3) 更新用户设置的状态至数据库,以及redis
	if cur_status ~= '1' then
		redis_api.cmd('private','hset',channelid .. ":userStatusTab", accountid .. ":status",cur_status)
	end
	---- 更新join表
	local cur_time = os.time() 
	local sql_str = string.format(G.sql_update_joinMemberList,cur_status,cur_time,channel_num,accountid)
	local  ok,ret = mysql_api.cmd(channel_dbname,'update',sql_str)
	if not ok or not ret then
		only.log('E','sql update joinMemberList failed [sql_str:%s]',sql_str)
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if cur_status == '3' then
		redis_api.cmd('statistic','srem',string.format("%s:channelOnlineUser",channelid),accountid)
		only.log('W',string.format("user_status set blacklist ,accountid:%s num:%s idx:%s ", accountid, channel_num, channelid ))
	end
	return true
end


---- 得到每个用户所在的地区
local function get_citycode(accountid)
	local ok , ret = redis_api.cmd('private','get',accountid .. ":cityCode")
	if ok and ret then
		only.log('D',string.format(" accountid:%s get citycode citycode is :%s  get success " , accountid, ret ))
		return ok,ret
	end

	only.log('D',string.format(" accountid:%s get citycode citycode is :%s get failed  " , accountid, ret ))

	return true,appfun.default_channel
end

local function get_default_channel( accountid , action_type )
	if action_type == appfun.DK_TYPE_COMMAND then
		---- get citycode 
		return get_citycode(accountid)
	elseif action_type == appfun.DK_TYPE_GROUP then
		return true,appfun.default_channel
	end
	return false,false
end

------ 代码有异常 2015-08-26
local function clear_userkey_bind( accountid, action_type ) 
	local ok, user_default_channel =  get_default_channel(accountid, action_type)
	if ok and user_default_channel then
		---- 更新用户的userKeyInfo表以及redis
		local custom_type = nil
		if action_type == appfun.DK_TYPE_COMMAND then
			custom_type = appfun.VOICE_COMMAND_TYPE_SECRETCHANNEL
		elseif action_type == appfun.DK_TYPE_GROUP then
			custom_type = appfun.GROUP_VOICE_TYPE_SECRETCHANNEL
		end
		local parameter = user_default_channel
		local parameter_id = nil
		if user_default_channel == appfun.default_channel then
			---- 20150613
			---- 原先是10086：channelOnlineUser
			---- 修改bug，idx：channelOnlineUser
			---- 10086
			only.log('D',"private get %s:channelID" ,user_default_channel)
			local ok, val = redis_api.cmd('private','get', user_default_channel .. ":channelID")
			if ok and val then
				parameter_id = val
			else
				only.log('E',string.format("***get default_channel failed, accountid:%s action_type:%s default channelnum:%s channelid:%s  " ,
										accountid, action_type,parameter_id))

				gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
			end
			---- end
		else
			local ok, val = redis_api.cmd('private','get', parameter .. ":channelID")
			if ok and val then
				parameter_id = val
			else
				only.log('E',string.format("***get default_channel failed, accountid:%s action_type:%s default channelnum:%s channelid:%s  " ,
										accountid, action_type,parameter, parameter_id))

				gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
			end
		end
		local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, parameter_id , custom_dbname )
		if not ok then
			
			only.log('E',string.format("[manage secret channel users] user set channel info account_id: %s  actionType :%s customType: %s customPar:%s secretChannel:%s \r\nsql:%s ",
			                            accountid,  action_type, custom_type , parameter, parameter_id , err_sql))

			gosay.go_false(url_tab, msg[err_msg])
		end
		return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter_id )
	end
end

function clear_userkey_info(channelnum,  channelid , accountid )
	local sql_filter = "" 
	if accountid then
		sql_filter = string.format(" and accountID = '%s'  ", accountid  )
	end
	---- 20150613
	---- 原先，local sql_str = string.format(G.sql_get_channel_userkey, channelid , sql_filter )
	---- 修改频道bug
	local sql_str = string.format(G.sql_get_channel_userkey, channelnum , sql_filter )
	local ok , ret = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or not ret then
		only.log('E',string.format(" get channel userKeyInfo  failed %s " ,  sql_str  ) )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	---- 当前频道里面没有人设置当前按键
	if #ret < 1 then
		return true
	end
	---- 管理频道用户，如果两个按键都设，即踢到地区频道，也踢到10086频道
	for index , info  in pairs(ret) do
		local ok, err = clear_userkey_bind( info['accountID'], tonumber(info['actionType']) ) 
		if not ok then
			only.log('E',string.format("index:%s accountid:%s action_type:%s init default_channel failed! " ,index ,info['accountID'], info['actionType'] ))
			return false
		end
	end
	return true
end

---- 管理频道状态 频道关闭后不能恢复/公司管理者只能关闭频道
local function manage_secret_channel_info(admin_accountid, channel_num, channelid, cur_status)
	local ok, ret = redis_api.cmd('private','get', channelid .. ':channelStatus')
	if not ok or not ret then
		only.log('E',string.format("[x] admin_accountid %s channelid get channelStatus %s failed " , admin_accountid, channelid, ret ) )
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end

	if tostring(ret) == tostring(cur_status) then
		---- 和上一次状态相同,直接返回true
		only.log('W',"cur channelStatus == really_channelStatus %s %s",ret , cur_status )
		return true
	end

	if tostring(ret) == '2' then
		only.log('W',"cur channel is close [channel_num:%s]",channel_num)
		return true
	end

	---- 更改频道状态为关闭，同时将频道里所有用户踢除
	local sql_tab = {}
	local cur_time = os.time()
	local sql_str = string.format(G.sql_close_channel, cur_status,cur_time, channel_num,channelid )
	table.insert(sql_tab,sql_str)
	---- 如果更改频道状态为2关闭则剔除joinMemberList里的所有用户
	local sql_str = string.format(G.sql_remove_joinMemberList, cur_time, channel_num, channelid)
	table.insert(sql_tab,sql_str)

	---- 解散频道的次数
	local  sql_str = string.format(G.sql_dissolve_userAdmin,cur_time,admin_accountid)

	local ok, ret = mysql_api.cmd(channel_dbname,'AFFAIRS', sql_tab )
	if not ok then
		only.log('E',string.format(" manage_secret_channel_info failed %s " ,  table.concat( sql_tab, "\r\n" )  ) )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	clear_userkey_info(channel_num, channelid )

	redis_api.cmd('private','set', channelid .. ":channelStatus", cur_status )

	return true
end


local function handle()

	local req_ip = ngx .var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()

	local req_method = ngx.var.request_method
	url_tab['client_host'] = req_ip
	if not req_body then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'req_body')
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
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'args')
	end

	if not args['appKey'] then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'appKey')
	end

	url_tab['app_key'] = args['appKey']
	check_parameter(args)


	local admin_accountid = args['accountID']
	local channel_num     = args['channelNumber']
	local accountid       = args['userAccountID']

	local cur_status      = args['curStatus']
	local info_type       = args['infoType']
	local ok              = nil

	local channelid = get_secret_channel_id(channel_num)
	if not channelid  then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
	end

	---- 1 是公司 2 是管理员
	if info_type == "1" then
		---- 判断重复提交
		if channel_status == '1' then
			---- 1正常 2关闭  管理员只能关闭频道，不能恢复频道
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'curStatus')
		end 
		
		ok = manage_secret_channel_info(admin_accountid, channel_num, channelid, cur_status)
	elseif info_type == '2' then
		---- 管理员管理频道里的用户
		ok = manage_secret_channel_user(admin_accountid, channel_num, channelid, cur_status, accountid)
	end

	if ok then
		--success
		gosay.go_success(url_tab,msg['MSG_SUCCESS'])
	else
		--failed
		gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
	end
end

handle()
