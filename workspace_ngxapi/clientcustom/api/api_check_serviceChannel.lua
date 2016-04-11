
--wufei
--2015.7.14
--审核服务频道

local ngx       = require('ngx')
local msg       = require('msg')
local only      = require('only')
local safe      = require('safe')
local link      = require('link')
local utils     = require('utils')
local gosay     = require('gosay')
local appfun    = require('appfun')
local app_utils = require('app_utils')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')


local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

 
local G = {

	-- 检查ID是否合法
	sql_check_accountid = " select 1 from userList where accountID = '%s' ",

	-- 获取申请表 apply 信息(申请阶段)
	sql_get_channel_info = " select accountID, channelUrl, channelName, logoUrl, briefIntro,  " ..
						 " checkAccountID, checkTime, checkStatus, checkRemark, checkAppKey, applyAppKey " ..
						 " from applyServiceChannelInfo where accountID = '%s' and id = %s and validity = 1 ",

	-- 检查生成的 channelNumber 是否存在(用于生成一个唯一频道编号)(申请阶段)
	sql_check_channel_number = " select 1 from checkServiceChannelInfo where channelNumber = '%s' limit 1 ",

	-- 审核通过后更新申请 apply 表(申请阶段)
	sql_update_apply_info = " update applyServiceChannelInfo set channelNumber = '%s', checkAccountID = '%s', checkTime = %s, " .. 
							" checkStatus = %d , checkRemark = '%s', checkAppKey = '%s', channelStatus = %d, updateTime = %s " ..
							" where accountID = '%s' and id = %s and validity = 1 ",

	-- 审核通过后插入数据到审核通过 check 表(申请阶段)
	sql_insert_agree_data = " insert into checkServiceChannelInfo ( accountID, channelNumber, channelUrl, channelName, logoUrl, " .. 
							" briefIntro,  checkAccountID, checkTime, checkStatus, checkRemark, checkAppKey, " .. 
							" createTime, updateTime, validity, remark, applyAppKey) " .. 
							" values('%s', '%s', '%s', '%s', '%s', " .. 
							       " '%s', '%s', %s, %d, '%s', %s, " .. 
							       " %s, %s, %d, '%s', %s) ", 

	-- 在 userCustomDefineInfo 中插入频道信息
	sql_insert_custom_info = " insert into userCustomDefineInfo(accountID, actionType, customType, callbackUrl, defineLogo, " ..
		 							" defineName, createTime, updateTime, isSystem, validity, remark, sortIndex, codeMenu, briefIntro) "..
						   				" values('%s', %d, %d, '%s', '%s', " .. 
						   					" '%s', %s, %s, %d, %d, '%s', %d, '%s','%s' ) ",
				   
	-- customType是正递增，获取customType最大值，+1后为下一个customType
	sql_select_checkinfo = "select max(customType) as maxCustomTypeValue from userCustomDefineInfo  where actionType=3 ",

	-- 检查需要重审的频道是否存在(重审阶段)
	sql_check_rechecking_channel = " select beforeChannelUrl, beforeChannelName, beforeLogoUrl, beforeBriefIntro, " ..
									" afterChannelUrl, afterChannelName, afterLogoUrl, afterBriefIntro from modifyServiceChannelInfo " .. 
										" where accountID = '%s' and channelNumber = '%s' and checkStatus = %d and validity = 1 ",

	-- 恢复 申请表apply 审核状态(重审阶段,驳回) 或
	-- 修改 申请表apply 修改后的数据和审核状态(重审阶段,通过)
	sql_change_apply_info = " update applyServiceChannelInfo set channelUrl = '%s', channelName = '%s', logoUrl = '%s', briefIntro = '%s', " .. 
	-- sql_change_apply_info = " update applyServiceChannelInfo set " .. 
								" checkAccountID = '%s', checkTime = %s, checkStatus = %d, checkRemark = '%s', checkAppKey = %s, " .. 
								" channelStatus = %d, updateTime= %s, remark = '%s' " .. 
								" where accountID = '%s' and channelNumber = '%s' and validity = 1 ",

	-- 修改 重申表modify 审核状态(重审阶段,驳回) 或
	-- 修改 重申表modify 审核状态(重审阶段,通过)
	sql_change_modify_check_status = " update modifyServiceChannelInfo set checkAccountID = '%s', checkTime = %s, checkStatus = %d, checkRemark = '%s', checkAppKey = %s, " .. 
										" updateTime = %s, remark = '%s' where accountID = '%s' and channelNumber = '%s' and validity = 1 ",

	-- 修改 审核表check 修改后的数据和审核状态(重审阶段,通过)
	sql_update_check_info = " update checkServiceChannelInfo set channelUrl = '%s', channelName = '%s', logoUrl = '%s', briefIntro = '%s', " .. 
								" checkAccountID = '%s', checkTime = %s, checkStatus = %d, checkRemark = '%s', checkAppKey = %s, " .. 
								" updateTime = %s , remark = '%s' where accountID = '%s' and channelNumber = '%s' and validity = 1  ",
	
	-- 修改 相应customType 的服务频道数据(重审阶段,通过)
	sql_update_usercustom = " update userCustomDefineInfo set callbackUrl = '%s', defineLogo = '%s', defineName = '%s', briefIntro = '%s', updateTime = '%s', remark = '%s' " .. 
							" where accountID = '%s' and customType = '%s' and validity = 1 "
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-- accountID
-- infoType
-- channelID
-- channelNumber
-- checkAccountID
-- checkStatus
-- checkRemark
local function check_parameter(args)

	if not app_utils.check_accountID(args['accountID']) or  string.find(args['accountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

    if not args['infoType'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
    end
    local info_type = tonumber(args['infoType'])
    if not ( info_type == cur_utils.SERVICE_CHANNEL_APPLY_PERIOD or
            info_type == cur_utils.SERVICE_CHANNEL_RECHECK_PERIOD) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'infoType')
    end

    if info_type == cur_utils.SERVICE_CHANNEL_APPLY_PERIOD then
        if  not (#args['channelID'] > 0) or string.find(args['channelID'], "%.") or not tonumber(args['channelID'])  then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelID')
        end
    end

    if info_type == cur_utils.SERVICE_CHANNEL_RECHECK_PERIOD  then
        if (not (#args['channelNumber'] > 0)) or string.find(args['channelNumber'], "'") then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelNumber')
        end
    end

	if not app_utils.check_accountID(args['checkAccountID']) or  string.find(args['checkAccountID'] ,"'" ) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkAccountID')
	end

	if not args['checkStatus'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
	end	
	local check_status = tonumber(args['checkStatus'])
	if info_type == cur_utils.SERVICE_CHANNEL_APPLY_PERIOD then
		if not check_status or not (check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REJECT or
								 	check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
		end
	end
	if info_type == cur_utils.SERVICE_CHANNEL_RECHECK_PERIOD then
		if not check_status or not (check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REAGREE or
								 	check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REDISMISSED) then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkStatus')
		end
	end


	if not args['checkRemark'] or string.find(args['checkRemark'],"'") or app_utils.str_count(args['checkRemark']) > 64 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'checkRemark')
	end

	safe.sign_check(args, url_tab )

end

-- 对checkaccountID进行数据库(userList)校验
local function check_userinfo(account_id)

	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status or user_tab == nil then
		only.log('E', string.format('connect userlist_dbname failed, sql_str:[%s]', sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	if #user_tab == 0 then
		only.log('D',"accountID=%s",account_id)
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
	end

	if #user_tab > 1 then
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

-- 生成一个唯一频道编号
local function gen_unique_number()

    local channel_number, sql_str

    while true do
        channel_number = utils.random_string( cur_utils.SERVICE_CHANNEL_UNIQUE_CODE_LENGTH ) -- 服务频道唯一编码字符串长度
        sql_str = string.format(G.sql_check_channel_number, channel_number)
        local ok_status, ret_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)

        if not ok_status or not ret_tab or type(ret_tab) ~= 'table' then
        	only.log('E', string.format('connect channel_dbname failed!, %s ' , sql_str))
			gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
		end

        if ok_status and #ret_tab==0 then
            break
        end
    end

    return channel_number
end

local function check_channel_exists( account_id, channel_id )

	local sql_str = string.format(G.sql_get_channel_info, account_id, channel_id )
	local ok, ret_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)
	if not ok or not ret_tab or type(ret_tab) ~= "table" then 
		only.log('E', string.format('connect channel_dbname failed! [%s]', sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	--考虑添加错误码
	if #ret_tab == 0 then
		only.log('E',string.format(' service channel record not exists ,sql_str:[%s] ' , sql_str) )
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], "service channel record not exists" )	
	end

	if #ret_tab > 1 then
		only.log('E',string.format(' service channel record > 1 ,sql_str:[%s] ' , sql_str) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	return ret_tab[1]
end

local function get_next_custom_type( )

	local sql_str = G.sql_select_checkinfo 
	local ok, res = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)
	if not ok or not res or type(res) ~= "table" then 
		only.log('E', string.format('connect channel_dbname failed!'))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	-- 若 userCustomDefineInfo 为空, custom_type 默认从10且递增
	-- 否则从最大 custom_type 的开始递增
	local custom_type = nil
	if #res == 0 then
		custom_type = 10
		return custom_type
	end

	local max_value = tonumber(res[1]["maxCustomTypeValue"])
	if not max_value or max_value < 10 then
		only.log('E',string.format(' get_next_custom_type error,customType:[%d], sql_str:[%s] ', max_value, sql_str) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	custom_type = max_value + 1

	return custom_type

end

local function check_origin_check_status( origin_check_status )

	if origin_check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REJECT then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], " 该频道已被驳回，请待用户修改之后提交审核 " )	
	end

	if origin_check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], " 该频道已经审核通过，不用再审核 " )	
	end

	if origin_check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REDISMISSED then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], " 该频道已经重审驳回，请待用户修改之后提交审核 " )	
	end

	if origin_check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REAGREE then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], " 该频道已经重审通过，不用再审核 " )
	end

