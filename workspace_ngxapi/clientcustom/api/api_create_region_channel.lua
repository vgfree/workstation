--author:zhangerna
--用户申请群聊频道

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
local cur_utils = require('clientcustom_utils')
local appfun    = require('appfun')


local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname = "app_custom___wemecustom"

local txt2voice = link.OWN_DIED.http.txt2voice

---- 群里面最大用户数
local max_capacity = 5000

local G = {
	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID = '%s' limit 1",

	---- 检查重复申请
	sql_check_repeat_apply = "select 1 from checkSecretChannelInfo WHERE number ='%s'  ",

	---- 判断用户申请的频道个数是否达到最大限度,不能从useradmin中取，创建的次数有可能和当前创建的频道不一致
	sql_check_channel_count = "select count(1) as count from checkSecretChannelInfo where accountID = '%s' and channelStatus = 1 ",

	---- channelType = 1 地区频道
	---- channelType = 2 原始老频道数据 2015-05-25
	---- userCount       当前频道总人数
	---- 加入申请表中
	sql_finish_apply_channel = "insert into checkSecretChannelInfo(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName," .. 
							" logoURL,openType,capacity,accountID,createTime,inviteUniqueCode,isVerify,keyWords,channelNameURL,channelType,userCount)" ..
							" values ('%s','%s', '%s', '%s', %s, '%s', %s, '%s', " ..
							" '%s' , %s, %s, '%s', %d,'%s',%d ,'%s','%s',1,1) " , 

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

}


local url_tab = {
	type_name = 'system',
	app_key = '',
	client_host = '',
	client_body = '',
}

local function check_parameter(args)
	--频道所在地区，频道介绍，频道分类，频道副标题，关键字，频道logo（86*86 40*40两尺寸），是否公开（公开表示可以被搜索到），是否需要验证加入，频道状态，频道二维码
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab,msg["MSG_ERROR_REQ_ARG"],'accountID')
	end

	if args['accountID'] ~= "kxl1QuHKCD" then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	--频道名
	if not args['channelName'] then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelName')
	end

	local channel_number = args['channelNumber']
	if not channel_number or #tostring(channel_number) ~= 6 or not utils.is_number(channel_number) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
	end

	local channel_name = args['channelName']
	if app_utils.str_count(channel_name) < 2 or app_utils.str_count(channel_name) > 16 or (string.find(args['channelName'],"'"))  then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelName')
	end

	--频道简介
	if not args['channelIntroduction']  then
		gosay.go_false(url_tab,msg[' MSG_ERROR_REQ_ARG'],'channelIntroduction')
	end

	local channel_intro = args['channelIntroduction']
	if app_utils.str_count(channel_intro) < 1 or app_utils.str_count(channel_intro) > 128  or (string.find(args['channelIntroduction'],"'")) then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelIntroduction')
	end

	--是否需要验证 0不验证 1 验证
	if args['isVerify'] then
		if not tonumber(args['isVerify']) or not (args['isVerify'] == '0' or args['isVerify'] == '1') then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'isVerify')
		end
	end
	--频道所属城市
	if not args['channelCityCode'] or not utils.is_number(args['channelCityCode']) or string.find(args['channelCityCode'],"'") or #tostring(args['channelCityCode']) < 6 or #tostring(args['channelCityCode']) > 10 then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelCityCode')
	end

	--频道类型
	if not args['channelCatalogID'] or not utils.is_number(args['channelCatalogID']) or string.find(args['channelCatalogID'],"'")  or #tostring(args['channelCatalogID']) < 6 or #tostring(args['channelCatalogID'])  > 10 then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelCatalogID')
	end

	--  频道是否开放
	local open_type = args['openType']
	if open_type and #tostring(open_type) > 0  then
		if not (open_type == "0" or open_type == "1")  then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'openType')
		end
	end

	-- 审核频道关键字
	local keyWords = {}

	if args['channelKeyWords'] then 
		if string.find(args['channelKeyWords'],"'") then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
		end

		if #args['channelKeyWords'] > 0 then
			local tab = utils.str_split(args['channelKeyWords'],",")
			if #tab > 5 then
				only.log('D',"channelKeyWords:%s",args['channelKeyWords'])
				gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
			end

			for k , v in pairs(tab) do
				---- 1) 频道关键字,单个最大长度为8 2015-05-25 
				if app_utils.str_count( v ) > 8 then
					only.log('D',"channelKeyWords111111:%s",v)
					gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
				end
			end
		end
	end

	local err_status = false
	local logurl = args['channelCatalogUrl']
	if logurl and #logurl > 0 then
		if (string.find(logurl,"'")) or #logurl > 128 then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelCatalogUrl')
		end
		local tmp_logurl = string.lower(args['channelCatalogUrl'])
		if string.find(tmp_logurl,"http://") then
			local suffix = string.sub(tmp_logurl,-5)
			if suffix then
				if  ( (string.find(suffix,"%.png")) or (string.find(suffix,"%.jpg")) or 
					(string.find(suffix,"%.jpeg"))  or (string.find(suffix,"%.gif")) or 
					(string.find(suffix,"%.bmp"))  or (string.find(suffix,"%.ico")) ) then
					err_status = true
				end
			end
		end
	else
		err_status = true
	end
	if not err_status then
		only.log('E',string.format(" channelCatalogUrl is error, %s " , logurl ))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelCatalogUrl')
	end
	-- safe.sign_check(args, url_tab )
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
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


