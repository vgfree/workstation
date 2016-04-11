--owner:jiang z.s. 
---- 审核用户申请的微频道 

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

local txt2voice = link.OWN_DIED.http.txt2voice

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ",

	sql_check_channelnumber = "select 1 FROM  userChannelList where upper(number) = upper('%s') limit 1 " ,
	
	sql_get_next_idx = "select max(idx) as count from  userChannelList  where channelType != 0  " ,
	--检查accountid，channelnumber和id是否匹配
	sql_get_channel_info = "select checkStatus ,name,cityCode ,cityName ,catalogID ,catalogName,introduction,keyWords from applyMicroChannelInfo where accountID = '%s' and number = '%s' and id = %d limit 1 " ,

	sql_save_check_result = " insert checkMicroChannelInfo( idx,number,name,introduction,cityCode,cityName," ..
								" catalogID,catalogName,chiefAnnouncerIntr,logoURL, channelNameURL ,accountID,inviteUniqueCode," .. 
								" createTime,updateTime,channelStatus,remark,keyWords) " ..
								" select '%s', number,name,introduction,cityCode,cityName," ..
								" catalogID,catalogName,chiefAnnouncerIntr,logoURL, '%s' ,accountID,'%s'," .. 
								" '%s','%s' ,1,'%s' ,keyWords " ..
								" from applyMicroChannelInfo where id = %s ",

	sql_save_invite = " insert into inviteLinksHistory (idx,number,accountID,inviteUniqueCode,channelType,crateTime,remark,appKey) " ..
						" values( '%s', '%s', '%s', '%s', %d, '%s', '%s', '%s' )" ,

	sql_update_apply_info = " update applyMicroChannelInfo set checkAccountID = '%s',checkTime = '%s', " ..
							" checkStatus = %d,checkRemark = '%s',checkAppKey='%s' , remark = '%s' where id = %s and number = '%s' limit 1 " ,

	sql_save_user_channel_list = " insert into userChannelList( idx,number,accountID,checkAccountID,channelType,createTime) " ..
								" values ('%s','%s','%s','%s',%s, '%s') ", 
}
  

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}



