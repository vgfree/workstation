local http_api  = require('http_short_api')
local redis_api = require('redis_pool_api')
local mysql_api = require('mysql_pool_api')
local utils     = require('utils')
local app_utils = require('app_utils')
local only      = require('only')
local msg       = require('msg')
local link      = require('link')
local appfun    = require('appfun')

module('account_utils', package.seeall)

---- 用户设置昵称之后触发的事件
function after_set_nickname(accountid, nickname, status )
	if not status or not nickname or #tostring(nickname) < 1 then
		redis_api.cmd('private', 'del', accountid .. ':nicknameURL')
		return false
	end

	local tmp_nickname = nickname
	if tostring(string.match(nickname,"(%d+)")) == tostring(nickname) then
		-- 全部是数字,需要转换为汉字
		tmp_nickname = appfun.number_to_chinese(tmp_nickname)
	elseif string.match(nickname,"(%a+)") then
		---- 针对昵称含有英文的使用IMEI后面4位,解决思必驰接口无法朗读的问题
		redis_api.cmd('private', 'del', accountid .. ':nicknameURL')
		return false
	end

	tmp_nickname = "道客" .. tmp_nickname

	local txt2voice = link["OWN_DIED"]["http"]["txt2voice"]
	local appKey = "2973785773"
	local secret = "D626681ED77073574611AE386010067269C602CE"
	--update utils to app_utils
	--local ok,file_url = utils.txt_2_voice(txt2voice,appKey,secret,tmp_nickname)
	local ok,file_url = app_utils.txt_2_voice(txt2voice,appKey,secret,tmp_nickname)
	if ok and file_url then
		redis_api.cmd('private', 'set', accountid .. ':nicknameURL',file_url)
		return true
	else
		only.log('E',string.format("nickname:%s to amr file_url failed!",tmp_nickname))
		redis_api.cmd('private', 'del', accountid .. ':nicknameURL')
		return false
	end
end

---- 用户设置昵称
function set_nickname(accountid, nickname)
	local ok,ret = redis_api.cmd('private', 'set', accountid .. ':nickname',nickname)
	after_set_nickname(accountid,nickname,ok)
	return ok,ret
end
