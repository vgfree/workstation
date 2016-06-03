local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local scan      = require('scan')
local only      = require('only')
local gosay 	= require('gosay')
local ngx	= require('ngx')
local msg 	= require('msg')
local weme_car  = 'weme_car___car'

local G         = {
        get_user_info = " select accountID as accountID,nickname as nickName,headName as headPic,birthday as birthday,gender as sex, activeCity as cityName,cityCode as cityCode,introduction as introduction,carBrand as carBrand,carModels as  carModel, plateNumber as carNumber from userInfo "
}

local url_tab   = {
        type_name       = 'updateInfoByID',
        app_Key         = nil,
        client_host     = nil,
        client_body     = nil,
}

function handle()
	local req_ip            = ngx.var.remote_addr
        local req_body          = ngx.req.get_body_data()
        local req_header        = ngx.req.get_headers()

	url_tab['client_host']          = req_ip



	local ok_status, ok_ret_userInfo = mysql_api.cmd(weme_car, 'SELECT', G.get_user_info)

	for index = 1, #ok_ret_userInfo do
		userInfo                        = {}
		userInfo['accountID']       	= (ok_ret_userInfo[index]['accountID'] == nil and "") or ok_ret_userInfo[index]['accountID']
        	userInfo['nickName']            = (ok_ret_userInfo[index]['nickName'] == nil and "") or ok_ret_userInfo[index]['nickName']
        	userInfo['headPic']             = (ok_ret_userInfo[index]['headPic'] == nil and "") or ok_ret_userInfo[index]['headPic']
        	userInfo['birthday']        	= (ok_ret_userInfo[index]['birthday'] == nil and "") or ok_ret_userInfo[index]['birthday']
        	userInfo['sex']                 = (tonumber(ok_ret_userInfo[index]['sex']) == 0 and tonumber(ok_ret_userInfo[index]['sex']) == 1) or 2
		userInfo['cityName']        	= (ok_ret_userInfo[index]['cityName'] == nil and "") or ok_ret_userInfo[index]['cityName']
		userInfo['cityCode']        	= (ok_ret_userInfo[index]['cityCode'] == nil and "") or ok_ret_userInfo[index]['cityCode']
        	userInfo['introduction']    	= (ok_ret_userInfo[index]['introduction'] == nil and "") or ok_ret_userInfo[index]['introduction']
        	userInfo['carBrand']        	= (ok_ret_userInfo[index]['carBrand'] == nil and "") or ok_ret_userInfo[index]['carBrand']
        	userInfo['carModel']        	= (ok_ret_userInfo[index]['carModel'] == nil and "") or ok_ret_userInfo[index]['carModel']
        	userInfo['carNumber']       	= (ok_ret_userInfo[index]['carNumber'] == nil and "") or ok_ret_userInfo[index]['carNumber']

        	local ok, ret_info = utils.json_encode(userInfo)
        	only.log('D', 'ret_userInfo = %s', ret_info)
        	local ok_status, ok_ret = redis_api.cmd('realroad', 'SET', userInfo['accountID'] .. ':userInfo', userInfo)
        	if not (ok_status and ok_ret) then
			gosay.go_false(url_tab, msg["MSG_DO_REDIS_FAILED"])
        	end
	end

	only.log('D', 'ok_config = %s', scan.dump(ok_config))

	local ret = 'ok';

        gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ret)

end

handle()
