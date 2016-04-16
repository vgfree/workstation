根据帐户编号判断用户是否在线的API
=================================

### API编号

### 功能简介
* 需求编号:S0133V2

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 accountID              | 用户帐号编号       | string      |  aaaaaaaaaa        |否          | 长度为10的数字或字母

### 示例代码

    POST /accountapi/v2/judgeOnlineMobile HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:94
    Content-Type:application/x-www-form-urlencoded

    accountID=mFm4jlAlmm&sign=F550494373B3DBCE183AAF6A7237ADCC4BCC992C&appKey=1111111111
 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"model":"11900","online":1}}`



### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
model           | 终端型号
online          | 用户是否在线。0：不在线，1：在线


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18053     | accountID不存在           | 请与公司客服联系


### 测试地址: api.daoke.io/accountapi/v2/judgeOnlineMobile
