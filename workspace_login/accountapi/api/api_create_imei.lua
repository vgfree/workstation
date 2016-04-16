--wufei
--2015.5.16
--生成IMEI

local ngx       = require('ngx')
local utils     = require('utils')
local only      = require('only')
local msg       = require('msg')
local gosay     = require('gosay')
local safe      = require('safe')
local socket    = require('socket')
local math      = require('math')
local link      = require('link')
local sha       = require('sha1')
local app_utils = require('app_utils')
local cjson     =  require('cjson')
local http_api  = require('http_short_api')
local mysql_api = require('mysql_pool_api')



local add_DepositInfo = link["OWN_DIED"]["http"]["addDepositInfo"]

local mirrtalk_dbname  = "app_ident___ident"

local reward_businessInfo = "app_crowd___crowd"

---- 2015-09-09 jiang z.s. 
---- IMEI一次生成的最大个数
local IMEI_MAX_COUNT = 500 

--mysql的操作
local sql_fmt = {
        --对表modelInfo的操作
        sql_insert_modelInfo = " insert into modelInfo (company,model,createTime,endTime,validity,businessID,isThirdModel) "..
                                " values ( '%s','%s',%d,%d,%d,%d,%d ) ",

        --对表imeiOrder的操作
        sql_insert_imeiOrder = " insert into imeiOrder (company,verificationCode,createTime,mirrtalkCount,model,appKey) "..
                                "values ( '%s','%s',%d,%d,'%s',%d ) ",

        --对表mirrtalkInfo的操作
        sql_insert_mirrtalkInfo = " insert ignore into mirrtalkInfo (imei,model,status,nCheck,endTime,validity,createTime, "..
                                    " updateTime,remarks,isOccupy) values (%d,'%s','%s',%d,%d,%d,%d,%d,'%s',%d) ",

        --对表mirrtalkHistory的操作
        sql_insert_mirrtalkHistory = " insert into mirrtalkHistory (imei,movement,endStatus,updateTime,remarks) values (%d,'%s','%s',%d,'%s') ",

        --对表getImeiInfo的操作
        sql_insert_getImeiInfo = " insert into getImeiInfo (verificationCode,createTime,currentIndex,imei,nCheck, "..
                                " depositPassword,clientIP,appKey) values ('%s',%d,%d,%d,%d,'%s',inet_aton('%s'),%d) ",

        --在userModelInfo中插入数据
        sql_insert_usermodelinfo = " insert into userModelInfo (businessID,appKey,model, useType, brandType, createTime,updateTime,validity, "..
                                    " isThirdModel) values (%d, %d,'%s', %d, '%s', %d, %d, %d, %d ) ",

        --排除重复的验证码
        sql_check_imeiOrder = " select 1 from imeiOrder where verificationCode = '%s' ",

        --避免重复插入model
        sql_check_modelInfo = " select 1 from userModelInfo where model = '%s' ",

        --检查businessID是否在表businessInfo中存在
        sql_select_businessID = " select 1 from businessInfo where validity = 1 AND businessID = %d ",

        --检查 appKey 和 businessID 是否存在于 userAppKeyInfo
        sql_select_userAppKeyInfo = " select 1 from userAppKeyInfo where validity = 1 AND businessID = %d and appKey = %s ",


        ----判断imei是否存在
        check_imei_exists = "select concat(imei,nCheck) as imei from mirrtalkInfo where imei in (%s) " , 

        --对表mirrtalkInfo的操作
        batch_insert_mirrtalkInfo_field = " insert ignore into mirrtalkInfo (imei,model,status,nCheck,endTime,validity,createTime, "..
                                    " updateTime,remarks,isOccupy) values %s ",

        batch_insert_mirrtalkInfo_values = " (%d,'%s','%s',%d,%d,%d,%d,%d,'%s',%d) ",


        --对表mirrtalkHistory的操作
        batch_insert_mirrtalkInfo_history_field = " insert into mirrtalkHistory (imei,movement,endStatus,updateTime,remarks) values %s ",


        batch_insert_mirrtalkInfo_history_values = " (%d,'%s','%s',%d,'%s') " , 


        --对表getImeiInfo的操作
        batch_insert_getImeiInfo_field = " insert into getImeiInfo (verificationCode,createTime,currentIndex,imei,nCheck, "..
                                " depositPassword,clientIP,appKey) values %s ",

        batch_insert_getImeiInfo_values = " ('%s',%d,%d,%d,%d,'%s',inet_aton('%s'),%d) ",

        batch_insert_mirrtalkDepositInfo_field = "INSERT INTO mirrtalkDepositInfo(imei,depositPassword,depositStatus,createTime,updateTime,remark) "..
                                    " values %s ",

        batch_insert_mirrtalkDepositInfo_values = " (%s,'%s', %d ,%s ,%s ,'%s') " ,

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
        local rad2 = rad1 % 62 +1       --#random_table  <----->  62

        var = var .. random_table[rad2]
    end
    return var
end


---- 用于生成单个IMEI
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

local function get_imei_pos( imei, pos )
    return string.sub(imei,pos,pos)
end

--生成押金密码
local function createdepositPassword(imei)

    local tab_depositPassword = {}
    if tonumber(get_imei_pos(imei,15)) == 0 or tonumber(get_imei_pos(imei,15)) == 1 then
        local nCheck = 3
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,1),get_imei_pos(imei,14)))%3)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,2),get_imei_pos(imei,13)))%3)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,3),get_imei_pos(imei,12)))%3)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,4),get_imei_pos(imei,11)))%3)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,5),get_imei_pos(imei,10)))%3)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s%s%s",get_imei_pos(imei,6),get_imei_pos(imei,7),get_imei_pos(imei,8),get_imei_pos(imei,9)))%3)
    else 
        local nCheck = tonumber(get_imei_pos(imei,15))
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,1),get_imei_pos(imei,14)))%nCheck)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,2),get_imei_pos(imei,13)))%nCheck)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,3),get_imei_pos(imei,12)))%nCheck)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,4),get_imei_pos(imei,11)))%nCheck)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s",get_imei_pos(imei,5),get_imei_pos(imei,10)))%nCheck)
        table.insert(tab_depositPassword,tonumber(string.format("%s%s%s%s",get_imei_pos(imei,6),get_imei_pos(imei,7),get_imei_pos(imei,8),get_imei_pos(imei,9)))%nCheck)
    end

    local depositPassword = table.concat( tab_depositPassword, "")
    return depositPassword
