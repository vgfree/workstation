
给用户更新帐户信息的API
========================

为用户更新帐户信息,编号：S0111V2
---------------------

### 注明

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.
* 签名计算: 各个参数按照其 key 的字典序排列,然后用 SHA1 加密, 签名值计算出来后, 需要将其全部转换成大写字母再, 放到 HTTP Body 中. 如果传入参数有multimediaFile，则此参数及其value不参与sign的计算

### 输入参数说明

#### 必填参数及描述

* appKey:          语镜公司下发的APP的标识
* sign	           加密签名
* IMEI             终端的编号,**IMEI为大写**


#### 可选参数及描述

* 无

#### 参数格式

 参数              |  类型       |   示例         |  限制条件
-------------------|-------------|----------------|--------------
 appKey:           | string      |  1010          | 长度不大于10
 sign:             | string      |  无            | 长度为40
 IMEI              | string      |  无            | 非0开头的长度15位的数字



### 错误编码

* 0:            Request OK

* ME01002:      appKey error
* ME01019:      sign is not match
* ME01022:      系统内部错误

* ME01023       参数错误

* ME18004       此IMEI在数据库中存在多条记录


### 返回格式

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok"}`


### 测试地址: 192.168.1.3:8088/accountapi/v2/updateAccount


#### 示例代码

    POST /accountapi/v2/updateAccount HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded
    
    sign=EDEF541F1E71393EC10BD93B9F3F28AC9817CFC9&appKey=1111111111&IMEI=123456789012345
    

#### 示例代码,请求成功

    HTTP/1.1 200 OK
    Server: nginx/1.4.1
    Date: Tue, 20 Aug 2013 13:00:35 GMT
    Content-Type: application/json
    Content-Length: 61
    Connection: close
    
    {"ERRORCODE":"0", "RESULT":"ok"}

