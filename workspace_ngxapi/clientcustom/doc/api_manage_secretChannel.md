
公司管理密频道
管理员管理密频道用户
========================

### API编号
* 
### 功能简介
* 
公司管理密频道
管理员管理密频道用户

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|-------------------|----------|-----------------|-----------------|---------------------------
 appKey                     | 应用标识        | string  | 1111111111     	| 否          	| 长度不大于10
 sign                       | 安全签名         | string  | 无            	| 否          	| 长度为40
 infoType                   | 函数接口        | int      | 1 		  	| 否         	| 信息标志 1.公司管理密频道 2.管理员管理频道里的用户
 accountID           | 管理员申请账户   | string  | aaaaaaaaaa 	| 否          	| 长度为10 
 channelNumber            	| 频道编号         | string  | 00000000   	| 否         	| 9/10位
 curStatus                 |频道的状态或用户状态|int    |1 或 2         	| 否         	|频道的状态1 正常 2 关闭 用户的状态 1正常2禁言3拉黑
 userAccountID                 |频道用户申请的帐号|string   |aaaaaaaaaa   	| 否         	|长度为10
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |(对accountID进行设置权限)

###特此声明

infoType   | 调用者身份 | curStatus|accountID| 功能说明 
-------------|------------|-------------|-----------|-----------------
1            | 公司  	  |   1   	 |X			| 修改频道状态为正常
1            | 公司  	  |   2   	 |X			| 关闭密频道		             
2		   |频道管理员  |	 1    	 |频道用户帐号| 修改频道用户状态为正常 
2		   |频道管理员  |	 2    	 |频道用户帐号| 修改频道用户状态为禁言             
2		   |频道管理员  |	 3    	 |频道用户帐号| 修改频道用户状态为拉黑            




### 示例代码 /clientcustom/v2/manageSecretChannelUsers
	POST /clientcustom/v2/manageSecretChannelUsers  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:155
	Content-Type:application/x-www-form-urlencoded

	adminAccountID=llllllllll&accountID=llllllllll&channelNumber=111111111&curStatus=2&sign=42706A6A602D7050C4367563EBE54843055289CD&infoType=2&appKey=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


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
 ME01023              | channelNumber is error!  | 频道编号错误,请检查输入频道编号
 ME01023              | curStatus is error!       | 当前状态错误 请检查输入状态
 ME01023              | accountID is error        | 管理员帐号错误,请检查输入参数
 ME01020              | mysql failed!		     | 数据库错误 请与公司客服联系
 ME01021			   | redis failed!              | 数据库错误 请与公司客服联系       
 ME18053              |this accountID is not exist!|当前的用户编号不存在 请重新输入
 ME01022              | internal data error       |系统错误 请与公司客服联系
 ME18305              |do not manage self         |管理员不能管理自己
 ME18109              |channel number is error   |频道编号错误 请检查频道编号
 ME18105              |Repeat submitted           |当前用户重复提交相同的数据 
 ME18312 				|did not join 			|当前用户从未加入群聊频道
 ME18306 				|you are not manager 	|当前用户不是管理员




### 测试地址: api.daoke.io/clientcustom/v2/manageSecretChannelUsers


