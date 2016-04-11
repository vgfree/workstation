
频道重置接口文档
========================

### API编号

### 功能简介
* 频道重置


### 参数格式
* 所有 API 都以 **POST** 方式请求，且传送方式为 **表单**.

### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 accountID        | 用户帐号编号    | string      |  aaaaaaaaaa    |否          | 长度为10的数字
 

### 示例代码

    POST /weiboapi/v2/resetChannel HTTP/1.0
    Host:192.168.1.3:8088
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    sign=8DDE0D38FD8D26D285DCC6C0E8A1FEBD056A7DA7&accountID=yuGWGIXwuh&appKey=1111111111


### 返回格式

* 出错: `{"ERRORCODE":"ME18024", "RESULT":"error json data!"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok"}`


### 返回结果参数

参数                | 参数说明
--------------------|--------------------------------------
无                  | 无


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign not match            | 请阅读语镜公司提供的签名算法
ME18021     | 错误请求                  | 请检查请求BODY
ME18024     | json解析错误              | 请与公司客服联系


### 测试地址: api.daoke.io/weibo/v2/resetChannel

