
local msg              = require('msg')
local only             = require('only')
local safe             = require('safe')
local link             = require('link')
local utils            = require('utils')
local gosay            = require('gosay')
local appfun           = require('appfun')
local app_utils        = require('app_utils')
local redis_api        = require("redis_pool_api")
local mysql_api        = require("mysql_pool_api")
-- local account_utils = require('account_utils')
local crazy_utils      = require('crazy_utils')

local txt2voice     = link.OWN_DIED.http.txt2voice

local channel_dbname = "app_custom___wemecustom"
local app_cli_dbname = "app_cli___cli"

local G = {
	sql_get_all_data                  = " select idx, number, name, introduction, cityCode, cityName, catalogID, catalogName, channelNameURL, accountID,	createTime, channelStatus from checkMicroChannelInfo ",
	sql_get_all_secret_data           = " select idx, number, name, introduction, cityCode, cityName, catalogID, catalogName, channelNameURL, accountID,	createTime, channelStatus from checkSecretChannelInfo ",
	sql_select_nickname               = " select nickname, accountID from userInfo where nickname != '' and status = 1 and accountID != '' ",
	sql_select_micro_channel_name     = " select idx, name from checkMicroChannelInfo  where channelNameURL = ''  %s ",
	sql_select_secret_channel_name    = " select idx, name from checkSecretChannelInfo  where channelNameURL = ''  %s ",
	sql_update_micro_channel_nameurl  = " update checkMicroChannelInfo set channelNameURL = '%s' where idx = '%s' ",
	sql_update_secret_channel_nameurl = " update checkSecretChannelInfo set channelNameURL = '%s' where idx = '%s' ",
}


local url_info = {
	type_name   = 'system',
	app_key     = nil,
	client_host = nil,
	client_body = nil
}

local function_keys = {
	[1] = tonumber(appfun.CHANNEL_TYPE_MICRO) or 0,		--微频道redis数据
	[2] = tonumber(appfun.CHANNEL_TYPE_SECRET) or 0,	--密频道redis数据
	[3] = 3,											--用户nickname url
	[4] = 4,											--微频道名channelName url
	[5] = 5,											--密频道名channelName url
}


local function check_parameter(args)

	if not args['keyType'] then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],"keyType")
	end

	local key_type = tonumber(args['keyType'])
	--假定数组功能键从1开始，且是连续的正整数
	if not key_type or key_type > #function_keys or key_type < 1 then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "keyType")
	end

	if not args['count'] or string.find(args['count'], "%.") then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],"count")
	end

	if args['count'] ~= '' then
		local count = tonumber(args['count'])
		if not count or count < 1 then
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],"count")
		end
	end

	safe.sign_check(args, url_info)
end


local function set_channel_idx_number( channel_num, channel_idx , owner , cur_time , capacity , channel_type,  open_type , check_status,
		citycode ,cityname ,catalogid , catalogname ,channelname,introduction,channelname_url )

	only.log('W', string.format( "channel_num:%s channel_idx:%s  owner:%s  cur_time:%s  capacity:%s \r\n" ..
														" channel_type:%s open_type:%s , citycode %s ,cityname %s ,catalogid %s, " .. 
														" catalogname %s,channelname %s ,introduction %s ,channelname_url :%s", 
														channel_num, 
														channel_idx , 
														owner , 
														cur_time , 
														capacity , 
														channel_type , 
														open_type ,
														citycode ,
														cityname ,
														catalogid , 
														catalogname ,
														channelname,
														introduction ,
														channelname_url
														)
													)

	if #tostring(channel_idx) < 9 then
		only.log('E',string.format("channel_idx %s   length   is error !" ,channel_idx ) )
		return false
	end

	---- 设置频道编号与频道ID对应的关系
	redis_api.cmd('private','set',string.format("%s:channelID",channel_num), channel_idx)
	redis_api.cmd('private','set',string.format("%s:channelNumber",channel_idx), channel_num)
	redis_api.cmd('private','set',string.format("%s:channelType",channel_idx), channel_type)
	redis_api.cmd('private','set',string.format("%s:channelStatus",channel_idx), check_status)
	

	if channelname_url then
		---- 只有微频道才有url 2014-12-19 jiang z.s.
		redis_api.cmd('private','set',string.format("%s:channelNameUrl",channel_idx),channelname_url)
	end

	---- 频道的创建者 owner 
	---- 频道的创建时间 createTime 
	---- 频道的最大容量 capacity
	redis_api.cmd('private','hmset',string.format("%s:userChannelInfo",channel_idx), 
							"owner", owner , 
							"createTime", cur_time,
							"capacity", capacity, 
							"channelType", channel_type ,
							"openType", open_type or 0,
							"cityCode", citycode ,
							"cityName", cityname ,
							"catalogID", catalogid ,
							"catalogName", catalogname ,
							"channelName", channelname,
							"introduction", introduction )
