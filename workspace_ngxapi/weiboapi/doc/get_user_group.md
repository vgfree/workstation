
得到用户所有集团的接口文档
========================

### API编号

### 功能简介
* 获得用户的所有集团

### 参数格式
* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|-----------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 accountID        | 用户帐号编号    | string      |  aaaaaaaaaa    |否          | 长度为10的数字或
 

### 示例代码

    POST /weiboapi/v2/getUserGroup HTTP/1.0
    Host:192.168.1.0:80
    Content-Length:98
    Content-Type:application/x-www-form-urlencoded

    sign=E2AF57DBB81C865A78D3AECAE0929767489F808D&accountID=O40cml0y5p&appKey=1111111111

### 返回body示例

* 出错: `{"ERRORCODE":"ME18024", "RESULT":"error json data!"}`

* 正确: `{"ERRORCODE":"0", "RESULT": [{"groupName":"liangGeDeGroup","groupID":"mirrtalkAll","isCarFleet":0,"createTime":"1970-10-10 00:00:00","roleType":2}]}`


### 返回结果参数

参数                | 参数说明
--------------------|-------------------------------------------
groupName           | 集团名称
groupID             | 集团编号
isCarFleet          | 是否是车队。0表示不是，1表示是车队
createTime          | 创建时间
roleType            | 用户角色,1代表集团创建者,2代表普通成员


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign not match            | 请阅读语镜公司提供的签名算法
ME18022     | 服务器内部错误            | 请与公司客服联系
ME18023     | 参数错误                  | 请检查输入参数


### 测试地址: api.daoke.io/weiboapi/v2/getUserGroup
