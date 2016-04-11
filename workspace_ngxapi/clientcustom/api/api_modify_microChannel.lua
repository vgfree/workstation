---- zhangkai.
---- 2014-11-17
--修改微频道详细信息
----infoType=1 修改审核未通过的微频道
----infoType=2 修改审核通过的微频道
local ngx       = require('ngx')
local utils     = require('utils')
local app_utils     = require('app_utils')
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
local channel_dbname  = "app_custom___wemecustom"

local G = {
		--校验accountid是否合法
		sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 1 ",
		--检测频道是否被注册过
		sql_check_channel    = "SELECT  1 FROM userChannelList WHERE upper(number) = upper('%s') limit 1 ",
		--获取频道类别
		sql_get_cataloginfo = " SELECT name from channelCatalog WHERE  catalogType in(0,1) and  id = '%s' limit 1 ",
		--校验频道是否申请过，没申请过无法修改 infoType = 1
		--用于修改被驳回/未审核的微频道
		sql_check_number = "SELECT 1 from applyMicroChannelInfo WHERE number ='%s' and accountID = '%s' and checkStatus = 1  and id = %d limit 1 ",
		--是否重复提交相同的数据 infoType = 1
		sql_same_modify       = "SELECT 1 FROM applyMicroChannelInfoHistory WHERE accountID = '%s' and afterNumber = '%s' and afterName = '%s' and afterIntroduction = '%s' and afterCityCode = '%s' and afterCatalogID = '%s'  limit 1 ",
		--获取未审核通过的微频道的旧信息 infoType = 1
		sql_get_oldApplyInfo = " SELECT number ,name ,introduction ,cityCode ,cityName ,catalogID ,catalogName ,chiefAnnouncerIntr ,logoURL ,keyWords" ..
							" FROM  applyMicroChannelInfo WHERE accountID = '%s' and id = %d limit 1 " ,
		--更改频道状态
		--查看自己频道的状态 infoType = 1
		sql_update_channelsatus = " update applyMicroChannelInfo set  number = '%s',name = '%s' ,introduction = '%s' ,cityCode = %d ,cityName = '%s' ,catalogID = %d , " ..
							" catalogName = '%s' ,chiefAnnouncerIntr = '%s' ,logoURL = '%s' ,keyWords = '%s' , createTime  = '%s',checkStatus = 0 ,count = count + 1 " ..
							" WHERE accountID = '%s' and number = '%s' and id = %d limit 1 " ,
		-- --添加修改记录 infoType = 1
 
		sql_insert_modifyInfo = " insert into applyMicroChannelInfoHistory ( " ..
							 "beforeNumber,beforeName ,beforeIntroduction ,beforeCityCode ,beforeCityName ,beforeCatalogID ,beforeCatalogName ,beforeChiefAnnouncerIntr,beforeLogoURL, beforeKeyWords , " .. 
							" accountID,updateTime ," ..
							" afterNumber,afterName ,afterIntroduction ,afterCityCode ,afterCityName ,afterCatalogID ,afterCatalogName ,afterChiefAnnouncerIntr,afterLogoURL ,afterKeyWords  ) " ..
							" SELECT   " ..
							" number,name,introduction,cityCode,cityName,catalogID,catalogName,chiefAnnouncerIntr,logoURL ,keyWords, accountID , " ..
							" '%s' as updateTime ,'%s' as afterNumber ,'%s' as afterName , '%s' as afterIntroduction , '%s' as afterCityCode ,'%s' as afterCityName ,  " ..
							" '%s' as afterCatalogID ,'%s' as afterCatalogName ,'%s' as afterChiefAnnouncerIntr ,'%s' as afterLogoURL ,'%s' as afterKeyWords " ..
							" from  applyMicroChannelInfo WHERE  accountID = '%s' and number = '%s' limit 1 " ,

		--获取已审核通过的微频道的旧信息 infoType = 2
		sql_get_oldCheckInfo = " SELECT number ,name ,introduction ,cityCode ,cityName ,catalogID ,catalogName ,chiefAnnouncerIntr ,logoURL ,channelNameURL ,inviteUniqueCode ,keyWords  " ..
						  " FROM checkMicroChannelInfo WHERE accountID = '%s' and idx = '%s' limit 1 ",	

		--校验频道是否申请成功过，没申请成功过无法修改,infoType = 2
		--用于修改审核通过的微频道
		sql_check_numberpassed = " SELECT idx from userChannelList WHERE number ='%s' and accountID = '%s' and channelType = 1 and idx = '%s' limit 1 ",	
		--检验有无频繁修改 
		sql_check_modifyStatus = " SELECT 1 FROM modifyMicroChannelInfo where idx = '%s' and channelStatus = 2 limit 1 ",
		--更改频道状态
		--查看自己频道的状态 infoType = 2
		sql_update_pass_channelstatus = " update checkMicroChannelInfo  set channelStatus = 2 , updateTime = '%s' WHERE accountID = '%s' and number = '%s'  and idx = '%s' limit 1 " ,
		
		----添加修改记录(备份) infoType = 2
		sql_insert_check_modifyInfo = " insert into modifyMicroChannelInfo(idx ,number ,name ,introduction ,cityCode ,cityName ,catalogID ,catalogName ," ..
							" chiefAnnouncerIntr ,logoURL , channelNameURL ,inviteUniqueCode ,createTime ,channelStatus ,accountID,keyWords )  " .. 
							" values( '%s','%s','%s','%s','%s','%s', "  ..
							" '%s','%s','%s','%s','%s','%s','%s',%s ,'%s','%s' )  " ,
	}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

