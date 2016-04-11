local cutils = require('cutils')
local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local mysql_api = require('mysql_pool_api')
local cjson   = require('cjson')

local url_tab = {
	type_name   = 'system',
	app_key     = '',
	client_host = '',
	client_body = '',
}

local host_ip = link.OWN_DIED.http.batchFollowMicroChannel.host
local host_port = link.OWN_DIED.http.batchFollowMicroChannel.port

local userlist_dbname = "app_usercenter___usercenter"
local G = {
	sql_imei_get_accountID = "select accountID from userList where imei in ( %s ) "
}

local function check_parameter(args)
	if not args['totalList'] or (string.find(args['totalList'] ,"'")) then
		only.log('E',string.format(" totalList:%s is error", args['totalList'] ))
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],args['totalList'])
	end
	safe.sign_check(args, url_tab )
end

local function follow_microchannel(appKey , secret ,accountid ,uniqueCode )      
    local  tab = {
        appKey = appKey,
        accountID =  accountid,
        uniqueCode = uniqueCode,
        followType = 1
    }

    tab['sign'] = app_utils.gen_sign(tab, secret)
    local body = utils.table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/followMicroChannel HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok then
        return false
    end
    return ret
 end

 local function get_accountid( imei )
 	if (string.find(imei ,"'")) then
 		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'totalList')
 	end
	local sql_str = string.format(G.sql_imei_get_accountID ,imei)
	local ok ,ret = mysql_api.cmd(userlist_dbname ,'select' ,sql_str)
	if not ok or not ret then
		only.log("E" ,sql_str)
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
	 
	if type(ret) ~= "table" or #ret == 0 then
		only.log('E',string.format("imei:%s is error!sql_str:%s" ,imei ,sql_str))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'imei')
	end
	return #ret ,ret
 end
 local function handle()
	local req_ip   = ngx.var.remote_addr
	local req_head = ngx.req.raw_header()
	local req_body = ngx.req.get_body_data()
	local req_method = ngx.var.request_method
	url_tab['client_host'] = req_ip
	if not req_body  then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_body'] = req_body

	local args = nil	
	if req_method == 'POST' then		
		local boundary = string.match(req_head, 'boundary=(..-)\r\n')		
		if not boundary then		
			args = ngx.decode_args(req_body)		
		else		
		---- 解析表单形式 		
			args = utils.parse_form_data(req_head, req_body)		
		end		
	end
	if not args then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	if not args['appKey'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
	end

	url_tab['app_key'] = args['appKey']
	check_parameter(args)

	local appKey = args['appKey']
	local secret = app_utils.get_secret(appKey)
	if not secret then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"secret")
	end

	local uniqueCode = args['uniqueCode']

	local totalList_str = args['totalList']
	if not totalList_str then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"not totalList")
	end
	----总的成功的次数
	local success_count = 0
	----totalList中的imei
	local imei_tab = {}
	----totalList中的accountID
	local accountid_tab = {}

	totalList_tab = utils.str_split(totalList_str,",")
	if type(totalList_tab) == "table" and #totalList_tab >= 1 then
		for k ,v in pairs(totalList_tab) do 
			---- imei
			if #tostring(v) == 15 then
				table.insert(imei_tab ,v)
			-- accountID
			elseif #tostring(v) == 10 then
				table.insert(accountid_tab ,v)
			end
		end
	end
	----totalList中imei总数
	local imei_count = 0
	----imei中能获取到的accountID总数
	local imei_get_accountid_count = 0
	----关注自己的次数
	local error_follow_self_count = 0
	----重复关注的次数
	local error_repeat_follow_count = 0
	local error_imei_get_accountID = 0
	----API调用失败
	local error_call_api_failed = 0

	if imei_tab and #imei_tab >= 1 then
		imei_count = #imei_tab
		local imei_str = table.concat(imei_tab ,",")
		local accountid_ret = nil
		imei_get_accountid_count ,accountid_ret = get_accountid(imei_str)
		if not accountid_ret or type(accountid_ret) ~= "table" then 
			gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'imei')
		end

		for k ,v in pairs(accountid_ret) do 
			local api_result = follow_microchannel(appKey , secret ,v["accountID"] ,uniqueCode )
			-- local req = utils.parse_api_result(api_result)
			if not api_result then
				error_call_api_failed = error_call_api_failed + 1
				only.log('E',"accountID:%s ,uniqueCode:%s",v["accountID"] ,uniqueCode)
			else
				local info = string.match(api_result, '.-\r\n\r\n(.+)')
				local ok,data = pcall(cjson.decode, info)
				
				if ok then
					if data["ERRORCODE"] == "0" then
						-- 关注成功
						success_count = success_count + 1
					elseif data["ERRORCODE"] == 'ME01023' then
						error_imei_get_accountID = error_imei_get_accountID + 1
					elseif data["ERRORCODE"] == 'ME18303' then
						error_repeat_follow_count = error_repeat_follow_count + 1
					elseif data["ERRORCODE"] == 'ME18302' then
						error_follow_self_count = error_follow_self_count + 1
					end
				end
			end
		end
	end

	if accountid_tab and #accountid_tab >= 1 then
		for k ,v in pairs(accountid_tab) do 
			local api_result = follow_microchannel(appKey , secret ,v ,uniqueCode )
			if not api_result then
				error_call_api_failed = error_call_api_failed + 1
				only.log('E',"accountID:%s",v)
			else
				local info = string.match(api_result, '.-\r\n\r\n(.+)')
				local ok,data = pcall(cjson.decode, info)
				if ok then
					if tonumber(data["ERRORCODE"]) == 0 then
						-- 关注成功
						success_count = success_count + 1
					elseif data["ERRORCODE"] == 'ME01023' then
						error_imei_get_accountID = error_imei_get_accountID + 1
					elseif data["ERRORCODE"] == 'ME18303' then
						error_repeat_follow_count = error_repeat_follow_count + 1
					elseif data["ERRORCODE"] == 'ME18302' then
						error_follow_self_count = error_follow_self_count + 1
					end
				end
			end
		end
	end
	----错误参数的个数 ,不是imei并且不是accountID
	local error_parameter_count = #totalList_tab - #imei_tab - #accountid_tab
	----imei获取不到accountID的个数
	local imei_no_accountid = imei_count - imei_get_accountid_count

	local result_tab = {
		total = #totalList_tab ,
		successed = success_count ,
		failed = #totalList_tab-success_count ,
		failedReason = {
			imeiNoAccountid = imei_no_accountid ,
			followSelf = error_follow_self_count ,
			repeatFollow = error_repeat_follow_count ,
			errorParameter = error_parameter_count ,
			accountIDError = error_imei_get_accountID ,
			callApiError = error_call_api_failed
		}
	}
	local ok, str = pcall(cjson.encode,result_tab)

	if str then
		----SUCCED
		gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
	else
		----FAILED
		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	end

end

safe.main_call( handle )
