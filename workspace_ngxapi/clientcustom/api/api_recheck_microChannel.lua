--owner:jiang z.s. 
---- 审核用户申请通过的微频道 

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
local channel_dbname  = "app_custom___wemecustom"

local txt2voice = link.OWN_DIED.http.txt2voice

local G = {
		sql_check_accountid = " SELECT 1 FROM userList WHERE accountID='%s' limit 1 ",

		sql_check_channel = "SELECT  1 FROM userChannelList WHERE number = '%s'  limit 1",
		----infoType = 1----获取待重审的微频道列表
		---- 获取重申频道的最新修改信息 2014-12-16 
		sql_get_recheck_list = " SELECT id as idx,accountID ,number ,name ,introduction ,cityCode ,cityName ,catalogID ,catalogName ,chiefAnnouncerIntr , " ..
								" logoURL ,channelStatus ,createTime ,updateTime FROM modifyMicroChannelInfo where channelStatus = 2  %s  limit %d , %d " ,
		----重审通过
		----读取modifyMicroChannelInfo表 channelStatus = 1
		----infoType = 2 
		sql_get_oldModifyInfo = " SELECT number ,name ,introduction ,cityCode ,cityName ,catalogID ,catalogName ,chiefAnnouncerIntr,logoURL  "	.. 
							" FROM modifyMicroChannelInfo where number = '%s' and id = %d and channelStatus = 2 limit 1  " ,
		----重审通过
		----更新modifyMicroChannelInfo表 channelStatus = 1		
		----infoType = 2 
		sql_update_modify_info = " update modifyMicroChannelInfo set checkAccountID = '%s',updateTime= '%s', channelStatus = 1 , remark = '%s' ,checkAppKey = '%s' where number = '%s' and id = %d limit 1 " ,
		----重审通过
		----更新checkMicroChannelInfo表 channelStatus = 1 
		----infoType = 2 
		---- channelNameURL 
		sql_update_check_info = " update checkMicroChannelInfo set number ='%s', updateTime = unix_timestamp() ,name ='%s',introduction ='%s',cityCode ='%s',cityName ='%s',catalogID ='%s', " ..
							" catalogName ='%s',chiefAnnouncerIntr ='%s',logoURL ='%s', channelNameURL = '%s' ,channelStatus ='%s' , remark = '%s' where number = '%s' and channelStatus = 2 limit 1 ",
		----重审驳回
		----驳回修改申请 channelStatus = 2
		----infoType = 2 
		sql_reject_modifytab = " update modifyMicroChannelInfo set checkAccountID = '%s',updateTime= '%s', channelStatus = 3 ,remark = '%s' ,checkAppKey = '%s' where number = '%s'  and channelStatus = 2 limit 1  ",
		----重审驳回
		----驳回修改申请 channelStatus = 2
		----infoType = 2 
		sql_reject_checktab = " update checkMicroChannelInfo set channelStatus = 1 , updateTime = unix_timestamp()  ,remark = '%s' where number = '%s' and channelStatus = 2 limit 1 ",
		----关闭微频道 channelStatus = 3
		----infoType = 2 
		sql_close_microChannel = " update checkMicroChannelInfo set channelStatus = 3 , updateTime = unix_timestamp() , remark = '%s' where number = '%s' and channelStatus != 3 limit 1 ",
		----关闭微频道 channelStatus = 3
		----infoType = 2 
		sql_close_microChannel_modify = " update modifyMicroChannelInfo set checkAccountID = '%s',updateTime= '%s',channelStatus = 4 , remark = '%s' ,checkAppKey = '%s' where number = '%s' and channelStatus = %d limit 1 ",
		----重新开启微频道 channelStatus = 4
		----infoType = 2 
		sql_reopen_microChannel = " update checkMicroChannelInfo set channelStatus = 1 , updateTime = unix_timestamp()  , remark = '%s' where number = '%s' and channelStatus = 3 limit 1 ",
		----重新开启微频道 channelStatus = 4
		----infoType = 2 
		sql_reopen_microChannel_modify = " update modifyMicroChannelInfo set checkAccountID = '%s',updateTime= '%s',channelStatus = 1 , remark = '%s' ,checkAppKey = '%s' where number = '%s'  and channelStatus = 4 limit 1 ",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-->chack parameter
local function check_parameter(args)
	if not args['infoType'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
	end
	if not (args['infoType']== '1' or args['infoType']== '2' ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
	end 

	if not app_utils.check_accountID(args['checkAccountID']) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkAccountID')
	end
	if args['infoType'] == '1' then
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

		if args['channelName'] and #tostring(args['channelName']) > 0 then
			if  app_utils.str_count(args['channelName']) > 16 or (string.find(args['channelName'],"'")) or (string.find(args['channelName'],'%s+') ) then
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelName')
			end
		end

		if args['channelNumber'] and #tostring(args['channelNumber']) > 0 then
			if #tostring(args['channelNumber']) > 16  or (string.find(args['channelNumber'] ,"'")) then
				only.log('E',string.format(" channel_number:%s is error", args['channelNumber'] ))
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
			end
		end
	elseif args['infoType'] == '2' then
		if not app_utils.check_accountID(args['accountID']) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
		end	

		if not args['checkStatus'] then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
		end

		---  1正常 3审核驳回
		local check_status = args['checkStatus'] 
		if not ( check_status == "1" or check_status == "3" or check_status == "2" or check_status == "4") then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
		end

		local channel_num = args['channelNumber']
		if not channel_num then 
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
		end
		if #tostring(channel_num) < 5 or  #tostring(channel_num) > 16  or not utils.is_variable_syntax(channel_num) then
			only.log('E',string.format(" channel_number:%s is error", channel_num ))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
		end
		if check_status == '1' or check_status == '2' then
			if not args['applyIdx'] then
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
			end
			if string.find(tonumber(args['applyIdx']),"%.") then
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
			end
		end

		if args['checkRemark'] and #tostring(args['checkRemark']) > 0 then
			if string.find(args['checkRemark'] ,"'") then	
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkRemark')
			end
		end
	end

	if args['startPage'] then 
		if not tonumber(args['startPage']) or string.find(tonumber(args['startPage']),"%.") or tonumber(args['startPage']) <= 0 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'startPage')
		end
	end

	if args['pageCount'] then
		if not tonumber(args['pageCount']) or string.find(tonumber(args['pageCount']),"%.")  or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'pageCount')
		end
	end
	-- safe.sign_check(args, url_tab )
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_tab, 'checkAccountID', safe.ACCESS_WEIBO_INFO)
end

