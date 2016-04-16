判断给定的用户名、手机号码或邮箱是否允许注册的API
===================================================

### API编号

### 功能简介
* 判断给定的用户名、手机号码或邮箱是否允许注册

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 username               | 用户名             | string      |  无                |否          | 必须为username or moblie or email
 

### 示例代码

    POST /accountapi/v2/checkRegistration HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:81
    Content-Type:application/x-www-form-urlencoded

    username=ayzh1010&sign=0EA90BFAAAB30A6D08CD18EF718D8EB474EC3D98&appKey=1111111111

### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功: `{"ERRORCODE":"0", "RESULT":"0"}`



### 返回结果参数

 参数                   | 参数说明
------------------------|------------------------------------
 无                     | 无


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18002     | 该用户名已被使用          | 请与公司客服联系

### 测试地址: api.daoke.io/accountapi/v2/checkRegistration

