-- huanglonghan
-- 2015.8.11
-- 修改频道分类

local msg	 = require('msg')
local safe	 = require('safe')
local only	 = require('only')
local gosay	 = require('gosay')
local utils	 = require('utils')
local mysql_api	 = require('mysql_pool_api')
local redis_api = require("redis_pool_api")

local url_info = {
        type_name = 'system',
        app_key = nil,
        client_host = nil,
        client_body = nil
}

local channel_catalog_dbname = 'app_custom___wemecustom'

local G = {

        --查找频道类型
        sql_select_channelType = "SELECT  catalogType  FROM channelCatalog WHERE id = '%s' ",

        --查找频道类型名
        sql_select_channelName = "SELECT  1  FROM channelCatalog WHERE name = '%s' and catalogType = '%s' ",

        --根据catalogID查找idx
        sql_select_channel_idx = "SELECT idx FROM %s WHERE catalogID = '%s' ",

        -- 更新频道分类
        sql_update_channel_catalog = "UPDATE channelCatalog SET %s ,updateTime ='%s' WHERE id = '%s' ",

        -- 更新微频道和群聊平道相关频道分类名
        sql_update_channel = "UPDATE %s SET catalogName = '%s' ,updateTime ='%s' WHERE catalogID = '%s' ",

}

--检查参数中不能包含 %与'
local function check_character( key,parameter )

        local str_res = string.find(parameter,"'")
        local str_tmp = string.find(parameter,"%%")
        if str_res or str_tmp then
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], key)
        end
end 

local function check_parameter(args)

        -- id不能为空
        if not args['catalogID'] or (args['catalogID'] and #args['catalogID'] == 0) then
                only.log('E','%s is error!','catalogID' )
                gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"],'catalogID')
        end

        -- 频道分类名不能大于10个汉字
        if  args['catalogName'] and #args['catalogName'] ~= 0 and #args['catalogName'] > 30 then 
                only.log('E', "catalogName is error  %s", args['catalogName'])
                gosay.go_false(url_info,  msg['MSG_ERROR_REQ_ARG'],'catalogName')
        end

        -- sortIndex 只能为数字
        if  args['sortIndex']  and #args['sortIndex'] ~= 0 and not tonumber(args['sortIndex']) then 
                only.log('E', "sortIndex is not number %s", args['sortIndex'])
                gosay.go_false(url_info,  msg['MSG_ERROR_REQ_ARG'],'sortIndex')
        end

        --检测url合法性
        if  args['logoURL'] and #args['logoURL'] ~= 0 and (string.find(args['logoURL'],"http://")) ~= 1 then
                only.log('E', "logoURL is error  %s", args['logoURL'])
                gosay.go_false(url_info,  msg['MSG_ERROR_REQ_ARG'],'logoURl')
        end

        --检查签名
        safe.sign_check(args,url_info)
end

local function gen_sql_str(catalogName,catalogType,logoURL,validity,introduction,sortIndex,channelCatalogType)
        -- 分类名
        local str_sql_catalogName = ''
        if  catalogName and #catalogName > 0 then 
                -- 查询频道名是否已经存在
                local str_sql = string.format(G.sql_select_channelName,catalogName,channelCatalogType)    

                local ok,ret = mysql_api.cmd(channel_catalog_dbname, "select", str_sql)
                if not ok then
                        only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
                end

                if #ret == 1 then
                        only.log('E', "catalogName is exist or error ret:%s ", #ret)
                        gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],'catalogName is exist or error')
                end

                str_sql_catalogName = string.format("name='%s',", catalogName)
        end 

        --分类类型
        local str_sql_catalogType = ''
        if  catalogType and #catalogType > 0 then 
                str_sql_catalogType = string.format("catalogType='%s',", catalogType)
        end 

        --logourl
        local str_sql_logoURL = ''
        if logoURL  and #logoURL > 0 then 
                str_sql_logoURL = string.format("logoURL='%s',", logoURL)
        end 

        --频道分类介绍
        local str_sql_introduction = ''
        if introduction  and #introduction > 0 then 
                str_sql_introduction = string.format("introduction='%s',", introduction)
        end

        -- 排序索引
        local str_sql_sortIndex = ''
        if sortIndex  and #sortIndex > 0 then 
                str_sql_sortIndex = string.format("sortIndex='%s',", sortIndex)
        end 

        --频道分类有效性
        local str_sql_validity = ''
        if  validity and #validity > 0 then 
                str_sql_validity = string.format("validity='%s',", validity)
        end 

        --组合sql语句
        gen_sql = string.format("%s%s%s%s%s ",str_sql_catalogName,str_sql_logoURL,str_sql_validity,str_sql_introduction,str_sql_sortIndex)
        return string.gsub(gen_sql,', ','')
