设置用户自定义参数的API
===============================

### API编号

### 功能简介
* 设置用户自定义的参数

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                   | 参数说明           |  类型       |   示例             |是否允许为空|  限制条件
------------------------|--------------------|-------------|--------------------|------------|---------------------
sign                   | 安全签名           | string      |  无                |否          | 长度为40
appKey                 | 应用标识           | string      | 1111111111         |否          | 长度不大
accountID             | 用户帐号编号       | string      | 无         |是          | 长度为10
model                  | 语镜终端型号       | string      |  无                |否          | 字母/数字
domain				| 数据接收服务器域名 | string	   |  无		|否	     | 无
customArgs            | 客户自有定义信息   | string      |  无                |否          | 无
remark				| 备注		     | string	   |  无		|是	     | 无

###示例代码

POST /accountapi/v2/setCustomArgs  HTTP/1.0
Host:127.0.0.1:80
Content-Length:248
Content-Type:application/x-www-form-urlencoded

customArgs=%7B%22voiceCommand%22%3Afalse%2C%22groupVoice%22%3Atrue%2C%22autoSend%22%3Afalse%2C%22ktvMode%22%3Afalse%2C%22stopNewStatus%22%3Afalse%2C%22stopNewStatusDis%22%3Atrue%2C%22autoSetVolume%22%3A%22true%22%7D&appKey=1111001010&remark=test123456123&domain=www.14523.com&sign=17F1C0A53D74D0996DACC01078BF7E331EF3E325&model=mmmmm&accountID=0000000000


### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功：`{"ERRORCODE": "0","RESULT": [{ "call1": "10086","remark":"test1","updateTime": "1435548807", "accountID": "lkj0000qWy","call2": "10086","customArgs": {"stopNewStatus": false,"ktvMode": false,"voiceCommand":false,"autoSend": false,"stopNewStatusDis": true,"groupVoice":"autoSetVolume": "true"},"model": "B0001", "domain": "www.14523.com", "port": "80"}]}`

### 返回参数列表
参数            	| 参数说明
--------------------|---------------------------
accountID		| 账户编号
updateTime		| 更新时间
call1          	| 频道号一
call2          	| 频道号二
model			| 语镜终端型号
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

 错误编码     | Error describe	                   | 错误描述               | 解决办法
--------------|------------------------------------|------------------------|---------------------------------------
 0            | Request OK                         | 调用成功               |
 ME01020      | mysql failed                       | mysql访问失败          |联系公司客服
 ME18053      | this accountID is not exist        | 这个accountID是不存在的|请提供正确的accountID
 ME18903      | model invalid			   | model 无效		    |请输入正确的model
 ME01023      | model is error			   | model 错误		    |请输入正确的model


### 测试地址: api.daoke.io /accountapi/v2/setCustomArgs
