
获取服务频道内容API
========================

### API编号
* 

### 功能简介
* 获取服务频道内容API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|------------------- |----------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string   | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string   | 无            | 否           | 长度为40
 accountID                  | 语境帐号           | string   | 2222222222    | 否           | 长度为10的字母
 serviceID					| 服务频道ID(自定义类型)  | number   | 13             | 否          | 大于等于10的整数
 startPage					| 开始页             | string   | 无            | 否           | number类型
 pageCount					| 页数量             | string   | 无            | 否           | number类型

### 示例代码/clientcustom/v2/getServiceContent

    POST /clientcustom/v2/getServiceContent HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

	appKey=2064302565&pageCount=1&sign=51FB22017C164631A7D9AECE2AD12B464826473C&serviceID=10&startPage=1&accountID=lVVnCmLuKm


### 返回body示例

* 成功: `{"ERRORCODE":"0","RESULT":{"count":"1","list":[{"channel":"10","text":{"content":"Hello World"},"touser":"","msgtype":"text","fromuser":"kxl1QuHKCD","msgid":"11111111111", "createtime":"0"}]}}`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

参数                  | 参数说明              
----------------------|----------------------------------------------
count                 | 内容数量
channel				 |服务频道号
text     			|根据消息类型可为text, image, voice, video, news
touser				|接受者accountid
msgtype				| 消息类型
fromuser			|发送者accountid
msgid				|消息唯一ID
createTime          | 发送内容的时间



### 错误编码

 参数                 | 错误描述                       | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | Request OK                     | 正常调用
 ME01023              | parameter is error!            | 请按照文档提供的参数要求传参
 ME01020              | mysql failed!                  | 请与公司客服联系
 ME01022              | internal data error!           | 请与公司客服联系
 ME01024              | http body is null!             | 请与公司客服联系
 ME18317              | current user is not exist channel| 请先申请一个服务频道


### 测试地址: api.daoke.io/clientcustom/v2/getServiceContent

