通过用户账号获取群聊频道关联关系API
========================

### API编号
*  2306

### 功能简介
* 获取用户所在频道的名称以及同频道成员列表

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                         	| 参数说明             	| 类型       |   示例             | 是否允许为空  | 限制条件
-------------------------------|--------------------------|-----------|--------------------|--------------|---------------------------
 appKey                     	| 应用标识           | string  | 1111111111 	| 否           	| 长度不大于10
 sign                       	| 安全签名           | string  | 无          	| 否           	| 长度为40
 accountID                  	| 查询者账号         | string  | 0000000000  	| 否            	| 语境公司下发的账号
 startPage                  	| 起始页             | string  | 1              | 是           | 正整数 默认为1
 pageCount                  	| 每页显示的条数      | string  | 20            | 是           | 正整数 默认为20
 accessToken                    | 令牌访问权限        |string   |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |

### 示例代码/clientcustom/ v2/getSecretchannelRelationByUserkey

	POST /clientcustom/v2/getSecretchannelRelationByUserkey HTTP/1.0
Host:192.168.1.207:80
Content-Length:84
Content-Type:application/x-www-form-urlencoded

appKey=200000005&pageCount=5&sign=25CC9CBB8563C0000000000000000000000004A940191F&startPage=1&accountID=0000000000&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

### 返回body示例

* 成功: `{"ERRORCODE": "0", "RESULT": {"userCount": "1",  "userList": [{"channelName": "频道幺零零八六", "channelNumber": "10086",  "accountID": "qwEsoRs98m", "actionType": "5"}]}} `

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回参数

 参数      |  参数描述 
-----------|----------------
userCount	|频道总人数
userList     | 频道成员列表
accountID   		| 用户账号
channelName 		| 频道名称
channelNumber    | 频道编号
actionType    	| 动作类型

*动作类型:1-拨打电话1;2-拨打电话2;3-发送语音,4-语音命令,5-发送群组语音,6-yes回复,7-no回复,8-关机,9-路过签到,10-语音回复,需返回bizid.


### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME01020              | mysql failed!		   | 数据库错误, 请与公司客服联系
 ME01024              | http body is null!    | 请检查输入参数
 ME01021               |redis failed!          |请与公司客服联系

### 测试地址: api.daoke.io/clientcustom/v2/getSecretchannelRelationByUserkey


