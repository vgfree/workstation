判断用户是否在线api
========================

### API编号
* 

### 功能简介
* 判断给定用户是否在线

### 参数格式

* API以 **POST** 方式请求，且使用**key-value键值对**方式提交

### 输入参数

 参数                           | 参数说明      | 类型  |   示例  		| 是否允许为空	| 限制条件
--------------------------------|---------------|-------|-----------------------|---------------|-------------------------
appKey				|应用标识	|string	|1111111111		|否		|长度不大于10
sign				|安全签名	|string	|无			|否		|长度为40
accountID			|用户账号	|string	|2222222222		|否		|长度为10字符串

#### 特殊说明
* accountID当传入参数为多个的时候，示例{2alQT35mv1,kxl1QuHKCD}，中间以“，”隔开,最多一次传50.



### 示例代码

	POST /clientcustom/v3/checkIsOnline HTTP/1.0
	Host:127.0.0.1:80
	Content-Length:84
	Content-Type:application/x-www-form-urlencoded

	appKey=5555555555&sign=8B61EF79DCA8C6AF5C2A2A06C1B2D69604810492&accountID=lkj7lIjqWy%2CzdfeqE74Vi%2CGbgzks2Ick


### 返回body

* 成功：`{"ERRORCODE":"0", "RESULT":{"offline":"["eB6bYE8pkl"]","online":"[ ]"}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回参数

 参数      |  参数描述 
-----------|--------------------
online     |  在线成员
offline    |  不在线成员


### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01023              | 参数错误               | 请检查输入参数


### 测试地址: api.daoke.io/clientcustom/v3/checkIsOnline
