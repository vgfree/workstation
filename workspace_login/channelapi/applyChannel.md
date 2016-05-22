用户申请群聊频道
========================

### API编号
*

### 功能简介

* 用户申请频道

### 参数格式

* API以 **post** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

参数                           | 参数说明         | 类型       |   示例      |
是否允许为空 | 限制条件
-----------------------------|-------------------|--------------|-------------|---------------|---------------------------
appKey                         | 应用标识              | string        |
1111111111    | 否           | 长度不大于10
sign                           | 安全签名              | string        | 无
| 否           | 长度为40
accountID                      | 语镜用户帐户编号      | string        |
2222222222    | 否           | 长度为10的字母
channelName                    | 频道名称              | string        | 无
| 否           | 长度大于2 最大长度16，可以是汉字
channelIntroduction            | 频道简介              | string        |
无            | 否           | 长度大于1 最大长度128，可以是汉字
channelCityCode                | 频道区域编号          | int
|111111         | 否           | 长度6-10 ,可为0，数字
channelCatalogID               | 频道类别编号          | int           |
无            | 否           | 长度6-11，数字
channelCatalogUrl              | 频道logourl地址       | string
| 无            | 是           | 最大长度128，必须图片格式结尾
openType                       |频道开放               |int
|1或0           |否            |1开放 0 非开放
isVerify                               |是否校验
|int    | 1或0                  | 是                    | 0 不校验 1
校验
channelKeyWords                        |频道关键字
|string |aaa,bbb,ccc    |是
|单个关键字标签最长是8，关键词最多由5个关键字标签组成

### 示例代码 /clientcustom/v2/applySecretChannel
POST /clientcustom/v2/applySecretChannel  HTTP/1.0
Host:api.daoke.io:80
Content-Length:312
Content-Type:application/x-www-form-urlencoded

channelName=测试测试&sign=23999E6EFED3E76B996248D139F8F299149C7D27&appKey=1111111111&channelCatalogUrl=http://www.daoke.me/logo.png&accountID=aaaaaaaaaa&channelIntroduction=专d分享交通电子眼的频道&openType=1&channelCatalogID=111111&channelCityCode=111111&isVerify=1&channelKeyWords=aa,bb,cc,cc





### 返回body示例

* 成功:
	`{"ERRORCODE": "0",
	"RESULT":
		{"channelNumber":
		"000000377",
		"uniqueCode":
		"000000377|2380b34402c111e58d9f902b34af3648"}}`
* 失败:
	`{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 错误编码

					参数
					|
					错误描述
					|
					解决办法
					------------------------|--------------------------------------------------|---------------------------------------
					0
					|
					ok
					|
					正常调用
					ME01002
					|
					appKey
					error
					|
					appKey需使用从语镜公司申请得到的appKey
					ME01023
					|
					accountid
					is
					error!
					|
					请与公司客服联系
					ME01019
					|
					sign
					is
					not
					match
					|
					请阅读语镜公司提供的签名算法
					ME01022
					|
					internal
					data
					error!
					|
					系统错误,请与公司客服联系
					ME01020
					|
					mysql
					failed
					|
					数据库错误,请与公司客服联系
					ME01021
					|
					redis
					failed!
					|
					数据库错误,请与公司客服联系
					ME01023
					|
					args
					is
					error!
					|
					参数错误，请检查参数
					ME18104
					|
					current
					user
					channel
					already
					exist
					|
					当前的频道已经存在,请重新申请
					ME18106
					|
					user
					channel
					Maximum
					|
					当前用户的密频道已经达到最大值
					ME18109
					|
					channel
					number
					is
					error
					|
					当前频道编码错误,请检查频道编码


