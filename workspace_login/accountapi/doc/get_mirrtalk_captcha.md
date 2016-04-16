
获取道客暗号的API
========================

获取道客暗号,编号：S0110V2
---------------------

### 注明

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.
* 签名计算: 各个参数按照其 key 的字典序排列,然后用 SHA1 加密, 签名值计算出来后, 需要将其全部转换成大写字母再, 放到 HTTP Body 中. 如果传入参数有multimediaFile，则此参数及其value不参与sign的计算

### 输入参数说明

#### 必填参数及描述

* appKey:               语镜公司下发的APP的标识
* sign	                加密签名
* accountID             账户编号
* mirrtalkNumber        用户语镜号码
* IMEI                  语镜终端编号

#### 可选参数及描述

* 无

#### 参数格式

 参数              |  类型       |   示例         |  限制条件
-------------------|-------------|----------------|--------------
 appKey:           | string      |  2064302565    | 长度不大于10
 sign:             | string      |  无            | 长度为40
 accountID         | string      |  adedfeqweo    | 长度为10
 mirrtalkNumber    | string      |  无            | 长度为11的数字,首位为1或8
 IMEI              | string      |  无            | 长度为15


### 错误编码

* 0:            Request OK

* ME01002:      appKey error
* ME01019:      sign is not match
* ME01022:      系统内部错误

* ME18008       此语镜未开机        
* ME01023       参数错误        


### 返回格式

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok"}`


### 测试地址: 192.168.1.3:8088/accountapi/v2/getMirrtalkCaptcha


#### 示例代码

    POST /accountapi/v2/getMirrtalkCaptcha HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:132
    Content-Type:application/x-www-form-urlencoded
    
    accountID=QOl9r5vTiw&IMEI=184991796904827&mirrtalkNumber=15221515357&sign=6F47FAB6B37295127DC81B1D8C58063F6720A376&appKey=1111111111

#### 示例代码,请求成功

    HTTP/1.1 200 OK
    Server: nginx
    Date: Tue, 15 Apr 2014 13:38:04 GMT
    Content-Type: application/json
    Content-Length: 34
    Connection: close
    
    {"ERRORCODE":"0", "RESULT":"ok!"}


