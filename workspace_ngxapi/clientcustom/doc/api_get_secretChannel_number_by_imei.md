通过imei获取用户关联频道信息
========================

### API编号

### 功能简介
*通过imei获取获取用户所在频道的名称、编号

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                         	| 参数说明             	| 类型        |   示例              | 是否允许为空    | 限制条件
-------------------------------|--------------------------|------------|---------------------|-----------------|---------------------------
 appKey                     	| 应用标识           		| string  	| 1111111111 			| 否           	| 长度不大于10
 sign                       	| 安全签名           		| string  	| 无          		| 否           	| 长度为40
 imeis                  		| 需要查询的用户的imei     | string  	| 0000000000  		| 否            	| 可以为多个,用逗号隔开

### 示例代码/clientcustom/v2/getChannelNumberByImei

	POST /clientcustom/v2/getChannelNumberByImei HTTP/1.0
	Host:192.168.1.207:80
	Content-Length:84
	Content-Type:application/x-www-form-urlencoded

appKey=2064302565&imeis=815467111699589%2C901960311113742&sign=04D56CCCEE131C4391B0AF1DDE1279A5E2CC7AE7

### 返回body示例

* 成功: `{ERRORCODE: "0",RESULT: {failed: [ ],success: [{channelName: "频道零零八九零",accountID: "Tyl11111fI",channelNumber: "00890",IMEI: "815467491699589",actionType: "4"},{channelName: "频道幺零零八六",accountID: "TylQBYfCfI",channelNumber: "10086",IMEI: "815467491699589",actionType: "5"}]}} `

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回参数

 参数      	 |  参数描述 
-------------|----------------
failed		 | 非法的IMEI列表
success      | 查询成功的IMEI列表
accountID    | 用户账号
channelName  | 频道名称
channelNumber| 频道编号
actionType   | 动作类型
IMEI 		 | 设备编号


*动作类型:1-拨打电话1;2-拨打电话2;3-发送语音,4-语音命令,5-发送群组语音,6-yes回复,7-no回复,8-关机,9-路过签到,10-语音回复,需返回bizid.


### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME01020              | mysql failed!		   | 数据库错误, 请与公司客服联系
 ME01024              | http body is null!     | 请检查输入参数
 ME01021              |redis failed!           |请与公司客服联系

### 测试地址: api.daoke.io/clientcustom/v2/getChannelNumberByImei


