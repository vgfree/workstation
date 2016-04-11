---- zhangerna
---- 2014-12-3
---- 修改群聊频道的详细信息

local ngx       = require('ngx')
local utils     = require('utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local app_utils = require('app_utils')
local cur_utils = require('clientcustom_utils')
local appfun    = require('appfun')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local url_tab = {                                       
    type_name   = 'system',                         
    app_key     = '',
    client_host = '',
    client_body = '',
}

local G = {
            sql_check_accountID = "SELECT 1 from userList where accountID = '%s'",
            sql_get_cataloginfo = "SELECT name FROM channelCatalog WHERE catalogType in(0,2) and id = %s  limit 1",

            sql_check_is_admin = "SELECT idx,name,introduction,cityCode,catalogID,logoURL,openType,keyWords, isVerify FROM checkSecretChannelInfo WHERE accountID = '%s' and number = '%s' and channelStatus = 1",
           
            sql_check_repeatModif = " SELECT 1 from checkSecretChannelInfo where number = '%s' and name = '%s' and introduction = '%s' and "..
                                        " cityCode = %d and catalogID = %d and logoURL = '%s' and accountID = '%s' and openType = %d and keyWords = '%s' and channelStatus = 1",

             sql_modify_channelinfo = "update checkSecretChannelInfo set name = '%s',introduction = '%s',"..
                                        " cityCode = %d,cityName = '%s',catalogID = %d,catalogName = '%s',logoURL = '%s',"..
                                        " openType = %s,updateTime = unix_timestamp() ,keyWords = '%s', isVerify = %s " .. 
                                        " where number = '%s' and accountID = '%s' and channelStatus = 1  ",
            --保存到历史记录
            sql_save_modif_history  = "insert into checkSecretChannelInfoHistory(idx,number,name,introduction,cityCode,cityName,catalogID,catalogName,logoURL,accountID,inviteUniqueCode, " ..
                                          "openType,appKey,updateTime,keyWords)  select idx,number,name,introduction,cityCode,cityName,catalogID,catalogName, " ..
                                          "logoURL,accountID,inviteUniqueCode,openType,'%s' as appKey ,updateTime , keyWords from checkSecretChannelInfo where number = '%s' and accountID = '%s' and channelStatus = 1",

            sql_update_userAdminInfo = "update userAdminInfo set modify = modify + 1 , updateTime = unix_timestamp() where accountID = '%s'",

}


local function check_parameter(args)
    if  not app_utils.check_accountID(args['accountID'])  then
        only.log('E',"accountID is error")
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'accountID')
    end

    if not args['channelNumber'] or #tostring(args['channelNumber']) < 5 or not tonumber(args['channelNumber']) then
        only.log('E',"[---------]channelNumber error ")
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelNumber')
    end

    if args['channelName'] and #args['channelName'] > 0 then
        local channel_name = args['channelName']
        if app_utils.str_count(channel_name) < 2 or app_utils.str_count(channel_name) > 16 or string.find(channel_name,"'")  then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelName')
        end
    end

    if args['channelOpenType'] and #tostring(args['channelOpenType']) > 0 then
        if not tonumber(args['channelOpenType']) or #tostring(args['channelOpenType']) == 0  or not (tonumber(args['channelOpenType']) == 0 or tonumber(args['channelOpenType']) == 1) or string.find(args['channelOpenType'],"'") or string.find(args['channelOpenType'],"%.") then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelOpenType') 
        end 
    end 

    if args['channelIntro'] and #tostring(args['channelIntro']) > 0 then
        local channel_intro = args['channelIntro']
        if app_utils.str_count(channel_intro) < 1 or app_utils.str_count(channel_intro) > 128  or string.find(channel_intro,"'") then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelIntroduction')
        end
    end

    if args['channelCitycode'] and #tostring(args['channelCitycode']) > 0 then
       if not utils.is_number(args['channelCitycode']) or not ( #tostring(args['channelCitycode']) == 6 or
                         (tonumber(args['channelCitycode']) or -1) == 0 ) or string.find(args['channelCitycode'],"%.") then

           only.log('E',"channelCitycode is error")
           gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelCitycode')
       end
    end

    if args['channelCatalogID'] and #tostring(args['channelCatalogID']) > 0 then
       if not utils.is_number(args['channelCatalogID']) or #tostring(args['channelCatalogID']) < 6 or #tostring(args['channelCatalogID'])  > 10 then
           gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelCatalogID')
       end
    end
    if args['channelKeyWords'] and #tostring(args['channelKeyWords']) > 0 then
        if string.find(args['channelKeyWords'],"'") then
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
        end

        if #args['channelKeyWords'] > 0 then
            local tab = utils.str_split(args['channelKeyWords'],",")
            if #tab > 5 then
                gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
            end

            for k , v in pairs(tab) do
                if app_utils.str_count( v ) > 4 then
                    gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelKeyWords')
                end
            end
        end
    end
    
   local err_status = false
   local logurl = args['channelLogoUrl']
   if logurl and #logurl > 0  then
       if string.find(logurl,"'") or #tostring(logurl) > 128 then
           gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelLogoUrl')
       end
       local tmp_logurl = string.lower(args['channelLogoUrl'])
       if (string.find(tmp_logurl,"http://")) == 1 then
           local suffix = string.sub(tmp_logurl,-5)
           if suffix then 
               if  (string.find(suffix,"%.png")) or (string.find(suffix,"%.jpg")) or
                    (string.find(suffix,"%.jpeg"))  or (string.find(suffix,"%.gif")) or
                    (string.find(suffix,"%.bmp"))  or (string.find(suffix,"%.ico"))  then
                    err_status = true
                end
            end
        end
    else
        err_status = true
    end
    if not err_status then
        only.log('E',string.format("channelLogoUrl is error,%s",logurl))
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelLogoUrl')
    end
    -- safe.sign_check(args,url_tab)
    -- 20150720
    -- 为io部门使用
    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

