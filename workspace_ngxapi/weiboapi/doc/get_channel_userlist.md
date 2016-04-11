
查询频道用户列表接口文档
========================

### API编号

### 功能简介
* 查询频道用户列表

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **表单**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|-----------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 accountID        | 用户帐号编号    | string      |  aaaaaaaaaa    |否          | 长度为10的数字或
 channelID        | 频道编号        | string      |  0086          |否          | 3<= 长度 <= 8 


### 示例代码

    POST /weiboapi/v2/getChannelUserList HTTP/1.0
    Host:192.168.1.3:8088
    Content-Length:102
    Content-Type:application/x-www-form-urlencoded

    channelID=0761769&sign=095F5C13D71BFC1EC154354E4F2ABCEAC8D06ECC&accountID=yuGWGIXwuh&appKey=1111111111


### 返回body示例

* 出错: `{"ERRORCODE":"ME18024", "RESULT":"error json data!"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"count":"2","list":[{"accountID":"qh5jDD2EXC"},{"accountID":"yuGWGIXwuh"}]}}`


### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
count               | 数量
accountID           | 账户编号


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
 0          | Request OK                |
 ME01002    | appKey error              | appKey需使用从语镜公司申请得到的appKey
 ME01019    | sign not match            | 请阅读语镜公司提供的签名算法
 ME18021    | 错误请求                  | 请检查输入参数
 ME18024    | json解析错误              | 请与公司客服联系


### 测试地址: api.daoke.io/weibo/v2/getChannelUserList

