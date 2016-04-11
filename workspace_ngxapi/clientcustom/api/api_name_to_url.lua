

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
local cur_utils = require('clientcustom_utils')
local appfun    = require('appfun') 

local txt2voice = link.OWN_DIED.http.txt2voice

local channel_dbname  = "app_custom___wemecustom"

local G = {
            sql_get_name_from_check_table = " select idx ,name from checkMicroChannelInfo where channelNameURL = '' limit 100 " ,
            sql_update_nameurl = " update checkMicroChannelInfo set channelNameURL = '%s' where idx = '%s'" ,
}
  
local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}

local function get_channelname_url( channel_name ,app_key )
    local tab = {
        appKey = app_key,
        text = channel_name,
    }
    tab['sign'] = app_utils.gen_sign(tab)
    tab['text'] = utils.url_encode(tab['text'])
    return appfun.txt2voice( txt2voice , tab)
end

local function function_name()
    local ok ,ret = mysql_api.cmd(channel_dbname ,'select' ,G.sql_get_name_from_check_table)
    if not ok or not ret then
        gosay.go_false(url_tab ,msg['MSG_DO_MYSQL_FAILED'])
    end
    if #ret == 0 then
        gosay.go_success(url_tab, msg['MSG_SUCCESS'])
    end
    local appKey = '4223273916'
    for k ,v in pairs(ret) do 
        ---- 微频道名称文本转语音
        local tmp_channelname = string.format("微频道%s" ,ret[k]['name'])
        ok_status, ok_channelname_url = get_channelname_url( tmp_channelname , appKey )
        -- if not ok_status or not ok_channelname_url then
        --     only.log('E',string.format(' channel_name:%s  txt2voice failed !' , tmp_channelname  ) )
        --     gosay.go_false(url_tab, msg['MSG_ERROR_TXT2VOICE_FAILED'])
        -- end
        if ok and ok_channelname_url then
            local ok = mysql_api.cmd(channel_dbname ,'update' ,string.format(G.sql_update_nameurl ,ok_channelname_url ,v['idx']))
            if not ok then
                gosay.go_false(url_tab ,msg['MSG_DO_MYSQL_FAILED'])
            end
            redis_api.cmd('private','set',string.format("%s:channelNameUrl",v['idx']),ok_channelname_url)
        end
    end
    return true
end


local function handle()
    local req_ip   = ngx.var.remote_addr
    local req_head = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local req_method = ngx.var.request_method

    local ok = function_name()
    only.log('D' ,ok)
    if ok then
        only.log('D' ,"abcdefghijklmnopqr")
        gosay.go_success(url_tab , msg['MSG_SUCCESS'])
    else 
        only.log('E' ,"\r\n------zktest------")
        gosay.go_false(url_tab ,msg['MSG_DO_MYSQL_FAILED'])
    end
end

safe.main_call( handle )
