
设置按键信息API
========================

### API编号
* 

### 功能简介
* 设置按键信息API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数 

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|------------------- |----------|--------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 申请账户           | string  | 2222222222    | 否           | 长度为10 
 parameter                  | 参数               | string  | 22222         | 否           | 长度不小于5
 accessToken                |令牌访问权限(由用户授权产生) | string | aaaaaaaaaaaaaaaaaaaaaaaaaaa | 否 |长度为32

 


### 返回结果参数 备注：+键 actionType=4 时候 customParameter 允许设置为空表示将该按键禁用频道
 actionType         | customType    |  功能说明   | customParameter  | status 
--------------------|---------------|-------------|------------------|---------
    3               |   10          |  路况分享   |      x           | true
    3               |   11          |  语音记事本 |      x           | true
    3               |   12          |  家人连线   |	     x           | true
    4               |   10          |  群聊频道   |	  密频道编码(空) | true
    5               |   10          |  群聊频道   |   密频道编码     | true



### 示例代码/clientcustom/v2/setUserkeyInfo

    POST /clientcustom/v2/setUserkeyInfo HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    appKey=1111111111&sign=3253330E067E4571BF3F34742EC78A4570EECFAB&parameter={"count":"1","list": [{"actionType":"3","customType":"10","customParameter":""}]}&accountID=1111111111&accessToken=c5f91a991bfd8ba1d55bbe576468d8b4


### 返回body示例

* 成功: 
		`{"ERRORCODE": "0", "RESULT": {"list": [{"status": true, "customParameter": "", "actionType": "3","customType": "10"}], "count": "1"}}`
* 失败: 
		`{"ERRORCODE":"ME01023", "RESULT":"accountID is error!"}`



### 返回结果参数

参数                  | 参数说明              
----------------------|----------------------------------------------
status                | true（成功）/ false（失败，用户在频道黑名单中）




### 错误编码

 参数                 | 错误描述                       | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | Request OK		               | 正常调用
 ME01003              | access token not matched       | 用户授权令牌不匹配
 ME01023              | parameter is error!            | 参数错误，请按照文档提供的参数要求传参
 ME01020              | mysql failed!          		   | 数据库错误 ,请与公司客服联系
 ME01024              | http body is null!             | 请与公司客服联系
 ME18312              | did not join				   | 当前用户从未加入群聊频道
 ME18316              | current customType is not exist| 当前自定义类型不存在，例如：customType = "10"


### 测试地址: api.daoke.io/clientcustom/v2/setUserkeyInfo

