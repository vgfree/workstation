获取用户拍照权限API
==========================

### API编号

### 功能简介
* 获取用户拍照权限

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 accountIDs             | 用户帐号           | string      |  无                |否          | 长度为10的字母(可输入多个accountID，每个accountID之间用逗号隔开。)
 

### 示例代码

    POST /accountapi/getDeviceControlPermission HTTP/1.0
    Host:192.168.1.3:8088/accountapi
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    appKey=2064302565&accountIDs=kxl1QuHKCD%2ClTPLXSoHmy%2C&sign=1111111111
 
### 返回body示例

* 出错: `{"ERRORCODE": "ME01023","RESULT": "accountIDs is error!"}`

* 正确: `{"ERRORCODE": "0","RESULT": [{"accountID": "kxl1QuHKCD","status": "1"},{"accountID": "lTPLXSoHmy","status": "2"}]}`


### 返回结果参数

参数            | 参数说明
----------------|--------------------------------------------------------
accountID       | 用户帐号
status          | 用户拍照权限；0：关闭，1：半开放(默认状态)，2：开放



### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01020     | mysql failed!             | 请与公司客服联系
ME01024     | http body is null!        | 请检查输入参数
ME01023     | accountIDs is error!      | 请检查输入参数




### 测试地址: api.daoke.io/accountapi/getDeviceControlPermission
