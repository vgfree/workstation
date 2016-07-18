curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"tianlongbabu", "chType":1, "reType":0, "chIntro":"武侠", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"众生皆苦,求而不得"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"sanguoyanyi", "chType":2, "chIntro":"发家致富", "aIntro":"施耐庵", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"三国鼎立,杀杀杀"}' -v http://127.0.0.1/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"shuihuzhuan", "chType":2, "chIntro":"上梁山", "aIntro":"施耐庵", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"大块吃肉,大碗喝酒"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"hongloumeng", "chType":2, "chIntro":"一群公子小姐", "aIntro":"曹雪芹", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"妹子,都是我的"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10000"}' -v http://192.168.130.76/channelapi/dissolveChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10000", "chName":"ludingji", "chIntro":"都是我老婆", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"找老婆,做大官"}' -v http://192.168.130.76/channelapi/modifyChannel

curl -H "appKey:1858017065" -H "accountID:1234567890" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10023", "remark":"炎发灼眼"}' -v http://192.168.130.76/channelapi/joinChannel

curl -H "appKey:1858017065" -H "accountID:1234567890" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10004"}' -v http://192.168.130.76/channelapi/quitChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10000", "action":2}' -v http://192.168.130.76/channelapi/blockChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10000", "blkID":["1234567890", "1234567891", "1234567892"], "setType":1}' -v http://192.168.130.76/channelapi/setChannelBlackList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10000"}' -v http://192.168.130.76/channelapi/getChannelInfo

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"UID":"e8O1W0ytqy"}' -v http://192.168.130.76/channelapi/getChannelList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10001", "jockeyList"=["1234567892","1234567891"]}' -v http://192.168.130.76/channelapi/setJockeyList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"鬼吹灯", "chType":1, "chIntro":"探险", "aIntro":"天下霸唱", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"人点烛,鬼吹灯"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10004"}' -v http://192.168.130.76/channelapi/getUserList

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -H "mirrtalkID:12345678901234567890123456789012" -v https://dc.daoke.me/getMsgToken

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10004"}' -v http://192.168.130.76/channelapi/getUserList



curl -H "appKey:1858017065" -H "time:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":"",],"typ":"1", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr", "citycode":"301100", "lng":121.4434, "lat":31.22, "diff":"1"}' -v http://192.168.71.94:9009/abcube_set


curl -H "appKey":"1858017065" -H "sign":"45456asdfserwerwefasdfsdf" -d '{"content":["text":"一小时帮忙拉","url":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr","urlType":"amr","isRepeat":"1", "es":""], "adtime":"07:00-0759", "typ":"1", "citycode":"301100", "cburl":"http://g4.tweet.daoke.me/group4/M06/33/5F/rBBHBVaN1UiAZ09VAAAGGHISzSk095.amr"}' -v http://192.168.71.94:9009/adcube_set


curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "time":"1458266656" -H "cid":"PdL1eoEl7P"  -d '{"typ":"2", "lng":121.4434, "lat":31.22, "speed":22, "dir":76}' -v http://192.168.71.94:9009/adcube_get

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "time":"1458266656" -H "cid":"PdL1eoEl7P"  -d '{"aid":"2", "mid":"jhsdhdfkha832489023490", "report":["token":"93518a2eddfe9a3d","status":"2","fileurl":"","filetype":"","lng":121.8754,"lat":31.22324,"speed":23,"dir":128,"vol":2]}' -v http://192.168.71.94:9009/adcube_cb


curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "aid":"PdL1eoEl7P" -v http://192.168.71.94:9009/adcube_del


curl -H "appKey":"1858017065" -H "sign":"6981D496DD5DE6523A47B4559AAB6800CF2EB509" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"type":1, "lon":121.424428, "lat":31.354628, "isHorizontal":false, "width":768, "height":1024, "mac":"127.0.0.1"}' -v  https://rtr.daoke.me/adGet

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "aid":"PdL1eoEl7P" -d '{"adtime":"0|1|5|7", "typ":"1", "citycode":"230900|469000|460200|301000|", "cburl":"http://ww2.sinaimg.cn/mw690/78d4c24cgw1f5livnor7ij21kw147dz7.jpg", "content":{"url":"http://s1.dwstatic.com/group1/M00/5F/9F/4aa6375b38194b32a304b1d30bfd72f0.jpg","text":"哈哈哈","bgColor":"1234","isRepeat":"3","logoUrl":"http://image.mmfile.daoke.me/dfsapi/v2/gainImage?isStorage=true%26group=dfsdb_1%26file=1463399617%3Ad35556ee1b5c11e6aab100505681e231.jpg"}}' -v https://rtr.daoke.me/adSet

HMSET A1 isOpen true isSelf true imgURL http://img1.gamersky.com/image2014/10/20141021lr_1/gamersky_13origin_25_201410301722C42.jpg reportURL http://ww2.sinaimg.cn/mw690/78d4c24cgw1f5livnor7ij21kw147dz7.jpg

HMSET A2 isOpen true isSelf true imgURL http://s1.dwstatic.com/group1/M00/5F/9F/4aa6375b38194b32a304b1d30bfd72f0.jpg reportURL http://s1.dwstatic.com/group1/M00/91/3C/79d400a4cf73739d2d2df10281664768.jpg

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"aid":"A1", "lon":121.4434, "lat":31.22,  "mac":"127.0.0.1"}' -v https://192.168.130.76/adReport



curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"aid":"A1", "lon":121.4434, "lat":31.22,  "mac":"127.0.0.1"}' -v https://rtr.daoke.me/adReport

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"adtime":"0|1|5|7", "typ":"1", "citycode":"230900|469000|460200|301000|", "cburl":"http://ww2.sinaimg.cn/mw690/78d4c24cgw1f5livnor7ij21kw147dz7.jpg"}' -v http://192.168.130.76/adSet




curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"adtime":"0|1|5|7", "typ":"1", "citycode":"230900|469000|460200|301000|", "cburl":"http://ww2.sinaimg.cn/mw690/78d4c24cgw1f5livnor7ij21kw147dz7.jpg"}' -v https://rtr.daoke.me/adSet


curl  -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"adtime":"0|1|5|7", "typ":"1", "citycode":"230900|469000|460200|301000|", "cburl":"http://ww2.sinaimg.cn/mw690/78d4c24cgw1f5livnor7ij21kw147dz7.jpg", "content":{"ot":"m", "url":"http://s1.dwstatic.com/group1/M00/5F/9F/4aa6375b38194b32a304b1d30bfd72f0.jpg","text":"哈哈哈","bgColor":"1234","isRepeat":"3","logoUrl":"http://image.mmfile.daoke.me/dfsapi/v2/gainImage?isStorage=true%26group=dfsdb_1%26file=1463399617%3Ad35556ee1b5c11e6aab100505681e231.jpg"}}' -v  http://192.168.130.76/adSet



curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"aid":"A_4"}' -v http://rtr.daoke.me/adDel

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"type":1, "citycode":"000000", "cbURL":"http://s1.dwstatic.com/cb","adtime":"24", "content":{"ot":"m","isOpen":"false", "isSelf":"true","reportURL":"http://pic1.win4000.com/pic/c/86/59d71086605.jpg", "imgURL":"http://cloud.rechaos.com/8/b/9/a/d/c/4/6/d/e/3.jpg"}}' -v https://rtr.daoke.me/adSet

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"type":2, "lon":121.443400, "lat":31.220000, "isHorizontal":false, "width":768, "height":1024, "mac":"127.0.0.1"}' -v https://rtr.daoke.me/adGet







curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"type":1, "citycode":"000000", "cbURL":"http://s1.dwstatic.com/cb","adtime":"24", "content":{"ot":"m","isOpen":"false", "isSelf":"true","reportURL":"http://pic1.win4000.com/pic/c/86/59d71086605.jpg", "imgURL":"http://cloud.rechaos.com/8/b/9/a/d/c/4/6/d/e/3.jpg"}}' -v http://192.168.130.76/adSet


curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -v http://192.168.130.76/adList
