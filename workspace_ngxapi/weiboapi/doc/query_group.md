
查询集团的接口文档
========================

### API编号

### 功能简介
* 查询集团列表

### 参数格式
* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|-----------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 groupName        | 集团名字        | string      |  mirrtalk      |否          | 长度不大于32,需URL编码
 groupType        | 集团类型        | string      |  1             |是          | 0代表非车队,1代表车队,2代表所有,默认为1



### 示例代码

    POST /weiboapi/v2/queryGroup HTTP/1.0
    Host:192.168.1.3:8088
    Content-Length:101
    Content-Type:application/x-www-form-urlencoded
    
    sign=56774F248D55C7F1F7884912FD3D1255A67DFE55&groupName=哄哄&appKey=1111111111

### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":[{"header":"WFlYtlfPlg","groupID":"pnlmBtmoFR3IFt7y","groupName":"牛逼哄哄"}]}`


### 返回结果参数

参数                | 参数说明
--------------------|--------------------------------------
header              |
groupID             | 集团编号
groupName           | 集团名称


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign not match            | 请阅读语镜公司提供的签名算法
ME01022     | 服务器内部错误            | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数



### 测试地址: api.daoke.io/weiboapi/v2/queryGroup


