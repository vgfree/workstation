获取群聊频道的用户列表
========================

### API编号
* 

### 功能简介

* 获取群聊频道的用户列表

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数                       | 参数说明            | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|----------------------|----------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       	| 安全签名           | string  | 无            | 否           | 长度为40
 accountID                 	| 管理员/普通用户的帐户	  | string  | aaaaaaaaaa    | 否           | 长度为10的字母
 channelNumber            	| 频道编号         | string  | 000000000   	| 否         	| 9/10位
 startPage                 	| 起始索引           | int      | 1     		| 是           | 不能有小数点
 pageCount                 	| 每页显示条数       | int      | 1     		| 是           | 小于500的正整数,不能有小数点
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |
 
### 示例代码clientcustom/v2/getUserJoinListSecretChannel 
	POST /clientcustom/v2/getUserJoinListSecretChannel  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:175
	Content-Type:application/x-www-form-urlencoded

	appKey=1111111111&pageCount=20&sign=84F8A595A1D5DCF4A8EEA78E1115BFE6C63645ED&channelNumber=000000000&startPage=1&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


### 返回body示例

* 成功:`{"ERRORCODE":"0", "RESULT":{"count":"8","list":[{"accountID":"aaaaaaaaaa","role":"1","actionType":"0","nickname":"屌炸天","online":0},{"accountID":"hhhhhhhhhh","role":"0","actionType":"5","nickname":"","online":0},{"accountID":"bbbbbbbbbb","role":"0","actionType":"4","nickname":"","online":0},{"accountID":"cccccccccc","role":"0","actionType":"5","nickname":"","online":0},{"accountID":"dddddddddd","role":"0","actionType":"5","nickname":"","online":0},{"accountID":"eeeeeeeeee","role":"0","actionType":"5","nickname":"","online":0},{"accountID":"ffffffffff","role":"0","actionType":"5","nickname":"","online":0},{"accountID":"gggggggggg","role":"0","actionType":"5","nickname":"","online":0}]}}
`
		
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回结果参数

 参数    | 参数说明
---------|--------------------------------
count | 条数
accountID|用户账号
nickname|昵称
online |是否在线
talkStatus|用户状态  1正常  2禁言  3剔除
role    |身份 0普通成员 1创建者  2管理员
actionType |3吐槽 4语音命令 5群组




### 错误编码

 参数                  | 错误描述              		| 解决办法     
-----------------------|-------------------------------|---------------------------------------
 0                     | ok              	  		| 调用成功
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01002              | appKey error         	  	| appKey需使用从语镜公司申请得到的appKey
 ME01023              | accountid is error!    	| 用户帐号错误,请与公司客服联系
 ME01020              | mysql failed!        	  	| 数据库错误 请与公司客服联系
 ME01019              | sign is not match      	| 请阅读语镜公司提供的签名算法
 ME01022              | internal data error    	| 请与公司客服联系
 ME01023              | args is error!      		| 参数错误，请检查参数
 ME18109 				|channel number is error 	|当前频道编码错误
 ME01021 				|redis failed! 				|数据库错误 请与公司客服联系
 ME18306 				|you are not manager 		|当前不是群聊频道管理员



### 测试地址: api.daoke.io/clientcustom/v2/getUserJoinListSecretChannel


