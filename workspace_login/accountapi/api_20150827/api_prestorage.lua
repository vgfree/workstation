--->owner:zhangerna
--->time:2014-11-15

local ngx = require('ngx')
local only = require('only')
local utils = require('utils')
local gosay = require('gosay')
local msg = require('msg')
local link = require('link')
local mysql_api = require('mysql_pool_api')
local safe = require('safe')


local app_mirtalk_db = 'app_ident___ident'
local app_config_db = 'app_mirrtalk___config_gc'
local app_s9test_db = 'app_sendBinaryStatus___s9test_gc'
local app_feedback_db = 'app_testvoice___feedback_gc'

local sql_fmt = {

    sql_get_mir_info = "SELECT validity ,status FROM mirrtalkInfo WHERE imei = %s AND ncheck = %s  ",
    sql_update_mirinfo = "update mirrtalkInfo set status = '%s', updateTime = %s where status = '10a' and validity = 1 and imei = %s ",
    sql_insert_mirinfo = "insert into mirrtalkHistory(imei,movement,originalStatus,endStatus,updateTime,remarks)" ..
                            "values ('%s','%s','%s','%s','%s','%s')",
    sql_check_conf = "SELECT 1 FROM userPowerOnInfo WHERE imei = %s  limit 1",
    sql_get_test_info = "SELECT dataType from sendBinaryStatus WHERE imei = '%s'",

    sql_test_voice_no_voicefile = "SELECT count(1) as voc_file_count FROM feedbackInfo  WHERE imei = %s and fileURL != ''",
    sql_test_voice_abnormal = "SELECT count(1) as voc_normal_count FROM feedbackInfo  WHERE imei = %s and isMute = 0 and actionType in (3,4,5,10) and fileURL !=  ''",

}

local url_tab = {

    type_name = 'system',
    app_key = '',
    client_host = '',
    client_body = '',


}
---check_parameter
local function check_parameters(args)
    url_tab['app_key'] = args['appKey']
	
	only.log('D','appk is apk'.. url_tab['app_key'])
    --check appKey and sign
    safe.sign_check(args,url_tab)
    --check IMEI
	only.log("D",args["IMEI"])
    if not args["IMEI"] or (not utils.is_number(args["IMEI"])) or (#args["IMEI"] ~= 15) or (string.sub(args["IMEI"],1,1)=='0') then 
        only.log('D','Imei check failed ')
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"IMEI")
    end
end

local function update_rollback(Imei,imei)

    local cur_status = '10r'
    local cur_time = ngx.time()

    local sql_tmp = string.format(sql_fmt.sql_update_mirinfo,cur_status,cur_time,imei)
	only.log('D','update data: ' .. sql_tmp)
    local sql_tab ={}
    table.insert(sql_tab,sql_tmp)

    local movement = '38'
    local originalStatus = '10a'
    local status = '10r'
    local updateTime = ngx.time()
    local remarks = '语境预入库'

    local sql_type = string.format(sql_fmt.sql_insert_mirinfo,Imei,movement,originalStatus,status,updateTime,remarks)
    table.insert(sql_tab,sql_type)
    only.log('D',sql_type)

    
    local is_ok,ret = mysql_api.cmd(app_mirtalk_db,'AFFAIRS',sql_tab)
    if not is_ok then
        only.log('E',string.format(" tab update or insert failed(AFFAIRS)!  %s ", table.concat( sql_tab, "\r\n")) )
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
    return true
