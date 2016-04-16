车机设备关联imei API
=================================

### API编号

### 功能简介
* 将车机设备号与语境公司提供的imei进行关联

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.


### 输入参数

 参数             |参数说明         |  类型       |   示例         |是否允许为空|  限制条件
------------------|-----------------|-------------|----------------|------------|---------------------
 appKey           | 应用标识        | string      | 1111111111     |否          | 长度不大于10
 sign             | 安全签名        | string      | 无             |否          | 长度为40
 deviceID         | 车机设备唯一号  | string      | 222222222222222|否          | 不超过64位的字母/数字
 model            | 车机设备类型    | string      | SG502 	   |否          | 长度为5位的字母/数字

### 示例代码
POST /accountapi/v2/associateDeviceIDWithImei HTTP/1.0
Host:127.0.0.1:80
Content-Length:98
Content-Type:application/x-www-form-urlencoded

sign=51CFA7775247BF0779A2FD582658D8EF67DCD060&deviceID=4561237894abc&model=HFN69&appKey=3671832113

### 返回body示例

*成功：`{"ERRORCODE":"0", "RESULT":{"businessBonusMax":"0.00","allowExchange":"1","bonusReturnMonth":"0","depositAmount":"0.00","businessID":"34","userBonusMax":"0.00","shareInfo":"0","bonusType":"1","bonusReturnTarget":"1","returnType":"1","depositType":"2","imei":"953426423793318"}}`

*失败： {"ERRORCODE":"ME18808", "RESULT":"deviceID   has binded imei!"}


### 返回结果参数

参数            | 参数说明
----------------|-------------------------------------------
imei            | 终端编号
depositType	| 押金类型
depositAmount	| 押金金额
businessID	| 商业编号
returnType	| 押金返回方式
bonusType	| 奖金类型
allowExchange	| 是否允许换货
shareInfo	| 是否获取私人信息
userBonusMax	| 里程奖金返个人的最大金额
businessBonusMax| 里程奖金返企业的最大金额
bonusReturnTarget|里程奖金的对象
bonusReturnMonth| 里程奖金返还总月数

### 错误编码

错误编码    | 错误描述                  | 解决办法
------------|---------------------------|------------------
0           | Request OK                |
ME01002     | appKey error              | appKey需使用从语镜公司申请得到的appKey
ME01019     | sign is not match         | 请阅读语镜公司提供的签名算法
ME01022     | 系统内部错误              | 请与公司客服联系
ME01023     | 参数错误                  | 请检查输入参数
ME18031     | IMEI不存在                | 请与公司客服联系
ME18059     | IMEI已经被绑定            | 请与公司客服联系
ME18808	    | 车机设备唯一号已经绑定imei| 请与公司客服联系
ME18807     | appkey is not match !     | 请输入和model号匹配的appkey

### 测试地址: api.daoke.io/accountapi/v2/associateDeviceIDWithImei
