-- jiang z.s. 
-- 2014-06-05 
-- clientcustom 公共函数模块

local only      = require('only')
local utils     = require('utils')
local cutils    = require('cutils')
local cjson     = require('cjson')
local link      = require('link')
local redis_api = require("redis_pool_api")
local mysql_api = require("mysql_pool_api")
local appfun    = require('appfun')

module('clientcustom_utils', package.seeall)

----------------------------------------------------------------------
---- daokeIO2.0 type操作类型
DK_TYPE_CALL1      = 1
DK_TYPE_CALL2      = 2
DK_TYPE_VOICE      = 3
DK_TYPE_COMMAND    = 4 
DK_TYPE_GROUP      = 5
DK_TYPE_YES        = 6
DK_TYPE_NO         = 7
DK_TYPE_POWEROFF   = 8
DK_TYPE_PASSBY     = 9
DK_TYPE_REPLYVOICE = 10
----------------------------------------------------------------------


----------------------------------------------------------------------
-- 语音指令自定义类型 actionType = 3
-- 10: 周围4公里
-- 11: 语音记事本
-- 12: app连线
AROUND_FOUR_KILOMETRE     = 10
VOICE_COMMAND_NOTEPAD     = 11
VOICE_COMMAND_APP_CONNECT = 12
VOICE_COMMAND_MAXVAL      = 12

----------------------------------------------------------------------



----------------------------------------------------------------------
-- 语音指令自定义类型 actionType = 4
-- 10:群聊频道
VOICE_COMMAND_TYPE_SECRETCHANNEL = 10
VOICE_COMMAND_TYPE_MAXVAL = 10
----------------------------------------------------------------------

----------------------------------------------------------------------
--频道自定义类型  actionType = 5 
-- 10: 群聊频道
GROUP_VOICE_TYPE_SECRETCHANNEL = 10
GROUP_VOICE_TYPE_MAXVAL = 10
----------------------------------------------------------------------

---- 密频道最大支持的人数
USER_CHANNEL_MAX_USER_COUNT = 100 

---- 每个用户的总密频道最大值
USER_CHANNEL_MAX_SECRET_COUNT = 10 


default_channel = "10086"

----------------------------------------------------------------------
-- 服务频道审核状态
-- checkStatus    0待审核  1驳回  2审核成功 3重审中 4重审成功 5重审驳回
SERVICE_CHANNEL_STATUS_OF_CHECKING    = 0
SERVICE_CHANNEL_STATUS_OF_REJECT      = 1
SERVICE_CHANNEL_STATUS_OF_AGREE       = 2
SERVICE_CHANNEL_STATUS_OF_RECHECKING  = 3
SERVICE_CHANNEL_STATUS_OF_REAGREE     = 4
SERVICE_CHANNEL_STATUS_OF_REDISMISSED = 5

-- 服务频道申请数量限制
SERVICE_CHANNEL_APPLY_QUANTITY_LIMIT = 10
-- 服务频道唯一编码字符串长度
SERVICE_CHANNEL_UNIQUE_CODE_LENGTH = 16

-- 服务频道审核阶段 
-- 1 申请阶段
-- 2 重审阶段
SERVICE_CHANNEL_APPLY_PERIOD   = 1
SERVICE_CHANNEL_RECHECK_PERIOD = 2

-- 用户可见的频道状态   0待审核  1驳回  2审核成功
SERVICE_CHANNEL_USER_STATUS_CHECKING = 0
SERVICE_CHANNEL_USER_STATUS_REJECT   = 1
SERVICE_CHANNEL_USER_STATUS_AGREE    = 2

----------------------------------------------------------------------