end


local function init_micro_redis_data()
	
	local sql_str = G.sql_get_all_data
	local ok_status, result_tab =  mysql_api.cmd(channel_dbname, 'SELECT' ,sql_str)
	if not ok_status or not result_tab or type(result_tab) ~= 'table' then
		only.log('D', string.format("DO MYSQL FAILED [%s]", sql_str))
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end	

	local sum = #result_tab
	only.log('D',string.format('[==========micro record sum:%d=============]', sum))

	if sum < 1 then return false end

	for i=1,sum do		
		local channel_num     = result_tab[i]['number']
		local channel_idx     = result_tab[i]['idx']
		local owner           = result_tab[i]['accountID']
		local cur_time        = result_tab[i]['createTime']
		local capacity        = 0
		-- local channel_type = 1
		local channel_type    = appfun.CHANNEL_TYPE_MICRO
		local open_type       = 1
		local check_status    = result_tab[i]['channelStatus']
		local citycode        = result_tab[i]['cityCode']
		local cityname        = result_tab[i]['cityName']
		local catalogid       = result_tab[i]['catalogID']
		local catalogname     = result_tab[i]['catalogName']
		local channelname     = result_tab[i]['name']
		local introduction    = result_tab[i]['introduction']
		local channelname_url = result_tab[i]['channelNameURL']
		set_channel_idx_number( channel_num, channel_idx , owner , cur_time , capacity , channel_type,  open_type , check_status,
			citycode ,cityname ,catalogid , catalogname ,channelname,introduction,channelname_url )
		only.log('D', string.format(">>>>>>>>>>>>>[fix micro redis data LOOP %d] SUCCESS<<<<<<<<<<<", i))	
	end
end

local function init_secret_redis_data()

	local sql_str = G.sql_get_all_secret_data
	local ok_status, result_tab =  mysql_api.cmd(channel_dbname, 'SELECT' ,sql_str)
	if not ok_status or not result_tab or type(result_tab) ~= 'table' then
		only.log('D', string.format("DO MYSQL FAILED [%s]", sql_str))
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end

	local sum = #result_tab
	only.log('D',string.format('[==========micro record sum:%d=============]', sum))
	if sum < 1 then return false end

	for i=1, sum do
		local channel_num     = result_tab[i]['number']
		local channel_idx     = result_tab[i]['idx']
		local owner           = result_tab[i]['accountID']
		local cur_time        = result_tab[i]['createTime']
		local capacity        = result_tab[i]['capacity']
		local channel_type    = appfun.CHANNEL_TYPE_SECRET
		local open_type       = result_tab[i]['openType']
		local check_status    = result_tab[i]['channelStatus']
		local citycode        = result_tab[i]['cityCode']
		local cityname        = result_tab[i]['cityName']
		local catalogid       = result_tab[i]['catalogID']
		local catalogname     = result_tab[i]['catalogName']
		local channelname     = result_tab[i]['name']
		local introduction    = result_tab[i]['introduction']
		local channelname_url = result_tab[i]['channelNameURL']
		set_channel_idx_number( channel_num, channel_idx , owner , cur_time , capacity , channel_type,  open_type , check_status,
			citycode ,cityname ,catalogid , catalogname ,channelname,introduction,channelname_url )
		only.log('D', string.format(">>>>>>>>>>>>>[secret LOOP %d] SUCCESS<<<<<<<<<<<", i))	
	end
end


function save_redis( account_id, nick_name, status)

	local x = nil
    for i=1, 3 do

    	x = i
        local ok,res = crazy_utils.after_set_nickname(account_id, nick_name, status)

        if ok then
            return true
        end

    end

    if x == 3 then
        only.log('D', string.format("fail to set nickname [=nickname=][nickname:%s, account_id:%s]", nick_name, account_id))
    end

end



local function init_nick_name_url_redis_data()

	
	local sql_str = G.sql_select_nickname
	local ok_status, result_tab = mysql_api.cmd(app_cli_dbname, 'SELECT', sql_str)

	if not ok_status or not result_tab or type(result_tab) ~= 'table' then
		only.log('D', string.format("DO MYSQL FAILED [%s]", sql_str))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
	
	local sum = #result_tab
	only.log('D',string.format('[==========userInfo record sum:%d=============]', sum))

	local status = 1
	for i=1, sum do
		save_redis(result_tab[i]['accountID'], result_tab[i]['nickname'], status)
	end	