local function check_accountid(accountid)
	----1.检测accountid是否合法
	local sql_str = string.format(G.sql_check_accountid ,accountid)
	local ok,ret = mysql_api.cmd(userlist_dbname ,'SELECT',sql_str)

	if not ok or not ret then
		only.log('E',string.format('do failed in sql_str:%s ',sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0 then
		local tmp_str = string.format("accountID:%s",accountid)
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],tmp_str)
	end	
end

local function get_recheck_list( start_index ,page_count ,channel_citycode ,catalogid ,channel_name ,channel_number )
	local str_filter = ""
	if channel_citycode then 
		str_filter = str_filter .. string.format("  and  cityCode = %s  ", channel_citycode )
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

	local sql_str = string.format(G.sql_get_recheck_list,str_filter ,start_index ,page_count)
	only.log('D',sql_str)
	local ok,ret  = mysql_api.cmd(channel_dbname ,'SELECT',sql_str)
	if not ok or not ret then
		only.log('E',string.format('do failed in sql_str:%s ',sql_str))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])		
	end
	return ret
end

---- 对名称名称设置对应的url 
local function get_channelname_url( channel_name ,app_key )
	local tab = {
		appKey = app_key,
		text = channel_name,
	}
	tab['sign'] = app_utils.gen_sign(tab)
	tab['text'] = utils.url_encode(tab['text'])
	return appfun.txt2voice( txt2voice , tab)
end


