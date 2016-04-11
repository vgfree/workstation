--
-- author: zhangjl
-- date: 2014 04 12 Tue 13:54:20 CST

local ngx = require 'ngx'
local only = require 'only'
local gosay = require 'gosay'
local utils = require 'utils'
local app_utils = require 'app_utils'
local msg = require 'msg'
local safe = require('safe')
local link = require('link')
local cutils = require('cutils')
local zmq_api = require('zmq_api')

local weibo_fun = require 'weibo_fun'

local redis_pool_api = require 'redis_pool_api'

local url_info = {
    type_name = 'system',
    app_key = nil,
    client_host = nil,
    client_body = nil,
}


local function get_binary_from_dfs(dfsurl)
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
        
	local file_type = string.sub(dfsurl,-4,-1)
        if not file_type then
                file_type = 'amr'
        else
                file_type = string.match(file_type,'%.(%w+)')
        end

	 if host == '127.0.0.1' then
                local tmp_path = '/data/nginx/weiboapi/amr'
                if not string.find(urlpath,'%/',2) then
                        -- dfsapi 存储失败,存放本地
			tmp_path = '/data/nginx/weiboapi/erramr'
			end

			local file_full_path = string.format("%s%s",tmp_path,urlpath)

			local f = io.open(file_full_path , 'r')
			if not f then
			only.log('E',"open file failed! %s", file_full_path)
			return false ,'',''
			end

		local file_data = f:read("*all")
		f:close()
		return true,file_type,file_data
	end

	local ok,ret = cutils.http(host,port,req,#req)
        if not ok then
                only.log('E','get dfs data  failed when send get request  %s ', dfsurl )
                return false,''
        end

        local split = string.find(ret,'\r\n\r\n')
        if not split then return false , '' end
        local head = string.sub(ret,1,split)
        local file_data = string.sub(ret,split+4,#ret)
	if not app_utils.check_is_amr(file_data,#file_data) then
	only.log('E',"voice file format is invalid: %s", dfsurl)
	return false, '', ''
	end


	if parstring then
	local par_tab = ngx.decode_args(parstring)
	if type(par_tab) == "table" and par_tab['daokeFilePath'] and par_tab['position']  then
	if (string.find(par_tab['daokeFilePath'] , "productList")) == 1 and ( par_tab['position'] == "1" or par_tab['position'] == "2" ) then
	local daoke_file_path = string.format("/data/nginx/weiboapi/amr/%s",par_tab['daokeFilePath'])
	local f = io.open(daoke_file_path,'r')
	if f then
	local append_data = f:read("*all")
	f:close()
	if  append_data and app_utils.check_is_amr(append_data,#append_data) and  (#append_data +  #file_data) <= dk_utils.MAX_NEWSTATUS_FILE_LENGTH then
		if par_tab['position'] == "1" then
			file_data = append_data .. file_data
		elseif par_tab['position'] == "2" then
			file_data = file_data .. append_data
		end
	end
	else
		only.log('E',"daoke file get failed  %s" , par_tab['daokeFilePath'] )
	end
	end
	end
	end



	return true,file_type,file_data

end

local function message_store_mysql(args)

	local ok,store_data = utils.json_encode(args)

	local path = 'weidb_group'
	local info = link["OWN_DIED"]["http"]["weidb"]  
	if not ok then
	only.log('D',"store data is %s",store_data)
	gosay.go_false(url_info, msg['MSG_ERROR_JSON_ENCODE_FAILED'])
	end
	local data = utils.post_data(path,info,store_data,"application/json; charset=utf-8")

	only.log('D','http weidb server return value is %s  ',data)
	local ok,ret = cutils.http(info['host'],info['port'],data,#data)
	only.log('D','http weidb server return value is %s  ', ret)
	if not ok then
	only.log('E','save data  failed when send get request  %s ', ret)
	return false,''
	end

end
 
local function check_parameters(tab)

	url_info['app_key'] = tab['appKey']

	if not tab['groupID'] then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "groupID")
	end


	if tab['receiveCrowd'] then
		local ok, receiveCrowd = utils.json_decode(tab['receiveCrowd'])
		if not ok then
        		only.log('D',"JSON DECODE FAILED")
        		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveCrowd")
        	end
          	------最大接口数组应该小于50
        	if type(receiveCrowd)~='table' or #receiveCrowd>50 then
        		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveCrowd ")
          	end

		tab['receiveCrowd'] = receiveCrowd
	end


--	if not tab['messageType'] or tab['messageType'] ~=1 and tab['messageType'] ~=4 then
--		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "messageType")
--	end

-->> check appKey and sigl
    --safe.sign_check(tab, url_info)
    
 
	tab['sourceType'] = 1
  
	tab['receiveSelf'] = tonumber(tab['receiveSelf']) or 1
	if tab['receiveSelf']~=0 and tab['receiveSelf']~=1 then
		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "receiveSelf")
	end
  


    tab['endTime'] = tonumber(tab['endTime'])  or os.time()+300
    if tab['endTime'] < os.time() then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "endTime")
    end


    if tab['multimediaURL'] and type (tab['multimediaURL']) == 'table' then
    	for k,v  in ipairs (tab['multimediaURL']) do 
    		if not string.match(v['multimediaURL'], 'http://[%w%.]+:?%d*/.+') then
   			 gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
    		end
  	 end
    
	 else
 	  	 if not string.match(tab['multimediaURL'], 'http://[%w%.]+:?%d*/.+') then
   			 gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
	   	 end

    end

    if tab['callbackURL'] then
    	if not string.match(tab['callbackURL'], 'http://[%w%.]+:?%d*/.+') then
    		gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "callbackURL")
	end
    end

    -->> check level
    tab['level'] = tonumber(tab['level']) or 99
    if tab['level']>99 or tab['level']<0 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "level")
    end

    local ok, res1, res2
    ok, res1 = weibo_fun.check_geometry_attr2(tab['senderLongitude'], tab['senderLatitude'], tab['senderAltitude'], tab['senderDistance'], tab['senderDirection'], tab['senderSpeed'], 'sender')
    if not ok then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], res1)
    end

    -- because this tab is used in the store of redis
    ok, res1, res2 = weibo_fun.check_geometry_attr(tab['receiverLongitude'], tab['receiverLatitude'], tab['receiverAltitude'], tab['receiverDistance'], tab['receiverDirection'], tab['receiverSpeed'], 'receiver')
    if not ok then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], res1)
    end

    tab['direction_tab'], tab['speed_tab'] = res1, res2

    if tab['senderAccountID'] then
        if not app_utils.check_accountID(tab['senderAccountID']) and not app_utils.check_imei(tab['senderAccountID']) then
            gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "senderAccountID")
        end
    end

    if tab['sourceID'] and #tab['sourceID']>32 then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "sourceID")
    end

    if tab['content'] then
	    tab['content'] = utils.url_decode(tab['content'])
    end
	return tab

