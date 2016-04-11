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

local host_ip = '127.0.0.1'

local host_port = 8088

--local host_ip = "api.daoke.io"
local host_port = 80


local appKey = '4223273916'
local secret  = 'DA00D00CBFECD61E4EA4FA830FCEEA4C96C5683D'

-- --android APP appKey -----------
local appKey = "286302235"
local secret = "CD5ED55440C21DAF3133C322FEDE2B63D1E85949"
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
        accountID = '',-- 'qkc1C2agiC,lVVnCmLuKm,OwQH5wZflD   -----ERROR lmKlsa6oNq
        -- 4:2
        actionType = "5",
        customType = "1",
        customParameter = '02988',
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
        accountID = 'plkOmBldlW',-- 'qkc1C2agiC,TFUb0stlS4    ----ERRORlmKlsa6oNq
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

    
    -- host_ip = "127.0.0.1"

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

local function test_apply_channel(  )
    local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        channelNumber = 'FMDK0001',
        channelName = "开发测试测试申请频道xxxxfff",
        channelIntroduction = "专业分享交通电子眼的频道",
        chiefAnnouncerIntr = "小喇叭专业广播,小心被啦来关起",
        channelCityCode = "310000",
        channelCatalog = '1000',
        channelType = "1",
        openType = '0',
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/userApplyChannel HTTP/1.0\r\n' ..
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

local function test_fetch_channel(  )
    local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        infoType = "2",
        channelStatus = "2"
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/fetchUserChannel HTTP/1.0\r\n' ..
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

local function test_check_userchannel ()

    local  tab = {
        appKey = appKey,
        checkAccountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        checkStatus = "1"   ,     -- 1 审核通过 / 驳回申请
        checkRemark = "人工审核通过", 
        applyUniqueCode = '3822d7e663cf11e4a8e1000c29ae7997'--//"43e830da5f4711e4a22b902b34af3648" ,  ----申请唯一码
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/checkApplyChannel HTTP/1.0\r\n' ..
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

-- 1) 查询结果
-- 2) 删除旧的
-- 3) 生成新的

local function test_get_channel_uniquecode()
    local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        channelNumber = 'FMDK0001',
        customType = "1",
        pageCount = "2",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/inviteLinksUserChannel HTTP/1.0\r\n' ..
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


local function test_del_channel_uniquecode()
    local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        channelNumber = 'FMDK0001',
        inviteUniqueCode = '540931e85e9411e4bc5c902b34af3648',
        customType = "2"
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/inviteLinksUserChannel HTTP/1.0\r\n' ..
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

local function test_create_channel_uniquecode()
    local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',-- 'yuGWGIXwuh', qh5jDD2EXC
        channelNumber = 'FMDK0001',
        customType = "3"
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/inviteLinksUserChannel HTTP/1.0\r\n' ..
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

