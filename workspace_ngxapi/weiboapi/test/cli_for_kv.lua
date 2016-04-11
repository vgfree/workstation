--
-- client for tester
-- auth: zhangjl (jayzh1010@gmail.com)
-- company: mirrtalk.com
local common_path = '../../open/lib/?.lua;;'
local cpath = '../../open/lib/?.so;'
package.path = common_path .. package.path
package.cpath = cpath .. package.cpath

require('socket')
local redis = require('redis')
local sha = require('sha1')
local json = require('cjson')

local luacutils = require('cutils')

local cfg = require('config_for_test')

local function send_data()
    status, res = pcall(json.decode, cfg.body)
    if status == nil then
        return
    end
    local key_table = {}
    for key, v in pairs(res) do
        if type(v) ~= 'table' then
            table.insert(key_table, key)
        end
    end
    table.insert(key_table, "secret")
    table.sort(key_table)

    local status, redis_conn
    status, redis_conn = pcall(redis.connect, '192.168.1.3', 6379)

    --get secret--
    local secret = redis_conn:get(res['appKey'] .. ':secret')
    if not secret then
        return
    end


    local sign_str = key_table[1] .. res[key_table[1]]
    for i=2,table.getn(key_table) do
        if key_table[i] == "secret" then
            sign_str = sign_str .. key_table[i] .. secret
            -- elseif key_table[i] == 'content' then
            --         sign_str = sign_str .. key_table[i] .. luacutils.urldecode(res[key_table[i]])

        elseif res[key_table[i]] ~= nil and type(res[key_table[i]]) ~= 'table' then
            sign_str = sign_str .. key_table[i] .. res[key_table[i]]
        end
    end

    local gen_sign = sha.sha1(sign_str)
    print(sign_str)
    print(gen_sign)


    local http_body = 'sign=' .. string.upper(gen_sign)
    for k,v in pairs(res) do
        if type(v) ~= 'table' then
            if k=='' or k=='' then
                v=luacutils.url_encode(v)
            end
            http_body = http_body .. "&" .. k .."=" .. v
        else
            -- to handle the json array
            -- local tmp = string.sub(json.encode(v), 1, -1)
            -- http_body = http_body .. "\"" .. k .."\":" .. json.encode(v) .. ","
        end
    end


    local tcp = socket.tcp()

    if tcp == nil then
        error('load tcp failed')
        return
    end

    local ret = tcp:connect(cfg.ip, cfg.port)
    if ret == nil then error('fail to connect to server')  return end

    local data = 'POST ' .. cfg.path ..  ' HTTP/1.0\r\n' ..
    'Host:192.168.1.3:8088\r\n' ..
    'Content-Length:' .. tostring(#http_body) .. '\r\n' ..
    'Content-Type:application/json\r\n\r\n' ..
    http_body

    print(data)
    ret = tcp:send(data)
    -- print('tcp:send', ret)

    ret = tcp:receive('*a')
    print(ret)

    tcp:shutdown('both')
end

send_data()
