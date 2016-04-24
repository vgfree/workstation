-- api_login
-- author : louis.tin
-- date	  : 04-14-2016
-- 登录接口
local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local gosay     = require('gosay')
local utils     = require('utils')
local only      = require('only')
local link      = require('link')
local cjson     = require('cjson')
local scan	= require('scan')
local safe 	= require('safe')
local app_utils = require('app_utils')
local msg = require('msg')

-- TODO 指定base userInfo 等参数的数据库
local app_config_db   = { [1] = 'login_config___config', [2] = 'weme_car___car'}

local url_tab = { 
	type_name   = 'login',
	app_Key     = '',
	client_host = '',
	client_body = '',
}

local G = {
	imei      = '',
	req_ip    = '',
	body      = '',
	err_desc  = '',

	cur_month = nil,
	cur_date  = nil,
	cur_time  = 0,


	-- sql_openconfig_info = " select customArgs from openconfigInfo where appkey='%s'",
	-----------------------------------------------------------------------
	-- TODO base roadRank sicong userInfo 的值都是从mysql中读取,表格未建立
	-- 在userInfo中部分key拼写格式不一致,没有sex字段,使用accountID来查找
	sql_login_info = "SELECT base,roadRank,sicong FROM loginConfig WHERE appKey='%s'",
	sql_login_userInfo = "SELECT gender as sex,nickname as nickName,headName as headerUrl,activeCity as cityName FROM userInfo WHERE accountID='%s'"
}


