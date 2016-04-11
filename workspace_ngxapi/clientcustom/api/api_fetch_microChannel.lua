---- jiang z.s.
---- 2014-11-10
---- 获取微频道列表
--获取所有待审核的微频道
--获取管理员自己的微频道
--查询所有能关注的微频道(支持查询)

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

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 1 ", 
	--获取所有待审核的微频道
	sql_get_channelStatus = "SELECT id as idx , number , name ,introduction ,catalogID ,catalogName ,chiefAnnouncerIntr , cityCode ,cityName ,accountID , " ..
						" logoURL ,createTime ,checkStatus ,checkRemark FROM  applyMicroChannelInfo WHERE checkStatus in ( %s )  %s  limit %d , %d  ",
	----获取已经审核通过的微频道（关闭/重启需要）
	sql_get_close_list = " SELECT id as idx ,number ,name ,introduction ,catalogID ,catalogName ,chiefAnnouncerIntr ,cityCode ,cityName ,accountID , " ..
						" logoURL ,createTime ,( channelStatus + 1)  as checkStatus ,remark as checkRemark,userCount FROM checkMicroChannelInfo " ..
						"  where channelStatus in (1 ,3)  %s  order by updateTime desc  limit %d , %d  ",
	--查询所有能关注的微频道
	sql_can_followChannel = "SELECT accountID ,'' as chiefAnnouncerName,  number , name ,introduction ,cityCode , cityName ,catalogID ,catalogName , chiefAnnouncerIntr , logoURL , inviteUniqueCode , 1 as checkStatus,userCount ,(userCount + 1000) as capacity  FROM checkMicroChannelInfo  WHERE  " ..
						" accountID != '%s' and channelStatus in (1,2)  %s   %s  limit %d , %d ",
	--获取微频道所有者的微频道在数据库中的所有记录
	-- tableType = nil	
	sql_get_allChannel = " (select id as idx ,name ,number,introduction ,cityName ,catalogID , cityCode ,catalogName ,chiefAnnouncerIntr ,createTime ,logoURL ,accountID ,checkRemark ,1 as tableInfo ,checkStatus ,'' as inviteUniqueCode, 0 as userCount  from applyMicroChannelInfo  where accountID = '%s' and checkStatus != 2  ) " ..
						" union " ..
						" (select idx ,name ,number ,introduction ,cityName ,catalogID ,cityCode ,catalogName ,chiefAnnouncerIntr ,createTime ,logoURL ,accountID ,'' as checkRemark ,2 as tableInfo ,channelStatus as checkStatus ,inviteUniqueCode, userCount  from checkMicroChannelInfo where channelStatus in (1,2) and accountID = '%s' ) " .. 
						" union " ..
						" (select idx ,name ,number ,introduction ,cityName ,catalogID  ,cityCode ,catalogName ,chiefAnnouncerIntr ,createTime ,logoURL ,accountID ,'' as checkRemark ,3 as tableInfo ,channelStatus as checkStatus ,'' as inviteUniqueCode,0 as userCount  from modifyMicroChannelInfo where channelStatus = 2 and accountID = '%s' ) " ,
	-- sql_fetch_channelInfo = "select id as idx , name ,number ,introduction,cityCode,cityName,catalogID,catalogName,chiefAnnouncerIntr,logoURL,accountID,checkStatus  " ..
	-- 					" from applyMicroChannelInfo  where accountID = '%s' " ,
	-- -- tableType = 1					
	sql_fetch_applyInfo = " select id as idx ,name ,number,introduction ,catalogID ,cityName ,cityCode ,catalogName ,chiefAnnouncerIntr ,createTime ,logoURL ,accountID ,checkRemark ,1 as tableInfo ,checkStatus, 0 as userCount  from applyMicroChannelInfo  where accountID = '%s'  and  checkStatus != 2  "	,
	-- -- tableType = 2
	sql_fetch_checkInfo = " select idx ,name ,number ,introduction ,cityName ,catalogID ,cityCode ,catalogName ,chiefAnnouncerIntr ,createTime ,logoURL ,accountID ,'' as checkRemark ,2 as tableInfo ,channelStatus as checkStatus, userCount from checkMicroChannelInfo where channelStatus in (1, 2 )  and accountID = '%s' "	,
	-- -- tableType = 3
	sql_fetch_modifyInfo = " select idx ,name ,number ,introduction ,cityName ,catalogID  ,cityCode ,catalogName ,chiefAnnouncerIntr ,createTime ,logoURL ,accountID ,'' as checkRemark ,3 as tableInfo ,channelStatus as checkStatus,0 as userCount  from modifyMicroChannelInfo where channelStatus  = 2  and accountID = '%s' ",			
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

