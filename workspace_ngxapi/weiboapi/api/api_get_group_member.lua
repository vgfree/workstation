--
-->authore: zhangjl
-->time :2013-03-20
-->local common_path = './conf/?.lua;./include/?.lua;./public/?.lua;'
-->package.path = common_path .. package.path

local ngx = require('ngx')
local utils = require('utils')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local only = require('only')
local msg = require('msg')
local safe = require('safe')

local sql_fmt = {

    sl_group_user = "SELECT distinct accountID,roleType,isDefaultGroup FROM userGroupInfo WHERE groupID='%s' AND validity=1",

    sl_group_info = "SELECT createTime, updateTime, name FROM groupInfo WHERE groupID='%s' AND validity=1",

}

local url_tab = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    if not args['groupID'] or #args['groupID']>16 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupID')
    end

    safe.sign_check(args, url_tab)
    
end

local function get_nickname(a_id)

    local ok, nickname = redis_pool_api.cmd('private', 'get', a_id .. ':nickname')
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end

    local ok, online_status = redis_pool_api.cmd('private', 'get', a_id .. ':heartbeatTimestamp')
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_REDIS_FAILED'])
    end

    if not online_status or os.time() - tonumber(online_status) > 60 then
        online_status = 0
    else
        online_status = 1
    end

    return nickname or '', online_status
end


local function get_member(args)  

    local sql = string.format(sql_fmt.sl_group_user, args['groupID'])
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then 
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    local ret_tab = {}
    local name_tab = {}
    local nickname
--[[
    for k, v in pairs(result) do
        nickname, online_status = get_nickname(v['accountID'])
        table.insert(ret_tab, {accountID=v['accountID'], name=nickname, online=online_status, roleType=v['roleType'], isDefaultGroup=v['isDefaultGroup']})
    end
--]]


    for k, v in pairs(result) do
		if #name_tab == 0 then	
			nickname, online_status = get_nickname(v['accountID'])
			table.insert(name_tab,nickname)
			table.insert(ret_tab,{accountID=v['accountID'], name=nickname, online=online_status, roleType=v['roleType'], isDefaultGroup=v['isDefaultGroup']})
		else
			nickname, online_status = get_nickname(v['accountID'])
			for i=1,  #ret_tab do
				if nickname < name_tab[i] then
					table.insert(name_tab,i,nickname)
					table.insert(ret_tab,i,{accountID=v['accountID'], name=nickname, online=online_status, roleType=v['roleType'], isDefaultGroup=v['isDefaultGroup']})
					break
				else 
					i = i + 1
					if i > #ret_tab then
						table.insert(name_tab,i,nickname)
						table.insert(ret_tab,i,{accountID=v['accountID'], name=nickname, online=online_status, roleType=v['roleType'], isDefaultGroup=v['isDefaultGroup']})
						break
					end
				end
			end
		end
	end

    --[[
    local sql = string.format(sql_fmt.sl_group_info, args['groupID'])
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then 
        return nil
    end

    result[1]['members'] = ret_tab
    ]]

    local ok, val = utils.json_encode(ret_tab)

	only.log("D",val)

    return val
end

local function handle()

    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()

    url_tab['client_host'] = ip
    url_tab['client_body'] = body
	
    only.log("D",body)

    if body == nil then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end

    local args = utils.parse_url(body)
    url_tab['app_key'] = args['appKey']

    -->check parameter
    check_parameter(args)

    local ret = get_member(args)
    
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)
end


safe.main_call( handle )
