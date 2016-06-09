### adcube_set
1. 取广告号 aid
每次+1
aid  = redis_api.cmd( 'private1', '', 'incr', SET_AID)

拼接
caid = "A_" .. aid

2. 集合存储
GPS = 'GPS'
gps = redis_api.cmd( 'private1','', 'sadd', GPS, caid)

3. 哈希存储
tostring(citycode) == "nil" 时

计算坐标
local x0,x1,y1,y0  = calculate(lng,lat,diff)

gps_aid = redis_api.cmd( 'private1','', 'hmset', caid ,'Content',content,'Adtime',adtime,'Typ',typ,'Cburl',cburl,'X0',x0,'X1',x1,'Y1',y1,'Y0',y0,'Diff',diff)
key : caid 广告号
value : content adtime typ cburl x0 x1 y1 y0 diff   广告内容 时间段 类型 回调URI 坐标 范围

tostring(citycode) ~= "nil" 时

将caid加入到对应的城市中
city = redis_api.cmd( 'private1','' ,'sadd', tab_city[i] ,caid)

city_aid = redis_api.cmd( 'private1','', 'hmset', caid ,'Citycode',citycode,'Content',content,'Adtime',adtime,'Typ',typ,'Cburl',cburl)
key : caid 广告号
value :  citycode content adtime typ cburl  城市编号 广告内容 时间段 类型 回调URI

总结: 在set中, 主要是以caid为key, 存储指定地区的指定时间段的指定广告内容 为key, 以供后续调用

# adcude_del
1. 获取 广告号aid1 的表
aid_table = redis_api.cmd('private1', '', 'hgetall', aid1)

2.
aid_table.Diff ~= nil 时 也就是说此时是以gps来存储的
ret = redis_api.cmd('private1','','srem','GPS',aid1)
此处GPS 就是个字符串, 它的value有好多个aid

ret = redis_api.cmd('private1','','del',aid1)

aid_table.Diff == nil 时 此时是以citycode来存储的
ret = redis_api.cmd('private1','','srem',tab_city[i],aid1)

ret = redis_api.cmd('private1','','del',aid1)

# adcude_get
1. 根据GPS取出aid , 在一个GPS下可能存储了多个广告aid
id_info = redis_api.cmd("private1", '', "SMEMBERS", "GPS")

2. 根据aid查询相应的广告信息,
value_tab = redis_api.cmd("private1", '', "HGETALL", id_info[i])
