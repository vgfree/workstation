-- ngx_newstatus.lua
-- auth: baoxue
-- Thu May 16 12:12:31 CST 2013

local utils     = require('utils')
local only      = require('only')
local cutils    = require('cutils')
local gosay     = require('gosay')
local cjson     = require('cjson')
local link      = require('link')
local ngx       = require('ngx')
local socket    = require('socket')
local dk_utils  = require('dk_utils')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local http_api = require('http_short_api')
local weibo    = require('weibo')

local app_url_db       = "app_url___url"
local app_newstatus_db = "app_ns___newStatus"
local app_weiboread_db = "app_weibo___weibo_read"

local MATH_FLOOR = math.floor
local STR_LEN    = string.len

local IS_NUMBER = utils.is_number
local IS_FLOOR  = utils.is_float
local IS_WORD   = utils.is_word


local url_tab = { 
		type_name   = 'transit',
		app_key     = '',
		client_host = '',
		client_body = '',
}   

local TIME_DIFF = 28800    -- 8*60*60

local G = {
	imei          = '',
	head          = '',
	ip            = '',
	body          = '',
	
	cur_gmtdate  = 0,	----280614(2014-06-28 GM当前时间,用来纠正异常数据的)
	cur_month     = 0,	----当前月份(201404)
	cur_time      = 0, 	----当前时间(时间戳)
	cur_accountid = '',  ----accountID or args['imei']
	sql_save_urllog               = "INSERT INTO urlLog_%s SET createTime = unix_timestamp() ,url='%s',clientip= inet_aton('%s'),returnValue='%s' " ,
}


local function check_parameter( args )
	--> check imei
	if (not IS_NUMBER(args["imei"])) or (STR_LEN(args["imei"]) ~= 15) or (string.find(args["imei"], "0") == 1) then
		only.log('E', "imei is error!")
		return false
	end
	return true
end


local function verify_parameter( args )
	local token_key = string.format('%s:tokenCode',args["imei"])
	local ok,tokencode = redis_api.cmd('private', "get", token_key )
	if not ok then
		only.log('E', "failed connect private redis!")
		return false
	end
	if not tokencode then
		only.log('E', string.format("%s get tokencode=nil from redis!", args["imei"] ))
		return false
	end

	if tokencode ~= args["tokencode"] then
		only.log('E', string.format(" IMEI: %s  redis tokencode  [%s] != post tokencode [%s] tokencode not match!",args["imei"], tokencode, args["tokencode"]))
		return false
	end
	
	if not dk_utils.verify_mod_list[ args["mod"] ] then
		only.log('E', "mod of no avail!")
		return false
	end
	return true
end


local function save_gps_gsensor_to_redis( tab_gpsinfo,tab_gsensorinfo,cur_time )
	dk_utils.set_gpsinfo(tab_gpsinfo,cur_time)
	dk_utils.set_gsensorinfo(tab_gsensorinfo,cur_time)
end


local function save_urllog(returnValue)
	-------------debug------------
	local sql = string.format(G.sql_save_urllog, G.cur_month ,G.body,G.ip, returnValue)
	local ok,ret = mysql_api.cmd(app_url_db, "insert", sql)
	if not ok then
		only.log('E','save_url_failed!')
		return false
	end
	return true
end

---- 参数异常,返回400
local function go_exit()
	only.log('D',string.format("---IMEI:%s return 400-->---",tostring(G.imei)))
	save_urllog(400)
	gosay.respond_to_httpstatus(url_tab,400)
end

---- 参数正常,没有微博,返回555
local function go_empty()
	save_urllog(555)
	gosay.respond_to_httpstatus(url_tab,555)
end

local function go_succ()
	save_urllog(200)
	gosay.respond_to_httpstatus(url_tab,200)
end


local function get_accountid( new_imei )
	local ok,ret = redis_api.cmd('private','get', new_imei .. ":accountID")
	if ok and ret and #tostring(ret) == 10 then
		return ret
	end
	return new_imei
end


local function handle()
	
	local req_head   = ngx.req.raw_header()
	local req_ip     = ngx.var.remote_addr
	local req_body   = ngx.req.get_body_data()
	local req_method = ngx.var.request_method

	local args = ngx.req.get_uri_args()
	if req_method == 'POST' then
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')
      	if not boundary then
			-- args = utils.parse_url(req_body)
			args = ngx.decode_args(req_body)
		else
			args = utils.parse_form_data(req_head, req_body)
		end
	end
	
	G["ip"]                = req_ip
	G["head"]              = req_head
	G["body"]              = req_body

	url_tab['client_host'] = req_ip
	url_tab['client_body'] = req_body


	local cur_date = ngx.get_today()
	G.cur_month = string.gsub(string.sub(cur_date,1,7),"%-","")
	G.cur_time = ngx.time()

	-- 280614   2014-06-28
	G.cur_gmtdate = string.format("%s%s%s",string.sub(cur_date,9,10), string.sub(cur_date,6,7), string.sub(cur_date,3,4) )
	G.cur_year = tonumber(string.sub(cur_date,1,2)) * 100

	if not args then
		only.log('E', "bad request!")
		go_exit()
	end

	if not req_body then
		G.body              =  utils.table_to_kv(args) 		----ngx.encode_args(args)
		url_tab['client_body'] = G.body
	end

	G.imei = args['imei']

	local ok = check_parameter( args )
	if not ok then
		go_exit()
	end
	
	local tmp_accountid = get_accountid(G.imei)

	local tab = {
		level = 20,
		interval = 5*60,
		receiverAccountID = tmp_accountid,
		multimediaURL = "http://g3.tweet.daoke.me/group3/M01/56/A2/rBALa1PrIOaAU5LDAAAZdxvb8B0887.amr",
	}

	local appKey = '2290837278'
	local secret = 'CEC10F39CF75BCFABF8B0D236936AF4BD6084E8E'
	local personalWeibo = { host = "127.0.0.1", port = "80" }
	local ok_status, ok_ret = weibo.send_weibo(personalWeibo,'personal', tab, appKey, secret)
	if ok_status then
		gosay.respond_to_json_str(url_tab,ok_ret['bizid'])
	else
		go_exit()
	end
end

handle()