function set_channel_idx_number( channel_num, channel_idx , owner , cur_time , capacity , channel_type,  open_type , check_status,
		citycode ,cityname ,catalogid , catalogname ,channelname,introduction,channelname_url )

	only.log('W', string.format( "channel_num:%s channel_idx:%s  owner:%s  cur_time:%s  capacity:%s \r\n" ..
														" channel_type:%s open_type:%s , citycode %s ,cityname %s ,catalogid %s, " .. 
														" catalogname %s,channelname %s ,introduction %s ,channelname_url :%s", 
														channel_num, 
														channel_idx , 
														owner , 
														cur_time , 
														capacity , 
														channel_type , 
														open_type ,
														citycode ,
														cityname ,
														catalogid , 
														catalogname ,
														channelname,
														introduction ,
														channelname_url
														)
													)

	if #tostring(channel_idx) < 9 then
		only.log('E',string.format("channel_idx %s   length   is error !" ,channel_idx ) )
		return false
	end

	---- 设置频道编号与频道ID对应的关系
	redis_api.cmd('private','set',string.format("%s:channelID",channel_num), channel_idx)
	redis_api.cmd('private','set',string.format("%s:channelNumber",channel_idx), channel_num)
	---- 频道类型，1 主播 2 群聊
	redis_api.cmd('private','set',string.format("%s:channelType",channel_idx), channel_type)
	---- 频道状态，1 正常 2 关闭
	redis_api.cmd('private','set',string.format("%s:channelStatus",channel_idx), check_status)
	

	if channelname_url then
		---- 只有微频道才有url 2014-12-19 jiang z.s.
		redis_api.cmd('private','set',string.format("%s:channelNameUrl",channel_idx),channelname_url)
	end

	---- 频道的创建者 owner 
	---- 频道的创建时间 createTime 
	---- 频道的最大容量 capacity
	redis_api.cmd('private','hmset',string.format("%s:userChannelInfo",channel_idx), 
							"owner", owner , 
							"createTime", cur_time,
							"capacity", capacity, 
							"channelType", channel_type ,
							"openType", open_type or 0,
							"cityCode", citycode ,
							"cityName", cityname ,
							"catalogID", catalogid ,
							"catalogName", catalogname ,
							"channelName", channelname,
							"introduction", introduction )
end


local  G = 
{
	sql_check_keyinfo = "select customType,customParameter,validity from userKeyInfo where accountID = '%s' and actionType= %d " , 

	sql_insert_keyinfo = "insert into userKeyInfo(accountID,actionType,customType,customParameter,createTime,updateTime,validity,remark)" ..
			" values( '%s',%d,%d,'%s',%d,%d,1,'%s' ) ",

	sql_update_keyinfo = " update  userKeyInfo set customParameter = '%s', remark = '%s' , customType = %d ,updateTime = %d, validity = 1 where accountID = '%s' and actionType = %d  " ,

	sql_history_keyinfo = "insert into userKeyHistory(accountID,actionType,customType,customParameter,updateTime,validity,remark)" ..
			" select accountID,actionType,customType,customParameter,updateTime,validity,remark from userKeyInfo  " ..
			" where accountID = '%s' and actionType = %d limit 1 " , 

	sql_clear_joinmemberlist = " update joinMemberList set actionType = actionType ^ ( power(2 , (%s - 1 ) ) )  ,updateTime = %d where accountID = '%s' " .. 
								" and  number != '%s' and  ( actionType  &   power(2 , (%s - 1 ) )  ) =  power(2 , (%s - 1 ) )  and validity = 1 " , 

	sql_update_joinmemberlist = " update joinMemberList set actionType = actionType | ( power(2 , (%s - 1 ) ) ) , validity = 1  , updateTime = %d where accountID = '%s'  " .. 
								" and number = '%s' and ( actionType  &   power(2 , (%s - 1 ) )  ) !=  power(2 , (%s - 1 ) ) " ,

	sql_insert_joinmemberlisthistory = "insert into joinMemberListHistory(idx,number,accountID,uniqueCode,updateTime,validity,talkStatus,actionType,role) " ..
			" select idx,number,accountID,uniqueCode,updateTime,validity,talkStatus,actionType,role from joinMemberList where accountID = '%s' and number = '%s' limit 1 " ,

	---- 允许按键可为空
	sql_update_userkeyinfo = " update userKeyInfo set validity = 0 where validity = 1 and actionType = %d and accountID = '%s'  " ,

	sql_clear_actiontype_empty = "update joinMemberList set actionType = actionType ^ (power(2 ,(%s - 1) ) ) ,updateTime = %d where validity = 1 and accountID = '%s' and number = '%s' " ,
}