local value = '1'

local field_tab  = {
	popularity = value,		----受欢迎度
	userCount  = value,		----用户总人数
	number     = value,		----频道编码
	name       = value,		----频道名称
	cityCode   = value,		----城市编码
}


-->chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID'])  then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	local info_type =  args['infoType'] 
	if not ( info_type == "0" or info_type == "1" or info_type == "2" ) then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
	end

	if info_type == "0" then
		---- 0待审核 
		---- 1驳回 
		---- 2审核成功
		---- 10 所有
		local channel_status = args['channelStatus'] or "10"
		if not ( channel_status == "0" or channel_status == "1" or channel_status == "2" or channel_status == "10" ) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelStatus')
		end
	elseif info_type == "1" then
		---- 0待审核 
		---- 1驳回 
		---- 2审核成功 
		---- 3重审中 
		---- 4重审成功 
		---- 5重审驳回
		local channel_status = args['channelStatus'] 
		if channel_status and #channel_status > 0 then 
			if not ( channel_status == "3" or channel_status == "1" or channel_status == "2" ) then

				only.log('E',"channelStatus error")
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelStatus')
			end
		end
	end
	if args['cityCode'] and #tostring(args['cityCode']) > 0 then
		if not tonumber(args['cityCode']) or #tostring(args['cityCode']) < 5 or not utils.is_number(args['cityCode']) or #tostring(args['cityCode']) > 10  then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'cityCode')
		end
	end

	if args['catalogID'] and #tostring(args['catalogID']) > 0 then
		if not tonumber(args['catalogID']) or #tostring(args['catalogID']) < 5 or not utils.is_number(args['catalogID']) or #tostring(args['catalogID']) > 10 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'catalogID')
		end
	end

	if args['channelName'] and ( app_utils.str_count(args['channelName']) > 16 or (string.find(args['channelName'],"'")) )  then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
	end

	if args['channelNumber'] and #tostring(args['channelNumber']) >0  then
		if #tostring(args['channelNumber']) > 16  or string.find(args['channelNumber'] ,"'") then
			only.log('E',string.format(" channel_number:%s is error", args['channelNumber'] ))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
		end
	end
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

	if args['startPage'] then 
		if not tonumber(args['startPage']) or string.find(tonumber(args['startPage']),"%.") or tonumber(args['startPage']) < 0 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'startPage')
		end
	end

	if args['pageCount'] then
		if not tonumber(args['pageCount']) or string.find(tonumber(args['pageCount']),"%.")  or tonumber(args['pageCount']) < 1 or tonumber(args['pageCount']) > 500 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'pageCount')
		end
	end

	---- 排序字段
	if args['sortField'] and #args['sortField'] > 0 then
		local tmp_tab = utils.str_split(args['sortField'],',')
		for k , v in pairs(tmp_tab) do
			if not field_tab[v] then
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'sortField')
			end
		end
	end

	-- safe.sign_check(args, url_tab)
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

