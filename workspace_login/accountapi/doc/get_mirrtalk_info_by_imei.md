获取IMEI信息的API
=================================

### API编号
* S0118V2

### 功能简介
* 通过语镜终端编号获得其信息

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      | 1111111111     |否          | 长度不大于10
 sign             | 安全签名        | string      | 无             |否          | 长度为40
 IMEI             | 终端的编号      | string      | 222222222222222|否          | 非0开头的长度15位的数字


### 示例代码

    POST /accountapi/v2/getMirrtalkInfoByImei HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    sign=D6A77E6E524866573E3B6403AC098A7D718ABF03&appKey=1111111111&IMEI=184991796904827


 ### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"legalIMEI":1,"usableIMEI":1,"online":0,"accountID":"abcqwertyu","nickname":"helo"}}`


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
accountID       | 用户帐号编号
online          | 是否在线。0：不在线，1：在线
legalIMEI       | IMEI是否合法。1代表IMEI合法,0代表非法
usableIMEI      | IMEI是否可用。1代表IMEI可用,0代表不可用
nickname        | 用户昵称

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18004     | 查询结果记录为多条        | 请与公司客服联系



### 测试地址: api.daoke.io/accountapi/v2/getMirrtalkInfoByImei
