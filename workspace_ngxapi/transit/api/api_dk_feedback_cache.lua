-- author: jiang z.s. 
-- date: 2014-03-25
-- 终端上传amr文件至该接口,需要将文件存储至dfs文件系统


local ngx       = require('ngx')
local only      = require('only')
local gosay     = require('gosay')
local utils     = require('utils')
local app_utils = require('app_utils')
local cutils    = require('cutils')
local cjson     = require('cjson')
local link      = require('link')
local socket    = require('socket')
local dk_utils  = require('dk_utils')
local mysql_api = require('mysql_pool_api')
local redis_api = require('redis_pool_api')
local http_api  = require('http_short_api')

local dfsSaveSound     = link.OWN_DIED.http.dfsSaveSound
local feedbackDispatch = link.OWN_DIED.http.feedbackDispatch

local host_ip   = dfsSaveSound.host
local host_port = dfsSaveSound.port


local url_tab = { 
        type_name   = 'transit',
        app_key     = '',
        client_host = '',
        client_body = '',
}

local app_url_db      = 'app_url___url'
local app_feedback_db = 'app_fb___feedback'

local G = {
	req_ip       = '',    ----访问者IP
	
	body         = '',    ----请求内容
	dfs_url      = '',    ----dfs返回的url
	file_id      = '',    ----fileID(UUID)
	file_size    = 0,     ----文件大小
	receive_time = 0,     ----多媒体文件ID,使用时间(精确到纳秒)
	accountid    = '',    ----如果IMEI:accountID失败,该值为IMEI
	file_name    = '',    ----上传的原始文件名
	file_binary  = '',
	imei         = '',
	boundary     = '',
	file_param   = '',
	
	org_url      = "",
	org_filesize = "",
	
	GMTTime      = '',
	collect_time = 0,
	latitude     = 0, 
	longitude    = 0 ,
	direction    = 0,
	speed        = 0 ,
	altitude     = 0,
	
	cur_month    = 0,
	cur_time     = 0,

	sql_save_urllog = "insert into urlLog_%s(createTime,url,clientip,returnValue) values(unix_timestamp() , '%s' , inet_aton('%s') , '%s' )",

	-- receive_time
	sql_save_feedback = "insert into feedbackInfo_%s(accountID,imei,imsi,actionType,createTime,collectTime,GMTTime," ..
                                " latitude,longitude,direction,speed,altitude," ..
                                " duration,channels,rate,bit,fileType,fileID,fileSize,fileURL,receivedTime," ..
                                " bizid,tokenCode) " ..
                                " values ( '%s',%d, %d , %d, unix_timestamp(), %d ,'%s', " ..
                                " %d, %d, %d, %d, %d, " .. 
                                " %d, %d, %d, %d, '%s', '%s', %d , '%s', %d , '%s', '%s' ) "

}

---- save file to disk(day)
---- if file dur < 2 filter (note)
local function save_file_to_disk()
	if #G.file_binary > 1 and G.dfs_url == '' then
		local tmp_file_name = string.format("%s____%s____%s____%s",G.imei, G.accountid , tostring(G.cur_time), G.file_name)
		local f = io.open("./transit/erramr/" .. tmp_file_name, 'w')
		if f then
			f:write(G.file_binary)
			f:close()
			return 'http://127.0.0.1/' .. tmp_file_name
		else
			only.log('E',"path error transit/erramr/ ")
		end
	end
	return ''
end

----获取最新时间
local function get_last_timestamp(accountid)
	local ok_status,ok_timestamp  = redis_api.cmd('private','get',accountid .. ':currentGPSTime')
	if not ok_status or ok_timestamp == nil then
		return 0
	end
	return tonumber(ok_timestamp) or 0
end

---- 获取最新经纬度
local function get_last_point( accountid)
	local ok,gps_str = redis_api.cmd('private','get',accountid .. ":currentBL")
	if not ok or gps_str == nil then
		return 0,0
	end

	local gps_info = utils.str_split(gps_str,",")
	if not gps_info or #gps_info ~= 2  then 
		return 0,0 
	end

	local lon = gps_info[1]
	local lat = gps_info[2]

	if tonumber(lon) == 0 or tonumber(lat) == 0 then
		return 0,0
	end
	return lon,lat