---- 对accountID进行数据库校验
local function check_userinfo(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status or not user_tab then
		only.log('E',string.format('connect userlist_dbname failed, %s ',sql_str) )
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

---- 获取所有待审核的微频道
----channelStatus
----0 ) 未审核
----1 ) 驳回
----2 ) 已经审核
----10) 所有
local function get_apply_microchannel( channel_status, start_index , page_count ,cityCode ,catalogid ,channel_name ,channel_number,channel_keyWords)
	local str_sql = ''
	local ok,ret = nil ,nil
	local str_filter = ""
	if cityCode then
		str_filter = str_filter .. string.format(" and cityCode = %s " ,cityCode)
	end
	if catalogid then
		str_filter = str_filter .. string.format("  and  catalogID = %s  ", catalogid )
	end

	if channel_name then
		str_filter = str_filter .. string.format("  and  name like  '%%%s%%'  ", channel_name )
	end

	if channel_number then
		str_filter = str_filter .. string.format("  and  upper(number) like  upper('%%%s%%')  ", channel_number )
	end
	if channel_keyWords and #channel_keyWords > 0 then
		str_filter = str_filter .. string.format(" and keyWords like '%%%s%%' ",channel_keyWords)
	end

	if channel_status == 1 or  channel_status == 0 then 
		str_sql = string.format(G.sql_get_channelStatus ,channel_status ,str_filter ,start_index ,page_count)
		ok,ret = mysql_api.cmd(channel_dbname , 'SELECT',str_sql)
	elseif channel_status == 2 then
		str_sql = string.format(G.sql_get_close_list ,str_filter ,start_index ,page_count)
		ok,ret = mysql_api.cmd(channel_dbname , 'SELECT',str_sql)	
	elseif channel_status == 10 then 
		local tmp_ret = {}
		str_sql = string.format(G.sql_get_close_list ,str_filter ,start_index ,page_count)
		ok,ret = mysql_api.cmd(channel_dbname , 'SELECT',str_sql)
		if not ok or not ret then
			only.log('E',string.format("failed to do !\r\n %s",str_sql))
			gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])			
		end
		if #ret ~= 0 then
			for k ,v in pairs(ret) do
				table.insert(tmp_ret ,v )
			end
		end
		local channel_status = '0,1'
		str_sql = string.format(G.sql_get_channelStatus ,channel_status ,str_filter ,start_index ,page_count)
		ok ,ret = mysql_api.cmd(channel_dbname , 'SELECT',str_sql)
		if not ok or not ret then
			only.log('E',string.format("failed to do !\r\n %s",str_sql))
			gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])			
		end
		if #ret ~= 0 then
			for k ,v in pairs(ret) do 
				table.insert(tmp_ret ,v )
			end
		end	
		ret = tmp_ret	
	end

	if not ok or not ret or type(ret) ~= "table"  then 
		only.log('E',string.format("failed to do !\r\n %s",str_sql))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	return ret 
end

---- 获取微频道所有者的微频道  未审核, 驳回 , 已经审核 
----channelStatus
----0 ) 未审核
----1 ) 驳回
----2 ) 已经审核
local function get_owner_microchannel( accountid ,check_status )
	local sql_str = nil
	-- local tmp = ''
	if check_status == 1 then
		-- tmp = string.format(' and checkChannelStatus in ( %s ) ',check_status)
		sql_str = string.format(G.sql_fetch_applyInfo ,accountid)
	elseif check_status == 2 then
		sql_str = string.format(G.sql_fetch_checkInfo ,accountid)
	elseif check_status == 3 then
		sql_str = string.format(G.sql_fetch_modifyInfo ,accountid)
	elseif not check_status then
		-- sql_str = string.format(G.sql_fetch_channelInfo ,accountid )
		sql_str = string.format(G.sql_get_allChannel ,accountid ,accountid ,accountid)
	end
	local ok,ret = mysql_api.cmd(channel_dbname ,'SELECT' ,sql_str)
	if not ok or not ret then
		only.log('E',sql_str)
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	for k,v in pairs(ret) do 
		v['idx'] = tonumber(v['idx'])
	end
	return ret
end

local function get_nickname(accountID)
	local ok,nickname = redis_api.cmd('private','get',accountID..':nickname')
	if not ok then
		only.log('E',"redis get chiefAnnouncerName failed [%s]",accountID)
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	return nickname or ''

