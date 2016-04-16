添加用户自定义账号的API
===============================

### API编号

### 功能简介
* 生成imei

### 参数格式

* 所有 API 都以 **POST** 方式请求，且传送方式为 **key-value键值对**.

### 输入参数


 参数                   |参数说明            |  类型      |   示例          |是否允许为空|  限制条件
-----------------------|-------------------|------------|----------------|------------|---------------------
 appKey                | 应用标识           | string      |  1111111111    |否          | 长度不大于10
 model                 | 车机设备类型        | string      |  SG502         |否          | 长度为5
 company               | 申请公司名称        | string      |  无            |否          | 无
 validity              | 有效性             | string      |  0             |否          | 0：无效；1：有效'
 businessID            | 渠道商的ID         | int         |  无            |否          | 无
 isThirdModel          | 是否是第三方model   | int         |  1             |否          | 0--不是;1--是
 mirrtalkCount         | 订购的语镜台数      |  int        |  50            |否          | 无
 mirrtalkInforemarks   | mirrtalkInfo备注   | string      |  无            |否          | 无
 mirrtalkHistoryremarks| mirrtalkHistory备注| string      |  无            |否          | 无


### 示例代码


    POST /accountapi/v2/createImei HTTP/1.0
    Host:127.0.0.1:80
    Content-Length:172
    Content-Type:application/x-www-form-urlencoded

    mirrtalkInforemarks=ffffffffffffffffffff&appKey=2064302565&businessID=99&company=anli&clientappKey=3333333333&isThirdModel=1&sign=A88050DF546F9912374D65B6DE515C56CA6BD070&mirrtalkCount=1&mirrtalkHistoryremarks=lllllllllllllllllllllllllllllllll&model=AL000

### 返回body示例

* 失败: `{"ERRORCODE":"ME01002", "RESULT":"appKey error"}`

* 成功: `{"ERRORCODE":"0", "RESULT":{"ERRORCODE": "0","RESULT": "ok!"}}`


### 返回结果参数

参数                    | 参数说明
------------------------|--------------------------------
无                      | 无

### 错误编码

错误编码    | 错误描述                          | 解决办法
------------|---------------------------------|------------------
0           | Request OK                      |
ME01023     | company is error!               | 查看申请公司名称是否为空
ME01023     | model is error!                 | 检查model是否为空
ME01023     | businessID is error!            | 检查businessID
ME01023     | isThirdModel is error!          | 检查isThirdModel
ME01023     | mirrtalkCount is error!         | 检查mirrtalkCount
ME01023     | clientIP is error!              | 检查clientIP
ME01023     | mirrtalkInforemarks is error!   | 检查mirrtalkInforemarks
ME01023     | mirrtalkHistoryremarks is error!| 检查mirrtalkHistoryremarks
ME01023     | clientappKey is error!          | 检查clientappKey

### 测试地址: api.daoke.io/accountapi/v2/createImei
