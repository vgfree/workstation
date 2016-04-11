
申请加入群聊频道API
========================

### API编号
* 

### 功能简介
* 用于加入某个群聊频道API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       	| 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
------------------------------|--------------------|----------|---------------|--------------|---------------------------
 appKey                   	| 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       	| 安全签名           | string  | 无            | 否           | 长度为40
 accountID                	| 申请账户           | string  | aaaaaaaaaa    | 否           | 长度为10 
 uniqueCode             	| 频道邀请码         | string  | xxxxxxxx    | 否           | 频道邀请码,数字与字母组合,32-64位
 remark 					|加入频道备注信息 		|string 	|xxxxx 		|是 				|长度不大于128
 accessToken 				|用户令牌访问权限 		|string  	|aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 		|否 		 |长度为32位


### 示例代码 /clientcustom/v2/joinSecretChannel

	POST /clientcustom/v2/joinSecretChannel  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:162
	Content-Type:application/x-www-form-urlencoded

	uniqueCode=000000013%7C50f5a77ed91011e4905f000c29bc68cf&appKey=184269830&sign=95A4F847E8C344C9FEAE719E148AE89584EEE700&accountID=0qEigeQNuz&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa



### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"isVerify":"0"}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`



### 返回结果参数

 参数    | 参数说明
---------|--------------------------------
isVerify | 是否验证加入 1 验证 0 不验证
channelNumber | 频道编号
applyIdx | 申请加入编号
manager |频道管理员
applyRemark | 备注



### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | ok               		| 调用成功
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01023              |  args is error    | 参数错误 ,请检查输入参数
 ME18303              | do not repeat follow   | 重复加入 请检查当前是否已经加入该频道
 ME01020              | mysql failed!		   | 数据库错误 请与公司客服联系
 ME01021			   | redis failed!            | 数据库错误 请与公司客服联系       
 ME18107              | uniquecode is error    | 邀请码错误  请检查邀请码
 ME18108              | user too many            |频道用户数已达到最大值 
 ME18053              |	this accountID is not exist!|当前的用户编号不存在 请重新输入
 ME01022              | internal data error  | 系统错误,请与公司客服联系



### 测试地址: api.daoke.io/clientcustom/v2/joinSecretChannel


