获取用户自定义参数的API
===============================

### API编号

### 功能简介
* 获取用户自定义的参数

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                        | 参数说明            | 类型     |   示例         | 是否允许为空  | 限制条件
-----------------------------|---------------------|----------|----------------|---------------|---------------------------
 appKey                      | 应用标识            | string   | 	       | 否            | 长度不大于10
 sign                        | 安全签名            | string   | 无             | 否            | 长度为40
 accountID                   | 语镜用户帐户编号    | string   | 无     | 是            | 长度为10的字符
 model                       | 语镜终端型号        | string   | 无             | 否            | 长度为5位的字母/数字

###示例代码

POST /accountapi/v2/getCustomArgs  HTTP/1.0
Host:127.0.0.1:80
Content-Length:94
Content-Type:application/x-www-form-urlencoded

sign=F4B50A3CEECFB000000000000000C1FD3510A&model=lpkldk&accountID=pppppppppp&appKey=1111115555

### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功：`{"ERRORCODE": "0", "RESULT": [{ "isDefine": 0, "isnewModel": 1,remark":"test1", "call2": "10086", "accountID": "lkj0000qWy", "customArgs":{"stopNewStatus": false,"ktvMode": false,"voiceCommand":false,"autoSend": false,"stopNewStatusDis": true,"groupVoice":"autoSetVolume": "true"}, "call1": "10086", "domain": "127.0.0.1", "port": "80"}]}


### 返回结果参数

参数            	| 参数说明
--------------------|-------------------------------------------
isDefine       	| 用户是否设置开机参数 0：否，1;是
isnewModel     	| 当前model是否为新加model（没有设置开机参数）0:否，1：是
accountID		| 账户编号
call1          	| 频道号一
call2          	| 频道号二
domain         	| 数据接收服务器域名
port          	| 端口
remark			| 备注
customArgs     	| 开机参数
stopNewStatus  	| 15分钟无gps
stopNewStatusDis| 定点无位移
autoSetVolume	| 自动调节音量
ktvMode          	| KTV模式
groupVoice       	| ++键功能
voiceCommand     | +键功能
autoSend          | 自动发送


### 错误编码


错误编码      |  Error describe                   | 错误描述              | 解决办法
--------------|-----------------------------------|-----------------------|---------------------------------------
 0            | Request OK                        | 调用成功              |
 ME01020      | mysql failed                      | 操作数据库错误        | 联系公司客服
 ME01022      | internal data error               | 系统错误              | 检查参数
 ME18004      | has more record in db             | 数据库数据错误        | 联系公司客服
 ME18053      | this accountID is not exist       |accountID不存在    |使用语境公司下发的账户编号
 ME18903      | model invalid                     | model 无效            |请输入正确的model


### 测试地址: api.daoke.io/accountapi/v2/getCustomArgs