end


----保存文件至DFS
local function upload_file( file_name, file_binary  )
	if not file_name then 
		file_name = string.format("test_save_sound_%s.amr",G.cur_time)
	end

	if not file_binary or #file_binary < 1 then
		return false,'',''
	end

	local  tab = {
		appKey = dk_utils.FEEDBACK_APPKEY ,
		length = #file_binary,
		amrtomp3 = "1",			---- *** 
	}

	----- 2014-07-02
	----- jiang z.s. 
	----- amrtomp3 = "1"  警告,暂时添加该参数,上传的amr文件,同时也会转换为mp3文件存储给微信(web)端使用

	tab['sign'] = app_utils.gen_sign(tab, dk_utils.FEEDBACK_SECRET )

	--文件二进制,重新拼接数据,发送至dfs接口
	local req = dk_utils.keys_binary_to_req(host_ip, host_port , 'dfsapi/v2/saveSound', tab ,file_name, file_binary)
	local ok,ret = cutils.http(host_ip, host_port, req, #req)
	if not ok then
		only.log('E',"[FAILED] HTTP post failed! saveSound api ")
		return false,'',''
	end

	if ret then
		local ok_str = string.match(ret,'{.+}')
		if ok_str then
			local ok_status ,ok_tab = pcall(cjson.decode , ok_str)
			if ok_status then
				if ok_tab['ERRORCODE'] == "0" then
					if ok_tab['RESULT']['url'] then
						return true,ok_tab['RESULT']['url'],ok_tab['RESULT']['fileID'],tonumber(ok_tab['RESULT']['fileSize']) or 0,
								ok_tab['RESULT']['orgurl'] or '', ok_tab['RESULT']['orgFileSize'] or 0
					end
				else
					only.log("E","dfsapi failed %s", ret)
					return false,"",""
				end
			end
		end
	end
	only.log('E',"============ERROR=====begin=======")
	only.log('E',string.format("%s",ret))
	only.log('E',"============ERROR=====end=======")
  	return false,'',''
end

local function save_files(file_tab , file_duration )
	G.file_name   = file_tab['file_name']
	G.file_binary = file_tab['data']
	if not G.file_binary or #G.file_binary < dk_utils.FILE_MIN_SIZE then
		G.file_binary = ""
		return false,'binary is nil or < 300 byte '
	end

	local ok_status, ok_url, ok_id , ok_size, org_url, org_filesize = upload_file( G.file_name ,  G.file_binary)
	if ok_status and ok_url then
		only.log('I',string.format("[SUCCED] dfs upload_file succed!--->------%s",ok_url))
	else
		only.log('E',"[FAILED] dfs upload_file failed!")
		ok_url = save_file_to_disk()
		if ok_url ~= '' then
			ok_id = utils.create_uuid()
			only.log('D',"[repair]:use local file:%s",ok_url, ok_id)
			return  true,ok_url, ok_id , #G.file_binary
		end
	end
	return ok_status, ok_url, ok_id, ok_size,org_url, org_filesize 
end


----保存文件至dfs
local function save_file_to_dfs(args)
	local ok_filter = false   --是否存在data二进制数据
	local ok_status = false   --调用dfs接口成功状态
	local ok_duration = ''    --音频文件录音时长

	---- 获取文件信息
	local v = args['mmfile']
	if not v then
		only.log('D',string.format('file no include mmfile'))
		return false
	end
	if type(v) == "table" then
		if v['file_name'] and v['data'] then
			ok_filter = true
			ok_duration = tonumber(args['mmfilemins']) or 0

			-- only.log('D',string.format("imei: %s  post file duration:%s file binary length: %d ", 
			-- 							args['imei'] , 
			-- 							ok_duration,
			-- 							#v['data']))

			ok_status ,G.dfs_url,G.file_id, G.file_size, G.org_url,G.org_filesize = save_files(v , ok_duration)
			if ok_status == true then
				--dfs调用成功
				v['data'] = G.dfs_url
			elseif v['data'] and ok_status == false then
				v['data'] = '[FAILED] [save file to dfs] '
				only.log('D','[FAILED] [save file to dfs] ')
			end
		end
	end
	if ok_filter == false then
		only.log('E','[SAVE DFSFILE FAILED] body must have binary data')
	end
	return ok_status 
end

----保存日志至URL表
local function save_urllog(return_value)

	----- 日志写test_db
	dk_utils.set_urlLog(G.imei,G.body,G.req_ip,return_value, G.cur_time )

	---- 日志是否写urllog 2014-09-16
	if tonumber(dk_utils.DK_WRITE_MYSQL_WITH_URL) ~= 0 then
		local sql_str = string.format(G.sql_save_urllog,G.cur_month,G.body,G.req_ip,return_value)
		local ok_status,ok_ret = mysql_api.cmd(app_url_db,'INSERT',sql_str)
		if not ok_status then
			only.log('E','[save_urllog] insert database failed!',sql_str) 
		end
	end

end

----通过IMEI获取accid
local function get_account_id(imei)
	local accountid = dk_utils.lru_cache_get_accountid( imei )
	if #tostring(accountid) == 10 then
		return true, accountid
	else
		return true,nil
	end
end

----通过IMEI获取tokencode
local function get_token_code(imei)
	local tokencode = dk_utils.lru_cache_get_token( imei )
	return true,tokencode
end


---- 格式化处理gps数据 
local function split_gps_data(gps_info)
	if not gps_info then return end

	----必须包含采集时间、经度、纬度、角度、速度、海拔。
	----250314092030,12122.11260E,3113.16226N,0.00,0.587,99999
	local gps_tab = utils.str_split(gps_info,',')
	if gps_tab and #gps_tab >=6 then
		G.GMTTime = gps_tab[1]
		G.collect_time = utils.gmttime_to_timestamp(G.GMTTime)
		local lonx = gps_tab[2]
		local tmp_lon = string.match(lonx,'%d+.%d+')

		local latx = gps_tab[3]
		local tmp_lat = string.match(latx,'%d+.%d+')

		if tmp_lon and tmp_lat then
			G.longitude, G.latitude = dk_utils.convert_gps( tonumber(tmp_lon), tonumber(tmp_lat) )
			----EAST 东经 经度（正：东经　负：西经）
			if not string.find(lonx,'E') then
				G.longitude = -1*G.longitude
			end
			----纬度（正：北纬　负：南纬）
			if not string.find(latx,'N') then
				G.latitude = -1*G.latitude
			end
		end
		G.direction =  string.format("%d",tonumber(gps_tab[4]) or 0 )
		G.speed = string.format("%d",tonumber(gps_tab[5]) or 0)
		G.altitude = tonumber(gps_tab[6]) or 0
		if G.altitude > 9999 then
			G.altitude = 9000 
		end
	end
end


----判断文件类型等参数
local function check_fileinfo(args)
	----判断文件类型
	local file_type = args['mmfiletype'] or ''
	file_type = string.upper(file_type)
	if file_type ~= "AMR" then
		only.log('E','[CHECK_FAILED] file_type must amr')
		return false
	end

	----判断文件kbps
	local filekbps = args['mmfilekbps']
	if tonumber(filekbps) > 8000 then
		only.log('E','[CHECK_FAILED] file kbps must less 8000')
		return false
	end

	----判断文件最大时常
	local filemins = tonumber(args['mmfilemins']) or 0
	local arg_type = tonumber(args['type']) or 0 
	if filemins <= 0  then
		only.log('E','[CHECK_FAILED] file mins must number and  > 0')
		return false
	elseif ( filemins > dk_utils.MAX_NORMAL_FILE_DURACION and arg_type == dk_utils.DK_TYPE_VOICE ) 
		or ( filemins > dk_utils.MAX_REPLY_FILE_DURACION and arg_type == dk_utils.DK_TYPE_REPLYVOICE ) then
		only.log('E','[CHECK_FAILED] file mins too long')
		return false
	end

	----判断文件最大长度
	local filelength = tonumber(args['mmfilelength']) or 0
	if filelength <= 0  then
		only.log('E','[CHECK_FAILED] file length must number')
		return false
	elseif filelength > dk_utils.MAX_FEEDBACK_FILE_LENGTH then
		only.log('E','[CHECK_FAILED] file length value too big')
		return false
	end

	---- 校验二进制文件
	local mmfile = args['mmfile'] 
	if not mmfile  then
		only.log('E','[CHECK_FAILED] must input file name')
		return false
	end

	if not mmfile['data'] then
		only.log('E','[CHECK_FAILED] file binary is nil')
		return false
	end

	---- if size > 20KB --ERROR
	if #mmfile['data'] > dk_utils.MAX_FEEDBACK_FILE_LENGTH then
		only.log('E','[CHECK_FAILED] file binary file too big')
		return false
	end
	return true
end


----检查参数
local function check_parameter(args)
	local imei = args['imei']
	local imsi = args['imsi']
	local mod = args['mod']
	local op_type = tonumber(args['type']) or 0

	if not imei  or not imsi  or not mod  then
		only.log('D','[CHECK_FAILED]params is nil')
		return false
	end
	if #imei ~= 15 or #imsi ~= 15 or #mod ~= 5   then
		only.log('D', '[CHECK_FAILED]params length error imei:%d imsi:%d mod:%d',#imei,#imsi,#mod) 
		return false 
	end

	----检测imei是否为15位数字
	if not utils.is_number(imei) or #imei ~= 15 then 
		only.log('D','[CHECK_FAILED]imei must be number %s ', imei)
		return false 
	end 

	----检测imsi是否为15位数字
	if not utils.is_number(imsi) or #imsi ~= 15 then
		only.log('D','[CHECK_FAILED]imsi must be number %s', imsi)
		return false 
	end

	----检测mod是否为大写字符+数字组合
	local tmp = string.match(mod,'%w+')
	if not tmp or #tmp ~= 5 then
		only.log('D','[CHECK_FAILED]imsi must be number and letter')
		return false 
	end
	if string.upper(tmp) ~= tmp then
		only.log('D','[CHECK_FAILED]imsi must uppercase letters %s ', tmp )
		return false 
	end

	if not op_type  then
		only.log('D','[CHECK_FAILED]type is nil %s ', op_type )
		return false
	end

	----判断操作类型
	if op_type <= 0 then
		only.log('D','[CHECK_FAILED]type must be number and > 0, op_type %s ', op_type)
		return false
	elseif op_type >= 100 or op_type < 1 then
		only.log('D','[CHECK_FAILED]type must in 1 - 99 ')
		return false
	end

	local token_code = args['tokencode'] or ''
	if #token_code ~= 10 then
		only.log('D','[CHECK_FAILED]tokencode length must be 10, %s', token_code)
		return false
	end

	local ok_status,tmp_token_code = get_token_code(imei)
	if tmp_token_code ~= token_code then
		only.log('E','[CHECK_FAILED]tokencode invalid really tokencode is:%s ',tmp_token_code)
		return false
	end
	return true
end


local function save_org_http_body(args)
	if not args or not G.boundary or G.boundary == '' then return end
	----拼接原始body,将二进制数据替换为dfs返回的url
	local key_value = G.boundary .. '\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n'
	local data_value = G.boundary .. '\r\nContent-Disposition: form-data; name="%s"; filename="%s"\r\nContent-Type: %s\r\n\r\n%s\r\n'

	local tab_form = {}
	for i,v in pairs(args) do
		if type(v) == "table" then
			if #G.dfs_url > 0 then
			table.insert(tab_form,string.format(data_value,i, v['file_name'], v['data_type'],G.dfs_url))
			end
		else
			table.insert(tab_form,string.format(key_value,i,v))
		end
	end
	G.body = string.format("%s%s--",table.concat(tab_form,''),G.boundary)
end


---- feedback_data
local function post_feedback_data(input_args)

	local args = {}
	for idx,val in pairs(input_args) do
		if type(val) ~= "table" then
			args[idx] = val
		end
	end

	---- add new 
	args['longitude']   =G.longitude
	args['latitude']    =G.latitude
	args['direction']   =G.direction
	args['speed']       = G.speed
	args['altitude']    = G.altitude
	args['dfsurl']      = G.dfs_url
	args['fileid']      = G.file_id
	args['filesize']    = G.file_size
	args['collecttime'] = G.collect_time
	args['receivetime'] = G.receive_time

	if G.accountid and #G.accountid == 10 then
		args['accountid'] = G.accountid
	end

	if G.org_url and #G.org_url > 10 then
		args['orgurl']      = G.org_url
		args['orgfilesize'] = G.org_filesize
	end

	local tmp_head = 'POST /feedbackDispatch HTTP/1.0 \r\n' ..
					'Host: %s:%s\r\n' .. 
					'Accept: */*\r\n' .. 
					'Content-Length: %d\r\n' .. 
					'Content-Type: application/x-www-form-urlencoded\r\n\r\n%s'

	----local feedback_data = utils.table_to_kv(args)
	local feedback_data = ngx.encode_args(args)
	local req = string.format(tmp_head,feedbackDispatch.host, tostring(feedbackDispatch.port), #feedback_data ,feedback_data )
	---- http异步调用
	local ok,ret = http_api.http(feedbackDispatch, req , false)
	if not ok then
		only.log('E',"[FAILED] %s %s HTTP post failed! feedback api ", feedbackDispatch.host, feedbackDispatch.port ) 
		return false
	end
	return true
end



local function go_exit()
	save_file_to_disk()
	save_urllog('400')
	gosay.respond_to_status(url_tab,false)
end

local function go_succ()
	save_urllog('200')
	gosay.respond_to_status(url_tab,true)
end


---- 保存所有参数至数据库
local function save_feedback_info(args)
	-- receive_time
	local sql_str = string.format(G.sql_save_feedback, 
								G.cur_month,
								G.accountid or '',
								args['imei'],args['imsi'],args['type'],G.collect_time,G.GMTTime,
								G.latitude * dk_utils.gps_point_unit,
								G.longitude * dk_utils.gps_point_unit,
								G.direction , G.speed, G.altitude,
								tonumber(args['mmfilemins']) or 0, dk_utils.DEFAULT_FILE_CHANNEL,
								tonumber(args['mmfilekbps']) or 0, dk_utils.DEFAULE_FILE_BIT,
								args['mmfiletype'] or '',G.file_id, G.file_size , G.dfs_url , G.receive_time,
								args['bizid'] or '', args['tokencode'] )

	local ok_status,ok_ret = mysql_api.cmd(app_feedback_db,'INSERT',sql_str)
	if not ok_status then
		only.log('E','save feedback info to database failed!',sql_str) 
		return false
	end
	return true
end


---- 检查所有type类型
local function all_type_check(args)
	local is_succed = false
	local bizid = args['bizid']
	local op_type = tonumber(args['type']) or 0

	if op_type == dk_utils.DK_TYPE_REPLYVOICE then
		if bizid and #bizid == dk_utils.BIZID_LENGTH then
			is_succed = true
		else
			return false
		end
	end

	if op_type == dk_utils.DK_TYPE_CALL1 or op_type == dk_utils.DK_TYPE_CALL2 then
		----1  call1 
		----2  call2 
		is_succed = true
	elseif op_type == dk_utils.DK_TYPE_VOICE or op_type == dk_utils.DK_TYPE_COMMAND or op_type == dk_utils.DK_TYPE_GROUP or op_type == dk_utils.DK_TYPE_REPLYVOICE then
		--  3 发送语音
		--  4 语音命令
		--  5 发送群组语音
		--  10 回复语音
		---- 判断文件相关的参数是否正确
		is_succed = check_fileinfo(args)
		if is_succed == true then
			is_succed = save_file_to_dfs(args)
			if is_succed ~= true then
				only.log('E',string.format('***Error*** actionType is %s, save file to dfs failed',op_type))
			end
		else
			only.log('E',string.format('***Error*** actionType is %s, check file info failed ',op_type))
		end

		---- 保存原始http body
		save_org_http_body(args)

	-- 保存文件至dfs
	elseif op_type == dk_utils.DK_TYPE_YES or op_type == dk_utils.DK_TYPE_NO then
		----YES OR NO reply 
		if bizid and #bizid == dk_utils.BIZID_LENGTH then
			is_succed = true
		end
	elseif op_type == dk_utils.DK_TYPE_POWEROFF then
		is_succed = true
	elseif op_type == dk_utils.DK_TYPE_NOT_COMMAND or op_type == dk_utils.DK_TYPE_NOT_GROUP then
		---- 
		is_succed = true
	end

	return is_succed
end


local function handle()
	local req_heads = ngx.req.raw_header()
	local req_ip  = ngx.var.remote_addr
	local req_body = ngx.req.get_body_data()

	local args = ngx.req.get_uri_args()

	url_tab['client_host'] = req_ip
	url_tab['client_body'] = 'maybe have binary'
	
	G.req_ip               = req_ip
	G.cur_time             = ngx.time()			----time 	1403933518
	G.cur_month			 = string.gsub(string.sub(ngx.get_today(),1,7),"%-","")

	local req_method = ngx.var.request_method
	if req_method == "POST" then
		args = nil
		---post key-values
		if not req_body then
			go_exit()
		end
		local boundary = string.match(req_heads, 'boundary=(..-)\r\n')
		if not boundary then
			url_tab['client_body'] = req_body
			----args                   = utils.parse_url(req_body)
			args                   = ngx.decode_args(req_body)

			G.body                 = req_body
			G.boundary             = nil
		else
			args       = utils.parse_form_data(req_heads, req_body)
			G.body     = req_body
			G.boundary = '--' .. boundary

			---- 保存原始http body
    			save_org_http_body(args)   --no fileURL
		end
	end

	if not args then
		only.log('E','[FAILED][Content-Type] get Content-Type failed!')
		go_exit()
	end

	--for i,v in pairs(args) do
	--	only.log('D',string.format("%s  %s",i,v))
	--end

	if not G.body or G.body == '' then
		--G.body                 = utils.table_to_kv(args)
		G.body                 =  ngx.encode_args(args)
		url_tab['client_body'] = G.body
	end

	only.log('D', "feedback Notice log imei:%s  imsi:%s  tokencode:%s  type:%s " , 
					args['imei'], args['imsi'], args['tokencode'],args['type'])


	local ok_status = check_parameter(args)
	if ok_status == false then
		go_exit()
	end

	---- 先校验参数,然后再使用2014-09-10 
	G.imei         = args['imei']
	local ok_status,acc_id = get_account_id(G.imei)
	if ok_status == false then
		go_exit()
	end

	local is_succed = all_type_check(args)
	if not is_succed then
		go_exit()
	end

	G.accountid    = acc_id or ''
	G.receive_time = string.format("%d", ngx.time() )


	----- 格式化处理gps数据
	split_gps_data(args['gps'])

	if G.longitude == 0 or G.latitude == 0 then
		local accountid = args['accountid'] or args['imei']
		local last_timestamp = get_last_timestamp(accountid)
		if  G.cur_time - last_timestamp < 30 then
			G.longitude, G.latitude  =  get_last_point(accountid)
		end
	end

	local bizid = args['bizid']
	if bizid and #bizid > 0 then
		bizid = string.match(bizid,'%w+')
		if not bizid or #bizid ~= dk_utils.BIZID_LENGTH then
			only.log('E','[CHECK_FAILED] bizid length error, %s ', bizid)
			go_exit()
		end
	end
	------ save param
	save_feedback_info(args)
	---- 所有成功,将调用该接口转发数据至api
	if is_succed == true then
		post_feedback_data(args)
		go_succ()
	end
	go_exit()
end

handle()

