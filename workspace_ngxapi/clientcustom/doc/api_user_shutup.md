
用户禁言API
========================

### API编号
* 

### 功能简介
* 用户禁言API

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                       | 参数说明           | 类型     |   示例        | 是否允许为空 | 限制条件
----------------------------|------------------- |----------|--------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40
 accountID                  | 申请账户           | string  | 2222222222    | 否           | 长度为10 
 totalTime                  | 禁言时间       	 | string  | 5      	   | 否           | 秒数，number类型
 status                     | 禁言状态           | int 	   | 1             | 否           | 1 禁言 0 不禁言
	

### 示例代码/clientcustom/v2/userShutUp

    POST /clientcustom/v2/userShutUp HTTP/1.0
    Host:api.daoke.io:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    totalTime=60&status=1&sign=718AD652C1B3846C6A13DE7686A138D97745BE4A&appKey=1111111111&accountID=2222222222


### 返回body示例

* 成功: 
		`{"ERRORCODE":"0", "RESULT":"ok"}`
* 失败: 
		`{"ERRORCODE":"ME01023", "RESULT":"parameter is error!"}`



### 错误编码

 参数                 | 错误描述                       | 解决办法     
----------------------|--------------------------------|---------------------------------------
 0                    | ok 		                       | 正常调用
 ME01023              | parameter is error!            | 参数错误，请按照文档提供的参数要求传参
 ME01020              | mysql failed!          		   | 数据库错误 ,请与公司客服联系
 ME18053              | this accountID is not exist!   | 当前的用户编号不存在 请重新输入
 ME01022              | internal data error! 		   | 系统错误 ,请与公司客服联系



### 测试地址: api.daoke.io/clientcustom/v2/userShutUp