local function test_follow_userchannel()
    local  tab = {
        appKey = appKey,
        accountID = 'RZ9tnakMTl',-- 'yuGWGIXwuh', qh5jDD2EXC
        uniqueCode = "b2a9b5205f4711e4a22b902b34af3648",
        followType = "1",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/followUserChannel HTTP/1.0\r\n' ..
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

local function test_unfollow_userchannel()
    local  tab = {
        appKey = appKey,
        accountID = 'RZ9tnakMTl',-- 'yuGWGIXwuh', qh5jDD2EXC
        channelNumber = 'FMDK0001',
        followType = "2",
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/followUserChannel HTTP/1.0\r\n' ..
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

local function  test_fetch_followlist_userchannel()
    local  tab = {
        appKey = appKey,
        channelNumber = 'FMDK0001',
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/fetchFollowListUserChannel HTTP/1.0\r\n' ..
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
--#------------------------------------------------------------------------------------------------------------------------------------------
--#------------------------------------------------------------------------------------------------------------------------------------------
--#------------------------------------------------------------------------------------------------------------------------------------------
--#------------------------------------------------------------------------------------------------------------------------------------------
--#------------------------------------------------------------------------------------------------------------------------------------------
local function test_getUserFollowListMicroChannel()     --//user
    local  tab = {
        appKey = appKey,
        accountID =  'E6ppmuzudN',--'RZ9tnakMTl',--//'kxl1QuHKCD',--//'mUhBunWEya',-- 
        --channelNumber = 'FMDK0001',
        --startPage = "1",
        --pageCount = "2",
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getUserFollowListMicroChannel HTTP/1.0\r\n' ..
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

local function test_getBossFollowListMicroChannel()      --//boss
    local  tab = {
        appKey = appKey,
        accountID =  'eB6bYE8pkl' ,--//'kxl1QuHKCD',--//
        channelNumber = 'FMDJ123456',
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getBossFollowListMicroChannel HTTP/1.0\r\n' ..
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

local function test_apply_microChannel()    --//申请微频道
    local tab = {
        appKey = appKey,
        accountID = 'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        channelNumber = 'FMDJ123456',                             --//频道编号
        channelName = "开发测试测试申请频道xxxxfff",              --//频道名称
        channelIntroduction = "专业分享交通电子眼的频道",          --//频道简介
        chiefAnnouncerIntr = "小喇叭专业广播,小心被啦来关起",     --//主播简介
        channelCityCode = "110000",  --//频道区域编码
        channelCatalogID = 100104,   --//频道类别编号
        channelCatalogUrl = 'http://www.baidu.com', --//
        startPage = 1,
        pageCount = 20,
    }
    
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"clientcustom/v2/applyMicroChannel",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
 end   

local function test_check_microChannel()    --//审核微频道
    local tab = {
        appKey = appKey,
        checkAccountID = 'eB6bYE8pkl' ,--//'kxl1QuHKCD',--//,'E6ppmuzudN',--//,
        channelNumber = 'FMDJ123456',--'FM090909',                             --//频道编号
        applyIdx = 13, -------------//当前channelnumber的在申请表中的id
        checkRemark = 'abcdefg',
        checkStatus = 2,
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

local function test_fetch_microChannel()    --//微频道list
    local tab = {
        appKey = appKey,
        accountID = 'eB6bYE8pkl' ,--//'E6ppmuzudN', --//'kxl1QuHKCD',--//, 
        channelnumber =  'FMDJ123456',--// 'FMDK0011',--//'FM0909091',--//                         --//频道编号
        channelStatus = 0,
        infoType = 2,
        --citycode = 310000 ,
        --likeName =  "测试",
        --catalogid = 100102,
        startPage=1,
        pageCount=20,
        --accountID=E6ppmuzudN&infoType=2&channelStatus=0&likecatalogName=200110&startPage=1&pageCount=20
    }
    
    tab['sign'] = gen_sign(tab, secret)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/fetchMicroChannel",tab)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/fetchMicroChannel HTTP/1.0\r\n' ..
                      'Host:%s:%s\r\n' ..
                      'Content-Length:%d\r\n' ..
                      'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
 end 

local function test_resetInviteUniqueCode()    
    local  tab = {
        appKey = appKey,
        accountID = 'eB6bYE8pkl',-- 'E6ppmuzudN', --// 'kxl1QuHKCD',-- 'RZ9tnakMTl',--
        channelNumber = 'FMDJ123456',
        channelType = '1',
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/resetInviteUniqueCode HTTP/1.0\r\n' ..
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

local function test_follow_microchannel()      --//关注微频道
    local  tab = {
        appKey = appKey,
        accountID = 'E6ppmuzudN',-- 'eB6bYE8pkl',--'mUhBunWEya',-- 'zdfeqE74Vi',--'kxl1QuHKCD',--'RZ9tnakMTl',--
        uniqueCode = "FMDJ123456|2ef4c77c707911e4945674d4350c77be",
        followType = 1,
        --channelNumber = 'FMDK0011',
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

local function test_unfollow_microchannel()      --//取消关注微频道
    local  tab = {
        appKey = appKey,
        accountID =  'E6ppmuzudN',--'RZ9tnakMTl',--'eB6bYE8pkl',--'mUhBunWEya',--
        followType = 2,
        channelNumber = 'FMDJ123456',
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

local function test_getMicroChannelInfo()
    local  tab = {
        appKey = appKey,
        channelNumber = 'FMDJ123456',--//'FMDK0011',--//
        accountID = "E6ppmuzudN",--//'RZ9tnakMTl',-- 'kxl1QuHKCD',----
        --channelType = 1,
    }

    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/getMicroChannelInfo HTTP/1.0\r\n' ..
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

local function test_recheck_microChannel()      --//重审微频道
    local  tab = {
        appKey = appKey,
        accountID = 'xGhm7TokxN', --'xGhm7TokxN',--'RZ9tnakMTl',--//'kxl1QuHKCD',--//
        channelNumber = 'KACHE',
        infoType = "2",
        checkAccountID = "kxl1QuHKCD",
        checkStatus = "3",
        applyIdx = "4",
    }
    
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/recheckMicroChannel HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

    ---- 2015-05-11 reopen channel 
    -- host_ip = "api.daoke.io"

    local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    print(req)
    local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok then
        print('http post failed!')
        return
    end
    print(ret)
end 

local function test_modify_microChannel()       --//修改微频道信息
    local  tab = {
        appKey = appKey,
        accountID = 'kxl1QuHKCD',--'RZ9tnakMTl',--//'kxl1QuHKCD',--//
        beforeChannelNumber = 'FM456789',
        channelName = '道客研发中心',
        introduction = '',
        cityCode = '',
        catalogID = '',
        chiefAnnouncerIntr = 'abcdefg',
        logoURL = 'www.baidu.com',
        infoType = "2",
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/modifyMicroChannel HTTP/1.0\r\n' ..
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

local function test_get_cataloginfo()       --//获取微频道/密频道类别列表
    local  tab = {
        appKey = appKey,
        startPage = 1,
        pageCount = 10,
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getCatalogInfo HTTP/1.0\r\n' ..
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

local function test_getcityinfo()       --//获取城市列表
    local  tab = {
        appKey = appKey,
        channelNumber = 'FMDK0001',
        name = 'abcdefg',
        introduction = 'Content-Type:application/x-www-form-urlencoded',
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getCityInfo HTTP/1.0\r\n' ..
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


local function test_split_str(  )
    local val = "abc123123"
    local tab = str_split(val,",")
    print(tab)

    for k, v in pairs(tab) do
        print(k,v )
    end
end



local function test_batch_unfollow_microchannel()      --//取消关注微频道

    local accountID_list_str = "X0zpzFzkfM,0uoWXaumeU,Co19qBIvGE,AwfiWPlASi,DiiQasOw00,0OQuPsM4ls,hlYkp4AkcG,4OEMlsollD,x7ml4QlhKl,0Yg7wRAkll,istltk1lNz,2glDMwhjAo,nbJOuPwYYl,CtildYFV61,t0lMvApBll,knmvil8ljk,9j8SsdTzml,LsvJduGzfQ,9lliSmogas,tyMS4ER0wl,CQloskg3v1,llYiv2qlZE,ux80vjTkQl,uHKqlLZMAl,uia0lQt7Pk,X8qmlKFuJl,Ehlio8l6O1,lgknKOpNiX,moJRZZqlsj,nyzFl9mW9N,sllliw805J,K3Bolhhz32,NrTdQYJzlV,iomlAwq45k,YDq6NT7wmy,nvloiwUTll,H6YsMpaYWE,hKnloRqKMv,tdlikGjlm7,QIsdmlcJmS,w3Pul9Rum8,pa0wlkmHgu,alNixZ3Lhf,l0lzlLESqv,F1KNql3yP7,4cDjnGmlxk,hbklZkjQQd,ksoQmr413X,lzsTjMyqqJ,8flblwRyNW,VlR3p0lT7l,JNrmUzAKCh,iuqvclI0JM,NuxAko36ul,e6E0qcww0I,N3kmsAKoql,zkmzBaZomA,0NUPJ3lk0l,X5l7sflLUn,lfm6q4mkZ7,lyqo4xL2SK,Glkzi6lTyi,b01yJ7wSMl,iwHymymMkS,i2UmAQlpbE,sllayRSu8n,kwjSqGf62g,zLYrBDY6I3,usFnMyzDdu,TAqs2SlPli,F3oqnSjifb,VbpqObmlau,rLMlOLfiHy,MollMlymAf,lSlHCkl1LW,zGF5Smq774,DUKAl6pl7o,mpmkElAlll,zVMAi3ldll,Rotfla2iuN,lw332WlJMk,tAkK9PSzpy,Ykl3vlRmlu,9zN7lTlTBT,l5ZylXwyrx,XkxpoloyNq,5Gmq02iaDJ,frvoyaDpcl,xom9wDiCmi,AssTomoVGL,kHzsyadlLE,bfu0ltiGQw,1SzlClXnN0,kMvrFle8Os,JpwqdmRGyM,rPGsRlEmuQ,KqmhhuyZmu,0fm1WvPioi,Iswzmlzxvy,0aK1opyGyO,16ch7twexo,ES0EhxhilS,N0MMNllCkG,iXkLAVSwmA,jMGo8DmtWl,vTkTP1QVCG,2epX64llT2,VUzl7M9ATt,rmz7Ok0Zey,6z9TlbJLSk,HA0OmVMlPf,7VU5lqLlRG,ejslMZmQIN,kmzAy3n0Gb,cumASkrYaf,llmLoaN5pk,CrpciWTg0M,lWXl4Wqfbo,lEnZXmD9mm,YlmsPq3nxQ,B6cyvmv1lz,llsum17qbG,nmmMw0FwDq,kWUzM1plQs,ydWwdylDml,izlalrilqq,Dllu7lrlXS,lQXEyiXJqY,2gKQsWiTiz,w6lyMZau55,wNDSkDETmp,kA47Bw4qJ4,6lG7ligaHl,7Yxp1Mkvh8,vobyouWlgN,FQmuyawPkw,QYx71ASYyT,mikUmEkK61,lIdkyd8VRW,7EgsmvirkG,nylBGnHHdc,X7lBlLojEl,mQWTuseoMl,oBp0OkElQQ,amHklylgQm,G7lxB5SlNk,piwQvsQlly,FT8lcmRVQc,alzqWHgoRl,EnlJpsnpG6,lSumqSEWhL,tlz8mMJlgi,lsNBlykZmi,szw3fT7zQl,luaOHxltyA,96qYmLu7Kd,GQxJXZkW3C,gaBjecQTth,oz0Sl0NpKl,lIsSuzYykr,glyzDRQtlR,wzEWMo1UwC,RsykmzGuDn,qczCl6wKsx,N1nlRZ8qVD,NuAnUkXaNT,bcqlNasOrl,tSlqsaUyqw,5ymy1xpSFb,fl3a8VGkuz,LibY7GM1qD,lLkkzMllKU,TBzNTuhS8i,hyrT6mXvEl,fZ4u9lRRlo,uJv0kGiJag,04lr04K0oZ,RHmMg1vri2,ew6qMY7TZD,lLTll9alqM,JjKTQ64lt5,9Pl7m0UoRq,spba8w9PTl,B4XImlwBbd,lloq3qDRgQ,nlfGfbvF1w,l1waqi3pus,gyl3lflJwN,thGAmcIGFl,llAdq8ihWl,My0VwnFJlz,5yfaqqSRi4,AllaSmFOLl,qwucmMwRa1,4tu1DRvyVs,YTXlq8NTHN,l9oqlNJvso,u8Pk4Olv1X,pcVmyqx0FM,3qEXr0W1NY,mPmNsDK1Sa,3AlByawlTl,pOcuIjwK6m,uqrplFvsTy,vEkluI0Fqo,Dmllcajld4,ndlTIh8lml,7K3YqmEulW,zsuTUYm9em,o4ylS2lmam,HKnlkMl7ld,lMAkLvlOmp,Cy1DqQwNKY,YYZlwyZJxl,QmDSJqpQlo,wMm8lxeGqA,yGlaJ18vm9,4SnpKlcTAl,pli4zKWbmi,AzkfM4lLql,6nNLmmGwyl,dA6XBdqg7W,Cy1lSlr4az,MlLrLmAl1l,luMDN4t5vl,4kafqpwycl,qEAwfyzlTy,G4liiRWyoG,PBl4lqZqAA,pOcJlzlHsZ,loXkKiszdR,mlWrn6Ty1J,8tWlGNkAws,dYvclmxmJl,uO8luz0EGB,7lTlMlAwvn,v0lqo1Vuav,QlHpNsKKxl,8CAloiUMYk,vGccaplmiy,Foz3MAiD3b,K0OrajpYGJ,4NsOlspm37,4lloz07Tlq,tkkwWtZS2B,n0plKaQlEd,xim7U7l0pq,dmuGqsfqK9,CBWz8NHlmu,tNiJlamlmT,ul2N2l16qq,jq7ThluJ8l,OmwkmjpqNi,VfsQBP8pp6,lDloleGQ6w,XsGLpLAsAi,B5l7qRwLTa,9qhuwQmlzq,tJRcDsuSgU,JlkNqyUWlP,klqTMWll8a,lTqTskDNlQ,tlKy8q3SFF,oGrx7SRqu9,Mmb02pqzcU,lwku7fEi2o,zHJATwjq2Y,0Rif4AnLpf,mbMNikglDh,R67kqm6O4e,lllllGlkh0,Y43wA7Msoz,ulzy3zxczQ,alJwH18mYk,mAXyoN4Xml,DLdoz01lzX,luzikPZW3B,lGlkAWyJYl,66zPdql5wb,IlmTSMBDql,Fl7bw85Z8s,fksvTglTAD,cLmZqvsHoK,Uw0TQTmll4,yllzkllnpi,QmoHxlMuoR,kSSlYlJzNX,yLwskqloEy,ecPkmkogwl,lxdl6OwJY0,0zBBvuli5Y,2niilkulHx,0Qwwqlr7lf,CSIjUAf0Xz,gAbKilUI9s,nlmwYlkkYM,lNOl7rfnQW,kMDJ1YkWwU,T0lGm4slfl,HvluxQZull,BUoMkJmVSk,Wwo2AJYVlf,l4TwlIV7Mm,k6j7lfBzm8,T8v7czh7Vl,EzjRMTGrJy,tlsYq3qwzk,a1LvULqqRi,ldbSZNulqZ,ipillclohl,DqszhtJl6r,6YRCfiww0A,9lYNQl07i7,lIwZBrkhhl,cY5NMYcBhm,gleQ5uUlMK,OG4misIxnl,zmwNMmNxlI,Xl9v6iluoR,wU2OviRJyq,WsazRkGIHQ,lwzQHlqoNv,zcy4ll45iG,3allkImlpk,6i8PlDlB7k,w1lDmif7so,wvWjsl0mHh,PATlYusAv6,XaMivkRl1w,mmolQ2lmS4,mktrvllyvp,PA7gpyttln,Uaqpv8Kxlz,RqmOPl9ApF,Hb06ylaAQm,81FmEymabp,ymgzlAon4j,IGlllwlKpm,ukbaDMZltl,m7JvhxrllQ,4lsslouINp,sMltwq3yeJ,kc6rhlZK4t,lyvlcoqgsn,tGJd1s3Zsp,IkWlwsJpwl,TTm50MlQ5u,Xy48loDTzD,lNbQfz5qJu,l0wMaYRjQB,H1mAxkymSq,QcRJMxNHBl,QlsMrlknll,QoNl7qq8xb,ushlSMNEEi,VsUk8pAcPa,UjPdmstTge,YJlwlypPXX,DGmlRb5iZX,lFRqPnVnl9,lscP7AiLuQ,7l2zzupk4l,lqlSZLJYXt,JXWImuGoaw,ilXlawTJDn,loSES2mrFB,kissQydYRv,lj6m77Wpsu,yKIGfAQKlK,f0qwzleSqA,4LIP1imvSO,QwSlF4y8Qb,0q7DkkobFR,X48m4Kzl0D,Hv2l8p7lqA"
    local accountID_tab = str_split(accountID_list_str,",")

    for k , accountID in pairs(accountID_tab) do
        local  tab = {
            appKey = appKey,
            accountID =  accountID ,-- 'E6ppmuzudN',--'RZ9tnakMTl',--'eB6bYE8pkl',--'mUhBunWEya',--
            followType = 2,
            channelNumber = 'KACHE',
        }

        tab['sign'] = gen_sign(tab, secret)
        local body = table_to_kv(tab)

        local post_data = 'POST /clientcustom/v2/followMicroChannel HTTP/1.0\r\n' ..
              'Host:%s:%s\r\n' ..
              'Content-Length:%d\r\n' ..
              'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

        -- host_ip = "api.daoke.io"

        local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
        print(req)
        local ok,ret = cutils.http(host_ip, host_port, req, #req)
        if not ok then
            print('http post failed!')
            return
        end
        print(ret)
    end
 end

local function create_region_channel( )

    local tab_info = {

{'北京市', '010001',  '110000',  '北京地区频道'},
{'天津市', '022001',  '120000',  '天津地区频道'},
{'上海市', '021001',  '310000',  '上海地区频道'},
{'重庆市', '023001',  '500000',  '重庆地区频道'},
{'邯郸市', '031001',  '130400',  '邯郸地区频道'},
{'邢台市', '031901',  '130500',  '邢台地区频道'},
{'保定市', '031201',  '130600',  '保定地区频道'},
{'承德市', '031401',  '130800',  '承德地区频道'},
{'唐山市', '031501',  '130200',  '唐山地区频道'},
{'沧州市', '031701',  '130900',  '沧州地区频道'},
{'廊坊市', '031601',  '131000',  '廊坊地区频道'},
{'衡水市', '031801',  '131100',  '衡水地区频道'},
{'福州市', '059101',  '350100',  '福州地区频道'},
{'厦门市', '059201',  '350200',  '厦门地区频道'},
{'三明市', '059801',  '350400',  '三明地区频道'},
{'莆田市', '059401',  '350300',  '莆田地区频道'},
{'泉州市', '059501',  '350500',  '泉州地区频道'},
{'漳州市', '059601',  '350600',  '漳州地区频道'},
{'南平市', '059901',  '350700',  '南平地区频道'},
{'宁德市', '059301',  '350900',  '宁德地区频道'},
{'龙岩市', '059701',  '350800',  '龙岩地区频道'},
{'南昌市', '079101',  '360100',  '南昌地区频道'},
{'新余市', '079001',  '360500',  '新余地区频道'},
{'九江市', '079201',  '360400',  '九江地区频道'},
{'鹰潭市', '070101',  '360600',  '鹰潭地区频道'},
{'上饶市', '079301',  '361100',  '上饶地区频道'},
{'宜春市', '079501',  '360900',  '宜春地区频道'},
-- {'临川市', '079401',  '362522',  '临川地区频道'},
{'吉安市', '079601',  '360800',  '吉安地区频道'},
{'赣州市', '079701',  '360700',  '赣州地区频道'},
{'济南市', '053101',  '370100',  '济南地区频道'},
{'青岛市', '053201',  '370200',  '青岛地区频道'},
{'淄博市', '053301',  '370300',  '淄博地区频道'},
{'潍坊市', '053601',  '370700',  '潍坊地区频道'},
{'烟台市', '053501',  '370600',  '烟台地区频道'},
{'威海市', '063101',  '371000',  '威海地区频道'},
{'兖州市', '053701',  '370882',  '兖州地区频道'},
{'日照市', '063301',  '371100',  '日照地区频道'},
{'德州市', '053401',  '371400',  '德州地区频道'},
{'太原市', '035101',  '140100',  '太原地区频道'},
{'大同市', '035201',  '140200',  '大同地区频道'},
{'阳泉市', '035301',  '140300',  '阳泉地区频道'},
{'长治市', '035501',  '140400',  '长治地区频道'},
{'朔州市', '034901',  '140600',  '朔州地区频道'},
{'孝义市', '035801',  '141181',  '孝义地区频道'},
{'临汾市', '035701',  '141000',  '临汾地区频道'},
{'运城市', '035901',  '140800',  '运城地区频道'},
{'通辽市', '047501',  '150500',  '通辽地区频道'},
{'包头市', '047201',  '150200',  '包头地区频道'},
{'郑州市', '037101',  '410100',  '郑州地区频道'},
{'开封市', '037801',  '410200',  '开封地区频道'},
{'洛阳市', '037901',  '410300',  '洛阳地区频道'},
{'新乡市', '037301',  '410700',  '新乡地区频道'},
{'濮阳市', '039301',  '410900',  '濮阳地区频道'},
{'商丘市', '037001',  '411400',  '商丘地区频道'},
{'南阳市', '037701',  '411300',  '南阳地区频道'},
{'周口市', '039401',  '411600',  '周口地区频道'},
{'沈阳市', '024001',  '210100',  '沈阳地区频道'},
{'大连市', '041101',  '210200',  '大连地区频道'},
{'抚顺市', '041301',  '210400',  '抚顺地区频道'},
{'本溪市', '041401',  '210500',  '本溪地区频道'},
{'丹东市', '041501',  '210600',  '丹东地区频道'},
{'锦州市', '041601',  '210700',  '锦州地区频道'},
{'营口市', '041701',  '210800',  '营口地区频道'},
{'阜新市', '041801',  '210900',  '阜新地区频道'},
{'辽阳市', '041901',  '211000',  '辽阳地区频道'},
{'铁岭市', '041001',  '211200',  '铁岭地区频道'},
{'武汉市', '027001',  '420100',  '武汉地区频道'},
{'黄石市', '072401',  '420200',  '黄石地区频道'},
{'十堰市', '071901',  '420300',  '十堰地区频道'},
{'宜昌市', '071701',  '420500',  '宜昌地区频道'},
{'荆门市', '071401',  '420800',  '荆门地区频道'},
{'孝感市', '071201',  '420900',  '孝感地区频道'},
{'黄冈市', '071301',  '421100',  '黄冈地区频道'},
{'恩施市', '071801',  '422801',  '恩施地区频道'},
{'长春市', '043101',  '220100',  '长春地区频道'},
{'吉林市', '042301',  '220200',  '吉林地区频道'},
{'四平市', '043401',  '220300',  '四平地区频道'},
{'辽源市', '043701',  '220400',  '辽源地区频道'},
{'通化市', '043501',  '220500',  '通化地区频道'},
{'临江市', '043901',  '220681',  '临江地区频道'},
{'大安市', '043601',  '220882',  '大安地区频道'},
{'敦化市', '043301',  '222403',  '敦化地区频道'},
{'珲春市', '044001',  '222404',  '珲春地区频道'},
{'长沙市', '073101',  '430100',  '长沙地区频道'},
{'湘潭市', '073201',  '430300',  '湘潭地区频道'},
{'衡阳市', '073401',  '430400',  '衡阳地区频道'},
{'岳阳市', '073001',  '430600',  '岳阳地区频道'},
{'常德市', '073601',  '430700',  '常德地区频道'},
{'郴州市', '073501',  '431000',  '郴州地区频道'},
{'益阳市', '073701',  '430900',  '益阳地区频道'},
{'怀化市', '074501',  '431200',  '怀化地区频道'},
{'张家界', '074401',  '430800',  '张家界地区频道'},
{'大庆市', '045901',  '230600',  '大庆地区频道'},
{'伊春市', '045801',  '230700',  '伊春地区频道'},
{'黑河市', '045601',  '231100',  '黑河地区频道'},
{'广州市', '020001',  '440100',  '广州地区频道'},
{'深圳市', '075501',  '440300',  '深圳地区频道'},
{'珠海市', '075601',  '440400',  '珠海地区频道'},
{'汕头市', '075401',  '440500',  '汕头地区频道'},
{'韶关市', '075101',  '440200',  '韶关地区频道'},
{'惠州市', '075201',  '441300',  '惠州地区频道'},
{'东莞市', '076901',  '441900',  '东莞地区频道'},
{'中山市', '076001',  '442000',  '中山地区频道'},
{'佛山市', '075701',  '440600',  '佛山地区频道'},
{'湛江市', '075901',  '440800',  '湛江地区频道'},
{'南京市', '025001',  '320100',  '南京地区频道'},
{'徐州市', '051601',  '320300',  '徐州地区频道'},
{'淮安市', '051701',  '320800',  '淮安地区频道'},
{'宿迁市', '052701',  '321300',  '宿迁地区频道'},
{'盐城市', '051501',  '320900',  '盐城地区频道'},
{'扬州市', '051401',  '321000',  '扬州地区频道'},
{'南通市', '051301',  '320600',  '南通地区频道'},
{'镇江市', '051101',  '321100',  '镇江地区频道'},
{'常州市', '051901',  '320400',  '常州地区频道'},
{'无锡市', '051001',  '320200',  '无锡地区频道'},
{'苏州市', '051201',  '320500',  '苏州地区频道'},
{'常熟市', '052001',  '320581',  '常熟地区频道'},
{'南宁市', '077101',  '450100',  '南宁地区频道'},
{'柳州市', '077201',  '450200',  '柳州地区频道'},
{'桂林市', '077301',  '450300',  '桂林地区频道'},
{'梧州市', '077401',  '450400',  '梧州地区频道'},
{'北海市', '077901',  '450500',  '北海地区频道'},
{'钦州市', '077701',  '450700',  '钦州地区频道'},
{'海口市', '089801',  '460100',  '海口地区频道'},
{'三亚市', '089901',  '460200',  '三亚地区频道'},
{'儋州市', '089001',  '469003',  '儋州地区频道'},
{'成都市', '028001',  '510100',  '成都地区频道'},
{'德阳市', '083801',  '510600',  '德阳地区频道'},
{'绵阳市', '081601',  '510700',  '绵阳地区频道'},
{'自贡市', '081301',  '510300',  '自贡地区频道'},
{'内江市', '083201',  '511000',  '内江地区频道'},
{'乐山市', '083301',  '511100',  '乐山地区频道'},
{'泸州市', '083001',  '510500',  '泸州地区频道'},
{'宜宾市', '083101',  '511500',  '宜宾地区频道'},
{'杭州市', '057101',  '330100',  '杭州地区频道'},
{'宁波市', '057401',  '330200',  '宁波地区频道'},
{'嘉兴市', '057301',  '330400',  '嘉兴地区频道'},
{'湖州市', '057201',  '330500',  '湖州地区频道'},
{'绍兴市', '057501',  '330600',  '绍兴地区频道'},
{'金华市', '057901',  '330700',  '金华地区频道'},
{'衢州市', '057001',  '330800',  '衢州地区频道'},
{'舟山市', '058001',  '330900',  '舟山地区频道'},
{'温州市', '057701',  '330300',  '温州地区频道'},
{'台州市', '057601',  '331000',  '台州地区频道'},
{'贵阳市', '085101',  '520100',  '贵阳地区频道'},
{'遵义市', '085201',  '520300',  '遵义地区频道'},
{'安顺市', '085301',  '520400',  '安顺地区频道'},
{'合肥市', '055101',  '340100',  '合肥地区频道'},
{'淮南市', '055401',  '340400',  '淮南地区频道'},
{'蚌埠市', '055201',  '340300',  '蚌埠地区频道'},
{'安庆市', '055601',  '340800',  '安庆地区频道'},
{'黄山市', '055901',  '341000',  '黄山地区频道'},
{'滁州市', '055001',  '341100',  '滁州地区频道'},
{'宿州市', '055701',  '341300',  '宿州地区频道'},
{'巢湖市', '056501',  '340181',  '巢湖地区频道'},
{'昆明市', '087101',  '530100',  '昆明地区频道'},
{'昭通市', '087001',  '530600',  '昭通地区频道'},
{'曲靖市', '087401',  '530300',  '曲靖地区频道'},
{'丽江县', '088801',  '530700',  '丽江县地区频道'},
{'开远市', '087301',  '532502',  '开远地区频道'},
{'楚雄市', '087801',  '532301',  '楚雄地区频道'},
{'西安市', '029001',  '610100',  '西安地区频道'},
{'铜川市', '091901',  '610200',  '铜川地区频道'},
{'宝鸡市', '091701',  '610300',  '宝鸡地区频道'},
{'渭南市', '091301',  '610500',  '渭南地区频道'},
{'拉萨市', '089101',  '540100',  '拉萨地区频道'},
{'兰州市', '093101',  '620100',  '兰州地区频道'},
{'金昌市', '093501',  '620300',  '金昌地区频道'},
{'天水市', '093801',  '620500',  '天水地区频道'},
{'平凉市', '093301',  '620800',  '平凉地区频道'},
{'玉门市', '093701',  '620981',  '玉门地区频道'},
{'敦煌市', '093702',  '620982',  '敦煌地区频道'},
{'西宁市', '097101',  '630100',  '西宁地区频道'},
{'喀什市', '099801',  '653101',  '喀什地区频道'},
{'银川市', '095101',  '640100',  '银川地区频道'},
{'石家庄市',    '031101',  '130100',  '石家庄地区频道'},
{'张家口市',    '031301',  '130700',  '张家口地区频道'},
{'秦皇岛市',    '033501',  '130300',  '秦皇岛地区频道'},
{'景德镇市',    '079801',  '360200',  '景德镇地区频道'},
{'格尔木市',    '097901',  '632801',  '格尔木地区频道'},
{'石嘴山市',    '095201',  '640200',  '石嘴山地区频道'},
{'青铜峡市',    '095301',  '640381',  '青铜峡地区频道'},
{'吐鲁番市',    '099501',  '652101',  '吐鲁番地区频道'},
{'阿图什市',    '090801',  '653001',  '阿图什地区频道'},
{'库尔勒市',    '099601',  '652801',  '库尔勒地区频道'},
{'哈尔滨市',    '045101',  '230100',  '哈尔滨地区频道'},
{'牡丹江市',    '045301',  '231000',  '牡丹江地区频道'},
{'佳木斯市',    '045401',  '230800',  '佳木斯地区频道'},
{'连云港市',    '051801',  '320700',  '连云港地区频道'},
{'日喀则市',    '089201',  '542301',  '日喀则地区频道'},
{'攀枝花市',    '081201',  '510400',  '攀枝花地区频道'},
{'六盘水市',    '085801',  '520200',  '六盘水地区频道'},
{'马鞍山市',    '055501',  '340500',  '马鞍山地区频道'},
{'呼和浩特',    '047101',  '150100',  '呼和浩特地区频道'},
{'满洲里市',    '047001',  '150781',  '满洲里地区频道'},
{'齐齐哈尔市',   '045201',  '230200',  '齐齐哈尔地区频道'},
{'乌鲁木齐市',   '099101',  '650100',  '乌鲁木齐地区频道'},
{'克拉玛依市',   '099001',  '650200',  '克拉玛依地区频道'},
{'二连浩特市',   '047901',  '152501',  '二连浩特地区频道'},
{'乌兰浩特市',   '048201',  '152201',  '乌兰浩特地区频道'},
    }


    for k ,v in pairs(tab_info) do
        local city_name = v[1]
        local tab = {
            appKey = appKey,
            accountID = "kxl1QuHKCD",
            channelNumber = v[2],
            channelCityCode = v[3],
            channelName = v[4],
            channelIntroduction = "此频道为" .. (city_name or '' )  .. "地区频道，快加入进来！",
            channelCatalogID = "301021",        ---- 群聊频道,地区频道
            openType = "1",
            channelKeyWords = city_name .. ",地区,群聊",
        }
        tab['sign'] = gen_sign(tab,secret)
        local host_ip = "115.231.73.70"
        local host_port = 80
        local body = table_to_kv(tab)
        local post_data = 'POST /clientcustom/v2/createRegionChannel HTTP/1.0\r\n' ..
              'Host:%s:%s\r\n' ..
              'Content-Length:%d\r\n' ..
              'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

        local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
        -- print(req)
        local ok,ret = cutils.http(host_ip, host_port, req, #req)
        if ok and ret then
            local msg = string.match(ret,'{.+}')
            if msg then
                local ok,tab = pcall(cjson.decode,msg)
                if tab then
                    if tab['ERRORCODE'] == "0" then
                        tab_info[k][4] = "1"
                    elseif tab['ERRORCODE']  == "ME18105" then
                        tab_info[k][4] = "2"
                    else
                        -- print(req)
                        -- print(ret)
                    end
                end
            end
        end
        -- break
    end

    for k ,v in pairs(tab_info) do
        if v[4] == "1" then
            print(string.format("%s %s succed", v[2],v[1]))
        elseif v[4] == "2" then
            print(string.format("%s %s exist", v[2],v[1]))
        else
            print(string.format("%s %s failed", v[2],v[1]))
        end
    end

end

local function transport_old_channel_info()

    local  tab = {
            appKey = appKey,
            isChannel = '1',    ---- 转移频道
        }

        tab['sign'] = gen_sign(tab, secret)
        local body = table_to_kv(tab)
        -- local host_ip = "115.231.73.70"
        -- local host_port = 80
        -- local host_ip = "192.168.1.207"
        -- local host_port = 80
        local post_data = 'POST /clientcustom/v2/transportOldChannelInfo HTTP/1.0\r\n' ..
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

local function transport_old_userKey_info()

    local  tab = {
            appKey = appKey,
            -- accountID = "vOlRjVmX3B",
            isChannel = '2',    ---- 用户按键
        }

        tab['sign'] = gen_sign(tab, secret)
        local body = table_to_kv(tab)

        local post_data = 'POST /clientcustom/v2/transportOldChannelInfo HTTP/1.0\r\n' ..
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



local function transport_old_auto_check_msg()
    local  tab = {
            appKey = appKey,
            isChannel = '3',    ---- 用户按键
            startPage = "1",
            pageCount = "500",
        }

        tab['sign'] = gen_sign(tab, secret)
        local body = table_to_kv(tab)

        local post_data = 'POST /clientcustom/v2/transportOldChannelInfo HTTP/1.0\r\n' ..
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



local function transport_old_auto_repair_all_data()
    local  tab = {
            appKey = appKey,
            isChannel = '4',    ---- 用户按键
            maxCount = "10000" ,
        }

        tab['sign'] = gen_sign(tab, secret)
        local body = table_to_kv(tab)
        -- local host_ip = "115.231.73.70"
        -- local host_port = 80
        local post_data = 'POST /clientcustom/v2/transportOldChannelInfo HTTP/1.0\r\n' ..
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

<<<<<<< HEAD
local function transport_clean_10086_channel(  )
    local  tab = {
            appKey = appKey,
            -- accountID = "uh5HJzalK3",
            isChannel = '6',    ---- 用户按键
            maxCount = "10000" ,
            channelList = "10086",
=======
local function clear_voicecommand_channel()
    local  tab = {
            appKey = appKey,
            isChannel = '5',    ---- 用户按键
            -- accountID = 'kxl1QuHKCD',
            maxCount = "10000" ,
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a
        }

        tab['sign'] = gen_sign(tab, secret)
        local body = table_to_kv(tab)
<<<<<<< HEAD

        local post_data = 'POST /clientcustom/v2/transportOldChannelInfo HTTP/1.0\r\n' ..
=======
        -- local host_ip = "api.daoke.io"
        -- local host_port = 80
        local post_data = 'POST /clientcustom/v2/setUserkeyInfo HTTP/1.0\r\n' ..
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a
              'Host:%s:%s\r\n' ..
              'Content-Length:%d\r\n' ..
              'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

<<<<<<< HEAD

=======
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a
        local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
        print(req)
        local ok,ret = cutils.http(host_ip, host_port, req, #req)
        if not ok then
            print('http post failed!')
            return
        end
        print(ret)
<<<<<<< HEAD
end

local function  test_check_is_online(  )
     local  tab = {
            appKey = appKey,
            accountID = 'kxl1QuHKCD,tbqY03flQn'
=======

end

local function repair_channel_yichang_data()
    local  tab = {
            appKey = appKey,
            isChannel = '8',    ---- 用户按键
            --["LmPkMjRwvw","l1zAbMqg30","OTDlvam8pl","Yu6RQc7llT"]
            --053427,520263,053401,88888,110099,456131,43110,42001,42000,000000
            ---- ["EcAmSwuT8a","OTfYKGlDip","sNbhaowzpa"]
            ---- 85762,81627,81688,083002,053133,369888,02016,01699,090888,85468 "iNllSEwGZx"
            ----
<<<<<<< HEAD
            channelNumbers = "000789",
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a
=======
            --channelNumber = "000010305",
            maxCount = 3000,
>>>>>>> fe6bc0088c3d0207b7a12f67ab02a0a45dd1510b
        }

        tab['sign'] = gen_sign(tab, secret)
        local body = table_to_kv(tab)
<<<<<<< HEAD
<<<<<<< HEAD

        local post_data = 'POST /clientcustom/v3/checkIsOnline HTTP/1.0\r\n' ..
=======
        -- local host_ip = "192.168.11.201"
=======
        --local host_ip = "192.168.1.207"
        -- local host_port = 80
        -- local host_ip = "api.daoke.io"
>>>>>>> fe6bc0088c3d0207b7a12f67ab02a0a45dd1510b
        -- local host_port = 80
        local post_data = 'POST /clientcustom/v2/transportOldChannelInfo HTTP/1.0\r\n' ..
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a
              'Host:%s:%s\r\n' ..
              'Content-Length:%d\r\n' ..
              'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

<<<<<<< HEAD
        -- host_ip = "api.daoke.io"

=======
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a
        local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
        print(req)
        local ok,ret = cutils.http(host_ip, host_port, req, #req)
        if not ok then
            print('http post failed!')
            return
        end
        print(ret)
<<<<<<< HEAD
end

=======


end
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a

-- test_get_subscribemsg()

--test_getUserFollowListMicroChannel()   --//user

--test_getBossFollowListMicroChannel()   --//boss

--test_apply_microChannel()   --//

--test_check_microChannel()   --//

--test_fetch_microChannel()    --//

--test_resetInviteUniqueCode() --//

--test_follow_microchannel() --//

-- test_unfollow_microchannel() --//

-- test_apply_microChannel()   --//

-- test_check_microChannel()

--test_getMicroChannelInfo() --//

-- test_get_cataloginfo()


-- test_recheck_microChannel()

-- test_modify_microChannel()

-- test_split_str()

-- test_batch_unfollow_microchannel()


---- 地区频道初始化数据
---- 2015-05-25 
-- create_region_channel()

---- 原始频道的数据迁移
---- 2015-05-25 

 -- transport_old_channel_info()

---- OLD CODE NEED REPARI 
-- for i = 1, 800 do
--     ---- 将用户设置的关联按键频道加入设置频道,再设置用户按键
--  transport_old_userKey_info()
--     -- 自动审核频道申请消息
--     transport_old_auto_check_msg()
--     socket.select(nil, nil, 3)
-- end

-- transport_old_auto_repair_all_data()

<<<<<<< HEAD

-- transport_clean_10086_channel()

-- test_check_is_online()

=======
---- clear_voicecommand_channel()

repair_channel_yichang_data()
>>>>>>> e3bfa4db633b12a19b12e81f124adbd43b28756a


