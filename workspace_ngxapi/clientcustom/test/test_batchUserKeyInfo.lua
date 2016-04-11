--yuGWGIXwuh

package.path = '/data/nginx/open/lib/?.lua;' .. package.path
package.cpath = '/data/nginx/open/lib/?.so;' .. package.cpath

local cutils = require('cutils')
local cjson  = require('cjson')
local sha    = require('sha1')
local socket = require('socket')


---- 线下测试环境
local host_ip = '192.168.1.207'
local host_port = 80

local host_ip = '127.0.0.1'

--local host_port = 8088

--local host_ip = "api.daoke.io"
--local host_port = 80


local appKey = '4223273916'
local secret  = 'DA00D00CBFECD61E4EA4FA830FCEEA4C96C5683D'
-- local appKey = '3858698681'
-- local  secret = 'C28A235E15C582F7F3815E728EC83616B23C6EDF'

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


local function test_get_cataloginfo()       --//获取城市列表
    local  tab = {
        appKey = appKey,
        --accountID = 'eB6bYE8pkl',

        --channelNumber = 'FMDK0001',
        --channelName = "s回申.请表gdffd\r",
        --channelStatus = '1',
        --cityCode = '110000',
        --catalogID= '1001142',
        --channelCatalogUrl = 'http://www.baidu.jpg',
        --followType = '1',
        --uniqueCode= 'daokegroup3|6dc90c8c7c1e11e483af74d4350c77be',

        startPage="01000",
        pageCount="10"
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getCatalogInfo  HTTP/1.0\r\n' ..
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
local function test_get_modifyMicroChannel()       --//获取城市列表
    local  tab = {
        appKey = appKey,
        accountID = "00AWBnDm8h",
beforeChannelNumber='daokegroup2',
        --channelNumber = 'daokegroup2',
        channelName = "s回申请llouiou表gdf",
        --channelStatus = '1',
        channelCityCode = "110000",
        channelCatalogID= "100101",
        channelCatalogUrl = 'http://www.baidu.jpg',
        infoType="1",
        applyIdx="1",
        --followType = '1',
        --uniqueCode= 'daokegroup3|6dc90c8c7c1e11e483af74d4350c77be',

       
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/modifyMicroChannel  HTTP/1.0\r\n' ..
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
local function test_apply_SecretChannel()    --//申请微频道
    local tab = {
        appKey = appKey,
        accountID ='0lvs06fTHc' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        channelNumber = 'c000000',--"b333333",--'FMDJ123456',                             --//频道编号
        channelName = "测试测死测试",              --//频道名称
        channelIntroduction = "专d分享交通电子眼的频道kasdfklska",              --//主播简介
        channelCityCode = "130000",  --//频道区域编码
        channelCatalogID ="100106",   --//频道类别编号
        channelCatalogUrl = 'http://www.baidu.jpg', --//
         openType = 1,
         actionType = 4,
    }
    
    tab['sign'] = gen_sign(tab,secret)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/userApplySecretChannel  HTTP/1.0\r\n' ..
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
local function test_get_SecretChannelInfo()    --//申请微频道
    local tab = {
        appKey = appKey,
        accountID ="E6ppmuzudN",--"0jimyZqoly",--"0lTlNooEyU",--'E6ppmuzudN' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        channelNumber = "b111111",--"c222222",--"a333333",--'FMDJ123456',  
        --                    --//频道编号
        showChannelID = '000000000'
      

    }
    
    tab['sign'] = gen_sign(tab,secret)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getSecretChannelInfo",tab)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getSecretChannelInfo  HTTP/1.0\r\n' ..
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
 local function test_join_SecretChannel()    --//申请微频道
    local tab = {
        appKey = appKey,
         followType = "1",
         accountID ='0mIGkzSlyw',--'0kkW0eyJlJ',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        --channelNumber = "b111111",--'FMDJ123456',                             --//频道编号
        --uniqueCode = 'b111111|83aefc66812b11e4bd2500e04c1eecbd',
        --uniqueCode = 'c222222|ceb10fe6829911e488a600e04c1eecbd',
        uniqueCode = "c333333|b2f0a664859a11e4abdf00e04c1eecbd",

        actionType = '5',
    }
    
    tab['sign'] = gen_sign(tab,secret)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/joinSecretChannel",tab)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/joinSecretChannel  HTTP/1.0\r\n' ..
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
 local function test_get_secretChannelList()    --//申请微频道
    local tab = {
        appKey = appKey,
        infoType = '2',
        accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        channelNumber = "a333333",--'FMDJ123456',                             --//频道编号
        pageCount = 10,
        startPage = 1,
       -- channelName = '.',


        --cityCode = '110000',
        --catalogID = '100104',

    }
    
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/fetchSecretChannel",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
 end   
local function test_get_user_join_secretChannelList()    --//申请微频道
    local tab = {
      --   appKey = appKey,
      --   --followType = '1',
      --   accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
      --   channelNumber = "a333333",--'FMDJ123456',                             --//频道编号
      --  pageCount = 10,
      --   startPage = 1,
      -- citycode = '110000',
      --   CatalogID = '100104',
         appKey = appKey,
         accountID = '0oiclkriRj',--'E6ppmuzudN',--'0jimyZqoly',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
       --  channelNumber = 'AX000000',                             --//频道编号
        startPage = 1,
        pageCount = 10,
       --  infoType = 1,
       --   --accountID ='0lTlNooEyU' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
       -- channelNumber = 'c222222',--"b333333",--'FMDJ123456'

    }
    
    tab['sign'] = gen_sign(tab,secret)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getUserJoinSecretChannelList",tab)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getUserJoinSecretChannelList  HTTP/1.0\r\n' ..
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
 local function test_modify_secretChannel()    --//申请微频道
    local tab = {
        appKey = appKey,
        accountID ='E6ppmuzudN' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        channelNumber = "a555555",--'FMDJ123456',                             --//频道编号
        -- channelName = "密频道",              --//频道名称
        -- channelIntroduction = "简介",          --//频道简介
        -- chiefAnnouncerIntr = "小心被播主播简介",     --//主播简介
        -- channelCityCode = "120000",  --//频道区域编码
        -- channelCatalog = "100101",   --//频道类别编号
        --channelLogoUrl = 'http://www.eeeeeee.jpg', --//
        channelName = "频道编号dfs",

        channelOpenType = 0,
    }
    
    tab['sign'] = gen_sign(tab,secret)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/modifySecretChannelInfo",tab)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/modifySecretChannelInfo  HTTP/1.0\r\n' ..
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
 local function  test_manage_secretChannel( )
      local tab = {
        appKey = appKey,
        --followType = '1',
        --accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        adminAccountID = '0lTlNooEyU',
        channelNumber = 'c222222',
        infoType = '2',
       curStatus = '1',
       -- accountID = 'E6ppmuzudN',--'0kjtMkiXml',--'E6ppmuzudN',
        accountID ='0jimyZqoly',--'0jimyZqoly',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        -- channelNumber = "c222222",--'FMDJ123456',                             --//频道编号
        -- uniqueCode = 'c222222|ceb10fe6829911e488a600e04c1eecbd',
    }
    
    tab['sign'] = gen_sign(tab,secret)
     local body = table_to_kv(tab)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/manageSecretChannelUsers",tab)
    local post_data = 'POST /clientcustom/v2/manageSecretChannelUsers  HTTP/1.0\r\n' ..
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
 local function test_fetch_secretChannel()
     local tab = {
        appKey = appKey,
      infoType = '3',
      accountID ='aaaaaaaaaa',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
    --     channelNumber = "a333333",--'FMDJ123456',                             --//频道编号
            pageCount = '20',
            startPage = '1',
        --startPage = "2",
    --     --cityCode = '120000',
    --    --catalogID = '100104',
    --    channelName = "a",
    --    showChannelID = "000000001",

 }
 tab['sign'] = gen_sign(tab,secret)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/modifySecretChannelInfo",tab)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/fetchSecretChannel  HTTP/1.0\r\n' ..
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

    
    -- tab['sign'] = gen_sign(tab,secret)
    -- local body = table_to_kv(tab)
    -- --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/fetchSecretChannel",tab)
    -- local post_data = 'POST /clientcustom/v2/fetchSecretChannel  HTTP/1.0\r\n' ..
    --       'Host:%s:%s\r\n' ..
    --       'Content-Length:%d\r\n' ..
    --       'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    -- --local req = string.format(post_data,host_ip, tostring(host_port) , #body , body )
    -- local req = string.format(post_data,host_ip, tostring(host_port) , 189,tab)

    -- local ok,ret = cutils.http(host_ip,host_port,req,#req)
    -- if not ok or ret == nil then
    --     print("post data failed!")
    --     return
    -- end
    print(ret)
 end
local function test_online_secretChannel( )
     local tab = {
        appKey = appKey,
        --followType = '1',
        --accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
       adminAccountID = 'kxl1QuHKCD',
       channelNumber = 'b111111',
       infoType = '2',
       curStatus = '3',
       accountID = 'E6ppmuzudN',
    }
    
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getUserOnlineList",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end 
local function test_admin_get_userList(  )
    local tab = {
        appKey = appKey,
        --followType = '1',
        --accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
     --  adminAccountID = '0kjtMkiXml',
       -- channelNumber = 'b111111',
        accountID = 'kxl1QuHKCD',
       startPage = 1,
       pageCount = 10,
        --accountID ='0lTlNooEyU' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
       channelNumber = 'c222222',--"b333333",--'FMDJ123456'
    }
    
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getSecretChannelUserList",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
local function test_get_userList_secretChannel()
    local tab = {
        appKey = appKey,
        accountID ='eB6bYE8pkl' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
        channelNumber = "a555555",--'FMDJ123456',                             --//频道编号
        -- channelName = "密频道",              --//频道名称
        -- channelIntroduction = "简介",          --//频道简介
        -- chiefAnnouncerIntr = "小心被播主播简介",     --//主播简介
        -- channelCityCode = "120000",  --//频道区域编码
        -- channelCatalog = "100101",   --//频道类别编号
        --channelLogoUrl = 'http://www.eeeeeee.jpg', --//

        --channelOpenType = 0,
        infoType = 2,
        startPage = '1',
        pageCount = '1',

    }
    
    tab['sign'] = gen_sign(tab,secret)
    --local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/modifySecretChannelInfo",tab)
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getSecretChannelUserList  HTTP/1.0\r\n' ..
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

local function test_get_allSecretChannelInfo()

   local tab = {
        appKey = appKey,
        --followType = '1',
        --accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
     --  adminAccountID = '0kjtMkiXml',
       -- channelNumber = 'b111111',
        accountID = 'kxl1QuHKCD',
       startPage = 1,
       pageCount = 10,
        --accountID ='0lTlNooEyU' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
       channelNumber = 'c222222',--"b333333",--'FMDJ123456'
    }
    
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getAllSecretChannelList",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end

--96666&appKey=3858698681&customType=2&accessToken=OezXcEiiBSKSxW0eoylIeA7Xk9Y4wmyK_YKyyLAbwEeih97AmtLFVvbEQCv1w7zjlnboiSGgKxNjEdUB8Lmd9_jakrYEtb-7LF7-DMVYqERwWpvBTF42vMjF_ZXhY5D1Qodjc_m8ANBLjq5zf2xHcQ___{"ERRORCODE":"ME01003", "RESULT":"access token not matched"}
local function test_set_custominfo()
    local tab = {
        appKey = appKey,
        --accountID=QpHbAlTBlw&actionT
        --followType = '1',
        --accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
     --  adminAccountID = '0kjtMkiXml',
       -- channelNumber = 'b111111',
       -- accountID = 'kxl1QuHKCD',
       --startPage = 1,
       --pageCount = 10,
        accountID ='QpHbAlTBlw' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
       --channelNumber = 'c222222',--"b333333",--'FMDJ123456'
       actionType = 4,
        customType = 2,
        customParameter = "96666"
        --customParameter=96666&appKey=385869
    }
    local host_ip = "api.daoke.io"
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
local function test_batch_fetch_userKeyInfo()


    local tab = {
        appKey = appKey,
        --followType = '1',
        --accountID ='E6ppmuzudN',--'eB6bYE8pkl',--'E6ppmuzudN' ,-- ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
     --  adminAccountID = '0kjtMkiXml',
       -- channelNumber = 'b111111',
       -- accountID = 'kxl1QuHKCD',
       --startPage = 1,
       --pageCount = 10,
   --     accountID ='0lTlNooEyU' ,--'eB6bYE8pkl' ,--//'E6ppmuzudN' ,--//'kxl1QuHKCD',--//, 
       --channelNumber = 'c222222',--"b333333",--'FMDJ123456'
     --  actionType = 4,
       -- customType = 6,
       -- customPar = "10086"
      --accountIDs = "eB6bYE8pkl, 0lTlNooEyU ,0s0sJ1sTlx,0uqavQT9zm,0ljqQM8Yk5,aaaaaaaaaa,kxl1QuHKCD",
      accountIDs = "yHnmlqIW9Q,DmBuB45EbZ",
       count = 2,
	--accountIDs = "0ljqQM8Yk5"
    } 
    local host_ip = "api.daoke.io"
    local host_port = 80

    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"clientcustom/v2/batchFetchUserKeyInfo",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
	print(ret)
end

local function test_batch_set_userKeyInfo()


    local tab = {
        appKey = appKey,
       	accountIDs = "AIAGlolYmp,SE2KCnkvoS,9M0Q3sscMR",
    	count = 3,
    	customType = 1,
    	channelInfo = '10086',
    }
    --local host_ip = "api.daoke.io"
    --local host_port = 80
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"clientcustom/v2/batchSetUserKeyInfo",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)

end

--test_apply_SecretChannel()
--test_get_SecretChannelInfo()
--test_join_SecretChannel()
---test_get_secretChannelList()
--test_get_user_join_secretChannelList()--//用户加入的密频道
--test_modify_secretChannel()
--test_manage_secretChannel()
--test_fetch_secretChannel()
--test_online_secretChannel()
--test_admin_get_userList() --//管理员的到密频道列表
--test_get_userList_secretChannel()
--test_get_clientcustom()
--test_get_allSecretChannelInfo()
--test_set_custominfo()
test_batch_fetch_userKeyInfo()
--test_batch_set_userKeyInfo()
