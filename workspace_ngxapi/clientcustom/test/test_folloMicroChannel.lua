package.path = '/data/nginx/open/lib/?.lua;' .. package.path
package.cpath = '/data/nginx/open/lib/?.so;' .. package.cpath
-- package.cpath = '/data/nginx/open/public/?.lua;' .. package.cpath

local cutils = require('cutils')
local cjson  = require('cjson')
local sha    = require('sha1')
local socket = require('socket')
local utils = require('utils')


---- 线下测试环境
-- local host_ip = '192.168.1.207'

local host_ip = '127.0.0.1'
local host_port = 80

local appKey = '4223273916'
local secret  = 'DA00D00CBFECD61E4EA4FA830FCEEA4C96C5683D'

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
    --print(string.format("%s, %s",sign_string,#sign_string))
    local result = sha.sha1(sign_string)
    local sign_result = string.upper(result)
    return sign_result
end

local function test_follow_microchannel()      --//关注微频道
    local  tab = {
        appKey = appKey,
        accountID =  'nmjOckC3tS',--'00AWBnDm8h',-- 'zdfeqE74Vi',--'eB6bYE8pkl',--'mUhBunWEya',--'kxl1QuHKCD',--
        uniqueCode = "wemeVOICE|c1e4ba287aca11e48fba00a0d1eb3b3c",
        followType = 1,
    }
    ---- IsKpVCvWzl
    ---- 0soaLuAqZT
    ---- 137318519999041 7lYxD4lnTY
    ---- 723314307699166 U7q4uf47sy
    ---- 406662680496434 xxxx
    ---- 897648238244539 sgYXpRvlsf
    ---- 139311121233931 gfvSiaqTUR
    ---- 815467491699589 TylQBYfCfI
    ---- 789904283093805 nmjOckC3tS
    
    
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)
    host_ip = 'api.daoke.io'
    local post_data = 'POST /clientcustom/v2/followMicroChannel HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    print(req)
    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok then
        print('http post failed!')
        return
    end
    print(ret)
 end
 local function test_split()
    local  a = "abc,efg,dde,"
    local tab = {}
    tab = utils.str_split(a,",")
    print (tab)
 end

test_follow_microchannel()
--print('abcdefg')
--test_split()