local function check_parameter(args)
	if not args['accountID'] or not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if string.find(args['accountID'] ,"'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end
	if not args['infoType'] or #tostring(args['infoType']) > 1 or not (tonumber(args['infoType']) == 1 or tonumber(args['infoType']) == 2)  then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
	end

	---- infoType == 1
	if tonumber(args['infoType']) == 1 then
		if args['channelNumber'] and #args['channelNumber'] > 0 then
			local after_channelNumber = args['channelNumber']
			if #tostring(after_channelNumber) < 5 or  #tostring(after_channelNumber) > 16 or not utils.is_variable_syntax(after_channelNumber) then
				only.log('E',string.format(" after_channelNumber:%s is error", after_channelNumber ))
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
			end
		end
		if not args['applyIdx'] then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
		end
		if not utils.is_number(args['applyIdx']) or string.find(args['applyIdx'],'%.') or #tostring(args['applyIdx']) > 5 then
			only.log('D',args['applyIdx'])
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
		end
	end
	---- 以下参数通用
	---- befornumber
	-- 频道编号
	local before_channelNumber = args['beforeChannelNumber']
	if not before_channelNumber or #tostring(before_channelNumber) < 5 or  #tostring(before_channelNumber) > 16 or not utils.is_variable_syntax(before_channelNumber) then
		only.log('E',string.format(" before_channelNumber:%s is error", before_channelNumber ))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'beforeChannelNumber')
	end

	---- 频道名称
	if args['channelName'] and #args['channelName'] > 0 then
		if string.find(args['channelName'] ,"'") then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
		end

		local channel_name = args['channelName'] 
		if app_utils.str_count(channel_name) < 2 or app_utils.str_count(channel_name) > 16  then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
		end
	end
	
	---- 频道简介
	if args['channelIntroduction'] and #args['channelIntroduction'] > 0 then
		if string.find(args['channelIntroduction'] ,"'") then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelIntroduction')
		end
		local channel_intro = args['channelIntroduction'] 
		if app_utils.str_count(channel_intro) < 1 or app_utils.str_count(channel_intro) > 128  then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelIntroduction')
		end
	end

	---- 频道所属城市
	if  args['channelCityCode'] and #args['channelCityCode'] > 0 then
		if not utils.is_number(args['channelCityCode']) or #tostring(args['channelCityCode']) < 6 or #tostring(args['channelCityCode']) > 10 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelCityCode')
		end
	end
	---- 检查频道关键字
	if args['channelKeyWords'] and #tostring(args['channelKeyWords']) > 0 then
		if string.find(args['channelKeyWords'],"'") then
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
		end

		if #args['channelKeyWords'] > 0 then
			local tab = utils.str_split(args['channelKeyWords'],",")
			if #tab > 5 then
				gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
			end

			for k , v in pairs(tab) do
				---- 1) 频道关键字,单个最大长度为8 2015-05-25 
				if app_utils.str_count( v ) > 8 then
					gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
				end
			end
		end
	end


	---- 频道所属类型
	if  args['channelCatalogID'] and #args['channelCatalogID'] > 0 then
		if not utils.is_number(args['channelCatalogID']) or #tostring(args['channelCatalogID']) < 6 or #tostring(args['channelCatalogID']) > 10 then 
			only.log('E',string.format("channelCatalogID :%s ",args['channelCatalogID']))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelCatalogID')
		end
	end

	---- 主播简介
	local chief_announcer_intr = args['chiefAnnouncerIntr']
	if chief_announcer_intr and #chief_announcer_intr > 0 then
		if string.find(args['chiefAnnouncerIntr'] ,"'") then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'chiefAnnouncerIntr')
		end
		if app_utils.str_count(chief_announcer_intr) < 1 or app_utils.str_count(chief_announcer_intr) > 128  then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'chiefAnnouncerIntr')
		end
	end

	local err_status = false
	local logurl = args['channelCatalogUrl']
	if logurl and #logurl > 0 then
		if string.find(logurl ,"'" ) or #logurl > 128 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelCatalogUrl')
		end
		local tmp_logurl = string.lower(args['channelCatalogUrl'])
		if (string.find(tmp_logurl,"http://")) == 1 then
			local suffix = string.sub(tmp_logurl,-5)
			if suffix then
				if  (string.find(suffix,"%.png")) or (string.find(suffix,"%.jpg")) or 
					(string.find(suffix,"%.jpeg"))  or (string.find(suffix,"%.gif")) or 
					(string.find(suffix,"%.bmp"))  or (string.find(suffix,"%.ico"))  then
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
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

