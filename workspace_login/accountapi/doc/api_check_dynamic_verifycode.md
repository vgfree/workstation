认证验证码并注册用户
========================
### 功能简介
* 认证验证码并注册用户

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型   | 示例                | 是否允许为空 | 限制条件
----------------------------|--------------------|--------|---------------------|--------------|--------------
 appKey                     | 应用标识           | string | 1111111111      	| 否           | 长度不大于10
 sign                       | 安全签名           | string | 无               	| 否           | 长度为40
 mobile                     | 手机号码           | string | 13512447814     	| 否           | 长度11首位为1的数字
 verifyCode               	| 手机发送的验证码   | string | 123456          	| 否           | 6位随机数字
 nickname               	| 用户昵称    		 | string | 123456          	| 是           | 用户自定义名称（默认为手机号后4位数字）
 password                 	|用户自定义密码   	 | string | 123456          	| 是           | 不小于6位(不输入password时使用verifyCode作为密码注册)
 

### 代码示例

    POST /accountapi/v2/checkDynamicVerifycode HTTP/1.0
    Host:api.daoke.io
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    mobile=18221520000&appKey=182269830&verifyCode=859146&sign=B6AED769CD319915F9E790B7CC678D5B11781C56

### 返回body示例

* 成功: `{"ERRORCODE": "0","RESULT": {"accountID": "Y1E000000gx"}}`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回结果参数

 参数   | 参数说明
------------------------------------------
 accountID | 用户编号

### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01006              | error json data!       | 请检查输入参数
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01020              | mysql failed           |  请与公司客服联系
 ME01022              | internal data error!   | 请与公司客服联系
 ME01023              | 参数错误                | 请检查输入参数
 ME01024			  | http body is null!     | 请检查输入参数
 ME18005              | this input field does not exist| 请检查输入参数
 ME18909			  |sms send failed		   |请与公司客服联系
 ME18910			  |verifycode is expire	   |请重新获取验证码


### 测试地址: api.daoke.io/accountapi/v2/checkDynamicVerifycode


