用户拍照权限控制设置API
==========================

### API编号

### 功能简介
* 用户拍照权限控制设置

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                   |参数说明            |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string      |  1111111111        |否          | 长度不大于10
 sign                   | 安全签名           | string      |  无                |否          | 长度为40
 accountID              | 用户帐号           | string      |  无                |否          | 长度为10的字母
 model                  | 设备号             | string      |  无                |是          | 长度为5位（为空时model号是MG900）
 status                 | 拍照权限设置       | string      |  0                 |否          | number（0：关闭，1：半开放，2：开放）

### 示例代码
	POST /accountapi/setDeviceControlPermission HTTP/1.0
    Host:192.168.1.3:8088/accountapi
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    status=0&appKey=1111111111&sign=3333333333&model=MG900&accountID=2222222222
 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01020", "RESULT":"mysql failed!"}`

* 正确: `{"ERRORCODE": "0", "RESULT": "ok!"}`



### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | ok!                       |
ME01020     | mysql failed!             | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数


### 测试地址: api.daoke.io/accountapi/setDeviceControlPermission
