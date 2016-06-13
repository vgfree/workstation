1. 搭建地址
   ip: 192.168.71.51

2. 数据库信息
   mysql : 192.168.71.85:3306
   user :

```bash
curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chName":"tianlongbabu", "chType":1, "reType":0, "chIntro":"武侠", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"众生皆苦,求而不得"}' -v http://192.168.130.76/channelapi/createChannel

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"chID":"10000", "reType":1, "chName":"ludingji", "chIntro":"都是我老婆", "aIntro":"金庸", "chLogo":"http://img1.mydrivers.com/img/20160519/2e6338af76364039aeadd114e121feb1.jpg", "keyWords":"找老婆,做大官"}' -v http://192.168.130.76/channelapi/modifyChannel


```
