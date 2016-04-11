
管理员审核微频道
========================

### API编号
* 

### 功能简介
* 管理员审核微频道

### 参数格式

* API以 **POST** 方式请求，使用key-val方式提交

### 输入参数

 参数                         | 参数说明           | 类型     |   示例        | 是否允许为空  | 限制条件
------------------------------|-------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 checkAccountID             | 审核人帐号         | string  | 1111111111             | 否           | 长度为10的字母 
 accountID                  | 审核帐号           | string  | 2222222222    | 否           | 长度为10的字母
 channelNumber             | 频道编号           | string  | 无             | 否           | 长度大于5 并且小于16 ,只能是字母加数字,第一位必须为字母     
 checkRemark                | 审核理由           | string  | 无            | 是           | 长度不大于64
 checkStatus                | 审核状态           | string  | 1             | 否           | 1驳回  2审核成功
 channelRemark             | 频道备注           | string  | 无             | 是           | 长度不大于64       
 applyIdx                   | 真实频道号         | string  | 1             | 否           | 正整数
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |无
 
### 示例代码/clientcustom/v2/checkApplyMicroChannel

	POST /clientcustom/v2/checkApplyMicroChannel HTTP/1.0
	Host:api.daoke.io:80
	Content-Length:150
	Content-Type:application/x-www-form-urlencoded

	sign=D36BA2EAE440B16C8CD0B75CEA9518DC061BF3D8&checkAccountID=1111111111&channelNumber=FMxx0001&applyIdx=1&checkRemark=&checkStatus=1&appKey=1111111111&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":"ok!"}`
* 失败: 
		`{"ERRORCODE":"ME18109", "RESULT":"channel number is error"}`


### 错误编码

 参数                 | 错误描述              	| 解决办法     
----------------------|-------------------------|---------------------------------------
 0                    | ok             		 	| 正常调用
 ME01002              | appKey error         	| appKey需使用从语镜公司申请得到的appKey
 ME01003 			  | access token not matched | 令牌访问权限不匹配
 ME01020              | mysql failed!        	| 数据库错误 ,请与公司客服联系
 ME01019              | sign is not match    	| 请阅读语镜公司提供的签名算法
 ME01022              | internal data error! 	| 系统错误，请与公司客服联系
 ME18109              | channelNumber is error! | 检查参数 ,请与公司客服联系
 ME18307              | txt2voice failed! 	 	| 文本转语音失败，请重试
 ME01023              | parameter is error!                 | 参数错误，请按照文档提供的参数要求传参

 
### 测试地址: api.daoke.io/clientcustom/v2/checkApplyMicroChannel

