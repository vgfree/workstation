--wufei
--2015.5.16
--生成IMEI

local ngx       = require('ngx')
local utils     = require('utils')
local only      = require('only')
local msg       = require('msg')
local gosay     = require('gosay')
local safe      = require('safe')
local mysql_api = require('mysql_pool_api')
local socket    = require('socket')
local math      = require('math')
local link      = require('link')
local app_utils = require('app_utils')
local http_api  = require('http_short_api')

local add_DepositInfo = link["OWN_DIED"]["http"]["addDepositInfo"]

local account_dbname  = "app_ident___ident"

local reward_businessInfo = "app_crowd___crowd"

--mysql的操作
local sql_fmt = {
		--对表modelInfo的操作
		sql_insert_modelInfo = " insert into modelInfo (company,model,createTime,endTime,validity,businessID,isThirdModel) values ( '%s','%s',%d,%d,%d,%d,%d ) ",

		--对表imeiOrder的操作
		sql_insert_imeiOrder = " insert into imeiOrder (company,verificationCode,createTime,mirrtalkCount,model,appKey) values ( '%s','%s',%d,%d,'%s',%d ) ",

		--对表mirrtalkInfo的操作
		sql_insert_mirrtalkInfo = " insert ignore into mirrtalkInfo (imei,model,status,nCheck,endTime,validity,createTime,updateTime,remarks,isOccupy) values (%d,'%s','%s',%d,%d,%d,%d,%d,'%s',%d) ",

		--对表mirrtalkHistory的操作
		sql_insert_mirrtalkHistory = " insert into mirrtalkHistory (imei,movement,endStatus,updateTime,remarks) values (%d,'%s','%s',%d,'%s') ",

		--对表getImeiInfo的操作
		sql_insert_getImeiInfo = " insert into getImeiInfo (verificationCode,createTime,currentIndex,imei,nCheck,depositPassword,clientIP,appKey) values ('%s',%d,%d,%d,%d,'%s',inet_aton('%s'),%d) ",

		--在userModelInfo中插入数据
		sql_insert_usermodelinfo = " insert into userModelInfo (businessID,appKey,model,createTime,updateTime,validity,isThirdModel) values (%d,%d,'%s',%d,%d,%d,%d ) ",

		--排除重复的验证码
		sql_check_imeiOrder = " select 1 from imeiOrder where verificationCode = '%s' ",

		--避免重复插入model
		sql_check_modelInfo = " select 1 from userModelInfo where model = '%s' ",

		--检查businessID是否在表businessInfo中存在
		sql_select_businessID = " select 1 from businessInfo where businessID = '%s' ",

		--检查 appKey 和 businessID 是否存在于 userAppKeyInfo
		sql_select_userAppKeyInfo = " select 1 from userAppKeyInfo where businessID = '%s' and appKey = %d ",
}

local url_tab = {
	type_name = 'system',
	app_key = nil,
	client_host = nil,
	client_body = nil,
	}

--生成20位随机验证码
local random_table = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
    'u', 'v', 'w', 'x', 'y', 'z'
} --62

function random_singly()
    local t = socket.gettime()
    local st = string.format("%f", t)
    local d = string.sub(st, -2, -1)
    local n = tonumber(d) % 10
    return n
end

function random_number(nub)
    local val = ''
    for i=1,nub do
        local rad = random_singly()
        val = val .. rad
    end
    return val
end

function random_among(_st, _ed)
    local btw = tostring(_ed - _st)
    local fld =  string.find(btw, '%.')

    local src = {}
    local nb, sv
    local rt = ""
    local step = 1
    local is_little = false
    local newbits = 0
    local allbits = 0
    if not fld then
        src[1] = btw
    else
        src[1] = string.sub(btw, 1, fld - 1)
        src[2] = string.sub(btw, fld + 1, -1)
    end
    repeat
        allbits = #src[step]
        newbits = (random_number(allbits) % allbits) + 1
        if newbits ~= allbits then
            rt = random_number(newbits)
        else
            for i=1, allbits do
                if is_little then
                    sv = random_singly()
                else
                    nb = tonumber(string.sub(src[step], i, i))
                    sv = random_singly() % (nb + 1)
                    if sv < nb then
                        is_little = true
                    end
                end
                rt = rt .. sv
            end
        end
        if not fld then
            --goto EXIT
            break
        else
            if step == 1 then
                rt = rt .. '.'
            end
            step = step + 1
        end
    until step == 2
    --::EXIT::
    return (tonumber(rt) + _st)
