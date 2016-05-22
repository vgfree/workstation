curl -v -F "filename=@/home/louis/Pictures/test.jpg" -F "length=115339" -F "isStorage=true" -F "cacheTime=200" -H "appkey:1858017065" -H "sign:1545678adsfaf234234234wf" http://192.168.71.84:2223/dfsapi/v2/saveImage


curl -H "appkey:3055426974" -H "accountid:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"imei":"147258369015935","imsi":"460011234453214","modeVer":"sony","androidVer":"5.1","baseBandVer":"","kernelVer":"","buildVer":"","lcdwidth":1080,"lcdHeight":1920}' -v http://127.0.0.1/login

curl -H "appkey:1858017065" -H "accountid:lW3B5D0mtj" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -v http://127.0.0.1/club/accountInfo/queryInfoByID

curl -H "appkey:1858017065" -H "refreshtoken:sdfsdfsdf23423423" -H "sign:45456asdfserwerwefasdfsdf" -v http://127.0.0.1/refreshTrustAccesstoken

curl -v -H "appkey:1255603831" -H "accountid:fuz1mli7Tl" -H "token:71e87e49e78e83c007dff96918f27098" -H "timestamp:1461760461" -H "sign:71e87e49e78e83c007dff96918f27098" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/ro%ad/img/11736.jpg", "introduction":"呵呵呵", "carBrand":"1", "carModel":"30", "carNumber":"asdfgh"}' http://127.0.0.1/club/accountInfo/updateInfoByID





curl -H "appKey:1858017065" -H "accountID:gI0IPLlElv" -H
"accessToken:1472583690" -H "timestamp:1458266656" -H
"sign:45456asdfserwerwefasdfsdf" -v
http://192.168.71.85/club/accountInfo/queryInfoByID

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"imei":"147258369015935","imsi":"460011234453214","modeVer":"sony","androidVer":"5.1","baseBandVer":"","kernelVer":"","buildVer":"","lcdwidth":1080,"lcdHeight":1920}' -v http://192.168.71.85/login

curl -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -v http://192.168.71.85/club/accountInfo/queryInfoByID

curl -H "appKey:1858017065" -H "sign:45456asdfserwerwefasdfsdf" -d "{'refreshToken':'sdfsdfsdf23423423'}" -v http://192.168.71.85/refreshTrustAccesstoken

curl -v -H "appKey:1858017065" -H "accountID:e8O1W0ytqy" -H "tokenCode:71e87e49e78e83c007dff96918f27098" -H "timestamp:1461760461" -H "sign:71e87e49e78e83c007dff96918f27098" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/ro%ad/img/11736.jpg", "introduction":"呵呵呵", "carBrand":"1", "carModel":"30", "carNumber":"asdfgh"}' http://192.168.71.85/club/accountInfo/updateInfoByID








       ret_userInfo                    = {}
       ret_userInfo['nickName']        = (parameter_tab['nickName'] == nil and "") or parameter_tab['nickName']
       ret_userInfo['headPic']         = (parameter_tab['headPic'] == nil and "") or parameter_tab['headPic']
       ret_userInfo['birthday']        = (parameter_tab['birthday'] == nil and "") or parameter_tab['birthday']
       ret_userInfo['sex']             = (parameter_tab['sex'] == nil and 0) or tonumber(parameter_tab['sex'])
       ret_userInfo['cityName']        = (parameter_tab['cityName'] == nil and "") or parameter_tab['cityName']
       ret_userInfo['cityCode']        = (parameter_tab['cityCode'] == nil and "") or parameter_tab['cityCode']
       ret_userInfo['introduction']    = (parameter_tab['introduction'] == nil and "") or parameter_tab['introduction']
       ret_userInfo['carBrand']        = (parameter_tab['carBrand'] == nil and "") or parameter_tab['carBrand']
       ret_userInfo['carModel']        = (parameter_tab['carModel'] == nil and "") or parameter_tab['carModel']
       ret_userInfo['carNumber']       = (parameter_tab['carNumber'] == nil and "") or parameter_tab['carNumber']
