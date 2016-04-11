---- jiang z.s.
---- 2015-05-25 
---- 迁移原始频道的老数据

local ngx       = require('ngx')
local utils     = require('utils')
local cutils    = require('cutils')
local app_utils = require('app_utils')
local appfun    = require('appfun')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

-- local host_ip   = userKeyServer.host
-- local host_port = userKeyServer.port


---- 群里面最大用户数
local max_capacity = 5000

local G = {
	sql_get_channel_info = " select distinct customParameter, 0 as status from userKeyInfo where validity = 1  and  ( ( actionType = 4 and customType = 2 ) or ( actionType = 5 and customType = 1  ) )  ",

	sql_get_user_key_info = " select accountID, actionType , customType , customParameter, 0 as status from userKeyInfo where customType < 10  and length(customParameter) != 9  %s order by updateTime  limit %s  ", 


	sql_get_user_key_info_by_accountid = " select accountID, actionType , customType , customParameter, 0 as status from userKeyInfo where customType < 10  and length(customParameter) != 9  %s order by accountID  limit %s  ", 

	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1",

	---- 检查重复申请
	sql_check_repeat_apply = "select 1 from checkSecretChannelInfo WHERE number ='%s'  ",

	---- 判断用户申请的频道个数是否达到最大限度,不能从useradmin中取，创建的次数有可能和当前创建的频道不一致
	sql_check_channel_count = "select count(1) as count from checkSecretChannelInfo where accountID = '%s' and channelStatus = 1 ",

	---- channelType = 1 地区频道
	---- channelType = 2 原始老频道数据 2015-05-25
	---- 加入申请表中
	sql_finish_apply_channel = "insert into checkSecretChannelInfo(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName," .. 
							" logoURL,openType,capacity,accountID,createTime,inviteUniqueCode,isVerify,keyWords,channelNameURL,channelType)" ..
							" values ('%s','%s', '%s', '%s', %s, '%s', %s, '%s', " ..
							" '%s' , %s, %s, '%s', %d,'%s',%d ,'%s','%s',2) " , 

	sql_insert_checkSecretChannelInfoHistory = "insert into checkSecretChannelInfoHistory(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName," .. 
							" logoURL,openType,capacity,updateTime,channelStatus,appKey,isVerify,accountID,inviteUniqueCode,keyWords,channelNameURL)" ..
							"select idx,number,name,introduction,cityCode,cityName,catalogID,catalogName,logoURL,openType,capacity,'%s', "..
							"channelStatus,'%s',isVerify , accountID,inviteUniqueCode,keyWords,channelNameURL  from checkSecretChannelInfo where accountID = '%s' and cityCode = %s and catalogID = %s and isVerify = %s",
	---- role 是否为管理员
	sql_join_channel_list    = "insert into joinMemberList(idx , number, uniqueCode , accountID, createTime,role) "..
							" values('%s','%s','%s','%s',%d,%d)",

  	---- 检查用户是否申请过频道
  	sql_select_userAdminInfo = "select `create` from userAdminInfo where accountID = '%s' ",
	---- 插入创建次数表
	sql_insert_userAdminInfo = "insert into userAdminInfo(accountID,`create`,createTime) values('%s' , %d, %d) ",
	---- 更新次数表
	sql_update_userAdminInfo = "update userAdminInfo set `create` = %d ,updateTime = %d where accountID = '%s' ",
	---- 将管理员自动加入joinMemberlist中
	sql_join_channelHistory = "insert into joinMemberListHistory(idx,number,accountID,uniqueCode, updateTime,role) "..
							" select idx, number, accountID,uniqueCode,createTime,role from joinMemberList where accountID = '%s' and number = '%s' ",
	---- 将申请频道加入频道列表
	sql_insert_userChannelList = "insert into userChannelList(idx,number,accountID,channelType,createTime) values ('%s','%s','%s',%d,%d)",

	sql_get_next_idx         = "SELECT max(id) as count FROM userChannelList where channelType != 0  " , 

	sql_get_catalog_name    = " select  name from channelCatalog where catalogType in (0,2) and id = %d ", 

	sql_update_user_count    = " update checkSecretChannelInfo set userCount = userCount + 1  where idx = '%s' and number = '%s' and userCount > 0  " ,

	sql_invalid_userkey_info = " update userKeyInfo set validity = 0 , updateTime = unix_timestamp() where  actionType = 4 and customType = 10  and  accountID in ('%s')   ",

	sql_invalid_join_member_list = " update joinMemberList set actionType = actionType  ^  8 , updateTime = unix_timestamp() where actionType > 0 and accountID in ('%s') and number in ('%s') ",

	sql_get_all_region_channel = "select accountID from userKeyInfo where actionType = 4 and customType = 10 and validity = 1 %s and  customParameter in ( '%s' ) limit %d   ",

	sql_invalid_all_join_member_list = " update joinMemberList set actionType = actionType  ^  8 , updateTime = unix_timestamp() where actionType > 0 and accountID in ('%s')  ",

	sql_check_number_is_exit = "select idx,number,accountID,inviteUniqueCode from checkSecretChannelInfo where channelStatus = 1 and number in('%s')  ",

	sql_join_channel = " insert into joinMemberList(idx,number,accountID,uniqueCode,createTime,validity,talkStatus,role,actionType) " ..
						" values ('%s','%s','%s','%s',%d, 1 , 1 , 0 ,  0  )" ,

	sql_get_channel_user_userkeyinfo = " select accountID from userKeyInfo where  validity = 1 and actionType = 5 and customType = 10 and customParameter = '%s' order by accountID limit %d  " ,

	sql_check_user_is_setkey = " select accountID from userKeyInfo where validity = 1 and actionType = 5 and customType = 10 and accountID = '%s' and customParameter = '%s' " ,

	sql_select_secretChannel = " select idx,number from checkSecretChannelInfo where channelStatus = 1 and openType = 0 %s limit %d " ,
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-->chack parameter
local function check_parameter(args)

	if args['accountID'] and #args['accountID'] > 0  then
		---- app_utils.check_accountID(accountid)
		if not app_utils.check_accountID(args['accountID']) then
		 	gosay.go_false(url_tab,msg["MSG_ERROR_REQ_ARG"],'accountID')
    	end 
	end

	if not args['channelNumbers'] or #args['channelNumbers'] < 5 or string.find(args['channelNumbers'],"'" )  then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumbers')
	end

	safe.sign_check(args, url_tab)

end



--对accountID进行数据库校验
local function check_accountid(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status  then
		only.log('E', string.format('connect userlist_dbname failed! %s' , sql_str) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if not user_tab or #tostring(user_tab) == 0 then
		only.log('E',string.format("userList tab is empty %s",sql_str))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end
	if #user_tab >1 then 
		-----数据库存在错误,
		only.log('E','[***] userList accountID recordset > 1 ')
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	return true
end

local function get_catalogname( channel_catalogid ) 
	local sql_str = string.format(G.sql_get_catalog_name, tonumber(channel_catalogid ))
	local ok, tab = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not tab or type(tab) ~= "table" then
		only.log('E',string.format("get_catalogname failed %s ", sql_str ))
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	if #tab < 1  then
		return nil
	end
	return tab[1]['name']
end


---- 对名称名称设置对应的url 
local function channelname_2_voice( channel_name ,app_key )
	local tab = {
		appKey = app_key,
		text = channel_name,
	}
	tab['sign'] = app_utils.gen_sign(tab)
	tab['text'] = utils.url_encode(tab['text'])
	return appfun.txt2voice( txt2voice , tab)
end


local function get_channelname_url( channel_name, app_key )
	for i = 1 , 3 do
		local ok, channelnameurl  = channelname_2_voice( channel_name, app_key )
		if ok and channelnameurl then
			return ok, channelnameurl
		end
	end
	return false,''
end

local function check_repeat_apply( channel_num )

	---- 判断完全相同的
	local sql_str = string.format(G.sql_check_repeat_apply,channel_num )

	local ok , tab = mysql_api.cmd(channel_dbname,'select',sql_str)

	only.log('W', "sql_check_repeat_apply Debug %s ", sql_str ) 

	if not ok or not tab then
		only.log('E', "sql_check_repeat_apply failed %s ", sql_str ) 
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #tab >= 1 then
		only.log('W', "cur channel repeat apply [%s] ", sql_str ) 
		-- gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_REP_SUBMITTED'])
		return false
	end
	return true
end

local function get_next_channel_idx()
	local sql_str = G.sql_get_next_idx
	local ok, tab = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not tab or type(tab) ~= "table"  then
		only.log('E',string.format("sql_get_next_idx failed %s ", sql_str ))
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	if #tab == 0 then
		return  1
	end
	return (tonumber(tab[1]['count']) or 0)  + 1 
end

local function create_old_channel_to_secret_channel(channel_number, channel_name ,  open_type, is_verify)

	local accountid = "kxl1QuHKCD"
	local channel_intro = channel_name
	local channel_citycode = 0
	local channel_cityname = ""
	local channel_catalogid = "301021"

	local appkey = "4223273916"
	local channel_keyWords = ""
	local channel_logo_url = ""

	if not check_repeat_apply( channel_number ) then
		only.log('E',string.format("check_repeat_apply %s %s is exists " ,channel_number, channel_name ))
		return 2
	end

	local cur_time = ngx.time()

	local tmp_channelname = channel_name

	---- 群聊频道昵称转语音,转三次如果三次都失败则自动忽略
	local ok_status, ok_channelname_url = get_channelname_url( tmp_channelname , appkey )
	only.log('D',"channelNameURL:%s,ok_status:%s",ok_channelname_url,ok_status)
	if not ok_status or not ok_channelname_url or #ok_channelname_url < 1 then
		only.log('E',string.format(' channel_name:%s  txt2voice failed !' , tmp_channelname  ) )
	end


	local channel_catalogname = get_catalogname( channel_catalogid )
	if not channel_catalogname then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"channelCatalogID")
	end

	local channel_count = get_next_channel_idx()
	local channel_idx = string.format("%.9d",channel_count)

	if not channel_idx or not (#tostring(channel_idx) == 9 or  #tostring(channel_idx) == 10) then
		only.log('E', '[*****] new idx %s failed  accountid:%s  city_code:%s  ' , channel_idx, accountid, channel_citycode ) 
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	local channel_num = channel_number

	local sql_tab = {}
	local cur_uuid = utils.create_uuid()
	local uniquecode = string.format("%s|%s",channel_num,cur_uuid)

	----频道的类型 2 群聊频道
	local channelType = appfun.CHANNEL_TYPE_SECRET

	---- 检查用户是否申请过频道
	local sql_str = string.format(G.sql_select_userAdminInfo,accountid)
	local  ok , ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok  then
		only.log('E',"sql_select_userAdminInfo failed [%s]",sql_str)
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	---- 之前没申请过频道
	---- 将数据插入数据库中
	local sql_str = nil
	if #ret == 0 then
		sql_str = string.format(G.sql_insert_userAdminInfo,accountid,1,cur_time)
	else
		sql_str = string.format(G.sql_update_userAdminInfo,tonumber(ret[1]['create'])+1,cur_time,accountid)
	end
	table.insert(sql_tab,sql_str)

	---- 保存自动审核数据
	local sql_str = string.format(G.sql_finish_apply_channel, channel_idx , channel_num, 
															channel_name , channel_intro, 
															channel_citycode, channel_cityname,
															channel_catalogid, channel_catalogname,
															channel_logo_url ,open_type, 
															max_capacity, accountid, 
															cur_time,
															uniquecode,is_verify,
															channel_keyWords,
															ok_channelname_url)

	table.insert(sql_tab,sql_str)
	
	---- 保存频道至频道汇总表中
	local sql_str = string.format(G.sql_insert_userChannelList,channel_idx,channel_num,accountid,channelType,cur_time)
	table.insert(sql_tab,sql_str)

	---- 把创建者加入成员列表
	---- role  0普通成员  1创建者   2普通管理员 
	local sql_str = string.format(G.sql_join_channel_list,channel_idx,channel_num,uniquecode,accountid,cur_time,1)
	table.insert(sql_tab,sql_str)

	---- 更新用户总人数
	local sql_str = string.format(G.sql_update_user_count, channel_idx , channel_num )
	table.insert(sql_tab , sql_str)

	---- 把创建者加入成员列表(记录历史数据)
	local sql_str = string.format(G.sql_join_channelHistory,accountid,channel_num)
	table.insert(sql_tab,sql_str)

	only.log('D',string.format("debug----Exec sql %s ",  table.concat( sql_tab, "\r\n")  ) )

	local ok, ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
	if not ok then
		only.log('E',string.format(" user apply channel failed!  %s ", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end


	cur_utils.set_channel_idx_number( channel_num, 
												channel_idx , 
												accountid , 
												cur_time , 
												max_capacity , 
												channelType , 
												tostring(open_type),
												1,						---- check_status 
												channel_citycode,
												channel_cityname,
												channel_catalogid,
												channel_catalogname,
												channel_name,
												channel_intro,
												ok_channelname_url)

	return 1
end


local function get_old_channel_list(  )
	local sql_str = G.sql_get_channel_info
	local ok, tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or not tab then
		only.log('E',string.format(" get channel info failed, %s ", sql_str ))
		return false
	end

	if #tab < 1 then
		only.log('E',string.format(" get channel info succed but resut is empty, %s ", sql_str ))
		return false
	end

	for k ,v in pairs(tab) do
		local tmp_channel_num = v['customParameter']
		if utils.is_number(tmp_channel_num)  then
			local open_type = "0" 
			local is_verity = "1"
			local channel_name = "频道" .. appfun.number_to_chinese(tmp_channel_num)
			if #tmp_channel_num == 5 then
				---- 公开
				open_type = "1" 
				is_verity = "0"
				channel_name = "频道" .. appfun.number_to_chinese(tmp_channel_num)
			end

			local ok = create_old_channel_to_secret_channel(tmp_channel_num, channel_name , open_type, is_verity) 
			only.log('W',string.format(" channel_num:%s resut:%s " , tmp_channel_num,  ok ))
			tab[k]['status'] = ok 
		end
	end
	return tab
end


local function user_join_channel( appKey , accountid, channel_number )

	if not channel_number or #channel_number < 4 then
		return false
	end

	local sql_str = string.format( " select inviteUniqueCode from checkSecretChannelInfo where number = '%s' ", channel_number )

	only.log('E'," === enter user_join_channel %s  ", sql_str)

	local ok, tab = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not tab or type(tab) ~= "table" then
		only.log('E',string.format("***checkSecretChannelInfo failed %s ", sql_str ))
		return false
	end
	if #tab < 1  then
		only.log('E',string.format("***checkSecretChannelInfo succed, but result is empty ,%s ", sql_str ))
		return false
	end

	local tab = {
		appKey = appKey,
		accountID = string.gsub(accountid," ",""),
		uniqueCode = tab[1]['inviteUniqueCode'],
		remark = 'systemautojoin',
	}
	tab['sign'] = app_utils.gen_sign(tab)

	local body = utils.table_to_kv(tab)
	local post_data = 'POST /clientcustom/v2/joinSecretChannel HTTP/1.0\r\n' ..
	  'Host:%s:%s\r\n' ..
	  'Content-Length:%d\r\n' ..
	  'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

	local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
	local ok,ret = cutils.http(host_ip, host_port, req, #req)
	if ok and ret then
		local msg = string.match(ret,'{.+}')
		if msg then
			local ok,tab = pcall(cjson.decode,msg)
			if tab then
				if tab['ERRORCODE'] == "0" or tab['ERRORCODE'] == "ME18309" then
					return true
				end
			end
		end
	end

	only.log('E',string.format("---join failed, %s ", ret ))
	return false
end

---- 设置用户按键 
local function set_key_info (appKey , tmp_account_id, new_action_type , new_custom_type, new_custom_parameter )
	local tab = {
		appKey = appKey,
		accountID = tmp_account_id,
		parameter = string.format('{"count":"1","list": [{"actionType":"%s","customType":"%s","customParameter":"%s"}]}',
						new_action_type , new_custom_type, new_custom_parameter or '')
	}
	tab['sign'] = app_utils.gen_sign(tab)
	local body = utils.table_to_kv(tab)
	local post_data = 'POST /clientcustom/v2/setUserkeyInfo HTTP/1.0\r\n' ..
	  'Host:%s:%s\r\n' ..
	  'Content-Length:%d\r\n' ..
	  'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

	local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
	local ok,ret = cutils.http(host_ip, host_port, req, #req)
	if ok and ret then
		local msg = string.match(ret,'{.+}')
		if msg then
			local ok,tab = pcall(cjson.decode,msg)
			if tab then
				if tab['ERRORCODE'] == "0" then
					return true
				end
			end
		end
	end
	only.log('E',"setUserkeyInfo failed, %s ", ret )
	return false
end


local function get_userkey_list( appKey, accountid )
	local sql_filter = ""
	if accountid and #tostring(accountid) == 10 and app_utils.check_accountID(accountid) then
		sql_filter = string.format("  and accountID = '%s'  ", accountid )
	end

	local sql_str = string.format(G.sql_get_user_key_info, sql_filter, 1000 )
	local ok, tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or not tab then
		only.log('E',string.format(" get user key info failed, %s ", sql_str ))
		return false
	end

	if #tab < 1 then
		return true
	end

	for k , v in pairs(tab) do

		only.log('D',"======enter===== loop =====  "  )

		local tmp_account_id = v['accountID']
		local tmp_action_type = v['actionType']
		local tmp_custom_type = v['customType']
		local tmp_custom_parameter = v['customParameter']


		only.log('W',"****init**** [%s] [%s] [%s] [%s] init ==== ", tmp_account_id , tmp_action_type , tmp_custom_type , tmp_custom_parameter )

		if tonumber(tmp_custom_type) < 10 then

			local new_action_type = ""
			local new_custom_type = ""
			local new_custom_parameter = ""

			if tmp_action_type == "4" then
				if  tmp_custom_type == "5"  then
					---- 家人连线
					new_action_type = "3"
					new_custom_type = "12"
					new_custom_parameter = ""
				elseif  tmp_custom_type == "1" then
					---- 语音记事本
					new_action_type = "3"
					new_custom_type = "11"
					new_custom_parameter = ""
				elseif  tmp_custom_type == "2" then
					---- 群聊频道
					new_action_type = "4"
					new_custom_type = "10"
					new_custom_parameter = tmp_custom_parameter
				end
			elseif tmp_action_type == "5" then
				new_action_type = "5"
				new_custom_type = "10"
				new_custom_parameter = tmp_custom_parameter
			end

			if new_custom_parameter and #new_custom_parameter > 4 then
				local ok  = user_join_channel( appKey,  tmp_account_id, new_custom_parameter )
				if ok then
					local ok = set_key_info (appKey, tmp_account_id, new_action_type , new_custom_type, new_custom_parameter )
					if not ok then
						only.log('E',string.format("****ERROR****set_key_info accountid:%s actionType:%s  customType:%s customParameter %s failed", 
						tmp_account_id, tmp_action_type, tmp_custom_type, tmp_custom_parameter ))
						tab[k]['status'] = "2"
					else

						tab[k]['status'] = "3"

						only.log('W',"****init**** [%s] [%s] [%s] [%s] set keyinfo succed ", tmp_account_id , tmp_action_type , tmp_custom_type , tmp_custom_parameter )

					end
				else
					only.log('E',string.format("****ERROR****user_join_channel  accountid:%s  actionType:%s customType:%s customParameter %s failed", 
						tmp_account_id, tmp_action_type, tmp_custom_type, tmp_custom_parameter ))
					tab[k]['status'] = "1"
				end
			end

			if tmp_action_type == "4" and tmp_custom_type ~= "2"   then
				---- 放至地区频道 -->--- 10086 
				local channel_number = "10086"
				local ok, city_code = redis_api.cmd('private','get', tmp_account_id .. ":cityCode")
				if ok and city_code then
					local ok, city_channel = redis_api.cmd('private','hget', "cityCodeChannelInfo",  city_code .. ":cityCodeChannel")
					if ok and city_channel then
						channel_number = city_channel 
					end
				end

				only.log('W'," ==== auto repair== %s  %s  " , tmp_account_id , channel_number)

				new_action_type = tmp_action_type 
				new_custom_type = "10"
				new_custom_parameter = channel_number 

				local ok  = user_join_channel( appKey,  tmp_account_id, new_custom_parameter )
				if ok then
					local ok = set_key_info (appKey, tmp_account_id, new_action_type , new_custom_type, new_custom_parameter )
					if not ok then
						only.log('E',string.format("--auto repair--****ERROR****set_key_info accountid:%s actionType:%s  customType:%s customParameter %s failed", 
						tmp_account_id, tmp_action_type, tmp_custom_type, tmp_custom_parameter ))
						tab[k]['status'] = "2"
					else

						tab[k]['status'] = "3"

						only.log('W',"****init**** [%s] [%s] [%s] [%s] set keyinfo succed ", tmp_account_id , tmp_action_type , tmp_custom_type , tmp_custom_parameter )

					end
				else
					only.log('E',string.format("--auto repair--****ERROR****user_join_channel  accountid:%s  actionType:%s customType:%s customParameter %s failed", 
						tmp_account_id, tmp_action_type, tmp_custom_type, tmp_custom_parameter ))
					tab[k]['status'] = "1"
				end
			end
		end
	end
	return tab
end


local function  check_manage_join_msg(appKey , accountID , applyAccountID , checkStatus , checkRemark , idx )
	local tab = {
		appKey = appKey,
		applyIdx = idx,
		applyAccountID = applyAccountID,
		checkStatus = checkStatus,
		checkRemark = checkRemark,
		accountID = accountID,
	}

		tab['sign'] = app_utils.gen_sign(tab)
	local body = utils.table_to_kv(tab)
	local post_data = 'POST /clientcustom/v2/veritySecretChannelMessage HTTP/1.0\r\n' ..
	  'Host:%s:%s\r\n' ..
	  'Content-Length:%d\r\n' ..
	  'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

	local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
	local ok,ret = cutils.http(host_ip, host_port, req, #req)
	if ok and ret then
		local msg = string.match(ret,'{.+}')
		if msg then
			local ok,tab = pcall(cjson.decode,msg)
			if tab then
				if tab['ERRORCODE'] == "0" then
					return true
				end
			end
		end
	end
	return false
end

local function get_manager_msg( appKey, startPage , pageCount  )
	---- clientcustom/v2/secretChannelMessage

	local accountID   = "kxl1QuHKCD"
	local checkRemark = "systemautocheck"
	local checkStatus = 1 

	local tab = {
		appKey = appKey,
		status = "0", 	---- 未处理的消息
		startPage = startPage ,
		pageCount = pageCount ,
		accountID = accountID,
	}

	tab['sign'] = app_utils.gen_sign(tab)
	local body = utils.table_to_kv(tab)
	local post_data = 'POST /clientcustom/v2/secretChannelMessage HTTP/1.0\r\n' ..
	  'Host:%s:%s\r\n' ..
	  'Content-Length:%d\r\n' ..
	  'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

	local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
	local ok,ret = cutils.http(host_ip, host_port, req, #req)
	if ok and ret then
		local msg = string.match(ret,'{.+}')
		if msg then
			local ok,tab = pcall(cjson.decode,msg)
			if tab then
				if tab['ERRORCODE'] == "0" then

					local tab_info = tab['RESULT'] 
					local tab_list = tab_info['list']
					for k , v in pairs(tab_list) do
						local ok  = check_manage_join_msg( appKey, accountID , v['applyAccountID'] , checkStatus , checkRemark , v['idx'] )
						if not ok then
							only.log('E',"check_manage_join_msg failed-->-- accountID:%s applyAccountID:%s checkStatus:%s checkRemark:%s applyIdx:%s ",
									accountID , v['applyAccountID'] , checkStatus , checkRemark , v['idx']  )
							tab_list[k]['status'] = "0"
						else
							tab_list[k]['status'] = "1"
						end
					end
					only.log('W',"setUserkeyInfo auto check message succed " )
					return tab_list
				end
			end
		end
	end
	only.log('E',"setUserkeyInfo failed, %s ", ret )
	return false
end


local function user_join_secret_channel( accountid , action_type, custom_type , parameter , parameter_id  )

	local cur_time = os.time()
	if parameter and #tostring(parameter) >= 5 and #tostring(parameter_id) >= 9  then
		local sql_fmt = "select 1 from joinMemberList where idx = '%s' and number = '%s' and accountID ='%s' "
		local sql_str = string.format(sql_fmt,parameter_id,parameter,accountid)
		local ok,sql_ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
		if not ok or not sql_ret or type(sql_ret) ~= "table" then
			only.log('E',"1111 user_join_secret_channel get data mysql  failed, %s ",sql_str)
			return false
		end
		if #sql_ret  == 0 then
			local sql_fmt = "insert into joinMemberList(idx , number, uniqueCode , accountID, createTime) "..
		                                    " values( '%s', '%s', '%s', '%s', %d )"

			local sql_str = string.format(sql_fmt,parameter_id,parameter,'',accountid, cur_time)
			local ok,sql_ret = mysql_api.cmd(channel_dbname,'INSERT',sql_str)
			if not ok or not sql_ret then
				only.log('E',"2222 user_join_secret_channel set data  mysql  failed, %s ",sql_str)
				return false
			end
		end

		local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, parameter_id , channel_dbname )
		if not ok then
			only.log('E',string.format("user set channel info account_id: %s  actionType :%s customType: %s customPar:%s secretChannel:%s \r\n msg:%s \r\nsql:%s ",
								accountid,  action_type, custom_type , parameter, parameter_id , err_msg, err_sql))
			return false
		end
		return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter_id )
	else
		only.log('E',"usr_join_secret_channel failed,accountid:%s,actionType:%s,parameter:%s,parameter_id:%s",
			accountid,action_type,parameter,parameter_id)
	end
end
---- 20150701
---- bug:设置吐曹健，但插入了joinMemberList表中
local function set_main_voice( accountid , action_type, custom_type , parameter , parameter_id  )

    local ok, err_msg, err_sql = cur_utils.user_set_channel_info( accountid,  action_type, custom_type , parameter, parameter_id , channel_dbname )
    if not ok then
        only.log('E',string.format("user set channel info account_id: %s  actionType :%s customType: %s customPar:%s secretChannel:%s \r\n msg:%s \r\nsql:%s ",
                                        accountid,  action_type, custom_type , parameter, parameter_id , err_msg, err_sql))
        return false
    end
    return cur_utils.save_user_keyinfo_to_redis( accountid, action_type, custom_type, parameter_id )

end
---- end

local function get_custom_parameter_id( channel_number )
	local ok, ret = redis_api.cmd('private','get',channel_number .. ":channelID")
	if ok and ret and type(ret) == "string" then
		return ret
	end
	return nil
end

local function set_user_key_and_join_members( accountid , max_count )
	local sql_filter = ""
	if accountid and #tostring(accountid) == 10 and app_utils.check_accountID(accountid) then
		sql_filter = string.format("  and accountID = '%s'  ", accountid )
	end

	local sql_str = string.format(G.sql_get_user_key_info_by_accountid, sql_filter,  max_count )
	local ok, tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or not tab then
		only.log('E',string.format(" get user key info failed, %s ", sql_str ))
		return false
	end

	if #tab < 1 then
		return true
	end

	for k , v in pairs(tab) do

		only.log('D',"======enter===== loop =====  " )

		local tmp_account_id = v['accountID']
		local tmp_action_type = tonumber(v['actionType'])
		local tmp_custom_type = tonumber(v['customType'])
		local tmp_custom_parameter = v['customParameter']


		only.log('W',"****init**** [%s] [%s] [%s] [%s] init ==== ", tmp_account_id , tmp_action_type , tmp_custom_type , tmp_custom_parameter )

		if tonumber(tmp_custom_type) < 10 then

			local new_action_type = 0
			local new_custom_type = 0
			local new_custom_parameter = ""

			if tmp_action_type == 4 then
				if  tmp_custom_type == 5  then
					---- 家人连线
					new_action_type = 3
					new_custom_type = 12
					new_custom_parameter = ""
				elseif  tmp_custom_type == 1 then
					---- 语音记事本
					new_action_type = 3
					new_custom_type = 11
					new_custom_parameter = ""
				elseif  tmp_custom_type == 2 then
					---- 群聊频道
					new_action_type = 4
					new_custom_type = 10
					new_custom_parameter = tmp_custom_parameter
				end
			elseif tmp_action_type == 5 then
				new_action_type = 5
				new_custom_type = 10
				new_custom_parameter = tmp_custom_parameter
			end

			only.log('D',"****ready**** [%s] [%s] [%s] [%s] set keyinfo  ", tmp_account_id , new_action_type , new_custom_type , new_custom_parameter )

			if new_custom_parameter and #new_custom_parameter > 4 then
				local new_custom_parameter_id = get_custom_parameter_id(new_custom_parameter)
				if new_custom_parameter_id then
					local ok, ret, msg  = user_join_secret_channel( tmp_account_id , new_action_type, new_custom_type , new_custom_parameter , new_custom_parameter_id  )
					if ok then
						tab[k]['status'] = "3"
						only.log('D',"****init**** [%s] [%s] [%s] [%s] set keyinfo succed ", tmp_account_id , new_action_type, new_custom_type , new_custom_parameter )
					else
						only.log('E',string.format("111****ERROR****user_join_secret_channel  accountid:%s  actionType:%s customType:%s customParameter %s failed, ret:%s msg:%s", 
							tmp_account_id, new_action_type, new_custom_type , new_custom_parameter , ret, msg  ))
						tab[k]['status'] = "1"
					end
				else
					tab[k]['status'] = "2"

					only.log('E',string.format("222****ERROR****user_join_secret_channel  accountid:%s  actionType:%s customType:%s customParameter %s failed, ret:%s msg:%s", 
							tmp_account_id, new_action_type, new_custom_type , new_custom_parameter , ret, msg  ))

					only.log('E',string.format("222****ERROR****user_join_secret_channel  channel_num:%s get channel_idx failed " , new_custom_parameter))
				end
			end

			if tmp_action_type == 4 and tmp_custom_type ~= 2  then

				---- 设置用户吐槽按键 
				local ok, ret, msg  = set_main_voice( tmp_account_id , new_action_type, new_custom_type , new_custom_parameter , nil  )
				if ok then
					tab[k]['status'] = "3"
					only.log('D',"444****init**** [%s] [%s] [%s] [%s] set keyinfo succed ", tmp_account_id , new_action_type, new_custom_type , new_custom_parameter )
				else
					only.log('E',string.format("444****ERROR****user_join_secret_channel  accountid:%s  actionType:%s customType:%s customParameter %s failed, ret:%s msg:%s", 
						tmp_account_id, tmp_action_type, tmp_custom_type, tmp_custom_parameter , ret, msg  ))
					tab[k]['status'] = "1"
				end

				---- 同时设置用户+按键为频道

				---- 放至地区频道 -->--- 10086 
				local channel_number = "10086"
				local ok, city_code = redis_api.cmd('private','get', tmp_account_id .. ":cityCode")
				if ok and city_code then
					local ok, city_channel = redis_api.cmd('private','hget', "cityCodeChannelInfo",  city_code .. ":cityCodeChannel")
					if ok and city_channel then
						channel_number = city_channel 
					end
				end

				only.log('W'," ==== auto repair== %s  %s  " , tmp_account_id , channel_number)

				new_action_type = tmp_action_type 
				new_custom_type = "10"
				new_custom_parameter = channel_number 

				local new_custom_parameter_id = get_custom_parameter_id(new_custom_parameter)
				if new_custom_parameter_id then
					local ok, ret, msg  = user_join_secret_channel( tmp_account_id , new_action_type, new_custom_type , new_custom_parameter , new_custom_parameter_id  )
					if ok then
						tab[k]['status'] = "3"
						only.log('W',"333****init**** [%s] [%s] [%s] [%s] set keyinfo succed ", tmp_account_id , new_action_type, new_custom_type , new_custom_parameter )
					else
						only.log('E',string.format("333****ERROR****user_join_secret_channel  accountid:%s  actionType:%s customType:%s customParameter %s failed, ret:%s msg:%s", 
							tmp_account_id, new_action_type, new_custom_type , new_custom_parameter , ret, msg  ))
						tab[k]['status'] = "1"
					end
				else
					tab[k]['status'] = "2"

					only.log('E',string.format("333****ERROR****user_join_secret_channel  accountid:%s  actionType:%s customType:%s customParameter %s failed, ret:%s msg:%s", 
							tmp_account_id, new_action_type, new_custom_type , new_custom_parameter , ret, msg  ))

					only.log('E',string.format("333****ERROR****user_join_secret_channel  channel_num:%s get channel_idx failed " , new_custom_parameter))
				end

			end
		end
	end
	return tab
end


local function remove_voice_command_default( accountid , max_count )
	local sql_filter = ""
	if accountid and #tostring(accountid) == 10 and app_utils.check_accountID(accountid) then
		sql_filter = string.format("  and accountID = '%s'  ", accountid )
	end


	local error_region_channel_tab = {
		'010001','022001','021001','023001','031001','031901','031201','031401','031501','031701','031601',
		'031801','059101','059201','059801','059401','059501','059601','059901','059301','059701','079101',
		'079001','079201','070101','079301','079501','079401','079601','079701','053101','053201','053301',
		'053601','053501','063101','053701','063301','053401','035101','035201','035301','035501','034901',
		'035801','035701','035901','047501','047201','037101','037801','037901','037301','039301','037001',
		'037701','039401','024001','041101','041301','041401','041501','041601','041701','041801','041901',
		'041001','027001','072401','071901','071701','071401','071201','071301','071801','043101','042301',
		'043401','043701','043501','043901','043601','043301','044001','073101','073201','073401','073001',
		'073601','073501','073701','074501','074401','045901','045801','045601','020001','075501','075601',
		'075401','075101','075201','076901','076001','075701','075901','025001','051601','051701','052701',
		'051501','051401','051301','051101','051901','051001','051201','052001','077101','077201','077301',
		'077401','077901','077701','089801','089901','089001','028001','083801','081601','081301','083201',
		'083301','083001','083101','057101','057401','057301','057201','057501','057901','057001','058001',
		'057701','057601','085101','085201','085301','055101','055401','055201','055601','055901','055001',
		'055701','056501','087101','087001','087401','088801','087301','087801','029001','091901','091701',
		'091301','089101','093101','093501','093801','093301','093701','093702','097101','099801','095101',
		'031101','031301','033501','079801','097901','095201','095301','099501','090801','099601','045101',
		'045301','045401','051801',	'089201','081201','085801','055501','047101','047001','045201','099101',
		'099001','047901','048201'
	}

	local region_channel_str = table.concat( error_region_channel_tab, "', '")

	
	local sql_str = string.format(G.sql_get_all_region_channel, sql_filter ,  region_channel_str , max_count )

	only.log('D',"sql_get accountid : %s",sql_str)

	local ok, tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or not tab or type(tab) ~= "table" then
		only.log('E',string.format(" sql_get_all_region_channel failed, %s ", sql_str ))
		return false
	end
	if #tab < 1 then
		only.log('D',"accountid is empty")
		return true
	end

	local account_list = {}
	for k , v in pairs(tab) do
		redis_api.cmd('private','del',  v['accountID'] .. ":currentChannel:voiceCommand" )
		table.insert(account_list, v['accountID'])
	end

	local sql_tab = {}
	
	local sql_str = string.format(G.sql_invalid_userkey_info, table.concat( account_list, "', '")  )
	table.insert(sql_tab,sql_str)

	
	local sql_str = string.format(G.sql_invalid_join_member_list,  table.concat( account_list, "', '") , region_channel_str )
	table.insert(sql_tab,sql_str)

	local ok = mysql_api.cmd(channel_dbname,"AFFAIRS",sql_tab)
	if not ok then
		only.log('E',string.format(" update  info failed, %s ", table.concat( sql_tab, "\r\n") ))
		return false
	end
	only.log('D',string.format(" update info succed, %s ", table.concat( sql_tab, "\r\n") ))
	return account_list
end


local function remove_all_voice_command( accountid ,  channellist ,  max_count )

	only.log('D',"enter remove_all_voice_command accountid:%s  channel_list:%s , max_count:%s ",accountid ,  channellist ,  max_count)

	local sql_filter = ""
	if accountid and #tostring(accountid) == 10 and app_utils.check_accountID(accountid) then
		sql_filter = string.format("  and accountID = '%s'  ", accountid )
	end

	local channellist_tab = {} 
	if not channellist or #channellist == 0 then
		---- 不传表示10086
		table.insert(channellist_tab,"10086")
	else
		channellist_tab = utils.str_split(channellist,',')
	end

	local filter_channel_str = ""
	if channellist_tab and #channellist_tab > 0 then
		filter_channel_str =  table.concat( channellist_tab, "', '") 
	end


	local sql_str = string.format(G.sql_get_all_region_channel, sql_filter , filter_channel_str , max_count )

	only.log('D',"remove_all_voice_command sql_get accountid : %s",sql_str)

	local ok, tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or not tab or type(tab) ~= "table" then
		only.log('E',string.format(" sql_get_all_region_channel failed, %s ", sql_str ))
		return false
	end

	if #tab < 1 then
		only.log('D',"remove_all_voice_command accountid is empty")
		return true
	end

	local account_list = {}
	for k , v in pairs(tab) do
		redis_api.cmd('private','del',  v['accountID'] .. ":currentChannel:voiceCommand" )
		table.insert(account_list, v['accountID'])
	end

	local sql_tab = {}
	
	local sql_str = string.format(G.sql_invalid_userkey_info, table.concat( account_list, "', '")  )
	table.insert(sql_tab,sql_str)

	
	local sql_str = string.format(G.sql_invalid_all_join_member_list,  table.concat( account_list, "', '")  )
	table.insert(sql_tab,sql_str)


	only.log('D',string.format("remove_all_voice_command debug sql, %s ", table.concat( sql_tab, "\r\n") ))

	local ok = mysql_api.cmd(channel_dbname,"AFFAIRS",sql_tab)
	if not ok then
		only.log('E',string.format("remove_all_voice_command update  info failed, %s ", table.concat( sql_tab, "\r\n") ))
		return false
	end
	only.log('D',string.format("remove_all_voice_command update info succed, %s ", table.concat( sql_tab, "\r\n") ))
	return account_list
end

local function  setuserkeyinfo(accountid,actionType,customType,channel_number,channel_idx )
	
	local ok_val = cur_utils.save_user_keyinfo_to_redis(accountid, actionType, customType, channel_idx)
	if  ok_val then
		only.log('W',"setUserkeyInfo success,accountID:%s,actionType:%s,customType:%s,channel_number:%s,channel_idx:%s",
														accountid,actionType,customType,channel_number,channel_idx)
		return true
	else
		only.log('E',"save_user_custominfo_to_redis error accountid:%s,actionType:%s,customType:%s channel_number:%s  channel_idx:%s", 
																accountid, actionType, customType, channel_number,channel_idx)
	end

end


local function get_accountid_by_userkeyinfo(number , max_count )
	local sql_str = string.format(G.sql_get_channel_user_userkeyinfo,number,max_count )
	local ok , ret = mysql_api.cmd(channel_dbname,'select',sql_str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',"sql_get_channel_user_userkeyinfo failed,[%s]",sql_str)
		return false,false
	end
	if #ret == 0 then
		only.log('W',"sql_get_channel_user_userkeyinfo get empty,[%s]",sql_str)
		return false,false
	end
	return true,ret
end

local function check_user_is_setuserkey(number,accountID)
	local sql_str = string.format(G.sql_check_user_is_setkey,accountID,number)
	local ok,ret = mysql_api.cmd(channel_dbname,'select',sql_str)
	if not ok or not ret  then
		only.log('E',"check_user_is_setuserkey select mysql failed ,[%s]",sql_str)
		return false,false
	end
	if #ret == 0 then
		---- 没有设置++键，则当前用户不是异常数据
		only.log('W',"sql_check_user_is_setkey is empty,[%s]",sql_str)
		return false,false
	end
	return true, ret
end

local function resolve_channel_exception_data( accountID , numbers ,max_count )
	if accountID and #accountID > 0 then
		if not check_accountid(accountID) then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
		end
	end
	local number_list = utils.str_split(numbers,",")
	---- 过滤非法频道频道
	local sql_str = string.format(G.sql_check_number_is_exit,table.concat(number_list,"' , '"))
	only.log('D',"sql_check_number_is_exit:%s",sql_str)
	local ok , ret = mysql_api.cmd(channel_dbname,'select',sql_str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',"sql_check_number_is_exit failed,[%s]",sql_str)
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		only.log('E',"cur channel is not exists,[%s]",sql_str)
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumbers')
	end
	---- 1.检查用户的accountID
	---- 2.accountID 存在则检查用户是否加入频道
	---- 3.加入，设置按键
	---- 4.没加入，则先加入频道，再设置按键
	local tab = {}
	local ok = nil
	for k,v in pairs(ret) do
		if accountID and #accountID > 0 then
			---- accountID存在，检查是否设置++键
			ok,tab = check_user_is_setuserkey( v['number'] , accountID)
		else
			---- 通过userKeyInfo获取accountID
			ok,tab = get_accountid_by_userkeyinfo(v['number'] , max_count )
		end
		if ok and tab then
			for i,t in pairs (tab) do
				local ok = setuserkeyinfo(t['accountID'],5,10,v['number'],v['idx'])
				if not ok then
					only.log('E',"channel setUserkeyInfo failed,accountID:%s ,number:%s , idx:%s",
													t['accountID'],v['number'],v['idx'])
				end
			end
		end
	end
	return ret

end

local function resolve_modify_secretChannel_exception_data(channelNumbers,max_count)
	local ret = ""
	if channelNumbers and #channelNumbers > 0 then
		ret= string.format(" and number = %s ",channelNumbers)
	end
	local sql_str = string.format(G.sql_select_secretChannel,ret,max_count)
	only.log('D',"sql_select_secretChannel:%s " , sql_str)
	local ok , ret = mysql_api.cmd(channel_dbname,'select',sql_str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',"sql_select_secretChannel failed,[%s]",sql_str)
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		only.log('E',"get open_type=0 channel is empty,[%s]",sql_str)
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumbers')
	end
	for k,v in pairs(ret) do
		-- redis_api.cmd('private','get',channel_number .. ":channelID")
		local ok,channelStatus = redis_api.cmd('private','get',v['idx'] .. ":channelStatus")
		if not ok or not channelStatus then
			only.log('E',"get channelStatus failed,idx:%s ",v['idx'])
		end
		if ok and channelStatus and channelStatus == '0' then
			only.log('W',"exception idx:%s ,channelStatus:%s " ,v['idx'],channelStatus)
			redis_api.cmd('private','set',string.format("%s:channelStatus",v['idx']), 1)
		end
	end
	return ret

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
		---- 解析表单形式 
		args = utils.parse_url(req_body)
	end

	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	local ret = nil 
	---- 2015-05-26
	if args['isChannel'] == "1" then
		---- 原始频道迁移
		ret = get_old_channel_list()
	elseif args['isChannel'] == "2" then
		---- 用户按键设置迁移
		ret = get_userkey_list( args['appKey'] , args['accountID'])
	elseif args['isChannel'] == "3" then
		---- systemautojoin
		---- 自动审核申请加入的车队
		ret = get_manager_msg( args['appKey'] , args['startPage'] , args['pageCount']  )
	elseif args['isChannel'] == "4" then
		local max_count = tonumber(args['maxCount']) or 10
		ret = set_user_key_and_join_members(args['accountID'], max_count )
	elseif args['isChannel'] == "5" then
		---- 清理用户+按键频道(地区频道)
		local max_count = tonumber(args['maxCount']) or 10
		ret = remove_voice_command_default(args['accountID'], max_count )
	elseif args['isChannel'] == "6" then
		---- 清理用户+按键频道(用户定制任意频道)
		local max_count = tonumber(args['maxCount']) or 10
		ret = remove_all_voice_command(args['accountID'],  args['channelList'] ,  max_count )

	elseif args['isChannel'] == '7' then
		---- 解决频道异常数据
		check_parameter(args)
		local max_count = tonumber(args['maxCount']) or 10
		ret = resolve_channel_exception_data( args['accountID'], args['channelNumbers'], max_count)
	elseif args['isChannel'] == '8' then
		---- 清理频道channelStatus的异常数据
		local max_count = tonumber(args['maxCount']) or 10
		ret = resolve_modify_secretChannel_exception_data(args['channelNumber'],max_count)
	else 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"isChannel")
	end


	local count = 0
	local resut = ""
	if not ret or type(ret) ~= "table" or #ret == 0 then
		resut = "[]"
	else
		count = #ret 
		local ok, tmp_ret = pcall(cjson.encode,ret)
		if ok and tmp_ret then
			resut = tmp_ret
		end
	end
	local str = string.format('{"count":"%s","list":%s}',count,resut)
	if str then
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

safe.main_call( handle )
