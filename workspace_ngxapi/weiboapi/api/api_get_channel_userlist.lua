--owner:xuzhongjun 
--Date :2014-05-14
--功能:查询accountid
--参数:channelID

local ngx       = require('ngx')
local utils     = require('utils')
local gosay     = require('gosay')
local only      = require('only')
local msg       = require('msg')
local safe = require('safe')
local cjson     = require('cjson')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')

local weibo_dbname    = 'app_weibo___weibo'

local G = {
    sql_query_accountid = "SELECT accountID FROM userGroupInfo WHERE groupID = '%s' AND validity = 1 AND groupType = 3 ",
    sql_check_channelid = "SELECT validity FROM channelInfo WHERE channelID = '%s' "
}

local url_tab = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->检查参数合法性
local function check_parameter(args)
    --> check channelID
    if not args['channelID'] or #args['channelID'] < 3 or #args['channelID'] > 8 or not utils.is_number(args['channelID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'channelID')
    end
	-->check appKey
    safe.sign_check(args, url_tab)
end

---- 对channel进行数据库校验
local function check_channelinfo(channel_id)
    local sql_str = string.format(G.sql_check_channelid, channel_id)
    local ok_status,channel_tab = mysql_api.cmd(weibo_dbname, 'SELECT', sql_str)
    only.log('D', sql_str)
    if not ok_status or channel_tab == nil  then
        only.log('E', 'connect weibo_dbname failed, query channel info')
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #channel_tab > 1 then 
        -----数据库存在错误,
        only.log('E', '[***] weibo channelinfo recordset > 1')
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end

    if #channel_tab == 1 and (tonumber(channel_tab[1]['validity']) or 0 ) == 0 then
            only.log('E', 'Invalid channelID')
            gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],'validity')
    end
end

local function get_accountid(channelid)
	local sql_str = string.format(G.sql_query_accountid, channelid)
	local ok_status, accountid_tab = mysql_api.cmd(weibo_dbname, 'SELECT', sql_str)
	--数据库错
	if not ok_status or accountid_tab == nil then
        only.log('D', sql_str)
		only.log('E', 'Connect weibo_dbname failed, query accountid')
		gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
	end
    return accountid_tab
end

local function handle()
    local ip = ngx.var.remote_addr
    local body = ngx.req.get_body_data()
    url_tab['client_host'] = ip
    url_tab['client_body'] = body
    if body == nil then 
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_NO_BODY'])
    end
    local args = utils.parse_url(body)
    url_tab['app_key'] = args['appKey']
    check_parameter(args)
    local channel_id = tostring(args['channelID'])

    check_channelinfo(channel_id)
    -- local accountid_tab = get_accountid(channel_id)
	-- local result, ret = {}, {} 
	-- for i = 1, #accountid_tab do
	-- 	result[i] = tostring(accountid_tab[i]['accountID'])
	-- end

	-- ret['accountID'] = result
	-- local ok, accountid_ret = pcall(cjson.encode,ret)
	-- if not ok and not accountid_ret then
	--     only.log('E', 'json encode error')
	-- 	gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
	-- end

    local ok_status,accountid_tab = redis_api.cmd('statistic','smembers', channel_id .. ':channelOnlineUser')
    if not ok_status  then
        only.log('E',string.format("accountid:%s  channelid:%s failed!",accountid,channel_id))
        gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
    end

    local ok,ok_str = pcall(cjson.encode,accountid_tab)
    if not ok then
         gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'],'json encode')
    end
    
    local ok_ret = string.format('{"count":"%d","list":%s}',#accountid_tab,ok_str)
	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], ok_ret)
end

safe.main_call( handle )