end

local function create_imei_base_info()
    ---- i imei的前面14位
    ---- n imei的最后一位
    local shortimei , nCheck = create_imei()
    return shortimei, nCheck
end

-- 新添加model，需要添加两张表userModelInfo业务表，modelInfo基本表
local function insert_modelInfo(args)
    local validity = 1
    local isThirdModel = tonumber(args['isThirdModel'])
    local businessID = tonumber(args['businessID'])
    local createTime = os.time()
    local appKey = tonumber(args['clientappKey'])
    local endTime = ( createTime + 315360000 )
    local brandType = args['brandType'] or ''
    local useType = args['useType'] or 1

    local sql_str = string.format( sql_fmt.sql_check_modelInfo,args['model'])
    local ok , ret = mysql_api.cmd(reward_businessInfo , 'select', sql_str)
    --only.log('D',string.format(" ret ==========================> %s " , ret[1]['model'] ))
    if ok and ret then 
        if #ret > 1 or #ret == 1 then 
            only.log('D',string.format(" %s is exist! " , "model" ))
        else
            --在表 modelInfo 中插入
            local sql_str = string.format( sql_fmt.sql_insert_modelInfo ,args['company'],args['model'],createTime, endTime,validity,businessID,isThirdModel)
            local ok , ret = mysql_api.cmd(mirrtalk_dbname , 'INSERT', sql_str)
            if not ok or not ret then
                only.log('E',string.format(" modelInfo:model=%s,businessID=%s INSERT failed!" ,args['model'],businessID ))
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
            end

            --在 userModelInfo 中插入数据
            local sql_str = string.format( sql_fmt.sql_insert_usermodelinfo ,businessID,appKey,args['model'],useType,brandType,createTime,createTime,validity,isThirdModel)
            local ok , ret = mysql_api.cmd(reward_businessInfo , 'INSERT', sql_str)
            if not ok or not ret then
                only.log('E',string.format(" userModelInfo:model=%s,businessID=%s,appKey=%d INSERT failed!" ,args['model'],businessID,appKey ))
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
            end
            only.log('D',string.format(" model = %s insert succed" , args['model'] ))

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
    ---- 最大尝试10次
    local i_max = 10 
    for i = 1, i_max do 
        local myverificationCode = random_string(20)
        ---- 临时生成一个特征码,长度20位
        only.log('D', string.format('myverificationCode = %s', myverificationCode ))

        local sql_str = string.format( sql_fmt.sql_check_imeiOrder,myverificationCode)
        local ok , ret = mysql_api.cmd(mirrtalk_dbname , 'SELECT', sql_str)
        if ret and #ret == 0 then
            local sql_str = string.format( sql_fmt.sql_insert_imeiOrder ,args['company'], myverificationCode, createTime, mirrtalkCount, args['model'], clientappKey)
            local ok , ret = mysql_api.cmd(mirrtalk_dbname , 'INSERT', sql_str)
            if not ok or not ret then
                only.log('E',string.format(" imeiOrder:verificationCode=%s,mirrtalkCount=%s,model=%s INSERT failed!" , myverificationCode, mirrtalkCount, args['model']))
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
            else
                return myverificationCode
            end
        end 
    end

