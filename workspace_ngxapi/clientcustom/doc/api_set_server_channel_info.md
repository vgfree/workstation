
设置服务频道信息API
========================

### API编号
* 

### 功能简介
* 设置服务频道信息API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|--------------------|----------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string   | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string   | 无            | 否           | 长度为40
 accountID                  | 语境帐号           | string   | 2222222222    | 否           | 长度为10的字母
 receiveAccountID           | 语境帐号           | string   | 2222222222    | 是           | 长度为10的字母
 serverID					| 服务频道ID(自定义类型)  | number   | 13         | 否          | 大于等于10的整数
 content					| 内容 (长度不大于512)  | string   	| 无            | 否           | number类型
 contentType				| 内容类型			| string   | 1  | 否   | text, image, voice, video, news

### 示例代码/clientcustom/v2/setServerChannelInfo

    POST /clientcustom/v2/setServerChannelInfo HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

	appKey=2064302565&receiveAccountID=&contentType=text&sign=B2D7CF54CA577AD63DDBD6EF21BACCB7B8A6AF09&content=%7B%22content%22%3A%22Hello+World%22%7D&serverID=13&accountID=kxl1QuHKCD


### 返回body示例

* 成功: `{"ERRORCODE":"0","RESULT":"ok!"}`
* 失败: `{"ERRORCODE":"ME01023", "RESULT":"parameter is error!"}`

### 返回结果参数

参数                  | 参数说明              
----------------------|----------------------------------------------
ok              | 正常调用


### 错误编码

 参数                 | 错误描述                       | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | Request OK                     | 正常调用
 ME01023              | parameter is error!            | 请按照文档提供的参数要求传参
 ME01020              | mysql failed!                  | 请与公司客服联系
 ME01022              | internal data error!           | 请与公司客服联系
 ME01024              | http body is null!             | 请与公司客服联系
 ME18317              | current user is not exist channel| 请先申请一个服务频道


### 测试地址: api.daoke.io/clientcustom/v2/setServerChannelInfo

