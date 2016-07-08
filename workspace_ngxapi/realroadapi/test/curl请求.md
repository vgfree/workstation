curl -v -F "filename=@/home/louis/Pictures/test.jpg" -F "length=115339" -F "isStorage=true" -F "cacheTime=200" -H "appkey:1858017065" -H "sign:1545678adsfaf234234234wf" http://192.168.71.84:2223/dfsapi/v2/saveImage


curl -H "appkey:3055426974" -H "accountid:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"imei":"147258369015935","imsi":"460011234453214","modeVer":"sony","androidVer":"5.1","baseBandVer":"","kernelVer":"","buildVer":"","lcdwidth":1080,"lcdHeight":1920}' -v http://127.0.0.1/login

curl -H "appkey:1858017065" -H "accountid:lW3B5D0mtj" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -v http://127.0.0.1/club/accountInfo/queryInfoByID

curl -H "appkey:1858017065" -H "refreshtoken:sdfsdfsdf23423423" -H "sign:45456asdfserwerwefasdfsdf" -v http://127.0.0.1/refreshTrustAccesstoken

curl -v -H "appkey:1255603831" -H "accountid:fuz1mli7Tl" -H "token:71e87e49e78e83c007dff96918f27098" -H "timestamp:1461760461" -H "sign:71e87e49e78e83c007dff96918f27098" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/ro%ad/img/11736.jpg", "introduction":"呵呵呵", "carBrand":"1", "carModel":"30", "carNumber":"asdfgh"}' http://127.0.0.1/club/accountInfo/updateInfoByID

curl -H "appkey:3055426974" -H "accountid:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"imei":"147258369015935","imsi":"460011234453214","modeVer":"sony","androidVer":"5.1","baseBandVer":"","kernelVer":"","buildVer":"","lcdwidth":1080,"lcdHeight":1920}' -v http://127.0.0.1/login

curl -H "appKey":"bcYtC65Gc89" -H "sign":"45456asdfserwerwefasdfsdf" -H "timestamp":"1467876519" -H "accountID":"PdL1eoEl7P" -d '{"type":1, "citycode":"301000|300000|100000|2000000", "cburl":"http://roadrank.daoke.me/ro%ad/img/11736.jpg","adtime":"0|1|5|7|", "content":{"reportURL":"http://ww2.sinaimg.cn/mw690/78d4c24cgw1f5livnor7ij21kw147dz7.jpg", "url":"http://s1.dwstatic.com/group1/M00/5F/9F/4aa6375b38194b32a304b1d30bfd72f0.jpg", "isRepeat":"3", "bgColor":"12345", "logoUrl":"http://image.mmfile.daoke.me/dfsapi/v2/gainImage?isStorage=true%26group=dfsdb_1%26file=1463399617%3Ad35556ee1b5c11e6aab100505681e231.jpg", "text":"hello world" }}' -v http://192.168.130.76/ad_set
