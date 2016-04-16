添加用户自定义账号的API
========================

### API编号

### 功能简介
* 添加用户自定义账号

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数              |参数说明            |  类型       |   示例         |是否允许为空|  限制条件
-------------------|--------------------|-------------|----------------|------------|---------------------
 appKey            | 应用标识           | string      |  1234567890   |否          | 长度不大于10
 sign              | 安全签名           | string      |  无            |否          | 长度为40
 username          | 用户名             | string      |  无            |是          | 允许为空，不为空时首位不能为数字，其长度不能大于64,不小于6位
 mobile            | 手机号码           | string      |  无            |是          | 允许为空，不为空时为11位数字
 userEmail         | 邮箱               | string      |  无            |是          | 允许为空，用户邮箱
 daokePassword     | 密码               | string      |  无            |否          | 长度不小于6
 accountType       | 用户的注册类型     | string      |  1             |否          | 1代表用户名为主，2代表手机号码为主，3代表邮箱为主
 nickname          | 用户的昵称         | string      |  无            |否          | 需进行url编码
 gender            | 性别               | string      |  无            |是          | 0表示女，1表示男，3表示未知

* username,mobile,userEmail三选一参数
### 示例代码

    POST /accountapi/v2/addCustomAccount HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:172
    Content-Type:application/x-www-form-urlencoded

    nickname=helloj&sign=7F8E592478C7FD859617457EF16E4ADA111FACE2&appKey=1234567890&gender=1&daokePassword=abc123&username=ja9zh1010&accountType=1

### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功: `{"ERRORCODE":"0", "RESULT":{"accountID":"QOl9r5vTiw"}}`


### 返回结果参数

参数                    | 参数说明
------------------------|--------------------------------
accountID               | 用户帐号编号


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01006     | error json data!          | 参数错误
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              	| 请与公司客服联系
ME01023     | 参数错误                  	| 请检查输入参数
ME01024	   | http body is null!        | 请检查输入参数
ME01020     | mysql failed!             | 请与公司客服联系
ME01021	   | redis failed!             | 请与公司客服联系
ME01025	   | http failed!              | 网络错误
ME18002     | username已经存在          | 请选择未注册的用户名


### 测试地址: api.daoke.io/accountapi/v2/addCustomAccount
