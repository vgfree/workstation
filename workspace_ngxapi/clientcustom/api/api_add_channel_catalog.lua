
-- huanglonghan
-- 2015.8.11
-- 增加频道分类

local msg	 = require('msg')
local safe	 = require('safe')
local only	 = require('only')
local gosay	 = require('gosay')
local utils	 = require('utils')
local mysql_api	 = require('mysql_pool_api')

local url_info = {
        type_name = 'system',
        app_key = nil,
        client_host = nil,
        client_body = nil
}

local channel_catalog_dbname = 'app_custom___wemecustom'

local G = {
        -- 查找最大ID
        sql_select_channelId = "SELECT  id  FROM channelCatalog WHERE catalogType = '%s' ORDER BY id desc limit 1 ",

        -- 查找最大sortIndex
        sql_select_sortIndex = "SELECT  sortIndex  FROM channelCatalog WHERE catalogType = '%s' ORDER BY sortIndex desc limit 1 ",

        -- 查找频道分类name
        sql_select_catalogName = "SELECT 1 FROM channelCatalog WHERE name = '%s' and catalogType = '%s' limit 1 ",

        -- 插入新的频道分类信息
        sql_insert_channelCatalog = "INSERT INTO channelCatalog (id ,name ,introduction ,catalogType ,validity ,sortIndex ,logoURL,createTime,updateTime)"..
        " VALUE ('%s','%s','%s','%s','%s','%s','%s','%s','%s') ",
}

--检查参数中的 %,'
local function check_character( key,parameter )

        local str_res = string.find(parameter,"'")
        local str_tmp = string.find(parameter,"%%")
        if str_res or str_tmp then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], key)
        end
end 

local function check_parameter(args)

        -- catalogtype 不为空
        if not args['catalogType'] or #args['catalogType'] > 0 and (tonumber(args['catalogType']) ~=1 and tonumber(args['catalogType']) ~= 2 ) then
                only.log('E','catalogType value is ERROR!')
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],'catalogType ')
        end

        -- logoURl最大为128
        if args['logoURL'] and (  #args['logoURL'] > 128 ) or ( #args['logoURL'] > 0 and string.find(args['logoURL'],"http://") ~= 1 ) then
                only.log('E','logoURL %s is ERROR!',args['logoURL'])
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'logoURL ')
        end

        --可以为nil 不为空时只能为数字
        if args['sortIndex'] and (  #args['sortIndex'] > 0 and not tonumber(args['sortIndex']) ) then 
                only.log('E','sortIndex %s is ERROR!',args['sortIndex'])
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'sortIndex')
        end

        -- 频道分类名最大10个汉字
        if not args['catalogName'] or #args['catalogName'] == 0 or #args['catalogName'] > 30 then 
                only.log('E', "catalogName is error %s", args['catalogName'])
                gosay.go_false(url_info,  msg['MSG_ERROR_REQ_ARG'],'catalogName ')
        end

        -- 不能为空 只能为1或0
        if not args['validity'] or #args['validity'] > 0 and  (tonumber(args['validity']) ~=0 and tonumber(args['validity']) ~= 1 )  then 
                only.log('E', "validity is error %s", args['validity'])
                gosay.go_false(url_info,  msg['MSG_ERROR_REQ_ARG'],'validity ')
        end

        --检查签名
        safe.sign_check(args,url_info)
end

local function addChannelCatalog(args)
        -- 查找最大ID
        local str_sql = string.format(G.sql_select_channelId, args['catalogType'])

        local ok,id = mysql_api.cmd(channel_catalog_dbname, "select", str_sql)
        if not ok or not id then
                only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        -- 查找最大sortIndex
        local str_sql = string.format(G.sql_select_sortIndex, args['catalogType'])

        local ok,sortIndex = mysql_api.cmd(channel_catalog_dbname, "select", str_sql)
        if not ok or not sortIndex then
                only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        local sqlIntroduction = ''
        if  args['introduction'] and #args['introduction'] > 0  then 
                sqlIntroduction = args['introduction'] 
        end

        --不输入参数则取最大sortIndex加1 
        local sqlSortIndex = ''
        if not args['sortIndex'] or #args['sortIndex'] == 0 then 
                sqlSortIndex = sortIndex[1]['sortIndex'] + 1
        elseif #args['sortIndex'] > 0 then 
                sqlSortIndex =  args['sortIndex']
        end

        local sqlLogoURL = args['logoURL'] or ''

        --插入新的分类
        --sql_insert_channelCatalog = "INSERT INTO catalogType (id ,name ,introduction ,catalogType ,validity ,sortIndex ,logoURL,createTime,updateTime)"..
        --                              " VALUE ('%s','%s','%s','%s','%s','%s','%s','%s','%s')
        local str_sql = string.format(G.sql_insert_channelCatalog,id[1]['id'] + 1,
        args['catalogName'],
        sqlIntroduction,
        args['catalogType'],
        args['validity'],
        sqlSortIndex,
        sqlLogoURL,
        os.time(),
        os.time())
        only.log('D',str_sql)
        local ok = mysql_api.cmd(channel_catalog_dbname, "insert", str_sql)
        if not ok then
                only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        return id[1]['id'],sqlIntroduction,sqlSortIndex,sqlLogoURL
end

local function handle()
        local req_ip = ngx.var.remote_addr
        local req_body = ngx.req.get_body_data()

        if not req_body then
                gosay.go_false(url_info,msg['MSG_ERROR_REQ_NO_BODY'])
        end
        url_info['client_host'] = req_ip
        url_info['client_body'] = req_body

        only.log('D','---%s',req_body)


        local args = utils.parse_url(req_body)
        if not args then
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],"args")
        end

        url_info['app_key'] = args['appKey']

        --检查组参数中不能含有 %与'
        for a,v in pairs(args) do 
                check_character(a,v)
        end

        check_parameter(args)

        -- 检测频道分类名是否已经存在
        local str_sql = string.format(G.sql_select_catalogName, args['catalogName'],args['catalogType'])

        local ok,ret = mysql_api.cmd(channel_catalog_dbname, "select", str_sql)
        if not ok or not ret then
                only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        if #ret == 1 or #ret > 1 then 
                only.log('E', "exist channel name %s",args['catalogName'])
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],'exist channel name')
        end

        local id,introduction,sortIndex,logoURL = addChannelCatalog(args)

        -- 返回结果信息
        local result = {
                catalogID = id + 1,
                catalogName = args['catalogName'],
                introduction = introduction,
                catalogType = args['catalogType'],
                validity = args['validity'] ,
                sortIndex = sortIndex,
                logoURL = logoURL,
        }
        local ok,result = utils.json_encode(result)
        if not ok then 
                only.log('E','table transit json_encode error ')
        end

        gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'],result)

end

safe.main_call( handle )