end


function random_string(nub)
    local var = ''
    for i=1,nub do
        local ret = random_among(1111111111, 9999999999999)
        local rad1 = tonumber(string.format("%d", ret / 62))
        local rad2 = rad1 % 62 +1		--#random_table  <----->  62

        var = var .. random_table[rad2]
    end
    return var
end


--生成imei
local function create_imei()
	--以随机数产生第一位1到9的数字
	local first_num = math.random(1,9)
	--以随机方式产生13个0到9的随机数
	local tab_middlenum = {}
	tab_middlenum['1'] = first_num

	for n = 2,14,1 do
		tab_middlenum[tostring(n)] = math.random(0,9)
	end

	local middlenum = string.format("%d%d%d%d%d%d%d%d%d%d%d%d%d%d",tab_middlenum['1'],tab_middlenum['2'],tab_middlenum['3'],tab_middlenum['4'],tab_middlenum['5'],tab_middlenum['6'],tab_middlenum['7'],tab_middlenum['8'],tab_middlenum['9'],tab_middlenum['10'],tab_middlenum['11'],tab_middlenum['12'],tab_middlenum['13'],tab_middlenum['14'])
	--根据第二部产生的随机数计算nCheck
	local a = 0
	for i = 1,13,2 do
		a = (a + tab_middlenum[tostring(i)])
	end

	local b= 0
	for j=2,14,2 do
		local num = 2*tab_middlenum[tostring(j)]
		if (num) >= 10 then
			local res = ( ( num-(num%10) )/10 ) + num%10
			b = b + res
		else
			b = b + num
		end
	end

	local  nCheck = nil
	local c = ( a + b )
	if c <= 10 then
		nCheck = 0
	elseif (c%10 == 0) then
		nCheck = 0
	else
		nCheck = (10 - c%10)
	end
	--拼接成15位IMEI
	local middlestring = tostring(middlenum)
	return middlestring,nCheck
end
--把15位的IMEI分割成单个字符
local function string_to_chsr(imei)
	local tab_imei = {}
	for i=1,15,1 do
		tab_imei[tostring(i)] = string.sub(imei,i,i)
	end
	return tab_imei
end

--生成押金密码
local function createdepositPassword(tab_imei)
	local tab_depositPassword = {}
	if tonumber(tab_imei['15']) == 0 or tonumber(tab_imei['15']) == 1 then
		local nCheck = 3
		tab_depositPassword['1'] = tonumber(string.format("%s%s",tab_imei['1'],tab_imei['14']))%3
		tab_depositPassword['2'] = tonumber(string.format("%s%s",tab_imei['2'],tab_imei['13']))%3
		tab_depositPassword['3'] = tonumber(string.format("%s%s",tab_imei['3'],tab_imei['12']))%3
		tab_depositPassword['4'] = tonumber(string.format("%s%s",tab_imei['4'],tab_imei['11']))%3
		tab_depositPassword['5'] = tonumber(string.format("%s%s",tab_imei['5'],tab_imei['10']))%3
		tab_depositPassword['6'] = tonumber(string.format("%s%s%s%s",tab_imei['6'],tab_imei['7'],tab_imei['8'],tab_imei['9']))%3
	else 
		local nCheck = tonumber(tab_imei['15'])
		tab_depositPassword['1'] = tonumber(string.format("%s%s",tab_imei['1'],tab_imei['14']))%nCheck
		tab_depositPassword['2'] = tonumber(string.format("%s%s",tab_imei['2'],tab_imei['13']))%nCheck
		tab_depositPassword['3'] = tonumber(string.format("%s%s",tab_imei['3'],tab_imei['12']))%nCheck
		tab_depositPassword['4'] = tonumber(string.format("%s%s",tab_imei['4'],tab_imei['11']))%nCheck
		tab_depositPassword['5'] = tonumber(string.format("%s%s",tab_imei['5'],tab_imei['10']))%nCheck
		tab_depositPassword['6'] = tonumber(string.format("%s%s%s%s",tab_imei['6'],tab_imei['7'],tab_imei['8'],tab_imei['9']))%nCheck
	end
	local depositPassword = string.format("%d%d%d%d%d%d",tab_depositPassword['1'],tab_depositPassword['2'],tab_depositPassword['3'],tab_depositPassword['4'],tab_depositPassword['5'],tab_depositPassword['6'])
	return depositPassword
