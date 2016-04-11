-->[ower]: jiangzs
-->[time]: 2014-03-17
-->用户传递参数accountid，收藏ID，对已经收藏的新闻进行删除（实际上是更新状态）
-- POST传入参数,body中的key-value,修改2014-04-09

local ngx = require("ngx")
local utils = require('utils')
local only = require('only')
local cjson = require('cjson')
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

local MAX_RECORD = 500

local function check_parameter(res,url_tab)
	-->> bad request
	if type(res) ~= 'table' then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'parameter')
	end
	-->> check accountid
	if not utils.is_word(res["accountid"]) then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'accountid')
	end
	if res["keyword"] and  #res["keyword"]  > 20 then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],"keyword length")
	end
	local cur_page = tonumber(res['curPage']) or 0
	local max_records = tonumber(res['maxRecords']) or 0
	if cur_page < 1 then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],"curPage")
	end
	if max_records < 1 or max_records > MAX_RECORD  then 
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],"maxRecords")
	end
end

local query_str = "select id as collectid,sourceID,title,description,link,releaseTime,typeName,longitude,latitude,bizid," ..
		"tokenCode,createTime from userCollectWeibo where validity = 1  "
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
	local keyword = string.gsub( (res["keyword"] or '' ),"'",'')
	local cur_page = tonumber(res['curPage']) or 0
	local max_page = tonumber(res['maxRecords']) or 0
	local str_where1 = ''
	local str_where2 = ''
	local str_limit = ''
	str_where1 = string.format("  and accountid = '%s' ",accountid)
	if keyword ~= '' then
		str_where2 = string.format("  and ( description like '%%%s%%' ) " ,keyword)
	else
		str_where2 = '  '
	end
	local start_index = ( ( cur_page - 1) * max_page ) - 1 
	if start_index < 1 then start_index = 0 end
	str_limit = string.format( "  order by id  limit %s , %s " , start_index  ,   max_page )
	local sql_str = string.format("%s %s %s %s ", query_str , str_where1, str_where2 , str_limit )
	local ok_status,ok_ret = mysql_api.cmd(app_yes_db_name,'SELECT',sql_str)
	if not ok_status then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"],'server')
	end

	local ok_status,ok_result = utils.json_encode(ok_ret)

	if not ok_status then
		gosay.go_false(url_tab, msg["MSG_ERROR_REQ_BAD_JSON"])
	end
	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],ok_result)
end
safe.main_call( handle )
