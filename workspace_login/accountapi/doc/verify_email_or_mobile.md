验证用户邮箱或手机号码API
=================================

### API编号

### 功能简介
* 验证用户邮箱或手机号码
* 无条件修改用户手机号和邮箱
### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 accountID        | 账户编号        | string      |  aaaaaaaaaa    |否          | 长度为10
 email            | 用户邮箱        | string      |  无            |是          | 合法的邮箱地址，邮箱与手机号码至少传一个
 mobile           | 用户手机号      | string      |  无            |是          | 首位为1长度为11的数字


### 示例代码

    POST /accountapi/v2/verifyEmailOrMobile HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:103
    Content-Type:application/x-www-form-urlencoded

    sign=3A3958C746B6AEAA2A0E1F8FBA26BFF6824D1A1F&mobile=15221515357&accountID=6mwpIlvLyK&appKey=1111111111
 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok!"}`


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
无              | 无

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18053     | accountID不存在           | 请与公司客服联系

### 测试地址: api.daoke.io/accountapi/v2/verifyEmailOrMobile
