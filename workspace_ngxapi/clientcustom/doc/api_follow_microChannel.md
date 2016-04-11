
关注/取消关注微频道API
========================

### API编号
* 

### 功能简介
* 用于关注某个微频道API
* 用于取消关注某个微频道API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|-------------------|----------|--------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 申请账户           | string  | 2222222222    | 否           | 长度为10 
 uniqueCode                 | 频道邀请码         | string  | xxxxxxxx      | 否           | 频道邀请码,数字与字母组合,32-64位
 followType                 | 操作类型           | int 	  | 1             | 否           | 1/ 2
 channelNumber              | 频道编号           | string  | 2222222222    | 否           | 长度大于5 并且小于16,只能是字母加数字,第一位必须为字母
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否             |长度为32
###特别说明:

followType		  | 参数说明 	| 必传参数 		| 参数说明
------------------|-------------|---------------|-----------------
1 				  | 关注 		| uniqueCode 	| 频道邀请码
2 				  | 取消关注 	| channelNumber | 频道编号

### 关注示例代码 /clientcustom/v2/followMicroChannel

	POST /clientcustom/v2/followMicroChannel HTTP/1.0
	Host:api.daoke.io
	Content-Length:141
	Content-Type:application/x-www-form-urlencoded

	uniqueCode=FMDKxxxxx|0a0b750468e111e48eb6902b34af3648&accountID=2222222222&sign=1577DB1BD51418177C1B0D152F5E9F30E69562AA&followType=1&appKey=1111111111

### 取消关注示例代码 /clientcustom/v2/followMicroChannel

	POST /clientcustom/v2/followMicroChannel HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:120
	Content-Type:application/x-www-form-urlencoded

	accountID=2222222222&channelNumber=FMDK0011&sign=923557792BD9A9EE17E73EDDB40D39154715FFEB&followType=2&appKey=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
	
### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":"ok"}`
* 失败: 
		`{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`



### 错误编码

 参数                 | 错误描述                | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | ok 		               | 正常调用
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!   | 系统错误 ,请与公司客服联系
 ME18302              | do not follow yourself | 不允许关注自己创建的微频道
 ME18303              | do not repeat follow   | 请检查当前是否已经关注了该频道
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参
 ME01003 			  | access token not matched | 用户令牌访问权限



### 测试地址: api.daoke.io/clientcustom/v2/followMicroChannel


