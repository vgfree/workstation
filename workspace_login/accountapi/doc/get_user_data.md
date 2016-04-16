获取用户资料API
==========================

### API编号

### 功能简介
* 获取用户资料

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数                    |参数说明            |  类型        |   示例             |是否允许为空|  限制条件
------------------------|------------------|--------------|--------------------|------------|---------------------
 appKey                 | 应用标识           | string       |  1111111111        |否           | 长度不大于10
 sign                   | 安全签名           | string       |  无                |否           | 长度为40
 accountID              | 用户帐号           | string       |  无                |否           | 长度为10的字母
 accessToken            | 访问令牌           | string       |  无                |否           | 非空
 field 					|用户信息		        | string       |nickname (昵称)	    |是           | 输入多个参数请以','分割开， 如果不输入这个参数默认会返回全部用户信息


### 示例代码

    POST /accountapi/v2/getUserData HTTP/1.0
    Host:192.168.1.207:8000
    Content-Length:120
    Content-Type:application/x-www-form-urlencoded

    appKey=184269830&accessToken=&sign=0C5B8214A3BF0F6550410DF7E3D2DB690E2ECDCB&field=nickname，idNumber&accountID=lV000mLuKm
 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":{nickname":'hfhggh'}


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
nickname        | 昵称
根据要获取的参数字段来返回所需的参数


### 错误编码

错误编码               | 错误描述                 | 解决办法
---------------------|--------------------------|------------------
0                    | 调用成功                  | 
 ME01002              | appKey error           | appKey需使用从语镜公司申请得到的appKey
 ME01003              | accessToken not match  | 访问令牌不匹配
 ME01004              | accessToken expire     | 访问令牌已过期
 ME01019              | sign is not match      | 请阅读语镜公司提供的签名算法
 ME01020              | mysql failed!    	  | 请与公司客服联系
 ME01022              | 系统内部错误           | 请与公司客服联系
 ME01023              | 参数错误               | 请检查输入参数
 ME01024              | http body is null!"   | 请检查输入参数
 ME18053              | 帐户不存在             | 更改帐户


### 测试地址: api.daoke.io/accountapi/v2/getUserData
