
提取用户禁言信息API
========================

### API编号
* 

### 功能简介
* 提取用户禁言信息API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|------------------- |----------|--------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountIDs                 | 账户数             | string  | 2222222222    | 否           | 长度为10,若要查询多个账号用户时，每个账号用户之间用逗号隔开
 count                      | 查询的用户数       | string  | 1     	       | 否           | number类型


### 示例代码/clientcustom/v2/fetchUserShutUpInfo

    POST /clientcustom/v2/fetchUserShutUpInfo HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    count=1&appKey=2222222222&accountIDs=1111111111&sign=83FDAE52CF4753030552BA77A9B13C11D15043CB
	
	
### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":"ok"}`
* 失败: 
		`{"ERRORCODE":"ME01023", "RESULT":"parameter is error!"}`



### 错误编码

 参数                 | 错误描述                | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | ok 		               | 正常调用
 ME01023              | parameter is error!    | 参数错误，请按照文档提供的参数要求传参
 ME01020              | mysql failed!          | 数据库错误 ,请与公司客服联系
 ME01022              | internal data error!   | 系统错误 ,请与公司客服联系



### 测试地址: api.daoke.io/clientcustom/v2/fetchUserShutUpInfo
