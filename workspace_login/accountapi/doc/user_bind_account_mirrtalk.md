用户绑定语镜账号和IMEI的API
=================================

### API编号

### 功能简介
* 用户绑定语镜账号和IMEI

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      | 1111111111     |否          | 长度不大于10
 sign             | 安全签名        | string      | 无             |否          | 长度为40
 accessToken    | 用户的授权访问令牌       | string      | 无         |  否             | 无
 accountID        | 账户编号        | string      | aaaaaaaaaa     |否          | 长度为10
 IMEI             | 终端的编号      | string      | 222222222222222|否          | 非0开头的长度15位的数字


### 示例代码

    POST /accountapi/v2/userBindAccountMirrtalk HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:105
    Content-Type:application/x-www-form-urlencoded

    IMEI=123456789012348&sign=511A4A24E9C7026F8F165F53E50A07B852C59D5C&accountID=6mwpIlvLyK&appKey=1111111111
 
### 返回body示例

* 出错: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 正确: `{"ERRORCODE":"0", "RESULT":"ok"}`



### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
无              | 无


### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01020		|mysql failed!				|请与公司客服联系
ME01022		|internal data error!		|请与公司客服联系
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误                 | 请与公司客服联系
ME01023     | 参数错误                    | 请检查输入参数
ME01024     |http body is null!			|请与公司客服联系
ME18004		|参数错误						|请检查输入参数
ME18031     | IMEI不存在                 | 请与公司客服联系
ME18053     |this accountID is not exist!| 请与公司客服联系
ME18059     | IMEI已经被绑定            | 请与公司客服联系
ME18060     | accountID被停止服务       | 请与公司客服联系
ME18902     |this accountID has bind! |请与公司客服联系
ME18906		|IMEI is invalidity       |请与公司客服联系
ME18907		|IMEI 与accountID重复绑定	  |请核实imei账号


### 测试地址: api.daoke.io/accountapi/v2/userBindAccountMirrtalk
