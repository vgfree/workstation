--owner:jiang z.s. 
---- 用户申请微频道

local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local appfun    = require('appfun')
local cur_utils = require('clientcustom_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')


local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
		---- 判断用户是否有效	
	sql_check_accountid  = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ",

	---- 判断channel number是否已经被占用
	sql_check_channel    = "SELECT  1 FROM userChannelList WHERE upper(number) = upper('%s')  limit 1",

	---- 判断是否重复提交多次
	sql_same_apply       = "SELECT number FROM applyMicroChannelInfo WHERE accountID = '%s' and number = '%s' and name ='%s' and introduction = '%s' and keyWords = '%s' limit 1",

	---- 判断类型名称是否存在
	sql_get_cataloginfo  = "SELECT name from channelCatalog WHERE catalogType in(0,1) and id =  %s limit 1 ",

	---- 限制最多申请3个微频道
	sql_count_apply_num  = "SELECT count(1) as count from  applyMicroChannelInfo WHERE accountID = '%s' " , 

	---- 保存申请成功的数据
	sql_insert_applyInfo = " insert into applyMicroChannelInfo(number,name,introduction,cityCode,cityName,catalogID,catalogName," ..
							" chiefAnnouncerIntr,logoURL,accountID,createTime,keyWords) " .. 
							" values('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}


