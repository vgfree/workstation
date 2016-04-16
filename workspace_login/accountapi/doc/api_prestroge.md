IMEI预入库
========================

### API编号
* 

### 功能简介

用于IMEI预入库，且在工程环境下使用

### 参数格式

* API以 **POST** 方式请求，使用k-v方式提交

### 输入参数

 参数                        | 参数说明            | 类型     |   示例        | 是否允许为空  | 限制条件
-----------------------------|--------------------|----------|---------------|--------------|---------------------------
 appKey                     | 应用标识            | string  | 1111111111    | 否           | 长度不大于10
 sign                       | 安全签名            | string  | 无            | 否           | 长度为40
 IMEI                      |  应用标识            |int      | 222222222222222|否           |长度为15，首位不为0
### 示例代码/

ST /accountapi/v2/prestorge HTTP/1.0
Host: 127.0.0.1:80
content-type: application/x-www-form-urlencodedr
content-Length:85

&sign=FBFF641045C67C4DD25C257098553962B0EDB351&appKey=3555943163&IMEI=526505718677951
====================================
HTTP/1.1 200 OK
Server: nginx
Date: Sat, 15 Nov 2014 06:44:02 GMT
Content-Type: application/json
Content-Length: 34
Connection: close


### 返回body示例

* 成功:
	1.{"ERRORCODE":"0", "RESULT":"ok!"}

* 失败: {"ERRORCODE":"ME18505", "RESULT":"not receive GPS information"}
        {"ERRORCODE":"ME18001", "RESULT":"cur status not allow prestorge operator!"}



### 错误编码

 参数                 | 错误描述               	 | 解决办法     
----------------------|----------------------------|---------------------------------------
 0                    | 调用成功              	 | 
 ME01002              | appKey error        	 | appKey需使用从语镜公司申请得到的appKey
 ME18503              | cur IMEI status not allow prestorge	 | 请与公司客服联系
 ME01020              | mysql failed!        	 | 访问令牌已过期
 ME01024              | http body is null!    	 | 请与公司客服联系
 ME01022              | 系统内部错误           	 | 请与公司客服联系
 ME18505              | not receive GPS information               | 


 


### 测试地址: api.daoke.io/accountapi/v2/prestorge