function check_is_can_set_channel_info( actionType, customType, customPar )
	if 	( actionType == appfun.DK_TYPE_COMMAND and 
			(customType == appfun.VOICE_COMMAND_CHANNEL or 
			customType == appfun.VOICE_COMMAND_SECRETCHANNEL ) ) or
		( actionType == appfun.DK_TYPE_GROUP and 
			( customType == appfun.GROUP_VOICE_CHANNEL or
			customType == appfun.GROUP_VOICE_SECRETCHANNEL ) ) then
		return true
	end
	return false
end

---- 2015-06-05 
---- 用户设置频道
---- 错误返回false，错误提示，
---- 正确返回true
function user_set_channel_info( accountID,  actionType, customType , customPar , customRemark , custom_dbname )
	local sql_tab = {}
	
	only.log('D', "user_set_channel_info===>=== %s" , actionType )

	if not ( actionType == appfun.DK_TYPE_VOICE or actionType == appfun.DK_TYPE_GROUP or actionType == appfun.DK_TYPE_COMMAND ) then
		only.log('E',string.format("[user_set_channel_info] actionType is error , actionType %s " , actionType ))
		return false, "MSG_ERROR_REQ_ARG"
	end

	---- 检查用户设置的key
	local sql_str = string.format( G.sql_check_keyinfo ,accountID, actionType)
	local ok ,ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
	if not ok or not ret and type(ret) ~= 'table' then
			only.log('E',string.format("query userKeyInfo by accountID %s failed! , %s ",accountID , sql_str ))
			return false,"MSG_DO_MYSQL_FAILED",sql_str
	end

	local cur_time = os.time()
	---- userKeyinfo 
	if #ret == 0  then
		----之前不存在,则直接插入
		local sql_str = string.format(G.sql_insert_keyinfo,accountID,actionType,customType,customPar or '',cur_time,cur_time , customRemark or '')
		table.insert(sql_tab, sql_str )

	else
		---- 简单设置用户按键信息
		local sql_str = string.format(G.sql_update_keyinfo ,customPar or '', customRemark or '', customType , cur_time ,accountID,actionType )
		table.insert(sql_tab, sql_str )

		---- 20150610
		---- 用户设置按键，更新join表中的数据
		---- 清理用户其他按键所关联的频道
		local sql_str = string.format(G.sql_clear_joinmemberlist,actionType, cur_time, accountID, customPar, actionType, actionType )
		table.insert(sql_tab,sql_str)

	end

	---- 2015-7-1
	---- bug:用户第一次设置按键，没更新joinMemberList表
	---- 设置用户关联当前按键

	local sql_str = string.format(G.sql_update_joinmemberlist, actionType, cur_time, accountID, customPar, actionType , actionType)
	table.insert(sql_tab,sql_str)

	---- 保存用户设置按键的历史信息
	local sql_str = string.format(G.sql_insert_joinmemberlisthistory,accountID, customPar)
	table.insert(sql_tab,sql_str)
	---- end

	local sql_str = string.format(G.sql_history_keyinfo ,accountID,actionType)
	table.insert(sql_tab, sql_str )

	---- modify by jiang z.s. 2015-10-04 
	---- optimize log detail 
	only.log('D',string.format("========debug info [user set channel info] update userKeyInfo by accountID %s , %s ",
											accountID , table.concat( sql_tab, "\r\n" ) ))

	local ok ,ret = mysql_api.cmd(custom_dbname,'AFFAIRS',sql_tab)
	if not ok or not ret then
		only.log('E',string.format("[user set channel info] update userKeyInfo by accountID %s failed! , %s ",accountID , table.concat( sql_tab, "\r\n" ) ))
		return false,"MSG_DO_MYSQL_FAILED",table.concat( sql_tab, "\r\n" )
	end
	return true
end

---- 获取用户的状态
---- 用户的状态 1正常 2禁言 3拉黑
---- Blacklist
function check_is_black(accountid, channel_idx)
	if channel_idx and #tostring(channel_idx) >= 9 then
	    local ok, ret = redis_api.cmd('private','hget', channel_idx .. ":userStatusTab", accountid .. ":status")
	    if not ok then
	        only.log('E',string.format(" accountid %s  channel_idx %s  get userStatusTab failed  " , accountid, channel_idx  ))
	        gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
	    end
	    if ret and tostring(ret) == "3" then
	        return true
	    end
	end
	return false
