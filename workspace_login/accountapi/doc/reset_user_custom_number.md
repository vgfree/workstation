恢复用户自定义默认号码API
=================================

### API编号

### 功能简介
* 恢复用户自定义默认号码

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 accountID              | 账户编号           | string      |  aaaaaaaaaa        |否          | 长度为10
 numberType             | 类型               | string      |  1                 |否          | 如果其值为0，表示两个号码都恢复默认值；如果其值为1，表示一号键callcenter恢复默认值；如果其值为4，表示四号键sos恢复默认
 

### 示例代码

    POST /accountapi/v2/resetUserCustomNumber HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:97
    Content-Type:application/x-www-form-urlencoded

    numberType=0&sign=012D59F3591D0AE73908712B351E8930CA5213FA&accountID=KHrD79T38a&appKey=1111111111
 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok"}`


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
ME18053     | accountID不存在           | 请与公司客服联系
ME18009     | 默认配置config不存在      | 请与公司客服联系


### 测试地址: api.daoke.io/accountapi/v2/resetUserCustomNumber
