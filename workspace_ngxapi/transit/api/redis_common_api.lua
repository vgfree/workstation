
local redis_api    = require('redis_pool_api')

module('redis_common_api', package.seeall)

-- 加入频道
function joinChannel(key, member)
        local ok_status = redis_api.cmd('statistic', 'sadd', key .. ':channelOnlineUser', member)
        return ok_status
end

-- 退出频道
function quitChannel(key, member)
        local ok_status = redis_api.cmd('statistic', 'srem', key .. ":channelOnlineUser", member)
        return ok_status
end

-- 查询用户是否在频道中
function selectChannel(key, member)
        local ok_status, is_online = redis_api.cmd('statistic', 'sismember' , key .. ":channelOnlineUser", member)
        return ok_status, is_online
end

-- 返回频道中所有成员
function allMembersChannel(key)
        local ok_status, member_tab = redis_api.cmd('statistic','smembers', key .. ':channelOnlineUser')
	return ok_status, member_tab
end

-- 返回频道中成员数量
function numMembersChannel(key)
        local ok_status, onlineUser = redis_api.cmd('statistic', 'scard', key .. ":channelOnlineUser")
        return ok_status, onlineUser
end

-- 查找给定模式的成员
function selectPattern(pattern)
        local ok_status, channel_key_tab = redis_api.cmd('statistic', "keys", pattern .. ":channelOnlineUser")
	return ok_status, channel_key_tab
end