end

---- 判断用户是否在线
function check_user_is_online( account_id )
	local ok_status,ok_ret = redis_api.cmd('statistic','sismember',"onlineUser:set",account_id)
	return ok_status and ok_ret
end

function get_channel_idx( channel_num )
	local ok, idx = redis_api.cmd('private','get', channel_num .. ':channelID')
	if ok and idx then
		return idx 
	end
	return nil
end

---- get accountid:groupVoiceCustomType和accountid:currentChannel:groupVoice ,返回pre_type,pre_channel或者nil,nil
local function get_groupvoice_channel( accountID )		
	local ok, pre_type = redis_api.cmd('private', 'get',accountID .. ":groupVoiceCustomType")
	if ok and pre_type and ( tonumber(pre_type) == appfun.GROUP_VOICE_CHANNEL or tonumber(pre_type) == appfun.GROUP_VOICE_SECRETCHANNEL ) then
		local ok, pre_channel = redis_api.cmd('private','get', accountID .. ":currentChannel:groupVoice")
		if ok and pre_channel then
			return pre_type, pre_channel
		end
		return pre_type, pre_channel
	end
	return appfun.GROUP_VOICE_CHANNEL, get_channel_idx( default_channel )
end


---- get accountid:groupVoiceCustomType和accountid:voiceCommand，返回值pre_type和pre_channel
local function get_voicecommand_channel( accountID )
	local ok, pre_type = redis_api.cmd('private', 'get',accountID .. ":voiceCommandCustomType")
	if ok and pre_type and ( tonumber(pre_type) == appfun.VOICE_COMMAND_CHANNEL or tonumber(pre_type) == appfun.VOICE_COMMAND_SECRETCHANNEL ) then
		local ok, pre_channel = redis_api.cmd('private', 'get',accountID .. ":currentChannel:voiceCommand")
		if ok and pre_channel then
			return pre_type, pre_channel
		end
		return pre_type, pre_channel
	end
	return nil,nil
end

------=====================================set user key info 2015-05-21 begin===================================================

local function get_voicecommand_channel_info( accountID )
	local ok, pre_info = redis_api.cmd('private', 'mget',accountID .. ":voiceCommandCustomType", accountID .. ":currentChannel:voiceCommand" )
	if ok and pre_info and type(pre_info) == "table" then
		return pre_info[1], pre_info[2]
	end
	return nil,nil
end

---- accountid:groupVoiceCustomType
---- accountid:currentChannel:groupVoice 
---- 返回pre_type,pre_channel或者nil,nil
local function get_groupvoice_channel_info( accountID )		
	local ok, pre_info = redis_api.cmd('private', 'mget',accountID .. ":groupVoiceCustomType", accountID .. ":currentChannel:groupVoice" )
	if ok and pre_info and type(pre_info) == "table"  then
		return pre_info[1], pre_info[2]
	end
	return nil,nil
end

---- 20150804
---- 允许按键设为空
function set_channel_is_empty(accountid,actionType,customType,custom_dbname)

	only.log('D',string.format("accountid:%s,actionType:%s,customType:%s",accountid,actionType,customType))
	
	local sql_str = string.format( G.sql_check_keyinfo ,accountid, actionType)
	local ok ,ret = mysql_api.cmd(custom_dbname,'SELECT',sql_str)
	if not ok or not ret and type(ret) ~= 'table' then
		only.log('E',string.format("query userKeyInfo by accountID %s failed! , %s ",accountid , sql_str ))
		return false ,'MSG_DO_MYSQL_FAILED',sql_str
	end
	local sql_tab = {}
	local cur_time = os.time()
	---- 清除joinMemberList里的按键
	---- 同时将setUserKeyInfo设为无效
	if #ret > 0 and ret[1]['validity'] == '1' then
		local sql_str = string.format(G.sql_update_userkeyinfo,actionType,accountid )
		table.insert(sql_tab,sql_str)

		local sql_str = string.format(G.sql_clear_actiontype_empty ,actionType,cur_time,accountid,ret[1]['customParameter'])
		table.insert(sql_tab,sql_str)

		only.log('W',string.format("sql_update_userkeyinfo ! , %s " , sql_str))
		local ok ,ret = mysql_api.cmd(custom_dbname,'AFFAIRS',sql_tab)
		if not ok then
			only.log('E',string.format("sql_update_userkeyinfo failed! , %s " , table.concat(sql_tab,"\r\n") ))
			return false,'MSG_DO_MYSQL_FAILED' ,sql_str
		end
	end

	local pre_custom, pre_channel = get_voicecommand_channel_info(accountid)

	redis_api.cmd('private', 'del',accountid .. ":voiceCommandCustomType" )
	redis_api.cmd('private','del',accountid .. ":currentChannel:voiceCommand")

	if check_user_is_online(accountid) then
		if pre_channel then
			redis_api.cmd('statistic','srem', pre_channel .. ":channelOnlineUser", accountid )
		end
	end
							
	return true
