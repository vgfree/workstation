-- zhouzhe
-- 2015-06-02
-- 获取自己所在频道的名称以及同频道成员列表

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
local cfg = require('config')


local url_info = { 
			type_name = 'system',
			app_key = nil,
			client_host = nil,
			client_body = nil,
		}

local sql_fmt = {
			sel_number = "SELECT customParameter FROM userKeyInfo WHERE accountID = '%s' limit 1 ",
			sel_accountid = "SELECT accountID, actionType FROM userKeyInfo WHERE customParameter = '%s'",
			sel_channel_name	 = "SELECT name FROM checkSecretChannelInfo WHERE number = '%s'"
	}

-- 检查参数
local function check_parameter(body)

	local res = utils.parse_url(body)

	if not res or type(res) ~= "table" then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
	end
	if not res['appKey'] then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_FAILED_GET_SECRET"])
	end
	if not res["accountID"] then
		gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
	end
	url_info["app_key"] = res['appKey']	

	-- safe.sign_check(res, url_info)
	-- 20150720
	-- 为io部门使用
	safe.sign_check(res, url_info, 'accountID', safe.ACCESS_WEIBO_INFO)
	-- only.log("D","sign_check")
	return res
end

-- 获取用户acountID
function get_member_accountid(res)

	-- 获取频道编号
	local sql = string.format(sql_fmt.sel_number, res["accountID"])
	only.log('D', sql)
	local ok, result = mysql_api.cmd("app_custom___wemecustom", 'SELECT', sql)

	if not ok and not result then
		only.log("D","result is error!")
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end
	if not result[1] then
		only.log("D","customParameter is error!")
		gosay.go_false(url_info, msg["MSG_ERROR_USER_NOT_JOIN_CHANNEL"])
	end
	local customParameter =result[1]["customParameter"]
	only.log("D","customParameter="..customParameter)
	-- 获取用户acountID
	local sql = string.format(sql_fmt.sel_accountid, customParameter)

	only.log('D', sql)
	local ok, result = mysql_api.cmd("app_custom___wemecustom", 'SELECT', sql)

	if not ok and not result then
		only.log("D","sel_accountid is error!")
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end
	-- for k,v in pairs(result) do
	-- 	only.log("D",result[k]["accountID"])
	-- end
	return result, customParameter 
end

-- 所需参数
function get_member_info(accountID, actionType, number )

	local sql = string.format(sql_fmt.sel_channel_name, number )
	-- only.log('D', sql)
	local ok, result = mysql_api.cmd("app_custom___wemecustom", 'SELECT', sql)

	if not ok then
		only.log('D', sql)
		gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
	end

	if not result and #result == 0 then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	local ret = string.format('{"accountID":"%s","fromChannel":"%s","fType":%d }', accountID, result[1]["name"], actionType )
	return ret
end

function handle( )

	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()

	if not body then 
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	
	url_info['client_host'] = ip
	url_info['client_body'] = body

	local res = check_parameter(body)
	if not res then 
		only.log("D","res is nil")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "res" )
	end
	-- get accountID
	local tab_res, number = get_member_accountid(res)

	if not tab_res then
		only.log("D","tab_res is nil")
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountid table" )
	end
	-- 返回json格式数据
	local result = "["
	for i= 1, #tab_res do
		result = result .. get_member_info(tab_res[i]["accountID"], tab_res[i]["actionType"], number)..","
	end

	if not result then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "result" )
	end
	ret = string.sub(result, 1,-2)
	ret = result .."]"
	-- only.log("D", ret )
	if not ret then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "ret" )
	end
	gosay.go_success(url_info, msg["MSG_SUCCESS_WITH_RESULT"], ret)
end

safe.main_call( handle )