local function recheck_microChannel(checkAccountID, checkAppKey, accountid ,channel_num ,checkStatus ,id_in_modifytable ,checkRemark)
	----频道状态 2.正常,1驳回,3.关闭 4.重新开启微频道
	local sql_tab = {}
	local ok,req = nil,nil
	local channel_name_url = nil
	local cur_time = ngx.time()
	local ok ,idx = redis_api.cmd('private','get',string.format("%s:channelID",channel_num)) 
	if not ok then
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end
	if not idx then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end
	local ok ,channelStatus = redis_api.cmd('private','get',string.format("%s:channelStatus",idx))
	if not ok or not channelStatus then
		gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
	end
	---- 关闭微频道
	if checkStatus == 3 then
		local sql_str = string.format(G.sql_close_microChannel ,checkRemark,channel_num)
		table.insert(sql_tab ,sql_str)		 
		if tonumber(channelStatus) ~= 1 then
			local sql_str = string.format(G.sql_close_microChannel_modify ,checkAccountID ,cur_time ,checkRemark,checkAppKey ,channel_num ,tonumber(channelStatus))  
			table.insert(sql_tab ,sql_str)
		end
	---- 重新开启微频道
	elseif checkStatus == 4 then
		only.log('E',string.format('cur_checkStatus:%s ,cur_channelStatus:%s !',checkStatus ,channelStatus))
		if tonumber(channelStatus) == 2 then
			only.log('E',string.format('cur_checkStatus:%s ,cur_channelStatus:%s !',checkStatus ,channelStatus))
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
		end
		local sql_str = string.format(G.sql_reopen_microChannel ,checkRemark,channel_num)
		table.insert(sql_tab ,sql_str)
		local sql_str = string.format(G.sql_reopen_microChannel_modify ,checkAccountID ,cur_time ,checkRemark,checkAppKey ,channel_num )  
		table.insert(sql_tab ,sql_str)		
	---- 驳回微频道
	elseif checkStatus == 1 then
		local sql_str = string.format(G.sql_reject_modifytab ,checkAccountID ,cur_time ,checkRemark ,checkAppKey ,channel_num)   ----id from modifytable 
		table.insert(sql_tab ,sql_str)
		local sql_str = string.format(G.sql_reject_checktab ,checkRemark,channel_num)
		table.insert(sql_tab ,sql_str)
	---- 审核通过微频道
	elseif checkStatus == 2 then
		----读取modifyMicroChannelInfo表
		local sql_str = string.format(G.sql_get_oldModifyInfo ,channel_num ,id_in_modifytable)   ----id from modifytable
		ok,req  = mysql_api.cmd(channel_dbname ,'SELECT' ,sql_str)
		if not ok or not req then
			only.log('E',sql_str)
			gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])			
		end
		if #req ~= 1 then
			only.log('E',sql_str)
			-- gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')
		end

		channel_name_url = req[1]['channelNameURL']
		if not channel_name_url or #tostring(channel_name_url) < 10 or not (string.find( channel_name_url or '', "http://")) then
			local channelname = string.format("微频道%s" ,req[1]['name'])
			local tmp_ok, tmp_url = get_channelname_url( channelname ,checkAppKey )
			if not tmp_ok or not tmp_url then
				only.log('E',string.format(' channel_name:%s  txt2voice failed ! ' , req[1]['name']  ) )
				gosay.go_false(url_tab ,msg['MSG_ERROR_TXT2VOICE_FAILED'])
			end
			channel_name_url = tmp_url
		end

		----更新checkMicroChannelInfo表
		local sql_str = string.format(G.sql_update_check_info ,req[1]['number'],
															req[1]['name'],
															req[1]['introduction'],
															req[1]['cityCode'],
															req[1]['cityName'],
															req[1]['catalogID'],
															req[1]['catalogName'],
															req[1]['chiefAnnouncerIntr'],
															req[1]['logoURL'],
															channel_name_url,
															1,
															checkRemark,
															channel_num)
		table.insert(sql_tab ,sql_str)
		----更新modifyMicroChannelInfo表
		local sql_str = string.format(G.sql_update_modify_info ,checkAccountID ,cur_time ,checkRemark ,checkAppKey ,channel_num,id_in_modifytable)
		table.insert(sql_tab ,sql_str)
	end
	
	

	local ok  = mysql_api.cmd(channel_dbname,"AFFAIRS",sql_tab)
	if not ok then
		only.log('E',string.format("modify channel failed!  %s ", table.concat( sql_tab, "\r\n")))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	----关闭
	if checkStatus == 3 then
		redis_api.cmd('private','set',string.format("%s:channelStatus",idx), 4)
	----重启	
	elseif checkStatus == 4 then
		redis_api.cmd('private','set',string.format("%s:channelStatus",idx), 1)
	----驳回
	elseif checkStatus == 1 then
		redis_api.cmd('private','set',string.format("%s:channelStatus",idx), 3)
	----通过
	elseif checkStatus == 2 then		
		local capacity = 0
		local channel_type = 1
		local open_type = 1	
		cur_utils.set_channel_idx_number( req[1]['number'], idx , accountid , 
											cur_time , capacity , channel_type,  
											open_type , 1,req[1]['cityCode'] ,
											req[1]['cityName'] ,req[1]['catalogID'] , 
											req[1]['catalogName'] ,req[1]['name'],
											req[1]['introduction'],channel_name_url )
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
	local checkAppKey = args['appKey']
	---- 传入参数语法校验
	check_parameter(args)
	---- 审核人
	local checkAccountID  = args['checkAccountID']
	---- 对accountID进行数据库校验
	check_accountid(checkAccountID)
	local accountid  = args['accountID']
	local infoType = tonumber(args['infoType'])	

	local check_status = tonumber(args['checkStatus']) 
	if  infoType == 2 and check_status ~= 3  then
		---- 只有在非关闭的情况下才校验账户 2015-05-11 
		---- 对accountID进行数据库校验
		check_accountid(accountid)
	end
	local channel_num = args['channelNumber']
	local idx = args['applyIdx']
	local checkRemark = args['checkRemark'] or ''
	local catalog_id = tonumber(args['catalogID']) 
	local channel_name = args['channelName']	
	local channel_citycode = tonumber(args['cityCode'])

	local start_page = tonumber(args['startPage']) or 1
	local page_count = tonumber(args['pageCount']) or 20
	local start_index = ( start_page - 1 ) * page_count

	---- 获取待重审的微频道的列表
	if infoType == 1 then
		local ret = get_recheck_list( start_index ,page_count ,channel_citycode ,catalog_id ,channel_name ,channel_num)
		local count = 0
		if not ret or type(ret) ~= "table" or #ret == 0 then
			ret = "[]"
		else
			count = #ret 
			local ok, tmp_ret = pcall(cjson.encode,ret)
			if ok and tmp_ret then
				ret = tmp_ret
			end
		end	
		
		local str = string.format('{"count":"%s","list":%s}',count,ret)	
		if str then
			gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
		else
			gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
		end	
	---- 重审微频道		
	elseif infoType == 2 then
		local ok = recheck_microChannel(checkAccountID, checkAppKey, accountid ,channel_num ,check_status ,idx ,checkRemark)
		if ok then
			gosay.go_success(url_tab, msg['MSG_SUCCESS'])
		else
			gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
		end	
	end

end

safe.main_call( handle )
