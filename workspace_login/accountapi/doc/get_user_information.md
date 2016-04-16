
获取用户信息
========================

### API编号

### 功能简介
* 获取用户的详细资料

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数           |参数说明                  |  类型       |   示例      | 是否允许为空   |  限制条件
----------------|--------------------------|-------------|-------------|----------------|--------------
 appKey         | 应用标识                 | string      | 1111111111 |  否             | 长度不大于10
 sign           | 安全签名                 | string      | 无         |  否             | 长度为40
 accountID      | 语镜用户帐户编号         | string      | aaaaaaaaaa |  否             | 长度为10的字母
 accessToken    | 用户的授权访问令牌       | string      | 无         |  否             | 无


### 代码示例

    POST /accountapi//getUserInformation HTTP/1.0
    Host:192.168.1.3:8088
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    accountID=aaaaaaaaaa&sign=75013BEF8D390523E0E2D1D288C84FF51690A519&appKey=1111111111&accessToken=asdfsdafsadffas


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"sharePosition":"1","status":"1","nickname":"甜甜","guardianMobile":"","accountID":"U8tlXVSPcq","checkQuestion":"0","time":"2014-03-14 14:40:51","checkMobileTime":"0"}}`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回结果参数

 参数                       | 参数说明
----------------------------|----------------------
 sharePosition              | 是否共享位置
 name                       | 主驾姓名
 nickname                   | 昵称
 gender                     | 主驾性别。0-女性;1-男性;2-中性;3-未知
 bloodType                  | 血型
 userEmail                  | 用户邮箱
 birthday                   | 生日
 drivingHabit               | 驾驶习惯
 drivingLicense             | 主驾驾照号
 drivingLicenseIssueDate    | 首次领取驾照时间
 plateNumber                | 车牌号
 VIN                        | 车辆识别代号
 drivingLicenseAddress      | 行驶证住址
 insuranceCompany           | 保险公司
 vehicleCommercialInsurance | 商业险保单号
 trafficCompulsoryInsurance | 交强险保单号
 insurancePeriod            | 保险期限
 driverEmergencyContact     | 主驾紧急联系人
 driverContactRelation      | 主驾紧急联系人与主驾关系
 driverEmergencyMobile      | 主驾紧急联系人手机号码
 purchaseCar4SName          | 购车4S店
 commonUse4SName            | 常用4S店
 tyreBrand                  | 轮胎品牌
 tyreModel                  | 轮胎型号
 SOSContactMobile           | 紧急联络人手机号码
 constellation              | 星座
 limitPassenger             | 核定载客数
 operatingLicenseNumber     | 营运证号码
 driverCertificationNumber  | 主驾资格证号
 checkMobileTime            | 验证用户手机号码时间
 checkUserEmailTime         | 验证用户邮箱时间
 idNumber                   | 用户身份证号码
 guardianMobile             | 监护人手机号码


### 错误编码

 参数                 | 错误描述               | 解决办法
----------------------|------------------------|------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01003              | accessToken not match  | 访问令牌不匹配
 ME01004              | accessToken expire     | 访问令牌已过期
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME18053              | 帐户不存在             | 更改帐户


### 测试地址: api.daoke.io/accountapi/v2/getUserInformation

