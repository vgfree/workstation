获取用户所在频道的名称以及同频道成员列表API
========================

### API编号
*  2306

### 功能简介
* 获取自己所在频道的名称以及同频道成员列表

### 参数格式

* API以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数

 参数                                 | 参数说明             | 类型       |   示例             | 是否允许为空  | 限制条件
--------------------------------------|---------------------|------------|--------------------|--------------|---------------------------
 appKey                     | 应用标识           | string  | 1111111111 | 否           | 长度不大于10
 sign                       | 安全签名           | string  | 无          | 否           | 长度为40
 accountID                  | 查询者账号         | string  | 0000000000  | 否            | 语境公司下发的账号
 accessToken                | 令牌访问权限        |string     |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否       |
 
### 示例代码/clientcustom/ v2/getChannelMemberList

	POST /clientcustom/v2/getChannelMemberList HTTP/1.0
	Host:192.168.1.207:80
	Content-Length:84
	Content-Type:application/x-www-form-urlencoded

	appKey=000120565&sign=5718CA165EA4000000008DDD000060&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

### 返回body示例

* 成功: `{"ERRORCODE": "0", "RESULT": [  {"accountID": "eB00000l", "channelname": "频00000幺", "actionType": 5} ] }`

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

### 返回参数

 参数      |  参数描述 
-----------|----------------
accountID   | 用户账号
fromChannel 	| 频道编号
fType    	| 动作类型




### 错误编码

 参数                 | 错误描述               | 解决办法     
----------------------|------------------------|---------------------------------------
 0                    | 调用成功               | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME18317              | Users did not join the channel! | 请先加入频道
 ME01020              | mysql failed!		   		  | 数据库错误, 请与公司客服联系
 ME01006              | error json data!        | 请检查输入参数
 ME18053              | this accountID is not exist!| 请检查输入参数
 ME01024              | http body is null!    | 请检查输入参数


### 测试地址: api.daoke.io/clientcustom/v2/getChannelMemberList


