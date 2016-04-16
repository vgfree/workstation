用户获取密码重置的验证码
========================
### 功能简介
* 用户获取密码重置的验证码

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型   | 示例               | 是否允许为空 | 限制条件
----------------------------|--------------------|--------|--------------------|--------------|--------------
 appKey                     | 应用标识           | string | 1111111111         | 否           | 长度不大于10
 sign                       | 安全签名           | string | 无                 | 否           | 长度为40
 mobile                     | 手机号码           | string | 13512447814        | 否           | 长度11首位为1的数字
 

### 代码示例

    POST /accountapi/v2/resetPasswordInitVerifyCode HTTP/1.0
    Host:api.daoke.io
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    appKey=182269830&sign=B6AED769CD319915F9E790B7CC678D5B11781C56&mobile=18221520000

### 返回body示例

* 成功: `{"ERRORCODE": "0","RESULT": {"validTime":"10"}}`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`



### 返回结果参数

 参数   | 参数说明
------------------------------------------
 validTime | 验证码有效时间（单位:分钟）

### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | ok		               | 正常调用
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01006              | error json data!       | 请检查输入参数
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01020              | mysql failed           | 请与公司客服联系
 ME01021			  | redis failed!		   |请与公司客服联系
 ME01022              | internal data error!   | 请与公司客服联系
 ME01023              | paramenter is error    | 请检查输入参数
 ME01024			  | http body is null!     | 请检查输入参数
 ME01025			  | http failed!		   |请与公司客服联系
 ME18061			  | user name is not exist!|请用该手机号码注册道客账户



### 测试地址: api.daoke.io/accountapi/v2/resetPasswordInitVerifyCode