end

--在表mirrtalkInfo和mirrtalkHistory中插入
local function really_create_imei(args,verification)
    --初始状态默认为10a，详情可查表systemStatusType
    --status =  = tostring(10).."a"
    local status=args['status'] or "10a"
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

    local model = args['model']

    local tmp_imei_list = {}
    local tab_imei_list = {}
    for i = 1 , mirrtalkCount * 3 , 1 do
        local shortimei, nCheck = create_imei_base_info()
        local imei = shortimei .. nCheck
        -- only.log('D',string.format("current imei is:%s",imei))
        if not tab_imei_list[imei] then
            tab_imei_list["count"] = 1 + ( tonumber(tab_imei_list["count"]) or 0  )
            tab_imei_list[imei] = shortimei
        end
        table.insert(tmp_imei_list,imei) -- 15
    end

    -- only.log('D',string.format("current imei list:%s ", table.concat( tmp_imei_list, ", ") ))

    ---- 过滤存在IMEI
    local sql_str = string.format(sql_fmt.check_imei_exists, table.concat( tmp_imei_list, ", "))
    local ok , ret = mysql_api.cmd(mirrtalk_dbname , 'SELECT', sql_str)
    if not ok or not ret then
        only.log('E', "check_imei_exists failed, %s" , sql_str )
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    if ok and ret and type(ret) =="table" and #ret > 0  then
        for i, v in pairs(ret) do
            tab_imei_list[v] = nil
            tab_imei_list["count"] = tonumber(tab_imei_list["count"]) - 1 
        end
    end

    local tab_really_imei = {}
    for k , v in pairs(tab_imei_list) do
        if k and #tostring(k) == 15 then
            table.insert(tab_really_imei,k)
        end
    end

    only.log('W',string.format("this request need imei Count:%s current imei count is :%s ", mirrtalkCount ,tab_imei_list["count"] ))

    local succ_count = 0 

    local clientIP = args['clientIP']
    local clientappKey = tonumber(args['clientappKey'])

    ---- 最多重试X次
    local iTryMax = 10 

    --产生语镜终端状态变动的动作,默认为10
    local movement = tostring( 10 )
    local endStatus = status

    local batch_imei_count = 100

    local succ_imei_str = ""

    local need_create_total = 0 

    local currentLoop = 1 


    for iTry = 0 , iTryMax do
        ---- 本次剩余创建的个数
        need_create_total = mirrtalkCount - succ_count 

        local sql_tab = {}

        local sql_mirrtalk_tab = {}
        local sql_mirrtalk_history_tab = {}
        local sql_getimeiinfo_tab = {}
        local sql_DepositInfo_tab = {}

        local current_need_create_count = need_create_total
        if current_need_create_count > batch_imei_count then
            ---- 本次需要创建的总数,不能一次全部创建
            current_need_create_count = batch_imei_count
        end

        local tab_max_index = succ_count  + current_need_create_count
        if tab_max_index > mirrtalkCount then
            ---- 当前数组的最大下标
            tab_max_index = mirrtalkCount
        end

        only.log('D', string.format("====current need create count %s , tab_max_index:%s ", current_need_create_count, tab_max_index))

        currentLoop = 1 + currentLoop

        only.log('D',string.format("====current loop startPos:%s endPos:%s ", succ_count + 1 , tab_max_index ))

        for current_create = succ_count + 1  , tab_max_index  do
            local imei = tab_really_imei[current_create]
            
            local shortimei = string.sub(imei,1,14)
            local nCheck = string.sub(imei,15,15)

            local sql_str = string.format( sql_fmt.batch_insert_mirrtalkInfo_values,shortimei,model,status,nCheck,endTime,validity,createTime,updateTime,remarks,isOccupy)
            table.insert(sql_mirrtalk_tab,sql_str)


            local sql_str = string.format( sql_fmt.batch_insert_mirrtalkInfo_history_values,imei,movement,endStatus,updateTime,remarks)
            table.insert(sql_mirrtalk_history_tab, sql_str)


            local depositPassword = createdepositPassword(imei)
            local sql_str = string.format( sql_fmt.batch_insert_getImeiInfo_values,verification,createTime,currentLoop,shortimei,nCheck,depositPassword,clientIP,clientappKey)
            table.insert(sql_getimeiinfo_tab, sql_str)

        	local input_pwd = ngx.md5(sha.sha1(depositPassword) .. ngx.crc32_short(depositPassword))
        	-- only.log('D',string.format("====current shortimei:%s nCheck:%s depositPassword:%s, input_pwd:%s ", shortimei, nCheck, depositPassword ,input_pwd) )
        	local deposit_str = string.format( sql_fmt.batch_insert_mirrtalkDepositInfo_values, imei, input_pwd, 1, 
                                                                                                createTime, updateTime, '语镜押金信息初始化')
        	table.insert(sql_DepositInfo_tab, deposit_str)
        end

        -- only.log('D',string.format("====deposit imei:%s ", table.concat(sql_DepositInfo_tab, ", " ) ) )
        local sql_str = string.format(sql_fmt.batch_insert_mirrtalkInfo_field,table.concat( sql_mirrtalk_tab, ", " ))
        table.insert(sql_tab,sql_str)

        local sql_str = string.format(sql_fmt.batch_insert_mirrtalkInfo_history_field,table.concat( sql_mirrtalk_history_tab, ", " ))
        table.insert(sql_tab,sql_str)

        local sql_str = string.format(sql_fmt.batch_insert_getImeiInfo_field,table.concat( sql_getimeiinfo_tab, ", " ))
        table.insert(sql_tab,sql_str)

        local ok , ret = mysql_api.cmd(mirrtalk_dbname , 'AFFAIRS', sql_tab)
        if not ok or not ret then
            only.log('W',string.format('create imei failed, sql_str:%s', table.concat( sql_tab, "\r\n")))
        else
            ---- 目前创建成功数
            if succ_imei_str == "" then
                succ_imei_str = succ_imei_str .. table.concat( tab_really_imei, ",", succ_count + 1, tab_max_index )
            else
                succ_imei_str = succ_imei_str  .. "," .. table.concat( tab_really_imei, ",", succ_count + 1, tab_max_index )
            end

            succ_count =  current_need_create_count + succ_count
            -- only.log('D',string.format("OK=====succed:%s list_str:%s", current_need_create_count , succ_imei_str))
        end

        -- depositInfo 在crowdRewards库，需要分开执行
        only.log('D',string.format("batch_insert_mirrtalkDepositInfo_field"))
	    local deposit_str = string.format(sql_fmt.batch_insert_mirrtalkDepositInfo_field, table.concat(sql_DepositInfo_tab, ", " ))
	    local ok , ret = mysql_api.cmd(reward_businessInfo , 'INSERT', deposit_str)
	    if not ok or not ret then
	        only.log('W',string.format('[init_deposit_info] create deposit info failed, sql_str:%s', table.concat( deposit_str, "\r\n")))
	    end

        if succ_count >= mirrtalkCount then
            only.log('D',string.format("need break,all of imei create succed"))
            ---- 全部生成完成
            break
        end
    end
    return succ_count , succ_imei_str

