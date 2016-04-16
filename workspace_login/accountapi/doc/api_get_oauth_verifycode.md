获取手机号对应的验证码接口文档API
=================================

### API编号

### 功能简介
* 获取手机号对应的验证码

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|---------------|------------|----------------|------------|---------------------
 appKey           | 应用标识       | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名       | string      |  无            |否          | 长度为40
 mobile           | 手机号         | string      |  无            |否          | 1开头的11位数字



### 示例代码

    POST /accountapi/v2/getOauthVerifycode HTTP/1.0
    Host:api.daoke.io
    Content-Length:101
    Content-Type:application/x-www-form-urlencoded

    mobile=1231111111&appKey=1111111111&sign=79B1C64EDCB6C7BBFFBCB82572D080E902BCFFDF


 ### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE": "0", "RESULT": "ok!"}`


### 返回结果参数

参数                 | 参数说明
--------------------|-------------------------------------------
无

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01020     | mysql failed              |  请与公司客服联系
ME01022     | 系统内部错误                | 请与公司客服联系
ME01023     | 参数错误                    | 请检查输入参数
ME01024	   | http body is null!        | 请检查输入参数




### 测试地址: api.daoke.io/accountapi/v2/getOauthVerifycode
