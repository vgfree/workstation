
根据第三方账户创建语镜帐号关联的API
========================

根据第三方账户创建语镜帐号,编号S0102V2
---------------------

### 注明

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.
* 签名计算: 各个参数按照其 key 的字典序排列,然后用 SHA1 加密, 签名值计算出来后, 需要将其全部转换成大写字母再, 放到 HTTP Body 中. 如果传入参数有multimediaFile，则此参数及其value不参与sign的计算

### 输入参数说明

#### 必填参数及描述

* appKey:               语镜公司下发的APP的标识
* sign	                加密签名
* account:              用户名
* loginType:            登陆类型.6:新浪微博


#### 可选参数及描述

* token,accessToken,accessTokenExpiration       此三个参数为一组
* nickname:                                     昵称

#### 参数格式

 参数                   |  类型       |   示例         |  限制条件
------------------------|-------------|----------------|--------------
 appKey:                | string      |  2064302565    | 长度不大于10
 sign:                  | string      |  无            | 长度为40
 account                | string      |  adedfeqweo    | 长度为10
 loginType              | string      |  6             | 6
 token                  | string      |  无            | 无
 accessToken            | string      |  无            | 无
 accessTokenExpiration  | string      |  无            | 无



### 错误编码

* 0:            Request OK

* ME01002:      appKey error
* ME01019:      sign is not match
* ME01022:      系统内部错误

* ME01023       参数错误




### 返回格式

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":}`


### 测试地址: 192.168.1.3:8088/accountapi/v2/createAccountID


#### 示例代码

    POST /accountapi/v2/createAccountID HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:108
    Content-Type:application/x-www-form-urlencoded
    
    loginType=6&nickname=hahaha&sign=64CEA2B78E99ACF6DB8F320877CF8744093006B8&account=hellolua&appKey=1111111111

#### 示例代码,请求成功

    HTTP/1.1 200 OK
    Server: nginx
    Date: Wed, 16 Apr 2014 02:35:17 GMT
    Content-Type: application/json
    Content-Length: 163
    Connection: close
    
    {"ERRORCODE":"0", "RESULT":{"isNew":1,"isHasDaokeAccount":0,"lastLoginTime":"","accountID":"myeqKOlAlh","nickname":"hahaha","registerTime":"2014-04-16 10:34:56"}}