end
local function handle()
    local req_ip = ngx.var.remote_addr
    local req_body = ngx.req.get_body_data()
    
    url_tab['client_host'] = req_ip
    if not req_body then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_NO_BODY'],"req_body")
    end
    url_tab['client_body'] = req_body
    
    local args = utils.parse_url(req_body)

    if not args or type(args) ~= 'table' then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"args")
    end

    if not args['appKey'] then
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],"appKey")
    end
    ----check parameter
    check_parameters(args)




    ---IMEI=  imei +ncheck
    local imei = string.sub(args['IMEI'],1,14)
    local ncheck = string.sub(args['IMEI'],-1,-1)

    ---look up mirrtalkinfo tab
    local sql_str = string.format(sql_fmt.sql_get_mir_info,imei,ncheck)
    local ok_status,ret = mysql_api.cmd(app_mirtalk_db,'SELECT',sql_str)
    if not ok_status or type(ret) ~="table" then
        only.log('E','mirinfo failed' .. sql_str)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end

    ---if mirrtalkinfo is empty
    if #ret == 0 then
        only.log('E','mirinfo tab failed(ret == 0)')
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_CODE'],'IMEI not exit')
    end

    ---if mirrtalkinfo have more record
    if #ret > 1 then
        only.log('E','mirinfo tab failed(ret > 1)')
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end

    ---if mirrtalkinfo have one record
    if ret[1]['validity'] == '0' then
         only.log('E','mirinfo validity error(validity == 0)')
         gosay.go_false(url_tab,msg['MSG_ERROR_REQ_CODE'],'IMEI not use')
    end
        
    if ret[1]['status'] ~= '10a' and ret[1]['status'] ~= '10r' then
         only.log('E','cur status not allow prestorge operator')
         gosay.go_false(url_tab,msg['MSG_ERROR_CUR_NO_ALLOW_PRESTORGE'])
    end

   if ret[1]['status'] == '10r' then
        only.log('D','prestorge success')
	gosay.go_false(url_tab,msg['MSG_ERROR_IMEI_ALREADY_PRESTORGE'])
    end 

    ---check userPowerOnInfo tab
    local sql = string.format(sql_fmt.sql_check_conf,args['IMEI'])
    local ok,result = mysql_pool_api.cmd(app_config_db,'SELECT',sql)
    
    if not ok or not result or type(result) ~= "table" then
        only.log('E',string.format('connect config_gc sql : %s',sql))
	gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end
    ---if userPowerOnInfo tab is empty
    if #result == 0 then
        only.log('E','config_gc error tab  is empty')
	gosay.go_false(url_tab,msg['MSG_ERROR_NOT_RECEIVE_BOOT_INFO'])
    end
	--s9test_gc  sendBinaryStatus
    local sq = string.format(sql_fmt.sql_get_test_info,args['IMEI'])
    local is_ok,tab = mysql_pool_api.cmd(app_s9test_db,'SELECT',sq)

    if not is_ok or type(tab) ~= "table" or not tab then
	only.log('E','mysql connected failed' , sq)
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED'])
    end


    if #tab == 0 or tab[1]['dataType']==1 then
	only.log('E','not receive GPS info!')
        gosay.go_false(url_tab,msg['MSG_ERROR_NOT_RECEIVE_GPS_INFO']) 
    end
  

    
    --判断是否收到语音文件
    local sq = string.format(sql_fmt.sql_test_voice_no_voicefile,args['IMEI'])
    local is_ok,voicefile_count = mysql_pool_api.cmd(app_feedback_db,'SELECT',sq)

    if not is_ok or not voicefile_count then
        only.log('E','mysql connected failed' , sq) 
        gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED']) 
    end 
        
    --only.log('D',string.format('====voc_file_count==== %s',voice_count[1]['voc_file_count']))

    if #voicefile_count == 0 then
        only.log('E','query database result is 0')
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_CODE'],'query database result is 0')
    end 
    if type(voicefile_count) ~= "table" then
        only.log('E','query database result is not table')
        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_CODE'],'query database result is not table')
    end 

    if tonumber(voicefile_count[1]['voc_file_count']) == 0  then 

        only.log('E','No accept voice file!')
        gosay.go_false(url_tab,msg['MSG_ERROR_NO_ACCEPT_VOICEFILE'])

    end                                                                                                                                                                                      

    --判断语音是否正常
    local sq = string.format(sql_fmt.sql_test_voice_abnormal,args['IMEI'])
    local is_ok,voice_normal_count = mysql_pool_api.cmd(app_feedback_db,'SELECT',sq)

    if not is_ok or not voice_normal_count then
	only.log('E','mysql connected failed' , sq)
	gosay.go_false(url_tab,msg['MSG_DO_MYSQL_FAILED']) 
    end
    
    only.log('D',string.format('====voc_normal_count==== %s',voice_normal_count[1]['voc_normal_count']))

    if #voice_normal_count == 0 then
	only.log('E','query database result is 0')
	gosay.go_false(url_tab,msg['MSG_ERROR_REQ_CODE'],'query database result is 0')
    end
    if type(voice_normal_count) ~= "table" then
	only.log('E','query database result is not table')
	gosay.go_false(url_tab,msg['MSG_ERROR_REQ_CODE'],'query database result is not table')
    end

    if tonumber(voice_normal_count[1]['voc_normal_count']) == 0  then 
	only.log('E','test voice is off normal')
	gosay.go_false(url_tab,msg['MSG_ERROR_VOICE_IS_ABNORMAL'])  
    end

    --only.log('E',string.format('count(1) value is %d',count['count(1)']))
    --only.log('E',string.format('====djksoa %s',voice_count['count(1)']))


  --[[  if or not voice_count[1]['count(1)'] then
	only.log('E','test voice is off normal')
	gosay.go_false(url_tab,msg['MSG_ERROR_REQ_CODE'],'test voice is abnormal')
	
    end --]]

    local ok = update_rollback(args['IMEI'],imei)
    if ok then
        ---success
        gosay.go_success(url_tab,msg['MSG_SUCCESS'])
    else
        --failed
        gosay.go_false(url_tab,msg['SYSTEM_ERROR'])
    end
    
end


handle()