end

local function handle()

    local req_heads = ngx.req.raw_header()
    local req_body = ngx.req.get_body_data()
    local ip = ngx.var.remote_addr

    url_info['client_host'] = ip
    url_info['client_body'] = req_body

    if not req_body then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_NO_BODY"])
    end

    local body_args = utils.parse_form_data(req_heads, req_body)
    if not body_args then
        gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "Content-Type")
    end


    local tab = check_parameters(body_args)

	
    if not tab['bizid'] then
        tab['bizid'] = weibo_fun.create_bizid('a2')
    end

	--固化到MySQL里
message_store_mysql(tab)

    local result_tab = {}
    local dfs_data_isok = false
    local dfs_data_type = 'amr'
    local dfs_data_binary = ''
    if type(tab['multimediaURL']) == 'table' then
		for k,v in ipairs (tab['multimediaURL']) do
			if  v ~= '' then
				--http://g1.tweet.daoke.me/group1/M00/00/00/rBALhFNNLg6ABKqHAAAotg-PQhY599.amr
				dfs_data_isok,dfs_data_type,dfs_data_binary = get_binary_from_dfs(v)
				---- 1 true --->---succed   false  -->---failed
				---- 2 binary is file data binary
			end
			only.log('E', " get dfsurl %s " , v)
			if dfs_data_isok == false or not dfs_data_binary then
				only.log('E', " get dfsurl %s data failed---->----return 555 " , v )
				gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
			end

		---- 二进制文件小于300字节, 大于20K,不下发给终端 2014-11-26 
			if #dfs_data_binary < weibo_fun.FILE_MIN_SIZE or #dfs_data_binary >= weibo_fun.MAX_NEWSTATUS_FILE_LENGTH then
				only.log('W', " get dfsurl %s data succed but file length :%s [ERROR]" , v ,#dfs_data_binary )
				gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
			end
		result_tab[k+2] = dfs_data_type..'\r\n'..dfs_data_binary	
		end
	else
		if  tab['multimediaURL'] ~= '' then
			--http://g1.tweet.daoke.me/group1/M00/00/00/rBALhFNNLg6ABKqHAAAotg-PQhY599.amr
			dfs_data_isok,dfs_data_type,dfs_data_binary = get_binary_from_dfs(tab['multimediaURL'])
			---- 1 true --->---succed   false  -->---failed
			---- 2 binary is file data binary
		end
		only.log('E', " group message get dfsurl is :%s " ,  tab['multimediaURL'])
		if dfs_data_isok == false or not dfs_data_binary then
			only.log('E', "get dfsurl %s data failed---->----return 555 "  , tab['multimediaURL'] )
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
		end

		---- 二进制文件小于300字节, 大于20K,不下发给终端 2014-11-26 
		if #dfs_data_binary < weibo_fun.FILE_MIN_SIZE or #dfs_data_binary >= weibo_fun.MAX_NEWSTATUS_FILE_LENGTH then
			only.log('W', " get dfsurl %s data succed but file length :%s [ERROR]" , tab['multimediaURL'] ,#dfs_data_binary )
			gosay.go_false(url_info, msg["MSG_ERROR_REQ_ARG"], "multimediaURL")
		end
		result_tab[3] = dfs_data_type ..'\r\n'..dfs_data_binary

end
	local group_table= {
		bizid = tab['bizid'],
		level  = tab['level'] or 99,
     		content = {},
		messageType  = tab['messageType'],
		tipType   = tab['tipType'] or 0,
		autoReply   = tab['autoReply'] or 0,
		invalidDis  = tab['invalidDis'],
		longitude  = tab['receiverLongitude'],
		latitude  = tab['receiverLatitude'],
		distance  = tab['receiverDistance'],
		direction =tab['direction_tab'],
		speed  = tab['speed_tab'],
	}
	group_table['content']['mmfiletype'] = dfs_data_type
        group_table['content']['mmfilelength'] = string.len(dfs_data_binary)

	local ok,second_frame = utils.json_encode(group_table)
	
	if not ok then
		only.log('D',"second frame is %s",second_frame)
		gosay.go_false(url_info, msg['MSG_ERROR_JSON_ENCODE_FAILED'])
	end
	
	result_tab[1] = '1'..tostring(tab['groupID'])
	result_tab[2] = 'json\r\n'..second_frame
	
	only.log('D',result_tab[1])
	only.log('D',result_tab[2])
	only.log('D',"%s",result_tab[3])

	
	local ok = zmq_api.cmd("group", "send_table", result_tab)
	if not ok  then
		gosay.go_false(url_info, msg['MSG_ERROR_ZMQ_DO_FAILED'])
	else
		gosay.go_false(url_info, msg['MSG_SUCCESS'])
	end

end

safe.main_call( handle )
