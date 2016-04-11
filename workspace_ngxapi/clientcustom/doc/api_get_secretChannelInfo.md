得到群聊频道详情
========================

### API编号
* 

### 功能简介

* 用户得到群聊频道详情

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       	| 参数说明           	| 类型     |   示例        | 是否允许为空| 限制条件
------------------------------|-----------------------|----------|---------------|--------------|---------------------------
 appKey                		| 应用标识           	| string  | 1111111111    | 否           | 长度不大于10
 sign                      	| 安全签名           	| string  | 无            | 否           | 长度为40
 accountID                	| 语镜用户帐户编号    	| string  | 2222222222    | 否           | 长度为10的字母
 channelNumber            	| 频道编号            | string  | 000000000    | 否           | 9/10 
 accessToken 				|用户令牌访问权限 		|string  	|aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 		|否 		 |长度为32位



### 示例代码/clientcustom/v2/getSecretChannelInfo 
	POST /clientcustom/v2/getSecretChannelInfo  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:130
	Content-Type:application/x-www-form-urlencoded

    appKey=1111111111&channelNumber=000000000&sign=06ACF2D96407A17AC7D449C338FEBA1ABAB93118&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


### 返回body示例

* 成功:
	`{"ERRORCODE":"0", "RESULT":[{"keyWords":"","createTime":"1433748968","isJoined":0,"adminName":"屌诈天","cityName":"全国","number":"00391","bindKey":0,"accountID":"aaaaaaaaaa","logoURL":"","openType":"1","catalogID":"111111","isVerify":"0","InviteUniqueCode":"00391|3f2ce4280db111e59c13000c29ae7997","capacity":"5000","introduction":"频道零零三九幺","userCount":"7","onlineCount":0,"name":"频道零零三九幺","cityCode":"0","catalogName":"地区频道"}]}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数    | 参数说明
---------|--------------------------------
channelInfo|频道详情列表
keyWords|频道关键字
createTime|申请时间
cityCode|频道区域编码
inviteUniqueCode|频道最新的邀请码
capacity|最大容量
accountID|申请人
cityName|城市名
number|频道编号
catalogName|频道类别名称
name|频道名称
logoURL|频道logourl地址
openType|密频道类型 1开放  0非开放
catalogID|频道类别编号
introduction|频道简介
isJoined|是否加入
bindKey|是否有关联键
userCount|频道用户总数
onlineCount|频道在线用户数


### 错误编码

 参数                 | 错误描述              	| 解决办法     
----------------------|--------------------------|---------------------------------------
 0                    | ok              		| 调用成功
 ME01002              | appKey error         	| appKey需使用从语镜公司申请得到的appKey
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01020              | mysql failed!        	| 数据库错误 请与公司客服联系
 ME01019              | sign is not match    | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error 	| 系统错误 请与公司客服联系
 ME01023              | accountID is error!  | 帐号错误, 请与公司客服联系
 ME18109              | channelNumber is error!| 频道编号错误, 请检查传入频道编号
 ME18053              |this accountID is not exist!|当前的用户编号不存在 请重新输入


### 测试地址: api.daoke.io/clientcustom/v2/getSecretChannelInfo


