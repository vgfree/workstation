
用户退出群聊频道
========================

### API编号
* 
### 功能简介
* 用户退出群聊频道

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|-------------------|----------|-----------------|-----------------|---------------------------
 appKey                     | 应用标识        | string  | 1111111111     	| 否          	| 长度不大于10
 sign                       | 安全签名         | string  | 无            	| 否          	| 长度为40
 accountID           | 管理员申请账户   | string  | aaaaaaaaaa 	| 否          	| 长度为10 
 channelNumber            	| 频道编号         | string  | 000000000   	| 否         	| 9/10位
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |



### 示例代码 /clientcustom/v2/quitSecretChannel
	POST /clientcustom/v2/quitSecretChannel  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:155
	Content-Type:application/x-www-form-urlencoded

	appKey=1111111111&channelNumber=000000000&sign=C2B17825B5B16427A995C05303076E5EA66CF048&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":"ok"}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`



### 错误编码

 参数                 | 错误描述                     | 解决办法     
----------------------|-------------------------------|---------------------------------------
 0                    | ok                     		| 调用成功
 ME01003 			  | access token not matched 		| 用户令牌访问权限不匹配
 ME01002              | appKey error               | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match         | 请阅读语镜公司提供的签名算法
 ME01023              | accountID is error        | 管理员帐号错误,请检查输入参数
 ME01020              | mysql failed!		     | 数据库错误 请与公司客服联系
 ME18053              |this accountID is not exist!|当前的用户编号不存在 请重新输入
 ME01022              | internal data error       |系统错误 请与公司客服联系
 ME18109              |channel number is error   |频道编号错误 请检查频道编号
 ME18312				|did not join					|当前用户之前未加入该群聊频道
 ME18311			|current channel is binded		|当前群聊频道已经关联按键,不能退出,(需要取消关联才能退出)
 ME18313			|deny quit  					|创建者不允许退出群聊频道




### 测试地址: api.daoke.io/clientcustom/v2/quitSecretChannel


