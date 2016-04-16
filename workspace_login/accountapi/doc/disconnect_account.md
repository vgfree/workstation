用户解绑账户和语镜的API
==========================

### API编号

### 功能简介
* 用户解绑账户和语镜

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 accessToken    		| 用户的授权访问令牌       | string      | 无         |  否             | 无
 accountID              | 账户编号           | string      |  aaaaaaaaaa        |否          | 长度为10
 

### 示例代码

    POST /accountapi/v2/disconnectAccount HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    sign=F6FE5DAE1578B50901F07972865240AF642C7EF5&accountID=mFm4jlAlmm&appKey=1111111111

### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功: `{"ERRORCODE":"0", "RESULT":"ok!"}`



 返回结果参数

 参数                   | 参数说明
------------------------|------------------------------------
 无                     | 无


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01020		|mysql failed!				|请与公司客服联系
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME01024     |http body is null!			|请与公司客服联系
ME18004		|参数错误						|请检查输入参数
ME18053     | accountID不存在           | 请与公司客服联系
ME18908     |account is not bind     |请绑定账号


### 测试地址: api.daoke.io/accountapi/v2/disconnectAccount
