-->[ower]: baoxue
-->[time]: 2013-09-02
-->accountID与IMEI绑定

local msg       = require('msg')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local ngx       = require ('ngx')
local sha       = require('sha1')
local app_utils = require('app_utils')
local link      = require('link')
local http_api  = require('http_short_api')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')


local reward_srv = link["OWN_DIED"]["http"]["rewardapi"]

local G = {
	sl_mirrtalk = "SELECT validity,status FROM mirrtalkInfo WHERE nCheck='%s' AND imei='%s' ",

	sl_account = " SELECT accountID FROM userList WHERE imei='%s' limit 1 ",

	sl_status = " SELECT userStatus,daokePassword, imei FROM userList WHERE accountID='%s' AND userStatus IN(1,3,4,5) ",
	
	upd_user_list = " UPDATE userList SET userStatus=5,updateTime=%s,imei='%s' WHERE accountID='%s' ",
	
	-- 2015-07-14 zhouzhe
	-- 1)查询之前accountID的rewardsType
	sl_user_WECodeInfo = " SELECT * FROM WECodeInfo WHERE accountID ='%s' AND rewardsType > 2 AND amountType=2 LIMIT 1 ",
	-- 2)查询当前imei的rewardsType  userMirrtalkInfo
	sl_user_imeistatus = " SELECT rewardsType FROM userMirrtalkInfo WHERE validity=1 AND imei='%s' LIMIT 1 ",
	-- 3)查询当前imei的rewardsType  businessMirrtalkInfo
	sl_business_imeistatus = " SELECT rewardsType FROM businessMirrtalkInfo WHERE validity=1 AND imei='%s' LIMIT 1 ",

	-- 4)如果是新增奖励类型插入旧数据到WECodeHistory表
	ins_wecodehistory = "INSERT INTO WECodeHistory SET WECode='%s', rewardsType=%d, amountType=%d, WECodeStatus=%d,"..
						" disabledTime='%s', accountID='%s', updateTime='%s', startUsingTime='%s', endUsingTime='%s', "..
						" usingLastYear='%s', usingLastMonth='%s' ",

	-- 5)如果是新的奖金类型更新WECodeInfo表
	upd_wecodeinfo = " UPDATE WECodeInfo SET rewardsType=%d, updateTime=%d WHERE accountID='%s' AND rewardsType=%d ",
	-- 6)从wecode中取出5条
	select_wecode = "SELECT WECode FROM WECodeInfo WHERE accountID = '' AND WECodeStatus=0 AND rewardsType=%s AND "..
					"amountType=2 AND disabledTime>%d LIMIT %d ",

}

local userlist_dbname =  "app_usercenter___usercenter"
local crowd_dbname = "app_crowd___crowd"

local crl_time = os.time()

