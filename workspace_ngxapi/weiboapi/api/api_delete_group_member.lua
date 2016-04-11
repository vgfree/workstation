
local ngx = require('ngx')
local utils = require('utils')
local app_utils = require('app_utils')
local gosay = require('gosay')
local redis_pool_api = require('redis_pool_api')
local mysql_pool_api = require('mysql_pool_api')
local only = require('only')
local msg = require('msg')
local safe = require('safe')


local sql_fmt = {

    sel_apply_user = "SELECT roleType FROM userGroupInfo WHERE accountID='%s' AND groupID='%s' AND validity=1",

    sel_del_record = "SELECT 1 FROM deleteGroupMemberInfo WHERE applyAccountID='%s' AND groupID='%s' AND createTime>%d",

    sel_del_user = "SELECT groupType,roleType,isDefaultGroup,validity,updateTime FROM userGroupInfo WHERE accountID='%s' AND groupID='%s' AND validity=1",

    ins_del_group_member = "INSERT INTO deleteGroupMemberInfo SET appKey=%s,groupID='%s',applyAccountID='%s',deleteAccountID='%s',callbackURL='%s',createTime=%d",

    update_user = "UPDATE userGroupInfo SET validity=0,isDefaultGroup=0,updateTime=%d  WHERE accountID='%s' AND groupID='%s'",

    sel_group = "SELECT groupID,groupType,roleType,isDefaultGroup,validity,updateTime FROM userGroupInfo WHERE accountID='%s' AND validity=1 order by id limit 1",

    upd_default_group = "UPDATE userGroupInfo SET isDefaultGroup=1,updateTime=%d  WHERE accountID='%s' AND groupID='%s' AND validity=1",

    ins_history = "INSERT INTO userGroupHistoryInfo SET accountID='%s',groupID='%s',groupType=%s,roleType=%s,isDefaultGroup=%s,validity=%s,updateTime=%s",

}

local url_tab = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}

-->chack parameter
local function check_parameter(args)

    safe.sign_check(args, url_tab)

    if not app_utils.check_accountID(args['applyAccountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'applyAccountID')
    end

    if not app_utils.check_accountID(args['deleteAccountID']) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'deleteAccountID')
    end

    --> check groupID
    if not args['groupID'] or #args['groupID'] > 16 then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'groupID')
    end

    local callback_url  = args['callbackURL']
    if callback_url and ((#callback_url > 512) or (not string.match(string.sub(callback_url, 1, 4), 'http'))) then
        gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'callbackURL')
    end

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

    -->check parameter
    check_parameter(args)

    local apply_id = args['applyAccountID']
    local delete_id = args['deleteAccountID']
    local group_id = args['groupID']

    local allow_del_number = 10


    local sql = string.format(sql_fmt.sel_apply_user, apply_id, group_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result==0 then
        only.log('E', string.format("the record of accountID:%s in group:%s is zero", apply_id, group_id))
        gosay.go_false(url_tab, msg["MSG_ERROR_APPLICANT_NOT_EXIST"])
    elseif #result > 1 then
        only.log('S', string.format("the record of accountID:%s is in group:%s more than one, call someone to handle", apply_id, group_id))
        gosay.go_false(url_tab, msg["MSG_ERROR_MORE_RECORD"], 'accountID and groupID')
    end

    local cur_time = os.time()

    if apply_id == delete_id then

        if tonumber(result[1]['roleType']) == 1 then
            gosay.go_false(url_tab, msg['MSG_ERROR_CANNOT_DEL'])
        end

    else

        if tonumber(result[1]['roleType']) ~= 1 then
            gosay.go_false(url_tab, msg['MSG_ERROR_NO_DEL_RIGHT'])
        end

        local cur_year = os.date('%Y', cur_time)
        local cur_month = os.date('%m', cur_time)
        local cur_day = os.date('%d', cur_time)
        local cur_day_timestamp = os.time( { year=cur_year, month=cur_month, day=cur_day, hour=0 } )
        sql = string.format(sql_fmt.sel_del_record, apply_id, group_id, cur_day_timestamp)
        only.log('D', sql)
        local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
        if not ok then
            gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
        end

        if #result > allow_del_number then
            gosay.go_false(url_tab, msg['MSG_ERROR_DEL_TOO_MANY'])
        end

    end

    sql = string.format(sql_fmt.sel_del_user, delete_id, group_id)
    only.log('D', sql)
    local ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    if #result == 0 then
        gosay.go_false(url_tab, msg["MSG_ERROR_DEL_ACCOUNT_ID_NOT_EXIST"])
    elseif #result > 1 then
        only.log('S', string.format("the record of accountID:%s is in group:%s more than one, call someone to handle", apply_id, group_id))
        gosay.go_false(url_tab, msg["MSG_ERROR_MORE_RECORD"], 'accountID and groupID')
    end

    local user_group_info = result[1]

    -- insert infomation into deleteGroupMember
    sql = string.format(sql_fmt.ins_del_group_member, args['appKey'], group_id, apply_id, delete_id, args['callbackURL'] or '', cur_time)
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    -- insert the old information into history
    sql = string.format(sql_fmt.ins_history, delete_id, group_id, user_group_info['groupType'], user_group_info['roleType'], user_group_info['isDefaultGroup'], user_group_info['validity'], user_group_info['updateTime'])
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'insert', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    -- update the information of deleteAccountID, set invalide
    sql = string.format(sql_fmt.update_user, cur_time, delete_id, group_id)
    only.log('D', sql)
    ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'update', sql) 
    if not ok then
        gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
    end

    -- set new default group
    if tonumber(user_group_info['isDefaultGroup']) == 1 then

        sql = string.format(sql_fmt.sel_group, delete_id)
        only.log('D', sql)
        ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'select', sql) 

        if ok and #result~=0 then
            local new_default_group = result[1]
            local sql_tab = {}

            -- insert the old information into history
            sql_tab[1] = string.format(sql_fmt.ins_history, delete_id, new_default_group['groupID'], new_default_group['groupType'], new_default_group['roleType'], new_default_group['isDefaultGroup'], new_default_group['validity'], new_default_group['updateTime'])
            only.log('D', sql_tab[1])

            sql_tab[2] = string.format(sql_fmt.upd_default_group, cur_time, delete_id, new_default_group['groupID'])
            only.log('D', sql_tab[2])
            ok, result = mysql_pool_api.cmd('app_weibo___weibo', 'affairs', sql_tab) 
            if not ok then
                gosay.go_false(url_tab, msg['MSG_DO_MYSQL_FAILED'])
            end

            redis_pool_api.cmd('private', 'set', delete_id .. ':defaultGroup', group_id)
        else
            redis_pool_api.cmd('private', 'del', delete_id .. ':defaultGroup')
        end

    end

    gosay.go_success(url_tab, msg['MSG_SUCCESS'])
end


safe.main_call( handle )
