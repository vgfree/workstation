### 客户端请求头内容
req_heads = POST /weiboapi/v2/sendMultimediaGroupWeibo HTTP/1.0
Host:192.168.1.207
Content-Length:1237
Content-Type:multipart/form-data;boundary=------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
### 客户端请求体
req_body = --------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="level"

20
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="groupID"

111111111
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="skipChannelAuthorize"

1
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="receiveSelf"

0
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="multimediaURL"

http://v1.mmfile.daoke.me/dfsapi/v2/gainSound?isStorage=true%26group=dfsdb_8%26file=1457401032%3A480ca2aae4ce11e58faa984be10d2298.amr
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="senderAccountID"

lAmQoflGq1
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="appKey"

2064302565
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU
Content-Disposition:form-data;name="interval"

600
--------WebKitFormBoundaryDcO1SS14537899027797338MTDfpuu1453789902kkU--

### 经过解析后的返回值
body_args = {
	["level"] = "20",
	["groupID"] = "111111111",
	["interval"] = "600",
	["appKey"] = "2064302565",
	["multimediaURL"] = "http://v1.mmfile.daoke.me/dfsapi/v2/gainSound?isStorage=true%26group=dfsdb_8%26file=1457401032%3A480ca2aae4ce11e58faa984be10d2298.amr",
	["receiveSelf"] = "0",
	["skipChannelAuthorize"] = "1",
	["senderAccountID"] = "lAmQoflGq1",
}

### 生成body_args.bizid
body_args["bizid"] = a2cf10ee22eff611e5bf50000c29ae7997

### 保存消息到数据库
weibo_fun.group_save_message_to_msgredis(body_args)