local function check_accountid( accountid )
	---- 1 检查当前的accountid是否合法
	local sql_str = string.format(G.sql_check_accountid ,accountid)
	local ok,ret = mysql_api.cmd(userlist_dbname ,'SELECT', sql_str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',string.format('accountid:%s',accountid))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret == 0 then
		only.log('E',sql_str)
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end	
end

local function get_catalogname_and_cityname( channel_catalogid ,channel_citycode )
	---- 5 获取频道类别
	----
	local sql_str = string.format(G.sql_get_cataloginfo ,channel_catalogid)
	local ok,ret = mysql_api.cmd(channel_dbname ,'SELECT' , sql_str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',string.format('get catalog info failed!  %s ',sql_str) )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then 
		only.log('E',string.format('get catalog info failed!  %s ',sql_str) )
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'catalogID')
	end
	channel_catalogname = ret[1]['name']
	---- 6 获取城市名称
	----
	local ok,channel_cityname = appfun.get_city_name_by_city_code ( channel_citycode )
	if not ok then
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	if not channel_cityname then 
		only.log('E',string.format(" channel_citycode:  %s  get city name failed ", channel_citycode))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'cityCode')
	end
	return channel_catalogname ,channel_cityname
end
----修改初审被驳回的微频道
local function modify_rejected_microchannel( accountid,
													before_channelNumber, 
													channel_number,
													channel_name,
													channel_intro,
													channel_citycode,
													channel_catalogid,
													channel_logoURL,
													channel_chiefintr,
													idx,channel_keysWords)
	---- 1 检查当前number是否是驳回的 infoType = 1
	idx = tonumber(idx)	  ----idx  当前idx对应数据库的id 2014-12-19 jiang z.s. 
	local sql_str = string.format(G.sql_check_number,before_channelNumber ,accountid ,idx)
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret then
		only.log('E',string.format('do failed in sql_str:%s ',sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		only.log('E',string.format("cur_channelnumber: %s is not apply or reject !",before_channelNumber))
		only.log('E',string.format('do failed in sql_str:%s ',sql_str))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"channelNumber")
	end	
	---- 2 检查当前的channelNumber是否已经被审核通过了 infoType = 1 
	local sql_str = string.format(G.sql_check_channel,channel_number)
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table"  then 
		only.log('E',string.format('channel_number:%s',channel_number))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret ~= 0 then
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_EXISTS'])
	end
	---- 3.对比修改前后的信息
	local sql_str = string.format(G.sql_get_oldApplyInfo ,accountid,idx)
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret then
		only.log('E',sql_str)
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret ~= 1 then 
		only.log('E',string.format('accountid:%s,idx:%s',accountid,idx))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end	
	local channel_name_tmp,channel_intro_tmp,channel_citycode_tmp = nil
	local channel_catalogid_tmp,channel_logoURL_tmp,channel_chiefintr_tmp ,channel_keysWords_tmp = nil
	if channel_name and #channel_name > 0 then
		channel_name_tmp = channel_name
	end
	if channel_intro and #channel_intro > 0 then
		channel_intro_tmp = channel_intro
	end
	if tonumber(channel_citycode) then
		channel_citycode_tmp = channel_citycode
	end
	if tonumber(channel_catalogid) then
		channel_catalogid_tmp = channel_catalogid
	end
	if channel_logoURL and #channel_logoURL > 0 then
		channel_logoURL_tmp = channel_logoURL
	end
	if channel_chiefintr and #channel_chiefintr > 0 then
		channel_chiefintr_tmp = channel_chiefintr
	end
	if channel_keysWords and #channel_keysWords > 0 then
		channel_keysWords_tmp = channel_keysWords
	end

	-- channel_number = ret[1]['number']
	channel_name = channel_name_tmp or ret[1]['name']
	channel_intro = channel_intro_tmp or ret[1]['introduction']
	channel_citycode = channel_citycode_tmp or ret[1]['cityCode']
	channel_catalogid = channel_catalogid_tmp or ret[1]['catalogID']
	channel_logoURL = channel_logoURL_tmp or ret[1]['logoURL']
	channel_chiefintr = channel_chiefintr_tmp or ret[1]['chiefAnnouncerIntr']
	channel_inviteUniqueCode =  ret[1]['inviteUniqueCode']
	channel_keysWords = channel_keysWords_tmp or ret[1]['keyWords']
	local channel_catalogname ,channel_cityname = get_catalogname_and_cityname( channel_catalogid ,channel_citycode )
	---- 4 检查是否存在相同的修改记录 , 重复提交返回提示
	local sql_str = string.format(G.sql_same_modify, accountid,channel_number ,channel_name ,channel_intro ,channel_citycode ,channel_catalogid )
	local ok ,tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or  not tab then
		only.log('E',string.format("check same apply accountid:%s channel_number:%s  failed \r\n  %s" ,accountid ,channel_number , sql_str ))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #tab > 0 then
		only.log('E',sql_str)
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_REP_SUBMITTED'])
	end

	local sql_tab = {}
	local updateTime = ngx.time()
	local sql_str = string.format(G.sql_insert_modifyInfo ,
							updateTime ,
							channel_number ,
							channel_name ,
							channel_intro ,
							channel_citycode ,
							channel_cityname ,
							channel_catalogid ,
							channel_catalogname,
							channel_chiefintr,
							channel_logoURL,
							channel_keysWords,
							accountid,
							before_channelNumber,
							idx)   

	table.insert(sql_tab, sql_str)


	local sql_str = string.format(G.sql_update_channelsatus ,
							channel_number ,
							channel_name ,
							channel_intro ,
							channel_citycode ,
							channel_cityname ,
							channel_catalogid,
							channel_catalogname ,
							channel_chiefintr ,
							channel_logoURL ,
							channel_keysWords,
							updateTime ,
							accountid ,
							before_channelNumber,
							idx)

	table.insert(sql_tab,sql_str)	
	
	only.log('D',string.format("[debug] sql_tab:  %s",table.concat( sql_tab, "\r\n") ) )

	local ok,ret  = mysql_api.cmd(channel_dbname,"AFFAIRS",sql_tab)
	if not ok then
		only.log('E',string.format("modify channel failed!  %s ", table.concat( sql_tab, "\r\n")))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	return true
end


----修改审核通过的微频道
local function modify_checked_microchannel( accountid,before_channelNumber,channel_name,channel_intro,
													channel_citycode,channel_catalogid,
													channel_logoURL,channel_chiefintr ,channel_keysWords)
	-- channel_number = before_channelNumber
	local ok,idx = redis_api.cmd('private','get',string.format("%s:channelID",before_channelNumber))
	if not ok then 
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end	
	if not idx then
		only.log('E',"channelNumber:%s",before_channelNumber)
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"channelNumber")
	end

	local sql_str = string.format(G.sql_get_oldCheckInfo ,accountid,idx)
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret then
		only.log('E',sql_str)
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret ~= 1 then
		only.log('E',string.format('accountid:%s,idx:%s, sql_str:%s ',accountid,idx , sql_str))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"accountID")
	end

	local channel_name_url = ''
	if not channel_name or tostring(channel_name) == ret[1]['name'] then
		---- 1) 没有修改名称
		---- 2) 修改的名称与数据库的一致
		channel_name_url =  ret[1]['channelNameURL']
	end
	local channel_name_tmp,channel_intro_tmp,channel_citycode_tmp = nil
	local channel_catalogid_tmp,channel_logoURL_tmp,channel_chiefintr_tmp ,channel_keysWords_tmp = nil
	if channel_name and #channel_name > 0 then
		channel_name_tmp = channel_name
	end
	if channel_intro and #channel_intro > 0 then
		channel_intro_tmp = channel_intro
	end
	if tonumber(channel_citycode) then
		channel_citycode_tmp = channel_citycode
	end
	if tonumber(channel_catalogid) then
		channel_catalogid_tmp = channel_catalogid
	end
	if channel_logoURL and #channel_logoURL > 0 then
		channel_logoURL_tmp = channel_logoURL
	end
	if channel_chiefintr and #channel_chiefintr > 0 then
		channel_chiefintr_tmp = channel_chiefintr
	end
	if channel_keysWords and #channel_keysWords > 0 then
		channel_keysWords_tmp = channel_keysWords
	end
	channel_name = channel_name_tmp or ret[1]['name']
	channel_intro = channel_intro_tmp or ret[1]['introduction']
	channel_citycode = channel_citycode_tmp or ret[1]['cityCode']
	channel_catalogid = channel_catalogid_tmp or ret[1]['catalogID']
	channel_logoURL = channel_logoURL_tmp or ret[1]['logoURL']
	channel_chiefintr = channel_chiefintr_tmp or ret[1]['chiefAnnouncerIntr']
	channel_inviteUniqueCode =  ret[1]['inviteUniqueCode']
	channel_keysWords = channel_keysWords_tmp or ret[1]['keyWords']
	local channel_catalogname ,channel_cityname = get_catalogname_and_cityname( channel_catalogid ,channel_citycode )
	---- 4 检查是否存在相同的修改记录 , 重复提交返回提示
	local sql_str = string.format(G.sql_check_modifyStatus ,idx)
	local ok ,ret = mysql_api.cmd(channel_dbname ,'SELECT',sql_str)
	if not ok or not ret then 
		only.log('E',sql_str)
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #ret > 0 then 
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_REP_SUBMITTED'])
	end

	---- 3 检查当前number是否是审核通过的 infoType = 2
	local sql_str = string.format(G.sql_check_numberpassed , before_channelNumber , accountid ,idx )
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret then
		only.log('E',string.format('do failed in sql_str:%s ',sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		only.log('E',string.format("cur_channelnumber: %s is not passed ! sql_str %s",before_channelNumber , sql_str) )
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"channelNumber")
	end

	local cur_channel_id = ret[1]['idx']
	if not cur_channel_id or #tostring(cur_channel_id) < 9 then
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"channelNumber")
	end

	local sql_tab = {}
	local updateTime = ngx.time()

	local sql_str = string.format(G.sql_update_pass_channelstatus, updateTime , accountid , before_channelNumber, idx )
	table.insert(sql_tab,sql_str)
	local sql_str = string.format(G.sql_insert_check_modifyInfo,
							cur_channel_id ,
							before_channelNumber,
							channel_name ,
							channel_intro,
							channel_citycode,
							channel_cityname,
							channel_catalogid,
							channel_catalogname,
							channel_chiefintr,
							channel_logoURL,
							channel_name_url ,
							channel_inviteUniqueCode,
							updateTime,
							2 ,
							accountid,
							channel_keysWords
							)

	table.insert(sql_tab,sql_str)

	local ok = mysql_api.cmd(channel_dbname,"AFFAIRS",sql_tab)
	if not ok then
		only.log('E',string.format("modify channel failed!  %s ", table.concat( sql_tab, "\r\n")))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	local ok = redis_api.cmd('private','set',string.format("%s:channelStatus", cur_channel_id ), 2)
	if not ok then
		only.log('E',string.format("idx:%s",cur_channel_id))
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end	
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

	url_tab['app_key'] = tonumber(args['appKey'])

	check_parameter(args)
	local accountid  = args['accountID']	
	local before_channelNumber = args['beforeChannelNumber'] 	
	local channel_name     = args['channelName']
	local channel_intro    = args['channelIntroduction'] 
	local channel_citycode = tonumber(args['channelCityCode']) 
	local channel_catalogid  = tonumber(args['channelCatalogID']) 
	local channel_logoURL = args['channelCatalogUrl'] 	
	local channel_chiefintr = args['chiefAnnouncerIntr']
	local channel_keysWords = args['channelKeyWords']
	local infoType = tonumber(args['infoType']) or 0

	local channel_number ,idx = nil ,nil
	if infoType == 1 then	
		channel_number = args['channelNumber']
		idx = tonumber(args['applyIdx'])		
	end

	check_accountid(accountid)
	local ok = nil
	if infoType == 1 then
		---- 修改被驳回的数据
		ok = modify_rejected_microchannel(accountid,
											before_channelNumber , 
											channel_number ,
											channel_name,
											channel_intro,
											channel_citycode,
											channel_catalogid,
											channel_logoURL,
											channel_chiefintr, 
											idx,channel_keysWords)
	elseif infoType == 2 then
		---- 修改已经成功审核的数据
		ok = modify_checked_microchannel(accountid,
										before_channelNumber,
										channel_name,
										channel_intro,
										channel_citycode,
										channel_catalogid,
										channel_logoURL,
										channel_chiefintr,
										channel_keysWords )
	end
	if ok then
		gosay.go_success(url_tab, msg['MSG_SUCCESS'])
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
