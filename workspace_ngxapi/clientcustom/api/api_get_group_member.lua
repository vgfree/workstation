
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
	sql_group = [[SELECT groupType FROM groupInfo WHERE groupID = '%s' and validity = 1]],
	sql_nickname = [[SELECT accountID,nickname FROM userInfo WHERE accountID in(%s)]],
}

local function check_parameter(args)
	if not utils.is_word(args['groupID']) or string.len(args['groupID']) ~= 16 then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'groupID')
	end

	safe.sign_check(args,url_info)
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
	local ok,res = redis_api.cmd("statistic","SMEMBERS",args['groupID'] .. ":members")
	if not ok then
		gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
	end
	local count = '1'
	for k,v in pairs(res) do 
		count = count .. "\'" .. v .. "\',"
	end
	count = string.sub(count,2,-2)
	only.log("D",count)
	sql = string.format(G.sql_nickname,count)
	ok,res = mysql_api.cmd("app_clientmirrtalk___clientmirrtalk","select",sql)
	if not ok then
		only.log("E",string.format("the sql does error : [[%s]]",sql))
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end
	only.log("D",sql)
	local ok,ret = utils.json_encode(res)
	only.log("D",ret)
	gosay.go_success(url_info,msg['MSG_SUCCESS_WITH_RESULT'],ret)
end
handle()