end

local function updatedb(args)

        local channelCatalogType = nil
        local secret_or_micro_table=''

        --判断catalogtype是否修改
        local str_sql = string.format(G.sql_select_channelType,args['catalogID'])
        local ok,ret = mysql_api.cmd(channel_catalog_dbname, "select", str_sql)
        if not ok then
                only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
        end

        if #ret ~= 1 then
                only.log('E', "catalogType error ret:%s ", #ret)
                gosay.go_false(url_info,msg['MSG_ERROR_REQ_ARG'],'catalogType')
        end

        channelCatalogType = tonumber(ret[1]['catalogType']) 	

        --根据频道类型选择要更新的表
        if tonumber(channelCatalogType) == 1 then
                secret_or_micro_table = 'checkMicroChannelInfo'
        elseif tonumber(channelCatalogType) == 2 then
                secret_or_micro_table = 'checkSecretChannelInfo'
        else
                only.log('E','secret_or_micro_table value is ERROR!')
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],'catalogType')
        end

        --根据输入的参数选择要更改的字段
        local gen_sql = gen_sql_str(args['catalogName'],args['catalogType'],args['logoURL'],args['validity'],args['introduction'], args['sortIndex'],channelCatalogType)
        --如果不修改分类名则不需要修改其他表
        if not args['catalogName'] or #args['catalogName'] == 0 then

                local str_sql = string.format(G.sql_update_channel_catalog,gen_sql,os.time(),args['catalogID'])

                only.log('D', str_sql)
                local ok,ret = mysql_api.cmd(channel_catalog_dbname, "update", str_sql)
                if not ok then
                        only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
                end

        else 
                --更新道频道分类名
                local sql_tab = {
                        [1] = string.format(G.sql_update_channel_catalog, gen_sql,os.time(), args['catalogID']),
                        [2] = string.format(G.sql_update_channel, secret_or_micro_table, args['catalogName'], os.time(), args['catalogID'])
                }

                only.log('D', sql_tab[1])
                only.log('D', sql_tab[2])
                local ok, result = mysql_api.cmd(channel_catalog_dbname, 'affairs', sql_tab)
                if not ok then
                        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
                end

                --查找idx
                local str_sql = string.format(G.sql_select_channel_idx,secret_or_micro_table,args['catalogID'])

                only.log('D', str_sql)
                local ok,ret = mysql_api.cmd(channel_catalog_dbname, "select", str_sql)
                if not ok then
                        only.log('E', "[***] connect [%s] failed!", channel_catalog_dbname)
                        gosay.go_false(url_info, msg['MSG_DO_MYSQL_FAILED'])
                end

                --根据idx修改redis
                if  ret and type(ret) == 'table' and #ret > 0 then
                        for a,v in pairs(ret) do 
                                local ok,ret = redis_api.cmd('private','hset',string.format("%s:userChannelInfo",v['idx']), 
                                "catalogName", args['catalogName'])
                        end 
                        only.log('D','ret:%s',#ret)
                end

        end
end

local function handle()
        local req_ip = ngx.var.remote_addr
        local req_body = ngx.req.get_body_data()

        if not req_body then
                gosay.go_false(url_info,msg['MSG_ERROR_REQ_NO_BODY'])
        end
        url_info['client_host'] = req_ip
        url_info['client_body'] = req_body

        local args = utils.parse_url(req_body)
        if not args then
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],"args")
        end
        if not args['appKey'] then
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],"appKey")
        end

        url_info['app_key'] = args['appKey']

        for a,v in pairs(args) do 
                check_character(a,v)
        end

        check_parameter(args)

        --更新数据库
        updatedb(args)

        local return_result = {
                catalogID = args['catalogID'],
                catalogName = args['catalogName'] or '',
                introduction = args['introduction'] or '',
                validity = args['validity'] or '',
                sortIndex = args['sortIndex'] or '',
                logoURL = args['logoURL'] or '',
        }
        local ok,return_result = utils.json_encode(return_result)
        if not ok then 
                only.log('E','table transit json_encode error ')
        end
        gosay.go_success(url_info, msg['MSG_SUCCESS_WITH_RESULT'],return_result)

end

safe.main_call( handle )
