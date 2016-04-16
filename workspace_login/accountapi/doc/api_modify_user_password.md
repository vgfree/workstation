修改手机用户密码API
======================

### API编号

### 功能简介
* 修改手机用户密码

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      |  1111111111    |否          | 长度不大于10
 sign             | 安全签名        | string      |  无            |否          | 长度为40
 mobile        	  | 手机号          | string      |  10191919191   |否          | 已经注册语境用户的手机号
 newPassword      | 用户的新密码    | string      |  无            |否          | 长度不小于6无特殊字符


###示例代码

POST /accountapi/v2/modifyUserPassword  HTTP/1.0
Host:127.0.0.1:80
Content-Length:64
Content-Type:application/x-www-form-urlencoded

mobile=18710405368&appKey=2064302565&newPassword=123456&sign=436BC46F1A911A87C929488EBCC157E162B737E8


### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功：`{"ERRORCODE":"0", "RESULT":"ok!"}`

### 返回参数列表

无

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0	    	| Request OK                |
ME01020	    |mysql failed				|联系公司客服
ME01006	    |error json data			|请提供正确的参数格式
ME01023	    |参数错误					|请提供有效的参数
ME18925	    |modify password failed		|请再次尝试

### 测试地址: api.daoke.io/accountapi/v2/modifyUserPassword
