###

> URL : Universal Resource Locator 统一资源定位符		
> URI : Universal Resource Identifier 统一资源标志符
> URN : Universal Resource Name 统一资源名称

URL: www.xxx.com/hello/sayHello.do
URI: hello/sayHello.do		
URN: sayHello.do

URI 可以分为URL, URN或同时具备locators 和names 特性的一个东西, URN就像一个人的
名字, URL就像一个人的地址. URN确定了资源的身份, URL提供了找到他的方式.		

URL是 URN的一种		
URL比URI多的就是访问机制(网络位置), e.g. http:// or ftp://

URI 示例(包含访问机制的也是URL)
```
ftp://ftp.is.co.za/rfc/rfc1808.txt (also a URL because of the protocol)
http://www.ietf.org/rfc/rfc2396.txt (also a URL because of the protocol)
ldap://[2001:db8::7]/c=GB?objectClass?one (also a URL because of the protocol)
mailto:John.Doe@example.com (also a URL because of the protocol)
news:comp.infosystems.www.servers.unix (also a URL because of the protocol)
tel:+1-816-555-1212
telnet://192.0.2.16:80/ (also a URL because of the protocol)
urn:oasis:names:specification:docbook:dtd:xml:4.1.2
```

形如 `files.hp.com` 的是URI ,因为没有访问机制,他可以对应不同的协议和端口
如: http://files.hp.com		
ftp://files.hp.com


curl -H "appKey:bcYtC65Gc89" -H "accountId:PdL1eoEl7P" -H
"accessToken:1472583690" -H "timestamp:1458266656" -H
"sign:45456asdfserwerwefasdfsdf" -d
"imei=147258369015935&imsi=460011234453214&modeVer=sony&androidVer=5.1&baseBandVer=5.11&kernelVer=2.6.3&buildVer=C6903&lcdWidth=1080&lcdHeight=1920"
-v http://192.168.1.207/


curl -v -H "appKey:zMm6mlT7jM" -H "accountId:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/road/img/11736.jpg"}' http://192.168.1.207/club/accountInfo/updateInfoByID












curl -v -H "appKey:zMm6mlT7jM" -H "accountId:e8O1W0ytqy" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/road/img/11736.jpg", "incroduction":"呵呵呵", "carBrand":1, "carModel":30, "carNumber":"asdfgh"}' http://192.168.1.207/club/accountInfo/updateInfoByID

curl -v -H "appKey:zMm6mlT7jM" -H "accountId:jwlE3wYHYz" -H "accessToken:1472583690" -H "timestamp:1458266656" -H "sign:45456asdfserwerwefasdfsdf" -d '{"nickName": "樊少皇","cityName": "上海","cityCode": "600012","sex": 1,"birthday": "1990-03-15","headPic": "http://roadrank.daoke.me/ro%ad/img/11736.jpg", "incroduction":"呵呵呵" "carrBrand":1, "carModel":30, "carNumber":"asdfgh"}' http://192.168.1.207/club/accountInfo/updateInfoByID






curl -H "appKey:bcYtC65Gc89" -H "accountId:PdL1eoEl7P" -H
"accessToken:1472583690" -H "timestamp:1458266656" -H
"sign:45456asdfserwerwefasdfsdf" -d
'{"imei":"147258369015935","imsi":"460011234453214","modeVer","sony","androidVer":"5.1","baseBandVer"="","kernelVer":"","buildVer","","lcdWidth":1080,"lcdHeight":1920}'
-v http://192.168.1.207/login
