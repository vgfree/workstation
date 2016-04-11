--yuGWGIXwuh

package.path = '/data/nginx/open/lib/?.lua;' .. package.path
package.cpath = '/data/nginx/open/lib/?.so;' .. package.cpath

local cutils = require('cutils')
local cjson  = require('cjson')
local sha    = require('sha1')
local socket = require('socket')


---- 线下测试环境
local host_ip = '192.168.1.207'
-- local host_port = 8088

-- local host_ip = '127.0.0.1'

-- local host_ip = "api.daoke.io"
local host_port = 80


local appKey = '184269830'
local secret  = '931E498698AB2D9B1D93F419E572D2ACCA981488'

-- --android APP appKey -----------
-- local appKey = "286302235"
-- local secret = "CD5ED55440C21DAF3133C322FEDE2B63D1E85949"
-- --android APP appKey -----------


    -- -- this appkey is for weixin
    -- appKey = 2064302565
    -- secret = '3A6D1A40DA75F96722BB812576361FDF347E5404'


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

--[[=================================HTTP FUNCTION=======================================]]--
function url_decode(str)
    if not str then return nil end
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)",
        function(h) return string.char(tonumber(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
end



function url_encode(str)
    if not str then return nil end
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

function keys_binary_to_req(host_ip, host_port , url_path, args )
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

    body_data =  body_data .. body_suffix

    local req_data = string.format(head_format, url_path, host_ip, tostring(host_port), #body_data, body_data)
    return req_data
end

function parse_url2(s, split_char, split_eq )
    if not s then return nil end

    if not split_char then split_char = "&" end
    if not split_eq then split_eq = "=" end
    local gm_str = string.format("([^%s%s]+)%s([^%s%s]*)",split_eq,split_char,split_eq,split_eq,split_char)

    local t = {}
    for k, v in string.gmatch(s, gm_str) do
           --t[k] = url_decode(v)
           t[k] = v
    end
    return t
end

--------------------------------------
----  modify ---err data  02988
-- 842497910690247  sl4aDdlU7z
-- 815777756630362  spAdyGlAYr
-- 769225254377264  zpVNMlPb9l
-- 972977528203915  plkOmBldlW
-- 683196015727290  l7z9CBppC3
-- 784091527588249  KmDbIKoolF 
-- 428810792859452  4nNGKv8t8q
--------------------------------------

local function test_set_clientcustom()
    local  tab = {
        appKey = appKey,
        accountID = 'qkc1C2agiC',-- 'qkc1C2agiC,lVVnCmLuKm,OwQH5wZflD   -----ERROR lmKlsa6oNq
        actionType = "5",
        customType = "1",
        customParameter = '790004', ---- c111111
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

	local post_data = 'POST /clientcustom/v2/setCustomInfo HTTP/1.0\r\n' ..
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

local function test_get_clientcustom()
    local  tab = {
        appKey = appKey,
        accountID = 'XxQ1GWlFlr',-- 'qkc1C2agiC,TFUb0stlS4    ----ERRORlmKlsa6oNq
        -- actionType = "4",
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/getCustomInfo HTTP/1.0\r\n' ..
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

local function test_set_subscribemsg()
    local  tab = {
        appKey = appKey,
        accountID = 'qkc1C2agiC',-- 'qkc1C2agiC,TFUb0stlS4
        -- subParameter = "1:1|2:1|3:1|4:1|5:1",
        -- subParameter = "36:1",
        -- subParameter="1:1|2:1|3:0|4:1|5:1|6:1|32:0",
        subParameter="33:1|34:1|35:1|36:1|37:1|38:1|39:1|40:1|41:1",
        -- systemSubscribed = "1",
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/setSubscribeMsg HTTP/1.0\r\n' ..
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

local function test_get_subscribemsg()
    local  tab = {
        appKey = appKey,
        accountID = 'qkc1C2agiC',-- 'qkc1C2agiC,TFUb0stlS4
        -- systemSubscribed = 1,
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/getSubscribeMsg HTTP/1.0\r\n' ..
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

local function test_get_channel_userlist()
    local  tab = {
        appKey = appKey,
        accountID = 'yuGWGIXwuh',-- 'yuGWGIXwuh', qh5jDD2EXC
        channelID = "5080000",
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /weiboapi/v2/getChannelUserList HTTP/1.0\r\n' ..
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

local function bin_str_to_tab( str )
    local tab = {}
    local max = #str
    for i = 1 ,  max do
        tab[max - i + 1 ] =  string.sub(str,i,i)
    end
    return tab
end

local function  test_set_subscribe()
    local parameter = "1:1|12:0|8:0|4:0"
    local par_tab  = parse_url2( parameter , "|" , ":" )
    local new_tab = {}
    -- for k,v in pairs(par_tab) do
    --     new_tab[tonumber(k)] = tonumber(v)
    --     --print(string.format(" -->--- %s  %s",type(k),type(v)) )
    -- end

    -- for k,v in pairs(new_tab) do
    --     print(string.format(" -->--- %s  %s",k,v) )
    -- end

    local str_bin = "110101"
    local tmp_tab = bin_str_to_tab(str_bin)
    for k,v in pairs(tmp_tab) do
        print(string.format(" -->--- %s  %s",k,v) )
    end
end

local function test_xxx(  )
    local parameter="1:1|2:0|0"
    local tmp_tab = str_split(parameter,"|")
    local par_tab = {}
    for i,v in pairs(tmp_tab) do
        print(string.format("%s  %s", i, v ))
        local new_tmp_tab = str_split(v,":")
        if #new_tmp_tab == 2 then
            par_tab[new_tmp_tab[1]] = new_tmp_tab[2]
        end
    end

    for i,v in pairs(par_tab) do
        print(string.format("xxx %s  %s", i, v ))
    end
end

local function test_json(  )
    local tab = {}
    table.insert(tab,"abc1")
    table.insert(tab,"abc2")
    table.insert(tab,"abc3")
    table.insert(tab,"abc4")
    local ok,str = pcall(cjson.encode,tab)
    print(str)
end

local function test_set_user_tempChannel(  )
    local  tab = {
        appKey = appKey,
        accountID = 'OwQH5wZflD',-- 'yuGWGIXwuh', qh5jDD2EXC
        tempChannelID = "111111",
        customType = 1,
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/setUserTempChannel HTTP/1.0\r\n' ..
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

local function test_set_tempChannel_info(  )
    local  tab = {
        appKey = appKey,
        accountID = "111111111111111",
        tempChannelID = "12345",
        -- customType = "2",
        customAutoMode = 1,
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/setTempChannelInfo HTTP/1.0\r\n' ..
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

local function test_get_tempChannel_info()
    local  tab = {
        appKey = appKey,
        tempChannelID = "12345",
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/getTempChannelInfo HTTP/1.0\r\n' ..
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

local function test_inviteuser_join()
    local  tab = {
        appKey        = appKey,
        accountID     =  '2222222222',
        tempChannelID = "12349",
        multimediaURL =  "http://192.168.1.6/group3/M00/00/1E/wKgBBlO_gmyAYYrYAAAITe8iduk605.amr",
        callbackURL   = "http://192.168.11.159:80/inviteToTempChannelCallback?inviteAccountID=anjiklmkin&inviteTempChannelID=12349",
    }
    tab['sign'] = gen_sign(tab, secret)

    -- tab['callbackURL'] = url_encode(tab['callbackURL'])

    local req = keys_binary_to_req(host_ip,host_port,"clientcustom/v2/inviteUserJoin", tab )
    print(req)
    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok then
        print('http post failed!')
        return
    end
    print(ret)
end

local function test_get_channel_info_detail(  )
    ----
    local  tab = {
        appKey = appKey,
        accountID = 'TFUb0stlS4',-- 'yuGWGIXwuh', qh5jDD2EXC
        groupID = "12345",
        groupType = 3,
	   opType = 2,
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /statapi/v2/fetchChannelInfoDetail HTTP/1.0\r\n' ..
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

local function test_get_blacklist()
    local  tab = {
        appKey = appKey,
        accountID = 'TFUb0stlS4',-- 'yuGWGIXwuh', qh5jDD2EXC
        groupID = "12311x",
        groupType = 3,
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/getGroupBlacklist HTTP/1.0\r\n' ..
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

-- local function test_app_connect_send_weibo(  )
--     ----appConnectSendWeibo
--     local tab = {
--         appKey = appKey,
--         multimediaURL = "http://192.168.1.6/group3/M00/00/1E/wKgBBlO_gmyAYYrYAAAITe8iduk605.amr",
--         accountID = "13807040235",
--         parameterType = "2",
--         level = 20,
--         interval = 6000,
--         callbackURL = "http://127.0.0.1/callbackURL",
--     }
--      tab['sign'] = gen_sign(tab, secret)
--     local req = keys_binary_to_req(host_ip, host_port , 'clientcustom/v2/appConnectSendWeibo', tab )
--     print(req)
--      local ok,ret = cutils.http(host_ip, host_port, req, #req)
-- end

local function test_set_blacklist()
    local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        groupID = "12345aa",
        groupType = "xxa",
        opType = 1 ,
    }
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/setGroupBlacklist HTTP/1.0\r\n' ..
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


local function apply_micro_channel_2( )
     local  tab = {
        appKey = appKey,
        accountID = 'qh5jDD2EXC',-- 'yuGWGIXwuh', qh5jDD2EXC
        channelNumber = "ZFM000012x",
        channelName = "上海语镜新功能上线通知",
        channelIntroduction = "新功能上线通知",
        channelCityCode = '310000',
        channelCatalogID = '100101',
        channelCatalogUrl = "http://www.baidu.com/img/bdlogo.png",
        chiefAnnouncerIntr = "FFFF小喇叭开始广播了",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/applyMicroChannel HTTP/1.0\r\n' ..
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


local function apply_fetch_channel_check_2()
     local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        infoType = "0",
        channelStatus = "0",
    }

---- InfoType 
----    0) 公司审核 
    ----channelStatus
    ----0 ) 未审核
    ----1 ) 驳回
    ----2 ) 已经审核
    ----10) 所有

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/fetchMicroChannel HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    -- host_ip = "192.168.1.190"
    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )

    print(req)
    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok then
        print('http post failed!')
        return
    end
    print(ret)
end


local function apply_fetch_channel_detail_info()
     local  tab = {
        appKey = appKey,
        accountID = 'mmlcAlmKXl',
        channelNumber = "ZZ1111",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/getMicroChannelInfo HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    -- host_ip = "192.168.1.190"
    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )

    print(req)
    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok then
        print('http post failed!')
        return
    end
    print(ret)
end


local function apply_check_channel_2()
     local  tab = {
        appKey = appKey,
        checkAccountID = 'TylQBYfCfI',-- 'yuGWGIXwuh', qh5jDD2EXC
        applyIdx = "11",
        checkStatus = "2",      ------- 1驳回  2审核成功
        checkRemark = "审核通过",
        accountID = 'kxl1QuHKCD',
        channelNumber = 'ZFM000012',
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/checkApplyMicroChannel HTTP/1.0\r\n' ..
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


local function apply_midify_micri_channel_2()
     local  tab = {
        appKey = appKey,
        checkAccountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        applyIdx = "18",
        checkStatus = "1",      ------- 1驳回  2审核成功
        checkRemark = "审核通过,江",
        accountID = 'TylQBYfCfI',
        channelNumber = 'ZFM0000',
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/checkApplyMicroChannel HTTP/1.0\r\n' ..
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


local function user_fetch_can_follow_micro_channel_list()
      local  tab = {
        appKey = appKey,
        accountID = 'mmlcAlmKXl', --mmlcAlmKXl',-- 'yuGWGIXwuh', qh5jDD2EXC
        infoType = "2",
        -- cityCode = '11000'
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/fetchMicroChannel HTTP/1.0\r\n' ..
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

---- ZFM000011|0b0fb4ce749e11e48b5c902b34af3648
local function user_follow_micro_channel_info(  )
    local  tab = {
        appKey = appKey,
        accountID = 'mmlcAlmKXl', --mmlcAlmKXl',-- 'yuGWGIXwuh', qh5jDD2EXC
        followType = "1",
        uniqueCode = "ZZ1111|ae0a3196796111e4a3fc74d4350c77be",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

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

local function user_unfollow_micro_channel_info(  )
    local  tab = {
        appKey = appKey,
        accountID = 'mmlcAlmKXl', --mmlcAlmKXl',-- 'yuGWGIXwuh', qh5jDD2EXC
        followType = "2",
        channelNumber = "ZFM000011"
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

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


local function apply_secret_channel()
    local  tab = {
        appKey = appKey,
        accountID = 'tmj0lu4uki', --mmlcAlmKXl',-- 'yuGWGIXwuh', qh5jDD2EXC, SE2KCnkvoS
        channelNumber = "SecFM0xxx",
        channelName = "测试密频道2",
        channelIntroduction = "个人微博2332",
        channelCityCode = "320000",
        channelCatalogID = "100108",
        channelCatalogUrl = "http://www.baidu.com/img/bd_logo1.png",
        openType = "1",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/applySecretChannel HTTP/1.0\r\n' ..
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

local function fetch_secret_channel()
    local  tab = {
        appKey = appKey,
        accountID = 'tmj0lu4uki', --mmlcAlmKXl',-- 'yuGWGIXwuh', qh5jDD2EXC, SE2KCnkvoS
        channelName = "测试密频道2",
        channelCityCode = "320000",
        channelCatalogID = "100108",
        infoType = "1"
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/fetchSecretChannel HTTP/1.0\r\n' ..
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

local function get_secret_channel_detail_info(  )
    local  tab = {
        appKey = appKey,
        accountID = 'tmj0lu4uki', --mmlcAlmKXl',-- 'yuGWGIXwuh', qh5jDD2EXC, SE2KCnkvoS
        channelNumber = "SecFM000012"
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/getSecretChannelInfo HTTP/1.0\r\n' ..
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


local function join_secret_channel(  )
     local  tab = {
        appKey = appKey,
        accountID = 'tmj0lu4uki', --mmlcAlmKXl',-- 'yuGWGIXwuh', qh5jDD2EXC, SE2KCnkvoS
        uniqueCode = ""
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/joinSecretChannel HTTP/1.0\r\n' ..
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


local function test_batch_get_userkeyinfo()
     local  tab = {
        appKey = appKey,
        accountIDs = "0s0sJ1sTlx,0uqavQT9zm,0fiQyGJ2oq,0ljqQM8Yk5,0nzlp7G178,0oiclkriRj,nmjOckC3tS,sgYXpRvlsf,EYxOqldzM5,eB6bYE8pkl",
        count = 5,
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/batchFetchUserKeyInfo HTTP/1.0\r\n' ..
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


local function test_batch_set_userkeyinfo()
     local  tab = {
        appKey = appKey,
        -- accountIDs = "0s0sJ1sTlx,0uqavQT9zm,0fiQyGJ2oq,0ljqQM8Yk5,0nzlp7G178,0oiclkriRj,nmjOckC3tS,sgYXpRvlsf,EYxOqldzM5,eB6bYE8pkl",
        -- accountIDs = "0lllloyulM,0vQurxHpDl,0vmotimmfl,0evvlm3HkQ,0hl21V5ulf,0lIsshlqlK,0r3hUQYiRp,0fiQyGJ2o,0fwyTunyP,0jimyZqol,0k8lAZawm,0k8lAZawm",
        accountIDs = "0fiQyGJ2o,0fwyTunyP,0jimyZqol,0k8lAZawm",
        count = 4,
        customType = "2",
        channelInfo = "shanghai1239",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/batchSetUserKeyInfo HTTP/1.0\r\n' ..
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


-- test_set_subscribe()

test_set_clientcustom()

-- test_get_clientcustom()

-- test_set_subscribemsg()

-- test_get_subscribemsg()

-- test_set_user_tempChannel()

-- test_set_user_tempChannel()

-- test_set_tempChannel_info()

-- test_get_tempChannel_info()

-- test_inviteuser_join()

-- test_get_channel_info_detail()

-- test_app_connect_send_weibo()

-- test_get_blacklist()

-- test_set_blacklist()

-- apply_micro_channel_2()

-- apply_fetch_channel_check_2()

-- apply_check_channel_2()

-- apply_fetch_channel_detail_info()

-- user_fetch_can_follow_micro_channel_list()

-- user_follow_micro_channel_info()

-- user_unfollow_micro_channel_info()

---- 申请密频道
-- apply_secret_channel()

---- 获取密频道列表
-- fetch_secret_channel()

---- 获取密频道详情
-- get_secret_channel_detail_info()

---- 加入密频道
-- join_secret_channel()


-- test_batch_get_userkeyinfo()

-- test_batch_set_userkeyinfo()