end

local function group_imei()
	local ta_imei = {}
	local ta_ncheck = {}
	local ta_depositPassword = {}
	local count = 1
	local i,n = create_imei()
	local shortimei = tonumber(i)
	local nCheck = tonumber(n)
	local imei = i..n
	local tab_imei = string_to_chsr(imei)
	local depositPassword = createdepositPassword(tab_imei)
	ta_imei[tostring(count)] = shortimei
	ta_ncheck[tostring(count)] = nCheck
	ta_depositPassword[tostring(count)] = depositPassword
		
	return ta_imei,ta_ncheck,ta_depositPassword
end

local function insert_modelInfo(args)
	local validity = 1
	local isThirdModel = tonumber(args['isThirdModel'])
	local businessID = tonumber(args['businessID'])
	local createTime = os.time()
	local appKey = tonumber(args['clientappKey'])
	local endTime = ( createTime + 315360000 )

	only.log('D',string.format(" model = %s " , args['model'] ))
	local sql_str = string.format( sql_fmt.sql_check_modelInfo,args['model'])
	local ok , ret = mysql_api.cmd(reward_businessInfo , 'select', sql_str)
	--only.log('D',string.format(" ret ==========================> %s " , ret[1]['model'] ))
	if ok and ret then 
		if #ret > 1 or #ret == 1 then 
			only.log('D',string.format(" %s is exist! " , "model" ))
		else
			--在表 modelInfo 中插入
			local sql_str = string.format( sql_fmt.sql_insert_modelInfo ,args['company'],args['model'],createTime, endTime,validity,businessID,isThirdModel)
			local ok , ret = mysql_api.cmd(account_dbname , 'INSERT', sql_str)
			if not ok or not ret then
				only.log('E',string.format(" modelInfo:model=%s,businessID=%s INSERT failed!" ,args['model'],businessID ))
				gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
			end

			--在 userModelInfo 中插入数据
			local sql_str = string.format( sql_fmt.sql_insert_usermodelinfo ,businessID,appKey,args['model'],createTime,createTime,validity,isThirdModel)
			local ok , ret = mysql_api.cmd(reward_businessInfo , 'INSERT', sql_str)
			if not ok or not ret then
				only.log('E',string.format(" userModelInfo:model=%s,businessID=%s,appKey=%d INSERT failed!" ,args['model'],businessID,appKey ))
				gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
			end

		end
	else
		only.log('D',string.format(" select userModelInfo failed! " ))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end	
end

--在表imeiOrder中插入
local function insert_imeiOrder(args)
	local createTime = os.time()
	local mirrtalkCount = tonumber(args['mirrtalkCount'])
	local clientappKey = tonumber(args['clientappKey'])
	local flag = 0
	local MyverificationCode
	repeat
		local myverificationCode = random_string(20)
		only.log('D','myverificationCode = %s', myverificationCode )
		local sql_str = string.format( sql_fmt.sql_check_imeiOrder,myverificationCode)
		local ok , ret = mysql_api.cmd(account_dbname , 'select', sql_str)
		if ret and #ret == 0 then
	 	local sql_str = string.format( sql_fmt.sql_insert_imeiOrder ,args['company'],myverificationCode,createTime,mirrtalkCount,args['model'],clientappKey)
	 	local ok , ret = mysql_api.cmd(account_dbname , 'INSERT', sql_str)
	 		if not ok or not ret then
				only.log('E',string.format(" imeiOrder:verificationCode=%s,mirrtalkCount=%s,model=%s INSERT failed!" , myverificationCode, mirrtalkCount,args['model']))
				gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
			else
				flag = 1 + flag
				MyverificationCode = myverificationCode
			end
		end	
	until (flag == 1)		
	return MyverificationCode
end

