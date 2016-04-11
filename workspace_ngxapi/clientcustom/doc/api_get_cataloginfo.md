获取微频道类别列表
========================

### API编号
*

### 功能简介

获取微频道所有类别的列表

### 参数格式

* API以 **POST** 方式请求，使用key-val方式提交

### 输入参数

 参数                       | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|-------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 channelType                | 频道类别           | int 	  | 1     	   | 否           | 1 主播频道的类别 / 2 群聊频道的类别
 startPage                  | 起始索引           | int 	  | 1            | 否           | 正整数
 pageCount                  | 每页显示条数       | int 	  | 1            | 否           | 正整数，小于500


### 示例代码/clientcustom/v2/getCatalogInfo
 | 请求方法URL协议/版本
 | 请求头(Request Header)

 | 请求正文

	POST /clientcustom/v2/getCatalogInfo HTTP/1.0
	Host:api.daoke.io
	Content-Length:85
	Content-Type:application/x-www-form-urlencoded

	sign=7C8A3AA818F5AB7EE3FDEC4A0165E7FA0D9D884E&startPage=1&pageCount=10&appKey=1111111111&channelType=1

### 返回body示例

* 成功:

		`{"ERRORCODE":"0", "RESULT":{"count":"19","list":[{"number":"200008","name":"搞基自由","logoURL": ""},{"number":"200007","name":"美食胖子送","logoURL":""},{"number":"200006","name":"两性深夜谈","logoURL":""},{"number":"200005","name":"旅行约一约","logoURL":""},{"number":"200004","name":"鲜肉来两斤","logoURL":""},{"number":"200003","name":"大叔也疯狂","logoURL":""},{"number":"200002","name":"美女要不要","logoURL":""},{"number":"200001","name":"节操几个钱","logoURL":""},{"number":"100111","name":"两性情感","logoURL":""},{"number":"100110","name":"应急救援","logoURL":""},{"number":"100109","name":"交通出行","logoURL":""},{"number":"100108","name":"线下服务","logoURL":""},{"number":"100107","name":"品牌产品","logoURL":""},{"number":"100106","name":"吃喝玩乐","logoURL":""},{"number":"100105","name":"行业交流","logoURL":""},{"number":"100104","name":"兴趣爱好","logoURL":""},{"number":"100103","name":"同城交友","logoURL":""},{"number":"100102","name":"车友会","logoURL":""},{"number":"100101","name":"同事朋友","logoURL":""}]}}`


* 失败:
		`{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

参数     | 参数说明
--------|--------------------------------
count   |数字,记录集
list    |查询返回信息集合
number  |频道类别编号
name 	|频道类别名称
logoURL |频道分类logourl

### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|-----------------------|---------------------------------------
 0                    | ok 		              | 调用成功
 ME01002              | appKey error          | appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!         | 数据库错误 ,请与公司客服联系
 ME01019              | sign is not match     | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!  | 系统错误，请与公司客服联系
 ME01023              | startPage is error!   | 起始页错误，请检查传入起始页
 ME01023              | pageCount is error!   | 每页条数，请检查传入每页条数


### 测试地址: api.daoke.io/clientcustom/v2/getCatalogInfo
