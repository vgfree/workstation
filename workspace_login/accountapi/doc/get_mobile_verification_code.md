获取手机验证码接口文档API
=================================

### API编号

### 功能简介
* 获取手机验证码

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 mobile           | 手机号          | string      |  无            |否          | 1开头的11位数字
 content          | 发送的内容      | string      |  无            |否          | 须包含[code]字段


### 示例代码

    POST /accountapi/v2/getMobileVerificationCode HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:101
    Content-Type:application/x-www-form-urlencoded

    sign=63ECE302F97C7548EC776D309E11A2B8B4944246&mobile=15221515357&content=hellonihao&appKey=1111111111


 ### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"bizid":"x527FaMBIu3KDc2","mobile":"15221515357","verificationCode":"7514","mobileCount":2}}`


### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
bizid               | 微博返回值
mobile              | 接收者手机号
verificationCode    | 验证码
mobileCount         | 合法手机号个数


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数



### 测试地址: api.daoke.io/accountapi/v2/getMobileVerificationCode
