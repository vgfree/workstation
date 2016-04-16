检查手机号是否被注册或绑定
========================

### API编号
2308
### 功能简介
1) 检查手机号是否被注册或绑定,
2) 检查输入的账户编号和手机号是否匹配

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数           |参数说明                  |  类型       |   示例      | 是否允许为空   |  限制条件
----------------|--------------------------|-------------|-------------|----------------|--------------
 appKey         | 应用标识                 | string      | 1111111111 |  否             | 长度不大于10
 sign           | 安全签名                 | string      | 无         |  否             | 长度为40
 mobile      | 用户手机账号         		| string      | 19595959595 |  是            | 手机号
 accountID    | 用户账号      			| string      |   无       | 是           	| 用户账号编号

### 代码示例

    POST /accountapi/v2/checkMobileRegister HTTP/1.0
    Host:192.168.1.207:8000
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    accountID=12356485896&sign=75013BEF8D390523E0E2D1D288C84FF51690A519&appKey=1111111111&mobile=12365252525&


### 返回body示例

* 成功: `{"ERRORCODE": "0", "RESULT": {"ismatch": 0, "isbind": 1}}`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回结果参数
 参数                    | 参数说明
-------------------------|----------------------
ismatch   			| 账户编号和手机号是否匹配 1: 匹配 , 0: 不匹配
isbind				| 手机号是否被注册或绑定   1: 绑定 , 0: 没绑定

### 错误编码

 参数                 | 错误描述               | 解决办法
----------------------|------------------------|------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error         | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match   | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01020			   | mysql failed          | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME01024			   | http body is null  | 请检查输入参数

### 测试地址: api.daoke.io /accountapi/v2/checkMobileRegister







