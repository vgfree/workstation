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

local host_port = 8088

--local host_ip = "api.daoke.io"
local host_port = 80


local appKey = '4223273916'
local secret  = 'DA00D00CBFECD61E4EA4FA830FCEEA4C96C5683D'

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

local function test_setUserKey()

    local error_list = {
        {actionType= 5 , customType = 10 , accountID = 'EaqklgSIGB', customParater = '090888'},
        {actionType= 5 , customType = 10 , accountID = 'wkDAWqlzBw', customParater = '01699'},
    }


    local fmt = '{"count":"1","list":["actionType":"5","customType":"10","customParameter":"%s"]}'

    for i,v in pairs(error_list) do
        local tab = {
            appKey = appKey,
            accountID = v['accountID'],
            parameter = string.format(fmt, v['customParater']),
        }
    end
    local host_ip = "192.168.1.207"
    local host_port = 80
    --local host_ip = "api.daoke.io"
    --local host_port = 80
    tab['sign'] = gen_sign(tab,secret)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/transportOldChannelInfo HTTP/1.0\r\n' ..
              'Host:%s:%s\r\n' ..
              'Content-Length:%d\r\n' ..
              'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'

        local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
        print(req)
        local ok,ret = cutils.http(host_ip, host_port, req, #req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)

end


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

test_setUserKey()



