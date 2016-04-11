修改密频道
========================

### API编号
* 

### 功能简介
* 修改群聊频道信息

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

  参数                       | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|-------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 语镜用户帐户编号  | string  | 2222222222    | 否           | 长度为10的字母
 channelNumber              | 频道编号          | string  | 000000000   | 否           | 9/10位 数字
 channelName                | 频道名称           | string  | 无            | 是          | 长度大于2 最大长度16，可以是汉字
 channelIntro        		| 频道简介         | string  | 无            | 是           | 长度大于1 最大长度128，可以是汉字
 channelCitycode            | 频道区域编号      | int 	  | 111111        | 是           | 长度6-10，数字
 channelCatalogID           | 频道类别编号        | int 	  | 无            | 是           | 长度6-11，数字
 channelLogoUrl          | 频道logo url地址    | string  | 无            | 是           | 最大长度128，必须图片格式结尾
 channelOpenType            |频道开放             |int      |1或0           |是            |1开放 0 非开放
 channelKeyWords 			|修改频道关键字 		|string |aa,bb,c 			|是   		|单个关键字标签最长是8，关键词最多由5个关键字标签组成
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |


### 示例代码 /clientcustom/v2/modifySecretChannelInfo HTTP/1.0

	POST /clientcustom/v2/modifySecretChannelInfo  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:323
	Content-Type:application/x-www-form-urlencoded

	appKey=1111111111&channelIntro=&channelCatalogID=111111&channelOpenType=&sign=CA1F8BD4C3E4E1F29EF5FC1DBE1900132857A7D5&channelNumber=000000040&channelCitycode=&channelLogoUrl=&channelName=&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":"ok!"}`
		
* 失败: `{"ERRORCODE":"ME18105", "RESULT":"Repeat submitted"}`


### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01003 			  | access token not matched 		| 用户令牌访问权限不匹配
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!          | 数据库错误 请与公司客服联系
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error! | 请与公司客服联系
 ME01023              | args is error!              | 参数错误 请检查参数
 ME18105              | Repeat submitted      | 重复提交数据 请检查输入参数
 ME18053              |this accountID is not exist!|当前用户不存在 请检查输入参数
 ME18109               |channel number is error  |频道编号错误 请检查参数
 ME01024               |http body is null          | 请与公司客服联系
 ME18053				|this accountID is not exist!|当前用户账号不存在
 ME01021				|redis failed!				|数据库错误 请与公司客服联系
 ME18109				|channel number is error 	|频道编号错误 请检查参数

### 测试地址: api.daoke.io/clientcustom/v2/modifySecretChannelInfo


