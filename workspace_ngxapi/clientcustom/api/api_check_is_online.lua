--	author :	guoqi
--	remark :	check user is online
--	date   :2015-02-10
--	修改 2015-07-04 zhouzhe

local msg		= require('msg')
local safe		= require('safe')
local utils		= require('utils')
local gosay 		= require('gosay')
local app_utils 	= require('app_utils')
local redis_api 	= require('redis_pool_api')
local cfg		= require('clientcustom_cfg')

-- 在线人员列表
local online_tab	= {}
-- 不在线人员列表
local offline_tab       = {}
-- 最大查询人数 50
local account_num = cfg.OWN_INFO.limits_number.account_num

local url_info 	= {
        type_name 	= 'system',
        app_key 	= nil,
        client_host 	= nil,
        client_body 	= nil,
}

--[[
检查参数
1. appKey为空 或 长度大于10 --> 报错
2. accountID为空 或 长度为0 或 包含"'" --> 报错
3. 符号校验3. 符号校验3. 符号校验
--]]


local function check_parameter( args )

        if not args['appKey'] or #args['appKey'] > 10 then
                only.log("E", "appKey is error")
                gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], 'appKey')
        end
        url_info['app_key'] = args['appKey']

        if not args['accountID'] or #args['accountID'] == 0 or string.find(args['accountID'], "'") then
                gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], 'accountID')
        end	
        safe.sign_check(args, url_info)
end

--[[
检查用户是否在线
1. 检查用户账户是否在redis在线用户数据库中
2. 用户在线则在online_tab 末尾添加用户账户
不在线在offline_tab 末尾添加用户账户
--]]


local function check_user_is_online( accountID )
        local ok, result = redis_api.cmd("statistic","sismember","onlineUser:set",accountID)
        if not ok then
                only.log("E",string.format("Save %s to an error occurred in redis",account_id))
        end
        if result then
                table.insert(online_tab, accountID)
        else
                table.insert(offline_tab, accountID)
        end
end

--[[

--]]


local function handle()
        -- 获取 req_ip 和 req_body
        local req_ip = ngx.var.remote_addr
        local req_body = ngx.req.get_body_data()

        if not req_body then
                gosay.go_false(url_info,msg['MSG_ERROR_REQ_NO_BODY'])
        end

        -- 解析 req_body, 返回值为table类型
        local args = utils.parse_url(req_body)
        if not args then
                gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'args')
        end

        url_info['client_host'] = req_ip
        url_info['client_body'] = req_body

        -- 检查参数
        check_parameter(args)

        ---- 2015-04-20 fixed appkey in static log is nil
        if not args['accountID'] or #args['accountID'] == 0 then
                only.log("E", "accountID is nil ")
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "accountID" )
        end

        -- accountID
        -- 1. 为10位,就是只有一个accountID，直接检查用户是否在线
        -- 2. 不为10位，说明不止一个accountID，此时需要进行处理后，再进行查询
        -- 3. 将处理后的accountID赋给account_tab，再通过循环检查account_tab中的成员是否在线
        --      
        if #args['accountID'] == 10 then
                -- only.log("D", "this is single accountID:%s", args['accountID'])
                if not app_utils.check_accountID(args['accountID']) then
                        only.log("E"," single accountID is error")
                        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
                end
                check_user_is_online(args['accountID'])
        else
                -- only.log("D", "this is many accountID")
                local account_tab = {}
                -- 将args中传输来的accountID赋值给count
                local count = string.sub(args['accountID'], 1, -1)
                -- 通过","来将count中的各个accountID区分开来，并赋给tab_splist
                local tab_split = utils.str_split(count,',')
                if not tab_split or type(tab_split ) ~= "table" then
                        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"accountID")
                end

                -- 最大查询个数为50
                if #tab_split > account_num then
                        only.log("E", "accountIDs too mauch len_tabSplit:%s", #tab_split )
                        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], "accountID amount")
                end

                -- 循环将tab_list中的accountID加入到account_tab中
                for _, val_aid in pairs( tab_split ) do
                        -- only.log("D", "all accountID:%s", val_aid)
                        if app_utils.check_accountID( val_aid ) then
                                table.insert(account_tab, val_aid )
                        end
                end
                --如果account_tab长度为0，返回错误信息
                if #account_tab == 0  then
                        only.log("E","accountIDs table is nil")
                        gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'accountID')
                end
                -- 循环检查用户是否在线
                for _, val_aid in pairs(account_tab) do
                        check_user_is_online( val_aid )
                end
        end

        local count = '{"online":"%s","offline":"%s"}'
        -- local on_str, off_str = '[]', '[]'
        local on_str, off_str = "", ""

        -- local ok = false
        -- if #online_tab ~= 0 then
        -- 	ok, on_str = utils.json_encode(online_tab)
        -- 	if not ok then
        -- 		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
        -- 	end
        -- end

        -- if #offline_tab ~= 0 then
        --  	ok,off_str = utils.json_encode(offline_tab)
        -- 	if not ok then
        -- 		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
        -- 	end
        -- end

        -- 在online_tab后连接","
        if online_tab and #online_tab ~= 0 then
                on_str = table.concat( online_tab, "," )
        end

        -- 在offline_tab后连接","
        if offline_tab and #offline_tab ~= 0 then
                off_str = table.concat(offline_tab, "," )
        end

        local ret = string.format(count, on_str, off_str)
        gosay.go_success(url_info,msg['MSG_SUCCESS_WITH_RESULT'], ret)	
end

handle()