end

---- local save voice command 
---- return true
local function set_redis_voicecommand_info( accountID, customType, channelID )
	
	local pre_custom, pre_channel = get_voicecommand_channel_info(accountID)

	only.log('D',string.format("[+]set_redis_voicecommand_info accountID:%s  \r\n pre_custom %s   pre_channel %s \r\ncur_custom %s cur_channel %s   ",
		accountID, pre_custom , pre_channel , customType , channelID ))

	if pre_custom  and tostring(customType) == pre_custom and tostring(channelID) ==  tostring(pre_channel) then
		---- 和之前的完全一致
		only.log('D',"[voice] is same pre setting 1")
		return true
	end

	redis_api.cmd('private', 'mset',
							accountID .. ":voiceCommandCustomType", 
							customType,
							accountID .. ":currentChannel:voiceCommand", 
							channelID )

	if tostring(channelID) ==  tostring(pre_channel) then 
		only.log('D',"[voice] is same pre setting 2")
		return true
	end

	if check_user_is_online(accountID) then
		----- 判断是否和++按键一致
		local pre_group_custom, pre_group_channel = get_groupvoice_channel_info(accountID)
		----- 2015-6-12
		----- ++ + 
		----- 1  2
		----- 1  1 需清除之前频道channelOnline
		----- 修改原因：如上图所示，没有清理2这个频道的channelOnlineUser，造成redis出现脏数据
		if pre_group_channel == channelID then
			---- 2015-7-1
			---- bug:如果之前频道不存在，srem删除失败
			if pre_channel then
				redis_api.cmd('statistic','srem', pre_channel .. ":channelOnlineUser", accountID )
			end
			---- end
			only.log('D',"[voice] is same the groupVoice setting")
			return true
		end
		---- end

		only.log('D',string.format("[voice] %s from: %s  to: %s ", accountID, pre_channel , channelID ))
		---- 2015-7-1
		---- bug:如果之前频道不存在，srem删除失败
		if pre_channel then
			redis_api.cmd('statistic','srem', pre_channel .. ":channelOnlineUser", accountID )
		end
		---- end

		---- 
		if not check_user_black_in_secret_channel(accountID,channelID) then
			redis_api.cmd('statistic','sadd', channelID .. ":channelOnlineUser", accountID )
		end
		return true
	end
	only.log('D',string.format("[voice] %s is offline", accountID))
	return true
end