end


local function get_channel_status_of_user( check_status )
	
	local channel_status = nil
	if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REJECT or 
		check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REDISMISSED then
		channel_status = cur_utils.SERVICE_CHANNEL_USER_STATUS_REJECT 
	end

	if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE or 
		check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REAGREE then
		channel_status = cur_utils.SERVICE_CHANNEL_USER_STATUS_AGREE 
	end

	return channel_status
end

-- 审核驳回(申请阶段)
-- 1.更新申请 apply 表
local function check_service_channel_reject( account_id, channel_id, check_accountID, check_status, check_remark, app_key )
	
	local channel_number = ''
	local check_time = os.time()
	local update_time = check_time
	local channel_status = get_channel_status_of_user( check_status )

	local sql_str = string.format(G.sql_update_apply_info, channel_number, check_accountID, check_time, 
										check_status, check_remark, app_key, channel_status, update_time,
											account_id, channel_id) 

	local ok_status, ret = mysql_api.cmd(channel_dbname, 'UPDATE', sql_str)
	if not ok_status then
		only.log('E',string.format("update failed, sql_str:[%s]", sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

end

-- 审核通过(申请阶段)
-- 1.更新申请 apply 表
-- 2.插入数据到审核通过 check 表
-- 3.插入频道信息到 userCustomDefineInfo 表
local function check_service_channel_agree( channel_tab, account_id, channel_id, check_accountID, check_status, check_remark, app_key)

	-- 审核成功
	local sql_tab = {}

	-- APPLY
	local channel_number = gen_unique_number()
	local check_time     = os.time()
	local update_time    = check_time
	local channel_status = get_channel_status_of_user( check_status )

	local sql_str = string.format(G.sql_update_apply_info, channel_number, check_accountID, check_time, 
										check_status, check_remark, app_key, channel_status, update_time,
											account_id, channel_id) 
	table.insert(sql_tab, sql_str)

	-- CHECK
	local channel_url  = channel_tab['channelUrl']
	local channel_name = channel_tab['channelName']
	local logo_url     = channel_tab['logoUrl']
	local brief_intro  = channel_tab['briefIntro']
	local apply_appKey = channel_tab['applyAppKey']

	local create_time = check_time
	local validity    = 1
	local remark      = '审核通过(申请阶段)'

	sql_str = string.format(G.sql_insert_agree_data, account_id, channel_number, channel_url, channel_name, logo_url, 
												brief_intro, check_accountID, check_time, check_status, check_remark, app_key,
													create_time, update_time, validity, remark, apply_appKey)
	table.insert(sql_tab, sql_str)

	-- USERCUSTOMDEFINEINFO
	local action_type = 3
	local custom_type = get_next_custom_type()

	local is_system  = 1
	local remark     = "申请阶段 频道审核通过"
	local sort_index = 0
	local code_menu  = ""

	local sql_str = string.format(G.sql_insert_custom_info, account_id, action_type, custom_type, channel_url, logo_url, 
									channel_name, create_time, update_time, is_system, validity, remark, sort_index, code_menu, brief_intro)
	table.insert(sql_tab, sql_str)

	local ok_status, ret = mysql_api.cmd(channel_dbname, 'AFFAIRS', sql_tab)
	if not ok_status then
		only.log('E',string.format("do AFFAIRS failed, sql_tab: \r\n [%s]", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	return channel_number

end

local function check_modify_channel_exists(account_id, channel_number)

	local sql_str = string.format(G.sql_check_rechecking_channel, account_id, channel_number, cur_utils.SERVICE_CHANNEL_STATUS_OF_RECHECKING)
	only.log('D', string.format('=====sql_check_rechecking_channel:%s======', sql_str))

	local ok_status, ret_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)
	if not ok_status or not ret_tab or type(ret_tab) ~= 'table' then
		only.log('E',string.format('connect channel_dbname failed!, sql_str:[%s]', sql_str))
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	-- 无数据 (此频道重审阶段当前无修改记录) ,考虑添加错误码
	if #ret_tab == 0 then
		only.log('E',string.format('accountID channelNumber checkStatus recordset = 0, sql_str:[%s]', sql_str))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'no modify of this channel')
	end

	-- 内部数据错误
	if #ret_tab > 1 then
		only.log('E',string.format('accountID channelNumber checkStatus recordset > 1, sql_str:[%s]', sql_str))
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

	return ret_tab[1]

end

-- 重审驳回
-- 1.恢复 申请表apply 修改前的数据和审核状态
-- 2.修改 重申表modify 审核状态
local function recheck_service_channel_redismiss( modify_tab , account_id, channel_number, check_accountID, check_status, check_remark, app_key)

	local before_channelUrl  = modify_tab['beforeChannelUrl']
	local before_channelName = modify_tab['beforeChannelName']
	local before_logoUrl     = modify_tab['beforeLogoUrl']
	local before_briefIntro  = modify_tab['beforeBriefIntro']

	local check_time            = os.time()
	local before_check_status   = cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE -- 申请表恢复之前审核通过的频道状态
	local before_channel_status = cur_utils.SERVICE_CHANNEL_USER_STATUS_AGREE -- 重审驳回,申请表恢复之前审核通过的审核状态
	
	local update_time = check_time
	local remark      = "重审驳回, 恢复修改前的审核通过的数据和状态"


	local sql_tab = {}

	-- APPLY
	local sql_str = string.format(G.sql_change_apply_info, before_channelUrl,
															before_channelName,
															before_logoUrl,
															before_briefIntro,
															check_accountID,
															check_time,
															before_check_status, --
															check_remark,
															app_key,
															before_channel_status, --
															update_time,
															remark,
															account_id,
															channel_number)
	only.log('D', string.format('sql_change_apply_info:[%s]', sql_str))
	table.insert(sql_tab, sql_str)

	-- MODIFY
	-- -- 修改 重申表modify 审核状态
	channel_status = cur_utils.SERVICE_CHANNEL_STATUS_OF_REDISMISSED -- 重审驳回,重申表记录重审驳回的审核状态
	remark = "重审驳回, 更新审核信息"
	sql_str = string.format(G.sql_change_modify_check_status, check_accountID, 
																check_time, 
																check_status, 
																check_remark, 
																app_key,
																update_time,
																remark,
																account_id,
																channel_number)
	only.log('D', string.format('sql_change_modify_check_status:[%s]', sql_str))
	table.insert(sql_tab, sql_str)

	local ok_status, ret = mysql_api.cmd(channel_dbname, 'AFFAIRS', sql_tab)
	if not ok_status then
		only.log('E',string.format("do AFFAIRS failed, sql_tab: \r\n [%s]", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

-- 重审通过(重审阶段)
-- 1.修改 申请表apply 修改后的数据和审核状态
-- 2.修改 审核表check 修改后的数据和审核状态
-- 3.修改 重申表modify 审核状态
-- 4.修改 相应customType 的服务频道数据
local function recheck_service_channel_reagree( modify_tab , account_id, channel_number, check_accountID, check_status, check_remark, app_key)

	local after_channelUrl  = modify_tab['afterChannelUrl']
	local after_channelName = modify_tab['afterChannelName']
	local after_logoUrl     = modify_tab['afterLogoUrl']
	local after_briefIntro  = modify_tab['afterBriefIntro']

	local cur_time       = os.time()
	local check_time     = cur_time
	local channel_status = get_channel_status_of_user(check_status) -- 重审通过
	local update_time    = check_time
	local remark         = "重审通过"

	local sql_tab = {}

	-- APPLY
	-- -- 恢复 申请表apply 修改前的数据和审核状态(重审阶段,驳回/通过)
	local sql_str = string.format(G.sql_change_apply_info, after_channelUrl, 
															after_channelName, 
															after_logoUrl, 
															after_briefIntro,
															check_accountID,
															check_time,
															check_status,
															check_remark,
															app_key,
															channel_status,
															update_time,
															remark,
															account_id,
															channel_number)
	only.log('D', string.format('sql_change_apply_info:[%s]', sql_str))
	table.insert(sql_tab, sql_str)

	-- MODIFY
	-- -- 修改 重申表modify 审核状态(重审阶段,驳回/通过)
	sql_str = string.format(G.sql_change_modify_check_status, check_accountID,
																check_time,
																check_status,
																check_remark,
																app_key,
																update_time,
																remark,
																account_id,
																channel_number)
	only.log('D', string.format('sql_change_modify_check_status:[%s]', sql_str))
	table.insert(sql_tab, sql_str)

	-- CHECK
	sql_str = string.format(G.sql_update_check_info, after_channelUrl, 
														after_channelName, 
														after_logoUrl, 
														after_briefIntro,
														check_accountID,
														check_time,
														check_status,
														check_remark,
														app_key,
														update_time,
														remark,
														account_id,
														channel_number)
	only.log('D', string.format('sql_update_check_info:[%s]', sql_str))
	table.insert(sql_tab, sql_str)


	-- USERCUSTOMDEFINEINFO
	-- sql_update_usercustom = " update userCustomDefineInfo set callbackUrl = '%s', defineLogo = '%s', defineName = '%s', briefIntro = '%s', updateTime = '%s', remark = '%s' " .. 
	-- 						" where accountID = '%s' and customType = '%s' and validity = 1 "
	-- remark = '重审通过'
	-- sql_str = string.format(G.sql_update_usercustom, after_channelUrl, 
	-- 													after_channelName, 
	-- 													after_logoUrl, 
	-- 													after_briefIntro,
	-- 													cur_time,
	-- 													remark,
	-- 													account_id,
	-- 													custom_type)  --
	-- only.log('D', string.format('sql_update_check_info:[%s]', sql_str))
	-- table.insert(sql_tab, sql_str)

	local ok_status, ret = mysql_api.cmd(channel_dbname, 'AFFAIRS', sql_tab)
	if not ok_status then
		only.log('E',string.format("do AFFAIRS failed, sql_tab: \r\n [%s]", table.concat( sql_tab, "\r\n")) )
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end
	
end

local function handle()

	local req_ip           = ngx.var.remote_addr
	local req_head         = ngx.req.raw_header()
	local req_body         = ngx.req.get_body_data()
	local req_method       = ngx.var.request_method
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
		    -- 解析表单形式 		
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

	local account_id      = args['accountID']
	local info_type       = tonumber(args['infoType'])
	local channel_id      = args['channelID']
	local channel_number  = args['channelNumber']
	local check_accountID = args['checkAccountID']
	local check_status    = tonumber(args['checkStatus'])
	local check_remark    = args['checkRemark']
	local app_key         = args['appKey']

	--检查审核员ID是否在userList
	check_userinfo(check_accountID)
	
	-- 申请阶段
	if info_type == cur_utils.SERVICE_CHANNEL_APPLY_PERIOD then

		-- 检查该账号是否申请有该 channel_number 的服务频道
		local channel_tab = check_channel_exists( account_id, channel_id )

		-- 检查被审核的频道的审核状态
		local origin_check_status = tonumber(channel_tab['checkStatus'])
		check_origin_check_status( origin_check_status )

		-- 检查频道是否已被关闭

		--callbackUrl不明确，如有需要，在此处修改逻辑

		-- 频道审核状态处于 "0待审核" 才能审核频道(申请阶段)
		if origin_check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_CHECKING then

			-- 驳回
			if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REJECT then
				check_service_channel_reject( account_id, channel_id, check_accountID, check_status, check_remark, app_key )
			end

			-- 通过
			if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_AGREE then

				local ret_str = '{"channelNumber":"%s"}'
				local channel_number = check_service_channel_agree(channel_tab, account_id, channel_id, check_accountID, check_status, check_remark, app_key)

				ret_str = string.format(ret_str, channel_number)
				gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)

			end
		end
	end

	-- 重审阶段
	if info_type == cur_utils.SERVICE_CHANNEL_RECHECK_PERIOD then

		-- 检查频道审核状态
		local modify_tab =  check_modify_channel_exists(account_id, channel_number)

		-- 重审驳回
		if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REDISMISSED then

			-- 恢复 申请表apply 修改前的数据和审核状态
			-- 修改 重申表modify 审核状态
			recheck_service_channel_redismiss( modify_tab , account_id, channel_number, check_accountID, check_status, check_remark, app_key)

		end

		-- 重审通过
		if check_status == cur_utils.SERVICE_CHANNEL_STATUS_OF_REAGREE then

			-- 修改 申请表apply 修改后的数据和审核状态
			-- 修改 审核表check 修改后的数据和审核状态
			-- 修改 重申表modify 审核状态
			-- 修改 相应customType 的服务频道数据
			recheck_service_channel_reagree( modify_tab , account_id, channel_number, check_accountID, check_status, check_remark, app_key)
		end

	end

	gosay.go_success(url_tab, msg['MSG_SUCCESS'])

end

safe.main_call( handle )
