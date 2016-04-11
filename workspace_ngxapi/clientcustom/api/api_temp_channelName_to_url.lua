-- 2015-10-28
-- Modify  :qiu mao sheng
-- 处理URL取不到文件
-- 处理办法：URL取不到文件的，重新生成，更新数据库同步redis

local msg       = require('msg')
local ngx       = require('ngx')
local safe      = require('safe')
local link      = require('link')
local only      = require('only')
local cjson     = require('cjson')
local utils     = require('utils')
local gosay     = require('gosay')
local appfun    = require('appfun')
local cutils    = require('cutils')
local app_utils = require('app_utils')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local cur_utils = require('clientcustom_utils')

local txt2voice = link.OWN_DIED.http.txt2voice

local channel_dbname  = "app_custom___wemecustom"

local G = {
            -- 1)查询channelNameURL
            sql_get_name_from_check_table = " select idx, name, channelNameURL from checkMicroChannelInfo where 1" ,
            
            -- 2)更新channelNameURL
            sql_update_nameurl = " update checkMicroChannelInfo set channelNameURL = '%s' where idx = '%s'" ,
}
  
local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}

-- 获取频道URL
local function get_channelname_url( channel_name, app_key )
    local tab = {
        appKey = app_key,
        text = channel_name,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    tab['text'] = utils.url_encode(tab['text'])
    return appfun.txt2voice( txt2voice , tab)
end


-- 根据dfsurl获取文件内容下发
local function get_dfs_data_by_http(dfsurl)
    if not dfsurl then return false,'' end 
    local tmp_domain = string.match(dfsurl,'http://[%w%.]+:?%d*/')
    if not tmp_domain then return false,'' end 
    local domain = string.match(tmp_domain,'http://([%w%.]+:?%d*)/')

    local parstring = nil
    local parindex = string.find(dfsurl,"%?")
    if parindex then
        parstring = string.sub(dfsurl,parindex + 1 ,#dfsurl)
        parindex = parindex - 1
    else
        parindex = #dfsurl
    end

    local urlpath = string.sub(dfsurl,#tmp_domain,parindex)

    if not urlpath then return false,'' end
    local data_format =  'GET %s HTTP/1.0\r\n' ..
                        'HOST:%s\r\n\r\n'

    local req = string.format(data_format,urlpath,domain)

    local host = domain
    local port = 80
    if string.find(domain,':') then
        host = string.match(domain,'([%w%.]+)')
        port = string.match(domain,':(%d+)')
        port = tonumber(port) or 80
    end

    local filey_tpe = string.sub(dfsurl,-4,-1)
    if not filey_tpe then 
        filey_tpe = 'amr'
    else
        filey_tpe = string.match(filey_tpe,'%.(%w+)')
    end

    local ok,ret = cutils.http(host,port,req,#req)
    if not ok then
        only.log('E','get dfs data when send get request failed!')
        return false,'','' 
    end

    local split = string.find(ret,'\r\n\r\n')
    if not split then return false , '' end
    local head = string.sub(ret,1,split)
    local file_data = string.sub(ret,split+4,#ret)

    if not app_utils.check_is_amr(file_data,#file_data) then
        -- only.log('E',string.format("data length:%s",#file_data))
        -- only.log('E',string.format("data header:%s",string.sub(file_data,1,20)))
        only.log('E',  "voice file is invalid: %s", dfsurl) 
        return false, '', ''
    end
    return true , filey_tpe, file_data
end

-- 处理URL取不到文件
local function channel_name_to_url()
    local ok ,ret = mysql_api.cmd( channel_dbname, 'select', G.sql_get_name_from_check_table )
    if not ok or not ret or type(ret) ~= 'table' then
        only.log('E', "get channel_name_to_url is FAILED:%s", sql)
        gosay.go_false(url_tab ,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        only.log('E',"channel_name_to_url not exists, %s ", sql)
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    end

    local appKey = '4223273916'
    for k, v in pairs(ret) do

        local ok, type,data = get_dfs_data_by_http( v['channelNameURL'] )
        if not ok then
            only.log('W',string.format(' current channelNameUrl is %s', v['channelNameURL']))

            ---- 微频道名称文本转语音
            local tmp_channelname = string.format("微频道%s", v['name'])
            local ok_status, ok_channelname_url = get_channelname_url( tmp_channelname , appKey )

            if ok_status and ok_channelname_url then
                -- 更新数据库
                local ok = mysql_api.cmd(channel_dbname, 'update', string.format(G.sql_update_nameurl, ok_channelname_url, v['idx']))
                if not ok then
                    gosay.go_false(url_tab ,msg['MSG_DO_MYSQL_FAILED'])
                end
                -- 同时备份，更新redis
                redis_api.cmd('private','set',string.format("%s:channelNameUrl", v['idx']), ok_channelname_url)
            else
                only.log('E',string.format('channelname:%s to voice failed !', tmp_channelname))
            end
        end

    end
end


local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local req_method = ngx.var.request_method

    -- 处理URL取不到文件
    -- 处理办法：URL取不到文件的，重新生成，更新数据库同步redis
    channel_name_to_url()

    gosay.go_success(url_tab , msg['MSG_SUCCESS'])
end

safe.main_call( handle )
