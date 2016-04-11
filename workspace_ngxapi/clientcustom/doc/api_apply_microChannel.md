用户申请微频道
========================

### API编号
* 

### 功能简介

* 用户申请微频道

### 参数格式

* API以 **POST** 方式请求，使用FORM方式提交

### 输入参数

 参数                       | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|-------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 语镜用户帐户编号    | string  | 2222222222    | 否           | 长度为10的字母
 channelNumber              | 频道编号           | string  | FM00090080    | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母
 channelName                | 频道名称           | string  | 无            | 否           | 长度大于2 最大长度16，可以是汉字
 channelIntroduction        | 频道简介           | string  | 无            | 否           | 长度大于1 最大长度128，可以是汉字
 chiefAnnouncerIntr         | 主播简介           | string  | 无            | 否           | 长度大于5 最大长度128，可以是汉字
 channelCityCode            | 频道区域编号        | int 	  | 110000        | 否           | 长度6-10，数字
 channelCatalogID           | 频道类别编号        | int 	  | 无            | 否           | 长度6-11，数字
 channelCatalogUrl          | 频道logo url地址   | string  | 无            | 否           | 最大长度128
 channelKeyWords 			| 频道关键字 		    |string 	|aa,bb 		|是 				|单个关键字标签最长是8，关键词最多由5个关键字标签组成
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       | 长度为32


### 示例代码 /clientcustom/v2/applyMicroChannel

	POST /clientcustom/v2/applyMicroChannel HTTP/1.0
	Host:api.daoke.io
	Content-Length:1551
	Content-Type:application/x-www-form-urlencoded



	appKey=1111111111&accessToken=cc7df2350a7755214dc93df48e15d682&channelCatalogID=111111&channelCatalogUrl=http%3A%2F%2Fg3.tweet.daoke.me%2Fgroup3%2FM02%2FE5%2FEA%2Fc-dJB1R8pY-AJlO2AAGsD3RDpM8392.png&sign=793D8CACB75728A13FD93305913AFFD15857B8A0&channelNumber=aaaaaa&channelCityCode=111111&chiefAnnouncerIntr=%E5%B1%8C%E7%82%B8%E5%A4%A9%E7%8B%AC%E6%92%AD&channelKeyWords=&channelName=%E5%BE%AE%E5%AF%86%E4%B9%8B%E5%A3%B0&channelIntroduction=%E5%86%85%E9%83%A8%E4%BA%A4%E6%B5%81&accountID=aaaaaaaaaa 


### 返回body示例

* 成功:
		`{"ERRORCODE":"0", "RESULT":'ok'}`
* 失败: 
		`{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 错误编码

 参数                 | 错误描述               				| 解决办法     
----------------------|-------------------------------------|---------------------------------------
 0                    | ok                    				| 正常调用
 ME01002              | appKey error          				| appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!         				| 数据库错误 ,请与公司客服联系
 ME01019              | sign is not match     				| 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!  				| 系统错误 ,请与公司客服联系
 ME18104              | current user channel already exist  | 当前用户申请的频道已经被审核通过了,请修改频道号
 ME18105              | Repeat submitted       				| 当前用户重复提交相同的数据
 ME18106              | user channel Maximum   				| 当前用户申请的频道已经达到最大值
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参 
 ME01003 			  | access token not matched 			| 令牌访问权限不匹配



### 测试地址: api.daoke.io/clientcustom/v2/applyMicroChannel


