重置用户密码的API
=================================

### API编号

### 功能简介
* 重置用户密码

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 accountID              | 账户编号           | string      |  aaaaaaaaaa        |否          | 长度为10


### 示例代码


    POST /accountapi/v2/resetUserPassword HTTP/1.1
    User-Agent: curl/7.19.7 (x86_64-redhat-linux-gnu) libcurl/7.19.7 NSS/3.13.6.0 zlib/1.2.3 libidn/1.18 libssh2/1.4.2
    Host: 0.0.0.0:8088
    Accept: */*
    Content-Length: 84
    Content-Type: application/x-www-form-urlencoded

    accountID=5IYlbByilK&sign=B989C0AC3B01A2973EDF77F3B52FD5BF60468D61&appKey=2064302565

 
### 返回body示例

* 出错: `{"ERRORCODE":"ME18068", "RESULT":"user mobile hasn't authorization!"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok!"}`



### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
无              | 无


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18068     | 用户手机未验证            | 请与公司客服联系


### 测试地址: api.daoke.io/accountapi/v2/resetUserPassword
