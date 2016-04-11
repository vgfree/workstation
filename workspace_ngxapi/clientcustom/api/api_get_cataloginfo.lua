---- zhangkai.
---- 2014-11-17
---- 获取频道类别表

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
local cur_utils = require('clientcustom_utils')

local userlist_dbname = "app_usercenter___usercenter"
local channel_dbname  = "app_custom___wemecustom"

local G = {
        -- sql_get_cataloginfo = "select  id as number, name ,catalogType from channelCatalog " .. 
        -- 					 -- " where  validity = 1 and catalogType in ( %s )  order by number desc  limit %d ,%d  ",
        -- 					 " where  validity = 1 and catalogType in ( %s )  order by sortIndex limit %d ,%d  ",

        -- 按照频道数量递减排序
        sql_get_cataloginfo =  " select t1.id as number, t1.name, t1.catalogType, t1.logoURL ," ..
        " sum(case when ISNULL(t2.catalogID) then 0 else 1 end ) as sortIndex " ..
        " from channelCatalog t1 left join  %s  t2 on t1.id = t2.catalogID " ..
        " WHERE validity = 1 and t1.catalogType IN ( %s ) GROUP BY t1.id,t1.name,t1.catalogType  order by sortIndex desc LIMIT %d, %d"
}

local url_tab = {
        type_name   = 'system',
        app_key     = '',
        client_host = '',
        client_body = '',
}

-->chack parameter
local function check_parameter(args)

        if args['startPage'] and #args['startPage'] > 0 then 
                if not tonumber(args['startPage']) or string.find(tonumber(args['startPage']),"%.") or tonumber(args['startPage']) <= 0 then
                        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'startPage')
                end
        end

        if args['pageCount'] and #args['pageCount'] > 0 then
                if not tonumber(args['pageCount']) or string.find(tonumber(args['pageCount']),"%.")  or tonumber(args['pageCount']) <= 0 or tonumber(args['pageCount']) > 500 then
                        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'pageCount')
                end
        end

        safe.sign_check(args, url_tab)
end

local function get_cataloginfo( start_index ,page_count , catalog_type )
        local sql_filter            = nil
        local secret_or_micro_table = ''

        local filter_data = {}
        table.insert(filter_data,0)
        if catalog_type == 1 or catalog_type == 2  then
                table.insert(filter_data,catalog_type)
        end

        if catalog_type == 1 then
                secret_or_micro_table = 'checkMicroChannelInfo'
        elseif catalog_type == 2 then
                secret_or_micro_table = 'checkSecretChannelInfo'
        else
                only.log('E','secret_or_micro_table value is ERROR!')
                gosay.go_false(url_info, msg['MSG_ERROR_REQ_ARG'],'catalogType')
        end

        sql_filter = table.concat( filter_data, ", ")

        local sql_str = string.format(G.sql_get_cataloginfo, secret_or_micro_table, sql_filter, start_index, page_count)
        local ok , ret = mysql_api.cmd(channel_dbname,'SELECT',sql_str)
        if not ok or ret == nil or type(ret) ~= "table"  then 
                only.log('E',string.format(" get catalog info failed %s " , sql_str ))
                gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
        end
        return ret
end

-- 运行流程：
-- 1. 获取请求 ip head body method
--      请求方法为POST时，解析表单
-- 2. 将参数传递给get_cataloginfo函数，返回table ret 
-- 3. 调用cjson.encode对ret进行编码,返回结果resut 
-- 4. 将结果用gosay.go_success进行打印
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
                        ---- 解析表单形式 
                        args = utils.parse_form_data(req_head, req_body)
                end
        end

        -- args为空时返回错误信息
        if not args then
                gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
        end

        if not args['appKey'] then
                gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"appKey")
        end

        url_tab['app_key'] = args['appKey']

        check_parameter(args)

        local catalog_type = tonumber(args['channelType']) or 1 

        local start_page = tonumber(args['startPage']) or 1
        local page_count = tonumber(args['pageCount']) or 20
        if start_page < 1 then
                start_page = 1 
        end
        local start_index = ( start_page - 1 ) * page_count

        local ret = get_cataloginfo( start_index ,page_count , catalog_type )
        local count = 0

        local resut = ""
        if not ret or type(ret) ~= "table" or #ret == 0 then
                resut = "[]"
        else
                count = #ret 
                local ok, tmp_ret = pcall(cjson.encode,ret)
                if ok and tmp_ret then
                        resut = tmp_ret
                end
        end
        local str = string.format('{"count":"%s","list":%s}',count,resut)
        if str then
                gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],str)
        else
                gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
        end
end

safe.main_call( handle )
