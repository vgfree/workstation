
--> authore: guoqi
local msg	 = require('msg')
local safe	 = require('safe')
local only	 = require('only')
local gosay	 = require('gosay')
local utils	 = require('utils')
local mysql_api	 = require('mysql_pool_api')
local redis_api	 = require('redis_pool_api')

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil
}

local account_tab={}

local G = {
	sql_account = [[ SELECT 1 FROM userList WHERE accountID = '%s']],
	sql_group = [[SELECT groupType FROM groupInfo WHERE groupID = '%s' and validity = 1]],
	sql_user = [[SELECT accountID FROM userList WHERE imei = '%s']],
	sql_select = [[SELECT * FROM userGroupInfo WHERE groupID = '%s' and accountID = '%s']],
	sql_group_abbr = [[SELECT 1 FROM groupInfo WHERE groupID='%s' and validity = 1]],
	sql_user_group = [[INSERT INTO userGroupInfo(groupID,accountID,groupType,createTime,updateTime) VALUES ('%s','%s',%d,%d,%d)]],
	sql_insert = [[INSERT INTO userGroupHistory (groupID,accountID,groupType,validity,updateTime) VALUE ('%s','%s',%d,%d,%d)]],
	sql_update = [[UPDATE userGroupInfo SET validity = 1,updateTime = %d WHERE groupID = '%s' AND accountID = '%s']],
}


local function check_parameter(args)
	if not utils.is_word(args['groupID']) or string.len(args['groupID']) ~= 16 then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'groupID')
	end
	if not args['accountID'] then
		only.log("E","accountID is nil")
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end
	local len = string.len(args['accountID'])
	if len ~= 10 and len ~= 15 then
		local count = string.sub(args['accountID'],2,-2)
		local tab = utils.str_split(count,',')
		--> 验证参数，分离accountID	
		args['account_tab'] = {}
		for k,v in pairs(tab) do
			if not utils.is_word(v) or string.len(v) ~= 10 then
				table.insert(account_tab,v)
			else
				table.insert(args['account_tab'],v)
			end
		end
		if #args['account_tab']==0 then
			only.log("E","AccountID is illegal")
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
		end
	else
		if not utils.is_word(args['accountID']) then
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
		end
	end
	safe.sign_check(args,url_info,"accountID",safe.ACCESS_USER_INO)
end

local function add_member(args,account_id,groupType,time)
	only.log("D",account_id)
	--> 根据accountID和groupID在数据库中查询是否已有记录
	local sql = string.format(G.sql_select,args['groupID'],account_id)
	local ok,res = mysql_api.cmd("app_custom___wemecustom",'select',sql)
	if not ok then
		only.log("E",string.format("the sql does error : [[%s]]",sql))
		return false
	-->无记录则直接插入信息
	elseif #res==0 then
		local sql = string.format(G.sql_user_group,args['groupID'],account_id,groupType,time,time)

		local ok,ret = mysql_api.cmd('app_custom___wemecustom','insert',sql)
		if not ok then
			only.log("E",string.format("the sql does error : [[%s]]",sql))
			return false
		else
			local ok,res = redis_api.cmd("statistic","sadd", args['groupID'] .. ":members",account_id)
			if not ok then
				only.log("E",string.format("Save %s to an error occurred in redis",account_id))
			end
		end

	--> 若有记录但其validity=0
	-->则保存一条记录在history，并修改validity=1
	elseif res[1]['validity']=='0' then
		local tab = res[1]
		local sql_tab={}
		local insert_sql = string.format(G.sql_insert,tab['groupID'],tab['accountID'],tab['groupType'],tab['validity'],tab['updateTime'])
		table.insert(sql_tab,insert_sql)
		local update_sql = string.format(G.sql_update,time,tab['groupID'],account_id)
		table.insert(sql_tab,update_sql)
		local ok,res = mysql_api.cmd("app_custom___wemecustom","AFFAIRS",sql_tab)
		if not ok then
			only.log("E",string.format("[[%s]]and [[%s]] does error",sql_tab['insert_sql'],sql_tab['update_sql']))
			return false
		else
			local ok,res = redis_api.cmd("statistic","sadd",args['groupID'] .. ":members",account_id)
			if not ok then
				only.log("E",string.format("Save %s to an error occurred in redis",account_id))
			end
		end

	-->若有记录且validity=1则排除该accountID
	else
		return false
	end
	return true
end




local function handle()
	local req_ip = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()

	if not req_body then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_NO_BODY'])
	end
	local args = utils.parse_url(req_body)
	if not args then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'args')
	end

	url_info['client_host'] = req_ip
	url_info['client_body'] = req_body

	check_parameter(args)

	--> 校验groupID
	local sql = string.format(G.sql_group,args['groupID'])
	local ok,res = mysql_api.cmd("app_custom___wemecustom","select",sql)
	
	if not ok then
		only.log("E",string.format("the sql does error : [[%s]]",sql))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
	if #res==0 then
		only.log("E","the groupID does not exist!")
		gosay.go_false(url_info,msg['MSG_ERROR_GROUP_ID_NOT_EXIST'])
	end
	
	local groupType = res[1]['groupType']

	--> 校验accountID
	if not args['account_id'] then
		if string.len(args['accountID']) == 10 then
			local sql = string.format(G.sql_account,args['accountID'])
			local ok,ret = mysql_api.cmd("app_usercenter___usercenter","select",sql)
			if not ok then
				only.log("E",string.format("the sql does error : [[%s]]",sql))
			end
			if #ret == 0 then
			end
		else
			local ok,res = redis_api.cmd("statistic","sismember",appKey .. ":authorizeIMEI",v)
			if not ok then
				only.log("E",string.format("select %s to an error occurred in redis",v))
				gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
			end
			if not res then
			else
				local sql = string.format(G.sql_user,v)
				local ok,res = mysql_api.cmd("app_usercenter___usercenter","select",sql)
				if not ok then
					only.log("E",string.format("the sql does error : [[%s]]",sql))
					gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
				end
				args['accountID'] = res[1]['accountID']
			end
		end
	else
		for k,v in pairs(args['account_tab']) do
			local sql = string.format(G.sql_account,v)
	
			local ok,ret = mysql_api.cmd("app_usercenter___usercenter","select",sql)
			if not ok then
				only.log("E",string.format("the sql does error : [[%s]]",sql))
				table.insert(account_tab,v)
				table.remove(args['account_tab'],k)
			elseif #ret==0 then
				table.insert(account_tab,v)
				table.remove(args['account_tab'],k)
			end
		end
	end
	
	local time = os.time()
	if not args['account_tab'] then
		local ok = add_member(args,args['accountID'],groupType,time)
		if not ok then
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],string.format("add member:%s",args['accountID']))
		end
		gosay.go_success(url_info,msg['MSG_SUCCESS'])
	else
		for k,v in pairs(args['account_tab']) do
			only.log("D",'accountID')
			only.log("D",v)
			local ok = add_member(args,v,groupType,time)
			if not ok then
				table.insert(account_tab,v)
			end
		end
		local tab = {}
		tab['error'] = account_tab
		local ok,ret = utils.json_encode(tab)
		only.log("D",ret)
		gosay.go_success(url_info,msg['MSG_SUCCESS_WITH_RESULT'],ret)
	end
end
handle()
