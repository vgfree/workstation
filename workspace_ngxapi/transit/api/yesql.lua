--local only = require('only')
--local ngx = require('ngx')
--local mysql_pool_api = require('mysql_pool_api')

local utils = require('utils')
local app_utils = require('app_utils')
local cutils = require('cutils')
local only = require('only')
local gosay = require('gosay')
local msg = require('msg')
local map = require('map')
local json = require('cjson')
local redis = require('redis')
local ngx = require('ngx')
local safe = require('safe')
local http_api = require('http_short_api')
local mysql_api = require('mysql_pool_api')



ngx.say("test start")
--[[
local insert_tb = "INSERT INTO positionInfoSource (longitude, latitude, distance, roadID, positionType, roadRootID, roadName, provinceCode, provinceName, cityCode, cityName, countyCode, countyName, title, content, accountID, positionStatus, direction, deviation, speed, geometryType, positionID, sourceID, appKey, startTime, endTime, createTime) VALUES (%.7f, %.7f, %u, '%s', %u, '%s', '%s', %u, '%s', %u, '%s', %u, '%s', '%s', '%s', '%s', %d, '%s', %u, '%s', %d, '%s','%s', '%s', %s, %s, '%s')"

insert_tb = string.format(insert_tb, args['longitude'] or 0, args['latitude'] or 0, args['distance'] or 0, args['roadID']or '', args['positionType'], args['roadRootID'] or 0, args['roadName'] or '', args['provinceCode'] or 0, args['provinceName'] or '', args['cityCode'] or 0, args['cityName'] or '', args['countyCode'] or 0, args['countyName'] or '',  args['title'] or '', args['content'], args['accountID'] or '', args['positionStatus'] , direction_str or "1000,1000", args['deviation'] or 1000, args['speed'] or '', args['geometryType'], PID, args['sourceID'] or '', args['appKey'], os.time(), args['interval'], os.date('%Y-%m-%d %H:%M:%S'))

--]]
--
local app_config_db = {'app_mirrtalk___config', 'app_mirrtalk___config_gc'}

local insert_tb = "select * from userPowerOnInfo"	
       ngx.say("insert_tb")


local ok,ret = mysql_api.cmd(app_config_db[2],'SELECT',insert_tb)
if not ok then
	only.log('E', "insert mysql roadMap  positionInfoSource error!")
else
	ngx.say("select success")
	return ret
end
	ngx.say("test end")