---- 执行函数
local function ready_execution(appKey)
	local sql_str = string.format(G.sql_login_info, appKey)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	local ok_status, ok_config = mysql_api.cmd(app_config_db[1], 'SELECT', sql_str)
	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end
	if #ok_config < 1  then
		only.log('E', '[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
		return false, nil
	end

		
	return true, ok_config[1]['base'], ok_config[1]['roadRank'], ok_config[1]['sicong']
end

local function ready_execution_userInfo(accountID)
	local sql_str = string.format(G.sql_login_userInfo, accountID)
	only.log('W', "mysql select condfig info is :%s", sql_str)

	-- TODO 指定执行目标数据库
	local ok_status, ok_config = mysql_api.cmd(app_config_db[2], 'SELECT', sql_str)

	if not ok_status  then
		only.log('E', 'connect database failed when query sql_openconfig_info, %s ', sql_str)
		return false, nil
	end
	if not ok_config then
		only.log('E', 'configInfo return is nil when query sql_openconfig_info')
		return false, nil
	end
	if #ok_config < 1  then
		only.log('E', '[READY_FAILED]return empty when query sql_openconfig_info, %s ' , sql_str)
		return false, nil
	end

	---------------------------------------------------------------------------------------------------
	-- 将sex转换为number
	ok_config[1]['sex'] = tonumber(ok_config[1]['sex'])
	
	user_info = cjson.encode(ok_config[1])
	
	return true, user_info

end

----检查参数
local function check_parameter(parameter_table)
	-->>
	-- safe check 
	--safe.sign_check(parameter_table, url_info)
	
	--> check username
	if not app_utils.check_accountID(parameter_table['accountID']) then                    
        	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')         
    	end
	
	--[[ 
	local tmp = appKey
	if not tmp or  #tmp > 11 then 
		only.log('E','[CHECK_FAILED]imei: appKey=%s must be less 10 number',appKey)
		return false 
	end 
	--]]
end

local function go_exit()
	local ret_str = '{"ERRORCODE":"ME01002", "RESULT":"appKey error"}'
	only.log('E','appKey error')
	gosay.respond_to_json_str(url_tab,ret_str)
end
------------------------------------------------------------------------------------------
local random_table = {                                                          
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',                       
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',                       
        'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',                       
        'U', 'V', 'W', 'X', 'Y', 'Z',                                           
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',                       
        'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',                       
        'u', 'v', 'w', 'x', 'y', 'z'                                            
} 

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
                        break                                                   
                else                                                            
                        if step == 1 then                                       
                                rt = rt .. '.'                                  
                        end                                                     
                        step = step + 1                                         
                end                                                             
        until step == 2                                                         
        return (tonumber(rt) + _st)                                             
end     

-- 生成token 
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
-------------------------------------------------------------------------------------------

local function handle()
	local req_head   = ngx.req.raw_header()
	local req_ip     = ngx.var.remote_addr
	local req_body   = ngx.req.get_body_data()
	local req_method = ngx.var.request_method
	local args       = ngx.req.get_uri_args()
	-- 获取head
	local req_header	 = ngx.req.get_headers() 
	
	only.log('D', '-----------------------------------------------------------------------------')	
	only.log('D', "req_head = %s", scan.dump(req_head))
	only.log('D', '-----------------------------------------------------------------------------')	
	only.log('D', "req_body = %s", scan.dump(req_body))
	only.log('D', '-----------------------------------------------------------------------------')	
	only.log('D', "method=%s",req_method)
	---- get_today
	G.cur_month =  string.gsub(string.sub(ngx.get_today(),1,7),"%-","")
	G.cur_date  = string.gsub(ngx.get_today(),"%-","")
	G.cur_time = os.time()

	
	if req_method == "POST" then                                            
                if not req_body then                                            
                        only.log('I', "post body is nil")                       
                        go_exit()                                               
                        return                                                  
                end                                                             
                args   = ngx.decode_args(req_body)                              
                G.body = string.format('POST %s',req_body)                      
                                                                                
                if not args or type(args) ~= 'table' then                       
                        only.log('I', "post bad request!")                      
                        go_exit()                                               
                        return                                                  
                end                                                             
        else                                                                    
                if not args or type(args) ~= 'table' then                       
                        only.log('I', "get bad request!")                       
                        go_exit()                                               
                        return                                                  
                end                                                             
                G.body = string.format('GET %s', ngx.encode_args(args) )                                               
        end                    

	G.imei      	= req_body['imei']
	G.appKey      	= req_header['appkey']

	only.log('D', "appKey=%s", req_header['appkey'])
	
	-- 获取请求参数
	local appKey		= req_header['appkey']
	local sign		= req_header['sign']
	local accessToken	= req_header['accessToken']
	local timestamp		= req_header['timestamp']
	local accountID		= req_header['accountid']
	local imei		= req_body['imei']
	local imsi		= req_body['imsi']
	local modelVer		= req_body['modelVer']
	local androidVer	= req_body['androidVer']
	local baseBandVer	= req_body['baseBandVer']
	local kernelVer		= req_body['kernelVer']
	local buildVer		= req_body['buildVer']
	local lcdWidth		= req_body['lcdWidth']
	local lcdHeight		= req_body['lcdHeight']
	
	-- url_tab 赋值
	url_tab['app_Key'] 	= appKey
	url_tab['client_host'] 	= req_ip
	url_tab['client_body'] 	= req_body 
	
	-- 拼接出parameter_table用于check
	local parameter_table 		= {}
	parameter_table.appKey 		= appKey
	parameter_table.sign 		= sign
	parameter_table.accessToken 	= accessToken	
	parameter_table.timestamp	= timestamp
	parameter_table.accountID	= accountID
	parameter_table.imei 		= imei
	parameter_table.imsi 		= imsi
	parameter_table.modelVer 	= modelVer
	parameter_table.androidVer 	= androidVer
	parameter_table.baseBandVer	= baseBandVer
	parameter_table.kernelVer	= kernelVer
	parameter_table.buildVer	= buildVer
	parameter_table.lcdWidth	= lcdWidth
	parameter_table.lcdHeight	= lcdHeight

	
	local ok_check = check_parameter(parameter_table)
		if ok_check == false then
		only.log('E','xxxxxxx1111111111')
			go_exit()
		return
	end

	
	-- 从mysql中获取base roadRank sicong 参数
	local ok_status, ok_ret_base, ok_ret_roadRank, ok_ret_sicong = ready_execution(appKey)
		only.log('E','xxxxxxx2222222222')
		if ok_status == false then
		go_exit()
	end
	-- 防止返回nil值
	--[[
	ok_ret_base['msgServer'] = (ok_ret_base['msgServer'] == 'nil' and "") or ok_ret_base['msgServer']	
	ok_ret_base['msgPort'] = (ok_ret_base['msgPort'] == 'nil' and 0) or tonumber(ok_ret_base['msgPort'])	
	ok_ret_base['heart'] = (ok_ret_base['heart'] == 'nil' and 0) or tonumber(ok_ret_base['heart'])	
	ok_ret_base['fileUrl'] = (ok_ret_base['fileUrl'] == 'nil' and "") or ok_ret_base['fileUrl']	
	
	ok_ret_roadRank['rrIoUrl'] = (ok_ret_roadRank['rrIoUrl'] == 'nil' and "") or ok_ret_roadRank['rrIoUrl']
	ok_ret_roadRank['normalRoad'] = (ok_ret_roadRank['normalRoad'] == 'nil' and 0) or tonumber(ok_ret_roadRank['normalRoad'])
	ok_ret_roadRank['highRoad'] = (ok_ret_roadRank['highRoad'] == 'nil' and 0) or tonumber(ok_ret_roadRank['highRoad'])
	ok_ret_roadRank['askTime'] = (ok_ret_roadRank['askTime'] == 'nil' and 0) or tonumber(ok_ret_roadRank['askTime'])

	ok_ret_sicong['serverType'] = (ok_ret_sicong['serverType'] == 'nil' and 0) or tonumber(ok_ret_sicong['serverType'])
	--]]
	-- 从mysql中获取 userInfo 参数
	local ok_status, ok_ret_userInfo = ready_execution_userInfo(accountID)
	only.log('D', 'userInfo = %s', ok_ret_userInfo)
	if ok_status == false then
		--go_exit()
	end

	-- 防止返回nil
	--[[
	ok_ret_userInfo['sex'] = (ok_ret_userInfo['sex'] == 'nil' and 0) or tonumber(ok_ret_userInfo['sex'])	
	ok_ret_userInfo['nickName'] = (ok_ret_userInfo['nickName'] == 'nil' and "") or ok_ret_userInfo['nickName']
	ok_ret_userInfo['headerUrl'] = (ok_ret_userInfo['headerUrl'] == 'nil' and "") or ok_ret_userInfo['headerUrl']
	ok_ret_userInfo['cityName'] = (ok_ret_userInfo['cityName'] == 'nil' and "") or ok_ret_userInfo['cityName']
	--]]
	

	local token	 = random_string(10)
	local msgToken	 = 1478523690


	-- 返回信息
	local ret_str = string.format('{"ERRORCODE":"%s", "RESULT":{"token":"%s", "msgToken":"%s", "accountID":"%s", "base":%s, "roadRank":%s, "sicong":%s, "userInfo":%s}}',
	 "0", 
	(token == nil and "") or token, 
	(msgToken == nil and "") or msgToken, 
	(accountID == nil and "") or accountID, 
	(ok_ret_base == nil and "") or ok_ret_base, 
	(ok_ret_roadRank == nil and "") or ok_ret_roadRank, 
	(ok_ret_sicong == nil and "") or ok_ret_sicong, 
	(ok_ret_userInfo == nil and "") or ok_ret_userInfo)	

	only.log('I','[SUCCED] ___%s',ret_str)
	gosay.respond_to_json_str(url_tab,ret_str)
end

handle()
