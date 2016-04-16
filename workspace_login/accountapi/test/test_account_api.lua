local cutils = require('cutils')
local cjson  = require('cjson')
local sha    = require('sha1')
local socket = require('socket')

---- 线上测试环境
-- local host_ip = '221.228.229.249'
-- local host_port = 80


---- 线下测试环境
local host_ip = '192.168.1.207'
-- local host_ip = '192.168.1.181'

local host_ip = '127.0.0.1'  ----localhost
-- local host_ip = "api.daoke.io"
local host_port = 80

-- local split_str = '-----------abc_transit_send_msg_to_dfsapi_saveSound____'
-- local data_head = 'POST /saveSound?%s HTTP/1.0\r\nHost:%s:%d\r\nContent-Length:%d\r\n\r\n%s'


local appKey = '4223273916'
local secret  = 'DA00D00CBFECD61E4EA4FA830FCEEA4C96C5683D'


local post_format =  "POST /api/v3.0/score HTTP/1.0\r\n" ..
                    "Host:%s:%s\r\n" ..
                    "Content-Length:%d\r\n" ..
                    "Connection:keep-alive\r\n" ..
                    "Content-Type:text/plain\r\n\r\n%s" 


---- table to key-value
function table_to_kv(tab)
    if not tab then return '' end
    local str = '' 
    for i,v in pairs(tab) do
        if str ~= '' then str = str .. "&" end
        str = str .. string.format("%s=%s",i,v)
    end
    return str
end


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
    print(string.format("%s, %s",sign_string,#sign_string))
    local result = sha.sha1(sign_string)
    local sign_result = string.upper(result)
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
        body_data = body_data .. string.format('%s\r\nContent-Disposition: form-data; name="mmfilename"; filename="%s"\r\n' ..
                    'Content-Type: application/octet-stream\r\n\r\n%s\r\n',
                                    body_boundary, file_name , file_binary)
    end
    body_data =  body_data .. body_suffix
    local req_data = string.format(head_format, url_path, host_ip, tostring(host_port), #body_data, body_data)
    return req_data
end

-->> split string into table
function str_split(s, c)
    if not s then return nil end

    local m = string.format("([^%s]+)", c)
    local t = {}
    local k = 1
    for v in string.gmatch(s, m) do
        t[k] = v
        k = k + 1
    end
    return t
end


function url_encode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w])",
        function (c)
            return string.format ("%%%02x", string.byte(c))
        end
        )
        str = string.gsub (str, " ", "+")
    end
    return str
end



local function test_test_account_info()

    local  tab = {
        appKey = '286302235', --appKey,
        accountID = 'qkc1C2agiC',
        nickname = "避免传递参数过多",
    }
    tab['sign'] = gen_sign(tab, 'CD5ED55440C21DAF3133C322FEDE2B63D1E85949') --secret)
     tab['text'] = url_encode(tab['text'])
    local body = table_to_kv(tab)

    -- print(body)

    local post_data = 'POST /accountapi/v2/fixUserInfo HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    print(req)

    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok or ret == nil then
        print("===post data failed!===")
        return
    end
    print("===socket succed===")
    print(ret)
end


local function test_check_login()

    local  tab = {
        appKey = '286302235', --appKey,
        username ="13281935468",
        password = "123123"
    }
    tab['sign'] = gen_sign(tab, 'CD5ED55440C21DAF3133C322FEDE2B63D1E85949') --secret)
    local body = table_to_kv(tab)

    -- print(body)


    -- host_ip = "api.daoke.io"

    local post_data = 'POST /accountapi/v2/checkLogin HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    print(req)

    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok or ret == nil then
        print("===post data failed!===")
        return
    end
    print("===socket succed===")
    print(ret)
end

-- test_test_account_info()

-- test_check_login()
