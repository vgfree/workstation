---- jiang z.s. 
---- 2014-11-03 
---- 获取自己所关注的所有微频道列表  --user

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
local appfun    = require('appfun')



local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {

	sql_check_accountid = "SELECT 1 FROM userList WHERE accountID='%s' limit 1 ",
	---- 获取当前用户关注的微频道编号
	sql_get_followChannel_num = "SELECT number FROM followUserList WHERE accountID  = '%s' and validity = 1 limit %d,%d  ",
	---- 根据编号获取频道详情
	sql_get_followChannel_info = "SELECT  accountID, number,name,introduction,chiefAnnouncerIntr,logoURL,catalogName , cityName ,cityCode,  '' as chiefAnnouncerName ,userCount " ..
								"FROM checkMicroChannelInfo WHERE number in ( %s ) and channelStatus != 3 order by id desc limit %d,%d ",
}

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

-->chack parameter
local function check_parameter(args)
	if not app_utils.check_accountID(args['accountID']) then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
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
	safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

---- 对accountID进行数据库校验
local function check_userinfo(account_id)
	local sql_str = string.format(G.sql_check_accountid,account_id)
	local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
	if not ok_status or not user_tab then
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


local function get_nickname(accountID)
	local ok,nickname = redis_api.cmd('private','get',accountID..':nickname')
	if not ok then
		only.log('E',"redis get chiefAnnouncerName failed [%s]",accountID)
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	end
	return nickname or ''

end

---- 
local function get_user_followlist_microchannel( accountid ,startIndex,pageCount)
	---- 获取当前用户关注的微频道编号
	local sql_num = string.format(G.sql_get_followChannel_num,accountid, startIndex,pageCount )
	local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_num)
								
	if not ok or not ret then
		only.log('E','connect channel_dbname faile')	
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	
	if #ret == 0 then
		return nil
	end

	local new_ret = {}
	for i,v in pairs(ret) do
		table.insert(new_ret,v['number'])
	end
	local filter_number = string.format("'%s'", table.concat( new_ret, "','"))

	---- 根据编号获取频道详情
	local sql_str = string.format(G.sql_get_followChannel_info, filter_number, startIndex, pageCount)
	only.log('D',sql_str)
	local ok, tab  = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
	if not ok or not tab  then
		only.log('E', string.format('connect channel_dbname failed!, %s ' , sql_str) )
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end

	---- 获取主播名
	for i, info in pairs(tab) do
		tab[i]['chiefAnnouncerName'] = get_nickname(info['accountID'])
	end

	return tab
end

local function handle()

	local req_ip   = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	url_tab['client_host'] = req_ip
	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_body'] = req_body
	local args = utils.parse_url(req_body)
	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
	end
	
	url_tab['app_key'] = args['appKey']
	---- 传入参数语法校验
	check_parameter(args)

	local accountid  =  args['accountID']
	---- 对accountID进行数据库校验
	check_userinfo(accountid)
	
	local startPage = tonumber(args['startPage']) or 1
	local pageCount = tonumber(args['pageCount']) or 20
	local  startIndex = (startPage - 1) * pageCount

	---- 获取自己所关注的所有微频道列表
	local ret = get_user_followlist_microchannel(accountid,startIndex,pageCount) 

	local count = 0
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
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

safe.main_call( handle )
