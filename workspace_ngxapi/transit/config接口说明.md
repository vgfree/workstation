### 输入参数
请求参数:
```
curl -v  "http://192.168.71.55/config?kernelver=3_3_0&verno=drivereyes_V151227_1.0_P3_1.0.2&imsi=554766547629275&mod=SG900&imei=554766547629275&androidver=4_4_2&modelver=CV5021CBDL7FG_0022&basebandver=M6290A2_408_WM930_2___Nov_22_2013_07_44_17__EC78_&buildver=CV5021CBDL7FG_0022_20151209"
* About to connect() to 192.168.71.55 port 80 (#0)
*   Trying 192.168.71.55... connected
* Connected to 192.168.71.55 (192.168.71.55) port 80 (#0)
> GET /config?kernelver=3_3_0&verno=drivereyes_V151227_1.0_P3_1.0.2&imsi=554766547629275&mod=SG900&imei=554766547629275&androidver=4_4_2&modelver=CV5021CBDL7FG_0022&basebandver=M6290A2_408_WM930_2___Nov_22_2013_07_44_17__EC78_&buildver=CV5021CBDL7FG_0022_20151209 HTTP/1.1
> User-Agent: curl/7.19.7 (x86_64-redhat-linux-gnu) libcurl/7.19.7 NSS/3.14.0.0 zlib/1.2.3 libidn/1.18 libssh2/1.4.2
> Host: 192.168.71.55
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx
< Date: Wed, 11 May 2016 07:30:52 GMT
< Content-Type: text/plain
< Transfer-Encoding: chunked
< Connection: keep-alive
< RESULT: {"call1":"10086","call2":"10086","customargs":{"stopNewStatus":false,"groupVoice":true,"voiceCommand":true,"ktvMode":false},"tokencode":"HRSAB7ERmB","accountID":"","domain":"s9offline.mirrtalk.com","port":80}
<
* Connection #0 to host 192.168.71.55 left intact
* Closing connection #0
```
程序分析:
args = {
	["kernelver"] = "3_3_0",
	["buildver"] = "CV5021CBDL7FG_0022_20151209",
	["imsi"] = "554766547629275",
	["mod"] = "SG900",
	["imei"] = "554766547629275",
	["androidver"] = "4_4_2",
	["basebandver"] = "M6290A2_408_WM930_2___Nov_22_2013_07_44_17__EC78_",
	["modelver"] = "CV5021CBDL7FG_0022",
	["verno"] = "drivereyes_V151227_1.0_P3_1.0.2",
}
