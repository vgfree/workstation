--jiang z.s. 
--2014-07-28
-- 临时频道的操作
-- 1: 释放(允许WEME使用++按键)
-- 2: 禁言(禁止WEME使用++按键)
-- 3: 解散临时频道

local ngx       = require('ngx')
local utils     = require('utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe      = require('safe')
local link      = require('link')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')



local url_tab = {
    type_name   = 'system',
    app_key     = '',
    client_host = '',
    client_body = '',
}


local default_channel = "10086"


-->chack parameter
local function check_parameter(args)

    if not args['tempChannelID'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'tempChannelID')
    end

    local tmp = string.match(args['tempChannelID'],'%d+')
    if not tmp or tostring(tmp) ~= args['tempChannelID'] then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'tempChannelID')
    end

    if #tmp < 5 or #tmp > 8 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'tempChannelID length')
    end

    safe.sign_check(args, url_tab, 'accountID', safe.ACCESS_WEIBO_INFO)
end

---- 设置声音模式
---- 0 禁言,禁止WEME说话给其他WEME听见
---- 1 默认,允许WEME说话给其他WEME听见

local function get_channel_sound_mode( tmp_channel_id, val )
    local ok,ret =  redis_api.cmd('private','get',tmp_channel_id .. ":channelSoundMode")
    if ok and ret then
        return tonumber(ret) or 1
    end
    return 1
end


local function handle()
    url_tab['client_host']   = ngx.var.remote_addr

    local req_body = ngx.req.get_body_data()
    if not req_body  then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    url_tab['client_body'] = req_body

    -- local args = utils.parse_url(req_body)
    local args = ngx.decode_args(req_body)
    if not args then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],"args")
    end
    url_tab['app_key'] = args['appKey']
    check_parameter(args)


    local tmp_channel_id = args['tempChannelID']

    -- 临时频道的操作
    -- 1: 释放(允许WEME使用++按键) default 
    -- 2: 禁言(禁止WEME使用++按键)

    local ret_status = get_channel_sound_mode(tmp_channel_id)
    local result = 1
    if ret_status ~= 1 then
        result = 2
    end
    gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'],result)
end
safe.main_call( handle )