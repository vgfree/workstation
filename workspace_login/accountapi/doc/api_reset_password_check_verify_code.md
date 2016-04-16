手机用户根据验证码重置新密码
========================
### 功能简介
* 手机用户根据验证码重置新密码

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型   | 示例               | 是否允许为空 | 限制条件
----------------------------|--------------------|--------|--------------------|--------------|--------------
 appKey                     | 应用标识           | string | 1111111111         | 否           | 长度不大于10
 sign                       | 安全签名           | string | 无                 | 否           | 长度为40
 mobile                     | 手机号码           | string | 13512447814        | 否           | 长度11首位为1的数字
 verifyCode                 | 验证码             | string | 123456        	  | 否      		| 长度为6且首位不为0的数字
 newPassword                | 密码          		| string | 123456       	  | 否           | 长度不小于6
 

### 代码示例

    POST /accountapi/v2/resetPasswordCheckVerifyCode HTTP/1.0
    Host:api.daoke.io
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    appKey=2064302565&mobile=18221520000&newPassword=daokeme&verifyCode=693692&sign=948B9C2F83245FB568ADC4CFAAD3571FE807C82C

### 返回body示例

* 成功: `{"ERRORCODE": "0","RESULT": "ok"}`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | ok		               | 正常调用
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01006              | error json data!       | 请检查输入参数
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01020              | mysql failed           | 请与公司客服联系
 ME01022              | internal data error!   | 请与公司客服联系
 ME01023              | paramenter is error    | 请检查输入参数
 ME01024			  | http body is null!     | 请检查输入参数
 ME18061			  | user name is not exist!|请用该手机号码注册道客账户
 ME18911              | VerifyCode expired!    | 请重新获取一个验证码
 ME18912              | VerifyCode isn't match!| 请输入正确的验证码
 ME18913			  | VerifyCode already used!| 请重新获取一个验证码
 ME18914			  | Please get a verifyCode first!|请先获取验证码


### 测试地址: api.daoke.io/accountapi/v2/resetPasswordCheckVerifyCode
