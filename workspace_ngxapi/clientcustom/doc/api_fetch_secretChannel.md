群聊频道列表
========================

### API编号
* 

### 功能简介

* 1.获取所有加入的群聊频道

* 2.获取密频道所有者的群聊频道

* 3.普通用户获取所加入的群聊频道

* 4.用户获取我创建的频道以及我加入的频道

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明            | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|----------------------|----------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       	| 安全签名           | string  | 无            | 否           | 长度为40
 accountID                 	| 语镜用户帐户编号	  | string  | aaaaaaaaaa    | 否           | 长度为10的字母
 infoType                 	| 函数接口           | int      | 1 			| 否           | 1.获取可加入的频道 2.获取所有者的频道 3.获取所加入的频道 4.获取我创建的以及我加入的频道
 startPage                 	| 起始索引           | int      | 1     		| 是           | 不能有小数点
 pageCount                 	| 每页显示条数       | int      | 1     		| 是           | 小于500的正整数,不能有小数点
 cityCode                  	| 频道区域编码       | int      | 100000     	| 是           | 数字，不能有小数点，长度6位到10位	 或0	(全国)
 channelNumber               | 频道编号          | string   | 000000000    	| 是           | 9/10位			
 catalogID                 	| 频道类别编码       | int      | 100000     	| 是           | 数字，不能有小数点，长度6位到10位
 channelName              	| 频道名称         	| string  	| 无          	| 否           | 长度大于2 最大长度16，可以是汉字
 channelKeyWords 			|频道关键字  		  |string 		|aa,bb,cc 	|是 				|单个关键字标签最长是8，关键词最多由5个关键字标签组成
 accessToken 				|用户令牌访问权限 		|string  	|aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 		|否 		 |长度为32位




### 特别说明	
infoType       |调用身份       |功能说明                     	|accountID   | cityCode | channelName  |catalogID   |channelNumber |status
-----------------|----------------|-------------------------|-------------|-----------------------------------------------------------
  1              |普通用户       	|普通用户的到可加入的群聊频道列表	|必传			| 允许为空   |允许为空        |允许为空		|允许为空 	|X
  2              |管理员          |管理员的到自己频道列表    	|必传   		|    X       |X               |X    |X 	备注:X(不存在此参数)|X
  3				 |普通用户 		|普通用户获取所加入的群聊频道 	|必传		|	X 		| X 		| X 		|X 					|X
  4 			|普通用户+管理员 	|用户获取我创建的频道以及我加入的频道|必传 		|X 			|X 			|X 		|X 		|X 				|
 


### 示例代码/clientcustom/v2/fetchSecretChannel
	POST /clientcustom/v2/fetchSecretChannel  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:175
	Content-Type:application/x-www-form-urlencoded


	appKey=1111111111&cityCode=&infoType=1&sign=F4FF66A0F845DB332AD2935346831A2C5B72DF81&catalogID=&channelNumber=&channelName=jk&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa




### 返回body示例

* 成功:
	`{"ERRORCODE":"0", "RESULT":{"count":"1","list":[{"keyWords":"考虑考虑","createTime":"1433748355","catalogNumber":"111111","capacity":"1000","cityName":"北京市","number":"111111111","userCount":"1","catalogName":"吃喝玩乐","introduction":"啦啦啦","logoURL":"http:\/\/g4.tweet.daoke.me\/group4\/M0A\/08\/10\/c-dJT1V1Q7aAN8D3AAB_XAEisPQ565.jpg","openType":"1","name":"奶茶","inviteUniqueCode":"111111111|b890b5bc0daf11e5b705000c29ae7997"}],"keyList":[]}}

		
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数    | 参数说明
---------|--------------------------------
 count  | 数字 条数 几条记录集
 list    |二维数组,查询返回信息集合 
 capacity|频道最大人数
 introduction|简介
 logoURL |图片的地址
 openType|频道是否对外开发
 number  |频道编号
 userCount |加入频道用户数
 name     |频道名
 inviteUniqueCode|邀请码
 cityName|城市名
 catalogName|类别名称
 createTime|创建时间
 keyList	|用户关联键
 catalogNumber | 类别编号






### 错误编码

 参数                  | 错误描述              		| 解决办法     
-----------------------|-------------------------------|---------------------------------------
 0                     | ok              	  		| 调用成功
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01002              | appKey error         	  	| appKey需使用从语镜公司申请得到的appKey
 ME01023              | accountid is error!    	| 请与公司客服联系
 ME01019              | sign is not match      	| 请阅读语镜公司提供的签名算法
 ME01022              | internal data error    	| 请与公司客服联系
 ME01023              | infoType is error         | 函数接口编号, 请检查输入接口编号
 ME01023              | args is error!      		| 参数错误，请检查参数
 ME01020              | mysql failed!		   		  | 数据库错误, 请与公司客服联系
 ME18053              |this accountID is not exist!	  |当前的用户编号不存在 ,请重新输入


 


### 测试地址: api.daoke.io/clientcustom/v2/fetchSecretChannel


