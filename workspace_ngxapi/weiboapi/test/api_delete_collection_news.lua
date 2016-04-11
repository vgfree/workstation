
local socket = require('socket')

local sha = require('sha1')

local cjson = require('cjson')



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


local function myfunction(body)
	local tcp = socket.tcp()
	tcp:setoption('keepalive', true)
	tcp:settimeout(1, 'b') 
	local ret = tcp:connect("127.0.0.1", 80)
	if ret == nil then
          print('----------Error---------------')
		return false
	end

	local data = "POST /deleteCollectionNews HTTP/1.0\r\n" ..
                     "User-Agent: curl/7.33.0\r\n" ..
                     "Host: 127.0.0.1:80\r\n" ..
                     "Connection: close\r\n" ..
                     "Content-type: application/json\r\n" ..
                     "Content-Length:" .. #body .. "\r\n" ..
                     "Accept: */*\r\n\r\n" ..
                      body

     print(data)
     print("==========================")

	tcp:send(data)
	local result = tcp:receive("*a")
	print(result)
	tcp:close()
end

function Sleep(n)
   socket.select(nil, nil, n)
end


function readyes()
	----local str = '["userid","readBizid", "yes"]'
	local body = '{"appKey":"1313750614","userid":"eB6bYE8pkl","yes":1, "curPage":"1","maxRecords":"50"}'

	local tab = {}
	tab['appKey'] = '1313750614'
	tab['accountid'] = 'eB6bYE8pkl'
	tab['collectid'] = '3'

	local secret = '3DEB5C94E12F0EEAA69FAC7D78B43B0B34D09662'

	local ok_sign = gen_sign(tab, secret)
	tab["sign"]		= ok_sign

	--local ok,body = pcall(cjson.encode ,tab)
	--return body
    
    local body = ''
    for i,v in pairs(tab) do
        if body ~= '' then body = body .. "&" end
        body = body .. string.format("%s=%s",i,v)
    end
    return body

end


local function execfunction()
	myfunction(readyes())
end

execfunction()
