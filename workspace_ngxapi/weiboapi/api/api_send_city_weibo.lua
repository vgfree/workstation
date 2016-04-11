
-- author: houyaqian
-- date: 2014 04 12 Tue 13:54:20 CST

local ngx = require 'ngx'
local only = require 'only'
local gosay = require 'gosay'
local utils = require 'utils'
local msg = require 'msg'
local safe = require('safe')
local redis_pool_api = require 'redis_pool_api'
local weibo_fun = require 'weibo_fun'

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

local function handle()

    local req_heads = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    url_info['client_host'] = ip
    url_info['client_body'] = req_body

    if not req_body then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_NO_BODY"])
    end

    local body_args = utils.parse_form_data(req_heads, req_body)
    if not body_args then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "Content-Type")
    end

    url_info['app_key'] = body_args['appKey']

    -->> check appKey and sign
    safe.sign_check(body_args, url_info)
	if not body_args['regionCode'] or not utils.is_number(body_args['regionCode']) then
	only.log('D',"regionCode is error")
	gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "regionCode")
	end

	if body_args['level'] and not utils.is_number(body_args['level']) then
	only.log('D',"level is error")
	gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "level")
	end
	body_args['level']               = tonumber(body_args['level'])

	if not utils.is_number(body_args['interval']) or tonumber(body_args['interval']) < 0  then
	only.log('D',"interval is error")
	gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "interval")
	end
	body_args['interval']               = tonumber(body_args['interval'])

	local ok, res1, res2
	ok, res1 = weibo_fun.check_geometry_attr2(body_args['senderLongitude'], body_args['senderLatitude'], body_args['senderAltitude'], body_args['senderDistance'],body_args['senderDirection'],body_args['senderSpeed'],'sender')
	if not ok then
	gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], res1)
	end

	-- because this tab is used in the store of redis
	ok, res1, res2 = weibo_fun.check_geometry_attr(body_args['receiverLongitude'], body_args['receiverLatitude'],body_args['receiverAltitude'], body_args['receiverDistance'], body_args['receiverDirection'], body_args['receiverSpeed'], 'receiver',body_args)

	if not ok then
	gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], res1)
	end

	if body_args['receiveCrowd'] then
	local ok, receiveCrowd = utils.json_decode(body_args['receiveCrowd'])

	if not ok then
	only.log('D',"JSON DECODE FAILED")
	gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveCrowd")
	end
	------最大接口数组应该小于50
	if type(receiveCrowd)~='table' or #receiveCrowd>50 then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveCrowd ")
	end
	body_args['receiveCrowd'] = receiveCrowd
	end
	
	body_args['receiverDirection'] = res1
	body_args['receiverSpeed']     = res2
	
	body_args['senderType']          = tonumber(body_args['senderType'])     
	body_args['messageType']		 = tonumber(body_args['messageType'])
	body_args['tipType']     		 = tonumber(body_args['tipType'])
	body_args['autoReply']			 = tonumber(body_args['autoReply'])
	body_args['intervalDis']		 = tonumber(body_args['intervalDis'])
	body_args['receiveSelf']		 = tonumber(body_args['receiveSelf'])
	body_args['receiverLongitude']	 = tonumber(body_args['receiverLongitude'])
	body_args['receiverLatitude']	 = tonumber(body_args['receiverLatitude'])
	body_args['receiverDistance']	 = tonumber(body_args['receiverDistance'])
	
	local ok,string = utils.json_encode(body_args)
	if not ok then
        	gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'], 'json_encode')
	elseif string == '[ ]' then
        	gosay.go_false(url_info, msg['MSG_ERROR_REQ_NO_BODY'])
	end

	only.log('D',string)
	
	local ok,bizid = redis_pool_api.cmd('weiboNew','SET','city', string)

	
	if not ok then
		only.log('S',string)
		gosay.go_false(url_info, msg['MSG_DO_REDIS_FAILED'])
	end
	
	if utils.is_word(bizid) then
		local result = string.format('{"bizid":"%s"}',bizid)
		gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'],result)
	end

	weibo_fun.string_to_error_code(bizid,url_info)
end

safe.main_call( handle )
