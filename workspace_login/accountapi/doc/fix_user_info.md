修改用户信息
========================

### API编号
* S0130V2

### 功能简介
* 修改用户相关资料

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型   | 示例               | 是否允许为空 | 限制条件
----------------------------|--------------------|--------|--------------------|--------------|---------------------------
 appKey                     | 应用标识           | string | 1111111111         | 否           | 长度不大于10
 sign                       | 安全签名           | string | 无                 | 否           | 长度为40
 accountID                  | 语镜用户帐户编号   | string | aaaaaaaaaa         | 否           | 长度为10的字母
 accessToken                | 用户的授权访问令牌 | string | 无                 | 否           | 无
 name                   	| 用户昵称           | string | hello              | 是           | 长度小于32
 homeAddress				| 住址				 | string | 无				   | 是			  | 
 nickname                   | 用户昵称           | string | hello              | 是           | 长度小于32
 gender                     | 性别               | string | 1                  | 是           | 0-女性;1-男性;2-中性;3-未知
 bloodType                  | 血型               | string | O                  | 是           | A;AB;B;O
 birthday                   | 生日               | string | 1985-01-08         | 是           | YYYY-MM-DD格式
 drivingLicense             | 驾照               | string | 150102195311292217 | 是           | 
 plateNumber                | 车牌号             | string | 苏Z88888           | 是           | 长度为7位
 SOSContactMobile           | 紧急联络人手机号码 | string | 13500000814        | 否 (如果传参不能为空)| 长度11首位为1的数字
 operatingLicenseNumber     | 营运证号码         | string |                    | 是           | 
 driverCertificationNumber  | 主驾资格证号       | string |                    | 是           | 
 idNumber                   | 用户身份证号码     | string |                    | 是           | 
 

### 代码示例

    POST /accountapi/v2/fixUserInfo HTTP/1.0
    Host:192.168.1.207:8000
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    accountID=aaaaaaaaaaa&sign=75013BEF8D390523E0E2D1D288C84FF51690A519&appKey=1111111111&nickname=hello&accessToken=adfasdfdsf


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":"ok!"}`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回结果参数

 参数   | 参数说明
--------|----------------------------------
 无     | 无

### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01003              | accessToken not match  | 访问令牌不匹配
 ME01004              | accessToken expire     | 访问令牌已过期
 ME01006              | error json data!       | 请检查输入参数
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01020              | mysql failed           |  请与公司客服联系
 ME01022              | 系统内部错误             | 请与公司客服联系
 ME01023              | 参数错误                | 请检查输入参数
 ME01024			  | http body is null!     | 请检查输入参数
 ME18005              | this input field does not exist   | 请检查输入参数
 ME18053              |this accountID is not exist!| 请与公司客服联系


### 测试地址: api.daoke.io/accountapi/v2/fixUserInfo

