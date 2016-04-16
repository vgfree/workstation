--
-- client for tester
-- auth: zhangjl (jayzh1010@gmail.com)
-- company: mirrtalk.com
local common_path = '../../open/lib/?.lua;'
local cpath = '../../open/lib/?.so;'
package.path = common_path .. package.path
package.cpath = cpath .. package.cpath

require('socket')
local redis = require('redis')
local sha = require('sha1')
local json = require('cjson')

local luacutils = require('cutils')

local cfg = require('config_for_test')

local function gen_sign(T, secret)
    local kv_table = {}
    for k,v in pairs(T) do
        if type(v) ~= "table" then
            if k ~= "sign" then
				print(k)
                table.insert(kv_table, k)
            end
        end
    end
    table.insert(kv_table, "secret")
    table.sort(kv_table)
    local sign_string = kv_table[1] .. T[kv_table[1]]
    for i = 2, #kv_table do
        if kv_table[i] == 'secret' then
            sign_string = sign_string .. kv_table[i] .. secret
        else
            sign_string = sign_string .. kv_table[i] .. T[kv_table[i]]
        end
    end

    print(sign_string)
    local result = sha.sha1(sign_string)
    local sign_result = string.upper(result)

    return sign_result
end


local function send_data()
    status, res = pcall(json.decode, cfg.body)
    if status == nil then
        return
    end

    local status, redis_conn
    status, redis_conn = pcall(redis.connect, '192.168.1.11', 6379)

    --get secret--
    local secret = redis_conn:get(res['appKey'] .. ':secret')
    if not secret then
        return
    end

    res.sign = gen_sign(res, secret)

	for k, v in pairs(res) do
        if type(v) == 'table' then
            res[k] = json.encode(v)
        end
    end

    local http_body = ''

    for k, v in pairs(res) do
        http_body = http_body .. string.format('%s=%s&', k, v)
    end
	http_body = string.sub(http_body, 1 , -2)
    -- this is for binary file
    -- http_body = http_body .. string.format('--%s\r\nContent-Disposition:form-data;name="multimediaFile"; filename="test.wav"\r\nContent-Type: audio/wav\r\n\r\n%s\r\n', boundary, data)

    local tcp = socket.tcp()
    if tcp == nil then
        error('load tcp failed')
        return
    end

    local ret = tcp:connect(cfg.ip, cfg.port)
    if ret == nil then error('fail to connect to server')  return end

	local data = 'POST ' .. cfg.path ..  ' HTTP/1.0\r\n' ..
	'Host:127.0.0.1:80\r\n' ..
	'Content-Length:' .. tostring(#http_body) .. '\r\n' ..
	'Content-Type:application/x-www-form-urlencoded\r\n\r\n' ..
	http_body

    print(data)
    ret = tcp:send(data)
    print('tcp:send', ret)

    ret = tcp:receive('*a')
    print(ret)

    tcp:shutdown('both')
end

send_data()
