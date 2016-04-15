
ip : 192.168.1.207


返回:		
```
curl -H "appKey:bcYtC65Gc89" -H "accountId:PdL1eoEl7P" -H
"accessToken:1472583690" -H "timestamp:1458266656" -H
"sign:45456asdfserwerwefasdfsdf" -d
"imei=147258369015935&imsi=460011234453214&modeVer=sony&androidVer=5.1&baseBandVer=5.11&kernelVer=2.6.3&buildVer=C6903&lcdWidth=1080&lcdHeight=1920"
-v http://192.168.1.207/login
* About to connect() to 192.168.1.207 port 80 (#0)
	*   Trying 192.168.1.207... connected
	* Connected to 192.168.1.207 (192.168.1.207) port 80 (#0)
	> POST /login HTTP/1.1
	> User-Agent: curl/7.19.7 (x86_64-redhat-linux-gnu) libcurl/7.19.7
	> NSS/3.13.6.0 zlib/1.2.3 libidn/1.18 libssh2/1.4.2
	> Host: 192.168.1.207
	> Accept: */*
		      > appKey:bcYtC65Gc89
		      > accountId:PdL1eoEl7P
		      > accessToken:1472583690
		      > timestamp:1458266656
		      > sign:45456asdfserwerwefasdfsdf
		      > Content-Length: 146
		      > Content-Type: application/x-www-form-urlencoded
		      > 
		      < HTTP/1.1 200 OK
		      < Server: nginx
		      < Date: Fri, 15 Apr 2016 03:09:54 GMT
		      < Content-Type: application/json
		      < Transfer-Encoding: chunked
		      < Connection: keep-alive
		      < 
		      {"err":"0", "result":{"token":"X0myMsXHeT",
		      "msgToken":"1478523690", "accountID":"PdL1eoEl7P",
		      "base":{"msgServer":"scsever.daoke.me", "msgPort":8282,
		      "heart":30,
		      "fileUrl":"http://oss-cn-hangzhou.aliyuncs.com"},
		      "roadRank":{"rrIoUrl":"http://rtr.daoke.io/roadRankapi",
		      "normalRoad":1000, "highRoad":5000, "askTime":180},
		      "sicong":{"serverType":1}, "userInfo":{"sex":1,
		      "nickName":"wsy",
		      "headerUrl":"http://roadrank.daoke.me/road/img/11736.jpg",
		      "cityName":"新乡市"}}}
		      * Connection #0 to host 192.168.1.207 left intact
		      * Closing connection #0
```