-->chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID']) or  string.find(args['accountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if not args['channelNumber'] or  string.find(args['channelNumber'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end

	-- 频道编号
	local channel_num = args['channelNumber']
	if #tostring(channel_num) < 5 or  #tostring(channel_num) > 16  or not utils.is_variable_syntax(channel_num) or  string.find(channel_num ,"'" )then
		only.log('E',string.format(" channel_number:%s is error", channel_num ))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end

	---- 频道名称
	if not args['channelName'] or  string.find(args['channelName'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
	end
	local channel_name = args['channelName'] 
	if app_utils.str_count(channel_name) < 2 or app_utils.str_count(channel_name) > 16 or  string.find(channel_name ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
	end

	---- 频道简介
	if not args['channelIntroduction'] or  string.find(args['channelIntroduction'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelIntroduction')
	end
	local channel_intro = args['channelIntroduction'] 
	if app_utils.str_count(channel_intro) < 1 or app_utils.str_count(channel_intro) > 128 or  string.find(channel_intro ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelIntroduction')
	end

	---- 频道所属城市
	if not args['channelCityCode'] or not utils.is_number(args['channelCityCode']) or #tostring(args['channelCityCode'])<6 or #tostring(args['channelCityCode'])>10 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelCityCode')
	end

	---- 频道所属类型
	if not args['channelCatalogID'] or not utils.is_number(args['channelCatalogID']) or #tostring(args['channelCatalogID']) < 6 or #tostring(args['channelCatalogID']) > 10 then
		only.log('E',string.format("channelCatalogID :%s ",args['channelCatalogID']))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelCatalogID')
	end

	---- 主播简介
	local chief_announcer_intr = args['chiefAnnouncerIntr']
	if not chief_announcer_intr or  string.find(chief_announcer_intr ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'chiefAnnouncerIntr')
	end

	if app_utils.str_count(chief_announcer_intr) < 5 or app_utils.str_count(chief_announcer_intr) > 128  then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'chiefAnnouncerIntr')
	end
	---- 检查keyWords
	if args['channelKeyWords'] then 
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

	local err_status = false
	local logurl = args['channelCatalogUrl']
	if logurl then
		if string.find(logurl ,"'" ) or #logurl > 128 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelCatalogUrl')
		end
		local tmp_logurl = string.lower(args['channelCatalogUrl'])
		if (string.find(tmp_logurl,"http://")) == 1 then
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

	---- safe.sign_check(args, url_tab )
	---- 20150720
	---- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

---- 对accountID进行数据库校验
local function check_userinfo(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status or not user_tab  then
		only.log('E',string.format('connect userlist_dbname failed!  %s ',sql_str) )
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

local function get_catalogname( channel_catalogid )
	local sql_str = string.format(G.sql_get_cataloginfo ,channel_catalogid)
	local ok,ret = mysql_api.cmd(channel_dbname ,'SELECT' , sql_str)
	if not ok or not ret or type(ret) ~= "table" then
		only.log('E',string.format(' 1 get catalog info failed!  %s ',sql_str) )
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then 
		only.log('E',string.format(' 2 get catalog info failed!  %s ',sql_str) )
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelCatalogID')
	end
	return ret[1]['name']
end

---- 用户申请微频道 2014-11-10 
local function apply_micro_channel( accountid,
									 channel_num,
									 channel_name,
									 channel_intro,
									 channel_citycode,
									 channel_catalogid,
									 channel_logoURL,
									 channel_chiefintr,
									 channel_keyWords )
	---- applyMicroChannelInfo          
	---- 1 检查当前的channel_num是否已经被审核通过了, [ userChannelList ]
	----		MSG_ERROR_USER_CHANNEL_EXISTS
	local sql_str = string.format(G.sql_check_channel,channel_num)
	local ok ,ret = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if  not ok or not ret then
		only.log('E',string.format("get check channel :%s " , sql_str ))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 1 then 
		only.log('E',string.format(" accountid:%s channel_num:%s ", accountid , channel_num ) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_EXISTS'])
	end

	---- 2 简单当前 accountid 名下, channel_num ,以及频道名称, 频道简介, 是否存在相同的申请记录( 申请的 ) , 则视为重复提交,返回提示
	----		MSG_ERROR_USER_CHANNEL_REP_SUBMITTED
	local sql_str = string.format(G.sql_same_apply, accountid, channel_num ,channel_name ,channel_intro,channel_keyWords)
	local ok ,tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or  not tab then
		only.log('E',string.format("check same apply accountid:%s channel_num:%s  failed \r\n  %s" ,accountid ,channel_num , sql_str ))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #tab == 1 then
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_REP_SUBMITTED'])
	end

	---- 3  校验都成功, 则插入表applyMicroChannelInfo
	----		MSG_SUCCESS
	local ok,channel_cityname = appfun.get_city_name_by_city_code ( channel_citycode )
	if not ok or not channel_cityname then
		only.log('E',string.format(" channel_citycode:  %s  get city name failed ", channel_citycode))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'cityCode')
	end

	local channel_catalogname = get_catalogname( channel_catalogid )
	local createtime = ngx.time()

	local sql_str = string.format(G.sql_count_apply_num,accountid)
	local ok, ret_tab = mysql_api.cmd(channel_dbname,"SELECT",sql_str)
	if not ok or not ret_tab then
		only.log('E',string.format("do failed in %s ",sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end 

	if #ret_tab > 0  and tonumber(ret_tab[1]['count']) >= 3 then
		only.log('E',string.format("user apply count > 3  %s ",sql_str))
		gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_MAX_COUNT'])
	end	

	local sql_str = string.format(G.sql_insert_applyInfo,
									channel_num,
									channel_name ,
									channel_intro ,
									channel_citycode ,
									channel_cityname ,
									channel_catalogid ,
									channel_catalogname,
									channel_chiefintr,
									channel_logoURL,
									accountid,
									createtime,
									channel_keyWords)   

	local ok = mysql_api.cmd(channel_dbname,"INSERT",sql_str)
	if not ok then
		only.log('E',string.format("insert apply info accountid:%s channel_num:%s  failed \r\n  %s" ,accountid ,channel_num , sql_str ))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
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

	url_tab['app_key'] = args['appKey']

	check_parameter(args)

	local accountid  = args['accountID']	
	check_userinfo(accountid)

	local channel_num      = args['channelNumber']
	local channel_name     = args['channelName']
	local channel_intro    = args['channelIntroduction'] 
	local channel_citycode = args['channelCityCode'] 
	local channel_catalogid  = args['channelCatalogID'] 
	local channel_logoURL = args['channelCatalogUrl'] or ''	
	local channel_chiefintr = args['chiefAnnouncerIntr']
	local channel_keyWords = args['channelKeyWords'] or ''	

	local ok = apply_micro_channel(accountid, 
									channel_num,
									channel_name,
									channel_intro,
									channel_citycode,
									channel_catalogid,
									channel_logoURL,
									channel_chiefintr,
									channel_keyWords)

	if ok then
		gosay.go_success(url_tab, msg['MSG_SUCCESS'])
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