end



---- 对名称名称设置对应的url 
local function channelname_2_voice( channel_name ,app_key )

	local txt2voice = link["OWN_DIED"]["http"]["txt2voice"]
	app_key = "2973785773"
	local secret = "D626681ED77073574611AE386010067269C602CE"

	local tab = {
		appKey = app_key,
		text = channel_name,
	}
	tab['sign'] = app_utils.gen_sign(tab, secret)
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


local function init_channel_name_url_redis_data(key_type, total, app_key)
	
	local sub_limit_str = " limit %s "
	if total == '' then
		sub_limit_str = ''
	else
		sub_limit_str = string.format(sub_limit_str, total)
	end

	local sql_str = nil
	local channel_name_prefix = nil
	if key_type == function_keys[4] then
		sql_str = string.format(G.sql_select_micro_channel_name, sub_limit_str)
		channel_name_prefix = "微频道"
	else
		sql_str = string.format(G.sql_select_secret_channel_name, sub_limit_str)
		channel_name_prefix = "频道"
	end

	local ok_status, result_tab = mysql_api.cmd(channel_dbname, 'SELECT', sql_str)
	if not ok_status or not result_tab or type(result_tab) ~= 'table' then
		only.log('D', string.format("DO MYSQL FAILED [%s]", sql_str))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	local sum = #result_tab
	only.log('D',string.format('[==========name url record sum:%d=============]', sum))

	local pattern_1 = '频道'
	local pattern_2 = '车队'
	local success_count = 0
	if sum > 0 then
		
		for i=1,sum do
	
			local idx = result_tab[i]['idx']
			
			--针对群聊频道中含有“车队”、“频道”的，保持原有频道名(2015/06/24)
			if key_type == function_keys[5] then
				if string.find(result_tab[i]['name'], pattern_1) or string.find(result_tab[i]['name'], pattern_2) then
					channel_name_prefix = ''
				end
			end

			local tmp_channelname = string.format("%s%s" , channel_name_prefix, result_tab[i]['name'])
			local ok_status, url_str = get_channelname_url(tmp_channelname, app_key)
			if not ok_status then
				only.log('D', string.format('[url failed index:%s]get channelname url failed [ *** channel\' name:%s]', idx, tmp_channelname))
			end
			
			if ok_status then
				only.log("D", string.format("[url success index:%s]Get url SUCCESS[%s]", idx, tmp_channelname))
				--维护redis
				if url_str then
					redis_api.cmd('private','set',string.format("%s:channelNameUrl", idx), url_str)
				end			
	
				--维护mysql
				local sql_str = nil
				if key_type == function_keys[4] then
					sql_str = string.format(G.sql_update_micro_channel_nameurl, url_str, idx)
				else
					sql_str = string.format(G.sql_update_secret_channel_nameurl, url_str, idx)
				end

				local ok_status, result_tab = mysql_api.cmd(channel_dbname, 'UPDATE', sql_str)
	
				if not ok_status then 
					only.log('D', string.format('update channel name url failed sql:[%s]' , sql_str))
					gosay.go_false(url_info ,msg['MSG_DO_MYSQL_FAILED'])
				end
	
				if ok_status then
					success_count = success_count + 1
					only.log("D", string.format("[db success index:%s]Get url SUCCESS[%s]", idx, tmp_channelname))
				end
			end
	
		end
	end
	
	return success_count

end

local function handle()

	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	url_info['client_host'] = req_ip

	if not req_body then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_info['client_body'] = req_body

	local args = utils.parse_url(req_body)
	if not args then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],"args")
	end
	check_parameter(args)

	url_info['app_key'] = args['appKey']
	local app_key = args['appKey']

	local key_type = tonumber(args['keyType'])
	if key_type == function_keys[1] then
		init_micro_redis_data()
	end

	if key_type == function_keys[2] then
		init_secret_redis_data()
	end

	if key_type == function_keys[3] then
		init_nick_name_url_redis_data()
	end

	local total = args['count']
	local micro_success_count = nil
	local secret_success_count = nil
	local ret = nil
	if key_type == function_keys[4] or key_type == function_keys[5] then 
		success_count = init_channel_name_url_redis_data(key_type, total, app_key)
		ret = string.format('{"total":"%s", "successCount":"%s"}', total, success_count)
	end 


	gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end

safe.main_call( handle )