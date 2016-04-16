设置用户自定义参数的API
===============================

### API编号

### 功能简介
* 设置用户自定义的参数

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

参数                    | 参数说明
------------------------|--------------------------------
accountID		| 用户帐号编号
appKey			| 应用标识
model			| 语镜终端型号
customArgs		| 客户自有定义信息
sign			| 安全签名


###示例代码

POST /accountapi/v2/updateCustomArgs  HTTP/1.0
Host:127.0.0.1:80
Content-Length:248
Content-Type:application/x-www-form-urlencoded

accountID=fgflPWlvgy&customArgs={"voiceCommand":false,"groupVoice":true,"autoSend":false,"ktvMode":false,"stopNewStatus":false,"stopNewStatusDis":true,"autoSetVolume":"true"}&model=MG900&sign=DD936B5373155B367BEDD21E2CA21CE32A252098&appKey=10469855


### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功：`{"ERRORCODE":"0", "RESULT":"ok!"}`

### 返回参数列表

无

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0	    | Request OK                |
ME01020	    |mysql failed		|联系公司客服
ME18053	    |this accountID is not exist|请提供正确的accountID


### 测试地址: api.daoke.io/accountapi/v2/updateCustomArgs
