
检查用户是否绑定IMEI
========================

### API编号

### 功能简介
* 验证用户是否绑定IMEI

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数           |参数说明                  |  类型       |   示例      | 是否允许为空   |  限制条件
----------------|--------------------------|-------------|-------------|----------------|--------------
 appKey         | 应用标识                 | string      | 1111111111 |  否             | 长度不大于10的数字
 sign           | 安全签名                 | string      | 无         |  否             | 长度为40
 accountID      | 语镜用户帐户编号         | string      | 2222222222 |  否             | 长度为10的字符
 accessToken    | 用户的授权访问令牌       | string      | 无         |  否             | 无


### 代码示例

	POST /accountapi/v2/checkIsBindImei HTTP/1.0
	Host: api.daoke.io:80
	content-type: application/x-www-form-urlencodedr
	content-Length:129

	accessToken=33333333333333333333333333333333&sign=01E968883FBC4AE3B21A1A051B07F63B5869BF3C&accountID=2222222222&appKey=1111111111


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"IMEI":"111111111111111","band":"1"}}`

* 失败: `{"ERRORCODE":"ME18001", "RESULT":"accessToken does not exist!"}`

### 返回结果参数

band:

 参数                       | 参数说明
----------------------------|----------------------
  0							 | 用户未绑定IMEI
  1							 | 用户已绑定IMEI

IMEI:
 参数                       | 参数说明
----------------------------|----------------------
  0							 | 用户不属于该组
  111111111111111			 | 用户属于改组



### 错误编码

 参数                 | 错误描述               
----------------------|------------------------
 0                    | 调用成功				
 ME01020              | mysql failed   
 ME01021              | redis failed           
 ME01022              | 系统内部错误           
 ME01023              | 参数错误               
 ME18001              | 结果错误           

 ### 测试地址: api.daoke.io/accountapi/v2/checkIsBindImei