local function get_secret_channel_id( channel_num )
    local ok, channelid = redis_api.cmd('private','get', channel_num .. ":channelID")
    if not ok or not channelid or #channelid < 9 then
        return false
    end
    return channelid
end

local function  check_repeatModify(accountID,
                                channelNumber,
                                channelName,
                                channelIntro,
                                channelCitycode,
                                channelCatalogID,
                                channelLogoUrl,
                                openType,
                                keyWords)

    local sql_str = string.format(G.sql_check_repeatModif,
                                      channelNumber,channelName,
                                      channelIntro,channelCitycode,
                                      channelCatalogID,channelLogoUrl,
                                      accountID,openType,keyWords)

    local ok ,str = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not str then
        only.log('E',string.format("connect mysql failed,sql_str :%s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #str == 1 then
        only.log('E','cur user repeat modify[%s]',sql_str)
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_REP_SUBMITTED'])
    end
end

local function check_accountID(accountID,channelNumber)
    --判断当前用户是否存在
    local sql_str = string.format(G.sql_check_accountID,accountID) 
    local ok,ret  = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',string.format("userList tab connect failed!sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',string.format("cur user is not exit,sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_ERROR_ACCOUNT_ID_NOT_EXIST'])
    end
    if #ret > 1 then
        only.log('E',"[*****]check_accountID SYSTEM_ERROR ")
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
    
end

local function get_channelInfo(accountID,channelNumber)
    local sql_str = string.format(G.sql_check_is_admin,accountID,channelNumber)
    local ok, ret  = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret or type(ret) ~= "table" then
        only.log('E',"get_channelInfo mysql failed [%s]",sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',string.format("cur user is not admin or channelNumber is error, %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_ERROR_USER_CHANNEL_IDX'])
    end
    
    if #ret > 1 then
        only.log('E',"[*****]check_accountID SYSTEM_ERROR ,%s ", sql_str )
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end

    return ret[1]['idx'],ret[1]['name'],ret[1]['introduction'],
                    ret[1]['cityCode'],ret[1]['catalogID'],
                    ret[1]['logoURL'],ret[1]['openType'],
                    ret[1]['keyWords'],ret[1]['isVerify']
end 

local function get_catalogname_and_cityname(channelCitycode,channelCatalogID)
    --获取类别名称
    local sql_str = string.format(G.sql_get_cataloginfo,channelCatalogID)
    local ok,ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
    if not ok or not ret then
        only.log('E',string.format("get_cataloginfo tab connect failed,sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',string.format("get_cataloginfo tab is empty,sql_str is %s",sql_str))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    --获取城市名称
    local  ok ,cityname = nil
    local citycode = tonumber(channelCitycode) or ''
    if citycode then
        if #tostring(citycode) == 6 then
            ok,cityname = appfun.get_city_name_by_city_code(citycode)
            if not ok or not cityname then
                only.log('E',string.format('get cityname failed!citycode is %s',channelCitycode))
                gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'get cityname failed')
            end
        elseif citycode == 0 then
            cityname = '全国'
        else
            only.log('E',"##channelCitycode %s",citycode)
            gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'channelCitycode')
        end
    end
    return ret[1]['name'],cityname
end

local function modify_channelInfo(accountID,
                                channelNumber,
                                channelName,
                                channelIntro,
                                channelCitycode,
                                channelLogoUrl,
                                channelCatalogID,
                                channelOpenType,
                                appKey,
                                channelIdx,
                                keyWords,
                                isVerify)

    local catalogname ,cityname= get_catalogname_and_cityname(channelCitycode,channelCatalogID)
    local tab = {}
    local sql_str = string.format(G.sql_modify_channelinfo,
                                              channelName,
                                              channelIntro,
                                              channelCitycode,
                                              cityname,
                                              channelCatalogID,
                                              catalogname,
                                              channelLogoUrl,
                                              channelOpenType,
                                              keyWords,
                                              isVerify,
                                              channelNumber,
                                              accountID)

    table.insert(tab,sql_str)
    local sql_str = string.format(G.sql_save_modif_history,appKey,channelNumber,accountID)
    table.insert(tab,sql_str)
    local sql_str = string.format(G.sql_update_userAdminInfo,accountID)
    table.insert(tab,sql_str)


    only.log('W',string.format("debug info,sql_str is %s",table.concat(tab,"\r\n")))

    local ok,ret = mysql_api.cmd(channel_dbname,'AFFAIRS',tab)
    if not ok or not ret then
        only.log('E',string.format("update checkapplyinfor connect failed,sql_str is %s",table.concat(tab,"\r\n")))
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    ---- 频道的创建者 owner 
    ---- 频道的创建时间 createTime 
    ---- 频道的最大容量 capacity
    redis_api.cmd('private','hmset',string.format("%s:userChannelInfo",channelIdx), 
                              "owner", accountID , 
                              "openType", channelOpenType ,
                              "cityCode", channelCitycode ,
                              "cityName", cityname ,
                              "catalogID", channelCatalogID ,
                              "catalogName", catalogname ,
                              "channelName", channelName,
                              "introduction", channelIntro )
    return true
end

local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local req_method = ngx.var.request_method

    url_tab['client_host'] = req_ip
    if not req_body  then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_body'] = req_body

    local args = nil
    if req_method == 'POST' then
        local boundary = string.match(req_head, 'boundary=(..-)\r\n')
        if not boundary then
            args = ngx.decode_args(req_body)
        else
            args = utils.parse_form_data(req_head,req_body)
        end
    end

    if not args then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'args')
    end
    if not args['appKey'] then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'appKey')
    end

    url_tab['app_key'] = tonumber(args['appKey'])

    check_parameter(args)
    
    local appKey = args['appKey']
    local accountID = args['accountID']
    local channelNumber = args['channelNumber']
    local channelName,channelIntro,channelLogoUrl,channelKeyWords
    local channelCitycode,channelCatalog,channelOpenType

    local channelIsVerify
  
    if args['channelName'] and #args['channelName'] > 1 then
        channelName = args['channelName']
    end
    if args['channelIntro'] and #args['channelIntro'] > 1 then
        channelIntro = args['channelIntro']
    end
    if args['channelCitycode'] and tonumber(args['channelCitycode']) then
        channelCitycode = args['channelCitycode']
    end
    if args['channelLogoUrl'] and #tostring(args['channelLogoUrl']) > 1 then
        channelLogoUrl = args['channelLogoUrl']
    end
    if args['channelCatalogID'] and tonumber(args['channelCatalogID']) then
        channelCatalogID = args['channelCatalogID']
    end
    if args['channelOpenType'] and tonumber(args['channelOpenType']) then
        channelOpenType = args['channelOpenType']
    end
    if args['channelKeyWords'] and #args['channelKeyWords'] > 1 then
        channelKeyWords = args['channelKeyWords']
    end

    if args['channelIsVerify'] and tonumber(args['channelIsVerify']) and #args['channelIsVerify'] > 0 then
        local tmp_val = tonumber(args['channelIsVerify'])
        if tmp_val == 0 or tmp_val == 1 then
            channelIsVerify = tmp_val
        end
    end

    check_accountID (accountID,channelNumber)

    ---- 得到频道详情 同时检查用户是否为admin
    local channelIdx,name,introduction,cityCode,catalogID,logoURL,openType,keyWords, isVerify = get_channelInfo(accountID,channelNumber)

    -- check_repeatModify(accountID ,channelNumber ,
    --                                     channelName or name,channelIntro or introduction,
    --                                     channelCitycode or cityCode,
    --                                     channelCatalogID or catalogID,channelLogoUrl or logoURL,
    --                                     channelOpenType or openType,
    --                                     channelKeyWords or keyWords)
  
    local ok = modify_channelInfo(accountID,
                                    channelNumber,
                                    channelName or name,
                                    channelIntro or introduction,
                                    channelCitycode or cityCode,
                                    channelLogoUrl or logoURL,
                                    channelCatalogID or catalogID,
                                    channelOpenType or openType,
                                    appKey,
                                    channelIdx ,
                                    channelKeyWords or keyWords,
                                    channelIsVerify or isVerify)
    if ok then
        gosay.go_success(url_tab,msg['MSG_SUCCESS'])
    else
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
end

safe.main_call( handle )
