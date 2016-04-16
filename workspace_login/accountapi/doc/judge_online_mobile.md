根据手机号判断用户是否在线的API
=================================

### API编号:S0119V2

### 功能简介
* 根据手机号判断用户是否在线

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  2020202020        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 mobile                 | 手机号             | string      |  无                |否          | 多个用逗号隔开
 

### 示例代码

    POST /accountapi/v2/judgeOnlineMobile HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:94
    Content-Type:application/x-www-form-urlencoded

    mobile=11111110000,22222220052&sign=F550494373B3DBCE1831111111114BCC992C&appKey=0202020202

### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{"11111110000":{"status":0},"22222220052":{"status":-3}}}`


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
mobile     	| 手机号码
status        | 状态 0：在线用户，-1：关机用户， -2：无IMEI用户， -3：无accountID用户


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME01024	   |  http body is null		|请检查输入参数


### 测试地址: api.daoke.io/accountapi/v2/judgeOnlineMobile
