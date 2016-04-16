local only      = require("only")
local utils	= require("utils")
local socket    = require("socket")
local mysql_api = require("mysql_pool_api")
local sha = require('sha1')
local appfun = require("appfun")

module('fun_sendsms', package.seeall)

--	author:		guoqi
--	date:		2014.11.11
--	function:	send sms

local app_sendsms = "app_sendsms___sendsms"

local  sql_fmt ={
	sql_update	= "UPDATE messageInfo SET returnCode = '%s', returnInfo = '%s' WHERE bizid = '%s'",
	sql_insert  = "INSERT INTO messageInfo(mobile,content,createTime,bizid,appKey,returnCode,sendCount,remarks) VALUES('%s', '%s', %d, '%s', %s, 'code', %d, '%s')",

}

local sms_info = {
	accountSid  =	"aaf98fda4351e36201438a4c7c961049",
	accountToken = "c0bde57aa2a64528938dec0b56eb0410",
	appId = "aaf98f894a85eee5014a956f9d5f06fd",
	host = "sandboxapp.cloopen.com",
	port = 8883,
	softVersion = "2013-12-26",
	sms_body    = "%s/Accounts/%s/SMS/TemplateSMS?sig=%s",	
	sms_fmt     = "POST %s HTTP/1.0\r\nHost: %s:%d\r\nContent-Length: %d \r\nAccept:application/json;\r\nContent-Type: application/json;charset=utf-8;\r\nAuthorization:%s\r\n%s",

}



local send_sms_flag = "ss"

function send(mobile,content,appKey,remarks)

	local cur_time = os.date("%Y%m%d%H%M%S",os.time())
	only.log('D',string.format("---------cur_time = %s",cur_time))

	--> check parameter
	if not (mobile and content and appKey) then  
		only.log("E","parameter error") 
		return false,"parameter error"
	end
	if not remarks then
		remarks = ""
	end
	
	local tab = {}
	tab["accountSid"] = utils.url_encode(sms_info["accountSid"])
	tab["accountToken"] = utils.url_encode(sms_info["accountToken"])
	tab["appId"] = utils.url_encode(sms_info["appId"])
	tab["softVersion"] = utils.url_encode(sms_info["softVersion"])
	tab["content"] =  utils.url_encode(content ) .. string.lower(utils.url_encode("【道客快分享】"))


	local SigParameter=tab['accountSid']..tab["accountToken"]..cur_time
	local sig = string.upper(ngx.md5(sha.sha1(SigParameter) .. ngx.crc32_short(SigParameter)))

	local res=tab['accountSid']..':'..cur_time
	only.log('D',string.format("------->>>>>res = %s", res))
	local Authorization = appfun.str2base64(res)

	--> construction data
	local data_center = string.format('{"to":"%s","appId":"%s","templateId":"1","datas":["%s"]}',mobile,tab['appId'],tab['content'])
	local body = string.format(sms_info.sms_body,tab["softVersion"],tab["accountSid"],sig)
	local len = #body + #data_center
	local data = string.format(sms_info.sms_fmt,body,sms_info["host"],sms_info["port"],len,data_center)

	--> send sms
	local tcp = socket.tcp()
	tcp:setoption('keepalive',true)
	tcp:settimeout(1,'b')

	local ret = tcp:connect(sms_info["host"],sms_info["port"])  
	if not ret then
		only.log("E",string.format("%s,host : %s  port : %d","not connected on the third parties",sms_info['host'],sms_info['port']))
		return false,"internal data error"
	end

	tcp:send(data)
	local result = tcp:receive("*a")
	tcp:close()

	only.log("D",result)
	--> generation of bizid and insert to mysql

	if not result then
		only.log("E","in the result http failed")
		return false,"http failed"
	end

	local uuid = utils.create_uuid()
	local bizid = send_sms_flag .. uuid

	if string.find(content,"'") then
		only.log("W",content)
		content = string.gsub(content,"'","")
	end

	local createtime = os.time()
	local sql_insert = string.format(sql_fmt.sql_insert,mobile,content,createtime,bizid,appKey,1,remarks)
	local ok,res = mysql_api.cmd(app_sendsms,"insert",sql_insert)

	if not ok then
		only.log("E","mysql insert failed : " .. sql_insert)
	end
	-->check http information returned 
	local res_body = string.match(result, "\r\n\r\n(.+)")

	if not res_body then
		only.log("E","in the res_body http failed")
		res_body=""

		local sql_update = string.format(sql_fmt.sql_update,"http failed",res_body,bizid)
		local ok,res = mysql_api.cmd(app_sendsms,"update",sql_update)
		
		if not ok then
			only.log("E","mysql update failed : " .. sql_update)
		end
		return false,"http failed"
	end

	local error_code = string.match(res_body, '<error>(.+)</error>')

	if tonumber(error_code) ~= 0 then
		only.log("E","http failed : " .. "res_body : " .. res_body)
		
		local sql_update = string.format(sql_fmt.sql_update,"http failed",res_body,bizid)
		local ok,res = mysql_api.cmd(app_sendsms,"update",sql_update)
	
		if not ok then
			only.log("E","mysql update failed : " .. sql_update)
		end
		return false,"http failed"
	end
	
	--> update mysql, return bizid
	local sql_update = string.format(sql_fmt.sql_update,"0","发送成功",bizid)
	ok,res = mysql_api.cmd(app_sendsms,"update",sql_update)

	if not ok then
		only.log("E","mysql update failed : " .. sql_update)
	end
	
	return true,bizid 
end