end

local model_useType = {
	[1] = '',
	[2] = '',
	[3] = '',
}

local function check_parameter( args )

    if not args['company'] or args['company'] == "" or string.find(args['company'],"'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"company")
    end

    if not args['model'] or #args['model'] ~= 5 or args['model'] == "" or string.find(args['model'],"'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"model")
    end

    if not args['useType'] or not utils.is_number(args['useType']) or not model_useType[tonumber(args['useType'])] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"useType")
    end

    if args['brandType'] 
            and #args['brandType']>0 
            and (#args['brandType'] > 64 
                or string.find(args['brandType'],"'") 
                or string.find(args['brandType']," ")) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"brandType")
    end

    if not args['businessID'] or not utils.is_number(args['businessID'])  then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"businessID")
    else

    	if args['useType'] == "1" and args['businessID'] == "0" then
    		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"businessID")
    	end

        if args['businessID'] ~= "0" then 
            local sql_str = string.format( sql_fmt.sql_select_businessID,args['businessID'])
            local ok , ret = mysql_api.cmd(reward_businessInfo , 'select', sql_str)
            if ok and ret then
                if #ret < 1 then 
                    only.log('E',string.format(" %s is not exist! " , args['businessID'] ))
                    gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"businessID")
                end
            else
                only.log('E',string.format("mysql check businessID:%s failed!,sql_str:%s " , args['businessID'] , sql_str ))
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
            end
        end
    end

    ----是否第三方model
    if not args['isThirdModel'] or args['isThirdModel'] == "" or string.find(args['isThirdModel'],"'") or tonumber(args['isThirdModel'])==nil then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"isThirdModel")
    else
        isThirdModel = tonumber(args['isThirdModel']) or -1 
        if isThirdModel ~= 1 and isThirdModel ~= 0 then
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"isThirdModel")
        end
    end

    ---- 客户端APPKEY
    if not args['clientappKey'] or not utils.is_number(args['clientappKey']) or string.find(args['clientappKey'],"'") or #args['clientappKey']>10 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"clientappKey")
    end

    ---- 生成IMEI的总数
    if not args['mirrtalkCount'] or not utils.is_number(args['mirrtalkCount']) or tonumber(args['mirrtalkCount']) <= 0 or tonumber(args['mirrtalkCount']) > IMEI_MAX_COUNT then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"mirrtalkCount")
    end

    ---- 生成IMEI的备注信息
    if not args['mirrtalkInforemarks'] or args['mirrtalkInforemarks'] == "" or string.find(args['mirrtalkInforemarks'],"'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"mirrtalkInforemarks")
    end

    if not args['mirrtalkHistoryremarks'] or args['mirrtalkHistoryremarks'] == "" or string.find(args['mirrtalkHistoryremarks'],"'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"mirrtalkHistoryremarks")
    end

    if not args['clientIP'] or args['clientIP'] == "" or #args['clientIP']<7 or string.find(args['clientIP'],"'") then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"clientIP")
    end

    if args['status'] and args['status'] ~= '' and args['status']~='13g' then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"status")
    end

    safe.sign_check(args, url_tab)
end

local function check_appkey_validity( args )

    --检查 appKey 和 businessID 是否匹配
    local sql_str = string.format( sql_fmt.sql_select_userAppKeyInfo ,args['businessID'], tonumber(args['clientappKey']) )
    local ok , ret = mysql_api.cmd(reward_businessInfo , 'SELECT', sql_str)
    if not ok or not ret then
        only.log('E',string.format(" userAppKeyInfo:appKey=%d,businessID='%s' INSERT failed!" ,tonumber(args['clientappKey']),args['businessID'] ))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    
    if #ret ~= 1 then
        only.log('E',string.format("businessID and appKey not match:businessID=%s,appKey='%s' , %s ",args['businessID'],args['clientappKey'], sql_str ))
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'businessID and appKey ')
    end

    return true