--在表mirrtalkInfo和mirrtalkHistory中插入
local function insert_mirrtalkInfo_mirrtalkHistory(args,verification)
	--初始状态默认为10a，详情可查表systemStatusType
	--status =  = tostring(10).."a"
	local status
	if args['status']=="" then
		status="10a"
	else
		status=args['status']
	end
	local model = args['model']
	local createTime = os.time()
	--有效期为10年 315360000秒
	local endTime = (createTime + 315360000)
	local updateTime = os.time()
	--有效性默认为1，即有效
	local validity = 1
	local remarks = args['mirrtalkInforemarks']
	--是否被占用，默认被占用
	local isOccupy = 0
	local mirrtalkCount = tonumber(args['mirrtalkCount'])

	local tab_imei = {}

	local count = 0
	--控制只生成mirrtalkcount相符的imei
	local counts=1
	for counts=1,mirrtalkCount,1 do
		local ta_imei,ta_ncheck,ta_depositPassword = group_imei()
		local shortimei = ta_imei['1']
		local nCheck = ta_ncheck['1']

		local model = args['model']
		local si = shortimei
		local Check = nCheck

		local sql_str = string.format( sql_fmt.sql_insert_mirrtalkInfo,si,model,status,Check,endTime,validity,createTime,updateTime,remarks,isOccupy)
		local ok , ret = mysql_api.cmd(account_dbname , 'INSERT', sql_str)
		if not ok or not ret then
			count = count - 1
			only.log('D',string.format(" mirrtalkInfo:imei=%s,nCheck=%s,remarks=%s INSERT failed at count= %d! ", si,Check,remarks,counts))
		else
			--成功说明插入成功，证明没有重复，可执行下面两张表的操作
			--把14位shortimei和ncheck连接起来
			local imei = shortimei..nCheck
			--产生语镜终端状态变动的动作,默认为10
			local movement = tostring( 10 )
			--变动后的状态，默认10a
			--local endStatus = tostring(10).."a"
			local endStatus = status
			local updateTime = os.time()
			only.log('D','imei = %s', imei )
			local remarks = args['mirrtalkHistoryremarks']

			local sql_str = string.format( sql_fmt.sql_insert_mirrtalkHistory,imei,movement,endStatus,updateTime,remarks)
			local ok , ret = mysql_api.cmd(account_dbname , 'INSERT', sql_str)
			if not ok or not ret then
				count = count - 1
				only.log('E',string.format(" mirrtalkHistory: imei= %s,remarks= %s INSERT failed at count= %d!" , imei,remarks, counts ))
			else
				--得到押金密码
				local depositPassword = ta_depositPassword['1']
				--第一步产生的20位验证码
				local verificationCode = verification
				only.log('D','verificationCode = %s', verificationCode )
				local createTime = os.time()
				--循环的次数
				local currentIndex = counts

				local clientIP = args['clientIP']
				local clientappKey = tonumber(args['clientappKey'])
				--在表getImeiInfo中插入
				only.log('D','clientIP = %s',clientIP)

				local sql_str = string.format( sql_fmt.sql_insert_getImeiInfo,verificationCode,createTime,currentIndex,si,Check,depositPassword,clientIP,clientappKey)
				local ok , ret = mysql_api.cmd(account_dbname , 'INSERT', sql_str)
				if not ok or not ret then
					count = count - 1
					only.log('D',string.format(" getImeiInfo:verificationCode=%s,shortimei=%d,Check=%s,depositPassword=%s,clientIP=%s " , verificationCode,si,Check,depositPassword ))
				else
					local  tab = {
						--传给被校验调用API的appkey
						appKey = tonumber(args['appKey']),
						IMEI = shortimei..nCheck,
						depositPassword = depositPassword,
					}
					--校验是否能调用API是自己的appkey
					local secret = app_utils.get_secret(args['appKey'])
			
					only.log('D','appKey = %s', tab['appKey'] )
					tab['sign'] = app_utils.gen_sign(tab,secret)
					local body = utils.table_to_kv(tab)

					local post_data = 'POST /rewardapi/v2/addDepositInfo HTTP/1.0\r\n' ..
					'Host:%s:%s\r\n' ..
					'Content-Length:%d\r\n' ..
					'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
					local data = string.format(post_data, add_DepositInfo['host'], add_DepositInfo['port'], #body, body)
					local ret = http_api.http(add_DepositInfo, data, true)
					if not ret then 
						count = count - 1
						gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"call addDepositInfo")
					end

					count = count + 1
					only.log('D',string.format('data = %s', data) )
					local body = string.match(ret, '{.+}')
					local ok, json_data = utils.json_decode(body)
					if not ok or tonumber(json_data['ERRORCODE']) ~= 0 then
						only.log('D',string.format(" call function addDepositInfo failed! " ))
					end
					local string_imei = shortimei..nCheck
					--local count_imei = tostring(count)
					table.insert(tab_imei,string_imei)
					--local str_count = string.format("%s",count)
					--tab_imei[str_count] = string_imei
				end
			end
		end
	end
	return count,tab_imei
end

