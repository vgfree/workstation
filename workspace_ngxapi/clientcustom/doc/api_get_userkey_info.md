
获取按键信息API
========================

### API编号
* 

### 功能简介
* 获取按键信息API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数
 
 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|------------------- |----------|--------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 申请账户           | string  | 2222222222    | 否           | 长度为10 
 actionType					| 作用类型			 | number  | 3             | 是           | 3,4,5  3：吐槽按键 4：语音命令 5：群组语音
 accessToken 				|用户令牌访问权限 		|string  	|aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 		|否 		 |长度为32位



### 示例代码/clientcustom/v2/getUserkeyInfo

    POST /clientcustom/v2/getUserkeyInfo HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded


    appKey=2222222222&sign=C95D52D96DAACACE6A3983AB83D4D5CE960D1097&actionType=3&accountID=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa



### 返回body示例

* 成功: 

		{
		    "ERRORCODE": "0", 
		    "RESULT": {
		        "count": "1", 
		        "list": [
		            {
		                "actionName": "voiceCommand", 
		                "actionType": "4", 
		                "customParameter": "000007643", 
		                "talkStatus": 1, 
		                "parameterName": "AA验证测试testS", 
		                "customType": "10",
		                "logo":"",
		            }
		        ]
		    }
		}

* 失败: 
		`{"ERRORCODE":"ME01023", "RESULT":"parameter is error!"}`


### 返回结果参数

参数                  | 参数说明              
----------------------|----------------------------------------------
count                 | 目录数量
actionName            | 按键名称（voiceCommand/groupVoice/mainVoice）
actionType            | 作用类型。3：吐槽按键 4：语音命令 5：群组语音
customType            | 自定义类型
customParameter       | 自定义类型对应的参数
parameterName         | 自定义类型对应的名称
talkStatus            | 自己所在频道的状态 1 正常 / 2 禁言 / 3拉黑  / 4 未审核通过
logo                  | 当前频道所关联的 logo

### 错误编码

 参数                 | 错误描述                       | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | Request OK					   | 正常调用
 ME01003 			  | access token not matched 		| 用户令牌访问权限不匹配
 ME01023              | parameter is error!            | 参数错误，请按照文档提供的参数要求传参
 ME01020              | mysql failed!          		   | 数据库错误 ,请与公司客服联系
 ME01022              | internal data error! 		   | 系统错误 ,请与公司客服联系
 ME01024              | http body is null! 		       | 请与公司客服联系


### 测试地址: api.daoke.io/clientcustom/v2/getUserkeyInfo

