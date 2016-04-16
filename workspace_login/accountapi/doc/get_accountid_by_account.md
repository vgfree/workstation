获取账号编号的API
==========================

### API编号

### 功能简介
* 根据账号名获取账号编号

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 name                   | 用户名             | string      |  mirrtalk          |否          | 长度不大于32,需URL编码
 account                | 用户帐号           | string      |  aaaaaaaaaa        |否          | 无
 loginType              | 登陆类型           | string      |  7                 |否          | 5：微信登陆；7：凯立德

### 示例代码

    POST /accountapi/v2/getAccountIDByAccount HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:108
    Content-Type:application/x-www-form-urlencoded

    clientIP=127.0.0.1&loginType=6&account=hello&sign=BA3B94EAB30392E4B78DAC390783AB74891DB534&appKey=1111111111


### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"accountID":"qjiFddlllE"}}`


### 返回结果参数

参数        | 参数说明
------------|-------------------
name        | 用户名
accountID   | 用户账户
nickname    | 用户昵称


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18002     | 第三方账户不存在          | 请与公司客服联系

### 测试地址: api.daoke.io/accountapi/v2/getAccountIDByAccount