local tmp_appKey = "286302235"
local tmp_secret = "CD5ED55440C21DAF3133C322FEDE2B63D1E85949"


---- 对名称名称设置对应的url 
local function channelname_2_voice( channel_name ,app_key )
	local tab = {
		appKey = tmp_appKey,
		text = channel_name,
	}
	tab['sign'] = app_utils.gen_sign(tab,tmp_secret)
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

	if not ok or not tab or type(tab) ~= "table" then
		only.log('E', "sql_check_repeat_apply failed %s , %s ",  type(tab) , sql_str ) 
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #tab >= 1 then
		only.log('W', "cur channel repeat apply [%s] ", sql_str ) 
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_REP_SUBMITTED'])
	end
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

--去掉频道编号 自动生成
local function apply_user_region_channel( accountid, channel_name, channel_number,
														channel_intro, 
														channel_citycode, 
														channel_catalogid ,  
														open_type , 
													    channel_logo_url,
													    is_verify,
													    appkey,
													    channel_keyWords)

	check_repeat_apply( channel_number )

	local cur_time = ngx.time()

	local tmp_channelname = channel_name

	---- 群聊频道昵称转语音,转三次如果三次都失败则自动忽略
	local ok_status, ok_channelname_url = get_channelname_url( tmp_channelname , appkey )
	only.log('D',"channelNameURL:%s,ok_status:%s",ok_channelname_url,ok_status)
	if not ok_status or not ok_channelname_url or #ok_channelname_url < 1 then
		only.log('E',string.format(' channel_name:%s  txt2voice failed !' , tmp_channelname  ) )
	end

	local ok,channel_cityname = appfun.get_city_name_by_city_code ( channel_citycode )
	if not ok or not channel_cityname then
		only.log('E', "get_city_name_by_city_code failed %s : %s ", accountid, channel_citycode)  
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"channelCityCode")
	end

	if type(channel_cityname) == "table" then
		only.log('E', "channel_cityname is table get_city_name_by_city_code failed %s : %s ", accountid, channel_citycode)  
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"channelCityCode")
	end

	if #channel_cityname >= 32 then
		only.log('E', "channel_cityname is too long get_city_name_by_city_code failed %s : %s ", accountid, channel_citycode)  
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"channelCityCode")
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

	---- 把创建者加入成员列表(记录历史数据)
	local sql_str = string.format(G.sql_join_channelHistory,accountid,channel_num)
	table.insert(sql_tab,sql_str)

	only.log('D',string.format("debug----Exec sql %s ",  table.concat( sql_tab, "\r\n")  ) )

	local ok, ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
	if not ok then
		only.log('E',string.format(" user apply channel failed!  %s ", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end


	redis_api.cmd('private','hmset',	"cityCodeChannelInfo",
									channel_citycode .. ":cityCodeChannel",  channel_number ,
									channel_number .. ":channelCityCode",  channel_citycode )


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

	return true
end


local function  handle()

	local req_ip = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()

	local req_method = ngx.var.request_method
	url_tab['client_host'] = req_ip
	if not req_body then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'])
	end
	url_tab['client_body'] = req_body

	local args = nil
	if req_method == 'POST' then
		args = ngx.decode_args(req_body)
	end

	if not args then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"appKey")
	end

	url_tab['app_key'] = args['appKey']
	appkey = args['appKey']
	check_parameter(args)

	local accountid = args['accountID']
	check_accountid(accountid)

	local channel_name = args['channelName']
	local channel_intro = args['channelIntroduction']
	local channel_citycode = args['channelCityCode']
	local channel_keyWords = args['channelKeyWords'] or ''
	---- is_verify 1 验证 0 不验证
	local is_verify = tonumber(args['isVerify']) or 0 

	local open_type = tonumber(args['openType']) or 1
	local channel_catalog = args['channelCatalogID']
	local channel_logo_url = args['channelCatalogUrl'] or ''

	local channel_number = args['channelNumber']

	local ok = apply_user_region_channel( accountid,  
							channel_name, 
							channel_number,
							channel_intro, 
							channel_citycode, 
							channel_catalog , 
							open_type ,  
							channel_logo_url,
							is_verify,
							appkey,
							channel_keyWords)
	if ok then
		----SUCCED
		gosay.go_success(url_tab, msg['MSG_SUCCESS'])
	else
		----FAILED
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

safe.main_call( handle )
