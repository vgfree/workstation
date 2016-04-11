-- zhouzhe
-- 2015-07-22
-- 通过获取imei获取所在频道编号

local ngx       = require('ngx')
local utils     = require('utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local http_api  = require('http_short_api')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')

local url_info = { 
	type_name = 'system',
	app_key = nil,
	client_host = nil,
	client_body = nil,
}
local custom_daname = 'app_custom___wemecustom'
local user_dbname = 'app_usercenter___usercenter'

local G = {
	-- 获取accountID
	select_accountID = " SELECT accountID FROM userList WHERE userStatus IN(1,4,5) AND imei='%s' ",

	-- 获取频道编号
	select_channel_number = " SELECT actionType, customParameter FROM userKeyInfo WHERE validity =1 AND accountID='%s' AND actionType IN(4,5) ",
}

-- 检查参数
local function check_parameter(args)

	if not args or type(args) ~= "table" then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
	end
	if not args['appKey'] or not utils.is_number(args['appKey'])  then
		only.log("E","appKey is error!")
		gosay.go_false( url_info, msg["MSG_ERROR_REQ_ARG"], "appKey" )
	end
	for i=1, #args['imeis'] do
		-- only.log("D", "imei is %s", args['imeis'][i])
		if #args['imeis'][i] ~= 15 then
			only.log("E", "imei is error")
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "imei")
		end
	end
end

-- 获取用户acountID
local function get_member_accountid(imeis)

	local failed = {}
	local success = {}
	local aid_tab = {}
	local i, k  = 1, 1

	-- 获取频道编号
	for _, imei in pairs(imeis) do
		if not imei or imei==''  then
			only.log("E","imei===error!")
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "imei")
		end
		local sql = string.format(G.select_accountID, imei)
		local ok, result = mysql_api.cmd( user_dbname, 'SELECT', sql)
		if not ok and not result then
			only.log("E","select_accountID is error!")
			gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
		end

		if #result < 1 then
			only.log("W", "select_accountID imei is error!")
			aid_tab['IMEI'] = imei
			failed[i]=aid_tab
			i = i+1
		else
			aid_tab['imei'] = imei
			aid_tab['accountID'] = result[1]['accountID']
			success[k]=aid_tab
			k = k+1
		end
		aid_tab = {}
	end
	return success, failed
end

-- 获取频道名称
local function get_channel_info( channel_num )

	local channel_idx  = nil

	local ok, channel_idx_new = redis_api.cmd('private','get',channel_num .. ":channelID")
	if not ok or not channel_idx_new then
		only.log('E', string.format('get user_channel  %s:channelNumer failed ' ,channel_num ) )
		gosay.go_false(url_info,msg['MSG_DO_REDIS_FAILED'])
	end
	channel_idx = channel_idx_new

	local ok, channel_name = redis_api.cmd('private','hget', channel_idx .. ":userChannelInfo","channelName")
	if not ok or not channel_name then
		only.log('E', string.format('hget user_channel  %s:userChannelInfo channelName failed   ' ,user_channel ) )
		gosay.go_false(url_info,msg['MSG_DO_REDIS_FAILED'])
	end
	return channel_name
end

-- 获取频道信息
local function get_channel_number(success )

	local table={}
	local k = 1
	for _, table_res in pairs(success) do
		local tab_tmp = {}
		local accountID = table_res['accountID']
		local imei = table_res['imei']
		local sql = string.format(G.select_channel_number, accountID )
		local ok, result = mysql_api.cmd( custom_daname, 'SELECT', sql)
		only.log("D"," select_channel_number,%s", sql)
		if not ok or not result then
			only.log('E',"sel_channel_name is error, %s", sql)
			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
		end

		for _, value in pairs(result) do
			local tab_res = {}
			tab_res['accountID'] = accountID
			tab_res['IMEI'] = imei
			tab_res['actionType'] = value['actionType']
			tab_res['channelNumber'] = value['customParameter']
			tab_res['channelName'] = get_channel_info( value['customParameter'] )
			table[k] = tab_res
			tab_res = {}
			k = k+1
		end
	end
	return table
end

function handle( )

	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()

	if not body then 
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	
	url_info['client_host'] = ip
	url_info['client_body'] = body

	local args = utils.parse_url(body)
	url_info["app_key"] = args['appKey']

	safe.sign_check(args, url_info )

	local imei_tab = utils.str_split(args["imeis"], ',')

	if not imei_tab or type(imei_tab) ~= 'table' then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'imei')
	end

	args['imeis'] = imei_tab

	-- 检查参数
	check_parameter(args)
	local table = {}
	-- 获取accountID
	local success, failed = get_member_accountid(args['imeis'])
	-- 获取频道名称和频道编号
	local success = get_channel_number(success)
	-- 返回参数处理

	local ret = '{"failed":%s,"success":%s}'
	local ok, res, str = nil,'[]', '[]'
	if success and #success > 0 then  
		ok, res = pcall(cjson.encode, success )
	end
	if failed and #failed > 0 then
		ok, str = pcall(cjson.encode, failed )
	end
	if not ok then
		gosay.go_false(url_info, msg['SYSTEM_ERROR'])
	end
	ret = string.format(ret, str, res)
	gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )
