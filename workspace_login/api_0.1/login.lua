-- name   :	login.lua
-- author :	louis.tin
-- data	  :	04-23-2016
-- 登录接口	

local ngx	= require('ngx')
local only	= require('only')
local mysql_api = require('mysql_pool_api')                                     
local gosay     = require('gosay')                                              
local utils     = require('utils')                                              
local link      = require('link')                                               
local cjson     = require('cjson')                                              
local scan      = require('scan')                                               
local safe      = require('safe')                                               
local app_utils = require('app_utils')                                          
local msg	= require('msg')

local app_config_db	= { [1] = 'login_config___config', [2] = 'weme_car___car' }

local url_tab = {                                                               
	type_name	= 'login',                                                  
	app_Key		= '',                                                       
	client_host	= '',                                                       
	client_body	= '',                                                       
}

local G = {
	sql_login_info = "SELECT base,roadRank,sicong FROM loginConfig WHERE appKey='%s'",
        sql_login_userInfo = "SELECT gender as sex,nickname as nickName,headName as headerUrl,activeCity as cityName FROM userInfo WHERE accountID='%s'"
}

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

	-- 将sex值转化为number
	ok_config[1]['sex'] = tonumber(ok_config[1]['sex'])                                                            

	return true, ok_config[1]                                                  
end    


local function check_parameter(parameter_table)
	--safe.sign_check(parameter_table, url_info) 

	if not app_utils.check_accountID(parameter_table['accountID']) then                    
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')         
	end

	local tmp = parameter_tab['appKey']                                                  
	if not tmp or  #tmp > 1 then                                           
		only.log('E','[CHECK_FAILED]imei: appKey=%s must be less 10 number', tmp)
		return false                                                    
	end  
end

-------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------

local function go_exit()                                                        
	local ret_str = '{"ERRORCODE":"ME01002", "RESULT":"appKey error"}'      
	only.log('E','appKey error')                                            
	gosay.respond_to_json_str(url_tab, ret_str)                              
end        

local function handle()
	local req_header	= ngx.req.get_headers()
	local req_body		= ngx.req.get_body_data()
	local req_ip		= ngx.var.remote_addr

	only.log('D', 'req_header = %s', scan.dump(req_header))
	only.log('D', 'req_body = %s', req_body)

	-- 获取请求参数
	-- 将header和body中的参数组装到一个table中,方便后续check和使用
	local parameter_tab		= {}
	parameter_tab['appKey']		= req_header['appkey'] 
	parameter_tab['sign']           = req_header['sign']                            
	parameter_tab['accessToken']	= req_header['accessToken']                     
	parameter_tab['timestamp']	= req_header['timestamp']                       
	parameter_tab['accountID']	= req_header['accountid']                       
	parameter_tab['imei']           = req_body['imei']                              
	parameter_tab['imsi']           = req_body['imsi']                              
	parameter_tab['modelVer']       = req_body['modelVer']                          
	parameter_tab['androidVer']     = req_body['androidVer']                        
	parameter_tab['baseBandVer']    = req_body['baseBandVer']                       
	parameter_tab['kernelVer']      = req_body['kernelVer']                         
	parameter_tab['buildVer']       = req_body['buildVer']                          
	parameter_tab['lcdWidth']       = req_body['lcdWidth']                          
	parameter_tab['lcdHeight']      = req_body['lcdHeight']			

	url_tab['app_Key']      = parameter_tab['appKey']                                        
	url_tab['client_host']  = req_ip                                        
	url_tab['client_body']  = req_body

	only.log('D', 'parameter_table = %s', scan.dump(parameter_tab))
	-- 参数检查
	local ok_check	= check_parameter(parameter_tab)                       
	if ok_check == false then                                       
		only.log('E','parameter error !')                               
		go_exit()                                               
		return                                                          
	end      

	-- 从mysql中获取base roadRank sicong 参数                               
	local ok_status, ok_ret_base, ok_ret_roadRank, ok_ret_sicong = ready_execution(parameter_tab['appKey'])
	if ok_status == false then                                      
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_FAILED_GET_SECRET'], 'appKey')
	end      
	
	ok_ret_base	= cjson.decode(ok_ret_base)
	ok_ret_roadRank = cjson.decode(ok_ret_roadRank)
	ok_ret_sicong	= cjson.decode(ok_ret_sicong)
	
	ok_ret_base['msgServer']	= (ok_ret_base['msgServer'] == nil and "") or ok_ret_base['msgServer']       
	ok_ret_base['msgPort']		= (ok_ret_base['msgPort'] == nil and 0) or tonumber(ok_ret_base['msgPort'])    
	ok_ret_base['heart']		= (ok_ret_base['heart'] == nil and 0) or tonumber(ok_ret_base['heart'])  
	ok_ret_base['fileUrl']		= (ok_ret_base['fileUrl'] == nil and "") or ok_ret_base['fileUrl']     

	ok_ret_roadRank['rrIoUrl']	= (ok_ret_roadRank['rrIoUrl'] == nil and "") or ok_ret_roadRank['rrIoUrl']
	ok_ret_roadRank['normalRoad']	= (ok_ret_roadRank['normalRoad'] == nil and 0) or tonumber(ok_ret_roadRank['normalRoad'])
	ok_ret_roadRank['highRoad']	= (ok_ret_roadRank['highRoad'] == nil and 0) or tonumber(ok_ret_roadRank['highRoad'])
	ok_ret_roadRank['askTime']	= (ok_ret_roadRank['askTime'] == nil and 0) or tonumber(ok_ret_roadRank['askTime'])

	ok_ret_sicong['serverType']	= (ok_ret_sicong['serverType'] == nil and 0) or tonumber(ok_ret_sicong['serverType'])
	
	ok_ret_base	= cjson.encode(ok_ret_base)
	ok_ret_roadRank = cjson.encode(ok_ret_roadRank)
	ok_ret_sicong	= cjson.encode(ok_ret_sicong)

	-- 从mysql中获取 userInfo 参数                                          
	local ok_status, ok_ret_userInfo = ready_execution_userInfo(parameter_tab['accountID'])  
	if ok_status == false then                                              
		gosay.go_false(url_tab, msg['MSG_ERROR_ACCOUNT_ID_NO_MONEY'], 'accountID')
	end                  

	ok_ret_userInfo['sex']		= (ok_ret_userInfo['sex'] == nil and 0) or tonumber(ok_ret_userInfo['sex'])    
	ok_ret_userInfo['nickName']	= (ok_ret_userInfo['nickName'] == nil and "") or ok_ret_userInfo['nickName']
	ok_ret_userInfo['headerUrl']	= (ok_ret_userInfo['headerUrl'] == nil and "") or ok_ret_userInfo['headerUrl']
	ok_ret_userInfo['cityName']	= (ok_ret_userInfo['cityName'] == nil and "") or ok_ret_userInfo['cityName']

	ok_ret_userInfo = cjson.encode(ok_ret_userInfo)

	only.log('D', 'ok_ret_base = %s', ok_ret_base)                         
	only.log('D', 'ok_ret_roadRank = %s', ok_ret_roadRank)                         
	only.log('D', 'ok_ret_sicong = %s', ok_ret_sicong)                         
	only.log('D', 'ok_ret_userInfo = %s', ok_ret_userInfo)                         

	-- 生成token
	-- msgToken 需要调用田山川接口生成
	local token      = random_string(10)                                    
	local msgToken   = 1478523690

	-- 组装返回信息
	local ret_str = string.format('{"ERRORCODE":"%s", "RESULT":{"token":"%s", "msgToken":"%s", "accountID":"%s", "base":%s, "roadRank":%s, "sicong":%s, "userInfo":%s}}',
	"0",                                                                   
	(token == nil and "") or token,                                         
	(msgToken == nil and "") or msgToken,                                   
	(parameter_tab['accountID'] == nil and "") or parameter_tab['accountID'],                                 
	(ok_ret_base == nil and "{}") or ok_ret_base,                             
	(ok_ret_roadRank == nil and "{}") or ok_ret_roadRank,                     
	(ok_ret_sicong == nil and "{}") or ok_ret_sicong,                         
	(ok_ret_userInfo == nil and "{}") or ok_ret_userInfo) 

	only.log('I', '[SUCCED] ___%s', ret_str)

	gosay.respond_to_json_str(url_tab, ret_str) 
end

safe.main_call(handle)


--[[
1. 通过http head和body传入参数
2. 将传入参数重组为一个新的table
3. 参数检查 
4. 从mysql中取出base Roadrank sicong userInfo数据
5. 生成token msgtoken
6. 组装返回信息,返回数据
--]]


