道客账户绑定手机号
========================

### API编号
2308
### 功能简介
道客账户绑定手机号,修改手机号

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数           |参数说明                  |  类型       |   示例      | 是否允许为空   |  限制条件
----------------|--------------------------|-------------|-------------|----------------|--------------
 appKey         | 应用标识                 | string      | 1111111111 |  否             | 长度不大于10
 sign           | 安全签名                 | string      | 无         |  否             | 长度为40
 accessToken    | 用户的授权访问令牌       | string      | 无         |  否             | 无
 mobile      | 用户手机账号         		| string      | 12356485896 |  是            | 用户注册的账号,手机号
 accountID    | 用户账号      			| string      |   无       | 是           		| 用户账号编号,mobile和accountID至少填一个
 newmobile    | 绑定手机号       		| string      | 12365252525         |  否       | 未注册未绑定账号的手机号


### 代码示例

    POST /accountapi/v2/userBindMobile HTTP/1.0
    Host:192.168.1.207:8000
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    newmobile=12356485896&sign=75013BEF8D390523E0E2D1D288C84FF51690A519&appKey=1111111111&mobile=12365252525&


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":ok }`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回结果参数

 参数                       | 参数说明
----------------------------|----------------------
无


### 错误编码

 参数                 | 错误描述               | 解决办法
----------------------|------------------------|------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01020			   | mysql failed           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME01024			   | http body is null  | 请检查输入参数
 ME18916              | mobile already registered | 更换其他手机号
 ME18917              | mobile already binded | 更换其他手机号
 ME18060              | accountID is not in service | 使用语境公司下发的accountID
 ME18068              | user mobile hasn't authorization | 该手机号未注册或未绑定账号
 ME18918              | mobile and accountID is not match | 请检查输入参数


### 测试地址: api.daoke.io /accountapi/v2/userBindMobile

