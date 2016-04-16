判断给定的用户名和密码能否登陆API
===============================

### API编号

### 功能简介
* 判断给定的用户名和密码能否登陆

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 username               | 用户名             | string      |  无                |否          | 必须为username or moblie or email
 daokePassword          | 登录密码           | string      |  无                |否          | 不小于6位的字符串


### 示例代码

    POST /accountapi/v2/checkLogin HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:103
    Content-Type:application/x-www-form-urlencoded

    daokePassword=abc123&username=jayzh1010&sign=8703382F9CD8580DF430D582A546119539FC2ECA&appKey=1111111111


### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功: `{"ERRORCODE":"0", "RESULT":{"name":"haha","accountID":"mF000lAlmm","nickname":"helloj"}}`



### 返回结果参数

参数        | 参数说明
------------|------------------------
name        | 用户名
accountID   | 账户编号
nickname    | 用户昵称
mobile		| 手机号


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18061     | 用户名不存在              | 请与公司客服联系
ME18062     | 该帐户停止服务            | 请与公司客服联系
ME18063     | 用户名和密码不匹配        | 请检查用户名和密码

### 测试地址: api.daoke.io/accountapi/v2/checkLogin
