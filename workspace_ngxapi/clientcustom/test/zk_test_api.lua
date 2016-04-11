package.path = '/data/nginx/open/lib/?.lua;' .. package.path
package.cpath = '/data/nginx/open/lib/?.so;' .. package.cpath

local cutils = require('cutils')
local cjson  = require('cjson')
local sha    = require('sha1')
local socket = require('socket')


---- 线下测试环境
--local host_ip = '192.168.1.207'
-- local host_port = 80

local host_ip = '127.0.0.1'
local host_port = 8088

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

local function test_getUserFollowListMicroChannel()     --//user
    local  tab = {
        appKey = appKey,
        accountID =  'RZ9tnakMTl',--//--'zdfeqE74Vi','kxl1QuHKCD',--//'mUhBunWEya',-- 
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
        accountID =  'E6ppmuzudN' ,--//'kxl1QuHKCD',--//
        channelNumber = 'zktesttwo',
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
        accountID = '00llyyUBkZ', -- 'kxl1QuHKCD' ,--//'00llyyUBkZ',--//'eB6bYE8pkl' ,--//,'E6ppmuzudN' ,--//
        channelNumber = 'HaPPy1100010',                             --//频道编号
        channelName = "1青春000ss00",              --//频道名称
        channelIntroduction = "青春时尚小清新",          --//频道简介
        chiefAnnouncerIntr = "青春时尚小清新",     --//主播简介
        channelCityCode = "310000",  --//频道区域编码
        channelCatalogID = 100104,   --//频道类别编号
        channelCatalogUrl = 'http://g3.tweet.daoke.me/group3/M02/E5/EA/c-dJB1R8pY-AJlO2AAGsD3RDpM8392.png', --//
        -- startPage = 1,
        -- pageCount = 20,
    }
    
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/applyMicroChannel",tab)
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
        checkAccountID = 'kxl1QuHKCD' ,--//'nmjOckC3tS'--// 'eB6bYE8pkl' ,--//'kxl1QuHKCD',--//,'E6ppmuzudN',--//,
        accountID = '0Bu7swuqrl' ,
        channelNumber = 'happy1100010',--'FM090909',                             --//频道编号
        checkRemark = '情况属实',
        checkStatus = 2,
        -- infoType = 1 ,
        applyIdx = 46,               -----//当前channelnumber的在申请表中的id
    }
    
    tab['sign'] = gen_sign(tab, secret)
    local body = table_to_kv(tab)

    local post_data = 'POST /clientcustom/v2/checkApplyMicroChannel HTTP/1.0\r\n' ..
          'Host:%s:%s\r\n' ..
          'Content-Length:%d\r\n' ..
          'Content-Type:application/x-www-form-urlencoded\r\n\r\n%s'
    -- local host_ip = "api.daoke.io"
    -- local host_port = 80
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
        accountID = 'E6ppmuzudN', --// '00AWBnDm8h' ,--//'kxl1QuHKCD',--//,
        --channelnumber =  'FMDJ123456',--// 'FMDK0011',--//'FM0909091',--//                         --//频道编号
        channelStatus = 10,
        infoType = 0,
        --channelNumber = 'fm',
        --cityCode = 110000,
        --channelName =  "y",
        --catalogID = 100104,
        --startPage=1,
        pageCount=50,
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
        accountID = '00AWBnDm8h',-- 'E6ppmuzudN', --// 'kxl1QuHKCD',-- 'RZ9tnakMTl',--
        channelNumber = 'zhangkaibelivehaha',
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
        accountID =  'RZ9tnakMTl',--'00AWBnDm8h',-- 'zdfeqE74Vi',--'eB6bYE8pkl',--'mUhBunWEya',--'kxl1QuHKCD',--
        uniqueCode = "h12345|ef88cedc828c11e4a1ea74d4350c77be",
        followType = 1,
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
        accountID =  'RZ9tnakMTl',--'E6ppmuzudN',--'eB6bYE8pkl',--'mUhBunWEya',--
        followType = 2,
        channelNumber = 'Iloveyouonly',
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
        channelNumber = 'zktestfour',--//'FMDK0011',--//
        accountID = "zdfeqE74Vi",--//'RZ9tnakMTl',-- 'kxl1QuHKCD',----
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
        checkAccountID = 'kxl1QuHKCD',--//'E6ppmuzudN',--'RZ9tnakMTl',--// 'eB6bYE8pkl',--
        -- accountID = 'nmjOckC3tS',-- 'E6ppmuzudN',
        -- channelNumber = 'h12345',
        -- checkRemark = 'abcdefg',
        -- checkStatus = 4,
        -- applyIdx = '000000077',
        infoType = 1,
        --cityCode = 110000 ,
        --channelName =  "10000",
        catalogID = 100107,
        --channelNumber = 'xx',
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/recheckMicroChannel HTTP/1.0\r\n' ..
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

