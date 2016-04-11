
管理员重审微频道
========================

### API编号
* 

### 功能简介
* 1.获取所有待重审的微频道
* 2.重审微频道

### 参数格式

* API以 **POST** 方式请求，使用k-v方式提交

### 输入参数

 参数                        | 参数说明           | 类型     |   示例        | 是否允许为空  | 限制条件
-----------------------------|-------------------|---------|---------------|--------------|-------------------------------------
 checkAppKey                 | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 checkAccountID             | 语镜用户帐户编号    | string  | 2222222222    | 否           | 长度为10的字母
 accountID                  | 频道所有者         | string  | 2222222222    | 否           | 长度为10的字母
 checkStatus                | 审核状态           | string  | 1             | 否           | 1驳回  2审核成功 3.关闭 4 开放被关闭的微频道   			 	
 channelNumber              | 频道编号           | string  | 无             | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母
 applyIdx              		| 需要重审的微频道编号| int     | 1				| 否           | 正整数
 infoType              		| 函数接口           | int 	  |1     			| 否           | 1.获取所有审核通过的微频道 2.重审微频道
 checkRemark                | 重审理由           | string  | 无             | 是           | 长度不大于64
 cityCode                   | 城市编号           | string  | 无             | 是           | 长度6-10，数字 
 catalogID                  | 类别编号           | string  | 无             | 是           | 长度6-11，数字
 channelName                | 城市名称           | string  | 无             | 是           | 长度大于2 最大长度16，可以是汉字
 startPage                  | 起始索引           | int       | 1     		   | 是           | 正整数
 pageCount                  | 每页显示条数       | int    | 1     		   | 是           | 小于500的正整数
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |(对checkAccountID进行accessToken验证)

### 示例代码/clientcustom/v2/recheckMicroChannel

	POST /clientcustom/v2/recheckMicroChannel HTTP/1.0
	Host:api.daoke.io
	Content-Length:150
	Content-Type:application/x-www-form-urlencoded

	sign=D36BA2EAE440B16C8CD0B75CEA9518DC061BF3D8&checkAccountID=1111111111&channelNumber=FMxx0001&applyIdx=1&checkRemark=&checkStatus=1&appKey=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":"ok!"}`
* 失败: 
		`{"ERRORCODE":"ME18109", "RESULT":"channel number is error"}`


### 错误编码

 参数                 | 错误描述              		| 解决办法     
----------------------|-----------------------------|---------------------------------------
 0                    | ok 	                 		| 正常调用
 ME01003 			  | access token not matched 		| 用户令牌访问权限不匹配
 ME01002              | appKey error         		| appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!        		| 数据库错误 ,请与公司客服联系
 ME01019              | sign is not match    		| 请阅读语镜公司提供的签名算法
 ME01022              | internal data error! 		| 系统错误，请与公司客服联系
 ME18109              | channelNumber is error!     | 当前频道编码错误 ,请与公司客服联系
 ME18104              | current user channel already exist    | 当前用户申请的频道已经被审核通过了 
 ME18307              | txt2voice failed! 	 		| 文本转语音失败，请重试
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参

 


### 测试地址: api.daoke.io/clientcustom/v2/recheckMicroChannel


