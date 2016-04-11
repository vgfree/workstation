修改微频道/被驳回的频道
========================

### API编号
* 

### 功能简介
* 修改微频道/修改被驳回的数据

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                        | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
-----------------------------|-------------------|---------|----------------|--------------|--------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无             | 否           | 长度为40
 accountID                  | 语镜用户帐户编号    | string  | 2222222222    | 否           | 长度为10的字母和数字
 beforeChannelNumber      	| 频道编号 			| string  | FM00090080    | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母
 channelNumber      		| 频道编号 			| string  | FM00090080    | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母	
 channelName                | 频道名称           | string  | 无            | 是           | 长度大于2 最大长度16，可以是汉字				
 channelIntroduction        | 频道简介          | string  | 无              | 是           | 长度大于1 最大长度128，可以是汉字								
 chiefAnnouncerIntr         | 主播简介          | string  | 无              | 是           | 长度大于5 最大长度128，可以是汉字								
 channelCityCode            | 频道区域名称      | string  | 无               | 是           | 长度6-10，数字										
 channelCatalogID           | 频道类别编号      | string  | 无              | 是           | 长度6-11，数字										
 channelCatalogUrl          | 频道logo url地址  | string  | 无              | 是           | 最大长度128											
 infoType                   | 接口标识           | int     | 1              | 是           | 只能是1/2
 channelKeyWords 			| 频道关键字 			|string |aa,bb,cc 		|是    			|关键字标签最长是8，关键词最多由5个关键字标签组成
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |无		
 

infoType 	| 	参数说明			| applyIdx			|参数说明		|类型	|限制条件			|是否允许为空
------------|-------------------|-------------------|---------------|-------|-------------------|-----------
1			|修改未通过的频道 	|	1 				|频道唯一标识	|int 	|数字不能有小数点		|否
2			|修改已通过的频道 	|	1 				|频道唯一标识	|int 	|数字不能有小数点		|否


### 示例代码 /clientcustom/v2/modifyMicroChannel HTTP/1.0

	POST /clientcustom/v2/modifyMicroChannel HTTP/1.0
	Host:api.daoke.io
	Content-Length:375
	Content-Type:application/x-www-form-urlencoded

	channelName=小喇叭专业!!abcdefg&pageCount=20&startPage=1&after_channelNumber=a11111&appKey=1111111111&sign=89B6EBAF3EA0AD5D0D04C2910293434F74DE63CD&before_channelNumber=a111111111&accountID=aaaaaaaaaa&channelCatalogUrl=http://www.baidu.com&channelIntroduction=小喇叭!!!123123&chiefAnnouncerIntr=小喇叭123!!!&channelCatalogID=111111&channelCityCode=111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


### 返回body示例

* 成功:
		 `{"ERRORCODE":"0", "RESULT":"ok!"}`
		
* 失败: 
		`{"ERRORCODE":"ME18105", "RESULT":"Repeat submitted"}`


 参数                | 参数说明
---------------------|-------------------------------
 inviteUniqueCode    | 邀请码

### 错误编码

 参数                 | 错误描述                				| 解决办法     
----------------------|-------------------------------------|---------------------------------------
 0                    | ok 		               				| 调用成功
 ME01003 			  | access token not matched 		| 用户令牌访问权限不匹配
 ME01002              | appKey error           				| appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!          				| 数据库错误 ,请与公司客服联系
 ME01019              | sign is not match      				| 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!   				| 系统错误，请与公司客服联系
 ME18105              | Repeat submitted       				| 当前用户重复提交相同的数据 ,请检查输入参数
 ME01024              | http body is null!     				| 请检查配置文件，请与公司客服联系
 ME18104              | current user channel already exist  | 当前频道被审核通过了 ,请检查输入参数
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参 

### 测试地址: api.daoke.io/clientcustom/v2/modifyMicroChannel