local function test_modify_microChannel()       --//修改微频道信息
    local  tab = {
        appKey = appKey,
        accountID = '00AWBnDm8h',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        beforeChannelNumber = 'daokegroup3',                             --//频道编号
        channelNumber = 'ZFM0000124',                             --//频道编号
        channelName = "Iloveyou信息",              --//频道名称
        channelIntroduction = "hellohello",          --//频道简介
        chiefAnnouncerIntr = "Iloveyouverymuch",     --//主播简介
        channelCityCode = 110000,  --//频道区域编码
        channelCatalogID = 100104,   --//频道类别编号
        channelCatalogUrl = 'http://www.baidu.com.jpg', --//
        infoType = 2,
        applyIdx = 5,
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

--test_getUserFollowListMicroChannel()   --//user

--test_getBossFollowListMicroChannel()   --//boss

--test_apply_microChannel()   --//

--test_check_microChannel()   --//

--test_fetch_microChannel()    --//

--test_resetInviteUniqueCode() --//

--test_follow_microchannel() --//

--test_unfollow_microchannel() --//

--test_getMicroChannelInfo() --//

--test_get_cataloginfo()

--test_modify_microChannel()

--test_recheck_microChannel()

local function test_apply_secretChannel()       --//申请密频道
    local  tab = {
        appKey = appKey,
        accountID = '0owl8cPTP6',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'BX1230owl8cPTP6',                             --//频道编号
        channelName = "AX1230owl8cPTP6",              --//频道名称
        channelIntroduction = "AX1230owl8cPTP6",          --//频道简介
        channelCityCode = "310000",  --//频道区域编码
        channelCatalogID = 100104,   --//频道类别编号
        openType = 1,
        channelCatalogUrl = 'http://g3.tweet.daoke.me/group3/M02/E5/EA/c-dJB1R8pY-AJlO2AAGsD3RDpM8392.png',
        actionType = 4,
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/userApplySecretChannel",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
local function test_fetch_secretChannelInfo()       --//获取密频道详情
    local  tab = {
        appKey = appKey,
        accountID = '0nlYFTfR0B',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX0nlYFTfR0BE3',                             --//频道编号
        startPage = 1,
        pageCount = 10,
        infoType = 2 ,
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/fetchSecretChannelInfo HTTP/1.0\r\n' ..
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

local function test_get_userList_secretChannel()       --//管理员得到密频道里所有的用户列表
    local  tab = {
        appKey = appKey,
        accountID = '0nlYFTfR0B',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX0nlYFTfR0BE3',                             --//频道编号
        startPage = 1,
        pageCount = 10,
    }
    tab['sign'] = gen_sign(tab, secret) 
    local body = table_to_kv(tab)
    local post_data = 'POST /clientcustom/v2/getUserListSecretChannel HTTP/1.0\r\n' ..
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
local function test_join_secretChannel()       --//加入密频道
    local  tab = {
        appKey = appKey,
        accountID = '00AWBnDm8h',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX0nlYFTfR0BE3',                             --//频道编号
        uniqueCode = 'AX0nlYFTfR0BE3|0379665c826c11e4a8f474d4350c77be';
        followType = 2;
        actionType = 4;
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/joinSecretChannel",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
local function test_get_secretChannelInfo()       --管理员得到密频道的详细信息 --用户的到密频道的详细信息
    local  tab = {
        appKey = appKey,
        accountID = '0PeUPsZPMl',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'zdfeqE74Vi',                
        infoType = 1 ;
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getSecretChannelInfo",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
local function test_fetch_secretChannel()       --1 查询所有能加入的密频道列表 --2 获取管理员自己的密频道列表
    local  tab = {
        appKey = appKey,
        accountID = '00AWBnDm8h',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX000000',                             --//频道编号
        startPage = 1,
        pageCount = 10,
        infoType = 1,
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
local function test_get_user_online_secretChannel()       --//修改微频道信息
    local  tab = {
        appKey = appKey,
        accountID = '0s0sJ1sTlx',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX0s0sJ1sTlxqv',                             --//频道编号
        -- startPage = 1,
        -- pageCount = 10,
        -- infoType = 1,
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getUserOnlineListSecretChannel",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
local function test_get_user_join_secretChannelList()       --//获取自己所加入的密频道列表
    local  tab = {
        appKey = appKey,
        accountID = '00AWBnDm8h',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX000000',                             --//频道编号
        startPage = 1,
        pageCount = 10,
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/getUserJoinSecretChannelList",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
local function test_manage_secretChannel_users()    --公司管理密频道--管理员更改密频道的里用户的状态(管理密频道)
    local  tab = {
        appKey = appKey,
        adminAccountID = '0s0sJ1sTlx',
        --accountID = '00AWBnDm8h',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX0s0sJ1sTlxqv', 
        curStatus = 1,   
        infoType = 1,
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/manageSecretChannelUsers",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
local function test_modify_secretChannel()       --//修改微频道信息
    local  tab = {
        appKey = appKey,
        accountID = '0s0sJ1sTlx',--// 'kxl1QuHKCD',--//'zdfeqE74Vi', --//'E6ppmuzudN' ,--//'nmjOckC3tS',--// , 'eB6bYE8pkl' ,
        channelNumber = 'AX0s0sJ1sTlxqv',                             --//频道编号
        channelName = "www.baidu.com",
        channelIntro = "www.baidu.com",
        channelCitycode = 1100000,
        channelLogoUrl = "www.baidu.com.jpg",
        channelCatalogID = 100101,
        channelRemark = "www.baidu.com",
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/modifySecretChannel",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end
-- test_apply_secretChannel()
-- test_fetch_secretChannelInfo()
-- test_get_userList_secretChannel()
-- test_join_secretChannel()
-- test_fetch_secretChannel()
-- test_get_secretChannelInfo()
-- test_get_user_online_secretChannel()
-- test_get_user_join_secretChannelList()
-- test_manage_secretChannel_users()
-- test_modify_secretChannel()

local function test_insert_into_sql()       --//修改微频道信息
    local  tab = {
        appKey = appKey,
        startPage = 1,
        pageCount = 30,
    }
    tab['sign'] = gen_sign(tab,secret)
    local req = keys_binary_to_req(host_ip,host_port,"/clientcustom/v2/insertIntoSql",tab)
    print(req)
    local ok,ret = cutils.http(host_ip,host_port,req,#req)
    if not ok or ret == nil then
        print("post data failed!")
        return
    end
    print(ret)
end

test_insert_into_sql()