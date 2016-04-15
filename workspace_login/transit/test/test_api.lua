
local cutils = require('cutils')
local cjson = require('cjson')


function url_decode(str)
    if not str then return nil end
    str = string.gsub (str, "+", " ")
    str = string.gsub (str, "%%(%x%x)",
        function(h) return string.char(tonumber(h,16)) end)
    str = string.gsub (str, "\r\n", "\n")
    return str
end

function parse_url(s)
	if not s then return nil end

	local t = {}
	for k, v in string.gmatch(s, "([^=&]+)=([^=&]*)") do
		t[k] = url_decode(v)
	end
	return t
end

local MAX_FILE_LENGTH = 48*1024 

---- 根据dfsurl获取文件内容下发
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


	print("host:", host)
	print("port:",port)
	print("url:",urlpath)
	print("parstring:",parstring)

	local ok,ret = cutils.http(host,port,req,#req)
	if not ok then
		only.log('E','get dfs data when send get request failed!')
		return false,'','' 
	end

	local split = string.find(ret,'\r\n\r\n')
	if not split then return false , '' end
	local head = string.sub(ret,1,split)
	local file_data = string.sub(ret,split+4,#ret)

	-- if not utils.check_is_amr(file_data,#file_data) then
	-- 	only.log('E',string.format("data length:%s",#file_data))
	-- 	only.log('E',string.format("data header:%s",string.sub(file_data,1,20)))
	-- 	only.log('E',string.format("voice file is invalid: %s", dfsurl))
	-- 	return false, '', ''
	-- end

	if parstring then
		-- local par_tab = ngx.encode_args(parstring)
		local par_tab = parse_url(parstring)
		if type(par_tab) == "table" then
			if string.find(par_tab['daokeFilePath'] , "productList") == 1 and par_tab['mode'] == "1" and ( par_tab['position'] == "1" or par_tab['position'] == "2" ) then
				local daoke_file_path = string.format("./transit/amr/%s",par_tab['daokeFilePath'])
				local f = io.open(daoke_file_path,'r')
				if f then 
					local append_data = f:read("*all")
					f:close()
					if    #append_data + #file_data <= MAX_FILE_LENGTH then
						if par_tab['position'] == "1" then
							file_data = append_data .. file_data
						elseif par_tab['position'] == "2" then
							file_data = file_data .. append_data
						end
						print("append succed")
					end 
				end
			end

		end

	end

	return true , filey_tpe, file_data

	
end


local function sort_func( a, b )
	return tonumber(a['index']) > tonumber(b['index'])
end

function test_json_decode(  )
	

local str = [[

    {
        "index": "1",
        "msgType": "link",
        "value": "http://g4.tweet.daoke.me/group4/M07/00/50/c-dJT1UGRCWAUFq8AAARPSt5mpE640.amr",
        "default": "",
        "filesize":"0",
        "isAllowFailed": "0"
    },
    {
        "index": "2",
        "msgType": "redis_variable",
        "value": "private|get|KbmwmGYbel:nicknameURL",
        "default": "",
        "filesize":"0",
        "isAllowFailed": "1"
    },
    {
        "index": "5",
        "msgType": "redis_fixation",
        "value": "qMkGm2sJue|nicknameURL",
        "default": "",
        "filesize":"0",
        "isAllowFailed": "1"
    }
     ]]

    str = ' ['  .. str  .. "] "

	--print (str)

    local ok,tab_info = pcall(cjson.decode,str)

    sortFunc = function(a, b) return b["index"] > a["index"] end

    table.sort(tab_info, sortFunc )

    print (tab_info)
    if ok then
	    for i, v in pairs(tab_info) do
	    		print( string.format(" [%s] -->-- %s", i , v ) )
	    		if type(v) == "table" then
	    			for a, b in pairs(v) do
	    				print( string.format(" --->--- [%s] -->-- %s", a , b ) )
	    				if type(b) == "table" then
			    			for a1, b1 in pairs(b) do
			    				print( string.format(" ||||||||||--->--- [%s] -->-- %s", a1 , b1 ) )
			    			end
			    		end
	    			end
	    		end
	    end
	end



end



-- local fileurl =  "http://g3.tweet.daoke.me/group3/M01/BC/65/c-dJB1Q9z4uAcr6oAAAN3LRyVdU430.amr?daokeFilePath=productList/SystemsRemind/aaaaa.amr&Position=1&Mode=1"
-- get_dfs_data_by_http(fileurl)

test_json_decode()


