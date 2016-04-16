得到用户imei和手机号码的API
=================================

### API编号

### 功能简介
* 通过用户账号编号获得imei和手机号码

### 参数格式 

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 accessToken    | 用户的授权访问令牌       | string      | 无         |  否             | 无
 accountID        | 账户编号        | string      |  aaaaaaaaaa    |否          | 长度为10


### 示例代码

    POST /accountapi/v2/getImeiPhone HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    sign=F6FE5DAE1578B50901F07972865240AF642C7EF5&accountID=mFm4jlAlmm&appKey=1111111111

 ### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"imei":"101012345678901","phone":"", "mirrtalkNumber":"", "checkMobile":"0"}}`


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
imei            | 终端编号
phone           | 手机号码
mirrtalkNumber  | 语镜号码
checkMobile     | 是否验证用户手机号码。0：未验证；1：已验证

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数


### 测试地址: api.daoke.io/accountapi/v2/getImeiPhone