local function set_redis_groupvoice_info( accountID, customType, channelID )

	local pre_custom, pre_channel = get_groupvoice_channel_info(accountID)

	only.log('D',string.format("[+]set_redis_groupvoice_info accountID:%s  \r\n pre_custom %s   pre_channel %s \r\ncur_custom %s cur_channel %s   ",
		accountID, pre_custom , pre_channel , customType , channelID ))

	---- [pre group voice is same ? ]
	if pre_custom  and tostring(customType) == pre_custom and tostring(channelID) ==  tostring(pre_channel) then
		---- 和之前的完全一致
		only.log('D',"[voice] 1 keep pre setting 1")
		return true
	end
	---- 2015-07-06
	---- 得到++键之前所设置的按键，如果不存在，则删除10086频道里的channelOnlineUser
	if not pre_channel and not pre_custom then
		local default_channel_idx = get_channel_idx( default_channel )
		redis_api.cmd('statistic','srem', default_channel_idx .. ":channelOnlineUser", accountID )
	end


	---- [set current redis-setting]
	redis_api.cmd('private', 'mset',
							accountID .. ":groupVoiceCustomType", 
							customType,
							accountID .. ":currentChannel:groupVoice", 
							channelID )

	if tostring(channelID) ==  tostring(pre_channel) then
		only.log('D',"[voice] is same pre setting 2")
		return true
	end

	if check_user_is_online(accountID) then
		----- 判断是否和++按键一致
		----- 2015-06-12
		----- 频道bug修改
		----- 修改原因：和上面类似，没有清理2这个频道的channelOnlineUser，造成redis出现脏数据
		----- [pre voice command]
		local pre_voice_custom, pre_voice_channel = get_voicecommand_channel_info(accountID)
		if pre_voice_channel == channelID then
			---- 2015-7-1
			---- bug:之前频道为nil
			if pre_channel then
				redis_api.cmd('statistic','srem', pre_channel .. ":channelOnlineUser", accountID )
			end
			---- end
			only.log('D',"[voice] is same the voiceCommand setting")
			return true
		end

		only.log('D',string.format("[voice] %s from: %s  to: %s ", accountID, pre_channel , channelID ))
		---- 2015-7-1
		---- bug:之前频道为nil
		if pre_channel then
			redis_api.cmd('statistic','srem', pre_channel .. ":channelOnlineUser", accountID )
		end
		---- end
		---- 2015-08-26 jiang z.s. 
		if not check_user_black_in_secret_channel(accountID,channelID) then
			redis_api.cmd('statistic','sadd', channelID .. ":channelOnlineUser", accountID )
		end

		return true
	end
	only.log('D',string.format("[voice] %s is offline", accountID))
	return true
end


---- 设置中间吐槽按键为服务频道
local function set_redis_mainvoice_info( accountID, actionType , customType  )
	
	only.log('D',"====set_redis_mainvoice_info==== %s %s %s ", accountID, actionType , customType )

	redis_api.cmd('private', 'set',
							accountID .. ":mainVoiceCustomType", 
							customType)
	return true
end


function save_user_keyinfo_to_redis( accountID, actionType, customType, channelID )

	only.log('D'," %s %s %s %s  ", accountID, actionType, customType, channelID)

	---- 20150707
	---- 修改bug
	---- channelID = nil 
	---- channelID = ""
	if channelID and #tostring(channelID) > 0  and #tostring(channelID) < 9  then
		only.log('E',"====save_user_keyinfo_to_redis==== %s %s %s %s", accountID, actionType , customType ,channelID)
		return false
	end

	if actionType == appfun.DK_TYPE_VOICE then
		return set_redis_mainvoice_info(accountID, actionType, customType)
	elseif actionType == appfun.DK_TYPE_COMMAND then

		----返回值true
		return set_redis_voicecommand_info(accountID, customType, channelID)
	elseif actionType == appfun.DK_TYPE_GROUP then
		----返回值true
		return set_redis_groupvoice_info(accountID,customType,channelID)
	end
	only.log('E',"==========save_user_custominfo_to_redis==error========")
end

function check_user_status_in_secret_channel(accountid, channel_id )
-- 判断用户当前所在频道的状态
-- 1 正常 / 2 禁言 / 3 拉黑 / 4 未审核通过
-- 针对 3 / 4 的情况,不允许把用户加入在线用户列表
	local ok, ret = redis_api.cmd('private','hget', channel_id .. ":userStatusTab", accountid .. ":status")
	return tonumber(ret) or 1
end

function check_user_black_in_secret_channel(accountid,channel_id)
	-- 判断用户当前所在频道的状态
	-- 1 正常 / 2 禁言 / 3 拉黑 / 4 未审核通过
	-- 针对 3 / 4 的情况,不允许把用户加入在线用户列表
	local ok, ret = redis_api.cmd('private','hget', channel_id .. ":userStatusTab", accountid .. ":status")
	if tonumber(ret) == 3 or tonumber(ret) == 4 then
		return true
	end
	return false
end
