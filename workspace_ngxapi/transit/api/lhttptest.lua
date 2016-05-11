-- api_dk_openconfig.lua

local ngx       = require('ngx')
local mysql_api = require('mysql_pool_api')
local only      = require('only')
local link      = require('link')
local lhttp_api = require('lhttp_pool_api')

	-- check appKey

	--get openconfig sql
	urlinfo='GET /lua HTTP/1.1\r\n' ..
        'User-Agent: curl/7.32.0\r\n' ..
        'Host: 192.168.71.73\r\n' ..
        'Accept: */*\r\n\r\n'
	local ok, info = lhttp_api.cmd("httptest", "origin",urlinfo)
	ngx.say(info)

