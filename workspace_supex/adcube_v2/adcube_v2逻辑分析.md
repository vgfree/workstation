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







curl -H "appKey:1858017065" -H "time:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":"",],"typ":"1", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr", "citycode":"301100", "lng":121.4434, "lat":31.22, "diff":"1"}' -v http://192.168.71.94/abcube_set

curl -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":"",] , "adtime":"07:00-07:59|13:00-13:59", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr",  "appKey":"1858017065", "sign":"45456asdfserwerwefasdfsdf"}' -v http://192.168.71.94:9009/adcube_set
curl -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":""] , "adtime":"07:00-0759|13:00-13:59", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr",  "appKey":"1858017065", "sign":"45456asdfserwerwefasdfsdf"}' -v http://192.168.71.94:9009/adcube_set
curl -d '{"adtime":"07:00-0759|13:00-13:59", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr",  "appKey":"1858017065", "sign":"45456asdfserwerwefasdfsdf"}' -v http://192.168.71.94:9009/adcube_set
curl -d '{"sign":"45456asdfserwerwefasdfsdf"}' -v http://192.168.71.94:9009/adcube_set
curl -H "appKey":"1858017065" -H "sign":"45456asdfserwerwefasdfsdf" -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":"",] , "adtime":"07:00-0759|13:00-13:59", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr"}' -v http://192.168.71.94:9009/adcube_set
curl -H "appKey":"1858017065" -H "sign":"45456asdfserwerwefasdfsdf" -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":""] , "adtime":"07:00-0759|13:00-13:59", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr"}' -v http://192.168.71.94:9009/adcube_set
curl -H "appKey":"1858017065" -H "sign":"45456asdfserwerwefasdfsdf" -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":""], "adtime":"07:00-0759", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr"}' -v http://192.168.71.94:9009/adcube_set
curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "time":"1458266656" -H "cid":"PdL1eoEl7P"  -d '{"typ":"2", "lng":121.4434, "lat":31.22, "speed":22, "dir":76}' -v http://192.168.71.94:9009/adcube_get
curl -H "appKey":"1858017065" -H "sign":"45456asdfserwerwefasdfsdf" -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":""] , "adtime":"07:00-0759|13:00-13:59", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr"}' -v http://192.168.71.94:9009/adcube_set
curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "time":"1458266656" -H "cid":"PdL1eoEl7P"  -d '{"typ":"2", "lng":121.4434, "lat":31.22, "speed":22, "dir":76}' -v http://192.168.71.94:9009/adcube_get


curl -v -H "Content-Type:application/json" "http://127.0.0.1:9009/adcube_get" -d '{"cid":"441116606054915","lat":31.211912,"lng":121.513249,"typ":"4","appKey":"1027395982","sign":"93087546DADD06AA764F509D054B98380F5F6215","speed":0,"dir":0,"time":1461829149}'
curl -v -H "Content-Type:application/json" "http://127.0.0.1:9009/adcube_get" -d '{"cid":"441116606054915","lat":0,"lng":0,"typ":"4","appKey":"1027395982","sign":"93087546DADD06AA764F509D054B98380F5F6215","speed":0,"dir":0,"time":1461829149}'


curl  -v -H "Content-Type:application/json" "http://127.0.0.1:9009/adcube_cb" -d  '{"sign":"4F5A41640F58E7C94D48809D4F90DF54E980C923","time":"1461829537496","vol":"0","speed":"4","dir":"149","token":"c8bdd08385359a35","status":"2","report":"{\"vol\":\"0\",\"dir\":\"149\",\"speed\":\"4\",\"status\":\"2\",\"token\":\"c8bdd08385359a35\",\"fileurl\":\"\",\"lng\":\"120.2929557861018\",\"filetype\":\"\",\"lat\":\"30.41962821970733\"}","lng":120.2929557861018,"aid":"7","cid":"863178022574685","lat":"30.41962821970733","appKey":"1858017065"}'
curl -v -H "Content-Type:application/json" "http://127.0.0.1:9009/adcube_get" -d '{"cid":"441116606054915","lat":31.211912,"lng":121.513249,"typ":"4","appKey":"1027395982","sign":"93087546DADD06AA764F509D054B98380F5F6215","speed":0,"dir":0,"time":1461829149}'
curl  -v -H "Content-Type:application/json" "http://127.0.0.1:9009/adcube_cb" -d  '{"sign":"4F5A41640F58E7C94D48809D4F90DF54E980C923","time":"1461829537496","vol":"0","speed":"4","dir":"149","token":"c8bdd08385359a35","status":"2","report":"{\"vol\":\"0\",\"dir\":\"149\",\"speed\":\"4\",\"status\":\"2\",\"token\":\"c8bdd08385359a35\",\"fileurl\":\"\",\"lng\":\"120.2929557861018\",\"filetype\":\"\",\"lat\":\"30.41962821970733\"}","lng":120.2929557861018,"aid":"7","cid":"863178022574685","lat":"30.41962821970733","appKey":"1858017065"}'
curl  -v -H "Content-Type:application/json" "http://127.0.0.1:9009/adcube_cb" -d  '{"mid":"1461858996lDlqjEN4s2","sign":"4F5A41640F58E7C94D48809D4F90DF54E980C923","time":"1461829537496","vol":"0","speed":"4","dir":"149","token":"c8bdd08385359a35","status":"2","report":{"vol":"0","dir":"149","speed":"4","status":"2","token":"c8bdd08385359a35","fileurl":"","lng":"120.2929557861018","filetype":"","lat":"30.41962821970733"},"lng":120.2929557861018,"aid":"7","cid":"863178022574685","lat":"30.41962821970733","appKey":"1858017065"}'
curl  -v -H "Content-Type:application/json" "http://127.0.0.1:9009/adcube_cb" -d  '{"sign":"4F5A41640F58E7C94D48809D4F90DF54E980C923","time":"1461829537496","vol":"0","speed":"4","dir":"149","token":"c8bdd08385359a35","status":"2","report":"{\"vol\":\"0\",\"dir\":\"149\",\"speed\":\"4\",\"status\":\"2\",\"token\":\"c8bdd08385359a35\",\"fileurl\":\"\",\"lng\":\"120.2929557861018\",\"filetype\":\"\",\"lat\":\"30.41962821970733\"}","lng":120.2929557861018,"aid":"7","cid":"863178022574685","lat":"30.41962821970733","appKey":"1858017065"}'
