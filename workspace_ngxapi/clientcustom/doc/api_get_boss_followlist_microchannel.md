主播查询本频道所有关注用户列表
========================

### API编号
* 

### 功能简介

主播查询本频道所有关注用户列表

### 参数格式

* API以 **POST** 方式请求，使用key-val方式提交

### 输入参数

 参数                        | 参数说明            | 类型     |   示例        | 是否允许为空  | 限制条件
-----------------------------|--------------------|----------|---------------|--------------|---------------------------
 appKey                     | 应用标识            | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名            | string  | 无            | 否           | 长度为40
 accountID                  | 语镜用户帐户编号    | string  | 2222222222    | 否           | 长度为10的字母
 channelNumber              | 频道编号           | string  | FM00090080    | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母
 startPage                  | 起始页             | int 	  | 1              | 是           | 正整数
 pageCount                  | 每页显示的条数      | int 	  | 20            | 是           | 正整数，小于500
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否           |长度为32

### 示例代码/clientcustom/v2/getBossFollowList

	POST /clientcustom/v2/getBossFollowListMicroChannel HTTP/1.0
	Host:api.daoke.io
	Content-Length:107
	Content-Type:application/x-www-form-urlencoded

	channelNumber=FMDK0001&sign=86CD480551E3FFE83EE62AB5D00198F497307ACC&accountID=1111111111&appKey=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

### 返回body示例

* 成功:
*关注该频道的所有用户列表
		1.`{"ERRORCODE":"0", "RESULT":{"count":"2","list":[{"uniqueCode":"1111111111|3f2465587cf411e4b79b000c29bc68cf","accountID":"1111111111","nickname":"我干杯你随意","online":"1","createTime":"1417836186"},{"uniqueCode":"1111111111|3f2465587cf411e4b79b000c29bc68cf ","accountID":"1111111111","nickname":"同学","online":"0","createTime":"1417847776"}]}}` 
*当前频道没有人关注
		2.`{"ERRORCODE":"0", "RESULT":[]}`
* 失败: 
		`{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

参数    | 参数说明
--------|--------------------------------
count   | 数字 当前关注该主播的人数
list    |二维数组,关注该主播的人的信息 
uniqueCode | 微频道邀请码
nickname | 昵称
online 	 | 在线
createTime | 创建时间

### 错误编码

 参数                 | 错误描述               	 | 解决办法     
----------------------|--------------------------|---------------------------------------
 0                    | ok 		             	 | 调用成功
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01002              | appKey error        	 | appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!        	 | 数据库错误 ,请与公司客服联系
 ME01024              | http body is null!    	 | 请检查配置文件，请与公司客服联系
 ME01022              | internal data error!     | 系统错误，请与公司客服联系
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参
 ME18109              | channel number is error! | 频道编号错误，请检查参数


### 测试地址: api.daoke.io/clientcustom/v2/getBossFollowListMicroChannel
