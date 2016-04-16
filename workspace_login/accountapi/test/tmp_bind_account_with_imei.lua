package.path = '/data/nginx/open/lib/?.lua;' .. package.path
package.cpath = '/data/nginx/open/lib/?.so;' .. package.cpath
-- package.cpath = '/data/nginx/open/public/?.lua;' .. package.cpath

local cutils = require('cutils')
local cjson  = require('cjson')
local sha    = require('sha1')
local socket = require('socket')
-- local utils  = require('utils')
-- local config = require('config_for_test')
-- local value_t = require('value_table')

local value={
    -- {mobile='18667230092', imei= '694482390735299'},
    -- {mobile='18669239091', imei= '690192368905220'},


}


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

    local result = sha.sha1(sign_string)
    local sign_result = string.upper(result)
    return sign_result
end

local function test_bind_mobile(tab, path)

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)
    host_ip = 'api.daoke.io'
    -- host_ip = '192.168.1.207'
    host_port = 80
    local post_data = 'POST '..path..' HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    -- print(req)
    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok or not ret then
        -- print('http post failed!')
        print("=======1111======== "..tab['IMEI'].." =======failed======"..path)
        return
    end
    -- print(ret)
    local body = string.match(ret,'{.*}')

    local ok, res = pcall(cjson.decode, body)
    if (not ok or type(res) ~= "table") and path == '/accountapi/v2/getMirrtalkInfoByImei' then
        print("====2222======= "..tab['IMEI'].." =======failed======")
        return 
    end

    if not ok then
        return ok, res
    end

    if not tab['newmobile'] then
        return res['RESULT']['accountID']
    else
        return ok, res
    end

end

local function get_accountid_by_imei( )
    local path1 = '/accountapi/v2/getMirrtalkInfoByImei'
    local path2 = '/accountapi/v2/userBindMobile'

    for _,table in pairs(value) do
        local  tab = {
            appKey = appKey,
            IMEI =  table['imei'],
        }
        -- print(appKey..'==000=='..table['mobile'])
        local accountID = test_bind_mobile(tab, path1 )
        print(accountID.."========="..table['mobile'].."====>>>>"..table['imei'])
        local  tab_ret = {
            appKey = appKey,
            accountID =  accountID,
            newmobile =  table['mobile'],
        }
        -- print(accountID..'===='..table['mobile'])
        local ok, ret = test_bind_mobile(tab_ret, path2 )
        if ok and ret then
            -- print("=======ok======")
        else
            print("=========="..table['mobile'].."=====falied=====")
        end
    end
end
get_accountid_by_imei( )