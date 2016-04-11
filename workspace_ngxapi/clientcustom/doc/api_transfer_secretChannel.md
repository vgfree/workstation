
群聊频道转移API
========================

### API编号
* 

### 功能简介
* 群聊频道转移API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|------------------- |----------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string   | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string   | 无            | 否           | 长度为40
 accountID                  | 用户帐号           | string   | 2222222222    | 否           | 长度为10 
 password					| 密码               | string   | 无            | 否           | 长度大于等于1
 receiverAccountID			| 接受者账户号       | string   | 2222222222    | 否           | 长度为10 
 channelNumber				| 频道编号           | number   | 010001        | 否           | 长度为1到50 
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |(对accountID进行accessToken验证)

### 示例代码/clientcustom/v2/transferSecretChannel

    POST /clientcustom/v2/transferSecretChannel HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    appKey=111111111&pageCount=3&sign=81267204822C52AFECC768C6D64B6693F6EBBFE5&startPage=1&actionType=3&defineName=sd&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":"ok!"}`
* 失败: 
		`{"ERRORCODE":"ME01023", "RESULT":"accountID is error!"}`


### 错误编码

 参数                 | 错误描述                       | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | ok!                            | 正常调用
 ME01003 			  | access token not matched 		| 用户令牌访问权限不匹配
 ME01023              | %s is error!                   | 参数错误，请按照文档提供的参数要求传参
 ME01020              | mysql failed!                  | 数据库错误 ,请与公司客服联系
 ME18053              | this accountID is not exist!   | 当前的用户编号不存在 请重新输入
 ME18063              | password is not matched        | 请重新输入正确的密码
 ME01021              | redis failed!                  | 请与公司客服联系
 ME18109              | channel number is error        | 当前频道编码错误,请检查频道编码
 ME01022              | internal data error!           | 数据库错误 ,请与公司客服联系
 ME18106 			  |user channel Maximum 			|当前用户频道数达到最大值


### 测试地址: api.daoke.io/clientcustom/v2/transferSecretChannel