end

local function handle()
    
    math.randomseed(os.time())

    local req_ip   = ngx.var.remote_addr
    local req_body = ngx.req.get_body_data()
    if not req_body then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_host'] = req_ip
    url_tab['client_body'] = req_body

    local args = utils.parse_url(req_body)

    if not args['appKey'] or not utils.is_number(args['appKey']) or  #args['appKey'] < 7 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
    else
        --参数检查时的appkey
        url_tab['app_key'] = args['appKey']
    end

    check_parameter( args )

    -- 检测businessID是否和appKey一致
    check_appkey_validity(args)

    local count , imei_str = really_create_imei(args,verification)
    local list_str = "[]"
    if not count or tonumber(count) < 1  or not imei_str then
        count = 0
        list_str = "[]"
    else
        local tab_imei = utils.str_split(imei_str,",")
        if tab_imei and #tab_imei > 0 then
            local ok, ret = pcall(cjson.encode,tab_imei)
            if ok and ret then
                list_str = ret
            end
        end
    end

    insert_modelInfo(args)

    ---- 生成特征码
    local verification = insert_imeiOrder(args)
    if not verification then
        only.log('E', string.format("insert_imeiOrder create new verification failed"))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"verification")
    end

    local ret_str = string.format("{'verificationCode':'%s','successcounts':%s,'imei':%s}",verification,count,list_str)
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret_str)

end

safe.main_call( handle )--wufei