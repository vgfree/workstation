-- zhouzhe
-- 2015-06-02
-- 通过用户账号获取群聊频道关联关系

local ngx       	= require('ngx')
local utils     	= require('utils')
local app_utils     = require('app_utils')
local gosay     	= require('gosay')
local only      	= require('only')
local msg       	= require('msg')
local safe      	= require('safe')
local link      	= require('link')
local cjson     	= require('cjson')
local redis_api 	= require('redis_pool_api')
local mysql_api 	= require('mysql_pool_api')

local channel_dbname  = 'app_custom___wemecustom'

local url_info 	= { 
	type_name 	= 'system',
	app_key 		= '',
	client_host = '',
	client_body = '',
}

local G = {

	-- select_number = "SELECT customParameter FROM userKeyInfo WHERE accountID = '%s' AND customParameter != '' ",

	-- select_accountID = "SELECT accountID, actionType FROM userKeyInfo WHERE customParameter = '%s' ",

	sql_get_voicecommand_info = " select customParameter from userKeyInfo where validity = 1 and actionType = 4 and customType = 10 and accountID = '%s' " , 

	sql_get_groupvoice_info   = " select customParameter from userKeyInfo where validity = 1 and actionType = 5 and customType = 10 and accountID = '%s' " , 

	sql_accountid_list    = " select accountID ,  actionType , customParameter channelNumber, %s channelName from userKeyInfo where validity = 1 " .. 
						" and actionType in (4,5) and customType = 10 and accountID != '%s' and customParameter in ('%s') limit %d,%d  "
}


-- 检查参数
local function check_parameter(args)
	if not app_utils.check_accountID( args['accountID'])  then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end
	if not args['appKey'] or not utils.is_number(args['appKey'])  then
		only.log("E","appKey is error!")
		gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
	end

	if args['startPage'] and #args['startPage'] > 0 then
        if not tonumber(args['startPage'])  or string.find(args['startPage'],"%.") or tonumber(args['startPage']) <= 0  then
            only.log('E','startPage is error')
            gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'startPage')
        end
    end

    if args['pageCount'] and #args['pageCount'] > 0 then
        if  not tonumber(args['pageCount'])  or string.find(args['pageCount'],"%.") or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
            only.log("E","pageCount is error!")
            gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'pageCount')
        end
    end

	-- safe.sign_check( args, url_info )
	-- 20150720
	-- 为io部门使用
	safe.sign_check(args, url_info, 'accountID', safe.ACCESS_WEIBO_INFO)
end

local function get_accountid_list_by_number( accountid ,channel_num1 ,  channel_num2 , channel_name1 , channel_name2  , start_page, page_count )
	local append_filter = ""
	local append_field = ""
	if channel_num1 and not channel_num2 then
		append_filter =  channel_num1
		append_field = string.format(" case when customParameter = '%s'  then '%s' end   " , channel_num1, channel_name1 )
	elseif not channel_num1 and channel_num2 then
		append_filter =  channel_num2
		append_field = string.format(" case when customParameter = '%s'  then '%s' end   " , channel_num2, channel_name2 )
	elseif not channel_num1 and not channel_num2 then
		return nil
	elseif channel_num1 and channel_num2 then
		append_filter =  channel_num1 .. "','" ..channel_num2
		append_field = string.format(" case when customParameter = '%s'  then '%s' when customParameter ='%s' then '%s' end  " , channel_num1, channel_name1 , channel_num2, channel_name2 )
	end

	local sql_str = string.format(G.sql_accountid_list, append_field, accountid, append_filter , start_page, page_count )

	only.log('W', string.format('debug get_accountid_list_by_channelidx sql %s ' ,sql_str ) )

	local ok, ret   = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table"  then 
		only.log('E', string.format('get get_accountid_list_by_channelidx failed %s ' ,sql_str ) )
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end
	return ret
end

local function get_channel_info( channel_num , channel_idx_ex )

	local channel_idx  = nil
	if channel_idx_ex then
		channel_idx = channel_idx_ex
	else
		local ok, channel_idx_new = redis_api.cmd('private','get',channel_num .. ":channelID")
		if not ok or not channel_idx_new then
			only.log('E', string.format('get user_channel  %s:channelNumer failed ' ,channel_num ) )
			gosay.go_false(url_info,msg['MSG_DO_REDIS_FAILED'])
		end
		channel_idx = channel_idx_new
	end

	local ok, channel_name = redis_api.cmd('private','hget', channel_idx .. ":userChannelInfo","channelName")
	if not ok or not channel_name then
		only.log('E', string.format('hget user_channel  %s:userChannelInfo channelName failed   ' ,user_channel ) )
		gosay.go_false(url_info,msg['MSG_DO_REDIS_FAILED'])
	end
	return channel_name
end


local function get_userkey_info_detail ( accountid , action_type )

	local action_info = {
		[4] = {
				sql_str = G.sql_get_voicecommand_info,
				sql_filters = G.sql_voicecommand_accountid_list,
				redis_key = "currentChannel:voiceCommand"
			},
		[5] = {
				sql_str = G.sql_get_groupvoice_info,
				sql_filters = G.sql_groupvoice_accountid_list,
				redis_key = "currentChannel:groupVoice",
			},
	}

	local sql_str = string.format( action_info[action_type]["sql_str"] ,accountid)
	local ok, ret   = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not ret or type(ret) ~= "table"  then 
		only.log('E', string.format('get sql_get_voicecommand_info failed %s ' ,sql_str ) )
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end

	local channel_num = nil
	local channel_idx = nil
	if #ret == 1 then
		channel_num = ret[1]['customParameter']
	else
		local ok, tmp_val = redis_api.cmd('private','get',accountid .. action_info[action_type]["redis_key"]  )
		if ok and tmp_val then
			local ok , channel_number = redis_api.cmd('private','get', tmp_val .. ":channelNumber" )
			if ok and channel_number then
				channel_idx = tmp_val
				channel_num = channel_number
			end
		end
	end
	if not channel_num then
		return nil
	end

	local channel_name = get_channel_info(channel_num,channel_idx)
	return channel_num , channel_name
end


local function handle()

	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()

	if not body then 
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	
	url_info['client_host'] = ip
	url_info['client_body'] = body

	local args = utils.parse_url(body)

	if not args or type(args) ~= "table" then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], args)
	end

 	-- 参数检查
	check_parameter(args)

	url_info["app_key"] = args['appKey']

	local start_page = tonumber(args['startPage']) or 1
	local page_count = tonumber(args['pageCount']) or 20
	local start_index = (start_page-1) * page_count
	if start_index < 0 then
		start_index = 0 
	end

	local accountid = args['accountID']

	local channel_num1 , channel_name1 = get_userkey_info_detail ( accountid, 4  )
	local channel_num2 , channel_name2 = get_userkey_info_detail ( accountid, 5  )

	local accountids = get_accountid_list_by_number( accountid , channel_num1 , channel_num2 , channel_name1 , channel_name2, start_index, page_count )
	local user_count = 0 
	local user_list = "[]"
	if accountids and #accountids > 0 then
		local ok, ret = pcall(cjson.encode, accountids )
		if ok and ret then
			user_list = ret
			user_count = #accountids
		end
	end

	local str = string.format('{"userCount":"%s","userList":%s}',  user_count , user_list )
	if str then
		gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		gosay.go_false(url_info, msg['SYSTEM_ERROR'])
	end
end

safe.main_call( handle )



