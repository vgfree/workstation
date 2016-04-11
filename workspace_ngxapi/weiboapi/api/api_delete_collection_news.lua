-- [ower]: jiangzs
-- [time]: 2014-03-17
-- 用户传递参数accountid，keyWork，当前页，每页最大条数，返回json数组
-- POST传入参数,body中的key-value,修改2014-04-09

local ngx = require("ngx")
local utils = require('utils')
local only = require('only')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local gosay = require('gosay')
local msg = require('msg')
local safe = require('safe')

local app_yes_db_name = 'app_yes___yes'


local url_tab = { 
        type_name = 'system',
        app_key = '',
        client_host = '',
        client_body = '',
    }   

local function check_parameter(res,url_tab)
	-->> bad request
	if type(res) ~= 'table' then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'parameter')
	end
	-->> check accountid
	if not utils.is_word(res["accountid"]) then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'accountid')
	end
	local collect_id = tonumber(res['collectid'])
	if not collect_id  then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],"collectid")
	end
end

local query_str 		= "select id from userCollectWeibo where validity = 1 and accountid = '%s' and id = %d limit 1 "
local delete_str 	= "update userCollectWeibo set validity = 0, updateTime = unix_timestamp(now()) where validity = 1 and accountid = '%s'  and id = %d "



function handle()
	local req_heads = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	local req_ip = ngx.var.remote_addr

	url_tab['client_host'] = req_ip
    	url_tab['client_body'] = req_body

	if not req_body then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'body')
	end
	
	local res = utils.parse_url(req_body)
	if not res then
		gosay.go_false(url_tab,msg["MSG_ERROR_REQ_ARG"],'key and value')
		return
	end

    	url_tab['app_key'] = res['appKey']

	safe.sign_check(res,url_tab)
	check_parameter(res,url_tab)

	local accountid = res["accountid"] 
	local collect_id = tonumber(res['collectid']) or 0
	local sql_str = string.format(query_str,accountid,collect_id)
	local ok_status,ok_result = mysql_api.cmd(app_yes_db_name,'SELECT',sql_str)
	if not ok_status then
		only.log('D',sql_str)
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'server')
	end
	if #ok_result ~= 1 then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'news not exists')
	end
	sql_str = string.format(delete_str,accountid,collect_id)
	local ok_status,ok_status = mysql_api.cmd(app_yes_db_name,'UPDATE',sql_str)
	if not ok_status then
		only.log('D',sql_str)
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'server')
	end
	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],collect_id)
end
safe.main_call( handle )
