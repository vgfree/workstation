----- make nickname to url

local ngx       = require ('ngx')
local utils     = require('utils')
local only      = require('only')
local gosay     = require('gosay')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')


local myutils = require('account_utils')


local url_tab = { 
		type_name   = 'transit',
		app_key     = '',
		client_host = '',
		client_body = '',
}   


local function get_nickname_tab()
	local sql_str = "select accountID,nickname from userInfo where nickname != '' "
	only.log('D',sql_str)
	local ok,tab = mysql_api.cmd('app_cli___cli','SELECT',sql_str)
	if ok and tab then
		return ok,tab
	end
	return false,nil
end


local function go_exit( str )
	only.log('D',str)
	gosay.respond_to_json_str(url_tab,str)
end


local function get_nickname_url( account_id )
	local ok,url = redis_api.cmd('private', 'get', account_id .. ':nicknameURL')
	if ok and url then
		return true
	end
	return false
end


function handle()

	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()

	local ok,tab = get_nickname_tab()
	if not ok or not tab then
		only.log('E',"get_nickname_tab failed!")
		go_exit("get_nickname_tab failed")
		return false
	end

	local count = #tab
	only.log('D',string.format("count:%s-----",count))


	local succ = 0
	for i,v in pairs(tab) do
		if get_nickname_url(v['accountID']) == false then
			local status = myutils.after_set_nickname(v['accountID'],v['nickname'],true)
			if not status then
				only.log('D',string.format("accountid: %s----nickname:%s failed",v['accountID'], v['nickname'] ))
			else
				succ = succ + 1 
			end
		end
	end

	local str = string.format("total:%s  succ:%s", count, succ)
	go_exit(str)

end


handle()
