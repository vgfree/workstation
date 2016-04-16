获取用户信息API
==========================

### API编号

### 功能简介
* 获取用户信息

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 username               | 用户帐号           | string      |  无                |否          | 长度为10的字母
 

### 示例代码

    POST /accountapi//getUserInfo HTTP/1.0
    Host:192.168.1.3:8088/accountapi
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    username=11111111111&sign=75013BEF8D390523E0E2D1D288C84FF51690A519&appKey=1111111111
 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"sharePosition":"1","id":"159","status":"1","nickname":"甜甜","guardianMobile":"","accountID":"U8tlXVSPcq","checkQuestion":"0","time":"2014-03-14 14:40:51","mobile":"10000000003","checkMobileTime":"nil"}}`


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
sharePosition   | 是否分享位置0：不分享；1：分享，该值必须为1
id              | 数据库表中自增id
status          | 用户状态；0：注销用户；1：正常用户；2：添加失败的用户3：暂停服务的用户
nickname        | 昵称
guardianMobile  | 监护人手机号码
accountID       | 用户账户编号
checkQuestion   | 是否验证问题。0：不验证；1：验证
time            | 时间
mobile          | 主驾手机号
checkMobileTime | 验证用户手机号码时间


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18061     | username不存在            | 请与公司客服联系


### 测试地址: api.daoke.io/accountapi/getUserInfo
