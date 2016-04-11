--owner: huanglonghan
--time: 2015.08.27
--获取用户设置按键历史信息
local ngx       = require('ngx')
local utils     = require('utils')
local app_utils = require('app_utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local cjson     = require('cjson')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local appfun    = require('appfun')

local userlist_dbname = 'app_usercenter___usercenter'
local custom_dbname   = 'app_custom___wemecustom'

local G = {
   	--查询用户设置按键历史
    sql_get_userkey_history = "(select actionType,'mainVoice'as actionName,customParameter, '' as parameterName,customType,updateTime "..
    							"from userKeyHistory where customParameter != '' and accountID ='%s' %s order by id desc limit 6 ) "..	 
							"union all "..
							"(select actionType,'voiceCommand' as actionName,customParameter, '' as parameterName,customType,updateTime "..
								"from userKeyHistory where customParameter != '' and accountID ='%s' %s order by id desc limit 6 ) ".. 
							"union all "..
							"(select actionType,'groupVoice' as actionName,customParameter, '' as parameterName,customType,updateTime "..
								"from userKeyHistory where customParameter != '' and accountID ='%s' %s order by id desc limit 6) ",
    --查询accountid
    sql_check_accountid = "SELECT 1 FROM userKeyHistory WHERE accountID='%s' limit 2 ", 
    --查询accountid
    sql_check_accountid_in_userlist = "SELECT 1 FROM userList WHERE accountID='%s' limit 2 ", 
    --查询群聊频道信息
    sql_get_secret_channel_info = "select name from checkSecretChannelInfo where number = '%s' " ,
}

local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}

--检查参数中的 %,'
local function check_character( key,parameter )

    local str_res = string.find(parameter,"'")
    local str_tmp = string.find(parameter,"%%")
    if str_res or str_tmp then
        gosay.go_false(url_tab, msg["MSG_ERROR_REQ_ARG"], key)
    end
end 

local actionTypes ={}                --多个时解析出的actionType

local function get_actionType(actionType)
    if not actionType or #actionType == 0 then 
        table.insert(actionTypes,'4')
        table.insert(actionTypes,'5')
    else
       actionTypes = utils.str_split(actionType, ',')
        if type(actionTypes) ~= 'table' then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], 'actionTypes')
        end
    end

    --检查actionType合法性
    for a,v in pairs(actionTypes) do
        ---- 目前actionType : DK_TYPE_VOICE / DK_TYPE_COMMAND / DK_TYPE_GROUP 
        only.log("D",'-->>>-----key:%s--value:%s',a,v)
        local actionType = tonumber(v)
        if not actionType or not 
                    ( actionType == appfun.DK_TYPE_COMMAND 
                    or actionType == appfun.DK_TYPE_GROUP
                    or actionType == appfun.DK_TYPE_VOICE  )then
            only.log('E',string.format("**action_type is error, %s ", 'actionType'))
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'actionType')
        end
    end
end

-->chack parameter
local function check_parameter(args)
    if not app_utils.check_accountID(args['accountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end

    get_actionType(args['actionType'])

    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
    -- safe.sign_check(args, url_tab)
end

---- 对accountID进行数据库校验
local function check_userinfo(accountid)
    --userlist
    local sql_str = string.format(G.sql_check_accountid_in_userlist,accountid)
    local ok_status,user_tab = mysql_api.cmd(userlist_dbname,'SELECT',sql_str)
    if not ok_status or user_tab == nil then
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        only.log('W',"cur accountID is not exit [%s]",accountid)
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'accountID')
    end
    if #user_tab > 1 then       
        -----数据库存在错误,       
        only.log('E','[***] userList accountID recordset > 1 ')     
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])        
    end
    --userkeyhistory
    local sql_str = string.format(G.sql_check_accountid,accountid)
    local ok_status,user_tab = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
    if not ok_status or user_tab == nil then
        only.log('E','connect userlist_dbname failed!')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #user_tab == 0 then
        only.log('W',"cur accountID is not exit [%s]",accountid)
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'User have no history,accountID')
    end

end

---- 获取频道信息
local function get_secret_channel_name( channel_num  )
    local sql_str = string.format(G.sql_get_secret_channel_info,channel_num)
    local ok, tmp_ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
    if ok and tmp_ret and type(tmp_ret) == "table" and #tmp_ret == 1 then
        return tmp_ret[1]['name'] or ''
    end
    return ''
end

--获取用户按键设置历史
local function get_userkey_history_list(accountid)

    --根据action_type构造查询条件
	local str_filter = {
		[3] = " and actionType = '' ",
		[4] = " and actionType = '' ",
		[5] = " and actionType = '' ",
	}
    for a,v in pairs(actionTypes) do 
        only.log("D",'-->>>-----key:%s--value:%s',a,v)
        str_filter[tonumber(v)] = string.format( " and actionType = %d ", tonumber(v) )
    end

    for a,v in pairs(str_filter) do 
        only.log("D",'-->>>-----key:%s--value:%s',a,v)
    end
    
    -- 查询用户设置按键历史
    local sql_str = string.format(G.sql_get_userkey_history, accountid ,str_filter[3], accountid ,str_filter[4], accountid ,str_filter[5] )
    local ok_status,ok_ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)

    only.log("D",string.format('------sql_get_userkey_history:------>>---%s',sql_str))

    if not ok_status or not ok_ret then
        only.log('E','connect custom_dbname failed! %s ' , sql_str )
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        -- return false
    end

    for i = 1, #ok_ret do
        if tostring(ok_ret[i]['customParameter']) == "nil" then
            only.log('D','xxxxx find is nil')
            ok_ret[i]['customParameter'] = ""
        end
        -- DK_TYPE_COMMAND 和 DK_TYPE_GROUP 才有parameterName
        if tonumber(ok_ret[i]['actionType']) == appfun.DK_TYPE_COMMAND and 
            tonumber(ok_ret[i]['customType']) == appfun.VOICE_COMMAND_TYPE_SECRETCHANNEL then
            ok_ret[i]['parameterName'] = get_secret_channel_name(ok_ret[i]['customParameter'])
        elseif tonumber(ok_ret[i]['actionType']) == appfun.DK_TYPE_GROUP and 
            tonumber(ok_ret[i]['customType']) == appfun.GROUP_VOICE_TYPE_SECRETCHANNEL then
            ok_ret[i]['parameterName'] = get_secret_channel_name(ok_ret[i]['customParameter'])
        end
    end
   
    local count = #ok_ret
    local ok_status,ok_str = pcall(cjson.encode,ok_ret)
    if not ok_status or not ok_str then
        only.log('E','cjson encode failed!')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
        -- return false
    end
    only.log('D',string.format("accountid:%s  result:%s ",accountid, ok_str ))
    return true,count,ok_str
end

local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    url_tab['client_host'] = req_ip
    if not req_body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_body'] = req_body

    local args = utils.parse_url(req_body)

    --检查组参数中不能含有 %与'
    for a,v in pairs(args) do 
    	check_character(a,v)
    end

    if not args then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
    end

    url_tab['app_key'] = args['appKey']

    check_parameter(args)

    local accountid  = args['accountID']
    check_userinfo(accountid)

    local ok_status,ok_count,ok_str = get_userkey_history_list(accountid)
    if not ok_status then
        only.log('D',string.format("accountid:%s get user key info failed!", accountid ))
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"actionType query")
    end

    if ok_count == 0 then
        ok_str = "[]"
    end
    local result = string.format('{"count":"%d","list":%s}',ok_count,ok_str)
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],result)

end

safe.main_call( handle )