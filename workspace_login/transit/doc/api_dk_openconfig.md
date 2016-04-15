开放平台config
========================

### API编号
* 

### 功能简介
* 用于开发平台config

### 参数格式

* API以 **GET/POST** 方式请求

### 输入参数

 参数                       | 参数说明           | 类型    |   示例        | 是否允许为空 | 限制条件
----------------------------|--------------------|---------|---------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无            | 否           | 长度为40 ( 计算签名只需要lenght,appKey)
 mod                        | 车机设备类型       | string  | SG900         | 是           | 长度为5
 imei    		    | WEME终端号         | string  | 无 	   | 是		  | 长度为15的数字
 imsi   		    | 用户识别码 	 | string  | 无 	   | 是		  | 长度不超过15位数字
              


### 示例代码/openconfig
	 POST /openconfig HTTP/1.1
	 Host: app.config.mirrtalk.com
	 Accept: */*
	 Content-Length: 114
	 Content-Type: application/x-www-form-urlencoded
	
	appKey=616515395&sign=DD936B5373155B367BEDD21E2CA21CE32A252098&mod=MG900&imie=619289341656306&imsi=460011857743311 


### 返回body示例

* 成功: `{"ERRORCODE":"0", "RESULT":{"feedbackHost":"m9feedback1.mirrtalk.com","fetchdataHost":"m9fetchdata1.mirrtalk.com","fetchdataPort":"8990","feedbackPort":"7990"}}`
* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`


### 返回结果参数

 参数   | 参数说明
--------|-------------------------------
	| 配置信息json串

### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey


### 测试地址: http://app.config.mirrtalk.com/openconfig