end

---- 查询所有能关注的微频道
local function get_can_follow_microchannel( accountid ,channel_citycode , channel_name  , catalogid , start_index , page_count ,channel_keyWords, orderby_str )
	local str_filter = ""
	if channel_citycode then 
		str_filter = str_filter .. string.format("  and  cityCode = %s  ", channel_citycode )
	end

	if catalogid then
		str_filter = str_filter .. string.format("  and  catalogID = %s  ", catalogid )
	end

	if channel_name and #channel_name > 0 then
		str_filter = str_filter .. string.format("  and  ( name like  '%%%s%%' or cityName like  '%%%s%%'   or upper(number) like '%%%s%%' ) ", channel_name , channel_name , string.upper(channel_name) )
	end

	if channel_keyWords and #channel_keyWords > 0 then
		str_filter = str_filter .. string.format(" and keyWords like '%%%s%%' ",channel_keyWords)
	end

	sql_str = string.format(G.sql_can_followChannel , accountid ,str_filter , orderby_str  ,start_index , page_count )
	only.log('D',"sql_str:%s",sql_str)
	local ok , ret = mysql_api.cmd(channel_dbname,'SELECT', sql_str )

	if not ok or not ret  or type(ret) ~= "table"  then 
		only.log('E',string.format("failed to do \r\n %s",sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	---- 获取主播名
	for i, info in pairs(ret) do
		ret[i]['chiefAnnouncerName'] = get_nickname(info['accountID'])
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

	---- 微频道
	---- infoType 
	----    0) 公司审核 
			----channelStatus
			----0 ) 未审核
			----1 ) 驳回
			----2 ) 已经审核
			----10) 所有
	----    1) 频道创建者
			----channelStatus
			----0 ) 未审核
			----1 ) 驳回
			----2 ) 已经审核
	----    2) 普通用户能关注的微频道
			----过滤条件
			---- 等于 catalogID
			---- 等于 cityCode
			---- 包含 channelName
	check_parameter(args)
	local accountid =  args['accountID']
	local info_type =  args['infoType'] 
	local start_page = tonumber(args['startPage']) or 1

	---- 兼容从0开始 2015-04-20
	if start_page < 1 then
		start_page = 1
	end
	local page_count = tonumber(args['pageCount']) or 20
	local start_index = ( start_page - 1 ) * page_count
	if start_index < 0 then
		start_index = 0 
	end

	local channel_status = tonumber(args['channelStatus']) 
	local channel_citycode = tonumber(args['cityCode'])
	local catalog_id = tonumber(args['catalogID']) 
	local channel_name = args['channelName']	
	local channel_number = args['channelNumber']
	local channel_keyWords = args['channelKeyWords']


	local orderby_str = args['sortField']
	if orderby_str and #orderby_str > 0 then
		local tmp_tab = utils.str_split(orderby_str,',')
		if tmp_tab and #tmp_tab > 0 then
			---- 频道排序字段
			orderby_str =  "  order by  "  ..  table.concat( tmp_tab, " desc , ")
		end
	end


	check_userinfo(accountid)

	local ret = nil
	local count = 0
	if info_type == "0" then
		---- 获取所有待审核的微频道
		ret = get_apply_microchannel( channel_status, start_index , page_count  ,channel_citycode ,catalog_id ,channel_name ,channel_number,channel_keyWords)
	elseif info_type == "1" then
		---- 获取微频道所有者的微频道  未审核, 驳回 , 已经审核 
		ret = get_owner_microchannel( accountid , channel_status )

	elseif info_type == "2" then

		---- 查询所有能关注的微频道	
		if not orderby_str or #orderby_str < 1 then
			orderby_str = "  order by popularity desc, userCount desc " 
		end

		ret = get_can_follow_microchannel( accountid ,channel_citycode , channel_name  , catalog_id , start_index , page_count ,channel_keyWords, orderby_str )
	end
	
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
		----SUCCED
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		----FAILED
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

safe.main_call( handle )