local url_info = { 
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function check_parameter(body)

	local res = utils.parse_url(body)

	if not res or type(res) ~= "table" then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],"args")
	end

	url_info['app_key'] = res['appKey']

	-- check imei
	if (not utils.is_number(res["IMEI"])) or (#res["IMEI"] ~= 15) or ( string.sub(res['IMEI'],1,1) == "0") then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "IMEI")
	end
	-- check accountID
	if (not utils.is_word(res["accountID"])) or (#res["accountID"] ~= 10) then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "accountID")
	end
	--accountID--2015/4/11---
	safe.sign_check(res, url_info, 'accountID', safe.ACCESS_BINDMIRRTALK_INFO)

	return res
end

local function check_user_is_online( account_id )
	local ok, ret = redis_api.cmd('statistic', 'sismember', 'onlineUser:set', account_id)
	return ok and ret
end

-- 2015-07-14 zhouzhe 创建wecode  create_wecode(cur_time, j)
local function create_wecode(cur_time, reward_type)

    local cur_year = os.date('%Y', cur_time)
    local cur_month = os.date('%m', cur_time)
    local cur_day = os.date('%d', cur_time)
    local next_time = os.time( { year=cur_year+1, month=cur_month, day=cur_day } )

    local tab = {
        appKey = url_info['app_key'],
        rewardsType = reward_type,
        disabledTime = next_time,
        createCount = 20,
    }

    local ok, secret = redis_api.cmd("public", "hget", tab["appKey"] .. ':appKeyInfo', 'secret')
    if not ok or not secret then
        return false
    end

    local sign = app_utils.gen_sign(tab, secret)

    local body = string.format('appKey=%s&sign=%s&rewardsType=%s&disabledTime=%s&createCount=%s', tab['appKey'], sign, tab['rewardsType'], next_time, tab['createCount'])

    local post_body = utils.post_data('rewardapi/v2/createWECode', reward_srv, body)

    only.log('D', post_body)
    local ret_body = http_api.http(reward_srv, post_body, true)
    
    if ret_body then
   		return true
	end
	only.log('E', ret_body)
end

-- 绑定wecode bind_wecode(res['accountID'], result[num]['WECode'])
local function bind_wecode(account_id, wecode)
	local tab = {
		appKey = url_info['app_key'],
		accountID = account_id,
		WECode = wecode,
	}

	tab['sign'] = app_utils.gen_sign(tab)
	local body = utils.table_to_kv(tab)
	only.log('D',string.format("body===%s=tab=", body ))
	local post_body = utils.post_data('rewardapi/v2/bindUserWECode', reward_srv, body)
	local ret = http_api.http(reward_srv, post_body, true)
	if not ret then
		only.log('E',string.format("bindUserWECode failed  %s ", post_body ) )
		gosay.go_false(url_info, msg['MSG_DO_HTTP_FAILED'])
	end

	local body = string.match(ret,'{.*}')
	only.log('D',string.format("body===%s====%s===", body,wecode ))
	if not body then
		only.log('E',string.format("[rewardapi/v2/bindUserWECode] %s \r\n ****SYSTEM_ERROR: %s", post_body, ret ))
		gosay.go_false(url_info, msg["SYSTEM_ERROR"])
	end

	local ok, ret__body = utils.json_decode(body)
	if not ok  then
		only.log('E',string.format("MSG_ERROR_REQ_BAD_JSON: %s", body ))
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_BAD_JSON"])
	end
	if tonumber(ret__body['ERRORCODE']) ~= 0 then
		--如果调用bindUserWECode API 不成功,打印日志
		only.log('E',string.format('Call bindUserWECode error,ERRORCODE:%s',ret__body['ERRORCODE']))
		return ret__body
	end
	return ret__body
end

local function creat_and_bind_wecode( imei, accountID, rewardsType )
	
	-- 从wecodeinfo中取出5条数据
	local wecode_num = 5
	local sql = string.format(G.select_wecode, rewardsType, crl_time, wecode_num )
	local ok, result = mysql_api.cmd(crowd_dbname, 'SELECT', sql)
	if not ok or not result then
		only.log('E', string.format("select_wecode failed , %s" , sql) )
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end
	only.log('D', "===%s,#result==%d===wecode_num===%d", accountID, #result, wecode_num )
	if #result < wecode_num then
		local ok = create_wecode(cur_time, rewardsType)
		if not ok then
			only.log("E","create_wecode is error")
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], "creat wecode" )
		end
		-- 从wecodeinfo中取出5条数据
		local sql = string.format(G.select_wecode, rewardsType, crl_time, wecode_num )
		local ok, result = mysql_api.cmd(crowd_dbname, 'SELECT', sql)
		if not ok or not result then
			only.log('E', string.format("select_wecode failed , %s" , sql) )
			gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
		end
	end

	for _,val in pairs(result) do
		for _, wecode_v in pairs(val) do
			local ret__body =  bind_wecode(accountID, wecode_v)
			only.log('E', "===%s====ERRORCODE===%s", wecode_v, ret__body['ERRORCODE'] )
			--绑定WECode成功
			if tonumber(ret__body['ERRORCODE']) == 0  then		
				only.log('D', string.format('bind wecode successed :%s',wecode_v ))
				return true
			end
		end
	end
	return false
end

-- wecode及rewardsType处理
local function handle_rewards_type( imei, accountID )

	local rewardsType = 4
	-- 查询当前imei的rewardsType  userMirrtalkInfo
	local sql_ret = string.format(G.sl_user_imeistatus , imei)
	local ok_t, ret = mysql_api.cmd(crowd_dbname, 'SELECT', sql_ret)
	if not ok_t or not ret then
		only.log('E', string.format("sl_user_imeistatus failed , %s" , sql_ret) )
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end
	-- 如果没有在userMirrtalkInfo表中查到就去企业表中查
	local ok_v, res = false, ''
	if #ret < 1 then
		-- 查询当前imei的rewardsType  businessMirrtalkInfo
		local sql_res = string.format(G.sl_business_imeistatus , imei)
		ok_v, res = mysql_api.cmd(crowd_dbname, 'SELECT', sql_res)
		if not ok_v or not res then
			only.log('E', string.format("sl_business_imeistatus failed , %s" , sql_res) )
			gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
		end
		if #res > 0 then
			only.log('D', string.format("res[1]['rewardsType'] , %s" , sql_res) )
			rewardsType = res[1]['rewardsType']
		end
	else
		-- only.log('D', string.format("ret[1]['rewardsType']  , %s" , sql_ret) )
		rewardsType = ret[1]['rewardsType']
	end

	-- 查询之前accountID的rewardsType
	local sql_str = string.format(G.sl_user_WECodeInfo , accountID)
	local ok, result = mysql_api.cmd(crowd_dbname, 'SELECT', sql_str)
	if not ok or not result then
		only.log('E', string.format("sl_user_WECodeInfo failed , %s" , sql_str) )
		gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
	end
	-- only.log('D', string.format("sl_user_WECodeInfo , %s" , sql_str) )
	-- 如果没有查到该imei信息
	if #res < 1 and #ret < 1 and  #result >0 then
		if type(result) == "table" then
			-- only.log("E", "rewardsType==%s",result[1]['rewardsType'], rewardsType)
			if tonumber(result[1]['rewardsType']) == rewardsType  then
				-- 返回1 说明该imei的rewardsType=4不用设置奖金类型
				return 1
			else

				-- 此奖励类型没有记录备份数据到历史表
				local sql = string.format(G.ins_wecodehistory , result['WECode'], result['rewardsType'], result['amountType'],
							result['WECodeStatus'],result['disabledTime'],result['accountID'], crl_time, result['startUsingTime'], 
							result['endUsingTime'], result['usingLastYear'], result['usingLastMonth'] )
				local ok = mysql_api.cmd(crowd_dbname, 'INSERT', sql)
				-- only.log('D', string.format("ins_wecodehistory, %s" , sql) )
				if not ok then
					only.log('E', string.format("ins_wecodehistory failed , %s" , sql) )
					gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
				end
				
				-- 更新数据wecodeinfo
				local sql = string.format(G.upd_wecodeinfo , rewardsType, crl_time, accountID, result[1]['rewardsType'])
				local ok = mysql_api.cmd(crowd_dbname, 'UPDATE', sql)
				only.log('D', string.format("upd_wecodeinfo===, %s,%s" , ok, sql) )
				if not ok then
					only.log('E', string.format("====upd_wecodeinfo failed , %s" , sql) )
					gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
				end
				-- 绑定老机器
				return 5
			end
		else
			only.log('E', string.format("sl_user_WECodeInfo return date error , %s" , sql_str) )
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], "accountID")
		end
	end

	-- 如果用户没有绑定wecode则去绑定wecode
	local isbind = false
	if #result < 1 then
		-- 绑定wecode尝试三次
		for i=1, 3 do
			-- only.log('D', "creat_and_bind_wecode===%s===%s===%d", imei, accountID, rewardsType )
			isbind = creat_and_bind_wecode( imei, accountID, rewardsType )
			if isbind then
				-- only.log("D", "isbind:%s", isbind)
				-- 返回2 说明该accountID之前没wecode现在已经绑定wecode
				return 2
			end
		end
		if not isbind then
			only.log("E", string.format("==bindimeiAPI==bind wecode failed,accountid: %s", accountID ))
			gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'bindUserWECode')
		end
	else
		
		if #result < 1 or type(result)~= "table" then
			only.log('E', string.format("sl_user_WECodeInfo return date error , %s" , sql_str) )
			gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'], "return date")
		end

		local result = result[1]
		-- 此奖金类型有记录
		if rewardsType == result['rewardsType'] then
			-- 返回3 说明此账号之前有绑定且奖金类型已经存在
			return 3
		end

		-- 此奖励类型没有记录备份数据到历史表
		local sql = string.format(G.ins_wecodehistory , result['WECode'], result['rewardsType'], result['amountType'],
					result['WECodeStatus'],result['disabledTime'],result['accountID'], result['updateTime'], result['startUsingTime'], 
					result['endUsingTime'], result['usingLastYear'], result['usingLastMonth'] )
		local ok = mysql_api.cmd(crowd_dbname, 'INSERT', sql)
		-- only.log('D', string.format("ins_wecodehistory, %s" , sql) )
		if not ok then
			only.log('E', string.format("ins_wecodehistory failed , %s" , sql) )
			gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
		end

		-- 更新数据wecodeinfo
		local sql = string.format(G.upd_wecodeinfo , rewardsType, crl_time, accountID, result['rewardsType'])
		local ok = mysql_api.cmd(crowd_dbname, 'UPDATE', sql)
		-- only.log('D', string.format("upd_wecodeinfo, %s,%s" , ok, sql) )
		if not ok then
			only.log('E', string.format("upd_wecodeinfo failed , %s" , sql) )
			gosay.go_false(url_info,msg['MSG_DO_MYSQL_FAILED'])
		end
		-- 新奖金类型
		return 4
	end
