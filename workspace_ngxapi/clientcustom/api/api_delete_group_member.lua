
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

local G = {
	sql_account = [[ SELECT 1 FROM userList WHERE accountID = '%s']],
	sql_group = [[SELECT groupType FROM groupInfo WHERE groupID = '%s' and validity = 1]],
	sql_group_abbr = [[SELECT 1 FROM groupInfo WHERE groupID='%s' and validity = 1]],
	sql_select_user = [[SELECT * FROM userGroupInfo WHERE groupID = '%s' and accountID = '%s' and validity = 1]],
	sql_insert = [[INSERT INTO userGroupHistory (groupID,accountID,groupType,validity,updateTime) VALUE ('%s','%s',%d,%d,%d)]],
	sql_update = [[UPDATE userGroupInfo SET validity = 0,updateTime = %d WHERE groupID = '%s' AND accountID = '%s']],
}


local account_tab={}

local function check_parameter(args)
	if not utils.is_word(args['groupID']) or string.len(args['groupID']) ~= 16 then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'groupID')
	end
	
	--> 验证accountID
	if not args['accountID'] then
		only.log("E","accountID is nil")
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end
	if string.len(args['accountID']) ~= 10 then
		local count = string.sub(args['accountID'],2,-2)
		local tab = utils.str_split(count,',')
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
			only.log("D","AccountID is illegal")
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
		end
	end
	if #args['accountID']==0 then
		only.log("D","AccountID is illegal")
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
	end

	safe.sign_check(args,url_info,"accountID",safe.ACCESS_USER_INO)
end

local function delete_member(args,account_id,time)
	local sql = string.format(G.sql_select_user,args['groupID'],account_id)
	local ok,res = mysql_api.cmd("app_custom___wemecustom","select",sql)
	if not ok  then
		only.log("E",string.format("the sql does error : [[%s]]",sql))
		table.insert(account_tab,account_id)
	elseif #res==0 then
		table.insert(account_tab,account_id)
	else
		local sql_tab = {}
		local tab = res[1]
		insert_sql = string.format(G.sql_insert,tab['groupID'],tab['accountID'],tab['groupType'],tab['validity'],tab['updateTime'])
		table.insert(sql_tab,insert_sql)
		update_sql = string.format(G.sql_update,time,args['groupID'],account_id)
		table.insert(sql_tab,update_sql)
		only.log("D",string.format("[[%s]]and [[%s]] ",sql_tab['insert_sql'],sql_tab['update_sql']))

		ok,res = mysql_api.cmd("app_custom___wemecustom","AFFAIRS",sql_tab)
		only.log("D",res)
		if not ok then
			only.log("E",string.format("[[%s]]and [[%s]] does error",sql_tab['insert_sql'],sql_tab['update_sql']))
			table.insert(account_tab,account_id)
		else
			ok,res = redis_api.cmd("statistic","SREM",args['groupID'] .. ":members",account_id)
			if not ok then
				only.log("E",string.format("Save %s to an error occurred in redis",account_id))
			end
		end
	end
end

local function handle()
	local req_ip = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()

	if not req_body then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_NO_BODY'])
	end
	only.log('E',req_body)
	local args = utils.parse_url(req_body)
	if not args then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'args')
	end

	url_info['client_host'] = req_ip
	url_info['client_body'] = req_body

	only.log("D",args['accountID'])
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
--
--	for k,v in pairs(args['accountID']) do
--		local sql = string.format(G.sql_account,v)
--
--		local ok,ret = mysql_api.cmd("app_usercenter___usercenter","select",sql)
--		if not ok then
--			gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
--		end
--		if #ret==0 then
--			table.insert(account_tab,v)
--			table.remove(args['accountID'],k)
--		end
--	end
	local time = os.time()
	if not args['account_tab'] then
		delete_member(args,args['accountID'],time)
	else
		for k,v in pairs(args['account_tab']) do
			delete_member(args,v,time)
		end
	end
	local tab = {}
	tab["error"] = account_tab

	local ok,ret = utils.json_encode(tab)
	only.log("D",ret)
	gosay.go_success(url_info,msg['MSG_SUCCESS_WITH_RESULT'],ret)
end
handle()