-->chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['checkAccountID']) or  string.find(args['checkAccountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkAccountID')
	end

	if not app_utils.check_accountID(args['accountID']) or  string.find(args['accountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	local channel_num = args['channelNumber']
	if #tostring(channel_num) < 5 or  #tostring(channel_num) > 16  or not utils.is_variable_syntax(channel_num) then
		only.log('E',string.format(" channel_number:%s is error", channel_num ))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
	end

	---- 审核备注
	if args['checkRemark'] then
		if string.find(args['checkRemark'],"'") or app_utils.str_count(args['checkRemark']) > 64 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkRemark')
		end
	end
	---- 频道备注
	if args['channelRemark'] then
		if string.find(args['channelRemark'],"'") or app_utils.str_count(args['channelRemark']) > 64 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelRemark')
		end
	end

	if not args['checkStatus'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
	end

	----  1驳回 2审核成功
	local check_status = args['checkStatus'] 
	if not ( check_status == "1" or check_status == "2" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
	end
	if not args['applyIdx'] or not utils.is_number(args['applyIdx']) then		
	    gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyIdx')		
    end
	---- safe.sign_check(args, url_tab )
	---- 20150720
	---- 为io部门使用
	safe.sign_check(args, url_tab, 'checkAccountID', safe.ACCESS_WEIBO_INFO)
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


local function get_next_channel_idx(  )
	local sql_str = G.sql_get_next_idx 
	local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table" then 
		only.log('E',string.format('get next channel failed! %s ' , sql_str) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret == 0  then
		return 1
	end
	return (tonumber(ret[1]["count"]) or 0 ) + 1
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



local function check_apply_microchannel(check_accountid,id ,accountid ,channel_number , check_status, check_remark, check_idx , app_key ,channel_remark)
	if check_status == "2" then
		----校验channelNumber是否审核通过
		local sql_str = string.format(G.sql_check_channelnumber,channel_number)
		local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
		if not ok or not ret then 
			only.log('E',string.format('get next channel failed! %s ' , sql_str) )
			gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
		end 
		if #ret == 1 then 
			gosay.go_false(url_tab ,msg['MSG_ERROR_USER_CHANNEL_EXISTS'])
		end
	end
	----检查accountid，channelnumber和id是否匹配
	local sql_str = string.format(G.sql_get_channel_info, accountid ,channel_number ,id )
	local ok, ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table" then 
		only.log('E',string.format('get next channel failed! %s ' , sql_str) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	
	if #ret ~= 1  then
		only.log('E',string.format(' cur_idx is error %s ' , sql_str) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_IDX'])	
	end

	if tonumber(ret[1]['checkStatus']) ~= 0 then
		only.log('E',string.format(' channel_number check succed %s ' ,channel_number) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	local citycode = ret[1]['cityCode']
	local cityname = ret[1]['cityName']
	local catalogid = ret[1]['catalogID']
	local catalogname = ret[1]['catalogName']
	local channelname = ret[1]['name']
	local introduction = ret[1]['introduction']
	local keyWords = ret[1]['keyWords']
	local max_idx = get_next_channel_idx()
	local channel_idx = string.format("%.9d",max_idx)

	if not channel_idx or #tostring(channel_idx) < 9 or #tostring(channel_idx) > 10 then
		only.log('E',string.format('[*****] channel_number %s new idx %s failed ' ,channel_number , channel_idx) )
		gosay.go_false(url_tab, msg['MSG_ERROR_USER_CHANNEL_IDX'])
	end

	local ok_status, ok_channelname_url = nil,nil
	local sql_tab = {}
	local updateTime = ngx.time()
	if check_status == "2" then
		---- 微频道名称文本转语音
		local tmp_channelname = string.format("微频道%s" ,ret[1]['name'])
		ok_status, ok_channelname_url = get_channelname_url( tmp_channelname , app_key )
		if not ok_status or not ok_channelname_url then
			only.log('E',string.format(' channel_name:%s  txt2voice failed !' , tmp_channelname  ) )
			gosay.go_false(url_tab, msg['MSG_ERROR_TXT2VOICE_FAILED'])
		end
		
		---- 审核成功	
		local cur_uuid = utils.create_uuid()
		local uniquecode = string.format("%s|%s",channel_number, cur_uuid)
		local ok,ret = redis_api.cmd('private','set',string.format("%s:inviteUniqueCode",channel_idx), uniquecode)
		if not ok then
			gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
		end
		
		----保存结果到审核表中
		local sql_str = string.format(G.sql_save_check_result, channel_idx ,ok_channelname_url, uniquecode ,updateTime , updateTime ,check_remark ,id  )
		table.insert(sql_tab, sql_str)
		----保存结果到用户邀请链接历史表
		local sql_str = string.format(G.sql_save_invite ,channel_idx, channel_number, accountid, uniquecode, 1 ,updateTime , check_remark , app_key )
		table.insert(sql_tab, sql_str) 
		----保存结果到频道汇总列表
		local sql_str = string.format(G.sql_save_user_channel_list,channel_idx,channel_number, accountid, check_accountid, 1 ,updateTime)
		table.insert(sql_tab, sql_str)

	end
	local sql_str = string.format(G.sql_update_apply_info,check_accountid,updateTime ,check_status, check_remark, app_key, channel_remark ,id, channel_number)
	table.insert(sql_tab, sql_str)

	only.log('D',string.format("debug check micro channel , %s ", table.concat( sql_tab, "\r\n")) )

	local ok, ret = mysql_api.cmd(channel_dbname,'AFFAIRS',sql_tab)
	if not ok then
		only.log('E',string.format("[**SYSTEM_ERROR**]check channel failed!  %s ", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	---- 审核成功
	if check_status == "2" then
		local cur_time = ngx.time()
		local capacity = 0
		local channel_type = appfun.CHANNEL_TYPE_MICRO
		local open_type = 1

		cur_utils.set_channel_idx_number( channel_number, 
											channel_idx , 
											accountid , 
											cur_time , 
											capacity , 
											channel_type,  
											open_type ,
											1, ---- 2014-11-25 正常状态
											citycode ,
											cityname ,
											catalogid , 
											catalogname ,
											channelname,
											introduction,
											ok_channelname_url)

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
	---- 传入参数语法校验
	check_parameter(args)
	---- 审核人
	local check_accountid  = args['checkAccountID']
	---- 对accountID进行数据库校验
	check_userinfo(check_accountid)

	local check_idx = args['applyIdx']
	local check_remark = args['checkRemark'] or ''
	local channel_remark = args['channelRemark'] or ''
	local check_status = args['checkStatus']
	local accountid = args['accountID']
	local channel_number = args['channelNumber']
	local id = tonumber(args['applyIdx'])

	local ok = check_apply_microchannel( check_accountid,id,accountid ,channel_number , check_status, check_remark, check_idx , args['appKey'] ,channel_remark )
	if ok then
		----SUCCED
		gosay.go_success(url_tab, msg['MSG_SUCCESS'])
	else
		----FAILED
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )
