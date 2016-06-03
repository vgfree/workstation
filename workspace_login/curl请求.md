curl -v -F "filename=@/home/louis/Pictures/test.jpg" -F "length=115339" -F "isStorage=true" -F "cacheTime=200" -H "appkey:1858017065" -H "sign:1545678adsfaf234234234wf" http://192.168.71.84:2223/dfsapi/v2/saveImage


curl -H "appKey:3055426974" -H "accountID:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"imei":"147258369015935","imsi":"460011234453214","modeVer":"sony","androidVer":"5.1","baseBandVer":"","kernelVer":"","buildVer":"","lcdwidth":1080,"lcdHeight":1920}' -v http://127.0.0.1/login

curl -H "appkey:1858017065" -H "lW3B5D0mtj" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -v http://127.0.0.1/club/accountInfo/queryInfoByID

curl -H "appkey:1858017065" -H "refreshtoken:sdfsdfsdf23423423" -H "sign:45456asdfserwerwefasdfsdf" -v http://127.0.0.1/refreshTrustAccesstoken

curl -v -H "appkey:1255603831" -H "accountid:fuz1mli7Tl" -H "token:71e87e49e78e83c007dff96918f27098" -H "timestamp:1461760461" -H "sign:71e87e49e78e83c007dff96918f27098" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/ro%ad/img/11736.jpg", "introduction":"呵呵呵", "carBrand":"1", "carModel":"30", "carNumber":"asdfgh"}' http://127.0.0.1/club/accountInfo/updateInfoByID


curl -H "appkey:3055426974" -H "accountid:e8O1W0ytqy" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -v http://127.0.0.1/getMsgToken



curl -H "appKey:1858017065" -H "accountID:gI0IPLlElv" -H
"accessToken:1472583690" -H "timestamp:1458266656" -H
"sign:45456asdfserwerwefasdfsdf" -v
http://192.168.71.85/club/accountInfo/queryInfoByID

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"imei":"147258369015935","imsi":"460011234453214","modeVer":"sony","androidVer":"5.1","baseBandVer":"","kernelVer":"","buildVer":"","lcdwidth":1080,"lcdHeight":1920}' -v http://192.168.71.85/login

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -v http://192.168.71.85/club/accountInfo/queryInfoByID

curl -H "appKey:1858017065" -H "sign:45456asdfserwerwefasdfsdf" -d "{'refreshToken':'sdfsdfsdf23423423'}" -v http://192.168.71.85/refreshTrustAccesstoken

curl -v -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1461760461" -H "sign:71e87e49e78e83c007dff96918f27098" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/ro%ad/img/11736.jpg", "introduction":"呵呵呵", "carBrand":"1", "carModel":"30", "carNumber":"asdfgh"}' http://192.168.71.85/club/accountInfo/updateInfoByID

curl -v  http://192.168.71.85/syncUserInfo



channelapi

%s/\s\+$//

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"tianlongbabu", "chType":1, "chIntro":"武侠", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"众生皆苦,求而不得"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"sanguoyanyi", "chType":2, "chIntro":"发家致富", "aIntro":"施耐庵", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"三国鼎立,杀杀杀"}' -v http://192.168.130.76/channelapi/createChannel

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
