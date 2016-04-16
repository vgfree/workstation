将第三方账户与语镜帐号关联的API
===============================

### API编号

### 功能简介
* 将第三方账户与语镜帐号关联

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数                   |参数说明            |  类型       |   示例         |是否允许为空|  限制条件
------------------------|--------------------|-------------|----------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111    |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无            |否          | 长度为40
 accountID              | 账户编号           | string      |  aaaaaaaaaa    |否          | 长度为10
 account                | 用户名             | string      |  aaaaaaaaaa    |否          | 长度小于64
 loginType              | 登录类型           | string      |  5            	|否          | 5：微信登陆；7：凯立德
 token                  | 登录令牌           | string      |  无            |否          | 非空
 refreshToken           | 刷新令牌           | string      |  无            |否          | 非空
 accessToken            | 访问令牌           | string      |  无            |否          | 非空
 accessTokenExpiration  | 访问令牌的截止时间 | string      |  无            |否          | 非空


### 示例代码

    POST /accountapi/v2/associateAccountWithAccountID HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:186
    Content-Type:application/x-www-form-urlencoded

    loginType=6&accessTokenExpiration=10000&sign=20B00A73EF0F7A1C8437DAE55C0D4C7024305BFB&token=1024&accessToken=10086&accountID=qjiFddlllE&refreshToken=10010&appKey=1111111111&account=hello

### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":"ok"}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`



### 返回结果参数

参数            | 参数说明
----------------|------------------------
无              | 无

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18011     | account已经存在           | 请选择未注册的用户名

### 测试地址: api.daoke.io/accountapi/v2/associateAccountWithAccountID
