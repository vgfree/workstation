
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
	sql_group_abbr = [[SELECT 1 FROM groupInfo WHERE groupID='%s']],
	sql_group_insert = [[INSERT INTO groupInfo (appKey,groupID,groupName,groupType,createTime,remarks) VALUE ('%s','%s','%s','%d',%d,'%s')]]
}

local function check_parameter(args)
	safe.sign_check(args,url_info)
--	safe.power_check(args['appKey'],'createGroup',url_info)

	if not args['groupType'] then
		args['groupType'] = 1
	end
	if not args['groupName'] then
		args['groupName'] = ""
	end
	if not args['remarks'] then
		args['remarks'] = ""
	end
	only.log("D",args['groupName'])

	if #args['groupName'] ~= 0 then
		if string.len(args['groupName']) > 64 then
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'groupName')
		end
	end
	if #args['remarks'] ~= 0 then
		if string.len(args['remarks']) > 64 then
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'remarks')
		end
	end

end


local function get_group_id(groupType)
    local sql, ok, result, random_abbr
    local flag = 'p'
    if groupType == 2 then
	    flag = 't'
    end
    while true do
        random_abbr = flag .. utils.random_string(15)
       	only.log("D",random_abbr)
	sql = string.format(G.sql_group_abbr, random_abbr)
        ok, result = mysql_api.cmd('app_custom___wemecustom', 'select', sql) 
        if ok and #result==0 then
            return random_abbr
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

	check_parameter(args)
	
		
	--> 生成groupID
	group_id = get_group_id(args['groupType'])
	
	--> 保存groupID
	local time = os.time()
	local sql = string.format(G.sql_group_insert,args['appKey'],group_id,args['groupName'],args['groupType'],time,args['remarks'])

	local ok,ret = mysql_api.cmd("app_custom___wemecustom","insert",sql)

	if not ok then
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end
	
	local tab={}

	tab["groupID"]=group_id

	local ok,ret = utils.json_encode(tab)
	if not ok then
		gosay.go_false(url_info,msg['MSG_ERROR_REQ_BAD_JSON'])
	end
	only.log("D",ret)

	gosay.go_success(url_info,msg['MSG_SUCCESS_WITH_RESULT'],ret)
	
end
handle()
