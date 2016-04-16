车机与设备号绑定API
=================================

### API编号

### 功能简介
* 将车机设备号和IMEI进行绑定

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      | 1111111111     |否          | 长度不大于10
 sign             | 安全签名        | string      | 无             |否          | 长度为40
 accountID        | 账户编号        | string      | aaaaaaaaaa     |否          | 长度为10
 deviceID         | 车机设备唯一号  | string      | 222222222222222|否          | 不超过64位的字母/数字
 model            | 车机设备类型    | string      | SG502 	   |否          | 长度为5位的字母/数字

### 示例代码
POST /accountapi/v2/carMachineBindImei HTTP/1.0
Host:192.168.1.191:80
Content-Length:119
Content-Type:application/x-www-form-urlencoded

accountID=eB6bYE8pkl&sign=1605469B5B962822F15625D9615C9963052FDBE4&model=S9YNK&deviceID=4561237894abc&appKey=3257675426
     
### 返回body示例

*成功：`{"ERRORCODE":"0", "RESULT":{"imei":"101012345678901"}}`

*失败： {"ERRORCODE":"ME18808", "RESULT":"deviceID   has binded imei!"}


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
imei            | 终端编号


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18031     | IMEI不存在                | 请与公司客服联系
ME18059     | IMEI已经被绑定            | 请与公司客服联系
ME18807     | accountID已经绑定imei     | 请与公司客服联系
ME18808	    | 车机设备唯一号已经绑定imei| 请与公司客服联系

### 测试地址: api.daoke.io/accountapi/v2/carMachineBindImei
