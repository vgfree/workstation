通过accountID解散频道
=================================

### API编号

### 功能简介
* 通过用户账号编号解散特定的频道

### 参数格式 

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数              |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      |  1111111111    |否           | 长度不大于10
 sign             | 安全签名        | string      |  无            |否           | 长度为40
 accountID        | 账户编号        | string      |  aaaaaaaaaa    |否           | 长度为10
 password         | 账户密码        | string      |  aaaaaaaaaa    |否           | 长度大于1
 channelNumber    | 频道号          | string      |  100101        |否           | 长度为1到50之间，不能存在"'"
 accessToken      | 令牌访问权限     |string       |aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  | 否             |无

 
### 示例代码

    POST /clientcustom/v2/dissolveSecretChannel HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:84
    Content-Type:application/x-www-form-urlencoded

    appKey=1111111111&sign=932AE1948605A0209F2FC487DD0D3DCB8E97F539&channelNumber=&password=52452hgff&accountID=aaaaaaaaaa&accessToken=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

 ### 返回body示例

* 出错: `{"ERRORCODE":"ME01023", "RESULT":"accountID is error!"}`

* 正确: `{"ERRORCODE":"0", "RESULT": "ok!"}`


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
无              | 无


### 错误编码

错误编码     | 错误描述                    | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01003     | access token not matched 	| 令牌访问权限不匹配
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME18063     | password is not matched   | 请检查password
ME18109     | channel number is error!  | 请检channel number
ME01023     | accountID is error!       | 请检查accountID
ME01020     | mysql failed              | 数据库错误,请与公司客服联系



### 测试地址: api.daoke.io/clientcustom/v2/dissolveSecretChannel
