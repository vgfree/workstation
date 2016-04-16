--
--> author:			guoqi
--> date:			2014-11-6
--> feature number: #2196
--> function:		检查用户是否绑定IMEI

local msg		= require("msg")
local only		= require("only")
local safe		= require("safe")
local utils		= require("utils")
local gosay		= require("gosay")
local mysql_api = require("mysql_pool_api")
local redis_api = require("redis_pool_api")

sql_fmt = {
	sl_userList	= "SELECT imei  FROM userList WHERE accountID = '%s'  ",
}

url_info = {
	type_name	= 'system',
	app_key		= '',  
	client_host = '',  
	client_body = '',  
}

local function check_parameter(args)
	-->> bad request
	if type(args) ~= 'table' then
		only.log("E","parameter erroe!")
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'parameter')
	end

	-->> check accountid
	if not utils.is_word(args["accountID"]) then
		only.log("E","accountID %s  not word is error!" , args["accountID"] )
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'accountID')
	end

	if #tostring(args["accountID"]) ~= 10 then
		only.log("E","accountID %s  length is error!" , args["accountID"] )
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'accountID')
	end

	safe.sign_check(args,url_info,"accountID",safe.ACCESS_USER_INFO)

end

local function handle()
	
	local req_ip = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()

	if not req_body then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_NO_BODY"])
	end 

	local args = utils.parse_url(req_body)

	if  not args or not args["appKey"] then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],"appKey")
	end

	if not args["accountID"] then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],"accountID")
	end

	url_info['client_host'] = req_ip
	url_info['client_body'] = req_body

	url_info["app_key"] = args["appKey"]

	check_parameter(args)

	local sql = string.format(sql_fmt.sl_userList,args["accountID"])
	
	--  select IMEI
	local ok,ret = mysql_api.cmd("app_usercenter___usercenter","select",sql)

	if not ok or not ret then
		only.log("E","mysql failed!")
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	-- no matching data
	if #ret == 0 then
		only.log("E", string.format("accountID %s does not exist!", args["accountID"]) )
		gosay.go_false(url_info,msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
	end

	-- more than one matching data
	if #ret > 1 then
		only.log("E","internal data error!")
		gosay.go_false(url_info, msg["SYSTEM_ERROR"])
	end

	local tab = {}

	if ret[1]["imei"] == "0" then
		tab["band"] = "0"
		tab["IMEI"] = "0"
	else
		tab["band"] = "1"

		only.log("D", string.format(" appKey:%s  imei:%s  accountID:%s ", args["appKey"],ret[1]["imei"],args["accountID"] ) )

		local ok, res= redis_api.cmd("statistic","sismember",args["appKey"] .. ":businessIMEI", ret[1]["imei"])
		if not ok then
			gosay.go_false(url_info,msg["MSG_DO_REDIS_FAILED"])
		end
		if not res then
			tab["IMEI"] = "0"
		else
			tab["IMEI"] = ret[1]["imei"]
		end
	end

	local ok,res = utils.json_encode(tab)
	if ok then
		gosay.go_success(url_info,msg["MSG_SUCCESS_WITH_RESULT"],res)
	else
		gosay.go_success(url_info,msg["SYSTEM_ERROR"])
	end
end

handle()
