的到用户加入的密频道列表
========================

### API编号
* 
### 功能简介

的到用户加入的密频道列表

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|-------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识         | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名         | string  | 无            | 否           | 长度为40
 accountID                  | 语镜用户帐户编号| string  | 2222222222    | 否           | 长度为10的字母
 startPage                  | 起始索引        | int      | 1             | 否           | 不能有小数点 
 pageCount                  | 每页显示条数    | int      | 1             | 否           | 小于500的正整数,不能有小数点

### 示例代码/clientcustom/v2/getUserJoinSecretChannelList 
	POST /clientcustom/v2/getUserJoinSecretChannelList  HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:109
	Content-Type:application/x-www-form-urlencoded
	pageCount=10&accountID=aaaaaaaaaa&startPage=1&sign=5B7DCB349AC18BE0EDB87791DF819C74BB7989D2&appKey=1111111111

### 返回body示例

* 成功:
	`{"ERRORCODE":"0", "RESULT":{count:1,list:[{"number":"c222222","catalogName":"行业交流","logoURL":"","introduction":"专d分享交通电子眼的频道kasdfkls","name":"测试测试","cityName":"天津市"}]}}`
		
* 失败: `{"ERRORCODE":"ME01022", "RESULT":"internal data error!"}`


### 返回结果参数

 参数    | 参数说明
---------|----------------------------
 count  | 数字 条数记录集
 catalogName |频道类型名
 logoURL |图片地址
 introduction|频道简介
 name    |频道名
 cityName |城市名
 number |频道编号




### 错误编码

 参数                 | 错误描述              | 解决办法     
----------------------|----------------------|---------------------------------------
 0                    | ok              | 调用成功
 ME01002              | appKey error         | appKey需使用从语镜公司申请得到的appKey
 ME01020              | mysql failed!        | 数据库错误 访问令牌已过期
 ME01019              | sign is not match    | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error  | 系统错误 请与公司客服联系
 ME01023              | args is error!   | 参数错误, 请与公司客服联系
 ME18053              |this accountID is not exist!|当前的用户编号不存在 请重新输入





### 测试地址: api.daoke.io/clientcustom/v2/getUserJoinSecretChannelList


