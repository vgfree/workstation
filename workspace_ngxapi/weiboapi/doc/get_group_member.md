
得到某集团所属成员的接口文档
========================

### API编号

### 功能简介
* 获得集团的所有成员


### 参数格式 
* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|-----------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 groupID          | 集团编号        | string      |  无            |否          | 长度3至8位的数字
 

### 示例代码

    POST /weiboapi/v2/getGroupMember HTTP/1.0
    Host:192.168.1.0:80
    Content-Length:93
    Content-Type:application/x-www-form-urlencoded
    
    sign=66E6D1BDB3D5BF4D427C6B3AB9F131665EE28931&groupAbbreviation=mirrtalkAll&appKey=1111111111

### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"members":[{"roleType":"2","accountID":"eIm5lSl5Ae","name":"","online":1,"isDefaultGroup":1},{"roleType":"2","accountID":"clvByproj4","name":"helloworld","online":1,"isDefaultGroup":1}],"updateTime":"2014-03-20 14:26:28","createTime":"2014-03-20 14:26:28","name":"liangGeDeGroup"}}`

### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
roleType            | 用户角色,1代表集团创建者,2代表普通成员
accountID           | 账户编号
name                | 用户昵称
online              | 是否在线。0：不在线，1在线
isDefaultGroup      | 是否在默认频道。0：不在默认频道， 1在默认频道


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              |appKey需使用从语镜公司申请得到的appKey
ME01019     | sign not match            |请阅读语镜公司提供的签名算法
ME01022     | 服务器内部错误            |请与公司客服联系
ME01023     | 参数错误                  |请检查输入参数

### 测试地址: api.daoke.io/weiboapi/v2/getGroupMember