local function check_parameter( args )

	if not args['company'] or args['company'] == "" or string.find(args['company'],"'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"company")
	end

	if not args['model'] or #args['model'] ~= 5 or args['model'] == "" or string.find(args['model'],"'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"model")
	end

	if not args['businessID'] or args['businessID'] == "" or string.find(args['businessID'],"'") or tonumber(args['businessID'])==nil then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"businessID")
	else
		if args['businessID'] ~= "0" then 
			local sql_str = string.format( sql_fmt.sql_select_businessID,args['businessID'])
			local ok , ret = mysql_api.cmd(reward_businessInfo , 'select', sql_str)
			if ok and ret then
				if #ret < 1 then 
				only.log('D',string.format(" %s is not exist! " , args['businessID'] ))
				gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"businessID")
				end
			else
				only.log('D',string.format(" check businessID failed! " ))
				gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
			end
		end
	end

	if not args['isThirdModel'] or args['isThirdModel'] == "" or string.find(args['isThirdModel'],"'") or tonumber(args['isThirdModel'])==nil then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"isThirdModel")
	else
		isThirdModel = tonumber(args['isThirdModel'])
		if isThirdModel ~= 1 and isThirdModel ~= 0 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"isThirdModel")
		end
	end

	if not args['clientappKey'] or args['clientappKey'] == "" or string.find(args['clientappKey'],"'") or #args['clientappKey']>10 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"clientappKey")
	end

	if not args['mirrtalkCount'] or args['mirrtalkCount'] == "" or tonumber(args['mirrtalkCount']) == 0 or string.find(args['mirrtalkCount'],"'") or tonumber(args['mirrtalkCount'])>500 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"mirrtalkCount")
	end

	if not args['mirrtalkInforemarks'] or args['mirrtalkInforemarks'] == "" or string.find(args['mirrtalkInforemarks'],"'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"mirrtalkInforemarks")
	end

	if not args['mirrtalkHistoryremarks'] or args['mirrtalkHistoryremarks'] == "" or string.find(args['mirrtalkHistoryremarks'],"'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"mirrtalkHistoryremarks")
	end

	if not args['clientIP'] or args['clientIP'] == "" or #args['clientIP']<7 or string.find(args['clientIP'],"'") then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"clientIP")
	end

	if args['status']~='13g' and args['status']~='' then 
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"status")
	end

	if args['useType'] == "" then
		args['useType'] = 1
	else
		if tonumber(args['useType']) == nil then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"useType")
		elseif tonumber(args['useType'])<1 or tonumber(args['useType']) > 3 then
			gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"useType")
		end
	end

	--检查 appKey 和 businessID 是否匹配
	local sql_str = string.format( sql_fmt.sql_select_userAppKeyInfo ,args['businessID'], tonumber(args['clientappKey']) )
	local ok , ret = mysql_api.cmd(reward_businessInfo , 'SELECT', sql_str)
	if not ok or not ret then
		only.log('E',string.format(" userAppKeyInfo:appKey=%d,businessID='%s' INSERT failed!" ,tonumber(args['clientappKey']),args['businessID'] ))
		gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
	end
	if #ret ~= 1 then
		only.log('E',string.format("businessID and appKey not match:businessID='%s',appKey='%s' ",args['businessID'],args['clientappKey']))
		gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'businessID and appKey ')
	end

	safe.sign_check(args, url_tab)
	return args
end

local function handle()
	math.randomseed(os.time())
	local req_ip   = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()
	--only.log('D','0000000000000000000000000000')
	if not req_body then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
	end
	url_tab['client_host'] = req_ip
	url_tab['client_body'] = req_body

	local args = utils.parse_url(req_body)

	if not args['appKey'] or args['appKey'] == "" then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
	else
		--参数检查时的appkey
		url_tab['app_key'] = args['appKey']
	end

	args = check_parameter( args )

	insert_modelInfo(args)
	local verification = insert_imeiOrder(args)
	local count,tab_imei = insert_mirrtalkInfo_mirrtalkHistory(args,verification)

	--local data = string.format("asktimes: %s, successtimes: %d !",args['mirrtalkCount'],count)
	--table.insert(tab_imei,1,'imei:')
	--table.insert(tab_imei,1,data)
	local data = {}
	data['verificationCode'] = verification
	data['imei'] = tab_imei
	data['successcounts'] = count
	local ok,rec = utils.json_encode(data)
	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], rec)

end

safe.main_call( handle )
