
用户查询自己关注的所有微频道
========================

### API编号
* 

### 功能简介
* 用户查询自己关注的所有的微频道,并返回所关注的详细信息

### 参数格式

* API以 **POST** 方式请求，使用k-v方式提交

### 输入参数

 参数                        | 参数说明           | 类型    |   示例         | 是否允许为空 | 限制条件
----------------------------|--------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111     | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无             | 否           | 长度为40
 accountID                  | 语镜用户帐户编号    | string  | 2222222222     | 否           | 长度为10的字母
 startPage                  | 起始页             | string  | 1              | 是           | 
 pageCount                  | 每页显示的条数      | string  | 20             | 是           | 小于500的正整数
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |


### 示例代码/clientcustom/v2/getOwnerFollowListUserChannel

	POST /clientcustom/v2/getOwnerFollowListUserChannel HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:108
	Content-Type:application/x-www-form-urlencoded

	pageCount=2&accountID=2222222222&startPage=1&sign=9AE606F7C26A561B5E6B299AFA402E7D030D6000&appKey=1111111111


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"count":"1","list":[{"number":"FMDK0001","catalogName":"","logoURL":"","chiefAnnouncerIntr":"小喇叭专业广播,小心被啦来关起","name":"开发测试测试申请频道xxxxfff","introduction":"专业分享交通电子眼的频道"}]}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数    | 参数说明
---------|--------------------------------
 count   | 数字 关注的所有频道的数量
 list    | 所关注的频道的详细信息
 number  | 微频道编号
 name    | 微频道名称
 catalogName | 微频道类别名称
 chiefAnnouncerIntr | 主播简介
 introduction  | 频道简介

### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01003 			  | access token not matched | 用户令牌访问权限不匹配
 ME01002              | appKey error         | appKey需使用从语镜公司申请得到的appKey
 ME01023              | parameter is error!   | 参数错误，请按照文档提供的参数要求传参
 ME01020              | mysql failed!        | 数据库错误，请与公司客服联系
 ME01019              | sign is not match    | 请阅读语镜公司提供的签名算法
 ME01022              | internal data error!           | 请与公司客服联系

 


### 测试地址: api.daoke.io/clientcustom/v2/getOwnerFollowListUserChannel


