
更新微频道/密频道的的邀请唯一码
========================

### API编号
* 

### 功能简介
* 重置频道当前邀请的惟一码

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|-------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 申请账户           | string  | 2222222222    | 否           | 长度为10 
 channelNumber              | 频道编号           | string  | FM00090080    | 否           | 主播频道 (长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母) 群聊频道 (9/10位 数字)
 channelType                | 频道类型           | int 	  | 1 		      | 否           | 1 主播频道 2 群聊频道
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |

### 示例代码 /clientcustom/v2/resetInviteUniqueCode

	POST /clientcustom/v2/resetInviteUniqueCode HTTP/1.0
	Host:api.daoke.io
	Content-Length:107
	Content-Type:application/x-www-form-urlencoded

	channelNumber=FM00090080&sign=7EC4D28BF24C47A8963305F8A5B899EBE3C0B090&accountID=222222222&appKey=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa



### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":"ok!"}`
		
* 失败: 
		`{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


 参数                | 参数说明
---------------------|--------------------------------
 inviteUniqueCode    | 邀请码

### 错误编码

 参数                 | 错误描述                | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | ok 		               | 调用成功
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01003              | accessToken not match  | 访问令牌不匹配
 ME01020              | mysql failed!          | 数据库错误 ,请与公司客服联系
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!   | 系统错误，请与公司客服联系
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参
 ME18109              | channel number is error| 检查参数 ,请与公司客服联系
 ME18306 				|you are not manager    |检查参数,当前用户不是群聊频道管理员
 ME18109 				|channel number is error |当前频道编号错误


### 测试地址: api.daoke.io/clientcustom/v2/resetInviteUniqueCode


