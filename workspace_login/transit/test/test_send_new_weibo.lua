
local cutils = require('cutils')
local cjson  = require('cjson')
local sha    = require('sha1')
local socket = require('socket')


function gen_sign(T, secret)

    local kv_table = {}
    for k,v in pairs(T) do
        if type(v) ~= "table" then
            if k ~= "sign" then
                table.insert(kv_table, k)
            end
        end
    end
    table.insert(kv_table, "secret")
    table.sort(kv_table)
    local sign_string = kv_table[1] .. T[kv_table[1]]
    for i = 2, #kv_table do
        if kv_table[i] ~= 'secret' then
            sign_string = sign_string .. kv_table[i] .. T[kv_table[i]]
        else
            sign_string = sign_string .. kv_table[i] .. secret
        end
    end
    print(sign_string)

    local result = sha.sha1(sign_string)
    local sign_result = string.upper(result)

    print(sign_result)

    return sign_result
end



function keys_binary_to_req(host_ip, host_port , url_path, args, file_name, file_binary)
    local head_boundary = string.format("----WebKitFormBoundaryDcO1SS%dMTDfpuu%skkU",socket.gettime() * 10000000, os.time())
    local head_format =   'POST /%s HTTP/1.0\r\n' ..
                            'Host:%s:%s\r\n' ..
                            'Content-Length:%d\r\n' ..
                            'Content-Type: multipart/form-data; boundary=' .. head_boundary .. '\r\n\r\n%s'

    local body_boundary = '--' .. head_boundary
    local body_suffix   = body_boundary .. '--'
    local body_prefix   = '%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n'

    local body_data = ''
    for i , v in pairs(args) do
        body_data = body_data .. string.format(body_prefix,body_boundary,i,v)
    end

    -- print(body_data)
    -- print(string.format("%s   %s   %s" , file_name, #file_binary, body_boundary))

    --Content-Transfer-Encoding: binary\r\n
    if file_name and file_binary then
        body_data = body_data .. string.format('%s\r\nContent-Disposition: form-data; name="mmfile"; filename="%s"\r\n' ..
                    'Content-Type: application/octet-stream\r\n\r\n%s\r\n',
                                    body_boundary, file_name , file_binary)

-- Content-Disposition: form-data; name="mmfile"; filename="c-dJBlQhKGWABJUKAAAN3GYMhxw722.amr"
-- Content-Type: audio/AMR

    end
    body_data =  body_data .. body_suffix
    local req_data = string.format(head_format, url_path, host_ip, tostring(host_port),  #body_data , body_data)
    return req_data
end

local function test_weibo()
	local args ={
		appKey = "4058657628",
		sourceID = "1340e33c910611e4b76f00a0d1e9d648",
		sourceType =1,
		multimediaURL = "http://g4.tweet.daoke.me/group4/M08/FD/DC/c-dJUFT2eBqAYc5sAAAN3ARoJDw771.amr",
		messageType = 1,
		senderAccountID = "kxl1QuHKCD",
		senderLongitude =116.9065760,
		senderLatitude =34.7141662,
		senderDirection =96,
		senderSpeed = 69,
		senderAltitude = 40,
		senderType = 2,
		commentID ="15cfb65ae03a11e39a0600266cf08874",
		receiverAccountID ="Vldmxal2l5",
		-- receiverLongitude = 116.9291964,
		-- receiverLatitude =34.7142600,
		-- receiverDistance =200,
		-- receiverDirection = "[94,45]",
		-- receiverSpeed = "[100,200]",
		content ="我要回家,我要妈妈",
		interval = 150 ,
		level =25,
		callbackURL = "http://api.daoke.io:80/customizationapp/v2/callbackFetch4MilesAheadPoi?positionType=1123110",
		-- autoReply = 1,
		-- intervalDis = 150,
		tipType =1,
		-- POIID = "P12345678",
		-- POIType = "123456"
	}

	local secret = "AD9615274A78006196C91390F449250DDA38D64A"	
	args['sign'] = gen_sign(args,secret)

	local host_ip= "192.168.1.195"
	local host_port = 8088
	local url_path = "weiboapi/v2/sendPersonalWeibo"

	local req =  keys_binary_to_req(host_ip, host_port , url_path, args, nil	, nil)

	print(req)

	local ok,ret = cutils.http(host_ip, host_port, req, #req)
	if not ok or ret == nil then
		print("post data failed!")
		return
	end
	print(ret)
end


local function sort_func( key , val  )
    print(key,val)
end

local function table_resvert( tab )
    local tmp_tab = {}
    for i = #tab , 1 , -1 do
        table.insert(tmp_tab,tab[i])
    end
    return tmp_tab
end

local function test_table_sort(  )
    local tab = {2,3,6,-1,7,10}
    local new_tab = resvert(tab)
    print(table.concat( tab, ", "))
    print(table.concat( new_tab, ", "))
end


-- test_weibo()

test_table_sort()
