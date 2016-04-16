
设置用户语镜号码的API
========================

设置用户语镜号码,编号:S0109V2
---------------------

### 注明

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.
* 签名计算: 各个参数按照其 key 的字典序排列,然后用 SHA1 加密, 签名值计算出来后, 需要将其全部转换成大写字母再, 放到 HTTP Body 中. 如果传入参数有multimediaFile，则此参数及其value不参与sign的计算

### 输入参数说明

#### 必填参数及描述

* appKey:               语镜公司下发的APP的标识
* sign	                加密签名
* accountID             账户编号
* mirrtalkNumber:       语镜号码
* verificationCode:     验证码


#### 可选参数及描述

* 无

#### 参数格式

 参数              |  类型       |   示例         |  限制条件
-------------------|-------------|----------------|--------------
 appKey:           | string      |  2064302565    | 长度不大于10
 sign:             | string      |  无            | 长度为40
 accountID         | string      |  adedfeqweo    | 长度为10
 mirrtalkNumber    | string      |  无            | 长度为11
 verificationCode  | string      |  无            | 长度为4


### 错误编码

* 0:            Request OK

* ME01002:      appKey error
* ME01019:      sign is not match
* ME01022:      系统内部错误

* ME01023       参数错误

* ME18003       此accountID不存在
* ME18004       此accountID存在多条记录
* ME18006       未绑定IMEI
* ME18007       验证码已过期
* ME18008       验证码不正确
* ME18010       此用户被暂停服务



### 返回格式

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"successful"}`


### 测试地址: 192.168.1.3:8088/accountapi/v2/setUserMirrtalkNumber


#### 示例代码

    POST /accountapi/v2/setUserMirrtalkNumber HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:133
    Content-Type:application/x-www-form-urlencoded
    
    accountID=mFm4jlAlmm&verificationCode=1010&mirrtalkNumber=15221515357&sign=235047FF05F07A03D043F1A407BC16AF2B87FC05&appKey=1111111111


#### 示例代码,请求成功

    HTTP/1.1 200 OK
    Server: nginx
    Date: Sun, 16 Mar 2014 15:01:35 GMT
    Content-Type: text/plain
    Content-Length: 41
    Connection: close
    
    {"ERRORCODE":"0", "RESULT":"ok"}