end
-- 2015-07-14 zhouzhe  end

function handle()
	local ip = ngx.var.remote_addr
	local body = ngx.req.get_body_data()
	if not body then
		gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	url_info['client_host'] = ip
	url_info['client_body'] = body

	local sql,ret
	local res = check_parameter(body)

	local imei = res["IMEI"]
	local account_id = res["accountID"]

	-- check imei
	local sql = string.format(G.sl_mirrtalk, string.sub(imei, -1, -1), string.sub(imei, 1, -2))
	local ok, res = mysql_api.cmd('app_ident___ident', 'SELECT', sql)
	only.log('D', string.format(" check imei === %s",sql ))
	if not ok or not res then

		only.log('E', string.format(" check imei failed %s",sql) )
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	if #res == 0 then
		gosay.go_false(url_info, msg["MSG_ERROR_IMEI_NOT_EXIST"])
	end
	--local model = res[1]['model']
	if tonumber(res[1]['validity']) == 0 or res[1]['status']~='13g' then
		-- gosay.go_false(url_info, msg["MSG_ERROR_IMEI_UNUSABLE"],imei)
		-- 2015-04-10 错误码调整 jiang z.s. 
		gosay.go_false(url_info, msg["MSG_ERROR_IMEI_INVALIDITY"])
	end

	-->| STEP 2 |<--
	-->> check if has imei in userList
	sql = string.format(G.sl_account, imei)
	local ok, res = mysql_api.cmd(userlist_dbname, 'SELECT', sql)
	only.log('D', string.format(" check account === %s",sql ))
	if not ok or not res then
		only.log('E',"check imei is bind failed, %s",sql)
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end

	if #res~= 0 then
		if res[1]['accountID'] == account_id then
			gosay.go_false(url_info, msg['MSG_ERROR_DEVICE_REBIND'])
		else
			gosay.go_false(url_info, msg["MSG_ERROR_IMEI_HAS_BIND"])
		end
	end

	-->| STEP 3 |<--
	-->> check if has accountID in userList
	sql = string.format(G.sl_status, account_id)
	only.log('D', string.format(" check sl status === %s",sql ))
	local ok, res = mysql_api.cmd(userlist_dbname, 'SELECT', sql)
	if not ok or not res then
		only.log('E',"check accountID , %s ", sql )
		gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
	end
	-->> has no
	if #res==0 then
		gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NOT_EXIST"])
	-->> has more than one
	elseif #res > 1 then
		only.log('S', string.format("the record of accountID:%s is more than one, call someone to handle", account_id))
		gosay.go_false(url_info, msg["MSG_ERROR_MORE_RECORD"], "accountID")
	end

	-->> has only one
	local status = tonumber(res[1]["userStatus"])
	local daoke_password = res[1]["daokePassword"]

	-->| STEP 4 |<--
	if status == 3 then
		gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_NO_SERVICE"])
	elseif status == 5 then

		if res[1]['imei'] == imei then
			gosay.go_false(url_info, msg['MSG_ERROR_DEVICE_REBIND'])
		else
			---- 已经绑定
			gosay.go_false(url_info, msg["MSG_ERROR_ACCOUNT_ID_HAS_BIND"])
		end
	elseif status == 4 then
		---- 未绑定,开始绑定
		-->| STEP 5 |<--
		local cur_time = os.time()
		-- local sql_tab = {}
		-- 2015-08-06 zhouzhe 增加字段model
		sql = string.format(G.upd_user_list, cur_time, imei, account_id)
		only.log('D', string.format(" upd_user_list === %s",sql ))
		-- table.insert(sql_tab, sql)
		-- 2015-08-06 zhouzhe 去除插入历史表操作，原因：和解绑重复,增加数据库信息
		-- sql = string.format(G.ins_history, cur_time, imei, account_id, daoke_password, model )
		-- only.log('D', string.format(" ins_history === %s",sql ))
		-- table.insert(sql_tab, sql)

		local ok = mysql_api.cmd(userlist_dbname, 'UPDATE', sql)
		if not ok then
			only.log('E',"bind accountid with imei failed "  )
			gosay.go_false(url_info, msg["MSG_DO_MYSQL_FAILED"])
		end

		redis_api.cmd('private', 'set', account_id .. ":IMEI", imei)
		redis_api.cmd('private', 'set', imei .. ":accountID", account_id)

		if check_user_is_online(imei) then

			---- 从默认的客户频道剔除在线
			redis_api.cmd('statistic', 'srem', '10086:channelOnlineUser', imei)

			redis_api.cmd('statistic', 'srem', 'onlineUser:set', imei)
			redis_api.cmd('statistic', 'sadd', 'onlineUser:set', account_id)
			
			local ok, ret = redis_api.cmd('statistic','smembers',account_id .. ":userFollowMicroChannel")
			if ok and ret then
				for k, idx in pairs(ret) do
					redis_api.cmd('statistic', 'sadd', idx .. ':channelOnlineuser', account_id)
					only.log('I',string.format("add channelidx:%s  channelOnlineuser %s" , idx, account_id ))
				end
			end

			local ok, ret = redis_api.cmd('private', 'get', imei .. ":cityCode")
			if ok and ret then
				only.log('W',"srem %s cityOnlineUser %s ",ret ,imei)
				only.log('W',"sadd %s cityOnlineUser %s ",ret ,account_id)
				redis_api.cmd('statistic', 'srem', ret .. ':cityOnlineUser', imei)
				redis_api.cmd('statistic', 'sadd', ret .. ':cityOnlineUser', account_id)
			end
		end
		-- 2015-07-14 查询imei的rewardsType 新增rewardsType需要绑定wecode
		local wecode_status = handle_rewards_type( imei, account_id )
		only.log("D", "status :%s", wecode_status)

		gosay.go_success(url_info, msg["MSG_SUCCESS"])
	end

	only.log('E',string.format("SYSTEM_ERROR: accountID: %s  imei:%s  %s", account_id, imei, status) )
	gosay.go_success(url_info, msg["SYSTEM_ERROR"])
end


safe.main_call( handle )

